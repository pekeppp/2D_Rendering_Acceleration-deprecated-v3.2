/* =========================================================================
 * tb_blt_unalign.v — 非对齐 lane / 退化尺寸 逐像素回归（簇 2 复现台）
 * -------------------------------------------------------------------------
 * 覆盖上板实测出错的几类情形（全部逐像素比对整幅 FB 影子镜像）：
 *   U1  FILL 32x16 @x=3   字节偏移 6  -> lane 3        （上板 A2：PASS 基准）
 *   U2  FILL 32x8  @x=7   字节偏移 14 -> lane 7
 *   U3  FILL 32x8  @x=5   字节偏移 10 -> lane 5
 *   U4  FILL 1x64  @x=4   字节偏移 8  -> lane 4，退化成竖条（上板 A4a）
 *   U5  FILL 200x1 @x=2   字节偏移 4  -> lane 2，退化横条 + 跨 16 拍突发（上板 A4b）
 *   U6  KEY  16x8  @x=7   字节偏移 14 -> lane 7，首词只有 1 个 lane（上板 C4）
 *   U7  KEY  16x8  @x=0   首词整词全键色（整词跳过 → 后续词地址仍须进位）
 *   U8  COPY 20x8  src 行内 x=3 + dst x=13（字节偏移 26 -> lane 5）（上板 B2）
 *   U9  COPY 13x9  src x=7 + dst x=11（双非对齐 + W%8!=0）
 *   U10 FILL 1x1   @x=7 / @x=31（单像素）
 *   U11 COPY 8x1   对齐 / 8x1 @src x=5 -> dst x=3（词边界）
 *   U12 KEY  32x4  @x=5（dst lane 5，行内混合键色）
 *
 * 判定：TB 内维护一份"影子镜像"（整幅 FB 的期望像素），每个用例跑完把行为
 *       DDR 模型的整幅 FB 与影子逐像素比对 —— 错一个像素都算 FAIL。
 * ========================================================================= */
`timescale 1ns/1ps
module tb_blt_unalign;
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

    /* ---- 引擎 AXI 主机 ---- */
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
        .irq_done(irq_done)
    );

    axi_slave_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 15), .AR_LAT(12), .B_LAT(2), .MAXO(4)) u_mem (
        .clk(clk), .rst_n(rst_n),
        .s_araddr(m_araddr), .s_arlen(m_arlen), .s_arsize(m_arsize), .s_arburst(m_arburst),
        .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata), .s_rresp(), .s_rlast(m_rlast), .s_rvalid(m_rvalid), .s_rready(m_rready),
        .s_awaddr(m_awaddr), .s_awlen(m_awlen), .s_awsize(m_awsize), .s_awburst(m_awburst),
        .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata), .s_wstrb(m_wstrb), .s_wlast(m_wlast), .s_wvalid(m_wvalid), .s_wready(m_wready),
        .s_bvalid(m_bvalid), .s_bresp(), .s_bready(m_bready)
    );

    always #5 clk = ~clk;

    /* ================= 地址布局 ================= */
    localparam SRC_BASE = 32'h0000_1000;   // 源（stride 64B / 16B 各用一块）
    localparam SS       = 32'd64;
    localparam FB_BASE  = 32'h0000_4000;   // 目标 FB：stride 128B（64 像素）
    localparam DS       = 32'd128;
    localparam FB_BYTES = 32'h4000;        // 0x4000..0x7FFF 全部纳入逐像素比对
    localparam UB_BASE  = 32'h0000_2000;   // 退化横条专用区（stride 512B）
    localparam SENT     = 16'hDEAD;

    /* ================= 影子镜像 ================= */
    reg [15:0] sh [0:16383];               // sh[a>>1]，覆盖 0x0000..0x7FFE

    integer errors = 0;
    integer i, j, n, k, bad;
    reg [31:0] rv;

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

    task fill_shadow;
        input [31:0] a0; input integer bytes; input [15:0] v;
        begin
            for (k = 0; k < bytes; k = k + 2) poke16(a0 + k, v);
        end
    endtask

    /* ================= AXI-Lite ================= */
    task axi_write;
        input [11:0] addr; input [31:0] data;
        begin
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb  = 4'hF; wvalid = 1'b1;
            while (!(bvalid && bready)) @(posedge clk);
            #1;
            awvalid = 1'b0; wvalid = 1'b0;
        end
    endtask

    task axi_read;
        input [11:0] addr; output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            #1;
            arvalid = 1'b0;
        end
    endtask

    task eng_init;
        begin
            axi_write(12'h00, 32'h4);          // SOFT_RST
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);   // 清 IRQ
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);          // GO
        end
    endtask

    task push_words;
        input [31:0] w0, w1, w2, w3, w4, w5, w6, w7;
        begin
            axi_write(12'h08, w0);
            axi_write(12'h08, w1);
            axi_write(12'h08, w2);
            axi_write(12'h08, w3);
            axi_write(12'h08, w4);
            axi_write(12'h08, w5);
            axi_write(12'h08, w6);
            axi_write(12'h08, w7);
        end
    endtask

    task wait_done;
        input [255:0] name;
        begin : wd
            for (n = 0; n < 200000; n = n + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) disable wd;
                if (rv & 32'h4) begin
                    $display("FAIL: %0s engine ERR", name);
                    errors = errors + 1;
                    disable wd;
                end
            end
            $display("FAIL: %0s wait DONE timeout", name);
            errors = errors + 1;
        end
    endtask

    /* ================= 逐像素比对（任意区间） ================= */
    task verify_region;
        input [31:0] a0; input integer bytes; input [255:0] name;
        begin
            bad = 0;
            for (k = 0; k < bytes; k = k + 2) begin
                if ({u_mem.mem[a0+k+1], u_mem.mem[a0+k]} !== sh[(a0+k) >> 1]) begin
                    bad = bad + 1;
                    if (bad <= 8)
                        $display("      MISMATCH x=%0d y=%0d got=%h exp=%h",
                                 ((k % DS) / 2), (k / DS),
                                 {u_mem.mem[a0+k+1], u_mem.mem[a0+k]}, sh[(a0+k) >> 1]);
                end
            end
            check(name, bad == 0);
            if (bad != 0) $display("      mis=%0d", bad);
        end
    endtask

    task verify_all;
        input [255:0] name;
        begin verify_region(FB_BASE, FB_BYTES, name); end
    endtask

    /* ================= 影子侧的"期望行为" ================= */
    task exp_fill;
        input [31:0] x0, y0, W, H; input [15:0] color;
        integer xx, yy;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1)
                    sh[(FB_BASE + (y0 + yy) * DS + (x0 + xx) * 2) >> 1] = color;
        end
    endtask

    task exp_copy;
        input [31:0] sa, sstr; input [31:0] x0, y0, W, H;
        integer xx, yy;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1)
                    sh[(FB_BASE + (y0 + yy) * DS + (x0 + xx) * 2) >> 1] =
                        sh[(sa + yy * sstr + xx * 2) >> 1];
        end
    endtask

    task exp_key;
        input [31:0] sa, sstr; input [31:0] x0, y0, W, H; input [15:0] key;
        reg [15:0] sv;
        integer xx, yy;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1) begin
                    sv = sh[(sa + yy * sstr + xx * 2) >> 1];
                    if (sv !== key)
                        sh[(FB_BASE + (y0 + yy) * DS + (x0 + xx) * 2) >> 1] = sv;
                end
        end
    endtask

    task gen_src;
        input [31:0] sa, sstr; input integer W, H; input [31:0] seed;
        integer xx, yy;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1)
                    poke16(sa + yy * sstr + xx * 2, seed[15:0] + yy * 32 + xx);
        end
    endtask

    /* =====================================================================
     * 用例
     * =================================================================== */
    initial begin
        #20 rst_n = 1'b1;
        #40;

        fill_shadow(FB_BASE, FB_BYTES, SENT);      // 目标 FB 全铺哨兵
        fill_shadow(UB_BASE, 32'h400, SENT);       // 退化横条区
        eng_init();

        /* ---------------- U1 FILL 32x16 @x=3 (lane 3) ---------------- */
        $display("--- U1 FILL 32x16 @x=3 byte6 lane3 ---");
        push_words(32'd1, 0, FB_BASE + 2*DS + 3*2, 0, DS, {16'd16, 16'd32}, 32'hFF, 16'hF800);
        wait_done("U1");
        exp_fill(3, 2, 32, 16, 16'hF800);
        verify_all("U1 FILL 32x16 @x=3 (lane 3)");

        /* ---------------- U2 FILL 32x8 @x=7 (lane 7) ---------------- */
        $display("--- U2 FILL 32x8 @x=7 byte14 lane7 ---");
        push_words(32'd1, 0, FB_BASE + 20*DS + 7*2, 0, DS, {16'd8, 16'd32}, 32'hFF, 16'h07E0);
        wait_done("U2");
        exp_fill(7, 20, 32, 8, 16'h07E0);
        verify_all("U2 FILL 32x8 @x=7 (lane 7)");

        /* ---------------- U3 FILL 32x8 @x=5 (lane 5) ---------------- */
        $display("--- U3 FILL 32x8 @x=5 byte10 lane5 ---");
        push_words(32'd1, 0, FB_BASE + 30*DS + 5*2, 0, DS, {16'd8, 16'd32}, 32'hFF, 16'h001F);
        wait_done("U3");
        exp_fill(5, 30, 32, 8, 16'h001F);
        verify_all("U3 FILL 32x8 @x=5 (lane 5)");

        /* ---------------- U4 FILL 1x64 @x=4 (lane 4, 竖条) ---------------- */
        $display("--- U4 FILL 1x64 @x=4 byte8 lane4 (degenerate column) ---");
        push_words(32'd1, 0, FB_BASE + 40*DS + 4*2, 0, DS, {16'd64, 16'd1}, 32'hFF, 16'hF81F);
        wait_done("U4");
        exp_fill(4, 40, 1, 64, 16'hF81F);
        verify_all("U4 FILL 1x64 @x=4 lane4 (column)");

        /* ---------------- U5 FILL 200x1 @x=2 (lane 2, 横条跨 16 拍突发) -------- */
        $display("--- U5 FILL 200x1 @x=2 byte4 lane2 (degenerate row) ---");
        push_words(32'd1, 0, UB_BASE + 2*2, 0, 32'd512, {16'd1, 16'd200}, 32'hFF, 16'hFFE0);
        wait_done("U5");
        for (i = 0; i < 200; i = i + 1)
            sh[(UB_BASE + (2 + i)*2) >> 1] = 16'hFFE0;
        verify_region(UB_BASE, 32'h400, "U5 FILL 200x1 @x=2 lane2 (row)");

        /* ---------------- U6 KEY 16x8 @x=7 (lane 7, 首词单 lane) -------------- */
        $display("--- U6 KEY 16x8 @x=7 byte14 lane7 ---");
        gen_src(SRC_BASE + 32'h600, 32'd32, 16, 8, 32'h5000);
        for (j = 0; j < 8; j = j + 1)
            for (i = 0; i < 16; i = i + 1)
                if (i % 2 == 0) poke16(SRC_BASE + 32'h600 + j*32 + i*2, 16'h07E0);
        push_words(32'd3, SRC_BASE + 32'h600, FB_BASE + 110*DS + 7*2, 32'd32, DS,
                   {16'd8, 16'd16}, 32'hFF, 16'h07E0);
        wait_done("U6");
        exp_key(SRC_BASE + 32'h600, 32'd32, 7, 110, 16, 8, 16'h07E0);
        verify_all("U6 KEY 16x8 @x=7 lane7 (1-lane)");

        /* ---------------- U7 KEY 16x8 @x=0：首词整词全键色 ---------------- */
        $display("--- U7 KEY 16x8 @x=0 first-word all key ---");
        gen_src(SRC_BASE + 32'h800, 32'd32, 16, 8, 32'h6000);
        for (j = 0; j < 8; j = j + 1)
            for (i = 0; i < 8; i = i + 1)
                poke16(SRC_BASE + 32'h800 + j*32 + i*2, 16'h07E0);
        push_words(32'd3, SRC_BASE + 32'h800, FB_BASE + 118*DS, 32'd32, DS,
                   {16'd8, 16'd16}, 32'hFF, 16'h07E0);
        wait_done("U7");
        exp_key(SRC_BASE + 32'h800, 32'd32, 0, 118, 16, 8, 16'h07E0);
        verify_all("U7 KEY 16x8 @x=0 all-key word");

        /* ---------------- U8 COPY 20x8 src x=3 -> dst x=13 ---------------- */
        $display("--- U8 COPY 20x8 src@x=3 dst@x=13 byte26 lane5 ---");
        gen_src(SRC_BASE, SS, 20, 8, 32'h3000);
        push_words(32'd0, SRC_BASE + 6, FB_BASE + 100*DS + 13*2, SS, DS,
                   {16'd8, 16'd20}, 32'hFF, 16'd0);
        wait_done("U8");
        exp_copy(SRC_BASE + 6, SS, 13, 100, 20, 8);
        verify_all("U8 COPY 20x8 src x3 -> dst x13");

        /* ---------------- U9 COPY 13x9 src x=7 -> dst x=11 (W%8!=0) -------- */
        $display("--- U9 COPY 13x9 src@x=7 dst@x=11 W=13 ---");
        gen_src(SRC_BASE + 32'h100, SS, 20, 9, 32'h2000);
        push_words(32'd0, SRC_BASE + 32'h100 + 14, FB_BASE + 88*DS + 11*2, SS, DS,
                   {16'd9, 16'd13}, 32'hFF, 16'd0);
        wait_done("U9");
        exp_copy(SRC_BASE + 32'h100 + 14, SS, 11, 88, 13, 9);
        verify_all("U9 COPY 13x9 unaligned W%8!=0");

        /* ---------------- U10 FILL 1x1 @x=7 / @x=31 ---------------- */
        $display("--- U10 FILL 1x1 @x=7, @x=31 ---");
        push_words(32'd1, 0, FB_BASE + 60*DS + 7*2, 0, DS, {16'd1, 16'd1}, 32'hFF, 16'h1234);
        wait_done("U10a");
        exp_fill(7, 60, 1, 1, 16'h1234);
        push_words(32'd1, 0, FB_BASE + 61*DS + 31*2, 0, DS, {16'd1, 16'd1}, 32'hFF, 16'h5678);
        wait_done("U10b");
        exp_fill(31, 61, 1, 1, 16'h5678);
        verify_all("U10 FILL 1x1 pixel (lane 7)");

        /* ---------------- U11 COPY 8x1 对齐 / 8x1 非对齐 ---------------- */
        $display("--- U11 COPY 8x1 aligned / unaligned ---");
        gen_src(SRC_BASE + 32'h200, 32'd16, 16, 2, 32'h7000);
        push_words(32'd0, SRC_BASE + 32'h200, FB_BASE + 70*DS, 32'd16, DS,
                   {16'd1, 16'd8}, 32'hFF, 16'd0);
        wait_done("U11a");
        exp_copy(SRC_BASE + 32'h200, 32'd16, 0, 70, 8, 1);
        push_words(32'd0, SRC_BASE + 32'h200 + 10, FB_BASE + 71*DS + 3*2, 32'd16, DS,
                   {16'd1, 16'd8}, 32'hFF, 16'd0);
        wait_done("U11b");
        exp_copy(SRC_BASE + 32'h200 + 10, 32'd16, 3, 71, 8, 1);
        verify_all("U11 COPY 8x1 aligned/unaligned");

        /* ---------------- U12 KEY 32x4 @x=5 (lane 5) ---------------- */
        $display("--- U12 KEY 32x4 @x=5 lane5 ---");
        gen_src(SRC_BASE + 32'h300, 32'd64, 32, 4, 32'h1000);
        for (j = 0; j < 4; j = j + 1)
            for (i = 0; i < 32; i = i + 1)
                if ((i % 4) == 0) poke16(SRC_BASE + 32'h300 + j*64 + i*2, 16'h0F0F);
        push_words(32'd3, SRC_BASE + 32'h300, FB_BASE + 80*DS + 5*2, 32'd64, DS,
                   {16'd4, 16'd32}, 32'hFF, 16'h0F0F);
        wait_done("U12");
        exp_key(SRC_BASE + 32'h300, 32'd64, 5, 80, 32, 4, 16'h0F0F);
        verify_all("U12 KEY 32x4 @x=5 (lane 5)");

        if (errors == 0) $display("========== tb_blt_unalign ALL PASS ==========");
        else             $display("========== tb_blt_unalign FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #30_000_000;
        $display("!!!!!!!! tb_blt_unalign WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
