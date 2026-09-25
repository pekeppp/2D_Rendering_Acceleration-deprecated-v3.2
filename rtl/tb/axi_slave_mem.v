/* =========================================================================
 * axi_slave_mem.v — 行为级 AXI4 从机（伪 DDR，128bit，INCR 突发）
 * -------------------------------------------------------------------------
 * 读侧：**支持多笔 outstanding 的流水化读**（模拟真实 DDR 控制器）
 *   - AR 队列（深度 MAXO）：accept 后记下 ready_at = now + AR_LAT；
 *     队列未满就一直收 → 主设备可以背靠背发 AR；
 *   - 数据按队列顺序回流（同 ID 保序）；当前笔结束时若下一笔已到时间，
 *     则**无缝续发**（1 beat/cycle）→ 读延迟只在流水起步时暴露一次。
 *   这样"突发流水"改造才有可测量的收益（原版从机一笔才收一笔，
 *   再多 outstanding 也只会被 s_arready 挡住）。
 * 写侧：单笔，按 WSTRB 生效，B 延迟 B_LAT。
 * TB 可经层次路径 u_mem.mem[..] 预填/校验。
 * ========================================================================= */
`timescale 1ns/1ps
module axi_slave_mem #(
    parameter AXI_DATA_W = 128,
    parameter MEM_BYTES  = 1 << 15,
    parameter AR_LAT     = 4,
    parameter B_LAT      = 2,
    parameter MAXO       = 4          // 读侧最大在飞笔数
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

    /* ---------------- 全局周期计数（用于 ready_at） ---------------- */
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

    reg [AXI_DATA_W-1:0] rdata_c;
    always @(*) begin
        rdata_c = {AXI_DATA_W{1'b0}};
        for (i = 0; i < AXI_DATA_W/8; i = i + 1)
            if (cur_r + i < MEM_BYTES)
                rdata_c[i*8 +: 8] = mem[cur_r + i];
    end
    assign s_rdata = rdata_c;
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

            /* AR 接收（可背靠背，队列未满就收） */
            if (s_arvalid && s_arready) begin
                q_addr[qwp] <= s_araddr;
                q_len [qwp] <= s_arlen;
                q_rdy [qwp] <= cyc + AR_LAT[31:0];
                q_wp        <= q_wp + 3'd1;
            end

            /* 数据回程 */
            if (s_rvalid && s_rready) begin
                if (s_rlast) begin
                    q_rp  <= q_rp + 3'd1;
                    /* 下一笔已到期 → 无缝续发（流水） */
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
            /* 队列计数：**AR 受理 +1 与突发收完 −1 必须写在同一条表达式里**。
             * 原写法把 `q_cnt <= q_cnt+1` 放在上面的 AR 分支、`q_cnt <= q_cnt-1`
             * 放在下面的回程分支，两者同拍发生时后者把前者覆盖掉 → q_cnt 永久偏小，
             * 累计到"q_cnt=0 但还有一笔没回数据"时从机就再也不发数据：
             * 表现为**主设备 rd_busy 永不落、像素通路永远等不到词、引擎卡在 BUSY**
             * （仿真假死；真 DDR 控制器不会有这个 bug）。 */
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
