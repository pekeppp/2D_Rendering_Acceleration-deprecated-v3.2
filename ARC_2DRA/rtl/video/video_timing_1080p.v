/* =========================================================================
 * video_timing_1080p.v — 1080p@60 (CEA-861) 视频时序发生器
 * -------------------------------------------------------------------------
 * 默认参数：1920×1080@60，像素时钟 148.75MHz（由板上 25MHz 经 PLL_BR0 生成，
 * 与板卡 03_hdmi_tx_demo 的 pll_hdmi 配置一致 → 实际约 60.1Hz，显示器可锁）。
 *   H: 1920 + 前肩88 + 同步44 + 后肩148 = 2200
 *   V: 1080 + 前肩4  + 同步5  + 后肩36  = 1125
 * 极性：HSYNC/VSYNC 均为正极性（CEA-861 1080p60）。
 * ========================================================================= */
`timescale 1ns/1ps
module video_timing_1080p #(
    parameter H_ACTIVE = 12'd1920,
    parameter H_FP     = 12'd88,
    parameter H_SYNC   = 12'd44,
    parameter H_BP     = 12'd148,
    parameter V_ACTIVE = 12'd1080,
    parameter V_FP     = 12'd4,
    parameter V_SYNC   = 12'd5,
    parameter V_BP     = 12'd36
)(
    input  wire         pclk,
    input  wire         prst_n,
    output reg  [11:0]  hcnt,
    output reg  [11:0]  vcnt,
    output wire         de,           // 有效像素区
    output wire         hs,           // 行同步（正极性）
    output wire         vs,           // 场同步（正极性）
    output wire         line_start,   // 行首 1 拍脉冲
    output wire         frame_start   // 帧首 1 拍脉冲
);
    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

    always @(posedge pclk or negedge prst_n) begin
        if (!prst_n) begin
            hcnt <= 12'd0;
            vcnt <= 12'd0;
        end else if (hcnt == H_TOTAL - 12'd1) begin
            hcnt <= 12'd0;
            if (vcnt == V_TOTAL - 12'd1)
                vcnt <= 12'd0;
            else
                vcnt <= vcnt + 12'd1;
        end else begin
            hcnt <= hcnt + 12'd1;
        end
    end

    assign de          = (hcnt < H_ACTIVE) && (vcnt < V_ACTIVE);
    assign hs          = (hcnt >= H_ACTIVE + H_FP) &&
                         (hcnt <  H_ACTIVE + H_FP + H_SYNC);
    assign vs          = (vcnt >= V_ACTIVE + V_FP) &&
                         (vcnt <  V_ACTIVE + V_FP + V_SYNC);
    assign line_start  = (hcnt == 12'd0);
    assign frame_start = (hcnt == 12'd0) && (vcnt == 12'd0);
endmodule
