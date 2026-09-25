/* =========================================================================
 * tb_arb_deadlock.v — DDR AXI 读/写仲裁"上板级"压力 + 反压 + 死锁自测
 * -------------------------------------------------------------------------
 * 拓扑与 ARC_2DRA/rtl/ddr3_example_top.v 完全一致：
 *
 *   读： CPU ──────┐
 *                  ├─ L1(axi_rd_arb) ─┐
 *       BitBlt ────┘                  ├─ L2(axi_rd_arb) ─→ DDR 单读口
 *       fb_scanout ────────────────────┘   （优先级 扫描 > BitBlt > CPU）
 *   写： CPU ──────┐
 *                  ├─ axi_wr_arb ─→ DDR 单写口
 *       BitBlt ────┘
 *
 * 从机故意"不友好"（旧单元 TB 的从机总是及时回数据、从不反压，测不出板级行为）：
 *   - AR/AW 受理随机反压，读延迟随机，R 回程随机插空拍，W 通道随机压 wready，
 *     B 延迟随机；突发长度 1..16 随机混合；AW 队列 4 深，**W/B 期间继续收 AW**，
 *     因此能造出"AW 握手与 B 握手同拍"、以及"owner 在 B 在飞时切换"的场景；
 *   - 内存数据完全按地址派生 byte(a)=a[7:0]^a[15:8]^a[23:16]^a[31:24]，
 *     上电把 512KB 全填 pattern；任何写都必须写出"目的地址的 pattern"。
 *
 * 检查项（任一条不过 → FAIL）：
 *   1) 读主机逐拍校验自己收到的 R 数据 + rlast 位置（抓 R 错路/丢拍）；
 *      （注：axi_rd_arb 没有 s_rid 端口，真实顶层 BitBlt/扫描输出主机也看不到
 *        rid，所以 R 归属完全依赖 owner —— 本 TB 的逐拍数据校验直接检验这一点。）
 *   2) 从机逐拍校验 W 数据 == 该 AW 地址的 pattern（抓 W 错路：把 A 主人的数据
 *      写到 B 主人的 AW 上）；结尾再全内存 512KB 逐字节对照 pattern；
 *   3) 死锁看门狗：任一主机 TIMEOUT 拍没有任何进展 → FAIL + dump 现场；
 *      从机侧另有一条"AW 已受理但 W 永不来"（写口卡死）检测；
 *   4) 计数漂移：流量停 + 排空后 6 个在飞计数（rd L1/L2 各 2 + wr 2）必须全 0；
 *   5) 不安全让位监视（与 RTL 实现无关，只看端口）：
 *      "从机本拍受理了 AR/AW（该笔就此在飞）" 与 "owner 本拍切换" 同拍 → 计数，
 *      必须为 0。这一条正是上板卡死根因的形式化判据。
 *   6) 三阶段：A 定向反压（CPU 背靠背写 + 引擎等写口 >32 拍，复现强制让位竞争）
 *              A2 定向反压（引擎连发 4 笔后让位 CPU，AW/B 同拍）
 *              B 随机压力（5 主机同时猛发，≥200k 周期）
 *
 * 运行：
 *   iverilog -g2001 -s tb_arb_deadlock -o z.vvp \
 *       ARC_2DRA/rtl/video/axi_rd_arb.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/tb/tb_arb_deadlock.v
 *   vvp z.vvp            （加 +vcd 可导出波形）
 * ========================================================================= */
`timescale 1ns/1ps

/* =========================================================================
 * 行为级 DDR 从机（不友好版）
 * ========================================================================= */
module arb_slave_ddr #(
    parameter MEM_BYTES = (1 << 19)          // 512KB，覆盖 TB 用到的所有区间
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         directed,            // 1 = 定向阶段（不随机反压）
    input  wire         stall_first_w,       // 单拍脉冲：下一笔受理的写突发压 wready 40 拍
    /* 读 */
    input  wire [27:0]  s_araddr,
    input  wire [7:0]   s_arlen,
    input  wire [3:0]   s_arid,
    input  wire         s_arvalid,
    output wire         s_arready,
    output wire [127:0] s_rdata,
    output wire         s_rlast,
    output wire [3:0]   s_rid,
    input  wire         s_rready,
    output reg          s_rvalid,
    /* 写 */
    input  wire [27:0]  s_awaddr,
    input  wire [7:0]   s_awlen,
    input  wire [3:0]   s_awid,
    input  wire         s_awvalid,
    output wire         s_awready,
    input  wire [127:0] s_wdata,
    input  wire [15:0]  s_wstrb,
    input  wire         s_wlast,
    input  wire         s_wvalid,
    output wire         s_wready,
    output reg          s_bvalid,
    input  wire         s_bready,
    /* 观测 / 错误 */
    output reg          err_wdata,           // W 数据与该 AW 地址 pattern 不符
    output reg          err_stall,           // AW 已收但 W 迟迟不来（写口卡死）
    output reg  [31:0]  n_rbub,              // R 回程空拍（读反压）次数
    output reg  [31:0]  n_wstall,            // wready 被压低的总拍数
    output reg  [7:0]   max_q,               // AR 队列峰值
    output reg  [7:0]   max_aq,              // AW 队列峰值
    output reg  [31:0]  n_awbsame            // "AW 握手与 B 握手同拍"次数
);
    reg [7:0]  mem [0:MEM_BYTES-1];
    integer    i, j;
    reg [31:0] cyc, lfs, x;
    reg [7:0]  expb;
    reg [15:0] n_wbad;

    /* 上电按地址 pattern 预填整个内存：任何写都必须写出"目的地址的 pattern"，
     * 结尾全内存逐字节对照即可抓出错路写 / 错数据 / 丢拍 */
    initial begin
        for (j = 0; j < MEM_BYTES; j = j + 1)
            mem[j] = j[7:0] ^ j[15:8] ^ j[23:16] ^ j[31:24];
    end

    /* 31bit 最大长度 LFSR（x^31 + x^28 + 1） */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cyc <= 32'd0;
            lfs <= 32'h1ACE_B00F;
        end else begin
            cyc <= cyc + 32'd1;
            lfs <= {lfs[30:0], lfs[31] ^ lfs[28]};
        end
    end

    /* ---------------- 读：AR 队列（8 深，多笔在飞，按序回程） ---------------- */
    localparam MAXQ = 8;
    reg [27:0] q_addr [0:MAXQ-1];
    reg [7:0]  q_len  [0:MAXQ-1];
    reg [31:0] q_rdy  [0:MAXQ-1];
    reg [3:0]  q_id   [0:MAXQ-1];
    reg [3:0]  q_cnt, q_wp, q_rp;
    wire [3:0] q_nx = (q_rp == MAXQ-1) ? 4'd0 : q_rp + 4'd1;
    reg [27:0] r_addr;
    reg [7:0]  r_len, r_beat;
    reg [3:0]  r_id, r_gap;
    reg        r_mid;                         // 空拍后"续发当前突发"

    assign s_arready = (q_cnt < MAXQ) && (directed | lfs[7]);   // 队列没满也随机反压
    assign s_rid     = r_id;
    assign s_rlast   = s_rvalid && (r_beat == r_len);
    assign s_rdata   = rd_beat({4'd0, r_addr} + {20'd0, r_beat, 4'b0});

    function [127:0] rd_beat;                 // 该 16B beat 的 pattern
        input [31:0] a;
        integer k;
        reg [31:0] y;
        begin
            for (k = 0; k < 16; k = k + 1) begin
                y = a + k;
                rd_beat[k*8 +: 8] = y[7:0] ^ y[15:8] ^ y[23:16] ^ y[31:24];
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_cnt <= 4'd0; q_wp <= 4'd0; q_rp <= 4'd0;
            s_rvalid <= 1'b0; r_addr <= 28'd0; r_len <= 8'd0; r_beat <= 8'd0;
            r_id <= 4'd0; r_gap <= 4'd0; r_mid <= 1'b0; max_q <= 8'd0;
            n_rbub <= 32'd0;
        end else begin
            if (q_cnt > max_q[3:0]) max_q <= {4'd0, q_cnt};

            /* AR 受理（背靠背，队列未满就收） */
            if (s_arvalid && s_arready) begin
                q_addr[q_wp] <= s_araddr;
                q_len [q_wp] <= s_arlen;
                q_id  [q_wp] <= s_arid;
                q_rdy [q_wp] <= cyc + (directed ? 32'd3 : (32'd3 + {29'd0, lfs[11:9]}));
                q_wp <= (q_wp == MAXQ-1) ? 4'd0 : q_wp + 4'd1;
            end
            /* 受理 +1 与收完 -1 必须写在同一表达式里（同拍握手不能互相覆盖） */
            q_cnt <= q_cnt + ((s_arvalid && s_arready) ? 4'd1 : 4'd0)
                           - ((s_rvalid && s_rready && s_rlast) ? 4'd1 : 4'd0);

            if (s_rvalid) begin
                if (s_rready) begin
                    if (s_rlast) begin
                        q_rp <= q_nx;
                        /* 下一笔已到期 → 无缝续发（流水） */
                        if ((q_cnt > 4'd1) && ((cyc + 32'd1) >= q_rdy[q_nx])) begin
                            r_addr <= q_addr[q_nx];
                            r_len  <= q_len [q_nx];
                            r_id   <= q_id  [q_nx];
                            r_beat <= 8'd0;
                        end else
                            s_rvalid <= 1'b0;
                    end else begin
                        r_beat <= r_beat + 8'd1;
                        if ((!directed) && (lfs[13:12] == 2'b00)) begin
                            s_rvalid <= 1'b0;               // 插空拍 → 读反压
                            r_gap    <= {2'd0, lfs[15:14]};
                            r_mid    <= 1'b1;
                            n_rbub   <= n_rbub + 32'd1;
                        end
                    end
                end
            end else begin
                if (r_gap != 4'd0)
                    r_gap <= r_gap - 4'd1;
                else if (r_mid) begin
                    s_rvalid <= 1'b1;                       // 续发当前突发（r_beat 保持）
                    r_mid    <= 1'b0;
                end else if ((q_cnt != 4'd0) && (cyc >= q_rdy[q_rp])) begin
                    s_rvalid <= 1'b1;
                    r_addr   <= q_addr[q_rp];
                    r_len    <= q_len [q_rp];
                    r_id     <= q_id  [q_rp];
                    r_beat   <= 8'd0;
                end
            end
        end
    end

    /* ---------------- 写：AW 队列（4 深）+ W 串行 + B 串行 ----------------
     * 关键：允许在 W/B 期间继续受理 AW（真实 DDR 控制器就是这样），于是可以造出
     * "AW 握手与 B 握手同拍"，专门压仲裁器 cnt 的 +1/-1 与 owner 切换的交错。 */
    localparam W_IDLE = 2'd0, W_W = 2'd1, W_B = 2'd2;
    localparam AWQ = 4;
    reg [27:0] aq_addr [0:AWQ-1];
    reg [7:0]  aq_len  [0:AWQ-1];
    reg [2:0]  aq_cnt;
    reg [1:0]  aq_wp, aq_rp;
    wire [1:0] aq_nx = (aq_rp == AWQ-1) ? 2'd0 : aq_rp + 2'd1;
    reg [1:0]  wst;
    reg [27:0] w_addr;
    reg [7:0]  w_len, w_beat, w_gap;
    reg [31:0] w_dly, w_wait;
    reg        w_slow_pend;                   // 下一笔被受理的写突发压 wready 40 拍
    reg        aw_hs_d;                       // 上一拍是否发生 AW 握手（统计同拍用）
    wire       wr_pop = ((wst == W_IDLE) && (aq_cnt != 3'd0) && !s_bvalid) ||
                        ((wst == W_B) && s_bvalid && s_bready && (aq_cnt != 3'd0));

    assign s_awready = (aq_cnt < 3'd4) && (directed ? 1'b1 : (lfs[19] | lfs[20]));
    assign s_wready  = (wst == W_W) && (w_gap == 8'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wst <= W_IDLE; w_addr <= 28'd0; w_len <= 8'd0; w_beat <= 8'd0;
            w_gap <= 8'd0; w_dly <= 32'd0; s_bvalid <= 1'b0;
            err_wdata <= 1'b0; err_stall <= 1'b0; w_slow_pend <= 1'b0;
            w_wait <= 32'd0; n_wstall <= 32'd0; n_wbad <= 16'd0;
            aq_cnt <= 3'd0; aq_wp <= 2'd0; aq_rp <= 2'd0; max_aq <= 8'd0;
            n_awbsame <= 32'd0; aw_hs_d <= 1'b0;
        end else begin
            if (aq_cnt > max_aq[2:0]) max_aq <= {5'd0, aq_cnt};
            if (stall_first_w) w_slow_pend <= 1'b1;

            /* AW 受理（W/B 期间也照收，队列未满） */
            if (s_awvalid && s_awready) begin
                aq_addr[aq_wp] <= s_awaddr;
                aq_len [aq_wp] <= s_awlen;
                aq_wp <= (aq_wp == AWQ-1) ? 2'd0 : aq_wp + 2'd1;
            end
            aw_hs_d <= (s_awvalid && s_awready);
            if (aw_hs_d && s_bvalid && s_bready) n_awbsame <= n_awbsame + 32'd1;
            /* 受理 +1 与弹出 -1 写在同一表达式（同拍握手不能互相覆盖） */
            aq_cnt <= aq_cnt + ((s_awvalid && s_awready) ? 3'd1 : 3'd0)
                             - (wr_pop ? 3'd1 : 3'd0);

            case (wst)
                W_IDLE: begin
                    w_wait <= 32'd0;
                    if (wr_pop) begin
                        w_addr <= aq_addr[aq_rp];
                        w_len  <= aq_len [aq_rp];
                        w_beat <= 8'd0;
                        w_gap  <= w_slow_pend ? 8'd40 :
                                  (directed ? 8'd0 : {5'd0, lfs[23:21]});
                        w_slow_pend <= 1'b0;
                        aq_rp <= aq_nx;
                        wst <= W_W;
                    end
                end
                W_W: begin
                    if (w_gap != 8'd0) begin
                        w_gap  <= w_gap - 8'd1;
                        w_wait <= w_wait + 32'd1;
                        n_wstall <= n_wstall + 32'd1;
                        if (w_wait > 32'd8000) err_stall <= 1'b1;
                    end else if (s_wvalid) begin
                        for (i = 0; i < 16; i = i + 1) begin
                            if (s_wstrb[i] && ((w_addr + i) < MEM_BYTES)) begin
                                x = w_addr + i;
                                expb = x[7:0] ^ x[15:8] ^ x[23:16] ^ x[31:24];
                                if (s_wdata[i*8 +: 8] !== expb) begin
                                    err_wdata <= 1'b1;
                                    n_wbad <= n_wbad + 16'd1;
                                    if (n_wbad < 16'd4)
                                        $display("  [DDR] W 数据错路 @%h byte%0d exp=%h got=%h (AW 地址=%h)",
                                                 w_addr, i, expb, s_wdata[i*8 +: 8], w_addr);
                                end
                                mem[w_addr + i] <= s_wdata[i*8 +: 8];
                            end
                        end
                        w_wait <= 32'd0;
                        if (s_wlast) begin
                            wst   <= W_B;
                            w_dly <= directed ? 32'd2 : (32'd2 + {29'd0, lfs[26:24]});
                        end else begin
                            w_addr <= w_addr + 28'd16;
                            w_beat <= w_beat + 8'd1;
                            w_gap  <= directed ? 8'd0 : {5'd0, lfs[29:27]};
                        end
                    end else begin
                        /* wvalid 一直不来：AW 已受理但 W 永远不来 = 写口卡死 */
                        w_wait <= w_wait + 32'd1;
                        if (w_wait > 32'd8000) err_stall <= 1'b1;
                    end
                end
                W_B: begin
                    if (w_dly != 32'd0)
                        w_dly <= w_dly - 32'd1;
                    else begin
                        s_bvalid <= 1'b1;                 // B 保持到 bready
                        if (s_bvalid && s_bready) begin
                            s_bvalid <= 1'b0;
                            if (aq_cnt != 3'd0) begin
                                w_addr <= aq_addr[aq_rp];
                                w_len  <= aq_len [aq_rp];
                                w_beat <= 8'd0;
                                w_gap  <= w_slow_pend ? 8'd40 :
                                          (directed ? 8'd0 : {5'd0, lfs[23:21]});
                                w_slow_pend <= 1'b0;
                                aq_rp <= aq_nx;
                                wst <= W_W;
                            end else
                                wst <= W_IDLE;
                        end
                    end
                end
                default: wst <= W_IDLE;
            endcase
        end
    end
endmodule


/* =========================================================================
 * 读主机：随机突发（1..16 拍）+ 逐拍数据校验 + 进展时间戳（看门狗用）
 * ========================================================================= */
module arb_rd_host #(
    parameter [27:0] BASE  = 28'd0,        // 本主机专用 64KB 只读区间
    parameter [31:0] SEED  = 32'h1234_5678,
    parameter [31:0] GAPMX = 32'd0,        // 每笔之间随机间隔上限（扫描输出用行间隔）
    parameter [63:0] NAME  = "RD"
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         run,
    input  wire [31:0]  cyc,
    output reg  [27:0]  araddr,
    output reg  [7:0]   arlen,
    output reg          arvalid,
    input  wire         arready,
    input  wire [127:0] rdata,
    input  wire         rlast,
    input  wire         rvalid,
    output reg          rready,
    output wire         idle,
    output reg  [31:0]  nburst,
    output reg  [31:0]  nbeat,
    output reg  [15:0]  lenmask,
    output reg  [31:0]  last_prog,
    output reg  [31:0]  nerr
);
    localparam S_IDLE = 2'd0, S_AR = 2'd1, S_R = 2'd2, S_GAP = 2'd3;
    reg [1:0]  st;
    reg [31:0] lfs;
    reg [27:0] ar_q, na;
    reg [7:0]  len_q, beat_q, nl;
    reg [31:0] gap;
    reg [15:0] nbad;
    reg        run_d;

    assign idle = (st == S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) lfs <= SEED;
        else        lfs <= {lfs[30:0], lfs[31] ^ lfs[28]};
    end

    function [127:0] rd_exp;
        input [31:0] a;
        integer k;
        reg [31:0] y;
        begin
            for (k = 0; k < 16; k = k + 1) begin
                y = a + k;
                rd_exp[k*8 +: 8] = y[7:0] ^ y[15:8] ^ y[23:16] ^ y[31:24];
            end
        end
    endfunction

    wire [127:0] expd = rd_exp({4'd0, ar_q} + {20'd0, beat_q, 4'b0});

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE; araddr <= 28'd0; arlen <= 8'd0; arvalid <= 1'b0;
            rready <= 1'b1; nburst <= 32'd0; nbeat <= 32'd0; lenmask <= 16'd0;
            last_prog <= 32'd0; nerr <= 32'd0; ar_q <= 28'd0; len_q <= 8'd0;
            beat_q <= 8'd0; gap <= 32'd0; nbad <= 16'd0; na <= 28'd0; nl <= 8'd0;
            run_d <= 1'b0;
        end else begin
            run_d <= run;
            if (run && !run_d) last_prog <= cyc;      // 使能沿起算（看门狗基准）
            case (st)
                S_IDLE: begin
                    if (run) begin
                        /* 16B 对齐、区间内、突发绝不越界（每区间 64KB，最长 16 拍=256B） */
                        na = BASE + ({16'd0, lfs[15:4]} % 28'd4080) * 28'd16;
                        nl = 8'd1 + lfs[19:16];
                        ar_q   <= na;
                        araddr <= na;
                        len_q  <= nl;
                        arlen  <= nl - 8'd1;
                        lenmask[nl - 8'd1] <= 1'b1;
                        arvalid <= 1'b1;
                        st <= S_AR;
                    end
                end
                S_AR: begin
                    if (arvalid && arready) begin
                        arvalid <= 1'b0;
                        beat_q  <= 8'd0;
                        last_prog <= cyc;
                        st <= S_R;
                    end
                end
                S_R: begin
                    /* rready 随机压低（读反压，与 rvalid 解耦） */
                    rready <= (lfs[17] | lfs[18]);
                    if (rvalid && rready) begin
                        last_prog <= cyc;
                        nbeat <= nbeat + 32'd1;
                        if (rdata !== expd) begin
                            nerr <= nerr + 32'd1;
                            nbad <= nbad + 16'd1;
                            if (nbad < 16'd4)
                                $display("  [%0s] R 数据不符 @%h beat%0d exp=%h got=%h",
                                         NAME, ar_q, beat_q, expd, rdata);
                        end
                        if (rlast !== (beat_q == len_q - 8'd1)) begin
                            nerr <= nerr + 32'd1;
                            if (nerr < 32'd4)
                                $display("  [%0s] rlast 位置错 @%h beat%0d len=%0d rlast=%b",
                                         NAME, ar_q, beat_q, len_q, rlast);
                        end
                        if (rlast) begin
                            nburst <= nburst + 32'd1;
                            gap <= (GAPMX == 0) ? 32'd0 : (lfs % GAPMX);
                            st  <= S_GAP;
                        end else
                            beat_q <= beat_q + 8'd1;
                    end
                end
                S_GAP: begin
                    if (gap != 32'd0) gap <= gap - 32'd1;
                    else              st  <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule


/* =========================================================================
 * 写主机：随机突发（1..16 拍），数据 = 目的地址 pattern
 *   aw_pipe=1 模拟"有在飞写时下一笔 AW 提前压上"（板级 CPU 典型）
 *   aw_pipe=0 模拟 axi_wr_master（AW->W->B 串行，一笔收完才发下一笔）
 * ========================================================================= */
module arb_wr_host #(
    parameter [27:0] BASE  = 28'd0,
    parameter [31:0] SEED  = 32'h8765_4321,
    parameter [31:0] GAPMX = 32'd0,
    parameter [63:0] NAME  = "WR"
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         run,
    input  wire         aw_pipe,           // 运行时可选：AW 与 B 流水
    input  wire [31:0]  cyc,
    output reg  [27:0]  awaddr,
    output reg  [7:0]   awlen,
    output reg          awvalid,
    input  wire         awready,
    output reg  [127:0] wdata,
    output reg  [15:0]  wstrb,
    output reg          wlast,
    output reg          wvalid,
    input  wire         wready,
    input  wire         bvalid,
    output reg          bready,
    output wire         idle,
    output reg  [31:0]  nburst,
    output reg  [31:0]  nbeat,
    output reg  [15:0]  lenmask,
    output reg  [31:0]  last_prog,
    output reg  [31:0]  nerr
);
    localparam S_IDLE = 2'd0, S_AW = 2'd1, S_W = 2'd2, S_B = 2'd3;
    reg [1:0]  st;
    reg [31:0] lfs, gap;
    reg [27:0] wa_q, na;
    reg [7:0]  len_q, beat_q, nl;
    reg        run_d;

    assign idle = (st == S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) lfs <= SEED;
        else        lfs <= {lfs[30:0], lfs[31] ^ lfs[28]};
    end

    function [127:0] wr_exp;
        input [31:0] a;
        integer k;
        reg [31:0] y;
        begin
            for (k = 0; k < 16; k = k + 1) begin
                y = a + k;
                wr_exp[k*8 +: 8] = y[7:0] ^ y[15:8] ^ y[23:16] ^ y[31:24];
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE; awaddr <= 28'd0; awlen <= 8'd0; awvalid <= 1'b0;
            wdata <= 128'd0; wstrb <= 16'hFFFF; wlast <= 1'b0; wvalid <= 1'b0;
            bready <= 1'b1;
            nburst <= 32'd0; nbeat <= 32'd0; lenmask <= 16'd0; last_prog <= 32'd0;
            nerr <= 32'd0; wa_q <= 28'd0; len_q <= 8'd0; beat_q <= 8'd0;
            gap <= 32'd0; na <= 28'd0; nl <= 8'd0; run_d <= 1'b0;
        end else begin
            /* bready 随机反压（不依赖 bvalid，避免与仲裁器成环） */
            bready <= (lfs[22] | lfs[23]);
            run_d <= run;
            if (run && !run_d) last_prog <= cyc;      // 使能沿起算（看门狗基准）
            case (st)
                S_IDLE: begin
                    if (run) begin
                        if (gap != 32'd0) gap <= gap - 32'd1;
                        else begin
                            na = BASE + ({16'd0, lfs[15:4]} % 28'd4080) * 28'd16;
                            nl = 8'd1 + lfs[19:16];
                            wa_q   <= na;
                            awaddr <= na;
                            len_q  <= nl;
                            awlen  <= nl - 8'd1;
                            lenmask[nl - 8'd1] <= 1'b1;
                            beat_q <= 8'd0;
                            awvalid <= 1'b1;
                            st <= S_AW;
                        end
                    end
                end
                S_AW: begin
                    if (awvalid && awready) begin
                        last_prog <= cyc;
                        awvalid <= 1'b0;
                        wdata   <= wr_exp({4'd0, wa_q});
                        wstrb   <= 16'hFFFF;
                        wlast   <= (len_q == 8'd1);
                        wvalid  <= 1'b1;
                        st <= S_W;
                    end
                end
                S_W: begin
                    if (wvalid && wready) begin
                        last_prog <= cyc;
                        nbeat <= nbeat + 32'd1;
                        if (wlast) begin
                            wvalid <= 1'b0;
                            st <= S_B;
                        end else begin
                            beat_q <= beat_q + 8'd1;
                            wdata  <= wr_exp({4'd0, wa_q} + {20'd0, (beat_q + 8'd1), 4'b0});
                            wlast  <= ((beat_q + 8'd1) == len_q - 8'd1);
                        end
                    end
                end
                S_B: begin
                    if (bvalid && bready) begin
                        last_prog <= cyc;
                        nburst <= nburst + 32'd1;
                        /* aw_pipe=1：AW 与 B 流水（下一笔 AW 先压上，等 B 回来）
                         * aw_pipe=0：B 收完再隔至少一拍发下一笔（与 axi_wr_master 一致）
                         * run 必须在这里也判一次：流水模式不经过 S_IDLE，
                         * 否则停流量后它会一直发下去（TB 排空不了）。 */
                        if (aw_pipe && run) begin
                            na = BASE + ({16'd0, lfs[15:4]} % 28'd4080) * 28'd16;
                            nl = 8'd1 + lfs[19:16];
                            wa_q   <= na;
                            awaddr <= na;
                            len_q  <= nl;
                            awlen  <= nl - 8'd1;
                            lenmask[nl - 8'd1] <= 1'b1;
                            beat_q <= 8'd0;
                            awvalid <= 1'b1;
                            st <= S_AW;
                        end else begin
                            gap <= (GAPMX == 0) ? 32'd1 : (32'd1 + (lfs % GAPMX));
                            st  <= S_IDLE;
                        end
                    end
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule


/* =========================================================================
 * 顶层：真实拓扑 + 阶段控制 + 看门狗 + 计数漂移 + 全内存对照
 * ========================================================================= */
module tb_arb_deadlock;
    localparam AW = 28, DW = 128, IDW = 4;
    localparam TIMEOUT  = 32'd30000;          // 单主机无进展判定阈值（拍）
    localparam NPHASE_A = 25000;              // 定向阶段周期数
    localparam NPHASE_B = 260000;             // 随机压力阶段周期数

    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg [31:0] cyc = 0;
    always @(posedge clk) cyc <= cyc + 1;

    reg directed = 1'b1;
    reg stall_first_w = 1'b0;
    reg pipe_c = 1'b1, pipe_b = 1'b0;      // 写主机是否"下一笔 AW 提前压上"
    reg run_rd_c = 0, run_rd_b = 0, run_rd_s = 0;
    reg run_wr_c = 0, run_wr_b = 0;

    /* ---------------- CPU 读（L1 c 侧） ---------------- */
    wire [AW-1:0]   cr_addr; wire [7:0] cr_len; wire cr_valid, cr_ready;
    wire [DW-1:0]   cr_data; wire cr_last; wire cr_rvalid, cr_rready;
    /* ---------------- BitBlt 读（L1 s 侧） ---------------- */
    wire [AW-1:0]   br_addr; wire [7:0] br_len; wire br_valid, br_ready;
    wire [DW-1:0]   br_data; wire br_last; wire br_rvalid, br_rready;
    /* ---------------- L1 主口 -> L2 c 侧 ---------------- */
    wire [AW-1:0]   m1_addr; wire [7:0] m1_len; wire m1_valid, m1_ready;
    wire [DW-1:0]   m1_data; wire m1_last;
    wire [IDW-1:0]  m1_arid, m1_rid;      // L1 m_arid -> L2 c_arid; L2 c_rid -> L1 m_rid
    wire m1_rvalid, m1_rready;
    /* ---------------- 扫描输出读（L2 s 侧） ---------------- */
    wire [AW-1:0]   sr_addr; wire [7:0] sr_len; wire sr_valid, sr_ready;
    wire [DW-1:0]   sr_data; wire sr_last; wire sr_rvalid, sr_rready;
    /* ---------------- DDR 读口（L2 主口） ---------------- */
    wire [AW-1:0]   dr_addr; wire [7:0] dr_len; wire dr_valid, dr_ready;
    wire [DW-1:0]   dr_data; wire dr_last; wire [IDW-1:0] dr_id; wire dr_rvalid, dr_rready;

    /* ---------------- 写：CPU / BitBlt / DDR ---------------- */
    wire [AW-1:0]   cw_awaddr; wire [7:0] cw_awlen; wire cw_awvalid, cw_awready;
    wire [DW-1:0]   cw_wdata; wire [15:0] cw_wstrb; wire cw_wlast, cw_wvalid, cw_wready;
    wire cw_bvalid, cw_bready;
    wire [AW-1:0]   bw_awaddr; wire [7:0] bw_awlen; wire bw_awvalid, bw_awready;
    wire [DW-1:0]   bw_wdata; wire [15:0] bw_wstrb; wire bw_wlast, bw_wvalid, bw_wready;
    wire bw_bvalid, bw_bready;
    wire [AW-1:0]   dw_awaddr; wire [7:0] dw_awlen; wire [3:0] dw_awid; wire dw_awvalid, dw_awready;
    wire [DW-1:0]   dw_wdata; wire [15:0] dw_wstrb; wire dw_wlast, dw_wvalid, dw_wready;
    wire dw_bvalid; wire [3:0] dw_bid; wire dw_bready;

    wire [IDW-1:0] dr_arid;               // u_l2.m_arid 驱动 -> 从机 s_arid（与真实顶层一致）

    /* ================= 主机统计端口 ================= */
    wire rd_c_idle, rd_b_idle, rd_s_idle, wr_c_idle, wr_b_idle;
    wire [31:0] rd_c_n, rd_b_n, rd_s_n, wr_c_n, wr_b_n;
    wire [31:0] rd_c_nb, rd_b_nb, rd_s_nb, wr_c_nb, wr_b_nb;
    wire [15:0] rd_c_lm, rd_b_lm, rd_s_lm, wr_c_lm, wr_b_lm;
    wire [31:0] rd_c_lp, rd_b_lp, rd_s_lp, wr_c_lp, wr_b_lp;
    wire [31:0] rd_c_err, rd_b_err, rd_s_err, wr_c_err, wr_b_err;

    /* ================= 5 个主机 ================= */
    arb_rd_host #(.BASE(28'h000_0000), .SEED(32'h0001_1111),
                  .GAPMX(32'd40), .NAME("CPU-RD")) h_rd_c (
        .clk(clk), .rst_n(rst_n), .run(run_rd_c), .cyc(cyc),
        .araddr(cr_addr), .arlen(cr_len), .arvalid(cr_valid), .arready(cr_ready),
        .rdata(cr_data), .rlast(cr_last), .rvalid(cr_rvalid), .rready(cr_rready),
        .idle(rd_c_idle), .nburst(rd_c_n), .nbeat(rd_c_nb), .lenmask(rd_c_lm),
        .last_prog(rd_c_lp), .nerr(rd_c_err));

    arb_rd_host #(.BASE(28'h001_0000), .SEED(32'h0002_2222),
                  .GAPMX(32'd0), .NAME("BLT-RD")) h_rd_b (
        .clk(clk), .rst_n(rst_n), .run(run_rd_b), .cyc(cyc),
        .araddr(br_addr), .arlen(br_len), .arvalid(br_valid), .arready(br_ready),
        .rdata(br_data), .rlast(br_last), .rvalid(br_rvalid), .rready(br_rready),
        .idle(rd_b_idle), .nburst(rd_b_n), .nbeat(rd_b_nb), .lenmask(rd_b_lm),
        .last_prog(rd_b_lp), .nerr(rd_b_err));

    /* 扫描输出：每笔之间留"行间隔"（真实显示：1 行 1 笔突发，行时间 >> 突发时间） */
    arb_rd_host #(.BASE(28'h002_0000), .SEED(32'h0003_3333),
                  .GAPMX(32'd60), .NAME("SCAN-RD")) h_rd_s (
        .clk(clk), .rst_n(rst_n), .run(run_rd_s), .cyc(cyc),
        .araddr(sr_addr), .arlen(sr_len), .arvalid(sr_valid), .arready(sr_ready),
        .rdata(sr_data), .rlast(sr_last), .rvalid(sr_rvalid), .rready(sr_rready),
        .idle(rd_s_idle), .nburst(rd_s_n), .nbeat(rd_s_nb), .lenmask(rd_s_lm),
        .last_prog(rd_s_lp), .nerr(rd_s_err));

    /* CPU 写：aw_pipe=1（有在飞写时下一笔 AW 已压上，板级 CPU 典型） */
    arb_wr_host #(.BASE(28'h004_0000), .SEED(32'h0004_4444), .GAPMX(32'd8),
                  .NAME("CPU-WR")) h_wr_c (
        .clk(clk), .rst_n(rst_n), .run(run_wr_c), .aw_pipe(pipe_c), .cyc(cyc),
        .awaddr(cw_awaddr), .awlen(cw_awlen), .awvalid(cw_awvalid), .awready(cw_awready),
        .wdata(cw_wdata), .wstrb(cw_wstrb), .wlast(cw_wlast), .wvalid(cw_wvalid), .wready(cw_wready),
        .bvalid(cw_bvalid), .bready(cw_bready),
        .idle(wr_c_idle), .nburst(wr_c_n), .nbeat(wr_c_nb), .lenmask(wr_c_lm),
        .last_prog(wr_c_lp), .nerr(wr_c_err));

    /* BitBlt 写：默认串行（与 rtl/axi_wr_master.v 的 AW->W->B 状态机一致） */
    arb_wr_host #(.BASE(28'h005_0000), .SEED(32'h0005_5555), .GAPMX(32'd4),
                  .NAME("BLT-WR")) h_wr_b (
        .clk(clk), .rst_n(rst_n), .run(run_wr_b), .aw_pipe(pipe_b), .cyc(cyc),
        .awaddr(bw_awaddr), .awlen(bw_awlen), .awvalid(bw_awvalid), .awready(bw_awready),
        .wdata(bw_wdata), .wstrb(bw_wstrb), .wlast(bw_wlast), .wvalid(bw_wvalid), .wready(bw_wready),
        .bvalid(bw_bvalid), .bready(bw_bready),
        .idle(wr_b_idle), .nburst(wr_b_n), .nbeat(wr_b_nb), .lenmask(wr_b_lm),
        .last_prog(wr_b_lp), .nerr(wr_b_err));

    /* ================= 仲裁器：真实两级拓扑 ================= */
    axi_rd_arb #(.AW(AW), .DW(DW), .IDW(IDW)) u_l1 (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(cr_addr), .c_arlen(cr_len), .c_arsize(3'd4), .c_arburst(2'b01),
        .c_arid(4'h0), .c_arvalid(cr_valid), .c_arready(cr_ready),
        .c_rdata(cr_data), .c_rresp(), .c_rid(), .c_rlast(cr_last),
        .c_rvalid(cr_rvalid), .c_rready(cr_rready),
        .s_araddr(br_addr), .s_arlen(br_len), .s_arsize(3'd4), .s_arburst(2'b01),
        .s_arvalid(br_valid), .s_arready(br_ready), .s_hold(1'b0),
        .s_rdata(br_data), .s_rresp(), .s_rlast(br_last),
        .s_rvalid(br_rvalid), .s_rready(br_rready),
        .m_araddr(m1_addr), .m_arlen(m1_len), .m_arsize(), .m_arburst(), .m_arid(m1_arid),
        .m_arvalid(m1_valid), .m_arready(m1_ready),
        .m_rdata(m1_data), .m_rresp(), .m_rid(m1_rid), .m_rlast(m1_last),
        .m_rvalid(m1_rvalid), .m_rready(m1_rready)
    );

    axi_rd_arb #(.AW(AW), .DW(DW), .IDW(IDW)) u_l2 (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(m1_addr), .c_arlen(m1_len), .c_arsize(3'd4), .c_arburst(2'b01),
        .c_arid(m1_arid), .c_arvalid(m1_valid), .c_arready(m1_ready),
        .c_rdata(m1_data), .c_rresp(), .c_rid(m1_rid), .c_rlast(m1_last),
        .c_rvalid(m1_rvalid), .c_rready(m1_rready),
        .s_araddr(sr_addr), .s_arlen(sr_len), .s_arsize(3'd4), .s_arburst(2'b01),
        .s_arvalid(sr_valid), .s_arready(sr_ready), .s_hold(1'b0),
        .s_rdata(sr_data), .s_rresp(), .s_rlast(sr_last),
        .s_rvalid(sr_rvalid), .s_rready(sr_rready),
        .m_araddr(dr_addr), .m_arlen(dr_len), .m_arsize(), .m_arburst(), .m_arid(dr_arid),
        .m_arvalid(dr_valid), .m_arready(dr_ready),
        .m_rdata(dr_data), .m_rresp(), .m_rid(dr_id), .m_rlast(dr_last),
        .m_rvalid(dr_rvalid), .m_rready(dr_rready)
    );

    axi_wr_arb #(.AW(AW), .DW(DW), .IDW(IDW)) u_wr (
        .clk(clk), .rst_n(rst_n),
        .c_awaddr(cw_awaddr), .c_awlen(cw_awlen), .c_awsize(3'd4), .c_awburst(2'b01),
        .c_awid(4'h0), .c_awvalid(cw_awvalid), .c_awready(cw_awready),
        .c_wdata(cw_wdata), .c_wstrb(cw_wstrb), .c_wlast(cw_wlast),
        .c_wvalid(cw_wvalid), .c_wready(cw_wready),
        .c_bvalid(cw_bvalid), .c_bresp(), .c_bid(), .c_bready(cw_bready),
        .b_awaddr(bw_awaddr), .b_awlen(bw_awlen), .b_awsize(3'd4), .b_awburst(2'b01),
        .b_awvalid(bw_awvalid), .b_awready(bw_awready),
        .b_wdata(bw_wdata), .b_wstrb(bw_wstrb), .b_wlast(bw_wlast),
        .b_wvalid(bw_wvalid), .b_wready(bw_wready),
        .b_bvalid(bw_bvalid), .b_bresp(), .b_bready(bw_bready),
        .m_awaddr(dw_awaddr), .m_awlen(dw_awlen), .m_awsize(), .m_awburst(), .m_awid(dw_awid),
        .m_awvalid(dw_awvalid), .m_awready(dw_awready),
        .m_wdata(dw_wdata), .m_wstrb(dw_wstrb), .m_wlast(dw_wlast),
        .m_wvalid(dw_wvalid), .m_wready(dw_wready),
        .m_bvalid(dw_bvalid), .m_bresp(), .m_bid(dw_bid), .m_bready(dw_bready)
    );

    /* ================= 从机 ================= */
    wire d_err_wdata, d_err_stall;
    wire [31:0] d_rbub, d_wstall, d_awbsame;
    wire [7:0]  d_maxq, d_maxaq;

    arb_slave_ddr #(.MEM_BYTES(1 << 19)) u_ddr (
        .clk(clk), .rst_n(rst_n), .directed(directed), .stall_first_w(stall_first_w),
        .s_araddr(dr_addr), .s_arlen(dr_len), .s_arid(dr_arid), .s_arvalid(dr_valid),
        .s_arready(dr_ready), .s_rdata(dr_data), .s_rlast(dr_last), .s_rid(dr_id),
        .s_rready(dr_rready), .s_rvalid(dr_rvalid),
        .s_awaddr(dw_awaddr), .s_awlen(dw_awlen), .s_awid(4'h0), .s_awvalid(dw_awvalid),
        .s_awready(dw_awready), .s_wdata(dw_wdata), .s_wstrb(dw_wstrb), .s_wlast(dw_wlast),
        .s_wvalid(dw_wvalid), .s_wready(dw_wready),
        .s_bvalid(dw_bvalid), .s_bready(dw_bready),
        .err_wdata(d_err_wdata), .err_stall(d_err_stall),
        .n_rbub(d_rbub), .n_wstall(d_wstall), .max_q(d_maxq),
        .max_aq(d_maxaq), .n_awbsame(d_awbsame)
    );

    /* ================= 计数漂移 / 不安全让位 监视 ================= */
    wire all_idle = rd_c_idle & rd_b_idle & rd_s_idle & wr_c_idle & wr_b_idle;
    wire counts_zero = (u_l1.cnt_c == 8'd0) && (u_l1.cnt_s == 8'd0) &&
                       (u_l2.cnt_c == 8'd0) && (u_l2.cnt_s == 8'd0) &&
                       (u_wr.cnt_c == 8'd0) && (u_wr.cnt_b == 8'd0);
    wire ddr_quiet = !dr_rvalid && !dw_bvalid && (u_ddr.q_cnt == 4'd0) && (u_ddr.wst == 2'd0);

    reg        l1_oq, l2_oq, w_oq, l1_hq, l2_hq, w_hq;
    reg [31:0] race_rd, race_wr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            l1_oq <= 0; l2_oq <= 0; w_oq <= 0; l1_hq <= 0; l2_hq <= 0; w_hq <= 0;
            race_rd <= 0; race_wr <= 0;
        end else begin
            l1_oq <= u_l1.owner;
            l2_oq <= u_l2.owner;
            w_oq  <= u_wr.owner;
            /* 不安全让位 = "从机本拍受理了某笔 AR/AW（该笔就此在飞）" 与
             * "owner 本拍切换" 同拍发生 -> 那笔的 R/B 必然按新 owner 分路（错路）。 */
            l1_hq <= (m1_valid & m1_ready);
            l2_hq <= (dr_valid & dr_ready);
            w_hq  <= (dw_awvalid & dw_awready);
            if ((u_l1.owner !== l1_oq) && l1_hq) race_rd <= race_rd + 32'd1;
            if ((u_l2.owner !== l2_oq) && l2_hq) race_rd <= race_rd + 32'd1;
            if ((u_wr.owner !== w_oq)  && w_hq)  race_wr <= race_wr + 32'd1;
        end
    end

    /* ================= 看门狗 ================= */
    reg fatal = 0, wd_printed = 0;

    task dump_state;
        begin
            $display("  ---- 现场 dump @cycle %0d ----", cyc);
            $display("  rd L1: owner=%b cnt_c=%0d cnt_s=%0d | rd L2: owner=%b cnt_c=%0d cnt_s=%0d",
                     u_l1.owner, u_l1.cnt_c, u_l1.cnt_s, u_l2.owner, u_l2.cnt_c, u_l2.cnt_s);
            $display("  wr   : owner=%b cnt_c=%0d cnt_b=%0d wait_b=%0d wait_c=%0d",
                     u_wr.owner, u_wr.cnt_c, u_wr.cnt_b, u_wr.wait_b, u_wr.wait_c);
            $display("  DDR  : AR队列=%0d AW队列=%0d wst=%0d w_wait=%0d w_addr=%h rvalid=%b bvalid=%b",
                     u_ddr.q_cnt, u_ddr.aq_cnt, u_ddr.wst, u_ddr.w_wait, u_ddr.w_addr,
                     dr_rvalid, dw_bvalid);
            $display("  B/R  : cw_b=%b/%b bw_b=%b/%b dw_b=%b/%b dr_rready=%b dw_bready=%b",
                     cw_bvalid, cw_bready, bw_bvalid, bw_bready,
                     dw_bvalid, dw_bready, dr_rready, dw_bready);
            $display("  主机 : rdC(b=%0d e=%0d) rdB(b=%0d e=%0d) rdS(b=%0d e=%0d) wrC(b=%0d e=%0d) wrB(b=%0d e=%0d)",
                     rd_c_n, rd_c_err, rd_b_n, rd_b_err, rd_s_n, rd_s_err,
                     wr_c_n, wr_c_err, wr_b_n, wr_b_err);
            $display("  握手 : cr_ar=%b/%b br_ar=%b/%b sr_ar=%b/%b m1_ar=%b/%b dr_ar=%b/%b",
                     cr_valid, cr_ready, br_valid, br_ready, sr_valid, sr_ready,
                     m1_valid, m1_ready, dr_valid, dr_ready);
            $display("  握手 : cw_aw=%b/%b bw_aw=%b/%b dw_aw=%b/%b dw_w=%b/%b",
                     cw_awvalid, cw_awready, bw_awvalid, bw_awready,
                     dw_awvalid, dw_awready, dw_wvalid, dw_wready);
            $display("  FSM  : wrC=%0d wrB=%0d rdC=%0d rdB=%0d rdS=%0d",
                     h_wr_c.st, h_wr_b.st, h_rd_c.st, h_rd_b.st, h_rd_s.st);
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && !wd_printed) begin
            if ((run_rd_c && ((cyc - rd_c_lp) > TIMEOUT)) ||
                (run_rd_b && ((cyc - rd_b_lp) > TIMEOUT)) ||
                (run_rd_s && ((cyc - rd_s_lp) > TIMEOUT)) ||
                (run_wr_c && ((cyc - wr_c_lp) > TIMEOUT)) ||
                (run_wr_b && ((cyc - wr_b_lp) > TIMEOUT)) ||
                d_err_stall || d_err_wdata) begin
                wd_printed <= 1'b1;
                fatal <= 1'b1;
                $display("!!!!!!!! 看门狗命中（死锁 / W 错路）cycle=%0d !!!!!!!!", cyc);
                dump_state;
            end
        end
    end

    /* ================= 主流程 ================= */
    integer i, bad, k, waitc;
    reg [31:0] ai;
    reg [7:0]  eb;
    reg [15:0] lmall;

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_arb_deadlock.vcd");
            $dumpvars(0, tb_arb_deadlock);
        end
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        /* 阶段 A：定向反压（CPU 与引擎同时抢写口；从机把第一笔 W 压 40 拍）
         *   复现"强制让位分支 wait_b>=32 与 CPU 的 AW 握手同拍" ------------- */
        $display("[TB] 阶段 A：定向反压（引擎等写口 > 32 拍 + CPU 背靠背写）");
        directed = 1'b1;
        pipe_c = 1'b1; pipe_b = 1'b0;      // CPU 流水 AW（板级 CPU 典型）；引擎串行
        stall_first_w = 1'b1;              // 脉冲：下一笔 W 压 40 拍
        run_wr_c = 1'b1; run_wr_b = 1'b1;
        repeat (2) @(posedge clk);
        stall_first_w = 1'b0;
        for (i = 0; i < NPHASE_A && !fatal; i = i + 1) @(posedge clk);

        /* 阶段 A2：第二条强制让位路径（b_bursts>=4 归还 CPU 与引擎 AW 握手同拍）
         *   引擎侧用"AW 提前压上"的主机（真实 axi_wr_master 不会，属防御性覆盖） */
        if (!fatal) $display("[TB] 阶段 A2：定向反压（引擎连发 4 笔后让位，AW/B 同拍）");
        directed = 1'b1;
        pipe_c = 1'b0; pipe_b = 1'b1;
        stall_first_w = 1'b1;
        repeat (2) @(posedge clk);
        stall_first_w = 1'b0;
        for (i = 0; i < NPHASE_A && !fatal; i = i + 1) @(posedge clk);

        /* 阶段 B：5 主机同时猛发 + 全随机反压 */
        if (!fatal) $display("[TB] 阶段 B：随机压力 %0d 拍", NPHASE_B);
        directed   = 1'b0;
        pipe_c = 1'b1; pipe_b = 1'b0;      // 回到真实配置
        run_rd_c = 1'b1; run_rd_b = 1'b1; run_rd_s = 1'b1;
        for (i = 0; i < NPHASE_B && !fatal; i = i + 1) @(posedge clk);

        /* 停流量 + 排空 */
        run_rd_c = 0; run_rd_b = 0; run_rd_s = 0; run_wr_c = 0; run_wr_b = 0;
        waitc = 0;
        while (!(all_idle && counts_zero && ddr_quiet) && (waitc < 200000)) begin
            @(posedge clk);
            waitc = waitc + 1;
        end
        $display("[TB] 排空用了 %0d 拍（all_idle=%b counts_zero=%b ddr_quiet=%b）",
                 waitc, all_idle, counts_zero, ddr_quiet);
        if (!(all_idle && counts_zero && ddr_quiet)) begin
            $display("  （排空未完成 -> dump 现场）");
            dump_state;
            repeat (20) @(posedge clk);
            $display("  +20拍: wst=%0d aq=%0d bvalid=%b rvalid=%b ddrcyc=%0d",
                     u_ddr.wst, u_ddr.aq_cnt, dw_bvalid, dr_rvalid, u_ddr.cyc);
        end

        /* ================= 统计 ================= */
        $display("================ tb_arb_deadlock 统计 ================");
        $display("总周期=%0d", cyc);
        $display("读突发: CPU=%0d BLT=%0d SCAN=%0d （beat %0d/%0d/%0d）",
                 rd_c_n, rd_b_n, rd_s_n, rd_c_nb, rd_b_nb, rd_s_nb);
        $display("写突发: CPU=%0d BLT=%0d （beat %0d/%0d）", wr_c_n, wr_b_n, wr_c_nb, wr_b_nb);
        $display("从机反压: R 空拍=%0d  wready 压低拍数=%0d  AW/B 同拍次数=%0d",
                 d_rbub, d_wstall, d_awbsame);
        $display("从机队列峰值: AR=%0d AW=%0d", d_maxq, d_maxaq);
        $display("不安全让位事件（必须 0）: 读仲裁=%0d  写仲裁=%0d", race_rd, race_wr);
        lmall = rd_c_lm | rd_b_lm | rd_s_lm | wr_c_lm | wr_b_lm;
        $display("突发长度覆盖 mask=%h （%s1..16 全覆盖）", lmall, (lmall == 16'hFFFF) ? "" : "非");
        $display("主机自身错误数: rdC=%0d rdB=%0d rdS=%0d wrC=%0d wrB=%0d",
                 rd_c_err, rd_b_err, rd_s_err, wr_c_err, wr_b_err);

        bad = 0;
        if (!counts_zero) begin
            bad = bad + 1;
            $display("FAIL: 计数漂移（流量停后未归零）: L1 c=%0d s=%0d | L2 c=%0d s=%0d | WR c=%0d b=%0d",
                     u_l1.cnt_c, u_l1.cnt_s, u_l2.cnt_c, u_l2.cnt_s, u_wr.cnt_c, u_wr.cnt_b);
        end
        if (!ddr_quiet)  begin bad = bad + 1; $display("FAIL: 从机侧未排空（队列/在飞未清）"); end
        if (race_rd != 0 || race_wr != 0) begin
            bad = bad + 1; $display("FAIL: 发现不安全让位（owner 切换与从机 AW/AR 受理同拍）");
        end
        if (d_err_wdata) begin bad = bad + 1; $display("FAIL: 从机检出 W 数据错路"); end
        if (d_err_stall) begin bad = bad + 1; $display("FAIL: 从机检出写口卡死（AW 已收，W 永不来）"); end
        if (rd_c_err | rd_b_err | rd_s_err | wr_c_err | wr_b_err) begin
            bad = bad + 1; $display("FAIL: 主机侧检出 R 数据不符 / rlast 位置错");
        end
        if (fatal) begin bad = bad + 1; $display("FAIL: 看门狗已命中（上面已 dump）"); end
        /* 流量规模下限（防"测试没跑起来"式假 PASS） */
        if (rd_c_n < 100 || rd_b_n < 100 || rd_s_n < 100 || wr_c_n < 100 || wr_b_n < 100) begin
            bad = bad + 1;
            $display("FAIL: 压力不足（有主机突发数 < 100）");
        end

        /* 全内存 512KB 逐字节对照 pattern（抓任何错路写/丢拍） */
        k = 0;
        for (i = 0; i < (1 << 19); i = i + 1) begin
            ai = i;
            eb = ai[7:0] ^ ai[15:8] ^ ai[23:16] ^ ai[31:24];
            if (u_ddr.mem[i] !== eb) begin
                if (k < 8) $display("  [MEM] @%h exp=%h got=%h", i, eb, u_ddr.mem[i]);
                k = k + 1;
            end
        end
        if (k != 0) begin bad = bad + 1; $display("FAIL: 内存 pattern 对照发现 %0d 字节不符", k); end
        else $display("PASS: 512KB 内存逐字节 = 地址 pattern（无错路写 / 无丢拍）");

        if (bad == 0) $display("========== tb_arb_deadlock ALL PASS ==========");
        else          $display("========== tb_arb_deadlock FAILED: %0d ==========", bad);
        $finish;
    end

    /* 全局兜底看门狗 */
    initial begin
        #40_000_000;
        $display("!!!!!!!! tb_arb_deadlock 全局看门狗（40ms）!!!!!!!!");
        dump_state;
        $display("========== tb_arb_deadlock FAILED: 全局超时 ==========");
        $finish;
    end
endmodule
