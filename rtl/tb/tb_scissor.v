/* =========================================================================
 * tb_scissor.v — ★S5（v3.2）scissor / 裁剪矩形 专项
 * -------------------------------------------------------------------------
 * 覆盖四条承诺：
 *   ① **关闭即逐位兼容**：CLIP_CTRL.bit0=0（复位默认）时，FILL/COPY/KEY/ALPHA
 *      的整幅结果与"没有这个功能"逐像素相同；
 *   ② **命中判据是半开区间**：x0 ≤ x < x1、y0 ≤ y < y1（含左含上、不含右不含下），
 *      单列/单行/退化空矩形都要逐像素验证；
 *   ③ **矩形外一个字节都不动**：整行在外、整列在外、整个矩形在外、非对齐目的地址
 *      （dst lane 3/7）四种情形都要"影子镜像逐像素相等"（比对范围覆盖整幅 FB）；
 *   ④ **命令起始锁存**：命令跑到一半再改 scissor 寄存器，本命令必须仍按旧值画完
 *      （下一命令才用新值）—— 这是"寄存器随时可写但绝不撕裂一条命令"的证据。
 *   另测：整行在外时**真的省拍**（读 PERF 0x1C 对比"有裁剪/无裁剪"的周期数）。
 *
 * 语义（见 rtl/功能清单.md §28）：clip 坐标是**本条命令目的矩形的局部坐标** ——
 *   原点 = 该命令第 0 行 dst_base 的第一个像素；x 向右、y 向下，单位 = 像素。
 *   当整幅 FB 就是目的矩形（dst=FB_BASE、stride=FB_STRIDE）时即"屏幕坐标"。
 *
 * A/B 逃生门：`-DSCISSOR_OFF` ⇒ 引擎恒不启用裁剪 ⇒ 同一份 TB 的期望值换成
 *   "完全不裁剪"那一支，必须同样 ALL PASS。
 *
 * 编译（仓库根）：
 *   iverilog -g2001 -s tb_scissor -o sim_tb_scissor.vvp \
 *     rtl/sync_fifo.v rtl/cmd_fifo.v rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v \
 *     rtl/axi_rd_master.v rtl/axi_wr_master.v rtl/stream_reader.v rtl/pixel_path.v \
 *     rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/clr_engine.v \
 *     rtl/dl_fetch.v rtl/blt_top.v rtl/tb/axi_slave_mem.v rtl/tb/tb_scissor.v
 * ========================================================================= */
`timescale 1ns/1ps
module tb_scissor;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

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
        .irq_done(irq_done),
        .scan_underrun(16'd0), .scan_abort(16'd0),
        .fb_cur_sel(2'd0), .fb_frame_cnt(16'd0), .frame_pulse(1'b0),
        .lut_bank_act(1'b0)
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

    localparam SRC_BASE = 32'h0000_1000;
    localparam SS       = 32'd64;
    localparam FB_BASE  = 32'h0000_4000;
    localparam DS       = 32'd128;
    localparam FB_BYTES = 32'h2000;
    localparam SENT     = 16'hDEAD;

    reg [15:0] sh [0:16383];
    integer errors = 0;
    integer i, j, n, k, bad;
    reg [31:0] rv, cyc_a, cyc_b;

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
        begin for (k = 0; k < bytes; k = k + 2) poke16(a0 + k, v); end
    endtask

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
            axi_write(12'h00, 32'h4);
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);          // GO
        end
    endtask

    task push_words;
        input [31:0] w0, w1, w2, w3, w4, w5, w6, w7;
        begin
            axi_write(12'h08, w0); axi_write(12'h08, w1);
            axi_write(12'h08, w2); axi_write(12'h08, w3);
            axi_write(12'h08, w4); axi_write(12'h08, w5);
            axi_write(12'h08, w6); axi_write(12'h08, w7);
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

    /* scissor 寄存器（0x90/0x94/0x98/0x9C/0xA0） */
    task set_clip;
        input [15:0] x0, x1, y0, y1;
        input        en;
        begin
            axi_write(12'h90, {16'd0, x0});
            axi_write(12'h94, {16'd0, x1});
            axi_write(12'h98, {16'd0, y0});
            axi_write(12'h9C, {16'd0, y1});
            axi_write(12'hA0, {31'd0, en});
        end
    endtask

    /* 回读校验（0x90~0xA0 都是可读的普通寄存器；顺带证明"旧寄存器地址没被挪动"） */
    task chk_clip_rb;
        input [15:0] x0, x1, y0, y1;
        input        en;
        reg   [31:0] r1, r2, r3, r4, r5;
        begin
            axi_read(12'h90, r1); axi_read(12'h94, r2);
            axi_read(12'h98, r3); axi_read(12'h9C, r4);
            axi_read(12'hA0, r5);
            check("S0 scissor 寄存器回读一致",
                  (r1[15:0] === x0) && (r2[15:0] === x1) && (r3[15:0] === y0) &&
                  (r4[15:0] === y1) && (r5[0] === en));
        end
    endtask

    task verify_region;
        input [31:0] a0; input integer bytes; input [255:0] name;
        begin
            bad = 0;
            for (k = 0; k < bytes; k = k + 2) begin
                if ({u_mem.mem[a0+k+1], u_mem.mem[a0+k]} !== sh[(a0+k) >> 1]) begin
                    bad = bad + 1;
                    if (bad <= 6)
                        $display("      MISMATCH x=%0d y=%0d got=%h exp=%h",
                                 ((k % DS) / 2), (k / DS),
                                 {u_mem.mem[a0+k+1], u_mem.mem[a0+k]}, sh[(a0+k) >> 1]);
                end
            end
            check(name, bad == 0);
        end
    endtask

    /* =====================================================================
     * 参考模型：只在"命令矩形 ∩ scissor 矩形"内写
     * =================================================================== */
    function [7:0] e5; input [4:0] v; begin e5 = {v, v[4:2]}; end endfunction
    function [7:0] e6; input [5:0] v; begin e6 = {v, v[5:4]}; end endfunction

    /* op: 0=COPY 1=FILL 2=ALPHA 3=KEY；bx/by = 目的矩形在命令局部坐标下的起点
     * （本 TB 里恒为 0，即 dst_base 就是矩形原点） */
    task model_region;
        input [1:0]  o;
        input [31:0] sa, sst, da, dstn;
        input integer W, H;
        input [15:0] col, ky;
        input [7:0]  cal;
        input [15:0] cx0, cx1, cy0, cy1;
        input        cen;
`ifdef SCISSOR_OFF
        integer dummy;                     // A/B：逃生门 ⇒ 模型也不裁剪
`endif
        integer xx, yy;
        reg [15:0] sp, dp, nv;
        reg        wr;
        reg [15:0] mr, mg, mb;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1) begin
                    sp = sh[(sa + yy*sst  + xx*2) >> 1];
                    dp = sh[(da + yy*dstn + xx*2) >> 1];
                    wr = 1'b1;
`ifdef SCISSOR_OFF
                    dummy = 0;
`else
                    if (cen && !((xx >= cx0) && (xx < cx1) && (yy >= cy0) && (yy < cy1)))
                        wr = 1'b0;
`endif
                    case (o)
                        2'd0: nv = sp;
                        2'd1: nv = col;
                        2'd2: begin
                            mr = e5(sp[15:11]) * {8'd0, cal} + e5(dp[15:11]) * (16'h00FF - {8'd0, cal}) + 16'd127;
                            mg = e6(sp[10:5])  * {8'd0, cal} + e6(dp[10:5])  * (16'h00FF - {8'd0, cal}) + 16'd127;
                            mb = e5(sp[4:0])   * {8'd0, cal} + e5(dp[4:0])   * (16'h00FF - {8'd0, cal}) + 16'd127;
                            nv = {mr[15:11], mg[15:10], mb[15:11]};
                        end
                        default: begin nv = sp; wr = wr && (sp !== ky); end
                    endcase
                    if (wr) sh[(da + yy*dstn + xx*2) >> 1] = nv;
                end
        end
    endtask

    task gen_src;
        input [31:0] sa, sstr;
        input integer W, H, pat;
        input [15:0] seed;
        integer xx, yy;
        reg [15:0] v;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1) begin
                    case (pat)
                        0: v = seed + yy*32 + xx;
                        1: v = ((xx % 4) == 0) ? 16'h7BEF : ((xx % 4) == 1) ? 16'hF800 :
                               ((xx % 4) == 2) ? 16'h07E0 : 16'h001F;
                        2: v = 16'h1234;                    // 全键色
                        default: v = seed;
                    endcase
                    poke16(sa + yy*sstr + xx*2, v);
                end
        end
    endtask

    /* 一条用例：下发命令 → 等完成 → 模型更新影子 → 整幅比对 */
    task clip_case;
        input [255:0] name;
        input [1:0]  o;
        input [31:0] sa, sst, da, dstn;
        input [15:0] W, H, col, ky;
        input [7:0]  cal;
        input [15:0] cx0, cx1, cy0, cy1;
        input        cen;
        begin
            set_clip(cx0, cx1, cy0, cy1, cen);
            push_words({29'd0, o}, sa, da, sst, dstn, {H, W}, {24'd0, cal},
                       {16'd0, (o == 2'd3) ? ky : col});
            wait_done(name);
            model_region(o, sa, sst, da, dstn, W, H, col, ky, cal, cx0, cx1, cy0, cy1, cen);
            verify_region(FB_BASE, FB_BYTES, name);
        end
    endtask

    /* =====================================================================
     * 用例
     * =================================================================== */
    initial begin
        #20 rst_n = 1'b1;
        #40;

        fill_shadow(FB_BASE, FB_BYTES, SENT);
        fill_shadow(SRC_BASE, 32'h1000, SENT);
        eng_init();
        set_clip(0, 0, 0, 0, 1'b0);        // 复位后必须"不裁剪"
        chk_clip_rb(0, 0, 0, 0, 1'b0);     // 回读校验（0x90~0xA0）

        /* ---------------------------------------------------------------
         * S1 关闭（默认）：四种算子逐位等于"没有 scissor"
         * ------------------------------------------------------------- */
        $display("--- S1 scissor 关闭 = 逐位兼容 ---");
        gen_src(SRC_BASE, SS, 32, 8, 1, 16'h3000);
        clip_case("S1a FILL 关闭 32x8", 2'd1, 0, 0, FB_BASE + 2*DS, DS,
                  32, 8, 16'hF81F, 0, 8'hFF, 3, 17, 1, 6, 1'b0);
        clip_case("S1b COPY 关闭 32x8", 2'd0, SRC_BASE, SS, FB_BASE + 12*DS, DS,
                  32, 8, 0, 0, 8'hFF, 3, 17, 1, 6, 1'b0);
        clip_case("S1c KEY  关闭 32x8", 2'd3, SRC_BASE, SS, FB_BASE + 22*DS, DS,
                  32, 8, 0, 16'h7BEF, 8'hFF, 3, 17, 1, 6, 1'b0);
        clip_case("S1d ALPHA 关闭 32x8 α=128", 2'd2, SRC_BASE, SS, FB_BASE + 32*DS, DS,
                  32, 8, 0, 0, 8'd128, 3, 17, 1, 6, 1'b0);

        /* ---------------------------------------------------------------
         * S2 启用：矩形内部 —— 只有 [x0,x1)×[y0,y1) 被写
         * ------------------------------------------------------------- */
        $display("--- S2 scissor 启用：内部矩形 ---");
        clip_case("S2a FILL 32x8 clip[4,20)x[2,6)", 2'd1, 0, 0, FB_BASE + 42*DS, DS,
                  32, 8, 16'h07E0, 0, 8'hFF, 4, 20, 2, 6, 1'b1);
        clip_case("S2b COPY 32x8 clip[4,20)x[2,6)", 2'd0, SRC_BASE, SS, FB_BASE + 52*DS, DS,
                  32, 8, 0, 0, 8'hFF, 4, 20, 2, 6, 1'b1);
        clip_case("S2c KEY 32x8 clip[4,20)x[2,6)", 2'd3, SRC_BASE, SS, FB_BASE + 62*DS, DS,
                  32, 8, 0, 16'h7BEF, 8'hFF, 4, 20, 2, 6, 1'b1);

        /* ---------------------------------------------------------------
         * S3 半开区间边界：单列 / 单行 / x1=x0 / y1=y0 / 越界（比命令还大）
         * ------------------------------------------------------------- */
        $display("--- S3 边界（半开区间） ---");
        clip_case("S3a 单列 clip[5,6)x[0,8)", 2'd1, 0, 0, FB_BASE + 2*DS, DS,
                  32, 8, 16'hF800, 0, 8'hFF, 5, 6, 0, 8, 1'b1);
        clip_case("S3b 单行 clip[0,32)x[3,4)", 2'd1, 0, 0, FB_BASE + 12*DS, DS,
                  32, 8, 16'h001F, 0, 8'hFF, 0, 32, 3, 4, 1'b1);
        clip_case("S3c 空(x1=x0) 不写", 2'd1, 0, 0, FB_BASE + 22*DS, DS,
                  32, 8, 16'hFFFF, 0, 8'hFF, 7, 7, 0, 8, 1'b1);
        clip_case("S3d 空(y1=y0) 不写", 2'd1, 0, 0, FB_BASE + 32*DS, DS,
                  32, 8, 16'hFFFF, 0, 8'hFF, 0, 32, 5, 5, 1'b1);
        clip_case("S3e 越界矩形（比命令大）", 2'd1, 0, 0, FB_BASE + 42*DS, DS,
                  32, 8, 16'h1234, 0, 8'hFF, 0, 100, 0, 100, 1'b1);
        clip_case("S3f x0 越界(>W) 不写", 2'd1, 0, 0, FB_BASE + 52*DS, DS,
                  32, 8, 16'hFFFF, 0, 8'hFF, 40, 50, 0, 8, 1'b1);

        /* ---------------------------------------------------------------
         * S4 整行在外（y 方向裁剪）+ 整列在外
         * ------------------------------------------------------------- */
        $display("--- S4 整行/整列在外 ---");
        clip_case("S4a 只留中间 2 行 clip[0,32)x[3,5)", 2'd1, 0, 0, FB_BASE + 2*DS, DS,
                  32, 8, 16'hF81F, 0, 8'hFF, 0, 32, 3, 5, 1'b1);
        clip_case("S4b 只留中间 2 列 clip[10,12)x[0,8)", 2'd1, 0, 0, FB_BASE + 12*DS, DS,
                  32, 8, 16'h07FF, 0, 8'hFF, 10, 12, 0, 8, 1'b1);
        clip_case("S4c 整条命令在外 clip[100,110)x[0,8)", 2'd1, 0, 0, FB_BASE + 22*DS, DS,
                  32, 8, 16'hFFFF, 0, 8'hFF, 100, 110, 0, 8, 1'b1);
        clip_case("S4d y 全在外 clip[0,32)x[20,30)", 2'd0, SRC_BASE, SS, FB_BASE + 32*DS, DS,
                  32, 8, 0, 0, 8'hFF, 0, 32, 20, 30, 1'b1);

        /* ---------------------------------------------------------------
         * S5 非对齐目的地址（lane 3 / lane 7）+ scissor
         * ------------------------------------------------------------- */
        $display("--- S5 非对齐 dst + scissor ---");
        clip_case("S5a dst x=3 lane3 clip[2,20)x[1,5)", 2'd1, 0, 0, FB_BASE + 2*DS + 3*2, DS,
                  32, 8, 16'hF81F, 0, 8'hFF, 2, 20, 1, 5, 1'b1);
        clip_case("S5b dst x=7 lane7 clip[1,16)x[0,8)", 2'd0, SRC_BASE, SS, FB_BASE + 12*DS + 7*2, DS,
                  32, 8, 0, 0, 8'hFF, 1, 16, 0, 8, 1'b1);
        clip_case("S5c dst x=5 lane5 clip[3,9)x[2,7)", 2'd3, SRC_BASE, SS, FB_BASE + 22*DS + 5*2, DS,
                  32, 8, 0, 16'h7BEF, 8'hFF, 3, 9, 2, 7, 1'b1);

        /* ---------------------------------------------------------------
         * S6 命令起始锁存：命令跑到一半改 scissor 寄存器，本命令仍按旧值
         * ------------------------------------------------------------- */
        $display("--- S6 命令起始锁存（中途改寄存器不撕裂本命令） ---");
        set_clip(0, 64, 0, 32, 1'b1);                   // 旧值：整块都画
        push_words(32'd1, 32'd0, FB_BASE + 2*DS, 32'd0, DS, {16'd32, 16'd64},
                   32'd0, 16'hF81F);                    // 64x32 FILL（约 1200 拍）
        /* 先等引擎真的进了 BUSY（= 8 个字已弹完、ST_DEC 已过），再等 60 拍，
         * 然后才改 scissor 寄存器 —— 这样"改寄存器"必然落在本命令执行中间。 */
        for (n = 0; n < 2000; n = n + 1) begin
            axi_read(12'h04, rv);
            if (rv & 32'h1) n = 3000;
        end
        repeat (60) @(posedge clk);
        axi_write(12'h90, 32'd10);                      // 中途改成 [10,12)x[0,1)
        axi_write(12'h94, 32'd12);
        axi_write(12'h98, 32'd0);
        axi_write(12'h9C, 32'd1);
        wait_done("S6");
        model_region(2'd1, 0, 0, FB_BASE + 2*DS, DS, 64, 32, 16'hF81F, 0, 8'hFF,
                     0, 64, 0, 32, 1'b1);                // 期望：整块（旧值）
        verify_region(FB_BASE, FB_BYTES, "S6 中途改 scissor 不影响本命令");

        /* ---------------------------------------------------------------
         * S7 省拍：整行在外时周期数应显著低于不裁剪（读 PERF 0x1C）
         * ------------------------------------------------------------- */
        $display("--- S7 整行跳过是否真的省拍（PERF 0x1C） ---");
        set_clip(0, 0, 0, 0, 1'b0);
        push_words(32'd1, 32'd0, FB_BASE + 2*DS, 32'd0, DS, {16'd32, 16'd64}, 32'd0, 16'h1234);
        wait_done("S7a");
        axi_read(12'h1C, cyc_a);
        model_region(2'd1, 0, 0, FB_BASE + 2*DS, DS, 64, 32, 16'h1234, 0, 8'hFF,
                     0, 64, 0, 32, 1'b0);               // 无裁剪：整块都写
        set_clip(0, 64, 0, 4, 1'b1);                     // 只留前 4 行
        push_words(32'd1, 32'd0, FB_BASE + 2*DS, 32'd0, DS, {16'd32, 16'd64}, 32'd0, 16'h1234);
        wait_done("S7b");
        axi_read(12'h1C, cyc_b);
        $display("      PERF 无裁剪=%0d 有裁剪(4/32 行)=%0d", cyc_a, cyc_b);
`ifdef SCISSOR_OFF
        /* A/B 逃生门：裁剪整体不生效 ⇒ 两次必须逐拍相同（这就是"关掉即回到今天"的证据） */
        check("S7 逃生门(-DSCISSOR_OFF)：不裁剪 ⇒ 两次周期数相同", cyc_b == cyc_a);
`else
        check("S7 裁剪 4/32 行后周期数明显下降", cyc_b < cyc_a - (cyc_a / 4));
`endif
        /* 模型：只有前 4 行被写（其余行保持哨兵/上一轮值） */
        model_region(2'd1, 0, 0, FB_BASE + 2*DS, DS, 64, 32, 16'h1234, 0, 8'hFF,
                     0, 64, 0, 4, 1'b1);
        verify_region(FB_BASE, FB_BYTES, "S7 裁剪后像素与模型一致");

        if (errors == 0) $display("========== tb_scissor ALL PASS ==========");
        else             $display("========== tb_scissor FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("!!!!!!!! tb_scissor WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
