/* =========================================================================
 * tb_fb_scanout.v — fb_scanout 行取数/显示正确性自测
 * -------------------------------------------------------------------------
 * 复现并验证修复：v1 的取数门控用了 buf_ready==0，两个行缓冲取满后再也无法清零，
 * 导致取数死锁、屏幕只重复显示第 0/1 行（表现为"只有彩条"或"满屏白"）。
 * 本 TB 用小尺寸参数（FB 32×16、显示 64×32）跑两帧以上，检查：
 *   1) 每行显示的像素属于同一 FB 行，且列号 0..31 顺序递增
 *   2) 相邻显示行的 FB 行号 +1（循环 0..15）→ 说明每帧都在重新取数
 *   3) 两帧内 16 个 FB 行全部出现过（若死锁则只会出现 0/1 两行）
 * ========================================================================= */
`timescale 1ns/1ps
module tb_fb_scanout;
    localparam FB_W = 32, FB_H = 16, STRIDE = 64;
    localparam [31:0] FB_BASE = 32'h0030_1000;

    reg clk = 1'b0, pclk = 1'b0, rst_n = 1'b0, prst_n = 1'b0;
    always #5  clk  = ~clk;      /* core_clk 100MHz */
    /* pixel_clk 用 5MHz：一条显示行 = 96 像素 × 200ns = 19.2us，
     * 必须**大于**一行取数时间（120 拍 × 8 周期 = 960 core 周期 = 9.6us）。
     * 若像素时钟太快（例如同为 100MHz），一行只有 960ns，而取一行要 9.6us，
     * 显示侧就会比取数快 10 倍 —— 行缓冲里的内容只隔十几行才推进一次，
     * 看起来像"行号不递增"，但那是测试台时序不真实，不是 RTL 的问题。
     * 真实 1080p 是 14.8us/行 vs 9.6us 取数，本 TB 用 19.2us 保留同样的余量。 */
    always #100 pclk = ~pclk;

    /* ---- AXI4 读主机接口 ---- */
    wire [27:0] m_araddr;
    wire [7:0]  m_arlen;
    wire [2:0]  m_arsize;
    wire [1:0]  m_arburst;
    wire [3:0]  m_arid;
    wire        m_arvalid, m_arready, m_rvalid, m_rlast, m_rready;
    wire [127:0] m_rdata;
    wire [1:0]  m_rresp;
    wire [3:0]  m_rid;

    /* ---- 显示输出 ---- */
    wire        vde, vhs, vvs, frame_tick;
    wire [7:0]  vr, vg, vb;
    wire [11:0] dbg_line;

    fb_scanout #(
        .FB_BASE(FB_BASE), .FB_STRIDE(32'd64), .FB_W(12'd32), .FB_H(12'd16),
        .WIN_X(12'd0), .WIN_Y(12'd0),
        .H_ACTIVE(12'd64), .H_FP(12'd8), .H_SYNC(12'd8), .H_BP(12'd16),
        .V_ACTIVE(12'd32), .V_FP(12'd2), .V_SYNC(12'd2), .V_BP(12'd4),
        .MAX_BURST(8'd16),
        .SCALE_SH(0)          /* 本 TB 守"不放大"那条路（32x16 窗口 + 黑边）；
                               * 2 倍放大由 tb_scanout_scale 专门覆盖 */
    ) dut (
        .clk(clk), .rst_n(rst_n),
        /* v2.6/v2.7 新增端口：本 TB 不测翻转，恒 0 钉住（= 显示基址恒为 FB_BASE） */
        .fb_sel(2'b00),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arid(m_arid), .m_axi_arvalid(m_arvalid),
        .m_axi_arready(m_arready), .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp),
        .m_axi_rid(m_rid), .m_axi_rlast(m_rlast), .m_axi_rvalid(m_rvalid),
        .m_axi_rready(m_rready),
        .pclk(pclk), .prst_n(prst_n),
        .vde(vde), .vhs(vhs), .vvs(vvs), .vr(vr), .vg(vg), .vb(vb),
        .frame_tick(frame_tick), .dbg_line(dbg_line), .dbg_abort(),
        /* ★S5（v3.2）新增的扫描输出颜色 LUT 端口：本 TB 不测 LUT，恒 0 钉住
         * （悬空是 z，仿真里会经像素通路传播成 x —— 见 fb_scanout.v 的端口注释） */
        .lut_wr(1'b0), .lut_ch(2'b00), .lut_idx(8'd0), .lut_data(8'd0),
        .lut_en(1'b0), .lut_bank_req(1'b0), .lut_bank_act()
    );

    /* ================= 行为 AXI 读从机 + 帧缓冲内容 ================= */
    /* 像素 (y,x) 的值 = (y<<8)|x，便于校验行号与列号 */
    reg [15:0] mem [0:FB_H*FB_W-1];
    integer k;
    initial for (k = 0; k < FB_H*FB_W; k = k + 1) mem[k] = ((k/FB_W) << 8) | (k % FB_W);

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

    assign m_arready = (rstate == RS_IDLE);
    assign m_rdata   = beat_of(s_addr);
    assign m_rresp   = 2'b00;
    assign m_rid     = 4'h1;
    assign m_rlast   = (s_cnt == s_len);
    assign m_rvalid  = rvalid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rstate <= RS_IDLE; rvalid_r <= 1'b0; s_addr <= 0; s_len <= 0; s_cnt <= 0; s_dly <= 0;
        end else begin
            case (rstate)
                RS_IDLE: begin
                    if (m_arvalid && m_arready) begin
                        s_addr <= {4'd0, m_araddr};
                        s_len  <= m_arlen;
                        s_cnt  <= 8'd0;
                        s_dly  <= 8'd3;          /* 模拟 DDR 读延迟 */
                        rstate <= RS_LAT;
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

    /* ================= 显示侧检查 =================
     * 只在"窗口有效"（dut.ctrl2[2]，即真正输出帧缓冲内容的那些像素）上做检查。
     * 数据通路（rdata→px1→px2）与控制通路（win_d1→ctrl1→ctrl2）都是 3 拍，
     * 且 RAM 读地址是组合产生的当前列号 → 第一个窗口像素就是正确的列 0，
     * 不需要再跳过任何像素。 */
    wire [15:0] px_out = {vr[7:3], vg[7:2], vb[7:3]};
    wire [7:0]  row_o  = px_out[15:8];
    wire [7:0]  col_o  = px_out[7:0];
    wire        win_v  = dut.ctrl2[2];

    reg [15:0] rows_seen;
    integer    n_err, n_line, prev_row, n_px;
    reg [7:0]  last_col;
    reg        prev_win, chk_arm, check_en;
    integer    dbg_cnt;

    initial begin
        rows_seen = 16'd0; n_err = 0; n_line = 0; prev_row = -1;
        last_col = 8'hFF; prev_win = 1'b0; n_px = 0;
        chk_arm = 1'b0; check_en = 1'b0;
        dbg_cnt = 0;
    end

    /* 第一帧是启动瞬态：复位释放时行缓冲还没取到数，"缓冲就绪"标志跨到像素
     * 时钟域也需要 2 拍同步，于是第一行的头几个像素会被判为未就绪。
     * 因此第一帧只统计不判定，从第二帧的行首开始正式检查。 */
    initial begin
        #800000 chk_arm = 1'b1;
    end

    always @(negedge pclk) begin
        if (!prst_n) begin
            rows_seen = 16'd0;
            prev_win  = 1'b0;
            check_en  = 1'b0;
            n_px      = 0;
        end else if (win_v) begin
            if (!prev_win) begin
                /* 窗口行首 */
                if (chk_arm)
                    check_en = 1'b1;
                n_px = 1;
                if (check_en) begin
                    n_line = n_line + 1;
                    if (dbg_cnt < 40) begin
                        $display("LINE vcnt=%0d row=%0d col=%0d (cons_p=%0d par_s1=%0d)",
                                 dut.vcnt, row_o, col_o, dut.cons_p, dut.par_s1);
                        dbg_cnt = dbg_cnt + 1;
                    end
                    if (col_o != 8'd0) begin
                        n_err = n_err + 1;
                        $display("FAIL: 行首列号应为 0 实际 %0d (line %0d)", col_o, n_line);
                    end
                    if (prev_row >= 0) begin
                        if (row_o != ((prev_row + 1) % FB_H)) begin
                            n_err = n_err + 1;
                            $display("FAIL: 行号跳变 期望 %0d 实际 %0d (line %0d)",
                                     (prev_row+1)%FB_H, row_o, n_line);
                        end
                    end
                    prev_row = row_o;
                end
            end else if (check_en) begin
                /* 同一行内列号必须严格 +1 */
                if (col_o != ((last_col + 8'd1) & 8'hFF)) begin
                    n_err = n_err + 1;
                    $display("FAIL: 行内列号 期望 %0d 实际 %0d (line %0d)",
                             (last_col+8'd1) & 8'hFF, col_o, n_line);
                end
                n_px = n_px + 1;
            end
            if (row_o < FB_H)
                rows_seen[row_o] = 1'b1;
            last_col = col_o;
            prev_win = 1'b1;
        end else begin
            if (check_en && prev_win && (n_px != FB_W)) begin
                n_err = n_err + 1;
                $display("FAIL: 第 %0d 行窗口像素数 %0d（应为 %0d）→ 该行有像素被判为未就绪",
                         n_line, n_px, FB_W);
            end
            prev_win = 1'b0;
        end
    end

    /* ================= 主流程 ================= */
    integer t;
    initial begin
        #1200000;                          /* 约 1.5 帧后 dump 内部状态 */
        /* v2.5：行缓冲存的是 128bit 拍，ram[t] 的第 0 个 16bit 就是第 8t 个像素 */
        for (t = 0; t < 4; t = t + 1)
            $display("DUMP mem[%0d]=0x%04x  buf0.beat%0d.px0=0x%04x  buf1.beat%0d.px0=0x%04x",
                     t * 8, mem[t * 8], t, dut.u_buf0.ram[t][15:0], t, dut.u_buf1.ram[t][15:0]);
        for (t = 30; t < 34; t = t + 1)
            $display("DUMP mem[%0d]=0x%04x", t, mem[t]);
        $display("DUMP DUT: st=%0d next_y=%0d fetch_y=%0d buf_ready=%b par_s1=%b",
                 dut.st, dut.next_y, dut.fetch_y, dut.buf_ready, dut.par_s1);
    end

    initial begin
        /* 复位必须在**至少一个 pclk 上升沿**之后才释放：
         * pclk 周期 200ns（第一个上升沿在 100ns），若像原来那样 #40 就释放，
         * 像素时钟域里的 always 块第一个沿看到的就是 prst_n=1，
         * 寄存器永远拿不到复位值（一直停在 X，表现为 hcnt/vcnt 全 X、
         * 窗口像素一个都不输出）。 */
        #200 rst_n = 1'b1;
        #300 prst_n = 1'b1;

        /* 等四帧（V_TOTAL=40 行 × 96 像素 × 200ns ≈ 768us/帧），
         * 第一帧留给启动瞬态，实际判定约 3 帧（≥48 个窗口行） */
        #4000000;                      /* 4ms ≈ 5.2 帧 */

        $display("检查结果: 显示行数=%0d, 出现过的 FB 行掩码=0x%04x, 错误=%0d",
                 n_line, rows_seen, n_err);

        if (rows_seen == 16'hFFFF && n_err == 0 && n_line >= 40)
            $display("========== tb_fb_scanout ALL PASS ==========");
        else begin
            if (rows_seen != 16'hFFFF)
                $display("FAIL: 只出现了部分 FB 行（掩码 0x%04x）→ 取数死锁/未推进", rows_seen);
            if (n_line < 40)
                $display("FAIL: 检查到的显示行数不足 (%0d)", n_line);
            $display("========== tb_fb_scanout FAILED ==========");
        end
        $finish;
    end
endmodule
