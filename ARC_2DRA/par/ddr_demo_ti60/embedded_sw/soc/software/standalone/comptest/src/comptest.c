/* =============================================================================
 * comptest.c — 「纯 CPU 软件渲染」vs「硬件 BitBlt 加速」帧率对比 Demo
 * -----------------------------------------------------------------------------
 * 赛题要求：基础测试 Demo（大量方块随机移动 / 大图快速切换）+ 屏上实时对比
 *          "纯软件 CPU 渲染"与"硬件加速渲染"的帧率差异。
 *
 * ★ 本版的三条硬规矩（都是上板踩坑换来的）：
 *   1) **CPU 永远不写"正在显示的那块帧缓冲"（FB_BASE）**。显示缓冲只由引擎写。
 *      fulltest 能一直跑就是因为它所有 CPU 侧帧缓冲写都写向屏外缓冲 FB1_BASE；
 *      comptest 早期版本让 CPU 直接往显示缓冲连续写，结果开机一两秒后整机卡死
 *      （CPU 写把 DDR 写队列灌满 → 扫描输出一行取数收不齐 → v1.0 的取数 FSM 卡在
 *       S_FETCH、s_hold 恒高 → CPU 再也拿不到 DDR 读通道。整份程序都在 DDR 里，
 *       所以那是整机死）。
 *   2) **CPU 模式 = 画进屏外缓冲 + 引擎整屏 COPY 上屏**。FB1/FB2 双缓冲，
 *      CPU 往空闲那块画、引擎同时搬另一块，两者流水重叠；每块有**自己的场景状态**，
 *      互不干扰，也不会撕裂。
 *   3) **OSD 也画在屏外缓冲**，硬件模式只让引擎搬最上面 960x16 那一条（30KB）上屏。
 *      ⇒ 显示缓冲的每一个像素都出自引擎。
 *
 * 两种模式（板载按键或串口切换）：
 *   ① CPU 渲染：CPU 32bit 直写屏外缓冲画方块 → 引擎整屏 COPY 到显示缓冲
 *   ② 硬件加速：CPU 只下发 FILL 指令，引擎直接渲染到显示缓冲
 *   两种模式用**同一个场景、同一个 N**，口径一致，fps 可直接对比。
 *
 * 显示：帧缓冲仍是 960x540，扫描输出按 2 倍最近邻放大铺满 1920x1080（无黑边），
 *       DDR 读带宽不变（仍只读 1MB/帧）；OSD 的 8x8 字模在屏上是 16x16。
 *
 * 按键（低有效，按下 = 0，已做软件消抖）：
 *   soc_gpio[0] = GPIOR_22 → 切换模式(CPU/硬件)
 *   soc_gpio[1] = GPIOR_21 → N(方块数) +25
 *   soc_gpio[2] = GPIOL_03 → 场景复位
 * 串口（作为备用，按键没接好时也能演示）：
 *   'm' 切模式 / 'n' 或 '+' N+25 / '-' N-25 / 'r' 场景复位
 *
 * ★★ printf 雷区（BSP 的 print.h 是 mini 版）：**只认 %c %s %d %X %x**。
 *    出现 %u / 宽度数字 / %% 时，它会跳过这些字符继续找下一个能认的说明符，
 *    于是多吃/少吃 va_arg → 后面的 %s 拿到整数当指针 → 直接挂死。
 *    本文件**所有**格式串都只用那五种说明符，且一个多余的 % 都没有。
 * ============================================================================= */

#include <stdint.h>
#include "bsp.h"
/* 必须包含：IDE 把 SYSTEM_GPIO_A_APB 定义为 SYSTEM_GPIO_0_IO_APB，而这个名字只有
 * 厂商的 compatibility.h 里才有映射（→ SYSTEM_GPIO_0_IO_CTRL）。少这个头会报
 * "'SYSTEM_GPIO_0_IO_APB' undeclared"。 */
#include "compatibility.h"

/* ============================== 地址与寄存器 ============================== */
#define FB_WIDTH      960
#define FB_HEIGHT     540
#define FB_STRIDE     (FB_WIDTH * 2)               /* 1920 B/行 */

#define DDR_BASE      0x00001000UL
#define FB_BASE       (DDR_BASE + 0x00300000UL)    /* 显示缓冲：**只由引擎写** */
#define FB1_BASE      (DDR_BASE + 0x00400000UL)    /* 屏外缓冲 A：CPU 画这里 */
#define FB2_BASE      (DDR_BASE + 0x00500000UL)    /* 屏外缓冲 B：CPU 画这里 */
#define FLUSH_SCRATCH (DDR_BASE + 0x00600000UL)    /* 缓存写穿屏障用的 8KB 临时区 */
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)

#define BLT_BASE      0xF8100000UL
#define BLT_CTRL            0x00
#define   BLT_CTRL_GO       (1UL << 0)
#define   BLT_CTRL_SOFT_RST (1UL << 2)
#define BLT_STATUS          0x04
#define   BLT_STATUS_ERR        (1UL << 2)
#define   BLT_STATUS_DONE       (1UL << 1)
#define   BLT_STATUS_FIFO_EMPTY (1UL << 3)
#define BLT_CMD_FIFO_DATA   0x08
#define BLT_CMD_FIFO_COUNT  0x0C
#define BLT_IRQ_STATUS      0x10
#define BLT_IRQ_EN          0x14
#define BLT_FIFO_DEPTH      256

#define BLT_OP_COPY   0UL
#define BLT_OP_FILL   1UL

#define COL_BG        0x0008u                      /* 背景（深蓝黑，非纯黑） */
#define COL_OSD_BG    0x0000u
#define COL_CPU_FG    0x07FFu                      /* 青色：CPU 模式 */
#define COL_HW_FG     0xFFE0u                      /* 黄色：硬件模式 */

#define OSD_H         16                           /* 状态条高度（帧缓冲像素） */
#define OSD_Y0        0

#define N_MIN   25
#define N_STEP  25
#define N_MAX   400
#define MAXBLK  N_MAX

/* ============================== 基础原语 ============================== */
static uint64_t tick(void) { return clint_getTime(BSP_CLINT); }

static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }

/* CPU 写完 DDR 后、引擎紧接着要读的场合调用（D$ 是写穿，本质是 store 有序屏障） */
static void cache_evict(void)
{
    volatile uint32_t *s = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
}

/* ============================== 引擎指令 ============================== */
/* 连续 8 个字写进指令 FIFO，中间不插别的访问 */
static void blt_emit(uint32_t op, uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                     uint32_t w, uint32_t h, uint32_t alpha, uint32_t color)
{
    blt_wr(BLT_CMD_FIFO_DATA, op);
    blt_wr(BLT_CMD_FIFO_DATA, src);
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    blt_wr(BLT_CMD_FIFO_DATA, color);
}
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
static int blt_idle(void)
{
    uint32_t st = blt_stat();
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
}
/* ★ 每条指令写 8 个字之前先确认 FIFO 有空间：FIFO 满时写 DATA 会把 CPU 挂在 APB 上，
 *   引擎一旦不动整个主循环就死在那里（表现为"画面不动 + 串口没反应"）。 */
#define HW_FIFO_MARGIN 56
static int blt_can_push(void)
{
    return (blt_cnt() <= (uint32_t)(BLT_FIFO_DEPTH - HW_FIFO_MARGIN - 1)) ? 1 : 0;
}
static void blt_init(void)
{
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    blt_wr(BLT_IRQ_STATUS, 1u);                        /* W1C */
    blt_wr(BLT_IRQ_EN, 0u);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
}
/* 一条整屏 COPY（屏外缓冲 → 显示缓冲） */
static void blt_copy_full(uint32_t src, uint32_t dst)
{
    blt_emit(BLT_OP_COPY, src, dst, FB_STRIDE, FB_STRIDE,
             FB_WIDTH, FB_HEIGHT, 0xFFu, 0u);
}
/* 只搬 OSD 那一条（960x16，30KB）—— 硬件模式下让状态条也由引擎上屏 */
static void blt_copy_osd(uint32_t src, uint32_t dst)
{
    blt_emit(BLT_OP_COPY, src, dst, FB_STRIDE, FB_STRIDE,
             FB_WIDTH, OSD_H, 0xFFu, 0u);
}
static void blt_fill(uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{
    blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color);
}

/* ============================== 8x8 字体 ============================== */
typedef struct { char c; uint8_t r[8]; } glyph_t;

static const glyph_t g_font[] = {
    { ' ', {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00} },
    { '0', {0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00} },
    { '1', {0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00} },
    { '2', {0x3C,0x66,0x06,0x0C,0x18,0x30,0x7E,0x00} },
    { '3', {0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00} },
    { '4', {0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00} },
    { '5', {0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00} },
    { '6', {0x1C,0x30,0x60,0x7C,0x66,0x66,0x3C,0x00} },
    { '7', {0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0x00} },
    { '8', {0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00} },
    { '9', {0x3C,0x66,0x66,0x3E,0x06,0x0C,0x38,0x00} },
    { 'A', {0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00} },
    { 'B', {0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00} },
    { 'C', {0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00} },
    { 'D', {0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00} },
    { 'E', {0x7E,0x60,0x60,0x78,0x60,0x60,0x7E,0x00} },
    { 'F', {0x7E,0x60,0x60,0x78,0x60,0x60,0x60,0x00} },
    { 'G', {0x3C,0x66,0x60,0x6E,0x66,0x66,0x3C,0x00} },
    { 'H', {0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00} },
    { 'I', {0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00} },
    { 'K', {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00} },
    { 'L', {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00} },
    { 'M', {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00} },
    { 'N', {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00} },
    { 'O', {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'P', {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00} },
    { 'R', {0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00} },
    { 'S', {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00} },
    { 'T', {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00} },
    { 'U', {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'W', {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00} },
    { 'X', {0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00} },
    { 'Y', {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00} },
    { '=', {0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00} },
    { '.', {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00} },
    { ':', {0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00} },
    { '/', {0x06,0x0C,0x18,0x30,0x60,0x40,0x00,0x00} },
    { '-', {0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00} },
};
#define FONT_N ((int)(sizeof(g_font)/sizeof(g_font[0])))

static const uint8_t *glyph_of(char c)
{
    int i;
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    return g_font[0].r;
}

/* ============================== CPU 侧绘制（直写屏外缓冲） ==============================
 * ★★ 只往屏外缓冲画（base 参数），显示缓冲永远不碰。
 *
 * ★★ 对齐陷阱（本 Demo 卡死的真正根因，务必保持）：
 *    32bit 存储要求地址 4 字节对齐，也就是**像素列号 x 必须是偶数**。
 *    `scene_step()` 会让 x += vx，而 vx ∈ {±1,±2,±3} ⇒ **x 会变成奇数**；
 *    第一版直接 `*(volatile uint32_t*)(base + y*1920 + x*2)` 就在奇数 x 上做了
 *    **未对齐的 32bit 存储** → RISC-V 触发未对齐异常 → 程序静默停死
 *    （现象：静态画面 + 串口再无输出，与 fbTest v2 "读未实现 mcycle CSR" 那次一模一样）。
 *    当年 FBtest 能跑，是因为它用 **16bit** 存储 `FB16[...]`，任意 x 都安全。
 *    ⇒ 这里改成：奇数 x 时用 16bit 收头/收尾，中间主体才用 32bit。
 *      这样既保留 32bit 的带宽优势，又对任意 x 都安全。 */
static void cpu_fill32(uint32_t base, int x, int y, int w, int h, uint16_t color)
{
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    int j, i;
    int odd = (x & 1);            /* 起始列是否奇数（需要先写 1 个 16bit 像素凑对齐） */
    for (j = 0; j < h; j++) {
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
                                                          + (uint32_t)x * 2u);
        int rem = w;
        if (odd) { *p++ = color; rem--; }                 /* 头部：1 像素，16bit，任意对齐 */
        {   volatile uint32_t *q = (volatile uint32_t *)p;
            for (i = 0; i < (rem >> 1); i++) q[i] = two;  /* 主体：4 字节对齐 */
        }
        if (rem & 1) p[rem - 1] = color;                  /* 尾部：1 像素，16bit */
    }
}
/* 8x8 字模：一行的 8 个像素合成 4 个 32bit 字写下去（比逐像素 16bit 写省一半事务）。
 * ★★ 端序陷阱：帧缓冲是**小端**，32bit 存储的**低 16 位落在低地址 = 左边的像素**。
 *    所以第 1 个像素（bit7）必须放在**低**半字。第一版写成"bit7 放高半字"，
 *    结果每个字里的两个像素被对调 → 字形碎成 2 像素一块，屏上就是乱码。 */
static void cpu_osd_text(uint32_t base, int x, int y, const char *s, uint16_t fg)
{
    while (*s) {
        const uint8_t *rp = glyph_of(*s++);
        int row;
        for (row = 0; row < 8; row++) {
            uint8_t bits = rp[row];
            volatile uint32_t *p = (volatile uint32_t *)(base + (uint32_t)(y + row) * FB_STRIDE
                                                              + (uint32_t)x * 2u);
            /* p[0] = 像素(x+0) 在低半字，像素(x+1) 在高半字 */
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
                 | ((bits & 0x20u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
                 | ((bits & 0x08u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
                 | ((bits & 0x02u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
        }
        x += 8;
    }
}

/* ============================== 场景（方块） ==============================
 * 两块屏外缓冲**各有一份场景状态**（g_sc[0] / g_sc[1]），因为它们可能处在不同帧；
 * 两份用同一个种子初始化、按同样规则推进 ⇒ 看起来完全一致。 */
typedef struct {
    int16_t  x, y;          /* 本帧位置 */
    int16_t  px, py;        /* 上一帧位置（擦除用） */
    int16_t  vx, vy;
    uint16_t color;
    uint8_t  sz;
} blk_t;

typedef struct { int x0, y0, w, h; } rect_t;

static blk_t    g_sc[2][MAXBLK];
static uint32_t g_seed = 0x12345678u;
static const uint32_t g_buf[2] = { FB1_BASE, FB2_BASE };

static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }

static void scene_init(int n, uint32_t seed)
{
    int side, i;
    for (side = 0; side < 2; side++) {
        uint32_t s = seed;
        for (i = 0; i < n; i++) {
            blk_t *b = &g_sc[side][i];
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
            b->sz = (uint8_t)(((i % 3) == 0) ? 16 : (((i % 3) == 1) ? 24 : 32));
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
            if (!b->vx) b->vx = 1;
            if (!b->vy) b->vy = 1;
            b->x  = (int16_t)((int)(r1 % 860u) & ~1);      /* 偶数对齐（32bit 写要求） */
            b->y  = (int16_t)((int)(r2 % 400u));
            b->px = b->x; b->py = b->y;
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
                                  | ((r1 + r2) & 0x1Fu));
        }
    }
}
/* 让所有物块的"上一帧位置"对齐到当前位置：重铺背景之后调用，
 * 这样下一帧只需"画"、不需要"擦"（否则会拿旧位置去擦，把背景擦花）。 */
static void scene_sync(blk_t *sc, int n)
{
    int i;
    for (i = 0; i < n; i++) { sc[i].px = sc[i].x; sc[i].py = sc[i].y; }
}

/* 在 region 内弹跳；方块永远不进 OSD 条 */
static void scene_step(blk_t *sc, int n, const rect_t *rg)
{
    int i;
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    int ymin = rg->y0 + OSD_H + 4, ymax = rg->y0 + rg->h;
    for (i = 0; i < n; i++) {
        blk_t *b = &sc[i];
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
        b->px = b->x; b->py = b->y;
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
        /* ★ x 保持偶数：CPU 侧 32bit 写要求 4 字节对齐。
         *   （cpu_fill32 现在已经能安全处理奇数 x 了，这里再保证一次是为了
         *     两条渲染路径位置一致、也避免任何未来代码再踩这个坑。） */
        b->x = (int16_t)(x & ~1);
        b->y = (int16_t)y;
    }
}

/* ============================== 输入：按键 + 串口 ============================== */
#define EV_NONE  0
#define EV_MODE  1
#define EV_N_INC 2
#define EV_N_DEC 3
#define EV_RESET 4

#define GPIO_INPUT_OFS 0x00
#define KEY_MASK       0x07u          /* soc_gpio[0..2] = GPIOR_22/GPIOR_21/GPIOL_03 */
#define KEY_DEBOUNCE   3              /* 连续 N 次读到同一状态才认（主循环很快，足够） */

static int uart_poll_char(void);
static uint32_t uart_status_raw(void);

static uint32_t gpio_read_keys(void)
{
    /* 只读这一块 GPIO 的输入寄存器（本 SoC 只生成了一块 GPIO） */
    return (*(volatile uint32_t *)(SYSTEM_GPIO_A_APB + GPIO_INPUT_OFS)) & KEY_MASK;
}

static uint32_t g_key_stable = KEY_MASK;   /* 消抖后的稳定值（1 = 未按，0 = 按下） */
static int      g_key_cnt    = 0;
static uint32_t g_key_prev   = KEY_MASK;

/* 返回本圈发生的按键事件（低有效：按下 = 0，取下降沿） */
static int key_poll(void)
{
    uint32_t now = gpio_read_keys();
    if (now != g_key_prev) {          /* 电平有变化 → 重新计稳定性 */
        g_key_prev = now;
        g_key_cnt  = 0;
        return EV_NONE;
    }
    if (g_key_cnt < KEY_DEBOUNCE) {
        g_key_cnt++;
        if (g_key_cnt == KEY_DEBOUNCE && now != g_key_stable) {
            uint32_t down = g_key_stable & ~now;      /* 新按下的位 */
            g_key_stable = now;
            if (down & 0x01u) return EV_MODE;         /* GPIOR_22：切模式 */
            if (down & 0x02u) return EV_N_INC;        /* GPIOR_21：N +25 */
            if (down & 0x04u) return EV_RESET;        /* GPIOL_03：场景复位 */
        }
    }
    return EV_NONE;
}

static int input_poll(void)
{
    int c = uart_poll_char();
    if (c == 'm' || c == 'M') return EV_MODE;
    if (c == 'n' || c == 'N' || c == '+') return EV_N_INC;
    if (c == '-') return EV_N_DEC;
    if (c == 'r' || c == 'R') return EV_RESET;
    return key_poll();
}

/* ★ 非阻塞串口读。状态寄存器两个字段必须分清（driver/uart.h）：
 *     uart_writeAvailability = (status >> 16) & 0xFF  → TX 剩余空间
 *     uart_readOccupancy     = (status >> 24)         → RX 已收字节数
 *   早期这里误用 >>16（TX 空间）→ TX 一忙就当成"有数据"，跑去读空的 RX 数据寄存器，
 *   真字符拿不到（串口指令完全无效）。 */
#define UART_TERM       SYSTEM_UART_0_IO_CTRL
#define UART_DATA_OFS   0x00
#define UART_STATUS_OFS 0x04

static uint32_t uart_status_raw(void)
{
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
}
static uint32_t uart_rx_occ(void) { return uart_status_raw() >> 24; }

static int uart_poll_char(void)
{
    if (uart_rx_occ() == 0u) return 0;
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
}

/* ============================== OSD ============================== */
static void u2s(char *buf, unsigned v, int width)      /* 右对齐十进制 */
{
    char d[12];
    int  n = 0, i;
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    for (i = 0; i < width - n; i++) *buf++ = ' ';
    while (n) *buf++ = d[--n];
    *buf = 0;
}
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
static char *appn(char *p, unsigned v, int w) { char t[16]; u2s(t, v, w); return app(p, t); }

/* 状态条永远画在**屏外缓冲**里；显示缓冲由引擎负责搬过去。
 * buf_idx 只影响画到哪一块屏外缓冲，进入该缓冲的场景状态也顺便复位成"整条重画"。 */
static void draw_osd(uint32_t base, int mode, int n, unsigned cpu_fps,
                     unsigned scr_fps, unsigned it_k)
{
    char line[64];
    char *p = line;

    cpu_fill32(base, 0, OSD_Y0, FB_WIDTH, OSD_H, COL_OSD_BG);
    p = app(p, (mode == 0) ? "CPU " : "HW ");
    p = appn(p, (unsigned)n, 3);
    p = app(p, " N  ");
    p = appn(p, cpu_fps, 5);
    p = app(p, " R/S  ");
    p = appn(p, scr_fps, 5);
    p = app(p, " S/S  ");
    p = appn(p, it_k, 5);
    p = app(p, " K");
    *p = 0;
    cpu_osd_text(base, 8, OSD_Y0 + 4, line, (mode == 0) ? COL_CPU_FG : COL_HW_FG);
}

/* ============================== 主循环 ============================== */
#define MODE_CPU 0
#define MODE_HW  1

/* 屏外缓冲状态机：每块缓冲在 FREE/RENDERING/READY/COPYING 之间流转 */
#define BS_FREE      0
#define BS_RENDERING 1
#define BS_READY     2
#define BS_COPYING   3

int main(int argc, char **argv)
{
    int      mode = MODE_CPU;
    int      n = 25;
    rect_t   rg;
    uint32_t it = 0, it_prev = 0;

    uint32_t bs[2];
    int      rendering = -1;          /* 正在被 CPU 渲染的缓冲下标，-1 = 无 */
    int      copying   = -1;          /* 正在被引擎 COPY 的缓冲下标，-1 = 无 */
    int      cpu_i     = 0;
    uint32_t render_frames = 0;       /* CPU 画完的帧数（纯渲染口径） */
    uint32_t scr_frames    = 0;       /* 引擎搬上屏的帧数 */
    uint32_t hw_frames     = 0;
    int      hw_i = 0, hw_half = 0;
    int      hw_frame_pushed = 0;   /* 本帧指令是否已全部下发（硬件模式"一帧一帧推"用） */
    int      osd_dirty       = 0;   /* 状态条已改、待搬到显示缓冲（在帧边界搬） */
    /* ★ 重铺标记：场景一变（N 加减 / 复位 / 切模式）就要把背景重铺一遍。
     *   不重铺的话，旧物块留在缓冲里的像素没有任何人负责擦掉，只有等某个新物块
     *   碰巧经过才被盖住 —— 就是"加减物块后旧物块要等接触才刷新"那个现象。 */
    int      repaint[2]      = { 0, 0 };
    int      hw_repaint      = 0;

    uint32_t t0, t_osd;
    uint32_t cpu_fps = 0, scr_fps = 0;
    uint32_t osd_evt = 0;

    (void)argc; (void)argv;

    /* ★ 必须最先调用：bsp_init() 里才配置 UART 时钟分频 */
    bsp_init();

    bsp_printf("\r\n===== comptest: CPU software render vs BitBlt HW accel =====\r\n");
    bsp_printf("FB=%x FB1=%x FB2=%x N=%d-%d step %d\r\n",
               (unsigned)FB_BASE, (unsigned)FB1_BASE, (unsigned)FB2_BASE,
               N_MIN, N_MAX, N_STEP);
    bsp_printf("keys: GPIOR_22=mode  GPIOR_21=N+25  GPIOL_03=reset\r\n");
    bsp_printf("uart: m=mode  n or +=N+25  -=N-25  r=reset\r\n");
    bsp_printf("ver: CPU renders to off-screen buf, engine copies to display\r\n");

    blt_init();

    /* ★ 只给**屏外缓冲**铺底。显示缓冲 FB_BASE 一个字节都不由 CPU 写 ——
     *   它的内容全部来自引擎（开机第一条整屏 COPY 就会铺满它，不需要单独清屏）。 */
    cpu_fill32(FB1_BASE, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    cpu_fill32(FB2_BASE, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    cache_evict();

    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x UST=%x URO=%d KEY=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(),
               (unsigned)blt_rd(0x20),
               (unsigned)uart_status_raw(), (int)uart_rx_occ(), (unsigned)gpio_read_keys());

    /* ================= ★ 未对齐写入自检（这次卡死的根因就是它） =================
     * 在**奇数 x** 处画一小块再读回：若 cpu_fill32 对奇数 x 仍做 32bit 未对齐存储，
     * CPU 会在这里就静默停死、下面这行 "aligncheck" 永远打不出来。
     * 打出来且值正确（f800）就说明这条路径安全了。 */
    cpu_fill32(FB1_BASE, 33, 300, 8, 2, 0xF800u);
    cpu_fill32(FB1_BASE, 32, 302, 9, 2, 0x07E0u);      /* 偶数 x + 奇数宽度 */
    {
        unsigned v1 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 300u * FB_STRIDE + 33u * 2u));
        unsigned v2 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 300u * FB_STRIDE + 40u * 2u));
        unsigned v3 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 302u * FB_STRIDE + 32u * 2u));
        unsigned v4 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 302u * FB_STRIDE + 40u * 2u));
        bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
                   v1, v2, v3, v4);
    }

    scene_init(n, g_seed);
    rg.x0 = 0; rg.y0 = 0; rg.w = FB_WIDTH; rg.h = FB_HEIGHT;

    /* ================= ★ 预热：趁 DDR 还健康，把主循环要用的**代码与数据**装进缓存 =================
     * 本工程整个程序都在 DDR 里（linker: ORIGIN=0x1000）。板级现象是"开机打印正常、
     * 一进主循环就整机静止"——若那一下是卡在**冷读**（D$/I$ miss 需要 DDR 读通道，
     * 而通道被扫描输出钉住），那么把工作集提前读热、之后靠缓存跑，就能活下来。
     * 这一步同时也是**诊断**：
     *   · 预热后能持续跑 → 证实卡死是"冷读拿不到 DDR 读通道"；
     *   · 预热后仍同样卡死 → 与读无关，得往写通路/别处查。
     * 预热要在**开机写清屏之后**做（那时 DDR 已经挨过最大的一波写，通道还正常）。 */
    {
        int wk;
        for (wk = 0; wk < 8; wk++)                       /* g_sc 两份场景数据 + scene_step 代码 */
            scene_step((wk & 1) ? g_sc[1] : g_sc[0], n, &rg);
        for (wk = 0; wk < 3; wk++) {                     /* fill / OSD / 字模 / .rodata 字符串 */
            cpu_fill32(FB1_BASE, 0, 0, FB_WIDTH, OSD_H, COL_OSD_BG);
            draw_osd(FB1_BASE, mode, n, 0, 0, 0);
        }
        for (wk = 0; wk < 64; wk++) {                    /* 输入轮询路径（GPIO/UART 状态读） */
            (void)gpio_read_keys();
            (void)uart_poll_char();
        }
        /* 打印路径：把 S/D 两条格式串连同 %d/%x 的转换代码都过一遍 */
        bsp_printf("warmup %d %d %d %d %d %d %x %x\r\n",
                   0, 0, 0, 0, 0, 0, 0u, 0u);
        /* 引擎收尾路径：等它做完（有界等待），把 blt_idle/blt_can_push 也跑热 */
        {
            uint32_t wt = (uint32_t)tick();
            while (!blt_idle() && ((uint32_t)(tick() - wt) < (uint32_t)(BSP_CLINT_HZ / 4u))) { }
        }
        bsp_printf("warmup done\r\n");
    }

    bs[0] = BS_FREE; bs[1] = BS_FREE;
    g_key_stable = gpio_read_keys();   /* 上电时按键未按（高）当基准 */
    g_key_prev   = g_key_stable;

    t0 = (uint32_t)tick();
    t_osd = t0;

    draw_osd(FB1_BASE, mode, n, 0, 0, 0);
    draw_osd(FB2_BASE, mode, n, 0, 0, 0);   /* ★ 两块屏外缓冲都要有状态条，
                                             *   否则双缓冲交替上屏时 OSD 会来回闪 */
    cache_evict();                     /* 保证上面这些 CPU 写对引擎可见（写穿 + 有序屏障） */
    /* 让显示缓冲先显示一块已铺底 + 带状态条的图，避免开机黑屏 */
    blt_copy_full(FB1_BASE, FB_BASE);  bs[0] = BS_COPYING; copying = 0;

    for (;;) {
        int ev;
        it++;
        ev = input_poll();

        /* ================= ★ 屏幕上心跳（不依赖串口、不依赖引擎） =================
         * 每 4096 圈在**屏外缓冲**顶部画一条随 it 左右跳动的红条。
         * 它能回答一个关键问题：**CPU 还活着吗？卡在读还是卡在别处？**
         *   · 红条在跳 → CPU 仍在执行、仍能 store（说明卡的不是写通路）；
         *   · 红条不动而串口也没了 → CPU 真的停了（多半卡在某次访问上）。
         * 这段只用常量与寄存器算地址，代码也是刚预热过的，不会引入新的冷读。 */
        if ((it & 4095u) == 0u) {
            cpu_fill32(g_buf[0], 0, OSD_H + 2, 128, 8, COL_BG);
            cpu_fill32(g_buf[0], (int)((it >> 12) & 1u) * 64, OSD_H + 2, 64, 8, 0xF800u);
        }

        if (ev == EV_MODE) {
            mode = (mode == MODE_CPU) ? MODE_HW : MODE_CPU;
            hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
            repaint[0] = repaint[1] = 1; hw_repaint = 1;   /* 两种模式的画面互相残留，重铺 */
            bsp_printf("\r\nEV mode -> %d (0=CPU 1=HW)\r\n", mode);
        }
        if (ev == EV_N_INC) {
            n += N_STEP; if (n > N_MAX) n = N_MIN;
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
        }
        if (ev == EV_N_DEC) {
            n -= N_STEP; if (n < N_MIN) n = N_MAX;
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
        }
        if (ev == EV_RESET) {
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
        }

        /* ---------- 引擎收尾：COPY 完成的缓冲回到 FREE ---------- */
        if (copying >= 0 && blt_idle()) {
            bs[copying] = BS_FREE;
            copying = -1;
            scr_frames++;
        }
        if (mode == MODE_CPU) {
            /* ---------- CPU 模式：画屏外缓冲 → 引擎整屏 COPY 上屏 ---------- */
            if (rendering < 0) {                     /* 选一块 FREE 的开始新一帧 */
                if      (bs[0] == BS_FREE) { rendering = 0; bs[0] = BS_RENDERING; }
                else if (bs[1] == BS_FREE) { rendering = 1; bs[1] = BS_RENDERING; }
                if (rendering >= 0) {
                    cpu_i = 0;
                    if (repaint[rendering]) {
                        /* ★ 场景刚变过：把这块屏外缓冲的**场景区**重铺背景（保留状态条），
                         *   并让物块 px=py 重新对齐 ⇒ 旧物块立刻消失，
                         *   不必再"等新物块碰到它"才被盖掉。 */
                        cpu_fill32(g_buf[rendering], 0, OSD_H,
                                   FB_WIDTH, FB_HEIGHT - OSD_H, COL_BG);
                        scene_sync(g_sc[rendering], n);
                        repaint[rendering] = 0;
                    }
                }
            }
            if (rendering >= 0) {
                blk_t *b = &g_sc[rendering][cpu_i];
                /* 擦旧位置 + 画新位置（全部写屏外缓冲） */
                if (b->px != b->x || b->py != b->y)
                    cpu_fill32(g_buf[rendering], b->px, b->py, b->sz, b->sz, COL_BG);
                cpu_fill32(g_buf[rendering], b->x, b->y, b->sz, b->sz, b->color);
                if (++cpu_i >= n) {                  /* 一帧画完 */
                    cpu_i = 0;
                    scene_step(g_sc[rendering], n, &rg);
                    bs[rendering] = BS_READY;
                    rendering = -1;
                    render_frames++;
                }
            }
            /* 有 READY 的缓冲 + 引擎空闲 → 推整屏 COPY（一次只允许一笔在飞） */
            if (copying < 0 && blt_can_push()) {
                if      (bs[0] == BS_READY) { cache_evict(); blt_copy_full(g_buf[0], FB_BASE); bs[0] = BS_COPYING; copying = 0; }
                else if (bs[1] == BS_READY) { cache_evict(); blt_copy_full(g_buf[1], FB_BASE); bs[1] = BS_COPYING; copying = 1; }
            }
        } else {
            /* ---------- 硬件加速模式：**一帧一帧推** ----------
             * 为什么不能"能推就推"（FIFO 一有空间就补下一帧）：那样引擎永远 BUSY，
             * `blt_idle()` 永不成立 ⇒ ①上屏帧计数永远不累加（串口 SCR=0，其实画面在动）
             * ②信息栏那条搬运永远发不出去（状态条不刷新）。两者都是同一个门控写错了。
             * 改成"推满一帧 → 等引擎做完（此刻 FIFO 必然空）→ 记一帧 + 推进场景
             *      + 顺手把状态条搬上屏"，三个动作都落在这个确定的空闲点上。 */
            if (hw_frame_pushed) {
                if (blt_idle()) {
                    hw_frames++;
                    hw_frame_pushed = 0;
                    hw_i = 0; hw_half = 0;
                    scene_step(g_sc[0], n, &rg);      /* 下一帧用新位置（擦除用 px/py） */
                    if (hw_repaint && blt_can_push()) {
                        /* ★ 场景刚变过：让引擎把显示缓冲整屏重铺背景（旧物块立刻消失），
                         *   状态条紧接着由下面这条 COPY 补回来（FIFO 保序）。 */
                        blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, COL_BG);
                        scene_sync(g_sc[0], n);
                        hw_repaint = 0;
                        osd_dirty  = 1;
                    }
                    if (osd_dirty && blt_can_push()) { /* ★ 状态条此刻搬，必然发得出去 */
                        blt_copy_osd(FB1_BASE, FB_BASE);
                        osd_dirty = 0;
                    }
                }
            } else {
                int budget = 32;
                while (budget-- > 0 && blt_can_push()) {
                    blk_t *b = &g_sc[0][hw_i];        /* 硬件模式的场景状态用 g_sc[0] */
                    if (hw_half == 0) {
                        if (b->px == b->x && b->py == b->y) { hw_half = 1; continue; }
                        blt_fill(FB_BASE + (uint32_t)b->py * FB_STRIDE + (uint32_t)b->px * 2u,
                                 FB_STRIDE, b->sz, b->sz, COL_BG);
                        hw_half = 1;
                    } else {
                        blt_fill(FB_BASE + (uint32_t)b->y * FB_STRIDE + (uint32_t)b->x * 2u,
                                 FB_STRIDE, b->sz, b->sz, b->color);
                        hw_half = 0;
                        if (++hw_i >= n) {
                            hw_frame_pushed = 1;      /* 本帧指令推满 → 停手，等引擎做完 */
                            break;
                        }
                    }
                }
            }
        }

        /* ---------- 每 300ms 刷 OSD + 打印一行统计（纯 ASCII） ---------- */
        if ((uint32_t)(tick() - t_osd) >= (uint32_t)(BSP_CLINT_HZ * 3u / 10u)) {
            uint32_t el = (uint32_t)(tick() - t_osd);
            uint32_t d_it = it - it_prev;

            t_osd   = (uint32_t)tick();
            it_prev = it;
            osd_evt++;

            cpu_fps = (uint32_t)(((uint64_t)render_frames * (uint64_t)BSP_CLINT_HZ) / el);
            scr_fps = (uint32_t)(((uint64_t)(scr_frames + hw_frames) * (uint64_t)BSP_CLINT_HZ) / el);

            /* ★ OSD 只画屏外缓冲，显示缓冲永远由引擎写：
             *   CPU 模式 → 画进"当前正在渲染的那块"（它随后会被整屏 COPY 上屏；场景
             *             方块永远不会进入 OSD 条，所以不会互相覆盖）。若此刻没有在渲染
             *             的缓冲（刚推完 COPY 的瞬间），就等下一轮 300ms 再画。
             *   硬件模式 → 固定画进 FB1，再让引擎搬最上面 960x16 那一条上屏。
             *   ★ 这条 OSD 搬运**不占用双缓冲状态机**（copying 只表示整屏 COPY 在飞），
             *     且只在引擎完全空闲时下发，避免与整屏 COPY 的完成判定互相干扰。 */
            if (mode == MODE_CPU) {
                /* ★ 两块屏外缓冲都要刷 OSD：它们是交替上屏的，只刷一块会让状态条
                 *   在两帧之间来回跳（数字闪烁）。正在被引擎整屏 COPY 的那块不能碰
                 *   （会撕裂），其余状态（FREE/READY/RENDERING）都可以安全写。 */
                if (bs[0] != BS_COPYING) draw_osd(g_buf[0], mode, n, cpu_fps, scr_fps, it / 1000u);
                if (bs[1] != BS_COPYING) draw_osd(g_buf[1], mode, n, cpu_fps, scr_fps, it / 1000u);
            } else {
                /* 硬件模式：画进 FB1，并打上"待搬运"标记 —— 真正的搬运放在
                 * 帧边界（引擎刚做完、FIFO 必然空的那一刻）执行，见上面的说明。 */
                draw_osd(FB1_BASE, mode, n, cpu_fps, scr_fps, it / 1000u);
                osd_dirty = 1;
            }

            bsp_printf("S it=%d d=%d m=%d N=%d CPU=%d SCR=%d C=%d ST=%x KEY=%x\r\n",
                       (int)it, (int)d_it, mode, n,
                       (int)cpu_fps, (int)scr_fps,
                       (int)blt_cnt(), (unsigned)blt_stat(),
                       (unsigned)gpio_read_keys());

            render_frames = 0; scr_frames = 0; hw_frames = 0;

            /* 诊断：每 10 次统计打一条更全的（含扫描输出健康度 0x20） */
            if ((osd_evt % 10u) == 0u) {
                uint32_t sc = blt_rd(0x20);
                bsp_printf("D it=%d SC=%x ab=%d un=%d t=%x\r\n",
                           (int)it, (unsigned)sc,
                           (int)(sc >> 16), (int)(sc & 0xFFFFu),
                           (unsigned)(uint32_t)(tick() - t0));
            }
        }
    }
    return 0;
}
