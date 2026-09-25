/* =========================================================================
 * clr_engine.v — 并发清屏引擎（独立写通道主机，把"整片重铺"挪出关键路径）
 * -------------------------------------------------------------------------
 * 【为什么需要它（板级实测数字）】
 *   一个 32x32 块的 FILL 只要 947 core 周期，但"每趟把 960x524 渲染区重铺成
 *   背景色"要 **568,000 周期**（60Hz 帧预算 1,666,667 的 34%）。而这 568k 是
 *   由 BitBlt 引擎当一条普通 FILL 指令执行的 ⇒ **整条指令流的完成时刻被它顶住**。
 *   本模块把"清一块矩形到常量颜色"做成**第二个、独立的写主机**：软件在画 B、
 *   显示 A 的时候让本引擎去清 C，三件事并行 ⇒ 清屏不再进关键路径。
 *
 * 【与 BitBlt 写通道的关系】
 *   本模块只输出"合并后的 16 拍 INCR 突发"（与 rtl/axi_wr_master.v 同口径），
 *   在 rtl/blt_top.v 里经**同一个 axi_wr_arb** 与 BitBlt 写主机合流：
 *   BitBlt 侧接仲裁器的 `c_`（默认 owner / 直通），本引擎接 `b_`（次级）。
 *   ★ 仲裁的**实际**语义（tb_clear_engine 的 4A/4B 用例量过，别把注释读得太满）：
 *     · c_ 侧只要"没有在飞写突发"（cnt_c==0 && !c_wvalid），次级当场就能拿到通道，
 *       并且**独占一整笔**（≤16 拍 + B）；c_awvalid 一直举着时次级根本抢不到（实测 0/120）。
 *     · 但 BitBlt 的 axi_wr_master 是 AW→W→B 串行、突发之间有 1~2 拍 awvalid=0，
 *       所以真机上清屏引擎**每笔都能抢一次**：同口径竞争者 64 笔被拖慢 2.07×，
 *       清屏拿到 52.5% 的突发 ⇒ "BitBlt 赢"应理解为"**默认 owner + 一笔之内就能拿回**"，
 *       而不是"清屏拿不到通道"。
 *     · 这是有意的取舍：本工程 BitBlt 是**像素通路受限**（~0.89~1.08 像素/周期），
 *       写通道有大富余（AW 事务砍 16 倍而帧时间不动）⇒ 清屏填空档几乎不花它的时间。
 *       若将来需要严格优先，收紧 `axi_wr_arb.yield_b` 的门槛即可（见功能清单 §21.8 第 6 条）。
 *   ⇒ 默认**一行软件都不改**时（从不写 CLR_CTRL.GO）本引擎 awvalid 恒 0，
 *     仲裁器 owner 恒不切换 ⇒ BitBlt 写通路与改动前逐位相同。
 *
 * 【吞吐：两级流水（构建银行 + 发送引擎），这是"2 像素/周期"的关键】
 *   朴素实现把"攒 16 拍词"和"发 AW→W×16→B"串起来（≈16 拍产 + ~20 拍发），
 *   实测只有 ~2.5 周期/拍（3.2 像素/周期），写通道有 1/4 时间是空的。
 *   这里改成**两级**：
 *     · 构建银行 bd_*：逐拍产词（1 词 = 8 像素 = 16 B），满了/不连续就**封口**；
 *     · 发送引擎 tx_*：独立小状态机（T_AW→T_W×N→T_B）把封口的那一笔发出去；
 *     · 两者**互相重叠**：产下一笔的同时发上一笔，发送期的 AW/B 气泡再也吃不到产能。
 *   代价：每拍 WSTRB 需要 **两份** MAX_BEATS 深的小数组（bd_strb/tx_strb），
 *   数据不用存（常量色 {$SLOTS{color_q}}）。实测见 tb_clear_engine。
 *
 * 【★ 安全：硬件互斥（本模块最要紧的部分）】
 *   目标缓冲 = CLR_CTRL[3:2]。以下两种情况**一个像素都不许写**：
 *     (a) 目标 == `fb_cur_sel`（扫描输出**正在显示**的那块）；
 *     (b) 目标 == `draw_sel`（DRAW_SEL：BitBlt 引擎**正在画**的那块）。
 *   两层执行：
 *     ① GO 时刻判一次（`go_bad`）：被禁 ⇒ 不启动、不发任何 AW/W，置 ERR（sticky）。
 *     ② 运行中**每个词都再判一次**（`run_bad`）：一旦扫描输出翻到了本引擎正在清的
 *        缓冲（软件违约），立刻停止产生新词，并**把已经组好的突发按 AXI 规范发完**
 *        （AW/W 拍数必须与 AW 声明一致，不能中途丢弃），然后置 ERR、**不置 clean**，收工。
 *        最大暴露 = **两笔**已组好的突发（发送引擎手里一笔 + 构建银行里封口等着接手的
 *        一笔）≤32 拍 = **≤512 B**。这是两级流水换吞吐的代价，TB 的 M3 用例把这个上界
 *        钉成了断言（`M3 AW after trip <= 2` / `M3 W after trip <= 32`）。
 *   两个判据都只看 **core 域寄存器**（fb_cur_sel 是 fb_scanout 的 core 域输出），
 *   没有引入任何新的跨时钟逻辑。
 *
 * 【WSTRB】RGB565 像素 = 2 字节，所以字节使能要按**字节槽**算（起点/终点位移 ×2，
 *   位移量 5 位防溢出）。非 16B 对齐的起点/终点/行宽都天然正确，不需要读-改-写。
 * ========================================================================= */
`timescale 1ns/1ps
module clr_engine #(
    parameter AW        = 32,
    parameter DW        = 128,
    /* 一笔突发最多几拍（与 axi_wr_master 的 MAX_BEATS 一致 = 16） */
    parameter MAX_BEATS = 16
)(
    input  wire            clk,
    input  wire            rst_n,

    /* ---- 配置寄存器（core 域，来自 blt_regs_axi_lite） ---- */
    input  wire [31:0]     cfg_addr,      // CLR_ADDR  ：起始字节地址
    input  wire [31:0]     cfg_stride,    // CLR_STRIDE：字节/行
    input  wire [15:0]     cfg_w,         // CLR_WH[15:0]   ：宽（像素）
    input  wire [15:0]     cfg_h,         // CLR_WH[31:16]  ：高（行）
    input  wire [15:0]     cfg_color,     // CLR_COLOR ：RGB565
    input  wire [1:0]      cfg_sel,       // CLR_CTRL[3:2]：目标缓冲号
    input  wire            cfg_go,        // CLR_CTRL[0]  ：1 拍脉冲
    input  wire            cfg_err_clr,   // CLR_CTRL[4]  ：1 拍脉冲，清 ERR

    /* ---- ★ 互斥（安全关键）：两个"禁写"来源 ---- */
    input  wire [1:0]      fb_cur_sel,    // 扫描输出当前**显示**的缓冲
    input  wire [1:0]      draw_sel,      // DRAW_SEL：BitBlt 引擎当前**画**的缓冲
    input  wire            draw_wr,       // DRAW_SEL 被写（1 拍脉冲）⇒ 该缓冲 clean 位清零

    /* ---- 状态回读（→ CLR_STAT / CLR_CYC） ---- */
    output reg             busy,          // CLR_STAT[0]
    output reg             err,           // CLR_STAT[6]：互斥拒绝/运行中被抢（sticky）
    output reg  [3:0]      clean,         // CLR_STAT[5:2]：四块缓冲的"已清干净"位图
    output reg  [15:0]     burst_cnt,     // CLR_STAT[31:16]：上一次 clear 的 AW 突发数
    output reg  [31:0]     cyc_cnt,       // CLR_CYC：上一次 clear 的 core 周期数

    /* ---- AXI4 写口（→ blt_top 内的 axi_wr_arb 次级端口） ---- */
    output wire [AW-1:0]   m_axi_awaddr,
    output wire [7:0]      m_axi_awlen,
    output wire [2:0]      m_axi_awsize,
    output wire [1:0]      m_axi_awburst,
    output wire            m_axi_awvalid,
    input  wire            m_axi_awready,
    output wire [DW-1:0]   m_axi_wdata,
    output wire [DW/8-1:0] m_axi_wstrb,
    output wire            m_axi_wlast,
    output wire            m_axi_wvalid,
    input  wire            m_axi_wready,
    input  wire            m_axi_bvalid,
    input  wire [1:0]      m_axi_bresp,
    output wire            m_axi_bready
);
    localparam integer SLOTS = DW / 16;          // 一个 128bit 词装几个 RGB565 像素 = 8
    localparam integer SB    = DW / 8;           // 字节使能位宽 = 16

    /* 主状态机 */
    localparam [1:0] S_IDLE = 2'd0, S_RUN = 2'd1, S_FIN = 2'd2;
    /* 发送引擎小状态机 */
    localparam [1:0] T_IDLE = 2'd0, T_AW = 2'd1, T_W = 2'd2, T_B = 2'd3;

    reg [1:0]  st;
    reg [1:0]  tx_st;

    /* ---------------- 走词状态（行/列推进） ---------------- */
    reg [31:0] row_addr;      // 本行第一个像素的字节地址
    reg [31:0] cur_addr;      // 本词第一个像素的字节地址
    reg [15:0] xleft;         // 本行剩余像素
    reg [15:0] rows;          // 剩余行数（产完最后一行会变成 0）
    reg [15:0] w_q, h_q, color_q;
    reg [31:0] stride_q;
    reg [1:0]  tgt;           // 本次 clear 的目标缓冲（互斥判据用）

    /* ---------------- 构建银行（逐拍产词） ---------------- */
    reg [31:0]   bd_addr;
    reg [7:0]    bd_len;                       // 已攒拍数（0 = 空）
    reg [SB-1:0] bd_strb [0:MAX_BEATS-1];
    reg          bd_sealed;                    // 1 = 已封口，等发送引擎接手

    /* ---------------- 发送银行（AXI 突发） ---------------- */
    reg [31:0]   tx_addr;
    reg [7:0]    tx_len;
    reg [7:0]    tx_wcnt;
    reg [SB-1:0] tx_strb [0:MAX_BEATS-1];

    reg [15:0]   n_burst;                      // 本次 clear 已发出的 AW 笔数
    reg [31:0]   cyc;                          // 本次 clear 已耗周期
    integer      k;

    /* ---------------- 组合：本拍要产出的词 ---------------- */
    wire [3:0]  lo_c     = cur_addr[3:1];                             // 词内起始**像素槽** 0..7
    wire [3:0]  avail_c  = SLOTS[3:0] - lo_c;                         // 本词还能装几个
    wire [3:0]  npx_c    = (xleft < {12'd0, avail_c}) ? xleft[3:0] : avail_c;
    wire        row_end  = ({12'd0, npx_c} == xleft);                 // 本行在本词结束
    /* ★ WSTRB 是**字节**使能（16 位），不是像素槽使能：每个 RGB565 像素占 2 个字节，
     *   所以起点/终点的位移都要 ×2，且位移量必须用 5 位（2*15=30，4 位会溢出）。 */
    wire [4:0]    lo_b    = {lo_c, 1'b0};                             // 起始字节槽 = 2*lo
    wire [4:0]    end_b   = {1'b0, (lo_c + npx_c)} << 1;              // 结束字节槽 = 2*(lo+npx)
    wire [SB-1:0] strb_c  = ({SB{1'b1}} << lo_b) & ~({SB{1'b1}} << end_b);
    wire [31:0]   waddr_c = {cur_addr[31:4], 4'b0000};                // 词地址（16B 对齐）
    wire [DW-1:0] wdata_c = {SLOTS{color_q}};                         // 8 个同色像素

    /* ---------------- ★ 互斥判据 ----------------
     * `CLEAR_MUTEX_OFF` 只用于 A/B 对照（证明 TB 真的能抓到"清正在显示的缓冲"）。 */
`ifdef CLEAR_MUTEX_OFF
    wire go_bad  = 1'b0;
    wire run_bad = 1'b0;
`else
    /* GO 时刻：按即将装载的 cfg_sel 判 */
    wire go_bad  = (st == S_IDLE) && cfg_go &&
                   ((cfg_sel == fb_cur_sel) || (cfg_sel == draw_sel));
    /* 运行中：按本次 clear 已锁定的 tgt 判（扫描输出翻过来 / 软件又把这块设成绘制目标） */
    wire run_bad = (tgt == fb_cur_sel) || (tgt == draw_sel);
`endif

    /* ---------------- 产词 / 封口 / 交接 / 收尾 ---------------- */
    /* 收尾判据用的"被互斥打断过"必须**锁存**（守卫可能只是短暂拉高）。 */
    reg  aborted_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            aborted_r <= 1'b0;
        else if (st == S_IDLE) aborted_r <= 1'b0;     // 空闲（含本拍 GO）时保持清零
        else if (run_bad)      aborted_r <= 1'b1;
    end
    /* ★ 只在"本次 clear 真的在跑"时才算被打断：空闲时 fb_cur_sel 恰好等于上次的目标
     *   是完全正常的（软件刚翻过去），不能因此把 ERR_CLR 也堵住。 */
    wire aborted = (st != S_IDLE) && (aborted_r | run_bad);

    wire gen_idle  = (rows == 16'd0);                     // 没有词可产了
    wire gen_run   = (st == S_RUN) && !run_bad && !gen_idle && !bd_sealed;
    wire start_new = gen_run && (bd_len == 8'd0);
    wire append_ok = gen_run && (bd_len != 8'd0) && (bd_len < MAX_BEATS[7:0]) &&
                     (waddr_c == (bd_addr + bd_len * (DW / 8)));
    wire accept    = start_new || append_ok;
    /* 满了 / 地址不连续 / 产完 / 被互斥拦下 → 把当前这一笔封口交给发送引擎 */
    wire seal_now  = (st == S_RUN) && !bd_sealed && (bd_len != 8'd0) && !accept;
    /* 交接：发送引擎空闲且构建银行已封口（两者同拍不冲突：交接要求 sealed，
     * 产词/封口要求 !sealed） */
    wire hand      = bd_sealed && (tx_st == T_IDLE);
    /* 排空完成：构建银行空且未封口、发送引擎也空闲 */
    wire drained   = !bd_sealed && (bd_len == 8'd0) && (tx_st == T_IDLE);
    /* ★ 收尾条件：**没有词可产**（正常清完）**或者已经被互斥打断**（aborted 锁存）。
     *   少了后半条会出大问题：被抢之后若 rows 还没归零，`gen_idle` 一直为假 ⇒ 状态机
     *   停在 S_RUN；等软件把 fb_cur_sel 挪开、run_bad 落下，引擎就**自己接着清**
     *   （tb_clear_engine 的 M3 "无新 GO 不得自行续写" 抓到的就是这个）。 */
    wire all_sent  = (st == S_RUN) && (gen_idle || aborted_r || run_bad) && drained;

    /* ---------------- AXI4 写口（由发送引擎驱动） ---------------- */
    assign m_axi_awvalid = (tx_st == T_AW);
    assign m_axi_awaddr  = tx_addr;
    assign m_axi_awlen   = tx_len - 8'd1;
    assign m_axi_awsize  = $clog2(DW / 8);
    assign m_axi_awburst = 2'b01;                       // INCR
    assign m_axi_wvalid  = (tx_st == T_W);
    assign m_axi_wdata   = wdata_c;                     // 常量色（8 个同色像素）
    assign m_axi_wstrb   = tx_strb[tx_wcnt[3:0]];       // 每拍各自的字节使能
    assign m_axi_wlast   = (tx_wcnt == tx_len - 8'd1);
    assign m_axi_bready  = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st         <= S_IDLE;
            tx_st      <= T_IDLE;
            row_addr   <= 32'd0;
            cur_addr   <= 32'd0;
            xleft      <= 16'd0;
            rows       <= 16'd0;
            w_q        <= 16'd0;
            h_q        <= 16'd0;
            color_q    <= 16'd0;
            stride_q   <= 32'd0;
            tgt        <= 2'd0;
            bd_addr    <= 32'd0;
            bd_len     <= 8'd0;
            bd_sealed  <= 1'b0;
            tx_addr    <= 32'd0;
            tx_len     <= 8'd0;
            tx_wcnt    <= 8'd0;
            n_burst    <= 16'd0;
            cyc        <= 32'd0;
            busy       <= 1'b0;
            err        <= 1'b0;
            clean      <= 4'b0000;
            burst_cnt  <= 16'd0;
            cyc_cnt    <= 32'd0;
        end else begin
            /* ---- 本次 clear 的运行周期计数 ---- */
            if (busy) cyc <= cyc + 32'd1;

            /* ---- ERR（sticky）：本拍的新拒绝压过 W1C 清除 ---- */
            if (cfg_err_clr && !go_bad && !aborted) err <= 1'b0;
            if (go_bad || aborted)                  err <= 1'b1;

            /* ---- clean 位图：DRAW_SEL 写入 ⇒ 那块立刻算"脏" ---- */
            if (draw_wr) clean[draw_sel] <= 1'b0;

            /* ================= 发送引擎（独立小 FSM） ================= */
            case (tx_st)
                T_AW: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        tx_wcnt <= 8'd0;
                        n_burst <= n_burst + 16'd1;
                        tx_st   <= T_W;
                    end
                end
                T_W: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        tx_wcnt <= tx_wcnt + 8'd1;
                        if (tx_wcnt == tx_len - 8'd1)
                            tx_st <= T_B;
                    end
                end
                T_B: begin
                    if (m_axi_bvalid && m_axi_bready)
                        tx_st <= T_IDLE;
                end
                default: ;                       // T_IDLE
            endcase

            /* ================= 交接：构建银行 → 发送银行（1 拍，逐位拷贝） =========
             * 放在 case 之后 ⇒ 同拍优先级最高；hand 成立时 tx_st 必为 T_IDLE，
             * 上面那个 case 不会对同样的寄存器赋值，不存在冲突。 */
            if (hand) begin
                tx_addr   <= bd_addr;
                tx_len    <= bd_len;
                for (k = 0; k < MAX_BEATS; k = k + 1)
                    tx_strb[k] <= bd_strb[k];
                tx_wcnt   <= 8'd0;
                bd_sealed <= 1'b0;
                bd_len    <= 8'd0;
                tx_st     <= T_AW;
            end

            /* ================= 主状态机 ================= */
            case (st)
                /* ================= 空闲：等 GO ================= */
                S_IDLE: begin
                    busy <= 1'b0;
                    if (cfg_go) begin
                        if (go_bad) begin
                            /* ★ 互斥拒绝：**一个 AW/W 都不发**，回空闲 + 置 ERR。
                             *   busy 保持 0 ⇒ 软件的有界等待立刻返回（不会假等）。 */
                            bd_len <= 8'd0;
                        end else if ((cfg_w == 16'd0) || (cfg_h == 16'd0)) begin
                            /* 空矩形：没什么可清，直接算"已清干净"（0 笔突发） */
                            clean[cfg_sel] <= 1'b1;
                            burst_cnt      <= 16'd0;
                            cyc_cnt        <= 32'd0;
                        end else begin
                            tgt        <= cfg_sel;
                            w_q        <= cfg_w;
                            h_q        <= cfg_h;
                            color_q    <= cfg_color;
                            stride_q   <= cfg_stride;
                            row_addr   <= cfg_addr;
                            cur_addr   <= cfg_addr;
                            xleft      <= cfg_w;
                            rows       <= cfg_h;
                            bd_addr    <= 32'd0;
                            bd_len     <= 8'd0;
                            bd_sealed  <= 1'b0;
                            n_burst    <= 16'd0;
                            cyc        <= 32'd0;
                            clean[cfg_sel] <= 1'b0;      // 清的过程中一律算"不干净"
                            busy       <= 1'b1;
                            st         <= S_RUN;
                        end
                    end
                end

                /* ================= 运行：产词 + 封口 + （由上面交接）发突发 ================= */
                S_RUN: begin
                    if (accept) begin
                        /* 计账：新开一笔 or 追加一拍 */
                        if (start_new) begin
                            bd_addr        <= waddr_c;
                            bd_len         <= 8'd1;
                            bd_strb[0]     <= strb_c;
                        end else begin
                            bd_len                <= bd_len + 8'd1;
                            bd_strb[bd_len[3:0]]  <= strb_c;
                        end
                        /* 行/列推进：本行在本词结束 ⇒ 跳下一行；否则按已写像素数前进 */
                        if (row_end) begin
                            row_addr <= row_addr + stride_q;
                            cur_addr <= row_addr + stride_q;
                            xleft    <= w_q;
                            rows     <= rows - 16'd1;
                        end else begin
                            cur_addr <= cur_addr + {12'd0, npx_c} * 16'd2;
                            xleft    <= xleft - {12'd0, npx_c};
                        end
                    end
                    if (seal_now)
                        bd_sealed <= 1'b1;
                    if (all_sent)
                        st <= S_FIN;
                end

                /* ================= 收尾 ================= */
                S_FIN: begin
                    busy      <= 1'b0;
                    burst_cnt <= n_burst;
                    cyc_cnt   <= cyc;
                    /* 只有"没被互斥打断过"才敢置 clean —— 否则软件会以为这块干净 */
                    if (!aborted)
                        clean[tgt] <= 1'b1;
                    st <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
