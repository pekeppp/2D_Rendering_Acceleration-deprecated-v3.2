/* =========================================================================
 * blt_addr_gen.v — 行地址与覆盖突发参数（纯组合）
 * -------------------------------------------------------------------------
 * 给定矩形区域基址 base、行距 stride、行号 row、本行处理的**像素窗口**
 * [win_x0, win_x0+win_w)：
 *   row_start   = base + row*stride + win_x0*2
 *   aligned_base= row_start 向下 16B 对齐（读覆盖 & 写突发起始）
 *   byte_off    = row_start[3:0]（行首在 16B 字内的字节偏移，像素对齐时为偶数）
 *   px_skip     = 读流起始 lane = byte_off/2（0..7，首拍丢弃的像素数）
 *   cover_beats = 覆盖 [row_start, row_start+win_w*2) 所需的 16B 拍数
 * 假设：像素 2B；行距 16B 对齐与否皆可（每行独立计算）。
 *
 * ★S3（v2.12）：新增 win_x0 / win_w 两个输入 = **本行的绘制窗口**。
 *   窗口是"透明块跳过"的落地方式：窗口之外的像素既不取数、也不算、也不写。
 *   · 未启用掩码时调用方传 win_x0=0、win_w=W ⇒ 输出与 v2.11 **逐位相同**
 *     （v2.11 的 row_bytes 输入等价于 win_w*2，已由 win_w 取代）。
 *   · win_w=0（整行 4 个列块全透明）⇒ cover_beats=0：这一行一个 beat 都不取，
 *     引擎侧同时不会启动像素通路（见 blt_engine_fsm 的 RS_LOOP 空窗口分支）。
 * ========================================================================= */
module blt_addr_gen (
    input  wire [31:0]  base,
    input  wire [31:0]  stride,
    input  wire [15:0]  row,
    input  wire [15:0]  win_x0,             // ★S3：本行窗口起始像素（未启用掩码时恒 0）
    input  wire [15:0]  win_w,              // ★S3：本行窗口宽度（像素；未启用掩码时 = W）
    output wire [31:0]  row_start,
    output wire [31:0]  aligned_base,
    output wire [3:0]   byte_off,
    output wire [2:0]   px_skip,
    output wire [15:0]  cover_beats
);
    wire [31:0] row_s  = base + stride * {16'd0, row} + {16'd0, win_x0} * 32'd2;
    wire [31:0] end_b  = row_s + {16'd0, win_w} * 32'd2;      // 末字节后一字节（独占）
    wire [31:0] a_base = {row_s[31:4], 4'b0};

    assign row_start    = row_s;
    assign aligned_base = a_base;
    assign byte_off     = row_s[3:0];
    /* px_skip = 行首在 16B 词内的**像素**序号 = byte_off/2 = row_s[3:1]（3 bit，0..7）。
     * 原写法 row_s[2:1] 只取了 2 bit（= lane & 3），凡是 byte_off >= 8（lane>=4）的
     * 行首都会被算成 lane-4，整行水平错位 4 像素。 */
    assign px_skip      = row_s[3:1];                // 偶数偏移 → 半字索引 0..7
    /* beats = ceil(end/16) - floor(start/16)；空窗口（win_w=0）⇒ 0 拍：
     * 此时 [row_s, row_s) 是空区间，上面那条减法会算出 1（未对齐）或 0（已对齐），
     * 必须显式钳到 0，否则引擎会为"整行全透明"白取一拍。 */
    assign cover_beats  = (win_w == 16'd0) ? 16'd0 :
                          (((end_b + 15) >> 4) - (row_s >> 4));
endmodule
