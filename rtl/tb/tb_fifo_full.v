/* =========================================================================
 * tb_fifo_full.v — 指令 FIFO "满时绝不丢字" 结构性单测（簇 3 复现/回归台）
 * -------------------------------------------------------------------------
 * 目的：证明命令入口在 FIFO 满的边界上**不丢字**，且反压语义正确。
 * 手法：把 blt_regs_axi_lite 与 cmd_fifo 直接对接（CMD_DEPTH=2 → 16 字；小深度
 *       让"满"很快出现），AXI-Lite 主机**背靠背**发 AW+W（bready 常高 →
 *       slave 允许的最快节奏 = 每 2 拍一次握手）。这正好覆盖危险窗口：
 *       握手受理那一拍 full 还是 0，而真正入队那两拍之后 full 已经变 1。
 * 说明：所有握手都在 **posedge** 采样（采样的是该沿之前的稳定值），
 *       避免 negedge 采样漏掉"只出现 1 拍"的 ready 窗口。
 *
 * 判定：
 *   P1  被受理的握手数 <= FIFO 容量，且 == FIFO 实收字数（一个字都不许静默丢）
 *   P2  FIFO 里存的是顺序的前 N 个唯一数据（按值校验）
 *   P3  满了以后 AW 不再被受理（背压生效）
 *   P4a 满边界 + "AW 先到"：腾出空间后该字仍必须入队且顺序不乱
 *   P4b 满边界 + "W 先到" ：W 先被锁存，等 AW 受理后仍必须入队且顺序不乱
 *   P5  逐字弹出顺序正确（empty 为权威、按 rd_ack 计数）
 * ========================================================================= */
`timescale 1ns/1ps
module tb_fifo_full;
    localparam DEPTH_W = 16;                 // CMD_DEPTH=2 → 16 字

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    /* ---- AXI-Lite 写口（读口不用） ---- */
    reg  [11:0] awaddr  = 12'd0;
    reg         awvalid = 1'b0;
    reg  [31:0] wdata   = 32'd0;
    reg  [3:0]  wstrb   = 4'hF;
    reg         wvalid  = 1'b0;
    reg         bready  = 1'b1;
    wire        awready, wready, bvalid;
    wire [1:0]  bresp;

    wire        fifo_wr_en;
    wire [31:0] fifo_wr_data;

    reg         rd_en = 1'b0;
    wire        rd_ack;
    wire [31:0] dout;
    wire        full, empty;
    wire [11:0] word_count;
    wire [8:0]  cmd_count;

    integer errors = 0;
    integer hs;                 // posedge 采样的"完整握手"次数
    integer maxocc;
    integer k, guard;
    integer okd;
    reg [31:0] vv;
    reg     auto_data = 1'b0;   // 背靠背阶段：每个 negedge 按 hs 刷新唯一数据
    reg     aw_hs = 1'b0;       // 本阶段是否出现过 AW 握手
    reg     w_hs  = 1'b0;       // 本阶段是否出现过 W 握手

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* =============== DUT =============== */
    blt_regs_axi_lite #(.ADDR_W(12)) u_regs (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(bresp), .s_axil_bready(bready),
        .s_axil_araddr(12'd0), .s_axil_arvalid(1'b0), .s_axil_arready(),
        .s_axil_rdata(), .s_axil_rresp(), .s_axil_rvalid(), .s_axil_rready(1'b1),
        .ctrl_go(), .soft_rst(), .irq_en(),
        .eng_busy(1'b0), .eng_done(1'b0), .eng_err(1'b0),
        .fifo_empty(empty), .fifo_full(full), .fifo_cmd_count(cmd_count),
        .fifo_wr_en(fifo_wr_en), .fifo_wr_data(fifo_wr_data),
        .dbg_cur(32'd0), .perf(32'd0), .irq_done(),
        /* ★v2.7 新增输入端口：本 TB 不碰翻转/清屏，全部钉 0（不接会悬空成 Z/X） */
        .fb_sel(), .fb_cur_sel(2'd0), .fb_frame_cnt(16'd0), .frame_pulse(1'b0),
        .clr_addr(), .clr_stride(), .clr_w(), .clr_h(), .clr_color(),
        .clr_sel(), .clr_go(), .clr_err_clr(),
        .clr_busy(1'b0), .clr_err(1'b0), .clr_clean(4'd0), .clr_burst(16'd0), .clr_cyc(32'd0),
        .draw_sel(), .draw_wr(),
        /* ★v2.11 显示列表新增端口：本 TB 不跑列表路径，输入全部钉 0
         * （不接会悬空成 Z/X，dl_gnt 的判据会被 X 污染） */
        .dl_base0(), .dl_base1(), .dl_count(),
        .dl_buf_sel(), .dl_irq_en(), .dl_auto_go(), .dl_strict(),
        .dl_go_pulse(), .dl_abort_pulse(),
        .dl_geom_base(), .dl_geom_max(), .dl_dst_base(),
        .dl_cfg_chunk(), .dl_cfg_wm(), .dl_cfg_prefetch(), .dl_cfg_gec(),
        .dl_timeout(), .dl_dst_stride(), .dl_fb_w(), .dl_fb_h(),
        .dl_err_clr_mask(), .dl_err_clr_pulse(), .dl_list_rewr_pulse(),
        .dl_base_align_err(),
        .dl_busy(1'b0), .dl_done(1'b0), .dl_err(1'b0), .dl_aborted(1'b0),
        .dl_stall(1'b0), .dl_consumed(16'd0), .dl_active_buf(2'd0),
        .dl_err_word(32'd0), .dl_fault_addr(32'd0), .dl_perf(32'd0),
        .dl_cmd_req(1'b0), .dl_cmd_data(32'd0), .dl_cmd_last(1'b0), .dl_cmd_gnt(),
        /* ★S5（v3.2）新增端口：本 TB 只压 cmd_fifo 满边界 ⇒ 输入全部钉 0
         * （属性 FIFO 的弹脉冲由引擎给；不接会悬空成 Z/X） */
        .attr_empty(), .attr_dout(), .attr_pop(1'b0),
        .clip_x0(), .clip_x1(), .clip_y0(), .clip_y1(), .clip_en(),
        .lut_wr(), .lut_ch(), .lut_idx(), .lut_data(),
        .lut_en(), .lut_bank_req(), .lut_bank_act(1'b0)
    );

    cmd_fifo #(.CMD_DEPTH(2)) u_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(fifo_wr_en), .din(fifo_wr_data),
        .rd_en(rd_en), .rd_ack(rd_ack), .dout(dout),
        .full(full), .empty(empty),
        .word_count(word_count), .cmd_count(cmd_count)
    );

    always @(posedge clk) begin
        if (awvalid && awready && wvalid && wready) hs = hs + 1;
        if (awvalid && awready) aw_hs <= 1'b1;
        if (wvalid  && wready ) w_hs  <= 1'b1;
    end

    always @(negedge clk) if (auto_data) wdata = 32'h1000_0000 + hs;

    always @(posedge clk) if (word_count > maxocc) maxocc = word_count;

    /* =============== 主机模型 =============== */
    task do_reset;
        begin
            @(negedge clk); rst_n = 1'b0;
            repeat (4) @(negedge clk);
            @(negedge clk); rst_n = 1'b1;
            repeat (4) @(negedge clk);
        end
    endtask

    task pop_one;
        begin
            while (empty) @(posedge clk);
            @(negedge clk); rd_en = 1'b1;
            @(negedge clk); rd_en = 1'b0;
        end
    endtask

    task pop_get;
        output [31:0] v;
        begin
            while (empty) @(posedge clk);
            v = dout;
            @(negedge clk); rd_en = 1'b1;
            @(negedge clk); rd_en = 1'b0;
        end
    endtask

    /* 逐字干净写一个字（等 AW+W 都握手完成，再撤 valid） */
    task write_1;
        input [31:0] d;
        begin
            @(negedge clk);
            awaddr = 12'h08; awvalid = 1'b1; wdata = d; wvalid = 1'b1;
            aw_hs = 1'b0; w_hs = 1'b0;
            guard = 0;
            while (guard < 100 && !(aw_hs && w_hs)) begin @(negedge clk); guard = guard + 1; end
            @(negedge clk); awvalid = 1'b0; wvalid = 1'b0;
            @(negedge clk);
        end
    endtask

    task fill_clean;
        input integer tag;
        begin
            do_reset();
            hs = 0; maxocc = 0;
            for (k = 0; k < DEPTH_W; k = k + 1)
                write_1(32'h3000_0000 + tag * 32'h100 + k);
            repeat (4) @(negedge clk);
        end
    endtask

    initial begin
        hs = 0; maxocc = 0;
        #20 rst_n = 1'b1;
        #30;

        /* ---------- P1/P2/P3：背靠背写满 ---------- */
        $display("--- P1/P2/P3 back-to-back burst (DEPTH=%0d) ---", DEPTH_W);
        hs = 0; maxocc = 0;
        @(negedge clk);
        auto_data = 1'b1;
        awaddr = 12'h08; awvalid = 1'b1; wvalid = 1'b1;
        repeat (300) @(negedge clk);          // 远多于灌满所需（16 字 ≈ 34 拍）
        auto_data = 1'b0;
        awvalid = 1'b0; wvalid = 1'b0;
        repeat (4) @(negedge clk);

        $display("  accepted-handshakes=%0d  word_count=%0d  maxocc=%0d  full=%b awready=%b wready=%b",
                 hs, word_count, maxocc, full, awready, wready);
        check("P1 accepted == enqueued words",
              (hs <= DEPTH_W) && (word_count == hs) && (hs == DEPTH_W));
        check("P1b FIFO really reached full", maxocc == DEPTH_W);
        check("P3 full => AW not accepted", full && !awready);

        okd = 1;
        for (k = 0; k < DEPTH_W; k = k + 1)
            if (u_fifo.mem[k] !== (32'h1000_0000 + k)) begin
                okd = 0;
                $display("      FIFO[%0d]=%h expected %h", k, u_fifo.mem[k], 32'h1000_0000 + k);
            end
        check("P2 FIFO holds first N words", okd);

        /* ---------- P5：逐字弹出 ---------- */
        $display("--- P5 pop all ---");
        okd = 1;
        for (k = 0; k < DEPTH_W; k = k + 1) begin
            while (empty) @(posedge clk);
            if (dout !== (32'h1000_0000 + k)) begin
                okd = 0;
                $display("      pop[%0d]=%h expected %h", k, dout, 32'h1000_0000 + k);
            end
            @(negedge clk); rd_en = 1'b1;
            @(negedge clk); rd_en = 1'b0;
        end
        check("P5 pop order matches push order", okd);
        while (!empty) @(posedge clk);
        check("P5b empty & count=0 after drain", empty && word_count == 0);

        /* ---------- P4a：满边界 + AW 先到 ---------- */
        $display("--- P4a full boundary, AW-first ---");
        fill_clean(1);
        pop_one();                                     // 腾出 1 字
        @(negedge clk); awaddr = 12'h08; awvalid = 1'b1; wvalid = 1'b0;
        aw_hs = 1'b0;
        guard = 0;
        while (guard < 100 && !aw_hs) begin @(negedge clk); guard = guard + 1; end
        check("P4a AW accepted after free", aw_hs);
        @(negedge clk); wdata = 32'hAAAA_1111; wvalid = 1'b1;
        w_hs = 1'b0; guard = 0;
        while (guard < 100 && !w_hs) begin @(negedge clk); guard = guard + 1; end
        @(negedge clk); awvalid = 1'b0; wvalid = 1'b0;
        repeat (6) @(negedge clk);
        okd = 1;
        for (k = 1; k < DEPTH_W; k = k + 1) begin
            pop_get(vv);
            if (vv !== (32'h3000_0000 + 32'h100 + k)) begin
                okd = 0; $display("      P4a pop[%0d]=%h", k, vv);
            end
        end
        pop_get(vv);
        if (vv !== 32'hAAAA_1111) begin okd = 0; $display("      P4a tail=%h", vv); end
        check("P4a AW-first order kept", okd);

        /* ---------- P4b：满边界 + W 先到 ---------- */
        $display("--- P4b full boundary, W-first ---");
        fill_clean(2);                                 // 重新干净灌满
        // 满时只给 W：W 被锁存（W_WON），AW 必须等空间
        @(negedge clk); awvalid = 1'b0; wvalid = 1'b1; wdata = 32'hBBBB_2222;
        repeat (8) @(negedge clk);
        @(negedge clk); wvalid = 1'b0;
        pop_one();                                     // 腾出 1 字
        @(negedge clk); awaddr = 12'h08; awvalid = 1'b1;
        aw_hs = 1'b0;
        guard = 0;
        while (guard < 100 && !aw_hs) begin @(negedge clk); guard = guard + 1; end
        @(negedge clk); awvalid = 1'b0;
        repeat (6) @(negedge clk);
        okd = 1;
        for (k = 1; k < DEPTH_W; k = k + 1) begin
            pop_get(vv);
            if (vv !== (32'h3000_0000 + 2*32'h100 + k)) begin
                okd = 0; $display("      P4b pop[%0d]=%h", k, vv);
            end
        end
        pop_get(vv);
        if (vv !== 32'hBBBB_2222) begin okd = 0; $display("      P4b tail=%h", vv); end
        check("P4b W-first order kept", okd);

        if (errors == 0) $display("========== tb_fifo_full ALL PASS ==========");
        else             $display("========== tb_fifo_full FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #2_000_000;
        $display("!!!!!!!! tb_fifo_full WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
