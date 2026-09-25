/* =========================================================================
 * axi_wr_master.v — AXI4 主机写通道（INCR 突发，合并相邻写词）
 * -------------------------------------------------------------------------
 * 消费上层 wd FIFO 中的 176bit 写词 {mask[15:0], addr[31:0], data[127:0]}：
 *   - 相邻（addr 连续 +16B）的词合并成一笔 INCR 突发（≤MAX_BEATS 拍）
 *   - 掩码逐拍直通（首尾/键控留孔的词允许在突发中间，WSTRB 不写）
 *   - 地址不连续 / 突发满 / 4KB 边界 / FIFO 真空 / 命令结束 时冲刷
 *
 * 写提交跟踪（新增，给引擎做指令边界屏障用）：
 *   b_pending = 已受理 AW、还没收到 B 的写突发数。本主机是 AW→W→B 串行
 *   （S_B 必须等到 B 才回 S_IDLE、才可能发下一笔 AW），所以它恒为 0/1 ——
 *   "同一时刻最多一笔写突发在飞"是**结构保证**，不是靠时序凑出来的。
 *   wr_idle_committed = (b_pending==0) && 本状态机空闲 = 这条写通道上再也没有
 *   未回 B 的写。引擎用它（再并上 wd FIFO 真空）作为一条指令的完成判据，
 *   这样"引擎 IDLE / STATUS.BUSY=0"才等价于"这条指令的写已经被内存系统受理"。
 * ========================================================================= */
/* ★v2.9 突发合并真正生效：合并判据换成"dout 上真有新词"（dout_v + cnt_more）
 * -------------------------------------------------------------------------
 * 症状（只读探针 rtl/tb/tb_perf_probe.v 实测，见 doc/perf_probe_report.md §4）：
 *   BitBlt 所有算子 burst_max=1、AW_top == 16B 词数（整屏 FILL 64,800 笔），
 *   写主机 8 拍/词 —— 16 拍合并**从来没触发过**；只有背靠背生产者的清屏引擎
 *   能合并（tb_blt_top T10：2 笔 AW）。
 *
 * 根因（三层，前两条都在"判据"上，第三条在"愿不愿意等"上）：
 *   1) 旧判据用 `!wd_empty`。empty = !out_v（输出寄存器有效位），而 sync_fifo 是
 *      "同步读 + 输出寄存器"：**弹字后的那一拍 out_v=0**（下一拍才从 BRAM 取回），
 *      这一拍 empty=1 而 FIFO 里其实还有字 ⇒ S_BUF 当拍判"断开"、立刻冲刷。
 *   2) 只把判据换成 wd_count 仍然不够：count 口径 = mcnt + rd_pend + out_v，其中
 *      mcnt 是**还压在 BRAM 里**的字。弹字后那一拍 out_v=0、dout 仍是上一个词的
 *      旧值，但 mcnt 可能 >0 ⇒ wd_count 仍 >1 ⇒ 误判"有新词"，于是拿**旧的 e_addr**
 *      去比连续性 → 必然不连续 → 每词一笔 AW。定位时加的临时计数器实测：稳态
 *      960x54 FILL 共发车 4,813 笔，其中 4,783 笔判成"地址不连续"（真跳变只有
 *      几十笔）—— 稳态下几乎每个突发都是这样被切碎的。
 *      正确口径必须把两件事分开：
 *        dout_v    = (wd_count != 0) && !wd_empty  ⇔ out_v：本拍 dout 上是**没被
 *                    消费的新词**
 *        cnt_more  = 吃掉队头之后后面还有货（mem/在飞/输出寄存器里还有）
 *      ⇒ word_here = dout_v && cnt_more 才是"能并进突发的新词"。
 *   3) 判据对了还必须**愿意等**：像素通路 8 拍/词、合并后写主机很快
 *      ⇒ FIFO 长年只有 1 个词，"下一拍没有新词"是稳态常态。所以 S_BUF 要等：
 *      等不到新词就计数，连续 HOLD_MAX 拍都等不到 → 判为地址跳变或命令结束。
 *      HOLD_MAX 必须 > 像素通路的词间隔（8 拍），否则连续的流会被切碎退化成
 *      "每词一笔 AW"；取 16 = 2×词间隔。
 *
 * 实测（960x540 FILL，探针）：AW 64,800 → 4,051 笔、burst_avg 1.000 → 15.996、
 * 写主机在 AXI 事务上的活跃拍数/词 8.0 → 1.13（= (18×16 + 4)/16 ≈ 18.25 拍/笔）。
 *
 * A/B 逃生门：-DWR_MERGE_HOLD_OFF 恢复改前的行为（S_BUF 只看 !wd_empty、不等）。
 * 实测该模式下探针逐字节回到改前读数（520,588 拍 / AW_top 64,800 / burst_max=1），
 * 用来证明"位精确与顺序不变，只有 AW 笔数与写侧拍数在变"。
 * 不变的东西：AW→W→B 序列与单笔在飞结构、b_pending / wr_idle_committed /
 * wr_commit_idle 的语义、引擎 FSM 的 ST_WDWAIT / done_out、非对齐/半词的字节
 * 掩码语义（bmask 仍是逐拍 16bit WSTRB 直通）。
 * ========================================================================= */
module axi_wr_master #(
    parameter AXI_DATA_W = 128,
    parameter MAX_BEATS  = 16,
    /* S_BUF 里"连续多少拍没有下一个词"就判定为地址跳变 / 命令结束（见文件头）。
     * 做成参数只为便于扫描取值；综合时按默认 16 静态展开，无额外逻辑。 */
    parameter [7:0] HOLD_MAX = 8'd16,
    /* ★v2.10 尾模式（cmd_end_flush 有效）下，"wd FIFO 已排空"之后最多再等几拍。
     * 等的是"刚写进 FIFO、还在同步读流水里"的那个尾词：sync_fifo 从 do_wr 到
     * dout 有效要 3 拍（写 mem → mcnt+1 → rd_pend → out_v），再加上引擎进入
     * ST_WDWAIT 可能比尾词真正入队早 1~2 拍，取 4 拍留 1 拍余量。 */
    parameter [3:0] TAIL_GRACE = 4'd4
)(
    input  wire                    clk,
    input  wire                    rst_n,

    /* ---- wd FIFO 侧 ---- */
    input  wire                    wd_empty,
    input  wire [4:0]              wd_count,   // ★v2.9 wd FIFO **真实**占用（sync_fifo 的 count 口径）
    input  wire [175:0]            wd_dout,    // {mask, addr, data}
    output wire                    wd_pop,
    output wire                    wd_busy,    // 突发未结束（含等 B）

    /* ---- ★v2.10 命令末尾冲刷提示（引擎侧） ---- */
    input  wire                    cmd_end_flush, // 高 = 本命令再也不会产出写词（引擎在 ST_WDWAIT）

    /* ---- 写提交跟踪（给引擎的指令边界屏障） ---- */
    output wire [4:0]              b_pending,        // 已发 AW、未回 B 的突发数
    output wire                    wr_idle_committed, // b_pending==0 且本机空闲

    /* ---- AXI4 写口 ---- */
    output wire [31:0]             m_axi_awaddr,
    output wire [7:0]              m_axi_awlen,
    output wire [2:0]              m_axi_awsize,
    output wire [1:0]              m_axi_awburst,
    output wire                    m_axi_awvalid,
    input  wire                    m_axi_awready,
    output wire [AXI_DATA_W-1:0]   m_axi_wdata,
    output wire [AXI_DATA_W/8-1:0] m_axi_wstrb,
    output wire                    m_axi_wlast,
    output wire                    m_axi_wvalid,
    input  wire                    m_axi_wready,
    input  wire                    m_axi_bvalid,
    input  wire [1:0]              m_axi_bresp,
    output wire                    m_axi_bready
);
    localparam S_IDLE = 3'd0;
    localparam S_BUF  = 3'd1;    // 收集相邻词
    localparam S_AW   = 3'd2;
    localparam S_W    = 3'd3;
    localparam S_B    = 3'd4;

    /* S_BUF 等待上限 = 端口参数 HOLD_MAX（默认 16，理由见模块头注释） */
`ifdef WR_MERGE_HOLD_OFF
    localparam MERGE_HOLD_EN = 1'b0;          // A/B 对照：恢复旧行为（只看 !wd_empty）
`else
    localparam MERGE_HOLD_EN = 1'b1;
`endif

/* ★v2.10 命令末尾冲刷提示（cmd_end_flush）
 * -------------------------------------------------------------------------
 * 症状（只读探针 rtl/tb/tb_perf_probe.v 实测，见 doc/perf_probe_report.md §4 的
 * 2026-09 更新）：合并不但把 AW 从 64,800 降到 4,051，还**给每条命令加了 +52 拍
 * 的常数尾巴** —— 32x32 FILL 1,180 → 1,232 拍（孤立与背靠背都是 +52，整屏
 * 520,588 → 520,640 也是 +52），全部落在引擎的 ENG_WDWAIT 桶（10 → 63 拍）。
 *
 * 根因：合并的等待窗口对"命令的最后一个词"完全不适用，而且叠了两层 ——
 *   1) cnt_more 的保守判据（"队头之后还有货"）在命令末尾永远不成立：最后一个词
 *      孤零零待在 FIFO 里（wd_count==1），于是它**并不进当前突发**，白等满
 *      HOLD_MAX=16 拍才发车；
 *   2) 那个尾词随后被 S_IDLE 取走、自成一笔突发，而它后面当然也没有词，
 *      于是**又等满 16 拍**才冲刷；
 *   3) 两笔突发的 AW→W→B 本身还要串起来发（单笔在飞结构），首尾相加就是 63 拍。
 * 而引擎在 ST_WDWAIT 里等的正是这串尾活（wr_commit_idle），所以 +52 全记在
 * 它头上；OFF 模式（每词一笔 AW、不合并）没有这个窗口，尾活只有 10 拍。
 *
 * 修法：引擎在进入 ST_WDWAIT 时给出"本命令再也不会产出写词"的提示，写主机据此
 * 进"尾模式"：
 *   · 放宽 word_here（不再要求 cnt_more）⇒ 尾词能并进当前突发；
 *   · 排空判据从"等满 HOLD_MAX"换成"wd_count==0 后再等 TAIL_GRACE 拍"⇒ 立刻发车。
 * 提示只影响**什么时候冲刷**：AW→W→B 的顺序、单笔在飞、b_pending /
 * wr_idle_committed / wr_commit_idle 的语义、引擎 ST_WDWAIT / done_out 的判据
 * 全部不变；即便提示来早了，最坏也只是把突发切碎（退化成 OFF 模式的节拍），
 * 不会丢词、不会乱序 —— 它是提示，不是数据通路的使能。
 *
 * A/B 逃生门：-DWR_CMD_END_FLUSH_OFF 逐字回到 v2.9 行为（1,232 拍 / ENG_WDWAIT 63）。
 * 提示依赖合并窗口才存在，所以 MERGE_HOLD_OFF（不合并）下自动关掉，
 * 保证 -DWR_MERGE_HOLD_OFF 的读数仍与改前逐字节一致。 */
`ifdef WR_CMD_END_FLUSH_OFF
    localparam CMD_END_FLUSH_EN = 1'b0;
`else
    localparam CMD_END_FLUSH_EN = MERGE_HOLD_EN;
`endif

    reg [2:0]           st;
    reg [31:0]          burst_addr;
    reg [7:0]           burst_len;                       // 已收集拍数 1..
    reg [AXI_DATA_W-1:0] bdata [0:MAX_BEATS-1];
    reg [AXI_DATA_W/8-1:0] bmask [0:MAX_BEATS-1];
    reg [7:0]           wcnt;                            // 已发数据拍
    reg [7:0]           hold_max;                        // S_BUF 连续无新词的拍数
    reg [3:0]           tail_wait;                       // ★v2.10 尾模式"FIFO 已排空"的连续拍数

    wire [15:0]  e_mask = wd_dout[175:160];
    wire [31:0]  e_addr = wd_dout[159:128];
    wire [AXI_DATA_W-1:0] e_data = wd_dout[AXI_DATA_W-1:0];

    assign wd_busy = (st != S_IDLE);

    /* ---- 写提交跟踪：AW 受理 +1、B 回 −1 ----
     * 减法的 0 保护：正常情况下每个 B 都对应一笔已受理的 AW；万一 B 被错路/多发
     * （历史上 axi_wr_arb 出过这类问题），也只会让计数停在 0，不会回绕成 31
     * 而把引擎的完成判据永久卡死。 */
    wire aw_hs = m_axi_awvalid && m_axi_awready;
    wire b_hs  = m_axi_bvalid  && m_axi_bready;
    reg [4:0] b_pending_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            b_pending_r <= 5'd0;
        else
            b_pending_r <= b_pending_r + (aw_hs ? 5'd1 : 5'd0)
                                        - ((b_hs && (b_pending_r != 5'd0)) ? 5'd1 : 5'd0);
    end

    assign b_pending         = b_pending_r;
    assign wr_idle_committed = (b_pending_r == 5'd0) && (st == S_IDLE);

    /* ---- 本次合并判据（组合） ----
     * ★关键：**两件事必须分开判**
     *   (a) "本拍 dout 上真的有一个**没被消费**的新词" → dout_v
     *   (b) "把队头这个词吃掉之后，后面还有货"        → cnt_more
     * 只用 wd_count 会把这两件事混在一起：count 口径是 mcnt + rd_pend + out_v，
     * 其中 mcnt 是**还压在 BRAM 里**的字。弹字后的那一拍 out_v=0（输出寄存器空窗、
     * dout 仍是上一个词的旧值），但 mcnt 可以 >0 ⇒ wd_count 仍然 >1 ⇒ 误判"有新词"，
     * 于是拿**旧的 e_addr** 去做连续性比较 → 比较失败 → 每词一笔 AW（定位时加的
     * 临时计数器实测：稳态 960x54 FILL 里 4,783 次发车全是这个原因）。
     * dout_v = (count!=0) && !empty = out_v：只有它为 1 时 dout 才是可捕获的新词。
     * （empty=!out_v，二者不会同拍冲突，纯组合，无额外寄存器。） */
    wire dout_v    = (wd_count != 5'd0) && !wd_empty;
    wire take_head = (burst_len != 8'd0);                   // 队头词已被本突发吃掉了
    wire cnt_more  = take_head ? (wd_count > 5'd1)          // 除队头外还有词（mem/在飞/输出寄存器）
                               : (wd_count != 5'd0);
    /* ★v2.10 尾模式（引擎在 ST_WDWAIT）：cnt_more 的"后面还有货"判据在命令末尾
     * 永远不成立（最后一个词孤零零待在 FIFO 里），会把尾词挡在突发之外。此处放宽成
     * 只看 dout_v —— 它本来就排掉了弹字后的空窗（那 1 拍 out_v=0、dout 还是旧词），
     * 所以 dout_v=1 就意味着 dout 上是**没被消费的新词**，并进来绝不会重复计数。 */
    wire tail_mode = CMD_END_FLUSH_EN && cmd_end_flush;
    wire word_here = dout_v && (tail_mode || cnt_more);     // dout 上确实是一个能并进突发的新词
    wire [31:0] next_addr = burst_addr + {16'd0, burst_len} * 16'd16;
    /* 4KB 边界：AXI 不允许一笔 INCR 跨越 4KB 地址边界（下一拍地址的低 12bit
     * 必须仍在本页内；回绕即跨页） */
    wire page_ok = ((burst_addr[11:0] + {burst_len, 4'd0}) >= burst_addr[11:0]);
    /* 突发扩展（本拍到底并进下一个词没有）：需要一个**真的在 dout 上的新词**
     * （word_here：dout_v 排掉弹字后的空窗 + cnt_more 保证队头之后还有货）、
     * 地址连续、不跨 4KB、没到 MAX_BEATS、也没被 A/B 逃生门关掉。 */
    wire merge_ok = MERGE_HOLD_EN && word_here && page_ok &&
                    (burst_len < MAX_BEATS) && (next_addr == e_addr);

    /* 空闲且 FIFO 非空 → 取首词进缓冲 */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st         <= S_IDLE;
            burst_addr <= 32'd0;
            burst_len  <= 8'd0;
            wcnt       <= 8'd0;
            hold_max   <= 8'd0;
            tail_wait  <= 4'd0;
        end else begin
            case (st)
                S_IDLE: begin
                    if (!wd_empty) begin
                        bdata[0]   <= e_data;
                        bmask[0]   <= e_mask[15:0];
                        burst_addr <= e_addr;
                        burst_len  <= 8'd1;
                        hold_max   <= 8'd0;
                        tail_wait  <= 4'd0;
                        st         <= S_BUF;
                    end
                end
                S_BUF: begin
                    /* 有下一个词（且连续、不跨 4KB、未满 16 拍）→ 并入本突发。
                     * 否则先在 S_BUF 里等：连续 HOLD_MAX 拍都没等到 → 认定
                     * 地址跳变或命令结束，冲刷发车。
                     * ★v2.10：尾模式（cmd_end_flush）下改判据，见文件头。 */
                    if (merge_ok) begin
                        bdata[burst_len] <= e_data;
                        bmask[burst_len] <= e_mask[15:0];
                        burst_len        <= burst_len + 8'd1;
                        hold_max         <= 8'd0;
                        tail_wait        <= 4'd0;
                    end else if (!word_here) begin
                        /* 本拍 dout 上没有"能并进来的新词"：两种等待口径 —— */
                        if (tail_mode) begin
                            /* 尾模式：命令已经不会再产词，别等满 HOLD_MAX。
                             *   wd_count != 0：FIFO 里还有字（1~2 拍后就读出来）→ 继续等；
                             *   wd_count == 0：真排空了 → 最多再等 TAIL_GRACE 拍给
                             *   "刚入队、还在同步读流水里"的尾词留时间，然后立刻发车。 */
                            if (wd_count != 5'd0)
                                tail_wait <= 4'd0;
                            else if (tail_wait >= TAIL_GRACE)
                                st <= S_AW;
                            else
                                tail_wait <= tail_wait + 4'd1;
                        end else if (MERGE_HOLD_EN && (hold_max < HOLD_MAX)) begin
                            hold_max <= hold_max + 8'd1;          // 再等一拍（等下一个词上 dout）
                        end else begin
                            st <= S_AW;                      // 断开/收满/等够 → 发出
                        end
                    end else begin
                        /* dout 上有新词却并不进来（地址跳变 / 跨 4KB / 已满 16 拍）
                         * → 说明本突发到此为止，立刻发车。 */
                        st <= S_AW;
                    end
                end
                S_AW: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        wcnt <= 8'd0;
                        st   <= S_W;
                    end
                end
                S_W: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        wcnt <= wcnt + 8'd1;
                        if (wcnt == burst_len - 8'd1)
                            st <= S_B;
                    end
                end
                S_B: begin
                    if (m_axi_bvalid && m_axi_bready)
                        st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end

    /* wd_pop：空闲取首词；或收集阶段并入下一个连续词。
     * ★v2.9：直接用 merge_ok（与上面 always 块**同一个信号**）—— 两者必须同拍
     * 成立，否则会出现"弹了不并入（丢词）"或"并入同一个词两次（写花）"。
     * 空闲分支用 !wd_empty 是安全的：那里 waiting 的正是"取首词进缓冲"，
     * 此时 wd_count≥1 与 out_v=1 同拍成立。 */
    assign wd_pop = ((st == S_IDLE) && !wd_empty) ||
                    ((st == S_BUF) && merge_ok);

    assign m_axi_awvalid = (st == S_AW);
    assign m_axi_awaddr  = burst_addr;
    assign m_axi_awlen   = burst_len - 8'd1;
    assign m_axi_awsize  = $clog2(AXI_DATA_W/8);
    assign m_axi_awburst = 2'b01;

    assign m_axi_wvalid  = (st == S_W);
    // W 数据：直接组合取 bdata[wcnt]（缓冲在发车时已全部就位）
    assign m_axi_wdata   = bdata[wcnt];
    assign m_axi_wstrb   = bmask[wcnt];
    assign m_axi_wlast   = (wcnt == burst_len - 8'd1);
    assign m_axi_bready  = 1'b1;
endmodule
