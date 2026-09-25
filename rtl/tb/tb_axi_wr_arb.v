/* =========================================================================
 * tb_axi_wr_arb.v — AXI 写通道 2 选 1 仲裁自测（CPU / BitBlt 共享 DDR 写口）
 * -------------------------------------------------------------------------
 * 核心风险：B 响应靠 owner 分路。若在飞写突发未收完就切换 owner，
 *   CPU 的 B 会被送给引擎（或反之）→ 其中一个主机会永久等 B（挂死），
 *   或者两个突发交错写入导致数据错乱。
 * 本 TB 让两个主机**同时**不停发写突发，各写自己的一段地址区间（数据 = 地址派生），
 * 最后逐字节校验两段内存；任何错路/丢拍都会表现为超时或数据不符。
 * ========================================================================= */
`timescale 1ns/1ps

module wr_master #(
    parameter [27:0] BASE = 28'h000_0000,
    parameter        NAME = "M"
)(
    input  wire         clk,
    input  wire         rst_n,
    output reg  [27:0]  awaddr,
    output reg  [7:0]   awlen,
    output reg          awvalid,
    input  wire         awready,
    output reg  [127:0] wdata,
    output reg  [15:0]  wstrb,
    output reg          wlast,
    output reg          wvalid,
    input  wire         wready,
    input  wire         bvalid,
    input  wire [1:0]   bresp,
    output reg          bready,
    output reg  [31:0]  nburst
);
    localparam S_IDLE = 2'd0, S_AW = 2'd1, S_W = 2'd2, S_B = 2'd3;
    reg [1:0]  st;
    reg [7:0]  len_q, beat;
    reg [27:0] addr_q;
    reg [31:0] blfs = 32'h1357_9BDF;      // bready 随机反压用

    always @(posedge clk) blfs <= {blfs[30:0], blfs[31] ^ blfs[28]};

    function [7:0] len_of;
        input [1:0] s;
        begin
            case (s)
                2'd0: len_of = 8'd0;
                2'd1: len_of = 8'd2;
                2'd2: len_of = 8'd5;
                default: len_of = 8'd9;
            endcase
        end
    endfunction

    wire [127:0] beat_data = {96'd0, (addr_q + (beat << 4)), 4'h0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE; awaddr <= 28'd0; awlen <= 8'd0; awvalid <= 1'b0;
            wdata <= 128'd0; wstrb <= 16'hFFFF; wlast <= 1'b0; wvalid <= 1'b0;
            bready <= 1'b1; len_q <= 8'd0; beat <= 8'd0; addr_q <= 28'd0;
            nburst <= 32'd0;
        end else begin
            bready <= (blfs[3] | blfs[4]);    // 25% 概率压低 bready（对抗性反压）
            case (st)
                S_IDLE: begin
                    addr_q  <= BASE + {20'd0, nburst[7:0]} * 28'h100;   // 每笔间隔 256B
                    len_q   <= len_of(nburst[1:0]);
                    awaddr  <= BASE + {20'd0, nburst[7:0]} * 28'h100;
                    awlen   <= len_of(nburst[1:0]);
                    awvalid <= 1'b1;
                    beat    <= 8'd0;
                    st      <= S_AW;
                end
                S_AW: if (awvalid && awready) begin
                    awvalid <= 1'b0;
                    wdata   <= beat_data;
                    wstrb   <= 16'hFFFF;
                    wlast   <= (len_q == 8'd0);
                    wvalid  <= 1'b1;
                    st      <= S_W;
                end
                S_W: if (wvalid && wready) begin
                    if (wlast) begin
                        wvalid <= 1'b0;
                        st     <= S_B;
                    end else begin
                        beat  <= beat + 8'd1;
                        wdata <= {96'd0, (addr_q + ((beat + 8'd1) << 4)), 4'h0};
                        wlast <= ((beat + 8'd1) == len_q);
                    end
                end
                S_B: if (bvalid && bready) begin
                    nburst <= nburst + 32'd1;
                    if (nburst[7:0] == 8'h1F)
                        st <= S_IDLE;              // 发够 32 笔就停
                    else
                        st <= S_IDLE;
                end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule

module tb_axi_wr_arb;
    reg clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    /* CPU 侧 */
    wire [27:0] c_awaddr; wire [7:0] c_awlen; wire [2:0] c_awsize = 3'd4; wire [1:0] c_awburst = 2'b01;
    wire [3:0]  c_awid = 4'h0; wire c_awvalid, c_awready;
    wire [127:0] c_wdata; wire [15:0] c_wstrb; wire c_wlast, c_wvalid, c_wready;
    wire c_bvalid; wire [1:0] c_bresp; wire [3:0] c_bid; wire c_bready;
    wire [31:0] c_n;

    /* BitBlt 侧 */
    wire [27:0] b_awaddr; wire [7:0] b_awlen; wire [2:0] b_awsize = 3'd4; wire [1:0] b_awburst = 2'b01;
    wire b_awvalid, b_awready;
    wire [127:0] b_wdata; wire [15:0] b_wstrb; wire b_wlast, b_wvalid, b_wready;
    wire b_bvalid; wire [1:0] b_bresp; wire b_bready;
    wire [31:0] b_n;

    /* DDR 侧 */
    wire [27:0] m_awaddr; wire [7:0] m_awlen; wire [2:0] m_awsize; wire [1:0] m_awburst;
    wire [3:0]  m_awid; wire m_awvalid, m_awready;
    wire [127:0] m_wdata; wire [15:0] m_wstrb; wire m_wlast, m_wvalid, m_wready;
    wire m_bvalid; wire [1:0] m_bresp; wire [3:0] m_bid; wire m_bready;

    wr_master #(.BASE(28'h000_0000), .NAME("CPU")) u_cpu (
        .clk(clk), .rst_n(rst_n),
        .awaddr(c_awaddr), .awlen(c_awlen), .awvalid(c_awvalid), .awready(c_awready),
        .wdata(c_wdata), .wstrb(c_wstrb), .wlast(c_wlast), .wvalid(c_wvalid), .wready(c_wready),
        .bvalid(c_bvalid), .bresp(c_bresp), .bready(c_bready), .nburst(c_n)
    );
    wr_master #(.BASE(28'h004_0000), .NAME("BLT")) u_blt (
        .clk(clk), .rst_n(rst_n),
        .awaddr(b_awaddr), .awlen(b_awlen), .awvalid(b_awvalid), .awready(b_awready),
        .wdata(b_wdata), .wstrb(b_wstrb), .wlast(b_wlast), .wvalid(b_wvalid), .wready(b_wready),
        .bvalid(b_bvalid), .bresp(b_bresp), .bready(b_bready), .nburst(b_n)
    );

    axi_wr_arb #(.AW(28), .DW(128), .IDW(4)) dut (
        .clk(clk), .rst_n(rst_n),
        .c_awaddr(c_awaddr), .c_awlen(c_awlen), .c_awsize(c_awsize), .c_awburst(c_awburst),
        .c_awid(c_awid), .c_awvalid(c_awvalid), .c_awready(c_awready),
        .c_wdata(c_wdata), .c_wstrb(c_wstrb), .c_wlast(c_wlast), .c_wvalid(c_wvalid), .c_wready(c_wready),
        .c_bvalid(c_bvalid), .c_bresp(c_bresp), .c_bid(c_bid), .c_bready(c_bready),
        .b_awaddr(b_awaddr), .b_awlen(b_awlen), .b_awsize(b_awsize), .b_awburst(b_awburst),
        .b_awvalid(b_awvalid), .b_awready(b_awready),
        .b_wdata(b_wdata), .b_wstrb(b_wstrb), .b_wlast(b_wlast), .b_wvalid(b_wvalid), .b_wready(b_wready),
        .b_bvalid(b_bvalid), .b_bresp(b_bresp), .b_bready(b_bready),
        .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_awid(m_awid), .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_bvalid(m_bvalid), .m_bresp(m_bresp), .m_bid(m_bid), .m_bready(m_bready)
    );

    /* ---- 行为写从机（存内存 + B 响应）----
     * 对抗性（2026-xx 加）：awready 随机反压、B 延迟随机、bready 随机压低。
     * 旧版从机"随时 ready + B 立刻回"，测不出 owner 切换/B 分路的边界。 */
    reg [7:0] mem [0:(1<<19)-1];
    localparam S_IDLE = 2'd0, S_W = 2'd1, S_B = 2'd2;
    reg [1:0]  wst = S_IDLE;
    reg [27:0] waddr;
    reg [7:0]  wlen, wcnt;
    reg [2:0]  bdly;
    reg [31:0] blfs = 32'h1234_5678;
    integer    k;

    always @(posedge clk) blfs <= {blfs[30:0], blfs[31] ^ blfs[28]};

    assign m_awready = (wst == S_IDLE) && (blfs[15] | blfs[16]);
    assign m_wready  = (wst == S_W);
    assign m_bvalid  = (wst == S_B) && (bdly == 3'd0);
    assign m_bresp   = 2'b00;
    assign m_bid     = 4'h1;

    /* bready 随机反压（在 wr_master 内部产生，见模块内 blfs） */

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wst <= S_IDLE; waddr <= 0; wlen <= 0; wcnt <= 0; bdly <= 3'd0;
        end else begin
            case (wst)
                S_IDLE: if (m_awvalid && m_awready) begin
                    waddr <= m_awaddr; wlen <= m_awlen; wcnt <= 8'd0; wst <= S_W;
                end
                S_W: if (m_wvalid && m_wready) begin
                    for (k = 0; k < 16; k = k + 1)
                        if (m_wstrb[k] && (waddr + k < (1<<19)))
                            mem[waddr + k] <= m_wdata[k*8 +: 8];
                    if (wcnt == wlen) begin
                        bdly <= blfs[12:10];              // B 延迟 0..7 拍
                        wst  <= S_B;
                    end else begin wcnt <= wcnt + 8'd1; waddr <= waddr + 16; end
                end
                S_B: if (bdly != 3'd0) bdly <= bdly - 3'd1;
                     else if (m_bready) wst <= S_IDLE;
            endcase
        end
    end

    integer errors = 0, i, j, b, bad;
    reg [7:0] ebyte;

    /* 与 wr_master 内的 len_of 保持一致（突发拍数 = 返回值+1） */
    function [7:0] len_tb;
        input [1:0] s;
        begin
            case (s)
                2'd0: len_tb = 8'd0;
                2'd1: len_tb = 8'd2;
                2'd2: len_tb = 8'd5;
                default: len_tb = 8'd9;
            endcase
        end
    endfunction

    /* 校验一个 16B beat：地址 B 的数据应为 {96'd0, B, 4'h0} */
    task check_beat;
        input [27:0] B;
        input        tag;
        begin
            for (j = 0; j < 16; j = j + 1) begin
                if (j == 0)      ebyte = 8'h00;
                else if (j == 1) ebyte = B[11:4];
                else if (j == 2) ebyte = B[19:12];
                else if (j == 3) ebyte = B[27:20];
                else             ebyte = 8'h00;
                if (mem[B + j] !== ebyte) begin
                    bad = bad + 1;
                    if (bad <= 6)
                        $display("FAIL: %0s 区 @%h byte%0d exp=%h got=%h",
                                 tag ? "BLT" : "CPU", B, j, ebyte, mem[B + j]);
                end
            end
        end
    endtask

    initial begin
        #30 rst_n = 1'b1;
        #200000;                                  // 跑 200us：两个主机各发几十笔

        $display("CPU 突发数=%0d  BLT 突发数=%0d", c_n, b_n);
        if (c_n < 32 || b_n < 32) begin
            errors = errors + 1;
            $display("FAIL: 有主机被饿死（CPU=%0d BLT=%0d）", c_n, b_n);
        end

        /* 校验两段地址区间的数据：beat 数据 = {96'd0, 该拍地址, 4'h0}
         * 即 16 字节里只有 byte1/2/3 非零，分别是地址的 bit[11:4]/[19:12]/[27:20]。
         * 主机写的是"每 256B 一笔、长度 = len_of(n[1:0])+1 拍"的突发 → 只校验这些地址。 */
        bad = 0;
        for (i = 0; i < 64; i = i + 1) begin : chk
            for (b = 0; b <= len_tb(i[1:0]); b = b + 1) begin
                check_beat(28'h000_0000 + i * 256 + b * 16, 0);
                check_beat(28'h004_0000 + i * 256 + b * 16, 1);
            end
        end
        if (bad != 0) begin errors = errors + 1; $display("FAIL: 数据校验不一致 %0d 处", bad); end
        else $display("PASS: 两段区间数据逐字节校验一致");

        if (errors == 0) $display("========== tb_axi_wr_arb ALL PASS ==========");
        else             $display("========== tb_axi_wr_arb FAILED: %0d ==========", errors);
        $finish;
    end

    initial begin
        #2_000_000;
        $display("!!!!!!!! tb_axi_wr_arb WATCHDOG（很可能 B 响应错路导致挂死）!!!!!!!!");
        $finish;
    end
endmodule
