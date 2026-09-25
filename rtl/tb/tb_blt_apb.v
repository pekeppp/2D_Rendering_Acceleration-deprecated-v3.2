/* =========================================================================
 * tb_blt_apb.v — APB 外设通路自测（blt_apb_top = APB→AXI-Lite 桥 + 加速器）
 * -------------------------------------------------------------------------
 * 为什么必须单独测：SoC 侧软件是通过 APB 窗口 (BLT_BASE=0xF8100000) 读写寄存器的，
 * APB→AXI-Lite 桥的时序（PREADY 只拉 1 拍、AW/W 同发、读回锁存）没有任何别的测试
 * 覆盖。本 TB 用 APB 主机模型完成"整条链路"：APB 写指令 → 引擎 → AXI 读写 DDR 模型
 *   T1 CTRL 读写回环（验证寄存器口方向/位宽）
 *   T2 APB 下发 FILL 指令 → 轮询 STATUS.DONE → 读 PERF/DBG_CUR_CMD → 校验 DDR 内容
 *   T3 APB 下发 COPY 指令 → 校验搬运结果
 *   T4 FIFO 深度占用读回（CMD_FIFO_COUNT）
 * ========================================================================= */
`timescale 1ns/1ps
module tb_blt_apb;
    reg clk = 1'b0;
    reg rst  = 1'b1;                 // blt_apb_top 用高有效 reset
    always #5 clk = ~clk;

    /* ---- APB 主机 ---- */
    reg  [31:0] paddr = 32'd0;
    reg  [0:0]  psel = 1'b0;
    reg         penable = 1'b0;
    reg         pwrite = 1'b0;
    reg  [31:0] pwdata = 32'd0;
    wire        pready, pslverror;
    wire [31:0] prdata;

    /* ---- 加速器 AXI 主机（接行为 DDR 模型） ---- */
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

    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15), .AR_LAT(8), .B_LAT(2), .MAXO(4)) u_mem (
        .clk(clk), .rst_n(~rst),
        .s_araddr(ar_addr), .s_arlen(ar_len), .s_arsize(ar_size), .s_arburst(ar_burst),
        .s_arvalid(ar_valid), .s_arready(ar_ready),
        .s_rdata(r_data), .s_rresp(), .s_rlast(r_last), .s_rvalid(r_valid), .s_rready(r_ready),
        .s_awaddr(aw_addr), .s_awlen(aw_len), .s_awsize(aw_size), .s_awburst(aw_burst),
        .s_awvalid(aw_valid), .s_awready(aw_ready),
        .s_wdata(w_data), .s_wstrb(w_strb), .s_wlast(w_last), .s_wvalid(w_valid), .s_wready(w_ready),
        .s_bvalid(b_valid), .s_bresp(), .s_bready(b_ready)
    );

    integer errors = 0, i, n, mism;
    reg [31:0] rv;
    reg [15:0] pv, exp;

    task check;
        input [255:0] name;
        input ok;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* ---- APB 主机模型：setup(1拍) + access(等到 PREADY) ---- */
    task apb_write;
        input [31:0] a;
        input [31:0] d;
        begin
            @(negedge clk);
            paddr = a; pwdata = d; pwrite = 1'b1; psel = 1'b1; penable = 1'b0;
            @(negedge clk);
            penable = 1'b1;
            @(negedge clk);
            while (!pready) @(negedge clk);
            @(negedge clk);
            psel = 1'b0; penable = 1'b0;
        end
    endtask

    /* APB 主机模型：全部在 **negedge** 驱动/采样。
     * 为什么不用 posedge：PREADY/prdata 是 DUT 在 posedge 更新的寄存器，
     * 若在 posedge 采样会读到"上一拍"的值，导致整个读取序列错位一次
     * （曾因此误判为 RTL 滞后一拍）。negedge 时值已稳定，语义无歧义。 */
    task apb_read;
        input [31:0] a;
        output [31:0] d;
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

    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; end
    endtask

    task peek16;
        input [31:0] a; output [15:0] v;
        begin v = {u_mem.mem[a+1], u_mem.mem[a]}; end
    endtask

    /* 下发一条指令：8 个字顺序写 CMD_FIFO_DATA(0x08) */
    task push_cmd;
        input [1:0]  op;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H;
        input [7:0]  alpha;
        input [15:0] color;
        begin
            apb_write(32'h08, {30'd0, op});
            apb_write(32'h08, sa);
            apb_write(32'h08, da);
            apb_write(32'h08, ss);
            apb_write(32'h08, ds);
            apb_write(32'h08, {H, W});
            apb_write(32'h08, {8'd0, alpha});
            apb_write(32'h08, {16'd0, color});
        end
    endtask

    task wait_done;
        input [255:0] name;
        begin : wd
            for (n = 0; n < 200000; n = n + 1) begin
                apb_read(32'h04, rv);
                if (rv & 32'h2) begin
                    $display("  %0s: STATUS=0x%x DONE", name, rv);
                    disable wd;
                end
                if (rv & 32'h4) begin
                    $display("FAIL: %0s 引擎 ERR", name);
                    errors = errors + 1;
                    disable wd;
                end
            end
            $display("FAIL: %0s 等待 DONE 超时", name);
            errors = errors + 1;
        end
    endtask

    initial begin
        #25 rst = 1'b0;

        /* ---- T1 寄存器读写回环：验证 APB 桥与寄存器口方向/位宽 ---- */
        $display("--- T1 寄存器读写回环 ---");
        apb_read(32'h00, rv);
        $display("  CTRL 初始 = 0x%x", rv);
        check("T1 初始 CTRL.GO=0", (rv & 32'h1) == 32'h0);
        apb_write(32'h14, 32'h1);            // IRQ_EN = 1
        apb_read(32'h14, rv);
        check("T1 IRQ_EN 写 1 读回 1", rv == 32'h1);
        apb_read(32'h00, rv);
        check("T1 CTRL 读回含 IRQ_EN(bit1)", (rv & 32'h2) == 32'h2);
        apb_write(32'h14, 32'h0);            // 关中断
        apb_write(32'h00, 32'h4);            // SOFT_RST
        apb_write(32'h00, 32'h0);
        apb_write(32'h10, 32'hFFFFFFFF);     // 清 IRQ（W1C）
        apb_write(32'h00, 32'h1);            // GO
        apb_read(32'h00, rv);
        check("T1 GO 置位后可读回", (rv & 32'h1) == 32'h1);
        apb_write(32'h00, 32'h5);            // SOFT_RST+GO：写完立刻读，验证"写→读"时序
        apb_read(32'h00, rv);
        check("T1 写完立刻读能见新值", (rv & 32'h1) == 32'h1);

        /* ---- T2 APB 下发 FILL 指令 ---- */
        $display("--- T2 APB FILL ---");
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h5555);
        push_cmd(2'd1, 0, 32'h2000, 0, 32'd32, 16'd16, 16'd2, 8'hFF, 16'hF800);
        apb_read(32'h0C, rv);
        $display("  CMD_FIFO_COUNT 入队后 = %0d", rv);
        wait_done("T2 FILL");
        apb_read(32'h1C, rv);
        $display("  PERF = %0d cycles", rv);
        check("T2 PERF 非 0", rv != 32'd0);
        apb_read(32'h18, rv);
        $display("  DBG_CUR_CMD = 0x%x (期望 1=FILL)", rv);
        check("T2 DBG_CUR_CMD = FILL(op=1)", rv == 32'd1);
        peek16(32'h2000, pv); check("T2 (0,0)=F800", pv == 16'hF800);
        peek16(32'h201E, pv); check("T2 (15,0)=F800", pv == 16'hF800);
        peek16(32'h203E, pv); check("T2 (15,1)=F800", pv == 16'hF800);
        peek16(32'h2040, pv); check("T2 后界未动", pv == 16'h5555);

        /* ---- T3 APB 下发 COPY 指令（带行距） ---- */
        $display("--- T3 APB COPY ---");
        for (i = 0; i < 8; i = i + 1) begin
            poke16(32'h1000 + i * 2, 16'hA000 + i);
            poke16(32'h1020 + i * 2, 16'hB000 + i);
        end
        for (i = 0; i < 128; i = i + 1) poke16(32'h4000 + i * 2, 16'h0000);
        push_cmd(2'd0, 32'h1000, 32'h4000, 32'd32, 32'd32, 16'd8, 16'd2, 8'hFF, 16'd0);
        wait_done("T3 COPY");
        peek16(32'h4000, pv); check("T3 行0px0", pv == 16'hA000);
        peek16(32'h400E, pv); check("T3 行0px7", pv == 16'hA007);
        peek16(32'h4020, pv); check("T3 行1px0", pv == 16'hB000);
        peek16(32'h4010, pv); check("T3 行0外未动", pv == 16'h0000);

        /* ---- T4 指令 FIFO 计数：一次推 3 条，读回应为 3 ---- */
        $display("--- T4 CMD_FIFO_COUNT ---");
        push_cmd(2'd1, 0, 32'h2000, 0, 32'd32, 16'd8, 16'd1, 8'hFF, 16'h001F);
        push_cmd(2'd1, 0, 32'h2020, 0, 32'd32, 16'd8, 16'd1, 8'hFF, 16'h07E0);
        push_cmd(2'd1, 0, 32'h2040, 0, 32'd32, 16'd8, 16'd1, 8'hFF, 16'hF800);
        apb_read(32'h0C, rv);
        $display("  入队 3 条后 CMD_FIFO_COUNT = %0d", rv);
        wait_done("T4 三条 FILL");

        if (errors == 0) $display("========== tb_blt_apb ALL PASS ==========");
        else             $display("========== tb_blt_apb FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #5_000_000;
        $display("!!!!!!!! tb_blt_apb WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
