# 软件应用层（standalone software application layer）调研笔记

- 调研对象根目录：
  `C:\2D_Rendering_Acceleration-deprecated-v3.2\2D_Rendering_Acceleration-deprecated-v3.2\ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\`
- 本文只读、未改动任何源文件（仅新增本笔记）。
- 结论口径：以 `FinalDemo/src/FinalDemo.c`（2840 行 / 187,334 字节，LF 换行，UTF-8）为**最完整 demo**，逐行读完（行号引用均指该文件）。

---

## 0. 重要更正：目录归属关系

任务描述里假设 `FinalDemo / AdDemo / comptest / fulltest / FBtest` 位于 `application/` 下。**实际不是**：

```
.../standalone/
├── application/            <-- 厂商原厂 demo（4 个）：coremark, dhrystone, fbTest, memTest
├── FinalDemo/              <-- 2D 加速器 demo（与 application/ 平级）
├── AdDemo/
├── comptest/
├── comptest2/
├── FBtest/
├── fulltest/
├── driver/                 <-- 共享驱动/BSP 头（不是 bsp/ 里的）
├── common/                 <-- 共享构建片段 + start.S + syscalls.c
├── apb3/ axi4/ bootloader/ customInstruction/ fpu/ gpio/ i2c/ smp/ spi/ timer/ uart/ vexriscv/
```

`bsp/`（含 `bsp.h`、`soc.h`）不在 `standalone/` 下，而在
`.../embedded_sw/soc/bsp/efinix/EfxSapphireSoc/`。

---

## 1. `application/` 目录：全部 demo 与源文件尺寸

### 1.1 `application/coremark/`

| 文件 | 字节 |
|---|---|
| `makefile` | 389 |
| `src/coremark.h` | 4,759 |
| `src/core_list_join.c` | 18,229 |
| `src/core_main.c` | 15,970 |
| `src/core_matrix.c` | 9,606 |
| `src/core_portme.c` | 4,799 |
| `src/core_portme.h` | 5,819 |
| `src/core_state.c` | 9,717 |
| `src/core_util.c` | 6,018 |
| `src/cvt.c` | 2,770 |
| `src/ee_printf.c` | 16,089 |
| `src/LICENSE.md` | 18,582 |

makefile 关键项：`PROJ_NAME=coremark`、`STANDALONE=../..`、`CFLAGS+=-DSMP`、`DEBUG=no`、`BENCH=yes`、`CFLAGS += -DITERATIONS=2000`。

### 1.2 `application/dhrystone/`

| 文件 | 字节 |
|---|---|
| `makefile` | 521 |
| `src/dhrystone.c` | 4,817 |
| `src/dhrystone.h` | 19,595 |
| `src/dhrystone_main.c` | 11,087 |
| `src/stdlib.c` | 2,570 |

makefile 关键项：`PROJ_NAME=dhrystone`、`STANDALONE=../..`、`-DSMP`、`DEBUG=no`、`BENCH=yes`、`-fno-inline -fno-common`、`-DTIME -DCORE_HZ=12000000ll`。

### 1.3 `application/fbTest/`（**纯 CPU 写 DDR 帧缓冲 + HDMI 扫描输出的软件 demo，不碰加速器**）

| 文件 | 字节 |
|---|---|
| `.cproject` | 9,445 |
| `.project` | 1,495 |
| `fbTest_ti.launch` | 6,257 |
| `fbTest_trion.launch` | 6,251 |
| `fbTest_tz.launch` | 6,257 |
| `makefile` | 342 |
| `.settings/org.eclipse.core.resources.prefs` | 55 |
| `src/fbTest.c` | 14,543 |
| `src/userDef.h` | 2,190 |
| `build/fbTest.elf` | 75,476 |
| `build/fbTest.hex` | 13,320 |
| `build/fbTest.bin` | 4,826 |
| `build/fbTest.asm` | 62,836 |
| `build/fbTest.map` | 60,854 |
| `build/obj_files/fbTest.o` | 196,148 |
| `build/obj_files/start.o` | 5,492 |
| `build/obj_files/syscalls.o` | 108,372 |

`src/userDef.h` 提供的地址宏（与 `FBtest/` 的同名头**逐字节相同**）：

```c
#define DDR_BASE      0x00001000UL                    /* SYSTEM_DDR_BMB */
#define FB_BASE       (DDR_BASE + 0x00300000UL)       /* 0x00301000 */
#define FB1_BASE      (DDR_BASE + 0x00400000UL)       /* 0x00401000 */
#define FLUSH_SCRATCH (DDR_BASE + 0x00500000UL)
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)
#define FB_WIDTH   960
#define FB_HEIGHT  540
#define FB_BPP     2
#define FB_STRIDE  (FB_WIDTH * FB_BPP)                /* 1920 B/行 */
#define FB_BYTES   (FB_STRIDE * FB_HEIGHT)            /* 1,036,800 B */
#define FRAME_DELAY_LOOPS  180000UL
```
颜色宏：`C_BLACK 0x0000 / C_WHITE 0xFFFF / C_RED 0xF800 / C_GREEN 0x07E0 / C_BLUE 0x001F / C_YELLOW 0xFFE0 / C_MAGENTA 0xF81F / C_CYAN 0x07FF / C_ORANGE 0xFD20`。

`fbTest.c`（v3/v4）要点：`tick()` 用 `clint_getTime(BSP_CLINT)`（**不用 `csr_read(mcycle)`** —— 该 SoC 上读未实现 CSR 会触发非法指令异常直接死机）；`#define FRAME_TICKS (TICK_HZ/60)` 按固定周期节流；每帧末尾 `cache_evict()` + `data_cache_invalidate_all()`；`#include "vexriscv.h"`。

### 1.4 `application/memTest/`

| 文件 | 字节 |
|---|---|
| `makefile` | 343 |
| `src/main.c` | 1,579 |
| `src/userDef.h` | 424 |

```c
#define MEM_LOC   ((volatile uint32_t*)0x00010000)
#define MAX_WORDS (4 * 1024 * 1024)
```
`main.c` 写 `MEM_LOC[i]=i` 再回读比对，失败打印 `Data mismatched at address 0x%x with value of 0x%x` 并死循环。

### 1.5 `application/` 之外的 2D 加速器 demo（真正的应用层主体）

| 目录 | 主源文件 | 字节 | 行数 | 其他源文件 |
|---|---|---|---|---|
| `FinalDemo/` | `src/FinalDemo.c` | 187,334 | 2,840 | `src/userDef.h` 2,054；`makefile` 326 |
| `AdDemo/` | `src/AdDemo.c` | 134,308 | 2,108 | `src/userDef.h` 2,054；`makefile` 323 |
| `comptest2/` | `src/comptest2.c` | 46,469 | 849 | `src/userDef.h` 2,054；`makefile` 326 |
| `comptest/` | `src/comptest.c` | 37,511 | 700 | `src/userDef.h` 2,054；`makefile` 325 |
| `fulltest/` | `src/fulltest.c` | 120,763 | 2,165 | `src/userDef.h` **6,734**（这个头里有寄存器表）；`makefile` 325 |
| `FBtest/` | `src/FBtest.c` | 6,281 | 153 | `src/userDef.h` 2,190；`makefile` 323 |

各工程还有：`.cproject`（9070~9287）、`.project`（1495~1498）、3 个 `.launch`（6251~6485）、`.settings/org.eclipse.core.resources.prefs`（55）、`build/{name}.{elf,hex,bin,asm,map}` 与 `build/obj_files/{name}.o, start.o, syscalls.o`。

已构建产物一览（`build/`）：

| 工程 | .elf | .hex | .bin | .asm | .map | <name>.o | start.o | syscalls.o |
|---|---|---|---|---|---|---|---|---|
| FinalDemo | 169,728 | 74,100 | 26,930 | 326,982 | 79,176 | 562,192 | 4,112 | 108,296 |
| AdDemo | 179,028 | 73,660 | 26,770 | 317,353 | 83,979 | 607,020 | 4,108 | 108,292 |
| comptest2 | 122,260 | 34,456 | 12,514 | 154,059 | 69,164 | 365,544 | 4,112 | 108,296 |
| comptest | 105,348 | 27,388 | 9,946 | 127,705 | 68,553 | 277,176 | 4,108 | 108,296 |
| fulltest | 173,364 | 95,044 | 34,546 | 360,606 | 73,522 | 589,972 | 4,108 | 108,296 |
| FBtest | 66,628 | 8,100 | 2,930 | 38,310 | 60,310 | 158,204 | 4,108 | 108,292 |

各 demo 定位（读源码头部注释得到）：

- **FinalDemo**：HW 加速 vs 纯 CPU 同屏实时对比。上下半屏各 260 行，默认纯硬件整屏；三缓冲 FLIP + 并发清屏引擎 + 帧边界中断节拍 + 显示列表路径（全部可开关）。
- **AdDemo**：**纯硬件渲染**，**一个 CPU 像素都没有**（连信息条 8x8 字都是 KEY 精灵由引擎画）。五个场景（1 GLOW 加算混合 / 2 FADE LUT 淡入淡出 / 3 CLIP scissor 裁剪 / 4 LAYER 分层 / 5 THRU 吞吐压测）。额外用到 **ATTR_PORT(0x8C)**、**CLIP_X0/X1/Y0/Y1(0x90/0x94/0x98/0x9C) + CLIP_CTRL(0xA0)**、**LUT_ADDR/DATA/CTRL/STAT(0xA4/0xA8/0xAC/0xB0)** 三组 v3.2/S5 新寄存器，并做 `feat_probe` 能力探测 + 自动退回。
- **comptest**：早期「纯 CPU 软件渲染 vs 硬件 BitBlt」对比。CPU 侧写屏外缓冲 FB1/FB2 双缓冲，引擎整屏 COPY 上屏；OSD 也画在屏外缓冲。只有 GPIO 按键 + 串口 `m/n/+/-/r`。
- **comptest2**：comptest 的改进版（单缓冲直接显示、上下半屏同场景同种子、每侧各自 dx/dy 记账），是 FinalDemo 的直接前身。
- **fulltest**：BitBlt 引擎**裸机端到端功能/压力测试**。`src/userDef.h` 内含完整寄存器表与操作码宏（见 §3.4）。8 个测试段 `[1]`~`[8]`，17 项功能测试 + 多精灵压测。
- **FBtest**：HDMI 扫描输出 + 缓存一致性自检 demo（`coherency_check()` 用 FB1 写 256 字 → `cache_evict()` → `data_cache_invalidate_all()` → 回读比对）。**不使用加速器**。

---

## 2. FinalDemo 如何初始化 2D 加速器驱动

### 2.1 头文件包含链

```c
#include <stdint.h>
#include "bsp.h"
#include "compatibility.h"      /* SYSTEM_GPIO_A_APB → SYSTEM_GPIO_0_IO_CTRL 的映射 */
```

`bsp.h` 实际位于
`.../embedded_sw/soc/bsp/efinix/EfxSapphireSoc/include/bsp.h`，其内部：

```c
#pragma once
#include "soc.h"
#include "uart.h"
#include "clint.h"
#include "semihosting.h"
...
#define BSP_PLIC            SYSTEM_PLIC_CTRL
#define BSP_UART_BAUDRATE   115200
#define BSP_UART_DATA_LEN   8
#define BSP_CLINT           SYSTEM_CLINT_CTRL
#define BSP_CLINT_HZ        SYSTEM_CLINT_HZ
#define bsp_uDelay(usec)    clint_uDelay(usec, SYSTEM_CLINT_HZ, SYSTEM_CLINT_CTRL);
#define BSP_UART_TERMINAL   SYSTEM_UART_0_IO_CTRL
#define bsp_putChar(c)      uart_write(BSP_UART_TERMINAL, c);
#define bsp_getChar()       uart_read(BSP_UART_TERMINAL)
#define ENABLE_BSP_PRINTF   1
static void bsp_init() { Uart_Config uartConfig; ...
    uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    uart_applyConfig(BSP_UART_TERMINAL, &uartConfig); }
```

包含路径（编译期由 makefile 拼出，`makefile` 的 `-I` 列表见 §8）：
`-I<BSP_PATH>/include`、`-I<BSP_PATH>/app`、`-I${STANDALONE}/include`、`-I${STANDALONE}/driver`。
构建日志（`doc/logs/build_v216_64x64.txt`）实证解析到
`../../../bsp/efinix/EfxSapphireSoc/include/...` 与 `../driver/{clint.h,uart.h}`。

### 2.2 初始化序列（`main()` 内）

```c
bsp_init();                      /* 必须最先调用：UART 时钟分频在这里配置 */
bsp_printf("\r\n===== FinalDemo: HW accel vs pure CPU, same screen =====\r\n");
...
blt_init();                      /* 加速器软复位 + 使能 */
g_disp_sel = fb_stat_sel();      /* 与实际在屏缓冲对齐（FB_STAT[1:0]） */
build_atlas();                   /* 精灵图集（开机按 BLK_LO=16 建） */
spr_mask_report();
cpu_fill32(g_fb_back, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
cache_evict();
/* 未对齐写入自检 + selfcheck 打印 STATUS/COUNT/SCAN/FB/DL */
scene_init(n, g_seed, 0);
cache_evict();
osd_build(...); osd_blit(...);
```

驱动寄存器读写只用了两个局部 helper（**没有独立 driver 文件，寄存器映射全部内联在 demo .c 里**）：

```c
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
```

`blt_init()`：

```c
static void blt_init(void)
{
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);   /* bit2 = 1 拍软复位脉冲 */
    blt_wr(BLT_IRQ_STATUS, 1u);            /* W1C */
    blt_wr(BLT_IRQ_EN, 0u);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);         /* bit0 = GO：开始自动消费指令 FIFO */
}
```

其他驱动 helper：`fb_of_sel()`、`fb_stat_sel()`、`blt_stat()`、`blt_cnt()`、`blt_idle_st()`、`blt_push_room()`、`clr_stat()/clr_busy()/clr_is_clean()/clr_wait_idle()/clr_start()/hw_pass_arm()`、`cache_evict()`。
`fulltest` 里的同型 helper 名为 `blt_wr(off,val)` / `blt_rd(off)`（参数顺序一致），AdDemo/comptest/comptest2 与 FinalDemo 逐字相同。

---

## 3. 精确寄存器接口（宏名 + 地址 + 位域）

### 3.1 基址

```c
#define BLT_BASE      0xF8100000UL
```
对应 BSP `soc.h` 的 `#define IO_APB_SLAVE_0_INPUT 0xf8100000`（`IO_APB_SLAVE_0_INPUT_SIZE 0x10000`）。
RTL 侧地址译码用 `case (ra[8:2])`（`rtl/blt_regs_axi_lite.v:759`），即 **基址 + 4×字偏移**，与下表一致。

### 3.2 控制 / 状态 / 指令 FIFO（FinalDemo.c:89-101）

```c
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
```

RTL 交叉验证（`rtl/blt_regs_axi_lite.v:760-767`）：
- `0x00` CTRL 读回 `{30'd0, irq_en, ctrl_go}` → bit0=GO、bit1=IRQ_EN
- `0x04` STATUS 读回 `{28'd0, fifo_empty, eng_err, eng_done, eng_busy}` → bit0=BUSY、bit1=DONE、bit2=ERR、bit3=FIFO_EMPTY
- `0x0C` CMD_FIFO_COUNT 读回 `{23'd0, fifo_cmd_count}`（**单位=指令条数 = 字数/8**，`rtl/cmd_fifo.v`；FIFO 共 256 条 = 2048 字）
- `0x14` IRQ_EN 写 `wd[0]=irq_en, wd[1]=irq_en_f, wd[2]=dl_irq_en`
- `0x20` SCAN_DBG（`fulltest` 用；`scan_abort, scan_underrun`）
- `fulltest/src/userDef.h` 额外给出：`BLT_CTRL_IRQ_EN (1UL<<1)`、`BLT_PERF`、`BLT_DBG_CUR_CMD`。

### 3.3 ★v2.6/v2.7 上屏与清屏引擎（FinalDemo.c:102-131）

```c
#define   BLT_IRQ_FRAME     (1UL << 1)     /* 扫描输出帧边界中断（0x10 W1C / 0x14 使能） */
#define BLT_FB_SEL          0x24
#define BLT_FB_STAT         0x28
#define   BLT_FB_STAT_SEL   (1UL << 0)
#define BLT_CLR_ADDR        0x2C
#define BLT_CLR_STRIDE      0x30
#define BLT_CLR_WH          0x34
#define BLT_CLR_COLOR       0x38
#define BLT_CLR_CTRL        0x3C
#define   BLT_CLR_GO        (1UL << 0)
#define   BLT_CLR_ERRCLR    (1UL << 4)
#define BLT_CLR_STAT        0x40
#define   BLT_CLR_STAT_BUSY (1UL << 0)
#define   BLT_CLR_STAT_ERR  (1UL << 6)
#define BLT_DRAW_SEL        0x44
#define BLT_CLR_CYC         0x48
#define FB_SEL_STAT_SEL(v)  ((uint32_t)(v) & 3UL)  /* 选择字段 2 bit */
```

位域（源码注释 + RTL 一致）：
- `FB_SEL (0x24, W)`：`[1:0]` 希望扫描输出显示哪块缓冲（0=FB_BASE / 1=FB_BACK / 2=FB_BUF2）。写下去只是**请求**，扫描输出在下一个帧边界锁存。
- `FB_STAT (0x28, R)`：`[1:0]` = **已经生效**的选择；`[31:16]` = 扫描输出场计数。
- `CLR_ADDR 0x2C` 清屏起始字节地址；`CLR_STRIDE 0x30` 字节/行；`CLR_WH 0x34 = (h<<16)|w`；`CLR_COLOR 0x38` RGB565 背景色；`CLR_CTRL 0x3C` `bit0=GO(1 拍)`、`[3:2]=目标缓冲`、`bit4=ERR_CLR(1 拍)`。
- `CLR_STAT 0x40`：`bit0=BUSY`、`bit1=目标已清干净`、`[5:2]=四块缓冲 clean 位图`、`bit6=ERR(sticky)`、`[31:16]=上次 clear 的 AW 突发数`。
- `DRAW_SEL 0x44` `[1:0]` = 引擎正在画的缓冲；`CLR_CYC 0x48` = 上次 clear 周期数。
- **硬件互斥**：清屏目标 == 正在显示的缓冲 或 == DRAW_SEL ⇒ 一个像素都不写并置 ERR。

用法（FinalDemo.c:456-488）：

```c
static void clr_start(uint32_t k, int y0, int h)
{
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)y0 * FB_STRIDE);
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    blt_wr(BLT_CLR_WH,     ((uint32_t)h << 16) | (uint32_t)FB_WIDTH);
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
}
static int clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }
```
`hw_pass_arm(y0,h)` 做五步：① 有界等清屏空闲 → ② 读 clean 位图 → ③ 写 `DRAW_SEL` → ④ 脏则退回命令式整片清屏 → ⑤ 给第三块下清屏命令。

### 3.4 引擎指令编码（FinalDemo.c:500-572）

```c
#define BLT_OP_FILL   1UL     /* rtl/pixel_path.v 一致 */
#define BLT_OP_ALPHA  2UL
#define BLT_OP_KEY    3UL
/* COPY = 0（blt_copy_full 里直接写 0UL） */

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
```
8 条**无条件** store = 一条指令，任何中断/边界检查都必须在调用点之前做（`fulltest` 的 `blt_emit_cmd()` 把它写成硬规矩）。

FIFO 流控：
```c
#define BLT_FIFO_DEPTH      256
#define HW_FIFO_MARGIN 56
#define BLT_PUSH_LIMIT (BLT_FIFO_DEPTH - HW_FIFO_MARGIN)      /* 200 条 */
static uint32_t blt_push_room(void)
{ uint32_t cnt = blt_cnt();
  if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
  return (uint32_t)BLT_PUSH_LIMIT - cnt; }
```
空闲判据：
```c
static int blt_idle_st(uint32_t st)
{ return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
          !(st & BLT_STATUS_ERR)) ? 1 : 0; }
```
**FIFO 满时写 DATA 会把 CPU 挂在 AXI-Lite 上（主循环死锁）** —— 这是必须遵守的硬约束。

### 3.5 ★v2.11 显示列表 / 描述符表（FinalDemo.c:133-191）

```c
#define BLT_DL_BASE0        0x4C
#define BLT_DL_BASE1        0x50
#define BLT_DL_COUNT        0x54
#define BLT_DL_CTRL         0x58
#define   DL_CTRL_GO        (1UL << 0)
#define   DL_CTRL_ABORT     (1UL << 1)
#define   DL_CTRL_BUF_SEL   (1UL << 2)
#define   DL_CTRL_IRQ_EN    (1UL << 3)
#define   DL_CTRL_AUTO_GO   (1UL << 4)
#define   DL_CTRL_STRICT    (1UL << 5)
#define BLT_DL_STATUS       0x5C
#define   DL_ST_BUSY        (1UL << 0)
#define   DL_ST_DONE        (1UL << 1)
#define   DL_ST_ERR         (1UL << 2)
#define   DL_ST_ABORTED     (1UL << 3)
#define   DL_ST_STALL       (1UL << 4)
#define   DL_ST_CONSUMED_SH 16
#define BLT_DL_ERR          0x60
#define   DL_ERR_CLR_ALL    0x010000FFUL     /* W1C：低 8 位 + bit24(UNSUPPORTED) */
#define BLT_DL_FAULT_ADDR   0x64
#define BLT_DL_GEOM_BASE    0x68
#define BLT_DL_GEOM_MAX     0x6C
#define BLT_DL_DST_BASE     0x70
#define BLT_DL_CFG          0x74
#define BLT_DL_TIMEOUT      0x78
#define BLT_DL_PERF         0x7C
#define BLT_DL_VERSION      0x80
#define BLT_DL_DST_STRIDE   0x84
#define BLT_DL_FB_WH        0x88
```
- `DL_ERR` 位（`dl_err_name()`，与 `rtl/dl_fetch.v` 一一对应）：`0x01 DESC_RANGE`、`0x02 GEOM_INDEX`、`0x04 GEOM_RANGE`、`0x08 SPRITE_BOUNDS`、`0x10 WATCHDOG`、`0x20 AXI_RRESP`、`0x40 DESC_COUNT`、`0x80 ZERO_SIZE`、`0x01000000 UNSUPPORTED`。
- `DL_STATUS[9:8]=ACTIVE_BUF`、`[31:16]=CONSUMED`。
- 时序坑（RTL `blt_regs_axi_lite.v` 的 `if (ws[0] && !dl_busy)`）：**DFU BUSY=1 期间 0x4C~0x88 的写入被静默丢弃** ⇒ `dl_arm()` 先 `dl_arm_wait_idle()`，写完必须**逐项读回校验**（`dl_reg_chk()` + `dl_arm_verify()`），否则拒绝开启列表路径。
- `DL_CTRL` 的 `AUTO_GO`/`STRICT` 是 RW 且**复位为 1** ⇒ 每次写 `DL_CTRL` 都要把这两位一起写回 1。
- 能力探测：`DL_VERSION(0x80)` 低 16 位 `>= 2` 才算带显示列表。RTL 实证读回常量 **`32'h0210_0002`**（`blt_regs_axi_lite.v:797`）。
- 看门狗：`DL_TIMEOUT(0x78)` `[15:0]` = **单条描述符**看门狗，单位 **core 拍**，0=关，RTL 复位值 4096；软件显式编程为字段上界 **`0xFFFF` ≈ 753µs@87MHz**。
```
#define DL_TIMEOUT_RESET    4096
#define DL_TIMEOUT_TICKS    0xFFFFu
#define DL_TIMEOUT_X        16
```
- 描述符 = **16 字节 = 4 字 = 恰好 1 个 128bit AXI beat**：
```
dw0 [15:0]=X(signed)  [31:16]=Y(signed)
dw1 [15:0]=SPR_ID     [31:16]=FLAGS
dw2 [15:0]=KEY(0xFFFF=用几何表默认键色) [23:16]=ALPHA [31:24]=PRIO
dw3 [15:0]=MASK_ID(4x4 透明块位图) [23:16]=W_OVR [31:24]=H_OVR
FLAGS: [1:0]=OP(00COPY/01FILL/10ALPHA/11KEY) [2]MIRROR_X [3]MIRROR_Y
       [4]CLIP_EN [5]SIZE_OVR [6]SRC_OFF_EN [7]MASK_EN [9:8]MASK_MODE
       [10]END_OF_LIST [11]IRQ_AFTER [12]CHAIN [15:13]保留(=0)
```
软件宏：`DL_F_CLIP (1<<4)`、`DL_F_SZOVR (1<<5)`、`DL_F_MASKEN (1<<7)`、`DL_F_MASKMODE01 (1<<8)`、`DL_DESC_MAX 4095`。
- 几何表 = 16B/条，`gw0=ATLAS_BASE`、`gw1=[15:0]ATLAS_STRIDE [31:16]KEY_DEFAULT`、`gw2=[15:0]W [31:16]H`、`gw3=[15:0]SX [31:16]SY`。SPR_ID 映射（**11 条**）：

```
#define DL_G_FILL_16    0     /*  FILL 16x16 */
#define DL_G_FILL_32    1     /*  FILL 32x32 */
#define DL_G_FILL_64    2     /*  FILL 64x64 */
#define DL_G_ALPHA_16   3
#define DL_G_ALPHA_32   4
#define DL_G_ALPHA_64   5
#define DL_G_KEY_16     6
#define DL_G_KEY_32     7
#define DL_G_KEY_64     8
#define DL_G_REP_SPLIT  9     /*  铺底 960x260 */
#define DL_G_REP_FULL   10    /*  铺底 960x524 */
#define DL_GEOM_N       11
```
- DDR 布局：
```c
#define DL_GEOM_ADDR    (DDR_BASE + 0x00800000UL)                       /* 0x00801000 */
#define DL_LIST_ADDR(b) (DDR_BASE + 0x00820000UL + (uint32_t)(b) * 0x00020000UL)
                                        /* b=0 → 0x00821000 ; b=1 → 0x00841000 */
```
- 关键 API：`dl_put()`（写描述符）、`dl_geom_put()`、`dl_spr_id(scene)`、`dl_rep_id(path)`、`dl_build()`、`dl_geom_fill()`/`dl_geom_build()`、`dl_arm()`/`dl_arm_verify()`/`dl_arm_wait_idle()`、`dl_go(buf,cnt,dst_base)`（固定顺序：`DST_BASE` → `COUNT` → `CTRL(GO|AUTO_GO|STRICT|BUF_SEL)`）、`dl_supported()`、`dl_err_report()`/`dl_status_dump()`/`dl_disable()`/`dl_wd_summary()`/`dl_wd_decide()`、`dl_pixel_probe()`（首表像素落地探针）、`dl_cost_report()`/`cmd_cost_report()`、`dl_apply_pending()`（'l' 的帧边界待生效切换）。

### 3.6 完整 DDR 内存映射（FinalDemo）

```c
#define FB_WIDTH      960
#define FB_HEIGHT     540
#define FB_STRIDE     (FB_WIDTH * 2)               /* 1920 B/行 */
#define DDR_BASE      0x00001000UL                 /* = soc.h SYSTEM_DDR_BMB */
#define FB_BASE       (DDR_BASE + 0x00300000UL)    /* 0x00301000 显示缓冲（只由引擎写） */
#define FB_BACK       (DDR_BASE + 0x00500000UL)    /* 0x00501000 后台缓冲 */
#define FB_BUF2       (DDR_BASE + 0x00700000UL)    /* 0x00701000 第三块缓冲 */
#define ATLAS_BASE    (DDR_BASE + 0x00200000UL)    /* 0x00201000 精灵图集 */
#define FLUSH_SCRATCH (DDR_BASE + 0x00600000UL)    /* 0x00601000 8KB 写穿屏障区 */
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)         /* 2048 字 */
/* 列表路径：0x00801000 几何表(176B) / 0x00821000 列表0 / 0x00841000 列表1 */
```

### 3.7 BSP 里的外设地址（`soc/bsp/efinix/EfxSapphireSoc/include/soc.h`）

```c
#define SYSTEM_CLINT_HZ 100000000
#define SYSTEM_RAM_A_CTRL 0xf9000000
#define SYSTEM_BMB_PERIPHERAL_BMB 0xf8000000          /* size 0x1000000 */
#define SYSTEM_PLIC_CTRL 0xf8c00000
#define SYSTEM_CLINT_CTRL 0xf8b00000                  /* CLINT: TIME @ +0xBFF8 */
#define SYSTEM_UART_0_IO_CTRL 0xf8010000
#define SYSTEM_SPI_0_IO_CTRL  0xf8014000
#define SYSTEM_GPIO_0_IO_CTRL 0xf8015000
#define SYSTEM_I2C_0_IO_CTRL  0xf8016000
#define IO_APB_SLAVE_0_INPUT  0xf8100000              /* ← 2D 加速器 BLT_BASE */
#define IO_APB_SLAVE_0_INPUT_SIZE 0x10000
#define SYSTEM_DDR_BMB 0x1000
#define SYSTEM_DDR_BMB_SIZE 0xe0000000
#define SYSTEM_AXI_A_BMB 0xe1000000
#define SYSTEM_PLIC_USER_INTERRUPT_A_INTERRUPT 16     /* 加速器中断线 */
```

---

## 4. 帧缓冲 / 多重缓冲 / 缓存操作

### 4.1 缓冲数量与上屏方式（三个编译期开关，FinalDemo.c:193-282）

```c
#ifndef FB_FLIP_PUBLISH
#define FB_FLIP_PUBLISH 1      /* 1 = FLIP 换基址上屏；0 = 整屏 COPY 上屏 */
#endif
#ifndef FB_TRIPLE_BUFFER
#define FB_TRIPLE_BUFFER 1     /* 仅 FLIP 路径有效：三缓冲轮转 + 并发清屏引擎 */
#endif
#ifndef FB_IRQ_PACING
#define FB_IRQ_PACING 1        /* 仅 FLIP 路径有效：翻转确认改成帧边界中断驱动 */
#endif

#if FB_TRIPLE_BUFFER
#define FB_NBUF             3
#else
#define FB_NBUF             2
#endif
#define FLIP_TIMEOUT_TICKS  (BSP_CLINT_HZ / 10u)   /* 有界等待：100ms ≈ 6 场 @60Hz */
#define CLR_WAIT_TICKS      (BSP_CLINT_HZ / 100u)  /* 清屏引擎有界等待：10ms */
#define SIZE_REPAINT_ROUNDS (FB_NBUF - 1)          /* 三缓冲=2，双缓冲=1 */
```

状态变量：
```c
static uint32_t g_fb_back = FB_BACK;        /* 当前后台缓冲：CPU 与引擎都画这里 */
static uint32_t g_disp_sel  = 0;            /* 已确认在屏的缓冲（0=FB_BASE 1=FB_BACK 2=FB_BUF2） */
static uint32_t g_flip_req  = 0;            /* 已写下、还没确认的请求 */
static uint32_t g_flip_to   = 0;            /* 有界等待超时次数 */
static uint8_t  g_bar_ok[3] = {0,0,0};      /* 信息条是否已画进 buf[0]/[1]/[2] */
static int      g_draw3 = -1, g_clr3 = -1;  /* 本趟绘制目标 / 交给清屏引擎预清的那块 */
static int      g_clr_need = 0, g_pass_armed = 0;
static uint32_t g_clr_fb = 0, g_clr_to = 0, g_clr_err = 0;
```

- **三缓冲轮转**：`显示 A / 画 B / 预清 C`。一次成功翻转后 `g_disp_sel = g_flip_req; g_draw3 = g_clr3; g_clr3 = old_disp; g_clr_need = 1; g_pass_armed = 0; g_fb_back = fb_of_sel(g_draw3);`
- **FLIP 上屏**（`FB_FLIP_PUBLISH=1`）：`cache_evict(); g_flip_req = g_draw3; blt_wr(BLT_FB_SEL, g_flip_req); back_busy = 1; back_t0 = tick32();`
  确认条件：`if (flip_ev && (fb_stat_sel() == g_flip_req)) { back_busy = 0; ... scr_frames++; }`
  超时：`if ((uint32_t)(tick32() - back_t0) > FLIP_TIMEOUT_TICKS) { g_flip_to++; blt_wr(BLT_FB_SEL, g_flip_req); back_t0 = tick32(); }`（重发请求，绝不往可能正在上屏的缓冲里画）。
  IRQ 节拍：`uint32_t irq = blt_rd(BLT_IRQ_STATUS); if (irq & BLT_IRQ_FRAME) { blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME); flip_ev = 1; } else flip_ev = 0;`
- **COPY 上屏**（`FB_FLIP_PUBLISH=0`）：
```c
static void blt_copy_full(uint32_t src, uint32_t dst)
{ blt_emit(0UL /*COPY*/, src, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, 0xFFu, 0u); }
```
  完成判据加 200µs 保护：`blt_idle_st(blt_stat()) && (tick32()-back_t0) > BSP_CLINT_HZ/5000u`。

### 4.2 缓存 flush / invalidate

FinalDemo **只用一种**缓存操作 —— 写穿屏障 `cache_evict()`（FinalDemo.c:492-498）：

```c
/* CPU 写完 DDR 后、引擎紧接着要读的场合调用（D$ 是写穿，本质是 store 有序屏障） */
static void cache_evict(void)
{
    volatile uint32_t *s = (volatile uint32_t *)FLUSH_SCRATCH;   /* 0x00601000 */
    uint32_t i;
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;   /* 2048 字 = 8KB */
}
```
调用点：
1. `build_atlas()` 之后（图集要给引擎读）
2. `scene_init()` 之后
3. `dl_geom_build()` 内（几何表 176B）
4. `dl_arm()` 里读回校验**之前**（把刚写的几何表挤出 D$，保证读回真的读 DDR）
5. `dl_build()` 写描述符之后（`cache_evict(); /* 硬件紧接着要读这批描述符 */`）
6. 每次上屏发布之前（FLIP 与 COPY 两条路径各一处）
7. 开机整屏铺底之后

**FinalDemo 不调用 `data_cache_invalidate_all()`**。该宏只在 `FBtest`、`application/fbTest`、`fulltest` 里用：
```c
/* driver/vexriscv.h */
#define data_cache_invalidate_all() asm(".word(0x500F)");
#define instruction_cache_invalidate() asm("fence.i");
```
依据（`fulltest` 头部注释）：本 SoC 的 D$ tag **没有 dirty 位**（写穿），所以 `cache_evict()` 只是"顺序屏障"；`invalidate` 只丢干净副本，任何时刻调用都安全；而 HDMI 扫描输出是外部主设备，CPU→外设方向必须用 flush/挤出而不是 invalidate。

### 4.3 与 CPU 视角有关的对齐陷阱（FinalDemo.c:689-712）

```c
/* 32bit 存储要求 4 字节对齐 = 像素列号 x 必须是偶数；奇数 x 用 16bit 收头/收尾 */
static void cpu_fill32(uint32_t base, int x, int y, int w, int h, uint16_t color)
{
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    int odd = (x & 1);
    for (j...) { volatile uint16_t *p = (volatile uint16_t *)(base + (y+j)*FB_STRIDE + x*2u);
        int rem = w;
        if (odd) { *p++ = color; rem--; }
        { volatile uint32_t *q = (volatile uint32_t *)p; for (i=0;i<(rem>>1);i++) q[i] = two; }
        if (rem & 1) p[rem-1] = color; }
}
```
> 早期版本在奇数 `x` 上做 32bit store → RISC-V 未对齐异常 → **程序静默停死**（静态画面 + 串口无输出）。这是本工程历史上"整机卡死"的真因。
> 另外 `scene_step()` 里**不能**再写 `x &= ~1`（旧版这么干会让 vx=±1 的方块卡住不动、永远不擦、ALPHA 场景一路变暗）。

---

## 5. 绘制：软件渲染路径 vs 硬件渲染路径

### 5.1 硬件路径（引擎指令）

```c
static void blt_fill(uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{ blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color); }

static void blt_alpha(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                      uint32_t w, uint32_t h, uint32_t alpha)
{ blt_emit(BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u); }

static void blt_key(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                    uint32_t w, uint32_t h, uint32_t key)
{ blt_emit(BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key); }
```

逐条下发路径的本趟循环（FinalDemo.c:2729-2760）：

```c
while (hw_i < n && room > 0u && budget-- > 0u) {
    blk_t *b = &g_sc[SIDE_HW][hw_i];
    uint32_t need = 1u;
    if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
        need = 2u;                                    /* 擦 + 画成对，绝不半发 */
    if (room < need) break;
    if (need == 2u)
        blt_fill(g_fb_back + (b->dy + y0) * FB_STRIDE + b->dx * 2u,
                 FB_STRIDE, b->sz, b->sz, COL_BG);    /* 擦旧矩形 */
    {   uint32_t dst = g_fb_back + (b->ty + y0) * FB_STRIDE + b->tx * 2u;
        if (scene == SC_FILL)       blt_fill (dst, FB_STRIDE, b->sz, b->sz, b->color);
        else if (scene == SC_ALPHA) blt_alpha(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, alpha);
        else                        blt_key  (ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, KEY_COLOR);
    }
    b->dx = b->tx; b->dy = b->ty;                     /* 记账：画的就是快照位置 */
    room -= need;
    if (++hw_i >= n) { hw_frame_pushed = 1; break; }
}
```
本趟开头（`hw_i==0`）若 `repaint_hw` 则先发一条整片 FILL：
```c
blt_fill(g_fb_back + (uint32_t)y0 * FB_STRIDE, FB_STRIDE, FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
```
**ALPHA 必须每次都擦**：`dest = blend(src,dest)` 不擦就再混一次 ⇒ 逐帧变暗（板上现象：方块不动时周期性忽明忽暗）。

### 5.2 软件（CPU）路径

```c
/* 与 rtl/pixel_path.v 同一条公式的定点混合 */
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
    if (r > 255u) r = 255u; if (g > 255u) g = 255u; if (b > 255u) b = 255u;
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
}

/* CPU 版 ALPHA：逐像素 读目的 → 混合 → 写回（CPU 最吃亏：多一次读） */
static void cpu_alpha_sprite(int x, int y, unsigned alpha)
{ const volatile uint16_t *s = (const volatile uint16_t *)ATLAS_BASE;
  for (j=0;j<SPR_H;j++){ volatile uint16_t *d = (volatile uint16_t *)(g_fb_back + (y+j)*FB_STRIDE + x*2u);
      for (i=0;i<SPR_W;i++) d[i] = blend565(s[j*SPR_W+i], d[i], alpha); } }

/* CPU 版 KEY：逐像素 读源 → 判色键 → 条件写 */
static void cpu_key_sprite(int x, int y)
{ ... uint16_t c = s[j*SPR_W+i]; if (c != (uint16_t)KEY_COLOR) d[i] = c; ... }
```
CPU 侧主循环（FinalDemo.c:2769-2793）：
```c
b = &g_sc[SIDE_CPU][cpu_i];
if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
    cpu_fill32(g_fb_back, b->dx, b->dy + y0, b->sz, b->sz, COL_BG);   /* 先擦 */
if (scene == SC_FILL)       cpu_fill32(g_fb_back, b->tx, b->ty + y0, b->sz, b->sz, b->color);
else if (scene == SC_ALPHA) cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
else                        cpu_key_sprite(b->tx, b->ty + y0);
b->dx = b->tx; b->dy = b->ty;
if (++cpu_i >= n) { cpu_i = 0; cpu_frames++; cpu_done = 1; }
```
CPU 侧**不跟随 `clear_pp`**（保持 comptest2 的"先擦后画"语义）—— 这是 CPU-vs-HW 公平对比的分母。

### 5.3 精灵图集 / 色键 / 掩码（FinalDemo.c:574-687）

```c
#define SPR_W      BLK_W          /* = g_blk（运行期） */
#define SPR_H      BLK_H
#define SPR_STRIDE (SPR_W * 2)
#define SPR_RING   (SPR_W / 8)    /* 白环厚度：16→2px，32→4px，64→8px */
#define KEY_COLOR     0xF81Fu     /* 色键（洋红）：精灵四角用它 */

static uint16_t spr_color(int i, int j)
{
    int dx = i - SPR_W/2, dy = j - SPR_H/2;
    int d2 = dx*dx + dy*dy, r2 = (SPR_W/2)*(SPR_W/2);
    int ri = SPR_W/2 - SPR_RING;
    if (d2 > r2)      return KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    if (d2 > ri*ri)   return COL_WHITE;      /* 白环 */
    rr = (i*31)/(SPR_W-1); gg = (j*63)/(SPR_H-1); bb = 31 - ((d2*31)/(r2?r2:1));
    return (rr<<11)|(gg<<5)|bb;              /* RGB565 渐变内芯 */
}
```
`build_atlas()` 把 `SPR_W×SPR_H` 像素写到 `ATLAS_BASE`，并在**同一个函数末尾**重算 4x4 透明块掩码：
```c
static uint16_t g_spr_mask = 0u;
static uint16_t spr_mask_of(const volatile uint16_t *px, int w, int h, uint16_t key);
static int      spr_mask_tiles(uint16_t m);
g_spr_mask = spr_mask_of((const volatile uint16_t *)ATLAS_BASE, SPR_W, SPR_H, (uint16_t)KEY_COLOR);
```
块边界与 RTL 同公式：列块起点 `floor(W*ct/4)`、行带起点 `floor(H*rt/4)`；位 `rt*4+ct = 1` 表示"整块全透明⇒跳过"。**只有 KEY 描述符**会带上 `MASK_EN + MASK_MODE=01`；ALPHA/FILL 在 RTL 里显式忽略掩码。

### 5.4 OSD / 字体（FinalDemo.c:760-955）

```c
#define OSD_H     16
#define SEP_H     4
#define TOP_Y0    OSD_H                          /* 上半天区起点 = 16 */
#define HALF_H    260                            /* 半区高度（虚拟场景高度也用它） */
#define BOT_Y0    (TOP_Y0 + HALF_H + SEP_H)      /* 下半天区起点 = 280 */
#define OSD_GLYPH_W  8 ; #define OSD_GLYPH_H  8
#define OSD_TEXT_Y   4 ; #define OSD_TEXT_X0  8
#define OSD_LEFT_CH  64
#define COL_BG        0x0008u
#define COL_OSD_BG    0x0000u
#define COL_HW_FG     0xFFE0u    /* 黄：硬件侧 */
#define COL_CPU_FG    0x07FFu    /* 青：CPU 侧 */
#define COL_SEP       0x4208u
#define COL_WHITE     0xFFFFu
```
`typedef struct { char c; uint8_t r[8]; } glyph_t;` + `static const glyph_t g_font[]`（约 36 个字模：数字、A C D E F H I K L M N O P R S T U W Y Z、`= . : / -` 与空格）；`glyph_of()` 会先把小写转大写。
`osd_text()` 每字符写 4 个 32bit 字（小端：`bit7` 必须放低半字，否则每个字里两个像素对调 → 屏上乱码）。
`osd_blit()` **只在 COPY 不在飞时**调用，且只清"文字真会落到"的两块黑底：
```c
cpu_fill32(g_fb_back, OSD_TEXT_X0, 0, OSD_LEFT_PX, OSD_H, COL_OSD_BG);
cpu_fill32(g_fb_back, FB_WIDTH - OSD_RIGHT_PX, 0, OSD_RIGHT_PX, OSD_H, COL_OSD_BG);
osd_text(OSD_TEXT_X0, OSD_TEXT_Y, line, COL_WHITE);
osd_text(FB_WIDTH - OSD_GLYPH_W * slen(lbl), OSD_TEXT_Y, lbl, COL_WHITE);
```
**信息条事件驱动**：`g_osd_dirty` 只在内容真的变了才置位；`g_osd_line[OSD_LEFT_CH+2]` 保存"想显示"的左串；组串在 `fmt_stat()`，比较用 `sseq()`（不引 `<string.h>`，BSP 是 mini 版）。

---

## 6. UART / 串口命令处理（**轮询，不用中断**）

### 6.1 底层（FinalDemo.c:957-974）

```c
#define UART_TERM       SYSTEM_UART_0_IO_CTRL      /* 0xF8010000 */
#define UART_DATA_OFS   0x00
#define UART_STATUS_OFS 0x04
static uint32_t uart_status_raw(void)
{ return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS); }
static int uart_poll_char(void)
{
    if ((uart_status_raw() >> 24) == 0u) return 0;                 /* RX 占用 = status[31:24] */
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
}
```
**关键坑**（源码注释原话）：`driver/uart.h` 里
`uart_writeAvailability = (status >> 16) & 0xFF`（TX 剩余空间）、
`uart_readOccupancy = (status >> 24)`（RX 已收字节数）。
早期误用 `>>16` ⇒ TX 一忙就当成"有数据"、跑去读空 RX，串口指令完全无效。

发送走 BSP：`bsp_printf()` → `uart_write()`（`while(uart_writeAvailability(reg)==0); write_u32(data, reg+UART_DATA);`），阻塞式；**115200 8N1**（`bsp_init()` 里 `clockDivider = BSP_CLINT_HZ/(115200*8)-1`）。
`print.h` 是 **mini 版，只认 `%c %s %d %X %x`** —— 出现 `%u`/宽度数字/`%%` 会错位消耗 `va_arg`，后面的 `%s` 拿整数当指针**直接挂死**。

### 6.2 读取时机：只在"慢时间片"

```c
#define SLOW_MASK        31u
if ((it & SLOW_MASK) == 0u) {          /* 每 32 圈一次 */
    int c = uart_poll_char();
    t_now = tick32();
    if (c) { ... 命令处理 ... }
    ... 场景推进 / 1Hz 统计 ...
}
```
（旧版每圈做：1 次 UART 状态读 + 3 次 CLINT 读 = 10 次外设总线事务/圈。）

### 6.3 `=N` 精确 N 命令（行缓冲，FinalDemo.c:976-1027）

```c
#define N_MIN   25
#define N_STEP  25
#define N_MAX   6000
#define MAXBLK  N_MAX
#define NLINE_MAX 12
#define NL_NONE    0     /* 该字符与 '=' 行无关 ⇒ 交给单字符命令分支 */
#define NL_MORE    1
#define NL_OK      2     /* 结算完成，*out = 实际生效的 N */
#define NL_ERR   (-1)
static char g_nl[NLINE_MAX]; static unsigned g_nl_n; static int g_nl_on;
static int nline_feed(int c, int *out);
```
- `=1375\n` ⇒ `EV N=1375`；`=10\n` ⇒ 钳到 25 ⇒ `EV N=25`；`=9999\n` ⇒ 钳到 6000 ⇒ `EV N=6000`；非数字/超长/无数字 ⇒ `EV N=ERR`。
- 边收边钳 `v = min(v*10+d, N_MAX)`（收满 12 位也不溢出）。
- 行内出现非法字符 ⇒ 立刻作废并复位，且**只吃掉那一个字符**，后续字符马上恢复单字符命令语义。

### 6.4 单字符命令一览（命中即执行，无需回车）

| 键 | 作用 | 回包 |
|---|---|---|
| `1` / `2` / `3` | 场景 FILL / ALPHA / KEY | `EV scene=0/1/2 (0=FILL 1=ALPHA 2=KEY)` |
| `s` | 路径 SPLIT（上 HW / 下 CPU） | `EV path=0 SPLIT` |
| `c` | 路径纯 CPU | `EV path=1 CPU only` |
| `h` | 路径纯硬件 | `EV path=2 HW only` |
| `n` / `N` / `+` | N += 25（越上界回绕到 N_MIN） | `EV N=<n>` |
| `-` | N -= 25（越下界回绕到 N_MAX） | `EV N=<n>` |
| `a` / `A` | alpha ∓32（钳在 0/32…255） | `EV alpha=<a>` |
| `e` | clear_per_pass 取反（每趟整片重铺） | `EV clear_per_pass=1 (1=every pass refills the HW region)` |
| `t` | 推进模式：时间(25 步/s) ↔ 每发布一帧一步 | `EV advance=0 (0=time 25 step/s, 1=one step per published frame)` |
| `k` | 方块/精灵边长 16→32→64→16 | `EV size=<g_blk>` |
| `r` | 场景重置（换种子 `g_seed += 0x9E3779B9u`） | `EV reset` |
| `l` | 显示列表路径 on/off（**默认关**，**帧边界待生效**） | `EV dl on/off pending` → 生效时 `EV dl on/off` |
| `?` | 打印帮助 | 多行 cmd 文本 |

`k` 的四步（FinalDemo.c:2075-2104）：① `g_blk = blk_next(g_blk)` → ② `build_atlas()`（图集 + 掩码同函数重算）→ ③ `scene_change=1`（走 `scene_init()` 通路，`repaint_hw = repaint_cpu = 1`）→ ④ `disp_change=1`（信息条补新 `SZ=`）。列表面板**不用重建**：几何表三个尺寸各占一条，`dl_spr_id()` 现算 SPR_ID。

`l` 的待生效切换（`dl_apply_pending()`）：`'l'` 只登记 `g_dl_want`，真正切换落在**帧发布边界**（FLIP 路径 = `FB_STAT` 确认翻转生效那一刻；COPY 路径 = 整帧 COPY 完成那一刻）。这修掉了旧版"列表路径每帧都发表 ⇒ DFU 几乎永远 BUSY ⇒ 打开之后再也关不掉、只能重启"。

---

## 7. 主循环结构 / 帧时序 / FPS

### 7.1 主循环骨架（`for (;;)`，FinalDemo.c:2025-2838）

```
it++
├─ if ((it & SLOW_MASK)==0)  ← 每 32 圈
│   ├─ c = uart_poll_char(); t_now = tick32();
│   ├─ if (c) { 命令处理 → scene_change / disp_change → scene_init / osd_build }
│   ├─ 场景推进（时间模式 or 帧率模式）
│   └─ 1Hz 帧率统计（内联门控 + osd_service，三个计数一起清零）
├─ if (back_busy)            ← 上屏在飞（FLIP 等 FB_STAT / COPY 等 idle）
│   ├─ 拍场景快照 snap_hw/snap_cpu（此刻两侧渲染段都被挡住）
│   ├─ 到点的 1Hz 统计/组串也在这里做
│   └─ 每 4 圈读一次状态；其余圈纯 ALU 退避；超时重发 FLIP 请求
├─ else if (本趟两侧都画完) → 发布上屏（FLIP: 写 FB_SEL / COPY: blt_copy_full）
├─ if (!back_busy && path != PATH_CPU)  ← 硬件侧渲染段
│   ├─ 列表路径（g_dl_fbwait 交接 / g_dl_mode 乒乓发表 / 逐条下发）
│   └─ 逐条下发路径（等本趟画完 → 或推指令）
├─ if (!back_busy && path != PATH_HW)   ← CPU 侧渲染段：每圈一块
└─ 信息条落屏（y 0..16，事件驱动 + 不在飞时才画；SPLIT 时补分隔条）
```

### 7.2 主循环节流参数（FinalDemo.c:1855-1867）

```c
#define SLOW_MASK        31u    /* 每 32 圈做一次"慢工作"：UART RX + 时间戳 + 场景推进 + 1Hz 统计 */
#define BLT_WAIT_MASK     3u    /* 等引擎时每 4 圈才读一次状态字 */
#define BLT_WAIT_NOP     48u    /* 每次退避空转量 ≈150~190 周期 ≈1.5~1.9us @100MHz */
#define HW_PUSH_BUDGET   64u    /* 一圈最多推几条引擎指令：64 条 = 512 次 FIFO 写 */
```
纯 ALU 退避（**不产生任何总线事务**，这比省 CPU 更重要 —— 整帧 COPY 正在吃 DDR 带宽）：
```c
static void cpu_backoff(uint32_t n)
{ if (n == 0u) return;
  __asm__ __volatile__ ("1:\n\t" "addi %0, %0, -1\n\t" "bnez %0, 1b\n\t" : "+r"(n)); }
```

### 7.3 帧时序 / 时间基

```c
/* 只用 CLINT mtime 低 32 位：1 次总线读（clint_getTime 要 hi/lo/hi 三次） */
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }

#define SCENE_TICKS  (BSP_CLINT_HZ / 25u)    /* 时间模式：场景推进周期 = 40ms（25 步/秒） */
#define MAX_STEPS    8                       /* 一次补步的上限 */
```
时间模式一次慢时间片里最多补 8 步（`do { scene_step_both(...); steps++; } while ((tick32()-t_scene) >= SCENE_TICKS && steps < MAX_STEPS);`）。

### 7.4 FPS 计算（FinalDemo.c:909-941）

三个计数器共用**同一个 1Hz 窗口、同一次清零**：
```c
uint32_t hw_frames = 0, cpu_frames = 0, scr_frames = 0;
/* hw_frames/cpu_frames = 两侧各自的**渲染趟数**；scr_frames = 整帧真正上屏的次数 */

static int osd_service(uint32_t t_now, uint32_t hw_frames, uint32_t cpu_frames, uint32_t scr_frames, ...)
{
    uint32_t el = (uint32_t)(t_now - g_osd_t0);
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;         /* 每秒最多算一次 */
    g_osd_t0  = t_now;
    g_hw_fps  = (uint32_t)(((uint64_t)hw_frames  * (uint64_t)BSP_CLINT_HZ) / el);
    g_cpu_fps = (uint32_t)(((uint64_t)cpu_frames * (uint64_t)BSP_CLINT_HZ) / el);
    g_scr_fps = (uint32_t)(((uint64_t)scr_frames * (uint64_t)BSP_CLINT_HZ) / el);
    osd_build(...);
    return 1;
}
```
`BSP_CLINT_HZ = SYSTEM_CLINT_HZ = 100000000`（core_clk 100MHz，`par` 的 `pt.sdc` 与 `rtl/功能清单.md §1` 同口径）。
信息条格式（`fmt_stat()`，FinalDemo.c:882-907）：
```
HW=nnn CPU=nnn SCR=nn SZ=nn N=nnnn SCn:NAME A=nnn [E] [FR] [L]
```
- `HW`/`CPU` 钳到 3 位、`SCR` 钳到 2 位（上屏帧率被 1.92M 周期的整帧 COPY 顶在 ~52fps）。
- `E` = clear_per_pass 开；`FR` = 帧率模式；`L` = 显示列表路径开。
- 右侧右对齐路径标签：`SPLIT` / `CPU ONLY` / `HW ONLY`。

成本读数（★v2.15，1Hz 门控，两条路径同口径）：
```
EV dl list done: n=%d cycles=%d cyc/sprite=%d     /* DL_PERF(0x7C)，纯硬件成本 */
EV cmd path done: n=%d cycles=%d cyc/sprite=%d    /* tick32 墙钟秒表，含 8 次 MMIO/块的 CPU 开销 */
```
板上实测（ALPHA/16x16）：列表路径 ≈1232 拍/精灵，逐条路径 ≈863 拍/精灵 ⇒ **读多的场景里列表路径是净亏**（源码如实写在注释里）。

---

## 8. 场景 / 路径 / N 的实现

### 8.1 常量与数据结构

```c
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
    int16_t  x, y;      /* 场景当前目标位置（两侧按同一规则推进，逐位相同） */
    int16_t  vx, vy;
    int16_t  dx, dy;    /* **这一侧**上一趟画到的位置（擦除用，各自独立） */
    int16_t  tx, ty;    /* ★本趟的快照：一趟渲染期间位置恒定不变 —— 消除尾迹的关键 */
    uint16_t color;
    uint8_t  sz;
} blk_t;

static blk_t    g_sc[NSIDE][MAXBLK];       /* 2 × 6000 × ~14B ≈ 168KB（在 1MB ram 区内） */
static uint32_t g_seed = 0x12345678u;
```
`h` 域用 `b->sz`（当前边长）而非常量钳位。

### 8.2 分区（路径决定谁画哪块屏）

```c
#define OSD_H     16
#define SEP_H     4
#define TOP_Y0    OSD_H                          /* 16 */
#define HALF_H    260
#define BOT_Y0    (TOP_Y0 + HALF_H + SEP_H)      /* 280 */
/* 16 + 260 + 4 + 260 = 540 ✓ */

static int hw_y0(int path)  { (void)path; return TOP_Y0; }
static int hw_h(int path)   { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
static int cpu_y0(int path) { return (path == PATH_SPLIT) ? BOT_Y0 : TOP_Y0; }
static int cpu_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
static int vrg_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
```
| path | 硬件侧 | CPU 侧 |
|---|---|---|
| `PATH_SPLIT` (0) | y 16..276 上半 | y 280..540 下半 |
| `PATH_HW` (2) | y 16..540 整区 | 不画 |
| `PATH_CPU` (1) | 不画 | y 16..540 整区 |

`vrg_h()` 同时决定**虚拟场景高度**（旧版写死 `HALF_H`，所以切到单模式时物块只在上面 260 行里弹）。

### 8.3 场景初始化 / 快照 / 推进（FinalDemo.c:1029-1134）

```c
#define SCENE_MX(sz)  (4 * (sz))          /* 右侧余量 = 4 个方块 */
#define SCENE_MY(sz)  (5 * (sz) / 2)      /* 下侧余量 = 2.5 个方块 */
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }

static void scene_init(int n, uint32_t seed, int sz_fixed)
{
    int xr = FB_WIDTH - SCENE_MX(g_blk);
    int yr = HALF_H   - SCENE_MY(g_blk);
    for (side = 0; side < NSIDE; side++) {
        uint32_t s = seed;                            /* 两侧同一颗种子 ⇒ 目标逐位相同 */
        for (i = 0; i < n; i++) {
            blk_t *b = &g_sc[side][i];
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
            b->sz = (uint8_t)(sz_fixed ? SPR_W : BLK_W);   /* 两种取值都 = g_blk */
            b->vx = (int16_t)((int)(r1 % 7u) - 3);         /* ±1..±3 */
            b->vy = (int16_t)((int)(r2 % 5u) - 2);         /* ±1..±2 */
            if (!b->vx) b->vx = 1;  if (!b->vy) b->vy = 1;
            b->x = (int16_t)((int)(r1 % (uint32_t)xr) & ~1);
            b->y = (int16_t)(int)(r2 % (uint32_t)yr);
            if (b->x + b->sz > FB_WIDTH) b->x = (int16_t)(FB_WIDTH - b->sz);  /* 兜底钳位 */
            if (b->y + b->sz > HALF_H)   b->y = (int16_t)(HALF_H   - b->sz);
            b->dx = b->x; b->dy = b->y;      /* 本侧"已画位置"初始对齐 */
            b->tx = b->x; b->ty = b->y;      /* 本趟快照初始对齐 */
            b->color = (uint16_t)((((r1>>8)&0x1Fu)<<11) | (((r2>>8)&0x3Fu)<<5) | ((r1+r2)&0x1Fu));
        }
    }
}
```
`sz_fixed`：FILL 传 0（用 `BLK_W`）、ALPHA/KEY 传 1（用 `SPR_W`）；因为都是 `g_blk`，两种取值相同 —— 统一几何让三个场景的每块工作量一致，横向对比才公平。

```c
/* 给场景拍快照：把当前的 x,y 冻结到 tx,ty。调用点只有两处：
 *   a) 一趟的起点（hw_i==0/cpu_i==0 且本侧上一趟已完成）
 *   b) 整帧 COPY 在飞的窗口（此刻两侧的渲染段都被 back_busy 挡住） */
static void scene_snap(blk_t *sc, int n)
{ for (i=0;i<n;i++) { sc[i].tx = sc[i].x; sc[i].ty = sc[i].y; } }

/* 只推进**目标位置**（两侧同时调用 ⇒ 目标逐位相同）；不动 dx/dy */
static void scene_step(blk_t *sc, int n, const rect_t *rg)
{
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    int ymin = rg->y0, ymax = rg->y0 + rg->h;
    for (i = 0; i < n; i++) {
        blk_t *b = &sc[i];
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
        b->x = (int16_t)x;  b->y = (int16_t)y;
    }
}
static void scene_step_both(int n, const rect_t *rg, int *snap_hw, int *snap_cpu)
{ scene_step(g_sc[SIDE_HW], n, rg); scene_step(g_sc[SIDE_CPU], n, rg);
  *snap_hw = 1; *snap_cpu = 1; }     /* 位置变了 ⇒ 两侧的快照都失效，等各自下一趟起点重拍 */
```

### 8.4 运行时方块尺寸（唯一来源 `g_blk`）

```c
/* ==== BLK_CYCLE_BEGIN ==== */
#define BLK_LO   16      /* 'k' 的循环顺序：16 → 32 → 64 → 16 */
#define BLK_MID  32
#define BLK_HI   64
#define BLK_N    3
static const int g_blk_tab[BLK_N] = { BLK_LO, BLK_MID, BLK_HI };
static int g_blk = BLK_LO;
static int blk_idx(int sz)  { int i; for (i=0;i<BLK_N;i++) if (g_blk_tab[i]==sz) return i; return 0; }
static int blk_next(int sz) { return g_blk_tab[(blk_idx(sz)+1) % BLK_N]; }
/* ==== BLK_CYCLE_END ==== */
#define BLK_W   g_blk
#define BLK_H   g_blk
```
64x64 的合法性：FILL 走 SIZE_OVR ⇒ `W_OVR/H_OVR` 是 8bit（64 ≤ 255 ✓）；ALPHA/KEY 走几何表 ⇒ W/H 是 16bit、行距 128B ≤ 65535 ✓。
初始位置余量（`SCENE_MX/MY`）：16 → xr=896/yr=220；32 → 832/180；64 → 704/100，`x+sz` 最大 912/864/768 ≪ 960。

### 8.5 消除尾迹的三条关键设计（源码注释原话要点）

1. **不需要屏外缓冲、不需要整屏 COPY**：两侧各画自己那一半。早期"CPU 一写显示缓冲就整机卡死"的真因是**未对齐 32bit 存储**，与写哪块缓冲无关。
2. **同一个场景**：两侧同一颗种子 + 同一套推进规则 ⇒ 目标坐标逐位相同；差异只体现在"谁跟得上"。
3. **每侧各有自己的 (dx,dy)**，且一趟之内用快照 (tx,ty) 恒定位置 ⇒ 某一侧慢很多也不会擦错地方、不会拖影。

---

## 9. 共享驱动 / BSP 头文件位置与内容

### 9.1 BSP（`sys/bsp`）——`.../embedded_sw/soc/bsp/efinix/EfxSapphireSoc/`

| 文件 | 字节 | 内容要点 |
|---|---|---|
| `include/bsp.h` | 5,381 | `BSP_PLIC/BSP_UART_BAUDRATE 115200/BSP_CLINT/BSP_CLINT_HZ/bsp_uDelay`、`bsp_putChar/bsp_getChar`、`bsp_init()`（UART 分频）、`ENABLE_BSP_PRINTF 1`、`ENABLE_BSP_PRINTF_FULL 0` |
| `include/soc.h` | 3,177 | 全部外设基址与 PLIC 中断号（见 §3.7） |
| `include/compatibility.h` | 2,321 | `SYSTEM_UART_0_IO_APB→SYSTEM_UART_0_IO_CTRL`、`SYSTEM_GPIO_0_IO_APB→…`、`SYSTEM_CLINT_CTRL→SYSTEM_MACHINE_TIMER_APB`、`SYSTEM_AXI_A_BMB→BMB` 等映射 |
| `include/print.h` | 13,920 | **mini printf**：只认 `%c %s %d %X %x` |
| `include/print_full.h` | 48,819 | 完整 printf（本工程 `ENABLE_BSP_PRINTF_FULL 0`，未启用） |
| `include/semihosting.h` | 6,023 | `sh_write0/sh_writec/sh_readc`（未使用，编译期警告来源） |
| `include/soc.mk` | 241 | **板级编译选项**（见 §10.2） |
| `linker/default.ld` | 3,896 | 默认链接脚本（`ram` 区 **1 MB**） |
| （另）`linker/{default_i,bootloader,freertos,freertos_i}.ld` | | 备用链接脚本 |
| （另）`openocd/*.cfg`、`ftdi_ti.cfg`、`debug_ti.cfg` | | 下载/调试（`.launch` 里引用） |
| （另）`app/lwip`、`app/fatfs` | | 网络/文件系统（本项目未用） |

### 9.2 共享驱动 `.../standalone/driver/`（`-I${STANDALONE}/driver`）

| 文件 | 字节 | 与 2D demo 的关系 |
|---|---|---|
| `io.h` | 2,426 | `read_u32/write_u32/read_u16/write_u16/read_u8/write_u8` + `readReg_u32/`writeReg_u32` 宏 |
| `type.h` | 2,258 | `u8/u16/u32/u64/int32_t` 等 |
| `uart.h` | 11,097 | `UART_DATA 0x00 / UART_STATUS 0x04 / UART_CLOCK_DIVIDER 0x08 / UART_FRAME_CONFIG 0x0C`、`uart_writeAvailability()`（`>>16 & 0xFF`）、`uart_readOccupancy()`（`>>24`）、`uart_write/uart_read/uart_writeStr/uart_writeHex/uart_applyConfig/uart_TX_emptyInterruptEna/uart_RX_NotemptyInterruptEna` |
| `clint.h` | 5,934 | `CLINT_IPI_ADDR 0x0000 / CLINT_CMP_ADDR 0x4000 / CLINT_TIME_ADDR 0xBFF8`、`clint_getTimeLow/High`、`clint_getTime`、`clint_setCmp`、`clint_uDelay` |
| `vexriscv.h` | 1,924 | `data_cache_invalidate_all() asm(".word(0x500F)")`、`data_cache_invalidate_address(a)`、`instruction_cache_invalidate() fence.i`、`soc_write_buffer_flush()`（CSR 0x810） |
| `riscv.h` | 15,291 | CSR 读写宏、`csr_read/csr_write`、trap 相关 |
| `start.h` | 795 | `extern void smp_unlock(...)` |
| `plic.h` | 8,994 | PLIC 驱动（FinalDemo 未用中断服务程序） |
| `gpio.h` | 6,727 | GPIO（comptest 用按键；FinalDemo 不用） |
| 其他 | | `timer.h / watchdog.h / spi.h / spiFlash.h / i2c.h / dmasg.h / mmc.h / DDRCali_i2c.h / efx_tse_*.h / apb3_cl.h / prescaler.h / device/{emc1413,pcf8523}.h` |

> **注意：`driver/` 里没有任何 `ra_*.h`、`blit*.h`、`dma*.h`、`axi*.h` 形式的 2D 加速器驱动头。** 全部寄存器映射都是各 demo `.c` 内联的 `#define BLT_*`（重复 5 份：FinalDemo / AdDemo / comptest / comptest2 / fulltest+userDef.h）。**这是本软件层最主要的可维护性问题**：同一份寄存器表被复制 5 遍，任何一处遗漏都会造成 RTL/软件不一致。

### 9.3 共享构建与启动 `.../standalone/common/`

| 文件 | 字节 | 作用 |
|---|---|---|
| `start.S` | 1,223 | 启动汇编（每个 makefile 都显式加进 `SRCS`） |
| `start_int.S` | 807 | 中断版启动 |
| `trap.S` | 744 | trap 向量 |
| `smpFunc.S` / `smpInit.S` | 640 / 264 | SMP 支持（`-DSMP` 时用） |
| `syscalls.c` | 1,438 | 最小 syscall stub（`standalone.mk` 显式编译成 `build/obj_files/syscalls.o`） |
| `bsp.mk` | 252 | BSP 路径与 `-I` |
| `riscv64-unknown-elf.mk` | 893 | 工具链前缀 / MARCH / MABI / 优化档 |
| `standalone.mk` | 2,017 | 目标与规则（§10.3） |

---

## 10. Makefile 结构与精确构建命令

### 10.1 每个 demo 的 makefile（以 FinalDemo 为例，326 字节，逐字）

```make
PROJ_NAME=FinalDemo
STANDALONE = ..

SRCS = 	$(wildcard src/*.c) \
		$(wildcard src/*.cpp) \
		$(wildcard src/*.S) \
		${STANDALONE}/common/start.S

include ${STANDALONE}/common/bsp.mk
include ${STANDALONE}/common/riscv64-unknown-elf.mk
include ${STANDALONE}/common/standalone.mk

LDSCRIPT =  ${BSP_PATH}/linker/default.ld
```
差异仅在 `PROJ_NAME`、`STANDALONE`（顶层 demo 为 `..`，`application/*` 为 `../..`）与少量 `CFLAGS`：
- `AdDemo/comptest/comptest2/FBtest/fulltest/FinalDemo`：`STANDALONE = ..`，无额外 CFLAGS。
- `application/fbTest`、`application/memTest`、`application/coremark`、`application/dhrystone`：`STANDALONE=../..`、`CFLAGS+=-DSMP`。

### 10.2 `common/bsp.mk`（252 字节，逐字）

```make
BSP_PATH ?= ${STANDALONE}/../../bsp/${BSP}
LWIP_PATH ?= ${BSP_PATH}/app/lwip
FATFS_PATH ?= ${BSP_PATH}/app/fatfs
CFLAGS += -I${BSP_PATH}/include
CFLAGS += -I${BSP_PATH}/app

include ${BSP_PATH}/include/soc.mk

LDSCRIPT ?= ${BSP_PATH}/linker/default.ld
```
`${BSP}` **必须由命令行/环境提供** —— 展开后 `bsp/` 下一层是 `efinix/EfxSapphireSoc`，所以：

> **`BSP=efinix/EfxSapphireSoc`**

（`doc/logs/build_v216_64x64.txt` 实证：include 解析为 `../../../bsp/efinix/EfxSapphireSoc/include/...`。）

`include/soc.mk`（241 字节，逐字）：

```make
RV_M=yes
#RV_C=yes
#RV_A=yes
#RV_F=yes
#RV_D=yes
#CFLAGS+=-DSMP
DEBUG?=yes
DEBUG_OG?=yes

CFLAGS += -DSYSTEM_UART_A_APB=SYSTEM_UART_0_IO_APB
CFLAGS += -DSYSTEM_GPIO_A_APB=SYSTEM_GPIO_0_IO_APB
CFLAGS += -DSYSTEM_I2C_A_APB=SYSTEM_I2C_0_IO_APB
```
注意：默认 `DEBUG=yes` + `DEBUG_OG=yes` ⇒ `-g3 -Og`。要 `-Os` 需 `make DEBUG=no`；要 `-O3` 用 `make DEBUG=no BENCH=yes`。

### 10.3 `common/riscv64-unknown-elf.mk`（893 字节）要点

```make
RISCV_BIN ?= riscv-none-elf-
RISCV_CC=${RISCV_BIN}gcc
RISCV_OBJCOPY=${RISCV_BIN}objcopy
RISCV_OBJDUMP=${RISCV_BIN}objdump
MARCH := rv32i
MABI := ilp32
BENCH ?= no
... RV_M=yes ⇒ MARCH := rv32im ; RV_F/RV_D/RV_C/RV_A 各档 ...
ifeq ($(DEBUG),yes)
  ifneq ($(DEBUG_OG),yes)  CFLAGS += -g3 -O0
  else                     CFLAGS += -g3 -Og
  endif
endif
ifneq ($(DEBUG),yes)
  ifneq ($(BENCH),yes)     CFLAGS += -Os
  else                     CFLAGS += -O3
  endif
endif
MARCH := $(MARCH)_zicsr_zifencei
CFLAGS  += -march=$(MARCH) -mabi=$(MABI) -DUSE_GP -fcommon
LDFLAGS += -march=$(MARCH) -mabi=$(MABI)
```
本板 `soc.mk` 里 `RV_M=yes` ⇒ 实际 `-march=rv32im_zicsr_zifencei -mabi=ilp32`。

### 10.4 `common/standalone.mk`（2,017 字节）要点 —— **产出 .hex 的就是这里**

```make
OBJDIR ?= build
LDFLAGS += -lc
CFLAGS  += ${CFLAGS_ARGS}
CFLAGS  += -I${STANDALONE}/include      # 该目录在本树中不存在（GCC 对不存在的 -I 无害，静默忽略）
CFLAGS  += -I${STANDALONE}/driver
CFLAGS  += -ffunction-sections -fdata-sections
LDFLAGS += -L${STANDALONE}/common
LDFLAGS += -specs=nosys.specs -lgcc -nostartfiles -ffreestanding \
           -Wl,-Bstatic,-T,$(LDSCRIPT),-Map,$(OBJDIR)/$(PROJ_NAME).map,--print-memory-usage,--no-warn-rwx-segment,--gc-sections -lm

OBJS := $(SRCS) → 去目录 → 换 .o → 前缀 $(OBJDIR)/obj_files/
OBJS += $(OBJDIR)/obj_files/syscalls.o

all: $(OBJDIR)/$(PROJ_NAME).elf $(OBJDIR)/$(PROJ_NAME).hex $(OBJDIR)/$(PROJ_NAME).asm $(OBJDIR)/$(PROJ_NAME).bin

$(OBJDIR)/%.elf: $(OBJS) | $(OBJDIR)
	@$(RISCV_CC) $(CFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)

%.hex: %.elf
	@$(RISCV_OBJCOPY) -O ihex $^ $@
%.bin: %.elf
	@$(RISCV_OBJCOPY) -O binary $^ $@
%.v: %.elf
	@$(RISCV_OBJCOPY) -O verilog $^ $@
%.asm: %.elf
	@$(RISCV_OBJDUMP) -S -d $^ > $@

clean:
	@rm -rf $(OBJDIR)
```
**可用目标只有 `all`（默认）与 `clean`**（外加内建的 `%.hex`/`%.bin`/`%.v`/`%.asm` 中间规则）。产物全部落在 `build/`。

### 10.5 ★精确构建命令（编译 demo → .hex）

工具链：`C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin`（含 `riscv-none-elf-gcc-13.4.0` 等；**当前 PATH 上没有 `riscv-none-elf-gcc`，必须自行加入 PATH 或用 `RISCV_BIN=` 指定**）。

**PowerShell（推荐写法）**：

```powershell
$env:PATH = "C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin;" + $env:PATH
$demo = "C:\2D_Rendering_Acceleration-deprecated-v3.2\2D_Rendering_Acceleration-deprecated-v3.2\ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\FinalDemo"
Push-Location $demo
make BSP=efinix/EfxSapphireSoc            # → build\FinalDemo.hex / .elf / .bin / .asm / .map
Pop-Location
```

**cmd.exe 等价写法**：

```bat
set PATH=C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin;%PATH%
cd /d C:\2D_Rendering_Acceleration-deprecated-v3.2\2D_Rendering_Acceleration-deprecated-v3.2\ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\FinalDemo
make BSP=efinix/EfxSapphireSoc
```

**不要 PATH 时指定前缀**：

```powershell
make BSP=efinix/EfxSapphireSoc RISCV_BIN=C:/Efinity/efinity-riscv-ide-2026.1/toolchain/bin/riscv-none-elf-
```

**其它 demo**（只需把工程目录换掉，`PROJ_NAME` 由各自 makefile 给出）：

```powershell
make BSP=efinix/EfxSapphireSoc   # ...\standalone\AdDemo        → build\AdDemo.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\comptest      → build\comptest.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\comptest2     → build\comptest2.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\FBtest        → build\FBtest.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\fulltest      → build\fulltest.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\application\fbTest  → build\fbTest.hex
make BSP=efinix/EfxSapphireSoc   # ...\standalone\application\memTest → build\memTest.hex
```

**只重建某一种产物**（利用内建模式规则）：

```powershell
make BSP=efinix/EfxSapphireSoc build/FinalDemo.hex
make BSP=efinix/EfxSapphireSoc build/FinalDemo.elf
```

**清理（改编译开关后必须做）**：

```powershell
make BSP=efinix/EfxSapphireSoc clean
```
`firmware/README.md` 原话：「改开关后必须 Clean 再 Build（**make 不跟踪编译选项变化**）。各工程 `build\<名>.hex` 才是 IDE 直接烧的那个。」

**FinalDemo 的三个开关**（默认值就写在 `FinalDemo.c:208-238`，用 `#ifndef` 包着 ⇒ 可用 `-D` 覆盖；`standalone.mk` 里有 `CFLAGS += ${CFLAGS_ARGS}` 这个入口）：

```powershell
# 例：退回"整屏 COPY 上屏 + 双缓冲"（等价 V2.0 行为，新旧位流都能跑）
make BSP=efinix/EfxSapphireSoc clean
make BSP=efinix/EfxSapphireSoc CFLAGS_ARGS="-DFB_FLIP_PUBLISH=0 -DFB_TRIPLE_BUFFER=0 -DFB_IRQ_PACING=0"
```

**可选优化档**：

```powershell
make BSP=efinix/EfxSapphireSoc DEBUG=no            # -Os（默认是 -g3 -Og）
make BSP=efinix/EfxSapphireSoc DEBUG=no BENCH=yes  # -O3
```

**烧写/打包（不是 make 目标）**：
- IDE 直接烧 `build\<名>.hex`；`.launch` 里 `PROGRAM_NAME = ./build/FinalDemo.elf`，OpenOCD 配置为
  `<BSP_PATH>/openocd/ftdi_ti.cfg` + `<BSP_PATH>/openocd/debug_ti.cfg`；另有 `_trion`、`_tz` 两套变体。
- 需要"位流 + 应用"合一镜像时用：
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\make_soc_image.ps1 `
      -BitstreamHex firmware\v3.2\ddr_demo_ti60_v3.2.hex `
      -AppBin       firmware\v3.2\AdDemo_v3.2.bin `
      -Out          firmware\v3.2\AdDemo_v3.2_soc.hex
  ```
  该脚本按 bootloader 约定把 **应用 .bin 放在 flash 偏移 `0x00380000`**（`USER_SOFTWARE_SIZE 0x01F000`），位流在 `0x00000000`；**输入是 `.bin` 而不是 `.hex`**。

### 10.6 构建产物与内存占用实证

`doc/logs/build_v216_64x64.txt`（FinalDemo，成功）：

```
CC src/FinalDemo.c
LD FinalDemo
Memory region         Used Size  Region Size  %age Used
             ram:      271264 B         1 MB     25.87%
```
`doc/logs/build_AdDemo.txt`：`ram: 109040 B / 1 MB = 10.40%`。
两处均伴随 BSP 头文件的既有告警（`semihosting.h` 注释内 `/*`、`print.h` 的 `digi` 未用、`clint.h`/`uart.h` 若干 `static` 函数未用）—— **这些是预期噪声，不是本次构建失败**。默认 `-Wall` 未显式打开，但 BSP 头里的 `static` 函数未用告警仍然出现。

---

## 11. 关键坑位清单（读 FinalDemo 得到的"改动前必读"）

1. **未对齐 32bit store 会静默停死**（RISC-V 未对齐异常）：奇数 `x` 必须用 16bit 收头/收尾（`cpu_fill32`）；`scene_step` 里不能 `x &= ~1`。
2. **FIFO 满时写 `BLT_CMD_FIFO_DATA(0x08)` 会把 CPU 挂在 AXI-Lite 上**：必须先 `blt_push_room()`（上限 200 条，FIFO 深 256 条）。
3. **一条引擎指令 = 8 次无条件 store**，不能在中途被打断；边界检查必须前置。
4. **ALPHA 不擦会逐帧变暗**（`dest = blend(src,dest)` 叠加）；`clear_pp=0` 时 ALPHA 每块都要"擦 + 画"成对下发。
5. **DFU BUSY 期间 `0x4C~0x88` 写入被静默丢弃** ⇒ arm 前等 idle、写完逐项读回校验。
6. **`DL_CTRL` 的 `AUTO_GO`/`STRICT` 复位为 1** ⇒ 每次写都要写回 1。
7. **`DL_STATUS.STALL` 是组合位**，出错后必然读到 0 ⇒ 必须在表在飞期间轮询时**粘住**（`g_dl_stall_seen`）。
8. **`DL_PERF` 只在 S_END/S_ERR/S_ABORT 等引擎 done_out 之后才写入** ⇒ 出错那一刻读到的是上一张表的值，本表真实值要等 `BUSY=0` 后补打 post-mortem。
9. **`CMD_FIFO_COUNT` 单位是指令条数 = 字数/8**；`COUNT==0` 不代表字级 FIFO 空（可能剩 1..7 个字），判空要同时看 `STATUS.FIFO_EMPTY`。
10. **`print.h` 是 mini 版**：只认 `%c %s %d %X %x`，`%u`/宽度/`%%` 会错位 `va_arg` 并挂死。
11. **不要用 `csr_read(mcycle)` 做时间基**（本 SoC 上会触发非法指令异常），一律用 CLINT mtime。
12. **CPU 写完 DDR 后引擎要读** ⇒ `cache_evict()`（8KB 写穿屏障），**不是** `data_cache_invalidate_all()`；D$ tag 无 dirty 位（写穿）。
13. **信息条必须落在"当前后台缓冲"里**（FLIP 路径用 `g_bar_ok[]` 跟踪），且只在"上屏不在飞"时重画。
14. **列表路径出错的自动重试必须有三条硬上界**（`DL_RETRY_MAX=1` + 1s 窗口内第二次事件即停用 + 重试自身失败即停用），否则会退化成"同一帧里反复重画整趟"的永久重试环、帧率当场崩塌。

---

## 12. 快速索引

| 想找什么 | 去哪里 |
|---|---|
| 2D 加速器寄存器宏 | `FinalDemo/src/FinalDemo.c:89-191`（最全）；`fulltest/src/userDef.h:78+`；`AdDemo/src/AdDemo.c:141+` |
| 引擎指令编码 | `FinalDemo.c:500-572`（`blt_emit` / `blt_fill` / `blt_alpha` / `blt_key` / `blt_copy_full`） |
| 显示列表（描述符/几何表） | `FinalDemo.c:1136-1212`（规格注释）、`1213-1337`（编码）、`1339-1849`（arm/go/错误处理/成本） |
| 三缓冲 + 清屏引擎 | `FinalDemo.c:102-131`（寄存器）、`455-490`（`clr_start` / `hw_pass_arm`）、`2245-2271`（轮转） |
| 主循环 | `FinalDemo.c:2025-2838` |
| 串口命令 | `FinalDemo.c:957-1027`（底层 + `=N` 行缓冲）、`2032-2168`（命令分支） |
| 场景 / 路径 / 尺寸 | `FinalDemo.c:325-377`、`1029-1134`、`1869-1877`、`2075-2104` |
| OSD / 字体 | `FinalDemo.c:760-955` |
| RTL 寄存器读回交叉验证 | `rtl/blt_regs_axi_lite.v:757-816`（读译码）、`:560-680`（写译码） |
| 板级编译选项 | `soc/bsp/efinix/EfxSapphireSoc/include/soc.mk` |
| 外设基址 | `soc/bsp/efinix/EfxSapphireSoc/include/soc.h` |
| 构建日志实证 | `doc/logs/build_v216_64x64.txt`、`doc/logs/build_AdDemo.txt` |
| 固件留档与开关说明 | `firmware/README.md` |
| 位流+应用合成脚本 | `tools/make_soc_image.ps1` |
