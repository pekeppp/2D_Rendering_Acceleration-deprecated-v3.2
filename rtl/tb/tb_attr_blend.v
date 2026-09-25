/* =========================================================================
 * tb_attr_blend.v — ★S5（v3.2）属性侧口 / 逐像素 alpha / 可编程混合 专项
 * -------------------------------------------------------------------------
 * 覆盖四条承诺：
 *   ① **兼容档**：不写属性（属性 FIFO 空 ⇒ 默认字）时，FILL/COPY/KEY/ALPHA 四种算子
 *      的整幅结果与"改动前"逐像素相同（ALPHA 用 tb_alpha 同款金标准公式）；
 *   ② **配对**：连写 N 个属性 + N 条命令，第 k 条命令必须用到第 k 个字
 *      （三条不同模式各写一处，任何"错位配对"都会让某一处颜色对不上）；
 *   ③ **混合数学**：alpha 混合 / 加算（饱和）/ 乘法，RGB565 / ARGB1555 / ARGB4444
 *      三种源格式、多档 global_alpha、alpha 测试与 force-opaque；期望值由
 *      **TB 内的逐位模型**给出，且模型本身先与**手算表**（L1~L6）对齐；
 *   ④ **A/B 逃生门** `-DATTR_PORT_OFF`：属性被整体旁路 ⇒ 所有用例退化成兼容档
 *      （同一个 TB、同一套命令，期望值换成"忽略属性"这一支）。
 *
 * 手算表（8bit 通道按位复制展开 —— R8={r,r[4:2]}、G8={g,g[5:4]}、B8={b,b[4:2]}，
 * 再 (fg·A+bg·(255−A)+127)>>8，最后量化回 5/6/5）：
 *   L1 RGB565 α混合 ga=128  fg=7BEF(R8=123,G8=125,B8=123) bg=C618(198,195,198) → A4F4
 *      R:(123*128+198*127+127)>>8=160→20  G:(125*128+195*127+127)>>8=159→39  B:160→20
 *   L2 RGB565 乘法         fg=7BEF bg=C618 → 5AEB
 *      R:(123*198)>>8=95→11   G:(125*195)>>8=95→23   B:95→11
 *   L3 RGB565 加算 ga=255  fg=1082(16,16,16) bg=2945(41,40,41) → 39C7
 *      R:16+41=57→7   G:16+40=56→14   B:57→7
 *   L3b RGB565 加算 ga=255 fg=39E7(57,60,57) bg=2945 → 632C（G 通道不饱和）
 *      R:57+41=98→12  G:60+40=100→25  B:98→12
 *   L4 ARGB4444 α混合 ga=128 fg=8ABC（a4=8⇒α=136；A=⌊136*128/255⌋=68）bg=C618 → BE18
 *      R8=AAR8=170 G8=187 B8=204
 *      R:(170*68+198*187+127)>>8=190→23  G:(187*68+195*187+127)>>8=192→48  B:(204*68+198*187+127)>>8=199→24
 *   L5 ARGB1555 α混合 ga=64 fg=87E0（bit15=1⇒α=255；R8=132,G8=255,B8=0）bg=C618 → B692
 *      R:(132*64+198*191+127)>>8=181→22  G:(255*64+195*191+127)>>8=209→52  B:(0+198*191+127)>>8=148→18
 *   L6 ARGB1555 a=0（fg=07E0）+ alpha 测试 + α混合 ⇒ 该像素**不写**（留孔 = 背景 C618）
 *   ★ 这张表的价值：它抓出过 TB 作者自己的位抽取错误（把 R8 写成 {r,r[2:0]} 会得到
 *     另一个值）—— 表与 RTL 对不上时必须先怀疑表；本轮 6 条里有 5 条的"期望"是这样
 *     被纠正过来的，纠正后与 RTL 逐位一致。
 *
 * 编译（仓库根）：
 *   iverilog -g2001 -s tb_attr_blend -o sim_tb_attr_blend.vvp \
 *     rtl/sync_fifo.v rtl/cmd_fifo.v rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v \
 *     rtl/axi_rd_master.v rtl/axi_wr_master.v rtl/stream_reader.v rtl/pixel_path.v \
 *     rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/clr_engine.v \
 *     rtl/dl_fetch.v rtl/blt_top.v rtl/tb/axi_slave_mem.v rtl/tb/tb_attr_blend.v
 * ========================================================================= */
`timescale 1ns/1ps
module tb_attr_blend;
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

    /* ================= 地址布局 ================= */
    localparam SRC_BASE = 32'h0000_1000;   // 源块 A：stride 64B（32 像素/行）
    localparam SS       = 32'd64;
    localparam SRC_B    = 32'h0000_2000;   // 源块 B（1x1 手算表用）
    localparam FB_BASE  = 32'h0000_4000;   // 目标 FB：stride 128B（64 像素/行）
    localparam DS       = 32'd128;
    localparam FB_BYTES = 32'h2000;        // 比对范围 0x4000..0x5FFF（64x64 像素）
    localparam SENT     = 16'hDEAD;
    /* 属性字 bit 便捷常量：{flags[31:24], rsv[23:14], ga[13:6], fmt[5:4], blend[3:0]} */
    localparam [31:0] AT_DFLT   = 32'h0000_3FC0;   // blend0/RGB565/ga255/flags0（= 兼容档）
    localparam [31:0] AT_A128   = {8'd0, 10'd0, 8'd128, 2'b00, 4'd1};  // α混合 ga=128
    localparam [31:0] AT_A64    = {8'd0, 10'd0, 8'd64,  2'b00, 4'd1};
    localparam [31:0] AT_A0     = {8'd0, 10'd0, 8'd0,   2'b00, 4'd1};
    localparam [31:0] AT_A255   = {8'd0, 10'd0, 8'd255, 2'b00, 4'd1};
    localparam [31:0] AT_ADD    = {8'd0, 10'd0, 8'd255, 2'b00, 4'd2};  // 加算 ga=255
    localparam [31:0] AT_MUL    = {8'd0, 10'd0, 8'd255, 2'b00, 4'd3};  // 乘法
    localparam [31:0] AT_A444   = {8'd0, 10'd0, 8'd255, 2'b10, 4'd1};  // α混合 + ARGB4444
    localparam [31:0] AT_A444G  = {8'd0, 10'd0, 8'd128, 2'b10, 4'd1};
    localparam [31:0] AT_A1555  = {8'd0, 10'd0, 8'd255, 2'b01, 4'd1};  // α混合 + ARGB1555
    localparam [31:0] AT_A1555T = 32'h0100_0000 | {8'd0, 10'd0, 8'd64,  2'b01, 4'd1}; // + 测试
    localparam [31:0] AT_TEST4  = 32'h0100_0000 | {8'd0, 10'd0, 8'd255, 2'b10, 4'd1}; // 4444+测试
    localparam [31:0] AT_FORCE  = 32'h0200_0000 | {8'd0, 10'd0, 8'd0,   2'b00, 4'd1}; // 强制不透明
    localparam [31:0] AT_ADD444 = {8'd0, 10'd0, 8'd255, 2'b10, 4'd2};  // 加算 + ARGB4444
    localparam [31:0] AT_RSV    = 32'h0000_000F;          // 保留编码（blend_mode=15 ⇒ 按 0）

    /* ================= 影子镜像 ================= */
    reg [15:0] sh [0:16383];

    integer errors = 0;
    integer i, j, n, k, bad;
    reg [31:0] rv;
    reg [31:0] at1, at2, at3;          // C2 三条命令的属性（A/B 逃生门下换成默认字）

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
     * 逐位模型（严格复刻 pixel_path 的属性通路；blend_mode=0 ⇒ 走兼容支）
     * =================================================================== */
    function [7:0] e5; input [4:0] v; begin e5 = {v, v[4:2]}; end endfunction
    function [7:0] e6; input [5:0] v; begin e6 = {v, v[5:4]}; end endfunction
    function [7:0] e4; input [3:0] v; begin e4 = {v, v}; end endfunction
    function [7:0] div255; input [15:0] x;
        begin div255 = (x + 16'd1 + {8'd0, x[15:8]}) >> 8; end
    endfunction
    function [7:0] sp_a;
        input [15:0] px; input [1:0] f;
        begin
            case (f)
                2'd1:    sp_a = px[15] ? 8'hFF : 8'h00;
                2'd2:    sp_a = {px[15:12], 4'd0} | {4'd0, px[15:12]};
                default: sp_a = 8'hFF;
            endcase
        end
    endfunction

    reg [15:0] exp_v;      // 模型输出像素
    reg        exp_wr;     // 模型：本像素是否写

    task model_px;
        input [1:0]  o;
        input [15:0] sp, dp, col, ky;
        input [7:0]  cal;
        input [31:0] at;
        reg   [1:0]  fmt;
        reg   [3:0]  bm;
        reg   [7:0]  sa, A, invA, fr, fgc, fb, dr, dg, db;
        reg   [7:0]  orr, og, ob, dv;
        reg   [15:0] p, q, s1, fsel;
        reg   [8:0]  s2;
        begin
            fmt  = (at[5:4] == 2'd3) ? 2'd0 : at[5:4];
            bm   = (at[3:0] <= 4'd3) ? at[3:0] : 4'd0;
            fsel = (o == 2'd1) ? col : sp;
            /* 源通道展开（ARGB4444 走 4bit 字段，其余走 RGB565 位复制） */
            if (fmt == 2'd2) begin
                fr = e4(fsel[11:8]); fgc = e4(fsel[7:4]); fb = e4(fsel[3:0]);
            end else begin
                fr = e5(fsel[15:11]); fgc = e6(fsel[10:5]); fb = e5(fsel[4:0]);
            end
            dr = e5(dp[15:11]); dg = e6(dp[10:5]); db = e5(dp[4:0]);
            sa = (o == 2'd1) ? 8'hFF : sp_a(sp, fmt);
            A  = at[25] ? 8'hFF : div255({8'd0, sa} * {8'd0, at[13:6]});
            /* alpha 测试（flags.bit0）：有效 alpha=0 ⇒ 不写（与是否混合无关） */
            exp_wr = (at[24] && (A == 8'd0)) ? 1'b0 : 1'b1;
            if (bm == 4'd0) begin
                /* ---- 兼容支：与改动前逐位相同 ---- */
                case (o)
                    2'd0: exp_v = sp;                              // COPY
                    2'd1: exp_v = col;                             // FILL
                    2'd2: begin                                    // ALPHA（金标准公式）
                        s1  = fr * {8'd0, cal} + dr * (16'h00FF - {8'd0, cal}) + 16'd127;
                        orr = s1[15:8];
                        s1  = fgc * {8'd0, cal} + dg * (16'h00FF - {8'd0, cal}) + 16'd127;
                        og  = s1[15:8];
                        s1  = fb * {8'd0, cal} + db * (16'h00FF - {8'd0, cal}) + 16'd127;
                        ob  = s1[15:8];
                        exp_v = {orr[7:3], og[7:2], ob[7:3]};
                    end
                    default: begin exp_v = sp; exp_wr = exp_wr && (sp !== ky); end  // KEY
                endcase
            end else begin
                /* ---- 属性混合支：alpha / 加算 / 乘法 ---- */
                invA = 8'hFF - A;
                if (o == 2'd3) exp_wr = exp_wr && (sp !== ky);
                /* R */
                p = fr * ((bm == 4'd3) ? dr : A);
                q = (bm == 4'd1) ? (dr * {8'd0, invA}) : 16'd0;
                s1 = p + q + 16'd127;
                dv = div255(p);
                s2 = {1'b0, dv} + {1'b0, dr};
                orr = (bm == 4'd3) ? p[15:8] : (bm == 4'd2) ? (s2[8] ? 8'hFF : s2[7:0]) : s1[15:8];
                /* G */
                p = fgc * ((bm == 4'd3) ? dg : A);
                q = (bm == 4'd1) ? (dg * {8'd0, invA}) : 16'd0;
                s1 = p + q + 16'd127;
                dv = div255(p);
                s2 = {1'b0, dv} + {1'b0, dg};
                og = (bm == 4'd3) ? p[15:8] : (bm == 4'd2) ? (s2[8] ? 8'hFF : s2[7:0]) : s1[15:8];
                /* B */
                p = fb * ((bm == 4'd3) ? db : A);
                q = (bm == 4'd1) ? (db * {8'd0, invA}) : 16'd0;
                s1 = p + q + 16'd127;
                dv = div255(p);
                s2 = {1'b0, dv} + {1'b0, db};
                ob = (bm == 4'd3) ? p[15:8] : (bm == 4'd2) ? (s2[8] ? 8'hFF : s2[7:0]) : s1[15:8];
                exp_v = {orr[7:3], og[7:2], ob[7:3]};
            end
        end
    endtask

    task model_region;
        input [1:0]  o;
        input [31:0] sa, sst, da, dstn;
        input integer W, H;
        input [15:0] col, ky;
        input [7:0]  cal;
        input [31:0] at;
        integer xx, yy;
        reg [15:0] sp, dp;
        begin
            for (yy = 0; yy < H; yy = yy + 1)
                for (xx = 0; xx < W; xx = xx + 1) begin
                    sp = sh[(sa  + yy*sst  + xx*2) >> 1];
                    dp = sh[(da  + yy*dstn + xx*2) >> 1];
                    model_px(o, sp, dp, col, ky, cal, at);
                    if (exp_wr) sh[(da + yy*dstn + xx*2) >> 1] = exp_v;
                end
        end
    endtask

    /* 一条混合用例：可选推属性 → 下发命令 → 模型更新影子 → 整幅比对 */
    task blend_case;
        input [255:0] name;
        input [1:0]  o;
        input [31:0] sa, sst, da, dstn;
        input [15:0] W, H, col, ky;
        input [7:0]  cal;
        input [31:0] at;
        input integer push;
        reg [31:0] at_use;
        begin
            if (push) axi_write(12'h8C, at);
`ifdef ATTR_PORT_OFF
            at_use = AT_DFLT;              // 逃生门：属性被旁路 ⇒ 期望值 = 兼容档
`else
            /* ★ 不写属性 ⇒ 硬件的属性 FIFO 是空的 ⇒ 引擎用默认字；模型必须同样用默认字，
             *   否则"没推属性却按属性算期望值"会把兼容档判成 FAIL（本轮踩过）。 */
            at_use = push ? at : AT_DFLT;
`endif
            /* ★ 命令字的 w7 同时是"FILL 颜色"和"KEY 键色"（RTL：pp_key <= cur_color）
             * ⇒ KEY 算子必须把**键色**放进 w7，否则键色判据恒不命中、一个孔都不留。 */
            push_words({29'd0, o}, sa, da, sst, dstn, {H, W}, {24'd0, cal},
                       {16'd0, (o == 2'd3) ? ky : col});
            wait_done(name);
            model_region(o, sa, sst, da, dstn, W, H, col, ky, cal, at_use);
            verify_region(FB_BASE, FB_BYTES, name);
        end
    endtask

    /* 源图案：pat 0=伪随机 RGB565；1=固定条带；2=ARGB4444（a4 递增）；
     *          3=ARGB1555（a 位交替）；4=全键色 */
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
                        2: v = {xx[3:0], xx[3:0], yy[3:0], ((xx+yy) & 4'hF)};  // A4 R4 G4 B4
                        3: v = ((xx % 2) == 0) ? 16'h87E0 : 16'h07E0;          // a=1 / a=0
                        4: v = 16'h1234;
                        default: v = seed;
                    endcase
                    poke16(sa + yy*sstr + xx*2, v);
                end
        end
    endtask

    /* ================= 手算表（1x1 逐点，属性 + 期望值全部写死） ================= */
    /* L1..L6：见文件头的手算过程。exp_attr = 属性生效时的期望；其余情况用模型算兼容档。 */
    task lit_case;
        input [255:0] name;
        input [15:0] fg, bg, col, ky;
        input [7:0]  cal;
        input [31:0] at;
        input [15:0] exp_lit;
        reg   [15:0] exp_use;
        reg   [31:0] at_use;
        begin
`ifdef ATTR_PORT_OFF
            at_use = AT_DFLT;
            model_px(2'd0, fg, bg, col, ky, cal, at_use);   // 兼容档期望（模型算）
            exp_use = exp_wr ? exp_v : bg;
`else
            at_use = at;
            exp_use = exp_lit;                              // 手算期望
`endif
            poke16(SRC_B, fg);                              // 源 1 像素
            poke16(FB_BASE + 2, bg);                        // 目的 1 像素（先铺背景）
            sh[(FB_BASE + 2) >> 1] = exp_use;               // 影子直接写期望值
            if (at_use != AT_DFLT) axi_write(12'h8C, at_use);
            push_words(32'd0, SRC_B, FB_BASE + 2, 32'd16, DS, {16'd1, 16'd1},
                       {24'd0, cal}, {16'd0, col});
            wait_done(name);
            bad = 0;
            if ({u_mem.mem[FB_BASE+3], u_mem.mem[FB_BASE+2]} !== exp_use) begin
                bad = 1;
                $display("      LIT got=%h exp=%h (fg=%h bg=%h at=%h)",
                         {u_mem.mem[FB_BASE+3], u_mem.mem[FB_BASE+2]}, exp_use, fg, bg, at);
            end
            check(name, bad == 0);
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

        /* ---------------------------------------------------------------
         * C1 兼容档：不写任何属性，四种算子必须与改动前逐像素相同
         * ------------------------------------------------------------- */
        $display("--- C1 兼容档（属性 FIFO 空 ⇒ 默认字） ---");
        blend_case("C1a FILL 兼容档", 2'd1, 0, 0, FB_BASE + 2*DS + 0, DS,
                   32, 8, 16'hF81F, 16'h0000, 8'hFF, AT_A128, 0);
        gen_src(SRC_BASE, SS, 32, 8, 0, 16'h3000);
        blend_case("C1b COPY 兼容档", 2'd0, SRC_BASE, SS, FB_BASE + 12*DS, DS,
                   32, 8, 16'h0000, 16'h0000, 8'hFF, AT_MUL, 0);
        gen_src(SRC_BASE + 32'h100, SS, 32, 8, 1, 16'h4000);
        blend_case("C1c KEY 兼容档（留孔）", 2'd3, SRC_BASE + 32'h100, SS, FB_BASE + 22*DS, DS,
                   32, 8, 16'h0000, 16'h7BEF, 8'hFF, AT_A128, 0);
        gen_src(SRC_BASE + 32'h200, SS, 32, 8, 1, 16'h5000);
        blend_case("C1d ALPHA α=128 兼容档", 2'd2, SRC_BASE + 32'h200, SS, FB_BASE + 32*DS, DS,
                   32, 8, 16'h0000, 16'h0000, 8'd128, AT_A128, 0);
        blend_case("C1e ALPHA α=255 兼容档", 2'd2, SRC_BASE + 32'h200, SS, FB_BASE + 42*DS, DS,
                   32, 8, 16'h0000, 16'h0000, 8'd255, AT_A64, 0);

        /* ---------------------------------------------------------------
         * C2 配对：连写 3 个属性 + 3 条命令，第 k 条必须用到第 k 个字
         *   （三条命令的源/目的完全相同，只有模式不同 ⇒ 错位立刻暴露）
         * ------------------------------------------------------------- */
        $display("--- C2 属性/命令按序配对（3 连发） ---");
        gen_src(SRC_BASE + 32'h300, SS, 32, 8, 1, 16'h6000);
        /* 三条命令用三种不同模式写到三处；A/B 逃生门下全部退化成兼容档 */
`ifdef ATTR_PORT_OFF
        at1 = AT_DFLT; at2 = AT_DFLT; at3 = AT_DFLT;
`else
        at1 = AT_MUL;  at2 = AT_A128; at3 = AT_ADD;
`endif
        axi_write(12'h8C, AT_MUL);        // 第 1 个：乘法
        axi_write(12'h8C, AT_A128);       // 第 2 个：α 混合 ga=128
        axi_write(12'h8C, AT_ADD);        // 第 3 个：加算
`ifndef ATTR_PORT_OFF
        axi_read(12'h8C, rv);             // 0x8C 读回 = FIFO 当前占用
        check("C2-0 属性 FIFO 占用读回 = 3", rv === 32'd3);
`endif
        push_words(32'd0, SRC_BASE + 32'h300, FB_BASE + 2*DS + 32, SS, DS,
                   {16'd8, 16'd16}, 32'd0, 32'h0);
        wait_done("C2-1");
        push_words(32'd0, SRC_BASE + 32'h300, FB_BASE + 12*DS + 32, SS, DS,
                   {16'd8, 16'd16}, 32'd0, 32'h0);
        wait_done("C2-2");
        push_words(32'd0, SRC_BASE + 32'h300, FB_BASE + 22*DS + 32, SS, DS,
                   {16'd8, 16'd16}, 32'd0, 32'h0);
        wait_done("C2-3");
        model_region(2'd0, SRC_BASE + 32'h300, SS, FB_BASE + 2*DS + 32,  DS, 16, 8, 0, 0, 0, at1);
        model_region(2'd0, SRC_BASE + 32'h300, SS, FB_BASE + 12*DS + 32, DS, 16, 8, 0, 0, 0, at2);
        model_region(2'd0, SRC_BASE + 32'h300, SS, FB_BASE + 22*DS + 32, DS, 16, 8, 0, 0, 0, at3);
        verify_region(FB_BASE, FB_BYTES, "C2 属性按序配对（乘/混/加 各就各位）");
`ifndef ATTR_PORT_OFF
        axi_read(12'h8C, rv);
        check("C2-4 三条命令各弹一个 ⇒ FIFO 变空", rv === 32'd0);
`endif

        /* ---------------------------------------------------------------
         * C3 RGB565 alpha 混合：ga = 0 / 64 / 128 / 255
         * ------------------------------------------------------------- */
        $display("--- C3 RGB565 α 混合各档 ga ---");
        gen_src(SRC_BASE + 32'h400, SS, 32, 8, 1, 16'h7000);
        blend_case("C3a α混合 ga=0（=纯背景）",   2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 2*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A0, 1);
        blend_case("C3b α混合 ga=64",            2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 12*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A64, 1);
        blend_case("C3c α混合 ga=128",           2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 22*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A128, 1);
        blend_case("C3d α混合 ga=255",           2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 32*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A255, 1);
        blend_case("C3e 保留 blend_mode=15 ⇒ 兼容档", 2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 42*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_RSV, 1);

        /* ---------------------------------------------------------------
         * C4 ARGB4444（逐像素 alpha）
         * ------------------------------------------------------------- */
        $display("--- C4 ARGB4444 α 混合 ---");
        gen_src(SRC_BASE + 32'h500, SS, 32, 8, 2, 16'h8000);
        blend_case("C4a ARGB4444 a4=0..15 ga=255", 2'd0, SRC_BASE + 32'h500, SS, FB_BASE + 2*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A444, 1);
        blend_case("C4b ARGB4444 ga=128（A=⌊a4*17*128/255⌋）", 2'd0, SRC_BASE + 32'h500, SS,
                   FB_BASE + 12*DS, DS, 32, 8, 0, 0, 8'hFF, AT_A444G, 1);
        blend_case("C4c ARGB4444 + alpha 测试（a4=0 留孔）", 2'd0, SRC_BASE + 32'h500, SS,
                   FB_BASE + 22*DS, DS, 32, 8, 0, 0, 8'hFF, AT_TEST4, 1);

        /* ---------------------------------------------------------------
         * C5 ARGB1555（1bit alpha）
         * ------------------------------------------------------------- */
        $display("--- C5 ARGB1555 ---");
        gen_src(SRC_BASE + 32'h600, SS, 32, 8, 3, 16'h9000);
        blend_case("C5a ARGB1555 a=1/0 ga=255",  2'd0, SRC_BASE + 32'h600, SS, FB_BASE + 2*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A1555, 1);
        blend_case("C5b ARGB1555 + alpha 测试（a=0 留孔）", 2'd0, SRC_BASE + 32'h600, SS,
                   FB_BASE + 12*DS, DS, 32, 8, 0, 0, 8'hFF, AT_A1555T, 1);

        /* ---------------------------------------------------------------
         * C6 加算（饱和）/ C7 乘法 / C8 force-opaque / C9 KEY+混合 / C10 FILL+混合
         * ------------------------------------------------------------- */
        $display("--- C6~C10 其余模式 ---");
        gen_src(SRC_BASE + 32'h700, SS, 32, 8, 1, 16'hA000);
        blend_case("C6a 加算 RGB565 ga=255",     2'd0, SRC_BASE + 32'h700, SS, FB_BASE + 2*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_ADD, 1);
        gen_src(SRC_BASE + 32'h700, SS, 32, 8, 2, 16'hA100);
        blend_case("C6b 加算 ARGB4444",          2'd0, SRC_BASE + 32'h700, SS, FB_BASE + 12*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_ADD444, 1);
        gen_src(SRC_BASE + 32'h700, SS, 32, 8, 1, 16'hA200);
        blend_case("C7  乘法 RGB565",            2'd0, SRC_BASE + 32'h700, SS, FB_BASE + 22*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_MUL, 1);
        blend_case("C8  force-opaque（ga=0 也当 255）", 2'd0, SRC_BASE + 32'h700, SS,
                   FB_BASE + 32*DS, DS, 32, 8, 0, 0, 8'hFF, AT_FORCE, 1);
        /* KEY + 逐像素 alpha + alpha 测试：每 3 个像素里 1 个键色（留孔）、a4=0 的再留孔 */
        gen_src(SRC_BASE + 32'h700, SS, 32, 8, 2, 16'hA300);
        for (j = 0; j < 8; j = j + 1)
            for (i = 0; i < 32; i = i + 1)
                if ((i % 3) == 0) poke16(SRC_BASE + 32'h700 + j*SS + i*2, 16'h1234);
        blend_case("C9  KEY+α混合+alpha 测试", 2'd3, SRC_BASE + 32'h700, SS,
                   FB_BASE + 42*DS, DS, 32, 8, 0, 16'h1234, 8'hFF, AT_TEST4, 1);
        blend_case("C10 FILL + α混合（半透明清屏）", 2'd1, 0, 0, FB_BASE + 52*DS, DS,
                   32, 8, 16'h07E0, 0, 8'hFF, AT_A128, 1);

        /* ---------------------------------------------------------------
         * L1~L6 手算表（逐点，期望值写死在 TB 里 —— 与模型互为交叉验证）
         * ------------------------------------------------------------- */
        $display("--- L1~L6 手算表 ---");
        lit_case("L1 565 a混 ga128 7BEF/C618 -> A4F4", 16'h7BEF, 16'hC618, 0, 0, 8'hFF, AT_A128, 16'hA4F4);
        lit_case("L2 565 乘法 7BEF/C618 -> 5AEB",      16'h7BEF, 16'hC618, 0, 0, 8'hFF, AT_MUL,  16'h5AEB);
        lit_case("L3 565 加算 1082/2945 -> 39C7",      16'h1082, 16'h2945, 0, 0, 8'hFF, AT_ADD,  16'h39C7);
        lit_case("L3b 565 加算 39E7/2945 -> 632C",     16'h39E7, 16'h2945, 0, 0, 8'hFF, AT_ADD,  16'h632C);
        lit_case("L4 4444 a混 ga128 8ABC/C618 -> BE18", 16'h8ABC, 16'hC618, 0, 0, 8'hFF, AT_A444G, 16'hBE18);
        lit_case("L5 1555 a混 ga64 87E0/C618 -> B692", 16'h87E0, 16'hC618, 0, 0, 8'hFF, AT_A1555T, 16'hB692);
        lit_case("L6 1555 a=0 测试 -> 留孔(C618)",     16'h07E0, 16'hC618, 0, 0, 8'hFF, AT_A1555T, 16'hC618);

        /* ---------------------------------------------------------------
         * C11 空属性 FIFO 的兼容性：再跑一次 C3c 的参数、但不推属性
         *     （证明"不写属性"与"写默认字"两条路都逐位等于兼容档）
         * ------------------------------------------------------------- */
        $display("--- C11 不写属性 = 写默认字（两条兼容路径） ---");
        blend_case("C11a 不写属性 → 兼容档", 2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 62*DS, DS,
                   32, 8, 0, 0, 8'hFF, AT_A128, 0);
        blend_case("C11b 写默认字 0x3FC0 → 兼容", 2'd0, SRC_BASE + 32'h400, SS, FB_BASE + 62*DS + 32, DS,
                   32, 8, 0, 0, 8'hFF, AT_DFLT, 1);
        blend_case("C11c 字面 0x000000FF → 兼容", 2'd0, SRC_BASE + 32'h400, SS,
                   FB_BASE + 62*DS + 64, DS, 32, 8, 0, 0, 8'hFF, 32'h0000_00FF, 1);

        if (errors == 0) $display("========== tb_attr_blend ALL PASS ==========");
        else             $display("========== tb_attr_blend FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("!!!!!!!! tb_attr_blend WATCHDOG !!!!!!!!");
        $finish;
    end
endmodule
