/* =========================================================================
 * fbTest.c — CPU 写 DDR 帧缓冲 + HDMI 扫描输出动态画面 Demo
 * -------------------------------------------------------------------------
 * 链路：RISC-V(软核) → AXI → DDR3 帧缓冲(FB0=0x00301000, 960×540 RGB565)
 *       → fb_scanout(AXI 读) → 1080p 时序 + 黑边 → dvi_encoder(TMDS) → HDMI
 *
 * 画面内容（最简单的动态渲染）：
 *   - 背景：8 条竖向 RGB565 彩条（静态，用于确认"屏上确实是 DDR 里的数据"）
 *   - 元素1：大色块来回弹跳，颜色每帧轮换（8 色循环）
 *   - 元素2：小白块反向弹跳
 * 每帧结束后做一次"缓存冲刷"：先写 8KB 冲刷缓冲把 D$ 脏行挤出，再作废 D$，
 * 保证外部主设备（扫描输出）从 AXI 读到的是 DDR 里的最新画面。
 * ========================================================================= */
#include <stdint.h>
#include "bsp.h"
#include "userDef.h"
#include "vexriscv.h"          /* data_cache_invalidate_all() */

#define FB32   ((volatile uint32_t *)(FB_BASE))
#define FB16   ((volatile uint16_t *)(FB_BASE))

/* 8 条彩条（与板卡 03_hdmi_tx_demo 的 color_bar 同风格） */
static const uint16_t BARS[8] = {
    C_WHITE, C_YELLOW, C_CYAN, C_GREEN, C_MAGENTA, C_RED, C_BLUE, C_BLACK
};
/* 弹跳方块的颜色轮换表 */
static const uint16_t PAL8[8] = {
    C_RED, C_GREEN, C_BLUE, C_YELLOW, C_CYAN, C_MAGENTA, C_ORANGE, C_WHITE
};

#define BOX_W    160
#define BOX_H    120
#define BOX2_W   80
#define BOX2_H   80

/* ------------------------------------------------------------------ */
/* 按 32bit 写填充矩形（一次写 2 个像素，比逐像素快一倍） */
static void fill_rect(int x, int y, int w, int h, uint16_t color)
{
    uint32_t v = ((uint32_t)color << 16) | (uint32_t)color;
    int i, j;

    if (w <= 0 || h <= 0) return;
    if (x < 0) { w += x; x = 0; }                 /* 裁剪到屏内 */
    if (y < 0) { h += y; y = 0; }
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    if (w <= 0 || h <= 0) return;

    for (j = 0; j < h; j++) {
        volatile uint32_t *row = FB32 + (uint32_t)(y + j) * (FB_WIDTH / 2) + (x / 2);
        int n = w / 2;
        for (i = 0; i < n; i++) row[i] = v;
        if (w & 1)                                    /* 奇数宽：补最后一个像素 */
            FB16[(uint32_t)(y + j) * FB_WIDTH + x + w - 1] = color;
    }
}

/* 整屏画 8 条竖彩条：每条 120 像素 = 60 个 32bit 字 */
static void fill_bg_bars(void)
{
    int y, b, k;
    for (y = 0; y < FB_HEIGHT; y++) {
        volatile uint32_t *row = FB32 + (uint32_t)y * (FB_WIDTH / 2);
        for (b = 0; b < 8; b++) {
            uint32_t v = ((uint32_t)BARS[b] << 16) | (uint32_t)BARS[b];
            for (k = 0; k < (FB_WIDTH / 8) / 2; k++)
                row[b * ((FB_WIDTH / 8) / 2) + k] = v;
        }
    }
}

/* 把 D$ 里可能还脏着的画面数据挤到 DDR（8KB ≫ 4KB D$） */
static void cache_evict(void)
{
    volatile uint32_t *scratch = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < FLUSH_WORDS; i++)
        scratch[i] = 0xA5A50000UL + i;
}

/* 一致性自检：写模式 → 挤出缓存 → 作废 D$ → 回读比对（用 FB1，不破坏画面） */
static int coherency_check(void)
{
    volatile uint32_t *p = (volatile uint32_t *)FB1_BASE;
    uint32_t i;
    for (i = 0; i < 256; i++) p[i] = 0x5A5A0000UL + i;
    cache_evict();
    data_cache_invalidate_all();
    for (i = 0; i < 256; i++)
        if (p[i] != (0x5A5A0000UL + i)) return 0;
    return 1;
}

/* 帧间延时（空循环，粗略节流） */
static void frame_delay(void)
{
    volatile uint32_t i;
    for (i = 0; i < FRAME_DELAY_LOOPS; i++) { }
}

/* ------------------------------------------------------------------ */
void main(void)
{
    int x  = 0, y = 0, dx = 12, dy = 8;
    int x2 = FB_WIDTH - BOX2_W, y2 = FB_HEIGHT - BOX2_H, dx2 = -9, dy2 = -6;
    uint32_t frame = 0;

    bsp_printf("\r\n*** 2DRA: CPU writes DDR framebuffer -> HDMI scanout ***\r\n");
    bsp_printf("FB0=0x%x  FB1=0x%x  %dx%d RGB565  stride=%d  bytes=%d\r\n",
               (unsigned)FB_BASE, (unsigned)FB1_BASE,
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES);

    /* 1) 缓存一致性自检：确认"CPU 写的数据真的落到 DDR"（HDMI 读的是 DDR） */
    if (coherency_check())
        bsp_printf("coherency check: PASS (CPU writes reach DDR)\r\n");
    else
        bsp_printf("coherency check: FAIL -> 需按文档处理 D$ 一致性（write-back 需清理）\r\n");

    /* 2) 静态背景彩条（先确认屏上能显示 DDR 内容） */
    fill_bg_bars();
    cache_evict();
    bsp_printf("background color bars written, start animation ...\r\n");

    /* 3) 动态渲染主循环 */
    for (;;) {
        /* 背景重画（同时天然把上一帧的方块"擦掉"） */
        fill_bg_bars();

        /* 元素1：大色块弹跳，颜色每帧轮换 */
        x += dx;  y += dy;
        if (x <= 0)                    { x = 0;                   dx = -dx; }
        if (y <= 0)                    { y = 0;                   dy = -dy; }
        if (x >= FB_WIDTH  - BOX_W)    { x = FB_WIDTH  - BOX_W;    dx = -dx; }
        if (y >= FB_HEIGHT - BOX_H)    { y = FB_HEIGHT - BOX_H;    dy = -dy; }
        fill_rect(x, y, BOX_W, BOX_H, PAL8[frame & 7]);

        /* 元素2：小白块反向弹跳 */
        x2 += dx2; y2 += dy2;
        if (x2 <= 0)                    { x2 = 0;                    dx2 = -dx2; }
        if (y2 <= 0)                    { y2 = 0;                    dy2 = -dy2; }
        if (x2 >= FB_WIDTH  - BOX2_W)   { x2 = FB_WIDTH  - BOX2_W;    dx2 = -dx2; }
        if (y2 >= FB_HEIGHT - BOX2_H)   { y2 = FB_HEIGHT - BOX2_H;    dy2 = -dy2; }
        fill_rect(x2, y2, BOX2_W, BOX2_H, C_WHITE);

        /* 4) 本帧写完后把数据推入 DDR，再作废 D$（保证扫描输出读到新画面） */
        cache_evict();
        data_cache_invalidate_all();

        frame++;
        if ((frame % 30) == 0)
            bsp_printf("frame=%u  box=(%d,%d)  small=(%d,%d)\r\n",
                       (unsigned)frame, x, y, x2, y2);

        frame_delay();
    }
}
