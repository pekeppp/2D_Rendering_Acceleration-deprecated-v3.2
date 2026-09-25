/* =========================================================================
 * sync_fifo.v — 参数化同步 FIFO（**BRAM 可推断版**：同步读 + 输出寄存器）
 * -------------------------------------------------------------------------
 * 为什么改：原版是 `assign dout = mem[rptr];` 的**异步读**。Titanium 的块 RAM
 * 不支持异步读，综合器只能把整个存储拆成寄存器阵列 —— 256×128bit 的 FIFO
 * 会变成 32768 个 FF + 巨大的读多路选择器，两块就把 60800 的器件容量撑爆
 * （实测网表里没有 BRAM 原语、u_src_fifo 相关行数 36 万）。
 *
 * 本版的存储访问全部是**同步读**（读地址在 rptr，读数据寄存一拍），
 * 因此可被 Efinity 推断成块 RAM；对外仍是 FWFT 语义：
 *   - dout 有效 ⟺ !empty；count != 0 ⟺ !empty（上层只需看 count/empty）
 *   - rd_en 请求弹字，**确实弹出时 rd_ack 拉高**（存储读有 1 拍流水，
 *     连续弹字约 1 字/2 拍 —— 对"每 8 像素才弹一词"的像素通路、
 *     以及按拍收集的写主机都远远够用）
 *   - 弹字计数请用 rd_ack（或"先看 !empty 再弹"），不要假设每拍必出字
 * ========================================================================= */
module sync_fifo #(
    parameter DW    = 32,      // 数据位宽
    parameter DEPTH = 16       // 深度（2 的幂）
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   wr_en,
    input  wire [DW-1:0]          din,
    input  wire                   rd_en,
    output wire                   rd_ack,     // 本拍确实弹出了一个字
    output wire [DW-1:0]          dout,
    output wire                   full,
    output wire                   empty,
    output wire [$clog2(DEPTH):0] count
);
    localparam AW  = $clog2(DEPTH);
    localparam ACW = AW + 1;

    /* mem 的读写都是同步访问 → 可推断 BRAM */
    reg [DW-1:0]  mem [0:DEPTH-1];
    reg [AW-1:0]  wptr;            // 写地址
    reg [AW-1:0]  rptr;            // **待取入输出寄存器**的地址
    reg [DW-1:0]  rdata_r;         // BRAM 读数据（寄存）
    reg [DW-1:0]  dout_r;          // 输出寄存器 = 队头
    reg           out_v;           // 队头有效
    reg           rd_pend;         // 已向 BRAM 发起读，下一拍数据到
    reg [ACW-1:0] mcnt;            // mem 中"尚未取入输出寄存器"的字数

    /* ---- 组合控制（必须在被引用之前声明） ---- */
    assign dout   = dout_r;
    assign empty  = !out_v;
    assign rd_ack = rd_en && out_v;
    /* 占用 = mem 中未取(mcnt) + 在飞(rd_pend) + 输出寄存器(out_v) */
    assign full   = ((mcnt + (rd_pend ? 1'b1 : 1'b0) + (out_v ? 1'b1 : 1'b0))
                     == DEPTH[ACW-1:0]);
    assign count  = mcnt + (rd_pend ? 1'b1 : 1'b0) + (out_v ? 1'b1 : 1'b0);

    wire do_wr = wr_en && !full;
    wire fetch = (!rd_pend) && (mcnt != 0);     // 发起一次 BRAM 读
    wire take  = rd_pend && !out_v;             // 数据到 → 装入输出寄存器

    /* 存储同步读：**必须是最"干净"的形式**才能被推断成 BRAM ——
     *   - 只有时钟、没有异步复位（Titanium 的 BRAM 输出寄存器不支持异步复位，
     *     一旦带上 reset，工具会直接放弃推断、把整块存储拆成寄存器阵列）
     *   - 读数据路径上不要加 mux/旁路
     * 同理 mem 数组本身绝不复位。 */
    always @(posedge clk)
        rdata_r <= mem[rptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr    <= {AW{1'b0}};
            rptr    <= {AW{1'b0}};
            dout_r  <= {DW{1'b0}};
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
            /* 计数：写入 +1、取入输出寄存器 -1（写与取可同拍，用一条表达式） */
            mcnt <= mcnt + (do_wr ? 1'b1 : 1'b0) - (fetch ? 1'b1 : 1'b0);
        end
    end
endmodule
