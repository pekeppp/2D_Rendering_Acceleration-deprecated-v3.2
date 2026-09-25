/* =============================================================================
 * comptest2.c — 同屏对比：硬件加速渲染 vs 纯 CPU 渲染
 * -----------------------------------------------------------------------------
 * 赛题要求：基础测试 Demo（大量方块随机移动）+ 屏上实时对比两种渲染路径的帧率差异。
 *
 * ★ 屏幕布局（帧缓冲 960x540，**单缓冲直接显示**）：
 *      y   0 ..  16   OSD 状态条（CPU 画）
 *      y  16 .. 276   上半：**硬件加速器**渲染（引擎 FILL/ALPHA/KEY 指令）
 *      y 276 .. 280   分隔条（CPU 画）
 *      y 280 .. 540   下半：**纯 CPU** 渲染（CPU 直写像素）
 *
 * ★ 三条关键设计（都是上板踩坑换来的，改动前务必读）：
 *   1) **不需要屏外缓冲、不需要整屏 COPY**：两侧各画自己那一半。早期版本
 *      "CPU 一写显示缓冲就整机卡死"的真因是**未对齐 32bit 存储**
 *      （`scene_step` 把 x 变成奇数），与写哪块缓冲无关；现已修正并加了开机自检。
 *   2) **同一个场景、按时间推进**：场景每 40ms 推进一步，两侧用**完全相同**的目标
 *      坐标 ⇒ 上下两半内容一致；差异只体现在"谁跟得上"（帧率/流畅度）。
 *   3) **每侧各有自己的"上次画在哪"(dx,dy)**：擦自己画过的位置、画到当前目标位置。
 *      某一侧慢很多、落后好几步也不会擦错地方、不会拖影。
 *
 * ★ 串口命令（交互**全部**走串口）：
 *      1 / 2 / 3    场景：1=纯色方块(FILL)  2=半透明叠加(ALPHA)  3=色键精灵(KEY)
 *      s / c / h    渲染路径：s=同屏对比   c=整屏纯 CPU   h=整屏纯硬件
 *      n 或 +       N(方块数) += 25        -    N -= 25
 *      a / A        透明度 alpha -= 32 / += 32（只对 ALPHA 场景有效）
 *      r            重置场景        ?  打印帮助
 *
 * ★ printf 雷区：BSP 的 print.h 是 mini 版，**只认 %c %s %d %X %x**。
 *   出现 %u / 宽度数字 / %% 会让它错位消耗 va_arg，后面的 %s 拿整数当指针直接挂死。
 * ============================================================================= */

#include <stdint.h>
#include "bsp.h"
#include "compatibility.h"      /* SYSTEM_GPIO_A_APB → SYSTEM_GPIO_0_IO_CTRL 的映射 */

/* ============================== 地址与寄存器 ============================== */
#define FB_WIDTH      960
#define FB_HEIGHT     540
#define FB_STRIDE     (FB_WIDTH * 2)               /* 1920 B/行 */

#define DDR_BASE      0x00001000UL
#define FB_BASE       (DDR_BASE + 0x00300000UL)    /* 显示缓冲：**只由引擎整屏 COPY 写** */
#define FB_BACK       (DDR_BASE + 0x00500000UL)    /* 后台缓冲：CPU 与引擎都画在这里 */
#define ATLAS_BASE    (DDR_BASE + 0x00200000UL)    /* 精灵图集（开机由 CPU 生成） */
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
#define BLT_SCAN_DBG        0x20
#define BLT_FIFO_DEPTH      256

/* 引擎操作码（与 rtl/pixel_path.v、blt_engine_fsm.v 一致） */
#define BLT_OP_FILL   1UL
#define BLT_OP_ALPHA  2UL
#define BLT_OP_KEY    3UL

/* ============================== 画面分区 ============================== */
#define OSD_H     16
#define SEP_H     4
#define TOP_Y0    OSD_H                          /* 上半天区起点 = 16 */
#define HALF_H    260                            /* 半区高度（虚拟场景高度也用它） */
#define BOT_Y0    (TOP_Y0 + HALF_H + SEP_H)      /* 下半天区起点 = 280 */
/* 16 + 260 + 4 + 260 = 540 ✓ */

#define COL_BG        0x0008u                     /* OSD 用（近黑） */

#define COL_OSD_BG    0x0000u
#define COL_HW_FG     0xFFE0u                    /* 黄：硬件侧 */
#define COL_CPU_FG    0x07FFu                    /* 青：CPU 侧 */
#define COL_SEP       0x4208u
#define COL_WHITE     0xFFFFu
#define KEY_COLOR     0xF81Fu                    /* 色键（洋红）：精灵四角用它 */

/* ============================== 场景 ============================== */
#define N_MIN   25
#define N_STEP  50
#define N_MAX   700
#define MAXBLK  N_MAX

#define NSIDE    2
#define SIDE_HW  0
#define SIDE_CPU 1

#define PATH_SPLIT 0
#define PATH_CPU   1
#define PATH_HW    2

#define SC_FILL  0
#define SC_ALPHA 1
#define SC_KEY   2

typedef struct { int x0, y0, w, h; } rect_t;

typedef struct {
    int16_t  x, y;      /* 场景当前目标位置（两侧按时间同步推进，逐位相同） */
    int16_t  vx, vy;
    int16_t  dx, dy;    /* **这一侧**上一趟画到的位置（擦除用，各自独立） */
    int16_t  tx, ty;    /* ★ 本趟的快照：一趟渲染期间位置恒定不变 ——
                         *   这是消除尾迹的关键。场景按时间推进，如果允许它在一趟
                         *   渲染中间改变位置，同一趟里有的块用旧位置、有的用新位置，
                         *   dx/dy 记账就不再自洽 ⇒ 有位置被画过却再没人擦 ⇒ 沿路径
                         *   一串残影（且越是慢的一侧越稠密）。 */
    uint16_t color;
    uint8_t  sz;
} blk_t;

static blk_t    g_sc[NSIDE][MAXBLK];
static uint32_t g_seed = 0x12345678u;

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
/* 写 FIFO 前先确认有空间：FIFO 满时写 DATA 会把 CPU 挂在 APB 上（主循环会死在那里） */
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
/* 整屏上屏：后台缓冲 -> 显示缓冲。双缓冲的关键一步 —— 只有它写显示缓冲，
 * 所以擦除/重画/重叠这些中间过程永远不会被屏幕看到（尾迹与闪烁都由此消除）。 */
static void blt_copy_full(uint32_t src, uint32_t dst)
{
    blt_emit(0UL /*COPY*/, src, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, 0xFFu, 0u);
}
static void blt_fill(uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{
    blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color);
}
/* 半透明叠加：src 是图集里的精灵（RGB565），alpha 0..255 */
static void blt_alpha(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                      uint32_t w, uint32_t h, uint32_t alpha)
{
    blt_emit(BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u);
}
/* 色键抠图：src 里等于 key 的像素不写 */
static void blt_key(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                    uint32_t w, uint32_t h, uint32_t key)
{
    blt_emit(BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key);
}

/* ============================== 精灵图集（开机由 CPU 生成） ==============================
 * 32x32 RGB565 圆盘精灵：四角 = 色键(洋红)，外圈白环，内部渐变。
 * 同一个精灵同时供 KEY 场景（四角透明）与 ALPHA 场景（整块半透明）使用。
 * 图集放在 DDR 里，引擎直接从这里取数 —— 这就是"图上屏"的最小闭环。 */
#define SPR_W      32
#define SPR_H      32
#define SPR_STRIDE (SPR_W * 2)

static uint16_t spr_color(int i, int j)
{
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    int d2 = dx * dx + dy * dy;
    int r2 = (SPR_W / 2) * (SPR_W / 2);
    unsigned rr, gg, bb;
    if (d2 > r2)                                   return KEY_COLOR;
    if (d2 > (SPR_W / 2 - 4) * (SPR_W / 2 - 4))    return COL_WHITE;
    rr = (unsigned)((i * 31) / (SPR_W - 1));
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
}
static void build_atlas(void)
{
    volatile uint16_t *p = (volatile uint16_t *)ATLAS_BASE;
    int i, j;
    for (j = 0; j < SPR_H; j++)
        for (i = 0; i < SPR_W; i++)
            p[j * SPR_W + i] = spr_color(i, j);
}

/* ============================== CPU 侧绘制 ==============================
 * ★★ 对齐陷阱（本 Demo 曾经整机卡死的真因，务必保持）：
 *    32bit 存储要求 4 字节对齐 = **像素列号 x 必须是偶数**，而 `scene_step` 会让
 *    x += vx（vx ∈ {±1,±2,±3}）⇒ x 会变成奇数。第一版直接在奇数 x 上做 32bit 存储
 *    → RISC-V 触发未对齐异常 → 程序静默停死（现象：静态画面 + 串口再无输出）。
 *    所以这里：奇数 x 用 16bit 收头/收尾，中间主体才用 32bit 批量写。
 *    （当年 FBtest 能跑，是因为它用 16bit 存储 `FB16[...]`，任意 x 都安全。） */
static void cpu_fill32(uint32_t base, int x, int y, int w, int h, uint16_t color)
{
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    int j, i;
    int odd = (x & 1);
    for (j = 0; j < h; j++) {
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
                                                          + (uint32_t)x * 2u);
        int rem = w;
        if (odd) { *p++ = color; rem--; }
        {   volatile uint32_t *q = (volatile uint32_t *)p;
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
        }
        if (rem & 1) p[rem - 1] = color;
    }
}

/* 与 rtl/pixel_path.v **同一条公式**的定点混合：
 *   通道展开 8bit（r5→{(r<<3)|(r>>2)} 等）→ (fg*α + bg*(255-α) + 127) >> 8 → 量化回 5/6/5
 *   （RTL 注释也说明：量化后普遍小 1~3 个 LSB，α=0/255 时也不是纯前景/背景） */
static uint16_t blend565(uint16_t fg, uint16_t bg, unsigned a)
{
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    unsigned ai  = 255u - a;
    unsigned r = (f8r * a + b8r * ai + 127u) >> 8;
    unsigned g = (f8g * a + b8g * ai + 127u) >> 8;
    unsigned b = (f8b * a + b8b * ai + 127u) >> 8;
    if (r > 255u) r = 255u;
    if (g > 255u) g = 255u;
    if (b > 255u) b = 255u;
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
}

/* CPU 版 ALPHA：逐像素 读目的 → 混合 → 写回（CPU 最吃亏的地方：多了一次读） */
static void cpu_alpha_sprite(int x, int y, unsigned alpha)
{
    const volatile uint16_t *s = (const volatile uint16_t *)ATLAS_BASE;
    int i, j;
    for (j = 0; j < SPR_H; j++) {
        volatile uint16_t *d = (volatile uint16_t *)(FB_BACK
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
        for (i = 0; i < SPR_W; i++)
            d[i] = blend565(s[j * SPR_W + i], d[i], alpha);
    }
}
/* CPU 版 KEY：逐像素 读源 → 判色键 → 条件写 */
static void cpu_key_sprite(int x, int y)
{
    const volatile uint16_t *s = (const volatile uint16_t *)ATLAS_BASE;
    int i, j;
    for (j = 0; j < SPR_H; j++) {
        volatile uint16_t *d = (volatile uint16_t *)(FB_BACK
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
        for (i = 0; i < SPR_W; i++) {
            uint16_t c = s[j * SPR_W + i];
            if (c != (uint16_t)KEY_COLOR) d[i] = c;
        }
    }
}

/* ============================== 8x8 字体（OSD 用） ============================== */
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
    { 'C', {0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00} },
    { 'D', {0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00} },
    { 'E', {0x7E,0x60,0x60,0x78,0x60,0x60,0x7E,0x00} },
    { 'F', {0x7E,0x60,0x60,0x78,0x60,0x60,0x60,0x00} },
    { 'H', {0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00} },
    { 'I', {0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00} },
    { 'K', {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00} },
    { 'L', {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00} },
    { 'M', {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00} },
    { 'N', {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00} },
    { 'O', {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'P', {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00} },
    { 'S', {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00} },
    { 'T', {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00} },
    { 'U', {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'W', {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00} },
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
/* 8x8 字模 -> 每行 4 个 32bit 字。
 * ★ 小端：32bit 存储的**低 16 位落在低地址 = 左边像素**，所以 bit7 必须放低半字
 *   （第一版放反了，每个字里两个像素对调 → 屏上全是乱码）。 */
static void osd_text(int x, int y, const char *s, uint16_t fg)
{
    while (*s) {
        const uint8_t *rp = glyph_of(*s++);
        int row;
        for (row = 0; row < 8; row++) {
            uint8_t bits = rp[row];
            volatile uint32_t *p = (volatile uint32_t *)(FB_BACK
                                    + (uint32_t)(y + row) * FB_STRIDE + (uint32_t)x * 2u);
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
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
static char *appn(char *p, unsigned v, int w)
{
    char d[12]; int n = 0, i;
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    for (i = 0; i < w - n; i++) *p++ = ' ';
    while (n) *p++ = d[--n];
    return p;
}

/* ============================== 串口（非阻塞） ==============================
 * 状态寄存器两个字段必须分清（driver/uart.h）：
 *   uart_writeAvailability = (status >> 16) & 0xFF  → TX 剩余空间
 *   uart_readOccupancy     = (status >> 24)         → RX 已收字节数
 * 早期误用 >>16 ⇒ TX 一忙就当成"有数据"、跑去读空 RX，串口指令完全无效。 */
#define UART_TERM       SYSTEM_UART_0_IO_CTRL
#define UART_DATA_OFS   0x00
#define UART_STATUS_OFS 0x04
static uint32_t uart_status_raw(void)
{
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
}
static int uart_poll_char(void)
{
    if ((uart_status_raw() >> 24) == 0u) return 0;
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
}

/* ============================== 场景 ============================== */
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }

/* 两侧用同一颗种子初始化 ⇒ 目标位置逐位相同 */
static void scene_init(int n, uint32_t seed, int sz_fixed)
{
    int side, i;
    for (side = 0; side < NSIDE; side++) {
        uint32_t s = seed;
        for (i = 0; i < n; i++) {
            blk_t *b = &g_sc[side][i];
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
            if (sz_fixed) b->sz = (uint8_t)SPR_W;            /* ALPHA/KEY 用图集尺寸 */
            else b->sz = (uint8_t)(((i % 3) == 0) ? 16 : (((i % 3) == 1) ? 24 : 32));
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
            if (!b->vx) b->vx = 1;
            if (!b->vy) b->vy = 1;
            b->x  = (int16_t)((int)(r1 % (uint32_t)(FB_WIDTH - 64)) & ~1);
            b->y  = (int16_t)(int)(r2 % (uint32_t)(HALF_H - 40));
            b->dx = b->x; b->dy = b->y;                      /* 本侧"已画位置"初始对齐 */
            b->tx = b->x; b->ty = b->y;                      /* 本趟快照初始对齐 */
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
                                  | ((r1 + r2) & 0x1Fu));
        }
    }
}
/* 只推进**目标位置**（两侧同时调用 ⇒ 目标逐位相同）；不动 dx/dy */
/* ★ 一趟渲染开始时给场景拍快照：把当前的 x,y 冻结到 tx,ty。
 *   此后本趟内所有擦/画都用 tx,ty，位置绝不会在一趟中间变化 ⇒ dx/dy 记账自洽 ⇒ 无尾迹。
 *   场景本身仍按时间在后台推进，只是要等下一趟才生效。 */
static void scene_snap(blk_t *sc, int n)
{
    int i;
    for (i = 0; i < n; i++) { sc[i].tx = sc[i].x; sc[i].ty = sc[i].y; }
}

/* 自动诊断（不依赖串口输入）：每 32 帧打印第一对重叠方块的像素在 FB_BACK/FB_BASE
 * 的值，以及硬件区域内两缓冲不一致的像素数（每 2x2 抽样）。冻结场景下用来判断
 * "错序在内存里" 还是 "只在显示侧"。 */
static void dbg_quick(int n, int y0, int h)
{
    int i, j, found = 0;
    for (i = 0; i < n && !found; i++) {
        for (j = i + 1; j < n && !found; j++) {
            int ax = g_sc[SIDE_HW][i].tx, ay = g_sc[SIDE_HW][i].ty + y0;
            int bx = g_sc[SIDE_HW][j].tx, by = g_sc[SIDE_HW][j].ty + y0;
            int x0 = (ax > bx) ? ax : bx, w0 = (ay > by) ? ay : by;
            int ax1 = ax + g_sc[SIDE_HW][i].sz, ay1 = ay + g_sc[SIDE_HW][i].sz;
            int bx1 = bx + g_sc[SIDE_HW][j].sz, by1 = by + g_sc[SIDE_HW][j].sz;
            int x1 = (ax1 < bx1) ? ax1 : bx1, w1 = (ay1 < by1) ? ay1 : by1;
            if (x0 < x1 && w0 < w1) {
                int px = x0 + (x1 - x0) / 2, py = w0 + (w1 - w0) / 2;
                uint32_t off = (uint32_t)py * FB_STRIDE + (uint32_t)px * 2u;
                bsp_printf("OV i=%d j=%d ci=%X cj=%X back=%X base=%X\r\n", i, j,
                           (unsigned)g_sc[SIDE_HW][i].color, (unsigned)g_sc[SIDE_HW][j].color,
                           (unsigned)*(volatile uint16_t *)(FB_BACK + off),
                           (unsigned)*(volatile uint16_t *)(FB_BASE + off));
                found = 1;
            }
        }
    }
    if (!found) bsp_printf("OV none\r\n");
    {
        int xx, yy; uint32_t d = 0;
        for (yy = 0; yy < h; yy += 2) {
            uint32_t row = (uint32_t)(yy + y0) * FB_STRIDE;
            for (xx = 0; xx < FB_WIDTH; xx += 2) {
                if (*(volatile uint16_t *)(FB_BACK + row + (uint32_t)xx * 2u) !=
                    *(volatile uint16_t *)(FB_BASE + row + (uint32_t)xx * 2u)) d++;
            }
        }
        bsp_printf("OV copy diff(1/4 sample)=%d\r\n", (int)d);
    }
}

/* ---------- OSD 数字输出：把关键读数画到屏幕，不依赖串口 ---------- */
static char g_l1[80], g_l2[80];

static char *os_puts(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
static char *os_dec(char *p, int v)
{
    char t[12]; int k = 0;
    if (v < 0) { *p++ = '-'; v = -v; }
    if (v == 0) t[k++] = '0';
    while (v > 0) { t[k++] = (char)('0' + (v % 10)); v /= 10; }
    while (k > 0) *p++ = t[--k];
    return p;
}
static char *os_hex4(char *p, unsigned v)
{
    const char *hx = "0123456789ABCDEF"; int sh;
    for (sh = 12; sh >= 0; sh -= 4) *p++ = hx[(v >> sh) & 0xFu];
    return p;
}

/* 找硬件区第一对重叠方块，读回重叠中心像素在 FB_BACK / FB_BASE 的值，
 * 并统计两缓冲不一致的像素数（1/16 抽样）—— 判定错序在内存还是显示侧。 */
static void osd_fill(int n, int y0, int h, int path, int scene, int alpha,
                      int fg_fence, int fg_guard, int fg_frozen)
{
    char *p;
    int i, j, found = 0, ci = 0, cj = 0, px = 0, py = 0;
    for (i = 0; i < n && !found; i++) {
        for (j = i + 1; j < n && !found; j++) {
            int ax = g_sc[SIDE_HW][i].tx, ay = g_sc[SIDE_HW][i].ty + y0;
            int bx = g_sc[SIDE_HW][j].tx, by = g_sc[SIDE_HW][j].ty + y0;
            int x0 = (ax > bx) ? ax : bx, w0 = (ay > by) ? ay : by;
            int ax1 = ax + g_sc[SIDE_HW][i].sz, ay1 = ay + g_sc[SIDE_HW][i].sz;
            int bx1 = bx + g_sc[SIDE_HW][j].sz, by1 = by + g_sc[SIDE_HW][j].sz;
            int x1 = (ax1 < bx1) ? ax1 : bx1, w1 = (ay1 < by1) ? ay1 : by1;
            if (x0 < x1 && w0 < w1) {
                ci = i; cj = j;
                px = x0 + (x1 - x0) / 2; py = w0 + (w1 - w0) / 2;
                found = 1;
            }
        }
    }
    p = os_puts(g_l1, "N=");   p = os_dec(p, n);
    p = os_puts(p, " SC=");    p = os_dec(p, scene);
    p = os_puts(p, " P=");     p = os_dec(p, path);
    p = os_puts(p, " A=");     p = os_dec(p, alpha);
    p = os_puts(p, " FGM=");   p = os_dec(p, fg_fence); p = os_dec(p, fg_guard); p = os_dec(p, fg_frozen);
    *p = 0;
    if (found) {
        uint32_t off = (uint32_t)py * FB_STRIDE + (uint32_t)px * 2u;
        p = os_puts(g_l2, "OV "); p = os_dec(p, ci); *p++ = '/'; p = os_dec(p, cj);
        p = os_puts(p, " CJ="); p = os_hex4(p, (unsigned)g_sc[SIDE_HW][cj].color);
        p = os_puts(p, " BK="); p = os_hex4(p, (unsigned)*(volatile uint16_t *)(FB_BACK + off));
        p = os_puts(p, " BS="); p = os_hex4(p, (unsigned)*(volatile uint16_t *)(FB_BASE + off));
    } else {
        p = os_puts(g_l2, "OV none");
    }
    {
        int xx, yy; uint32_t d = 0;
        for (yy = 0; yy < h; yy += 4) {
            uint32_t row = (uint32_t)(yy + y0) * FB_STRIDE;
            for (xx = 0; xx < FB_WIDTH; xx += 4) {
                if (*(volatile uint16_t *)(FB_BACK + row + (uint32_t)xx * 2u) !=
                    *(volatile uint16_t *)(FB_BASE + row + (uint32_t)xx * 2u)) d++;
            }
        }
        p = os_puts(p, " DF="); p = os_dec(p, (int)d); *p = 0;
    }
}
static void scene_step(blk_t *sc, int n, const rect_t *rg)
{
    int i;
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    int ymin = rg->y0, ymax = rg->y0 + rg->h;
    for (i = 0; i < n; i++) {
        blk_t *b = &sc[i];
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
        /* ★ 不再把 x 强行取整成偶数：旧的 32bit 对齐要求已经由 cpu_fill32 内部
         *   （奇数 x 用 16bit 收头/收尾）解决；而这里的 `x & ~1` 会让 vx=±1 的方块
         *   被取整卡住不动 —— 不动就永远不擦，ALPHA 场景会因为混合反复叠加而一路变暗。 */
        b->x = (int16_t)x;
        b->y = (int16_t)y;
    }
}

/* ============================== 主程序 ============================== */
#define SCENE_TICKS  (BSP_CLINT_HZ / 25u)    /* 场景推进周期 = 40ms（25 步/秒） */

/* 硬件侧天区起点/高度（SPLIT 只用上半；单模式铺满场景区） */
static int hw_y0(int path)  { (void)path; return TOP_Y0; }
static int hw_h(int path)   { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
static int cpu_y0(int path) { return (path == PATH_SPLIT) ? BOT_Y0 : TOP_Y0; }
static int cpu_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
/* ★ 场景虚拟区域高度也要跟着路径变：SPLIT 只有半屏高，单模式是整屏高。
 *   原来固定成 HALF_H，所以即便单模式给了整屏高度，物块也只在上面 260 行里弹
 *   —— 就是"切到纯 CPU/纯硬件时仍只渲染一半"的原因。 */
static int vrg_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }

int main(int argc, char **argv)
{
    int      path  = PATH_SPLIT;
    int      scene = SC_FILL;
    int      n     = 25;
    unsigned alpha = 128u;
    uint32_t it = 0, it_prev = 0;
    uint32_t hw_frames = 0, cpu_frames = 0;
    uint32_t hw_fps = 0, cpu_fps = 0;
    uint32_t t_osd, t_scene;
    int hw_i = 0, hw_frame_pushed = 0;
    int fence_on = 0, hw_fence = 0;   /* 'f'：硬件侧每块之间插围栏（诊断写顺序竞态） */
    int guard_us = 0;                 /* 'g'：推拷贝前干等多少微秒（等写落地） */
    uint32_t guard_t0 = 0;
    int frozen = 0;                    /* 'm'：冻结运动（判决闪烁是否来自帧间内容差异/撕裂） */
    int clear_pp = 0;                  /* 'e'：每趟整片重铺背景，不再擦旧矩形（治'擦到邻居'的拖影） */
    int cpu_i = 0;
    /* 重铺标记：两侧各一个（场景/路径一变就要把各自区域铺回背景，
     * 否则旧物块留在屏上没人擦 —— 就是"加减物块后要等接触才刷新"那个现象） */
    int repaint_hw = 1, repaint_cpu = 1;
    /* 双缓冲：两侧各完成一遍 = 一个演示帧，此刻把后台缓冲整体搬上屏一次 */
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    uint32_t disp_frames = 0, disp_fps = 0;
    uint32_t back_t0 = 0;

    rect_t vrg;
    vrg.x0 = 0; vrg.y0 = 0; vrg.w = FB_WIDTH; vrg.h = HALF_H;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */

    bsp_printf("\r\n===== comptest2: HW accel vs pure CPU, same screen =====\r\n");
    bsp_printf("FB=%x BACK=%x ATLAS=%x SPR=%dx%d\r\n",
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)ATLAS_BASE, SPR_W, SPR_H);
    bsp_printf("layout: OSD 0-16 | HW 16-276 | sep | CPU 280-540\r\n");
    bsp_printf("cmd: 1/2/3 scene FILL/ALPHA/KEY, s/c/h path SPLIT/CPU/HW\r\n");
    bsp_printf("     n or + N+25, - N-25, a/A alpha-/+, r reset, ? help\r\n");

    blt_init();
    build_atlas();                    /* 32x32 精灵图集（引擎与 CPU 都从它取数） */
    cpu_fill32(FB_BACK, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);        /* 整屏近黑铺底 */
    cache_evict();

    /* ★ 未对齐写入自检：CPU 侧曾因奇数 x 做 32bit 存储而整机静默停死。
     *   这两行能在开机第一秒就暴露该类问题（打印不出来或值不对 = 有问题）。 */
    cpu_fill32(FB_BACK, 33, 500, 8, 2, 0xF800u);
    cpu_fill32(FB_BACK, 32, 502, 9, 2, 0x07E0u);
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 500u * FB_STRIDE + 33u * 2u)),
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 500u * FB_STRIDE + 40u * 2u)),
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 502u * FB_STRIDE + 32u * 2u)),
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 502u * FB_STRIDE + 40u * 2u)));
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG));

    scene_init(n, g_seed, 0);
    cache_evict();
    blt_copy_full(FB_BACK, FB_BASE);   /* 开机先整屏上屏一次，避免显示未初始化 DDR */
    back_busy = 1; back_t0 = (uint32_t)tick();
    t_osd = t_scene = (uint32_t)tick();

    for (;;) {
        int c;
        it++;
        if (hw_fence && blt_idle()) hw_fence = 0;   /* 围栏：引擎做完了才继续发 */

        /* ---------------- 串口命令（交互全部走这里） ---------------- */
        c = uart_poll_char();
        if (c) {
            int scene_change = 0;
            if (c == '1' || c == '2' || c == '3') {
                scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
                scene_change = 1;
                bsp_printf("\r\nEV scene=%d (0=FILL 1=ALPHA 2=KEY)\r\n", scene);
            } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
            else if (c == 'c' || c == 'C')   { path = PATH_CPU;   repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=1 CPU only\r\n"); }
            else if (c == 'h' || c == 'H')   { path = PATH_HW;    repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=2 HW only\r\n"); }
            else if (c == 'n' || c == 'N' || c == '+') {
                n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1;
                bsp_printf("\r\nEV N=%d\r\n", n); }
            else if (c == '-') {
                n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1;
                bsp_printf("\r\nEV N=%d\r\n", n); }
            else if (c == 'd' || c == 'D') {   /* 诊断：重叠处像素在 FB_BACK / FB_BASE 各是什么，以及拷贝是否忠实 */
                int hy0 = hw_y0(path), oi, oj, ofound = 0;
                bsp_printf("\r\nEV dump scene=%d path=%d n=%d y0=%d alpha=%d\r\n",
                           scene, path, n, hy0, (int)alpha);
                for (oi = 0; oi < n && !ofound; oi++) {
                    for (oj = oi + 1; oj < n && !ofound; oj++) {
                        int ax = g_sc[SIDE_HW][oi].tx, ay = g_sc[SIDE_HW][oi].ty + hy0;
                        int bx = g_sc[SIDE_HW][oj].tx, by = g_sc[SIDE_HW][oj].ty + hy0;
                        int lx0 = (ax > bx) ? ax : bx, ly0 = (ay > by) ? ay : by;
                        int ax1 = ax + g_sc[SIDE_HW][oi].sz, ay1 = ay + g_sc[SIDE_HW][oi].sz;
                        int bx1 = bx + g_sc[SIDE_HW][oj].sz, by1 = by + g_sc[SIDE_HW][oj].sz;
                        int lx1 = (ax1 < bx1) ? ax1 : bx1, ly1 = (ay1 < by1) ? ay1 : by1;
                        if (lx0 < lx1 && ly0 < ly1) {
                            int px = lx0 + (lx1 - lx0) / 2, py = ly0 + (ly1 - ly0) / 2;
                            uint32_t off = (uint32_t)py * FB_STRIDE + (uint32_t)px * 2u;
                            bsp_printf("  pair i=%d j=%d px=%d,%d ci=%X cj=%X back=%X base=%X\r\n",
                                       oi, oj, px, py, (unsigned)g_sc[SIDE_HW][oi].color,
                                       (unsigned)g_sc[SIDE_HW][oj].color,
                                       (unsigned)*(volatile uint16_t *)(FB_BACK + off),
                                       (unsigned)*(volatile uint16_t *)(FB_BASE + off));
                            ofound = 1;
                        }
                    }
                }
                if (!ofound) bsp_printf("  no overlap pair in HW region\r\n");
                {   /* 拷贝忠实度：硬件区域内 FB_BASE 与 FB_BACK 不同的像素数 */
                    int oyy, oxx; uint32_t odiff = 0, ofirst = 0;
                    for (oyy = 0; oyy < hw_h(path); oyy++) {
                        uint32_t orow = (uint32_t)(oyy + hy0) * FB_STRIDE;
                        for (oxx = 0; oxx < FB_WIDTH; oxx++) {
                            uint16_t pa = *(volatile uint16_t *)(FB_BACK + orow + (uint32_t)oxx * 2u);
                            uint16_t pb = *(volatile uint16_t *)(FB_BASE + orow + (uint32_t)oxx * 2u);
                            if (pa != pb) { if (odiff == 0) ofirst = orow + (uint32_t)oxx * 2u; odiff++; }
                        }
                    }
                    bsp_printf("  copy diff=%d first_off=%X (0=拷贝忠实)\r\n", (int)odiff, (unsigned)ofirst);
                }
            }
            else if (c == 'e' || c == 'E') { clear_pp = !clear_pp;
                repaint_hw = repaint_cpu = 1;   /* 立即重铺一次，状态一致 */
                bsp_printf("\r\nEV clear_per_pass=%d (1=每趟整片重铺, 且不再发擦除)\r\n", clear_pp); }
            else if (c == 'm' || c == 'M') { frozen = !frozen;
                bsp_printf("\r\nEV freeze=%d (1=运动暂停)\r\n", frozen); }
            else if (c == 'g' || c == 'G') { guard_us = guard_us ? 0 : 300;
                bsp_printf("\r\nEV guard=%dus (0=off,300=wait writes before copy)\r\n", guard_us); }
            else if (c == 'f' || c == 'F') { fence_on = !fence_on;
                bsp_printf("\r\nEV fence=%d (1=hw waits engine idle per block)\r\n", fence_on); }
            else if (c == 'a') { if (alpha >= 32u)  alpha -= 32u;
                bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
            else if (c == 'A') { if (alpha <= 223u) alpha += 32u;
                bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
            else if (c == 'r' || c == 'R') { scene_change = 1;
                bsp_printf("\r\nEV reset\r\n"); }
            else if (c == '?') {
                bsp_printf("\r\ncmd: 1/2/3=FILL/ALPHA/KEY  s/c/h=SPLIT/CPU/HW"
                           "  n/+/ -=N  a/A=alpha  f=fence g=guard m=freeze e=clear d=dump r=reset\r\n"); }
            if (scene_change) {
                scene_init(n, g_seed, (scene == SC_FILL) ? 0 : 1);
                hw_i = 0; hw_frame_pushed = 0; cpu_i = 0;
                repaint_hw = repaint_cpu = 1;
            }
        }

        /* ---------------- 场景按时间推进（两侧同时、目标逐位相同） ---------------- */
        vrg.h = vrg_h(path);          /* 虚拟区域跟着路径变（单模式 = 整屏高） */
        if (!frozen && (uint32_t)(tick() - t_scene) >= (uint32_t)SCENE_TICKS) {
            t_scene = (uint32_t)tick();
            scene_step(g_sc[SIDE_HW],  n, &vrg);
            scene_step(g_sc[SIDE_CPU], n, &vrg);
        }

        /* ---------------- 双缓冲：两侧都画完一遍 → 整体搬上屏一次 ----------------
         * ★ 只有这一处写显示缓冲（FB_BASE），所以"擦除/重画/重叠"的中间过程永远不会
         *   被屏幕看到。之前的尾迹与重叠闪烁，根子都是屏幕拍到了帧中间状态
         *   （两阶段把"已擦未画"的窗口拉长到 10ms 量级，而屏幕每 16.7ms 采一次样）。
         *   这也正是最初"CPU 画屏外缓冲、引擎 COPY 上屏"的做法。 */
        if (back_busy) {
            if (blt_idle() && ((uint32_t)(tick() - back_t0) > (uint32_t)(BSP_CLINT_HZ / 5000u))) {
                back_busy = 0;                 /* 200us 保护：避开刚下发时的假空闲 */
                disp_frames++;
                /* ★ 周期诊断已停用：它们每帧要读回几万个 DDR 像素（1/4 与 1/16 抽样），
                 *   走的是与引擎/扫描共享的读通路，实测会把 HW= 明显压低。
                 *   需要时发串口 'd' 手动触发一次即可（或让 path==99 走进下面分支）。 */
                if (path == 99) {
                    dbg_quick(n, hw_y0(path), hw_h(path));
                    osd_fill(n, hw_y0(path), hw_h(path), path, scene, (int)alpha,
                             fence_on, guard_us ? 1 : 0, frozen);
                }
            }
        } else if ((path == PATH_CPU || hw_done) && (path == PATH_HW || cpu_done)) {
            /* 'g'：推拷贝前先干等 guard_us 微秒，等渲染的写真正落到 DDR。
             * 拷贝是'读 FB_BACK'的另一个 master，与尚未落地的渲染写之间没有顺序保证
             * （read-after-write 冒险），会读到'部分更新'的后台缓冲 —— 重叠处每帧
             * 上下关系乱跳就是这么来的。CPU 侧不出现：它每块要毫秒级，写早落地了。 */
            if (guard_us && guard_t0 == 0) {
                guard_t0 = (uint32_t)tick() | 1u;
            } else if (guard_us &&
                       ((uint32_t)(tick() - guard_t0) < (uint32_t)guard_us * (BSP_CLINT_HZ / 1000000u))) {
                /* 等写落地 */
            } else {
                guard_t0 = 0;
                cache_evict();                 /* 保证 CPU 的像素对引擎可见 */
                blt_copy_full(FB_BACK, FB_BASE);
                back_busy = 1;
                back_t0   = (uint32_t)tick();
                hw_done = 0; cpu_done = 0;
            }
        }

        /* ---------------- 硬件侧：**相邻式**擦+画，位置用本趟快照 ----------------
         * 全部画在后台缓冲里；屏幕看到的是上面那条整帧 COPY。
         * ★ 相邻式（擦一块立刻画这一块）是 v1 的原始做法 —— 当时只有重叠闪烁、没有尾迹。
         *   我后来为修闪烁改成"先擦完 N 块再统一画 N 块"，结果引入了尾迹且闪烁也没修好，
         *   所以退回来；重叠闪烁交给双缓冲解决（瞬态只在后台缓冲里，屏幕看不到）。 */
        if (!back_busy && path != PATH_CPU) {
            if (hw_frame_pushed) {
                if (blt_idle()) {
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
                    hw_done = 1;
                                        /* 'e' 打开：下一趟先整片铺背景再画全部块 ⇒ 不再擦掉压在旧位置上的邻居，
                     *   场景1 那种 2~3px 背景色拖影即消失；中间态被双缓冲挡住。 */
                    if (clear_pp) repaint_hw = 1;
                    scene_snap(g_sc[SIDE_HW], n);     /* 上一趟结束 → 为下一趟拍快照 */
                }
            } else if (repaint_hw && blt_can_push()) {
                blt_fill(FB_BACK + (uint32_t)hw_y0(path) * FB_STRIDE, FB_STRIDE,
                         FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
                repaint_hw = 0;
            } else {
                int budget = fence_on ? 1 : 32;
                int y0 = hw_y0(path);
                while (budget-- > 0 && blt_can_push() && !hw_fence) {
                    blk_t *b = &g_sc[SIDE_HW][hw_i];
                    /* ★ 擦除条件：ALPHA **必须每次都擦**，其余可以"没动就不擦"。
                     *   FILL/KEY 是幂等的（重画同一块结果不变），而 ALPHA 是
                     *   dest = blend(src, dest) —— 不擦就再混一次 ⇒ 一次比一次暗。
                     *   板级现象正是：方块不动时逐帧变暗、每次场景步进（移动后才擦）
                     *   亮度恢复 ⇒ 以 25Hz 周期性忽明忽暗。 */
                    if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
                        blt_fill(FB_BACK + (uint32_t)(b->dy + y0) * FB_STRIDE
                                          + (uint32_t)b->dx * 2u,
                                 FB_STRIDE, b->sz, b->sz, COL_BG);
                    {                                              /* 立刻画到本趟快照位置 */
                        uint32_t dst = FB_BACK + (uint32_t)(b->ty + y0) * FB_STRIDE
                                             + (uint32_t)b->tx * 2u;
                        if (scene == SC_FILL)
                            blt_fill(dst, FB_STRIDE, b->sz, b->sz, b->color);
                        else if (scene == SC_ALPHA)
                            blt_alpha(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
                                      SPR_W, SPR_H, alpha);
                        else
                            blt_key(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
                                    SPR_W, SPR_H, KEY_COLOR);
                    }
                    b->dx = b->tx; b->dy = b->ty;                  /* 记账：画的就是快照位置 */
                    if (++hw_i >= n) { hw_frame_pushed = 1; break; }
                    if (fence_on) { hw_fence = 1; break; }   /* 围栏：等这块彻底落地再发下一块 */
                }
            }
        }

        /* ---------------- CPU 侧：每圈一块，相邻式擦+画，同样用本趟快照 ---------------- */
        if (!back_busy && path != PATH_HW) {
            int y0 = cpu_y0(path);
            blk_t *b;
            if (repaint_cpu) {                 /* 场景/路径刚变过 → 先把这片区域铺背景 */
                cpu_fill32(FB_BACK, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
                repaint_cpu = 0;
            }
            b = &g_sc[SIDE_CPU][cpu_i];
            /* 同硬件侧：ALPHA 必须每次重铺背景（否则混合逐次叠加、越来越暗） */
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
                cpu_fill32(FB_BACK, b->dx, b->dy + y0, b->sz, b->sz, COL_BG);
            if (scene == SC_FILL)
                cpu_fill32(FB_BACK, b->tx, b->ty + y0, b->sz, b->sz, b->color);
            else if (scene == SC_ALPHA)
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
            else
                cpu_key_sprite(b->tx, b->ty + y0);
            b->dx = b->tx; b->dy = b->ty;
            if (++cpu_i >= n) {
                cpu_i = 0; cpu_frames++;
                cpu_done = 1;
                scene_snap(g_sc[SIDE_CPU], n);   /* 上一趟结束 → 为下一趟拍快照 */
            }
        }

        /* ---------------- OSD + 统计（每 300ms） ---------------- */
        if ((uint32_t)(tick() - t_osd) >= (uint32_t)(BSP_CLINT_HZ * 3u / 10u)) {
            uint32_t el = (uint32_t)(tick() - t_osd);
            uint32_t d_it = it - it_prev;
            char line[72];
            char *p = line;
            uint32_t sc = blt_rd(BLT_SCAN_DBG);

            t_osd = (uint32_t)tick();
            it_prev = it;

            hw_fps  = (uint32_t)(((uint64_t)hw_frames  * (uint64_t)BSP_CLINT_HZ) / el);
            disp_fps = (uint32_t)(((uint64_t)disp_frames * (uint64_t)BSP_CLINT_HZ) / el);
            cpu_fps = (uint32_t)(((uint64_t)cpu_frames * (uint64_t)BSP_CLINT_HZ) / el);

            cpu_fill32(FB_BACK, 0, 0, FB_WIDTH, OSD_H, COL_OSD_BG);
            p = app(p, (path == PATH_SPLIT) ? "SPLIT " :
                       ((path == PATH_CPU) ? "CPUMODE " : "HWMODE "));
            p = app(p, (scene == SC_FILL) ? "FILL " :
                       ((scene == SC_ALPHA) ? "ALPHA " : "KEY "));
            p = app(p, "N");    p = appn(p, (unsigned)n, 4);
            p = app(p, " A");   p = appn(p, alpha, 4);
            p = app(p, " HW");  p = appn(p, hw_fps, 5);
            p = app(p, " CPU"); p = appn(p, cpu_fps, 5);
            p = app(p, " SCR");p = appn(p, disp_fps, 5);
            *p = 0;
            osd_text(8, 4, line, COL_WHITE);

            /* ★ 分隔条与两侧标签**只在分屏模式画**：单模式是整屏渲染，中间不该有一条线，
             *   也不该残留上一次模式画的 "CPU"/"HW" 字样。
             *   （单模式下切换路径会触发整区重铺，把旧标签一起清掉。） */
            if (path == PATH_SPLIT) {
                osd_text(8, TOP_Y0 + 4, "HW", COL_HW_FG);
                cpu_fill32(FB_BACK, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
                osd_text(8, BOT_Y0 + 4, "CPU", COL_CPU_FG);
            } else if (path == PATH_CPU) {
                osd_text(8, TOP_Y0 + 4, "CPU ONLY", COL_CPU_FG);
            } else {
                osd_text(8, TOP_Y0 + 4, "HW ONLY", COL_HW_FG);
            }
            cache_evict();

            bsp_printf("S it=%d d=%d p=%d sc=%d N=%d A=%d HW=%d CPU=%d C=%d ST=%x ab=%d un=%d\r\n",
                       (int)it, (int)d_it, path, scene, n, (int)alpha,
                       (int)hw_fps, (int)cpu_fps,
                       (int)blt_cnt(), (unsigned)blt_stat(),
                       (int)(sc >> 16), (int)(sc & 0xFFFFu));

            hw_frames = 0; cpu_frames = 0; disp_frames = 0;
        }
    }
    return 0;
}
