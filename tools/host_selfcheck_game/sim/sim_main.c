/* =============================================================================
 * sim_main.c —— GameDemo 主机自检 / 全固件仿真（QEMU riscv32，**同一份固件源码**）
 * -----------------------------------------------------------------------------
 * 与 tools/host_selfcheck（AdDemo 那套「抽标记段 + 手写期望值」）的区别：
 *   这里**不抽段**，而是把 `GameDemo.c` **原样 #include 进来**，
 *   再把三个基址（DDR_BASE / BLT_BASE / UART_TERM）用 -D 覆盖到一块 RAM 上，
 *   用一个「假引擎 + 假时钟 + 假帧边界」把它跑起来。于是：
 *     · 被测的就是**将要烧进板子的那份源码**（一个字符都没改）；
 *     · 主循环、FLIP 三缓冲轮转、清屏引擎互斥、绘制清单构建、游戏逻辑、串口协议
 *       **全部真的被执行**，不是「读一遍代码觉得没问题」；
 *     · 每帧都能对绘制清单做不变量检查（尤其是**裁剪**：见 GameDemo.c 的 dl_sprite）。
 *
 * 覆盖范围（分组）：
 *   A 属性字 / 定点混合 / 帧预算模型         —— 纯算式，手算期望值
 *   B 串口协议（按键包 '@HH' + '=N' 行）      —— 穷举 + 定向向量 + 「两套协议不打架」
 *   C 游戏逻辑（夹紧 / 碰撞 / 弹池 / 表 / 长跑）—— 纯函数，跑 1800 帧
 *   D 主循环仿真（真实状态机，600 个上屏帧）  —— 帧数/裁剪/轮转/退化路径/输入生效
 *
 * ★ 已知的口径差别（**如实记录，不要当成通过**）：
 *   1) 假引擎「瞬时完成」：STATUS 恒为 DONE|FIFO_EMPTY ⇒ 仿真里的帧率恒为 60，
 *      **不能**用来测吞吐/极限 N。极限 N 只能上板用 `g` 自动爬坡量。
 *   2) 帧边界中断在仿真里是**电平恒高**（没有 W1C 的读副作用可模仿）⇒
 *      FLIP 的确认仍然被 FB_STAT 卡在真正的场边界上（帧率口径不受影响），
 *      但 `EV flip timeout` 那条有界超时分支在仿真里不会被走到。
 *   3) UART 的 RX 在仿真里恒为空（MMIO 读无法挂副作用）⇒ `serial_drain()` 的
 *      「无数据」路径被走到；**解析本身**由 B 组把 kp_feed/nline_feed 直接喂满，
 *      再由 C/D 组验证解析出来的按键状态真的驱动了自机。
 * ============================================================================= */

#include <stdint.h>
#include <stdarg.h>

/* ============================== 1. 控制台（QEMU virt 的 16550 @0x10000000） ============== */
#define QEMU_UART 0x10000000u
static void uputc(char c) { *(volatile unsigned char *)QEMU_UART = (unsigned char)c; }
static void uputs(const char *s) { while (*s) uputc(*s++); }
static void uputu(unsigned v)
{
    char b[12]; int n = 0;
    if (!v) { uputc('0'); return; }
    while (v) { b[n++] = (char)('0' + v % 10u); v /= 10u; }
    while (n) uputc(b[--n]);
}
static void uputi(int v) { if (v < 0) { uputc('-'); uputu((unsigned)(-v)); } else uputu((unsigned)v); }
static void uputx(unsigned v)
{
    const char *h = "0123456789ABCDEF";
    int i, st = 0;
    uputs("0x");
    for (i = 28; i >= 0; i -= 4) {
        unsigned d = (v >> i) & 0xFu;
        if (d || st || i == 0) { uputc(h[d]); st = 1; }
    }
}
/* ★ 裸机 + -nostdlib：GCC 在 -Os 下会把某些结构体/数组初始化编译成 memcpy/memset 调用，
 *   所以这里自带最小的实现（标准做法，不是 workaround）。 */
void *memcpy(void *dst, const void *src, unsigned n)
{
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n--) *d++ = *s++;
    return dst;
}
void *memset(void *dst, int c, unsigned n)
{
    unsigned char *d = (unsigned char *)dst;
    while (n--) *d++ = (unsigned char)c;
    return dst;
}
/* 极简字符串相等（sim 自己用；固件里没有 strcmp，也不该为了测试引入一个） */
static int sim_streq(const char *a, const char *b)
{
    while (*a && *a == *b) { a++; b++; }
    return (*a == *b) ? 1 : 0;
}

/* ============================== 2. 假 BSP（GameDemo.c 真正用到的那几个符号） ==============
 * ★ 必须是**非 static**（fake bsp.h 里的声明），这样 GameDemo.c 里的调用能链到这里来。 */
static int g_quiet   = 0;        /* 1 = 不再往控制台打固件日志（只计数） */
static unsigned g_fw_lines = 0;  /* 固件打过的行数（自检里要断言"它在说话"） */
#define FW_LINE_CAP 400

void bsp_init(void) { }
/* mini printf 的仿真版：只认 %c %s %d %X %x —— 与 BSP 的 print.h **同一份限制**
 * （超出这五种就原样打出来，而不是像真 BSP 那样错位消耗 va_arg 挂死）。 */
void bsp_printf(const char *fmt, ...)
{
    int show;
    va_list ap;
    va_start(ap, fmt);
    g_fw_lines++;
    show = (!g_quiet && g_fw_lines <= FW_LINE_CAP) ? 1 : 0;
    for (; *fmt; fmt++) {
        if (*fmt != '%') { if (show) uputc(*fmt); continue; }
        fmt++;
        switch (*fmt) {
        case 'c': { int c = va_arg(ap, int); if (show) uputc((char)c); break; }
        case 's': { const char *s = va_arg(ap, const char *); if (show) uputs(s ? s : "(null)"); break; }
        case 'd': { int v = va_arg(ap, int); if (show) uputi(v); break; }
        case 'X': { unsigned v = va_arg(ap, unsigned); if (show) uputx(v); break; }
        case 'x': { unsigned v = va_arg(ap, unsigned); if (show) uputx(v); break; }
        default:  if (show) { uputc('%'); uputc(*fmt); } break;
        }
    }
    va_end(ap);
}

/* ============================== 3. 导入固件（main 改名，其余一个字符不动） ============== */
#define main game_main
#include "GameDemo.c"
#undef main

/* ============================== 4. 假引擎 / 假时钟 / 假帧边界 ==============================
 * 三个基址由命令行 -D 覆盖：
 *     DDR_BASE  = 0x81000000   （帧缓冲 / 图集 / 屏障区都在它里面，相对布局一位不变）
 *     BLT_BASE  = 0x82000000   （引擎寄存器组：普通 RAM，读写即"生效"）
 *     UART_TERM = 0x82100000   （UART 寄存器：普通 RAM；RX 恒空，见文件头口径 3） */
#define MM(off)   (*(volatile uint32_t *)(BLT_BASE + (off)))
#define SIMW(a)   (*(volatile uint32_t *)(a))

#define SIM_TICK_STEP    4096u          /* 每次 tick32() 推进的核拍数 */
#define SIM_FRAME_TICKS  1666667u       /* 60Hz 场周期（与板级口径一致） */
#define SIM_FRAMES       600            /* 仿真跑多少个**已上屏帧** */

static uint32_t g_vnow      = 0;
static uint32_t g_next_bnd  = SIM_FRAME_TICKS;
static unsigned g_fields    = 0;
static unsigned g_presented = 0;
static unsigned g_repaint_seen = 0;
static unsigned g_frame_chk = 0;
static unsigned g_rect_bad  = 0;
static unsigned g_attr_bad  = 0;
static int      g_done      = 0;
static int      g_in_tick   = 0;   /* ★ 防重入：sim_input -> serial_apply_key -> tick32() */
static void sim_finish(void);

/* 自机活动范围（D 组断言"输入真的驱动了自机"） */
static int g_plr_min = 1 << 20, g_plr_max = -(1 << 20);
static int g_on_max  = 0;              /* 观测到的最大同屏元素数（高负载断言用） */
static unsigned g_op_seen[BULM_N];     /* 每个敌弹档实际渲染过的帧数（四档都要 != 0） */
static unsigned g_op_unknown = 0;      /* 弹尺寸的条目里出现了没见过的算子（守门人） */

/* 测试计数 */
static unsigned g_pass = 0, g_fail = 0;
#define CHECK(cond, name) do { if (cond) { g_pass++; } else { g_fail++; uputs("  *** FAIL: "); uputs(name); uputs("\n"); } } while (0)

/* 帧边界上「这次翻转真的换了一块缓冲吗」—— 与固件确认上屏是同一个事件 */
static int sim_sel_diff(void) { return ((MM(BLT_FB_SEL) & 3u) != (MM(BLT_FB_STAT) & 3u)) ? 1 : 0; }

static void sim_check_frame(void)
{
    int i;
    int bullet_op = -1;
    g_frame_chk++;
    if (g_dl_n > DRAW_MAX) g_rect_bad++;
    for (i = 0; i < g_dl_n; i++) {
        draw_t *d = &g_dl[i];
        if (d->op == DRAW_FILL_FULL) {
            if (d->x != 0 || d->y != PLAY_Y0) g_rect_bad++;
            else g_repaint_seen++;
            continue;
        }
        /* ★ 裁剪的守门人：每一条矩形都必须完整落在游戏区里（否则目的地址会算出界外） */
        if (d->x < 0 || d->y < PLAY_Y0) g_rect_bad++;
        else if ((int)d->x + (int)d->w > FB_WIDTH) g_rect_bad++;
        else if ((int)d->y + (int)d->h > FB_HEIGHT) g_rect_bad++;
        else if (d->w == 0 || d->h == 0) g_rect_bad++;
        if ((d->op == DRAW_KEY || d->op == DRAW_GLOW || d->op == DRAW_ALPHA) && d->arg >= S_N)
            g_attr_bad++;
        /* 弹尺寸（16x16）的精灵条目 = 敌弹 → 记下它用的是哪一档算子 */
        if (d->w == SZ_B && d->h == SZ_B && d->op != DRAW_FILL_FULL) {
            if (d->op == DRAW_FILL)       bullet_op = BULM_FILL;
            else if (d->op == DRAW_ALPHA) bullet_op = BULM_ALPHA;
            else if (d->op == DRAW_GLOW)  bullet_op = BULM_ADD;
            else if (d->op == DRAW_KEY)   bullet_op = BULM_KEY;
            else                          g_op_unknown++;
        }
    }
    if (bullet_op >= 0) g_op_seen[bullet_op]++;
    if (PX(g_px) < g_plr_min) g_plr_min = PX(g_px);
    if (PX(g_px) > g_plr_max) g_plr_max = PX(g_px);
    if (g_on_screen > g_on_max) g_on_max = g_on_screen;
}

/* 输入脚本：直接走**固件自己的解析器与命令分派**
 *   · '@HH' 包 -> kp_feed -> serial_apply_key
 *   · 单字符 -> serial_cmd（固件里那唯一一份 switch）
 *   · '=N'   -> nline_feed
 * ★ 按键状态是"整包替换"语义：上位机每次都要发**完整**的按键位图，
 *   所以这里也维护一个 g_sim_mask，心跳包重发的是它 —— 这正是真实上位机的行为
 *   （否则心跳会像最初那样把方向键悄悄清掉）。 */
static unsigned g_sim_mask = 0u;
static void sim_key(unsigned m) { char b[8]; const char *h = "0123456789abcdef";
    g_sim_mask = m;
    b[0] = '@'; b[1] = h[(m >> 4) & 0xF]; b[2] = h[m & 0xF]; b[3] = '\n'; b[4] = 0;
    { int i; unsigned mm = 0; for (i = 0; b[i]; i++) { int r = kp_feed((unsigned char)b[i], &mm);
        if (r == KP_OK) serial_apply_key(mm); } }
}
static void sim_cmd(const char *s)
{
    int i;
    unsigned m = 0u;
    for (i = 0; s[i]; i++) {
        int r = kp_feed((unsigned char)s[i], &m);
        if (r == KP_OK) { serial_apply_key(m); continue; }
        if (r != KP_NONE) continue;
        {
            int nc = 0;
            int nl = nline_feed((unsigned char)s[i], &nc, N_MIN, N_MAX);
            if (nl == NL_OK) { g_ncap = nc; g_auto = 0; continue; }
            if (nl != NL_NONE) continue;
        }
        serial_cmd((unsigned char)s[i]);
    }
}
static void sim_input(unsigned f)
{
    switch (f) {
    case 4:   sim_key(KEY_FIRE);                       break;  /* 开火 → 从标题页开始 */
    case 30:  sim_key(KEY_DOWN | KEY_RIGHT | KEY_FIRE); break;
    case 70:  sim_key(KEY_LEFT | KEY_FIRE);             break;  /* 往左跑一段 */
    case 110: sim_key(KEY_RIGHT | KEY_FIRE);            break;  /* 再往右跑 */
    case 150: sim_key(KEY_UP | KEY_FOCUS | KEY_FIRE);   break;  /* 慢速上移 */
    case 165: sim_key(KEY_FIRE);                        break;
    case 170: sim_key(KEY_FIRE | KEY_BOMB);             break;  /* 炸弹（上升沿） */
    case 175: sim_key(KEY_FIRE);                        break;
    case 200: sim_cmd("3");                             break;  /* 预设 N=1280 */
    case 240: sim_cmd("=2400\n");                       break;  /* 行命令精确 N（压到上限） */
    case 260: sim_cmd("g");                             break;  /* 自动爬坡开 */
    case 300: sim_cmd("g");                             break;  /* 爬坡关（避免 N 一路涨） */
    case 320: sim_cmd("5");                             break;  /* ★ 敌弹 = FILL */
    case 340: sim_cmd("6");                             break;  /* ★ 敌弹 = ALPHA */
    case 360: sim_cmd("7");                             break;  /* ★ 敌弹 = ADD（原来的辉光） */
    case 380: sim_cmd("8");                             break;  /* ★ 敌弹 = KEY */
    case 400: sim_cmd("f");                             break;  /* ★ 循环回 FILL */
    case 420: sim_cmd("c");                             break;  /* 切纯 CPU 对照路径 */
    case 450: sim_cmd("h");                             break;  /* 切回硬件路径 */
    case 470: sim_cmd("d");                             break;  /* 诊断行 */
    case 480: sim_key(KEY_FIRE | KEY_LEFT);             break;
    case 540: sim_cmd("r");                             break;  /* 重开一局 */
    case 545: sim_key(KEY_FIRE);                        break;
    default: break;
    }
    /* 心跳：整包重发当前状态（真实上位机每 100ms 也是这么发的） */
    if (f > 4 && (f % 6) == 0) sim_key(g_sim_mask);
}

static void sim_tick(void)
{
    if (g_in_tick) return;                       /* ★ 重入保护（见 g_in_tick 声明处） */
    g_in_tick = 1;
    g_vnow += SIM_TICK_STEP;
    /* 假引擎：FIFO 立刻被消费 ⇒ 恒空闲 */
    MM(BLT_STATUS)         = 0x0Au;                 /* DONE | FIFO_EMPTY */
    MM(BLT_CMD_FIFO_COUNT) = 0u;
    MM(BLT_SCAN_DBG)       = 0u;
    MM(BLT_DL_VERSION)     = 0x02100002u;           /* 与 rtl 回读值一致 */
    MM(BLT_IRQ_STATUS)     = 2u;                    /* 帧边界中断（电平，见口径 2） */
    /* 清屏引擎：每 7 个场强制报一次「不干净」⇒ 命令式整片重铺那条退化路径也跑到 */
    MM(BLT_CLR_STAT) = ((g_fields % 7u) == 3u) ? (1u << 1)
                                               : ((1u << 1) | (0xFu << 2));
    if (g_vnow >= g_next_bnd) {
        g_next_bnd += SIM_FRAME_TICKS;
        g_fields++;
        sim_check_frame();
        if (sim_sel_diff()) {
            g_presented++;
            sim_input(g_presented);
        }
        MM(BLT_FB_STAT) = (MM(BLT_FB_SEL) & 3u) | ((g_fields & 0xFFFFu) << 16);
        if (g_presented >= (unsigned)SIM_FRAMES && !g_done) { g_done = 1; sim_finish(); }
    }
    g_in_tick = 0;
}
uint32_t clint_getTimeLow(int p) { (void)p; sim_tick(); return g_vnow; }


static void group_A(void)
{
    uputs("\n[A] 属性字 / 定点混合 / 帧预算模型\n");
    /* A1 属性字编解码 round-trip + 默认字 */
    {
        struct { unsigned b, f, g, fl; } tv[4];
        int i, bad = 0;
        tv[0].b = ATTR_BLEND_OP;    tv[0].f = ATTR_FMT_565;  tv[0].g = 255u; tv[0].fl = 0u;
        tv[1].b = ATTR_BLEND_ALPHA; tv[1].f = ATTR_FMT_4444; tv[1].g = 128u; tv[1].fl = 0u;
        tv[2].b = ATTR_BLEND_ADD;   tv[2].f = ATTR_FMT_565;  tv[2].g = 96u;  tv[2].fl = 0u;
        tv[3].b = ATTR_BLEND_MUL;   tv[3].f = ATTR_FMT_1555; tv[3].g = 64u;  tv[3].fl = ATTR_FLAG_ATEST;
        for (i = 0; i < 4; i++) {
            uint32_t w = attr_word(tv[i].b, tv[i].f, tv[i].g, tv[i].fl);
            if (attr_blend(w) != tv[i].b || attr_fmt(w) != tv[i].f ||
                attr_ga(w) != tv[i].g || attr_flags(w) != tv[i].fl) bad++;
        }
        CHECK(bad == 0, "A1 attr_word 编解码 round-trip");
        CHECK(ATTR_DEFAULT == 0x00003FC0u, "A1 默认字 = 0x00003FC0（硬件空 FIFO 的等价字）");
        CHECK((attr_word(ATTR_BLEND_ADD, ATTR_FMT_565, 255u, 0u) & 0x3FFFu) ==
              (0x3FC0u | ATTR_BLEND_ADD), "A1 加算档位只动 blend 字段");
    }
    /* A2/A3 定点混合手算期望值（与 rtl/pixel_path.v 同式） */
    CHECK(blend565(0xF800u, 0x001Fu, 128u) == 0x780Fu, "A2 blend565(红,蓝,128) == 0x780F");
    CHECK(blend565(0xFFFFu, 0x0000u, 255u) == 0xFFFFu, "A2 blend565(白,黑,255) == 白");
    CHECK(add565(0xF800u, 0x001Fu, 255u) == 0xF81Fu, "A3 add565(红,蓝,255) == 0xF81F");
    CHECK(add565(0x0000u, 0x1234u, 255u) == 0x1234u, "A3 add565(黑,X,255) == X（辉光「黑=透明」）");
    CHECK(add565(0xFFFFu, 0xFFFFu, 255u) == 0xFFFFu, "A3 add565 饱和钳位");
    CHECK(add565(0x0000u, 0x1234u, 0u) == 0x1234u, "A3 add565 ga=0 == 背景");
    /* A4 帧预算模型：必须复现文档里的板级实测「每块 = A + B×px」。
     * ★ 16x16 与 64x64 是**逐拍精确**的；32x32 有 −3.3% 的拟合残差，
     *   这与《性能优化成果与计划》§3 记的「32×32 三点残差 −2.9%/−3.9%/−3.2%」一致
     *   ⇒ 测试按 ±5% 放行，并在注释里写明残差是模型固有的，不是实现算错。 */
    CHECK(cyc_of(DRAW_FILL, 16) == 514u,  "A4 模型 16x16 FILL  == 514 拍（板测 514.3）");
    CHECK(cyc_of(DRAW_KEY,  16) == 719u,  "A4 模型 16x16 KEY   == 719 拍（板测 719.1）");
    CHECK(cyc_of(DRAW_GLOW, 16) == 856u,  "A4 模型 16x16 ALPHA == 856 拍（板测 856.4）");
    CHECK(cyc_of(DRAW_GLOW, 64) == 6743u, "A4 模型 64x64 ALPHA == 6743 拍（板测 6742.7）");
    {
        int v = (int)cyc_of(DRAW_GLOW, 32);
        CHECK(v > 1969 - 99 && v < 1969 + 99, "A4 模型 32x32 ALPHA ≈ 1969 拍（拟合残差 ±5%）");
    }
    /* A6 信息条最坏串：宽度必须塞得进黑底，且字形全覆盖（OP= 字段是新加的） */
    {
        char worst[OSD_LEFT_CH + 2];
        int k, miss = 0;
        fmt_stat(worst, 999u, 999u, N_MAX, 9999, SCORE_CAP, 99, 9, "ALPHA", 1, 1);
        for (k = 0; worst[k]; k++) if (!glyph_found(worst[k])) miss++;
        for (k = 0; path_label()[k]; k++) if (!glyph_found(path_label()[k])) miss++;
        CHECK(slen(worst) <= OSD_LEFT_CH, "A6 信息条最坏串不超黑底（含 OP= 字段）");
        CHECK(miss == 0, "A6b 最坏串与路径标签的字形全覆盖");
        uputs("   A6 观测：worst=\""); uputs(worst); uputs("\"  len=");
        uputu((unsigned)slen(worst)); uputs(" limit="); uputu((unsigned)OSD_LEFT_CH); uputs("\n");
    }
    /* A7 帧预算模型：三种算子同预算下的容量排序（FILL 最省、ALPHA 最贵） */
    {
        unsigned f = cost_capacity(DRAW_FILL,  SZ_B, 70, 0);
        unsigned k = cost_capacity(DRAW_KEY,   SZ_B, 70, 0);
        unsigned a = cost_capacity(DRAW_ALPHA, SZ_B, 70, 0);
        CHECK(f > k && k > a, "A7 三种算子容量排序 FILL > KEY > ALPHA");
    }
    CHECK(cost_capacity(DRAW_GLOW, 16, 70, 1) >= cost_capacity(DRAW_GLOW, 16, 70, 0),
          "A5 双 lane 容量 >= 单 lane 容量");
    CHECK(cost_capacity(DRAW_GLOW, 16, 70, 0) > 1000u &&
          cost_capacity(DRAW_GLOW, 16, 70, 0) < 3000u, "A5 16x16 辉光 70% 预算容量在合理量级");
}

static void group_B(void)
{
    int i, ok;
    uputs("\n[B] 串口协议（按键包 '@HH' + '=N' 行命令）\n");
    /* B1 定向向量 */
    {
        unsigned m; int r;
        g_kp_on = 0; m = 0;
        r = kp_feed('@', &m); CHECK(r == KP_MORE, "B1 '@' 起包");
        r = kp_feed('0', &m); r = kp_feed('0', &m); r = kp_feed('\n', &m);
        CHECK(r == KP_OK && m == 0u, "B1 \"@00\\n\" -> mask 0");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); kp_feed('f', &m); kp_feed('F', &m);
        r = kp_feed('\n', &m); CHECK(r == KP_OK && m == 0xFFu, "B1 \"@fF\\n\" 大小写都认 -> 0xFF");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); kp_feed('0', &m); kp_feed('f', &m);
        r = kp_feed('\r', &m); CHECK(r == KP_OK && m == 0x0Fu, "B1 '\\r' 也当行结束 -> 0x0F");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); r = kp_feed('\n', &m); CHECK(r == KP_ERR, "B1 \"@\\n\" 位数不足 -> ERR");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); kp_feed('1', &m); r = kp_feed('\n', &m);
        CHECK(r == KP_ERR, "B1 \"@1\\n\" 只有一位 -> ERR");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); kp_feed('1', &m); r = kp_feed('z', &m);
        CHECK(r == KP_ERR && g_kp_on == 0, "B1 非十六进制立刻作废并复位");
        g_kp_on = 0; m = 0;
        kp_feed('@', &m); kp_feed('1', &m); kp_feed('2', &m); r = kp_feed('3', &m);
        CHECK(r == KP_ERR, "B1 超长 -> ERR");
    }
    /* B2 穷举：长度 1..4、字母表 6 个字符的全部组合（6+36+216+1296 = 1554 条）
     *    判据：不崩、且**只有**"@+2 个十六进制+行结束"这一种形态能返回 KP_OK。 */
    {
        const char alpha[6] = { '@', '0', 'F', '\n', 'g', '=' };
        int a1, a2, a3, a4, cases = 0, bad = 0, okcnt = 0;
        for (a1 = 0; a1 < 6; a1++)
        for (a2 = -1; a2 < 6; a2++)
        for (a3 = -1; a3 < 6; a3++)
        for (a4 = -1; a4 < 6; a4++) {
            char s[4]; int n = 1, k, res = KP_NONE; unsigned m = 0;
            s[0] = alpha[a1];
            if (a2 >= 0) s[n++] = alpha[a2];
            if (a3 >= 0) s[n++] = alpha[a3];
            if (a4 >= 0) s[n++] = alpha[a4];
            if (n > 4) continue;
            g_kp_on = 0;
            for (k = 0; k < n; k++) { res = kp_feed((unsigned char)s[k], &m); if (res == KP_OK) break; }
            cases++;
            if (res == KP_OK) {
                okcnt++;
                /* 合法形态只可能是 @ <hex> <hex> <term> 四字节 */
                if (!(n == 4 && s[0] == '@' && kp_hexval(s[1]) >= 0 &&
                      kp_hexval(s[2]) >= 0 && (s[3] == '\n'))) bad++;
            }
        }
        CHECK(cases == 2058, "B2 穷举用例数 == 2058（长度 1..4、字母表 6 字符）");
        CHECK(bad == 0, "B2 穷举：KP_OK 只出现在 \"@HH\\n\"");
        CHECK(okcnt > 0, "B2 穷举里确实有合法包被接受");
    }
    /* B3 命令字节绝不被按键包吞掉（两套协议不打架） */
    {
        const char *cmds = "1234nN+-cChHgGbBpPrRdD?=";
        unsigned m = 0; int bad = 0;
        for (i = 0; cmds[i]; i++) { g_kp_on = 0; if (kp_feed(cmds[i], &m) != KP_NONE) bad++; }
        CHECK(bad == 0, "B3 所有单字符命令都返回 KP_NONE（原样交回命令分支）");
    }
    /* B4 '=N' 行命令语义（只钳不拒） */
    {
        struct { const char *s; int want; int res; } tv[5];
        int k;
        tv[0].s = "=1375\n"; tv[0].want = 1375; tv[0].res = NL_OK;
        tv[1].s = "=10\n";   tv[1].want = N_MIN; tv[1].res = NL_OK;
        tv[2].s = "=9999\n"; tv[2].want = N_MAX; tv[2].res = NL_OK;
        tv[3].s = "=\n";     tv[3].want = 0;     tv[3].res = NL_ERR;
        tv[4].s = "=12x\n";  tv[4].want = 0;     tv[4].res = NL_ERR;
        ok = 1;
        for (k = 0; k < 5; k++) {
            int nc = 0, r = NL_NONE;
            for (i = 0; tv[k].s[i]; i++) { r = nline_feed(tv[k].s[i], &nc, N_MIN, N_MAX); if (r != NL_MORE) break; }
            if (r != tv[k].res) ok = 0;
            if (r == NL_OK && nc != tv[k].want) ok = 0;
            g_nl_on = 0;
        }
        CHECK(ok, "B4 '=N' 精确/钳位/错误语义");
    }
    /* B5 uart_poll_char：直接 poke 假 UART 寄存器（RX 占用在 status[31:24]） */
    {
        int a, b, c;
        SIMW(UART_TERM + 0x04u) = 0u;
        a = uart_poll_char();
        SIMW(UART_TERM + 0x00u) = 0x41u;
        SIMW(UART_TERM + 0x04u) = (1u << 24);
        b = uart_poll_char();
        SIMW(UART_TERM + 0x04u) = (3u << 24);
        c = uart_poll_char();
        SIMW(UART_TERM + 0x04u) = 0u;
        CHECK(a == 0, "B5 RX 空 -> uart_poll_char() == 0");
        CHECK(b == 0x41 && c == 0x41, "B5 RX 有数据 -> 返回数据字节（判据是 >>24 而不是 >>16）");
        /* ★ 旧版真 bug 的守门人：把占用挪到 TX 位（>>16）必须**读不到** */
        SIMW(UART_TERM + 0x04u) = (1u << 16);
        CHECK(uart_poll_char() == 0, "B5 只看 status[31:24]（TX 余量字段不得被当成 RX）");
        SIMW(UART_TERM + 0x04u) = 0u;
    }
}

static void group_C(void)
{
    uputs("\n[C] 游戏逻辑（纯函数 + 长跑）\n");
    int i;
    /* C1 ent_clamp：四个方向都夹回区内并**只把那一个轴**的速度反向
     *   （另一轴本来就在区内，速度不该被动） */
    {
        ent_t t; int bad = 0;
        int xs[4], ys[4], flipx[4], flipy[4];
        xs[0] = FP(-99);  ys[0] = FP(300);  flipx[0] = 1; flipy[0] = 0;
        xs[1] = FP(2000); ys[1] = FP(300);  flipx[1] = 1; flipy[1] = 0;
        xs[2] = FP(100);  ys[2] = FP(-99);  flipx[2] = 0; flipy[2] = 1;
        xs[3] = FP(100);  ys[3] = FP(9000); flipx[3] = 0; flipy[3] = 1;
        for (i = 0; i < 4; i++) {
            t.x = (int16_t)xs[i]; t.y = (int16_t)ys[i]; t.vx = 8; t.vy = 8;
            t.sz = SZ_B; t.r = 4; t.kind = S_B0; t.life = 1;
            ent_clamp(&t);
            if (PX(t.x) < 0 || PX(t.x) + SZ_B > PLAY_W) bad++;
            if (PX(t.y) < PLAY_Y0 || PX(t.y) + SZ_B > PLAY_Y1) bad++;
            if (flipx[i] && t.vx != -8) bad++;
            if (flipy[i] && t.vy != -8) bad++;
            if (!flipx[i] && t.vx != 8) bad++;
            if (!flipy[i] && t.vy != 8) bad++;
        }
        CHECK(bad == 0, "C1 ent_clamp：夹回区内 + 只反越界那一轴的速度");
    }
    /* C2 圆-圆碰撞边界 */
    CHECK(hit_cc(100, 100, 4, 108, 100, 4) == 1, "C2 相切（距离 == r1+r2）算命中");
    CHECK(hit_cc(100, 100, 4, 109, 100, 4) == 0, "C2 差 1 像素不算命中");
    CHECK(hit_cc(0, 0, 0, 0, 0, 0) == 1, "C2 半径 0 重叠算命中");
    /* C3 弹池容量 = N（敌弹）/ PLR_SLOTS（自机弹），互不挤占 */
    {
        int k, got, bad = 0;
        for (k = 0; k < BUL_TOTAL; k++) g_bul[k].life = 0;
        g_ncap = 100;
        for (k = 0; k < 100; k++) { got = bul_alloc_enemy(); if (got < 0) bad++; else g_bul[got].life = 1; }
        CHECK(bad == 0, "C3 前 100 个敌弹槽都能拿到");
        CHECK(bul_alloc_enemy() < 0, "C3 敌弹池满 -> 返回 -1（这就是同屏上限的物理含义）");
        CHECK(bul_alloc(0, PLR_SLOTS) >= 0, "C3 敌弹池满时自机弹仍拿得到槽位");
        g_ncap = 256;
        for (k = 0; k < BUL_TOTAL; k++) g_bul[k].life = 0;
    }
    /* C4 isqrt32 */
    {
        int bad = 0;
        for (i = 0; i <= 1000; i++) if (isqrt32((uint32_t)(i * i)) != i) bad++;
        CHECK(bad == 0, "C4 isqrt32 对 0..1000 的完全平方精确");
        CHECK(isqrt32(2u) == 1, "C4 isqrt32(2) == 1");
    }
    /* C5 正余弦表 */
    {
        int bad = 0;
        for (i = 0; i < 64; i++) {
            long s = isin(i), c = icos(i);
            long n = s * s + c * c;
            if (s < -256 || s > 256 || c < -256 || c > 256) bad++;
            if (n < 62000L || n > 69000L) bad++;      /* 256² = 65536，量化误差 <5% */
        }
        CHECK(bad == 0, "C5 sin/cos 表定标 256、平方和 ≈ 65536");
    }
    /* C6 无渲染长跑 1800 帧：不越界、不超上限、不泄漏 */
    {
        int bad = 0, maxalive = 0, k;
        unsigned km = 0u;
        g_quiet = 1;
        g_seed = 0x12345678u;
        g_star_n = STAR_MAX;
        stars_reset();
        game_reset();
        g_ncap = 512;
        g_hp = 99;                      /* 长跑只验不变量，不让它中途 GameOver */
        for (i = 0; i < 1800; i++) {
            int alive = 0;
            if (i == 60)  km = KEY_FIRE | KEY_RIGHT;
            if (i == 400) km = KEY_FIRE | KEY_LEFT | KEY_UP;
            if (i == 900) km = KEY_FIRE | KEY_FOCUS;
            g_keymask = km;
            game_tick();
            for (k = 0; k < BUL_TOTAL; k++) if (g_bul[k].life) alive++;
            if (alive > maxalive) maxalive = alive;
            if (alive > BUL_TOTAL) bad++;
            if (PX(g_px) < 0 || PX(g_px) > FB_WIDTH) bad++;
            if (PX(g_py) < PLAY_Y0 || PX(g_py) > PLAY_Y1) bad++;
            if (g_score < 0 || g_score > SCORE_CAP) bad++;
        }
        g_quiet = 0;
        CHECK(bad == 0, "C6 1800 帧长跑：自机不出界 / 分数不越界");
        CHECK(maxalive <= BUL_TOTAL, "C6 同屏弹数不超过池容量");
        CHECK(g_state == GS_PLAY, "C6 长跑后仍在游戏状态（没被误判 GameOver）");
        uputs("   C6 观测：maxalive="); uputu((unsigned)maxalive);
        uputs(" score="); uputu((unsigned)g_score);
        uputs(" level="); uputu((unsigned)g_level); uputs("\n");
    }
    /* C7 自动爬坡纯函数：从 N_MIN 收敛到 N_MAX，掉帧时回退并给 LIMIT */
    {
        int n = N_MIN, lim = 0, on = 1, r, steps = 0;
        while (on && steps < 10000) { r = ramp_apply(60, &n, &lim, &on); steps++; }
        CHECK(r == 2 && n == N_MAX, "C7 帧率充裕时爬坡顶到 N_MAX 并停下");
        n = 1024; lim = 0; on = 1;
        r = ramp_apply(30, &n, &lim, &on);
        CHECK(r == -1 && on == 0 && lim == n, "C7 帧率不足时回退一档、给 LIMIT、关掉爬坡");
        n = 1024; lim = 0; on = 0;
        CHECK(ramp_apply(10, &n, &lim, &on) == 0 && n == 1024, "C7 爬坡关着时一动不动");
    }
}

/* ============================== 6. E 组：敌弹显示模式 ============================== */
static void group_E(void)
{
    int i;
    uputs("\n[E] 敌弹显示模式 FILL / ALPHA / ADD / KEY\n");

    /* E1 '5'/'6'/'7'/'8' 直选四档（走固件自己的 serial_cmd） */
    {
        const char keys[4] = { '5', '6', '7', '8' };
        const int  want[4] = { BULM_FILL, BULM_ALPHA, BULM_ADD, BULM_KEY };
        int bad = 0;
        g_quiet = 1;
        for (i = 0; i < 4; i++) { g_bulm = -1; serial_cmd(keys[i]); if (g_bulm != want[i]) bad++; }
        g_quiet = 0;
        CHECK(bad == 0, "E1 '5'/'6'/'7'/'8' 分别选中 FILL/ALPHA/ADD/KEY");
    }
    /* E2 'f' 循环 FILL→ALPHA→ADD→KEY→FILL；'F' 等价 */
    {
        int bad = 0;
        g_quiet = 1;
        g_bulm = BULM_FILL;
        for (i = 0; i < 4; i++) {
            int want = (BULM_FILL + i + 1) % BULM_N;
            serial_cmd('f');
            if (g_bulm != want) bad++;
        }
        g_quiet = 0;
        CHECK(bad == 0 && g_bulm == BULM_FILL, "E2 'f' 循环一圈回到 FILL（4 档）");
        g_quiet = 1; serial_cmd('F'); g_quiet = 0;
        CHECK(g_bulm == BULM_ALPHA, "E2b 大写 'F' 与 'f' 等价");
    }
    /* E3 生效档名：ADD 在没有属性侧口时必须如实报成 KEY（HUD 不许说谎） */
    {
        int save = g_glow, bad = 0;
        g_glow = 1; g_bulm = BULM_ADD;
        if (!sim_streq(bulm_eff_name(), "ADD")) bad++;
        g_glow = 0;
        if (!sim_streq(bulm_eff_name(), "KEY")) bad++;
        g_bulm = BULM_FILL;
        if (!sim_streq(bulm_eff_name(), "FILL")) bad++;      /* FILL 不受 attr 影响 */
        g_bulm = BULM_ALPHA;
        if (!sim_streq(bulm_eff_name(), "ALPHA")) bad++;
        g_glow = save; g_bulm = BULM_ADD;
        CHECK(bad == 0, "E3 bulm_eff_name：ADD 无属性侧口时报 KEY，其余档名原样");
    }
    /* E4 切档真的改变绘制清单里的算子；FILL 档用纯色方块、其余档用精灵 */
    {
        int save_state = g_state, save_star = g_star_n, save_inv = g_invuln;
        int save_mode = g_bulm;
        int k, bad = 0;
        for (k = 0; k < ENEMY_MAX; k++) g_en[k].t = 0;
        for (k = 0; k < SPARK_MAX; k++) g_spk[k].life = 0;
        for (k = 0; k < BUL_TOTAL; k++) g_bul[k].life = 0;
        g_star_n = 0;
        g_state = GS_OVER;            /* 不画自机 ⇒ 清单里只剩我们要的这一条 */
        g_invuln = 0;
        g_bul[PLR_SLOTS].life = 10;   /* 正好一颗敌弹，放正中央（不会被裁掉） */
        g_bul[PLR_SLOTS].x    = (int16_t)FP(FB_WIDTH / 2);
        g_bul[PLR_SLOTS].y    = (int16_t)FP(PLAY_Y0 + 200);
        g_bul[PLR_SLOTS].kind = S_B0;
        g_bul[PLR_SLOTS].sz   = SZ_B;
        g_bul[PLR_SLOTS].r    = 4;
        g_bul[PLR_SLOTS].vx   = 0;
        g_bul[PLR_SLOTS].vy   = 0;

        {
            const int  mode[4]  = { BULM_FILL, BULM_ALPHA, BULM_ADD, BULM_KEY };
            const int  wop[4]   = { DRAW_FILL, DRAW_ALPHA, DRAW_GLOW, DRAW_KEY };
            for (i = 0; i < 4; i++) {
                g_bulm = mode[i];
                build_draw_list(0);
                if (g_dl_n != 1) { bad++; continue; }
                if (g_dl[0].op != wop[i]) bad++;
                if (g_dl[0].w != SZ_B || g_dl[0].h != SZ_B) bad++;
                if (mode[i] == BULM_FILL) {
                    if (g_dl[0].arg != g_spr_fill[S_B0]) bad++;   /* FILL 的 arg 是颜色 */
                } else {
                    if (g_dl[0].arg != (uint16_t)S_B0) bad++;     /* 其余是精灵号 */
                }
                if (mode[i] == BULM_ALPHA && g_dl[0].ga != BUL_ALPHA_V) bad++;
            }
        }
        CHECK(bad == 0, "E4 四档在绘制清单里分别落到 FILL/ALPHA/GLOW/KEY 算子（尺寸/载荷都对）");
        /* 收尾：把现场还原成"能继续跑"的状态 */
        for (k = 0; k < BUL_TOTAL; k++) g_bul[k].life = 0;
        g_state = save_state; g_star_n = save_star; g_invuln = save_inv; g_bulm = save_mode;
    }
    /* E5 容量排序：同样 16x16、同样 70% 帧预算 ⇒ FILL > KEY > ALPHA（这就是"切档为什么值得"） */
    {
        unsigned f = cost_capacity(DRAW_FILL,  SZ_B, 70, 0);
        unsigned k = cost_capacity(DRAW_KEY,   SZ_B, 70, 0);
        unsigned a = cost_capacity(DRAW_ALPHA, SZ_B, 70, 0);
        CHECK(f > k && k > a, "E5 容量排序 FILL > KEY > ALPHA（单 lane 板测口径）");
        CHECK(f > a + 200u, "E5b FILL 比 ALPHA 多出的容量是可观的（>200 颗/帧）");
        uputs("   E5 观测：16x16 @70% 预算 FILL="); uputu(f);
        uputs(" KEY="); uputu(k); uputs(" ALPHA="); uputu(a); uputs("\n");
    }
    g_bulm = g_glow ? BULM_ADD : BULM_KEY;      /* 还原默认档，交给 D 组的输入脚本去切 */
}

/* ============================== 7. 收尾：D 组结论 + 总账 ============================== */
#define SIM_FINISHER 0x00100000u    /* QEMU virt 的 SiFive test 设备：写 0x5555 = 退出码 0 */

static void sim_finish(void)
{
    unsigned secs_x100 = (unsigned)(((uint64_t)g_vnow * 100u) / (uint64_t)BSP_CLINT_HZ);
    uputs("\n[D] 主循环仿真（真实状态机，");
    uputu((unsigned)SIM_FRAMES);
    uputs(" 个上屏帧）\n");

    CHECK(g_presented >= (unsigned)SIM_FRAMES, "D1 跑满目标帧数（状态机没有卡死）");
    CHECK(g_frame_chk == (unsigned)SIM_FRAMES, "D1 每个场边界都检查过一次绘制清单");
    CHECK(g_rect_bad == 0, "D2 每一帧的每个矩形都完整落在游戏区内（裁剪生效）");
    CHECK(g_attr_bad == 0, "D3 绘制清单里的精灵号都合法（< S_N）");
    CHECK(g_dl_n <= DRAW_MAX, "D4 绘制清单不溢出（<= DRAW_MAX）");
    CHECK(g_repaint_seen > 0, "D5 走通过「清屏不干净 -> 命令式整片重铺」的退化路径");
    CHECK(g_plr_max > g_plr_min + 40, "D6 串口按键真的驱动了自机（横向行程 > 40px）");
    CHECK(g_ncap > 256, "D7 预设/爬坡/行命令真的抬高了 N");
    CHECK(g_on_max > 600, "D8 高负载：同屏元素数确实被推到 600 以上（N=2400 档）");
    CHECK(g_op_seen[BULM_FILL] > 0 && g_op_seen[BULM_ALPHA] > 0 &&
          g_op_seen[BULM_ADD] > 0 && g_op_seen[BULM_KEY] > 0,
          "D9 四档敌弹在真机主循环里都被渲染过（FILL/ALPHA/ADD/KEY 各 != 0 帧）");
    CHECK(g_op_unknown == 0, "D10 弹尺寸条目里只出现四种已知算子");
    {
        uputs("   D 观测：敌弹各档渲染帧数 FILL="); uputu(g_op_seen[BULM_FILL]);
        uputs(" ALPHA="); uputu(g_op_seen[BULM_ALPHA]);
        uputs(" ADD=");   uputu(g_op_seen[BULM_ADD]);
        uputs(" KEY=");   uputu(g_op_seen[BULM_KEY]);
        uputs(" 未知=");  uputu(g_op_unknown); uputs("\n");
    }
    CHECK(g_hw_fps > 0 || g_sw_fps > 0, "D11 1Hz 帧率窗口算出过非零帧率");
    CHECK(g_fw_lines > 0, "D12 固件在往串口说话（日志行数 > 0）");
    CHECK(g_stto == 0, "D13 没有触发过引擎有界恢复（blt_recover）");
    CHECK(g_flip_to == 0, "D14 没有触发过翻转超时（有界等待正常）");
    {
        /* 帧率口径：上屏帧数 / 虚拟秒数。仿真里假引擎瞬时完成 ⇒ 应该正好贴住 60 */
        unsigned fps_x10 = (secs_x100 == 0u) ? 0u
                         : (unsigned)(((uint64_t)g_presented * 10u * 100u) / (uint64_t)secs_x100);
        uputs("   D 观测：presented="); uputu(g_presented);
        uputs(" vnow="); uputu(g_vnow);
        uputs(" (约 "); uputu(secs_x100 / 100u); uputs(".");
        uputu(secs_x100 % 100u); uputs(" s 虚拟时间)");
        uputs("  fps_x10="); uputu(fps_x10);
        uputs("\n   D 观测：自机 x ∈ ["); uputi(g_plr_min); uputs(", "); uputi(g_plr_max); uputs("]");
        uputs("  N="); uputu((unsigned)g_ncap);
        uputs(" ON_max="); uputu((unsigned)g_on_max);
        uputs(" score="); uputu((unsigned)g_score);
        uputs(" level="); uputu((unsigned)g_level);
        uputs(" attr="); uputu((unsigned)g_attr_on);
        uputs(" glow="); uputu((unsigned)g_glow);
        uputs(" start_sel="); uputu((unsigned)g_disp_sel);
        uputs("\n");
        CHECK(fps_x10 >= 590u && fps_x10 <= 610u, "D15 上屏帧率贴住 60fps（假引擎瞬时完成）");
    }

    uputs("\n===== GameDemo host self-check: ");
    uputu(g_pass); uputs(" passed / "); uputu(g_fail); uputs(" failed =====\n");
    *(volatile uint32_t *)SIM_FINISHER = 0x5555u;
    for (;;) { }
}

int main(void)
{
    uputs("\n===== GameDemo host self-check (QEMU riscv32, 真实固件源码 + 假引擎) =====\n");
    uputs("firmware: src/GameDemo.c 原样 #include；基址覆盖 DDR=0x81000000 BLT=0x82000000 UART=0x82100000\n");
    uputs("N_MAX="); uputu((unsigned)N_MAX);
    uputs(" BUL_TOTAL="); uputu((unsigned)BUL_TOTAL);
    uputs(" DRAW_MAX="); uputu((unsigned)DRAW_MAX);
    uputs(" S_N="); uputu((unsigned)S_N);
    uputs(" ATLAS_BYTES="); uputu((unsigned)ATLAS_BYTES);
    uputs("\nbulm modes: ");
    { int k; for (k = 0; k < BULM_N; k++) { if (k) uputs("/"); uputs(g_bulm_name[k]); } }
    uputs("  (keys f cycle, 5/6/7/8 direct)\n");

    group_A();
    group_B();
    group_C();
    group_E();

    uputs("\n[D] 启动固件主循环（跑 ");
    uputu((unsigned)SIM_FRAMES);
    uputs(" 帧后自动收尾）...\n");
    g_seed = 0x0BADF00Du;
    game_main(0, 0);        /* ★ 真·固件入口；永不返回，由 sim_finish() 退出 QEMU */
    return 0;
}

