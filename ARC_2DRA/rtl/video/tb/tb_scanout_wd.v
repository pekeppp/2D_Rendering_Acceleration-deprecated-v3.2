/* =========================================================================
 * tb_scanout_wd.v — fb_scanout 取数看门狗 / s_hold 有界性 / 退避 验证
 * -------------------------------------------------------------------------
 * 板级现象（comptest 复现）：开机信息正常、跑 1~2 秒后整机静止 —— 只碰 MMIO 的
 * 循环能跑满 1 秒 62 万圈，而一旦读 .bss / 写帧缓冲就立刻卡死。
 * 本工程整个程序（代码/数据/栈）都在 DDR（linker: ORIGIN=0x0000_1000, 124K），
 * 所以"CPU 拿不到 DDR 读通道" = 整机死。
 *
 * 读通道为什么会被永久拿走：读仲裁器的归还条件是
 *      cnt_s==0 && !s_arvalid && !s_hold
 * 而扫描输出在取数期间的 s_hold 恒高，且 v2.5 的 S_FETCH **唯一出口**是
 * "收满 BEATS_PER_LINE 拍"。于是只要从机少回几拍、或某笔突发彻底不来，
 * FSM 就永远停在 S_FETCH -> s_hold 永远为高 -> CPU 永远拿不到读通道。
 *
 * 三件必须有界的事（本 TB 逐条盯）：
 *   1) 取数本身：FETCH_TO 超时 -> S_DRAIN 排空 -> 硬放弃 + dbg_abort++
 *   2) 排空：DRAIN_TO 内把残留 R 拍收干净再交还通道（否则残留拍会错路给 CPU）
 *   3) **退避**：硬放弃后 BACKOFF_TO 拍内 s_arvalid=0/s_hold=0，通道必然回 CPU。
 *      没有退避的话，"失败->立刻重试"的风暴会让扫描输出几乎一直占着读通道
 *      （占用率 ~100%），CPU 只能挤缝隙 -> 整机卡死。有退避后占用率上限
 *      = (FETCH_TO+DRAIN_TO)/(FETCH_TO+DRAIN_TO+BACKOFF_TO) ≈ 67% -> CPU 一定活得下去。
 *
 * 故障注入：
 *   fault A（软）：某行只回 2/4 拍并**提前拉 rlast**（突发被截短）
 *   fault B（硬）：某行回 2 拍后**彻底停住**（永远不来 rlast）
 *   fault C（硬）：第二个硬故障行，专门验证"每次排空前 drain_to 都被清零"
 *                  （若上一轮残留值没清，第二次排空会立刻超时 -> 下面的断言会失败）
 *
 * A/B：加 `-DWD_OFF` 把三个超时都放到 0xFFFF（等价于没有任何有界化），
 *      期望本 TB **FAIL** —— 那就直接证明"有界化 + 退避"是整机能活的关键。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_scanout_wd;
    localparam FB_W = 32, FB_H = 16;
    localparam [31:0] FB_BASE = 32'h0030_1000;
    localparam integer FAULT_A_LINE = 4;      /* 软故障：只回一半 + 提前 rlast */
    localparam integer FAULT_B_LINE = 8;      /* 硬故障：回一半后彻底停住 */
    localparam integer FAULT_C_LINE = 12;     /* 第二个硬故障行 */
    localparam integer TO_VAL = 64;           /* 正常一行只要 4 拍 */
    /* 退避值单独取大一些：`dbg_abort` 在 pclk 域（5MHz，1 拍 = 20 core 拍）经两级
     * 同步才被本 TB 看到，滞后 ≈ 2~3 个 pclk 拍 = 40~60 个 core 拍。若退避也只有
     * 64 拍，TB 根本量不到它（第一版就是这样误报 FAIL 的）。 */
    localparam integer BO_VAL = 1024;
    localparam integer BO_LAG  = 128;         /* 允许的同步滞后 */
    localparam integer HOLD_MAX_OK = TO_VAL * 2 + 32;

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5   clk  = ~clk;      /* core_clk 100MHz */
    always #100 pclk = ~pclk;     /* pixel_clk 5MHz（一行显示时间远大于取数） */

    wire [27:0]  m_araddr;
    wire [7:0]   m_arlen;
    wire [2:0]   m_arsize;
    wire [1:0]   m_arburst;
    wire [3:0]   m_arid;
    wire         m_arvalid, m_arready, m_rvalid, m_rlast, m_rready, m_hold;
    wire [127:0] m_rdata;
    wire [1:0]   m_rresp;
    wire [3:0]   m_rid;
    wire         vde, vhs, vvs, frame_tick;
    wire [7:0]   vr, vg, vb;
    wire [11:0]  dbg_line;
    wire [15:0]  dbg_underrun, dbg_abort;

    fb_scanout #(
        .FB_BASE(FB_BASE), .FB_STRIDE(32'd64), .FB_W(12'd32), .FB_H(12'd16),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(12'd64), .H_FP(12'd8), .H_SYNC(12'd8), .H_BP(12'd16),
        .V_ACTIVE(12'd32), .V_FP(12'd2), .V_SYNC(12'd2), .V_BP(12'd4),
        .MAX_BURST(8'd16),
`ifdef WD_OFF
        .FETCH_TO(16'hFFFF), .DRAIN_TO(16'hFFFF), .BACKOFF_TO(16'hFFFF)  /* 没有任何有界化 */
`else
        .FETCH_TO(TO_VAL[15:0]), .DRAIN_TO(TO_VAL[15:0]), .BACKOFF_TO(BO_VAL[15:0])
`endif
    ) dut (
        .clk(clk), .rst_n(rst_n),
        /* v2.6/v2.7 新增端口：本 TB 只测看门狗/退避，翻转路径由 tb_scanout_flip 覆盖 */
        .fb_sel(2'b00),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arid(m_arid), .m_axi_arvalid(m_arvalid),
        .m_axi_arready(m_arready), .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp),
        .m_axi_rid(m_rid), .m_axi_rlast(m_rlast), .m_axi_rvalid(m_rvalid),
        .m_axi_rready(m_rready), .m_axi_hold(m_hold),
        .pclk(pclk), .prst_n(prst_n),
        .vde(vde), .vhs(vhs), .vvs(vvs), .vr(vr), .vg(vg), .vb(vb),
        .frame_tick(frame_tick), .dbg_line(dbg_line),
        .dbg_underrun(dbg_underrun), .dbg_abort(dbg_abort),
        /* ★S5（v3.2）新增的扫描输出颜色 LUT 端口：本 TB 不测 LUT，恒 0 钉住 */
        .lut_wr(1'b0), .lut_ch(2'b00), .lut_idx(8'd0), .lut_data(8'd0),
        .lut_en(1'b0), .lut_bank_req(1'b0), .lut_bank_act()
    );

    /* ================= 故障注入从机 ================= */
    reg [31:0] a_addr;
    reg        busy;
    reg [7:0]  bcnt, limit;
    reg        rlast_en;

    wire [31:0] a_off  = a_addr - FB_BASE;
    wire [11:0] a_line = a_off / 64;

    assign m_arready = !busy;
    assign m_rvalid  = busy && (bcnt < limit);
    assign m_rlast   = m_rvalid && rlast_en && (bcnt == (limit - 8'd1));
    assign m_rdata   = 128'd0;          /* 本 TB 不校验数据，只看"会不会卡死" */
    assign m_rresp   = 2'b00;
    assign m_rid     = 4'h1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0; bcnt <= 8'd0; limit <= 8'd0; rlast_en <= 1'b0; a_addr <= 32'd0;
        end else if (!busy) begin
            if (m_arvalid && m_arready) begin
                a_addr <= m_araddr;
                busy   <= 1'b1;
                bcnt   <= 8'd0;
                if (a_line == FAULT_A_LINE[11:0]) begin
                    limit <= 8'd2; rlast_en <= 1'b1;        /* 只回 2 拍 + 提前 rlast */
                end else if ((a_line == FAULT_B_LINE[11:0]) ||
                             (a_line == FAULT_C_LINE[11:0])) begin
                    limit <= 8'd2; rlast_en <= 1'b0;        /* 只回 2 拍，永远不来 rlast */
                end else begin
                    limit <= m_arlen + 8'd1; rlast_en <= 1'b1;
                end
            end
        end else begin
            if (m_rvalid && m_rready) begin
                bcnt <= bcnt + 8'd1;
                if (bcnt == (limit - 8'd1))
                    busy <= 1'b0;                       /* 本突发结束（故障行到此为止） */
            end
        end
    end

    /* ================= 监视 ================= */
    integer hold_run = 0, hold_max = 0;
    /* 超时驱动的那次 hold 时长（>FETCH_TO/2 的才算）：它必须 ≈ FETCH_TO+DRAIN_TO。
     * 若 DRAIN 没真的等（例如 drain_to 上一轮残留值没清零 -> 立刻超时），本项会掉到
     * ≈FETCH_TO，断言随即失败。 */
    integer hold_min_to = 1_000_000;
    integer ar_hs = 0;
    reg     seen_a = 1'b0, seen_b = 1'b0, seen_c = 1'b0;
    reg [15:0] abort_at_b = 16'd0;
    integer fail = 0;

    /* 硬放弃之后 m_axi_hold 必须**立刻连续为低**至少 BACKOFF_TO 拍。
     * 只测"abort 之后的第一段低电平"：帧边界的空闲也会产生很长的低电平，
     * 把那些算进来断言就形同虚设。 */
    integer low_run = 0, bo_min = 1_000_000, bo_cnt = 0;
    reg     just_aborted = 1'b0;
    reg [15:0] abort_d = 16'd0;

    always @(posedge clk) begin
        if (m_hold) begin
            hold_run = hold_run + 1;
            if (hold_run > hold_max) hold_max = hold_run;
        end else begin
            if ((hold_run > (TO_VAL / 2)) && (hold_run < hold_min_to))
                hold_min_to = hold_run;
            hold_run = 0;
        end

        if (dbg_abort != abort_d) begin
            abort_d      = dbg_abort;
            just_aborted = 1'b1;
            low_run      = 0;
        end
        if (just_aborted) begin
            if (!m_hold) low_run = low_run + 1;
            else begin                       /* hold 重新拉起 -> 这段退避结束 */
                if (low_run < bo_min) bo_min = low_run;
                bo_cnt       = bo_cnt + 1;
                just_aborted = 1'b0;
            end
        end

        if (m_arvalid && m_arready) begin
            ar_hs = ar_hs + 1;
            if (((m_araddr - FB_BASE) / 64) == FAULT_A_LINE) seen_a = 1'b1;
            if (((m_araddr - FB_BASE) / 64) == FAULT_B_LINE) begin
                seen_b = 1'b1;
                abort_at_b = dbg_abort;
            end
            if (((m_araddr - FB_BASE) / 64) == FAULT_C_LINE) seen_c = 1'b1;
        end
    end

    /* 只报告"故障之后又取到了多少行" —— 这是自恢复的直接证据 */
    integer ar_at_b = -1, ar_after_b = 0;
    always @(posedge clk) begin
        if (seen_b && (ar_at_b < 0)) ar_at_b = ar_hs;
        if ((ar_at_b >= 0) && (ar_hs > ar_at_b)) ar_after_b = ar_hs - ar_at_b;
    end

    initial begin
        #200 rst_n = 1'b1; prst_n = 1'b1;
        /* 跑足够多帧（一帧 32 显示行 × 19.2us ≈ 615us）。
         * 没有有界化时故障行会永久卡住，所以要多跑很久才能看清后果。 */
`ifdef WD_OFF
        #3_000_000;
`else
        #800_000;
`endif
        $display("--------------------------------------------------");
        $display("hold_max             = %0d  (上限 %0d)", hold_max, HOLD_MAX_OK);
        $display("hold_min (timeout)   = %0d  (应 ≈ FETCH_TO+DRAIN_TO = %0d)", hold_min_to, TO_VAL*2);
        $display("hold low after abort = %0d  (%0d 次退避, 应 >= BACKOFF_TO-%0d = %0d)",
                 (bo_cnt == 0) ? -1 : bo_min, bo_cnt, BO_LAG, BO_VAL - BO_LAG);
        $display("ar handshakes        = %0d", ar_hs);
        $display("fault lines seen     = A:%0d B:%0d C:%0d", seen_a, seen_b, seen_c);
        $display("dbg_abort            = %0d  (故障行前 %0d)", dbg_abort, abort_at_b);
        $display("AR after faultB      = %0d  (自恢复证据)", ar_after_b);
        $display("dbg_underrun         = %0d", dbg_underrun);
        $display("--------------------------------------------------");

        if (hold_max > HOLD_MAX_OK) begin
            $display("FAIL: m_axi_hold 连续为高 %0d 拍 > %0d -> 读通道被长期钉住，CPU 会被锁死",
                     hold_max, HOLD_MAX_OK);
            fail = fail + 1;
        end
        if (!seen_a || !seen_b || !seen_c) begin
            $display("FAIL: 故障注入没有真正发生 (A=%0d B=%0d C=%0d)", seen_a, seen_b, seen_c);
            fail = fail + 1;
        end
        if (dbg_abort < 16'd2) begin
            $display("FAIL: 两次硬故障应各记一次 dbg_abort，实际 %0d", dbg_abort);
            fail = fail + 1;
        end
        if (hold_min_to < (TO_VAL*2 - 8)) begin
            $display("FAIL: 超时驱动的 hold 只有 %0d 拍，应 ≈%0d -> DRAIN 没有真的等待排空",
                     hold_min_to, TO_VAL*2);
            fail = fail + 1;
        end
        if ((bo_cnt == 0) || (bo_min < BO_VAL - BO_LAG)) begin
            $display("FAIL: 硬放弃后 hold 只低 %0d 拍 (< %0d, 共 %0d 次) -> 退避没生效，CPU 会被饿死",
                     (bo_cnt == 0) ? -1 : bo_min, BO_VAL - BO_LAG, bo_cnt);
            fail = fail + 1;
        end
        if (ar_after_b < 8) begin
            $display("FAIL: 故障之后只取到 %0d 行 -> 没有自恢复", ar_after_b);
            fail = fail + 1;
        end
        if (fail == 0) $display("========== tb_scanout_wd ALL PASS ==========");
        else           $display("========== tb_scanout_wd FAILED (%0d) ==========", fail);
        $finish;
    end
endmodule
