#ifndef USERDEF_H
#define USERDEF_H

/* =========================================================================
 * 2DRA 帧缓冲地址与画面参数
 * -------------------------------------------------------------------------
 * 地址以仓库开发文档为准（《DDR3内存分配分析.md》《板级集成接线清单.md》）：
 *   DDR 在 CPU 视角的基址 = soc.h 中 SYSTEM_DDR_BMB = 0x00001000
 *   布局：程序区 1MB → 精灵/图集 2MB → FB0 +0x300000 → FB1 +0x400000 → 空闲
 *   HDMI 扫描输出（rtl/video/fb_scanout.v）读取的正是同一物理地址，
 *   所以这里的数值必须与硬件参数 FB_BASE 一致（当前 0x00301000）。
 *
 * 注意：旧版 fbTest.c 用的 0x01000000 不在文档布局内，已按文档修正。
 * ========================================================================= */

#define DDR_BASE      0x00001000UL                    /* SYSTEM_DDR_BMB */

#define FB_BASE       (DDR_BASE + 0x00300000UL)       /* 0x00301000 帧缓冲0（HDMI 输出）*/
#define FB1_BASE      (DDR_BASE + 0x00400000UL)       /* 0x00401000 帧缓冲1（备用/双缓冲）*/

/* 冲刷缓冲：把 D$ 中的脏行挤到 DDR（写 8KB ≫ 4KB D$） */
#define FLUSH_SCRATCH (DDR_BASE + 0x00500000UL)
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)

/* 画面规格：960×540 RGB565 —— 与 rtl/video/fb_scanout.v、software/blt_regs.h 一致 */
#define FB_WIDTH   960
#define FB_HEIGHT  540
#define FB_BPP     2
#define FB_STRIDE  (FB_WIDTH * FB_BPP)                /* 1920 B/行 */
#define FB_BYTES   (FB_STRIDE * FB_HEIGHT)            /* 1,036,800 B */
#define FB_WORDS   (FB_BYTES / 4)                     /* 259,200 个 32bit 字 */

/* 每帧软件延时（空循环次数，按手感调节；越大越慢） */
#define FRAME_DELAY_LOOPS  180000UL

/* ===== RGB565 常用颜色（扫描输出会把它扩展成 RGB888 送 HDMI） ===== */
#define C_BLACK    0x0000
#define C_WHITE    0xFFFF
#define C_RED      0xF800
#define C_GREEN    0x07E0
#define C_BLUE     0x001F
#define C_YELLOW   0xFFE0
#define C_MAGENTA  0xF81F
#define C_CYAN     0x07FF
#define C_ORANGE   0xFD20
#define C_DBLUE    0x0010

#endif /* USERDEF_H */
