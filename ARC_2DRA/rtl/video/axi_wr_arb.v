/* =========================================================================
 * axi_wr_arb.v — AXI4 写通道 2 选 1 仲裁（CPU 与 BitBlt 引擎共享 DDR 写口）
 * -------------------------------------------------------------------------
 * ★ 设计原则（上板教训，务必保持）：
 *   1) **CPU 侧完全直通**：引擎不用写口时，CPU 的 AW/W/B 就是一根直连线，
 *      与"CPU 直连 DDR"逐字节等价 —— 这是板子能启动的前提。
 *      上一版为了"受理权归仲裁器"加了 1 深 skid，结果板子起不来（22:16 那次），
 *      旁路掉 skid（CPU 直连）后立刻启动（22:27 串口日志 [1]~[4] 全 PASS）。
 *   2) **切换只发生在"两侧都没有在飞写突发"时**：owner 同一时刻只给一侧，
 *      AW/W/B 全按 owner 分路，绝不错路。
 *   3) **强制让位那一路必须排除"本拍真的握手"**（`!c_aw_hs` / `!b_aw_hs`）。
 *      老版就是漏了这条：让位与 CPU 的 AW 握手同拍发生 → DDR 收下了这笔 AW
 *      （已计入在飞），owner 却同时切走 → 该笔的 B/W 全归另一侧 →
 *      计数泄漏 + 内存写花 + 引擎永远等不到 B（上板表现为 BUSY 不退）。
 *      注意这一条**不需要 skid 也能成立**：只要握手这一拍不切换，计数与 DDR
 *      恒等，就不存在"已受理未计入"。
 * ========================================================================= */
`timescale 1ns/1ps
module axi_wr_arb #(
    parameter AW  = 28,
    parameter DW  = 128,
    parameter IDW = 4,
    /* 一侧连续等待超过这么多拍 → 强制让位一笔（有界公平，两侧都不被饿死）。
     * 强制让位同样带"本拍不握手"的门限。 */
    parameter [7:0] WAIT_MAX = 8'd32
)(
    input  wire            clk,
    input  wire            rst_n,

    /* ---- CPU（SoC 的外存写口） ---- */
    input  wire [AW-1:0]   c_awaddr,
    input  wire [7:0]      c_awlen,
    input  wire [2:0]      c_awsize,
    input  wire [1:0]      c_awburst,
    input  wire [IDW-1:0]  c_awid,
    input  wire            c_awvalid,
    output wire            c_awready,
    input  wire [DW-1:0]   c_wdata,
    input  wire [DW/8-1:0] c_wstrb,
    input  wire            c_wlast,
    input  wire            c_wvalid,
    output wire            c_wready,
    output wire            c_bvalid,
    output wire [1:0]      c_bresp,
    output wire [IDW-1:0]  c_bid,
    input  wire            c_bready,

    /* ---- BitBlt 引擎写通道 ---- */
    input  wire [AW-1:0]   b_awaddr,
    input  wire [7:0]      b_awlen,
    input  wire [2:0]      b_awsize,
    input  wire [1:0]      b_awburst,
    input  wire            b_awvalid,
    output wire            b_awready,
    input  wire [DW-1:0]   b_wdata,
    input  wire [DW/8-1:0] b_wstrb,
    input  wire            b_wlast,
    input  wire            b_wvalid,
    output wire            b_wready,
    output wire            b_bvalid,
    output wire [1:0]      b_bresp,
    input  wire            b_bready,

    /* ---- DDR 控制器 AXI 从口（写） ---- */
    output wire [AW-1:0]   m_awaddr,
    output wire [7:0]      m_awlen,
    output wire [2:0]      m_awsize,
    output wire [1:0]      m_awburst,
    output wire [IDW-1:0]  m_awid,
    output wire            m_awvalid,
    input  wire            m_awready,
    output wire [DW-1:0]   m_wdata,
    output wire [DW/8-1:0] m_wstrb,
    output wire            m_wlast,
    output wire            m_wvalid,
    input  wire            m_wready,
    input  wire            m_bvalid,
    input  wire [1:0]      m_bresp,
    input  wire [IDW-1:0]  m_bid,
    output wire            m_bready
);
    reg        owner;            // 0 = CPU（默认/直通），1 = BitBlt
    reg [7:0]  cnt_c;            // CPU 已送给 DDR、还没收到 B 的写突发数
    reg [7:0]  cnt_b;            // 引擎已送给 DDR、还没收到 B 的写突发数
    reg [7:0]  wait_b;           // 引擎连续等待拍数
    reg [7:0]  wait_c;           // CPU 连续等待拍数（引擎霸占时）

    /* 只统计"DDR 真正受理"的那一拍：m_aw_hs 与 owner 决定的归属恒等 */
    wire c_aw_hs = c_awvalid && c_awready;
    wire b_aw_hs = b_awvalid && b_awready;
    wire c_b_hs  = c_bvalid  && c_bready;
    wire b_b_hs  = b_bvalid  && b_bready;

    /* ---- 直通路由（无 skid） ---- */
    assign c_awready = (owner == 1'b0) ? m_awready : 1'b0;
    assign b_awready = (owner == 1'b1) ? m_awready : 1'b0;
    assign c_wready  = (owner == 1'b0) ? m_wready  : 1'b0;
    assign b_wready  = (owner == 1'b1) ? m_wready  : 1'b0;

    assign m_awaddr  = owner ? b_awaddr  : c_awaddr;
    assign m_awlen   = owner ? b_awlen   : c_awlen;
    assign m_awsize  = owner ? b_awsize  : c_awsize;
    assign m_awburst = owner ? b_awburst : c_awburst;
    assign m_awid    = owner ? {IDW{1'b0}} : c_awid;
    assign m_awvalid = owner ? b_awvalid : c_awvalid;

    assign m_wdata   = owner ? b_wdata  : c_wdata;
    assign m_wstrb   = owner ? b_wstrb  : c_wstrb;
    assign m_wlast   = owner ? b_wlast  : c_wlast;
    assign m_wvalid  = owner ? b_wvalid : c_wvalid;

    assign c_bvalid  = m_bvalid && (owner == 1'b0);
    assign b_bvalid  = m_bvalid && (owner == 1'b1);
    assign m_bready  = owner ? b_bready : c_bready;
    assign c_bresp   = m_bresp;
    assign b_bresp   = m_bresp;
    assign c_bid     = m_bid;

    /* ---- 让位判定 ----
     * CPU→引擎：
     *   · 软让位：CPU 完全没有在飞/在发/在请求 → 引擎可用；
     *   · 硬让位：引擎等够 WAIT_MAX 拍 → 允许 CPU 有一条**还没被受理**的 AW，
     *     但这一拍**绝不抢握手**（`!c_aw_hs`）—— 这是老版踩过的坑。 */
    wire c_idle   = (cnt_c == 8'd0) && !c_wvalid;
    wire yield_b  = (owner == 1'b0) && c_idle && b_awvalid &&
                    ((!c_awvalid) || ((wait_b >= WAIT_MAX) && !c_aw_hs));
    /* 引擎→CPU：引擎写突发全部收完 B、且不是本拍刚握手，就交还 CPU */
    wire b_idle   = (cnt_b == 8'd0) && !b_wvalid;
    wire yield_c  = (owner == 1'b1) && b_idle && !b_aw_hs &&
                    ((!b_awvalid) || (wait_c >= WAIT_MAX));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            owner  <= 1'b0;
            cnt_c  <= 8'd0;
            cnt_b  <= 8'd0;
            wait_b <= 8'd0;
            wait_c <= 8'd0;
        end else begin
            cnt_c <= cnt_c + (c_aw_hs ? 8'd1 : 8'd0) - (c_b_hs ? 8'd1 : 8'd0);
            cnt_b <= cnt_b + (b_aw_hs ? 8'd1 : 8'd0) - (b_b_hs ? 8'd1 : 8'd0);

            if (owner == 1'b0) begin
                if (b_awvalid) begin
                    if (wait_b != 8'hFF) wait_b <= wait_b + 8'd1;
                end else
                    wait_b <= 8'd0;
                wait_c <= 8'd0;
                if (yield_b) begin
                    owner  <= 1'b1;
                    wait_b <= 8'd0;
                end
            end else begin
                if (c_awvalid || c_wvalid) begin
                    if (wait_c != 8'hFF) wait_c <= wait_c + 8'd1;
                end else
                    wait_c <= 8'd0;
                wait_b <= 8'd0;
                if (yield_c) begin
                    owner  <= 1'b0;
                    wait_c <= 8'd0;
                end
            end
        end
    end
endmodule
