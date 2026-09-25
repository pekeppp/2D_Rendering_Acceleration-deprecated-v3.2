/* =========================================================================
 * blt_apb_top.v — BitBlt 加速器的"APB 外设"顶层（对接 Sapphire SoC APB slave 0）
 * -------------------------------------------------------------------------
 * 作用：把 blt_top 的 AXI-Lite 寄存器接口桥到 SoC 的 APB3 从口上，使软核侧
 *       可以用普通的 `*(volatile uint32_t*)(BLT_BASE + off)` 读写寄存器。
 *
 *   SoC io_apbSlave_0 (0xF8100000, 64KB)          blt_top
 *        PADDR/PSEL/PENABLE/PWRITE/PWDATA  ──┐
 *        PRDATA/PREADY/PSLVERROR           ──┤  APB→AXI-Lite 桥（本文件）
 *                                            └─→ s_axil_* ─→ 寄存器组/指令FIFO/引擎
 *   加速器的 AXI4 主机（读+写）由本模块直接引出，接到 DDR 控制器（经仲裁器）。
 *
 * APB 时序实现要点：
 *   - 访问阶段（PSEL && PENABLE && !PREADY）启动一次 AXI-Lite 事务；
 *   - 写：AW 与 W 同时发出（寄存器组的写口在有 AW+W 时生效），等 B 后拉 PREADY；
 *   - 读：AR → 等 R → 把 RDATA 锁存到 PRDATA 再拉 PREADY；
 *   - PREADY 只拉 1 拍；APB 协议保证两次传输之间至少有一个空闲周期。
 *   - 指令 FIFO 满时寄存器组会把 awready/wready 拉低（背压），桥自然等待，
 *     因此 APB 会插入等待周期，不会丢字。
 * ========================================================================= */
module blt_apb_top #(
    parameter AXI_DATA_W = 128,
    parameter CMD_DEPTH  = 256
)(
    input  wire                    clk,
    input  wire                    reset,        // 高有效（与 vendor apb3_top 一致）

    /* ---------------- APB3 从口 ---------------- */
    input  wire [31:0]             apb_paddr,
    input  wire [0:0]              apb_psel,
    input  wire                    apb_penable,
    output wire                    apb_pready,
    input  wire                    apb_pwrite,
    input  wire [31:0]             apb_pwdata,
    output wire [31:0]             apb_prdata,
    output wire                    apb_pslverror,

    output wire                    irq_done,

    /* ---------------- AXI4 主机：读（源/背景搬运） ---------------- */
    output wire [31:0]             m_axi_araddr,
    output wire [7:0]              m_axi_arlen,
    output wire [2:0]              m_axi_arsize,
    output wire [1:0]              m_axi_arburst,
    output wire                    m_axi_arvalid,
    input  wire                    m_axi_arready,
    input  wire [AXI_DATA_W-1:0]   m_axi_rdata,
    input  wire [1:0]              m_axi_rresp,
    input  wire                    m_axi_rlast,
    input  wire                    m_axi_rvalid,
    output wire                    m_axi_rready,

    /* ---------------- AXI4 主机：写（回写目的） ---------------- */
    output wire [31:0]             m_axi_awaddr,
    output wire [7:0]              m_axi_awlen,
    output wire [2:0]              m_axi_awsize,
    output wire [1:0]              m_axi_awburst,
    output wire                    m_axi_awvalid,
    input  wire                    m_axi_awready,
    output wire [AXI_DATA_W-1:0]   m_axi_wdata,
    output wire [AXI_DATA_W/8-1:0] m_axi_wstrb,
    output wire                    m_axi_wlast,
    output wire                    m_axi_wvalid,
    input  wire                    m_axi_wready,
    input  wire                    m_axi_bvalid,
    input  wire [1:0]              m_axi_bresp,
    output wire                    m_axi_bready,

    /* 扫描输出健康度（只读诊断，来自 fb_scanout） */
    input  wire [15:0]             scan_underrun,
    input  wire [15:0]             scan_abort,

    /* ★ 显示缓冲翻转（FLIP）↔ fb_scanout：由 ddr3_example_top 直连，
     *   寄存器 0x24 FB_SEL（写请求）/ 0x28 FB_STAT（已生效选择 + 场计数）。
     *   ★v2.7：选择位 1 bit → 2 bit（三缓冲）；新增 frame_pulse（帧边界脉冲）。 */
    output wire [1:0]              fb_sel,
    input  wire [1:0]              fb_cur_sel,
    input  wire [15:0]             fb_frame_cnt,
    input  wire                    frame_pulse,

    /* ★S5（v3.2）扫描输出颜色 LUT（寄存器 0xA4~0xB0）↔ fb_scanout：
     *   写口（0xA8）/ bank 请求（0xAC）由加速器寄存器组给出，已生效 bank（0xB0）
     *   从 fb_scanout 回来；同样由 ddr3_example_top 直连。 */
    output wire                    lut_wr,
    output wire [1:0]              lut_ch,
    output wire [7:0]              lut_idx,
    output wire [7:0]              lut_data,
    output wire                    lut_en,
    output wire                    lut_bank_req,
    input  wire                    lut_bank_act
);
    /* ---------------- APB ↔ AXI-Lite 桥 ----------------
     * 每个事务都有**独立的响应相位**（S_WDONE / S_RDONE），PREADY 只在那 1 拍拉高：
     *   写：AW+W 同发 → 等 B → 再单独 1 拍响应（保证"写完立刻读"能读到新值）
     *   读：AR → 等 R 把数据打一拍 → 再单独 1 拍把 PRDATA+PREADY 一起给出
     * 代价是每次访问多 1 拍；对寄存器访问完全无所谓，但换来的是**时序无歧义**。 */
    localparam S_IDLE  = 3'd0,
               S_WAW   = 3'd1,
               S_WB    = 3'd2,
               S_WDONE = 3'd3,
               S_RAR   = 3'd4,
               S_RWAIT = 3'd5,
               S_RDONE = 3'd6;
    reg [2:0]  st;
    reg        awv, wv, arv;
    reg [11:0] awaddr_q, araddr_q;
    reg [31:0] wdata_q, rdata_q, prdata_r;
    reg        pready_r;

    wire       apb_go = apb_psel[0] && apb_penable && !pready_r;

    /* blt_top 的 AXI-Lite 从口 */
    wire [11:0] sa_awaddr  = awaddr_q;
    wire        sa_awvalid = awv;
    wire        sa_awready;
    wire [31:0] sa_wdata   = wdata_q;
    wire [3:0]  sa_wstrb   = 4'hF;
    wire        sa_wvalid  = wv;
    wire        sa_wready;
    wire        sa_bvalid;
    wire [1:0]  sa_bresp;
    wire        sa_bready  = 1'b1;         // 永远接收写响应
    wire [11:0] sa_araddr  = araddr_q;
    wire        sa_arvalid = arv;
    wire        sa_arready;
    wire [31:0] sa_rdata;
    wire [1:0]  sa_rresp;
    wire        sa_rvalid;
    wire        sa_rready  = 1'b1;         // 永远接收读数据

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            st        <= S_IDLE;
            awv       <= 1'b0;
            wv        <= 1'b0;
            arv       <= 1'b0;
            awaddr_q  <= 12'd0;
            araddr_q  <= 12'd0;
            wdata_q   <= 32'd0;
            rdata_q   <= 32'd0;
            prdata_r  <= 32'd0;
            pready_r  <= 1'b0;
        end else begin
            pready_r <= 1'b0;              // 默认只拉 1 拍
            case (st)
                S_IDLE: begin
                    if (apb_go) begin
                        if (apb_pwrite) begin
                            awaddr_q <= apb_paddr[11:0];
                            wdata_q  <= apb_pwdata;
                            awv      <= 1'b1;
                            wv       <= 1'b1;
                            st       <= S_WAW;
                        end else begin
                            araddr_q <= apb_paddr[11:0];
                            arv      <= 1'b1;
                            st       <= S_RAR;
                        end
                    end
                end
                S_WAW: begin
                    if (sa_awready) awv <= 1'b0;
                    if (sa_wready)  wv  <= 1'b0;
                    if ((!awv || sa_awready) && (!wv || sa_wready))
                        st <= S_WB;
                end
                S_WB: begin
                    if (sa_bvalid)
                        st <= S_WDONE;         // 寄存器已落地 → 单独一拍响应
                end
                S_WDONE: begin
                    pready_r <= 1'b1;
                    st       <= S_IDLE;
                end
                S_RAR: begin
                    if (arv && sa_arready) begin
                        arv <= 1'b0;
                        st  <= S_RWAIT;        // AR 受理 → 去等 R
                    end
                end
                S_RWAIT: begin
                    if (sa_rvalid) begin
                        rdata_q <= sa_rdata;   // 数据先落地
                        st      <= S_RDONE;
                    end
                end
                S_RDONE: begin
                    prdata_r <= rdata_q;       // 再花一拍把 PRDATA+PREADY 同拍给出
                    pready_r <= 1'b1;
                    st       <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end

    assign apb_pready    = pready_r;
    assign apb_prdata    = prdata_r;
    assign apb_pslverror = 1'b0;

    /* ---------------- 加速器本体 ---------------- */
    blt_top #(.AXI_DATA_W(AXI_DATA_W), .CMD_DEPTH(CMD_DEPTH)) u_blt (
        .clk(clk), .rst_n(~reset),
        .s_axil_awaddr (sa_awaddr),  .s_axil_awvalid(sa_awvalid), .s_axil_awready(sa_awready),
        .s_axil_wdata  (sa_wdata),   .s_axil_wstrb  (sa_wstrb),
        .s_axil_wvalid (sa_wvalid),  .s_axil_wready (sa_wready),
        .s_axil_bvalid (sa_bvalid),  .s_axil_bresp  (sa_bresp),   .s_axil_bready(sa_bready),
        .s_axil_araddr (sa_araddr),  .s_axil_arvalid(sa_arvalid), .s_axil_arready(sa_arready),
        .s_axil_rdata  (sa_rdata),   .s_axil_rresp  (sa_rresp),
        .s_axil_rvalid (sa_rvalid),  .s_axil_rready (sa_rready),
        .m_axi_araddr  (m_axi_araddr), .m_axi_arlen (m_axi_arlen),
        .m_axi_arsize  (m_axi_arsize), .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid (m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata   (m_axi_rdata),  .m_axi_rresp (m_axi_rresp),
        .m_axi_rlast   (m_axi_rlast),  .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready  (m_axi_rready),
        .m_axi_awaddr  (m_axi_awaddr), .m_axi_awlen (m_axi_awlen),
        .m_axi_awsize  (m_axi_awsize), .m_axi_awburst(m_axi_awburst),
        .m_axi_awvalid (m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata   (m_axi_wdata),  .m_axi_wstrb (m_axi_wstrb),
        .m_axi_wlast   (m_axi_wlast),  .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),
        .m_axi_bvalid  (m_axi_bvalid), .m_axi_bresp (m_axi_bresp),
        .m_axi_bready  (m_axi_bready),
        .irq_done      (irq_done),
        .scan_underrun (scan_underrun),
        .scan_abort    (scan_abort),
        .fb_sel        (fb_sel),
        .fb_cur_sel    (fb_cur_sel),
        .fb_frame_cnt  (fb_frame_cnt),
        .frame_pulse   (frame_pulse),
        /* ★S5（v3.2）扫描输出颜色 LUT：直通到 ddr3_example_top → fb_scanout */
        .lut_wr        (lut_wr),
        .lut_ch        (lut_ch),
        .lut_idx       (lut_idx),
        .lut_data      (lut_data),
        .lut_en        (lut_en),
        .lut_bank_req  (lut_bank_req),
        .lut_bank_act  (lut_bank_act)
    );
endmodule
