/* =========================================================================
 * blt_engine_fsm.v — BitBlt 引擎主控（**行级重叠 + 突发流水**版）
 * -------------------------------------------------------------------------
 * 流程：IDLE→(FIFO≥8字&go) POP(8字)→DEC→EXEC(行流水)→WDWAIT
 *
 * 与原版的三个关键差别（性能改造，功能语义不变）：
 *
 * 1) **行级重叠**：原版每行是"取完整行（等 FIFO 收满）→ 再算"，取数与运算
 *    完全串行，DDR 读延迟每行都全额暴露。本版改为：
 *      - 像素通路只要拿到本行**第 1 个词**就可启动，后续词边到边算
 *        （`stream_reader` 是 FWFT，缺词时像素通路自然停顿）；
 *      - "发第 r+1 行的突发"发生在"算第 r 行"期间，读延迟被运算时间盖住。
 *
 * 2) **突发流水**：读主机改成信用握手、最多 OUTSTAND 笔在飞，行内/行间
 *    突发可以背靠背连续发出，不再每笔都等一次 AR+DDR 延迟。
 *
 * 3) **精确 drain**：行尾要丢掉的字数 = 本行覆盖字数 − 像素通路自己弹走的词数
 *      弹词数 = (px_skip + W) / 8   （每 8 像素弹 1 词；行首词只载不弹）
 *      覆盖字数 cover_beats 由 blt_addr_gen 给出 = ceil((px_skip + W)/8)
 *    所以 drain ∈ {0,1}：只有行尾那个"没被弹走的半词"需要丢。
 *    原版是"drain 到 FIFO 空"——那与预取不兼容（会把下一行已到的数据丢掉）。
 *
 * 行缓冲边界：FIFO 中最多同时存在 2 行（proc_r 与 proc_r+1）；
 * 约束 issue_r ≤ proc_r+1 保证这一点，取数不会跑到运算前面超过一行。
 * 因此 FG/BG FIFO 深度须 ≥ 2×cover_beats(max)，960 宽时 = 2×121 = 242 → 256。
 *
 * 4) **指令边界写屏障**：ST_WDWAIT 的出口要求 wr_commit_idle（wd FIFO 真空 +
 *    写主机空闲 + 没有未回 B 的写突发）。旧版只看 wd_empty/wd_busy，而 wd_empty
 *    是输出寄存器有效位（同步读流水，比真空晚 2~3 拍），于是"最后那个写词还没发
 *    出 AXI"就会报 IDLE/BUSY=0 —— 软件的 blt_idle() 误以为像素已落 DDR，下一条
 *    指令的 dst 读（ALPHA/KEY）/src 读（COPY）还会抢在它的写前面（写后读危险）。
 *    屏障只加在**指令边界**（一条指令的最后一个写突发），指令内部的突发照旧与
 *    行计算重叠，所以吞吐代价只是命令尾部一次 B 往返，不是逐像素串行。
 *    `-DBLT_WR_ORDER_OFF` 可关掉它做 A/B（见 blt_top.v）。
 *
 * 5) **★S3（v2.12）透明块跳过（KEY + 4×4 块掩码）**：整块都是键色的区域
 *    **不取数、不算、不写**。掩码随命令字来（w0[31:16] = 16 位块掩码，w0[2] =
 *    MASK_EN；DFU 从描述符 dw3[15:0]/FLAGS[7] 搬过来），**引擎 FSM 一行的
 *    端口都没改**（I1 不变：CPU 写 0 就是今天的行为）。
 *    落地方式是"**行窗口**"：本行的窗口 = [第一个非透明列块的起点, 最后一个
 *    非透明列块的终点]，窗口外的像素根本不经过像素通路 —— 于是
 *      · blt_addr_gen 按窗口算 row_start / px_skip / cover_beats ⇒ **源读的
 *        突发变短甚至不发**（整行全透明 ⇒ cover_beats=0）；
 *      · 像素通路只被喂窗口宽度，16B 打包/字节掩码/行尾冲刷/乒乓节拍一行未改；
 *      · 目的侧只有窗口内才产生写词 ⇒ 窗口外一个字节都不动。
 *    安全规则（只有"整块每个像素都不写"才允许跳过）：
 *      msk_on = MASK_EN && OP==KEY && W>=4 && H>=4。COPY/FILL/ALPHA 每个像素
 *      都要写，掩码**显式忽略**；逐像素 alpha（ARGB1555）尚不存在。
 *    `-DMASK_SKIP_OFF`：msk_on 恒 0 ⇒ 窗口恒为整行，逐位回到 S2 之后的行为。
 * ========================================================================= */
module blt_engine_fsm (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          go,            // CTRL.GO（run 使能）
    output reg           err_out,       // 电平，停机
    output wire          done_out,      // = IDLE && cmd空 && wd空（电平）
    output wire          busy_out,

    /* ---- 指令 FIFO ---- */
    input  wire [11:0]   cmd_wcount,
    input  wire          cmd_empty,     // !empty 才保证 cmd_dout 是当前队头
    input  wire [31:0]   cmd_dout,
    output wire          cmd_pop,       // 组合脉冲：本拍读取 cmd_dout 并弹字

    /* ---- 行缓冲状态（empty 才是"数据可用"的权威标志：同步读 FIFO 有 1 拍流水） ---- */
    input  wire          fg_empty,
    input  wire          bg_empty,
    output reg           fg_drain,
    output reg           bg_drain,
    input  wire          wd_empty,
    input  wire          wd_busy,     // 写主机仍在收尾
    input  wire          wr_commit_idle,  // 写通路彻底干净：无未发写词、无未回 B 的突发
    /* ★v2.10 命令末尾冲刷提示 → axi_wr_master.cmd_end_flush。
     * st==ST_WDWAIT ⇒ 本命令的像素已全部产出、再也没有写词会给出去 ⇒ 写主机的
     * 合并等待窗口（HOLD_MAX=16 拍）此时等的是一个永远不会来的词，纯浪费。
     * 提示只改变"什么时候冲刷尾突发"：不改 AW→W→B 结构与单笔在飞、不改
     * b_pending/wr_idle_committed、也不改下面 done_out / ST_WDWAIT 的出口判据
     * （命令依旧必须等写被内存系统受理才允许报完成）。 */
    output wire          wr_cmd_end,

    /* ---- 像素通路 ---- */
    output reg           pp_start,
    input  wire          pp_busy,
    input  wire          pp_row_done,
    output reg  [1:0]    pp_op,
    output reg  [15:0]   pp_width,
    output reg  [31:0]   pp_dbase,
    output reg  [2:0]    pp_dlane0,
    output reg  [2:0]    pp_fskip,
    output reg  [2:0]    pp_bskip,
    output reg  [7:0]    pp_alpha,
    output reg  [15:0]   pp_color,
    output reg  [15:0]   pp_key,
    /* ---- ★S5（v3.2）属性侧口：每命令按序弹一个字 → 像素通路 ---- */
    input  wire [31:0]   attr_dout,       // 属性 FIFO 队头（FWFT，!empty 时有效）
    input  wire          attr_empty,      // 空 ⇒ 用 ATTR_DEFAULT（= 今天的兼容行为）
    output reg           attr_pop,        // 弹出脉冲（1 拍）；空时不弹
    output reg  [31:0]   pp_attr,         // 本命令的属性字（ST_DEC 锁存 → RS_INIT 下发）
    output reg           pp_blend,        // 本命令是否真的走逐像素混合（blend_mode != 0）
    /* ---- ★S5 scissor（命令起始锁存；clip_en=0 ⇒ 逐位回到今天） ---- */
    input  wire [15:0]   clip_x0,
    input  wire [15:0]   clip_x1,
    input  wire [15:0]   clip_y0,
    input  wire [15:0]   clip_y1,
    input  wire          clip_en,

    /* ---- AXI 读主机（信用握手 / 可多笔在飞） ---- */
    output wire          rd_req,
    output wire [31:0]   rd_addr,
    output wire [7:0]    rd_len,
    output wire          rd_bg,
    input  wire          rd_ready,
    input  wire          rd_busy,
    input  wire          rd_done,
    input  wire          rd_tag,

    output reg  [31:0]   dbg_opword,
    output reg  [31:0]   perf_cycles   // 上一条指令的引擎周期数（读 PERF 可见）
);
    /* ---------------- 状态 ---------------- */
    localparam ST_IDLE    = 3'd0;
    localparam ST_POP     = 3'd1;
    localparam ST_DEC     = 3'd4;
    localparam ST_EXEC    = 3'd2;
    localparam ST_WDWAIT  = 3'd3;

    localparam RS_INIT    = 2'd0;
    localparam RS_LOOP    = 2'd1;   // 发突发 + 起行 + 等本行算完
    localparam RS_DRAIN   = 2'd2;

    reg [2:0]  st;
    reg [1:0]  rstate;
    reg [3:0]  pcnt;
    integer    k;                          // ★S3：复位时清 wt_* 表用

    /* ---------------- 指令寄存器 ---------------- */
    reg [31:0] w0, w1, w2, w3, w4, w5, w6, w7;
    reg [1:0]  cur_op;
    reg [31:0] cur_sa, cur_da, cur_ss, cur_ds;
    reg [15:0] cur_W, cur_H;
    reg [7:0]  cur_alpha;
    reg [15:0] cur_color;

    /* ---------------- ★S3 透明块跳过：掩码与"行窗口" ----------------
     * 掩码位序：bit(rt*4+ct)，rt = 行带 0(上)..3(下)，ct = 列块 0(左)..3(右)，
     * 1 = **该块整块都是键色（全透明）** ⇒ 本行窗口可以不含它。
     * 列块边界（像素，向下取整）：W/4、W/2、3W/4；行带边界同理由 H 给出。 */
    reg  [15:0] cur_mask;                  // 当前命令的 16 位块掩码（w0[31:16]）
    reg         cur_msk_on;                // 本命令掩码是否真的生效（见 msk_dec）
    reg  [15:0] wt_x0 [0:3];               // 4 个行带的窗口起点（像素）
    reg  [15:0] wt_w  [0:3];               // 4 个行带的窗口宽度（像素；0 = 整带全透明）
    reg  [3:0]  wt_e;                      // bit k = 第 k 个行带空窗口
    reg  [15:0] iw_x0, iw_w;  reg iw_e;     // 发送指针当前行的窗口
    reg  [15:0] pw_x0, pw_w;  reg pw_e;     // 处理指针当前行的窗口

    wire [15:0] col_t1 = cur_W >> 2;                        // 列块 1 起点
    wire [15:0] col_t2 = cur_W >> 1;                        // 列块 2 起点
    wire [15:0] col_t3 = (cur_W * 16'd3) >> 2;              // 列块 3 起点 = 3W/4
    wire [15:0] row_t1 = cur_H >> 2;                        // 行带 1 起点
    wire [15:0] row_t2 = cur_H >> 1;
    wire [15:0] row_t3 = (cur_H * 16'd3) >> 2;

    /* ★S3 窗口计算（纯组合；RS_INIT 一拍把 4 个行带全算出来存进 wt_*）：
     *   窗口 = [第一个非透明列块的起点, 最后一个非透明列块的终点]。
     *   4 个列块全透明（或列块边界退化）⇒ 空窗口 {e=1, x0=0, w=0}。
     *   m=0000（掩码关闭）⇒ 窗口 = [0, W) ⇒ 与 S2 逐位相同。 */
    function [32:0] win_band;              // {e, x0[15:0], w[15:0]}
        input [3:0]  m;                    // 1 = 该列块全透明
        input [15:0] w;                    // 精灵宽（列块 3 的终点）
        input [15:0] c1, c2, c3;           // 列块 1/2/3 的起点
        reg   [15:0] x_lo, x_hi;           // 窗口起点 / 终点+1
        begin
            if      (!m[0]) x_lo = 16'd0;
            else if (!m[1]) x_lo = c1;
            else if (!m[2]) x_lo = c2;
            else            x_lo = c3;
            if      (!m[3]) x_hi = w;
            else if (!m[2]) x_hi = c3;
            else if (!m[1]) x_hi = c2;
            else            x_hi = c1;
            if (x_hi <= x_lo) win_band = {1'b1, 16'd0, 16'd0};
            else              win_band = {1'b0, x_lo, x_hi - x_lo};
        end
    endfunction

    /* 掩码生效判据（组合，ST_DEC 那拍锁存）：
     *   `-DMASK_SKIP_OFF` ⇒ 恒 0（A/B 逃生门，逐位回到 S2 之后的行为）；
     *   否则要求 MASK_EN=1、OP==KEY、W≥4 且 H≥4（4×4 网格每块至少 1 像素）。
     * COPY/FILL/ALPHA 的 keep 恒 1（每像素都要写）⇒ 这里显式判成 0，掩码被忽略。 */
`ifdef MASK_SKIP_OFF
    wire        msk_ena = 1'b0;
`else
    wire        msk_ena = w0[2];
`endif
    wire        msk_dec = msk_ena && (w0[1:0] == 2'd3) &&
                          (w5[15:0] >= 16'd4) && (w5[31:16] >= 16'd4);
    /* ---- ★S5 scissor：命令起始锁存 + 两个纯组合判据（声明必须在 wb*c 之前） ----
     * `-DSCISSOR_OFF` ⇒ 恒不启用 = A/B 逃生门（逐位回到今天）。 */
`ifdef SCISSOR_OFF
    wire        clip_en_eff = 1'b0;
`else
    wire        clip_en_eff = clip_en;
`endif
    reg  [15:0] cur_cx0, cur_cx1, cur_cy0, cur_cy1;
    reg         cur_clip_en;

    /* 列方向求交：{e,x0,w} ∩ [cx0,cx1)（未启用 ⇒ 逐位原样返回） */
    function [32:0] win_clip_x;
        input [32:0] w_in;
        input        en;
        input [15:0] cx0, cx1;
        reg   [15:0] x0, x1;
        begin
            if (!en) win_clip_x = w_in;
            else begin
                x0 = w_in[31:16];
                x1 = w_in[31:16] + w_in[15:0];
                if (x0 < cx0) x0 = cx0;
                if (x1 > cx1) x1 = cx1;
                if (x1 <= x0) win_clip_x = {1'b1, 16'd0, 16'd0};
                else          win_clip_x = {1'b0, x0, x1 - x0};
            end
        end
    endfunction

    /* 行方向：整行落在矩形外 ⇒ 本行空窗口（不取数、不算、不写） */
    function row_out_of_clip;
        input [15:0] r;
        input        en;
        input [15:0] cy0, cy1;
        begin
            row_out_of_clip = en && ((r < cy0) || (r >= cy1));
        end
    endfunction

    /* 掩码关掉时喂给窗口计算的是全 0 ⇒ 4 个行带都是整行 */
    wire [15:0] mask_eff = cur_msk_on ? cur_mask : 16'd0;
    wire [32:0] wb0 = win_band(mask_eff[3:0],   cur_W, col_t1, col_t2, col_t3);
    wire [32:0] wb1 = win_band(mask_eff[7:4],   cur_W, col_t1, col_t2, col_t3);
    wire [32:0] wb2 = win_band(mask_eff[11:8],  cur_W, col_t1, col_t2, col_t3);
    wire [32:0] wb3 = win_band(mask_eff[15:12], cur_W, col_t1, col_t2, col_t3);
    /* ★S5：与 scissor 的列区间求交（未启用 ⇒ 逐位原样，见 win_clip_x） */
    wire [32:0] wb0c = win_clip_x(wb0, cur_clip_en, cur_cx0, cur_cx1);
    wire [32:0] wb1c = win_clip_x(wb1, cur_clip_en, cur_cx0, cur_cx1);
    wire [32:0] wb2c = win_clip_x(wb2, cur_clip_en, cur_cx0, cur_cx1);
    wire [32:0] wb3c = win_clip_x(wb3, cur_clip_en, cur_cx0, cur_cx1);

    /* 注：S3 起"本行取多少个字节"由**行窗口**决定（blt_addr_gen 的 win_w），
     * 原来的 row_bytes = 2*W 已不再需要单独保存。 */

    /* ---------------- 行流水指针 ---------------- */
    reg [15:0] issue_r;        // 下一笔要发突发/正在发突发的行（"发送指针"）
    reg [15:0] proc_r;         // 正在（或即将）交像素通路处理的行（"处理指针"）
    reg [15:0] bi_fg, bi_bg;   // 本行已发出的 fg/bg 突发序号
    reg        pp_run;         // 像素通路本行已启动
    reg [15:0] dr_fg, dr_bg;   // 行尾待丢字数

    /* ★S3：行号 → 行带号（必须在 issue_r/proc_r 声明之后，纯比较逻辑） */
    wire [1:0]  rt_i  = (issue_r >= row_t3) ? 2'd3 :
                        (issue_r >= row_t2) ? 2'd2 : (issue_r >= row_t1) ? 2'd1 : 2'd0;
    wire [1:0]  rt_p  = (proc_r  >= row_t3) ? 2'd3 :
                        (proc_r  >= row_t2) ? 2'd2 : (proc_r  >= row_t1) ? 2'd1 : 2'd0;
    wire [1:0]  rt_in = ((issue_r + 16'd1) >= row_t3) ? 2'd3 :
                        ((issue_r + 16'd1) >= row_t2) ? 2'd2 :
                        ((issue_r + 16'd1) >= row_t1) ? 2'd1 : 2'd0;
    wire [1:0]  rt_pn = ((proc_r  + 16'd1) >= row_t3) ? 2'd3 :
                        ((proc_r  + 16'd1) >= row_t2) ? 2'd2 :
                        ((proc_r  + 16'd1) >= row_t1) ? 2'd1 : 2'd0;

    reg [31:0] cyc_cnt;        // 指令周期计数（PERF）

    /* ---------------- ★S5（v3.2）属性侧口 / scissor ----------------
     * 属性字（ATTR_PORT 0x8C）在**每条命令起始**（ST_DEC）按 FIFO 顺序弹一个：
     *   · FIFO 非空 → 弹队头、用它；
     *   · FIFO 为空 → 用 ATTR_DEFAULT（**兼容档**）且**不弹**（pop 只在非空时拉高）。
     * 锁存之后整条命令都用这一份（`cur_attr`）⇒ 软件在命令中途继续写属性也不会
     * 撕裂正在画的命令：那些字只会配给后面的命令。
     *
     * ATTR_DEFAULT：blend_mode=0 / src_format=0（RGB565）/ global_alpha=255 / flags=0。
     * 按冻结位域逐位展开 = 32'h0000_3FC0。规格书写的 "0x0000_00FF" 是**语义**
     * （低字节 255 = 不淡）；若软件真的写 0x0000_00FF，其 blend_mode=0xF 落进
     * "保留 ⇒ 按 0" ⇒ 混合关闭 ⇒ 整字惰性 ⇒ 同样逐位兼容。两条路都通。 */
    localparam [31:0] ATTR_DEFAULT = 32'h0000_3FC0;
    reg  [31:0] cur_attr;
    reg         cur_blend;

    /* 属性解码（组合，与 pixel_path 里的解码逐字同源；保留编码一律按 0） */
    wire [31:0] attr_sel   = attr_empty ? ATTR_DEFAULT : attr_dout;
    wire [3:0]  at_bmode   = (attr_sel[3:0] <= 4'd3) ? attr_sel[3:0] : 4'd0;
    wire        at_blend   = (at_bmode != 4'd0);

    wire need_fg = (cur_op != 2'd1);                 // FILL 除外
    /* ★S5：逐像素混合需要**目的像素当背景** ⇒ 混合命令（blend_mode != 0）与 ALPHA
     * 一样要读 bg 流（bg 流就是 dst 行，地址生成/突发/drain 口径全部复用）。
     * cur_blend=0（默认）时本式与改动前逐字相同。 */
    wire need_bg = (cur_op == 2'd2) || cur_blend;    // ALPHA 或"属性混合"才读背景

    /* ---------------- 地址生成（组合） ----------------
     * issue 侧（给发送指针）与 proc 侧（给处理指针）各一套：
     * 两者相差一行，必须能同时取值，否则行级重叠无从谈起。
     * ★S3：每套的 win_x0/win_w = **本行的绘制窗口**（发送侧用 iw_*，处理侧用 pw_*；
     *   掩码关闭时恒为 0 / cur_W ⇒ 与 S2 逐位相同）。 */
    wire [31:0] s_rs_i, s_ab_i, d_rs_i, d_ab_i;
    wire [3:0]  s_bo_i, d_bo_i;
    wire [2:0]  s_sk_i, d_sk_i;
    wire [15:0] s_cv_i, d_cv_i;
    wire [31:0] s_rs_p, s_ab_p, d_rs_p, d_ab_p;
    wire [3:0]  s_bo_p, d_bo_p;
    wire [2:0]  s_sk_p, d_sk_p;
    wire [15:0] s_cv_p, d_cv_p;

    blt_addr_gen u_src_i (
        .base(cur_sa), .stride(cur_ss), .row(issue_r),
        .win_x0(iw_x0), .win_w(iw_w),
        .row_start(s_rs_i), .aligned_base(s_ab_i), .byte_off(s_bo_i),
        .px_skip(s_sk_i), .cover_beats(s_cv_i)
    );
    blt_addr_gen u_dst_i (
        .base(cur_da), .stride(cur_ds), .row(issue_r),
        .win_x0(iw_x0), .win_w(iw_w),
        .row_start(d_rs_i), .aligned_base(d_ab_i), .byte_off(d_bo_i),
        .px_skip(d_sk_i), .cover_beats(d_cv_i)
    );
    blt_addr_gen u_src_p (
        .base(cur_sa), .stride(cur_ss), .row(proc_r),
        .win_x0(pw_x0), .win_w(pw_w),
        .row_start(s_rs_p), .aligned_base(s_ab_p), .byte_off(s_bo_p),
        .px_skip(s_sk_p), .cover_beats(s_cv_p)
    );
    blt_addr_gen u_dst_p (
        .base(cur_da), .stride(cur_ds), .row(proc_r),
        .win_x0(pw_x0), .win_w(pw_w),
        .row_start(d_rs_p), .aligned_base(d_ab_p), .byte_off(d_bo_p),
        .px_skip(d_sk_p), .cover_beats(d_cv_p)
    );

    /* ---------------- 发送侧（组合，valid/ready 握手） ---------------- */
    wire [15:0] nbfg = (s_cv_i + 16'd15) >> 4;      // 本行 fg 突发数
    wire [15:0] nbbg = (d_cv_i + 16'd15) >> 4;      // 本行 bg 突发数（ALPHA）
    wire        fg_left = need_fg && (bi_fg < nbfg);
    wire        bg_left = need_bg && (bi_bg < nbbg);

    wire        in_range  = (issue_r < cur_H) && (issue_r <= (proc_r + 16'd1));
    wire        issue_en  = (st == ST_EXEC) && (rstate == RS_LOOP) && in_range &&
                            (fg_left || bg_left);
    wire [15:0] left_beats = fg_left ? (s_cv_i - (bi_fg << 4))
                                     : (d_cv_i - (bi_bg << 4));
    wire [7:0]  burst_beats = (left_beats > 16'd16) ? 8'd16 : left_beats[7:0];
    wire [31:0] burst_addr  = (fg_left ? s_ab_i : d_ab_i) +
                              (fg_left ? (bi_fg << 8) : (bi_bg << 8));  // 每突发 16 拍×16B

    assign rd_req  = issue_en && rd_ready;          // 同拍握手：发一笔
    assign rd_addr = burst_addr;
    assign rd_len  = burst_beats;
    assign rd_bg   = ~fg_left;                      // fg 优先，其次 bg

    /* 本行突发是否已全部发出（用于推进发送指针） */
    wire row_issued = !fg_left && !bg_left;

    /* 像素通路启动条件：本行词已到 ≥1 个，且本行突发已全部发出 */
    wire row0_ready = (!need_fg || !fg_empty) &&
                      (!need_bg || !bg_empty);
    wire can_start  = (st == ST_EXEC) && (rstate == RS_LOOP) && !pp_run &&
                      (proc_r < cur_H) && (issue_r > proc_r) && row0_ready;

    /* ---------------- 输出 ---------------- */
    assign busy_out = (st != ST_IDLE);
    /* 完成判据（本次改动）：除了"wd 看起来空 + 写主机不忙"，还必须 wr_commit_idle
     * —— wd FIFO 真空 且 写主机空闲 且 没有已受理未回 B 的写突发。
     * 这样 STATUS.BUSY=0 / DONE 才真的等于"本条指令的像素已被内存系统受理"，
     * 下一条指令的写与读（ALPHA/KEY 的 dst、COPY 的 src）都不会抢在它前面。
     * wd_empty 是输出寄存器有效位（同步读流水，比真空晚 2~3 拍），所以必须并上
     * wr_commit_idle 里的 count==0，否则最后那个写词还没进 AXI 就会判完成。 */
    assign done_out = (st == ST_IDLE) && (cmd_wcount < 12'd8) && wd_empty &&
                      !wd_busy && wr_commit_idle && !err_out;

    /* 组合弹字脉冲：POP 状态下"有字可读"即弹（同拍读 dout + 拉 rd_en） */
    assign cmd_pop = (st == ST_POP) && !cmd_empty;

    /* ★v2.10 命令末尾冲刷提示（见端口注释）：本命令的最后一行做完、进 WDWAIT 即有效。
     * 为什么用 ST_WDWAIT 而不是"最后一个词落进 wd FIFO"：引擎在这一刻就已经**确定**
     * 不会再有写词（像素通路已交回、行指针到头），而尾词从"落 staging → wd_wr →
     * FIFO 写 mem → 可读"还要 3~4 拍；写主机侧用 TAIL_GRACE 兜这几拍，不必把
     * pixel_path 的内部流水引出来。 */
    assign wr_cmd_end = (st == ST_WDWAIT);

    /* ---------------- 主状态机 ---------------- */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st        <= ST_IDLE;
            rstate    <= RS_INIT;
            pcnt      <= 4'd0;
            fg_drain  <= 1'b0;
            bg_drain  <= 1'b0;
            pp_start  <= 1'b0;
            err_out   <= 1'b0;
            pp_run    <= 1'b0;
            issue_r   <= 16'd0;
            proc_r    <= 16'd0;
            bi_fg     <= 16'd0;
            bi_bg     <= 16'd0;
            dr_fg     <= 16'd0;
            dr_bg     <= 16'd0;
            cur_op    <= 2'd0;
            dbg_opword<= 32'd0;
            cyc_cnt   <= 32'd0;
            perf_cycles<= 32'd0;
            cur_mask  <= 16'd0;
            cur_msk_on<= 1'b0;
            wt_e      <= 4'd0;
            iw_x0 <= 16'd0; iw_w <= 16'd0; iw_e <= 1'b0;
            pw_x0 <= 16'd0; pw_w <= 16'd0; pw_e <= 1'b0;
            /* ★S5：属性/scissor 复位为"不生效" */
            cur_attr   <= ATTR_DEFAULT;
            cur_blend  <= 1'b0;
            attr_pop   <= 1'b0;
            pp_attr    <= ATTR_DEFAULT;
            pp_blend   <= 1'b0;
            cur_cx0 <= 16'd0; cur_cx1 <= 16'd0;
            cur_cy0 <= 16'd0; cur_cy1 <= 16'd0;
            cur_clip_en <= 1'b0;
            for (k = 0; k < 4; k = k + 1) begin
                wt_x0[k] <= 16'd0; wt_w[k] <= 16'd0;
            end
        end else begin
            fg_drain  <= 1'b0;
            bg_drain  <= 1'b0;
            pp_start  <= 1'b0;
            attr_pop  <= 1'b0;               // ★S5：弹出脉冲只拉 1 拍

            /* 指令周期计数：从进入 POP 到 WDWAIT 结束 */
            if (st == ST_IDLE) begin
                if (go && !err_out && cmd_wcount >= 12'd8)
                    cyc_cnt <= 32'd1;
            end else
                cyc_cnt <= cyc_cnt + 32'd1;

            case (st)
                ST_IDLE: begin
                    if (go && !err_out && cmd_wcount >= 12'd8) begin
                        st   <= ST_POP;
                        pcnt <= 4'd0;            // 下一拍进入 POP，由 cmd_pop 组合弹字
                    end
                end

                ST_POP: begin
                    /* **组合**弹字：本拍"读 cmd_dout + 置 rd_en"同拍生效，
                     * 否则 pop 要下一拍才生效，同一个字会被锁存两次。
                     * 有字才弹（同步读 FIFO 约 1 字/2 拍，8 字 ≈ 16 拍，可忽略）。 */
                    if (cmd_pop) begin
                        case (pcnt)
                            4'd0: w0 <= cmd_dout;
                            4'd1: w1 <= cmd_dout;
                            4'd2: w2 <= cmd_dout;
                            4'd3: w3 <= cmd_dout;
                            4'd4: w4 <= cmd_dout;
                            4'd5: w5 <= cmd_dout;
                            4'd6: w6 <= cmd_dout;
                            4'd7: w7 <= cmd_dout;
                        endcase
                        if (pcnt == 4'd7) begin
                            st   <= ST_DEC;      // 下一拍再译码（用稳定值）
                            pcnt <= 4'd0;
                        end else
                            pcnt <= pcnt + 4'd1;
                    end
                end

                ST_DEC: begin
                    dbg_opword <= w0;
                    cur_op     <= w0[1:0];
                    cur_sa     <= w1;
                    cur_da     <= w2;
                    cur_ss     <= w3;
                    cur_ds     <= w4;
                    cur_W      <= w5[15:0];
                    cur_H      <= w5[31:16];
                    cur_alpha  <= w6[7:0];
                    cur_color  <= w7[15:0];
                    /* ★S3：掩码与生效判据一起锁存（msk_dec 是 w0/w5 的纯组合） */
                    cur_mask   <= w0[31:16];
                    cur_msk_on <= msk_dec;
                    /* ★S5：属性字**按序弹一个**（空 FIFO 用默认字，且不弹）；
                     * scissor 四边界 + 使能也在这一刻锁存（命令起始）。 */
                    cur_attr   <= attr_sel;
                    cur_blend  <= at_blend;
                    if (!attr_empty) attr_pop <= 1'b1;
                    cur_cx0 <= clip_x0; cur_cx1 <= clip_x1;
                    cur_cy0 <= clip_y0; cur_cy1 <= clip_y1;
                    cur_clip_en <= clip_en_eff;
                    if (w0[1:0] > 2'd3) begin
                        err_out <= 1'b1;         // 非法 op：停机
                        st      <= ST_IDLE;
                    end else if (w5[15:0] == 16'd0 || w5[31:16] == 16'd0) begin
                        st      <= ST_IDLE;      // 空矩形：跳过
                    end else begin
                        st      <= ST_EXEC;
                        rstate  <= RS_INIT;
                        proc_r  <= 16'd0;
                        issue_r <= 16'd0;
                        bi_fg   <= 16'd0;
                        bi_bg   <= 16'd0;
                        pp_run  <= 1'b0;
                    end
                end

                ST_EXEC: begin
                    case (rstate)
                        RS_INIT: begin
                            pp_op    <= cur_op;
                            pp_width <= cur_W;
                            pp_alpha <= cur_alpha;
                            pp_color <= cur_color;
                            pp_key   <= cur_color;
                            /* ★S5：属性字下发给像素通路（整条命令恒定） */
                            pp_attr  <= cur_attr;
                            pp_blend <= cur_blend;
                            dr_fg    <= 16'd0;
                            dr_bg    <= 16'd0;
                            pp_run   <= 1'b0;
                            /* ★S3：一拍把 4 个行带的窗口算出来（掩码关闭时 4 个 = 整行），
                             * 并把发送/处理指针的窗口都置成行带 0（两指针此刻都在行 0）。
                             * ★S5：每个行带窗口再与 scissor 的**列区间**求交
                             * （[cx0,cx1)，未启用 ⇒ 逐位原样）；行方向由下面的
                             * row_out_of_clip() 在每次"换行"时判成空窗口。 */
                            wt_e    <= {wb3c[32], wb2c[32], wb1c[32], wb0c[32]};
                            wt_x0[0]<= wb0c[31:16]; wt_w[0] <= wb0c[15:0];
                            wt_x0[1]<= wb1c[31:16]; wt_w[1] <= wb1c[15:0];
                            wt_x0[2]<= wb2c[31:16]; wt_w[2] <= wb2c[15:0];
                            wt_x0[3]<= wb3c[31:16]; wt_w[3] <= wb3c[15:0];
                            iw_e    <= wb0c[32] | row_out_of_clip(16'd0, cur_clip_en, cur_cy0, cur_cy1);
                            iw_x0   <= wb0c[31:16]; iw_w <= wb0c[15:0];
                            pw_e    <= wb0c[32] | row_out_of_clip(16'd0, cur_clip_en, cur_cy0, cur_cy1);
                            pw_x0   <= wb0c[31:16]; pw_w <= wb0c[15:0];
                            pp_width<= wb0c[15:0];
                            /* 不需要取数的（FILL）直接把发送指针放到末尾 */
                            issue_r  <= (need_fg || need_bg) ? 16'd0 : cur_H;
                            rstate   <= RS_LOOP;
                        end

                        RS_LOOP: begin
                            /* (1) 发突发：有信用就连发；每拍最多 1 笔 */
                            if (rd_req && rd_ready) begin
                                if (fg_left)
                                    bi_fg <= bi_fg + 16'd1;
                                else
                                    bi_bg <= bi_bg + 16'd1;
                            end

                            /* (2) 本行突发发完 → 发送指针推进一行（窗口跟着换行带） */
                            if (in_range && row_issued) begin
                                issue_r <= issue_r + 16'd1;
                                bi_fg   <= 16'd0;
                                bi_bg   <= 16'd0;
                                /* ★S5：行方向 scissor —— 整行在矩形外 ⇒ 空窗口
                                 * （不发突发、不算、不写，见 (3a)） */
                                iw_e    <= wt_e[rt_in] |
                                           row_out_of_clip(issue_r + 16'd1, cur_clip_en, cur_cy0, cur_cy1);
                                iw_x0   <= wt_x0[rt_in];
                                iw_w    <= wt_w[rt_in];
                            end

                            /* (3a) ★S3：本行窗口为空（整带全透明）⇒ 这一行不取数、
                             * 不算、不写，直接把处理指针推过去。门控与 (3b) 同源，
                             * 只是**不要求 FIFO 里有词**（这一行本来就没有词）。
                             * ★S5：scissor 判出的"整行在外"走的是同一条路。 */
                            if (!pp_run && (proc_r < cur_H) && (issue_r > proc_r) && pw_e) begin
                                if (proc_r == cur_H - 16'd1)
                                    st <= ST_WDWAIT;
                                else begin
                                    proc_r <= proc_r + 16'd1;
                                    pw_e   <= wt_e[rt_pn] |
                                              row_out_of_clip(proc_r + 16'd1, cur_clip_en, cur_cy0, cur_cy1);
                                    pw_x0  <= wt_x0[rt_pn];
                                    pw_w   <= wt_w[rt_pn];
                                end
                            end
                            /* (3b) 起本行：词到了就能开始算，同时继续发下一行 */
                            else if (can_start) begin
                                pp_start  <= 1'b1;
                                pp_run    <= 1'b1;
                                pp_dbase  <= d_ab_p;
                                pp_dlane0 <= d_sk_p;
                                pp_fskip  <= s_sk_p;
                                pp_bskip  <= d_sk_p;
                                pp_width  <= pw_w;      // ★S3：本行只画窗口内的像素
                                /* 行尾待丢 = 覆盖字数 − 像素通路弹走的词数（窗口口径） */
                                dr_fg <= need_fg ?
                                         (s_cv_p - (({13'd0, s_sk_p} + pw_w) >> 3)) : 16'd0;
                                dr_bg <= need_bg ?
                                         (d_cv_p - (({13'd0, d_sk_p} + pw_w) >> 3)) : 16'd0;
                            end

                            /* (4) 本行算完 → 精确 drain */
                            if (pp_row_done) begin
                                pp_run <= 1'b0;
                                rstate <= RS_DRAIN;
                            end
                        end

                        RS_DRAIN: begin
                            /* 只在"当前确实有字可弹"时计数：同步读 FIFO 的存储读有
                             * 1 拍流水，连续弹字约 1 字/2 拍，不能按拍硬数。 */
                            if (dr_fg != 16'd0 && !fg_empty) begin
                                fg_drain <= 1'b1;
                                dr_fg    <= dr_fg - 16'd1;
                            end
                            if (dr_bg != 16'd0 && !bg_empty) begin
                                bg_drain <= 1'b1;
                                dr_bg    <= dr_bg - 16'd1;
                            end
                            if (dr_fg == 16'd0 && dr_bg == 16'd0) begin
                                if (proc_r == cur_H - 16'd1) begin
                                    st <= ST_WDWAIT;
                                end else begin
                                    proc_r <= proc_r + 16'd1;
                                    /* ★S3：处理指针换行 ⇒ 窗口也跟着换行带
                                     * ★S5：并上 scissor 的行判据 */
                                    pw_e   <= wt_e[rt_pn] |
                                              row_out_of_clip(proc_r + 16'd1, cur_clip_en, cur_cy0, cur_cy1);
                                    pw_x0  <= wt_x0[rt_pn];
                                    pw_w   <= wt_w[rt_pn];
                                    rstate <= RS_LOOP;
                                end
                            end
                        end

                        default: rstate <= RS_INIT;
                    endcase
                end

                ST_WDWAIT: begin
                    /* 指令边界屏障：必须写通路彻底干净（wd FIFO 真空 + 无在飞突发
                     * + 所有 B 都已回）才能进 IDLE、才允许 pop 下一条指令。
                     * 判据交给顶层的 wr_commit_idle（见 blt_top.v 的说明）。 */
                    if (wd_empty && !wd_busy && wr_commit_idle) begin
                        perf_cycles <= cyc_cnt;      // 锁存本条指令耗时
                        st <= ST_IDLE;
                    end
                end

                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
