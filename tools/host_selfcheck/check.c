/* =============================================================================
 * check.c —— AdDemo 主机自检（**临时文件，不入仓库**；放在 %TEMP%\adcheck 下）
 * -----------------------------------------------------------------------------
 * 被测代码 = AdDemo.c 里 ==== NAME_BEGIN/END ==== 标记之间的源码段，由 extract 步骤
 * **原样**摘进 sections.h（不复制、不改写）⇒ "自检跑的就是板上跑的那份判据"。
 * 组：
 *   A 属性字编码（65536 组合编解码往返）      B 空 FIFO = 硬件默认字
 *   C 已知画法：属性字 vs 命令 8 字（真实下发路径）  D 扫描输出 LUT 表公式
 *   E 图集（3 种尺寸的圆盘 + 辉光）           F 场景边界（3 尺寸 x 4000 步）
 *   G 信息条最坏宽度                        H ★LUT 四步发布序列（两种极性）
 *   I ★信息条/HUD 永不被裁（计划规则 + 守卫 + 回读）  J ★宽条/精灵的逐条局部平移
 *   K ★ST_CLIP 等待的有界超时路径
 * ============================================================================= */
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
static void chk(const char *name, int ok)
{
    if (ok) g_pass++;
    else { g_fail++; printf("   FAIL: %s\n", name); }
}
static void sec(const char *s) { printf("\n== %s ==\n", s); }

/* ---------------- 板级宏（与 AdDemo.c / BSP 一致） ---------------- */
#define BSP_CLINT_HZ   100000000u          /* soc.h: SYSTEM_CLINT_HZ */
#define FB_WIDTH       960
#define FB_HEIGHT      540
#define FB_STRIDE      (FB_WIDTH * 2)
#define TOP_Y0         16
#define PLAY_H         (FB_HEIGHT - TOP_Y0)
#define OSD_H          16
#define OSD_GLYPH_W    8
#define OSD_GLYPH_H    8
#define OSD_TEXT_Y     4
#define OSD_TEXT_X0    8
#define OSD_LEFT_CH    72
#define OSD_LEFT_PX    (OSD_GLYPH_W * OSD_LEFT_CH)
#define OSD_RIGHT_PX   (OSD_GLYPH_W * 8)
#define OSD_LABEL      "HW ONLY"
#define PLAY_X0        200
#define PLAY_X1        760
#define PLAY_Y0        96
#define PLAY_Y1        472
#define SWEEP_T        6
#define HUD_X0         776
#define HUD_Y0         24
#define HUD_W          176
#define HUD_H          508
#define HUD_BARS       4
#define HUD_ITEMS      (1 + 4 + HUD_BARS)
#define KEY_COLOR      0xF81Fu
#define COL_WHITE      0xFFFFu
#define ATLAS_BASE     0x00201000UL
#define GLOW_BASE      0x00211000UL

#define BLT_ATTR_PORT       0x8C
#define BLT_CLIP_X0         0x90
#define BLT_CLIP_X1         0x94
#define BLT_CLIP_Y0         0x98
#define BLT_CLIP_Y1         0x9C
#define BLT_CLIP_CTRL       0xA0
#define   BLT_CLIP_EN       (1UL << 0)
#define BLT_LUT_ADDR        0xA4
#define BLT_LUT_DATA        0xA8
#define BLT_LUT_CTRL        0xAC
#define   BLT_LUT_EN        (1UL << 0)
#define   BLT_LUT_BANK      (1UL << 1)
#define BLT_LUT_STAT        0xB0
#define   BLT_LUT_STAT_BANK (1UL << 0)
#define BLT_CMD_FIFO_DATA   0x08
#define BLT_CMD_FIFO_COUNT  0x0C
#define BLT_STATUS          0x04
#define BLT_FB_STAT         0x28
#define BLT_OP_COPY         0UL
#define BLT_OP_FILL         1UL
#define BLT_OP_ALPHA        2UL
#define BLT_OP_KEY          3UL

#define ST_WAIT_MORE   0
#define ST_WAIT_IDLE   1
#define ST_WAIT_TIMEO  2
#define STW_RESTART    0
#define STW_FENCE      1
#define STW_CLIP       2
#define STW_CONTENT    3
#define STW_ROOM       4
#define LUT_PEND_TICKS (BSP_CLINT_HZ / 5u)
#define ST_WAIT_TICKS  (BSP_CLINT_HZ / 5u)

/* ---------------- 板上硬件的模型（只建自检要用的那几个寄存器） ---------------- */
static uint32_t m_reg[256];
static uint32_t m_now   = 0;              /* 模拟墙钟（tick32） */
static uint32_t m_frames = 0;             /* 场计数（FB_STAT[31:16]） */
static uint32_t m_frames_advance = 0;     /* 1 = 每次读 FB_STAT 就当过了一个帧边界 */
static int      m_lut_wrbank = 0;         /* 0xAC bit1 当前值：**写** bank */
static int      m_lut_lat    = 0;         /* 帧边界锁存的 bit1 */
static int      m_lut_en     = 0;
static int      m_show_bit1_direct = 0;   /* 0 = 显示 = ~bit1（权威）；1 = 显示 = bit1（老语义） */
static int      m_lut_addr   = 0;
static uint8_t  m_tbl[2][3][256];
static long     m_wr_cnt[2];              /* 每个 bank 被写了几项 */
static int      m_clip_mirror = 0;        /* 0xA0 回读值 */
static int      m_clip_stuck  = 0;        /* 1 = 写不进去（回读恒 1）= 寄存器坏 */
static uint32_t m_status      = 0xFFFFFFFFu; /* 引擎 STATUS（本自检不直接用） */

static void m_frame_boundary(void) { m_lut_lat = m_lut_wrbank; m_frames++; }
static int  m_disp_bank(void) { return m_show_bit1_direct ? m_lut_lat : (m_lut_lat ^ 1); }

/* ---------------- EMIT 自检用的写 trace ---------------- */
#define TRACE_MAX 256
static uint32_t m_tr_off[TRACE_MAX];
static uint32_t m_tr_val[TRACE_MAX];
static int      m_tr_n = 0;
static void m_tr(const uint32_t off, const uint32_t v)
{ if (m_tr_n < TRACE_MAX) { m_tr_off[m_tr_n] = off; m_tr_val[m_tr_n] = v; m_tr_n++; } }

static void blt_wr(uint32_t off, uint32_t v)
{
    m_tr(off, v);
    switch (off) {
    case BLT_LUT_CTRL: m_lut_en = (int)(v & 1u); m_lut_wrbank = (int)((v >> 1) & 1u); break;
    case BLT_LUT_ADDR: m_lut_addr = (int)v; break;
    case BLT_LUT_DATA: {
        int ch = (m_lut_addr >> 8) & 3, ix = m_lut_addr & 0xFF;
        if (ch < 3) { m_tbl[m_lut_wrbank][ch][ix] = (uint8_t)v; m_wr_cnt[m_lut_wrbank]++; }
        break; }
    case BLT_CLIP_CTRL: m_clip_mirror = m_clip_stuck ? 1 : (int)(v & 1u); break;
    case BLT_CMD_FIFO_DATA: break;
    case BLT_ATTR_PORT:     break;
    default: m_reg[off & 0xFFu] = v; break;
    }
}
static uint32_t blt_rd(uint32_t off)
{
    switch (off) {
    case BLT_LUT_STAT:  return (uint32_t)m_disp_bank();
    case BLT_LUT_CTRL:  return (uint32_t)((m_lut_wrbank << 1) | m_lut_en);
    case BLT_LUT_ADDR:  return (uint32_t)m_lut_addr;
    case BLT_LUT_DATA:  return (uint32_t)m_tbl[m_lut_wrbank][(m_lut_addr >> 8) & 3][m_lut_addr & 0xFF];
    case BLT_CLIP_CTRL: return (uint32_t)m_clip_mirror;
    case BLT_STATUS:    return m_status;
    case BLT_FB_STAT:   if (m_frames_advance) m_frame_boundary(); return (m_frames << 16);
    default:            return m_reg[off & 0xFFu];
    }
}
static uint32_t tick32(void) { m_now += 1000000u; return m_now; }   /* 每次调用 +10ms */
static int m_printf_n = 0;
static void bsp_printf(const char *fmt, ...)
{
    va_list ap;
    m_printf_n++;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

/* ---------------- 板级外部状态（AdDemo.c 里在标记段之外声明） ---------------- */
static int g_feat_lut  = 1;
static int g_feat_clip = 1;
static int g_scis_on   = 1;
static int g_clip_pass = 0;
static int g_blk       = 32;
#define SPR_W       g_blk
#define SPR_H       g_blk
#define SPR_STRIDE  (SPR_W * 2)
#define SPR_RING    (SPR_W / 8)
#define GLOW_VARIANTS   4
#define GLOW_VAR_STRIDE (SPR_H * SPR_STRIDE)
#define MAXPT 6000
typedef struct {
    int16_t x, y, vx, vy, tx, ty;
    uint8_t a, v;
} part_t;
static part_t g_pt[MAXPT];
static int    g_n    = 320;
static uint32_t g_anim = 0;

static const char *scene_name(int s)
{
    if (s == 1) return "FADE";
    if (s == 2) return "CLIP";
    if (s == 3) return "LAYER";
    if (s == 4) return "THRU";
    return "GLOW";
}

#include "sections.h"

/* =============================================================================
 * A) 属性字编码
 * ============================================================================= */
static void t_attr(void)
{
    int bad = 0, resv = 0, bad2 = 0;
    unsigned blend, fmt, ga, fl;
    char nm[64];
    sec("A) attr word encoding round-trip (blend x fmt x ga x flags)");
    for (blend = 0; blend < 16u; blend++)
    for (fmt = 0; fmt < 4u; fmt++) {
        bad = 0;
        for (ga = 0; ga < 256u; ga += 8u)
        for (fl = 0; fl < 4u; fl++) {
            uint32_t w = attr_word(blend, fmt, ga, fl);
            if (attr_blend(w) != blend || attr_fmt(w) != fmt ||
                attr_ga(w) != ga || attr_flags(w) != fl) bad++;
            if (w & 0x00FFC000u) resv++;
        }
        snprintf(nm, sizeof nm, "A%02d attr round-trip blend=%u fmt=%u (all ga x flags)",
                 (int)(blend * 4u + fmt), blend, fmt);
        chk(nm, bad == 0);
    }
    for (ga = 0; ga < 256u; ga++) {
        uint32_t w = attr_word(3u, 2u, ga, 3u);
        if (attr_ga(w) != ga) bad2++;
    }
    chk("A64 global_alpha: all 256 values survive the round-trip", bad2 == 0);
    chk("A65 reserved bits [15:14]/[23:16] always 0", resv == 0);
}

/* =============================================================================
 * B) FIFO 为空 = 硬件默认字
 * ============================================================================= */
static void t_default(void)
{
    uint32_t d = attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u);
    sec("B) empty FIFO = hardware default word");
    printf("   ATTR_DEFAULT = %x\n", (unsigned)ATTR_DEFAULT);
    chk("B1 ATTR_DEFAULT == attr_word(0,0,255,0) == 0x3FC0",
        d == 0x00003FC0u && d == (uint32_t)ATTR_DEFAULT);
}

/* =============================================================================
 * C) 已知画法：属性字 vs 命令 8 字（走真实的 blt_* 下发路径）
 * ============================================================================= */
static void t_emit(void)
{
    int i, k, bad = 0, attrs_on = 0, attrs_off = 0;
    static const uint32_t exp[9][8] = {
        { 1u, 0u, 0x00507990u, 0u, 0x00000780u, 0x020C03C0u, 0x000000FFu, 0x00000008u },
        { 0u, 0x00211000u, 0x00507990u, 0x00000780u, 0x00000780u, 0x020C03C0u, 0xFFu, 0u },
        { 3u, 0x00201000u, 0x00507990u, 0x00000010u, 0x00000780u, 0x00080008u, 0xFFu, 0x0000F81Fu },
        { 2u, 0x00201000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000C8u, 0u },
        { 2u, 0x00211000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000FFu, 0u },
        { 2u, 0x00201000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000FFu, 0u },
        { 2u, 0x00201000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000FFu, 0u },
        { 2u, 0x00201000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000FFu, 0u },
        { 2u, 0x00201000u, 0x00507990u, 0x00000040u, 0x00000780u, 0x00200020u, 0x000000C8u, 0u },
    };
    sec("C) known draws: attr word + 8 command words (real blt_* path)");
    g_attr_on = 0;
    m_tr_n = 0;
    blt_fill(0x00507990u, FB_STRIDE, FB_WIDTH, PLAY_H, 0x0008u);
    blt_copy(0x00211000u, 0x00507990u, FB_STRIDE, FB_STRIDE, FB_WIDTH, PLAY_H);
    blt_key(0x00201000u, 0x00507990u, 0x10u, FB_STRIDE, 8u, 8u, KEY_COLOR);
    blt_glow(0x00201000u, 0x00507990u, 200u);                    /* 属性关：RGB565 降级路径 */
    g_attr_on = 1;
    blt_glow(0x00211000u, 0x00507990u, 200u);                    /* 加算 4444 ga=200（带属性） */
    e_alpha(attr_word(ATTR_BLEND_ALPHA, ATTR_FMT_4444, 128u, 0u), 0x00201000u, 0x00507990u,
            SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, 0xFFu);
    e_alpha(attr_word(ATTR_BLEND_MUL, ATTR_FMT_1555, 64u, ATTR_FLAG_ATEST), 0x00201000u,
            0x00507990u, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, 0xFFu);
    e_alpha(attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, 255u, ATTR_FLAG_OPAQUE), 0x00201000u,
            0x00507990u, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, 0xFFu);
    g_attr_on = 0;
    blt_glow(0x00201000u, 0x00507990u, 200u);                    /* 每精灵 alpha 走 w6 */
    k = 0;
    {   int draw_bad[9];
        for (i = 0; i < 9; i++) draw_bad[i] = 0;
        for (i = 0; i < m_tr_n; ) {
            if (m_tr_off[i] == BLT_ATTR_PORT) {
                uint32_t wv = m_tr_val[i];
                attrs_on++;
                if (k != 4 && k != 5 && k != 6 && k != 7) bad++;  /* 只有带属性的 4 条写 */
                if (k == 4 && wv != attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, 200u, 0u)) bad++;
                if (k == 5 && wv != attr_word(ATTR_BLEND_ALPHA, ATTR_FMT_4444, 128u, 0u)) bad++;
                if (k == 6 && wv != attr_word(ATTR_BLEND_MUL, ATTR_FMT_1555, 64u, ATTR_FLAG_ATEST)) bad++;
                if (k == 7 && wv != attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, 255u, ATTR_FLAG_OPAQUE)) bad++;
                i++;
                continue;
            }
            if (m_tr_off[i] != BLT_CMD_FIFO_DATA) { bad++; draw_bad[k < 9 ? k : 8]++; i++; continue; }
            {   int j;
                for (j = 0; j < 8 && i + j < m_tr_n; j++)
                    if (m_tr_off[i + j] != BLT_CMD_FIFO_DATA || m_tr_val[i + j] != exp[k][j])
                        draw_bad[k < 9 ? k : 8]++;
            }
            i += 8;
            k++;
        }
        if (bad || k != 9) {
            int q;
            printf("   trace: n=%d k=%d bad=%d\n", m_tr_n, k, bad);
            for (q = 0; q < m_tr_n; q++) printf("     [%3d] off=%02X val=%08X\n", q, m_tr_off[q], m_tr_val[q]);
        }
        for (i = 0; i < 9; i++) {
            char nm[64];
            snprintf(nm, sizeof nm, "C1.%d draw #%d: 8 command words bit-exact", i + 1, i + 1);
            chk(nm, draw_bad[i] == 0);
        }
    }
    g_attr_on = 0;
    m_tr_n = 0;
    blt_fill(0x00507990u, FB_STRIDE, FB_WIDTH, PLAY_H, 0x0008u);
    for (i = 0; i < m_tr_n; i++) if (m_tr_off[i] == BLT_ATTR_PORT) attrs_off++;
    chk("C1 9 known draws: command words bit-exact", k == 9 && bad == 0);
    chk("C2 attr word precedes its command; exactly 1 per command (attr on)", attrs_on == 4);
    chk("C3 attr off -> zero ATTR_PORT writes (legacy path bit-identical)", attrs_off == 0);
}

/* =============================================================================
 * D) 扫描输出 LUT 表公式
 * ============================================================================= */
static void t_lut_tab(void)
{
    int i, bad_id = 0, bad_bk = 0, bad_wh = 0, bad_mono = 0;
    unsigned f;
    sec("D) scanout LUT table math (fade/flash)");
    for (i = 0; i < 256; i++) {
        if (lut_chan((unsigned)i, 255u, 0u) != (unsigned)i) bad_id++;
        if (lut_chan((unsigned)i, 0u, 0u) != 0u) bad_bk++;
        if (lut_chan((unsigned)i, 255u, 255u) != 255u) bad_wh++;
    }
    for (f = 0; f <= 255u; f++) {
        unsigned v, prev = lut_chan(0u, f, 0u);
        for (v = 1; v < 256u; v++) {
            unsigned cur = lut_chan(v, f, 0u);
            if (cur < prev) bad_mono++;
            prev = cur;
        }
    }
    printf("   identity bad=%d | fade=0 black bad=%d | flash=255 white bad=%d | mono bad=%d\n",
           bad_id, bad_bk, bad_wh, bad_mono);
    printf("   fade=128: v=0->%d v=64->%d v=128->%d v=255->%d | flash=128: v=0->%d v=255->%d\n",
           lut_chan(0u, 128u, 0u), lut_chan(64u, 128u, 0u), lut_chan(128u, 128u, 0u),
           lut_chan(255u, 128u, 0u), lut_chan(0u, 255u, 128u), lut_chan(255u, 255u, 128u));
    chk("D1 fade=255,flash=0 is identity", bad_id == 0);
    chk("D2 fade=0 all-black; flash=255 all-white", bad_bk == 0 && bad_wh == 0);
    chk("D3 monotonic non-decreasing over the whole fade grid", bad_mono == 0);
    chk("D4 LUT_ADDR channel field is 2 bits (blue = ch2 reachable)",
        lut_addr(2u, 0x55u) == 0x255u && lut_addr(0u, 0x55u) == 0x055u && lut_addr(1u, 0u) == 0x100u);
}

/* =============================================================================
 * E) 图集   F) 场景边界
 * ============================================================================= */
static const int blk_tab[3] = { 16, 32, 64 };

static void t_atlas(void)
{
    int s;
    sec("E) atlas: RGB565 disc + ARGB4444 glow (3 sizes)");
    for (s = 0; s < 3; s++) {
        int bad = 0, j, i;
        g_blk = blk_tab[s];
        for (j = 0; j < SPR_H && !bad; j++)
            for (i = 0; i < SPR_W; i++) {
                uint16_t c = disc_color(i, j);
                if (i == 0 && j == 0 && c != (uint16_t)KEY_COLOR) bad++;
                if (i == SPR_W / 2 && j == SPR_H / 2 && c == (uint16_t)KEY_COLOR) bad++;
            }
        chk("E1 disc: corner = key, centre != key", bad == 0);
        bad = 0;
        for (j = 0; j < SPR_H && !bad; j++)
            for (i = 0; i < SPR_W; i++) {
                uint16_t c = glow_color(i, j, 0);
                if (i == 0 && j == 0 && c != 0x0000u) bad++;      /* 圆外全透明 */
                if (i == SPR_W / 2 && j == SPR_H / 2 && argb4444_a(c) == 0u) bad++;
            }
        printf("   sz=%d: disc corner=%04X centre=%04X | glow corner=%04X centre=%04X a4=%d\n",
               SPR_W, disc_color(0, 0), disc_color(SPR_W / 2, SPR_H / 2),
               glow_color(0, 0, 0), glow_color(SPR_W / 2, SPR_H / 2, 0),
               argb4444_a(glow_color(SPR_W / 2, SPR_H / 2, 0)));
        chk("E2 glow: outside transparent, centre alpha > 0", bad == 0);
    }
    g_blk = 32;
}

/* ================= L) font atlas layout + fade/flash time base =================
 * Regression guard for the two on-board bugs of 2026-09-16:
 *  (1) FONT_STRIDE served as both the source row pitch (16 B) and the glyph
 *      pitch, while build_atlas() writes 8 rows per glyph => cell idx read
 *      row 0 of glyphs idx..idx+7 (the info bar looked like stacked dashes);
 *  (2) FADE_PERIOD_MS / FLASH_MS are milliseconds but were used as CLINT ticks
 *      (100 MHz) => 100000x too fast (no fade / white strobe). */
static void t_font_fx(void)
{
    static uint8_t atlas[8192];
    int v, j, i, bad = 0;

    sec("L) font atlas addressing + fade/flash time base");

    /* L1: what build_atlas() writes must be exactly what blt_key(base, FONT_ROW_BYTES)
     * reads back, for every glyph and every row. */
    if ((uint32_t)FONT_N * (uint32_t)FONT_GLYPH_BYTES > (uint32_t)sizeof(atlas)) {
        chk("L1a font atlas fits the simulated region", 0);
    } else {
        memset(atlas, 0xAA, sizeof(atlas));
        for (v = 0; v < FONT_N; v++)                       /* writer: build_atlas() */
            for (j = 0; j < 8; j++)
                for (i = 0; i < 8; i++) {
                    uint16_t px = (g_font[v].r[j] & (uint8_t)(0x80u >> i))
                                  ? (uint16_t)COL_WHITE : (uint16_t)KEY_COLOR;
                    uint32_t off = FONT_GLYPH_OFF(v) + (uint32_t)j * FONT_ROW_BYTES
                                   + (uint32_t)i * 2u;
                    atlas[off]     = (uint8_t)(px & 0xFFu);
                    atlas[off + 1] = (uint8_t)(px >> 8);
                }
        for (v = 0; v < FONT_N; v++)                       /* reader: blt_key */
            for (j = 0; j < 8; j++)
                for (i = 0; i < 8; i++) {
                    uint16_t want = (g_font[v].r[j] & (uint8_t)(0x80u >> i))
                                    ? (uint16_t)COL_WHITE : (uint16_t)KEY_COLOR;
                    uint32_t off = FONT_GLYPH_OFF(v) + (uint32_t)j * FONT_ROW_BYTES
                                   + (uint32_t)i * 2u;
                    uint16_t got = (uint16_t)(atlas[off] | ((uint16_t)atlas[off + 1] << 8));
                    if (got != want) bad++;
                }
        chk("L1b font: builder layout == emitter read-back (glyph x row)", bad == 0);
    }
    chk("L2 font: glyph pitch = 8 x source row pitch", FONT_GLYPH_BYTES == 8 * FONT_ROW_BYTES);
    chk("L3 font: FONT_N glyphs fit FONT_REGION_BYTES",
        (uint32_t)FONT_N * (uint32_t)FONT_GLYPH_BYTES <= (uint32_t)FONT_REGION_BYTES);
    printf("   font: %d glyphs, glyph=%dB row=%dB region=%luB needed=%luB\n",
           FONT_N, FONT_GLYPH_BYTES, FONT_ROW_BYTES,
           (unsigned long)FONT_REGION_BYTES,
           (unsigned long)((uint32_t)FONT_N * (uint32_t)FONT_GLYPH_BYTES));

    /* L4: the tick -> ms conversion is the only place a unit slip can happen;
     * dropping "/ MS_TICKS" makes L4b fail by 100000x. */
    chk("L4a one second of ticks is 1000 ms", fx_elapsed_ms(BSP_CLINT_HZ, 0u) == 1000u);
    chk("L4b 3.6 s of ticks is FADE_PERIOD_MS ms",
        fx_elapsed_ms((uint32_t)(FADE_PERIOD_MS * MS_TICKS), 0u) == FADE_PERIOD_MS);
    chk("L4c elapsed is wrap safe",
        fx_elapsed_ms((uint32_t)(3u * BSP_CLINT_HZ), (uint32_t)(1u * BSP_CLINT_HZ)) == 2000u);
    chk("L4d constants are milliseconds, not ticks",
        FADE_PERIOD_MS >= 1000u && FLASH_MS >= 100u);

    /* L5: fade ramp: full, monotone down to black, hold, monotone back up, wraps. */
    {
        unsigned prev = fx_fade_of_ms(0u), mono = 0, k;
        if (prev != 255u) bad++;
        bad = 0;
        for (k = 10u; k < 1200u; k += 10u) {
            unsigned cur = fx_fade_of_ms(k);
            if (cur > prev) mono++;
            prev = cur;
        }
        if (fx_fade_of_ms(1199u) > 1u) bad++;
        if (fx_fade_of_ms(1200u) != 0u || fx_fade_of_ms(1400u) != 0u) bad++;
        prev = 0u;
        for (k = 1500u; k < 2700u; k += 10u) {
            unsigned cur = fx_fade_of_ms(k);
            if (cur < prev) mono++;
            prev = cur;
        }
        if (fx_fade_of_ms(2700u) != 255u || fx_fade_of_ms(3590u) != 255u) bad++;
        if (fx_fade_of_ms(FADE_PERIOD_MS) != 255u) bad++;      /* wraps to the start */
        if (mono) bad++;
        chk("L5 fade: 255 -> black -> 255, monotone, wraps at 3.6 s", bad == 0);
        printf("   fade: 0ms=%u 600ms=%u 1200ms=%u 2000ms=%u 2700ms=%u 3600ms=%u\n",
               fx_fade_of_ms(0u), fx_fade_of_ms(600u), fx_fade_of_ms(1200u),
               fx_fade_of_ms(2000u), fx_fade_of_ms(2700u), fx_fade_of_ms(3600u));
    }
    /* L6: flash decay over 220 ms, clamped at the top. */
    bad = 0;
    if (fx_flash_of_ms(0u) != 0u) bad++;
    if (fx_flash_of_ms(FLASH_MS) != 255u) bad++;
    if (fx_flash_of_ms(FLASH_MS + 1000u) != 255u) bad++;
    if (fx_flash_of_ms(110u) != 127u) bad++;
    if (fx_flash_of_ms(220u) <= fx_flash_of_ms(110u)) bad++;
    chk("L6 flash: 255 at 220 ms, 127 at 110 ms, 0 at 0 ms", bad == 0);

    /* L7: how long the effects last in frames at 60 Hz (the on-board symptom was
     * "the whole fade over in 36 us" and "the flash over in 2.2 us"). */
    {
        unsigned fade_fr  = (unsigned)(FADE_PERIOD_MS / 1000u * 60u);
        unsigned flash_fr = (unsigned)((FLASH_MS * 60u) / 1000u);
        chk("L7a fade cycle is 60..600 frames", fade_fr >= 60u && fade_fr <= 600u);
        chk("L7b flash lasts 3..60 frames", flash_fr >= 3u && flash_fr <= 60u);
        printf("   duration: fade=%u frames (%.1fs), flash=%u frames, rearm=%us\n",
               fade_fr, (double)FADE_PERIOD_MS / 1000.0, flash_fr, FLASH_REARM_MS / 1000u);
    }
}

static void t_bounds(void)
{
    int s;
    sec("F) scene bounds: 3 sizes x 4000 steps");
    for (s = 0; s < 3; s++) {
        int step, bad0 = 0, bad1 = 0, i;
        g_blk = blk_tab[s];
        scene_init(512, 0x12345678u);
        for (i = 0; i < 512; i++) {
            if (g_pt[i].x < 0 || g_pt[i].x + SPR_W > FB_WIDTH) bad0++;
            if (g_pt[i].y < TOP_Y0 || g_pt[i].y + SPR_H > FB_HEIGHT) bad0++;
        }
        for (step = 0; step < 4000; step++) {
            scene_step(512);
            for (i = 0; i < 512; i++) {
                if (g_pt[i].x < 0 || g_pt[i].x + SPR_W > FB_WIDTH) bad1++;
                if (g_pt[i].y < TOP_Y0 || g_pt[i].y + SPR_H > FB_HEIGHT) bad1++;
            }
        }
        printf("   sz=%d: 512 particles x 4000 steps: initial out=%d in-step out=%d\n",
               SPR_W, bad0, bad1);
        chk("F1 initial bbox inside the render region", bad0 == 0);
        chk("F2 bbox stays inside for 4000 steps", bad1 == 0);
    }
    g_blk = 32;
}

/* =============================================================================
 * G) 信息条最坏宽度
 * ============================================================================= */
static void t_osd(void)
{
    char worst[OSD_LEFT_CH + 2];
    int len;
    sec("G) info bar worst-case width (real fmt_stat)");
    fmt_stat(worst, 99u, MAXPT, 3, 64, 255u, 9999u, 100u, 1, 1, 1, 1, 1);
    len = (int)strlen(worst);
    printf("   worst: \"%s\"\n   len=%d chars = %d px | text x=[%d,%d) label x=[%d,%d)\n",
           worst, len, len * OSD_GLYPH_W, OSD_TEXT_X0, OSD_TEXT_X0 + len * OSD_GLYPH_W,
           FB_WIDTH - OSD_RIGHT_PX, FB_WIDTH);
    chk("G1 worst-case text fits OSD_LEFT_CH", len <= OSD_LEFT_CH);
    chk("G2 text never reaches the right label region",
        OSD_TEXT_X0 + len * OSD_GLYPH_W <= FB_WIDTH - OSD_RIGHT_PX);
    chk("G3 strip covers the text and stays on-screen",
        OSD_TEXT_X0 >= 0 && OSD_TEXT_X0 + OSD_LEFT_PX <= FB_WIDTH);
    chk("G4 worst-case string built without overrunning the buffer", len > 0 && len < OSD_LEFT_CH + 2);
}

/* =============================================================================
 * H) ★ LUT 四步发布序列（两种极性）
 * ============================================================================= */
static void m_reset_lut(int show_bit1_direct)
{
    int b, c, i;
    m_lut_wrbank = 0; m_lut_lat = 0; m_lut_en = 0;      /* RTL 复位值：写 bank0、显示 bank1 */
    m_show_bit1_direct = show_bit1_direct;
    m_frames_advance = 1;                              /* 扫描输出在跑 */
    g_feat_lut = 1; g_lut_inv = 1; g_lut_cal = 0;
    g_lut_pend = -1; g_lut_pend_en = 0; g_lut_en = 0; g_lut_disp = 0;
    g_lut_f = 255u; g_lut_g = 0u; g_lut_stage_en = 0;
    for (b = 0; b < 2; b++) { m_wr_cnt[b] = 0; for (c = 0; c < 3; c++) for (i = 0; i < 256; i++) m_tbl[b][c][i] = 0xA5; }
}

static void t_lut_publish(void)
{
    int wr, disp0, disp_mid;
    long wr_disp_before;

    sec("H) LUT 4-step publish sequence (both polarities)");
    m_reset_lut(0);                                   /* 权威语义：显示 = ~bit1 */
    lut_bank_calib();
    chk("H1 live test decides display=~write (authoritative RTL)", g_lut_inv == 1 && g_lut_cal == 1);
    m_reset_lut(1);                                   /* 老语义：显示 = bit1 */
    lut_bank_calib();
    chk("H2 live test decides display=write (the old wording's polarity)", g_lut_inv == 0 && g_lut_cal == 1);

    /* ① 读 0xB0 → ② 写非显示 bank → ③ 写 3x256 → ④ 发布（帧边界生效） */
    m_reset_lut(0);
    lut_bank_calib();
    disp0 = m_disp_bank();
    m_wr_cnt[0] = 0; m_wr_cnt[1] = 0;
    lut_write_table(128u, 0u, 1);
    wr = m_lut_wrbank;                                /* 写口 = 0xAC bit1 的当前值 */
    wr_disp_before = m_wr_cnt[disp0];                 /* 写表期间碰过显示 bank 吗 */
    chk("H3 step2: write target is the NON-displayed bank (no tearing)",
        wr == (disp0 ^ 1) && wr_disp_before == 0);
    m_frame_boundary();
    disp_mid = m_disp_bank();
    lut_publish();                                    /* step4 */
    m_frame_boundary();
    chk("H4 display does not change while the table is being written", disp_mid == disp0);
    chk("H5 step4 publish: displayed bank == the bank written", m_disp_bank() == wr);
    chk("H6 LUT_STAT mirrors the written bank after publish",
        (int)(blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK) == wr);
    chk("H7 published bank holds the fade table just written",
        m_tbl[wr][0][64] == (uint8_t)lut_chan(64u, 128u, 0u) &&
        m_tbl[wr][2][255] == (uint8_t)lut_chan(255u, 128u, 0u));

    m_reset_lut(1);
    lut_bank_calib();
    lut_write_table(64u, 0u, 1);
    wr = m_lut_wrbank;
    lut_publish();
    m_frame_boundary();
    chk("H8 legacy polarity: displayed bank == bank written too", m_disp_bank() == wr);

    m_reset_lut(0);
    m_tbl[0][0][7] = 0xFF; m_tbl[1][0][7] = 0xFF;      /* 两个 bank 先塞满"全白" */
    lut_identity_safe_off();
    chk("H9 safe-off: LUT disabled (0xAC bit0 = 0)", (blt_rd(BLT_LUT_CTRL) & BLT_LUT_EN) == 0u);
    chk("H10 safe-off: BOTH banks hold the identity table",
        m_tbl[0][0][7] == (uint8_t)lut_chan(7u, 255u, 0u) &&
        m_tbl[1][0][7] == (uint8_t)lut_chan(7u, 255u, 0u) &&
        m_tbl[0][1][200] == (uint8_t)lut_chan(200u, 255u, 0u) &&
        m_tbl[1][1][200] == (uint8_t)lut_chan(200u, 255u, 0u));

    m_reset_lut(0);
    lut_bank_calib();
    m_tbl[m_disp_bank()][0][200] = 0xFF;               /* 假装屏上那张是上一次的白闪表 */
    lut_write_table(255u, 0u, 0);                      /* 场景不要 LUT ⇒ want_en = 0 */
    lut_publish();
    m_frame_boundary();
    chk("H11 scene that does not want the LUT: identity + en=0 (no stale white-out)",
        m_tbl[m_disp_bank()][0][200] == (uint8_t)lut_chan(200u, 255u, 0u) &&
        (blt_rd(BLT_LUT_CTRL) & BLT_LUT_EN) == 0u);

    {   unsigned a, b2, c, d;
        g_lut_inv = 1; a = lut_pub_bank(0u); b2 = lut_pub_bank(1u);
        g_lut_inv = 0; c = lut_pub_bank(0u); d = lut_pub_bank(1u);
        chk("H12 publish value = ~write-bank (authoritative) / write-bank (legacy)",
            a == 1u && b2 == 0u && c == 0u && d == 1u);
    }

    m_reset_lut(0);
    m_frames_advance = 0;                              /* 扫描输出没在跑 */
    m_printf_n = 0;
    lut_bank_calib();
    chk("H13 calib timeout keeps the display=~write default and warns",
        g_lut_inv == 1 && g_lut_cal == 0 && m_printf_n > 0);
    m_frames_advance = 1;
}

/* =============================================================================
 * I) ★ 信息条 / HUD 永不被裁
 * ============================================================================= */
static void t_never_clipped(void)
{
    irect_t r;
    iclip_t w;
    int bad = 0, k, len, out = 0;

    sec("I) info bar / HUD never clipped (plan rule + emit guard + readback)");
    osd_strip_rect(&r);
    if (clip_local(r.dx, r.dy, r.w, r.h, &w)) bad++;
    for (len = 1; len <= OSD_LEFT_CH; len++)
        for (k = 0; k < len; k++) {
            osd_glyph_rect(k, len, &r, 1);
            if (clip_local(r.dx, r.dy, r.w, r.h, &w)) bad++;
            if (!(r.dy + r.h <= CLIP_SY0 || r.dy >= CLIP_SY1 ||
                  r.dx + r.w <= CLIP_SX0 || r.dx >= CLIP_SX1)) out++;
        }
    chk("I1 info bar strip + every left glyph: zero intersection with the window", bad == 0);
    chk("I2 info bar rects are all outside the playfield window (screen coords)", out == 0);
    bad = 0;
    for (k = 0; k < (int)strlen(OSD_LABEL); k++) {
        osd_glyph_rect(k, (int)strlen(OSD_LABEL), &r, 0);
        if (clip_local(r.dx, r.dy, r.w, r.h, &w)) bad++;
    }
    chk("I3 right label (HW ONLY) glyphs: zero intersection", bad == 0);
    bad = 0;
    for (k = 0; k < HUD_ITEMS; k++) {
        hud_rect(k, &r);
        if (clip_local(r.dx, r.dy, r.w, r.h, &w)) bad++;
    }
    chk("I4 HUD items (base + 4 edges + bars): zero intersection", bad == 0);
    bad = 0;
    for (k = 0; k < 4; k++) {
        clip_edge_rect(k, &r);
        if (clip_local(r.dx, r.dy, r.w, r.h, &w)) bad++;
    }
    chk("I5 clip-edge borders sit outside the window (never clipped)", bad == 0);

    g_clip_on = 1; g_emit_cls = CLIP_CLS_DECOR; g_clip_viol = 0; g_clip_warn = 0; g_scis_on = 1;
    chk("I6 guard rejects a DECOR draw while the scissor is armed", clip_emit_guard() == 0);
    chk("I7 violation counted + scissor abandoned (bar can never be silently lost)",
        g_clip_viol == 1 && g_scis_on == 0);
    g_clip_on = 0; g_emit_cls = CLIP_CLS_DECOR;
    chk("I8 guard allows DECOR draws with the scissor off", clip_emit_guard() == 1);
    g_clip_on = 1; g_emit_cls = CLIP_CLS_FIELD;
    chk("I9 guard still allows playfield (FIELD) draws while armed", clip_emit_guard() == 1);
    g_clip_on = 0;

    g_feat_clip = 1; m_clip_stuck = 0; g_clip_on = 1;
    chk("I10 clip_off_verified: readback 0 => ok + mirror cleared",
        clip_off_verified() == 1 && g_clip_on == 0);
    m_clip_stuck = 1; g_scis_on = 1;
    chk("I11 clip_off_verified: stuck readback => scissor permanently disabled",
        clip_off_verified() == 0 && g_scis_on == 0);
    m_clip_stuck = 0;
}

/* =============================================================================
 * J) ★ 逐条局部平移（三种宽条 + 精灵的每种相对位置）
 * ============================================================================= */
static void t_xlate(void)
{
    irect_t r;
    iclip_t w;
    int hit;

    sec("J) per-draw local translation (wide strips + sprite positions)");
    g_n = 320;
    hit = clip_local(0, 0, FB_WIDTH, FB_HEIGHT, &w);
    chk("J1 full-screen rect: local window == screen window",
        hit == 1 && w.x0 == CLIP_SX0 && w.x1 == CLIP_SX1 && w.y0 == CLIP_SY0 && w.y1 == CLIP_SY1);

    g_sw_y = PLAY_Y0 + 100;                                   /* 横扫条：整屏宽 x 6 */
    content_rect(g_n, &r);
    hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
    chk("J2 horizontal sweep 960x6: local [200,760)x[0,6) keeps the full 6px height",
        hit == 1 && r.dx == 0 && r.w == FB_WIDTH &&
        w.x0 == PLAY_X0 && w.x1 == PLAY_X1 && w.y0 == 0 && w.y1 == SWEEP_T);

    g_sw_x = PLAY_X0 + 17;                                    /* 竖扫条：6 x 524 */
    content_rect(g_n + 1, &r);
    hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
    chk("J3 vertical sweep 6x524: local [0,6)x[96,472) keeps the whole strip",
        hit == 1 && r.w == SWEEP_T && w.x0 == 0 && w.x1 == SWEEP_T &&
        w.y0 == PLAY_Y0 && w.y1 == PLAY_Y1);

    {   int sz = SPR_W, okL, okR, okT, okB, skip = 0;
        g_pt[0].tx = (int16_t)(PLAY_X0 + 40); g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y0 + 40);
        content_rect(0, &r);
        hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
        chk("J4 sprite fully inside: local window == [0,SZ)x[0,SZ)",
            hit == 1 && w.x0 == 0 && w.y0 == 0 && w.x1 == sz && w.y1 == sz);

        g_pt[0].tx = (int16_t)(PLAY_X0 - 10);
        content_rect(0, &r); hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
        okL = (hit == 1 && w.x0 == 10 && w.x1 == sz && w.y0 == 0 && w.y1 == sz);
        chk("J5a sprite straddling the LEFT border: window = exact intersection", okL);
        g_pt[0].tx = (int16_t)(PLAY_X1 - 10);
        content_rect(0, &r); hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
        okR = (hit == 1 && w.x0 == 0 && w.x1 == 10 && w.y0 == 0 && w.y1 == sz);
        chk("J5b sprite straddling the RIGHT border: window = exact intersection", okR);
        g_pt[0].tx = (int16_t)(PLAY_X0 + 40); g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y0 - 10);
        content_rect(0, &r); hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
        okT = (hit == 1 && w.y0 == 10 && w.y1 == sz && w.x0 == 0 && w.x1 == sz);
        chk("J5c sprite straddling the TOP border: window = exact intersection", okT);
        g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y1 - 10);
        content_rect(0, &r); hit = clip_local(r.dx, r.dy, r.w, r.h, &w);
        okB = (hit == 1 && w.y0 == 0 && w.y1 == 10 && w.x0 == 0 && w.x1 == sz);
        chk("J5d sprite straddling the BOTTOM border: window = exact intersection", okB);

        g_pt[0].tx = (int16_t)(PLAY_X0 - 40); g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y0 + 40);
        content_rect(0, &r); if (!clip_local(r.dx, r.dy, r.w, r.h, &w)) skip++;
        g_pt[0].tx = (int16_t)(PLAY_X1 + 10);
        content_rect(0, &r); if (!clip_local(r.dx, r.dy, r.w, r.h, &w)) skip++;
        g_pt[0].tx = (int16_t)(PLAY_X0 + 40); g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y0 - 40);
        content_rect(0, &r); if (!clip_local(r.dx, r.dy, r.w, r.h, &w)) skip++;
        g_pt[0].ty = (int16_t)(TOP_Y0 + PLAY_Y1 + 5);
        content_rect(0, &r); if (!clip_local(r.dx, r.dy, r.w, r.h, &w)) skip++;
        chk("J6 sprite fully outside: command skipped (no fetch, no draw)", skip == 4);
    }

    hit = clip_local(0, TOP_Y0, FB_WIDTH, PLAY_H, &w);
    chk("J7 scene base 960x524 @y=16: local window == [200,760)x[96,472)",
        hit == 1 && w.x0 == PLAY_X0 && w.x1 == PLAY_X1 && w.y0 == PLAY_Y0 && w.y1 == PLAY_Y1);

    {   int i, bad = 0; unsigned s = 12345u;
        for (i = 0; i < 512; i++) {
            int dx, dy, x0, x1, y0, y1, sx0, sx1, sy0, sy1;
            s = s * 1664525u + 1013904223u; dx = (int)((s >> 8) % (unsigned)(FB_WIDTH - SPR_W));
            s = s * 1664525u + 1013904223u; dy = TOP_Y0 + (int)((s >> 8) % (unsigned)(PLAY_H - SPR_H));
            if (!clip_local(dx, dy, SPR_W, SPR_H, &w)) continue;
            x0 = w.x0 + dx; x1 = w.x1 + dx; y0 = w.y0 + dy; y1 = w.y1 + dy;
            sx0 = CLIP_SX0 > dx ? CLIP_SX0 : dx; sx1 = CLIP_SX1 < dx + SPR_W ? CLIP_SX1 : dx + SPR_W;
            sy0 = CLIP_SY0 > dy ? CLIP_SY0 : dy; sy1 = CLIP_SY1 < dy + SPR_H ? CLIP_SY1 : dy + SPR_H;
            if (x0 != sx0 || x1 != sx1 || y0 != sy0 || y1 != sy1) bad++;
            if (!(w.x0 >= 0 && w.y0 >= 0 && w.x1 <= SPR_W && w.y1 <= SPR_H && w.x0 < w.x1 && w.y0 < w.y1)) bad++;
        }
        chk("J8 local+origin == screen window intersect dst rect (512 random sprites)", bad == 0);
    }
}

/* =============================================================================
 * K) ★ ST_CLIP / 段机等待的有界超时路径
 * ============================================================================= */
static void t_timeout(void)
{
    int which = -1, i, r;
    uint32_t t0 = 0, ticks = (uint32_t)ST_WAIT_TICKS;

    sec("K) bounded wait / ST_CLIP timeout path");
    which = -1; t0 = 0;
    r = st_wait_state(STW_CLIP, 0, 100u, ticks, &which, &t0);
    chk("K1 busy engine: keeps waiting (no hang, no false timeout)", r == ST_WAIT_MORE);
    r = st_wait_state(STW_CLIP, 0, 100u + ticks, ticks, &which, &t0);
    chk("K2a exactly at the deadline: still waiting", r == ST_WAIT_MORE);
    r = st_wait_state(STW_CLIP, 0, 100u + ticks + 1u, ticks, &which, &t0);
    chk("K2b past the deadline: TIMEO (caller recovers: soft reset + reopen pass)", r == ST_WAIT_TIMEO);
    which = STW_CLIP; t0 = 7u;
    r = st_wait_state(STW_CLIP, 1, 999999u, ticks, &which, &t0);
    chk("K3 idle: ST_WAIT_IDLE and the timer is cleared", r == ST_WAIT_IDLE && which == -1);
    which = STW_RESTART; t0 = 0;
    r = st_wait_state(STW_CLIP, 0, 5u * ticks, ticks, &which, &t0);
    chk("K4 a different wait restarts the deadline", r == ST_WAIT_MORE && which == STW_CLIP && t0 == 5u * ticks);
    which = -1; t0 = 0; r = -1;
    for (i = 0; i < 100000000; i++) {
        r = st_wait_state(STW_CLIP, 0, (uint32_t)i, ticks, &which, &t0);
        if (r == ST_WAIT_TIMEO) break;
    }
    printf("   dead-engine model: recovery reached after %d ticks = %d ms = %d frames @60Hz\n",
           i, (int)(i / (BSP_CLINT_HZ / 1000u)), (int)(i / (BSP_CLINT_HZ / 60u)));
    chk("K5 dead engine: the recovery branch is reached in a bounded number of ticks", r == ST_WAIT_TIMEO);
    chk("K6 the bound is a few frames (>= 5 and <= 30 frames @60Hz)",
        i >= (int)(BSP_CLINT_HZ / 60u) * 5 && i <= (int)(BSP_CLINT_HZ / 60u) * 30);
    which = -1; t0 = 0;
    r = st_wait_state(STW_ROOM, 0, 0u, ticks, &which, &t0);
    chk("K7 the FIFO-room wait shares the same bounded rule",
        r == ST_WAIT_MORE && which == STW_ROOM &&
        st_wait_state(STW_ROOM, 0, ticks + 1u, ticks, &which, &t0) == ST_WAIT_TIMEO);
    chk("K8 LUT pending-publish bound is a few frames (5..15 @60Hz)",
        LUT_PEND_TICKS >= 5u * (BSP_CLINT_HZ / 60u) && LUT_PEND_TICKS <= 15u * (BSP_CLINT_HZ / 60u));

    /* K9/K10 进度判据：命令条数在变 ⇒ 把计时器往前推（长场景不许被误判成停机） */
    {   uint32_t last = 600u, t0b = 1000u;
        chk("K9 frozen FIFO count is NOT progress (timer keeps its deadline)",
            st_wait_progress(600u, &last, 5000u, &t0b) == 0 && t0b == 1000u && last == 600u);
        chk("K10 draining FIFO count IS progress (a slow pass is never mistaken for a stall)",
            st_wait_progress(320u, &last, 5000u, &t0b) == 1 && t0b == 5000u && last == 320u);
    }
}

int main(void)
{
    int p0;
    printf("===== AdDemo host self-check (sections extracted from AdDemo.c) =====\n");
    p0 = g_pass; t_attr();          printf("[A attr encoding          ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_default();       printf("[B default word           ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_emit();          printf("[C known draws / pairing  ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_lut_tab();       printf("[D LUT table math         ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_atlas();         printf("[E atlas                  ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_bounds();        printf("[F scene bounds           ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_osd();           printf("[G info bar width         ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_lut_publish();   printf("[H LUT 4-step publish     ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_never_clipped(); printf("[I bar/HUD never clipped  ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_xlate();         printf("[J per-draw translation   ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_timeout();       printf("[K ST_CLIP timeout path   ] %d checks\n", g_pass - p0);
    p0 = g_pass; t_font_fx();       printf("[L font layout + fx timing] %d checks\n", g_pass - p0);
    printf("\n===== AdDemo host self-check: %d passed / %d failed =====\n", g_pass, g_fail);
    return g_fail ? 1 : 0;
}
