/* =========================================================================
 * tb_rd_arb_leak.v — 复现并守住「读仲裁器 cnt_s 泄漏 ⇒ CPU 永久失去 DDR 读通道」
 * -------------------------------------------------------------------------
 * 板级现场（comptest）：自检阶段读到 `SCAN=00070108` —— 高 16 位 = 扫描输出的取数
 * 看门狗已经放弃过 **7 行**取数；紧接着 CPU 就彻底死了（整份程序都在 DDR 里）。
 *
 * 机制：
 *   扫描输出放弃本行时清的是**它自己的**账本（ar_idx/burst_done → s_hold 落下），
 *   但仲裁器这边那笔突发的 AR 早已计入 `cnt_s`，而对应的 rlast **永远不会来了**
 *   ⇒ `cnt_s` 永久泄漏 ≠ 0 ⇒ 归还条件 `cnt_s==0 && !s_arvalid && !s_hold` 被永远否决
 *   ⇒ owner 永远停在 1（扫描输出）⇒ CPU 再也拿不到 DDR 读通道。
 *
 * 本 TB 精确模拟这一幕：
 *   · S 侧（模拟扫描输出）：发一笔 AR，只收 2 拍就**把手放下**（= 看门狗放弃本行），
 *     之后永远安静；那笔突发剩下的拍永不到来。
 *   · C 侧（模拟 CPU）：持续请求读，统计"完成了多少笔突发"。
 *   · 从机：给 S 侧那笔只回 2 拍、**永不拉 rlast**；给 C 侧正常回满并拉 rlast。
 *
 * 判据：
 *   · 修复后：泄漏兜底（LEAK_TO）到点强制归还 ⇒ C 侧持续拿到通道（完成笔数 >= 50，
 *             且最长等待有界）；
 *   · A/B（`-DLEAK_OFF`，把 LEAK_TO 设为 0xFFFF 等价于没有兜底）：C 侧几乎完全拿不到
 *             通道 ⇒ 期望 FAIL —— 那就直接证明这条兜底是"CPU 不被永久锁死"的关键。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_rd_arb_leak;
    localparam AW = 28, DW = 128;

    reg clk = 1'b0, rst_n = 1'b0;
    always #5 clk = ~clk;

    /* ---------------- C 侧（CPU） ---------------- */
    reg  [AW-1:0]  c_araddr  = 28'h000_1000;
    reg  [7:0]     c_arlen   = 8'd3;          /* 4 拍突发 */
    reg            c_arvalid = 1'b0;
    wire           c_arready;
    wire [DW-1:0]  c_rdata;
    wire [1:0]     c_rresp;
    wire [3:0]     c_rid;
    wire           c_rlast, c_rvalid;
    reg            c_rready  = 1'b1;

    /* ---------------- S 侧（扫描输出） ---------------- */
    localparam [AW-1:0] S_ADDR = 28'h100_0000;   /* ★ bit24 置位 = 给 S 侧的数据。
                                                  *   注意 0x010_0000 是 bit20，写错就从机
                                                  *   会把 S 那笔当 C 的、回满并拉 rlast，
                                                  *   泄漏就复现不出来了（踩过这个坑）。 */
    reg  [AW-1:0]  s_araddr  = S_ADDR;
    reg  [7:0]     s_arlen   = 8'd7;             /* 8 拍突发 */
    reg            s_arvalid = 1'b0;
    reg            s_hold    = 1'b0;
    reg            s_rready  = 1'b1;
    wire           s_arready;
    wire [DW-1:0]  s_rdata;
    wire [1:0]     s_rresp;
    wire           s_rlast, s_rvalid;

    /* ---------------- DDR 侧 ---------------- */
    wire [AW-1:0]  m_araddr;
    wire [7:0]     m_arlen;
    wire [2:0]     m_arsize;
    wire [1:0]     m_arburst;
    wire [3:0]     m_arid;
    wire           m_arvalid, m_arready;
    wire [DW-1:0]  m_rdata;
    wire [1:0]     m_rresp;
    wire [3:0]     m_rid;
    wire           m_rlast, m_rvalid, m_rready;

`ifdef LEAK_OFF
    /* 等价于"没有泄漏兜底"：LEAK_TO 放到计数器的饱和值 0xFFFF，并把观察窗口缩到
     * 远小于它 ⇒ 在窗口内**永不放行**（这正是修复前"cnt_s 永久否决"的行为）。 */
    localparam [15:0] LK = 16'hFFFF;
    localparam integer SIM_CYC = 30000;
`else
    localparam [15:0] LK = 16'd256;              /* 与 RTL 默认一致 */
    localparam integer SIM_CYC = 400000;
`endif

    axi_rd_arb #(.AW(AW), .DW(DW), .IDW(4), .S_PRIO(0), .WAIT_MAX(8'd32), .LEAK_TO(LK))
    dut (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(c_araddr), .c_arlen(c_arlen), .c_arsize(3'd4), .c_arburst(2'b01),
        .c_arid(4'h0), .c_arvalid(c_arvalid), .c_arready(c_arready),
        .c_rdata(c_rdata), .c_rresp(c_rresp), .c_rid(c_rid), .c_rlast(c_rlast),
        .c_rvalid(c_rvalid), .c_rready(c_rready),
        .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arsize(3'd4), .s_arburst(2'b01),
        .s_arvalid(s_arvalid), .s_arready(s_arready), .s_hold(s_hold),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
        .s_rvalid(s_rvalid), .s_rready(s_rready),
        .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize),
        .m_arburst(m_arburst), .m_arid(m_arid), .m_arvalid(m_arvalid),
        .m_arready(m_arready), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rid(m_rid),
        .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
    );

    /* ================= 从机：S 侧那笔只回 2 拍且永不 rlast ================= */
    reg [AW-1:0] b_addr;
    reg [7:0]    b_len, b_cnt;
    reg          b_is_s, b_busy, b_dly;

    assign m_arready = !b_busy;
    assign m_rvalid  = b_busy && (b_dly == 1'b0);
    assign m_rdata   = {DW{1'b0}};
    assign m_rresp   = 2'b00;
    assign m_rid     = b_is_s ? 4'h1 : 4'h0;
    /* ★ 关键：给 S 侧的那笔**永远不拉 rlast**（模拟"rlast 再也不会来"） */
    assign m_rlast   = b_busy && (b_dly == 1'b0) && !b_is_s && (b_cnt == b_len);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_busy <= 1'b0; b_cnt <= 8'd0; b_len <= 8'd0; b_is_s <= 1'b0; b_dly <= 1'b0;
        end else if (!b_busy) begin
            if (m_arvalid && m_arready) begin
                b_addr <= m_araddr;
                b_len  <= m_arlen;
                b_cnt  <= 8'd0;
                b_is_s <= m_araddr[24];              /* bit24 置位 = 给 S 侧的数据 */
                b_busy <= 1'b1;
                b_dly  <= 1'b1;
            end
        end else if (b_dly) begin
            b_dly <= 1'b0;
        end else if (m_rvalid && m_rready) begin
            b_cnt <= b_cnt + 8'd1;
            /* S 侧：只回 2 拍就收工（rlast 永不来）；C 侧：回满 */
            if (b_is_s ? (b_cnt == 8'd1) : (b_cnt == b_len)) begin
                b_busy <= 1'b0;
                b_dly  <= 1'b1;
            end
        end
    end

    /* ================= S 侧主机的行为（模拟扫描输出 + 看门狗放弃） ================= */
    reg [1:0] s_st;                       /* 0=发 AR, 1=只收 2 拍, 2=放弃后永远安静 */
    reg [7:0] s_got;
    integer   s_ar_seen;

    initial begin
        s_st = 2'd0; s_arvalid = 1'b0; s_hold = 1'b0; s_got = 8'd0; s_ar_seen = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_st <= 2'd0; s_arvalid <= 1'b0; s_hold <= 1'b0; s_got <= 8'd0;
        end else case (s_st)
            2'd0: begin                       /* 拉一笔 AR，等受理 */
                s_arvalid <= 1'b1;
                s_hold    <= 1'b1;            /* 有突发在飞 → 钉住通道 */
                if (s_arvalid && s_arready) begin
                    s_arvalid <= 1'b0;
                    s_got     <= 8'd0;
                    s_ar_seen = s_ar_seen + 1;
                    s_st      <= 2'd1;
                end
            end
            2'd1: begin                       /* 收到 2 拍就够了（模拟"只回来一部分"） */
                if (s_rvalid && s_rready) begin
                    s_got <= s_got + 8'd1;
                    if (s_got >= 8'd1) begin
                        /* ★ 看门狗放弃本行：把自己的账本清零、把手放下，之后永远安静。
                         *   注意那笔突发剩下的拍**永远不会来**，仲裁器的 cnt_s 就永久泄漏。 */
                        s_hold    <= 1'b0;
                        s_arvalid <= 1'b0;
                        s_st      <= 2'd2;
                        $display("[%0t] S 放弃本行: cnt_s=%0d owner=%0d (期望 cnt_s=1 且 owner=1)",
                                 $time, dut.cnt_s, dut.owner);
                    end
                end
            end
            default: begin                    /* 永远安静 */
                s_hold    <= 1'b0;
                s_arvalid <= 1'b0;
            end
        endcase
    end

    /* ================= C 侧主机：持续请求，统计完成笔数 / 最长等待 ================= */
    reg [1:0] c_st;
    integer   c_done, c_wait, c_wait_max, c_got_beat;

    initial begin
        c_st = 2'd0; c_arvalid = 1'b0; c_done = 0; c_wait = 0; c_wait_max = 0; c_got_beat = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_st <= 2'd0; c_arvalid <= 1'b0; c_done <= 0; c_wait <= 0; c_wait_max <= 0;
        end else case (c_st)
            2'd0: begin                       /* 发一笔 AR */
                c_arvalid <= 1'b1;
                if (c_arvalid && c_arready) begin
                    c_arvalid <= 1'b0;
                    c_st      <= 2'd1;
                    if (c_wait > c_wait_max) c_wait_max <= c_wait;
                    c_wait    <= 0;
                end else begin
                    c_wait <= c_wait + 1;     /* 未被受理 → 计数等待拍数 */
                end
            end
            default: begin                    /* 等这一笔的 rlast */
                if (c_rvalid && c_rready) begin
                    c_got_beat <= c_got_beat + 1;
                    if (c_rlast) begin
                        c_done <= c_done + 1;
                        c_st   <= 2'd0;
                        /* 地址推进，避免和上一笔完全一样（不强制） */
                        c_araddr <= c_araddr + 28'h40;
                    end
                end
                c_wait <= c_wait + 1;
            end
        endcase
    end

    /* ================= 监视：cnt_s 每次变化都记下来（定位是谁减掉的） ================= */
    reg [7:0] cs_d = 8'hFF;
    reg       own_d = 1'b1;
    always @(posedge clk) begin
        if (dut.cnt_s !== cs_d) begin
            $display("[%0t] cnt_s %0d -> %0d   (s_ar_hs=%b s_r_end=%b m_rlast=%b owner=%0d s_quiet=%b)",
                     $time, cs_d, dut.cnt_s, dut.s_ar_hs, dut.s_r_end, m_rlast, dut.owner, dut.s_quiet);
            cs_d <= dut.cnt_s;
        end
        if (dut.owner !== own_d) begin
            $display("[%0t] owner %0d -> %0d   (cnt_c=%0d cnt_s=%0d leak_c=%0d)",
                     $time, own_d, dut.owner, dut.cnt_c, dut.cnt_s, dut.leak_c);
            own_d <= dut.owner;
        end
    end

    /* ================= 结束判定 ================= */
    integer fail;
    initial begin
        fail = 0;
        #200 rst_n = 1'b1;
        #(SIM_CYC * 10);                      /* 观察窗口（10ns/拍） */
        $display("--------------------------------------------------");
        $display("观察窗口              = %0d 拍", SIM_CYC);
        $display("S 侧已发出的 AR       = %0d", s_ar_seen);
        $display("★ 仲裁器 cnt_s（内部）= %0d   (S 侧早已安静，仍 != 0 即泄漏)", dut.cnt_s);
        $display("★ 仲裁器 owner（内部）= %0d   (0=CPU 1=扫描输出)", dut.owner);
        $display("C 侧完成突发笔数      = %0d  (修复后应 >= 50)", c_done);
        $display("C 侧最长 AR 等待拍数  = %0d", c_wait_max);
        $display("C 侧累计收到拍数      = %0d", c_got_beat);
        $display("--------------------------------------------------");
        if (s_ar_seen < 1) begin
            $display("FAIL: S 侧没有成功发出 AR，测试没有真正制造泄漏");
            fail = fail + 1;
        end
        if (dut.cnt_s == 8'd0) begin
            $display("FAIL: cnt_s 没有泄漏（=0）—— 本 TB 没有复现出要测的场景");
            fail = fail + 1;
        end
        if (c_done < 50) begin
            $display("FAIL: C 侧只完成 %0d 笔（<50）→ 读通道被 cnt_s 泄漏否决", c_done);
            fail = fail + 1;
        end
        if (fail == 0) $display("========== tb_rd_arb_leak ALL PASS ==========");
        else           $display("========== tb_rd_arb_leak FAILED (%0d) ==========", fail);
        $finish;
    end
endmodule
