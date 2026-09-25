////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2026 Efinix Inc. All rights reserved.
// Full license header bsp/efinix/EfxSapphireSocRV64/include/LICENSE.MD
////////////////////////////////////////////////////////////////////////////////

#ifndef SRC_USERDEF_H_
#define SRC_USERDEF_H_

#ifdef __cplusplus
extern "C" {
#endif

/* -----------------------------------------------------------------------------*/
/* User Configuration                         	        	
/* -----------------------------------------------------------------------------**/

/* -----------------------------------------------------------------------------*/
/*  USER DEBUG CONFIGURATION
/* -----------------------------------------------------------------------------*/
// --- DEBUG_MODE --- 
    // 0 = Asserts OFF, Logs removed
    // 1 = Asserts ON, Logs filtered
#define DEBUG_MODE 1
// --- ACTIVE_DEBUG_MOD --- This is the list of available module to debug
    // DBG_MOD_SYS          // Enable Log for RISCV Extension
    // DBG_MOD_IRQ          // Enable Log for IRQ, mtrap
    // DBG_MOD_FAULT        // Enable Log for System Fault  
    // DBG_MOD_UART         // Enable Log for UART Driver
    // DBG_MOD_I2C          // Enable Log for I2C Driver   
    // DBG_MOD_SPI          // Enable Log for SPI Driver
    // DBG_MOD_SPI_FLASH    // Enable Log for SPI FLASH Driver
    // DBG_MOD_RTC          // Enable Log for RTC Driver
    // DBG_MOD_CAM          // Enable Log for CAM Driver
    // DBG_MOD_SENSOR       // Enable Log for Sensor (temp sensor)
    // DBG_MOD_MAIN         // Enable Log for main.c
    // DBG_MOD_ALL          // Enable all Logs
#define ACTIVE_DEBUG_MOD   DBG_MOD_ALL

// --- ACTIVE_MIN_LVL ---
    // DBG_LVL_ALL     0   // Show Info, Warn, Error
    // DBG_LVL_WARN    1   // Show Warn, Error
    // DBG_LVL_ERR     2   // Show Error only
    // DBG_LVL_NONE    3   // Silence
#define ACTIVE_MIN_LVL   DBG_LVL_WARN

/* =========================================================================
 * 2DRA fulltest —— 地址布局 / BitBlt 引擎寄存器 / 画面参数
 * -------------------------------------------------------------------------
 * 全部数值已与硬件对齐（soc.h + rtl/blt_regs_axi_lite.v + rtl/video/fb_scanout.v）：
 *   - DDR 在 CPU 视角的基址 = SYSTEM_DDR_BMB = 0x00001000
 *   - 布局：程序区 1MB → 精灵/图集 2MB → FB0 +0x300000 → FB1 +0x400000 → 空闲
 *   - HDMI 扫描输出（fb_scanout）读的就是 FB0（FB_BASE）这块物理内存，
 *     所以往 FB_BASE 写（CPU 或 BitBlt 引擎）都能在 HDMI 上看到
 *   - BitBlt 引擎寄存器窗口挂在 APB slave 0（soc.h: IO_APB_SLAVE_0_INPUT
 *     = 0xf8100000，窗口 64KB），CPU 用 volatile 32bit 读写即可
 * 注意：地址宏与端口宏禁止改动（改了就对不上硬件）。
 * ========================================================================= */

/* ---------------- DDR 地址布局（字节地址，CPU 视角） ---------------- */
#define DDR_BASE      0x00001000UL                    /* SYSTEM_DDR_BMB */
#define FB_BASE       (DDR_BASE + 0x00300000UL)       /* 0x00301000 帧缓冲0：HDMI 扫描输出显示的就是它 */
#define FB1_BASE      (DDR_BASE + 0x00400000UL)       /* 0x00401000 备用帧缓冲（自检用，不上屏） */
#define SPRITE_BASE   (DDR_BASE + 0x00100000UL)       /* 0x00101000 精灵/图案区 */
#define FLUSH_SCRATCH (DDR_BASE + 0x00500000UL)       /* 0x00501000 缓存冲刷缓冲 */

/* ---------------- 画面规格：960×540 RGB565 ---------------- */
#define FB_WIDTH   960
#define FB_HEIGHT  540
#define FB_BPP     2
#define FB_STRIDE  (FB_WIDTH * FB_BPP)                /* 行距 = 1920 字节/行 */
#define FB_BYTES   (FB_STRIDE * FB_HEIGHT)            /* 1,036,800 字节 */
#define FB_WORDS   (FB_BYTES / 4)                     /* 259,200 个 32bit 字 */

/* 缓存冲刷缓冲长度：写 8KB ≫ 4KB D$，足以把 D$ 里的脏行全挤到 DDR */
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)

/* ---------------- BitBlt 加速器寄存器（APB slave 0） ---------------- */
#define BLT_BASE   0xF8100000UL                       /* CPU 视角基址 */

#define BLT_CTRL            0x00   /* RW: bit0=GO(自动消费指令FIFO) bit1=IRQ_EN bit2=SOFT_RST */
#define   BLT_CTRL_GO       (1UL << 0)
#define   BLT_CTRL_IRQ_EN   (1UL << 1)
#define   BLT_CTRL_SOFT_RST (1UL << 2)

#define BLT_STATUS          0x04   /* R : bit0=BUSY bit1=DONE(电平) bit2=ERR bit3=FIFO_EMPTY */
#define   BLT_STATUS_BUSY       (1UL << 0)
#define   BLT_STATUS_DONE       (1UL << 1)
#define   BLT_STATUS_ERR        (1UL << 2)
#define   BLT_STATUS_FIFO_EMPTY (1UL << 3)

#define BLT_CMD_FIFO_DATA   0x08   /* W : 写指令字；连写 8 个字 = 一条指令 */
#define BLT_CMD_FIFO_COUNT  0x0C   /* R : 已排队的完整指令条数（FIFO 深度 256 条） */
#define BLT_IRQ_STATUS      0x10   /* W1C: bit0=DONE */
#define BLT_IRQ_EN          0x14   /* RW: bit0 */
#define BLT_DBG_CUR_CMD     0x18   /* R : 当前/最近指令 word0 */
#define BLT_PERF            0x1C   /* R : 上一条指令的引擎周期数（性能统计用） */

#define BLT_CMD_FIFO_DEPTH  256    /* 指令条数深度（RTL cmd_fifo） */
#define BLT_CMD_WORDS       8      /* 一条指令 = 8 个 32bit 字 */

/* ---------------- 指令字布局（word0..word7） ----------------
 * word0 = op
 * word1 = src_addr   (字节地址；FILL 忽略)
 * word2 = dst_addr   (字节地址)
 * word3 = src_stride (源行距，字节；FILL 忽略)
 * word4 = dst_stride (目的行距，字节)
 * word5 = (height<<16) | width   (单位：像素)
 * word6 = alpha      (0~255，仅 ALPHA 用；其余填 255)
 * word7 = color      (FILL=填充色；KEY=键色；其余填 0)
 * ---------------------------------------------------------- */
#define BLT_OP_COPY   0UL   /* 逐像素拷贝 */
#define BLT_OP_FILL   1UL   /* 用 color 填充矩形 */
#define BLT_OP_ALPHA  2UL   /* out = fg*alpha + bg*(255-alpha)，再 >>8（会读目的缓冲区） */
#define BLT_OP_KEY    3UL   /* 源像素 == color(键色) 时跳过不写（保留目的原有内容） */

/* ---------------- RGB565 常用颜色 ---------------- */
#define C_BLACK    0x0000
#define C_WHITE    0xFFFF
#define C_RED      0xF800
#define C_GREEN    0x07E0
#define C_BLUE     0x001F
#define C_YELLOW   0xFFE0
#define C_MAGENTA  0xF81F   /* 也叫 C_KEY：键色/透明色 */
#define C_CYAN     0x07FF
#define C_ORANGE   0xFD20
#define C_DBLUE    0x0010   /* 深蓝：帧缓冲演示背景 */
#define KEY_COLOR  0xF81F   /* 色彩键控键色（与 blt_regs.h / 硬件一致） */

#ifdef __cplusplus
}
#endif // C_plusplus

#endif /* SRC_USERDEF_H_ */
