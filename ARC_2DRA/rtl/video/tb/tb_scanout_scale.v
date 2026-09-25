/* =========================================================================
 * tb_scanout_scale.v — fb_scanout「2 倍放大铺满 1080p」正确性验证
 * -------------------------------------------------------------------------
 * 需求：帧缓冲仍是 960x540（DDR 读带宽不变），但输出画面要填满 1920x1080、无黑边。
 * 做法：SCALE_SH=1 → 输出窗口 = 源窗口的 2 倍；源像素 (x,y) 覆盖输出 2x2 块，
 *       一条源行供两条输出行使用（横纵都是最近邻放大）。
 *
 * 本 TB 用 32x16 的假帧缓冲，像素值 = (y<<8)|x（便于从像素值反查行列），
 * 输出 64x32 正好铺满 active 区。做**坐标无关的序列检查**（不依赖内部延迟对齐）：
 *   1) 每一条输出行内，64 个像素解码出的源列号必须是 0,0,1,1,...,31,31  → 横向放大正确
 *   2) 连续输出行的源行号必须每条恰好重复 2 次、且逐条 +1        → 纵向放大正确、无丢行
 *   3) DE 期间不得出现黑像素（win_v 必须恒有效）                  → 无黑边
 *   4) 取数笔数应与"源 16 行 x 若干帧"同量级                      → 放大不增加 DDR 读量
 * ========================================================================= */
`timescale 1ns/1ps
module tb_scanout_scale;
    localparam FB_W = 32, FB_H = 16;
    localparam [31:0] FB_BASE = 32'h0030_1000;

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
        .V_ACTIVE(12'd32), .V_FP(12'd20), .V_SYNC(12'd2), .V_BP(12'd20),
        .MAX_BURST(8'd16),
        .SCALE_SH(1)                       /* ★ 2 倍放大：64x32 输出 = 铺满 active */
    ) dut (
        .clk(clk), .rst_n(rst_n),
        /* 本 TB 守"不翻转"那条路：fb_sel 恒 0 ⇒ 显示基址恒为 FB_BASE，与改动前等价。
         * （v2.6 新增端口，不接会悬空成 Z/X ⇒ 地址变 X，必须显式钉住；v2.7 起是 2 bit。） */
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

    /* ================= 行为 AXI 读从机（内容 = (y<<8)|x） ================= */
    reg [15:0] mem [0:FB_H*FB_W-1];
    integer j;
    initial for (j = 0; j < FB_H*FB_W; j = j + 1) mem[j] = ((j/FB_W) << 8) | (j % FB_W);

    function [127:0] beat_of;
        input [31:0] a;
        integer b;
        reg [31:0] off;
        begin
            off = a - FB_BASE;
            beat_of = 128'd0;
            for (b = 0; b < 8; b = b + 1)
                if (((off >> 1) + b) < (FB_H*FB_W))
                    beat_of[b*16 +: 16] = mem[(off >> 1) + b];
        end
    endfunction

    reg [31:0] s_addr;
    reg [7:0]  s_len, s_cnt, s_dly;
    reg [1:0]  rstate;
    localparam RS_IDLE = 2'd0, RS_LAT = 2'd1, RS_SEND = 2'd2;
    reg rvalid_r;
    integer fetch_cnt = 0;

    assign m_arready = (rstate == RS_IDLE);
    assign m_rdata   = beat_of(s_addr);
    assign m_rresp   = 2'b00;
    assign m_rid     = 4'h1;
    assign m_rlast   = (s_cnt == s_len);
    assign m_rvalid  = rvalid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rstate <= RS_IDLE; rvalid_r <= 1'b0;
            s_addr <= 0; s_len <= 0; s_cnt <= 0; s_dly <= 0;
        end else begin
            case (rstate)
                RS_IDLE: begin
                    if (m_arvalid && m_arready) begin
                        s_addr <= {4'd0, m_araddr};
                        s_len  <= m_arlen;
                        s_cnt  <= 8'd0;
                        s_dly  <= 8'd3;          /* 模拟 DDR 读延迟 */
                        rstate <= RS_LAT;
                        fetch_cnt = fetch_cnt + 1;
                    end
                end
                RS_LAT: begin
                    if (s_dly == 8'd0) begin
                        rvalid_r <= 1'b1;
                        rstate   <= RS_SEND;
                    end else
                        s_dly <= s_dly - 8'd1;
                end
                RS_SEND: begin
                    if (rvalid_r && m_rready) begin
                        if (m_rlast) begin
                            rvalid_r <= 1'b0;
                            rstate   <= RS_IDLE;
                        end else begin
                            s_addr <= s_addr + 16;
                            s_cnt  <= s_cnt + 8'd1;
                        end
                    end
                end
                default: rstate <= RS_IDLE;
            endcase
        end
    end

    /* ================= 显示侧：序列检查 ================= */
    wire [15:0] px_out = {vr[7:3], vg[7:2], vb[7:3]};   /* 888 -> 565 还原 */
    wire [7:0]  row_o  = px_out[15:8];                  /* 解码出的源行号 */
    wire [7:0]  col_o  = px_out[7:0];                   /* 解码出的源列号 */
    wire        win_v  = dut.ctrl2[2];
    wire        de_v   = dut.ctrl2[3];

    integer n_err, n_line, n_black, n_de;
    integer px_in_row;            /* 本输出行内第几个窗口像素（从 0 起） */
    integer run_same, n_run_bad;
    integer n_rep, n_adv;
    integer last_row_o;
    reg     prev_win, chk_arm, check_en;

    initial begin
        n_err = 0; n_line = 0; n_black = 0; n_de = 0;
        px_in_row = 0; run_same = 0; n_run_bad = 0; last_row_o = -1; n_rep = 0; n_adv = 0;
        prev_win = 1'b0; chk_arm = 1'b0; check_en = 1'b0;
    end

    /* 第一帧是启动瞬态（行缓冲未就绪 + 就绪标志跨时钟同步）。
     * 延迟一段时间后，**从某个帧首（vcnt==0）开始**正式判定：
     * 这样"每条源行连续 2 条输出行"的序列从干净状态起算，也不会把跨帧回绕误判成跳变。 */
    initial #800000 chk_arm = 1'b1;

    always @(negedge pclk) begin
        if (prst_n && chk_arm && !check_en && (dut.vcnt == 12'd0)) begin
            check_en   = 1'b1;
            last_row_o = -1;
            run_same   = 0;
        end
    end

    always @(negedge pclk) begin
        if (!prst_n) begin
            check_en = 1'b0; n_line = 0; px_in_row = 0; run_same = 0;
        end else begin
            if (de_v) begin
                n_de = n_de + 1;
                /* DE 期间黑 = 黑边。跳过判定起点那一行：判定正好落在帧首，
                 * 该行缓冲刚被 frame_rst 清掉、预取还没回来（本 TB 消隐期只有 8 行，
                 * 真实 1080p 有 45 行，实际不会出现），属于本 TB 的边界效应。 */
                if (!win_v && check_en && (n_line > 1) && (dut.hcnt > 12'd3)) begin
                    n_black = n_black + 1;
                    if (n_black <= 6)
                        $display("BLACK vcnt=%0d hcnt=%0d par_cur=%0d rdy=%b buf_ok=%0d cons_p=%0d next_y=%0d line=%0d",
                                 dut.vcnt, dut.hcnt, dut.par_cur, dut.rdy_p1, dut.buf_ok,
                                 dut.cons_p, dut.next_y, n_line);
                end
            end

            if (win_v) begin
                if (!prev_win) begin
                    /* ---- 新的输出行开始 ---- */
                    if (chk_arm) check_en = 1'b1;
                    if (check_en) begin
                        n_line = n_line + 1;
                        /* (2) 纵向：同一源行应恰好连续出现 2 条输出行，然后 +1 */
                        /* 纵向放大判据（对判定起点/跨帧回绕都鲁棒）：
                         *   相邻输出行要么"同一条源行"（重复 n_rep++），
                         *   要么"源行 +1"（前进 n_adv++）；其它一律算错。
                         *   2 倍放大 ⇒ 重复次数 ≈ 前进次数。（若放大没生效，
                         *   就会全是不重复也不前进 → n_run_bad 飙升。） */
                        if (last_row_o >= 0) begin
                            if (row_o == last_row_o)
                                n_rep = n_rep + 1;
                            else if (row_o == ((last_row_o + 1) & 8'hFF))
                                n_adv = n_adv + 1;
                            else if (!((last_row_o == (FB_H-1)) && (row_o == 8'd0))) begin
                                n_run_bad = n_run_bad + 1;
                                if (n_run_bad <= 6)
                                    $display("FAIL: 源行号跳变 %0d -> %0d（应重复或 +1）",
                                             last_row_o, row_o);
                            end
                        end
                        last_row_o = row_o;
                        run_same   = 1;
                        /* 调试：打印前若干条检查到的输出行 */
                        if (n_line <= 20)
                            $display("ROW vcnt=%0d src_row=%0d par_cur=%0d cons_p=%0d next_y=%0d",
                                     dut.vcnt, row_o, dut.par_cur, dut.cons_p, dut.next_y);
                        /* (1) 行首源列号必须是 0 */
                        if (col_o != 8'd0) begin
                            n_err = n_err + 1;
                            if (n_err <= 6) $display("FAIL: 行首源列号应为 0，实际 %0d", col_o);
                        end
                    end
                    px_in_row = 0;
                end else begin
                    px_in_row = px_in_row + 1;
                end

                /* (1) 横向：第 k 个像素的源列号必须是 k>>1（即 0,0,1,1,2,2,...） */
                if (check_en && (col_o != ((px_in_row >> 1) & 8'hFF))) begin
                    n_err = n_err + 1;
                    if (n_err <= 6)
                        $display("FAIL: 行内第 %0d 个像素源列号 = %0d，应为 %0d",
                                 px_in_row, col_o, px_in_row >> 1);
                end
            end else if (prev_win && check_en) begin
                /* 刚结束一条输出行：行内像素数应为 64（= 32 源列 x 2） */
                if ((px_in_row + 1) != 64) begin
                    n_err = n_err + 1;
                    if (n_err <= 6)
                        $display("FAIL: 输出行只有 %0d 个有效像素（应为 64）", px_in_row + 1);
                end
            end
            prev_win = win_v;
        end
    end

    /* ================= 结束判定 ================= */
    initial begin
        #200 rst_n = 1'b1; prst_n = 1'b1;
        #3_000_000;                       /* 3ms ≈ 5 帧（一帧 32x19.2us = 614us） */

        $display("--------------------------------------------------");
        $display("检查过的输出行数   = %0d  (应 >= 32)", n_line);
        $display("横向/行首映射错误  = %0d", n_err);
        $display("纵向: 重复 %0d 次 / 前进 %0d 次 (2倍放大 => 两者应接近) / 异常 %0d", n_rep, n_adv, n_run_bad);
        $display("DE 期间黑像素      = %0d  (必须 0 -> 无黑边)", n_black);
        $display("DE 像素总数        = %0d", n_de);
        $display("取数笔数(AR)       = %0d", fetch_cnt);
        $display("dbg_underrun       = %0d", dbg_underrun);
        $display("--------------------------------------------------");

        if (n_line < 32)     begin $display("FAIL: 检查到的输出行太少"); n_err = n_err + 1; end
        if (n_err != 0)      begin $display("FAIL: 横向放大映射有错"); end
        if ((n_run_bad != 0) || (n_rep < 8) || (n_adv < 8) || (n_rep > n_adv + 2) || (n_adv > n_rep + 2)) begin $display("FAIL: 纵向放大异常 (rep=%0d adv=%0d bad=%0d)", n_rep, n_adv, n_run_bad); end
        if (n_black != 0)    begin $display("FAIL: DE 期间有黑像素 -> 还有黑边"); end
        if (dbg_underrun > 2) begin $display("FAIL: 欠载过多 %0d（应仅启动瞬态 <=2）", dbg_underrun); end

        if ((n_err == 0) && (n_run_bad == 0) && (n_black == 0) && (n_line >= 32) &&
            (dbg_underrun <= 2))
            $display("========== tb_scanout_scale ALL PASS ==========");
        else
            $display("========== tb_scanout_scale FAILED ==========");
        $finish;
    end
endmodule
