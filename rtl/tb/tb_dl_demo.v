/* =========================================================================
 * dl_demo_mem — 行为级伪 DDR（AXI4 从机，128bit，INCR 突发，多笔在飞）
 *   与 rtl/tb/axi_slave_mem.v **行为等价**，只有一处实现差别：读数据用寄存器打
 *   一拍（读地址提前一拍算出）。原因：iverilog 对"大容量存储 + 组合读"会展开成
 *   巨型选择网络（16MB 容量要几分钟），寄存器读只占一个存储端口（<0.1s）。
 *   AXI 侧可见的差别只有"每个 R beat 晚 1 拍"，本台不依赖任何绝对延迟。
 *   AR 队列 / R 返回 / 写字节合并 / q_cnt 同拍加减 与 axi_slave_mem 逐行一致。
 * ========================================================================= */
module dl_demo_mem #(
    parameter AXI_DATA_W = 128,
    parameter MEM_BYTES  = 1 << 24,
    parameter AR_LAT     = 20,
    parameter B_LAT      = 2,
    parameter MAXO       = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [31:0]             s_araddr,
    input  wire [7:0]              s_arlen,
    input  wire [2:0]              s_arsize,
    input  wire [1:0]              s_arburst,
    input  wire                    s_arvalid,
    output reg                     s_arready,
    output wire [AXI_DATA_W-1:0]   s_rdata,
    output wire [1:0]              s_rresp,
    output wire                    s_rlast,
    output reg                     s_rvalid,
    input  wire                    s_rready,
    input  wire [31:0]             s_awaddr,
    input  wire [7:0]              s_awlen,
    input  wire [2:0]              s_awsize,
    input  wire [1:0]              s_awburst,
    input  wire                    s_awvalid,
    output reg                     s_awready,
    input  wire [AXI_DATA_W-1:0]   s_wdata,
    input  wire [AXI_DATA_W/8-1:0] s_wstrb,
    input  wire                    s_wlast,
    input  wire                    s_wvalid,
    output reg                     s_wready,
    output reg                     s_bvalid,
    output wire [1:0]              s_bresp,
    input  wire                    s_bready
);
    reg [7:0] mem [0:MEM_BYTES-1];
    integer i;

    assign s_rresp = 2'b00;
    assign s_bresp = 2'b00;

    reg [31:0] cyc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cyc <= 32'd0;
        else        cyc <= cyc + 32'd1;
    end

    /* ---------------- 读：AR 队列 + 流水回程 ---------------- */
    reg [31:0] q_addr [0:MAXO-1];
    reg [7:0]  q_len  [0:MAXO-1];
    reg [31:0] q_rdy  [0:MAXO-1];
    reg [2:0]  q_cnt, q_wp, q_rp;
    reg [7:0]  r_cnt;

    wire [1:0]  qrp = q_rp[1:0];
    wire [1:0]  qwp = q_wp[1:0];
    wire [31:0] rd_base = q_addr[qrp];
    wire [7:0]  rd_len  = q_len [qrp];
    wire [31:0] cur_r   = rd_base + {24'd0, r_cnt} * 16;

    /* 下一拍要呈现的 beat 地址：
     *   空闲 ⇒ 本笔首 beat；本拍未被受理 ⇒ 同 beat 重放；
     *   本拍是末 beat ⇒ 无缝续发的下一笔首 beat（未续发时该值不会被用）；
     *   否则 ⇒ 本笔下一 beat。 */
    wire [31:0] next_addr = (!s_rvalid)            ? rd_base :
                            (!s_rready)            ? cur_r   :
                            (r_cnt == rd_len)      ? q_addr[(q_rp + 3'd1) & 3'd3] :
                                                     (rd_base + ({24'd0, r_cnt} + 24'd1) * 16);

    reg [AXI_DATA_W-1:0] rdata_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rdata_r <= {AXI_DATA_W{1'b0}};
        else
            for (i = 0; i < AXI_DATA_W/8; i = i + 1)
                rdata_r[i*8 +: 8] <= ((next_addr + i) < MEM_BYTES) ? mem[next_addr + i] : 8'd0;
    end
    assign s_rdata = rdata_r;
    assign s_rlast = s_rvalid && (r_cnt == rd_len);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_arready <= 1'b1;
            s_rvalid  <= 1'b0;
            q_cnt     <= 3'd0;
            q_wp      <= 3'd0;
            q_rp      <= 3'd0;
            r_cnt     <= 8'd0;
        end else begin
            s_arready <= (q_cnt < MAXO[2:0]);

            if (s_arvalid && s_arready) begin
                q_addr[qwp] <= s_araddr;
                q_len [qwp] <= s_arlen;
                q_rdy [qwp] <= cyc + AR_LAT[31:0];
                q_wp        <= q_wp + 3'd1;
            end

            if (s_rvalid && s_rready) begin
                if (s_rlast) begin
                    q_rp  <= q_rp + 3'd1;
                    if ((q_cnt > 3'd1) && ((cyc + 32'd1) >= q_rdy[(q_rp + 3'd1) & 3'd3])) begin
                        r_cnt <= 8'd0;
                        s_rvalid <= 1'b1;
                    end else
                        s_rvalid <= 1'b0;
                end else
                    r_cnt <= r_cnt + 8'd1;
            end else if (!s_rvalid && (q_cnt != 3'd0) && (cyc >= q_rdy[qrp])) begin
                s_rvalid <= 1'b1;
                r_cnt    <= 8'd0;
            end
            q_cnt <= q_cnt + ((s_arvalid && s_arready) ? 3'd1 : 3'd0)
                           - ((s_rvalid && s_rready && s_rlast) ? 3'd1 : 3'd0);
        end
    end

    /* ---------------- 写 ---------------- */
    localparam WR_IDLE = 2'd0, WR_W = 2'd1, WR_B = 2'd2;
    reg [1:0]  wrst;
    reg [31:0] w_addr;
    reg [7:0]  w_dly;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wrst      <= WR_IDLE;
            s_awready <= 1'b1;
            s_wready  <= 1'b0;
            s_bvalid  <= 1'b0;
            w_addr    <= 32'd0;
            w_dly     <= 8'd0;
        end else begin
            case (wrst)
                WR_IDLE: begin
                    s_awready <= 1'b1;
                    if (s_awvalid) begin
                        s_awready <= 1'b0;
                        w_addr    <= s_awaddr;
                        s_wready  <= 1'b1;
                        wrst      <= WR_W;
                    end
                end
                WR_W: begin
                    if (s_wvalid && s_wready) begin
                        for (i = 0; i < AXI_DATA_W/8; i = i + 1)
                            if (s_wstrb[i] && (w_addr + i < MEM_BYTES))
                                mem[w_addr + i] <= s_wdata[i*8 +: 8];
                        if (s_wlast) begin
                            s_wready <= 1'b0;
                            w_dly    <= B_LAT[7:0];
                            wrst     <= WR_B;
                        end else
                            w_addr <= w_addr + 16;
                    end
                end
                WR_B: begin
                    if (w_dly == 8'd0) begin
                        s_bvalid <= 1'b1;
                        if (s_bvalid && s_bready) begin
                            s_bvalid  <= 1'b0;
                            s_awready <= 1'b1;
                            wrst      <= WR_IDLE;
                        end
                    end else
                        w_dly <= w_dly - 8'd1;
                end
                default: wrst <= WR_IDLE;
            endcase
        end
    end
endmodule


/* =========================================================================
 * tb_dl_demo.v — 用**固件真实生成的描述符**跑显示列表路径（场景 1/2/3，16/32/64）
 * -------------------------------------------------------------------------
 * 由来（板上现象）：FinalDemo 按 'l' 打开显示列表后，场景 2(ALPHA)/3(KEY) 打不开，
 *   场景 1(FILL) 正常。本台把**软件 dl_build()/dl_geom_build() 原样输出**的描述符
 *   逐字节喂给真实 RTL，回答两件事：
 *     (i)  取指器接受吗？（DL_ERR == 0、CONSUMED == 条数）
 *     (ii) DFU 展开出的 8 字命令与"逐条下发路径"逐位相同吗？像素逐字节相同吗？
 *
 * 数据来源：主机自检程序把 FinalDemo.c 的 DL_ENC 段与 dl_geom_build() 原样抽出、
 *   配最小桩编译运行后的打印结果；本文件里的描述符/几何表/参考命令就是那份输出，
 *   原样搬运（描述符四字组 = dl_put() 写进 DDR 的那 16 字节）。
 *   固件地址按真实值使用：ATLAS=0x201000、后台缓冲 FB_BACK=0x501000、
 *   几何表 0x801000、列表 0x821000/0x841000（DDR_BASE=0x1000）。
 *   唯一一处替换：几何表 gw0（图集基址）在主机自检里是主机数组地址，这里换回固件
 *   常量 ATLAS_BASE（0x201000）—— 固件写的就是它，其余字段一位未动。
 *
 * 覆盖：FILL/ALPHA/KEY × 16/32/64（★v2.16 新增 64x64 三例），每场 4 块**贴边**位置
 *   （x∈{0, FB_W-sz}、y∈{0, HALF_H-sz}；64x64 ⇒ x∈{0,896}、y∈{0,196}），
 *   外加"整片重铺"（W=960 必须走几何表）。每例三遍：先逐条 8 字 push（金标准），
 *   再描述符表 + DFU 跑两次（BUF1 首张 / BUF0 乒乓第二张，与固件节奏一致）；
 *   命令字逐位比、渲染区（y16..540，1,006,080 字节）逐字节比。
 *   ★几何表同时由 8 条扩到 **11 条**（DL_GEOM_MAX=11，逐字对着固件 DL_GEOM_N）⇒ 本台
 *     顺带回答"取指器接受 11 条条目吗"：RTL 的 0x6C 是完整 16 bit 字段、判据是
 *     `spr_id >= s_geom_max`，而几何 cache 是 16 条直接映射（索引 spr_id[3:0]）⇒ 11 条
 *     各占一个互不相同的索引，零冲突（用例 1 的 9 例 + 重铺那条就是这条结论的证据）。
 *
 * 另外复现"只有精灵条目会踩"的两类板上失败签名（场景 1 完全不读几何表 ⇒ 不受影响）：
 *   3) 几何表内容为 0（写丢了/读成 0，冷 cache）⇒ DL_ERR=0x80 ZERO_SIZE、0 条命令；
 *   4) DL_GEOM_MAX 写被 BUSY 丢掉（=0）⇒ DL_ERR=0x2 GEOM_INDEX、0 条命令，
 *      而同一条规则下 FILL+SIZE_OVR 照常展开 4×8 字（场景 1 一切正常）。
 *   —— 板上的"场景 2/3 打不开列表模式、场景 1 正常"就是这两条签名之一。
 *
 * 编译运行（仓库根目录）：
 *   iverilog -g2001 -s tb_dl_demo -o sim_tb_dl_demo.vvp rtl/sync_fifo.v rtl/cmd_fifo.v \
 *     rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v rtl/axi_rd_master.v rtl/axi_wr_master.v \
 *     rtl/stream_reader.v rtl/pixel_path.v rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v \
 *     rtl/clr_engine.v rtl/dl_fetch.v rtl/blt_top.v rtl/tb/axi_slave_mem.v rtl/tb/tb_dl_demo.v
 *   vvp sim_tb_dl_demo.vvp
 * ========================================================================= */
`timescale 1ns/1ps
module tb_dl_demo;

    /* ================= 固件常量（FinalDemo.c） ================= */
    localparam [31:0] DDR_BASE  = 32'h0000_1000;
    localparam [31:0] ATLAS     = DDR_BASE + 32'h0020_0000;   // 0x00201000
    localparam [31:0] FB_BACK   = DDR_BASE + 32'h0050_0000;   // 0x00501000
    localparam [31:0] GEOM      = DDR_BASE + 32'h0080_0000;   // 0x00801000
    localparam [31:0] LIST0     = DDR_BASE + 32'h0082_0000;   // 0x00821000
    localparam [31:0] LIST1     = DDR_BASE + 32'h0084_0000;   // 0x00841000
    localparam        FB_W = 960, FB_H = 540, TOP_Y0 = 16;
    localparam [31:0] FB_STRIDE = 32'd1920;
    localparam [15:0] KEY_COLOR = 16'hF81F;
    /* ★v2.16：几何表条目数（固件 DL_GEOM_N）—— 自检里就是 11 条 */
    localparam integer DL_GEOM_MAX = 11;
    localparam [31:0] DST_BASE  = FB_BACK + TOP_Y0 * FB_STRIDE;   // 0x00508800
    localparam integer CMP_BYTES = (FB_H - TOP_Y0) * 1920;        // y 16..540

    /* ================= 时钟 / 复位 ================= */
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;
    integer cyc = 0;
    always @(posedge clk) cyc = cyc + 1;

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
    reg  [1:0]  fb_cur_sel_r = 2'd0;
    wire [1:0]  m_rresp = 2'b00;

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

    /* 16MB：固件布局最高用到 0x841000 + 列表 ⇒ 全部地址必须可寻址
     * （越界读在模型里返回 0 ⇒ 会假装成 ZERO_SIZE，不是真实板级行为） */
    dl_demo_mem #(.AXI_DATA_W(128), .MEM_BYTES(1 << 24), .AR_LAT(20), .B_LAT(2), .MAXO(4)) u_mem (
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

    /* ================= 记分板 ================= */
    integer errors = 0;
    task chk;
        input ok;
        input [255:0] name;
        begin
            if (!ok) begin errors = errors + 1; $display("FAIL: %0s", name); end
            else $display("PASS: %0s", name);
        end
    endtask

    /* ================= AXI-Lite / 存储任务 ================= */
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
            rd = rdata; #1; arvalid = 1'b0;
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

    /* ================= 命令捕获（cmd_fifo 写口） ================= */
    integer cap_n;
    reg     cap_en = 0;
    reg [31:0] capw [0:511];
    always @(posedge clk) if (rst_n && cap_en && u_blt.fifo_wr_en) begin
        if (cap_n < 512) capw[cap_n] = u_blt.fifo_wr_data;
        cap_n = cap_n + 1;
    end

    /* ================= 图集（= 固件 build_atlas() 的 spr_color 公式） ================= */
    function [15:0] spr_color;
        input integer i, j, w, h, ring;
        integer dx, dy, d2, r2, ri, bb;
        reg [31:0] rr, gg;
        begin
            dx = i - w/2; dy = j - h/2; d2 = dx*dx + dy*dy; r2 = (w/2)*(w/2); ri = w/2 - ring;
            if (d2 > r2)         spr_color = KEY_COLOR;
            else if (d2 > ri*ri) spr_color = 16'hFFFF;
            else begin
                rr = (i * 31) / (w - 1);
                gg = (j * 63) / (h - 1);
                bb = 31 - ((d2 * 31) / ((r2 != 0) ? r2 : 1));
                if (bb < 0) bb = 0;
                spr_color = ((rr << 11) | (gg << 5) | bb);
            end
        end
    endfunction
    task atlas_init;
        input integer sz; integer i, j;
        begin
            for (i = 0; i < 64; i = i + 1)
                for (j = 0; j < 64; j = j + 1)
                    poke16(ATLAS + i*128 + j*2, 16'h0000);
            for (j = 0; j < sz; j = j + 1)
                for (i = 0; i < sz; i = i + 1)
                    poke16(ATLAS + j*sz*2 + i*2, spr_color(i, j, sz, sz, sz/8));
            $display("      [atlas] %0dx%0d (0,0)=%04x (1,0)=%04x (%0d,%0d)=%04x (%0d,%0d)=%04x",
                     sz, sz, spr_color(0,0,sz,sz,sz/8), spr_color(1,0,sz,sz,sz/8),
                     sz/2, sz/2, spr_color(sz/2,sz/2,sz,sz,sz/8),
                     sz-1, sz-1, spr_color(sz-1,sz-1,sz,sz,sz/8));
        end
    endtask

    /* 几何表：固件 dl_geom_build() 的 11 条（gw0 = ATLAS_BASE）
     * ★v2.16 条目号重排（每个场景占连续三格：16/32/64），铺底两条挪到 9/10：
     *   0/1/2=FILL 16/32/64  3/4/5=ALPHA 16/32/64  6/7/8=KEY 16/32/64  9/10=铺底
     *   ⇒ 64x64 的三条（2/5/8）就是本次新增；DL_GEOM_MAX 也从 8 变成 11。 */
    task geom_init;
        begin
            /* g[0] FILL 16 */ poke32(GEOM +  0, 32'h00201000); poke16(GEOM +  4, 32); poke16(GEOM +  6, 16'hf81f);
            poke16(GEOM +  8, 16); poke16(GEOM + 10, 16); poke16(GEOM + 12, 0); poke16(GEOM + 14, 0);
            /* g[1] FILL 32 */ poke32(GEOM + 16, 32'h00201000); poke16(GEOM + 20, 64); poke16(GEOM + 22, 16'hf81f);
            poke16(GEOM + 24, 32); poke16(GEOM + 26, 32); poke16(GEOM + 28, 0); poke16(GEOM + 30, 0);
            /* g[2] FILL 64 */ poke32(GEOM + 32, 32'h00201000); poke16(GEOM + 36, 128); poke16(GEOM + 38, 16'hf81f);
            poke16(GEOM + 40, 64); poke16(GEOM + 42, 64); poke16(GEOM + 44, 0); poke16(GEOM + 46, 0);
            /* g[3] ALPHA 16 */ poke32(GEOM + 48, 32'h00201000); poke16(GEOM + 52, 32); poke16(GEOM + 54, 16'hf81f);
            poke16(GEOM + 56, 16); poke16(GEOM + 58, 16); poke16(GEOM + 60, 0); poke16(GEOM + 62, 0);
            /* g[4] ALPHA 32 */ poke32(GEOM + 64, 32'h00201000); poke16(GEOM + 68, 64); poke16(GEOM + 70, 16'hf81f);
            poke16(GEOM + 72, 32); poke16(GEOM + 74, 32); poke16(GEOM + 76, 0); poke16(GEOM + 78, 0);
            /* g[5] ALPHA 64 */ poke32(GEOM + 80, 32'h00201000); poke16(GEOM + 84, 128); poke16(GEOM + 86, 16'hf81f);
            poke16(GEOM + 88, 64); poke16(GEOM + 90, 64); poke16(GEOM + 92, 0); poke16(GEOM + 94, 0);
            /* g[6] KEY 16 */ poke32(GEOM + 96, 32'h00201000); poke16(GEOM + 100, 32); poke16(GEOM + 102, 16'hf81f);
            poke16(GEOM + 104, 16); poke16(GEOM + 106, 16); poke16(GEOM + 108, 0); poke16(GEOM + 110, 0);
            /* g[7] KEY 32 */ poke32(GEOM + 112, 32'h00201000); poke16(GEOM + 116, 64); poke16(GEOM + 118, 16'hf81f);
            poke16(GEOM + 120, 32); poke16(GEOM + 122, 32); poke16(GEOM + 124, 0); poke16(GEOM + 126, 0);
            /* g[8] KEY 64 */ poke32(GEOM + 128, 32'h00201000); poke16(GEOM + 132, 128); poke16(GEOM + 134, 16'hf81f);
            poke16(GEOM + 136, 64); poke16(GEOM + 138, 64); poke16(GEOM + 140, 0); poke16(GEOM + 142, 0);
            /* g[9] 铺底 960x260 */ poke32(GEOM + 144, 32'h00000000); poke16(GEOM + 148, 0); poke16(GEOM + 150, 16'h0000);
            poke16(GEOM + 152, 960); poke16(GEOM + 154, 260); poke16(GEOM + 156, 0); poke16(GEOM + 158, 0);
            /* g[10] 铺底 960x524 */ poke32(GEOM + 160, 32'h00000000); poke16(GEOM + 164, 0); poke16(GEOM + 166, 16'h0000);
            poke16(GEOM + 168, 960); poke16(GEOM + 170, 524); poke16(GEOM + 172, 0); poke16(GEOM + 174, 0);
        end
    endtask

    /* 固件 dl_build() 输出：FILL 场景 尺寸 16，4 条描述符（贴边位置） */
    task list_fill16;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00310000);
            poke32(base +   8, 32'h00ff1234); poke32(base +  12, 32'h10100000);
            poke32(base +  16, 32'h000003b0); poke32(base +  20, 32'h00310000);
            poke32(base +  24, 32'h00ff1235); poke32(base +  28, 32'h10100000);
            poke32(base +  32, 32'h00f40000); poke32(base +  36, 32'h00310000);
            poke32(base +  40, 32'h00ff1236); poke32(base +  44, 32'h10100000);
            poke32(base +  48, 32'h00f403b0); poke32(base +  52, 32'h00310000);
            poke32(base +  56, 32'h00ff1237); poke32(base +  60, 32'h10100000);
        end
    endtask
    /* 固件 dl_build() 输出：ALPHA 场景 尺寸 16，4 条描述符（贴边位置） */
    task list_alpha16;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00120003);
            poke32(base +   8, 32'h00800000); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h000003b0); poke32(base +  20, 32'h00120003);
            poke32(base +  24, 32'h00800000); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00f40000); poke32(base +  36, 32'h00120003);
            poke32(base +  40, 32'h00800000); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00f403b0); poke32(base +  52, 32'h00120003);
            poke32(base +  56, 32'h00800000); poke32(base +  60, 32'h00000000);
        end
    endtask
    /* 固件 dl_build() 输出：KEY 场景 尺寸 16，4 条描述符（贴边位置） */
    task list_key16;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00130006);
            poke32(base +   8, 32'h00fff81f); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h000003b0); poke32(base +  20, 32'h00130006);
            poke32(base +  24, 32'h00fff81f); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00f40000); poke32(base +  36, 32'h00130006);
            poke32(base +  40, 32'h00fff81f); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00f403b0); poke32(base +  52, 32'h00130006);
            poke32(base +  56, 32'h00fff81f); poke32(base +  60, 32'h00000000);
        end
    endtask
    /* 固件 dl_build() 输出：FILL 场景 尺寸 32，4 条描述符（贴边位置） */
    task list_fill32;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00310001);
            poke32(base +   8, 32'h00ff1234); poke32(base +  12, 32'h20200000);
            poke32(base +  16, 32'h000003a0); poke32(base +  20, 32'h00310001);
            poke32(base +  24, 32'h00ff1235); poke32(base +  28, 32'h20200000);
            poke32(base +  32, 32'h00e40000); poke32(base +  36, 32'h00310001);
            poke32(base +  40, 32'h00ff1236); poke32(base +  44, 32'h20200000);
            poke32(base +  48, 32'h00e403a0); poke32(base +  52, 32'h00310001);
            poke32(base +  56, 32'h00ff1237); poke32(base +  60, 32'h20200000);
        end
    endtask
    /* 固件 dl_build() 输出：ALPHA 场景 尺寸 32，4 条描述符（贴边位置） */
    task list_alpha32;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00120004);
            poke32(base +   8, 32'h00800000); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h000003a0); poke32(base +  20, 32'h00120004);
            poke32(base +  24, 32'h00800000); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00e40000); poke32(base +  36, 32'h00120004);
            poke32(base +  40, 32'h00800000); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00e403a0); poke32(base +  52, 32'h00120004);
            poke32(base +  56, 32'h00800000); poke32(base +  60, 32'h00000000);
        end
    endtask
    /* 固件 dl_build() 输出：KEY 场景 尺寸 32，4 条描述符（贴边位置） */
    task list_key32;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00130007);
            poke32(base +   8, 32'h00fff81f); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h000003a0); poke32(base +  20, 32'h00130007);
            poke32(base +  24, 32'h00fff81f); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00e40000); poke32(base +  36, 32'h00130007);
            poke32(base +  40, 32'h00fff81f); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00e403a0); poke32(base +  52, 32'h00130007);
            poke32(base +  56, 32'h00fff81f); poke32(base +  60, 32'h00000000);
        end
    endtask
    /* 固件 dl_build() 输出：FILL 场景 尺寸 64，4 条描述符（贴边位置） */
    task list_fill64;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00310002);
            poke32(base +   8, 32'h00ff1234); poke32(base +  12, 32'h40400000);
            poke32(base +  16, 32'h00000380); poke32(base +  20, 32'h00310002);
            poke32(base +  24, 32'h00ff1235); poke32(base +  28, 32'h40400000);
            poke32(base +  32, 32'h00c40000); poke32(base +  36, 32'h00310002);
            poke32(base +  40, 32'h00ff1236); poke32(base +  44, 32'h40400000);
            poke32(base +  48, 32'h00c40380); poke32(base +  52, 32'h00310002);
            poke32(base +  56, 32'h00ff1237); poke32(base +  60, 32'h40400000);
        end
    endtask
    /* 固件 dl_build() 输出：ALPHA 场景 尺寸 64，4 条描述符（贴边位置） */
    task list_alpha64;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00120005);
            poke32(base +   8, 32'h00800000); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h00000380); poke32(base +  20, 32'h00120005);
            poke32(base +  24, 32'h00800000); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00c40000); poke32(base +  36, 32'h00120005);
            poke32(base +  40, 32'h00800000); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00c40380); poke32(base +  52, 32'h00120005);
            poke32(base +  56, 32'h00800000); poke32(base +  60, 32'h00000000);
        end
    endtask
    /* 固件 dl_build() 输出：KEY 场景 尺寸 64，4 条描述符（贴边位置） */
    task list_key64;
        input [31:0] base;
        begin
            poke32(base +   0, 32'h00000000); poke32(base +   4, 32'h00130008);
            poke32(base +   8, 32'h00fff81f); poke32(base +  12, 32'h00000000);
            poke32(base +  16, 32'h00000380); poke32(base +  20, 32'h00130008);
            poke32(base +  24, 32'h00fff81f); poke32(base +  28, 32'h00000000);
            poke32(base +  32, 32'h00c40000); poke32(base +  36, 32'h00130008);
            poke32(base +  40, 32'h00fff81f); poke32(base +  44, 32'h00000000);
            poke32(base +  48, 32'h00c40380); poke32(base +  52, 32'h00130008);
            poke32(base +  56, 32'h00fff81f); poke32(base +  60, 32'h00000000);
        end
    endtask


    /* 金标准参考字扁平表（9 例 × 4 块 × 8 字 = 288 字；★v2.16 新增 6/7/8 = 64x64 三例） */
    reg [31:0] refw [0:287];
    initial begin
        refw[  0]=32'h00000001; refw[  1]=32'h00000000; refw[  2]=32'h00508800; refw[  3]=32'h00000000;
        refw[  4]=32'h00000780; refw[  5]=32'h00100010; refw[  6]=32'h000000ff; refw[  7]=32'h00001234;
        refw[  8]=32'h00000001; refw[  9]=32'h00000000; refw[ 10]=32'h00508f60; refw[ 11]=32'h00000000;
        refw[ 12]=32'h00000780; refw[ 13]=32'h00100010; refw[ 14]=32'h000000ff; refw[ 15]=32'h00001235;
        refw[ 16]=32'h00000001; refw[ 17]=32'h00000000; refw[ 18]=32'h0057ae00; refw[ 19]=32'h00000000;
        refw[ 20]=32'h00000780; refw[ 21]=32'h00100010; refw[ 22]=32'h000000ff; refw[ 23]=32'h00001236;
        refw[ 24]=32'h00000001; refw[ 25]=32'h00000000; refw[ 26]=32'h0057b560; refw[ 27]=32'h00000000;
        refw[ 28]=32'h00000780; refw[ 29]=32'h00100010; refw[ 30]=32'h000000ff; refw[ 31]=32'h00001237;
        refw[ 32]=32'h00000002; refw[ 33]=32'h00201000; refw[ 34]=32'h00508800; refw[ 35]=32'h00000020;
        refw[ 36]=32'h00000780; refw[ 37]=32'h00100010; refw[ 38]=32'h00000080; refw[ 39]=32'h00000000;
        refw[ 40]=32'h00000002; refw[ 41]=32'h00201000; refw[ 42]=32'h00508f60; refw[ 43]=32'h00000020;
        refw[ 44]=32'h00000780; refw[ 45]=32'h00100010; refw[ 46]=32'h00000080; refw[ 47]=32'h00000000;
        refw[ 48]=32'h00000002; refw[ 49]=32'h00201000; refw[ 50]=32'h0057ae00; refw[ 51]=32'h00000020;
        refw[ 52]=32'h00000780; refw[ 53]=32'h00100010; refw[ 54]=32'h00000080; refw[ 55]=32'h00000000;
        refw[ 56]=32'h00000002; refw[ 57]=32'h00201000; refw[ 58]=32'h0057b560; refw[ 59]=32'h00000020;
        refw[ 60]=32'h00000780; refw[ 61]=32'h00100010; refw[ 62]=32'h00000080; refw[ 63]=32'h00000000;
        refw[ 64]=32'h00000003; refw[ 65]=32'h00201000; refw[ 66]=32'h00508800; refw[ 67]=32'h00000020;
        refw[ 68]=32'h00000780; refw[ 69]=32'h00100010; refw[ 70]=32'h000000ff; refw[ 71]=32'h0000f81f;
        refw[ 72]=32'h00000003; refw[ 73]=32'h00201000; refw[ 74]=32'h00508f60; refw[ 75]=32'h00000020;
        refw[ 76]=32'h00000780; refw[ 77]=32'h00100010; refw[ 78]=32'h000000ff; refw[ 79]=32'h0000f81f;
        refw[ 80]=32'h00000003; refw[ 81]=32'h00201000; refw[ 82]=32'h0057ae00; refw[ 83]=32'h00000020;
        refw[ 84]=32'h00000780; refw[ 85]=32'h00100010; refw[ 86]=32'h000000ff; refw[ 87]=32'h0000f81f;
        refw[ 88]=32'h00000003; refw[ 89]=32'h00201000; refw[ 90]=32'h0057b560; refw[ 91]=32'h00000020;
        refw[ 92]=32'h00000780; refw[ 93]=32'h00100010; refw[ 94]=32'h000000ff; refw[ 95]=32'h0000f81f;
        refw[ 96]=32'h00000001; refw[ 97]=32'h00000000; refw[ 98]=32'h00508800; refw[ 99]=32'h00000000;
        refw[100]=32'h00000780; refw[101]=32'h00200020; refw[102]=32'h000000ff; refw[103]=32'h00001234;
        refw[104]=32'h00000001; refw[105]=32'h00000000; refw[106]=32'h00508f40; refw[107]=32'h00000000;
        refw[108]=32'h00000780; refw[109]=32'h00200020; refw[110]=32'h000000ff; refw[111]=32'h00001235;
        refw[112]=32'h00000001; refw[113]=32'h00000000; refw[114]=32'h00573600; refw[115]=32'h00000000;
        refw[116]=32'h00000780; refw[117]=32'h00200020; refw[118]=32'h000000ff; refw[119]=32'h00001236;
        refw[120]=32'h00000001; refw[121]=32'h00000000; refw[122]=32'h00573d40; refw[123]=32'h00000000;
        refw[124]=32'h00000780; refw[125]=32'h00200020; refw[126]=32'h000000ff; refw[127]=32'h00001237;
        refw[128]=32'h00000002; refw[129]=32'h00201000; refw[130]=32'h00508800; refw[131]=32'h00000040;
        refw[132]=32'h00000780; refw[133]=32'h00200020; refw[134]=32'h00000080; refw[135]=32'h00000000;
        refw[136]=32'h00000002; refw[137]=32'h00201000; refw[138]=32'h00508f40; refw[139]=32'h00000040;
        refw[140]=32'h00000780; refw[141]=32'h00200020; refw[142]=32'h00000080; refw[143]=32'h00000000;
        refw[144]=32'h00000002; refw[145]=32'h00201000; refw[146]=32'h00573600; refw[147]=32'h00000040;
        refw[148]=32'h00000780; refw[149]=32'h00200020; refw[150]=32'h00000080; refw[151]=32'h00000000;
        refw[152]=32'h00000002; refw[153]=32'h00201000; refw[154]=32'h00573d40; refw[155]=32'h00000040;
        refw[156]=32'h00000780; refw[157]=32'h00200020; refw[158]=32'h00000080; refw[159]=32'h00000000;
        refw[160]=32'h00000003; refw[161]=32'h00201000; refw[162]=32'h00508800; refw[163]=32'h00000040;
        refw[164]=32'h00000780; refw[165]=32'h00200020; refw[166]=32'h000000ff; refw[167]=32'h0000f81f;
        refw[168]=32'h00000003; refw[169]=32'h00201000; refw[170]=32'h00508f40; refw[171]=32'h00000040;
        refw[172]=32'h00000780; refw[173]=32'h00200020; refw[174]=32'h000000ff; refw[175]=32'h0000f81f;
        refw[176]=32'h00000003; refw[177]=32'h00201000; refw[178]=32'h00573600; refw[179]=32'h00000040;
        refw[180]=32'h00000780; refw[181]=32'h00200020; refw[182]=32'h000000ff; refw[183]=32'h0000f81f;
        refw[184]=32'h00000003; refw[185]=32'h00201000; refw[186]=32'h00573d40; refw[187]=32'h00000040;
        refw[188]=32'h00000780; refw[189]=32'h00200020; refw[190]=32'h000000ff; refw[191]=32'h0000f81f;
        /* ---- ★v2.16 新增：64x64（FILL/ALPHA/KEY，贴边位置：x∈{0,896}、y∈{0,196}）---- */
        refw[192]=32'h00000001; refw[193]=32'h00000000; refw[194]=32'h00508800; refw[195]=32'h00000000;
        refw[196]=32'h00000780; refw[197]=32'h00400040; refw[198]=32'h000000FF; refw[199]=32'h00001234;
        refw[200]=32'h00000001; refw[201]=32'h00000000; refw[202]=32'h00508F00; refw[203]=32'h00000000;
        refw[204]=32'h00000780; refw[205]=32'h00400040; refw[206]=32'h000000FF; refw[207]=32'h00001235;
        refw[208]=32'h00000001; refw[209]=32'h00000000; refw[210]=32'h00564600; refw[211]=32'h00000000;
        refw[212]=32'h00000780; refw[213]=32'h00400040; refw[214]=32'h000000FF; refw[215]=32'h00001236;
        refw[216]=32'h00000001; refw[217]=32'h00000000; refw[218]=32'h00564D00; refw[219]=32'h00000000;
        refw[220]=32'h00000780; refw[221]=32'h00400040; refw[222]=32'h000000FF; refw[223]=32'h00001237;
        refw[224]=32'h00000002; refw[225]=32'h00201000; refw[226]=32'h00508800; refw[227]=32'h00000080;
        refw[228]=32'h00000780; refw[229]=32'h00400040; refw[230]=32'h00000080; refw[231]=32'h00000000;
        refw[232]=32'h00000002; refw[233]=32'h00201000; refw[234]=32'h00508F00; refw[235]=32'h00000080;
        refw[236]=32'h00000780; refw[237]=32'h00400040; refw[238]=32'h00000080; refw[239]=32'h00000000;
        refw[240]=32'h00000002; refw[241]=32'h00201000; refw[242]=32'h00564600; refw[243]=32'h00000080;
        refw[244]=32'h00000780; refw[245]=32'h00400040; refw[246]=32'h00000080; refw[247]=32'h00000000;
        refw[248]=32'h00000002; refw[249]=32'h00201000; refw[250]=32'h00564D00; refw[251]=32'h00000080;
        refw[252]=32'h00000780; refw[253]=32'h00400040; refw[254]=32'h00000080; refw[255]=32'h00000000;
        refw[256]=32'h00000003; refw[257]=32'h00201000; refw[258]=32'h00508800; refw[259]=32'h00000080;
        refw[260]=32'h00000780; refw[261]=32'h00400040; refw[262]=32'h000000FF; refw[263]=32'h0000F81F;
        refw[264]=32'h00000003; refw[265]=32'h00201000; refw[266]=32'h00508F00; refw[267]=32'h00000080;
        refw[268]=32'h00000780; refw[269]=32'h00400040; refw[270]=32'h000000FF; refw[271]=32'h0000F81F;
        refw[272]=32'h00000003; refw[273]=32'h00201000; refw[274]=32'h00564600; refw[275]=32'h00000080;
        refw[276]=32'h00000780; refw[277]=32'h00400040; refw[278]=32'h000000FF; refw[279]=32'h0000F81F;
        refw[280]=32'h00000003; refw[281]=32'h00201000; refw[282]=32'h00564D00; refw[283]=32'h00000080;
        refw[284]=32'h00000780; refw[285]=32'h00400040; refw[286]=32'h000000FF; refw[287]=32'h0000F81F;
    end


    /* ================= 主流程 ================= */
    integer i, rv;
    reg [7:0]  gold [0:CMP_BYTES-1];
    integer mism, case_idx, case_base, total_mism, run_no;
    integer kk;

    /* 逐条下发路径（金标准）：把 refw 里本例的 4×8 字**按固件的下发顺序**写进 cmd_fifo */
    task push_ref;
        begin
            for (kk = 0; kk < 32; kk = kk + 1) axi_write(12'h08, refw[case_base + kk]);
        end
    endtask

    /* 固件 blt_init()：CTRL.GO 一直开着（与逐条路径同一前提） */
    task eng_init;
        begin
            axi_write(12'h00, 32'h4);
            axi_write(12'h00, 32'h0);
            axi_write(12'h10, 32'hFFFFFFFF);
            axi_write(12'h14, 32'h0);
            axi_write(12'h00, 32'h1);
        end
    endtask

    task wait_eng_idle;
        begin : weil
            for (i = 0; i < 4000000; i = i + 1) begin
                axi_read(12'h04, rv);
                if ((rv & 32'h2) && (rv & 32'h8) && !(rv & 32'h4)) disable weil;  // DONE && FIFO_EMPTY && !ERR
                if (rv & 32'h4) begin
                    $display("FAIL: 引擎 ERR（STATUS=0x%h）", rv);
                    errors = errors + 1; disable weil;
                end
            end
            $display("FAIL: 引擎 DONE 超时（STATUS=0x%h）", rv);
            errors = errors + 1;
        end
    endtask

    /* DUT 硬复位：把 DFU（含 16 条几何表 cache）彻底清干净 —— 复现"上电后第一次读
     * 几何表"这个唯一会踩到 DDR 内容的时刻（cache 命中会掩盖 DDR 里的错误内容）。 */
    task dut_reset;
        begin
            rst_n = 1'b0;
            #60;
            rst_n = 1'b1;
            #200;
            eng_init();
        end
    endtask
    task dl_wait_idle;                 /* 等 DFU 落 BUSY（错误后必须等它收尾） */
        begin : dwi
            for (i = 0; i < 4000000; i = i + 1) begin
                axi_read(12'h5C, rv);
                if (!(rv & 32'h1)) disable dwi;
            end
            $display("FAIL: 等 DFU 落 BUSY 超时（DL_STATUS=0x%h）", rv);
            errors = errors + 1;
        end
    endtask
    task dl_wait_err;                  /* 预期出错：等 ERR 锁存（或 DONE） */
        begin : dwe
            for (i = 0; i < 4000000; i = i + 1) begin
                axi_read(12'h5C, rv);
                if ((rv & 32'h4) || ((rv & 32'h2) && !(rv & 32'h1))) disable dwe;
            end
            $display("FAIL: 等 DL 结果超时（DL_STATUS=0x%h）", rv);
            errors = errors + 1;
        end
    endtask
    task dl_arm_regs_gm0;              /* 同 dl_arm_regs，但 GEOM_MAX 写 0（模拟"写被丢"） */
        begin
            axi_write(12'h68, GEOM);
            axi_write(12'h6C, 32'd0);
            axi_write(12'h84, FB_STRIDE);
            axi_write(12'h88, (FB_H << 16) | FB_W);
            axi_write(12'h4C, LIST0);
            axi_write(12'h50, LIST1);
            axi_write(12'h60, 32'h0100_00FF);
            axi_write(12'h58, 32'h30);
        end
    endtask

    task fb_bg;                      // 渲染区铺成同一份确定性背景（与 tb_dl_basic 同风格）
        integer r, c;
        begin
            for (r = TOP_Y0; r < FB_H; r = r + 1)
                for (c = 0; c < FB_W; c = c + 1)
                    poke16(FB_BACK + r*FB_STRIDE + c*2, 16'h1000 + ((r*7 + c*13) & 16'h03FF));
        end
    endtask

    task fb_snap;
        integer a;
        begin
            for (a = 0; a < CMP_BYTES; a = a + 1) gold[a] = u_mem.mem[DST_BASE + a];
        end
    endtask

    task fb_cmp;
        begin
            mism = 0;
            for (i = 0; i < CMP_BYTES; i = i + 1)
                if (u_mem.mem[DST_BASE + i] !== gold[i]) begin
                    if (mism < 4)
                        $display("      MISMATCH off=%0d (x=%0d y=%0d) got=%02h exp=%02h",
                                 i, (i % 1920) / 2, TOP_Y0 + i / 1920,
                                 u_mem.mem[DST_BASE + i], gold[i]);
                    mism = mism + 1;
                end
        end
    endtask

    /* 固件 dl_arm() + dl_go() 的寄存器序列（顺序一字不改） */
    task dl_arm_regs;
        begin
            axi_write(12'h68, GEOM);            // DL_GEOM_BASE
            axi_write(12'h6C, DL_GEOM_MAX);     // DL_GEOM_MAX（固件 DL_GEOM_N = 11）
            axi_write(12'h84, FB_STRIDE);       // DL_DST_STRIDE
            axi_write(12'h88, (FB_H << 16) | FB_W);
            axi_write(12'h4C, LIST0);           // DL_BASE0
            axi_write(12'h50, LIST1);           // DL_BASE1
            axi_write(12'h60, 32'h0100_00FF);   // DL_ERR W1C
            axi_write(12'h58, 32'h30);          // AUTO_GO | STRICT
        end
    endtask
    /* bsel=1 时选 LIST1（固件首张表的 BUF_SEL 就是 1：b = 1 - g_dl_buf，g_dl_buf=0） */
    task dl_go;
        input integer bsel;
        input [31:0] cnt;
        begin
            axi_write(12'h70, DST_BASE);        // DL_DST_BASE
            axi_write(12'h54, cnt);             // DL_COUNT
            axi_write(12'h58, bsel ? 32'h35 : 32'h31);
        end
    endtask
    reg [31:0] dl_err, dl_fa;
    task dl_wait_done;
        input integer cnt_expect;
        begin : dwd
            for (i = 0; i < 4000000; i = i + 1) begin
                axi_read(12'h5C, rv);
                if (rv & 32'h4) begin
                    axi_read(12'h60, dl_err); axi_read(12'h64, dl_fa);
                    $display("FAIL: 列表路径报错 DL_STATUS=0x%h DL_ERR=0x%h FAULT=0x%h",
                             rv, dl_err, dl_fa);
                    errors = errors + 1;
                    disable dwd;
                end
                if ((rv & 32'h2) && !(rv & 32'h1)) begin     // DONE && !BUSY
                    chk(rv[31:16] === cnt_expect[15:0], "CONSUMED == 描述符条数");
                    disable dwd;
                end
            end
            $display("FAIL: 列表 DONE 超时（DL_STATUS=0x%h）", rv);
            errors = errors + 1;
        end
    endtask

    task cmp_cmds;                 // 捕获到的 8 字命令 vs 金标准
        input integer nblk;
        begin
            for (i = 0; i < nblk * 8; i = i + 1)
                if (capw[i] !== refw[case_base + i]) begin
                    $display("      CMD MISMATCH blk%0d w%0d got=%08x exp=%08x",
                             i/8, i%8, capw[i], refw[case_base + i]);
                    errors = errors + 1;
                end
            chk(cap_n === nblk * 8, "DFU 展开的命令条数 == 逐条路径（8 字/块，无多无少）");
        end
    endtask

    task poke_list;
        input [31:0] base;
        begin
            case (case_idx)
                0: list_fill16(base);
                1: list_alpha16(base);
                2: list_key16(base);
                3: list_fill32(base);
                4: list_alpha32(base);
                5: list_key32(base);
                6: list_fill64(base);
                7: list_alpha64(base);
                8: list_key64(base);
            endcase
        end
    endtask

    task atlas_for_case;
        begin
            case (case_idx)
                0: atlas_init(16);
                1: atlas_init(16);
                2: atlas_init(16);
                3: atlas_init(32);
                4: atlas_init(32);
                5: atlas_init(32);
                6: atlas_init(64);
                7: atlas_init(64);
                8: atlas_init(64);
            endcase
        end
    endtask

    task run_case;
        input integer desc_cnt;
        begin
            run_no = 0;
            fb_bg();
            cap_en = 0; cap_n = 0;
            push_ref;
            wait_eng_idle;
            fb_snap();

            run_no = 1;                              // 首张表：BUF_SEL=1 → LIST1
            fb_bg();
            atlas_for_case();
            poke_list(LIST1);
            cap_n = 0; cap_en = 1;
            dl_arm_regs(); dl_go(1, desc_cnt); dl_wait_done(desc_cnt); cap_en = 0;
            cmp_cmds(4);
            fb_cmp();
            chk(mism == 0, "★列表路径(BUF1)与逐条路径像素逐字节相同（渲染区 1,006,080 字节）");
            total_mism = total_mism + mism;

            run_no = 2;                              // 乒乓第二张：BUF_SEL=0 → LIST0
            fb_bg();
            poke_list(LIST0);
            cap_n = 0; cap_en = 1;
            dl_go(0, desc_cnt); dl_wait_done(desc_cnt); cap_en = 0;
            cmp_cmds(4);
            fb_cmp();
            chk(mism == 0, "★列表路径(BUF0 乒乓)与逐条路径像素逐字节相同");
            total_mism = total_mism + mism;
        end
    endtask

    initial begin
        errors = 0; total_mism = 0;
        #20 rst_n = 1'b1;
        #200;

        geom_init();
        eng_init();

        $display("==== 1) 固件描述符进真实 RTL：9 例（FILL/ALPHA/KEY x 16/32/64，含贴边位置，%0d 条几何表条目） ====",
                 DL_GEOM_MAX);
        case_idx = 0; case_base = 0;   run_case(4);
        case_idx = 1; case_base = 32;  run_case(4);
        case_idx = 2; case_base = 64;  run_case(4);
        case_idx = 3; case_base = 96;  run_case(4);
        case_idx = 4; case_base = 128; run_case(4);
        case_idx = 5; case_base = 160; run_case(4);
        case_idx = 6; case_base = 192; run_case(4);
        case_idx = 7; case_base = 224; run_case(4);
        case_idx = 8; case_base = 256; run_case(4);

        $display("==== 2) 整片重铺（W=960 必须走几何表，SPR_ID=9） ====");
        fb_bg();
        cap_en = 0; cap_n = 0;
        axi_write(12'h08, 32'h00000001); axi_write(12'h08, 32'h00000000);
        axi_write(12'h08, 32'h00508800); axi_write(12'h08, 32'h00000000);
        axi_write(12'h08, 32'h00000780); axi_write(12'h08, 32'h010403c0);
        axi_write(12'h08, 32'h000000ff); axi_write(12'h08, 32'h00000008);
        wait_eng_idle;
        fb_snap();
        fb_bg();
        poke32(LIST1 +  0, 32'h00000000); poke32(LIST1 +  4, 32'h00110009);
        poke32(LIST1 +  8, 32'h00ff0008); poke32(LIST1 + 12, 32'h00000000);
        cap_n = 0; cap_en = 1;
        dl_arm_regs(); dl_go(1, 1); dl_wait_done(1); cap_en = 0;
        chk(capw[0] === 32'h00000001 && capw[2] === 32'h00508800 && capw[5] === 32'h010403c0
            && capw[7] === 32'h00000008, "重铺描述符展开 = blt_fill(960x260) 的 8 字");
        fb_cmp();
        chk(mism == 0, "★重铺（几何表 W=960）与逐条 FILL 像素相同");
        total_mism = total_mism + mism;

        $display("==== 3) 复现失败签名 A：几何表内容为 0（写丢了/读成 0） ====");
        /* 板上症状（场景 2/3 打不开列表模式）的两个签名之一：精灵描述符读到的几何
         * 是全 0。★ 必须先硬复位把几何 cache 清掉 —— cache 命中会掩盖 DDR 里的内容。 */
        begin : gz
            integer a;
            dut_reset();
            geom_init();
            for (a = 0; a < DL_GEOM_MAX * 16; a = a + 1) u_mem.mem[GEOM + a] = 8'h00;
            fb_bg();
            list_alpha16(LIST1);
            fb_snap();                       // 金标准 = 什么都没画（背景原样）
            cap_n = 0; cap_en = 1;
            dl_arm_regs(); dl_go(1, 4);
            dl_wait_err;
            cap_en = 0;
            axi_read(12'h5C, rv);
            axi_read(12'h60, dl_err);
            $display("      几何表全 0（冷 cache）：DL_STATUS=0x%h DL_ERR=0x%h 展开命令字数=%0d",
                     rv, dl_err, cap_n);
            chk((rv & 32'h4) !== 0,   "几何表全 0 ⇒ DFU 报 DL_ERR（不会静默跑完）");
            chk((dl_err & 32'hFF) === 32'h80, "几何表全 0 ⇒ DL_ERR 低位 = 0x80 ZERO_SIZE");
            chk(cap_n === 0,          "几何表全 0 ⇒ 一个字都没展开（一个像素都没画）");
            fb_cmp();
            chk(mism == 0,            "几何表全 0 ⇒ 渲染区一个字节都没变（画面冻结）");
            dl_wait_idle();
            axi_write(12'h60, 32'h0100_00FF);
        end

        $display("==== 4) 复现失败签名 B：DL_GEOM_MAX 写被丢（=0） ====");
        /* RTL 在 DFU BUSY 时忽略 0x4C~0x88 的写入（blt_regs_axi_lite.v）⇒ GEOM_MAX 若被丢，
         * 规则"GEOM_MAX=0 时只允许 FILL+SIZE_OVR，否则 GEOM_INDEX"（设计文档 §8.1 /
         * 功能清单 §25）⇒ 精灵条目一律 GEOM_INDEX，而场景 1 的 FILL+SIZE_OVR 一条不受影响。 */
        begin : gm
            geom_init();
            list_alpha16(LIST1);
            cap_n = 0; cap_en = 1;
            dl_arm_regs_gm0();               // ★ GEOM_MAX = 0
            dl_go(1, 4);
            dl_wait_err;
            cap_en = 0;
            axi_read(12'h5C, rv);
            axi_read(12'h60, dl_err);
            $display("      GEOM_MAX=0：DL_STATUS=0x%h DL_ERR=0x%h（0x2 = GEOM_INDEX）", rv, dl_err);
            chk((rv & 32'h4) !== 0,          "GEOM_MAX=0 ⇒ 精灵条目报 DL_ERR（场景 2/3 打不开）");
            chk((dl_err & 32'hFF) === 32'h2, "GEOM_MAX=0 ⇒ DL_ERR 低位 = 0x2 GEOM_INDEX");
            chk(cap_n === 0,                 "GEOM_MAX=0 ⇒ 精灵表一条命令都没展开");
            /* 让 DFU 收尾并清掉锁存的错误，再做对照 */
            dl_wait_idle();
            axi_write(12'h60, 32'h0100_00FF);
            /* 对照：同一条规则下 FILL+SIZE_OVR（场景 1）不受影响 */
            list_fill16(LIST1);
            cap_n = 0; cap_en = 1;
            dl_go(1, 4);
            dl_wait_done(4);
            cap_en = 0;
            axi_read(12'h5C, rv);
            $display("      GEOM_MAX=0 + FILL+SIZE_OVR（场景 1）：DL_STATUS=0x%h 展开命令字数=%0d",
                     rv, cap_n);
            chk((rv & 32'h4) === 0,          "GEOM_MAX=0 时 FILL+SIZE_OVR 依旧无错（场景 1 正常）");
            chk(cap_n === 4 * 8,             "GEOM_MAX=0 时 FILL 条目照常展开 4×8 字");
        end

        if (errors == 0) $display("========== tb_dl_demo ALL PASS（累计不一致字节 %0d） ==========", total_mism);
        else             $display("========== tb_dl_demo FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #400_000_000;
        $display("!!!!!!!! tb_dl_demo WATCHDOG TIMEOUT !!!!!!!!");
        $finish;
    end
endmodule

