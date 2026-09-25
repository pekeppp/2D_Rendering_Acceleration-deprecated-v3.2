/* =========================================================================
 * tb_blt_top.v — BitBlt 引擎集成自测（blt_top + 行为 AXI 从机）
 * -------------------------------------------------------------------------
 * 功能用例：FILL 对齐/非对齐、COPY 带行距、KEY 键控留孔、ALPHA 定点混合
 * 性能用例（行级重叠 + 突发流水改造的量化证据）：
 *   T7 多行 COPY（32 行 × 24 像素，每行 4 拍突发）
 *   T8 极扁 COPY（64 行 × 8 像素，每行仅 1 拍突发 → 最能暴露"行固定开销"）
 *   每个用例打印 PERF 周期数；同一测试台可对旧/新 RTL 各跑一次做 A/B 对比。
 * 从机 AR_LAT=20：模拟真实 DDR 读延迟（延迟有没有被藏住，看 T8 最清楚）。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_blt_top;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    /* ---- AXI-Lite 主测口 ---- */
    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

    /* ---- 引擎 AXI 主机（接行为从机） ---- */
    wire [31:0] m_araddr, m_awaddr;
    wire [7:0]  m_arlen, m_awlen;
    wire [2:0]  m_arsize, m_awsize;
    wire [1:0]  m_arburst, m_awburst;
    wire        m_arvalid, m_arready, m_rvalid, m_rlast;
    wire [127:0] m_rdata;
    wire        m_awvalid, m_awready, m_wvalid, m_wlast, m_bvalid;
    wire [127:0] m_wdata;
    wire [15:0] m_wstrb;
    wire        m_bready;
    wire        irq_done;

    /* ★v2.7：清屏引擎互斥用的"当前显示缓冲"由 TB 驱动；并统计 AXI 写口上的 AW 笔数 */
    reg  [1:0]  fb_cur_sel_r = 2'd0;
    integer     aw_cnt = 0;
    always @(posedge clk) if (m_awvalid && m_awready) aw_cnt = aw_cnt + 1;

    blt_top #(.AXI_DATA_W(128), .CMD_DEPTH(256)) u_blt (
        .clk(clk), .rst_n(rst_n),
        .s_axil_awaddr(awaddr), .s_axil_awvalid(awvalid), .s_axil_awready(awready),
        .s_axil_wdata(wdata), .s_axil_wstrb(wstrb),
        .s_axil_wvalid(wvalid), .s_axil_wready(wready),
        .s_axil_bvalid(bvalid), .s_axil_bresp(), .s_axil_bready(bready),
        .s_axil_araddr(araddr), .s_axil_arvalid(arvalid), .s_axil_arready(arready),
        .s_axil_rdata(rdata), .s_axil_rresp(), .s_axil_rvalid(rvalid), .s_axil_rready(rready),
        .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready),
        .m_axi_rdata(m_rdata), .m_axi_rresp(), .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready),
        .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen), .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst), .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready),
        .m_axi_wdata(m_wdata), .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast),
        .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
        .m_axi_bvalid(m_bvalid), .m_axi_bresp(), .m_axi_bready(m_bready),
        .irq_done(irq_done),
        /* ★v2.7 新增端口：不接会悬空成 Z（清屏引擎的互斥判据要用 fb_cur_sel） */
        .fb_sel(), .fb_cur_sel(fb_cur_sel_r), .fb_frame_cnt(16'd0), .frame_pulse(1'b0)
    );

    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15), .AR_LAT(20), .B_LAT(2), .MAXO(4)) u_mem (
        .clk(clk), .rst_n(rst_n),
        .s_araddr(m_araddr), .s_arlen(m_arlen), .s_arsize(m_arsize),
        .s_arburst(m_arburst), .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata), .s_rresp(), .s_rlast(m_rlast),
        .s_rvalid(m_rvalid), .s_rready(m_rready),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize),
        .s_awburst(m_awburst), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast),
        .s_wvalid(m_wvalid), .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(), .s_bready(m_bready)
    );

    always #5 clk = ~clk;

    /* ---- 全局周期计数（性能测量） ---- */
    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    integer errors = 0;
    integer i, j, n, rr, cc, mism;
    reg [31:0] rv;
    reg timedout;
    integer t_start, t_end;

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

    /* ---- AXI-Lite 写 ---- */
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

    task axi_read;
        input [11:0] addr;
        output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            #1;
            arvalid = 1'b0;
        end
    endtask

    /* ---- 行为内存存取 ---- */
    task poke16;
        input [31:0] a;
        input [15:0] v;
        begin
            u_mem.mem[a]   = v[7:0];
            u_mem.mem[a+1] = v[15:8];
        end
    endtask

    task peek16;
        input [31:0] a;
        output [15:0] v;
        begin
            v = {u_mem.mem[a+1], u_mem.mem[a]};
        end
    endtask

    /* ---- 引擎初始化 + 推一条指令 + 等待完成（并测周期） ---- */
    task eng_init;
        begin
            axi_write(12'h00, 32'h4);          // SOFT_RST
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);   // 清 IRQ
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);          // GO
        end
    endtask

    task push_cmd;
        input [1:0]  op;
        input [31:0] sa, da, ss, ds;
        input [15:0] W, H;
        input [7:0]  alpha;
        input [15:0] color;
        begin
            axi_write(12'h08, {30'd0, op});
            axi_write(12'h08, sa);
            axi_write(12'h08, da);
            axi_write(12'h08, ss);
            axi_write(12'h08, ds);
            axi_write(12'h08, {H, W});
            axi_write(12'h08, {8'd0, alpha});
            axi_write(12'h08, {16'd0, color});
        end
    endtask

    /* 轮询 DONE，并打印本条指令的引擎耗时（周期数） */
    task wait_done;
        input [255:0] name;
        begin : wd
            t_start = cyc;
            for (n = 0; n < 400000; n = n + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) begin
                    t_end = cyc;
                    $display("PERF %0s: %0d cycles", name, t_end - t_start);
                    disable wd;
                end
                if (rv & 32'h4) begin
                    $display("FAIL: 引擎 ERR 状态");
                    errors = errors + 1;
                    disable wd;
                end
            end
            $display("FAIL: 等待 DONE 超时");
            errors = errors + 1;
        end
    endtask

    reg [15:0] pv, exp;

    initial begin
        #20 rst_n = 1'b1;

        /* ============ T1 FILL 对齐 16x2 @0x2000, stride 32 ============ */
        $display("--- T1 FILL aligned ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h5555);
        push_cmd(2'd1, 0, 32'h2000, 0, 32'd32, 16'd16, 16'd2, 8'hFF, 16'hF800);
        wait_done("T1 FILL 16x2");
        peek16(32'h2000, pv); check("T1 (0,0)=F800", pv == 16'hF800);
        peek16(32'h201E, pv); check("T1 (15,0)=F800", pv == 16'hF800);
        peek16(32'h2020, pv); check("T1 (0,1)=F800", pv == 16'hF800);
        peek16(32'h203E, pv); check("T1 (15,1)=F800", pv == 16'hF800);
        peek16(32'h1FFE, pv); check("T1 前界未动", pv == 16'h5555);
        peek16(32'h2040, pv); check("T1 后界未动", pv == 16'h5555);

        /* ============ T2 FILL 非对齐 x=3（byte 6, lane3） ============ */
        $display("--- T2 FILL unaligned ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h5555);
        push_cmd(2'd1, 0, 32'h2006, 0, 32'd32, 16'd16, 16'd2, 8'hFF, 16'h00F0);
        wait_done("T2 FILL 16x2 unaligned");
        peek16(32'h2000, pv); check("T2 lane<3 未写(2000)", pv == 16'h5555);
        peek16(32'h2002, pv); check("T2 lane<3 未写(2002)", pv == 16'h5555);
        peek16(32'h2004, pv); check("T2 lane=2 未写(2004)", pv == 16'h5555);
        peek16(32'h2006, pv); check("T2 (x0)=00F0", pv == 16'h00F0);
        peek16(32'h2024, pv); check("T2 行0末=00F0", pv == 16'h00F0);
        peek16(32'h2044, pv); check("T2 行1末=00F0", pv == 16'h00F0);
        peek16(32'h2046, pv); check("T2 尾部未写(2046)", pv == 16'h5555);

        /* ============ T3 COPY 8x2 @0x1000 → 0x4000（带行距 32） ============ */
        $display("--- T3 COPY ---");
        eng_init();
        for (i = 0; i < 8; i = i + 1) begin
            poke16(32'h1000 + i * 2, 16'hA000 + i);
            poke16(32'h1020 + i * 2, 16'hB000 + i);
        end
        for (i = 0; i < 128; i = i + 1) poke16(32'h4000 + i * 2, 16'h0000);
        push_cmd(2'd0, 32'h1000, 32'h4000, 32'd32, 32'd32, 16'd8, 16'd2, 8'hFF, 16'd0);
        wait_done("T3 COPY 8x2");
        peek16(32'h4000, pv); check("T3 行0px0", pv == 16'hA000);
        peek16(32'h400E, pv); check("T3 行0px7", pv == 16'hA007);
        peek16(32'h4020, pv); check("T3 行1px0", pv == 16'hB000);
        peek16(32'h402E, pv); check("T3 行1px7", pv == 16'hB007);
        peek16(32'h4010, pv); check("T3 行0外未动", pv == 16'h0000);

        /* ============ T4 KEY 键控（0xF81F 跳过） ============ */
        $display("--- T4 KEY ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h1111);
        for (i = 0; i < 8; i = i + 1) begin
            poke16(32'h3000 + i * 2, (i % 2) ? 16'hF81F   : (16'h1000 + i));
            poke16(32'h3020 + i * 2, (i % 2) ? (16'h2000 + i) : 16'hF81F);
        end
        push_cmd(2'd3, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'hFF, 16'hF81F);
        wait_done("T4 KEY 8x2");
        peek16(32'h2000, pv); check("T4 px0 写入", pv == 16'h1000);
        peek16(32'h2002, pv); check("T4 px1 键色保留背景", pv == 16'h1111);
        peek16(32'h2004, pv); check("T4 px2 写入", pv == 16'h1002);
        peek16(32'h2006, pv); check("T4 px3 键色保留", pv == 16'h1111);
        peek16(32'h200E, pv); check("T4 px7 键色保留", pv == 16'h1111);
        peek16(32'h2020, pv); check("T4 行1px0 键色保留", pv == 16'h1111);
        peek16(32'h2022, pv); check("T4 行1px1 写入", pv == 16'h2001);

        /* ============ T5 ALPHA：白叠黑 α=128 → 0x7BEF ============ */
        $display("--- T5 ALPHA ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h0000);
        for (i = 0; i < 8; i = i + 1) begin
            poke16(32'h3000 + i * 2, 16'hFFFF);
            poke16(32'h3020 + i * 2, 16'hFFFF);
        end
        push_cmd(2'd2, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'd128, 16'd0);
        wait_done("T5 ALPHA 8x2");
        peek16(32'h2000, pv); check("T5 α=128 白叠黑=7BEF", pv == 16'h7BEF);
        peek16(32'h200E, pv); check("T5 α=128 (7,0)=7BEF", pv == 16'h7BEF);
        peek16(32'h2020, pv); check("T5 α=128 行1=7BEF", pv == 16'h7BEF);

        /* ============ T6 ALPHA α=255 全不透明 → FFFF ============ */
        $display("--- T6 ALPHA 255 ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h0000);
        push_cmd(2'd2, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'd255, 16'd0);
        wait_done("T6 ALPHA 8x2 a=255");
        peek16(32'h2000, pv); check("T6 α=255=FFFF", pv == 16'hFFFF);

        /* ============ T9 ALPHA 彩色的"非盲"用例 ============
         * T5/T6 是白/黑：字段全 0 或全 1，任何错误的位复制展开都恰好无损，
         * 所以它们对本 bug 是**盲的**（上板 ALPHA 全错而 T5/T6 一直 PASS 的原因）。
         * 这里用 fg=0xFD20 / bg=0x0010 这种"低位不为 0/1"的颜色：
         *   α=0   → 必须逐像素等于纯背景 0x0010（等价于展开+混合的恒等性）
         *   α=255 → 必须逐像素等于纯前景 0xFD20
         *   α=160 → 金标准 0x9B46（0x9B25 就是修复前那个"小 1 个 LSB"的错值） */
        $display("--- T9 ALPHA 彩色非盲用例 fg=FD20 bg=0010 ---");
        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h0010);
        poke16(32'h1FFE, 16'hDEAD);       // 区域前哨兵
        poke16(32'h2010, 16'hDEAD);       // 行 0 区域后哨兵（同词内，验掩码）
        for (i = 0; i < 8; i = i + 1) begin
            poke16(32'h3000 + i * 2, 16'hFD20);
            poke16(32'h3020 + i * 2, 16'hFD20);
        end
        push_cmd(2'd2, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'd0, 16'd0);
        wait_done("T9 ALPHA a=0 (bg 恒等)");
        peek16(32'h2000, pv); check("T9 α=0 → 纯背景 0010", pv == 16'h0010);
        peek16(32'h200E, pv); check("T9 α=0 行0末=0010", pv == 16'h0010);
        peek16(32'h2020, pv); check("T9 α=0 行1=0010", pv == 16'h0010);
        peek16(32'h1FFE, pv); check("T9 前界未动", pv == 16'hDEAD);
        peek16(32'h2010, pv); check("T9 行0后界未动(掩码)", pv == 16'hDEAD);

        eng_init();
        push_cmd(2'd2, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'd255, 16'd0);
        wait_done("T9 ALPHA a=255 (fg 恒等)");
        peek16(32'h2000, pv); check("T9 α=255 → 纯前景 FD20", pv == 16'hFD20);
        peek16(32'h200E, pv); check("T9 α=255 行0末=FD20", pv == 16'hFD20);
        peek16(32'h2020, pv); check("T9 α=255 行1=FD20", pv == 16'hFD20);

        eng_init();
        for (i = 0; i < 64; i = i + 1) poke16(32'h2000 + i * 2, 16'h0010);
        push_cmd(2'd2, 32'h3000, 32'h2000, 32'd32, 32'd32, 16'd8, 16'd2, 8'd160, 16'd0);
        wait_done("T9 ALPHA a=160 (中间α)");
        peek16(32'h2000, pv); check("T9 α=160 → 金标准 9B46", pv == 16'h9B46);
        peek16(32'h200E, pv); check("T9 α=160 行0末=9B46", pv == 16'h9B46);
        peek16(32'h2020, pv); check("T9 α=160 行1=9B46", pv == 16'h9B46);

        /* ============ T7 多行 COPY 32 行 × 24 像素（每行 4 拍突发） ============
         * 专测"行级重叠"：32 行各 1 笔突发，旧版每行都要等一次 AR + 读延迟。 */
        $display("--- T7 COPY 32 rows x 24 px ---");
        eng_init();
        for (rr = 0; rr < 32; rr = rr + 1)
            for (cc = 0; cc < 24; cc = cc + 1)
                poke16(32'h1000 + rr * 64 + cc * 2, 16'h3000 + rr * 24 + cc);
        for (i = 0; i < 1024; i = i + 1) poke16(32'h6000 + i * 2, 16'hDEAD);
        push_cmd(2'd0, 32'h1000, 32'h6000, 32'd64, 32'd64, 16'd24, 16'd32, 8'hFF, 16'd0);
        wait_done("T7 COPY 32x24 (768px)");
        mism = 0;
        for (rr = 0; rr < 32; rr = rr + 1)
            for (cc = 0; cc < 24; cc = cc + 1) begin
                peek16(32'h1000 + rr * 64 + cc * 2, exp);
                peek16(32'h6000 + rr * 64 + cc * 2, pv);
                if (pv !== exp) begin
                    mism = mism + 1;
                    if (mism <= 12) $display("  T7 MISMATCH row=%0d col=%0d exp=%h got=%h", rr, cc, exp, pv);
                end
            end
        check("T7 全区域逐像素比对 (768px)", mism == 0);
        if (mism != 0) $display("  T7 不一致像素数 = %0d", mism);

        /* ============ T8 极扁 COPY 64 行 × 8 像素（每行仅 1 拍突发） ============
         * 最能暴露"每行固定开销"：每行数据只有 16B，延迟若没藏住，时间几乎全是等待。 */
        $display("--- T8 COPY 64 rows x 8 px ---");
        eng_init();
        for (rr = 0; rr < 64; rr = rr + 1)
            for (cc = 0; cc < 8; cc = cc + 1)
                poke16(32'h1000 + rr * 32 + cc * 2, 16'h5000 + rr * 8 + cc);
        for (i = 0; i < 1024; i = i + 1) poke16(32'h6000 + i * 2, 16'hBEEF);
        push_cmd(2'd0, 32'h1000, 32'h6000, 32'd32, 32'd32, 16'd8, 16'd64, 8'hFF, 16'd0);
        wait_done("T8 COPY 64x8 (512px)");
        mism = 0;
        for (rr = 0; rr < 64; rr = rr + 1)
            for (cc = 0; cc < 8; cc = cc + 1) begin
                peek16(32'h1000 + rr * 32 + cc * 2, exp);
                peek16(32'h6000 + rr * 32 + cc * 2, pv);
                if (pv !== exp) mism = mism + 1;
            end
        check("T8 全区域逐像素比对 (512px)", mism == 0);
        if (mism != 0) $display("  T8 不一致像素数 = %0d", mism);

        /* PERF 寄存器（0x1C）：引擎锁存的上一条指令周期数（给软件做性能统计） */
        axi_read(12'h1C, rv);
        $display("PERF-REG (0x1C) = %0d cycles", rv);
        check("T8 PERF 寄存器已锁存非零", rv != 32'd0);

        /* ============ T10 ★v2.7 并发清屏引擎：**全路径集成** ============
         * 寄存器（0x2C~0x48）→ clr_engine → blt_top 内的写仲裁器（BitBlt 空闲 = 直通）
         * → blt_top 的 m_axi 写口 → 行为从机 → 回读像素。
         * 这一条覆盖的是"接线/译码/互斥在真实顶层里都成立"，与 tb_clear_engine 的
         * 单模块吞吐/协议测试互补。 */
        $display("--- T10 clear engine via registers (32x8 @0x4000) ---");
        eng_init();
        for (i = 0; i < 512; i = i + 1) poke16(32'h4000 + i * 2, 16'hDEAD);   /* 区域 + 外围 */
        fb_cur_sel_r = 2'd0;                       /* 显示 = 0 */
        axi_write(12'h44, 32'h0000_0001);          /* DRAW_SEL = 1（引擎在画 1） */
        axi_write(12'h2C, 32'h0000_4000);          /* CLR_ADDR   */
        axi_write(12'h30, 32'h0000_0040);          /* CLR_STRIDE = 64 B（32 px/行） */
        axi_write(12'h34, 32'h0008_0020);          /* CLR_WH：h=8, w=32 */
        axi_write(12'h38, 32'h0000_1234);          /* CLR_COLOR  */
        aw_cnt  = 0;
        t_start = cyc;
        axi_write(12'h3C, 32'h0000_0009);          /* CLR_CTRL：GO + 目标 = 2 */
        rv = 32'h1;
        for (i = 0; (i < 20000) && (rv & 32'h1); i = i + 1) axi_read(12'h40, rv);
        t_end = cyc;
        axi_read(12'h40, rv);
        $display("T10 clear cycles=%0d  AW bursts=%0d  CLR_STAT=%x", t_end - t_start, aw_cnt, rv);
        check("T10 清屏完成 BUSY=0",       (rv & 32'h1) == 0);
        check("T10 目标缓冲 clean 位=1",   (rv & 32'h2) == 32'h2);
        check("T10 clean 位图 bit2=1",     (rv[5:2] & 4'h4) == 4'h4);
        check("T10 ERR=0（没触发互斥）",    (rv & 32'h40) == 0);
        check("T10 AW 突发数 = 2（32 拍合并成 2×16）", aw_cnt == 2);
        check("T10 寄存器里的突发数 = 2",  rv[31:16] == 16'd2);
        mism = 0;
        for (rr = 0; rr < 8; rr = rr + 1)
            for (cc = 0; cc < 32; cc = cc + 1) begin
                peek16(32'h4000 + rr * 64 + cc * 2, pv);
                if (pv !== 16'h1234) begin
                    mism = mism + 1;
                    if (mism <= 8) $display("  T10 MISMATCH row=%0d col=%0d got=%h", rr, cc, pv);
                end
            end
        check("T10 区域内逐像素 = CLR_COLOR (256px)", mism == 0);
        if (mism != 0) $display("  T10 不一致像素数 = %0d", mism);
        peek16(32'h4000 + 8 * 64, pv); check("T10 区域后一行未被写", pv == 16'hDEAD);
        peek16(32'h4000 - 2,      pv); check("T10 区域前一字未被写", pv == 16'hDEAD);

        /* ---- T10b ★ 硬件互斥（寄存器路径）：目标 = 正在显示的缓冲 ⇒ 一个 AW 都不许发 ---- */
        $display("--- T10b clear-engine mutex via registers ---");
        fb_cur_sel_r = 2'd2;                       /* 目标 2 正在显示 */
        aw_cnt = 0;
        axi_write(12'h3C, 32'h0000_0009);          /* GO + 目标 = 2 */
        repeat (50) @(posedge clk);
        axi_read(12'h40, rv);
        check("T10b 清正在显示的缓冲 → 0 笔 AW", aw_cnt == 0);
        check("T10b ERR 置位",                 (rv & 32'h40) == 32'h40);
        check("T10b BUSY=0（立刻返回，不死等）", (rv & 32'h1) == 0);
        axi_write(12'h3C, 32'h0000_0018);          /* ERR_CLR（bit4）+ 目标 = 2 */
        axi_read(12'h40, rv);
        check("T10b ERR_CLR 后 ERR=0", (rv & 32'h40) == 0);
        fb_cur_sel_r = 2'd0;
        axi_read(12'h48, rv);
        $display("T10 CLR_CYC (0x48) = %0d", rv);
        check("T10 CLR_CYC 非零", rv != 32'd0);

        if (errors == 0)
            $display("========== tb_blt_top ALL PASS ==========");
        else
            $display("========== tb_blt_top FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #30_000_000;
        $display("!!!!!!!! WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
