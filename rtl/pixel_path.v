/* =========================================================================
 * pixel_path.v — 像素通路（每行一个事务：消费 fg/bg 像素 → 打包写词）
 * -------------------------------------------------------------------------
 * - 4 种 op：COPY / FILL / KEY（键色跳过不写）/ ALPHA（定点混合）
 * - 目的侧按 16B 词打包：lane=(d_lane0+i)&7；掩码按实际写入字节置位
 * - 词在 lane==7 或行尾提交进 wd FIFO（全掩码为 0 不写 → KEY 留孔天然正确）
 * - ALPHA v1 组合乘加（后期寄存器级进 DSP，公式不变）
 *
 * ★v2.8 词提交 skid（乒乓 staging）：-DPIXEL_PACK_PINGPONG_OFF 回到旧节拍
 * ★v3.1 双 lane（2 px/拍）：-DPIXEL_PIXELS2_OFF 回到 v2.8 单 lane 行为（逐字）
 * ★v3.2（S5）属性侧口：逐像素 alpha（ARGB1555/ARGB4444）+ alpha/加算/乘法混合
 *      （两个 lane 共用一份乘加通路）；-DBLEND_OFF 把混合通路整体编掉
 * ★v3.3 关键路径切分：把整条 49 级组合锥从乘加通路入口切成两段
 *      （默认关；`-DPX_ACC_PIPE_ON` 打开，A/B 逃生门 —— 详见文件头 v3.3 一节）
 * -------------------------------------------------------------------------
 * 旧节拍：词满那一拍只置 flush_p，**下一拍是一整拍专属冲刷拍** —— 这一拍照样
 * 占着打包器的节拍，于是 9 拍/词 = 0.889 px/拍（整屏 FILL 585,387 拍里
 * 64,800 拍 = 11.07% 全花在这上面）。
 * 现在：词满那一拍把"含本像素的整词"落进 176bit staging
 * （h_acc/h_mask/h_addr/h_v），打包器**当拍清零**、下一拍就开始装下一个词；
 * staging 由一条独立推词通路在下一拍把它送进 wd FIFO。推词与像素组装并行
 * ⇒ 8 拍/词 = 1.0 px/拍。
 * wd 侧协议逐拍不变：wd_wr 仍是 1 拍寄存脉冲、wd_word 在脉冲期间稳定；而且
 * **同一个词"从词满到进 wd FIFO"的拍数也与旧冲刷完全相同** —— 旧：词满拍末置
 * flush_p、下一拍（冲刷拍）末置 wd_wr；新：词满拍末落 staging、下一拍末置 wd_wr。
 * 两者写入 FIFO 都落在"词满拍 +2"，中间那 1 拍正是被省下来的旧冲刷拍。
 * staging 兼作 wd 满时的缓冲：满时本词先在 staging 里等，最多给 wd FIFO 8 拍
 * 排空时间（旧写法是当拍就停像素）。staging 只认"空/不空"，不做同拍推空+装入
 * 的交换 —— 理由是 wd_wr 寄存一拍，交换会让两次推词决定挨在一起，第二次的
 * 写入拍可能正好撞上 FIFO full 而被静默丢弃（见 skid_ok 处的实测记录）。
 * -------------------------------------------------------------------------
 * ★v3.1 双 lane（默认开；`-DPIXEL_PIXELS2_OFF` 逐字回到 v2.8 单 lane 路径）
 * -------------------------------------------------------------------------
 * 背景（实测）：整屏 960x540 FILL = 520,588 拍 / 518,400 像素 = 0.996 px/拍，
 * 墙就是"一拍只装 1 个 16bit lane"。下游写通道早已不是瓶颈（AW 合并后
 * 1.13 拍/16B 词 ≈ 7 px/拍，见 §23），所以把打包器加宽到一拍 2 像素。
 *
 * 三条规则（改动全部落在这里与 stream_reader.v，寄存器图/命令集/FSM/扫描输出
 * /dl_fetch 一律未动）：
 *  1. **配对只在 dst 偶 lane 上做**：`two = !lane[0] && 行内还剩≥2 像素`。
 *     lane 偶 ⇒ lane+1 ≤ 7 ⇒ **一对永不跨 16B 词** ⇒ 一拍最多成 1 个词、
 *     最多推 1 个词，v2.8 的单条 staging/skid 结构与推词时序原样保留。
 *     d_lane0 为奇时行首那个像素单独走一拍，之后 i 变偶 → 全部成对；
 *     代价 = 每行最多 1 拍（整屏 540 拍 = 0.2%）。
 *  2. **词边界与掩码语义逐位不变**：word_end = (本拍末像素 lane==7) || is_last；
 *     整词全键色只进位 jw、不提交（KEY 留孔）；行尾残词照旧落 staging。
 *     两个像素各自 keep（KEY 逐像素判 key），掩码各置 2 bit。
 *  3. **ALPHA 两套并行组合乘加**：公式/抽头/量化与单 lane 版逐位相同，
 *     只是同拍算两个像素（关键路径深度不变：两组乘法互相独立）。
 *
 * 背压：`px_gate/skid_ok/push_can` 与 v2.8 逐字相同 —— 本拍要出词而 staging
 * 还没腾空就停像素（`skid_ok = !h_v`，不做同拍"推空+装入"）。词周期从 8 拍
 * 缩到 4 拍后，staging 每词的可用窗口反而更宽（推词决定之间仍至少隔 2 拍 ⇒
 * "写入拍必 !full"的结构性保证不变，不丢词、不重词）。
 * 上游：fg/bg 读取器同步加宽到 2 px/拍（stream_reader.v 的双词槽预取），
 * 否则读类算子只能到 1 px/拍；`two==1` 时两个读取器都必须能交付 2 像素
 * （`fg_rdy2/bg_rdy2`），否则整拍停顿 —— 只停一拍、不拆对，绝不丢像素。
 * -------------------------------------------------------------------------
 * ★v3.3 关键路径切分：-DPX_ACC_PIPE_ON（**默认关**的 A/B 逃生门）
 * -------------------------------------------------------------------------
 * 证据（Efinity 2026-09-16 STA，ARC_2DRA/par/ddr_demo_ti60/outflow/
 * ddr_demo_ti60.timing.rpt）：core_clk 约束 10ns 下建立余量只剩 +0.022ns，
 * 最差路径就是本模块：`u_.../u_path/u_fgr/lane[2]~FF|CLK` →
 * `u_.../u_path/acc[90]~FF|D`，Logic Level **49**、数据路径 9.846ns。49 级是
 * 这么堆起来的（同一条 report 的逐级清单，累计到达时间）：
 *   0.35~2.44  lane[2] →（LUT__91946/91962/91976/91979…91984，9 级）8:1 像素
 *              选择 `wcur[lane*16+:16]` + `sp_alpha()` 逐像素 alpha 解码
 *              + `(op==1)?255:…` 与 a444 格式 mux
 *   2.44~3.75  mult_67|A→O：`mul_sa1 = sp_alpha·ga`（EFX_DSP24）
 *   3.75~4.54  add_78：`a_div1 = (x + (x>>8) + 1)>>8`（16bit 进位链 /255）
 *   4.54~5.62  LUT__92207/92481：`qs1_r = m_a ? inva1 : 0`（含 255−A）
 *   5.62~6.94  mult_104|B→O：`q_g1 = bd_g1 · qs1_r`（第二个 DSP）
 *   6.94~7.72  add_108：`m_g = p_g1 + q_g1 + 127`
 *   7.72~9.38  ~9 级 LUT：`bl_out()`（floor(p/255) 的 `dv=(p+(p>>8)+1)>>8`、
 *              加算饱和 s2、模式 mux）+ 量化 {r[7:3],g[7:2],b[7:3]}
 *   9.38~9.98  `acc_n0/n` 的 `<< (lane*16)`（128bit 变量移位）+ OR → acc[90]|D
 * 也就是说：**两个 DSP 串在一条线上，前面还压着"像素选择+逐像素 alpha"、
 * 后面还压着"bl_out 的 /255 与移位"** —— 单拍做不完 10ns。
 *
 * 切法（一个 stage、104bit 寄存器，切在**乘加通路入口**）：
 *   stage1（组合，拍内完成）= lane→px 选择→sp_alpha→`sp_alpha·ga`→/255→
 *       A_ds/inva（≈5.3ns 估算）+ keep/配对/行尾/操作数打包进寄存器；
 *   stage2（组合）= 通道展开→sel/qs mux→两个 DSP→p+q+127→bl_out→量化→
 *       移位/OR→acc（≈4.5ns 估算）。
 * 为什么必须连"整对像素"一起搬：alpha 是**逐像素**的，只把 alpha 延迟一拍会
 * 配错像素（两个 lane 各一份），所以 lane/two/is_last/keep/源像素/目的像素都
 * 跟着延迟 ⇒ 打包器整体晚一拍消费像素（**每行多 1 拍**，见下）。
 *
 * 流水线为什么必须"前瞻"而不能"保守停顿"：像素被读侧消费后 bundle 只活一拍，
 * 若等打包器在 T+1 发现"staging 占着"再停，像素已经丢了。于是闸门改成
 * `pipe_ok`（= 下一拍打包台不会**同时**遇到"要推词"与"staging 未腾空"），
 * 其中 `h_v_nxt/aempty_nxt` 都按 always 块里的赋值优先级**逐字推导**（见
 * PX_ACC_PIPE_ON 段的注释）⇒ 前瞻是精确的，不是保守估计：
 * 任意两次推词决定之间仍至少隔 1 拍（结构性不丢词），bundle 与打包台 1:1。
 *
 * 代价（实测，日志见 doc/logs/pxpipe_*）：行末最后一个词晚一拍落 staging ⇒
 * `row_done` 晚一拍 ⇒ **每行多 1 拍**（整屏 960x540 FILL 520,588 → 521,128 拍，
 * +0.10%；读受限的算子会被 `row0_ready` 等待吸收，增量更小）。
 * 为什么不把 `row_done` 留在 stage1、让它"不晚"：那样引擎进 ST_WDWAIT 的那一拍
 * 尾词还没写进 wd FIFO，`wr_commit_idle`（blt_top 里 `wd_count==0`）会提前满足
 * ⇒ DONE 早报，v2.10 的指令边界屏障语义被破坏。留 stage2 出 row_done，才与
 * v3.2 有**同样的 1 拍余量**（尾词 do_wr 落在 WDWAIT 判据的前一拍）。
 *
 * 默认（无 -D）逐位等于 v3.2：新逻辑全部在 `ifdef PX_ACC_PIPE_ON` 里，连
 * can_pp/flush_p/flush_ok 都把原式作为 `else` 支逐字保留；stage1 那份老组合
 * 乘加通路在开关打开时不再驱动打包器（只喂层次探针），综合会整块剪掉。
 * ========================================================================= */
module pixel_path (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    output reg           busy,
    output reg           row_done,
    input  wire [1:0]    op,
    input  wire [15:0]   width,
    input  wire [31:0]   d_base,
    input  wire [2:0]    d_lane0,
    input  wire [2:0]    fg_skip,
    input  wire [2:0]    bg_skip,
    input  wire [7:0]    alpha,
    input  wire [15:0]   color,
    input  wire [15:0]   key,
    input  wire          fg_empty,      // FIFO 空标志（!empty 才保证 dout 有效）
    input  wire [127:0]  fg_dout,
    output wire          fg_rd,
    input  wire          bg_empty,
    input  wire [127:0]  bg_dout,
    output wire          bg_rd,
    input  wire          wd_full,
    output reg           wd_wr,
    output reg  [175:0]  wd_word,
    /* ---- ★S5（v3.2）属性侧口（每命令一个字，来自 blt_engine_fsm） ---- */
    input  wire          blend,          // 本命令真的走属性混合（blend_mode 已解码 != 0）
    input  wire [31:0]   attr            // 属性字：blend_mode/fmt/global_alpha/flags
);
    wire need_fg = (op != 2'd1);                 // 非 FILL
    /* ★S5：混合需要目的像素当背景（bg 流 = dst 行）⇒ 与 ALPHA 同一条读取通路。
     * 本式与 blt_engine_fsm 的 need_bg 同源（同一根 blend 线），不会各算各的。 */
    wire need_bg = (op == 2'd2) || blend;        // 仅 ALPHA / 属性混合

    /* ---------- 状态/计数器（两种模式共用） ---------- */
    localparam S_IDLE = 1'b0, S_RUN = 1'b1;
    reg        st;
    reg        clr_p;

    /* ---------- fg/bg 读取器（两种模式共用实例，内部按同一宏分叉） ---------- */
    wire fg_rdy, fg_rdy2, bg_rdy, bg_rdy2;
    wire [15:0] fg_px, fg_px2, bg_px, bg_px2;
    wire fg_take, fg_take2, bg_take, bg_take2;

    /* 本行源流的"词账"（双像素读取器靠它把弹词条数钉得与引擎 drain 口径一致）：
     *   nfull  = 会被整词消费的词数 = floor((skip+width)/8) = 像素通路该弹的词数
     *   nwords = 本行触及的词总数     = ceil((skip+width)/8)  = 载入上界
     * 引擎 RS_LOOP 的 dr_* = cover_beats − nfull 用的就是这个 nfull（同一算式）。 */
    wire [16:0] fg_sw    = {14'd0, fg_skip} + {1'b0, width};
    wire [16:0] bg_sw    = {14'd0, bg_skip} + {1'b0, width};
    wire [15:0] fg_nfull = fg_sw[16:3];
    wire [15:0] fg_nwords= fg_sw[16:3] + {15'd0, |fg_sw[2:0]};
    wire [15:0] bg_nfull = bg_sw[16:3];
    wire [15:0] bg_nwords= bg_sw[16:3] + {15'd0, |bg_sw[2:0]};

    /* 读取器的 en 用**电平**（本行处理中）而不是 1 拍启动脉冲：
     * 行级重叠后数据是边到边来的，读取器需要在本行为真的整个期间
     * 自行"缺词就等、到词就载"；行首第一个词用 skip，之后用 lane=0。 */
    stream_reader u_fgr (
        .clk(clk), .rst_n(rst_n), .clr(clr_p),
        .en((st == S_RUN) && need_fg), .skip(fg_skip),
        .fifo_empty(fg_empty), .fifo_dout(fg_dout),
        .rd_en(fg_rd), .ready(fg_rdy), .ready2(fg_rdy2),
        .px(fg_px), .px2(fg_px2),
        .take(fg_take), .take2(fg_take2),
        .nfull(fg_nfull), .nwords(fg_nwords)
    );
    stream_reader u_bgr (
        .clk(clk), .rst_n(rst_n), .clr(clr_p),
        .en((st == S_RUN) && need_bg), .skip(bg_skip),
        .fifo_empty(bg_empty), .fifo_dout(bg_dout),
        .rd_en(bg_rd), .ready(bg_rdy), .ready2(bg_rdy2),
        .px(bg_px), .px2(bg_px2),
        .take(bg_take), .take2(bg_take2),
        .nfull(bg_nfull), .nwords(bg_nwords)
    );

    /* =====================================================================
     * ★S5（v3.2）属性侧口：逐像素 alpha + 可编程混合（**两种 lane 模式共用这一份**）
     * ---------------------------------------------------------------------
     * 只有一套乘加数据通路（每个通道 2 个 8x8 乘法器/lane，与 §27 的 ALPHA 完全同量）：
     *   p = fg · sel      （sel = 乘模式的 bg，否则 = A）
     *   q = bg · (255−A)  （只有 alpha 混合模式非 0）
     *   alpha 混合 out = (p + q + 127) >> 8   ← **与 §11 的金标准算式逐位相同的写法**
     *   加算     out = min(255, floor(p/255) + bg)      （饱和）
     *   乘法     out = p >> 8                           （p = fg·bg）
     * 最后统一量化回 5/6/5（{r8[7:3],g8[7:2],b8[7:3]}，与今天同一句）。
     *
     * **兼容档为什么是"结构性"的**：`blend=0`（未写属性 / blend_mode=0 / ATTR_PORT_OFF）时
     *   · op=ALPHA ⇒ A=命令字 alpha、模式=alpha 混合 ⇒ p=f·alpha、q=bg·(255−alpha)，
     *     与旧写法是同一个算式、同一组操作数、同一量化 ⇒ 输出逐位相同；
     *   · 其余 op ⇒ case(op) 的老分支，混合通路的输出根本没被选中。
     * 也就是说"关掉新功能"不是靠旁路，而是靠新式子退化成老式子（tb_alpha 的金标准向量守着）。
     * `-DBLEND_OFF` 可把混合通路整体编掉（面积逃生门：blend_eff 恒 0）。
     * ===================================================================== */
`ifdef BLEND_OFF
    wire        blend_eff = 1'b0;      // 面积逃生门：混合通路整体编掉
`else
    wire        blend_eff = blend;     // 由引擎给（每命令恒定）；单元台必须显式接 0
`endif

    /* 属性解码（保留编码一律按 0；与 blt_engine_fsm 的解码同源） */
    wire [3:0]  bmode   = (attr[3:0] <= 4'd3) ? attr[3:0] : 4'd0;   // 4~15 保留→0
    wire [1:0]  sfmt    = (attr[5:4] == 2'd3) ? 2'd0 : attr[5:4];   // 3 保留→0
    wire [7:0]  ga      = attr[13:6];
    wire        a_test  = attr[24];
    wire        a_force = attr[25];

    /* 每像素 alpha：RGB565=255；ARGB1555=bit15?255:0；ARGB4444=a4*17。
     * FILL 的"源"是命令字颜色（没有 alpha 位）⇒ 恒 255。 */
    function [7:0] sp_alpha;
        input [15:0] px;
        input [1:0]  f;
        begin
            case (f)
                2'd1:    sp_alpha = px[15] ? 8'd255 : 8'd0;
                2'd2:    sp_alpha = {px[15:12], 4'b0} | {4'b0, px[15:12]};
                default: sp_alpha = 8'd255;
            endcase
        end
    endfunction

    /* FILL 的"源"是命令字颜色（没有 alpha 位）⇒ sprite_alpha 恒 255；颜色字段按 RGB565 抽。
     * 其它 op 的源 = fg 像素（下面按 src_format 选抽头）。 */
    wire [15:0] fgs1 = (op == 2'd1) ? color : fg_px;
    wire [15:0] fgs2 = (op == 2'd1) ? color : fg_px2;
    /* RGB565 → RGB888 的**位复制**必须是"把字段的高位复制到低位"：
     *   R8={r[4:0],r[4:2]}=px[15:11]++px[15:13]   G8={g[5:0],g[5:4]}=px[10:5]++px[10:9]
     *   B8={b[4:0],b[4:2]}=px[4:0] ++px[4:2]
     * 原来三处都错写成"取字段的**低位**"（px[13:11] / px[7:6] / px[2:0]），展开值
     * 最多小 7 个 LSB；经 (fg*α+bg*(255-α)+127)>>8 再量化回 5/6/5 后，表现为输出
     * 字段**普遍小 1~3 个 LSB**（越中间越明显），且 α=0/255 时**连纯背景/纯前景都
     * 回不到原值**（0xC618@α0 会算成 0xBDF7）。白/黑像素字段全 0 或全 1，错误展开
     * 恰好无损，所以金标准 0x7BEF@α128 一直是好的 —— 这也是该 bug 长期潜伏的原因。
     * 注意：绿通道的**字段抽头**（px[10:5]）是对的，错的只是后面的复制抽头。
     * ★S5 起这两组展开同时供"属性混合"使用（源 = fg 或 FILL 的命令字颜色），
     * 抽头与上面完全一致 —— ALPHA 金标准仍由同一组抽头产生。 */
    /* 源像素的通道展开：
     *   RGB565 / ARGB1555 —— 两者 R/G/B 字段位置完全相同（bit15 是 alpha）⇒ 用今天那套
     *     5/6/5 → 8bit 位复制（§11 的抽头，一字不改）；
     *   ARGB4444 —— A4R4G4B4，R/G/B 在 [11:8]/[7:4]/[3:0]（**与 RGB565 不同位置**），
     *     4bit 字段按位复制成 8bit（{f,f}），再在输出级量化回 5/6/5。
     *     ★ 这是位域决定的必做选择：不换抽头的话 ARGB4444 的"红"会取到 {A4,R4[3]}
     *     组合出来的假字段，颜色整个错位（详见 功能清单 §28 的说明）。
     * 关闭属性（sfmt=0）时选中的就是下面那一支 ⇒ 与今天逐位相同。 */
    wire        a444 = (sfmt == 2'd2);
    wire [7:0]  be_r1 = a444 ? {fgs1[11:8], fgs1[11:8]} : {fgs1[15:11], fgs1[15:13]};
    wire [7:0]  be_g1 = a444 ? {fgs1[7:4],  fgs1[7:4]}  : {fgs1[10:5],  fgs1[10:9]};
    wire [7:0]  be_b1 = a444 ? {fgs1[3:0],  fgs1[3:0]}  : {fgs1[4:0],   fgs1[4:2]};
    wire [7:0]  be_r2 = a444 ? {fgs2[11:8], fgs2[11:8]} : {fgs2[15:11], fgs2[15:13]};
    wire [7:0]  be_g2 = a444 ? {fgs2[7:4],  fgs2[7:4]}  : {fgs2[10:5],  fgs2[10:9]};
    wire [7:0]  be_b2 = a444 ? {fgs2[3:0],  fgs2[3:0]}  : {fgs2[4:0],   fgs2[4:2]};
    wire [7:0]  bd_r1 = {bg_px[15:11], bg_px[15:13]};    // 混合目的 = bg 流（dst 行，恒 RGB565）
    wire [7:0]  bd_g1 = {bg_px[10:5],  bg_px[10:9]};
    wire [7:0]  bd_b1 = {bg_px[4:0],   bg_px[4:2]};
    wire [7:0]  bd_r2 = {bg_px2[15:11], bg_px2[15:13]};
    wire [7:0]  bd_g2 = {bg_px2[10:5],  bg_px2[10:9]};
    wire [7:0]  bd_b2 = {bg_px2[4:0],   bg_px2[4:2]};

    /* 有效 alpha（属性侧）：A = sprite_alpha · global_alpha / 255，force_opaque ⇒ 255。
     * floor(x/255) 用 (x + (x>>8) + 1) >> 8：x ≤ 65025 时与整数除法**逐值相同**。 */
    wire [15:0] mul_sa1 = {8'd0, (op == 2'd1) ? 8'd255 : sp_alpha(fg_px,  sfmt)} * {8'd0, ga};
    wire [15:0] mul_sa2 = {8'd0, (op == 2'd1) ? 8'd255 : sp_alpha(fg_px2, sfmt)} * {8'd0, ga};
    wire [7:0]  a_div1  = (mul_sa1 + 16'd1 + {8'd0, mul_sa1[15:8]}) >> 8;
    wire [7:0]  a_div2  = (mul_sa2 + 16'd1 + {8'd0, mul_sa2[15:8]}) >> 8;
    reg  [7:0]  a_eff1, a_eff2;
    always @* begin
        a_eff1 = a_div1; if (a_force) a_eff1 = 8'd255;      // if 写法：z 安全
        a_eff2 = a_div2; if (a_force) a_eff2 = 8'd255;
    end

    /* 数据通路里的 alpha：blend 关 ⇒ 命令字 alpha（= 今天）；blend 开 ⇒ 属性有效 alpha */
    reg  [7:0]  A_ds1, A_ds2;
    reg         m_a, m_2, m_3;                              // 三种模式的选择（每条命令恒定）
    always @* begin
        A_ds1 = alpha;
        A_ds2 = alpha;
        m_a   = (op == 2'd2);                               // 今天：只有 ALPHA 走混合公式
        m_2   = 1'b0;
        m_3   = 1'b0;
        if (blend_eff) begin
            A_ds1 = a_eff1;
            A_ds2 = a_eff2;
            m_a   = (bmode == 4'd1);
            m_2   = (bmode == 4'd2);
            m_3   = (bmode == 4'd3);
        end
    end
    wire [7:0] inva1 = 8'hFF - A_ds1;
    wire [7:0] inva2 = 8'hFF - A_ds2;

    /* 三模式共用的后处理（乘法器留在调用处 ⇒ 每通道每 lane 只有 2 个 8x8 乘法器）。
     * s1 = p + q + 127 在**调用处**算：这样旧层次探针名 m_r/m_g/m_b 能原样留着
     * （tb_alpha 的逐拍 dump 直接引用它们），且不多花一个加法器。 */
    function [7:0] bl_out;
        input [15:0] s1;        // = p + q + 127（alpha 混合的和，也是旧探针的 m_*）
        input [15:0] p;         // fg · sel
        input [7:0]  bg8;       // 目的像素（加算用）
        input        is_m2;
        input        is_m3;
        reg   [7:0]  dv;
        reg   [8:0]  s2;
        begin
            dv = (p + {8'd0, p[15:8]} + 16'd1) >> 8;    // floor(p/255)
            s2 = {1'b0, dv} + {1'b0, bg8};              // 加算
            if (is_m3)      bl_out = p[15:8];           // 乘法 (fg·bg)>>8
            else if (is_m2) bl_out = s2[8] ? 8'hFF : s2[7:0];
            else            bl_out = s1[15:8];          // alpha 混合（老算式逐字）
        end
    endfunction

    /* lane1 */
    wire [7:0]  sel1_r = m_3 ? bd_r1 : A_ds1;
    wire [7:0]  sel1_g = m_3 ? bd_g1 : A_ds1;
    wire [7:0]  sel1_b = m_3 ? bd_b1 : A_ds1;
    wire [7:0]  qs1_r  = m_a ? inva1 : 8'd0;
    wire [7:0]  qs1_g  = qs1_r, qs1_b = qs1_r;
    wire [15:0] p_r1 = be_r1 * {8'd0, sel1_r};
    wire [15:0] p_g1 = be_g1 * {8'd0, sel1_g};
    wire [15:0] p_b1 = be_b1 * {8'd0, sel1_b};
    wire [15:0] q_r1 = bd_r1 * {8'd0, qs1_r};
    wire [15:0] q_g1 = bd_g1 * {8'd0, qs1_g};
    wire [15:0] q_b1 = bd_b1 * {8'd0, qs1_b};
    wire [15:0] m_r = p_r1 + q_r1 + 16'd127;    // ★ 兼容旧层次探针名（tb_alpha dump）
    wire [15:0] m_g = p_g1 + q_g1 + 16'd127;
    wire [15:0] m_b = p_b1 + q_b1 + 16'd127;
    wire [7:0]  o_r1 = bl_out(m_r, p_r1, bd_r1, m_2, m_3);
    wire [7:0]  o_g1 = bl_out(m_g, p_g1, bd_g1, m_2, m_3);
    wire [7:0]  o_b1 = bl_out(m_b, p_b1, bd_b1, m_2, m_3);
    wire [7:0]  r8 = o_r1, g8 = o_g1, b8 = o_b1;    // ★ 兼容旧层次探针名
    wire [15:0] bl_px1 = {o_r1[7:3], o_g1[7:2], o_b1[7:3]};     // 量化回 5/6/5（同今天）

    /* lane2（同式并行一套；非配对拍无意义，但组合求值无害） */
    wire [7:0]  sel2_r = m_3 ? bd_r2 : A_ds2;
    wire [7:0]  sel2_g = m_3 ? bd_g2 : A_ds2;
    wire [7:0]  sel2_b = m_3 ? bd_b2 : A_ds2;
    wire [7:0]  qs2_r  = m_a ? inva2 : 8'd0;
    wire [7:0]  qs2_g  = qs2_r, qs2_b = qs2_r;
    wire [15:0] p_r2 = be_r2 * {8'd0, sel2_r};
    wire [15:0] p_g2 = be_g2 * {8'd0, sel2_g};
    wire [15:0] p_b2 = be_b2 * {8'd0, sel2_b};
    wire [15:0] q_r2 = bd_r2 * {8'd0, qs2_r};
    wire [15:0] q_g2 = bd_g2 * {8'd0, qs2_g};
    wire [15:0] q_b2 = bd_b2 * {8'd0, qs2_b};
    wire [15:0] m_r2 = p_r2 + q_r2 + 16'd127;
    wire [15:0] m_g2 = p_g2 + q_g2 + 16'd127;
    wire [15:0] m_b2 = p_b2 + q_b2 + 16'd127;
    wire [7:0]  o_r2 = bl_out(m_r2, p_r2, bd_r2, m_2, m_3);
    wire [7:0]  o_g2 = bl_out(m_g2, p_g2, bd_g2, m_2, m_3);
    wire [7:0]  o_b2 = bl_out(m_b2, p_b2, bd_b2, m_2, m_3);
    wire [15:0] bl_px2 = {o_r2[7:3], o_g2[7:2], o_b2[7:3]};

    /* alpha 测试（flags.bit0）：有效 alpha=0 的像素不写。用 if 写法 ⇒ attr 悬空(z) 时恒放行 */
    reg a_ok1, a_ok2;
    always @* begin
        a_ok1 = 1'b1;
        a_ok2 = 1'b1;
        if (a_test && (a_eff1 == 8'd0)) a_ok1 = 1'b0;
        if (a_test && (a_eff2 == 8'd0)) a_ok2 = 1'b0;
    end

`ifdef PIXEL_PIXELS2_OFF
    /* =====================================================================
     * 单 lane 路径（v2.8 行为，逐字保留；A/B 逃生门）
     * ===================================================================== */
    /* ---------- 状态/计数器 ---------- */
    reg [15:0] i;
    reg        i_done;
    reg        done_i;

    /* ---------- 打包器 ---------- */
    reg  [127:0] acc;
    reg  [15:0]  amask;
    reg          aempty;
    reg  [15:0]  jw;

`ifdef PIXEL_PACK_PINGPONG_OFF
    /* ---------- 旧节拍（A/B 对照）：专属冲刷拍 ---------- */
    reg          flush_p;         // 词满 → 下一拍整拍专门冲刷
`else
    /* ---------- ★v2.8 成词 staging（skid）：与打包器并行的"待推词" ----------
     * 打包器只管装词；词一成（lane==7 或行尾）就当拍落这里，由推词通路
     * 下一拍送进 wd FIFO —— 两者并行，打包器不再为提交让出一拍。 */
    reg  [127:0] h_acc;           // 成词的 128bit 数据
    reg  [15:0]  h_mask;          // 成词的 16bit 字节掩码
    reg  [31:0]  h_addr;          // 成词的目的地址（= d_base + jw*16）
    reg          h_v;             // staging 里有一个待推的词
`endif

    /* ---------- 组合：lane / 输出 / 保留 ---------- */
    wire [2:0] lane = (d_lane0 + i[2:0]);
    wire       is_last = (i == width - 16'd1);

    /* ALPHA 混合（组合）：★S5 起改用上面那份共用数据通路 bl_px1。
     * 兼容性证明见"属性侧口"一节：blend=0 且 op=ALPHA 时它就是 §11 的老算式
     * （p=f·alpha、q=bg·(255−alpha)、+127、>>8、量化 5/6/5），一字不差。
     * 下面这些名字保留下来只为少改下游（out_alpha / ar.. 只是别名）。 */
    wire [15:0] out_alpha = bl_px1;
    wire [7:0]  ar = be_r1, ag = be_g1, ab = be_b1;      // 兼容旧层次探针的别名
    wire [7:0]  br = bd_r1, bg2 = bd_g1, bb2 = bd_b1;

    reg  [15:0] out_px;
    reg         keep;
    always @* begin
        case (op)
            2'd0: begin out_px = fg_px; keep = 1'b1; end                    // COPY
            2'd1: begin out_px = color; keep = 1'b1; end                    // FILL
            2'd2: begin out_px = out_alpha; keep = 1'b1; end                // ALPHA
            default: begin out_px = fg_px; keep = (fg_px != key); end       // KEY
        endcase
        /* ★S5：属性混合生效时覆盖（blend=0 ⇒ 上面的老行为原样，逐位不变） */
        if (blend_eff) begin
            out_px = bl_px1;
            keep   = keep && a_ok1;
        end
    end

    // 推进条件
`ifdef PIXEL_PACK_PINGPONG_OFF
    wire core_can = (st == S_RUN) && !flush_p && !i_done && !done_i;
    wire can_pp   = core_can && (!need_fg || fg_rdy) && (!need_bg || bg_rdy);
    wire flush_ok = flush_p && !wd_full;
`else
    /* 并入本拍像素后的词（组合）—— acc/amask 与该词落 staging 共用这一份逻辑。
     * 表达式与旧写法逐字相同（只是从"下一拍才用它"提前到"当拍就用"），
     * 而且**必须带上 keep 门控**：KEY 的键色像素是"留孔不写"，旧写法里这两条
     * OR 就写在 `if (keep)` 里面。漏掉门控的后果实测过：键色像素落在词尾
     * （lane==7）或行尾时会被当成"要写"的像素，掩码多置 2 bit、数据写成键色，
     * 探针的 px_written 立刻从 713 变 744（32x32 KEY 用例，恰好 31 行 × 1 像素）。 */
    wire [127:0] acc_n   = keep ? (acc   | ({16'd0, out_px} << (lane * 16))) : acc;
    wire [15:0]  amask_n = keep ? (amask | (16'h0003 << (lane * 2)))         : amask;
    wire         word_end   = (lane == 3'd7) || is_last;  // 本拍末要一个词边界
    wire         w_nonempty = keep || !aempty;            // 含本拍像素后本词非空（有掩码）
    wire         need_push  = word_end && w_nonempty;     // 本拍末要产出（提交）一个词
    /* 推词：staging 有词且 wd 有位 → 下一拍 wd_wr 拉高（脉冲与旧冲刷逐拍相同）。
     * 它与像素组装并行，不占打包器节拍。 */
    wire         push_can   = h_v && !wd_full;
    /* staging 本拍末能不能接住新词：**只认 h_v 空**，不认"同拍推空+装入"的交换。
     * 为什么不做交换：wd_wr 是寄存脉冲 ⇒ 决定推的那一拍 P 之后，真正写进 FIFO 是
     * P+1 那一拍（sync_fifo 的 do_wr = wr_en && !full 在 P+1 才判 full）。若允许
     * P 拍"推空+装入"，则 P+1 拍 h_v 又为 1、且 P+1 拍 full 仍可能是 0（占用在
     * P 末才 +1）⇒ 会连着决定第二次推词，而第二次的写入拍正好可能撞上 full=1，
     * 那一个字被 FIFO 静默丢弃（`do_wr` 门控掉）。实测症状：tb_blt_unalign 的
     * U4（1x64 竖条、行间隔 4 拍 < 写主机 8 拍/词 ⇒ wd 常常满）漏写 7 个像素。
     * 只认 h_v 空 ⇒ 任意两次推词决定之间至少隔 1 拍 ⇒ 写入拍一定仍 !full
     * （占用只可能被读侧弹低）⇒ 结构上不可能丢词。代价：wd 满时每个词多停 1 拍
     * （饱和写场景，与本次吞吐目标无关）。 */
    wire         skid_ok    = !h_v;
    /* 本拍末要出词、但 staging 还没腾空 → 停一拍像素（wd FIFO 满时才会发生） */
    wire         px_gate    = !need_push || skid_ok;

    wire core_can = (st == S_RUN) && !i_done && !done_i;
    wire can_pp   = core_can && (!need_fg || fg_rdy) && (!need_bg || bg_rdy) && px_gate;
    /* 诊断量（probe/tb_alpha 观察）：专属冲刷拍已经没有了；flush_p 只剩
     * "本拍真要推进像素、却被 wd 满挡在 staging 外"这一含义 ⇒ 必须并上 core_can：
     * 行末最后一个像素被消费后 i 仍停在 width-1、is_last/aempty 组合会让 need_push
     * 继续成立，而那时像素通路已经交回引擎（st=IDLE），那一拍不是停顿、只该算
     * 引擎开销。不并 core_can 的话整屏 FILL 会有 540 拍被误标成 FLUSH_HOLE。
     * flush_ok 实际恒 0（flush_p 只在 wd 满挡住时出现）。 */
    wire flush_p  = core_can && need_push && !skid_ok;
    wire flush_ok = flush_p && !wd_full;
`endif
    assign fg_take  = can_pp && need_fg;
    assign bg_take  = can_pp && need_bg;
    assign fg_take2 = 1'b0;                 // 单 lane 模式不存在双像素消费
    assign bg_take2 = 1'b0;

    wire [31:0] wd_addr_c = d_base + {16'd0, jw} * 16'd16;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= S_IDLE;
            busy     <= 1'b0;
            row_done <= 1'b0;
            i        <= 16'd0;
            i_done   <= 1'b0;
            done_i   <= 1'b0;
            clr_p    <= 1'b0;
            acc      <= 128'd0;
            amask    <= 16'd0;
            aempty   <= 1'b1;
            jw       <= 16'd0;
            wd_wr    <= 1'b0;
            wd_word  <= 176'd0;
`ifdef PIXEL_PACK_PINGPONG_OFF
            flush_p  <= 1'b0;
`else
            h_acc    <= 128'd0;
            h_mask   <= 16'd0;
            h_addr   <= 32'd0;
            h_v      <= 1'b0;
`endif
        end else begin
            wd_wr <= 1'b0;
`ifndef PIXEL_PACK_PINGPONG_OFF
            /* ---- 推词通路（与像素组装并行）----
             * staging 有词且 wd FIFO 有位 → 下拍 wd_wr 拉高：协议与旧冲刷完全相同
             * （1 拍寄存脉冲 + 脉冲期间 wd_word 稳定），只是不再占打包器的节拍。
             * 赋值次序说明：下面 S_RUN 里的 h_v<=1（装入新词）只在 h_v==0 时发生
             * （见 skid_ok），所以这里的 h_v<=0 与它永不同拍，不存在相互覆盖。 */
            if (push_can) begin
                wd_wr   <= 1'b1;
                wd_word <= {h_mask, h_addr, h_acc};
                h_v     <= 1'b0;
            end
`endif
            case (st)
                S_IDLE: begin
                    row_done <= 1'b0;
                    clr_p    <= 1'b0;
                    if (start) begin
                        st      <= S_RUN;
                        busy    <= 1'b1;
                        i       <= 16'd0;
                        i_done  <= 1'b0;
                        done_i  <= 1'b0;
                        acc     <= 128'd0;
                        amask   <= 16'd0;
                        aempty  <= 1'b1;
                        jw      <= 16'd0;
`ifdef PIXEL_PACK_PINGPONG_OFF
                        flush_p <= 1'b0;
`endif
                    end
                end
                S_RUN: begin
`ifdef PIXEL_PACK_PINGPONG_OFF
                    if (flush_ok) begin
                        if (!aempty) begin
                            wd_wr   <= 1'b1;
                            wd_word <= {amask, wd_addr_c, acc};
                        end
                        /* jw 必须**每个词边界**都进位：整词全键色（KEY 留孔）时
                         * 该词不写，但下一个词的地址仍要 +16B。原写法把 jw+1 放在
                         * `if (!aempty)` 里，一旦某个词整词被跳过，后续所有词都会
                         * 提前一个词（水平错位 8 像素）。 */
                        jw      <= jw + 16'd1;
                        aempty  <= 1'b1;
                        acc     <= 128'd0;
                        amask   <= 16'd0;
                        flush_p <= 1'b0;
                        if (i_done) begin
                            done_i   <= 1'b1;
                            st       <= S_IDLE;
                            busy     <= 1'b0;
                            row_done <= 1'b1;
                            clr_p    <= 1'b1;
                        end
                    end else if (can_pp) begin
                        if (keep) begin
                            acc    <= acc | ({16'd0, out_px} << (lane * 16));
                            amask  <= amask | (16'h0003 << (lane * 2));
                            aempty <= 1'b0;
                        end
                        if (lane == 3'd7)
                            flush_p <= 1'b1;              // 词满 → 下拍冲刷
                        if (is_last) begin
                            i_done <= 1'b1;
                            if (lane != 3'd7) begin       // 行尾残余词
                                if (!aempty || keep) flush_p <= 1'b1;
                                else begin
                                    done_i   <= 1'b1;
                                    st       <= S_IDLE;
                                    busy     <= 1'b0;
                                    row_done <= 1'b1;
                                    clr_p    <= 1'b1;
                                end
                            end
                        end else begin
                            i <= i + 16'd1;
                        end
                    end
`else
                    if (can_pp) begin
                        if (need_push) begin
                            /* 词满（lane==7）或行尾残余词：把**含本像素的整词**当拍
                             * 落 staging，打包器当拍清零 → 下一拍就开始装下一个词。
                             * 进 wd FIFO 的拍数关系与旧冲刷一致（见文件头）。 */
                            h_acc  <= acc_n;
                            h_mask <= amask_n;
                            h_addr <= wd_addr_c;
                            h_v    <= 1'b1;
                            acc    <= 128'd0;
                            amask  <= 16'd0;
                            aempty <= 1'b1;
                            jw     <= jw + 16'd1;
                        end else if (word_end) begin
                            /* 词边界但整词全键色：掩码为 0 → 不提交（KEY 留孔），
                             * 但 jw 仍要进位（与旧冲刷分支同一语义，见 10.1.4） */
                            acc    <= 128'd0;
                            amask  <= 16'd0;
                            aempty <= 1'b1;
                            jw     <= jw + 16'd1;
                        end else if (keep) begin
                            acc    <= acc_n;
                            amask  <= amask_n;
                            aempty <= 1'b0;
                        end
                        if (is_last) begin
                            /* 行末：本拍就是最后一个像素，词已（或无需）落 staging
                             * → 同拍收尾，不再需要 i_done 那一拍冲刷 */
                            i_done   <= 1'b1;
                            done_i   <= 1'b1;
                            st       <= S_IDLE;
                            busy     <= 1'b0;
                            row_done <= 1'b1;
                            clr_p    <= 1'b1;
                        end else
                            i <= i + 16'd1;
                    end
`endif
                end
                default: st <= S_IDLE;
            endcase
        end
    end
`else
    /* =====================================================================
     * ★v3.1 双 lane 路径（默认）：一拍吃 2 个像素
     * ===================================================================== */
    /* ---------- 状态/计数器 ---------- */
    reg [15:0] i;              // 本拍首像素在行内的下标（0..width-1）
    reg        i_done;         // 兼容旧层次探针（tb_alpha dump_state）
    reg        done_i;

    /* ---------- 打包器 ---------- */
    reg  [127:0] acc;
    reg  [15:0]  amask;
    reg          aempty;
    reg  [15:0]  jw;

    /* ---------- 成词 staging（同 v2.8） ---------- */
    reg  [127:0] h_acc;
    reg  [15:0]  h_mask;
    reg  [31:0]  h_addr;
    reg          h_v;

`ifdef PX_ACC_PIPE_ON
    /* ---------- ★v3.3 流水边界寄存器（stage1 → stage2，默认关，见文件头） ----------
     * 切点 = **乘加通路入口**：寄存器里装的是"打包台下一拍要用的全部操作数"。
     * 之所以连像素/lane/keep 一起搬（而不是只搬 alpha）：alpha 是逐像素的，只延迟
     * alpha 会配错像素 ⇒ 两个 lane 的源/目的像素、lane、配对、行尾、keep 同步延迟，
     * 打包器整体晚一拍消费（b_v = 上一拍 can_pp，两者 1:1，见 always 块）。 */
    reg         b_v;                   // 边界里有一个待打包的像素对
    reg  [2:0]  b_lane;                // 本对首像素的 dst lane
    reg         b_two, b_last;         // 配对拍 / 行尾对
    reg         b_keep, b_kb;          // 两个 lane 的 keep（已含 alpha 测试，同 stage1 值）
    reg  [15:0] b_fgs1, b_fgs2;        // 源像素（FILL ⇒ 命令字颜色）
    reg  [15:0] b_bg1,  b_bg2;         // 目的像素（bg 流 = dst 行）
    reg  [7:0]  b_A1,   b_A2;          // 有效 alpha A_ds（blend 关 ⇒ 命令字 alpha）
    reg  [7:0]  b_ia1,  b_ia2;         // 255 − A_ds
`endif

    /* ---------- 组合：lane / 配对 / 输出 / 保留 ---------- */
    wire [2:0] lane = (d_lane0 + i[2:0]);        // 本拍首像素的 dst lane
    /* 配对条件：dst 偶 lane（⇒ lane+1 ≤ 7，一对永不跨 16B 词）且行内还剩 ≥2 像素。
     * d_lane0 为奇时行首那个像素单独走一拍（lane 奇），i 随之为偶 ⇒ 之后全成对。 */
    wire       two    = !lane[0] && (i != (width - 16'd1));
    wire [2:0] lane_e = two ? (lane + 3'd1) : lane;    // 本拍末像素的 lane
    wire       is_last= ((two ? (i + 16'd1) : i) == (width - 16'd1));

    // ALPHA 混合 / 属性混合（组合）：★S5 起两种 lane 都用上面那份共用数据通路
    // （bl_px1 / bl_px2），公式、抽头、量化与单 lane 版逐位相同：见"属性侧口"一节。
    wire [15:0] out_alpha  = bl_px1;
    wire [15:0] out_alpha2 = bl_px2;
    wire [7:0]  ar = be_r1, ag = be_g1, ab = be_b1;      // 兼容旧层次探针的别名
    wire [7:0]  br = bd_r1, bg2 = bd_g1, bb2 = bd_b1;
    wire [7:0]  ar2 = be_r2, ag2 = be_g2, ab2 = be_b2;
    wire [7:0]  br2 = bd_r2, bg3 = bd_g2, bb3 = bd_b2;

    reg  [15:0] out_px, out_px2;
    reg         keep,   keep_b;
    always @* begin
        case (op)
            2'd0: begin out_px = fg_px;  keep = 1'b1;
                        out_px2= fg_px2; keep_b = 1'b1; end                 // COPY
            2'd1: begin out_px = color;  keep = 1'b1;
                        out_px2= color;  keep_b = 1'b1; end                 // FILL
            2'd2: begin out_px = out_alpha;  keep = 1'b1;
                        out_px2= out_alpha2; keep_b = 1'b1; end             // ALPHA
            default: begin out_px = fg_px;  keep = (fg_px != key);
                           out_px2= fg_px2; keep_b = (fg_px2 != key); end   // KEY
        endcase
        /* ★S5：属性混合生效时覆盖（blend=0 ⇒ 上面的老行为原样，逐位不变）。
         * 两个 lane 各自按自己的 a_ok 决定是否写 ⇒ 逐像素 alpha 在配对拍上也正确。 */
        if (blend_eff) begin
            out_px  = bl_px1;
            out_px2 = bl_px2;
            keep    = keep   && a_ok1;
            keep_b  = keep_b && a_ok2;
        end
    end
    /* 第二个像素只在配对拍才真的消费（非配对拍 out_px2/keep_b 无意义） */
    wire keep2     = two && keep_b;
    wire keep_any  = keep || keep2;

    /* ---------- 词组装（组合）：两个像素各置 2bit 掩码 ----------
     * 表达式与单 lane 版逐字相同，第二个像素用 lane+1（lane 偶 ⇒ lane+1 ≤ 7）。
     * **keep 门控必须保留**：KEY 的键色像素是"留孔不写"（v2.8 实测记录）。 */
    wire [127:0] acc_n0   = keep  ? (acc    | ({16'd0, out_px}   << (lane * 16)))        : acc;
    wire [127:0] acc_n    = keep2 ? (acc_n0 | ({16'd0, out_px2}  << ((lane + 3'd1)*16))) : acc_n0;
    wire [15:0]  amask_n0 = keep  ? (amask  | (16'h0003 << (lane * 2)))                  : amask;
    wire [15:0]  amask_n  = keep2 ? (amask_n0 | (16'h0003 << ((lane + 3'd1) * 2)))       : amask_n0;

`ifdef PX_ACC_PIPE_ON
    /* =====================================================================
     * ★v3.3 stage2：用流水寄存器里的操作数重算乘加通路
     * ---------------------------------------------------------------------
     * 表达式与上面 stage1 的通道展开 / sel / qs / 两个乘法 / 加法 / bl_out **逐字相同**
     * （同一 bl_out 函数、同一抽头、同一 +127、同一量化），只是操作数换成寄存器里
     * 的那一份 ⇒ 输出逐位不变，只晚一拍。
     * stage1 那一份组合通路在 PX_ACC_PIPE_ON 下不再驱动打包器（只喂层次探针：
     * tb_alpha 的 +trace 逐级打印、tb_perf_probe 的 keep/lane），综合会整块剪掉
     * ⇒ 关键路径只剩这条被寄存器切开的链。保留它的好处是 A/B 两次仿真的逐级
     * 探针读数可以逐拍对照（值与相对 can_pp 的时序都不变）。
     * ===================================================================== */
    /* 源/目的通道展开（bd_* 是纯连线；be_* 多一级 src_format mux，a444 每命令恒定） */
    wire [7:0]  s2_ber1 = a444 ? {b_fgs1[11:8], b_fgs1[11:8]} : {b_fgs1[15:11], b_fgs1[15:13]};
    wire [7:0]  s2_beg1 = a444 ? {b_fgs1[7:4],  b_fgs1[7:4]}  : {b_fgs1[10:5],  b_fgs1[10:9]};
    wire [7:0]  s2_beb1 = a444 ? {b_fgs1[3:0],  b_fgs1[3:0]}  : {b_fgs1[4:0],   b_fgs1[4:2]};
    wire [7:0]  s2_ber2 = a444 ? {b_fgs2[11:8], b_fgs2[11:8]} : {b_fgs2[15:11], b_fgs2[15:13]};
    wire [7:0]  s2_beg2 = a444 ? {b_fgs2[7:4],  b_fgs2[7:4]}  : {b_fgs2[10:5],  b_fgs2[10:9]};
    wire [7:0]  s2_beb2 = a444 ? {b_fgs2[3:0],  b_fgs2[3:0]}  : {b_fgs2[4:0],   b_fgs2[4:2]};
    wire [7:0]  s2_bdr1 = {b_bg1[15:11], b_bg1[15:13]};
    wire [7:0]  s2_bdg1 = {b_bg1[10:5],  b_bg1[10:9]};
    wire [7:0]  s2_bdb1 = {b_bg1[4:0],   b_bg1[4:2]};
    wire [7:0]  s2_bdr2 = {b_bg2[15:11], b_bg2[15:13]};
    wire [7:0]  s2_bdg2 = {b_bg2[10:5],  b_bg2[10:9]};
    wire [7:0]  s2_bdb2 = {b_bg2[4:0],   b_bg2[4:2]};
    /* lane1 乘加（与 stage1 的 sel1 / qs1 / p_?1 / q_?1 / m_? / o_?1 同式） */
    wire [7:0]  s2_sel1r = m_3 ? s2_bdr1 : b_A1;
    wire [7:0]  s2_sel1g = m_3 ? s2_bdg1 : b_A1;
    wire [7:0]  s2_sel1b = m_3 ? s2_bdb1 : b_A1;
    wire [7:0]  s2_qs1   = m_a ? b_ia1 : 8'd0;
    wire [15:0] s2_pr1 = s2_ber1 * {8'd0, s2_sel1r};
    wire [15:0] s2_pg1 = s2_beg1 * {8'd0, s2_sel1g};
    wire [15:0] s2_pb1 = s2_beb1 * {8'd0, s2_sel1b};
    wire [15:0] s2_qr1 = s2_bdr1 * {8'd0, s2_qs1};
    wire [15:0] s2_qg1 = s2_bdg1 * {8'd0, s2_qs1};
    wire [15:0] s2_qb1 = s2_bdb1 * {8'd0, s2_qs1};
    wire [15:0] s2_mr  = s2_pr1 + s2_qr1 + 16'd127;
    wire [15:0] s2_mg  = s2_pg1 + s2_qg1 + 16'd127;
    wire [15:0] s2_mb  = s2_pb1 + s2_qb1 + 16'd127;
    wire [7:0]  s2_or1 = bl_out(s2_mr, s2_pr1, s2_bdr1, m_2, m_3);
    wire [7:0]  s2_og1 = bl_out(s2_mg, s2_pg1, s2_bdg1, m_2, m_3);
    wire [7:0]  s2_ob1 = bl_out(s2_mb, s2_pb1, s2_bdb1, m_2, m_3);
    wire [15:0] s2_px1 = {s2_or1[7:3], s2_og1[7:2], s2_ob1[7:3]};
    /* lane2（同式并行一套） */
    wire [7:0]  s2_sel2r = m_3 ? s2_bdr2 : b_A2;
    wire [7:0]  s2_sel2g = m_3 ? s2_bdg2 : b_A2;
    wire [7:0]  s2_sel2b = m_3 ? s2_bdb2 : b_A2;
    wire [7:0]  s2_qs2   = m_a ? b_ia2 : 8'd0;
    wire [15:0] s2_pr2 = s2_ber2 * {8'd0, s2_sel2r};
    wire [15:0] s2_pg2 = s2_beg2 * {8'd0, s2_sel2g};
    wire [15:0] s2_pb2 = s2_beb2 * {8'd0, s2_sel2b};
    wire [15:0] s2_qr2 = s2_bdr2 * {8'd0, s2_qs2};
    wire [15:0] s2_qg2 = s2_bdg2 * {8'd0, s2_qs2};
    wire [15:0] s2_qb2 = s2_bdb2 * {8'd0, s2_qs2};
    wire [15:0] s2_mr2 = s2_pr2 + s2_qr2 + 16'd127;
    wire [15:0] s2_mg2 = s2_pg2 + s2_qg2 + 16'd127;
    wire [15:0] s2_mb2 = s2_pb2 + s2_qb2 + 16'd127;
    wire [7:0]  s2_or2 = bl_out(s2_mr2, s2_pr2, s2_bdr2, m_2, m_3);
    wire [7:0]  s2_og2 = bl_out(s2_mg2, s2_pg2, s2_bdg2, m_2, m_3);
    wire [7:0]  s2_ob2 = bl_out(s2_mb2, s2_pb2, s2_bdb2, m_2, m_3);
    wire [15:0] s2_px2 = {s2_or2[7:3], s2_og2[7:2], s2_ob2[7:3]};

    /* 打包器输入：与 stage1 的 out_px/out_px2/keep2 逐字同式。
     * （blend 关 + ALPHA ⇒ 上面这条通路自动退化成老算式；其它 op 取原始像素/颜色） */
    wire [15:0] s2_out1 = (blend_eff || (op == 2'd2)) ? s2_px1
                        : ((op == 2'd1) ? color : b_fgs1);
    wire [15:0] s2_out2 = (blend_eff || (op == 2'd2)) ? s2_px2
                        : ((op == 2'd1) ? color : b_fgs2);
    wire        s2_k2    = b_two && b_kb;
    wire        s2_kany  = b_keep || s2_k2;
    wire [2:0]  s2_lane_e= b_two ? (b_lane + 3'd1) : b_lane;
    wire        s2_wend  = (s2_lane_e == 3'd7) || b_last;
    wire        s2_wnon  = s2_kany || !aempty;
    wire        s2_push  = s2_wend && s2_wnon;
    /* 词组装（与 stage1 的 acc_n0/acc_n/amask_n0/amask_n 同式） */
    wire [127:0] s2_acc0 = b_keep ? (acc   | ({16'd0, s2_out1} << (b_lane * 16)))            : acc;
    wire [127:0] s2_accn = s2_k2  ? (s2_acc0 | ({16'd0, s2_out2} << ((b_lane + 3'd1) * 16))) : s2_acc0;
    wire [15:0]  s2_msk0 = b_keep ? (amask | (16'h0003 << (b_lane * 2)))                     : amask;
    wire [15:0]  s2_mskn = s2_k2  ? (s2_msk0 | (16'h0003 << ((b_lane + 3'd1) * 2)))          : s2_msk0;
`endif

    /* ---------- 推进/背压（与 v2.8 同一套，只是 `need_push` 的门控按本拍末像素算） */
    wire word_end   = (lane_e == 3'd7) || is_last;
    wire w_nonempty = keep_any || !aempty;
    wire need_push  = word_end && w_nonempty;
    wire push_can   = h_v && !wd_full;
    wire skid_ok    = !h_v;                    // 只认 h_v 空（见单 lane 版的长注释）
    wire px_gate    = !need_push || skid_ok;

`ifdef PX_ACC_PIPE_ON
    /* ---- 前瞻一拍：下一拍打包台看到的状态（pipe_ok 拿它做**精确**闸门） ----
     * 打包台在 T+1 会被挡 ⟺ 它在 T+1 要推词（= 本拍 live 的 np_nxt）而 staging 那拍
     * 还占着。两个状态量都按 always 块里的赋值**优先级**逐字推导：
     *   aempty(T+1)：由本拍打包台的动作决定（stage2 在 T 处理的是 T−1 捕获的 bundle）
     *   h_v(T+1)   ：推词通路清 0 与打包台置 1 的先后顺序与 always 块完全一致
     * 所以前瞻不是保守估计 —— 预测"要停"就一定停，预测"能推"就一定推得进。 */
    wire        s2_fill = b_v && s2_push;
    wire        h_v_nxt = s2_fill ? 1'b1 : (push_can ? 1'b0 : h_v);
    wire        ae_rst  = b_v && (s2_push || s2_wend);             // 打包台把 aempty 置 1
    wire        ae_set  = b_v && !s2_push && !s2_wend && s2_kany;  // 打包台把 aempty 置 0
    wire        ae_nxt  = ae_rst ? 1'b1 : (ae_set ? 1'b0 : aempty);
    wire        np_nxt  = word_end && (keep_any || !ae_nxt);       // T+1 的 need_push（口径同 stage1）
    wire        pipe_ok = !(np_nxt && h_v_nxt);
`endif

    wire core_can   = (st == S_RUN) && !i_done && !done_i;
    /* 配对拍要求两侧读取器都能交付 2 像素（只停一拍、不拆对，绝不丢像素） */
    wire fg_ok      = two ? fg_rdy2 : fg_rdy;
    wire bg_ok      = two ? bg_rdy2 : bg_rdy;
`ifdef PX_ACC_PIPE_ON
    /* ★v3.3：闸门换成"前瞻一拍的流水闸门"pipe_ok —— 像素被读侧消费后 bundle 只活
     * 一拍，所以必须在前一拍就知道下一拍打包台推不推得进去（推导见上面 stage2 段）。
     * 饱和（wd 满）时它比 px_gate 宽松，最多比 v3.2 少停 1 拍；像素/字节结果不变。*/
    wire can_pp     = core_can && (!need_fg || fg_ok) && (!need_bg || bg_ok) && pipe_ok;
    wire flush_p    = core_can && np_nxt && !pipe_ok;
    wire flush_ok   = flush_p && !wd_full;
`else
    wire can_pp     = core_can && (!need_fg || fg_ok) && (!need_bg || bg_ok) && px_gate;
    wire flush_p    = core_can && need_push && !skid_ok;
    wire flush_ok   = flush_p && !wd_full;
`endif

    assign fg_take  = can_pp && need_fg && !two;
    assign fg_take2 = can_pp && need_fg &&  two;
    assign bg_take  = can_pp && need_bg && !two;
    assign bg_take2 = can_pp && need_bg &&  two;

    wire [31:0] wd_addr_c = d_base + {16'd0, jw} * 16'd16;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= S_IDLE;
            busy     <= 1'b0;
            row_done <= 1'b0;
            i        <= 16'd0;
            i_done   <= 1'b0;
            done_i   <= 1'b0;
            clr_p    <= 1'b0;
            acc      <= 128'd0;
            amask    <= 16'd0;
            aempty   <= 1'b1;
            jw       <= 16'd0;
            wd_wr    <= 1'b0;
            wd_word  <= 176'd0;
            h_acc    <= 128'd0;
            h_mask   <= 16'd0;
            h_addr   <= 32'd0;
            h_v      <= 1'b0;
`ifdef PX_ACC_PIPE_ON
            b_v      <= 1'b0;
            b_lane   <= 3'd0;
            b_two    <= 1'b0;
            b_last   <= 1'b0;
            b_keep   <= 1'b0;
            b_kb     <= 1'b0;
            b_fgs1   <= 16'd0;
            b_fgs2   <= 16'd0;
            b_bg1    <= 16'd0;
            b_bg2    <= 16'd0;
            b_A1     <= 8'd0;
            b_A2     <= 8'd0;
            b_ia1    <= 8'd0;
            b_ia2    <= 8'd0;
`endif
        end else begin
            wd_wr <= 1'b0;
            /* ---- 推词通路（与像素组装并行）：协议与 v2.8 逐拍相同 ---- */
            if (push_can) begin
                wd_wr   <= 1'b1;
                wd_word <= {h_mask, h_addr, h_acc};
                h_v     <= 1'b0;
            end
`ifdef PX_ACC_PIPE_ON
            /* =================================================================
             * ★v3.3 流水边界（stage1 → stage2）
             * -----------------------------------------------------------------
             * (a) 捕获：本拍 can_pp=1（读侧消费了一对像素）⇒ 把打包台下一拍要用的
             *     全部操作数装进寄存器。b_v = can_pp（1:1，不丢不重）：
             *     can_pp 里已含 core_can ⇒ 行外/行末之后自动清 0，不会残留。
             * (b) 打包：b_v=1 就是"上一拍捕获的像素对"，本拍无条件消费（pipe_ok 已
             *     精确保证推得进）。赋值次序 = 先推词通路清 h_v、再打包台置 h_v，
             *     与 v3.2 的先后完全一致（h_v_nxt 就是照这个顺序推的）。
             *     打包台晚一拍，所以 row_done/busy/clr_p/st 都从这里出（见文件头：
             *     不能留 stage1，否则引擎会在尾词入队前满足 wr_commit_idle）。
             * ================================================================= */
            b_v <= can_pp;
            if (can_pp) begin
                b_fgs1 <= fgs1;    b_fgs2 <= fgs2;
                b_bg1  <= bg_px;   b_bg2  <= bg_px2;
                b_A1   <= A_ds1;   b_A2   <= A_ds2;
                b_ia1  <= inva1;   b_ia2  <= inva2;
                b_keep <= keep;    b_kb   <= keep_b;
                b_lane <= lane;    b_two  <= two;   b_last <= is_last;
            end
            if (b_v) begin
                if (s2_push) begin
                    /* 词满（本对末像素 lane==7）或行尾残词：含本对两个像素的整词
                     * 落 staging，打包器当拍清零（与 v3.2 同语义，只是晚一拍）。 */
                    h_acc  <= s2_accn;
                    h_mask <= s2_mskn;
                    h_addr <= wd_addr_c;
                    h_v    <= 1'b1;
                    acc    <= 128'd0;
                    amask  <= 16'd0;
                    aempty <= 1'b1;
                    jw     <= jw + 16'd1;
                end else if (s2_wend) begin
                    /* 词边界但整词全键色：掩码 0 → 不提交，jw 仍进位 */
                    acc    <= 128'd0;
                    amask  <= 16'd0;
                    aempty <= 1'b1;
                    jw     <= jw + 16'd1;
                end else if (s2_kany) begin
                    acc    <= s2_accn;
                    amask  <= s2_mskn;
                    aempty <= 1'b0;
                end
                if (b_last) begin
                    i_done   <= 1'b1;
                    done_i   <= 1'b1;
                    st       <= S_IDLE;
                    busy     <= 1'b0;
                    row_done <= 1'b1;
                    clr_p    <= 1'b1;
                end
            end
`endif
            case (st)
                S_IDLE: begin
                    row_done <= 1'b0;
                    clr_p    <= 1'b0;
                    if (start) begin
                        st      <= S_RUN;
                        busy    <= 1'b1;
                        i       <= 16'd0;
                        i_done  <= 1'b0;
                        done_i  <= 1'b0;
                        acc     <= 128'd0;
                        amask   <= 16'd0;
                        aempty  <= 1'b1;
                        jw      <= 16'd0;
                    end
                end
                S_RUN: begin
`ifdef PX_ACC_PIPE_ON
                    /* ★v3.3 stage1：本拍只"消费 + 捕获"（捕获段在 always 块顶部），
                     * 打包/推词/行末收尾都在 stage2 那一拍。i_done/done_i 仍在**本拍**
                     * 置起 ⇒ core_can 当拍即 0，读侧不会多消费一个像素对（弹词条数与
                     * v3.2 逐词一致，引擎的 dr_* drain 口径不变）。 */
                    if (can_pp) begin
                        if (is_last) begin
                            i_done   <= 1'b1;
                            done_i   <= 1'b1;
                        end else
                            i <= i + (two ? 16'd2 : 16'd1);
                    end
`else
                    if (can_pp) begin
                        if (need_push) begin
                            /* 词满（本拍末像素 lane==7）或行尾残词：含本拍**两个**
                             * 像素的整词当拍落 staging，打包器当拍清零。 */
                            h_acc  <= acc_n;
                            h_mask <= amask_n;
                            h_addr <= wd_addr_c;
                            h_v    <= 1'b1;
                            acc    <= 128'd0;
                            amask  <= 16'd0;
                            aempty <= 1'b1;
                            jw     <= jw + 16'd1;
                        end else if (word_end) begin
                            /* 词边界但整词全键色：掩码 0 → 不提交，jw 仍进位 */
                            acc    <= 128'd0;
                            amask  <= 16'd0;
                            aempty <= 1'b1;
                            jw     <= jw + 16'd1;
                        end else if (keep_any) begin
                            acc    <= acc_n;
                            amask  <= amask_n;
                            aempty <= 1'b0;
                        end
                        if (is_last) begin
                            i_done   <= 1'b1;
                            done_i   <= 1'b1;
                            st       <= S_IDLE;
                            busy     <= 1'b0;
                            row_done <= 1'b1;
                            clr_p    <= 1'b1;
                        end else
                            i <= i + (two ? 16'd2 : 16'd1);
                    end
`endif
                end
                default: st <= S_IDLE;
            endcase
        end
    end
`endif
endmodule
