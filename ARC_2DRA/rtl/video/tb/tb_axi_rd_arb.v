/* =========================================================================
 * tb_axi_rd_arb.v — AXI 读通道 2 选 1 仲裁自测
 * -------------------------------------------------------------------------
 * 要验证的核心风险：R 数据回程是靠 owner 归属来分路的（不是靠 rid 解复用）。
 * 如果 owner 在当前突发尚未收完（cnt!=0）时就切换，扫描输出的剩余 R 拍会被
 * 送给 CPU（或反之）→ 帧缓冲内容被 CPU 读数据污染 / CPU 读到画面数据。
 * 本 TB 让两个主机**同时**不停发读请求，从机按"地址决定数据"返回，两个主机
 * 各自校验"收到的每个 beat 数据都等于自己请求的地址" → 任何错路都会立刻报错。
 * 同时检查每个突发的 rlast 落在正确的最后一拍（不丢拍、不多收）。
 * ========================================================================= */
`timescale 1ns/1ps

/* ---------------- 读主机模型：不停发突发并校验数据 ---------------- */
module arb_master #(
    parameter [27:0] BASE   = 28'h000_1000,
    parameter [27:0] STRIDE = 28'h000_0100,
    parameter        NAME   = "M"
)(
    input  wire         clk,
    input  wire         rst_n,
    output reg  [27:0]  araddr,
    output reg  [7:0]   arlen,
    output reg          arvalid,
    input  wire         arready,
    input  wire [127:0] rdata,
    input  wire         rvalid,
    input  wire         rlast,
    output reg          rready,
    output reg  [31:0]  nburst,
    output reg  [31:0]  nbeat,
    output reg  [31:0]  errs
);
    localparam S_IDLE = 2'd0, S_DATA = 2'd1, S_GAP = 2'd2;
    reg [1:0]  st;
    reg [7:0]  cur_len, beat;
    reg [27:0] cur_addr, seq;
    reg [3:0]  gap;
    reg [127:0] exp;

    /* 突发长度轮流取 1/3/7/15，覆盖单拍与多拍 */
    function [7:0] len_of;
        input [1:0] s;
        begin
            case (s)
                2'd0: len_of = 8'd0;
                2'd1: len_of = 8'd2;
                2'd2: len_of = 8'd6;
                default: len_of = 8'd14;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE; araddr <= 28'd0; arlen <= 8'd0; arvalid <= 1'b0;
            rready <= 1'b1; beat <= 8'd0; cur_len <= 8'd0; cur_addr <= 28'd0;
            seq <= 28'd0; gap <= 4'd0; nburst <= 32'd0; nbeat <= 32'd0; errs <= 32'd0;
        end else begin
            case (st)
                S_IDLE: begin
                    cur_addr <= BASE + seq * STRIDE;
                    cur_len  <= len_of(seq[1:0]);
                    araddr   <= BASE + seq * STRIDE;
                    arlen    <= len_of(seq[1:0]);
                    arvalid  <= 1'b1;
                    st       <= S_DATA;
                    beat     <= 8'd0;
                end
                S_DATA: begin
                    if (arvalid && arready) begin
                        arvalid <= 1'b0;
                    end
                    if (rvalid && rready) begin
                        exp = {96'd0, (cur_addr + (beat << 4)), 4'h0};
                        if (rdata !== exp) begin
                            errs <= errs + 32'd1;
                            if (errs < 32'd6)
                                $display("[%0s] FAIL 数据错路: 期望 0x%032x 实际 0x%032x (beat %0d)",
                                         NAME, exp, rdata, beat);
                        end
                        nbeat <= nbeat + 32'd1;
                        if (rlast) begin
                            if (beat != cur_len) begin
                                errs <= errs + 32'd1;
                                $display("[%0s] FAIL rlast 位置错: beat=%0d len=%0d", NAME, beat, cur_len);
                            end
                            nburst <= nburst + 32'd1;
                            seq    <= seq + 28'd1;
                            gap    <= 4'd3;
                            st     <= S_GAP;
                        end else begin
                            beat <= beat + 8'd1;
                        end
                    end
                    if (arvalid && arready)
                        beat <= 8'd0;
                end
                S_GAP: begin
                    if (gap == 4'd0)
                        st <= S_IDLE;
                    else
                        gap <= gap - 4'd1;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule

/* ---------------- 顶层：两个主机 + 仲裁器 + 行为从机 ---------------- */
module tb_axi_rd_arb;
    localparam AW = 28, DW = 128, IDW = 4;

    reg clk = 1'b0, rst_n = 1'b0;
    always #5 clk = ~clk;

    /* CPU 侧 */
    wire [AW-1:0]  c_araddr;
    wire [7:0]     c_arlen;
    wire [IDW-1:0] c_arid;
    wire           c_arvalid, c_arready, c_rvalid, c_rlast, c_rready;
    wire [DW-1:0]  c_rdata;
    wire [1:0]     c_rresp;
    wire [31:0]    c_nburst, c_nbeat, c_errs;

    /* 扫描输出侧 */
    wire [AW-1:0]  s_araddr;
    wire [7:0]     s_arlen;
    wire           s_arvalid, s_arready, s_rvalid, s_rlast, s_rready;
    wire [DW-1:0]  s_rdata;
    wire [1:0]     s_rresp;
    wire [31:0]    s_nburst, s_nbeat, s_errs;

    /* DDR 侧 */
    wire [AW-1:0]  m_araddr;
    wire [7:0]     m_arlen;
    wire [2:0]     m_arsize;
    wire [1:0]     m_arburst;
    wire [IDW-1:0] m_arid;
    wire           m_arvalid, m_arready, m_rvalid, m_rlast, m_rready;
    wire [DW-1:0]  m_rdata;
    wire [1:0]     m_rresp;
    wire [IDW-1:0] m_rid;

    arb_master #(.BASE(28'h800_0000), .STRIDE(28'h000_0100), .NAME("CPU")) u_cpu (
        .clk(clk), .rst_n(rst_n),
        .araddr(c_araddr), .arlen(c_arlen), .arvalid(c_arvalid), .arready(c_arready),
        .rdata(c_rdata), .rvalid(c_rvalid), .rlast(c_rlast), .rready(c_rready),
        .nburst(c_nburst), .nbeat(c_nbeat), .errs(c_errs)
    );

    arb_master #(.BASE(28'h030_1000), .STRIDE(28'h000_0040), .NAME("SCAN")) u_scan (
        .clk(clk), .rst_n(rst_n),
        .araddr(s_araddr), .arlen(s_arlen), .arvalid(s_arvalid), .arready(s_arready),
        .rdata(s_rdata), .rvalid(s_rvalid), .rlast(s_rlast), .rready(s_rready),
        .nburst(s_nburst), .nbeat(s_nbeat), .errs(s_errs)
    );

    axi_rd_arb #(.AW(AW), .DW(DW), .IDW(IDW)) dut (
        .clk(clk), .rst_n(rst_n),
        .c_araddr(c_araddr), .c_arlen(c_arlen), .c_arsize(3'd4), .c_arburst(2'b01),
        .c_arid(4'h0), .c_arvalid(c_arvalid), .c_arready(c_arready),
        .c_rdata(c_rdata), .c_rresp(c_rresp), .c_rid(c_arid), .c_rlast(c_rlast),
        .c_rvalid(c_rvalid), .c_rready(c_rready),
        .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arsize(3'd4), .s_arburst(2'b01),
        .s_arvalid(s_arvalid), .s_arready(s_arready), .s_hold(1'b0),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
        .s_rvalid(s_rvalid), .s_rready(s_rready),
        .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_arid(m_arid), .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rid(m_rid), .m_rlast(m_rlast),
        .m_rvalid(m_rvalid), .m_rready(m_rready)
    );

    /* ---- 行为 AXI 从机：数据 = 该拍地址左移 4 位（128 位 beat） ---- */
    localparam RS_IDLE = 2'd0, RS_LAT = 2'd1, RS_SEND = 2'd2;
    reg [1:0]      rs;
    reg [27:0]     sla_addr;
    reg [7:0]      sla_len, sla_beat, sla_dly;
    reg            sla_rv;

    assign m_arready = (rs == RS_IDLE);
    assign m_rvalid  = sla_rv;
    assign m_rlast   = (sla_beat == sla_len);
    assign m_rresp   = 2'b00;
    assign m_rid     = 4'h1;
    assign m_rdata   = {96'd0, (sla_addr + (sla_beat << 4)), 4'h0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rs <= RS_IDLE; sla_rv <= 1'b0; sla_addr <= 28'd0; sla_len <= 8'd0;
            sla_beat <= 8'd0; sla_dly <= 8'd0;
        end else begin
            case (rs)
                RS_IDLE: if (m_arvalid && m_arready) begin
                    sla_addr <= m_araddr;
                    sla_len  <= m_arlen;
                    sla_beat <= 8'd0;
                    sla_dly  <= 8'd3;
                    rs       <= RS_LAT;
                end
                RS_LAT: if (sla_dly == 8'd0) begin
                    sla_rv <= 1'b1;
                    rs     <= RS_SEND;
                end else
                    sla_dly <= sla_dly - 8'd1;
                RS_SEND: if (sla_rv && m_rready) begin
                    if (m_rlast) begin
                        sla_rv <= 1'b0;
                        rs     <= RS_IDLE;
                    end else
                        sla_beat <= sla_beat + 8'd1;
                end
                default: rs <= RS_IDLE;
            endcase
        end
    end

    /* ---- 主流程 ---- */
    initial begin
        #200 rst_n = 1'b1;             /* 保持复位 ≥1 个时钟沿 */
        #40000;                        /* 40us：两侧各完成数百个突发 */

        $display("CPU : 突发=%0d 拍=%0d 错误=%0d", c_nburst, c_nbeat, c_errs);
        $display("SCAN: 突发=%0d 拍=%0d 错误=%0d", s_nburst, s_nbeat, s_errs);

        if ((c_errs == 0) && (s_errs == 0) &&
            (c_nburst >= 32'd20) && (s_nburst >= 32'd20) &&
            (c_nbeat  >= 32'd100) && (s_nbeat >= 32'd100))
            $display("========== tb_axi_rd_arb ALL PASS ==========");
        else begin
            if ((c_nburst < 32'd20) || (s_nburst < 32'd20))
                $display("FAIL: 突发数太少（CPU=%0d SCAN=%0d）→ 有主机被饿死",
                         c_nburst, s_nburst);
            $display("========== tb_axi_rd_arb FAILED ==========");
        end
        $finish;
    end
endmodule
