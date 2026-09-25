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
 * ========================================================================= */
`timescale 1ns/1ps
module fb_scanout #(
    parameter [31:0] FB_BASE   = 32'h0030_1000,   // FB0 = DDR_BASE(0x1000)+0x300000
    parameter [31:0] FB_STRIDE = 32'd1920,        // 字节/行 = 960*2
    parameter [11:0] FB_W      = 12'd960,
    parameter [11:0] FB_H      = 12'd540,
    parameter [11:0] WIN_X     = 12'd0,
    parameter [11:0] WIN_Y     = 12'd0,
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
    wire [11:0]    xoff     = (hcnt >= WIN_X) ? (hcnt - WIN_X) : 12'd0;
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
                        cur_addr   <= FB_BASE + (next_y * FB_STRIDE);
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
    wire wd_abort_ev = (st == S_DRAIN) && !all_bursts_got && (drain_to >= DRAIN_TO);    reg  wd_tgl;
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

    wire in_win_x = (hcnt >= WIN_X) && (hcnt < (WIN_X + FB_W));
    wire in_win_y = (vcnt >= WIN_Y) && (vcnt < (WIN_Y + FB_H));
    wire win_now  = in_win_x && in_win_y;
    wire par_cur  = vcnt[0] ^ WIN_Y[0];
    wire buf_ok   = par_cur ? rdy_p1[1] : rdy_p1[0];

    /* 每帧垂直消隐起点翻转一次 → core 域据此重新从第 0 行开始取数，
     * 让下一帧的第 0/1 行在消隐期（约 45 行时间）就预取好 */
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n)
            frame_tgl_p <= 1'b0;
        else if ((hcnt == 12'd0) && (vcnt == V_ACTIVE))
            frame_tgl_p <= ~frame_tgl_p;
    end

    /* 显示侧"当前消费的内容行号"：窗口内 = vcnt-WIN_Y，消隐期 = 0（下一帧从第 0 行开始）。
     * 用 gray 码送出，保证跨时钟采样时每次只有 1 位在变，采样结果非旧即新。 */
    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            cons_p   <= 12'd0;
            cons_g_p <= 12'd0;
        end else if (hcnt == 12'd0) begin
            if ((vcnt >= WIN_Y) && (vcnt < (WIN_Y + FB_H)))
                cons_p <= (vcnt - WIN_Y);
            else
                cons_p <= 12'd0;
            cons_g_p <= ((vcnt >= WIN_Y) && (vcnt < (WIN_Y + FB_H)))
                        ? ((vcnt - WIN_Y) ^ ((vcnt - WIN_Y) >> 1))
                        : 12'd0;
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

    assign vde = ctrl2[3];
    assign vhs = ctrl2[1];
    assign vvs = ctrl2[0];
    /* RGB565 → RGB888：低位补高位（保证 8 位结果的高 5/6/5 位仍是原分量，
     * 这是与软件侧/测试台对齐的关键）。注意绿分量是 6 位，补位只能补 2 位
     * （{px2[10:5], px2[7:6]}）。原来写成 {px2[10:5], px2[8:5]} 是 10 位拼接，
     * 赋值给 8 位 wire 时被截断成低 8 位 → 整个绿色通道比特错位。 */
    wire [7:0] r8 = {px2[15:11], px2[13:11]};
    wire [7:0] g8 = {px2[10:5],  px2[7:6]};
    wire [7:0] b8 = {px2[4:0],   px2[2:0]};
    assign vr = ctrl2[2] ? r8 : 8'h00;
    assign vg = ctrl2[2] ? g8 : 8'h00;
    assign vb = ctrl2[2] ? b8 : 8'h00;
endmodule
