/* =========================================================================
 * fbTest.c — CPU 写 DDR 帧缓冲 + HDMI 扫描输出动态画面 Demo（v3）
 * -------------------------------------------------------------------------
 * 链路：RISC-V(软核) → AXI → DDR3 帧缓冲(FB0=0x00301000, 960×540 RGB565)
 *       → fb_scanout(AXI 读) → 1080p 时序 + 黑边 → dvi_encoder(TMDS) → HDMI
 *
 * 上板实测（v2）：静态画面（彩条+白框+右上角固定红块）正确上屏，但画面不动、
 * 串口停在 "static pattern" 之后再无输出。静态画面 = 循环之前的
 * draw_static_marks()，而循环体第一个动作就是把 120×90 方块画到左上角 (8,8)
 * —— 屏上没有它 ⇒ 程序根本没走完循环第一轮；日志停住的下一条语句正好是
 * t_prev = csr_read(mcycle)。
 *
 * v3 的三点改动（都为了让"卡在哪"变成可观测事实，而不是猜测）：
 *   ① 时间基准从 mcycle CSR 换成 CLINT mtime（clint_getTime(BSP_CLINT)，纯 MMIO 读）。
 *      mcycle 属于可选实现的 CSR，读未实现 CSR 会触发非法指令异常 → 程序直接
 *      停死、串口什么都不再打印，与现象完全吻合；mtime 是 SoC 必备外设
 *      （SYSTEM_CLINT_HZ），普通 load，不可能陷入异常。
 *   ② 全流程分步打印 + 时间基准自检 + 实时上屏"闪烁自检"：后者在固定位置
 *      画块→延时→擦除 3 次，专门验证"运行中的 CPU 写 → 扫描输出立刻可见"
 *      这条实时通路（不依赖动画循环）。
 *   ③ 实测写入开销（写 4096 个 32bit 字测 ticks/word），并据此预算每帧
 *      ticks 与 fps，与实测值对照 —— 若帧率低，就知道该优化哪一项。
 *   节流循环带次数上限，即使时间基准异常也不会卡死（会退化成空循环延时）。
 *   ④ v4：擦除动态方块时会把"静态标记"按相交区域补画回来。原先 restore_bg()
 *      只铺彩条，大方块移动范围会压过固定红块 (820..931 × 16..95)，擦除把红块
 *      涂成彩条后就再没恢复 → 现象是"红块被移动方块碰到才消失，且方块走后不回来"。
 *      层次固定为：彩条(底) < 静态标记 < 动态方块(顶)。
 * ========================================================================= */
#include <stdint.h>
#include "bsp.h"               /* 已包含 clint.h（clint_getTime / clint_uDelay） */
#include "userDef.h"
#include "vexriscv.h"          /* data_cache_invalidate_all() */

#define FB32   ((volatile uint32_t *)(FB_BASE))
#define FB16   ((volatile uint16_t *)(FB_BASE))

/* CLINT 时间基准：BSP_CLINT + 0xBFF8 = mtime，BSP_CLINT_HZ = 100MHz。
 * 厂商 coremark/dhrystone 用的就是 clint_getTime(BSP_CLINT)，这里保持一致。 */
#define TICK_HZ          BSP_CLINT_HZ
#define FRAME_TICKS      (TICK_HZ / 60)               /* ≈60fps */

/* 8 条竖彩条（与板卡 03_hdmi_tx_demo 的 color_bar 同风格） */
static const uint16_t BARS[8] = {
    C_WHITE, C_YELLOW, C_CYAN, C_GREEN, C_MAGENTA, C_RED, C_BLUE, C_BLACK
};
/* 弹跳方块的颜色轮换表 */
static const uint16_t PAL8[8] = {
    C_RED, C_GREEN, C_BLUE, C_YELLOW, C_CYAN, C_MAGENTA, C_ORANGE, C_WHITE
};

/* 静态标记：屏幕四周留白边框，动态方块被限制在边框内，永不被覆盖 */
#define BORDER   8
/* 动态元素尺寸（宽/高都取偶数，保证 32bit 写像素对齐） */
#define BOX_W    120
#define BOX_H    90
#define BOX2_W   60
#define BOX2_H   60

/* 静态固定红块的位置/尺寸：draw_static_marks() 画它，restore_bg() 也要按它补画，
 * 所以必须写成同一份常量，避免两处不一致。 */
#define MARK_X   (FB_WIDTH - 140)
#define MARK_Y   (BORDER + 8)
#define MARK_W   112
#define MARK_H   80

/* 彩条宽度（像素）= FB_WIDTH/8 = 120 */
#define BAR_COLS      (FB_WIDTH / 8)

/* ------------------------------------------------------------------ */
static uint64_t tick(void)
{
    return clint_getTime(BSP_CLINT);
}

/* 用 32bit 写填充矩形（x、w 为偶数时完全对齐；奇数宽补最后一像素） */
static void fill_rect(int x, int y, int w, int h, uint16_t color)
{
    uint32_t v = ((uint32_t)color << 16) | (uint32_t)color;
    int i, j;

    if (w <= 0 || h <= 0) return;
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    if (w <= 0 || h <= 0) return;

    for (j = 0; j < h; j++) {
        volatile uint32_t *row = FB32 + (uint32_t)(y + j) * (FB_WIDTH / 2) + (x / 2);
        int n = w / 2;
        for (i = 0; i < n; i++) row[i] = v;
        if (w & 1)
            FB16[(uint32_t)(y + j) * FB_WIDTH + x + w - 1] = color;
    }
}

/* 把"静态标记"按与 (x,y,w,h) 的相交区域补画回来。
 * 为什么会需要它：restore_bg() 擦动态方块时是"整块铺回彩条"，它并不知道那里
 * 还有一层静态标记；大方块的移动范围 (x 到 832) 会压过固定红块 (x 820..931)，
 * 于是擦除会把红块涂成彩条，而 draw_static_marks() 只在开机时执行过一次 ——
 * 红块就此永久消失（现象：红块被移动方块"碰"到才不见，方块走后也不回来）。
 * 层次关系应当是：彩条(底) < 静态标记 < 动态方块(顶)。 */
static void redraw_marks(int x, int y, int w, int h)
{
    int sx = (x > MARK_X) ? x : MARK_X;
    int sy = (y > MARK_Y) ? y : MARK_Y;
    int ex = ((x + w - 1) < (MARK_X + MARK_W - 1)) ? (x + w - 1) : (MARK_X + MARK_W - 1);
    int ey = ((y + h - 1) < (MARK_Y + MARK_H - 1)) ? (y + h - 1) : (MARK_Y + MARK_H - 1);

    if (sx > ex || sy > ey) return;
    fill_rect(sx, sy, ex - sx + 1, ey - sy + 1, C_RED);
}

/* 用彩条颜色恢复矩形（擦除动态元素）。彩条是竖条，按列分段落填充。 */
static void restore_bg(int x, int y, int w, int h)
{
    int b, j, k, n;

    if (w <= 0 || h <= 0) return;
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    if (w <= 0 || h <= 0) return;

    for (b = 0; b < 8; b++) {
        int bx0 = b * BAR_COLS;
        int bx1 = bx0 + BAR_COLS - 1;
        int sx  = (x > bx0) ? x : bx0;
        int ex  = ((x + w - 1) < bx1) ? (x + w - 1) : bx1;
        uint16_t c;
        uint32_t v;

        if (sx > ex) continue;
        c = BARS[b];
        v = ((uint32_t)c << 16) | (uint32_t)c;
        n = (ex - sx + 1) / 2;
        for (j = y; j < y + h; j++) {
            volatile uint32_t *row = FB32 + (uint32_t)j * (FB_WIDTH / 2) + (sx / 2);
            for (k = 0; k < n; k++) row[k] = v;
            if ((ex - sx + 1) & 1)
                FB16[(uint32_t)j * FB_WIDTH + ex] = c;
        }
    }

    /* 铺完彩条后，把被这次擦除波及的静态标记补回（否则红块永久消失） */
    redraw_marks(x, y, w, h);
}

/* 静态背景：整屏 8 条竖彩条（只在开机时画一次） */
static void draw_bars(void)
{
    int y, b, k;
    for (y = 0; y < FB_HEIGHT; y++) {
        volatile uint32_t *row = FB32 + (uint32_t)y * (FB_WIDTH / 2);
        for (b = 0; b < 8; b++) {
            uint32_t v = ((uint32_t)BARS[b] << 16) | (uint32_t)BARS[b];
            for (k = 0; k < BAR_COLS / 2; k++)
                row[b * (BAR_COLS / 2) + k] = v;
        }
    }
}

/* 静态标记：白色边框 + 固定红块（证明"非彩条的 CPU 写内容"也能上屏）
 * 注意：红块用的是 MARK_* 常量，restore_bg() 里补画用的是同一份 —— 两处必须一致。 */
static void draw_static_marks(void)
{
    fill_rect(0, 0, FB_WIDTH, BORDER, C_WHITE);                      /* 上边 */
    fill_rect(0, FB_HEIGHT - BORDER, FB_WIDTH, BORDER, C_WHITE);     /* 下边 */
    fill_rect(0, 0, BORDER, FB_HEIGHT, C_WHITE);                     /* 左边 */
    fill_rect(FB_WIDTH - BORDER, 0, BORDER, FB_HEIGHT, C_WHITE);     /* 右边 */
    fill_rect(MARK_X, MARK_Y, MARK_W, MARK_H, C_RED);                /* 固定红块 */
}

/* 把 D$ 中可能还脏着的画面数据挤到 DDR（写 8KB ≫ 4KB D$） */
static void cache_evict(void)
{
    volatile uint32_t *scratch = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < FLUSH_WORDS; i++)
        scratch[i] = 0xA5A50000UL + i;
}

/* 一致性自检：写模式 → 挤出缓存 → 作废 D$ → 从 DDR 回读比对（用 FB1，不动画面） */
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

/* ------------------------------------------------------------------ */
void main(void)
{
    int x = BORDER, y = BORDER;
    int dx = 16, dy = 12;
    int x2 = FB_WIDTH - BORDER - BOX2_W, y2 = FB_HEIGHT - BORDER - BOX2_H;
    int dx2 = -12, dy2 = -8;
    uint32_t frame = 0, draw_cyc, period_cyc;
    uint32_t probe_cyc, words, est_ticks, i, guard;
    uint64_t t0, t_prev, ta, tb;
    int throttle, ok;
    volatile uint32_t sink;

    bsp_printf("\r\n*** 2DRA: CPU writes DDR framebuffer -> HDMI scanout (v4) ***\r\n");
    bsp_printf("FB0=0x%x FB1=0x%x %dx%d RGB565 stride=%d bytes=%d\r\n",
               (int)FB_BASE, (int)FB1_BASE,
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES);

    /* ---- 步骤 1：时间基准自检（换掉 mcycle：读未实现 CSR 会触发异常死机）---- */
    sink = 0;
    ta   = tick();
    for (i = 0; i < 20000u; i++) sink += i;      /* volatile 累加，防止被优化掉 */
    tb   = tick();
    throttle = ((uint32_t)(tb - ta) > 1000u);
    bsp_printf("step1 timebase: CLINT@0x%x mtime, 20000-loop = %d ticks -> %s\r\n",
               (int)BSP_CLINT, (int)(uint32_t)(tb - ta),
               throttle ? "OK" : "BAD(use delay loop)");

    /* ---- 步骤 2：一致性自检（CPU 写 → 挤出 D$ → 回读）---- */
    ok = coherency_check();
    bsp_printf("step2 coherency check: %s\r\n", ok ? "PASS" : "FAIL");

    /* ---- 步骤 3：实测单次 32bit 写 DDR 的开销（用 FB1，不影响画面）---- */
    ta = tick();
    for (i = 0; i < 4096u; i++)
        ((volatile uint32_t *)FB1_BASE)[i] = 0x12340000UL + i;
    tb = tick();
    probe_cyc = (uint32_t)(tb - ta);
    bsp_printf("step3 write probe: 4096 words in %d ticks = %d ticks/word\r\n",
               (int)probe_cyc, (int)(probe_cyc / 4096u));

    /* 每帧写次数预算：两个方块各"擦一次+画一次" + 冲刷缓冲 */
    words     = ((uint32_t)(BOX_W * BOX_H) / 2u + (uint32_t)(BOX2_W * BOX2_H) / 2u) * 2u
                + FLUSH_WORDS;
    est_ticks = words * (probe_cyc / 4096u);
    bsp_printf("step3 budget: %d words/frame -> est %d ticks/frame (~%d fps)\r\n",
               (int)words, (int)est_ticks,
               (est_ticks ? (int)(TICK_HZ / est_ticks) : 0));

    /* ---- 步骤 4：静态画面（彩条 + 白边框 + 固定红块），并计时 ---- */
    ta = tick();
    draw_bars();
    tb = tick();
    bsp_printf("step4 bars: %d words in %d ticks (%d ticks/word avg)\r\n",
               (int)FB_WORDS, (int)(uint32_t)(tb - ta),
               (int)((uint32_t)(tb - ta) / FB_WORDS));

    ta = tick();
    draw_static_marks();
    cache_evict();
    tb = tick();
    bsp_printf("step4 marks+flush done in %d ticks; static pattern on screen\r\n",
               (int)(uint32_t)(tb - ta));

    /* ---- 步骤 5：实时上屏自检（画块→延时→擦除 ×3）----
     * 不经过动画循环，直接验证"运行中的 CPU 写 → 扫描输出立刻可见"。 */
    bsp_printf("step5 blink test: watch the screen for 3 blinks...\r\n");
    for (i = 0; i < 3u; i++) {
        fill_rect(400, 240, 160, 120, C_MAGENTA);
        cache_evict();
        bsp_printf("  blink %d ON\r\n", (int)(i + 1u));
        if (throttle) clint_uDelay(500000u, TICK_HZ, BSP_CLINT);
        restore_bg(400, 240, 160, 120);
        cache_evict();
        bsp_printf("  blink %d OFF\r\n", (int)(i + 1u));
        if (throttle) clint_uDelay(300000u, TICK_HZ, BSP_CLINT);
    }

    /* ---- 步骤 6：动态渲染主循环 ---- */
    bsp_printf("step6 entering main loop\r\n");
    t_prev = tick();

    for (;;) {
        t0 = tick();

        /* 1) 擦除上一帧的两个方块（用彩条颜色恢复背景） */
        restore_bg(x,  y,  BOX_W,  BOX_H);
        restore_bg(x2, y2, BOX2_W, BOX2_H);

        /* 2) 更新位置（弹跳；限制在白色边框内，避免压到静态标记） */
        x += dx;  y += dy;
        if (x < BORDER) { x = BORDER; dx = -dx; }
        if (y < BORDER) { y = BORDER; dy = -dy; }
        if (x > FB_WIDTH  - BORDER - BOX_W)  { x = FB_WIDTH  - BORDER - BOX_W;  dx = -dx; }
        if (y > FB_HEIGHT - BORDER - BOX_H)  { y = FB_HEIGHT - BORDER - BOX_H;  dy = -dy; }

        x2 += dx2; y2 += dy2;
        if (x2 < BORDER) { x2 = BORDER; dx2 = -dx2; }
        if (y2 < BORDER) { y2 = BORDER; dy2 = -dy2; }
        if (x2 > FB_WIDTH  - BORDER - BOX2_W) { x2 = FB_WIDTH  - BORDER - BOX2_W; dx2 = -dx2; }
        if (y2 > FB_HEIGHT - BORDER - BOX2_H) { y2 = FB_HEIGHT - BORDER - BOX2_H; dy2 = -dy2; }

        /* 3) 画新位置：大色块每帧换色 + 小白块 */
        fill_rect(x,  y,  BOX_W,  BOX_H,  PAL8[frame & 7u]);
        fill_rect(x2, y2, BOX2_W, BOX2_H, C_WHITE);

        /* 4) 把本帧数据推入 DDR（不再调用 invalidate！） */
        cache_evict();

        draw_cyc = (uint32_t)(tick() - t0);
        frame++;

        /* 5) 前 3 帧 + 每 60 帧打印统计 */
        if (frame <= 3u || (frame % 60u) == 0u) {
            period_cyc = (uint32_t)(tick() - t_prev);
            t_prev = tick();
            bsp_printf("frame=%d box=(%d,%d) small=(%d,%d) draw=%d cyc period=%d cyc (~%d fps)\r\n",
                       (int)frame, x, y, x2, y2,
                       (int)draw_cyc, (int)period_cyc,
                       (period_cyc ? (int)(TICK_HZ / period_cyc) : 0));
        }

        /* 6) 按固定周期节流（≈60fps）；带次数上限，时间基准异常也不卡死 */
        if (throttle) {
            guard = 0;
            while ((uint32_t)(tick() - t0) < FRAME_TICKS) {
                if (++guard > 40000000UL) break;
            }
        } else {
            sink = 0;
            for (i = 0; i < FRAME_DELAY_LOOPS; i++) sink += i;
        }
    }
}
