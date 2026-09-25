/* =========================================================================
 * tb_blt_burst.v — 经 APB 连续下发 300 条 1x1 FILL（2400 字 > 指令 FIFO 2048 字）
 * -------------------------------------------------------------------------
 * 目的（簇 3 回归）：证明"指令 FIFO 写满"这个边界上一条指令都不能丢 —— 300 条
 * 全部生效，并逐像素回读行为 DDR 模型比对。
 *
 * 两个下发路径都测（对应上板 fulltest 的 5c/5b）：
 *   R1 裸写：不查 CMD_FIFO_COUNT，完全靠 APB 反压（FIFO 满 → awready 低 → 桥停）
 *     阶段1：GO=0 先把 256 条（2048 字）灌到 FIFO 满（确定性地测到"满"这个边界）
 *     阶段2：GO=1 边跑边把剩下 44 条灌完（FIFO 保持满/近满）
 *   R2 带 COUNT 等待：Go=1 全程运行，每条指令前轮询 CMD_FIFO_COUNT，>=200 先等
 *
 * 证据链：
 *   - fifo_full 曾经拉高 & 峰值占用 == 2048        → 真的到过满（2400 > 2048）
 *   - 0x08 的 B 响应数 == fifo_wr_en 脉冲数 == 2400 → 受理即入队，无静默丢弃
 *   - 300 个像素逐像素回读全部等于各自唯一颜色      → 没有丢指令
 *
 * 关键设置：行为 DDR 写响应延迟 B_LAT=128（模拟真实 DDR 写回延迟），让引擎消费
 * 速度慢于 CPU 灌入速度，FIFO 才会真的冲到满。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_blt_burst;
    localparam N     = 300;
    localparam COLS  = 20;
    localparam BX    = 13;                 // 字节偏移 26 → lane 5（顺带覆盖非对齐）
    localparam BY    = 64;
    localparam FB_BASE = 32'h0000_4000;
    localparam DS      = 32'd128;          // 64 像素/行
    localparam FB_BYTES= 32'h4000;         // 0x4000..0x7FFF
    localparam SENT    = 16'hDEAD;

    reg clk = 1'b0;
    reg rst  = 1'b1;                       // blt_apb_top 高有效复位
    always #5 clk = ~clk;

    /* ---- APB 主机 ---- */
    reg  [31:0] paddr = 32'd0;
    reg  [0:0]  psel = 1'b0;
    reg         penable = 1'b0;
    reg         pwrite = 1'b0;
    reg  [31:0] pwdata = 32'd0;
    wire        pready, pslverror;
    wire [31:0] prdata;

    /* ---- 加速器 AXI 主机 ---- */
    wire [31:0] ar_addr, aw_addr;
    wire [7:0]  ar_len, aw_len;
    wire [2:0]  ar_size, aw_size;
    wire [1:0]  ar_burst, aw_burst;
    wire        ar_valid, ar_ready, r_valid, r_last;
    wire [127:0] r_data;
    wire        aw_valid, aw_ready, w_valid, w_last, b_valid;
    wire [127:0] w_data;
    wire [15:0] w_strb;
    wire        b_ready;
    wire        irq_done;

    blt_apb_top #(.AXI_DATA_W(128), .CMD_DEPTH(256)) u_dut (
        .clk(clk), .reset(rst),
        .apb_paddr(paddr), .apb_psel(psel), .apb_penable(penable),
        .apb_pready(pready), .apb_pwrite(pwrite), .apb_pwdata(pwdata),
        .apb_prdata(prdata), .apb_pslverror(pslverror),
        .irq_done(irq_done),
        .m_axi_araddr(ar_addr), .m_axi_arlen(ar_len), .m_axi_arsize(ar_size),
        .m_axi_arburst(ar_burst), .m_axi_arvalid(ar_valid), .m_axi_arready(ar_ready),
        .m_axi_rdata(r_data), .m_axi_rresp(), .m_axi_rlast(r_last),
        .m_axi_rvalid(r_valid), .m_axi_rready(r_ready),
        .m_axi_awaddr(aw_addr), .m_axi_awlen(aw_len), .m_axi_awsize(aw_size),
        .m_axi_awburst(aw_burst), .m_axi_awvalid(aw_valid), .m_axi_awready(aw_ready),
        .m_axi_wdata(w_data), .m_axi_wstrb(w_strb), .m_axi_wlast(w_last),
        .m_axi_wvalid(w_valid), .m_axi_wready(w_ready),
        .m_axi_bvalid(b_valid), .m_axi_bresp(), .m_axi_bready(b_ready)
    );

    /* 行为 DDR：写响应慢（B_LAT=128）→ 引擎消费慢 → FIFO 会被灌满 */
    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15),
                    .AR_LAT(8), .B_LAT(128), .MAXO(4)) u_mem (
        .clk(clk), .rst_n(~rst),
        .s_araddr(ar_addr), .s_arlen(ar_len), .s_arsize(ar_size), .s_arburst(ar_burst),
        .s_arvalid(ar_valid), .s_arready(ar_ready),
        .s_rdata(r_data), .s_rresp(), .s_rlast(r_last), .s_rvalid(r_valid), .s_rready(r_ready),
        .s_awaddr(aw_addr), .s_awlen(aw_len), .s_awsize(aw_size), .s_awburst(aw_burst),
        .s_awvalid(aw_valid), .s_awready(aw_ready),
        .s_wdata(w_data), .s_wstrb(w_strb), .s_wlast(w_last), .s_wvalid(w_valid), .s_wready(w_ready),
        .s_bvalid(b_valid), .s_bresp(), .s_bready(b_ready)
    );

    /* ---- 影子镜像 ---- */
    reg [15:0] sh [0:16383];

    integer errors = 0;
    integer i, k, bad;
    reg [31:0] rv;

    /* ---- 观测计数 ---- */
    integer b_cnt;         // 0x08 写事务收到 B 响应（= AXI-Lite 受理并回复 OKAY）的次数
    integer enq;           // 真正入 FIFO 的字数（fifo_wr_en 脉冲）
    integer maxocc;        // 指令 FIFO 峰值占用
    reg     full_seen;     // 是否见过 full
    integer apb_cnt;       // TB 下发的 0x08 APB 写事务数

    always @(posedge clk) begin
        if (u_dut.sa_bvalid && u_dut.sa_bready && (u_dut.u_blt.u_regs.wa[8:2] == 3'd2))
            b_cnt = b_cnt + 1;
        if (u_dut.u_blt.fifo_wr_en)
            enq = enq + 1;
        if (u_dut.u_blt.u_cmd.word_count > maxocc)
            maxocc = u_dut.u_blt.u_cmd.word_count;
        if (u_dut.u_blt.u_cmd.full)
            full_seen = 1'b1;
    end

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; sh[a >> 1] = v; end
    endtask

    /* ---- APB 主机模型（setup + access，等 PREADY） ---- */
    task apb_write;
        input [31:0] a; input [31:0] d;
        begin
            @(negedge clk);
            paddr = a; pwdata = d; pwrite = 1'b1; psel = 1'b1; penable = 1'b0;
            @(negedge clk);
            penable = 1'b1;
            @(negedge clk);
            while (!pready) @(negedge clk);
            @(negedge clk);
            psel = 1'b0; penable = 1'b0;
            if (a == 32'h08) apb_cnt = apb_cnt + 1;
        end
    endtask

    task apb_read;
        input [31:0] a; output [31:0] d;
        begin
            @(negedge clk);
            paddr = a; pwrite = 1'b0; psel = 1'b1; penable = 1'b0;
            @(negedge clk);
            penable = 1'b1;
            @(negedge clk);
            while (!pready) @(negedge clk);
            d = prdata;
            @(negedge clk);
            psel = 1'b0; penable = 1'b0;
        end
    endtask

    /* 8 个字一条指令 */
    task push_words;
        input [31:0] op, sa, da, ss, ds, w5, alpha, color;
        begin
            apb_write(32'h08, op);
            apb_write(32'h08, sa);
            apb_write(32'h08, da);
            apb_write(32'h08, ss);
            apb_write(32'h08, ds);
            apb_write(32'h08, w5);
            apb_write(32'h08, alpha);
            apb_write(32'h08, color);
        end
    endtask

    /* 真正空闲：指令 FIFO 空 + 引擎 IDLE + 写数据 FIFO 空 + 写主机 IDLE，
     * 并且连续 400 拍保持（避免"引擎刚好追上了 CPU"造成的假 DONE） */
    task wait_true_idle;
        input [255:0] name;
        integer g;
        begin
            g = 0;
            while (g < 400) begin
                @(negedge clk);
                if ((u_dut.u_blt.u_cmd.word_count == 0) &&
                    (u_dut.u_blt.u_eng.st == 3'd0) &&
                    u_dut.u_blt.u_wd_fifo.empty &&
                    (u_dut.u_blt.u_wr.st == 3'd0))
                    g = g + 1;
                else
                    g = 0;
            end
            $display("  %0s: FIFO empty / engine IDLE / wr master IDLE for 400 cycles", name);
        end
    endtask

    task verify_fb;
        input [255:0] name;
        begin
            bad = 0;
            for (k = 0; k < FB_BYTES; k = k + 2) begin
                if ({u_mem.mem[FB_BASE+k+1], u_mem.mem[FB_BASE+k]} !== sh[(FB_BASE+k) >> 1]) begin
                    bad = bad + 1;
                    if (bad <= 8)
                        $display("      MISMATCH x=%0d y=%0d got=%h exp=%h",
                                 (k % DS) / 2, k / DS,
                                 {u_mem.mem[FB_BASE+k+1], u_mem.mem[FB_BASE+k]}, sh[(FB_BASE+k) >> 1]);
                end
            end
            check(name, bad == 0);
            if (bad != 0) $display("      mis=%0d", bad);
        end
    endtask

    integer base_b, base_enq, sent;
    integer guard_cnt;

    initial begin
        b_cnt = 0; enq = 0; maxocc = 0; full_seen = 1'b0; apb_cnt = 0;
        #25 rst = 1'b0;
        repeat (5) @(negedge clk);

        /* 清中断；GO 先不开（R1 阶段1 需要引擎不消费，好确定性地把 FIFO 顶满） */
        apb_write(32'h10, 32'hFFFFFFFF);
        apb_write(32'h14, 32'h0);
        apb_write(32'h00, 32'h0);

        /* ================= R1 裸写（只靠 APB 反压） ================= */
        $display("--- R1 bare burst: 300 x FILL 1x1 (no COUNT check, APB backpressure) ---");
        for (i = 0; i < FB_BYTES; i = i + 2) poke16(FB_BASE + i, SENT);
        base_b = b_cnt; base_enq = enq; maxocc = 0; full_seen = 1'b0;
        apb_cnt = 0;
        for (i = 0; i < 256; i = i + 1)
            push_words(32'd1, 32'd0,
                       FB_BASE + (BY + i/COLS) * DS + (BX + i % COLS) * 2,
                       32'd0, DS, {16'd1, 16'd1}, 32'hFF, 16'h4000 + i[15:0]);
        $display("  phase1 (GO=0) after fill-up: enq=%0d maxocc=%0d full_seen=%b",
                 enq - base_enq, maxocc, full_seen);
        check("R1 phase1: FIFO filled to 2048", full_seen && (maxocc == 2048));
        apb_write(32'h00, 32'h1);                  // GO：开始消费
        for (i = 256; i < N; i = i + 1)
            push_words(32'd1, 32'd0,
                       FB_BASE + (BY + i/COLS) * DS + (BX + i % COLS) * 2,
                       32'd0, DS, {16'd1, 16'd1}, 32'hFF, 16'h4000 + i[15:0]);
        wait_true_idle("R1");
        $display("  R1: APB writes=%0d  B-resp(0x08)=%0d  fifo_enq=%0d  maxocc=%0d  full_seen=%b",
                 apb_cnt, b_cnt - base_b, enq - base_enq, maxocc, full_seen);
        check("R1 APB writes issued == 2400", apb_cnt == 8*N);
        check("R1 B resp == enq == 2400",
              (b_cnt - base_b) == 8*N && (enq - base_enq) == 8*N);
        for (i = 0; i < N; i = i + 1)
            sh[(FB_BASE + (BY + i/COLS)*DS + (BX + i%COLS)*2) >> 1] = 16'h4000 + i[15:0];
        verify_fb("R1 300x 1x1 FILL all effective");

        /* ================= R2 带 COUNT 等待（GO=1 全程运行） ================= */
        $display("--- R2 counted burst: wait CMD_FIFO_COUNT < 200 ---");
        for (i = 0; i < FB_BYTES; i = i + 2) poke16(FB_BASE + i, (i/2) & 16'hFFFF);
        base_b = b_cnt; base_enq = enq; maxocc = 0; full_seen = 1'b0;
        apb_cnt = 0;
        for (i = 0; i < N; i = i + 1) begin
            guard_cnt = 0;
            apb_read(32'h0C, rv);
            while (rv >= 32'd200 && guard_cnt < 200000) begin
                apb_read(32'h0C, rv);
                guard_cnt = guard_cnt + 1;
            end
            push_words(32'd1, 32'd0,
                       FB_BASE + (BY + i/COLS) * DS + (BX + i % COLS) * 2,
                       32'd0, DS, {16'd1, 16'd1}, 32'hFF, 16'h2000 + i[15:0]);
        end
        wait_true_idle("R2");
        $display("  R2: APB writes=%0d  B-resp(0x08)=%0d  fifo_enq=%0d  maxocc=%0d  full_seen=%b",
                 apb_cnt, b_cnt - base_b, enq - base_enq, maxocc, full_seen);
        check("R2 APB writes issued == 2400", apb_cnt == 8*N);
        check("R2 B resp == enq == 2400",
              (b_cnt - base_b) == 8*N && (enq - base_enq) == 8*N);
        check("R2 COUNT wait: FIFO never full", !full_seen && (maxocc < 2048));
        for (i = 0; i < N; i = i + 1)
            sh[(FB_BASE + (BY + i/COLS)*DS + (BX + i%COLS)*2) >> 1] = 16'h2000 + i[15:0];
        verify_fb("R2 300x 1x1 FILL all effective");

        if (errors == 0) $display("========== tb_blt_burst ALL PASS ==========");
        else             $display("========== tb_blt_burst FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("!!!!!!!! tb_blt_burst WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
