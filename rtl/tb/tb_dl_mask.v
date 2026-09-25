/* =========================================================================
 * tb_dl_mask.v — S3「透明块跳过」（KEY + 4×4 块掩码）专项测试台
 * -------------------------------------------------------------------------
 * 测什么（对应任务书"必须的证据"第 1、2 条）：
 *   (i)  **位精确**：同一批精灵、同一批位置，"带掩码的 KEY" 与 "不带掩码的 KEY"
 *        （CPU 路径 push 同一组 8 字做的金标准）**逐字节**完全相同；
 *        位置表刻意横扫各种对齐（x = 0/1/2/3/5/…，dst lane 0~7 全覆盖）。
 *   (ii) **真的省了**：按 AXI 实测拍数（读 beat / 写 beat / AW 笔）与墙钟拍数，
 *        带掩码 vs 不带掩码逐用例对比，并折算到每精灵。省得少就照实打印。
 *   (iii)**安全规则**：ALPHA / FILL / COPY 每像素都要写 ⇒ 掩码**必须被忽略**。
 *        本台的证法是"喂 0xFFFF（全透明）掩码"：若硬件真去跳，像素与拍数都会变。
 *   (iv) **A/B 逃生门**：`-DMASK_SKIP_OFF` 下掩码位恒 0（连命令字都逐位回到 S2），
 *        本台所有用例仍然位精确，且"带掩码"与"不带掩码"的拍数/beat 数**必须相等**。
 *   (v)  MASK_MODE 编码检查：MASK_EN=1 而 MASK_MODE≠01（本版本只实现了 01）
 *        ⇒ DL_ERR bit24（UNSUPPORTED），而不是拿 01 的语义去猜。
 *
 * 精灵形状（与 demo 的 KEY 精灵同构，逐像素可复现）：
 *   S0 16×16 demo"实心球"：白环 + 渐变内芯，四角键色 **61/256**（= 任务书给的数）
 *   S1 16×16 典型弹幕弹（r=6 实心圆，键色 143/256 ≈ 56% 透明）
 *   S2 32×32 demo 球（同形状放大 2×）
 *   S3 32×32 典型弹（r=11）
 *   S4 32×32 小弹（r=7：上下两条行带**整带透明** ⇒ 整行都不取数）
 *
 * 编译运行（仓库根；A/B 加 -DMASK_SKIP_OFF）：
 *   $env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
 *   iverilog -g2001 -s tb_dl_mask -o sim_tb_dl_mask.vvp rtl/sync_fifo.v rtl/cmd_fifo.v \
 *     rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v rtl/axi_rd_master.v rtl/axi_wr_master.v \
 *     rtl/stream_reader.v rtl/pixel_path.v rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v \
 *     rtl/clr_engine.v rtl/dl_fetch.v rtl/blt_top.v rtl/tb/axi_slave_mem.v rtl/tb/tb_dl_mask.v
 *   vvp sim_tb_dl_mask.vvp
 * ========================================================================= */
`timescale 1ns/1ps
module tb_dl_mask;

    /* ================= 时钟 / 复位 ================= */
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

    /* ================= 地址布局（真实存储 32KB） =================
     *   0x0000..0x1FFF  atlas（5 个形状，行距 64B）
     *   0x2000..0x5FFF  目标 FB（128×64 像素，行距 256B）
     *   0x6000..0x6FFF  描述符表
     *   0x7000..0x707F  几何表 */
    localparam [31:0] ATLAS    = 32'h0000_0000;
    localparam [31:0] DST      = 32'h0000_2000;
    localparam [31:0] LIST     = 32'h0000_6000;
    localparam [31:0] GEOM     = 32'h0000_7000;
    localparam [31:0] A_STRIDE = 32'd64;
    localparam [31:0] D_STRIDE = 32'd256;
    localparam [15:0] FB_W = 16'd128, FB_H = 16'd64;
    localparam [15:0] KEYC = 16'hF81F;             // 与 demo 的 KEY_COLOR 一致
    localparam integer NSH   = 5;                  // 形状数
    localparam integer NDESC = 16;                 // 每条列表的描述符数
    localparam integer NVAL  = 16384;              // 逐字节比对范围（FB 16KB）

    /* ================= AXI-Lite 主测口 ================= */
    reg  [11:0] awaddr = 0, araddr = 0;
    reg         awvalid = 0, wvalid = 0, arvalid = 0;
    reg  [31:0] wdata = 0;
    reg  [3:0]  wstrb = 4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [31:0] rdata;
    reg         bready = 1, rready = 1;

    /* ================= 引擎 AXI 主机 ================= */
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
    wire [1:0]  m_rresp = 2'b00;                  // DFU 用它判 RRESP，必须显式接 0
    reg  [1:0]  fb_cur_sel_r = 2'd0;

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
        .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp), .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready),
        .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen), .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst), .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready),
        .m_axi_wdata(m_wdata), .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast),
        .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
        .m_axi_bvalid(m_bvalid), .m_axi_bresp(), .m_axi_bready(m_bready),
        .irq_done(irq_done),
        .scan_underrun(16'd0), .scan_abort(16'd0),
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

    /* ================= 计数器 / 记分板 ================= */
    integer errors = 0;
    integer ar_cnt, rd_beats, aw_cnt, w_beats, b_cnt;
    integer t0, t1, rv;
    integer i, j, n, mism, tseq;
    integer cyc_nomask, cyc_mask, beat_nomask, beat_mask, aw_nomask, aw_mask;
    integer w_nomask, w_mask;
    integer pf_nomask, pf_mask;                  // ★ DFU 自己的 GO→DONE 计数（无轮询抖动）
    integer pf_warm;                             // 每条列表第一次跑（冷状态，仅打印参考）
    integer pend_nomask, pend_mask;              // DL_PERF − 本次 CPU 实测墙钟，仅打印
    reg [7:0] gold [0:NVAL-1];
    reg [7:0] shot [0:NVAL-1];
    reg [31:0] q0, q1, q2, q3, q4, q5, q6, q7;

    always @(posedge clk) if (rst_n) begin
        if (m_arvalid && m_arready) ar_cnt = ar_cnt + 1;
        if (m_rvalid && m_rready)   rd_beats = rd_beats + 1;
        if (u_blt.blt_awvalid && u_blt.blt_awready) aw_cnt = aw_cnt + 1;
        if (m_wvalid && m_wready)   w_beats = w_beats + 1;
        if (m_bvalid && m_bready)   b_cnt = b_cnt + 1;
    end

    task chk;
        input ok;
        input [255:0] name;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* ================= AXI-Lite / 存储 ================= */
    task axi_write;
        input [11:0] addr; input [31:0] data;
        begin
            awaddr = addr; awvalid = 1'b1;
            wdata  = data; wstrb  = 4'hF; wvalid = 1'b1;
            while (!(bvalid && bready)) @(posedge clk);
            #1; awvalid = 1'b0; wvalid = 1'b0;
        end
    endtask

    task axi_read;
        input [11:0] addr; output [31:0] rd;
        begin
            araddr = addr; arvalid = 1'b1;
            while (!(rvalid && rready)) @(posedge clk);
            rd = rdata;
            #1; arvalid = 1'b0;
        end
    endtask

    task poke16;
        input [31:0] a; input [15:0] v;
        begin u_mem.mem[a] = v[7:0]; u_mem.mem[a+1] = v[15:8]; end
    endtask

    task poke32;
        input [31:0] a; input [31:0] v;
        begin u_mem.mem[a]   = v[7:0];   u_mem.mem[a+1] = v[15:8];
              u_mem.mem[a+2] = v[23:16]; u_mem.mem[a+3] = v[31:24]; end
    endtask

    task peek16;
        input [31:0] a; output [15:0] v;
        begin v = {u_mem.mem[a+1], u_mem.mem[a]}; end
    endtask

    /* ================= 形状表 ================= */
    reg [31:0] sh_off  [0:NSH-1];
    reg [15:0] sh_w    [0:NSH-1];
    reg [15:0] sh_h    [0:NSH-1];
    reg [15:0] sh_rin  [0:NSH-1];      // d² ≤ rin ⇒ 渐变内芯
    reg [15:0] sh_rout [0:NSH-1];      // rin < d² ≤ rout ⇒ 白环；否则键色

    task init_shapes_tab;
        begin
            sh_off[0]=32'h0000; sh_w[0]=16'd16; sh_h[0]=16'd16; sh_rin[0]=16'd36;  sh_rout[0]=16'd64;
            sh_off[1]=32'h0400; sh_w[1]=16'd16; sh_h[1]=16'd16; sh_rin[1]=16'd36;  sh_rout[1]=16'd36;
            sh_off[2]=32'h0800; sh_w[2]=16'd32; sh_h[2]=16'd32; sh_rin[2]=16'd144; sh_rout[2]=16'd256;
            sh_off[3]=32'h1000; sh_w[3]=16'd32; sh_h[3]=16'd32; sh_rin[3]=16'd121; sh_rout[3]=16'd121;
            sh_off[4]=32'h1800; sh_w[4]=16'd32; sh_h[4]=16'd32; sh_rin[4]=16'd49;  sh_rout[4]=16'd49;
        end
    endtask

    /* 形状生成：与 demo 的精灵同构（圆盘 + 白环 + 渐变内芯 + 键色四角） */
    task gen_shape;
        input integer k;
        integer x, y; reg [31:0] d; reg [15:0] c; integer cxx, cyy;
        begin
            cxx = (sh_w[k] - 1) / 2;
            cyy = (sh_h[k] - 1) / 2;
            for (y = 0; y < sh_h[k]; y = y + 1)
                for (x = 0; x < sh_w[k]; x = x + 1) begin
                    d = (x - cxx) * (x - cxx) + (y - cyy) * (y - cyy);
                    if      (d <= sh_rin[k])  c = 16'h0800 + ((x * 3 + y * 5) & 16'h00FF);
                    else if (d <= sh_rout[k]) c = 16'hFFFF;
                    else                      c = KEYC;
                    poke16(ATLAS + sh_off[k] + y * A_STRIDE + x * 2, c);
                end
        end
    endtask

    /* 键色像素计数（打印用） */
    task count_key;
        input integer k; output integer nk;
        integer x, y; reg [15:0] c;
        begin
            nk = 0;
            for (y = 0; y < sh_h[k]; y = y + 1)
                for (x = 0; x < sh_w[k]; x = x + 1) begin
                    peek16(ATLAS + sh_off[k] + y * A_STRIDE + x * 2, c);
                    if (c === KEYC) nk = nk + 1;
                end
        end
    endtask

    /* 软件侧算 4×4 块掩码：整块每个像素都是键色 ⇒ 该位置 1（全透明，可跳）。
     * 与硬件同一套列块/行带边界（floor(W*ct/4)、floor(H*rt/4)）。 */
    task calc_mask;
        input integer k; output [15:0] msk;
        integer rt, ct, x, y; reg allkey; reg [15:0] c;
        begin
            msk = 16'd0;
            for (rt = 0; rt < 4; rt = rt + 1)
                for (ct = 0; ct < 4; ct = ct + 1) begin
                    allkey = 1'b1;
                    for (y = (sh_h[k]*rt)/4; y < (sh_h[k]*(rt+1))/4; y = y + 1)
                        for (x = (sh_w[k]*ct)/4; x < (sh_w[k]*(ct+1))/4; x = x + 1) begin
                            peek16(ATLAS + sh_off[k] + y*A_STRIDE + x*2, c);
                            if (c !== KEYC) allkey = 1'b0;
                        end
                    if (allkey) msk = msk | (16'd1 << (rt*4 + ct));
                end
        end
    endtask

    /* 位置表：横扫 dst 对齐（x 奇偶/半字/lane）与行位置 */
    task pos_of;
        input integer idx; output [15:0] xx; output [15:0] yy;
        begin
            xx = ((idx * 7) % 96);
            yy = ((idx * 5) % 32);
        end
    endtask

    task init_geom;
        begin
            for (n = 0; n < NSH; n = n + 1) begin
                poke32(GEOM + n*16 + 0,  ATLAS + sh_off[n]);   // ATLAS_BASE
                poke16(GEOM + n*16 + 4,  A_STRIDE[15:0]);      // ATLAS_STRIDE
                poke16(GEOM + n*16 + 6,  KEYC);                // KEY_DEFAULT
                poke16(GEOM + n*16 + 8,  sh_w[n]);             // W
                poke16(GEOM + n*16 + 10, sh_h[n]);             // H
                poke16(GEOM + n*16 + 12, 16'd0);               // SX
                poke16(GEOM + n*16 + 14, 16'd0);               // SY
            end
        end
    endtask

    task init_dst;
        integer r, c;
        begin
            for (r = 0; r < FB_H; r = r + 1)
                for (c = 0; c < FB_W; c = c + 1)
                    poke16(DST + r*D_STRIDE + c*2, 16'h1000 + ((r*7 + c*13) & 16'h03FF));
        end
    endtask

    /* ================= 命令 / 描述符 ================= */
    /* 与 DFU 展开逐字一致的 8 字（CPU 路径金标准；w0 高 30 位恒 0 = 掩码关） */
    task cmd_of;
        input integer k; input [1:0] op; input [7:0] alpha;
        input [15:0] xx; input [15:0] yy; input [15:0] fillc;
        begin
            q0 = {30'd0, op};
            q1 = (op == 2'd1) ? 32'd0 : (ATLAS + sh_off[k]);
            q2 = DST + yy*D_STRIDE + xx*2;
            q3 = A_STRIDE;
            q4 = D_STRIDE;
            q5 = {sh_h[k], sh_w[k]};
            q6 = {24'd0, alpha};
            q7 = (op == 2'd1) ? {16'd0, fillc} : {16'd0, KEYC};
        end
    endtask

    task push_cmd;
        begin
            axi_write(12'h08, q0); axi_write(12'h08, q1);
            axi_write(12'h08, q2); axi_write(12'h08, q3);
            axi_write(12'h08, q4); axi_write(12'h08, q5);
            axi_write(12'h08, q6); axi_write(12'h08, q7);
        end
    endtask

    /* 描述符表：FLAGS = {保留[15:13], CHAIN, IRQ[11], END[10], MODE[9:8], MASK_EN[7],
     *                   SRC_OFF[6], SZ_OVR[5], CLIP[4], MIRY[3], MIRX[2], OP[1:0]} */
    task build_list;
        input integer k; input [1:0] op; input men; input [15:0] msk;
        input [7:0] alpha; input [15:0] fillc;
        integer di; reg [15:0] fl; reg [15:0] xx, yy;
        begin
            for (di = 0; di < NDESC; di = di + 1) begin
                pos_of(di, xx, yy);
                fl = {3'd0, 2'd0, (di == NDESC-1), 2'b01, men, 5'd0, op};
                poke16(LIST + di*16 + 0,  xx);
                poke16(LIST + di*16 + 2,  yy);
                poke16(LIST + di*16 + 4,  k[15:0]);
                poke16(LIST + di*16 + 6,  fl);
                poke16(LIST + di*16 + 8,  (op == 2'd1) ? fillc : KEYC);   // KEY / FILL 色
                poke16(LIST + di*16 + 10, {8'd0, alpha});                 // ALPHA
                poke16(LIST + di*16 + 12, msk);                           // MASK_ID（S3）
                poke16(LIST + di*16 + 14, 16'd0);                         // W_OVR/H_OVR
            end
        end
    endtask

    task eng_init;
        begin
            axi_write(12'h00, 32'h4);
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);
        end
    endtask

    task wait_eng_start;
        begin
            for (i = 0; (i < 200000) && (u_blt.u_eng.st == 3'd0); i = i + 1) @(posedge clk);
        end
    endtask

    task wait_done_level;
        begin : wdl
            for (i = 0; i < 2000000; i = i + 1) begin
                axi_read(12'h04, rv);
                if (rv & 32'h2) disable wdl;
                if (rv & 32'h4) begin
                    $display("FAIL: 引擎 ERR（STATUS=0x%h）", rv);
                    errors = errors + 1;
                    disable wdl;
                end
            end
            $display("FAIL: DONE 超时");
            errors = errors + 1;
        end
    endtask

    task snap_dst;
        input integer which;
        integer a;
        begin
            for (a = 0; a < NVAL; a = a + 1) begin
                if (which == 0) shot[a] = u_mem.mem[DST + a];
                else            gold[a] = u_mem.mem[DST + a];
            end
        end
    endtask

    task cmp_dst;
        input [255:0] tag;
        integer a;
        begin
            mism = 0;
            for (a = 0; a < NVAL; a = a + 1)
                if (shot[a] !== gold[a]) begin
                    if (mism < 5)
                        $display("      MISMATCH %0s off=%0d (x=%0d y=%0d) got=%02h exp=%02h",
                                 tag, a, (a % 256) / 2, a / 256, shot[a], gold[a]);
                    mism = mism + 1;
                end
        end
    endtask

    /* ================= 列表路径 ================= */
    task dl_config;
        input [15:0] cnt;
        begin
            axi_write(12'h4C, LIST);
            axi_write(12'h50, LIST);
            axi_write(12'h68, GEOM);
            axi_write(12'h6C, NSH[15:0]);
            axi_write(12'h70, DST);
            axi_write(12'h84, D_STRIDE[15:0]);
            axi_write(12'h88, {FB_H, FB_W});
            axi_write(12'h74, 32'h0000_0483);       // CHUNK=8 WM=4 PREFETCH=1 GEC=1
            axi_write(12'h78, 32'd4096);            // DL_TIMEOUT
            axi_write(12'h54, {16'd0, cnt});
            axi_write(12'h60, 32'hFFFF_FFFF);       // 清 DL_ERR
        end
    endtask

    /* 跑一条列表，记录墙钟/读 beat/写 beat；返回是否 DONE 且无错 */
    integer dl_cyc, dl_perf, dl_ok;
    task run_list;
        begin
            axi_write(12'h00, 32'h0);               // 关 CTRL.GO，让 AUTO_GO 当唯一启动源
            dl_config(NDESC[15:0]);
            ar_cnt = 0; rd_beats = 0; aw_cnt = 0; w_beats = 0; b_cnt = 0;
            t0 = cyc;
            axi_write(12'h58, 32'h31);              // GO + AUTO_GO + STRICT_BOUNDS
            dl_ok = 0;
            begin : dwd
                for (i = 0; i < 2000000; i = i + 1) begin
                    axi_read(12'h5C, rv);
                    if ((rv & 32'h2) && !(rv & 32'h1)) begin   // DONE=1 && BUSY=0
                        dl_cyc  = cyc - t0;
                        axi_read(12'h7C, dl_perf);
                        dl_ok = 1;
                        disable dwd;
                    end
                end
                $display("FAIL: 列表 DONE 超时（DL_STATUS=0x%h）", rv);
                errors = errors + 1;
                dl_cyc = cyc - t0;
                disable dwd;
            end
        end
    endtask

    task dl_status_err;
        output [31:0] st; output [31:0] er;
        begin
            axi_read(12'h5C, st);
            axi_read(12'h60, er);
        end
    endtask

    /* ================= 主流程 ================= */
    localparam integer NCASE = 9;
    integer ci, k, nkey, kmask;
    reg [15:0] msk_c;
    reg [1:0]  cop;
    reg [7:0]  calpha;
    reg [15:0] cfill;
    integer csel [0:NCASE-1];
    reg [1:0] copa [0:NCASE-1];
    reg       cmasken [0:NCASE-1];      // 本用例的 MASK_EN
    reg       cmaskall[0:NCASE-1];      // 1 = 喂 0xFFFF（专门验"非 KEY 必须忽略"）
    reg       cstrict [0:NCASE-1];      // 1 = 该形状确实有整带/整词可跳（源读 beat 必减）

    initial begin
        errors = 0; ar_cnt = 0; rd_beats = 0; aw_cnt = 0; w_beats = 0; b_cnt = 0;

        /* 用例表：sel = 形状号，op，MASK_EN，是否喂全 1 掩码 */
        csel[0]=0; copa[0]=2'd3; cmasken[0]=1; cmaskall[0]=0; cstrict[0]=0;  // 16 demo 球  KEY
        csel[1]=1; copa[1]=2'd3; cmasken[1]=1; cmaskall[1]=0; cstrict[1]=0;  // 16 典型弹  KEY
        csel[2]=2; copa[2]=2'd3; cmasken[2]=1; cmaskall[2]=0; cstrict[2]=0;  // 32 demo 球  KEY
        csel[3]=3; copa[3]=2'd3; cmasken[3]=1; cmaskall[3]=0; cstrict[3]=1;  // 32 典型弹  KEY
        csel[4]=4; copa[4]=2'd3; cmasken[4]=1; cmaskall[4]=0; cstrict[4]=1;  // 32 小弹    KEY
        csel[5]=3; copa[5]=2'd2; cmasken[5]=1; cmaskall[5]=1; cstrict[5]=0;  // ALPHA + 全 1 掩码
        csel[6]=3; copa[6]=2'd1; cmasken[6]=1; cmaskall[6]=1; cstrict[6]=0;  // FILL  + 全 1 掩码
        csel[7]=3; copa[7]=2'd0; cmasken[7]=1; cmaskall[7]=1; cstrict[7]=0;  // COPY  + 全 1 掩码
        csel[8]=4; copa[8]=2'd2; cmasken[8]=1; cmaskall[8]=0; cstrict[8]=0;  // ALPHA + 真掩码

        #20 rst_n = 1'b1;
        #200;

        init_shapes_tab();
        for (n = 0; n < NSH; n = n + 1) gen_shape(n);
        init_geom();
        eng_init();

        $display("==== S3 形状表（键色 = 全透明）====");
        for (n = 0; n < NSH; n = n + 1) begin
            count_key(n, nkey);
            calc_mask(n, msk_c);
            $display("SHAPE S%0d %0dx%0d key_px=%0d/%0d mask=0x%04h",
                     n, sh_w[n], sh_h[n], nkey, sh_w[n]*sh_h[n], msk_c);
        end

        $display("==== S3 用例：带掩码 vs 不带掩码（金标准 = CPU 路径同 8 字）====");
        for (ci = 0; ci < NCASE; ci = ci + 1) begin
            k      = csel[ci];
            cop    = copa[ci];
            calpha = 8'h80;
            cfill  = 16'h07E0;
            calc_mask(k, msk_c);
            if (cmaskall[ci]) msk_c = 16'hFFFF;

            /* --- 金标准：CPU 路径 push 同一组 8 字（w0 高 30 位 = 0 ⇒ 掩码关） --- */
            init_dst();
            axi_write(12'h00, 32'h1);                  // CTRL.GO = 1（CPU 路径）
            for (n = 0; n < NDESC; n = n + 1) begin
                pos_of(n, q0, q1);                     // 借用 q0/q1 存位置
                cmd_of(k, cop, calpha, q0, q1, cfill);
                push_cmd();
            end
            wait_eng_start; wait_done_level;
            snap_dst(1);

            /* --- A：列表路径，MASK_EN=0（每条列表的**第一次**跑：冷状态，只作参考） --- */
            init_dst();
            build_list(k, cop, 1'b0, 16'd0, calpha, cfill);
            run_list();
            pf_warm = dl_perf;
            snap_dst(0); cmp_dst("NOMASK-WARM");
            chk(dl_ok == 1 && mism == 0, "列表路径(无掩码) == CPU 金标准");            /* --- A2：再跑一次 MASK_EN=0 = **正式基线** ---
             * 为什么基线取"第二次跑"：同配置重跑逐位可重复（A2 == B，见 CASE 行），
             * 而每条列表**第一次**跑会比之后多 ~22 拍（多一笔 1 拍描述符块读，
             * 是 DFU 预取在冷启动状态下的分块差异，与掩码无关）。用 A2 做基线，
             * 掩码的全部差异才干净地归因于窗口本身。 */
            init_dst();
            build_list(k, cop, 1'b0, 16'd0, calpha, cfill);
            run_list();
            pf_nomask = dl_perf; beat_nomask = rd_beats;
            aw_nomask = aw_cnt;  w_nomask    = w_beats;
            cyc_nomask = dl_cyc;
            snap_dst(0); cmp_dst("NOMASK");

            /* --- B：列表路径，MASK_EN=1 + 掩码 --- */
            init_dst();
            build_list(k, cop, cmasken[ci], msk_c, calpha, cfill);
            run_list();
            cyc_mask = dl_cyc; beat_mask = rd_beats;
            aw_mask  = aw_cnt; w_mask    = w_beats;
            pf_mask  = dl_perf; pend_mask = dl_cyc - dl_perf;
            snap_dst(0); cmp_dst("MASK");
            chk(dl_ok == 1 && mism == 0, "★带掩码路径 == 不带掩码路径（逐字节）");

            $display("CASE %0d | shape S%0d %0dx%0d | op=%0d | mask=0x%04h | DL_PERF base=%0d mask=%0d (d=%0d, /sprite %0d) | warm=%0d | rdbeat base=%0d mask=%0d | aw %0d -> %0d | wbeat %0d -> %0d",
                     ci, k, sh_w[k], sh_h[k], cop, msk_c,
                     pf_nomask, pf_mask, pf_mask - pf_nomask,
                     (pf_mask - pf_nomask)/NDESC, pf_warm,
                     beat_nomask, beat_mask,
                     aw_nomask, aw_mask, w_nomask, w_mask);

            if (cop == 2'd3 && msk_c != 16'd0) begin
`ifdef MASK_SKIP_OFF
                /* A/B 逃生门：掩码位被强行清零 ⇒ 读数必须与"无掩码"完全一致 */
                chk(pf_mask == pf_nomask && cyc_mask == cyc_nomask &&
                    beat_mask == beat_nomask &&
                    w_mask == w_nomask && aw_mask == aw_nomask,
                    "★MASK_SKIP_OFF：带掩码描述符与无掩码逐位同拍（逃生门）");
`else
                /* 源读 beat 不必然减少：16 像素宽的一行只有 2 个 16B 词，窗口
                 * 只要还跨着这两个词（例如 12 像素窗口落在字节 0~23），取数
                 * 拍数就与整行相同 —— 省下的是**像素通路拍数**（DL_PERF 会变）。
                 * 只有窗口落进更少的词、或整带透明（S3/S4）才会真的少读。 */
                chk(beat_mask <= beat_nomask, "KEY+掩码：源读 beat 不增加");
                chk(pf_mask  <  pf_nomask,    "★KEY+掩码：DL_PERF 拍数真的变少");
                chk(w_mask    <= w_nomask,    "KEY+掩码：写词数不增加");
                if (cstrict[ci])
                    chk(beat_mask < beat_nomask, "★KEY+掩码（有整带/整词可跳）：源读 beat 真的变少");
`endif
            end else if (cop == 2'd3) begin
                /* 掩码为 0（demo 的"实心球"：没有任何一个 4×4 块整块透明）⇒ 省不了 */
                chk(pf_mask == pf_nomask && beat_mask == beat_nomask && cyc_mask == cyc_nomask,
                    "KEY 掩码=0：与无掩码逐位同拍（该形状确实没有可跳的块）");
            end else begin
                /* 非 KEY：掩码（哪怕全 1）必须被忽略 —— 拍数/beat 必须一致 */
                chk(pf_mask == pf_nomask && cyc_mask == cyc_nomask &&
                    beat_mask == beat_nomask &&
                    w_mask == w_nomask && aw_mask == aw_nomask,
                    "★非 KEY（ALPHA/FILL/COPY）：掩码被忽略，读数逐位相同");
            end
        end

        /* ---------------- MASK_MODE 编码检查 ---------------- */
        $display("==== MASK_MODE 检查（MASK_EN=1 而 MODE≠01 ⇒ UNSUPPORTED）====");
        begin : mdm
            reg [15:0] fl;
            init_dst();
            pos_of(0, q0, q1);
            fl = {3'd0, 2'd0, 1'b1, 2'b00, 1'b1, 5'd0, 2'd3};   // MODE=00 + MASK_EN=1
            poke16(LIST + 0,  q0);
            poke16(LIST + 2,  q1);
            poke16(LIST + 4,  16'd3);
            poke16(LIST + 6,  fl);
            poke16(LIST + 8,  KEYC);
            poke16(LIST + 10, 16'd0);
            poke16(LIST + 12, 16'd0);
            poke16(LIST + 14, 16'd0);
            axi_write(12'h00, 32'h0);
            dl_config(16'd1);
            axi_write(12'h58, 32'h31);
            for (i = 0; i < 200000; i = i + 1) begin
                axi_read(12'h5C, rv);
                if ((rv & 32'h2) && !(rv & 32'h1)) i = 200000;
                if (rv & 32'h4) i = 200000;
            end
            dl_status_err(rv, t1);
            $display("MODE=00: DL_STATUS=0x%h DL_ERR=0x%h", rv, t1);
`ifdef MASK_SKIP_OFF
            chk((rv & 32'h4) == 0, "MASK_SKIP_OFF：MASK_MODE 检查一并关闭（不报错）");
`else
            chk(t1[24] === 1'b1, "MASK_MODE≠01 ⇒ DL_ERR.UNSUPPORTED（bit24）");
`endif
            axi_write(12'h60, 32'hFFFF_FFFF);
            axi_write(12'h5C, 32'h0);
        end

        if (errors == 0) $display("========== tb_dl_mask ALL PASS ==========");
        else             $display("========== tb_dl_mask FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #200_000_000;
        $display("!!!!!!!! tb_dl_mask WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule
