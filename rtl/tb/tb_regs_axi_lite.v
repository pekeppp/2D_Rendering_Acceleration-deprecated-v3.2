/* =========================================================================
 * tb_regs_axi_lite.v — 寄存器从机 + 指令 FIFO 联动自测
 * 覆盖：AXI-Lite 读写握手（含 W 先到/AW 先到）、GO/SOFT_RST 语义、
 *       STATUS 位映射、IRQ 完成沿 + 使能沿补偿 + W1C、
 *       FIFO 写满反压（fork 并发弹字验证不丢）、读回 DBG/PERF。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_regs_axi_lite;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    /* ---- AXI-Lite 主测口 ---- */
    reg  [11:0] awaddr = 12'd0;
    reg         awvalid = 1'b0;
    wire        awready;
    reg  [31:0] wdata = 32'd0;
    reg  [3:0]  wstrb = 4'h0;
    reg         wvalid = 1'b0;
    wire        wready;
    wire        bvalid;
    wire [1:0]  bresp;
    reg         bready = 1'b1;
    reg  [11:0] araddr = 12'd0;
    reg         arvalid = 1'b0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 1'b1;

    /* ---- 引擎桩信号 ---- */
    reg         eng_busy = 1'b0;
    reg         eng_done = 1'b1;      // 空闲且 FIFO 空 → DONE 电平
    reg         eng_err  = 1'b0;
    reg  [31:0] dbg_cur  = 32'h1234_5678;
    reg  [31:0] perf     = 32'h0000_00FF;

    reg         fifo_rd = 1'b0;
    wire [31:0] fifo_dout;
    wire [11:0] fifo_wcnt;
    wire        fifo_rdack;                   // 本拍确实弹出一个字（同步读 FIFO 协议）

    wire        ctrl_go, soft_rst, irq_en, irq_done, fifo_wr_en;
    wire [31:0] fifo_wr_data;
    wire        fifo_empty, fifo_full;
    wire [8:0]  fifo_cmd_count;

    /* FLIP（0x24/0x28）：请求直通扫描输出，状态由扫描输出侧给（这里用 TB 驱动桩）
     * ★v2.7：选择位 1 bit → 2 bit（三缓冲）；新增帧边界脉冲输入。 */
    wire [1:0]  fb_sel_w;
    reg  [1:0]  fb_cur_sel_r = 2'd0;
    reg  [15:0] fb_frame_cnt_r = 16'd0;
    reg         frame_pulse_r = 1'b0;

    /* ★v2.7 清屏引擎（0x2C~0x48）：配置输出 / 状态输入（TB 用桩驱动） */
    wire [31:0] clr_addr_w, clr_stride_w;
    wire [15:0] clr_w_w, clr_h_w, clr_color_w;
    wire [1:0]  clr_sel_w, draw_sel_w;
    wire        clr_go_w, clr_err_clr_w, draw_wr_w;
    reg         clr_busy_r = 1'b0, clr_err_r = 1'b0;
    reg  [3:0]  clr_clean_r = 4'b0000;
    reg  [15:0] clr_burst_r = 16'd0;
    reg  [31:0] clr_cyc_r   = 32'd0;

    wire fifo_rst_n = rst_n & ~soft_rst;      // SOFT_RST 脉冲清 FIFO

    /* ★v2.11：显示列表配置寄存器的观测线（本 TB 只做回读断言，不需要驱动） */
    wire [31:0] dl_base0_w, dl_base1_w, dl_geom_base_w, dl_dst_base_w;
    wire [15:0] dl_count_w, dl_geom_max_w, dl_timeout_w, dl_dst_stride_w;
    wire [15:0] dl_fb_w_w, dl_fb_h_w;
    wire [3:0]  dl_cfg_chunk_w, dl_cfg_wm_w;
    wire        dl_buf_sel_w, dl_irq_en_w, dl_auto_go_w, dl_strict_w;
    wire        dl_cfg_prefetch_w, dl_cfg_gec_w;
    wire        dl_go_pulse_w, dl_abort_pulse_w, dl_err_clr_pulse_w;
    wire        dl_list_rewr_pulse_w, dl_base_align_err_w;
    wire [31:0] dl_err_clr_mask_w;

    /* ★S5（v3.2）属性侧口 / scissor / LUT：观测线（本 TB 只做回读断言，不需要驱动） */
    wire        attr_empty_w;
    wire [31:0] attr_dout_w;
    wire [15:0] clip_x0_w, clip_x1_w, clip_y0_w, clip_y1_w;
    wire        clip_en_w;
    wire        lut_wr_w;
    wire [1:0]  lut_ch_w;
    wire [7:0]  lut_idx_w, lut_data_w;
    wire        lut_en_w, lut_bank_req_w;
    /* lut_wr 是 1 拍脉冲：用计数器抓，避免"检查时刻恰好错过"的时序竞态 */
    integer     lut_wr_pulses = 0;
    always @(posedge clk) if (lut_wr_w) lut_wr_pulses = lut_wr_pulses + 1;

    blt_regs_axi_lite #(.ADDR_W(12)) u_regs (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(bresp), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(rresp),
        .s_axil_rvalid(rvalid), .s_axil_rready(rready),
        .ctrl_go(ctrl_go), .soft_rst(soft_rst), .irq_en(irq_en),
        .eng_busy(eng_busy), .eng_done(eng_done), .eng_err(eng_err),
        .fifo_empty(fifo_empty), .fifo_full(fifo_full), .fifo_cmd_count(fifo_cmd_count),
        .fifo_wr_en(fifo_wr_en), .fifo_wr_data(fifo_wr_data),
        .dbg_cur(dbg_cur), .perf(perf), .irq_done(irq_done),
        .fb_sel(fb_sel_w), .fb_cur_sel(fb_cur_sel_r), .fb_frame_cnt(fb_frame_cnt_r),
        .frame_pulse(frame_pulse_r),
        .clr_addr(clr_addr_w), .clr_stride(clr_stride_w),
        .clr_w(clr_w_w), .clr_h(clr_h_w), .clr_color(clr_color_w),
        .clr_sel(clr_sel_w), .clr_go(clr_go_w), .clr_err_clr(clr_err_clr_w),
        .clr_busy(clr_busy_r), .clr_err(clr_err_r), .clr_clean(clr_clean_r),
        .clr_burst(clr_burst_r), .clr_cyc(clr_cyc_r),
        .draw_sel(draw_sel_w), .draw_wr(draw_wr_w),
        /* ★v2.11 显示列表新增端口：本 TB 只测寄存器组，DFU 不存在 ⇒ 输入全钉 0
         * （不接会悬空成 Z/X，写口仲裁的判据会被 X 污染导致 awready 恒 X） */
        .dl_base0(dl_base0_w), .dl_base1(dl_base1_w), .dl_count(dl_count_w),
        .dl_buf_sel(dl_buf_sel_w), .dl_irq_en(dl_irq_en_w),
        .dl_auto_go(dl_auto_go_w), .dl_strict(dl_strict_w),
        .dl_go_pulse(dl_go_pulse_w), .dl_abort_pulse(dl_abort_pulse_w),
        .dl_geom_base(dl_geom_base_w), .dl_geom_max(dl_geom_max_w),
        .dl_dst_base(dl_dst_base_w),
        .dl_cfg_chunk(dl_cfg_chunk_w), .dl_cfg_wm(dl_cfg_wm_w),
        .dl_cfg_prefetch(dl_cfg_prefetch_w), .dl_cfg_gec(dl_cfg_gec_w),
        .dl_timeout(dl_timeout_w), .dl_dst_stride(dl_dst_stride_w),
        .dl_fb_w(dl_fb_w_w), .dl_fb_h(dl_fb_h_w),
        .dl_err_clr_mask(dl_err_clr_mask_w), .dl_err_clr_pulse(dl_err_clr_pulse_w),
        .dl_list_rewr_pulse(dl_list_rewr_pulse_w),
        .dl_base_align_err(dl_base_align_err_w),
        .dl_busy(1'b0), .dl_done(1'b0), .dl_err(1'b0), .dl_aborted(1'b0),
        .dl_stall(1'b0), .dl_consumed(16'd0), .dl_active_buf(2'd0),
        .dl_err_word(32'd0), .dl_fault_addr(32'd0), .dl_perf(32'd0),
        .dl_cmd_req(1'b0), .dl_cmd_data(32'd0), .dl_cmd_last(1'b0), .dl_cmd_gnt(),
        /* ★S5（v3.2）新增端口：属性 FIFO 的弹脉冲由引擎给（本 TB 无引擎 ⇒ 钉 0）；
         * scissor/LUT 配置输出引到观测线；LUT 已生效 bank 由扫描输出给（钉 0）。
         * 不接会悬空成 Z/X —— 与本文件上面 DL 端口那条注释同一约定。 */
        .attr_empty(attr_empty_w), .attr_dout(attr_dout_w), .attr_pop(1'b0),
        .clip_x0(clip_x0_w), .clip_x1(clip_x1_w),
        .clip_y0(clip_y0_w), .clip_y1(clip_y1_w), .clip_en(clip_en_w),
        .lut_wr(lut_wr_w), .lut_ch(lut_ch_w), .lut_idx(lut_idx_w), .lut_data(lut_data_w),
        .lut_en(lut_en_w), .lut_bank_req(lut_bank_req_w), .lut_bank_act(1'b0)
    );

    cmd_fifo #(.CMD_DEPTH(256)) u_fifo (
        .clk(clk), .rst_n(fifo_rst_n),
        .wr_en(fifo_wr_en), .din(fifo_wr_data),
        .rd_en(fifo_rd), .rd_ack(fifo_rdack), .dout(fifo_dout),
        .full(fifo_full), .empty(fifo_empty),
        .word_count(fifo_wcnt), .cmd_count(fifo_cmd_count)
    );

    /* 弹字计数：同步读 FIFO 有 1 拍流水，连续弹字约 1 字/2 拍 —— 必须按 rd_ack
     * 计数、并按 empty（dout 有效的权威标志）决定何时可弹。 */
    integer pop_cnt = 0;
    always @(posedge clk) if (fifo_rdack) pop_cnt = pop_cnt + 1;

    /* 协议正确的"弹一个字"：先等 !empty，再拉 rd_en 一整拍 */
    task fifo_pop1;
        begin
            while (fifo_empty) @(posedge clk);
            @(posedge clk); #1; fifo_rd = 1'b1;
            @(posedge clk); #1; fifo_rd = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    always #5 clk = ~clk;

    integer errors = 0;
    integer i;

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin
                errors = errors + 1;
                $display("FAIL: %0s", name);
            end else begin
                $display("PASS: %0s", name);
            end
        end
    endtask

    /* AXI-Lite 写：拉高 AW/W，保持到 B 返回（B 意味着两通道均已握手且落地），
     * 收到 B 的同一沿后立刻撤 valid（避免下一个沿误收第二笔）。 */
    task axi_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb  = 4'hF; wvalid = 1'b1;
            while (!(bvalid && bready)) @(posedge clk);
            #1;
            awvalid = 1'b0; wvalid = 1'b0;
        end
    endtask

    /* AXI-Lite 读 */
    task axi_read;
        input [11:0] addr;
        output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!arready) @(posedge clk);
            @(posedge clk); #1;
            arvalid = 1'b0;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            @(posedge clk); #1;
        end
    endtask

    reg [31:0] rv;

    // 看门狗：正常流程 2ms 内应结束；超时强制退出并打印进度
    initial begin
        #2_000_000;
        $display("!!!!!!!! WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end

    initial begin
        #20; rst_n = 1'b1;

        // ---- 1. 复位后初值 ----
        $display("STEP1: 复位初值检查");
        axi_read(12'h00, rv); check("CTRL 初值 0", rv == 0);
        axi_read(12'h04, rv); check("STATUS DONE+FIFO_EMPTY 初值", rv == (8'h0A));
        axi_read(12'h10, rv); check("IRQ_STATUS 初值 0", rv == 0);

        // ---- 2. blt_init 序列：SOFT_RST → 0 → 清 IRQ → IRQ_EN=0 → GO ----
        $display("STEP2: init 序列");
        axi_write(12'h00, 32'h0000_0004);           // SOFT_RST
        axi_write(12'h00, 32'h0000_0000);
        axi_write(12'h10, 32'hFFFF_FFFF);           // W1C 全清
        axi_write(12'h14, 32'h0000_0000);
        axi_write(12'h00, 32'h0000_0001);           // GO
        axi_read(12'h00, rv); check("CTRL 读回 GO", (rv & 3'h1) == 1);

        // ---- 3. 推一条 FILL 指令（8 字） ----
        $display("STEP3: 推指令 8 字");
        axi_write(12'h08, 32'h0000_0001);           // op=FILL
        axi_write(12'h08, 32'h0000_0000);           // src_addr=0
        axi_write(12'h08, 32'h8030_0000);           // dst_addr
        axi_write(12'h08, 32'h0000_0000);           // src_stride
        axi_write(12'h08, 32'h0000_0780);           // dst_stride=1920
        axi_write(12'h08, 32'h02D0_03C0);           // 低16=width=960, 高16=height=540
        axi_write(12'h08, 32'h0000_00FF);           // alpha=255, pad0=0
        axi_write(12'h08, 32'h0000_F800);           // color=红
        axi_read(12'h0C, rv); check("CMD_FIFO_COUNT=1", rv == 1);
        axi_read(12'h04, rv); check("STATUS FIFO 非空", (rv & 8'h08) == 0);

        // ---- 4. IRQ：使能 → 完成沿置位 → W1C 清除 ----
        $display("STEP4: IRQ 完成沿");
        axi_write(12'h14, 32'h0000_0001);           // IRQ_EN=1
        axi_read(12'h04, rv);
        eng_busy = 1'b1; eng_done = 1'b0;           // 引擎执行中
        #40;
        // 引擎消费 8 字（按 empty/rd_ack 协议逐字弹）
        for (i = 0; i < 8; i = i + 1)
            fifo_pop1();
        check("引擎弹走 8 字（rd_ack 计数）", (pop_cnt == 8) && (fifo_wcnt == 0));
        eng_busy = 1'b0; eng_done = 1'b1;           // 完成 → DONE 沿
        #20;
        check("irq_done 置位", irq_done == 1'b1);
        axi_read(12'h10, rv); check("IRQ_STATUS bit0=1", (rv & 1) == 1);
        axi_write(12'h10, 32'h0000_0001);           // W1C
        axi_read(12'h10, rv); check("W1C 后 IRQ_STATUS=0", rv == 0);
        check("irq_done 清除", irq_done == 1'b0);
        axi_read(12'h04, rv);
        check("STATUS DONE=1", (rv & 2'h2) == 2);
        check("STATUS FIFO_EMPTY=1", (rv & 8'h8) == 8);

        // ---- 4b. 关 IRQ_EN，准备测"晚开使能"补偿 ----
        axi_write(12'h14, 32'h0000_0000);

        // ---- 5. 使能沿补偿：DONE 已高时开 IRQ_EN 应直接置位 ----
        axi_write(12'h14, 32'h0000_0001);
        #10;
        axi_read(12'h10, rv); check("晚开使能补偿置位", (rv & 1) == 1);
        axi_write(12'h14, 32'h0000_0000);
        axi_write(12'h10, 32'h0000_0001);           // 清

        // ---- 6. 读回 DBG/PERF ----
        axi_read(12'h18, rv); check("DBG_CUR_CMD 读回", rv == 32'h1234_5678);
        axi_read(12'h1C, rv); check("PERF 读回", rv == 32'h0000_00FF);

        // ---- 6b. FLIP 寄存器（v2.6 新增，不重编号旧寄存器；v2.7 选择位扩到 2 bit）----
        //   0x24 FB_SEL (W)  →  fb_sel 输出（扫描输出只在帧边界锁存它）
        //   0x28 FB_STAT (R) →  [1:0] = 已生效的显示缓冲；[31:16] = 场计数
        axi_write(12'h24, 32'h0000_0001); #10;
        check("FB_SEL 写 1 → fb_sel 输出=1", fb_sel_w === 2'd1);
        axi_read (12'h24, rv);            check("FB_SEL 读回请求=1", (rv & 32'h3) == 32'h1);
        check("FB_SEL[31:2] 恒 0", rv[31:2] == 30'd0);
        axi_write(12'h24, 32'h0000_0002); #10;
        check("★FB_SEL 写 2 → fb_sel 输出=2（三缓冲）", fb_sel_w === 2'd2);
        fb_cur_sel_r = 2'd2; fb_frame_cnt_r = 16'h1234; #10;
        axi_read (12'h28, rv);
        check("FB_STAT[1:0]=已生效选择(2)", (rv & 32'h3) == 32'h2);
        check("FB_STAT[31:16]=场计数", rv[31:16] == 16'h1234);
        check("FB_STAT[15:2] 恒 0", rv[15:2] == 14'd0);
        fb_cur_sel_r = 2'd0; fb_frame_cnt_r = 16'h0001; #10;
        axi_read (12'h28, rv);
        check("FB_STAT 跟随扫描输出侧输入变化",
              (rv[31:16] == 16'h0001) && ((rv & 32'h3) == 32'h0));
        axi_write(12'h24, 32'h0000_0000); #10;
        check("FB_SEL 写 0 → fb_sel 输出=0", fb_sel_w === 2'd0);

        // ---- 6c. ★v2.7 帧边界中断：IRQ_STATUS bit1（W1C）/ IRQ_EN bit1 ----
        //   默认（FRAME 未使能）来脉冲不该置位；使能后来一个脉冲应置位 1 拍源→状态可读。
        axi_write(12'h10, 32'hFFFF_FFFF);           // 先全清
        axi_write(12'h14, 32'h0000_0000);           // 两路使能都关
        frame_pulse_r = 1'b1; #10; frame_pulse_r = 1'b0; #10;
        axi_read (12'h10, rv); check("FRAME 未使能 → 脉冲不置位", rv == 0);
        axi_write(12'h14, 32'h0000_0002);           // IRQ_EN bit1 = FRAME 使能
        axi_read (12'h14, rv); check("IRQ_EN[1]=FRAME 使能可读回", (rv & 32'h3) == 32'h2);
        frame_pulse_r = 1'b1; #10; frame_pulse_r = 1'b0; #10;
        axi_read (12'h10, rv); check("FRAME 脉冲 → IRQ_STATUS bit1=1", (rv & 32'h2) == 32'h2);
        check("irq_done 由 FRAME 位置起", irq_done == 1'b1);
        axi_write(12'h10, 32'h0000_0002);           // W1C 只清 bit1
        axi_read (12'h10, rv); check("W1C bit1 后 IRQ_STATUS=0", rv == 0);
        check("irq_done 随之落下", irq_done == 1'b0);
        // CTRL.bit1 只动 DONE 使能，不许把 FRAME 使能冲掉
        axi_write(12'h00, 32'h0000_0003);           // GO=1, CTRL 里的 IRQ_EN=1
        axi_read (12'h14, rv); check("CTRL 写不覆盖 FRAME 使能位", (rv & 32'h2) == 32'h2);
        axi_write(12'h14, 32'h0000_0000);

        // ---- 6d. ★v2.7 清屏引擎寄存器（0x2C~0x48）----
        axi_write(12'h2C, 32'h0070_1000); axi_read(12'h2C, rv);
        check("CLR_ADDR 读回", rv == 32'h0070_1000);
        check("CLR_ADDR → clr_addr 输出", clr_addr_w === 32'h0070_1000);
        axi_write(12'h30, 32'h0000_0780); axi_read(12'h30, rv);
        check("CLR_STRIDE 读回=1920", rv == 32'h0780);
        axi_write(12'h34, 32'h020C_03C0); axi_read(12'h34, rv);
        check("CLR_WH 读回 {h,w}", rv == 32'h020C_03C0);
        check("CLR_WH → clr_w/clr_h 输出", (clr_w_w === 16'h03C0) && (clr_h_w === 16'h020C));
        axi_write(12'h38, 32'h0000_F800); axi_read(12'h38, rv);
        check("CLR_COLOR 读回", (rv & 32'hFFFF) == 32'hF800);
        check("CLR_COLOR → clr_color 输出", clr_color_w === 16'hF800);
        // CLR_CTRL：bit0 GO（1 拍脉冲）、[3:2] 目标、bit4 ERR_CLR（1 拍脉冲）
        clr_busy_r = 1'b0;
        axi_write(12'h3C, 32'h0000_000C); #2;        // 只写目标=3，不发 GO
        check("CLR_CTRL[3:2] → clr_sel=3", clr_sel_w === 2'd3);
        check("只写目标不发 GO", clr_go_w === 1'b0);
        axi_write(12'h3C, 32'h0000_000D);            // GO + 目标=3
        check("CLR_CTRL.bit0 → clr_go 1 拍脉冲", clr_go_w === 1'b1);
        #10; check("clr_go 自动落回 0", clr_go_w === 1'b0);
        axi_write(12'h3C, 32'h0000_001C);            // ERR_CLR + 目标仍为 3（[3:2] 一次写全）
        check("CLR_CTRL.bit4 → clr_err_clr 1 拍脉冲", clr_err_clr_w === 1'b1);
        #10; check("clr_err_clr 自动落回 0", clr_err_clr_w === 1'b0);
        axi_read (12'h3C, rv); check("CLR_CTRL 读回目标位", (rv[3:2] == 2'd3));
        // DRAW_SEL：写它 → draw_sel 输出 + draw_wr 1 拍脉冲（清 clean 位用）
        axi_write(12'h44, 32'h0000_0001);
        check("DRAW_SEL[1:0] → draw_sel=1", draw_sel_w === 2'd1);
        check("DRAW_SEL 写入 → draw_wr 1 拍脉冲", draw_wr_w === 1'b1);
        #10; check("draw_wr 自动落回 0", draw_wr_w === 1'b0);
        axi_read (12'h44, rv); check("DRAW_SEL 读回", (rv & 32'h3) == 32'h1);
        // CLR_STAT：bit0 BUSY、bit1 = 目标(3)的 clean 位、[5:2] 位图、bit6 ERR、[31:16] 突发数
        clr_busy_r = 1'b1; clr_err_r = 1'b1; clr_clean_r = 4'b1100; clr_burst_r = 16'h0F5A;
        #10; axi_read(12'h40, rv);
        check("CLR_STAT[0]=BUSY",       rv[0] === 1'b1);
        check("CLR_STAT[1]=目标 clean", rv[1] === 1'b1);      // 目标=3 → clean[3]=1
        check("CLR_STAT[5:2]=clean 位图", rv[5:2] === 4'b1100);
        check("CLR_STAT[6]=ERR",        rv[6] === 1'b1);
        check("CLR_STAT[15:7] 恒 0",    rv[15:7] === 9'd0);
        check("CLR_STAT[31:16]=突发数", rv[31:16] === 16'h0F5A);
        clr_clean_r = 4'b0000; #10; axi_read(12'h40, rv);
        check("CLR_STAT[1] 跟随 clean 位图（目标不干净 → 0）", rv[1] === 1'b0);
        clr_busy_r = 1'b0; clr_err_r = 1'b0;
        clr_cyc_r = 32'h0003_932B; #10; axi_read(12'h48, rv);
        check("CLR_CYC 读回", rv === 32'h0003_932B);

        // ---- 6b. ★S5（v3.2）属性 / scissor / LUT 寄存器（0x8C~0xB0）----
        //    只做"寄存器落地 + 端口输出 + 回读"的映射检查；属性与命令的配对、
        //    裁剪行为、LUT 像素级行为分别在 tb_attr_blend / tb_scissor /
        //    tb_scanout_lut 里验证（本 TB 里没有引擎与扫描输出）。
        $display("STEP6b: ★S5 属性/scissor/LUT 寄存器");
        axi_write(12'h90, 32'd11); #10;
        check("CLIP_X0 → clip_x0_w = 11", clip_x0_w === 16'd11);
        axi_write(12'h94, 32'd22); #10;
        check("CLIP_X1 → clip_x1_w = 22", clip_x1_w === 16'd22);
        axi_write(12'h98, 32'd33); #10;
        check("CLIP_Y0 → clip_y0_w = 33", clip_y0_w === 16'd33);
        axi_write(12'h9C, 32'd44); #10;
        check("CLIP_Y1 → clip_y1_w = 44", clip_y1_w === 16'd44);
        axi_write(12'hA0, 32'd1);  #10;
        check("CLIP_CTRL.bit0 → clip_en_w = 1", clip_en_w === 1'b1);
        axi_read (12'h90, rv); check("CLIP_X0 回读", rv[15:0] === 16'd11);
        axi_read (12'hA0, rv); check("CLIP_CTRL 回读 bit0=1", rv[0] === 1'b1);
        axi_write(12'hA0, 32'd0);  #10;
        check("CLIP_CTRL 关闭 → clip_en_w = 0", clip_en_w === 1'b0);
        // 属性 FIFO：写 0x8C 只入队（本 TB 无引擎 ⇒ attr_pop 恒 0），读回 = 占用深度
        axi_read (12'h8C, rv); check("ATTR_PORT 初始占用 = 0", rv === 32'd0);
        axi_write(12'h8C, 32'h0000_3FC3 | 32'h0100_0000); #10;
        check("ATTR_PORT 写 → attr_empty=0（有货）", attr_empty_w === 1'b0);
        check("ATTR_PORT 队头 = 写入值", attr_dout_w === (32'h0000_3FC3 | 32'h0100_0000));
        axi_read (12'h8C, rv); check("ATTR_PORT 占用读回 = 1", rv === 32'd1);
        // LUT 写口：LUT_ADDR 选通道/下标，LUT_DATA 写数据并产生 1 拍写脉冲
        axi_write(12'hA4, 32'h0000_0205); #10;      // ch=2(G) idx=5
        check("LUT_ADDR[9:8] → lut_ch = 2", lut_ch_w === 2'd2);
        check("LUT_ADDR[7:0] → lut_idx = 5", lut_idx_w === 8'd5);
        check("未写 LUT_DATA 时无 lut_wr 脉冲", lut_wr_pulses == 0);
        axi_write(12'hA8, 32'h0000_007B); #40;      // 写数据 → 1 拍写脉冲
        check("LUT_DATA → lut_data = 7B", lut_data_w === 8'h7B);
        check("写 LUT_DATA → lut_wr 恰好 1 拍脉冲", lut_wr_pulses == 1);
        check("lut_wr 是脉冲（当前已落回 0）", lut_wr_w === 1'b0);
        axi_write(12'hAC, 32'h0000_0003); #10;      // enable=1 bank=1
        check("LUT_CTRL.bit0 → lut_en = 1", lut_en_w === 1'b1);
        check("LUT_CTRL.bit1 → lut_bank_req = 1", lut_bank_req_w === 1'b1);
        axi_read (12'hAC, rv); check("LUT_CTRL 回读 = 3", (rv & 32'h3) === 32'h3);
        axi_read (12'hB0, rv); check("LUT_STAT.bit0 读回（本 TB 钉 0）= 0", rv[0] === 1'b0);

        // ---- 7. FIFO 写满反压（并发弹字，验证不丢） ----
        $display("STEP7: 填满 FIFO 开始 (2048 字)");
        eng_busy = 1'b1; eng_done = 1'b0;
        for (i = 0; i < 2048; i = i + 1)             // 填满 2048 字
            axi_write(12'h08, 32'h1111_0000 + i);
        $display("STEP7a: 填满完成");
        axi_read(12'h0C, rv); check("填满后 COUNT=256", rv == 256);
        $display("STEP7b: fork 反压测试");
        fork
            begin : writer
                axi_write(12'h08, 32'hCAFE_CAFE);    // 满时应被卡住
                $display("STEP7c: writer 完成");
            end
            begin : popper
                repeat (40) @(posedge clk);          // 确认已卡住（反压）
                $display("STEP7d: popper 弹字");
                fifo_pop1();                         // 引擎弹 1 字让出空间
            end
        join
        $display("STEP7e: fork join 结束");
        axi_read(12'h0C, rv); check("反压后仍满 256 条（不丢字）", rv == 256);
        eng_busy = 1'b0; eng_done = 1'b1;

        if (errors == 0)
            $display("========== tb_regs_axi_lite ALL PASS ==========");
        else
            $display("========== tb_regs_axi_lite FAILED: %0d ==========", errors);
        $finish;
    end
endmodule
