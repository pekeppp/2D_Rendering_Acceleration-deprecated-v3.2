/* =========================================================================
 * fb_scanout.v — 帧缓冲扫描输出（DDR 读 → 双行缓冲 → 1080p 画面窗口）
 * -------------------------------------------------------------------------
 * 【v2.5：只把"取数变快"，其余结构保持已知可启动的 v2 不动】
 *
 * 上板现象（22:38 日志那一版 = v2）：
 *   · 压测档（被 60fps 节流、引擎/CPU 有间隙）→ 少量"针簇状黑色细线"；
 *   · 待机 demo（引擎+CPU 连续工作、没有节流）→ **大面积三角形黑色闪烁**。
 * 两者同源：扫描输出取一行太慢，遇到抢占就错过行死线，显示侧对未就绪行输出黑。
 *
 * 量化根因（v2）：行缓冲是 16bit 宽 → 一个 128bit 拍要写 8 次、每次 1 像素
 *   （每拍 9 个 core 周期）→ 取满一行 120 拍 ≈ **1080 周期**；而 1080p 一行只有
 *   `2200 pclk / 148.5MHz = 14.81us = 1481 core 周期(@100MHz)` → **占 73%**，
 *   只剩 ~400 周期余量给仲裁+DDR 延迟，任何抢占都会踩线。
 *
 * v2.5 改动（**只此一项，数据通路，不碰仲裁/CDC/门控**）：
 *   · 行缓冲改成直接存 **128bit 拍**（120 拍 → 128 深，1 个 BRAM/缓冲）；
 *   · 写侧：一拍一个 beat 直接进缓冲，`rready` 取数期间恒高（不再有 8 周期拆包空洞）；
 *   · 读侧：用列号低 3 位从拍里选 16bit 像素（`xlo` 需延迟 1 拍与 RAM 输出寄存对齐）；
 *   · AR 允许 1~AR_OUT 笔在飞（组合 valid，靠 beat 数封顶，**不做减法**，避免下溢），
 *     多笔在飞把 DDR 突发间的延迟藏掉 → 一行取数从 ≈1080 降到 ≈250~400 周期（约 20%）。
 *   其余（双行 ping-pong、超前 1 行门控、gray 码 CDC、像素流水线、RGB565 补位）**逐行照抄 v2**，
 *   把改动面压到最小 —— 上两次"起不来"的教训就是改动面太大、且缺少"CPU 也在读"的验证。
 *
 * 【v2.6：双缓冲 FLIP（显示基址乒乓），只加不删】
 *   动机（板级实测）：整屏 COPY 960x540 要 ~707k core 周期（7.1ms），占 60Hz 帧预算
 *   （1.667M 周期）的 42%。双缓冲本来就不需要搬像素 —— 只要**换一个显示基址**。
 *   做法：新增 `fb_sel`（请求）/`fb_cur_sel`（已生效）/`frame_cnt`（场计数）三个端口 +
 *   `FB_BASE1` 参数。fb_sel 只在 pclk 域**帧边界**锁存（保护①），再同步回 core 域、
 *   只在**取数趟边界**提交成 fb_cur_sel（保护②），取数地址只用 fb_cur_sel 算。
 *   详细论证与"为什么不会混帧"见本文件"显示缓冲选择（FLIP）"一节。
 *   ★ 不引入任何看门狗/排空/中止逻辑；`fb_sel` 恒 0 时（复位默认）行为与 v2.5 逐位相同。
 *   仿真：`rtl/tb/tb_scanout_flip.v`（含 `-DFLIP_UNLATCHED` 的 A/B 对照）。
 *
 * 【v2.7：三缓冲 FLIP + 帧边界脉冲（只加不删；fb_sel 恒 0 时与 v2.6 逐位相同）】
 *   动机：双缓冲下"画 B 的同时不能清 C"（只有两块）。三缓冲才能把整片清屏挪出
 *   关键路径（清 C / 画 B / 显示 A 三件事并行，见 rtl/clr_engine.v）。
 *   改动：
 *   ① 选择位 1 bit → 2 bit（`fb_sel[1:0]` / `fb_cur_sel[1:0]`，用到 0/1/2，3 保留）；
 *      显示基址由 `FB_BASE / FB_BASE1 / FB_BASE2` 三个**参数**经 `base_of_sel()`
 *      查表给出 —— 一个 32bit 三选一，**没有写死任何地址**。
 *   ② 跨域改成**格雷码**（多比特 CDC 的必要条件）：core 域先 `bin2gray2(fb_sel)`，
 *      pclk 域两级同步 → 帧边界锁存（仍是原来的唯一采样点），回 core 域再两级同步，
 *      最后 `gray2bin2()` 还原成二进制寄存器 `fb_cur_sel`。相邻请求码只差 1 位 ⇒
 *      任何时刻锁存到的必然是"旧值或新值"，不会出现第三种码。
 *      ★ 两级保护（帧边界锁存 + 趟边界提交）的**结构与采样点一字未改**，
 *        "一趟取数基址恒定 ⇒ 绝不混帧"的论证完全不变。
 *   ③ 新增输出 `frame_pulse`（core 域，每个场边界恰好 1 拍）：由已有的 `frame_rst`
 *      寄存一拍得到，`frame_cnt` 与中断块的 FRAME 位都用它当事件源。
 *   仿真：`rtl/tb/tb_scanout_flip.v`（三缓冲 + 任意两两互切 + 帧脉冲宽度/个数）。
 *
 * 【★S5（v3.2）：扫描输出颜色 LUT（只加不删；lut_en=0/悬空时与 v2.7 逐位相同）】
 *   动机（`doc/性能优化成果与计划.md` §7.5 P5）：全屏渐变/闪白/受击闪红今天只能靠 CPU
 *   逐像素写 DDR，而"效果代码与被测对象共用一条 DDR 读通路"已经吃过一次大亏。
 *   做法：在**行缓冲之后、串行器之前**插入 3 通道 × 2 bank × 256 项的 8bit→8bit LUT
 *   （R'=LUT_R[R] 等，再量化回 5/6/5），寄存器 0xA4/0xA8/0xAC/0xB0 在 core 域、
 *   LUT 读口在 pclk 域。bank 与使能只在**帧边界**锁存（复用 FLIP 的采样点）⇒
 *   写表不可能撕裂显示；软件用 0xB0 读回已生效 bank 判断哪张表空闲。
 *   A/B：`-DLUT_OFF`；仿真：`rtl/tb/tb_scanout_lut.v`。
 * ========================================================================= */
`timescale 1ns/1ps
module fb_scanout #(
    parameter [31:0] FB_BASE   = 32'h0030_1000,   // FB0 = DDR_BASE(0x1000)+0x300000
    /* ★ 第二个帧缓冲（双缓冲 FLIP 用）：FB1 = DDR_BASE(0x1000)+0x500000
     *   与软件侧 FB_BACK 完全一致。两个基址都是**参数**，都不写死。
     *   本文件只在别处提到 FB_BASE/FB_STRIDE —— 显示缓冲由 fb_sel 在两个参数间选。 */
    parameter [31:0] FB_BASE1  = 32'h0050_1000,   // FB1 = DDR_BASE(0x1000)+0x500000
    /* ★ 第三个帧缓冲（v2.7 三缓冲）：FB2 = DDR_BASE(0x1000)+0x700000
     *   与软件侧 FB_BUF2 完全一致。三个基址都是**参数**，一个都不写死。
     *   每块占 2MB 窗口（960*540*2 = 1.04MB），互相不重叠。 */
    parameter [31:0] FB_BASE2  = 32'h0070_1000,   // FB2 = DDR_BASE(0x1000)+0x700000
    parameter [31:0] FB_STRIDE = 32'd1920,        // 字节/行 = 960*2
    parameter [11:0] FB_W      = 12'd960,
    parameter [11:0] FB_H      = 12'd540,
    parameter [11:0] WIN_X     = 12'd0,
    parameter [11:0] WIN_Y     = 12'd0,
    /* ★ 输出放大倍数（点对点最近邻，log2）：0 = 原样 960x540；1 = 2 倍 → 1920x1080。
     *   取 1 时输出窗口正好铺满整个 active 区 ⇒ **画面无黑边**。
     *   关键：**DDR 读带宽完全不变** —— 仍然只读 960x540（1MB/帧 = 62MB/s@60fps），
     *   只是每个源像素横向/纵向各用两次、一条源行供两条输出行使用。
     *   （若改成读 1920x1080 的帧缓冲，读带宽翻倍到 ~124MB/s，正是要避免的。）
     *   SCALE_SH=0 时与 v1.0 逐位等价（par_cur = vcnt[0]^WIN_Y[0]）。 */
    parameter integer SCALE_SH = 1,
    parameter [11:0] H_ACTIVE  = 12'd1920,
    parameter [11:0] H_FP      = 12'd88,
    parameter [11:0] H_SYNC    = 12'd44,
    parameter [11:0] H_BP      = 12'd148,
    parameter [11:0] V_ACTIVE  = 12'd1080,
    parameter [11:0] V_FP      = 12'd4,
    parameter [11:0] V_SYNC    = 12'd5,
    parameter [11:0] V_BP      = 12'd36,
    parameter [7:0]  MAX_BURST = 8'd16,
    /* 同时在飞的 AR 笔数上限（1 就够藏掉突发间隙，越大越不怕 DDR 排队；
     * 对控制器读缓冲要求也越高，默认 4） */
    parameter [3:0]  AR_OUT    = 4'd4,
    /* ★★ 取数看门狗（必须有！）：S_FETCH 期间 s_hold 一直是高，而读仲裁器
     *   归还通道的条件是 `cnt_s==0 && !s_arvalid && !s_hold` —— 也就是说
     *   **只要本 FSM 卡在 S_FETCH，CPU 就永远拿不到 DDR 读通道**（而本工程整个
     *   程序都跑在 DDR 里：0x1000 起 124KB），CPU 会在下一次取指/读变量时死掉，
     *   表现就是"开机正常、跑一会儿整机静止、屏幕停在最后一帧"（板级实测：
     *   只碰 MMIO 的循环能跑 1 秒 62 万圈，一旦读 .bss/写帧缓冲立刻卡死）。
     *   所以本行取数必须有硬上限：超时就放弃本行、把通道让回去，下一轮重取。
     *   一行正常取数约 250~400 拍，显示侧一行的预算是 1481 拍，所以取 4096：
     *   既给"被 DDR 竞争拖慢"的取数留足余量，又把 CPU 最坏被锁时间钉在
     *   FETCH_TO+DRAIN_TO ≈ 8192 拍 ≈ 82us（远小于 16.7ms 一帧）。 */
    parameter [15:0] FETCH_TO   = 16'd4096,
    /* 放弃前先"排空"：保持 rready=1、s_hold=1 把已下单的突发收干净再交还通道，
     * 避免残留 R 拍在通道易主后被送给 CPU（错路写坏 CPU 的 D$）。 */
    parameter [15:0] DRAIN_TO   = 16'd4096,
    /* ★★ 硬放弃后的**强制退避**：这段时间内 s_arvalid=0 / s_hold=0，
     *   读仲裁器必然把通道交还 CPU。
     *   为什么必须有：取数失败后如果立刻重试，扫描输出会以
     *   (FETCH_TO+DRAIN_TO) 为周期无限占着读通道，CPU 只能在每个周期的
     *   一两个缝隙里挤 —— 上板表现就是"整机卡死"（CPU 整个程序都在 DDR 里）。
     *   有了退避，扫描输出对读通道的占用上限被钉死在
     *        (FETCH_TO+DRAIN_TO) / (FETCH_TO+DRAIN_TO+BACKOFF_TO) = 8192/12288 ≈ 67%
     *   ⇒ CPU 至少拿到 1/3 的读带宽，最坏也只是"慢"，绝不会"死"。
     *   代价：退避期间不取数，画面会欠载（这是可接受的降级，且 DDR 压力解除后自动恢复）。 */
    parameter [15:0] BACKOFF_TO = 16'd4096
)(
    input  wire         clk,
    input  wire         rst_n,
    /* ★ 显示缓冲选择（FLIP，见文件末尾"显示缓冲选择"一节）：
     *   fb_sel     —— core 域输入：CPU 的**请求**（0=FB_BASE 1=FB_BASE1 2=FB_BASE2）。
     *                 本模块只在 pclk 域的**帧边界**采样它，帧中途改不会立刻生效。
     *                 ★ v2.7 起是 2 bit：跨域用格雷码编码（见下面 bin2gray2/gray2bin2）。
     *   fb_cur_sel —— core 域输出：当前**取数（= 当前上屏）**所用的那个缓冲，
     *                 即"已经生效的显示缓冲"。软件读 FB_STAT[1:0] 就是读它；
     *                 清屏引擎用它做**互斥**（目标缓冲 == 本值 ⇒ 一个像素都不许写）。
     *   frame_cnt  —— core 域输出：场计数器，每个帧边界（垂直消隐起点）+1。
     *   frame_pulse—— core 域输出：帧边界 1 拍脉冲（场事件源，接中断块 FRAME 位）。
     *                 三个输出都在 core 域，软件/中断直接读，无跨域采样问题。 */
    input  wire [1:0]   fb_sel,
    output reg  [1:0]   fb_cur_sel,
    output reg  [15:0]  frame_cnt,
    output reg          frame_pulse,
    /* ★S5（v3.2）扫描输出颜色 LUT（见文件末尾"扫描输出颜色 LUT"一节）：
     *   写口在 core 域（寄存器 0xA4/0xA8/0xAC 由 blt_regs_axi_lite 给出），
     *   读口在 pclk 域（像素输出级）。lut_en / lut_bank_req 只是**请求**：
     *   两者都在 pclk 域的**帧边界**锁存（与 fb_sel 同一采样点）⇒ 一场之内只读
     *   一个 bank ⇒ 写表不可能撕裂正在显示的图像。
     *   lut_bank_act = 已生效的 bank（core 域输出 → 寄存器 0xB0 bit0）。
     *   ★ 这是一组**必须接线**的端口：悬空（z）在仿真里会经 r8/vr 传播成 x，
     *     所以既有测试台都按本工程约定显式接 0（见 tb_fb_scanout 的 `.fb_sel(2'b00)`）。 */
    input  wire         lut_wr,
    input  wire [1:0]   lut_ch,
    input  wire [7:0]   lut_idx,
    input  wire [7:0]   lut_data,
    input  wire         lut_en,
    input  wire         lut_bank_req,
    output wire         lut_bank_act,
    output wire [27:0]  m_axi_araddr,
    output wire [7:0]   m_axi_arlen,
    output wire [2:0]   m_axi_arsize,
    output wire [1:0]   m_axi_arburst,
    output wire [3:0]   m_axi_arid,
    output wire         m_axi_arvalid,
    input  wire         m_axi_arready,
    input  wire [127:0] m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,
    input  wire [3:0]   m_axi_rid,
    input  wire         m_axi_rlast,
    input  wire         m_axi_rvalid,
    output wire         m_axi_rready,
    /* 归属钉住：本行取数还没搬完（S_FETCH 期间）就拉高，交给读仲裁器，
     * 防止它在半行处把通道换走（换走 → 剩余 R 拍被送给 CPU → 本行永远等不到 → 卡死）。 */
    output wire         m_axi_hold,

    input  wire         pclk,
    input  wire         prst_n,
    output wire         vde,
    output wire         vhs,
    output wire         vvs,
    output wire [7:0]   vr,
    output wire [7:0]   vg,
    output wire [7:0]   vb,
    output wire         frame_tick,
    output wire [11:0]  dbg_line,
    /* 欠载诊断：行首(hcnt==0)就发现该行缓冲未就绪 → 这行必然从左侧开始出黑，+1。
     * 软件读加速器寄存器 0x20 低 16 位（正常恒 0）。 */
    output reg  [15:0]  dbg_underrun,
    /* 看门狗中止次数：
     *   [15:0] = 取数彻底超时（连排空都收不干净）而硬放弃本行的次数。
     *   ★ 这个计数必须恒 0。一旦非 0，说明 DDR 侧真的丢过突发 —— 它同时也意味着
     *     "CPU 曾被锁在读通道之外约 (FETCH_TO+DRAIN_TO) 拍"，是整机卡死的直接证据。 */
    output reg  [15:0]  dbg_abort
);
    localparam integer BEATS_PER_LINE = (FB_W * 2) / 16;      // 960px → 120
    localparam integer NBURST         = (BEATS_PER_LINE + MAX_BURST - 1) / MAX_BURST;

    /* 放大后输出窗口尺寸（SCALE_SH=1 时 1920x1080，正好铺满 active 区 ⇒ 无黑边） */
    localparam [11:0] DISP_W = FB_W << SCALE_SH;
    localparam [11:0] DISP_H = FB_H << SCALE_SH;

    /* clog2：行缓冲地址位宽（120 拍 → 128 深） */
    function integer clog2;
        input integer v;
        integer i;
        begin
            clog2 = 0;
            for (i = v - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction
    localparam integer ADDRW = clog2(BEATS_PER_LINE);

    /* 第 k 笔突发要请求多少拍（最后一笔可能不足 MAX_BURST） */
    function integer burst_beats;
        input integer k;
        integer left;
        begin
            left = BEATS_PER_LINE - k * MAX_BURST;
            burst_beats = (left > MAX_BURST) ? MAX_BURST : left;
        end
    endfunction

    assign m_axi_arsize  = 3'd4;      // 16 B/拍
    assign m_axi_arburst = 2'b01;     // INCR
    assign m_axi_arid    = 4'h1;

    /* ================= core_clk：行取数状态机 =================
     * 一拍一个 beat 直接写进行缓冲；AR 允许 AR_OUT 笔在飞（把突发间隙/延迟藏掉）。
     * ★ 三个状态：IDLE → FETCH →(超时)→ DRAIN → IDLE。
     *   DRAIN 存在的唯一目的：**保证 S_FETCH 一定会退出**，从而保证 s_hold 有界，
     *   从而保证 CPU 不会被永久锁在 DDR 读通道之外（见 FETCH_TO 参数处的说明）。 */
    localparam [1:0] S_IDLE = 2'd0, S_FETCH = 2'd1, S_DRAIN = 2'd2, S_BACKOFF = 2'd3;
    reg [1:0]       st;
    reg [11:0]      next_y;
    reg [11:0]      fetch_y;
    reg [31:0]      cur_addr;
    reg             buf_wsel;
    reg [ADDRW-1:0] buf_waddr;      // 当前 beat 序号（同时是行缓冲写地址）
    reg [7:0]       beat_idx;       // 本行已收到的 beat 数
    reg [7:0]       ar_idx;         // 已下发的 AR 笔数
    reg [1:0]       buf_ready;      // core 域：缓冲内容就绪
    reg [7:0]       burst_done;     // 已收到 rlast 的突发数（口径兜底用）
    reg [15:0]      fetch_to;       // S_FETCH 已持续拍数（看门狗）
    reg [15:0]      drain_to;       // S_DRAIN 已持续拍数
    reg [15:0]      backoff_to;     // S_BACKOFF 已持续拍数（强制让出通道）

    /* AR 载荷由 ar_idx 组合产生：只在握手时 ar_idx 变化 → 满足 AXI"valid 期间载荷不变" */
    assign m_axi_araddr = cur_addr + (ar_idx[3:0] * (MAX_BURST * 16));
    assign m_axi_arlen  = burst_beats(ar_idx) - 8'd1;
    /* 口径兜底/排空退出共用判定：**已下发的突发是否都收到 rlast 了**
     * （把本拍的 rlast 也算进来，因为 burst_done 是寄存器）。 */
    localparam [8:0] NBURST_N = NBURST;                 // 定宽，避免无尺寸比较
    wire       r_last_now     = m_axi_rvalid && m_axi_rready && m_axi_rlast;
    wire [8:0] bursts_seen    = {1'b0, burst_done} + {8'd0, r_last_now};
    wire       all_bursts_got = (ar_idx >= NBURST) && (bursts_seen >= NBURST_N);
    /* 在飞额度：只用两个**单调递增**量比较（`ar_idx*MAX_BURST <= beat_idx + AR_OUT*MAX_BURST`），
     * 不做减法 —— 早期版本用 (ar_idx-done_bursts) 判额度，计数一旦被打乱就下溢成 15、
     * 条件永假 → arvalid 再不拉起 → 取数 FSM 死在 S_FETCH（整行整行黑、跨帧不恢复）。
     * 这里的 AR_OUT 只是"在飞上限"，arvalid 掉下去也不影响正确性：每行的完成由
     * `beat_idx == BEATS_PER_LINE-1` 判定，与 AR/突发边界无关。 */
    assign m_axi_arvalid = (st == S_FETCH) &&
                           (ar_idx < NBURST) &&
                           ((ar_idx * MAX_BURST) <= (beat_idx + AR_OUT * MAX_BURST));

    /* 行缓冲写口：一拍一次写整拍（地址=beat 序号寄存器，数据/写使能同拍组合产生） */
    wire           buf_we    = (st == S_FETCH) && m_axi_rvalid && m_axi_rready;
    wire [127:0]   buf_wdata = m_axi_rdata;
    /* 取数期间恒接收数据（一拍一个 beat，无 8 周期拆包空洞）；
     * DRAIN 期间同样保持接收，把残留 beat 收干净再走。 */
    assign m_axi_rready = (st != S_IDLE);
    /* ★★ 归属钉住：只在"有笔突发真在飞"（或正在排空吸收残留拍）时钉住。
     *   `ar_idx != burst_done` = 有已受理的突发还没收到 rlast。
     *   S_BACKOFF 期间 ar_idx/burst_done 已清零 ⇒ s_hold=0 ⇒ 通道必然交还 CPU。 */
    assign m_axi_hold   = (ar_idx != burst_done);

    wire [11:0]    hcnt, vcnt;
    /* 读侧：拍号 = 列号>>3；拍内 16bit 像素由列号低 3 位选 */
    /* 读侧：拍号 = 列号>>3；拍内 16bit 像素由列号低 3 位选。
     * ★ 放大：源列号 = (输出列 - WIN_X) >> SCALE_SH（同一源像素被相邻两个输出列各用一次） */
    wire [11:0]    xoff     = (hcnt >= WIN_X) ? ((hcnt - WIN_X) >> SCALE_SH) : 12'd0;
    wire [ADDRW-1:0] raddr_w = xoff[11:3];
    wire [2:0]     xlo      = xoff[2:0];
    reg  [2:0]     xlo_d1;

    wire [127:0]   rdata_b0, rdata_b1;

    /* CDC：core→pixel（缓冲就绪） */
    reg  [1:0]     rdy_p0, rdy_p1;
    /* CDC：pixel→core（显示行奇偶；初值 1 允许先取第 0 行） */
    reg            line_par_p;
    reg            par_s0, par_s1;
    /* CDC：pixel→core（显示侧"当前消费的内容行号"，gray 码传输）
     * 用行号（而不是只用奇偶）才能把取数限制在"最多超前 1 行"，
     * 否则核心会顺着奇偶相同的所有行一路抢跑，把行缓冲覆盖成最后几行。 */
    reg  [11:0]    cons_p;
    reg  [11:0]    cons_g_p;
    reg  [11:0]    cons_g0, cons_g1;
    wire [11:0]    cons_s;
    /* CDC：pixel→core（每帧垂直消隐起点翻转 → core 域 1 拍脉冲 frame_rst） */
    reg            frame_tgl_p;
    reg            frm_s0, frm_s1, frm_s2;
    wire           frame_rst = frm_s1 ^ frm_s2;

    function [11:0] gray2bin;
        input [11:0] g;
        integer i;
        begin
            gray2bin[11] = g[11];
            for (i = 10; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ g[i];
        end
    endfunction

    assign cons_s = gray2bin(cons_g1);

    /* 行缓冲（双口，写 core_clk / 读 pclk）：128bit 拍 × 2^ADDRW 深
     * 读地址是**组合**地址（= 当前拍号）：RAM 自带 1 拍输出寄存，加"选拍内 16bit"
     * 与 px1/px2 两级，共 3 拍，与控制通路 win_d1→ctrl1→ctrl2 的 3 拍严格对齐。
     * 选像素用的列号低位必须**延迟 1 拍**，才与 RAM 输出寄存后的那一拍对齐。 */
    simple_dual_port_ram #(.DATA_WIDTH(128), .ADDR_WIDTH(ADDRW), .OUTPUT_REG("TRUE")) u_buf0 (
        .wdata(buf_wdata), .waddr(buf_waddr), .we(buf_we && (buf_wsel == 1'b0)),
        .wclk(clk), .raddr(raddr_w), .re(1'b1), .rclk(pclk), .rdata(rdata_b0)
    );
    simple_dual_port_ram #(.DATA_WIDTH(128), .ADDR_WIDTH(ADDRW), .OUTPUT_REG("TRUE")) u_buf1 (
        .wdata(buf_wdata), .waddr(buf_waddr), .we(buf_we && (buf_wsel == 1'b1)),
        .wclk(clk), .raddr(raddr_w), .re(1'b1), .rclk(pclk), .rdata(rdata_b1)
    );

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            rdy_p0  <= 2'b00;
            rdy_p1  <= 2'b00;
            xlo_d1  <= 3'd0;
        end else begin
            rdy_p0 <= buf_ready;
            rdy_p1 <= rdy_p0;
            xlo_d1 <= xlo;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            par_s0 <= 1'b1;
            par_s1 <= 1'b1;
        end else begin
            par_s0 <= line_par_p;
            par_s1 <= par_s0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frm_s0 <= 1'b0;
            frm_s1 <= 1'b0;
            frm_s2 <= 1'b0;
        end else begin
            frm_s0 <= frame_tgl_p;
            frm_s1 <= frm_s0;
            frm_s2 <= frm_s1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cons_g0 <= 12'd0;
            cons_g1 <= 12'd0;
        end else begin
            cons_g0 <= cons_g_p;
            cons_g1 <= cons_g0;
        end
    end

    /* ================= 显示缓冲选择（FLIP / 双缓冲乒乓） =================
     * 目标：把"整帧 COPY 上屏"换成"换一个显示基址"，同时**结构上不可能**拼出
     *       由两个缓冲混起来的帧。
     *
     * 两级保护（缺一不可）：
     *   ① pclk 域**帧边界锁存**：CPU 的请求 fb_sel 先做 core→pclk 两级同步，
     *      只在 `hcnt==0 && vcnt==V_ACTIVE`（垂直消隐起点，与上面 frame_tgl_p 同一个
     *      事件）采样进 fb_sel_lat。⇒ 帧中途改请求，本场绝不会被看到，下一场才生效。
     *   ② core 域**趟边界提交**：pclk 的锁存值再同步回 core 域，并且只在
     *      `st==S_IDLE && next_y==0`（本趟取数一行都还没取）时抄进 fb_cur_sel。
     *      取数地址 cur_addr 只用 fb_cur_sel 算 ⇒ **一趟取数（= 一场的 540 行）
     *      用的基址恒定**。即使 ① 的同步值晚到几拍（它确实会晚 2~3 拍），也不可能在
     *      任何一趟中途换基址。而显示侧的行缓冲是乒乓 + "最多超前 1 行"取数，
     *      一场显示的行必然来自同一趟取数 ⇒ **不会混帧**。
     *
     * 代价/时延：请求写进 FB_SEL 后，最多下一场生效（正常就是下一场：帧边界与
     *   本窗口之间隔着整个垂直消隐 ≈45 行 ≈ 6.6 万 core 周期，同步早就稳定了）。
     *   若帧边界那一刻取数 FSM 恰好不在 IDLE（罕见的 DDR 卡顿），本场跳过，
     *   下一场边界再提交 —— 软件侧用 FB_STAT 的有界等待兜住这种情况。
     *
     * A/B 对照：`-DFLIP_UNLATCHED` 把两级保护全部旁路（请求直通取数基址），
     *   用于证明 tb_scanout_flip 真的能抓到"帧中途换缓冲 ⇒ 混帧"。默认不定义。
     *
     * ★ v2.7 多比特 CDC（1 bit → 2 bit）：两位**同时变**时，同一个时钟沿上两级同步器
     *   的两个触发器可能各自采到新旧不同的位 ⇒ 锁存出一个"第三种码"（如 01→10 时
     *   采到 00 或 11）。这里用**格雷码**消除它：编码后相邻选择只差 1 位，
     *   任何采样时刻的结果必然是"旧码或新码"。两个方向的跨域都走格雷码，
     *   只在最后（core 域、进 fb_cur_sel 之前）还原成二进制。
     *   选择序列 0→1→2 对应格雷 00→01→11（软件若按 0→2 直接跳，则两位同时变，
     *   锁到的可能仍是旧值/新值之一，绝不会锁出 3 号缓冲）。 */
    function [1:0] bin2gray2;
        input [1:0] b;
        begin bin2gray2 = b ^ (b >> 1); end
    endfunction
    function [1:0] gray2bin2;
        input [1:0] g;
        begin gray2bin2 = {g[1], g[1] ^ g[0]}; end
    endfunction

    wire [1:0] fb_sel_g = bin2gray2(fb_sel);         // core 域：请求 → 格雷码

    reg  [1:0] fb_sel_p0, fb_sel_p1;  // core → pclk 两级同步（格雷码，每次只变 1 位）
    reg  [1:0] fb_sel_lat;            // pclk 域：帧边界锁存值（格雷码）
    reg  [1:0] fb_lat_c0, fb_lat_c1;  // pclk → core 两级同步（格雷码）
    wire [1:0] fb_lat_bin = gray2bin2(fb_lat_c1);    // core 域：还原成二进制

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            fb_sel_p0  <= 2'b00;
            fb_sel_p1  <= 2'b00;
            fb_sel_lat <= 2'b00;
        end else begin
            fb_sel_p0 <= fb_sel_g;
            fb_sel_p1 <= fb_sel_p0;
            /* ★ 唯一采样点：帧边界（与 frame_tgl_p / cons_p 用的同一时刻） */
            if ((hcnt == 12'd0) && (vcnt == V_ACTIVE))
                fb_sel_lat <= fb_sel_p1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fb_lat_c0 <= 2'b00;
            fb_lat_c1 <= 2'b00;
        end else begin
            fb_lat_c0 <= fb_sel_lat;
            fb_lat_c1 <= fb_lat_c0;
        end
    end

    /* 趟边界：取数 FSM 空闲且本趟还没取第 0 行（next_y 只在 frame_rst / 复位时归零，
     * 每取一行就 +1）⇒ 此刻改基址不会让任何一趟里出现两个缓冲。 */
    wire pass_start = (st == S_IDLE) && (next_y == 12'd0);

`ifdef FLIP_UNLATCHED
    /* A/B 对照（只用于仿真）：完全不锁存 —— 请求直通，取数下一行就可能换缓冲。 */
    wire [1:0]  flip_sel_eff = fb_sel;
`else
    wire [1:0]  flip_sel_eff = fb_lat_bin;
`endif

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fb_cur_sel <= 2'd0;
`ifdef FLIP_UNLATCHED
        else        fb_cur_sel <= flip_sel_eff;
`else
        else if (pass_start) fb_cur_sel <= flip_sel_eff;
`endif
    end

    /* 当前趟的取数基址：**基址查表**（三个缓冲都是参数，不写死任何地址）。
     * 只有 fb_cur_sel 参与，一趟之内恒定 ⇒ 不会混帧。 */
    function [31:0] base_of_sel;
        input [1:0] s;
        begin
            case (s)
                2'd0:    base_of_sel = FB_BASE;
                2'd1:    base_of_sel = FB_BASE1;
                2'd2:    base_of_sel = FB_BASE2;
                default: base_of_sel = FB_BASE;   // 3 = 保留，回落到 FB0（绝不悬空）
            endcase
        end
    endfunction

`ifdef FLIP_UNLATCHED
    wire [31:0] cur_base = base_of_sel(flip_sel_eff);
`else
    /* ★ 同拍竞态的消除：`fb_cur_sel` 的提交（本 always 块）与 S_IDLE 里
     *   `cur_addr <= cur_base + next_y*FB_STRIDE` 是**同一个时钟沿**的两个非阻塞赋值。
     *   若第 0 行的取数恰好就在 pass_start 这一拍启动，`cur_base` 读到的还是**上一场的旧值**
     *   ⇒ 第 0 行取旧缓冲（真混帧）。现网配置（V_ACTIVE=1080 / WIN_Y=0 / SCALE_SH=1）下
     *   被 `next_y[0] != par_s1` 间接挡住而没有触发，但这是**埋伏的**（例如 V_ACTIVE=30 就会踩）。
     *   这里让"正在提交的那一拍"直接用待提交值 ⇒ 同拍启动的第 0 行必然用新基址；
     *   其余任何一拍 pass_start 都为假，仍用已提交的 fb_cur_sel ⇒ **一趟之内基址依然恒定**。 */
    wire [31:0] cur_base = base_of_sel(pass_start ? flip_sel_eff : fb_cur_sel);
`endif

    /* 场计数：在 core 域按已经同步好的 frame_rst（每场恰好 1 拍脉冲）累加。
     * 输出本身就是 core 域寄存器 ⇒ 软件读走 APB/AXI-Lite 没有任何跨域问题。 */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)       frame_cnt <= 16'd0;
        else if (frame_rst) frame_cnt <= frame_cnt + 16'd1;
    end

    /* ★ v2.7 帧边界脉冲：core 域、每个场边界恰好 1 拍。
     *   来源就是上面那个已经同步好的 frame_rst（frm_s1 ^ frm_s2，恒 1 拍宽），
     *   再寄存一拍 ⇒ 与本模块其它输出同为**寄存器输出**，扇出到中断块/软件都干净。
     *   它与 frame_cnt 的自增是**同一拍**（两者都由 frame_rst 寄存），tb_scanout_flip
     *   直接断言了这一点（"frame_cnt 自增那一拍必有脉冲"，0 违例）。 */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)         frame_pulse <= 1'b0;
        else                frame_pulse <= frame_rst;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st         <= S_IDLE;
            next_y     <= 12'd0;
            fetch_y    <= 12'd0;
            cur_addr   <= 32'd0;
            buf_wsel   <= 1'b0;
            buf_waddr  <= {ADDRW{1'b0}};
            beat_idx   <= 8'd0;
            ar_idx     <= 8'd0;
            buf_ready  <= 2'b00;
            burst_done <= 8'd0;
            fetch_to   <= 16'd0;
            drain_to   <= 16'd0;
        end else begin
            case (st)
                S_IDLE: begin
                    /* 垂直消隐期：为下一帧从头开始取数（否则第一帧取完 540 行后就停在
                     * next_y==FB_H，屏幕会一直重复最后一两行）。仅在 IDLE 时重置，
                     * 避免打断正在进行中的 AXI 突发。 */
                    if (frame_rst) begin
                        next_y    <= 12'd0;
                        buf_ready <= 2'b00;
                    end
                    /* 取数门控：最多比"显示侧正在消费的行"超前 1 行，且不写正在显示的那个缓冲。 */
                    else if ((next_y < FB_H) &&
                             (next_y <= (cons_s + 12'd1)) &&
                             (next_y[0] != par_s1)) begin
                        fetch_y    <= next_y;
                        buf_wsel   <= next_y[0];
                        /* ★ 基址来自"本趟已提交"的 fb_cur_sel（帧边界锁存 + 趟边界提交）：
                         *   一趟之内恒定 ⇒ 不会混帧。fb_cur_sel=0 时与改动前逐位等价。 */
                        cur_addr   <= cur_base + (next_y * FB_STRIDE);
                        buf_waddr  <= {ADDRW{1'b0}};
                        beat_idx   <= 8'd0;
                        ar_idx     <= 8'd0;
                        burst_done <= 8'd0;
                        fetch_to   <= 16'd0;
                        /* ★ 必须一起清零：否则上一次 DRAIN 中止后残留的大值会让
                         *   下一次排空**立刻**超时。tb_scanout_wd 专门注入两个硬故障行
                         *   来盯这一点（注掉本行 → hold_min 从 133 掉到 69 → FAIL）。 */
                        drain_to   <= 16'd0;
                        buf_ready[next_y[0]] <= 1'b0;
                        st         <= S_FETCH;
                    end
                end

                S_FETCH: begin
                    /* AR：只做计数，valid/载荷由上面的组合逻辑产生 */
                    if (m_axi_arvalid && m_axi_arready)
                        ar_idx <= ar_idx + 8'd1;

                    /* R：一拍一个 beat 进缓冲；收到整行即完成（与 AR/突发边界无关，最稳） */
                    if (m_axi_rvalid && m_axi_rready) begin
                        buf_waddr <= buf_waddr + {{(ADDRW-1){1'b0}}, 1'b1};
                        beat_idx  <= beat_idx + 8'd1;
                        fetch_to  <= 16'd0;                       // 有数据就不算卡
                        if (m_axi_rlast)
                            burst_done <= burst_done + 8'd1;
                        if (beat_idx == (BEATS_PER_LINE - 1)) begin
                            buf_ready[buf_wsel] <= 1'b1;          // 整行就绪
                            next_y <= fetch_y + 12'd1;
                            st     <= S_IDLE;
                        end
                        /* ★ 口径兜底：已下发的突发全部收到 rlast，但 beat 数没到齐
                         *   （例如从机对某笔突发少回了几拍）→ 也认定本行结束。
                         *   画面可能有一小段错位，但**绝不会把 FSM 永久卡在 S_FETCH**。 */
                        else if (all_bursts_got) begin
                            buf_ready[buf_wsel] <= 1'b1;
                            next_y <= fetch_y + 12'd1;
                            st     <= S_IDLE;
                        end
                    end
                    else begin
                        /* 没有数据在流：累计等待拍数，到点转 DRAIN（不立刻交还通道，
                         * 先把可能的残留 beat 排空，见 DRAIN 说明）。 */
                        if (fetch_to != 16'hFFFF)
                            fetch_to <= fetch_to + 16'd1;
                        if (fetch_to >= FETCH_TO)
                            st <= S_DRAIN;
                    end
                end

                /* ★ 排空：保持 rready=1 / s_hold=1，把已下单突发的残留 R 拍收干净，
                 *   然后不标 ready 地放弃本行（next_y 不动 → 下一轮重取同一行）。
                 *   这样交还通道时**一定没有在飞的 R 拍**，不会错路给 CPU。
                 *   只有连排空都超时（从机真的把数据丢了）才硬放弃 —— 这是唯一
                 *   "宁可冒错路风险也要放开总线"的场合，用 dbg_abort 计数记录。 */
                S_DRAIN: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        drain_to <= 16'd0;
                        if (m_axi_rlast)
                            burst_done <= burst_done + 8'd1;
                    end
                    else if (drain_to != 16'hFFFF)
                        drain_to <= drain_to + 16'd1;

                    if (all_bursts_got)
                        st <= S_IDLE;                    // 收干净了（正常路径）
                    else if (drain_to >= DRAIN_TO) begin
                        /* 硬放弃：产生一次 dbg_abort 事件（经翻转位同步到 pclk 域累加），
                         * 清掉突发账本让 s_hold 立刻落下，然后**强制退避**：
                         * 退避期间 s_arvalid=0 / s_hold=0，读通道必然回到 CPU。
                         * 这是"CPU 绝不被永久锁死"的硬保证（占用上限 67%）。 */
                        ar_idx     <= 8'd0;
                        burst_done <= 8'd0;
                        backoff_to <= 16'd0;
                        st         <= S_BACKOFF;
                    end
                end

                /* ★ 强制退避：把读通道让给 CPU 一段时间后再重取本行（next_y 不动）。
                 *   代价是这段不取数 → 画面欠载；但换来的是 CPU 一定活得下去。 */
                S_BACKOFF: begin
                    if (backoff_to != 16'hFFFF)
                        backoff_to <= backoff_to + 16'd1;
                    if (backoff_to >= BACKOFF_TO)
                        st <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end

    assign dbg_line = fetch_y;

    /* ★ 硬放弃事件 → pclk 域（dbg_abort 是 pclk 域寄存器）：
     *   多位计数器不能直接跨域，用"每次事件翻转一次"的单比特 toggle 最稳。 */
    wire wd_abort_ev = (st == S_DRAIN) && !all_bursts_got && (drain_to >= DRAIN_TO);
    reg  wd_tgl;;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          wd_tgl <= 1'b0;
        else if (wd_abort_ev) wd_tgl <= ~wd_tgl;
    end

    /* ================= pixel_clk：1080p 时序 + 窗口像素 ================= */
    wire        de, hs, vs;

    video_timing_1080p #(
        .H_ACTIVE(H_ACTIVE), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP),
        .V_ACTIVE(V_ACTIVE), .V_FP(V_FP), .V_SYNC(V_SYNC), .V_BP(V_BP)
    ) u_timing (
        .pclk(pclk), .prst_n(prst_n),
        .hcnt(hcnt), .vcnt(vcnt),
        .de(de), .hs(hs), .vs(vs),
        .line_start(), .frame_start(frame_tick)
    );

    /* ★ 放大：输出窗口 = 源窗口的 SCALE 倍 ⇒ SCALE_SH=1 时 1920x1080 铺满，无黑边 */
    wire in_win_x = (hcnt >= WIN_X) && (hcnt < (WIN_X + DISP_W));
    wire in_win_y = (vcnt >= WIN_Y) && (vcnt < (WIN_Y + DISP_H));
    wire win_now  = in_win_x && in_win_y;
    /* 输出行相对窗口起点的偏移，以及它对应的**源行号** */
    wire [11:0] vrel = (vcnt >= WIN_Y) ? (vcnt - WIN_Y) : 12'd0;
    wire [11:0] vsrc = vrel >> SCALE_SH;
    /* 缓冲奇偶 = 源行号最低位：SCALE_SH=0 时即 vcnt[0]^WIN_Y[0]（与 v1.0 等价）；
     * SCALE_SH=1 时每两条输出行才换一次源行（纵向最近邻放大）。 */
    wire par_cur  = (SCALE_SH == 0) ? vrel[0] : vrel[1];
    wire buf_ok   = par_cur ? rdy_p1[1] : rdy_p1[0];

    /* 每帧垂直消隐起点翻转一次 → core 域据此重新从第 0 行开始取数，
     * 让下一帧的第 0/1 行在消隐期（约 45 行时间）就预取好 */
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n)
            frame_tgl_p <= 1'b0;
        else if ((hcnt == 12'd0) && (vcnt == V_ACTIVE))
            frame_tgl_p <= ~frame_tgl_p;
    end

    /* 显示侧"当前消费的**源**内容行号"：窗口内 = (vcnt-WIN_Y)>>SCALE_SH，消隐期 = 0
     * （下一帧从第 0 行开始）。用 gray 码送出，保证跨时钟采样时每次只有 1 位在变。 */
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            cons_p   <= 12'd0;
            cons_g_p <= 12'd0;
        end else if (hcnt == 12'd0) begin
            if (in_win_y) begin
                cons_p   <= vsrc;
                cons_g_p <= vsrc ^ (vsrc >> 1);
            end else begin
                cons_p   <= 12'd0;
                cons_g_p <= 12'd0;
            end
        end
    end

    reg  win_d1, win_d2;
    /* 硬放弃 toggle 的两级同步（core → pclk）+ 边沿检测 */
    reg  wd_t1, wd_t2, wd_t3;
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            wd_t1 <= 1'b0; wd_t2 <= 1'b0; wd_t3 <= 1'b0;
        end else begin
            wd_t1 <= wd_tgl;
            wd_t2 <= wd_t1;
            wd_t3 <= wd_t2;
        end
    end
    wire wd_ev_p = wd_t2 ^ wd_t3;      // 每次翻转产生一个 pclk 周期脉冲

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            line_par_p   <= 1'b0;
            win_d1       <= 1'b0;
            win_d2       <= 1'b0;
            dbg_underrun <= 16'd0;
            dbg_abort    <= 16'd0;
        end else begin
            if (hcnt == 12'd0)
                line_par_p <= par_cur;
            win_d1 <= win_now && buf_ok;
            win_d2 <= win_d1;
            if ((hcnt == 12'd0) && win_now && !buf_ok)
                dbg_underrun <= dbg_underrun + 16'd1;
            if (wd_ev_p)
                dbg_abort    <= dbg_abort + 16'd1;
        end
    end

    /* 选拍（par_cur 每个显示行只在 hcnt==0 处变化，对齐关系同 v2） */
    wire [127:0] beat_sel = par_cur ? rdata_b1 : rdata_b0;
    /* 从 128bit 拍里取 16bit 像素：列号低 3 位 × 16bit（选拍号延迟 1 拍对齐 RAM 输出寄存） */
    wire [15:0]  px565 = beat_sel >> {xlo_d1, 4'd0};

    reg [3:0]  ctrl1, ctrl2;
    reg [15:0] px1, px2;
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            ctrl1 <= 4'd0; ctrl2 <= 4'd0;
            px1   <= 16'd0; px2  <= 16'd0;
        end else begin
            ctrl1 <= {de, win_d1, hs, vs};
            ctrl2 <= ctrl1;
            px1   <= px565;
            px2   <= px1;
        end
    end

    /* =========================================================================
     * ★S5（v3.2）扫描输出颜色 LUT：R'=LUT_R[R] / G'=LUT_G[G] / B'=LUT_B[B]
     * -------------------------------------------------------------------------
     * 结构：三个通道各一块 512×8 双口 RAM（地址 = {bank, index[7:0]}，两个 bank
     *   共用一块 RAM 的不同半区）；写口 = core 域 clk，读口 = pclk 域。
     * 时序（为什么**不加流水级、不产生 1 像素相位偏移**）：
     *   读地址由**px1 那一级**（行缓冲输出后第 1 拍）组合给出 —— RAM 自带 1 拍输出
     *   寄存 ⇒ LUT 输出与 px2（第 2 拍）**同拍** ⇒ vr/vg/vb 与 ctrl2(vde/hs/vs) 的
     *   对齐关系与改动前**完全相同**（LUT 只是插在 r8/g8/b8 与输出之间的一个 mux）。
     * 输出级：把 8bit 表值**量化回 5/6/5，再用与行缓冲 RGB565→888 完全相同的抽头
     *   复制回 8bit**（= 补字段的**低位**，见文件末尾输出级的注释）：
     *     · 关闭（复位默认 / 端口悬空）⇒ 直接输出今天的 r8/g8/b8 ⇒ 逐位相同；
     *     · 开启且表为恒等 LUT[i]=i ⇒ lut_*_o == r8/g8/b8，量化回 5/6/5 再按同一抽头
     *       复制 = 原值 ⇒ **同样逐位相同**（tb_scanout_lut T2 与 tb_lut_proto T4 断言
     *       这条；后者是"AXI-Lite → 寄存器 → 写脉冲 → LUT → 屏幕"的端到端版本，
     *       2026-09-16 就是它抓到输出级抽头与旁路不一致的）。
     * 为什么写表不会撕裂显示（三条一起才成立）：
     *   ① **写口与显示口永远指向不同的 bank**：写地址用的是 0xAC bit1 的**当前值**
     *      （"写入 bank"），而显示的读地址用的是 `~lut_bk_lat` —— 即**另一个** bank。
     *      于是"正在显示的那张表"在物理上不可能被表写碰到（两个 bank 是 RAM 里不同
     *      的地址区）⇒ 写表期间屏幕**逐像素不变**（tb_scanout_lut T5 的监视器断言）。
     *   ② **显示 bank 只在帧边界换**：`lut_bk_lat` 与使能 `lut_en_lat` 的唯一采样点是
     *      `hcnt==0 && vcnt==V_ACTIVE`（与 fb_sel_lat / frame_tgl_p 同一时刻）⇒ 一场
     *      之内只读一个 bank，绝不会半场换表、也不会半场开关 LUT。
     *   ③ 软件协议只有一条：**读完 LUT_STAT（当前显示的 bank）→ 把新表整张写进去
     *      （自动落到另一个 bank）→ 最后写一次 0xAC bit1**（= 把刚写好的那个 bank
     *      选成"要显示的下一个 bank"）⇒ 下一次帧边界生效。表写期间不要翻 bit1。
     * 复位后：bit1=0 ⇒ 写入 bank0、显示 bank1（LUT 默认关闭，屏幕不受任何影响）。
     * A/B 逃生门：`-DLUT_OFF` 把使能恒置 0（LUT 通路保留但永不生效）。
     * ========================================================================= */
    /* ---- 写口译码（core 域）：通道 0/1/2 各有一张表；通道 3 保留 ⇒ 不写 ----
     * ★ 老 TB 必须**显式**把本组端口接 0（本工程既有约定，见 tb_fb_scanout 的
     *   `.fb_sel(2'b00)` 注释）：仿真里悬空输入是 z，而 z 经 if/case 都会传播成 x
     *   （iverilog 实测：`if (z)` 与 `case (z) 1'b1: ... default:` 都返回 x），
     *   唯一可靠的做法就是接线，而不是在 RTL 里"猜"悬空。 */
    wire        lut_we_r = lut_wr && (lut_ch == 2'd0);
    wire        lut_we_g = lut_wr && (lut_ch == 2'd1);
    wire        lut_we_b = lut_wr && (lut_ch == 2'd2);
`ifdef LUT_OFF
    wire        lut_en_eff = 1'b0;          // A/B 逃生门：LUT 通路保留但永不生效
`else
    wire        lut_en_eff = lut_en;
`endif

    /* ---- core → pclk 两级同步 + **帧边界**锁存（与 fb_sel_lat 同款） ---- */
    reg        lut_en_p0, lut_en_p1, lut_bk_p0, lut_bk_p1;
    reg        lut_en_lat, lut_bk_lat;
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            lut_en_p0 <= 1'b0; lut_en_p1 <= 1'b0;
            lut_bk_p0 <= 1'b0; lut_bk_p1 <= 1'b0;
            lut_en_lat<= 1'b0; lut_bk_lat<= 1'b0;
        end else begin
            lut_en_p0 <= lut_en;                 // 请求（core 域，已由寄存器组寄存）
            lut_en_p1 <= lut_en_p0;
            lut_bk_p0 <= lut_bank_req;
            lut_bk_p1 <= lut_bk_p0;
            /* ★ 唯一采样点：帧边界（与 frame_tgl_p / fb_sel_lat 同一时刻） */
            if ((hcnt == 12'd0) && (vcnt == V_ACTIVE)) begin
                lut_en_lat <= lut_en_p1;
                lut_bk_lat <= lut_bk_p1;
            end
        end
    end

    /* ---- pclk → core 同步（已生效 bank → 寄存器 0xB0 bit0） ---- */
    reg        lut_bk_c0, lut_bk_c1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_bk_c0 <= 1'b0;
            lut_bk_c1 <= 1'b0;
        end else begin
            lut_bk_c0 <= lut_bk_lat;
            lut_bk_c1 <= lut_bk_c0;
        end
    end
    assign lut_bank_act = ~lut_bk_c1;       // 已**显示**的 bank（= 写入 bank 的反相）

    /* ---- 三张表（每通道 512×8：{bank, index}） ----
     * 写 bank = 0xAC bit1 的当前值；读 bank = 帧边界锁存值取反（= 另一个 bank） */
    wire [8:0]  lut_wa   = {lut_bank_req, lut_idx};      // 写地址（core 域：目标 bank）
    wire [7:0]  r8_1 = {px1[15:11], px1[15:13]};         // 表输入 = 与今天同抽头的 8bit 展开
    wire [7:0]  g8_1 = {px1[10:5],  px1[7:6]};
    wire [7:0]  b8_1 = {px1[4:0],   px1[2:0]};
    wire [8:0]  lut_ra_r = {~lut_bk_lat, r8_1};          // 读地址（pclk 域，bank = 显示）
    wire [8:0]  lut_ra_g = {~lut_bk_lat, g8_1};
    wire [8:0]  lut_ra_b = {~lut_bk_lat, b8_1};
    wire [7:0]  lut_r_o, lut_g_o, lut_b_o;

    simple_dual_port_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(9), .OUTPUT_REG("TRUE")) u_lut_r (
        .wdata(lut_data), .waddr(lut_wa), .we(lut_we_r),
        .wclk(clk), .raddr(lut_ra_r), .re(1'b1), .rclk(pclk), .rdata(lut_r_o)
    );
    simple_dual_port_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(9), .OUTPUT_REG("TRUE")) u_lut_g (
        .wdata(lut_data), .waddr(lut_wa), .we(lut_we_g),
        .wclk(clk), .raddr(lut_ra_g), .re(1'b1), .rclk(pclk), .rdata(lut_g_o)
    );
    simple_dual_port_ram #(.DATA_WIDTH(8), .ADDR_WIDTH(9), .OUTPUT_REG("TRUE")) u_lut_b (
        .wdata(lut_data), .waddr(lut_wa), .we(lut_we_b),
        .wclk(clk), .raddr(lut_ra_b), .re(1'b1), .rclk(pclk), .rdata(lut_b_o)
    );

    /* ---- 输出级：把 8bit 表值量化回 5/6/5，再用**与旁路完全相同的**展开规则复制回 8bit ----
     * ★ 口径必须与下面的 r8/g8/b8 逐位一致（这是"恒等表 LUT[i]=i + 使能 == 关闭 LUT"
     *   这条兼容性不变量的**结构性**保证，tb_lut_proto 的 T4 硬测这一条）：
     *   旁路用的是"把字段的**低位**补到低位"（r5[2:0] / g6[2:1] / b5[2:0]，见下面的 r8/g8/b8），
     *   所以这里也必须补低位：{rq5, rq5[2:0]} / {gq6, gq6[2:1]} / {bq5, bq5[2:0]}。
     *   恒等表时 lut_r_o == r8 ⇒ rq5 = r8[7:3]，{rq5, rq5[2:0]} 逐位还原 r8（G 同理）。
     * ★ 历史：本行原来是"复制字段**高位**"（{rq5, rq5[4:2]} / {gq6, gq6[5:4]} / {bq5, bq5[4:2]}）。
     *   两种做法满量程都是 255，中间码只差 1~7 个 LSB，肉眼看不出来，但**破坏**了上面那条
     *   不变量 —— 2026-09-16 由 rtl/tb/tb_lut_proto.v 的 T4 逐像素比对抓到（关 LUT 与
     *   恒等表+使能整场 2048 像素全部差在 G，R/B 部分码值也差）。
     * ★ 把**整条视频通路**（含旁路 856-858 与 rtl/pixel_path.v 的展开）统一改成"复制高位"
     *   是另一件**会改变现有画面颜色（最多 7 LSB）**的事，属于用户/上板验收的决定，
     *   本模块不单方面改 —— 这里只保证 LUT 通路与旁路**同口径**（改动最小、旧行为零变化）。 */
    wire [4:0] rq5 = lut_r_o[7:3];
    wire [5:0] gq6 = lut_g_o[7:2];
    wire [4:0] bq5 = lut_b_o[7:3];
    wire [7:0] r_lut8 = {rq5, rq5[2:0]};
    wire [7:0] g_lut8 = {gq6, gq6[2:1]};
    wire [7:0] b_lut8 = {bq5, bq5[2:0]};

    assign vde = ctrl2[3];
    assign vhs = ctrl2[1];
    assign vvs = ctrl2[0];
    /* RGB565 → RGB888：低位补高位（保证 8 位结果的高 5/6/5 位仍是原分量，
     * 这是与软件侧/测试台对齐的关键）。注意绿分量是 6 位，补位只能补 2 位
     * （{px2[10:5], px2[7:6]}）。原来写成 {px2[10:5], px2[8:5]} 是 10 位拼接，
     * 赋值给 8 位 wire 时被截断成低 8 位 → 整个绿色通道比特错位。
     * ★S5：这两组值（r8/g8/b8）同时是 LUT 的旁路值 —— lut_en=0 时逐位等于改动前；
     *   ★ 它们还是 LUT 输出级（本文件"输出级"一节）必须对齐的**口径基准**：补的是字段低位
     *   （r5[2:0] / g6[2:1] / b5[2:0]），LUT 输出级就补同样的位 ⇒ 恒等表 + 使能
     *   与 lut_en=0 逐位相同（tb_lut_proto 的 T4）。改这里的抽头必须同步改输出级。 */
    wire [7:0] r8 = {px2[15:11], px2[13:11]};
    wire [7:0] g8 = {px2[10:5],  px2[7:6]};
    wire [7:0] b8 = {px2[4:0],   px2[2:0]};
    assign vr = ctrl2[2] ? (lut_en_eff ? r_lut8 : r8) : 8'h00;
    assign vg = ctrl2[2] ? (lut_en_eff ? g_lut8 : g8) : 8'h00;
    assign vb = ctrl2[2] ? (lut_en_eff ? b_lut8 : b8) : 8'h00;
endmodule
