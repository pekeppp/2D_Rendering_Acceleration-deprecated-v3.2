/* =========================================================================
 * cmd_fifo.v — 指令 FIFO（**BRAM 可推断版**：同步读 + 输出寄存器）
 * -------------------------------------------------------------------------
 * 契约（对齐 software/blt_regs.h + blt_drv.c）：
 *   - CPU 侧逐字 push（wr_en）；引擎侧逐字 pop（rd_en + rd_ack 握手）
 *   - word_count：已可用的字数 0..2048；cmd_count = floor(word_count/8)
 *   - full 按字算；CPU 写满时由寄存器从机反压，绝不丢字
 *
 * 存储改为同步读（同 sync_fifo）：原版 `assign dout = mem[rptr];` 是异步读，
 * Titanium 块 RAM 不支持 → 2048×32bit 会被拆成 65536 个 FF（超过整片容量），
 * 这是本次 PnR 资源爆掉的主因之一。上层弹字请按 rd_ack 计数，
 * 或"先判 !empty 再弹"（连续弹字约 1 字/2 拍，8 字一条指令 ≈ 16 拍，可忽略）。
 * ========================================================================= */
module cmd_fifo #(
    parameter CMD_DEPTH = 256      // 指令条数（每条 8 字）
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          wr_en,
    input  wire [31:0]   din,
    input  wire          rd_en,
    output wire          rd_ack,     // 本拍确实弹出了一个字
    output wire [31:0]   dout,
    output wire          full,       // 字满（2048）
    output wire          empty,      // 字空
    output wire [11:0]   word_count,
    output wire [8:0]    cmd_count
);
    localparam DEPTH = CMD_DEPTH * 8;     // 2048 字
    localparam AW    = $clog2(DEPTH);     // 11
    localparam ACW   = AW + 1;

    reg [31:0]   mem [0:DEPTH-1];
    reg [AW-1:0] wptr;
    reg [AW-1:0] rptr;
    reg [31:0]   rdata_r;
    reg [31:0]   dout_r;
    reg          out_v;
    reg          rd_pend;
    reg [ACW-1:0] mcnt;

    /* ---- 组合控制（先声明后引用） ---- */
    assign dout       = dout_r;
    assign empty      = !out_v;
    assign rd_ack     = rd_en && out_v;
    /* 占用 = mem 中未取 + 在飞 + 输出寄存器 */
    assign full       = ((mcnt + (rd_pend ? 1'b1 : 1'b0) + (out_v ? 1'b1 : 1'b0))
                         == DEPTH[ACW-1:0]);
    assign word_count = mcnt + (rd_pend ? 1'b1 : 1'b0) + (out_v ? 1'b1 : 1'b0);
    assign cmd_count  = word_count[AW:3];          // floor(word_count/8)

    wire do_wr = wr_en && !full;
    wire fetch = (!rd_pend) && (mcnt != 0);
    wire take  = rd_pend && !out_v;

    /* 存储同步读：必须最"干净"（无异步复位、无旁路 mux）才能推断成 BRAM。
     * 原设计想加"写穿透旁路"，但分析后不需要：fetch 只在 mcnt!=0 时发起，
     * 而 wptr==rptr 只发生在"空"或"满"两种情形 —— 满时写被 full 挡住，
     * 空时 fetch 不会发起，所以不存在"同拍写读同地址且数据被读到"的窗口。 */
    always @(posedge clk)
        rdata_r <= mem[rptr];          // 同步读 → 可推断 BRAM

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr    <= {AW{1'b0}};
            rptr    <= {AW{1'b0}};
            dout_r  <= 32'd0;
            out_v   <= 1'b0;
            rd_pend <= 1'b0;
            mcnt    <= {ACW{1'b0}};
        end else begin
            if (do_wr) begin
                mem[wptr] <= din;
                wptr      <= wptr + 1'b1;
            end
            if (fetch)
                rd_pend <= 1'b1;
            else if (take)
                rd_pend <= 1'b0;
            if (take) begin
                dout_r <= rdata_r;
                rptr   <= rptr + 1'b1;
                out_v  <= 1'b1;
            end else if (rd_ack)
                out_v <= 1'b0;
            mcnt <= mcnt + (do_wr ? 1'b1 : 1'b0) - (fetch ? 1'b1 : 1'b0);
        end
    end
endmodule
