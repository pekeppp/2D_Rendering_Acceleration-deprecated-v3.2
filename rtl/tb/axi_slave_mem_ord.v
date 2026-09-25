/* =========================================================================
 * axi_slave_mem_ord.v — 行为级 AXI4 从机（**写提交可乱序 + B 即提交**版）
 * -------------------------------------------------------------------------
 * 与 axi_slave_mem.v 的差别**只在写侧**（读侧照抄，含 q_cnt 同拍修正）：
 *
 *   - 写侧 = "写缓冲 + 提交调度器"：AW/W 受理后进 WBUF 深缓冲，每个条目带一个
 *     **提交时刻 ctime**，到点才把数据落进 mem；
 *   - **B 在真正提交那一拍才回**，所以对本 TB 来说 "收到 B" == "像素已落内存"，
 *     这是判断"引擎 IDLE/BUSY=0 能不能当写完成用"的基准（也是 AXI 世界里主机
 *     唯一能拿到的排序原语）；
 *   - 读侧数据在回程那一拍从 mem 取值 —— mem 里**只有已提交的数据**，写缓冲里
 *     还没提交的数据读不到。因此"下一条指令的读跑到上一条指令还没提交的写前面"
 *     会读到旧值：这正是写后读（RAW）危险，不是从机模型作弊。
 *
 * 提交延迟（DLY_MODE）：
 *   0 = 固定 DLY 拍后提交，模拟"写回延迟固定且较长"（本工程 tb_blt_burst 用
 *       B_LAT=128 代表真实 DDR 写回延迟，本 TB 沿用同一量级）。
 *   1 = 每笔突发用 LFSR 取 4..259 拍的随机延迟，模拟 DDR bank/row 调度导致的
 *       **提交顺序不确定**：后受理的突发有可能先落内存（乱序提交）。
 *
 * 用法：u_mem.mem[a]（预填/校验）、u_mem.commit_cnt（已提交突发数）。
 * ========================================================================= */
`timescale 1ns/1ps
module axi_slave_mem_ord #(
    parameter AXI_DATA_W = 128,
    parameter MEM_BYTES  = 1 << 15,
    parameter AR_LAT     = 8,
    parameter MAXO       = 4,          // 读侧最大在飞笔数
    parameter WBUF       = 4           // 写缓冲条目数
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    dly_rand,    // 0=固定 dly_val 拍；1=每笔 4..259 拍随机
    input  wire [31:0]             dly_val,     // 固定提交延迟
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
    output wire                    s_awready,
    input  wire [AXI_DATA_W-1:0]   s_wdata,
    input  wire [AXI_DATA_W/8-1:0] s_wstrb,
    input  wire                    s_wlast,
    input  wire                    s_wvalid,
    output wire                    s_wready,
    output reg                     s_bvalid,
    output wire [1:0]              s_bresp,
    input  wire                    s_bready
);
    localparam BEATS_MAX = 16;
    localparam BW        = AXI_DATA_W/8;      // 16

    reg [7:0] mem [0:MEM_BYTES-1];
    integer i, b, j, k;

    assign s_rresp = 2'b00;
    assign s_bresp = 2'b00;

    /* ---------------- 全局周期计数 ---------------- */
    reg [31:0] cyc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cyc <= 32'd0;
        else        cyc <= cyc + 32'd1;
    end

    /* ================= 读侧（与 axi_slave_mem.v 一致） ================= */
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
        for (i = 0; i < BW; i = i + 1)
            if (cur_r + i < MEM_BYTES)
                rdata_c[i*8 +: 8] = mem[cur_r + i];      // 只看得见"已提交"的数据
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

            if (s_arvalid && s_arready) begin
                q_addr[qwp] <= s_araddr;
                q_len [qwp] <= s_arlen;
                q_rdy [qwp] <= cyc + AR_LAT[31:0];
                q_wp        <= q_wp + 3'd1;
            end

            if (s_rvalid && s_rready) begin
                if (s_rlast) begin
                    q_rp <= q_rp + 3'd1;
                    if ((q_cnt > 3'd1) && ((cyc + 32'd1) >= q_rdy[(q_rp + 3'd1) & 3'd3])) begin
                        r_cnt    <= 8'd0;
                        s_rvalid <= 1'b1;
                    end else
                        s_rvalid <= 1'b0;
                end else
                    r_cnt <= r_cnt + 8'd1;
            end else if (!s_rvalid && (q_cnt != 3'd0) && (cyc >= q_rdy[qrp])) begin
                s_rvalid <= 1'b1;
                r_cnt    <= 8'd0;
            end
            /* 受理 +1 / 收完 −1 必须写在同一条表达式里（11.6 的假死教训） */
            q_cnt <= q_cnt + ((s_arvalid && s_arready) ? 3'd1 : 3'd0)
                           - ((s_rvalid && s_rready && s_rlast) ? 3'd1 : 3'd0);
        end
    end

    /* ================= 写侧：写缓冲 + 提交调度器 ================= */
    reg [31:0]            wb_addr [0:WBUF-1];
    reg [7:0]             wb_len  [0:WBUF-1];
    reg [31:0]            wb_ct   [0:WBUF-1];
    reg                   wb_v    [0:WBUF-1];
    reg [AXI_DATA_W-1:0]  wb_dat  [0:WBUF*BEATS_MAX-1];
    reg [BW-1:0]          wb_str  [0:WBUF*BEATS_MAX-1];

    integer commit_cnt;                 // 已提交突发数（TB 可读）

    /* 正在收 W 的槽 */
    reg [1:0]  wslot;
    reg        wbusy;
    reg [7:0]  wbeat;
    reg [7:0]  wlen;
    reg [15:0] lfsr;
    reg [15:0] wto;                 // W 收拍看门狗：DUT 中途被 SOFT_RST 打断时不留死锁

    /* 找空闲槽（低索引优先） */
    reg [1:0] fslot;
    reg       any_free;
    always @(*) begin
        any_free = 1'b0;
        fslot    = 2'd0;
        for (b = WBUF-1; b >= 0; b = b - 1)
            if (!wb_v[b]) begin
                any_free = 1'b1;
                fslot    = b[1:0];
            end
    end

    /* 本笔的提交延迟 */
    wire [31:0] dly_now = dly_rand ? (32'd4 + {24'd0, lfsr[7:0]}) : dly_val;

    /* 提交选择：所有到点条目里选 ctime 最小者（同刻则槽号小的先） */
    reg        csel_v;
    reg [1:0]  csel;
    always @(*) begin
        csel_v = 1'b0;
        csel   = 2'd0;
        for (b = 0; b < WBUF; b = b + 1)
            if (wb_v[b] && (cyc >= wb_ct[b]))
                if (!csel_v || (wb_ct[b] < wb_ct[csel])) begin
                    csel_v = 1'b1;
                    csel   = b[1:0];
                end
    end

    /* AW/W ready 组合给出（受理权在本模块手里，不受主机 valid 影响） */
    wire aw_hs = s_awvalid && s_awready;
    wire w_hs  = s_wvalid  && s_wready;
    assign s_awready = any_free && !wbusy;
    assign s_wready  = wbusy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_bvalid   <= 1'b0;
            wbusy      <= 1'b0;
            wslot      <= 2'd0;
            wbeat      <= 8'd0;
            wlen       <= 8'd0;
            lfsr       <= 16'hACE1;
            wto        <= 16'd0;
            commit_cnt <= 0;
            for (b = 0; b < WBUF; b = b + 1) wb_v[b] <= 1'b0;
        end else begin
            /* ---- 提交：落 mem + 回 B（B = 已提交）；同一拍只提交一笔 ---- */
            if (csel_v && !s_bvalid) begin
                for (j = 0; j <= wb_len[csel]; j = j + 1)
                    for (k = 0; k < BW; k = k + 1)
                        if (wb_str[csel*BEATS_MAX+j][k] &&
                            (wb_addr[csel] + j*16 + k < MEM_BYTES))
                            mem[wb_addr[csel] + j*16 + k] <= wb_dat[csel*BEATS_MAX+j][k*8 +: 8];
                wb_v[csel] <= 1'b0;
                s_bvalid   <= 1'b1;
                commit_cnt <= commit_cnt + 1;
            end else if (s_bvalid && s_bready)
                s_bvalid <= 1'b0;

            /* ---- AW 受理：缓冲有空格且当前没有在收 W ---- */
            if (aw_hs) begin
                wb_addr[fslot] <= s_awaddr;
                wb_len [fslot] <= s_awlen;
                wslot          <= fslot;
                wlen           <= s_awlen;
                wbeat          <= 8'd0;
                wbusy          <= 1'b1;
            end

            /* ---- W 收拍：收满 wlast 才算一笔，登记提交时刻 ---- */
            if (w_hs) begin
                wb_dat[wslot*BEATS_MAX + wbeat] <= s_wdata;
                wb_str[wslot*BEATS_MAX + wbeat] <= s_wstrb;
                if (s_wlast || (wbeat == wlen)) begin
                    wb_v [wslot] <= 1'b1;
                    wb_ct[wslot] <= cyc + dly_now;
                    wbusy        <= 1'b0;
                    lfsr         <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
                end else
                    wbeat <= wbeat + 8'd1;
            end

            /* 主机被中途复位 → 这笔突发永远不会再来 W：超时丢弃，避免模型死锁 */
            if (wbusy && !w_hs) begin
                if (wto == 16'd512) begin
                    $display("  [MEM] W 收拍超时（主机中途复位？）addr=%h len=%0d，丢弃该笔",
                             wb_addr[wslot], wlen);
                    wbusy <= 1'b0;
                    wto   <= 16'd0;
                end else
                    wto <= wto + 16'd1;
            end else
                wto <= 16'd0;
        end
    end
endmodule
