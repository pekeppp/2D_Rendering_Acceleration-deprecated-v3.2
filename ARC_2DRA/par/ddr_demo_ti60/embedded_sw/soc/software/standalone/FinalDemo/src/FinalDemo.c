/* =============================================================================
 * FinalDemo.c — 最终演示：硬件加速渲染 vs 纯 CPU 渲染（同屏实时对比）
 * -----------------------------------------------------------------------------
 * 由 comptest2.c 精简而来：去掉全部调试/实验开关（围栏 f、预拷等待 g、冻结 m、
 * 像素回读 d、周期诊断 dbg_quick、OSD 读数 osd_fill），保留已经上板验证过的内核。
 *
 * ★ 屏幕布局（帧缓冲 960x540，双缓冲：后台 FB_BACK --整帧COPY--> 显示 FB_BASE）：
 *      y   0 ..  16   信息条（**在渲染区之外**：每趟的区域重铺不会碰它）
 *                      左：HW=nnn CPU=nnn SCR=nn N=nnnn SCn=FILL A=nnn [E] [FR]
 *                          （HW/CPU = 每侧**渲染趟率**；★ SCR = **真正上屏的帧率**
 *                            = 整帧 COPY 的完成次数/秒 —— 屏幕实际流畅度只看这个数，
 *                            它被 1.92M 周期的整帧 COPY 硬顶在 ~52fps；
 *                            + **人读得懂的场景名** + 两个模式标记）
 *                      右：路径标签 SPLIT / HW ONLY / CPU ONLY（右对齐，x=960-8*字符数）
 *      y  16 .. 276   上半：**硬件加速器**渲染（引擎 FILL/ALPHA/KEY 指令）
 *      y 276 .. 280   分隔条（CPU 画，仅 SPLIT 模式）
 *      y 280 .. 540   下半：**纯 CPU** 渲染（CPU 直写像素）
 *
 * ★ 启动默认值：
 *      path      = PATH_HW      纯硬件整屏
 *      clear_pp  = 1            每趟整片重铺背景（不再逐块擦旧矩形）
 *      frame_adv = 0            场景按**墙钟时间**推进（SCENE_TICKS，25 步/秒）
 *      scene     = FILL, N = 25, alpha = 128
 *      blk       = 16x16        ★ 三个场景**统一**几何，且**运行时可循环切 16 / 32 / 64**
 *                                 （串口键 'k'，循环顺序 16 → 32 → 64 → 16）：
 *                                 FILL 的方块边长、ALPHA/KEY 的图集精灵
 *                                 （SPR_W/SPR_H/SPR_STRIDE）全部从变量 g_blk 导出
 *                                 ⇒ 全工程只有一处方块尺寸**来源**（不再有编译期常量），
 *                                 三个合法值也只有一处枚举（g_blk_tab/blk_next()）
 *
 * ★ 三条关键设计（都是上板踩坑换来的，改动前务必读）：
 *   1) **不需要屏外缓冲、不需要整屏 COPY**：两侧各画自己那一半。早期版本
 *      "CPU 一写显示缓冲就整机卡死"的真因是**未对齐 32bit 存储**
 *      （`scene_step` 把 x 变成奇数），与写哪块缓冲无关；现已修正并加了开机自检。
 *   2) **同一个场景**：两侧用同一颗种子初始化、同一套推进规则 ⇒ 目标坐标逐位相同；
 *      差异只体现在"谁跟得上"（帧率/流畅度）。
 *   3) **每侧各有自己的"上次画在哪"(dx,dy)**，且一趟之内用快照 (tx,ty) 恒定位置：
 *      某一侧慢很多、落后好几步也不会擦错地方、不会拖影。
 *      ★ 本版把"拍快照"挪到**每趟的起点**（旧版是"上一趟结束时"拍 + 时间模式每步
 *        再拍一次，而那个时刻另一趟可能正在飞 ⇒ 同一趟里前后块的 tx,ty 不一致）。
 *        现在一趟内 tx,ty 恒定，dx/dy 记账与"画在哪"严格一一对应。
 *
 * ★ 每趟重铺（clear_pp=1，硬件侧）：先把整片渲染区铺成背景色，再画 N 个块，
 *   **不发任何"擦旧矩形"指令**。这是上板验证过的模式：既消掉 2~3px 的黑色拖尾，
 *   也消掉 KEY 场景四角的闪烁。CPU 侧**保持 comptest2 的"先擦后画"语义不变**，
 *   这样 CPU-vs-HW 的帧率对比才是诚实的。
 *
 * ★ 主循环节流（本版重点，性能相关，改动前先读）：
 *   1) 串口 RX / 时间戳 / 场景推进 / 1Hz 统计 全部收进"**每 32 圈一次**"的慢时间片
 *      （SLOW_MASK）——旧版每圈都做，光 OSD 门控那三个 tick() 就是 9 次外设读/圈；
 *   2) 时间基改用 CLINT mtime **低 32 位**（tick32）：1 次总线读，而不是
 *      clint_getTime() 的 hi/lo/hi 三次（本程序所有时间量都是 ≤1s 的差值，回绕安全）；
 *   3) BLT_STATUS / CMD_FIFO_COUNT **每圈最多各读一次**，状态字在同圈内复用；
 *      FIFO 余量一次读出后在圈内自己递减记账（只会更保守，绝不会写满挂死）；
 *   4) 整帧 COPY 在飞的 ~19ms 窗口：先做"下一趟要用的活"（场景快照 + 到点的
 *      1Hz 统计/组串），再**纯 ALU 有界退避**（不产生任何总线事务），每 4 圈才
 *      问一次引擎状态；纯硬件模式下"等本趟画完"同样退避（SPLIT/CPU 模式下不退避，
 *      因为下面 CPU 段每圈都要画一块，退避会拖慢 CPU 侧的诚实工作量）；
 *   5) 信息条**事件驱动**：只有 fps/N/场景/路径/α/模式标记真的变了才重画，
 *      而且只在 COPY 不在飞时重画（旧版按固定帧节拍重画，且可能与在飞的 COPY
 *      抢同一块 DDR ⇒ 偶尔拍到"半张信息条"）；
 *   6) 周期性串口状态行（S it=... 每秒一行）**整条删除**：它是纯轮询式打印，
 *      115200 波特下 ~106 字节/秒 = 9.2ms/秒 的串口时间，其中大部分是 CPU 卡在
 *      uart_write() 的 `while(uart_writeAvailability==0)` 里空转。fps 读数只走屏幕。
 *      按键回声（EV ...）保留：只在真的有键到达时打一行，不影响稳态。
 *      ★ 本版新增的 SCR=（真正上屏帧率）**同样只走屏幕**，没有恢复任何周期打印。
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
#define FB_BUF2       (DDR_BASE + 0x00700000UL)    /* ★ 第三块缓冲（三缓冲 FLIP 用） */
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
/* ★ FLIP（v2.6 新增，见 rtl/功能清单.md §20）：
 *   FB_SEL (0x24, W) : ★v2.7 [1:0] = 希望扫描输出显示哪块缓冲（0=FB_BASE 1=FB_BACK 2=FB_BUF2）。
 *                      写下去只是**请求**，扫描输出在下一个帧边界（垂直消隐起点）才锁存它。
 *   FB_STAT(0x28, R) : [1:0]   = **已经生效**的显示缓冲选择
 *                      [31:16] = 扫描输出场计数（每个帧边界 +1，@60Hz 约 1092 秒回绕）
 * ★v2.7 三缓冲 + 并发清屏引擎（详见 rtl/功能清单.md §21）：
 *   0x2C CLR_ADDR   W  清屏起始字节地址      0x40 CLR_STAT R bit0=BUSY bit1=目标已清干净
 *   0x30 CLR_STRIDE W  字节/行                          [5:2]=四块缓冲 clean 位图
 *   0x34 CLR_WH     W  (h<<16)|w                        bit6=ERR(互斥拒绝/运行中被抢, sticky)
 *   0x38 CLR_COLOR  W  RGB565 背景色                    [31:16]=上一次 clear 的 AW 突发数
 *   0x3C CLR_CTRL   W  bit0=GO(1 拍) [3:2]=目标缓冲  0x44 DRAW_SEL  W [1:0]=引擎正在画的缓冲
 *                      bit4=ERR_CLR(1 拍)             0x48 CLR_CYC   R 上次 clear 的周期数
 *   ★ 硬件互斥：清屏目标 == 正在显示的缓冲 或 == DRAW_SEL（正在画的缓冲）⇒ 一个像素都不写，
 *     置 ERR。所以"清屏永远不会破坏正在上屏的缓冲"是**硬件保证**，不依赖软件正确性。 */
#define   BLT_IRQ_FRAME     (1UL << 1)     /* ★v2.7：扫描输出帧边界中断（0x10 W1C / 0x14 使能） */
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

/* ★v2.11 显示列表 / 描述符表（DFU 取指器，见 rtl/dl_fetch.v + rtl/功能清单.md §25）：
 *   0x4C DL_BASE0/0x50 DL_BASE1  列表 A/B 基地址（[31:4]，16B 对齐）
 *   0x54 DL_COUNT               本列表描述符条数（≤4095；0 = 合法空列表）
 *   0x58 DL_CTRL                bit0=GO(1 拍) bit1=ABORT bit2=BUF_SEL bit3=IRQ_EN
 *                               ★bit4=AUTO_GO / bit5=STRICT_BOUNDS 是 RW 且**复位为 1**
 *                               ⇒ 每次写 DL_CTRL 都要把这俩一起写回 1，写 0 就把它们关了。
 *   0x5C DL_STATUS              bit0=BUSY bit1=DONE(电平) bit2=ERR bit3=ABORTED bit4=STALL
 *                               [9:8]=ACTIVE_BUF [31:16]=CONSUMED
 *   0x60 DL_ERR                 W1C：[7:0]=错误位 [23:16]=序号 [24]=UNSUPPORTED
 *   0x64 DL_FAULT_ADDR / 0x68 GEOM_BASE / 0x6C GEOM_MAX / 0x70 DST_BASE
 *   0x74 DL_CFG / 0x78 TIMEOUT / 0x7C PERF / 0x80 VERSION / 0x84 DST_STRIDE / 0x88 FB_WH
 *   0x10/0x14 追加 bit2 = DL_DONE（本轮用轮询，不开中断） */
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

/* ★v2.14 显示列表看门狗 DL_TIMEOUT(0x78) —— 单位/复位值/放哪儿都要对着 RTL 抄，不能凭感觉调：
 *   rtl/blt_regs_axi_lite.v:392（复位 16'd4096）、:499（`if (ws[0] && !dl_busy)` 才写得进）、
 *   :620（读回 {16'd0, dl_timeout}）；rtl/dl_fetch.v:358（判据）、:459-462（计数）、
 *   :491（GO 那一拍采样）；rtl/功能清单.md §25 寄存器表。
 *   语义：[15:0] = **单条描述符**的看门狗，单位是 **core 拍**（不是 us/ms），**0 = 关**。
 *   计数器在"描述符已取到手、准备展开"（S_HEAD 且 df 非空）时清零；此后只要状态机还停在
 *   非终态（S_CHUNK 等描述符回程 / S_GEOM 等几何表 / S_FILL / S_PUSH 等 FIFO 让位 /
 *   S_DRAIN 等读通道真空）就一直累加，`wd_cnt >= s_timeout` 且确实卡在这些等待上
 *   ⇒ 报 DL_ERR.WATCHDOG(0x10)，并带上出错序号 idx 与 FAULT_ADDR。
 *   复位 4096 拍 ≈ 47µs@87MHz（§25 的口径）—— 对"精灵正在读图集、desc/几何表还要和
 *   fg/bg 抢 DDR"的列表路径**太短**：板上场景 2(ALPHA) 跑到第 ~20 条描述符就报看门狗。
 *   本版显式把它编程到字段上界 0xFFFF = 65535 拍 ≈ 753µs@87MHz（= 16×4096-1）：
 *   这个值依然**有界** —— 取指再慢也不该慢过 0.75ms，超过就是真死了 ⇒ 当场就能把
 *   "慢但有界（带宽争用，靠调 CHUNK/FIFO_WM/仲裁能治）"与"永不完成（饿死，要改 RTL）"分开。 */
#define DL_TIMEOUT_RESET    4096         /* RTL 复位值（core 拍） */
#define DL_TIMEOUT_TICKS    0xFFFFu      /* 本版显式编程值 = [15:0] 字段上界 */
#define DL_TIMEOUT_X        16           /* 相对复位值的倍数（仅打印用；16×4096 = 65536） */

/* ============================== 上屏方式（编译期开关） ==============================
 * ★ FB_FLIP_PUBLISH 默认 **0 = 关**：上屏仍然走"整屏 COPY"这条已经上板验证过的路径，
 *   现在的 bitstream 一行都不用重综合也照样跑。
 *   编译期加 -DFB_FLIP_PUBLISH=1 才切到 **FLIP 路径**：
 *     · 一趟渲染进"非显示"的那块缓冲（后台缓冲随翻转在 FB_BASE/FB_BACK 间换）；
 *     · 本趟画完 → 写 FB_SEL(0x24) 请求翻到它；
 *     · 轮询 FB_STAT(0x28) 等"已生效选择"变成它（**有界超时** 100ms；超时就重发请求
 *       继续等 —— 绝不在"可能正在上屏"的缓冲里画，宁可让画面停一帧也不撕裂）；
 *     · 确认的那一刻 = 这一帧真的上屏了 → scr_frames++（与 COPY 路径同一个口径）。
 *
 *   为什么值得：板级实测整帧 COPY（960x540 RGB565）≈ 707k core 周期 = 7.1ms，
 *   占 60Hz 帧预算（1.667M 周期）的 42%；FLIP 只是换一个显示基址 —— 写 1 个寄存器、
 *   等一个帧边界，**一次 DDR 搬运都不做**。省下的时间全部变成内容预算（约 2.8 倍）。
 *   代价：显示缓冲只有两块（本来就是双缓冲），翻转最多延后一场生效。
 *   ★ 开关只改"怎么把后台缓冲送上屏"：渲染、场景推进、信息条、串口行为完全不变。 */
#ifndef FB_FLIP_PUBLISH
#define FB_FLIP_PUBLISH 1
#endif

/* ============================== ★v2.7 两个新开关（都默认关 = 行为与上板验证过的那版一致） ==============================
 * ① FB_TRIPLE_BUFFER（默认 **0 = 关**）
 *    只在 FB_FLIP_PUBLISH=1 时才有意义。开（-DFB_TRIPLE_BUFFER=1）之后：
 *      · 用**三块**缓冲轮转：显示 A / 画 B / 预清 C（FB_BASE、FB_BACK、FB_BUF2）；
 *      · 硬件"并发清屏引擎"（0x2C~0x48）在后台把 C 的渲染区铺成背景色，
 *        所以那 568k 周期的整片重铺**不再进关键路径**；
 *      · 每趟开画前检查目标缓冲的 clean 位（CLR_STAT[5:2]）：
 *          干净  → 本趟不发命令式清屏（省下 568k 周期）；
 *          不干净→ **退回改动前那条命令式区域清屏**（FILL 整片），语义与老版本逐位相同；
 *        有界等待（CLR_WAIT_TICKS）绝不会无限等，**也绝不会往可能正在上屏的缓冲里画**。
 *      · 每次开画前写 DRAW_SEL = 本趟要画的那块 ⇒ 硬件互斥的另一半生效
 *        （清屏引擎的目标 == 正在画的那块 ⇒ 拒绝写）。
 * ② FB_IRQ_PACING（默认 **0 = 关**）
 *    只在 FB_FLIP_PUBLISH=1 时才有意义。开（-DFB_IRQ_PACING=1）之后：
 *      · 翻转确认不再"无条件轮询 FB_STAT"，而是先开 IRQ_EN[1]（帧边界中断），
 *        等 IRQ_STATUS[1]（W1C）置位 —— 即**由扫描输出的帧边界事件驱动**，
 *        每来一个场边界才读一次 FB_STAT 确认一次（把"等一帧"这件事交给硬件节拍）。
 *      · 使能方式：编译期 `-DFB_IRQ_PACING=1`（可同时给 -DFB_TRIPLE_BUFFER=1）。
 *      · RTL 侧已经把中断线接到 SoC 的 `userInterruptA`（PLIC 源，claim ID 0x10）；
 *        要变成"真正的中断服务程序"还需软件自己配 PLIC + 装 trap 向量 ——
 *        **本开关没有做这一步**，它用的是同一个事件源的电平/W1C 状态（不依赖 trap）。 */
#ifndef FB_TRIPLE_BUFFER
#define FB_TRIPLE_BUFFER 1
#endif
#ifndef FB_IRQ_PACING
#define FB_IRQ_PACING 1
#endif

/* 当前**后台缓冲**（CPU 与引擎都画在这里）。
 * COPY 路径下它恒为 FB_BACK（与改动前逐字节等价）；FLIP 路径下随翻转切换。 */
static uint32_t g_fb_back = FB_BACK;

#if FB_FLIP_PUBLISH
/* ---- FLIP 路径专用状态（开关关掉时全部不参与编译，避免 -Wall 的 unused 告警）---- */
#define FLIP_TIMEOUT_TICKS  (BSP_CLINT_HZ / 10u)   /* 有界等待：100ms ≈ 6 场 @60Hz */
#define FB_SEL_STAT_SEL(v)  ((uint32_t)(v) & 3UL)  /* ★v2.7：选择字段变成 2 bit */
/* 缓冲块数：三缓冲开关打开时 3，否则 2（与 v2.6 完全一致） */
#if FB_TRIPLE_BUFFER
#define FB_NBUF             3
#else
#define FB_NBUF             2
#endif
static uint32_t g_disp_sel  = 0;      /* 已确认在屏的缓冲（0=FB_BASE 1=FB_BACK 2=FB_BUF2） */
static uint32_t g_flip_req  = 0;      /* 已写下、还没确认的请求 */
static uint32_t g_flip_to   = 0;      /* 有界等待超时次数（正常恒 0） */
static uint8_t  g_bar_ok[3] = {0, 0, 0}; /* 信息条是否已经画进 buf[0]/[1]/[2] */
/* 注：fb_of_sel()/fb_stat_sel() 两个小函数的定义放在 blt_rd() 之后（见下）——
 *     它们要用 blt_rd()，本工程是 C99，不能隐式声明。 */
#if FB_TRIPLE_BUFFER
/* ★v2.7 三缓冲轮转状态：disp=正在显示 / draw=本趟要画 / clr=交给清屏引擎预清的那块 */
#define CLR_WAIT_TICKS      (BSP_CLINT_HZ / 100u)  /* 清屏引擎的有界等待：10ms（实测整片清 ≈2.1ms） */
static int      g_draw3   = -1;       /* 本趟绘制目标（0..2），-1 = 还没选 */
static int      g_clr3    = -1;       /* 交给清屏引擎预清的那块（0..2） */
static int      g_clr_need = 0;       /* 1 = 本趟开始时要给清屏引擎下一条清屏命令 */
static int      g_pass_armed = 0;     /* 本趟是否已经做过"查 clean + 选目标 + 下清屏命令" */
static uint32_t g_clr_fb  = 0;        /* clean 不干净 → 退回命令式整片清屏的次数 */
static uint32_t g_clr_to  = 0;        /* 等清屏引擎超时次数（正常恒 0） */
static uint32_t g_clr_err = 0;        /* 硬件互斥拒绝/打断次数（正常恒 0；>0 说明软件违约过） */
#endif
#endif
/* ★ 尺寸切换（串口键 'k'）后的"补重铺"轮数：FLIP 路径下缓冲是轮转的，
 *   切换的那一刻只来得及重铺**当前**正在画的那一块，另外两块里还是**旧尺寸**的方块
 *   （清屏引擎只清硬件渲染区，CPU 半区没人管）⇒ 接下来 (FB_NBUF-1) 次成功翻转后
 *   再各强制重铺一次，轮转一圈正好覆盖全部缓冲。
 *   它只多置一个"重铺请求"，发布/翻转/清屏协议本身一位都没有改。
 *   COPY 路径（FB_FLIP_PUBLISH=0）只往同一个后台缓冲里画，不存在轮转残留 ⇒ 0。 */
#if FB_FLIP_PUBLISH
#define SIZE_REPAINT_ROUNDS (FB_NBUF - 1)      /* 三缓冲=2，双缓冲=1 */
#else
#define SIZE_REPAINT_ROUNDS 0
#endif
/* ★ CMD_FIFO_COUNT 的单位是**指令条数**（rtl/cmd_fifo.v: cmd_count = word_count/8），
 *   FIFO 共 256 条 = 2048 字。这里的 256 就是"条数深度"，与驱动侧的用法一致。 */
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

/* OSD 字体：8x8 字模，osd_text 每字符前进 8 像素 ⇒ 字形宽 8、高 8。
 * 信息条高 OSD_H = 16，文字画在 y = 4..11，完全落在 y < 16 的黑条里。 */
#define OSD_GLYPH_W  8
#define OSD_GLYPH_H  8
#define OSD_TEXT_Y   4
#define OSD_TEXT_X0  8
/* ★ 信息条宽度上界（**静态可证**，见 fmt_stat 注释）：
 *   左串最长 55 字符 = 440px（加了 " SZ=64" 之后；SZ 恒两位 ⇒ 16/32/64 同宽）；
 *   右标签最长 "CPU ONLY" = 8 字符 = 64px。
 *   重画时只清这两块黑底（不再整条 960px 铺黑），也保证不会留残字。
 *   ★ OSD_LEFT_CH 取 64（=512px 黑底）而最长串只用 55（=440px）⇒ 留 9 个字符位余量，
 *     以后再加字段也不会溢出黑底；右标签最小 x = 960-64 = 896 仍远离 8+512 = 520。 */
#define OSD_LEFT_CH  64
#define OSD_LEFT_PX  (OSD_GLYPH_W * OSD_LEFT_CH)
#define OSD_RIGHT_PX (OSD_GLYPH_W * 8)

#define COL_BG        0x0008u                     /* 场景背景（近黑） */

#define COL_OSD_BG    0x0000u
#define COL_HW_FG     0xFFE0u                    /* 黄：硬件侧 */
#define COL_CPU_FG    0x07FFu                    /* 青：CPU 侧 */
#define COL_SEP       0x4208u
#define COL_WHITE     0xFFFFu
#define KEY_COLOR     0xF81Fu                    /* 色键（洋红）：精灵四角用它 */

/* ============================== 场景 ============================== */
#define N_MIN   25
#define N_STEP  25
#define N_MAX   6000
#define MAXBLK  N_MAX

/* ★ 统一方块几何：**运行时可在 16x16 / 32x32 / 64x64 之间循环切换**（串口键 'k'，见 main）。
 *   ★ 唯一来源就是**变量 g_blk**（= 方块边长 = 精灵边长，正方形）。下面所有用到尺寸的
 *     地方都从它导出，不存在第二处硬编码的方块尺寸：
 *       · FILL 的方块边长        = BLK_W/BLK_H（scene_init 写进 b->sz）
 *       · ALPHA/KEY 的图集精灵   = SPR_W/SPR_H/SPR_STRIDE（同样由 g_blk 导出）
 *       · HW/CPU 两侧"擦旧矩形"  = b->sz（就是画过的那一块，同一个值）
 *       · scene_step 的边界钳位  = w = b->sz ⇒ 方块永远留在自己的渲染区里
 *       · build_atlas()/spr_color() 与 CPU 参考实现 cpu_alpha_sprite/cpu_key_sprite
 *         都按**当前** g_blk 逐像素生成/取数 ⇒ 三种尺寸下 CPU 与加速器逐像素一致
 *   ★ BLK_W/BLK_H/SPR_* 这几个名字**原样保留**，但它们现在是"跟着 g_blk 走的运行期
 *     表达式"而不是编译期常量：切尺寸只改 g_blk 一处，消费者一行都不用动。
 *   ★ g_blk = 16 时所有表达式的值与改造前**逐位相同**（旧版 FILL 是 16/24/32 混排、
 *     ALPHA/KEY 固定 32x32，三个场景口径不一致；现在三个场景共用同一个值）。
 *   ★ 切换时必须重建图集（build_atlas）并重铺两侧，否则残留旧尺寸像素 —— 见 'k' 命令。
 *   ★ 三个合法值与循环顺序**只有下面这一处枚举**（BLK_MID 是本版新增的中间档）：
 *     几何表 SPR_ID（dl_spr_id）、信息条 SZ=、帮助文本全部从 g_blk_tab 导出。
 *     64x64 的合法性边界（都在 RTL 里查过，见各消费点的注释）：
 *       · FILL 走 SIZE_OVR ⇒ W_OVR/H_OVR 是 **8 bit**，64 ≤ 255 ✓（b->sz 也是 uint8_t）；
 *       · ALPHA/KEY 走几何表 ⇒ W/H 是 16 bit 字段、行距 128 B ≤ 65535 ✓。 */
/* ==== BLK_CYCLE_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
#define BLK_LO   16                      /* 'k' 的循环顺序：16 → 32 → 64 → 16 */
#define BLK_MID  32
#define BLK_HI   64
#define BLK_N    3
static const int g_blk_tab[BLK_N] = { BLK_LO, BLK_MID, BLK_HI };
static int g_blk = BLK_LO;               /* ★ 唯一边长来源：方块 = 精灵 = g_blk */

/* 尺寸 → 下标（0/1/2，几何表的"第几档"就按它排）；不在表里按 0 处理（防御性，表里只有三个合法值） */
static int blk_idx(int sz) { int i; for (i = 0; i < BLK_N; i++) if (g_blk_tab[i] == sz) return i; return 0; }
/* 'k' 的下一步：16 → 32 → 64 → 16（绕回最小档） */
static int blk_next(int sz) { return g_blk_tab[(blk_idx(sz) + 1) % BLK_N]; }
/* ==== BLK_CYCLE_END ==== */

#define BLK_W   g_blk
#define BLK_H   g_blk

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
    int16_t  tx, ty;    /* ★ 本趟的快照：一趟渲染期间位置恒定不变 ——
                         *   这是消除尾迹的关键。场景推进时如果允许它在一趟
                         *   渲染中间改变位置，同一趟里有的块用旧位置、有的用新位置，
                         *   dx/dy 记账就不再自洽 ⇒ 有位置被画过却再没人擦 ⇒ 沿路径
                         *   一串残影（且越是慢的一侧越稠密）。
                         *   本版把快照点定在**每趟起点**（见 main 的渲染段），
                         *   所以一趟内 tx,ty 绝不会变。 */
    uint16_t color;
    uint8_t  sz;
} blk_t;

static blk_t    g_sc[NSIDE][MAXBLK];
static uint32_t g_seed = 0x12345678u;

/* ============================== 基础原语 ============================== */

/* ★ 时间基：只用 CLINT mtime 的**低 32 位**。
 *   @100MHz 低 32 位 42.9s 回绕，而本程序所有时间量都是"两个时间戳之差"且窗口
 *   ≤1s，无符号减法天然跨回绕正确 ⇒ 低 32 位完全够用。
 *   而 clint_getTime() 要读 hi/lo/hi 三个寄存器 = **3 次外设总线事务**，这里 1 次。 */
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }

/* 有界退避：**纯寄存器空转**，不读任何外设、不碰任何内存 ⇒ 不产生一次总线事务
 * （在"整帧 COPY 正在吃 DDR 带宽"的窗口里，这一点比省 CPU 更重要）。
 * 用自写 asm 循环：编译器既不能删掉、也不会展开，n 的周期数可预期
 * （每圈 3 条指令 ≈ 3~4 周期，n=48 ⇒ ≈150~190 周期 ≈ 1.5~1.9us @100MHz）。 */
static void cpu_backoff(uint32_t n)
{
    if (n == 0u) return;
    __asm__ __volatile__ (
        "1:\n\t"
        "addi %0, %0, -1\n\t"
        "bnez %0, 1b\n\t"
        : "+r"(n));
}

static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }

#if FB_FLIP_PUBLISH
/* ---- FLIP 路径的两个小工具（定义点必须在 blt_rd 之后）---- */
/* 缓冲号 → 字节基址（三块都在 DDR 里，互不重叠；与 RTL 侧 FB_BASE/FB_BASE1/FB_BASE2 一致） */
static uint32_t fb_of_sel(uint32_t s)
{
#if FB_TRIPLE_BUFFER
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
#else
    return s ? FB_BACK : FB_BASE;
#endif
}
/* FB_STAT(0x28) [1:0] = 扫描输出**已经生效**的显示缓冲选择 */
static uint32_t fb_stat_sel(void) { return FB_SEL_STAT_SEL(blt_rd(BLT_FB_STAT)); }
#if FB_TRIPLE_BUFFER
/* ---- ★v2.7 清屏引擎（0x2C~0x48）小工具 ---- */
static uint32_t clr_stat(void)  { return blt_rd(BLT_CLR_STAT); }
static int      clr_busy(void)  { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
/* 目标缓冲是否"已经清成背景色"（CLR_STAT[5:2] 位图，硬件维护） */
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }
/* 有界等待清屏引擎空闲：超时返回 0（调用方据此退回命令式清屏，绝不无限等） */
static int clr_wait_idle(void)
{
    uint32_t t0 = tick32();
    int      guard = 0;
    while (clr_busy()) {
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
        /* 每 64 次 MMIO 读之间插一段纯 ALU 退避（48 = 主循环里的 BLT_WAIT_NOP） */
        if (++guard > 64) { guard = 0; cpu_backoff(48u); }
    }
    return 1;
}
/* 给清屏引擎下一条"把 k 的渲染区清成背景色"的命令（k 必须不是正在显示、也不是正在画的那块） */
static void clr_start(uint32_t k, int y0, int h)
{
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)y0 * FB_STRIDE);
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    blt_wr(BLT_CLR_WH,     ((uint32_t)h << 16) | (uint32_t)FB_WIDTH);
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    /* bit0=GO（1 拍脉冲），[3:2]=目标缓冲号 */
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
}
/* ★v2.11：本趟开画前的**一次性动作**（原先内联在逐条下发路径里，为了列表路径共用而提取，
 * 五步顺序与语义一字未改）：
 *   ① 有界等待清屏引擎空闲  ② 读 clean 位图  ③ 写 DRAW_SEL（在 ② 之后，它会清 clean 位）
 *   ④ 不干净 ⇒ 退回命令式整片清屏（由调用方置 repaint_hw）  ⑤ 给第三块下清屏命令
 * 返回 1 = 本趟需要命令式重铺（目标缓冲不干净）；0 = 已经干净，可省下 568k 周期。 */
static int hw_pass_arm(int y0, int h)
{
    int clean_k;
    if (!clr_wait_idle()) {                        /* ① */
        /* 超时：不等了，交给硬件互斥兜底（会被拒绝 ⇒ 走回退路径） */
    }
    clean_k = clr_is_clean((uint32_t)g_draw3);     /* ② */
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);       /* ③ */
    if (clr_stat() & BLT_CLR_STAT_ERR) {           /*    清掉互斥留下的 sticky 错误 */
        g_clr_err++;
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    }
    if (!clean_k) g_clr_fb++;                      /* ④ 脏 ⇒ 必须退回命令式清屏 */
    if (g_clr_need) {                              /* ⑤ */
        clr_start((uint32_t)g_clr3, y0, h);
        g_clr_need = 0;
    }
    return clean_k ? 0 : 1;
}
#endif
#endif

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

/* 空闲判定：**从已经读到手的状态字**判定，不再自己去读总线 ⇒ 一圈之内只读一次
 * BLT_STATUS，需要判两次（等本趟 / 等 COPY）也只用同一个字。 */
static int blt_idle_st(uint32_t st)
{
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
}

/* 写 FIFO 前先确认有空间：FIFO 满时写 DATA 会把 CPU 挂在 AXI-Lite 上（主循环会死在那里）。
 * ★ 旧版是"每推一条指令读一次 CMD_FIFO_COUNT"（N=1000 时 ≈1000 次/趟）；
 *   现在改成"每圈读一次，拿到余量后在圈内自己记账"，判据与旧版完全等价：
 *     旧：cnt <= 199 才允许再推一条 ⇒ 峰值占用 200 条；
 *     新：room = 200 - cnt（cnt > 199 ⇒ 0），每条指令 room-- ⇒ 峰值同样是 200 条，
 *         而 200 离 FIFO 满（256 条）还差 56 条 = HW_FIFO_MARGIN，安全性不变。
 *   记账只会**更保守**（引擎只会把条数越取越少，余量估计不会偏乐观）。 */
#define HW_FIFO_MARGIN 56
#define BLT_PUSH_LIMIT (BLT_FIFO_DEPTH - HW_FIFO_MARGIN)      /* 200 条 */
static uint32_t blt_push_room(void)
{
    uint32_t cnt = blt_cnt();
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
}

static void blt_init(void)
{
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    blt_wr(BLT_IRQ_STATUS, 1u);                        /* W1C */
    blt_wr(BLT_IRQ_EN, 0u);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
}
/* 整屏上屏：后台缓冲 -> 显示缓冲。双缓冲的关键一步 —— 只有它写显示缓冲，
 * 所以擦除/重画/重叠这些中间过程永远不会被屏幕看到（尾迹与闪烁都由此消除）。
 * ★ FLIP 路径不用它（上屏改成"换显示基址"）⇒ 关掉开关才会被引用，
 *   这里一并按开关编译，免得 -Wall 报 unused-function。 */
#if !FB_FLIP_PUBLISH
static void blt_copy_full(uint32_t src, uint32_t dst)
{
    blt_emit(0UL /*COPY*/, src, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, 0xFFu, 0u);
}
#endif
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

/* ============================== 精灵图集（开机 + 每次切尺寸由 CPU 生成） ==============================
 * ★ RGB565 圆盘精灵，尺寸**跟着 g_blk 走**（与 FILL 的方块同尺寸，见 BLK_W/BLK_H）：
 *   四角 = 色键(洋红)，外圈白环，内部渐变。同一个精灵同时供 KEY 场景（四角透明）
 *   与 ALPHA 场景（整块半透明）使用。图集放在 DDR 里，引擎直接从这里取数 ——
 *   这就是"图上屏"的最小闭环。
 *   ★ 白环厚度按半径等比缩放（SPR_RING = g_blk/8）：16x16 时是 2px、32x32 时是 4px、
 *     **64x64 时是 8px** —— 旧版写死的 `SPR_W/2 - 4` 在 16x16 下会把整个精灵做成白环，
 *     换成 SPR_RING 后"白环 + 内部渐变 + 四角色键"的观感在三种尺寸下一致（都是半径的
 *     1/4 厚白环，图元设计语言不随尺寸变）。
 *   ★ 这四个名字现在都是**运行期表达式**（跟随 g_blk）⇒ 尺寸一变就必须重新
 *     build_atlas()，否则引擎/CPU 会按新跨度去读旧版式的图集（串口键 'k' 已处理）。 */
#define SPR_W      BLK_W
#define SPR_H      BLK_H
#define SPR_STRIDE (SPR_W * 2)
#define SPR_RING   (SPR_W / 8)               /* 白环厚度：16→2px，32→4px，64→8px（等比） */

/* ==== SPR_MASK_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
static uint16_t spr_color(int i, int j)
{
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    int d2 = dx * dx + dy * dy;
    int r2 = (SPR_W / 2) * (SPR_W / 2);
    int ri = SPR_W / 2 - SPR_RING;       /* 白环内边界半径（外边界 = SPR_W/2） */
    unsigned rr, gg, bb;
    if (d2 > r2)              return KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    if (d2 > ri * ri)         return COL_WHITE;      /* 白环 */
    rr = (unsigned)((i * 31) / (SPR_W - 1));
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
}

/* ============================== ★S3 透明块掩码（4x4 块 = 16 位） ==============================
 * RTL 侧（rtl/dl_fetch.v + rtl/blt_engine_fsm.v 的 win_band，功能清单 §26）给 **KEY** 操作
 * 加了"整块全透明 ⇒ 整块跳过"：一个 4x4 网格覆盖整颗精灵，位 `rt*4+ct = 1` 表示
 * "行带 rt × 列块 ct 这一块一个像素都不用碰"（不取数、不 blend、不写）。
 * 块边界与硬件**同一套公式**：列块起点 = floor(W*ct/4)，行带起点 = floor(H*rt/4)
 *   ⇒ 16x16 时每块 4x4 像素、32x32 时每块 8x8 像素、**64x64 时每块 16x16 像素**
 *     （尺寸怎么变都是 16 块 = 16 位，与 RTL 的 4x4 网格一一对应）。
 *
 * ★ 置位只有**一个**安全条件（少一条就是画错，不是省不下）：该块**每一个**像素都等于色键。
 *   只要有一个像素不是色键，这一块就必须清 0 —— 被跳过的块是不取数、不写、也不 blend 的，
 *   清 0 只是"不省"，置 1 却是"漏画"。所以本函数只做这一件事，不做任何"猜"。
 *   ⇒ 今天这颗"白环 + 渐变内芯 + 四角键色"的圆盘：圆盘半径 = W/2 内切包围盒，
 *     每个 4x4 块都至少压着一个实体像素 ⇒ 掩码恒为 0x0000（spr_mask_report 会照实打出来）。
 *
 * ★ 与 FILL/ALPHA 无关：RTL 的 msk_dec 只在 `MASK_EN && OP==KEY && W≥4 && H≥4` 时让掩码生效，
 *   ALPHA/FILL **显式忽略**掩码（测试台用全 1 掩码反证过）⇒ 本文件干脆不给它们置 MASK_EN，
 *   免得留下"以为 ALPHA 也能省"的错觉。
 *
 * ★ 数据通路：软件只写**描述符**（dw3[15:0] = 掩码、dw1.FLAGS[7] = MASK_EN、FLAGS[9:8] = 01）
 *   ⇒ 只有列表路径（串口 'l'）会真的用到它；逐条下发路径的 w0 就是 op（w0[31:2] = 0），
 *   那条路径的掩码恒关（行为与改动前逐位相同）。
 *
 * ★ 重算时机：**只在 build_atlas() 里**算（函数末尾一行）。图集是唯一被改的东西，
 *   而 'k' 切尺寸 / 开机都只经由 build_atlas() ⇒ 两者写在同一个函数里，不会有人漏掉一个。
 *   掩码是纯函数结果（只读像素数组），所以也能整段抽到主机上做自检 —— 见标记。 */
static uint16_t g_spr_mask = 0u;      /* 当前图集的 4x4 块掩码（随 g_blk 变，0 = 一块都标不上） */

static uint16_t spr_mask_of(const volatile uint16_t *px, int w, int h, uint16_t key)
{
    uint16_t m = 0u;
    int rt, ct;
    for (rt = 0; rt < 4; rt++) {
        int y0 = (h * rt) / 4, y1 = (h * (rt + 1)) / 4;      /* 与 RTL 的 row_t* 同一公式 */
        for (ct = 0; ct < 4; ct++) {
            int x0 = (w * ct) / 4, x1 = (w * (ct + 1)) / 4;  /* 与 RTL 的 col_t* 同一公式 */
            int allkey = 1, i, j;
            for (j = y0; j < y1 && allkey; j++)
                for (i = x0; i < x1; i++)
                    if (px[j * w + i] != key) { allkey = 0; break; }
            if (allkey) m = (uint16_t)(m | (uint16_t)(1u << (rt * 4 + ct)));
        }
    }
    return m;
}
/* 置位的块数（只给开机那一行读数用，不参与任何判定） */
static int spr_mask_tiles(uint16_t m)
{
    int n = 0;
    while (m) { n += (int)(m & 1u); m = (uint16_t)(m >> 1); }
    return n;
}
static void build_atlas(void)
{
    /* 图集版式（唯一来源，三个消费者必须一致）：
     *   起点 ATLAS_BASE，行跨度 SPR_STRIDE = SPR_W*2 字节，共 SPR_H 行，整块 SPR_W*SPR_H 像素。
     *   消费者：① 引擎 ALPHA/KEY 指令（blt_alpha/blt_key 传 SPR_STRIDE/SPR_W/SPR_H）
     *           ② CPU 参考实现 cpu_alpha_sprite/cpu_key_sprite（同样按 SPR_W 逐行取数）
     *   ★ 所有跨度/行数都是运行期表达式 ⇒ **尺寸一变必须重跑本函数**（'k' 命令里做了），
     *     否则消费者会按新跨度去读旧版式的图集（整块错位）。
     *   16x16 时整块 512 字节、32x32 时 2048 字节、64x64 时 8192 字节，离
     *   FLUSH_SCRATCH(0x600000) 十万八千里，三种尺寸都不会与别的缓冲区互相踩。 */
    volatile uint16_t *p = (volatile uint16_t *)ATLAS_BASE;
    int i, j;
    for (j = 0; j < SPR_H; j++)
        for (i = 0; i < SPR_W; i++)
            p[j * SPR_W + i] = spr_color(i, j);
    /* ★S3：图集刚重画 ⇒ **同一处**重算 4x4 透明块掩码（唯一消费者 = KEY 描述符的 dw3[15:0]）。
     *   放在这里而不是各调用点：开机与 'k' 切尺寸都只经由本函数，掩码绝不会与图集脱节。
     *   纯读像素（不碰寄存器）⇒ 主机自检可以把这一段原样拿走跑。 */
    g_spr_mask = spr_mask_of((const volatile uint16_t *)ATLAS_BASE, SPR_W, SPR_H,
                             (uint16_t)KEY_COLOR);
}

/* ★S3：图集重建后打一行掩码读数（**只在重建时打**，不是周期打印）。
 *   marked = 置位的块数/16；只有 KEY 会真的用它，所以读数里点明这件事。
 *   本函数也在标记区内 ⇒ 主机自检会把 bsp_printf 接到 stdout 上，跑出来的**就是板上这一行**。 */
static void spr_mask_report(void)
{
    bsp_printf("EV atlas %dx%d keymask=%x marked=%d/16 (KEY dw3[15:0]+FLAGS[7]=1; ALPHA/FILL ignore)\r\n",
               SPR_W, SPR_H, (unsigned)g_spr_mask, spr_mask_tiles(g_spr_mask));
}
/* ==== SPR_MASK_END ==== */

/* ============================== CPU 侧绘制 ==============================
 * ★★ 对齐陷阱（本 Demo 曾经整机卡死的真因，务必保持）：
 *    32bit 存储要求 4 字节对齐 = **像素列号 x 必须是偶数**，而 `scene_step` 会让
 *    x += vx（vx ∈ {±1,±2,±3}）⇒ x 会变成奇数。第一版直接在奇数 x 上做 32bit 存储
 *    → RISC-V 触发未对齐异常 → 程序静默停死（现象：静态画面 + 串口再无输出）。
 *    所以这里：奇数 x 用 16bit 收头/收尾，中间主体才用 32bit 批量写。
 *    ★ 本版**一个字都没动这三个函数**：CPU 侧的像素语义（先擦后画、逐像素读写）
 *      就是 CPU-vs-HW 帧率对比的"分母"，动它对比就不诚实了。 */
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
        volatile uint16_t *d = (volatile uint16_t *)(g_fb_back
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
        volatile uint16_t *d = (volatile uint16_t *)(g_fb_back
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
    { 'R', {0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00} },
    { 'S', {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00} },
    { 'T', {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00} },
    { 'U', {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'W', {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00} },
    { 'Y', {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00} },
    { 'Z', {0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00} },   /* ★ 新字形：信息条 "SZ=32" 要用 */
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
/* 8x8 字模 -> 每行 4 个 32bit 字 ⇒ **每字符前进 8 像素、占 8x8**。
 * ★ 小端：32bit 存储的**低 16 位落在低地址 = 左边像素**，所以 bit7 必须放低半字
 *   （第一版放反了，每个字里两个像素对调 → 屏上全是乱码）。 */
static void osd_text(int x, int y, const char *s, uint16_t fg)
{
    while (*s) {
        const uint8_t *rp = glyph_of(*s++);
        int row;
        for (row = 0; row < 8; row++) {
            uint8_t bits = rp[row];
            volatile uint32_t *p = (volatile uint32_t *)(g_fb_back
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
        x += OSD_GLYPH_W;
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
/* 右对齐路径标签用：x = FB_WIDTH - 8*strlen(label)。
 * 不引 <string.h>：BSP 是 mini 版，自己数一遍字符最省事。 */
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }
/* 极简 strcmp/strcpy（同上：不引 <string.h>） */
static int sseq(const char *a, const char *b)
{
    while (*a && *a == *b) { a++; b++; }
    return (*a == *b) ? 1 : 0;
}
static void scpy(char *d, const char *s) { while ((*d++ = *s++) != 0) { } }

/* ============================== 信息条 ============================== */
static const char *scene_name(int scene)
{
    return (scene == SC_ALPHA) ? "ALPHA" : ((scene == SC_KEY) ? "KEY" : "FILL");
}
static const char *path_label(int path)
{
    return (path == PATH_SPLIT) ? "SPLIT" : ((path == PATH_CPU) ? "CPU ONLY" : "HW ONLY");
}

/* ★ 信息条**左侧**那一行的组串：帧率 + **场景名** + 参数 + 两个模式标记。
 *   SCn 给编号（与命令 1/2/3 对应），后面紧跟人读得懂的名字 FILL/ALPHA/KEY；
 *   SZ 给**当前方块/精灵边长**（串口键 'k' 循环切换 16/32/64）；
 *   fps/N/α 都用 appn 补到固定宽度 ⇒ 数值变短时不会把上一次的长数字留在右边
 *   （配合"重画前先清黑底"⇒ 屏上无残字）。
 *   ★ HW/CPU = 每侧**渲染趟率**，SCR = **真正上屏的帧率**（整帧 COPY 完成次数/秒）：
 *     三者共用同一个 1Hz 窗口、同一次清零，所以可以直接对比 ——
 *     前面两个只说明"算得多快"，屏幕实际多流畅只看 SCR（被 1.92M 周期的整帧 COPY
 *     顶在 ~52fps 上）。
 *   E  = clear_per_pass 开（硬件侧每趟整片重铺）    FR = 帧率模式（按已发布帧推进）
 *   L  = ★v2.11 显示列表路径开（串口键 'l' 切换；默认关 = 逐条下发）
 *   ★ 宽度上界（**静态可证**）：HW/CPU 先钳到 3 位、SCR 钳到 2 位、SZ 恒 2 位、
 *     N ≤ 6000（4 位）、α ≤ 255（3 位）、场景名 ≤ "ALPHA"（5 位）、标记 ≤ 2 位、FR = 3 位、
 *     L = 2 位：
 *     "HW=999 CPU=999 SCR=99 SZ=64 N=6000 SC2:ALPHA A=255 E FR L" = 57 字符 = 456px
 *     ⇒ 左串 x ∈ [8, 464)（最后一个像素列 463）；黑底按 OSD_LEFT_CH=64 铺到 x=520
 *   右侧标签最长 "CPU ONLY" = 8 字符 = 64px，右对齐 ⇒ 最小 x = 960-64 = 896
 *   ⇒ 最坏情况左右之间仍空 896-464 = 432px（54 个字符位），**不可能重叠**。
 *   （所用字符 H W = C P U N S R Z 空格 数字 : A L F I K E Y 全部已在 g_font 中，
 *     其中 Z 是本次为 SZ= 新增的字形。） */
static void fmt_stat(char *line, uint32_t hw_fps, uint32_t cpu_fps, uint32_t scr_fps,
                     int n, int scene, unsigned alpha, int clear_pp, int frame_adv, int blk,
                     int dl)
{
    char *p = line;
    if (hw_fps  > 999u) hw_fps  = 999u;        /* 钳位只为把最长串钉死在上界内 */
    if (cpu_fps > 999u) cpu_fps = 999u;
    /* ★ SCR 只留 2 位：上屏帧率 = 1e8 周期 / (≥1.92M 周期 + 渲染) ≤ 52fps，
     *   2 位数永远够（钳到 99 同时把最长串钉死）。 */
    if (scr_fps >  99u) scr_fps =  99u;
    p = app(p, "HW=");   p = appn(p, hw_fps,  3);
    p = app(p, " CPU="); p = appn(p, cpu_fps, 3);
    p = app(p, " SCR="); p = appn(p, scr_fps, 2);
    /* ★ SZ=：当前方块/精灵边长（'k' 在 16→32→64→16 上循环）。**两位十进制恒成立**
     *   （16/32/64 都是两位数），appn 补位 ⇒ 数值变化时屏上不留残字。 */
    p = app(p, " SZ=");  p = appn(p, (unsigned)blk, 2);
    p = app(p, " N=");   p = appn(p, (unsigned)n, 4);
    p = app(p, " SC");   p = appn(p, (unsigned)(scene + 1), 1);
    p = app(p, ":");
    p = app(p, scene_name(scene));
    p = app(p, " A=");   p = appn(p, alpha, 3);
    if (clear_pp)  p = app(p, " E");
    if (frame_adv) p = app(p, " FR");
    if (dl)        p = app(p, " L");          /* ★v2.11 列表路径标记（'l' 切换） */
    *p = 0;
}

/* 信息条状态：**事件驱动** —— g_osd_dirty 只在"要显示的内容真的变了"时置位，
 * 落屏（osd_blit）只在 COPY 不在飞时做，两者都跟帧率/帧节拍无关。 */
static char     g_osd_line[OSD_LEFT_CH + 2];   /* 当前"想要显示"的左串 */
static int      g_osd_dirty = 1;               /* 1 = 还没落到 FB_BACK 上 */
static uint32_t g_osd_t0   = 0;                /* 1Hz 统计窗口起点 */
static uint32_t g_hw_fps   = 0, g_cpu_fps = 0; /* 上一次算出的**渲染趟率**（组串用） */
static uint32_t g_scr_fps  = 0;                /* ★ 上一次算出的**上屏帧率** */

/* 组串：内容与上次不同才置 dirty（fps 每秒才算一次 ⇒ 稳态就是 ~1 次/秒） */
static void osd_build(int n, int scene, unsigned alpha, int clear_pp, int frame_adv, int blk,
                      int dl)
{
    char tmp[OSD_LEFT_CH + 2];
    fmt_stat(tmp, g_hw_fps, g_cpu_fps, g_scr_fps, n, scene, alpha, clear_pp, frame_adv, blk, dl);
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
}

/* 1Hz 帧率统计（**只在窗口到期时干活**）。返回 1 表示这次真的重算了 ⇒ 调用方清计数。
 * 三个计数（hw_frames/cpu_frames/scr_frames）用**同一个窗口**、同一次清零，见 main。
 * 从"慢时间片"和"COPY 在飞的窗口"两处调用都是安全的：内部自带时间门控。 */
static int osd_service(uint32_t t_now, uint32_t hw_frames, uint32_t cpu_frames,
                       uint32_t scr_frames, int n, int scene, unsigned alpha,
                       int clear_pp, int frame_adv, int blk, int dl)
{
    uint32_t el = (uint32_t)(t_now - g_osd_t0);
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;         /* 每秒最多算一次 */
    g_osd_t0  = t_now;
    g_hw_fps  = (uint32_t)(((uint64_t)hw_frames  * (uint64_t)BSP_CLINT_HZ) / el);
    g_cpu_fps = (uint32_t)(((uint64_t)cpu_frames * (uint64_t)BSP_CLINT_HZ) / el);
    g_scr_fps = (uint32_t)(((uint64_t)scr_frames * (uint64_t)BSP_CLINT_HZ) / el);
    osd_build(n, scene, alpha, clear_pp, frame_adv, blk, dl);
    return 1;
}

/* 落屏：**只在 COPY 不在飞时调用**（否则引擎可能正把半张信息条拷上屏）。
 * 只清"文字真的会落到"的两块黑底，不再整条 960px 铺黑：
 *   左块 x∈[8,456)（按 OSD_LEFT_CH=56 字符算，实际最长 49 字符 ⇒ 缩串/换场景名都不留残字）
 *   右块 x∈[896,960)（覆盖所有右标签）
 * ★ 这里**不再** cache_evict()：信息条的唯一消费者是引擎的整帧 COPY，而每次下发
 *   COPY 之前都会先 cache_evict()（见 main），所以这里的 8KB 写穿屏障纯冗余。 */
static void osd_blit(const char *line, const char *lbl)
{
    cpu_fill32(g_fb_back, OSD_TEXT_X0, 0, OSD_LEFT_PX, OSD_H, COL_OSD_BG);
    cpu_fill32(g_fb_back, FB_WIDTH - OSD_RIGHT_PX, 0, OSD_RIGHT_PX, OSD_H, COL_OSD_BG);
    osd_text(OSD_TEXT_X0, OSD_TEXT_Y, line, COL_WHITE);
    osd_text(FB_WIDTH - OSD_GLYPH_W * slen(lbl), OSD_TEXT_Y, lbl, COL_WHITE);
}

/* ============================== 串口（非阻塞） ==============================
 * 状态寄存器两个字段必须分清（driver/uart.h）：
 *   uart_writeAvailability = (status >> 16) & 0xFF  → TX 剩余空间
 *   uart_readOccupancy     = (status >> 24)         → RX 已收字节数
 * 早期误用 >>16 ⇒ TX 一忙就当成"有数据"、跑去读空 RX，串口指令完全无效。
 * ★ 本版只在"慢时间片"（每 32 圈）里调用，不再每圈都碰 UART 状态寄存器。 */
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

/* ============================== '=' 精确 N 命令（行缓冲） ==============================
 * 其余命令都是"收到一个字符立刻执行"；只有 '=' 需要先把后面的一串数字攒起来再执行
 * （串口是逐字符到达的，主循环每个慢时间片只取一个字符），所以从看到 '=' 起启用一个
 * 小行缓冲，由行终止符 '\n' 或 '\r' 结算。
 *   =1375\n  ⇒ N 精确等于 1375，回显 EV N=1375
 *   =10\n    ⇒ 钳到 N_MIN ⇒ EV N=25      （只钳不拒，回显**实际生效**的值）
 *   =9999\n  ⇒ 钳到 N_MAX ⇒ EV N=6000
 *   非数字 / 位数超过行缓冲 / '=' 后一个数字都没有 ⇒ EV N=ERR
 * ★ 缓冲**只在看到 '=' 之后才启用**（g_nl_on），没启用时每个字符都原样交回单字符命令
 *   分支 ⇒ 原有命令的语义一位都没变。
 * ★ "resets on any other character"：行内收到不该出现的字符（非数字）或位数太多，
 *   立刻作废并复位，并只吃掉那一个字符 —— 它后面的字符马上恢复正常的单字符命令语义，
 *   所以一个坏行最多只影响它自己那一个字符，绝不会把后续命令一直吞下去。
 * ★ 边收边钳（v = min(v*10+d, N_MAX)）：哪怕收满 12 位也不会整数溢出，
 *   而且"位数在缓冲内就必须钳值而不是报错"（=9999 ⇒ 6000）这条语义得以保持。 */
#define NLINE_MAX 12                     /* 行缓冲容量：最多 12 位十进制数字 */
#define NL_NONE    0                     /* 该字符与 '=' 行无关 ⇒ 交给单字符命令分支 */
#define NL_MORE    1                     /* 已收进 '=' 行，还没结算 */
#define NL_OK      2                     /* 结算完成，*out = 实际生效的 N */
#define NL_ERR   (-1)                    /* 该行无效 ⇒ 回 EV N=ERR */

static char     g_nl[NLINE_MAX];         /* 已收下的数字字符 */
static unsigned g_nl_n  = 0;             /* 已收下的位数 */
static int      g_nl_on = 0;             /* 1 = 正在收 '=' 之后的数字 */

static int nline_feed(int c, int *out)
{
    unsigned v, i;
    if (!g_nl_on) {
        if (c != '=') return NL_NONE;    /* 与 '=' 行无关：原样交回单字符命令分支 */
        g_nl_on = 1; g_nl_n = 0;         /* 看到 '='：启用行缓冲 */
        return NL_MORE;
    }
    if (c == '\n' || c == '\r') {        /* 行终止：结算 */
        g_nl_on = 0;
        if (g_nl_n == 0u) return NL_ERR; /* "=" 后面一个数字都没有 */
        v = 0u;
        for (i = 0; i < g_nl_n; i++) {
            v = v * 10u + (unsigned)(g_nl[i] - '0');
            if (v > (unsigned)N_MAX) v = (unsigned)N_MAX;
        }
        if (v < (unsigned)N_MIN) v = (unsigned)N_MIN;   /* 下界同样只钳不拒 */
        *out = (int)v;
        return NL_OK;
    }
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) {
        g_nl_on = 0;                     /* 非数字 / 太长：作废并立即复位 */
        return NL_ERR;
    }
    g_nl[g_nl_n++] = (char)c;
    return NL_MORE;
}

/* ============================== 场景 ============================== */
/* ==== SCENE_BOUNDS_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
/* 标记区内：lcg / scene_init / scene_snap / scene_step / scene_step_both —— 也就是
 * "初始位置怎么来、每步怎么钳位"的全部逻辑（自检把三种尺寸 × 三个场景 × 三条路径全跑一遍，
 * 断言**从第 0 步起**每一个方块都留在渲染区内）。 */
/* ★ 初始位置的两个余量都写成方块边长的倍数（唯一来源仍是 g_blk）：
 *   右侧余量 = 4 个方块（⇒ x+sz 离 FB_WIDTH 还有 3 个方块），下侧余量 = 2.5 个方块
 *   （⇒ y+sz 离 HALF_H 还有 1.5 个方块）。三种尺寸下的实际取值范围：
 *     尺寸 sz   xr = 960-4*sz   x+sz ≤    yr = 260-5*sz/2   y+sz ≤
 *       16         896            912         220             235
 *       32         832            864         180             211
 *       64         704            768         100             163
 *   g_blk=16/32 时与原式**逐位相同**（旧版就是 FB_WIDTH-64 / HALF_H-40，这里只是把
 *   "两个魔数"写成 sz 的倍数）；64x64 时 xr=704、yr=100 仍为正 ⇒ 区间非空，且离
 *   渲染区边界还有 192 / 96 像素富余 ⇒ **初始位置必然在界内**（之后由 scene_step 按
 *   b->sz 钳位保持）。 */
#define SCENE_MX(sz)  (4 * (sz))
#define SCENE_MY(sz)  (5 * (sz) / 2)
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }

/* 两侧用同一颗种子初始化 ⇒ 目标位置逐位相同 */
static void scene_init(int n, uint32_t seed, int sz_fixed)
{
    int side, i;
    int xr = FB_WIDTH - SCENE_MX(g_blk);
    int yr = HALF_H   - SCENE_MY(g_blk);
    for (side = 0; side < NSIDE; side++) {
        uint32_t s = seed;
        for (i = 0; i < n; i++) {
            blk_t *b = &g_sc[side][i];
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
            /* ★ 统一几何：FILL 与 ALPHA/KEY 的方块尺寸现在是同一个值（都 = g_blk，
             *   运行时可切 16/32/64）。旧版 FILL 走 16/24/32 混排、ALPHA/KEY 走图集
             *   32x32 —— 三个场景的方块大小（也就是每像素的工作量）不一致，
             *   横向对比就不公平。sz_fixed 仍然保留它的语义：ALPHA/KEY 必须跟随
             *   图集精灵尺寸（而图集是按 g_blk 生成的）⇒ 两种取值都等于 g_blk。 */
            b->sz = (uint8_t)(sz_fixed ? SPR_W : BLK_W);
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
            if (!b->vx) b->vx = 1;
            if (!b->vy) b->vy = 1;
            b->x  = (int16_t)((int)(r1 % (uint32_t)xr) & ~1);
            b->y  = (int16_t)(int)(r2 % (uint32_t)yr);
            /* ★ 兜底钳位：把"初始位置也一定在渲染区内"变成**代码保证**，而不是只靠上面
             *   那张余量表。界用的是三种路径里**最小**的那个渲染区（SPLIT 半区）：
             *   x+sz ≤ FB_WIDTH、y+sz ≤ HALF_H。就算以后有人改小了 SCENE_MX/MY，
             *   这里也不会让方块一开局就骑在边界外（scene_step 只能救"以后"，
             *   救不了第 0 帧）。今天的余量下这两条**一次都不触发**（上表最大
             *   768/163 ≪ 960/260）⇒ 16/32 逐位不变，纯防回归。 */
            if (b->x + b->sz > FB_WIDTH) b->x = (int16_t)(FB_WIDTH - b->sz);
            if (b->y + b->sz > HALF_H)   b->y = (int16_t)(HALF_H   - b->sz);
            b->dx = b->x; b->dy = b->y;                      /* 本侧"已画位置"初始对齐 */
            b->tx = b->x; b->ty = b->y;                      /* 本趟快照初始对齐 */
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
                                  | ((r1 + r2) & 0x1Fu));
        }
    }
}

/* ★ 给场景拍快照：把当前的 x,y 冻结到 tx,ty。
 *   调用点只有两处，且都是"本侧没有在途的块"的时刻（见 main）：
 *     a) 一趟的起点（hw_i==0/cpu_i==0 且本侧上一趟已完成）
 *     b) 整帧 COPY 在飞的窗口（此刻两侧的渲染段都被 back_busy 挡住）
 *   此后本趟内所有擦/画都用 tx,ty，位置绝不会在一趟中间变化 ⇒ dx/dy 记账自洽 ⇒ 无尾迹。
 *   场景本身仍在后台被推进（按时间或按帧），只是要等下一趟才生效。 */
static void scene_snap(blk_t *sc, int n)
{
    int i;
    for (i = 0; i < n; i++) { sc[i].tx = sc[i].x; sc[i].ty = sc[i].y; }
}

/* 只推进**目标位置**（两侧同时调用 ⇒ 目标逐位相同）；不动 dx/dy */
static void scene_step(blk_t *sc, int n, const rect_t *rg)
{
    int i;
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    int ymin = rg->y0, ymax = rg->y0 + rg->h;
    for (i = 0; i < n; i++) {
        blk_t *b = &sc[i];
        /* ★ 钳位用的 w 就是**这一块自己的 b->sz**（= 当前尺寸）而不是任何常量：
         *   切到 32/64 之后 scene_init 已经把 b->sz 改成新尺寸，所以这里
         *   "x+w > xmax ⇒ x = xmax-w" 自动按新尺寸收敛 ⇒ 方块永远待在渲染区内，
         *   不会出现"对 16x16 合法、对 64x64 溢出"的位置。 */
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
/* 两侧各推进一步（目标逐位相同）；**位置变了 ⇒ 两侧的快照都失效，等各自下一趟起点
 * 重拍**。这里只置标志、不立刻拍快照 —— 立刻拍的话另一侧可能正在飞，
 * 一趟之内前后块的位置就不一致了（旧版就是在这里立刻拍的）。 */
static void scene_step_both(int n, const rect_t *rg, int *snap_hw, int *snap_cpu)
{
    scene_step(g_sc[SIDE_HW],  n, rg);
    scene_step(g_sc[SIDE_CPU], n, rg);
    *snap_hw  = 1;
    *snap_cpu = 1;
}
/* ==== SCENE_BOUNDS_END ==== */

/* ============================== ★v2.11 显示列表 / 描述符表路径 ==============================
 * 为什么：板级实测"每块一次 CPU 下发"≈190 拍/块（1 读 COUNT + 8 写 DATA 走 APB 桥），
 *   把 16x16 FILL 从引擎自身能到的 367 拍/块抬到 561 拍/块。RTL v2.11 新增取指器
 *   `rtl/dl_fetch.v`（DFU）：从 DDR 读 **16B/条**的紧凑描述符，展开成**与 CPU 今天写的
 *   逐位相同的 8 字命令**再推进**同一个 cmd_fifo**（引擎 FSM/像素通路一行未改）。
 * 本段软件只做两件事：①把几何表建在 DDR（开机一次）；②每趟把 N 块写成一串描述符 + GO。
 *
 * ★ 默认**关**（g_dl_mode=0）＝与上板验证过的版本逐位相同；串口键 'l' 打开。
 *   DL_ERR 一置位就自动停用列表路径并交回逐条下发 ⇒ 列表路径坏了也不会让演示"看起来死了"。
 *
 * ★v2.14 板上"场景 2(ALPHA) 跑到第 ~20 条描述符报 WATCHDOG、场景 1(FILL) 一直正常"的
 *   软件侧诊断与兜底（**一行 RTL 都没改，也不需要新 bitstream**）：
 *   ① 看门狗 0x78 显式编程到字段上界 65535 拍（16× 复位值 ≈753µs@87MHz，见上面的常量注释）
 *      —— 4096 拍 ≈47µs 对"精灵读图集 + desc/几何表抢 DDR"太短，"慢但有界"会被误判成死；
 *   ② DL_ERR 时打**解码后的状态快照**（DL_STATUS 各位 + CONSUMED + STALL 粘住位 + DL_PERF
 *      + 清屏引擎计数器），BUSY 落定后再补一行 post-mortem（那才是本表的 PERF）；
 *   ③ 只对 WATCHDOG 做**有界**自动重试（额度与停用条件见下面的 v2.15 一节）。
 *
 * ★v2.15 止住"重试风暴"（**本次改动的核心，改前务必读**）：
 *   板上日志（ALPHA/16x16，按 'l' 之后）：看门狗在**随机序号**（12/28/52/132…）触发、
 *   stall_seen=1，每次重试都"成功"（cumulative ok=136 bad=0），可下一帧又触发 ⇒
 *   旧策略（一次事件最多 2 次重试、成功就恢复额度、每次立刻从 hw_i=0 重画整趟）会退化成
 *   **同一帧里反复重画整趟**的永久重试环，帧率当场崩塌。本版给这条路写了三条硬上界：
 *   ① **一次事件最多重试 1 次**（DL_RETRY_MAX=1），且只在"这一趟彻底作废"之后才开始：
 *      BUSY=0、两张列表缓冲都交回、hw_i 已回 0 —— 交接点与 v2.14 相同（fbwait 分支）；
 *   ② **1s 窗口（DL_WD_WINDOW_TICKS）内的第二次看门狗事件 ⇒ 不重试，直接停用**列表路径；
 *   ③ **重试自己也失败**（表再报错 / 重新 arm 校验不过 / 首表像素探针不过）⇒ 同样停用。
 *   ⇒ 每按一次 'l' 最多只作废 2 趟（1 次原错 + 1 次重试），随后要么恢复正常、要么停用并打
 *     一行总结（EV dl disabled after N watchdog events …; press l to re-arm）后**不再自动重臂**，
 *     必须用户再按 'l'（走 g_dl_want/dl_apply_pending 的正常开关路径）。
 *     因为 ② 保证两次"重新起趟"至少隔 1s，而一帧只有 ~19ms ⇒ **一帧里不可能重开第二趟**，
 *     帧率再也不会被重试拖垮（判据/规则都在 dl_wd_decide() 里，主机自检直接测它）。
 *   ④ 失败面**照着证据说话**：WATCHDOG 的提示按 idx/CONSUMED/stall_seen 说"取指被饿住"，
 *      不再一律打成"几何表读失败"（旧提示对 ALPHA 是误导 —— 画面明明在动，只是这一条卡住）；
 *   ⑤ 每张跑完的表打一行**成本**（EV dl list done: n=.. cycles=.. cyc/sprite=..，1Hz 门控），
 *      逐条路径打同口径的一行（EV cmd path done: …）⇒ "列表到底是赚是亏"在板上直接比大小。
 *      ★ 板上已实测（ALPHA/16x16）：一张 976 精灵的列表 perf=1202408 拍 ≈ 1232 拍/精灵，
 *        比逐条路径的 ~863 拍/精灵**更慢** ⇒ 读多的场景里列表路径是**净亏**，
 *        这是要如实告诉用户的事实，不是可以藏起来的细节（成本行就是干这个的）。
 *
 * ---- 描述符 = 16B = 4 字 = 恰好 1 个 128bit AXI beat（小端，逐位对应 dl_fetch.v 的 d0..d3）----
 *   dw0 [15:0]=X(signed)  [31:16]=Y(signed)
 *   dw1 [15:0]=SPR_ID     [31:16]=FLAGS
 *   dw2 [15:0]=KEY(0xFFFF=用几何表默认键色) [23:16]=ALPHA [31:24]=PRIO（硬件不排序，写 0）
 *   dw3 [15:0]=MASK_ID（★S3：4x4 透明块位图；全 0 = 与改动前逐位相同）[23:16]=W_OVR [31:24]=H_OVR
 *   FLAGS：[1:0]=OP(00COPY/01FILL/10ALPHA/11KEY = w0[1:0]) [2]MIRROR_X [3]MIRROR_Y
 *          [4]CLIP_EN [5]SIZE_OVR [6]SRC_OFF_EN [7]MASK_EN [9:8]MASK_MODE
 *          [10]END_OF_LIST [11]IRQ_AFTER [12]CHAIN [15:13]保留（必须 0）
 *   ★ 本工程只用 OP / CLIP_EN / SIZE_OVR，以及 ★S3 的 MASK_EN + MASK_MODE=01（**只给 KEY**）：
 *     MIRROR_X/Y、SRC_OFF_EN、CHAIN 在 RTL 里**未实现**（置位即报 DL_ERR.UNSUPPORTED bit24），
 *     END_OF_LIST 也不用（靠 DL_COUNT 收尾）。MASK_EN=1 而 MASK_MODE≠01 同样报 UNSUPPORTED。
 *
 * ---- 几何表 = 16B/条，SPR_ID 直接索引（开机建一次；内容与 g_blk 无关，'k' 不用重建）----
 *   gw0=ATLAS_BASE   gw1=[15:0]ATLAS_STRIDE [31:16]KEY_DEFAULT
 *   gw2=[15:0]W [31:16]H   gw3=[15:0]SX [31:16]SY
 *   SPR_ID 映射（**每个 (场景, 尺寸) 组合一条** —— 尺寸运行时可切 16/32/64，三条都得在）：
 *     **按场景分组、组内按尺寸升序**（下标 = 场景基号 + blk_idx(g_blk)，见 dl_spr_id）：
 *       0 = FILL  16x16     1 = FILL  32x32     2 = FILL  64x64
 *       3 = ALPHA 16x16     4 = ALPHA 32x32     5 = ALPHA 64x64
 *       6 = KEY   16x16     7 = KEY   32x32     8 = KEY   64x64
 *       9 = 铺底 960x260（SPLIT 的硬件半区）   10 = 铺底 960x524（HW ONLY 整个渲染区）
 *   ★v2.16 由 8 条扩到 **11 条**（净增 3 条 = 三个场景的 64x64）。容量是查过 RTL 的：
 *     · 0x6C DL_GEOM_MAX 是**完整 16 bit** RW 字段（blt_regs_axi_lite.v:488/:616 的 wd[15:0]），
 *       dl_fetch 的 GEOM_MAXN=1023 只是文档口径的参数、并未参与比较逻辑；真正的判据是
 *       `spr_id >= s_geom_max`（dl_fetch.v:236）而 spr_id = d1[15:0] ⇒ 11 条绰绰有余；
 *     · 几何表 cache（dl_fetch.v:171-173/250-251）是 **16 条直接映射**（索引 spr_id[3:0]、
 *       标签 spr_id[15:4]）⇒ 11 条（id 0..10）各占一个不同索引，**零冲突、全部可常驻**。
 *     上一版是 8 条（正好占掉 16 条 cache 的一半）；扩到 11 条后仍有 5 格空闲索引。
 *   ★ FILL 走 SIZE_OVR（W/H 来自描述符 dw3），几何表内容其实读不到，但 SPR_ID 仍必须
 *     < DL_GEOM_MAX（RTL 的 GEOM_INDEX 检查与 need_geom 无关）⇒ FILL 也要占条目。
 *   ★ 每趟"整片重铺"W=960 超过 SIZE_OVR 的 W_OVR/H_OVR 上界 255 ⇒ 只能走几何表。
 *
 * ---- DDR 布局（都在 +0x800000 之后，与 FB/ATLAS/FLUSH_SCRATCH 互不重叠）----
 *   +0x00800000 几何表 11 条 × 16B = 176B（16B 对齐）
 *   +0x00820000 列表缓冲 0（DL_DESC_MAX 条 × 16B，16B 对齐）
 *   +0x00840000 列表缓冲 1
 * ============================================================================= */
/* ==== DL_LAYOUT_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
/* DL_GEOM_N 也在标记区内 ⇒ 自检用的条目数与固件**同一个宏**，不会各自写一个数。 */
#define DL_GEOM_ADDR    (DDR_BASE + 0x00800000UL)
#define DL_LIST_ADDR(b) (DDR_BASE + 0x00820000UL + (uint32_t)(b) * 0x00020000UL)
#define DL_GEOM_N       11
#define DL_FBWAIT_TICKS (BSP_CLINT_HZ / 50u)   /* 出错交接的有界等待：20ms */
/* ==== DL_LAYOUT_END ==== */

/* ---- 编码/建表（纯函数：不碰任何硬件 ⇒ 可在主机上单独编译做自检）----
 * ==== DL_ENC_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
#define DL_DESC_MAX     4095        /* = dl_fetch 的 COUNT_MAX；超了报 DL_ERR.DESC_COUNT */
/* 描述符 FLAGS 位（与 dl_fetch.v 的 flags[15:0] 逐位对应） */
#define DL_F_CLIP       (1UL << 4)             /* 越屏自动裁剪（不开 + STRICT ⇒ 报错停机） */
#define DL_F_SZOVR      (1UL << 5)             /* W/H 取自 dw3 的 W_OVR/H_OVR */
#define DL_F_MASKEN     (1UL << 7)             /* ★S3：透明块掩码生效（只允许配 KEY） */
#define DL_F_MASKMODE01 (1UL << 8)             /* ★S3：MASK_MODE[1:0]=01（1=该块全透明⇒跳过） */
/* 几何表条目号（SPR_ID）—— 映射见上面的大段注释。
 * ★v2.16 重排：每个场景占**连续三格**（16/32/64），铺底两条挪到 9/10。
 *   dl_spr_id() 用 "场景基号 + blk_idx(g_blk)" 选条目 ⇒ 新增尺寸只需在 dl_geom_fill
 *   里补一条、并在组内保持升序，不会再有"每个尺寸各写一份 if"。 */
#define DL_G_FILL_16    0
#define DL_G_FILL_32    1
#define DL_G_FILL_64    2
#define DL_G_ALPHA_16   3
#define DL_G_ALPHA_32   4
#define DL_G_ALPHA_64   5
#define DL_G_KEY_16     6
#define DL_G_KEY_32     7
#define DL_G_KEY_64     8
#define DL_G_REP_SPLIT  9
#define DL_G_REP_FULL   10

/* 写一条 16B 描述符到列表缓冲的下标 i（list 指向 DDR，小端 4 字 = d0..d3）
 * ★S3：多了 mask 一个入参 —— 写进 dw3[15:0]=MASK_ID。**传 0 时 p[3] 与改动前逐位相同**，
 *   而 FLAGS 由调用方给（只有 KEY 且掩码非 0 才会带上 MASK_EN/MASK_MODE=01）。 */
static void dl_put(uint32_t *list, int i, int x, int y, unsigned spr_id, unsigned flags,
                   unsigned key, unsigned alpha, unsigned w_ovr, unsigned h_ovr, unsigned mask)
{
    volatile uint32_t *p = (volatile uint32_t *)list + (i * 4);
    p[0] = ((uint32_t)(uint16_t)x) | ((uint32_t)(uint16_t)y << 16);
    p[1] = (spr_id & 0xFFFFu) | ((flags & 0xFFFFu) << 16);
    p[2] = (key & 0xFFFFu) | ((alpha & 0xFFu) << 16);            /* [31:24] PRIO=0 */
    p[3] = (mask & 0xFFFFu)                                      /* [15:0] MASK_ID（S3） */
         | ((w_ovr & 0xFFu) << 16) | ((h_ovr & 0xFFu) << 24);
}
/* 写一条 16B 几何表条目到下标的 id（16B/条，SPR_ID 索引） */
static void dl_geom_put(uint32_t *g, int id, uint32_t atlas, unsigned stride, unsigned keydef,
                        unsigned w, unsigned h, unsigned sx, unsigned sy)
{
    volatile uint32_t *p = (volatile uint32_t *)g + (id * 4);
    p[0] = atlas;
    p[1] = (stride & 0xFFFFu) | ((keydef & 0xFFFFu) << 16);
    p[2] = (w & 0xFFFFu) | ((h & 0xFFFFu) << 16);
    p[3] = (sx & 0xFFFFu) | ((sy & 0xFFFFu) << 16);
}

/* (场景, 当前尺寸) → 几何表条目号。'k' 切尺寸时这里自动选到另一条，表本身不用重建。
 * 基号 = 场景 × BLK_N（三个场景各占连续 BLK_N=3 格），组内偏移 = blk_idx(g_blk) ⇒
 * 尺寸表（g_blk_tab）一改，这里、几何表内容、信息条 SZ= 一起跟着变，没有第二处枚举。 */
static unsigned dl_spr_id(int scene)
{
    int i = blk_idx(g_blk);
    if (scene == SC_ALPHA) return (unsigned)(DL_G_ALPHA_16 + i);
    if (scene == SC_KEY)   return (unsigned)(DL_G_KEY_16   + i);
    return (unsigned)(DL_G_FILL_16 + i);
}
/* 每趟整片重铺用的条目号（高度跟着渲染区走：SPLIT 半区 / 单模式整区） */
static int dl_rep_id(int path)
{
    return (path == PATH_SPLIT) ? DL_G_REP_SPLIT : DL_G_REP_FULL;
}

/* 把本趟 hw_i 起的若干块写成一串描述符（**纯 DDR 写，不产生任何 MMIO**）。
 * 语义与逐条路径逐位相同：
 *   · clear_pp=0 时的"擦旧矩形"（FILL + SIZE_OVR，色 = COL_BG），擦/画成对、不拆开；
 *   · 画到本趟快照 (tx,ty)；FILL 的色与尺寸、ALPHA 的 α、KEY 的色键与 blt_*() 完全一致；
 *   · rep_id ≥ 0 时先补一条"整片重铺"（与 blt_fill(整片) 同语义，只是 W/H 走几何表）。
 * ★S3 的唯一例外：KEY 且掩码非 0 时，描述符多带 MASK_EN/MASK_MODE=01 + dw3 掩码 ——
 *   这是**软件侧主动加的信息**，逐条下发路径的 w0 放不下（w0 就是 op）⇒ 那条路径没有掩码。
 *   掩码为 0（今天三种尺寸都是）时，两条路径的描述符**逐位相同**。
 * 出参：*cnt = 写入条数，*last = 本趟是否已写完；*hw_i 就地推进（记账时刻与逐条路径一致）。*/
static void dl_build(uint32_t *list, int *hw_i, int n, int scene, unsigned alpha,
                     int clear_pp, int rep_id, int *cnt, int *last)
{
    int i = *hw_i, c = 0;
    unsigned op  = (scene == SC_FILL) ? BLT_OP_FILL
                 : ((scene == SC_ALPHA) ? BLT_OP_ALPHA : BLT_OP_KEY);
    unsigned spr = dl_spr_id(scene);
    unsigned key = (scene == SC_KEY) ? (unsigned)KEY_COLOR : 0u;  /* ALPHA 的 w7 逐位对齐 CPU 路径 = 0 */
    unsigned al  = (scene == SC_ALPHA) ? alpha : 0xFFu;
    /* ★S3：透明块掩码**只在 KEY 且掩码非 0** 时才挂上去（两条都必要）：
     *   · 别的 OP（FILL/ALPHA/COPY）在 RTL 里被 msk_dec 显式忽略 ⇒ 置了也是白置，
     *     不如不置，免得描述符长得像"ALPHA 也能省"；
     *   · 掩码全 0 时 MASK_EN=0 ⇒ FLAGS 与 dw3[15:0] 与改动前**逐位相同**（惰性改动）；
     *   其余三条 FILL 描述符（整片重铺 / 擦旧矩形 / FILL 的方块）恒不置。 */
    unsigned msk   = ((scene == SC_KEY) && (g_spr_mask != 0u)) ? (unsigned)g_spr_mask : 0u;
    unsigned fl    = (op | DL_F_CLIP) | (msk ? (DL_F_MASKEN | DL_F_MASKMODE01) : 0u);

    if (rep_id >= 0)
        dl_put(list, c++, 0, 0, (unsigned)rep_id, BLT_OP_FILL | DL_F_CLIP,
               (unsigned)COL_BG, 0xFFu, 0u, 0u, 0u);

    while (i < n) {
        blk_t *b = &g_sc[SIDE_HW][i];
        int need = 1;
        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
            need = 2;                                    /* 与逐条路径同一条擦除条件 */
        if (c + need > DL_DESC_MAX) break;               /* 放不下 ⇒ 留到下一段（顺序不变） */
        if (need == 2)
            dl_put(list, c++, b->dx, b->dy, DL_G_FILL_16,
                   BLT_OP_FILL | DL_F_CLIP | DL_F_SZOVR,
                   (unsigned)COL_BG, 0xFFu, (unsigned)b->sz, (unsigned)b->sz, 0u);
        if (scene == SC_FILL)
            dl_put(list, c++, b->tx, b->ty, spr, BLT_OP_FILL | DL_F_CLIP | DL_F_SZOVR,
                   (unsigned)b->color, 0xFFu, (unsigned)b->sz, (unsigned)b->sz, 0u);
        else
            dl_put(list, c++, b->tx, b->ty, spr, fl, key, al, 0u, 0u, msk);
        b->dx = b->tx; b->dy = b->ty;                    /* 记账：画的就是快照位置 */
        i++;
    }
    *hw_i = i;
    *cnt  = c;
    *last = (i >= n) ? 1 : 0;
}
/* ==== DL_ENC_END ==== */

/* ---- 列表路径状态（只在主循环的硬件渲染段里被读写）---- */
static int      g_dl_mode     = 0;   /* 运行期开关（串口 'l'）：0 = 逐条下发（默认） */
static int      g_dl_armed    = 0;   /* 列表模式的寄存器/几何表是否已配置 */
static int      g_dl_inflight = 0;   /* 1 = 有一张表正在被 DFU 消费 */
static int      g_dl_buf      = 0;   /* 在飞表所用的列表缓冲号（0/1） */
static int      g_dl_pend     = -1;  /* 已填好、等上一张跑完就 GO 的缓冲（-1 = 无） */
static int      g_dl_pend_n   = 0;   /* 它的描述符条数 */
static int      g_dl_pend_last= 0;   /* 它是"本趟最后一段" */
static int      g_dl_fbwait   = 0;   /* 出错后等 DFU 落 BUSY，再交回逐条路径 */
static uint32_t g_dl_ft0      = 0;
static int      g_dl_report   = 0;   /* 打开后第一张表跑完打一行读数（一次性，非周期打印） */
/* ★v2.13 'l' 登记的目标模式（-1 = 没有待生效请求，0/1 = 想切到哪条路径）。
 *   真正的切换不在这里做，而是在**帧发布边界**落地 —— 见 dl_apply_pending()。 */
static int      g_dl_want     = -1;
/* ★v2.13 第一张表的"像素落地"探针地址（0 = 本张表不做）。见 dl_pixel_probe()。 */
static uint32_t g_dl_probe_px = 0;

/* ★v2.14 出错诊断 + 看门狗自动恢复的状态（都只在主循环硬件渲染段里被读写）：
 *   · stall_seen：DL_STATUS.STALL 是**组合**位（dl_fetch.v:341-346：`stall = 状态机非空闲
 *     且正卡在等读回程/等 FIFO`），一进 S_ERR 就自动落 0 ⇒ **出错那一刻再读它必然是 0**，
 *     拿它回答"刚才是不是被饿住"永远得到假的"没饿住"。所以必须在表在飞期间轮询时把它
 *     **粘住**（g_dl_stall_seen），出错时打印的是"这张表跑的时候有没有见过 STALL"。
 *   · retry_n/pend/ok/bad：**一次看门狗事件最多一次**的自动重试（只对 WATCHDOG，
 *     理由见错误分支）。n = 1 表示"当前在飞/待发的这张表就是本次事件唯一的重试"；
 *     ok/bad = 累计成功/失败次数（打印用，不参与判断）。
 *   · wd_events/wd_last：自 'l' 打开列表路径以来的**看门狗事件计数**与**上一次事件的时刻**
 *     —— 决定"这是不是 1s 窗口内的第二次"（规则见 dl_wd_decide()），也是停用总结行的 N。
 *   · postmortem：DL_PERF(0x7C) 只在 S_END/S_ERR/S_ABORT **等引擎 done_out 之后**才被写入
 *     （dl_fetch.v:643-663）⇒ 出错那一刻读到的是**上一张表**的周期数。所以出错时只打印
 *     perf_prev=，等 BUSY 真落定后再读一次才是"这张出错表"的真实周期数（GO→出错→引擎收尾）。*/
static int      g_dl_stall_seen = 0;
static int      g_dl_postmortem = 0;
static int      g_dl_retry_n    = 0;
static int      g_dl_retry_pend = 0;
static uint32_t g_dl_retry_ok   = 0;
static uint32_t g_dl_retry_bad  = 0;
static uint32_t g_dl_wd_events  = 0;
static uint32_t g_dl_wd_last    = 0;   /* 0 = 本次打开以来还没出过事件（判据里当"很久以前"用） */

/* ---- 成本读数（★v2.15）：两个 1Hz 门控 + 在飞/待发表各画了几个精灵（成本行的 n=）----
 * 为什么要 n：DL_PERF 是**整张表**的周期数（含表里那条"整片重铺"描述符），只有除以精灵数
 * 才能拿去和逐条路径的"每块开销"横着比 —— 这正是"列表模式在这颗板子上到底赚不赚"的答案。
 * 门控用 tick32（1 次总线读/次），稳态下每个窗口最多各打一行 ⇒ 不刷屏。 */
static uint32_t g_dl_cost_t0     = 0;  /* 列表成本行的 1Hz 门控 */
static uint32_t g_cmd_cost_t0    = 0;  /* 逐条成本行的 1Hz 门控 */
static int      g_dl_inflight_sp = 0;  /* 在飞的那张表画了几个精灵 */
static int      g_dl_pend_sp     = 0;  /* 已填好、待发的那张表画了几个精灵 */
static uint32_t g_cmd_t0         = 0;  /* 本趟逐条下发的起点（0 = 本趟没在计时） */

/* ---- ★v2.15 看门狗事件处置策略（**纯函数**：不碰任何硬件 ⇒ 可整段抽到主机上自检）----
 * ==== DL_WD_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
/* 三条规则（顺序即优先级，与板上分支一一对应）：
 *   ① spent=1（报错的这张表**正是本次事件唯一的那次重试**）⇒ 重试也失败 ⇒ 停用；
 *   ② gap ≤ 1s 窗口内的第二次事件 ⇒ 停用（**不重试** —— 止住风暴的那一刀就在这里）；
 *   ③ 其余 ⇒ 允许本事件唯一的一次重试。
 * 出参 *again = 1 表示"1s 窗口内的第二次事件"（错误分支据此选提示语）。
 * 入参 gap：距上一次事件的 tick 数；本次打开还没有过事件时调用方传 0xFFFFFFFF（= 很久以前）。
 * ★ 一帧只有 ~19ms，而两次"重新起趟"必须由两次事件驱动且至少隔 1s ⇒ **一帧最多重开一趟**。*/
#define DL_WD_OFF    0
#define DL_WD_RETRY  1
#define DL_WD_WINDOW_TICKS  ((uint32_t)BSP_CLINT_HZ)   /* 1s：窗口内第二次事件 ⇒ 停用 */
static int dl_wd_decide(int spent, uint32_t gap, int *again)
{
    int a = (gap <= DL_WD_WINDOW_TICKS);
    *again = a;
    if (spent) return DL_WD_OFF;
    if (a)     return DL_WD_OFF;
    return DL_WD_RETRY;
}
/* ==== DL_WD_END ==== */

/* 一次"看门狗事件"最多自动重试几次（★v2.15：2 → 1）。做成宏只是为了让提示语里的 n/N 一致；
 * 真正的上界是 dl_wd_decide() 的三条规则，不是这个数。 */
#define DL_RETRY_MAX  1

/* 生成几何表内容（**唯一来源**）：DDR 写入与读回校验都用这一段 ⇒ 两边不可能走样。
 * 内容与 g_blk **无关**：三个尺寸各占一条，所以 'k' 切 16/32/64 不需要重建表
 * —— 描述符里的 SPR_ID 会指向对应那条。
 * ==== DL_GEOM_BEGIN：主机自检按这一对标记原样取这段源码（保证"被测的就是固件里跑的"）==== */
static void dl_geom_fill(uint32_t *g)
{
    /* FILL 三条：走 SIZE_OVR 时读不到，但 SPR_ID 必须 < DL_GEOM_MAX，所以照样填成有效几何 */
    dl_geom_put(g, DL_G_FILL_16,  ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    dl_geom_put(g, DL_G_FILL_32,  ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    dl_geom_put(g, DL_G_FILL_64,  ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    /* ALPHA/KEY 就是图集里的那一颗精灵：起点 ATLAS_BASE、行距 = 边长*2、W=H=边长、SX=SY=0。
     * ★64x64 的三条（FILL/ALPHA/KEY 各一条）是本次**唯一的内容变化**：行距 128 B
     *   （= 64*2，与 build_atlas 的版式同一个式子）、W=H=64、SX=SY=0、键色 = KEY_COLOR，
     *   与 16/32 那六条同构 —— 不是"特例"，只是同一张表的第三档。 */
    dl_geom_put(g, DL_G_ALPHA_16, ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    dl_geom_put(g, DL_G_ALPHA_32, ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    dl_geom_put(g, DL_G_ALPHA_64, ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    dl_geom_put(g, DL_G_KEY_16,   ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    dl_geom_put(g, DL_G_KEY_32,   ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    dl_geom_put(g, DL_G_KEY_64,   ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    /* 整片重铺（W=960 > SIZE_OVR 的 8bit 上界 ⇒ 必须走几何表）；高度与 hw_h(path) 一致 */
    dl_geom_put(g, DL_G_REP_SPLIT, 0UL, 0u, 0u, (unsigned)FB_WIDTH, (unsigned)HALF_H, 0u, 0u);
    dl_geom_put(g, DL_G_REP_FULL,  0UL, 0u, 0u, (unsigned)FB_WIDTH,
                (unsigned)(FB_HEIGHT - TOP_Y0), 0u, 0u);
}
/* ==== DL_GEOM_END ==== */

/* 建几何表（打开列表模式时建一次）到 DDR。 */
static void dl_geom_build(void)
{
    dl_geom_fill((uint32_t *)DL_GEOM_ADDR);
    cache_evict();      /* CPU 写完 DDR、硬件紧接着要读 ⇒ 写穿屏障 */
}

/* 单条寄存器读回校验：写下去的值必须能原样读回。
 * 为什么必须查：RTL 在 DFU BUSY=1 时**静默丢弃** 0x4C~0x88 的写入
 * （rtl/blt_regs_axi_lite.v 的 `if (ws[0] && !dl_busy)`）——丢了 GEOM_MAX/GEOM_BASE
 * 的后果见 dl_arm() 的注释。返回 1 = 一致。 */
static int dl_reg_chk(uint32_t off, uint32_t want, const char *name)
{
    uint32_t got = blt_rd(off);
    if (got != want) {
        bsp_printf("EV dl arm FAIL %s: wrote %x read %x\r\n", name,
                   (unsigned)want, (unsigned)got);
        return 0;
    }
    return 1;
}

/* 等 DFU 落 BUSY（有界）。BUSY=1 期间 DFU 会忽略 0x4C~0x88 的写入 ⇒ 配置前必须等。 */
#define DL_ARM_IDLE_TICKS (BSP_CLINT_HZ / 100u)      /* 10ms 上界 */
static int dl_arm_wait_idle(void)
{
    uint32_t t0 = tick32();
    while (blt_rd(BLT_DL_STATUS) & DL_ST_BUSY)
        if ((uint32_t)(tick32() - t0) > (uint32_t)DL_ARM_IDLE_TICKS) return 0;
    return 1;
}

/* ---- ★v2.13 arm 校验：几何表 + DL 配置寄存器**逐项读回** -------------------------
 * 板上症状：场景 2(ALPHA)/3(KEY) 按 'l' 打不开列表模式，场景 1(FILL) 正常。
 * 三个场景在列表路径上**唯一的差别就是几何表**（rtl/dl_fetch.v 的 need_geom：
 *   FILL+SIZE_OVR 完全不读几何表；每个精灵描述符、以及"整片重铺"都必须读）。
 * ⇒ 几何表这条链路（CPU 写 → DDR → DFU 读）任何一环出问题，都**只砸场景 2/3**：
 *   · 配置寄存器被 BUSY 丢掉 ⇒ GEOM_MAX=0 ⇒ 精灵条目一律 GEOM_INDEX(0x2)，
 *     而场景 1 的 FILL+SIZE_OVR 条目一条都不受影响（功能清单 §25 / 设计文档 §8.1）；
 *   · 几何表 W/H 读成 0 ⇒ ZERO_SIZE(0x80)（或 CLIP 生效时被静默跳过）。
 * 这两种都必须让软件**自己发现并说清楚**，而不是让用户对着"开了又自己关"猜。 */
static int dl_arm_verify(void)
{
    uint32_t exp[DL_GEOM_N * 4];
    const volatile uint32_t *ge = (const volatile uint32_t *)DL_GEOM_ADDR;
    int i;

    dl_geom_fill(exp);                       /* 期望值 = 同一个生成函数 */
    for (i = 0; i < DL_GEOM_N * 4; i++) {
        if (ge[i] != exp[i]) {
            bsp_printf("EV dl arm FAIL geom[%d].dw%d: wrote %x read %x\r\n",
                       i / 4, i % 4, (unsigned)exp[i], (unsigned)ge[i]);
            return 0;
        }
    }
    /* 语义校验：精灵条目（ALPHA/KEY 的 16/32/64 共 6 条）的 W/H/行距都不能为 0
     * （为 0 就是"整条链路废了"）。★ v2.16 条目号重排后范围是 [DL_G_ALPHA_16, DL_G_KEY_64]，
     *   64x64 那三条（5/8）也被这一圈覆盖 —— 新尺寸的几何一旦填错，arm 当场就会拦下来。 */
    for (i = DL_G_ALPHA_16; i <= DL_G_KEY_64; i++) {
        unsigned w = (unsigned)(ge[i * 4 + 2] & 0xFFFFu);
        unsigned h = (unsigned)(ge[i * 4 + 2] >> 16);
        unsigned st= (unsigned)(ge[i * 4 + 1] & 0xFFFFu);
        if (!w || !h || !st) {
            bsp_printf("EV dl arm FAIL geom[%d]: W=%d H=%d stride=%d (must be non-zero)\r\n",
                       i, (int)w, (int)h, (int)st);
            return 0;
        }
    }
    if (!dl_reg_chk(BLT_DL_GEOM_BASE,  DL_GEOM_ADDR,   "GEOM_BASE"))  return 0;
    if (!dl_reg_chk(BLT_DL_GEOM_MAX,   (uint32_t)DL_GEOM_N, "GEOM_MAX")) return 0;
    if (!dl_reg_chk(BLT_DL_DST_STRIDE, (uint32_t)FB_STRIDE, "DST_STRIDE")) return 0;
    if (!dl_reg_chk(BLT_DL_FB_WH,
                    ((uint32_t)FB_HEIGHT << 16) | (uint32_t)FB_WIDTH, "FB_WH")) return 0;
    if (!dl_reg_chk(BLT_DL_BASE0,      DL_LIST_ADDR(0), "BASE0"))     return 0;
    if (!dl_reg_chk(BLT_DL_BASE1,      DL_LIST_ADDR(1), "BASE1"))     return 0;
    return 1;
}

/* 打开列表模式前的一次性配置（幂等）。★ 只在"没有表在飞"时调用：BUSY=1 期间 DFU
 * 会**忽略** 0x4C~0x88 的写入（读回旧值）⇒ 这里先等 BUSY 落，写完再逐项读回校验。
 * 返回 1 = 配置真的生效；0 = 校验没过（已打印**具体**哪一项，调用方必须停在逐条路径）。 */
static int dl_arm(void)
{
    if (!dl_arm_wait_idle()) {
        bsp_printf("EV dl arm FAIL: DFU still BUSY (DL_STATUS=%x); 0x4C~0x88 writes would be ignored\r\n",
                   (unsigned)blt_rd(BLT_DL_STATUS));
        return 0;
    }
    dl_geom_build();
    blt_wr(BLT_DL_GEOM_BASE,  DL_GEOM_ADDR);                     /* [31:4]，16B 对齐 */
    blt_wr(BLT_DL_GEOM_MAX,   (uint32_t)DL_GEOM_N);
    blt_wr(BLT_DL_DST_STRIDE, (uint32_t)FB_STRIDE);
    blt_wr(BLT_DL_FB_WH,      ((uint32_t)FB_HEIGHT << 16) | (uint32_t)FB_WIDTH);
    blt_wr(BLT_DL_BASE0,      DL_LIST_ADDR(0));                  /* 写 BASE 会清 DONE */
    blt_wr(BLT_DL_BASE1,      DL_LIST_ADDR(1));
    blt_wr(BLT_DL_ERR,        DL_ERR_CLR_ALL);                   /* W1C：清掉上次的锁存 */
    /* AUTO_GO / STRICT_BOUNDS 是 RW 且复位为 1 ⇒ 这里把 1 写回去（不置 GO） */
    blt_wr(BLT_DL_CTRL,       DL_CTRL_AUTO_GO | DL_CTRL_STRICT);
    /* ★v2.14 看门狗放到字段上界（语义/依据见 DL_TIMEOUT_* 常量注释）。
     * 必须在 BUSY=0 时写（上面 dl_arm_wait_idle 已保证），否则 RTL 静默丢弃。 */
    blt_wr(BLT_DL_TIMEOUT,    DL_TIMEOUT_TICKS);
    /* 读回前先把 D$ 冲一遍：把那 176 字节几何表从缓存里挤出去（写回 DDR），
     * 这样随后的读回才是**真的读 DDR**，而不是命中刚写进去的缓存行。 */
    cache_evict();
    if (!dl_arm_verify()) {
        bsp_printf("EV dl arm FAIL -> list path stays OFF (per-command continues)\r\n");
        return 0;
    }
    /* 看门狗读数**单独处理**：它只影响诊断灵敏度，不影响画面对不对，所以读回不一致
     * 只警告、不否决 arm（某颗老 bitstream 没有 0x78 时，列表路径照样能用，只是看门狗
     * 仍是复位 4096 拍 ≈47µs）。但必须**说出来** —— 不打印就等于假装设上了。 */
    {
        uint32_t tmo = blt_rd(BLT_DL_TIMEOUT) & 0xFFFFu;
        if (tmo != (DL_TIMEOUT_TICKS & 0xFFFFu))
            bsp_printf("EV dl arm WARN TIMEOUT: wrote %x read %x (0x78 missing? watchdog stays %d ticks)\r\n",
                       (unsigned)(DL_TIMEOUT_TICKS & 0xFFFFu), (unsigned)tmo, (int)DL_TIMEOUT_RESET);
        bsp_printf("EV dl arm ok: timeout=%d/%d ticks (x%d reset %d, ~753us@87MHz) GEOM_BASE=%x GEOM_MAX=%d\r\n",
                   (int)tmo, (int)(DL_TIMEOUT_TICKS & 0xFFFFu), DL_TIMEOUT_X, (int)DL_TIMEOUT_RESET,
                   (unsigned)blt_rd(BLT_DL_GEOM_BASE), (int)(blt_rd(BLT_DL_GEOM_MAX) & 0xFFFFu));
    }
    g_dl_stall_seen = 0;          /* 从这一刻起重新观察"取指有没有被饿住"（见状态声明处） */
    return 1;
}

/* 发一张表：DST_BASE + COUNT + (GO|BUF_SEL|AUTO_GO|STRICT)。
 * ★ 顺序固定、且必须在 BUSY=0 时调用：DFU 只在 GO 那一拍采样这组配置。 */
static void dl_go(int buf, int cnt, uint32_t dst_base)
{
    blt_wr(BLT_DL_DST_BASE, dst_base);
    blt_wr(BLT_DL_COUNT,    (uint32_t)cnt);
    blt_wr(BLT_DL_CTRL,     (uint32_t)(DL_CTRL_GO | DL_CTRL_AUTO_GO | DL_CTRL_STRICT |
                                        (buf ? DL_CTRL_BUF_SEL : 0UL)));
}

/* 能力探测：DL_VERSION[15:0] ≥ 2（S2）才认为这颗 bitstream 真的带显示列表 —— 老
 * bitstream 里 0x80 是未实现地址，读回 0。没有这道门，在老 bitstream 上按 'l' 会出现
 * "DL_STATUS 读回 0 ⇒ 以为表瞬间跑完了"的假成功（画面不动但不报错），那正是本版最想
 * 避免的"看起来死了"。 */
static int dl_supported(void)
{
    uint32_t v = blt_rd(BLT_DL_VERSION);
    if ((v & 0xFFFFu) >= 2u) return 1;
    bsp_printf("\r\nEV dl not supported (DL_VERSION=%x, need [15:0]>=2)\r\n", (unsigned)v);
    return 0;
}

/* DL_ERR 位 → 人读得懂的名字（与 rtl/dl_fetch.v 的 err_any_w 一一对应）。
 * 为什么要名字：板上"列表模式开了又自己关"时，光看 code=2 谁也猜不到是哪一项检查
 * 不过；这里把**位**翻成规则名，再补一行"精灵条目要读几何表"的提示。 */
static const char *dl_err_name(uint32_t e)
{
    if (e & 0x01u)       return "DESC_RANGE (base/count/tail)";
    if (e & 0x02u)       return "GEOM_INDEX (SPR_ID>=GEOM_MAX, or GEOM_MAX=0)";
    if (e & 0x04u)       return "GEOM_RANGE (geom addr off/unaligned)";
    if (e & 0x08u)       return "SPRITE_BOUNDS (off-screen w/o CLIP_EN)";
    if (e & 0x10u)       return "WATCHDOG (one descriptor stuck > DL_TIMEOUT)";
    if (e & 0x20u)       return "AXI_RRESP (R channel not OKAY)";
    if (e & 0x40u)       return "DESC_COUNT (>4095)";
    if (e & 0x80u)       return "ZERO_SIZE (W or H == 0; geometry/override)";
    if (e & 0x01000000u) return "UNSUPPORTED (MIRROR/SRC_OFF/CHAIN/MASK_MODE)";
    return "?";
}

/* 停用列表路径的**统一出口**：打印硬件现在的配置读回，W1C 清错，g_dl_mode=0
 * （本帧余下部分交回逐条路径，信息条上的 L 标记随之消失）。
 * 调用点：DL_ERR 且不该/不能再重试、第一张表"一个像素都没画"、arm 校验不过。
 * ★v2.15：这里**不**自动重臂（g_dl_mode=0 且没有任何"下次自动打开"的路径）——
 *   要再试必须用户按 'l'（那次会顺带把风暴计数与重试现场清零，见 dl_apply_pending()）。*/
static void dl_disable(const char *why)
{
    bsp_printf("EV list path OFF (%s), fallback to per-command (key l re-arms)\r\n", why);
    bsp_printf("EV dl cfg readback: GEOM_BASE=%x GEOM_MAX=%d DST_STRIDE=%d FB_WH=%dx%d\r\n",
               (unsigned)blt_rd(BLT_DL_GEOM_BASE), (int)(blt_rd(BLT_DL_GEOM_MAX) & 0xFFFFu),
               (int)(blt_rd(BLT_DL_DST_STRIDE) & 0xFFFFu),
               (int)(blt_rd(BLT_DL_FB_WH) & 0xFFFFu), (int)(blt_rd(BLT_DL_FB_WH) >> 16));
    blt_wr(BLT_DL_ERR, DL_ERR_CLR_ALL);          /* W1C，否则 ERR 一直挂着 */
    g_dl_mode  = 0;
    g_dl_armed = 0;                              /* 下次 'l' 重新走一遍 dl_arm() */
    g_dl_want  = -1;                             /* 出错即撤销待生效请求：要再试请重新按 'l' */
    g_dl_probe_px = 0;
    /* 自动重试的现场一并作废（否则下一个错误会被当成"某次重试失败"）。
     * ★ 注意**不清** g_dl_wd_events/g_dl_wd_last：它们要留给下面那行总结，而且"停用期间"
     *   根本不会再产生事件；用户按 'l' 时 dl_apply_pending() 会把它们清零。 */
    g_dl_retry_n = 0; g_dl_retry_pend = 0;
    g_dl_postmortem = 0;
}

/* ★v2.15 看门狗风暴的**唯一总结行**（每次停用只打一行，之后再无任何周期打印）：
 *   EV dl disabled after N watchdog events (ok=.. bad=..): <why>; descriptor fetch starved
 *      (stall_seen=1); press l to re-arm
 * 为什么要有它：旧版每次事件打 5~7 行、每帧再来一轮，"重试成功"的假象让人以为一切正常；
 * 现在失败面收敛成一行：N/ok/bad 是账，<why> 是本次停用的直接原因，末段是**证据**
 * （stall_seen=1 = 取指被 DDR 争用饿住；stall_seen=0 = 取指压根没回来，那是 RTL 侧的事）。
 * 只由 WATCHDOG 相关路径调用；GEOM_INDEX/ZERO_SIZE 这类确定性问题仍走 dl_disable()。*/
static void dl_wd_summary(const char *why)
{
    bsp_printf("EV dl disabled after %d watchdog events (ok=%d bad=%d): %s; descriptor fetch %s; press l to re-arm\r\n",
               (int)g_dl_wd_events, (int)g_dl_retry_ok, (int)g_dl_retry_bad, why,
               g_dl_stall_seen ? "starved (stall_seen=1)"
                               : "did not return (stall_seen=0)");
}

/* ★v2.14 DL_STATUS(0x5C) 解码打印。位定义：rtl/blt_regs_axi_lite.v:47 的注释与 §25 寄存器表
 *   bit0=BUSY bit1=DONE bit2=ERR bit3=ABORTED bit4=STALL [9:8]=ACTIVE_BUF [31:16]=CONSUMED。
 * 为什么要解码：光看 STATUS=... 十六进制，读日志的人得当场翻 RTL 才知道是"还在忙"还是"卡住"。
 * ★ STALL 的坑（本函数打印两个不同的 STALL，别混）：
 *   · STALL=%d   = 这一次读回时的**实时**组合位。它在 S_ERR 里恒为 0（状态机已离开等待态）
 *                  ⇒ 出错后立刻读它必然 0，**不能**回答"是不是被饿住了"。
 *   · stall_seen = 表在飞期间软件**粘住**的"见过 STALL 没有"（见 g_dl_stall_seen 注释）。
 *                  这才是"取指被饿住（starved，带宽争用）"与"取指彻底死掉（dead）"的分界。 */
static void dl_status_dump(const char *tag, uint32_t st)
{
    bsp_printf("EV dl %s: DL_STATUS=%x BUSY=%d DONE=%d ERR=%d ABORTED=%d STALL=%d ACTIVE_BUF=%d CONSUMED=%d stall_seen=%d\r\n",
               tag, (unsigned)st,
               (int)(st & 1u), (int)((st >> 1) & 1u), (int)((st >> 2) & 1u),
               (int)((st >> 3) & 1u), (int)((st >> 4) & 1u),
               (int)((st >> 8) & 3u), (int)(st >> DL_ST_CONSUMED_SH),
               (int)g_dl_stall_seen);
}

/* DL_ERR 置位：把 code/序号/UNSUPPORTED/FAULT_ADDR 报到串口（位翻成规则名），再补一份
 * **解码后的现场快照**：DL_STATUS 每一位 + 出错时的 CONSUMED + DL_PERF + 清屏引擎计数器。
 * ★v2.14 起本函数**只打印与清错**，不再自己停用列表路径 —— 由调用方按错误类别决定
 *   "看门狗自动重试"还是"直接退回逐条"（见主循环错误分支）。
 * 返回清错前读到的 DL_ERR（调用方要用它的低 8 位判类别）。 */
static uint32_t dl_err_report(void)
{
    uint32_t e  = blt_rd(BLT_DL_ERR);
    uint32_t fa = blt_rd(BLT_DL_FAULT_ADDR);
    uint32_t st = blt_rd(BLT_DL_STATUS);
    bsp_printf("\r\nEV DL_ERR code=%x (%s) idx=%d unsup=%d fault=%x\r\n",
               (unsigned)(e & 0xFFu), dl_err_name(e), (int)((e >> 16) & 0xFFu),
               (int)((e >> 24) & 1u), (unsigned)fa);
    dl_status_dump("status", st);                 /* ★v2.14：解码后的 DL_STATUS + CONSUMED */
    /* DL_PERF 的时序坑：perf_r 只在 S_END/S_ERR/S_ABORT **等引擎 done_out 之后**才写入
     * （rtl/dl_fetch.v:643-663）⇒ 出错这一刻读到的是**上一张表**的周期数，不是这张。
     * 所以这里标成 perf_prev=，本表的真实周期数在"BUSY 落定后的 post-mortem"那行。 */
    bsp_printf("EV dl perf_prev=%d tmo=%d (this list's PERF comes after BUSY=0)\r\n",
               (int)blt_rd(BLT_DL_PERF), (int)(DL_TIMEOUT_TICKS & 0xFFFFu));
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
    /* 清屏引擎计数器：ERR 现场最想知道的是"后台清屏是不是正踩着 DDR"（它会和 desc/图集抢带宽，
     * 正是"取指被饿住"的头号嫌疑人）。前三个是硬件读数（0x40/0x48），后三个是软件累计值：
     *   busy = CLR_STAT[0]；fb/to/err 见 dl_apply_pending() 的注释。 */
    bsp_printf("EV dl clr: CLR_STAT=%x CLR_CYC=%d busy=%d fb=%d to=%d err=%d\r\n",
               (unsigned)blt_rd(BLT_CLR_STAT), (int)blt_rd(BLT_CLR_CYC),
               (int)(blt_rd(BLT_CLR_STAT) & BLT_CLR_STAT_BUSY),
               (int)g_clr_fb, (int)g_clr_to, (int)g_clr_err);
#else
    bsp_printf("EV dl clr: CLR_STAT=%x CLR_CYC=%d busy=%d\r\n",
               (unsigned)blt_rd(BLT_CLR_STAT), (int)blt_rd(BLT_CLR_CYC),
               (int)(blt_rd(BLT_CLR_STAT) & BLT_CLR_STAT_BUSY));
#endif
    /* ★v2.15 提示必须**从现场证据推出来**，不能一律推给几何表：
     *   旧版把 WATCHDOG(0x10) 和 ZERO_SIZE(0x80)/AXI_RRESP(0x20) 一起打成
     *   "geometry-table read failed -> only FILL(SIZE_OVR) would have drawn" —— 对板上 ALPHA 的
     *   看门狗是**误导**：那条错的语义就是"某一条描述符在 DL_TIMEOUT 拍内没走完"
     *   （rtl/dl_fetch.v 的 wd_cnt/s_timeout），与几何表没有必然关系，而且画面是**在动的**
     *   （CONSUMED 已经吃到 idx 附近，只有这一条卡住）。所以改成：
     *   · WATCHDOG：一律说"取指在 idx 处被饿住"，并把判据一并打出来（CONSUMED 与 idx 的关系、
     *     stall_seen）—— stall_seen=1 = 见过 STALL（DDR 争用，有界）；=0 = 取指没回来（RTL 侧）；
     *   · GEOM_INDEX(0x02)/ZERO_SIZE(0x80)：这两类**只有读几何表才可能报**，才说几何表；
     *   · AXI_RRESP(0x20)：读通道非 OKAY，描述符/几何表两条都可能，写清"两者之一"；
     *   · arm 时读回校验不过 ⇒ 由 dl_arm_verify()/dl_reg_chk() 自己打印 geom[i].dwN 与
     *     寄存器名的"写入/读回"两个值（那才是几何表有问题的**直接证据**），这里不重复猜。 */
    {
        uint32_t idx  = (e >> 16) & 0xFFu;              /* DL_ERR[23:16] = 出错序号 */
        uint32_t cons = st >> DL_ST_CONSUMED_SH;        /* 复用上面那次 DL_STATUS 读（同一次快照）*/
        if ((e & 0x10u) && idx)
            bsp_printf("EV dl hint: descriptor fetch starved at idx=%d (CONSUMED=%d %s idx, stall_seen=%d) -> DDR bandwidth, not the geometry table\r\n",
                       (int)idx, (int)cons, (cons < idx) ? "<" : ">=", (int)g_dl_stall_seen);
        else if (e & 0x00000010u)
            bsp_printf("EV dl hint: WATCHDOG with idx=0 (no descriptor index) -> check DL_COUNT/BASE\r\n");
        else if (e & 0x00000002u)
            bsp_printf("EV dl hint: ALPHA/KEY descriptors need the geometry table; FILL+SIZE_OVR does not\r\n");
        else if (e & 0x00000080u)
            bsp_printf("EV dl hint: geometry/override W/H read as 0 (ZERO_SIZE) -> geometry table suspect\r\n");
        else if (e & 0x00000020u)
            bsp_printf("EV dl hint: read channel not OKAY (descriptor or geometry fetch, both possible)\r\n");
    }
    blt_wr(BLT_DL_ERR, DL_ERR_CLR_ALL);          /* W1C，否则 ERR 一直挂着（重试前必须清） */
    return e;
}

/* ---- ★v2.13 第一张表的"像素到底落没落"自检 --------------------------------------
 * 为什么需要它：arm 校验只能证明"软件写下去的东西能读回来"，**证明不了** DFU 那条
 * 路径（几何表 → 展开 → 引擎）真的画出了像素。板上"列表模式开了、画面却不动/什么都没有"
 * 就是这一类：DL_ERR 可能是 0、CONSUMED 也可能是满的，但一个像素都没画。
 * 判据：块 0 的**精灵中心**在列表路径下必然被写过 —— 清屏引擎与"整片重铺"都把渲染区
 * 铺成 COL_BG，而精灵中心既不是色键也不是 COL_BG（图集中心的渐变值恒非 COL_BG，
 * ALPHA 与 COL_BG 混合后也恒非 COL_BG）。读回它 == COL_BG ⇒ 这张表等于没画。
 * 只在**打开后第一张表**做一次（g_dl_report 触发），不是周期开销。
 * 返回 1 = 通过（或本张表没有可用探针点）。 */
static int dl_pixel_probe(void)
{
    uint16_t px;
    if (!g_dl_probe_px) return 1;
    px = *(volatile uint16_t *)g_dl_probe_px;
    g_dl_probe_px = 0;
    if (px == (uint16_t)COL_BG) {
        bsp_printf("EV dl 1st list drew NOTHING at blk0 sprite centre (px=%x = bg)\r\n",
                   (unsigned)px);
        bsp_printf("EV dl hint: table ran but produced no pixels -> geometry/DFU path suspect\r\n");
        return 0;
    }
    return 1;
}

/* ============================== ★v2.15 成本读数（"列表到底赚不赚"） ==============================
 * 板上已知事实（本次改动的**结论之一**，必须让用户在板上自己看得见）：
 *   一张**成功跑完**的 976 精灵列表 perf=1202408 拍 ⇒ ~1232 拍/精灵，
 *   而逐条下发路径在 ALPHA/16x16 上只有 ~863 拍/精灵 ⇒ 读多的场景里列表路径**更慢**。
 * 所以本版给两条路径各加**同口径**的一行成本，都按 1Hz 门控（不是每帧、更不是每条）：
 *   EV dl list done: n=<精灵数> cycles=<DL_PERF> cyc/sprite=<cycles/n>   ← 列表路径，硬件自测
 *   EV cmd path done: n=<精灵数> cycles=<软件秒表> cyc/sprite=<...>      ← 逐条路径，同口径对照
 * 单位说明（两个数为什么能直接比大小）：
 *   · cycles 都按 **core_clk 拍**记 —— DL_PERF(0x7C) 是取指器在 core 域数的周期数；
 *     逐条路径的秒表是 CLINT mtime 低 32 位（tick32），CLINT 就在 core_clk 域
 *     （soc.h: SYSTEM_CLINT_HZ=100000000；par 的 pt.sdc: `create_clock -period 10.000 -name
 *     core_clk` ⇒ 100MHz；rtl/功能清单.md §1 同样写 core_clk 100MHz 单时钟域）。
 *     ★ 就算将来某颗 bitstream 换了主频而 SYSTEM_CLINT_HZ 没跟着改，**两个数仍同步缩放**
 *     ⇒ 绝对值可能偏，但"列表 vs 逐条"的**大小关系**依然成立（这正是本行要回答的问题）；
 *   · 口径差别只有一条，且**必须知道**：DL_PERF 只数"硬件把这张表跑完"的拍数（GO→done，
 *     不含软件下发的空档），逐条路径的秒表是"软件把这一趟推完 + 等引擎画完"的**墙钟**拍数
 *     （含 8 次 MMIO/块的 CPU 开销）。也就是说：列表路径那行是**纯硬件成本**，
 *     逐条那行是**含 CPU 下发开销的真实成本** —— 后者正是用户按 'l' 想省掉的东西。
 *     （SPLIT 模式下逐条那行还夹着 CPU 侧渲染的时间 ⇒ 那种模式下的横比请以 HW ONLY 为准。）
 *   · 列表那行的 n 只数"精灵"，cycles 里却含同一张表里那条**整片重铺**描述符（W=960 的
 *     FILL，~56 万拍）⇒ 小 N 时 cyc/sprite 会明显偏高。想只看精灵开销就把 N 加大再比
 *     （N=976 时重铺只占 3%），这也是"同一场景、同一 N、按 'l' 前后各读一行"的用法。*/
#define DL_COST_TICKS   ((uint32_t)BSP_CLINT_HZ)   /* 成本行 1Hz 门控（与 fps 同一个 1 秒口径） */

/* 一张列表跑完之后调用（在"本表消费完"的分支里）：n = 该表画的精灵数。
 * 读 DL_PERF 的时机与"1st list"那行完全相同（BUSY=0 之后 perf_r 已写入）⇒ 是**这张表**的数。 */
static void dl_cost_report(int sprites)
{
    uint32_t now = tick32();
    int      perf;
    if ((uint32_t)(now - g_dl_cost_t0) < DL_COST_TICKS) return;   /* 1s 内最多一行 */
    g_dl_cost_t0 = now;
    perf = (int)blt_rd(BLT_DL_PERF);
    bsp_printf("EV dl list done: n=%d cycles=%d cyc/sprite=%d\r\n",
               sprites, perf, (sprites > 0) ? (perf / sprites) : 0);
}

/* 逐条路径的一趟跑完之后调用（参数 n = 本趟精灵数）。
 * g_cmd_t0 由"本趟起点"置上（见主循环逐条下发段），跑完就作废 ⇒ 只在真的量到一整趟时才打。 */
static void cmd_cost_report(int n)
{
    uint32_t now, dt;
    if (!g_cmd_t0) return;                       /* 本趟没计时（例如这一趟是列表路径发的） */
    now = tick32();
    dt  = (uint32_t)(now - g_cmd_t0);
    g_cmd_t0 = 0;
    if ((uint32_t)(now - g_cmd_cost_t0) < DL_COST_TICKS) return;   /* 1s 内最多一行 */
    g_cmd_cost_t0 = now;
    bsp_printf("EV cmd path done: n=%d cycles=%d cyc/sprite=%d\r\n",
               n, (int)dt, (n > 0) ? ((int)dt / n) : 0);
}

/* ============================== ★v2.13 'l' 的**待生效切换** ==============================
 * 修的板上问题：'l' 原来是"立刻切，但只要 DFU 有表在飞就拒绝"。列表路径**每帧都发一张表**
 * ⇒ DFU 几乎永远 BUSY ⇒ 打开之后就**再也关不掉**（回 EV dl busy），板上只能重启才能回到
 * 逐条路径 —— A/B 测量因此做不下去。
 *
 * 现在 'l' 只登记"想要的目标模式"（g_dl_want），真正的切换在**帧发布边界**落地：
 *   · FLIP 路径：FB_STAT 确认本次翻转真的生效那一刻（这一帧已经上屏）；
 *   · COPY 路径：整帧 COPY 完成、判定"这一帧已上屏"那一刻。
 * 为什么这一刻是安全的（三条都由软件自己的状态保证）：
 *   ① 本帧那张表已经被 DFU 消费完 —— 走到帧发布边界必须经过 `fin`，而 `fin` 只在
 *      "无在飞表 + 无待发段"的分支里发生（hw_i 已回 0）；
 *   ② 引擎已完成（DL_STATUS.DONE 的定义里含引擎 done_out ⇒ 这张表的像素**已写提交**）；
 *   ③ 下一趟从 hw_i==0 重新开始 ⇒ 切换后整趟只用新路径，**绝不会一张表切到一半**，
 *      也**绝不会同一帧里两条路径混用**。
 * 再保险一道：真到那一刻若还有表在飞/有待发段/在等出错交接，就**继续等下一个帧边界**。
 * 回包：按 'l' 立刻回 `EV dl on pending` / `EV dl off pending`；真正生效时回 `EV dl on` /
 * `EV dl off`（打开时照旧补一行 DL_VERSION/几何表/两张列表地址的读数）。 */
static int dl_apply_pending(void)
{
    if (g_dl_want < 0) return 0;                                   /* 没有待生效请求 */
    if (g_dl_inflight || g_dl_pend >= 0 || g_dl_fbwait) return 0;   /* 还有表在飞 ⇒ 再等一帧 */
    g_dl_mode  = g_dl_want;
    g_dl_want  = -1;
    g_dl_armed = 0;                       /* 关→开时下次重新走一遍 dl_arm() */
    /* ★v2.15：这是一次**用户主动**的开关 ⇒ 看门狗风暴的账与重试现场全部清零：
     *   · 上一次风暴的事件时间戳不清掉的话，用户重开后遇到的**第一个**看门狗会被当成
     *     "1s 窗口内的第二次事件"而立刻停用（等于不给任何自动恢复机会）；
     *   · 清账之后用户重开列表路径就重新拿到"1 次事件 1 次重试、1s 内第二次才停用"的完整策略，
     *     总结行的 N/ok/bad 也从这一次打开重新算。
     * 另外把逐条路径的秒表作废（新模式的第一趟不该带着旧起点算成本）。 */
    g_dl_retry_n = 0; g_dl_retry_pend = 0;
    g_dl_wd_events = 0; g_dl_wd_last = 0;
    g_cmd_t0 = 0;
    bsp_printf("\r\nEV dl %s\r\n", g_dl_mode ? "on" : "off");
    if (g_dl_mode)
        bsp_printf("     DL_VERSION=%x geom=%x lists=%x/%x\r\n",
                   (unsigned)blt_rd(BLT_DL_VERSION), (unsigned)DL_GEOM_ADDR,
                   (unsigned)DL_LIST_ADDR(0), (unsigned)DL_LIST_ADDR(1));
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
    /* ★v2.13：一行**累计**诊断（只在切换时打一次，不是周期打印）。三个计数都是清屏引擎的：
     *   fb  = 目标缓冲不干净 ⇒ 本趟的整片重铺**退回引擎关键路径**（命令式 FILL / 描述符）的次数；
     *   to  = 等清屏引擎空闲撞上 10ms 上界的次数；err = 硬件互斥拒绝/被打断的次数。
     *   稳态下 fb/to/err **都应该不涨**（涨 ⇒ 清屏引擎没在干活，背景重铺又回到关键路径上了）。
     *   用法：按 'l' 切换两次、各跑一段，用两次读数之差就能算出每种模式下"每帧几次"，
     *   不必重启、也不必外加任何仪器。 */
    bsp_printf("     clr fb=%d to=%d err=%d (cumulative; fb=region repaint in-path)\r\n",
               (int)g_clr_fb, (int)g_clr_to, (int)g_clr_err);
#endif
    return 1;                              /* 本帧真的换了模式 ⇒ 调用方重画信息条 */
}

/* ============================== 主程序 ============================== */
#define SCENE_TICKS  (BSP_CLINT_HZ / 25u)    /* 时间模式：场景推进周期 = 40ms（25 步/秒） */
#define MAX_STEPS    8                       /* 一次补步的上限（长时间停顿后别一次跳太多） */

/* ★ 主循环节流参数（单位是"圈"，不是毫秒）：
 *   SLOW_MASK      每 32 圈做一次"慢工作"：UART RX + 时间戳 + 场景推进 + 1Hz 统计。
 *   BLT_WAIT_MASK  等引擎时每 4 圈才读一次状态字，其余圈纯 ALU 退避。
 *   BLT_WAIT_NOP   每次退避的空转量（≈150~190 周期 ≈ 1.5~1.9us @100MHz）
 *                  ⇒ 轮询周期 ≈ 4*190 ≈ 760 周期 ≈ 7.6us；对 ~19ms 的整帧 COPY
 *                  来说，"发现引擎完成"的延迟只占帧时间 0.04%，测不出来。
 *   HW_PUSH_BUDGET 一圈最多推几条引擎指令：64 条 = 512 次 FIFO 写 ≈ 2~3k 周期
 *                  ≈ 30us ⇒ 慢时间片的间隔仍有上界，长指令流（N=6000）也不会
 *                  让 UART/场景饿太久。 */
#define SLOW_MASK        31u
#define BLT_WAIT_MASK     3u
#define BLT_WAIT_NOP     48u
#define HW_PUSH_BUDGET   64u

/* 硬件侧渲染区起点/高度（SPLIT 只用上半；单模式铺满场景区） */
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
    int      path  = PATH_HW;          /* ★ 默认：纯硬件整屏 */
    int      scene = SC_FILL;
    int      n     = N_MIN;            /* ★ 默认 N=25 */
    int      n_cmd = N_MIN;            /* '=' 行缓冲结算出的 N（nline_feed 的出口） */
    unsigned alpha = 128u;
    /* it 只当"慢时间片"的分频计数用（每 32 圈一次），不再有周期性上报/打印 */
    uint32_t it = 0;
    /* ★ 三个计数器共用同一个 1Hz 窗口、同一次清零（见 osd_service 调用点）：
     *   hw_frames/cpu_frames 数的是两侧各自的**渲染趟数**，scr_frames 数的是
     *   **整帧 COPY 真正完成的次数** = 上屏帧数 —— 屏幕的流畅度只看最后一个。 */
    uint32_t hw_frames = 0, cpu_frames = 0, scr_frames = 0;
    uint32_t t_scene, t_now = 0;
    int hw_i = 0, hw_frame_pushed = 0;
    int hw_fifo_full = 0;              /* 上一圈 FIFO_COUNT 读满（纯硬件模式下据此低频轮询） */
    int clear_pp = 1;                  /* ★ 'e' 默认 ON：每趟整片重铺背景（硬件侧） */
    int frame_adv = 0;                 /* ★ 't'：0=按墙钟时间推进  1=每发布一帧推进一步 */
    int pend_adv = 0;                  /* 帧率模式下攒下的待推步数（慢时间片里结算） */
    int cpu_i = 0;
    /* 重铺标记：两侧各一个（场景/路径一变就要把各自区域铺回背景，
     * 否则旧物块留在屏上没人擦 —— 就是"加减物块后要等接触才刷新"那个现象） */
    int repaint_hw = 1, repaint_cpu = 1;
#if FB_FLIP_PUBLISH
    /* ★ 尺寸切换（'k'）后的"补重铺"剩余轮数（见 SIZE_REPAINT_ROUNDS）：
     *   轮转的另外两块缓冲里还留着旧尺寸的方块，接下来几次成功翻转后各补铺一次。
     *   默认 0 ⇒ 不影响任何稳态行为。只在 FLIP 路径存在（COPY 路径没有轮转残留）。 */
    int size_repaint = 0;
#endif
    /* 双缓冲：两侧各完成一遍 = 一个演示帧，此刻把后台缓冲整体搬上屏一次 */
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    /* 快照失效标志：场景位置变过 ⇒ 等本侧下一趟起点再重拍（保证一趟内 tx,ty 恒定） */
    int snap_hw = 0, snap_cpu = 0;
    uint32_t back_t0 = 0;

    rect_t vrg;
    vrg.x0 = 0; vrg.y0 = 0; vrg.w = FB_WIDTH; vrg.h = HALF_H;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */

    bsp_printf("\r\n===== FinalDemo: HW accel vs pure CPU, same screen =====\r\n");
    bsp_printf("FB=%x BACK=%x ATLAS=%x SPR=%dx%d\r\n",
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)ATLAS_BASE, SPR_W, SPR_H);
    bsp_printf("blk: %dx%d sprite, runtime-switchable %d/%d/%d (key k cycles 16->32->64->16,\r\n",
               SPR_W, SPR_H, BLK_LO, BLK_MID, BLK_HI);
    bsp_printf("     atlas rebuilt + scene re-init at every step)\r\n");
    bsp_printf("layout: info 0-16 | HW 16-276 | sep | CPU 280-540\r\n");
    bsp_printf("default: path=HW only, clear_per_pass=1, advance=time, N=%d\r\n", n);
    bsp_printf("cmd: 1/2/3 scene FILL/ALPHA/KEY, s/c/h path SPLIT/CPU/HW\r\n");
    bsp_printf("     n or + N+%d, - N-%d, a/A alpha-/+, e clear-per-pass,\r\n", N_STEP, N_STEP);
    bsp_printf("     =N exact N (%d..%d clamped, e.g. =1375 + Enter),\r\n", N_MIN, N_MAX);
    bsp_printf("     t time/frame advance, k blk 16/32/64 (cycles), r reset, ? help\r\n");
    bsp_printf("     l list mode (DDR descriptor table) on/off -- DEFAULT OFF\r\n");
    bsp_printf("       (l takes effect at the next frame boundary, reply: EV dl on/off pending)\r\n");
    bsp_printf("       DL WATCHDOG: 1 retry/event; a 2nd event within 1s disables list mode\r\n");
    bsp_printf("       cost: EV dl list done / EV cmd path done (n=.. cycles=.. cyc/sprite=..)\r\n");

    blt_init();
#if FB_FLIP_PUBLISH
    /* ★ 先与实际在屏的缓冲对齐：FB_STAT[0] = 扫描输出**已经生效**的选择。
     *   不假设复位值 —— 这样"不复位 FPGA 直接重跑程序"也不会把后台缓冲画错
     *   （重跑时上一轮的翻转可能还生效着）。 */
    g_disp_sel = fb_stat_sel();
#if FB_TRIPLE_BUFFER
    /* ★v2.7 三缓冲轮转初值：本趟画 disp+1，另一块（disp+2）交给清屏引擎预清。
     *   必须在这里（osd_blit/铺底之前）就把 g_fb_back 定下来，否则信息条会画错缓冲。 */
    g_draw3      = (int)((g_disp_sel + 1u) % 3u);
    g_clr3       = (int)((g_disp_sel + 2u) % 3u);
    g_clr_need   = 1;                  /* 本趟开始时给清屏引擎下第一条命令 */
    g_pass_armed = 0;
    g_fb_back    = fb_of_sel((uint32_t)g_draw3);
#else
    g_fb_back  = fb_of_sel(g_disp_sel ^ 1u);
#endif
#endif
    build_atlas();                    /* 精灵图集：开机按 BLK_LO=16 建（引擎与 CPU 都从这里取数；'k' 会重跑） */
    spr_mask_report();                /* ★S3：图集一重建就报掩码（含"一块都标不上"这种读数） */
    cpu_fill32(g_fb_back, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);      /* 整屏近黑铺底 */
    cache_evict();

    /* ★ 未对齐写入自检：CPU 侧曾因奇数 x 做 32bit 存储而整机静默停死。
     *   这两行能在开机第一秒就暴露该类问题（打印不出来或值不对 = 有问题）。 */
    cpu_fill32(g_fb_back, 33, 500, 8, 2, 0xF800u);
    cpu_fill32(g_fb_back, 32, 502, 9, 2, 0x07E0u);
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 33u * 2u)),
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 40u * 2u)),
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 32u * 2u)),
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 40u * 2u)));
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x FB=%x DL=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
               (unsigned)blt_rd(BLT_FB_STAT), (unsigned)blt_rd(BLT_DL_VERSION));

    scene_init(n, g_seed, 0);
    cache_evict();

    /* ★ 信息条开机就画好：先组串 → 落屏 → 再整屏上屏，这样**第一帧**顶上就有读数，
     *   而不是黑条空等一秒。t_now 同时作为 1Hz 统计窗口与场景时间基的起点。 */
    t_now    = tick32();
    t_scene  = t_now;
    g_osd_t0 = t_now;
    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    osd_blit(g_osd_line, path_label(path));
    g_osd_dirty = 0;

#if FB_FLIP_PUBLISH
#if FB_TRIPLE_BUFFER
    /* ★v2.7 三缓冲：显示 A / 画 B / 预清 C。
     *   另外两块（还没画过的那两块）在这里各铺一次底（只此一次），免得显示到 DDR 上电随机值。
     *   ★ 当前绘制的这块（g_fb_back = g_draw3）**不能**再铺一次 —— 上面 osd_blit 已经把
     *     信息条画进去了，再铺会把信息条擦掉。 */
    cpu_fill32(fb_of_sel((uint32_t)((g_draw3 + 1) % 3)), 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    cpu_fill32(fb_of_sel((uint32_t)((g_draw3 + 2) % 3)), 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0;
    g_bar_ok[(uint32_t)g_draw3] = 1;      /* 信息条已经在"本趟要画的那块"里了 */
    g_flip_req = g_disp_sel;              /* 没有在途请求 */
    cache_evict();
    bsp_printf("publish: FLIPx3 (disp=%d draw=%d clr=%d, clear-engine on)\r\n",
               (int)g_disp_sel, g_draw3, g_clr3);
#else
    /* ★ FLIP 路径：**一次整屏 COPY 都不做**。
     *   后台缓冲 = 非显示的那块（上面已经铺好底 + 画好信息条），第一趟画完就翻过去；
     *   两块缓冲都保证"已初始化" —— 显示缓冲这里补一次近黑铺底，
     *   免得第一趟之前屏幕上是 DDR 上电随机值。 */
    g_bar_ok[g_disp_sel ^ 1u] = 1;            /* 信息条已经在后台缓冲里了 */
    g_flip_req = g_disp_sel;                  /* 没有在途请求 */
    cpu_fill32(fb_of_sel(g_disp_sel), 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);  /* 开机只此一次 */
    cache_evict();
    bsp_printf("publish: FLIP (no full-screen COPY; disp_sel=%d FB_SEL=0x%X FB_STAT=0x%X)\r\n",
               (int)g_disp_sel, (unsigned)BLT_FB_SEL, (unsigned)BLT_FB_STAT);
#endif
#if FB_IRQ_PACING
    /* ★v2.7 IRQ 帧节拍：开 FRAME 中断使能（0x14 bit1）。默认关 = 与改动前一致。 */
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);
    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);        /* 先清掉可能已有的挂起 */
    bsp_printf("pacing: IRQ (frame-boundary IRQ_STATUS[1], IRQ_EN[1] on)\r\n");
#endif
#else
    cache_evict();                    /* 开机唯一一次上屏前的写穿屏障 */
    blt_copy_full(FB_BACK, FB_BASE);  /* 开机先整屏上屏一次，避免显示未初始化 DDR */
    back_busy = 1; back_t0 = t_now;
    bsp_printf("publish: COPY (full-screen blit, build-time switch off)\r\n");
#endif

    for (;;) {
        it++;

        /* ============ 慢时间片（每 32 圈）：UART + 时间 + 场景 + 1Hz 统计 ============
         * ★ 旧版这些工作全在"每圈"里做：1 次 UART 状态读 + 3 次 tick()（每次 3 个
         *   CLINT 寄存器读）= 10 次外设总线事务/圈，占空转期总线事务的绝大部分。
         *   收敛到 1/32 频率后：稳态平均每圈只多 0.03 次总线读。 */
        if ((it & SLOW_MASK) == 0u) {
            int c = uart_poll_char();
            t_now = tick32();

            /* ---------------- 串口命令（交互全部走这里） ---------------- */
            if (c) {
                int scene_change = 0;
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
                /* ★ '=' 精确 N（行缓冲）：先喂给它。只有返回 NL_NONE 才说明这个字符
                 *   与 '=' 行无关 ⇒ 落到下面原来的单字符命令分支，语义一位未变。 */
                int nl = nline_feed(c, &n_cmd);
                if (nl == NL_OK) {
                    n = n_cmd;               /* 已在 nline_feed 里钳到 [N_MIN, N_MAX] */
                    scene_change = 1; disp_change = 1;
                    bsp_printf("\r\nEV N=%d\r\n", n);     /* 回显**实际生效**的值 */
                } else if (nl == NL_ERR) {
                    bsp_printf("\r\nEV N=ERR\r\n");       /* 非数字 / 太长 / 空数字 */
                } else if (nl == NL_NONE) {
                    if (c == '1' || c == '2' || c == '3') {
                        scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
                        scene_change = 1; disp_change = 1;
                        bsp_printf("\r\nEV scene=%d (0=FILL 1=ALPHA 2=KEY)\r\n", scene);
                    } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
                        disp_change = 1; bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
                    else if (c == 'c' || c == 'C')   { path = PATH_CPU;   repaint_hw = repaint_cpu = 1;
                        disp_change = 1; bsp_printf("\r\nEV path=1 CPU only\r\n"); }
                    else if (c == 'h' || c == 'H')   { path = PATH_HW;    repaint_hw = repaint_cpu = 1;
                        disp_change = 1; bsp_printf("\r\nEV path=2 HW only\r\n"); }
                    else if (c == 'n' || c == 'N' || c == '+') {
                        n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1; disp_change = 1;
                        bsp_printf("\r\nEV N=%d\r\n", n); }
                    else if (c == '-') {
                        n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1; disp_change = 1;
                        bsp_printf("\r\nEV N=%d\r\n", n); }
                    else if (c == 'e' || c == 'E') { clear_pp = !clear_pp;
                        if (!clear_pp) repaint_hw = 1;   /* 立即重铺一次，切模式后状态一致 */
                        disp_change = 1;
                        bsp_printf("\r\nEV clear_per_pass=%d (1=every pass refills the HW region)\r\n", clear_pp); }
                    else if (c == 't' || c == 'T') { frame_adv = !frame_adv;
                        t_scene = t_now;                 /* 切回时间模式时别攒出一大跳 */
                        disp_change = 1;
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
                                   frame_adv); }
                    else if (c == 'k' || c == 'K') {
                        /* ★ 方块/精灵尺寸 **16x16 → 32x32 → 64x64 → 16x16**（运行期几何循环）。
                         *   四步的顺序是有讲究的：
                         *   ① 改 g_blk —— 唯一的尺寸来源（BLK_W/SPR_* 都是它的别名）。
                         *      下一步的取值只由 blk_next() 给（唯一的尺寸表 g_blk_tab）；
                         *   ② build_atlas() 按新尺寸重画图集（含 4x4 透明块掩码，同一个
                         *      函数里算）。必须在**下一次绘制之前**完成，否则引擎/CPU 会拿
                         *      新跨度去读旧版式的图集（整块错位）；
                         *   ③ scene_change=1 ⇒ 走既有的"重新初始化场景"通路（与 1/2/3
                         *      场景键、'r' 重置完全同一条代码路径）：
                         *        · scene_init() 把**全部 N 个方块**的 b->sz 写成新尺寸，
                         *          并在**按新尺寸算出的安全范围**内重新随机位置（余量表见
                         *          SCENE_MX/SCENE_MY 的注释：64x64 时 xr=704 / yr=100）；
                         *        · hw_i/cpu_i/hw_frame_pushed/pend_adv 清零，两侧重开一趟；
                         *        · repaint_hw = repaint_cpu = 1 ⇒ 两侧渲染区整片重铺，
                         *          旧尺寸的残留像素与"对 16x16 合法、对 64x64 会溢出"的
                         *          位置都在本趟被盖掉/被 scene_step 按新 b->sz 钳回区内；
                         *        · FIFO 里可能还压着几条旧尺寸的指令，但重铺指令排在它们
                         *          **后面**（FIFO 保序）⇒ 最终画面只可能是新尺寸。
                         *      ★ 列表路径不用做任何事：几何表**三个尺寸各占一条**，描述符里
                         *        的 SPR_ID 由 dl_spr_id() 现算 ⇒ 下一张表自动指向 64x64 那条。
                         *   ④ disp_change=1 ⇒ 信息条补上新的 SZ= 值（SZ=64 仍是两位）。 */
                        g_blk = blk_next(g_blk);
                        build_atlas();
                        spr_mask_report();        /* ★S3：掩码跟着图集一起换（同一个函数里算的） */
                        scene_change = 1; disp_change = 1;
#if FB_FLIP_PUBLISH
                        size_repaint = SIZE_REPAINT_ROUNDS;   /* 另外两块缓冲补铺（见声明处） */
#endif
                        bsp_printf("\r\nEV size=%d\r\n", g_blk); }
                    else if (c == 'a') { if (alpha >= 32u)  alpha -= 32u;
                        disp_change = 1; bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
                    else if (c == 'A') { if (alpha <= 223u) alpha += 32u;
                        disp_change = 1; bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
                    else if (c == 'r' || c == 'R') { scene_change = 1; g_seed += 0x9E3779B9u;
                        bsp_printf("\r\nEV reset\r\n"); }
                    else if (c == 'l' || c == 'L') {
                        /* ★v2.13 列表路径开关（**默认关** = 逐条下发，与上板验证过的版本一致）。
                         *   ★ 本版改成**待生效切换**：'l' 只登记目标模式，真正的换路径放到帧发布
                         *     边界（原因、安全性论证与回包见 dl_apply_pending()）。旧版是"有表
                         *     在飞就拒绝"，而列表路径**每帧都发一张表** ⇒ DFU 几乎永远 BUSY ⇒
                         *     打开之后**再也关不掉**（板上只能重启），A/B 测量做不下去。
                         *     现在按两次 'l' 就能来回切，不用重启。
                         *   关→开时**仍在按键这一刻**做能力探测（dl_supported）：老 bitstream 上
                         *   0x80 读回 0，必须马上拒绝 —— 不能让用户以为"EV dl on pending"之后
                         *   会生效（那正是本版最想避免的"看起来死了"的假成功）。
                         *   ★v2.13 修正：探测只在**关→开**（next==1）时做。上一版写成 `!next`，
                         *   极性反了 ⇒ 开的时候不探测、关的时候反而探测（老 bitstream 上就会
                         *   "假成功打开" + "关不掉"）。旧版（v2.11）的 `g_dl_mode || dl_supported()`
                         *   也是这个极性，本次改回一致。
                         *   待生效期间再按 'l' = 撤销（目标又变回当前模式）。
                         *   ★v2.15：这一次按键同时是"风暴之后**唯一**的重新打开入口" ——
                         *     看门狗连续出事后 dl_disable() 会把列表路径关掉且**不再自动重臂**，
                         *     用户按 'l' 才重新打开；dl_apply_pending() 会顺手把事件计数与重试
                         *     现场清零（重新拿到"1 次事件 1 次重试、1s 内第二次才停用"的完整策略）。 */
                        int want = (g_dl_want >= 0) ? g_dl_want : g_dl_mode;
                        int next = !want;
                        if (next && !dl_supported()) {
                            /* 关→开、能力探测不通过：dl_supported() 已打印原因 ⇒ 不登记请求 */
                        } else if (next == g_dl_mode) {
                            g_dl_want = -1;                  /* 又按回来了 ⇒ 撤销待生效请求 */
                            bsp_printf("\r\nEV dl %s pending cancelled\r\n",
                                       g_dl_mode ? "on" : "off");
                        } else {
                            g_dl_want = next;
                            bsp_printf("\r\nEV dl %s pending (takes effect at the next frame boundary)\r\n",
                                       next ? "on" : "off");
                        } }
                    else if (c == '?') {
                        bsp_printf("\r\ncmd: 1/2/3=scene FILL/ALPHA/KEY   s/c/h=path SPLIT/CPU/HW\r\n"
                                   "     n or + =N+%d   - =N-%d   a/A=alpha-/+   e=clear-per-pass\r\n"
                                   "     =N=exact N, decimal, %d..%d clamped (e.g. =1375)\r\n"
                                   "     t=advance time/frame   k=blk size 16/32/64 (cycles\r\n"
                                   "       16->32->64->16; atlas+scene rebuilt, EV size=)\r\n"
                                   "     l=list mode on/off (DL descriptor table, default OFF,\r\n"
                                   "       takes effect at the next frame boundary; EV dl on/off pending)\r\n"
                                   "       DL WATCHDOG: 1 retry/event; a 2nd event within 1s disables list\r\n"
                                   "       mode (EV dl retry 1/1 ok|failed, EV dl disabled after N events)\r\n"
                                   "     cost: EV dl list done / EV cmd path done, n=.. cycles=.. cyc/sprite=..\r\n"
                                   "       (at most one line per second each)\r\n"
                                   "     r=reset   ?=help\r\n"
                                   "     (HW/CPU=render pass/s, SCR=published frames/s, L=list mode)\r\n",
                                   N_STEP, N_STEP, N_MIN, N_MAX); }
                }
                if (scene_change) {
                    scene_init(n, g_seed, (scene == SC_FILL) ? 0 : 1);
                    hw_i = 0; hw_frame_pushed = 0; cpu_i = 0; pend_adv = 0;
                    repaint_hw = repaint_cpu = 1;
                    snap_hw = snap_cpu = 0;   /* scene_init 已把 tx,ty 对齐到 x,y */
                    hw_fifo_full = 0;
                }
                if (disp_change)
                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
            }

            /* ---------------- 场景推进：两种模式互斥 ----------------
             * 时间模式（默认）  ：按墙钟推进，40ms 一步 = 25 步/秒（与帧率无关）。
             * 帧率模式（'t'）   ：目标在"一帧被发布上屏之后"才前进一步 ⇒ 运动锁在帧率上。 */
            vrg.h = vrg_h(path);          /* 虚拟区域跟着路径变（单模式 = 整屏高） */
            if (!frame_adv) {
                pend_adv = 0;
                if ((uint32_t)(t_now - t_scene) >= (uint32_t)SCENE_TICKS) {
                    int steps = 0;
                    t_scene = t_now;
                    do { scene_step_both(n, &vrg, &snap_hw, &snap_cpu); steps++; }
                    while ((uint32_t)(tick32() - t_scene) >= (uint32_t)SCENE_TICKS &&
                           steps < MAX_STEPS);
                }
            } else if (pend_adv > 0) {
                scene_step_both(n, &vrg, &snap_hw, &snap_cpu);
                pend_adv--;
            }

            /* ---------------- 1Hz 帧率统计（值没变就不重画信息条） ----------------
             * 调用点先用**更便宜的内联判断**挡一道：没到点一个函数调用都不发。
             * ★ hw/cpu/scr 三个计数在这里**一起清零** ⇒ 三个数字共享同一个窗口，
             *   屏幕上 HW=/CPU=/SCR= 可以直接横向对比。 */
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, hw_frames, cpu_frames, scr_frames,
                            n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode)) {
                hw_frames = 0; cpu_frames = 0; scr_frames = 0;
            }
        }

        /* ---------------- 双缓冲：两侧都画完一遍 → 整体搬上屏一次 ----------------
         * ★ 只有这一处写显示缓冲（FB_BASE），所以"擦除/重画/重叠"的中间过程永远不会
         *   被屏幕看到。之前的尾迹与重叠闪烁，根子都是屏幕拍到了帧中间状态
         *   （两阶段把"已擦未画"的窗口拉长到 10ms 量级，而屏幕每 16.7ms 采一次样）。
         *   这也正是最初"CPU 画屏外缓冲、引擎 COPY 上屏"的做法。 */
        if (back_busy) {
            /* ============ 整帧 COPY 在飞的窗口（~19ms/帧）：**不空转** ============
             * 1) 先把下一趟要用的场景快照拍好。此刻两侧的渲染段都被 back_busy 挡住，
             *    没有任何一侧在"记账中途"；引擎 FIFO 里可能还压着本帧的指令，但那些
             *    指令的目的地址在推出时就已定死，改 tx,ty 不会影响它们，而每个块画完
             *    就把 dx,dy 记成自己的 tx,ty ⇒ 记账始终自洽。
             * 2) 到点的 1Hz 统计/组串也在这个窗口里做（osd_service 自带门控，
             *    慢时间片里那次调用会直接返回，不会重复算；调用点还先用内联判断
             *    挡一道，没到点连函数调用都不发）。
             * 3) 有界退避 + 低频轮询：每 4 圈才读一次 BLT_STATUS，其余圈纯 ALU 空转，
             *    **一个外设寄存器都不碰**（旧版这里每圈 1 次状态 + 3 次 CLINT 读）。 */
            if (snap_hw)  { scene_snap(g_sc[SIDE_HW],  n); snap_hw  = 0; }
            if (snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, hw_frames, cpu_frames, scr_frames,
                            n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode)) {
                hw_frames = 0; cpu_frames = 0; scr_frames = 0;
            }
            if ((it & BLT_WAIT_MASK) == 0u) {
#if FB_FLIP_PUBLISH
                /* ★ FLIP 的"上屏完成"判据：FB_STAT[1:0] 真的变成了我们请求的那一块。
                 *   它由扫描输出在**帧边界**锁存 → 确认它的那一刻，"这一帧已经在屏上"
                 *   成立（仿真实测：帧边界后 4 个 core 拍就生效）。
                 *   有界超时：超过 FLIP_TIMEOUT_TICKS 就重发一次请求继续等 ——
                 *   **绝不**退化成"往可能正在上屏的缓冲里画"（那会撕裂），也绝不空转到死。
                 * ★v2.7 FB_IRQ_PACING=1：**节拍改成帧边界中断**（IRQ_STATUS[1]，W1C）——
                 *   先查中断状态，只有这一场的中断到了才读一次 FB_STAT 确认，读一次就清掉。 */
                int flip_ev = 1;
#if FB_IRQ_PACING
                {
                    uint32_t irq = blt_rd(BLT_IRQ_STATUS);
                    if (irq & BLT_IRQ_FRAME) {
                        blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);   /* W1C：清本场中断 */
                        flip_ev = 1;
                    } else {
                        flip_ev = 0;                             /* 本场还没到 —— 不读 FB_STAT */
                    }
                }
#endif
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
                    back_busy  = 0;
#if FB_TRIPLE_BUFFER
                    /* ★v2.7 三缓冲轮转：刚画完的这块上屏了，接下来
                     *   画 = 之前预清好的那块，清 = 刚腾出来的旧显示缓冲。 */
                    {
                        int old_disp = (int)g_disp_sel;
                        g_disp_sel   = g_flip_req;
                        g_draw3      = g_clr3;
                        g_clr3       = old_disp;
                        g_clr_need   = 1;          /* 下一趟开始时给清屏引擎下新命令 */
                        g_pass_armed = 0;
                        g_fb_back    = fb_of_sel((uint32_t)g_draw3);
                    }
#else
                    g_disp_sel = g_flip_req;
                    g_fb_back  = fb_of_sel(g_disp_sel ^ 1u);   /* 新的后台缓冲 */
#endif
                    scr_frames++;                              /* 这一帧真的上屏了 */
                    if (frame_adv && pend_adv < MAX_STEPS) pend_adv++;
                    /* 新后台缓冲里是**两帧前**的内容：clear_pp 关掉时要整片重铺一次，
                     * 否则这一轮没动的物块会留着上一轮的残影（clear_pp=1 每趟本来就重铺）。
                     * ★ 刚切过方块尺寸（size_repaint>0）时同样补铺：轮转到的这块里还是
                     *   **旧尺寸**的方块，不盖掉就会和新尺寸的混在同一帧里（见 'k' 命令
                     *   与 SIZE_REPAINT_ROUNDS）。补铺只加"重铺请求"，发布协议未改。 */
                    if (!clear_pp || size_repaint > 0) {
                        repaint_hw = 1; repaint_cpu = 1;
                        if (size_repaint > 0) size_repaint--;
                    }
                    /* ★v2.13：'l' 的待生效切换就在**这一刻**落地 —— 这里正是"帧发布边界"：
                     *   本帧已经上屏（FB_STAT 确认翻转生效）、本帧那张表已被 DFU 消费完、
                     *   引擎的像素也已写提交，而下一趟从 hw_i==0 重新开始
                     *   ⇒ 不会切在一张表中间，也不会在同一帧里混用两条路径
                     *   （内部还有"确实没有表在飞"的保险，见 dl_apply_pending()）。 */
                    if (dl_apply_pending())
                        osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
                    g_flip_to++;
                    if (g_flip_to == 1u)
                        bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
                                   (unsigned)blt_rd(BLT_FB_STAT));
                    blt_wr(BLT_FB_SEL, g_flip_req);       /* 重发请求，继续有界等待 */
                    back_t0 = tick32();
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
#else
                /* 200us 保护：避开刚下发时的假空闲 */
                if (blt_idle_st(blt_stat()) &&
                    ((uint32_t)(tick32() - back_t0) > (uint32_t)(BSP_CLINT_HZ / 5000u))) {
                    back_busy = 0;
                    /* ★ Change 1：一帧**真的上屏了** —— 记在上屏计数里（1Hz 窗口内统计）。
                     *   这里是"整帧 COPY 已确认完成 + 200us 保护已过"的唯一判定点，
                     *   所以 scr_frames 就是显示缓冲被更新的次数 = 屏幕帧率。 */
                    scr_frames++;
                    /* ★ 一帧已发布上屏 —— 帧率模式在这里攒一步，慢时间片里结算 */
                    if (frame_adv && pend_adv < MAX_STEPS) pend_adv++;
                    /* ★v2.13：COPY 路径的"帧发布边界"就是这里（与 FLIP 路径的翻转确认
                     *   同一个时刻口径）：整帧 COPY 已完成 ⇒ 'l' 的待生效切换在此落地。 */
                    if (dl_apply_pending())
                        osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
#endif
            } else {
                cpu_backoff(BLT_WAIT_NOP);
            }
        } else if ((path == PATH_CPU || hw_done) && (path == PATH_HW || cpu_done)) {
#if FB_FLIP_PUBLISH
            /* ★ FLIP 上屏：请求翻到"刚画好的这一块"（= 非显示的那块），然后等它生效。
             *   一次 DDR 搬运都不做 —— 省掉的正是整帧 COPY 的 ~707k core 周期。
             *   写 FB_SEL 只是请求，扫描输出会在下一个帧边界锁存它 ⇒ 绝不会出现
             *   "一场里混两个缓冲"的帧。 */
            cache_evict();                 /* 与 COPY 路径同一位置：保证 CPU 像素对内存有序 */
#if FB_TRIPLE_BUFFER
            /* ★v2.7 三缓冲：请求翻到"本趟画的那一块"（g_draw3） */
            g_flip_req = (uint32_t)g_draw3;
#else
            g_flip_req = g_disp_sel ^ 1u;
#endif
            blt_wr(BLT_FB_SEL, g_flip_req);
            back_busy = 1;
            back_t0   = tick32();
            hw_done = 0; cpu_done = 0;
#else
            cache_evict();                 /* 保证 CPU 的像素对引擎可见 */
            blt_copy_full(FB_BACK, FB_BASE);
            back_busy = 1;
            back_t0   = tick32();
            hw_done = 0; cpu_done = 0;
#endif
        }

        /* ---------------- 硬件侧：每趟"整片重铺 + 画全部块"，位置用本趟快照 ----------------
         * 全部画在后台缓冲里；屏幕看到的是上面那条整帧 COPY。
         * ★ clear_pp=1（默认）：本趟先 FILL 整片渲染区为背景色，再画 N 块，
         *   **不发任何逐块擦除指令** —— 上板验证：黑拖尾与 KEY 四角闪烁都消失。
         * ★ clear_pp=0：退回 comptest2 的"逐块擦旧矩形再画"（留给板上 A/B 对比）。 */
        if (!back_busy && path != PATH_CPU) {
            /* ============ ★v2.11 列表路径（串口 'l' 打开；**默认关**）============
             * 一张表 = 本趟的一段（≤ DL_DESC_MAX 条）。硬件同一时刻只允许一张表在飞
             * （GO 在 BUSY 时被忽略），两张表放在 DL_BASE0/1 里乒乓：
             *   在飞的那张被 DFU 消费时，CPU 把**下一段**写进另一张（BUF_SEL 选它）。
             * ★ 缓冲区复用规则（本实现的一条硬规则）：
             *   GO(k) 之后 buf k 记"在用"；只有轮询到**本表跑完且 DFU 落 BUSY**
             *   （DL_STATUS.BUSY=0 且 DONE/ABORTED；出错则 ERR 后等 BUSY=0）才清"在用"，
             *   此后才允许再写它 ⇒ "表还在被读"与"CPU 在写它"永不重叠。
             *   DONE 的定义里含引擎 done_out（写已提交），所以"可写"= 上一张表的像素
             *   真的落进了 DDR，而不只是"看起来不忙"。
             * ★ 完成判据只用 DL_STATUS（本模式不再轮询逐条状态/FIFO_COUNT）。 */
            /* ★ 出错后的交接必须排在 g_dl_mode 判断**之前**：出错时列表路径可能已经被
             *   停用（dl_disable），也可能还开着等**看门狗自动重试**（v2.14）—— 两种情况下
             *   DFU 都可能还在把已展开的命令跑完，必须等它落 BUSY 才能安全地重新 arm 或
             *   交回逐条路径（硬件在 S_PUSH 期间会压住 CPU 对 0x08 的写口）。 */
            if (g_dl_fbwait) {
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
                if (poll) {
                    uint32_t fst  = blt_rd(BLT_DL_STATUS);
                    int      idle = ((fst & DL_ST_BUSY) == 0u);
                    if (idle || ((uint32_t)(tick32() - g_dl_ft0) > (uint32_t)DL_FBWAIT_TICKS)) {
                        /* ★v2.14 post-mortem：只有**真的等到 BUSY=0** 才有意义 —— 此时
                         *   S_ERR/S_END 已经走完、perf_r 刚被写入（dl_fetch.v:643-663），
                         *   所以这一行的 perf= 才是**这张出错表**的真实周期数（GO→出错→引擎收尾），
                         *   拿它和 tmo= 一比就知道"离超时差多远"。20ms 上界到点但 DFU 还 BUSY 时
                         *   不打印（那会儿 PERF 还是上一张表的，打出来只会误导）。 */
                        if (idle && g_dl_postmortem) {
                            g_dl_postmortem = 0;
                            dl_status_dump("post-mortem", fst);
                            bsp_printf("EV dl post-mortem: perf=%d tmo=%d (this list, GO->ERR->BUSY=0)\r\n",
                                       (int)blt_rd(BLT_DL_PERF), (int)(DL_TIMEOUT_TICKS & 0xFFFFu));
                        }
                        /* 没等到 BUSY=0（20ms 上界到点）也把这一行作废：那会儿 PERF 还是旧的，
                         * 留到下一次交接打出来只会误导。 */
                        g_dl_postmortem = 0;
                        /* 停了（或有界超时）：本趟作废、从零重画 */
                        g_dl_fbwait = 0; g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
                        hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                        g_pass_armed = 0;
#endif
                        if (g_dl_retry_pend) {
                            /* ★v2.15 看门狗**唯一的一次**自动重试在这里（也**只**在这里）落地：
                             *   · 前提：本表已彻底停下（idle = BUSY=0）、两张列表缓冲都交回
                             *     （g_dl_inflight=0、g_dl_pend=-1）、本趟已作废（hw_i=0）⇒
                             *     满足原有的**缓冲复用规则**（绝不会一边被读一边被写）；
                             *   · 有界超时到点但 DFU 还 BUSY ⇒ **不重试**：那不是"被饿住"而是
                             *     "没回来"，重新 arm 也一定在 dl_arm_wait_idle() 处失败 ——
                             *     当场记账 + 总结行 + 停用，比再等一轮更清楚（也就不可能拖帧率）；
                             *   · 做法：g_dl_armed=0 ⇒ 下一圈在列表分支里重新走一遍 dl_arm()
                             *     （几何表重建 + 配置逐项读回校验 + 清 DL_ERR + 重设 TIMEOUT），
                             *     然后从 hw_i=0 用**同一张表**重画本趟（repaint_hw=1 ⇒ 首段带
                             *     整片重铺，出错前那半张表画过的像素会被盖掉）；
                             *   · g_dl_mode 一直是 1 ⇒ 重试期间**不会**混入逐条路径，重试也
                             *     不会切在一张表中间；
                             *   · g_dl_report=1 由 arm 分支自动置上 ⇒ 重试那张表照样做"第一张表
                             *     读数 + 像素落地探针"（原有的两条保证一个都不少）；
                             *   · ★ 一帧只有 ~19ms，而 dl_wd_decide() 保证两次"重新起趟"至少隔
                             *     1s ⇒ 同一个帧里**绝不可能**重开第二趟。 */
                            g_dl_retry_pend = 0;
                            if (!idle) {
                                g_dl_retry_bad++;
                                bsp_printf("EV dl retry %d/%d failed (DFU still BUSY after %d ticks)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX, (int)DL_FBWAIT_TICKS);
                                dl_wd_summary("retry aborted: DFU never went idle");
                                dl_disable("WATCHDOG: DFU never went idle");
                            } else {
                                g_dl_armed  = 0;
                                g_dl_report = 1;
                                g_dl_stall_seen = 0;
                                bsp_printf("EV dl retry %d/%d start (fresh arm, this pass from hw_i=0)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX);
                            }
                        }
                    } else {
                        cpu_backoff(BLT_WAIT_NOP);
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
            } else if (g_dl_mode) {
                int y0   = hw_y0(path);
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
                int armed_ok = 1;

                /* ★v2.13 关→开时的一次性配置**带回读校验**：不过就当场退回逐条路径。
                 * 校验内容与理由见 dl_arm()/dl_arm_verify() —— 覆盖的正是"只有场景 2/3
                 * 会踩"的几何表那条链路（配置寄存器读回、几何表读回、W/H/行距非 0）。 */
                if (!g_dl_armed) {
                    armed_ok = dl_arm();
                    g_dl_armed = armed_ok;
                    g_dl_report = armed_ok;
                    g_dl_probe_px = 0;
                }

                if (!armed_ok) {
                    /* 校验没过：本帧就回逐条路径（不动 hw_i/hw_frame_pushed —— 列表路径
                     * 一个字都还没发），'L' 标记随之消失。原因已由 dl_arm() 打印。 */
                    /* ★v2.15：若这次 arm 是"看门狗重试的重新 arm"，它同样算一次重试失败
                     * ⇒ 按新策略**直接停用**（不再有第二次机会），并打那一行总结。
                     * 这里必须把重试现场清干净，否则下一圈的 (g_dl_retry_n && g_dl_mode)
                     * 会拿着过期序号误报 ok。 */
                    if (g_dl_retry_n) {
                        g_dl_retry_bad++;
                        bsp_printf("EV dl retry %d/%d failed (re-arm verification failed)\r\n",
                                   g_dl_retry_n, DL_RETRY_MAX);
                        dl_wd_summary("retry re-arm verification failed");
                    }
                    g_dl_retry_n = 0; g_dl_retry_pend = 0;
                    g_dl_postmortem = 0;
                    g_dl_mode = 0; g_dl_want = -1;
                    hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                    g_pass_armed = 0;
#endif
                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                } else if (g_dl_inflight) {
                    /* ① 乒乓：把下一段写进另一张缓冲。
                     *    描述符只是 DDR 存储（一次 MMIO 都没有），不打扰 DFU 取指。 */
                    if (g_dl_pend < 0 && hw_i < n) {
                        int c = 0, last = 0;
                        int i0  = hw_i;              /* ★v2.15：本段画了几个精灵（成本行的 n=）*/
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
                        dl_build((uint32_t *)DL_LIST_ADDR(1 - g_dl_buf), &hw_i, n, scene,
                                 alpha, clear_pp, rep, &c, &last);
                        if (rep >= 0) repaint_hw = 0;
                        cache_evict();             /* 硬件紧接着要读这批描述符 */
                        g_dl_pend = 1 - g_dl_buf; g_dl_pend_n = c; g_dl_pend_last = last;
                        g_dl_pend_sp = hw_i - i0;
                    }
                    /* ② 低频轮询本表：DONE 电平（含引擎写提交）或 ERR 锁存 */
                    if (poll) {
                        uint32_t st = blt_rd(BLT_DL_STATUS);
                        /* ★v2.14 STALL 必须在这里**粘住**：它是组合位，出错后进 S_ERR 就恒 0
                         *   （理由见 dl_status_dump()），只有在"表还在飞"的每次轮询里记下来，
                         *   出错时才能回答"这张表是不是被饿住过"。 */
                        if (st & DL_ST_STALL) g_dl_stall_seen = 1;
                        if (st & DL_ST_ERR) {
                            /* ★v2.15 错误处置：先打完整现场（dl_err_report 只打印 + W1C 清错），
                             *   再按**类别 + 证据**决定下一步。只有 WATCHDOG（code=0x10）值得
                             *   自动重试，而且上界由 dl_wd_decide() 给死（**纯函数、主机自检直接
                             *   测它**）：
                             *   · spent=1（错的正是本次事件唯一的那次重试）⇒ 停用；
                             *   · 距上一次看门狗事件 ≤1s ⇒ 停用（**不重试** —— 止住风暴的那一刀）；
                             *   · 其余 ⇒ 允许本事件唯一的一次重试（等 BUSY=0 → 重新 arm → 本趟
                             *     从 hw_i=0 重发），成功与否都只此一次。
                             *   其余错误（DESC_RANGE/GEOM_INDEX/ZERO_SIZE/UNSUPPORTED/RRESP…）
                             *   是**确定性**的配置/数据问题，重试只会再错一次，直接退回逐条。
                             *   ★ 为什么这样就不可能拖垮帧率：两条"重新起趟"至少隔 1s，而一帧
                             *     只有 ~19ms ⇒ 一帧最多重开一趟，且每按一次 'l' 最多作废 2 趟。 */
                            uint32_t ew    = dl_err_report();
                            int      wd    = ((ew & 0xFFu) == 0x10u);
                            int      spent = (g_dl_retry_n != 0);   /* 错的正是上一次重试 */
                            uint32_t now   = tick32();
                            uint32_t gap   = 0xFFFFFFFFu;           /* 默认 = "很久以前"（没出过事件）*/
                            int      again = 0;
                            int      verdict = DL_WD_OFF;
                            if (wd) {
                                g_dl_wd_events++;
                                if (g_dl_wd_last != 0)
                                    gap = (uint32_t)(now - g_dl_wd_last);
                                g_dl_wd_last = now;
                            }
                            if (spent) {
                                g_dl_retry_bad++;
                                bsp_printf("EV dl retry %d/%d failed (code=%x %s)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX,
                                           (unsigned)(ew & 0xFFu), dl_err_name(ew));
                                g_dl_retry_n = 0;
                            }
                            if (wd)
                                verdict = dl_wd_decide(spent, gap, &again);
                            if (verdict == DL_WD_RETRY) {
                                g_dl_retry_n    = 1;        /* 本事件唯一的一次重试 */
                                g_dl_retry_pend = 1;
                                bsp_printf("EV dl retry %d/%d pending (WATCHDOG: wait BUSY=0, re-arm, resend this pass)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX);
                            } else {
                                if (wd) {
                                    /* 停用：一行总结（为什么 + 账 + 证据），之后不再自动重臂 */
                                    if (spent)
                                        dl_wd_summary("retry also failed");
                                    else if (again)
                                        dl_wd_summary("2nd watchdog within 1s window");
                                    else
                                        dl_wd_summary("watchdog event");   /* 防御：dl_wd_decide 不会给这个组合 */
                                    dl_disable("WATCHDOG");
                                } else if (spent) {
                                    /* 重试那张表这次报的是**确定性**错误（不是看门狗）——同样属于
                                     * "重试也失败" ⇒ 一样停用 + 总结行，到此为止（不再有第二次）。 */
                                    dl_wd_summary("retry failed with a deterministic error");
                                    dl_disable("DL_ERR");
                                } else {
                                    dl_disable("DL_ERR");   /* 确定性错误：直接退回逐条 */
                                }
                            }
                            g_dl_postmortem = 1;        /* BUSY 落定后补一行本表真实 PERF */
                            g_dl_fbwait = 1; g_dl_ft0 = tick32();
                            g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
                            hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                            g_pass_armed = 0;
#endif
                            osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                        } else if (!(st & DL_ST_BUSY)) {
                            /* 本表消费完（DONE；ABORTED 也走这里）⇒ 它那张缓冲重新可写 */
                            if (g_dl_report) {
                                g_dl_report = 0;
                                bsp_printf("EV dl 1st list: STATUS=%x consumed=%d perf=%d\r\n",
                                           (unsigned)st, (int)(st >> DL_ST_CONSUMED_SH),
                                           (int)blt_rd(BLT_DL_PERF));
                                /* ★v2.13：再验一次"真的画了像素"——DONE/consumed 都正常
                                 * 却一个像素都没画，是列表路径最阴的一种失败。不过就停用
                                 * 列表路径（宁可用慢的逐条路径，也不留一幅冻住的画面）。 */
                                if (!dl_pixel_probe()) {
                                    /* ★v2.15：如果这张正是"重试表"，它同样算重试失败（表跑完了却
                                     *   没画像素 —— 和看门狗是两回事，所以不去重试，直接停用）。
                                     *   必须在 dl_disable() 之前打印：它会把重试现场清掉。 */
                                    if (g_dl_retry_n) {
                                        g_dl_retry_bad++;
                                        bsp_printf("EV dl retry %d/%d failed (list ran but drew no pixels)\r\n",
                                                   g_dl_retry_n, DL_RETRY_MAX);
                                        dl_wd_summary("retry drew no pixels");
                                    }
                                    dl_disable("1st list drew no pixels");
                                    g_dl_fbwait = 1; g_dl_ft0 = tick32();
                                    g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
                                    hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                                    g_pass_armed = 0;
#endif
                                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                                }
                            }
                            /* ★v2.15 成本行：这张表**跑完了**（BUSY=0 之后 DL_PERF 才是这张表的
                             *   周期数）⇒ 记一行"n / cycles / cyc/sprite"，1Hz 门控不刷屏。
                             *   放在"重试 ok"之前打：先给数、再给结论，日志顺序更好读。 */
                            dl_cost_report(g_dl_inflight_sp);
                            /* ★v2.15 重试成功的判据：那张重试表**跑完了且没报错**、而且
                             *   上面的像素探针也没把它否掉（探针不过时 dl_disable() 已经把
                             *   g_dl_mode 清 0 ⇒ 这里绝不会把"没画像素"报成 ok）。
                             *   成功后**没有"恢复额度"这回事**了：策略是"一次事件一次机会"，
                             *   下一次看门狗事件会重新走一遍 dl_wd_decide()（距上次 >1s 才重试）。 */
                            if (g_dl_retry_n && g_dl_mode) {
                                g_dl_retry_ok++;
                                bsp_printf("EV dl retry %d/%d ok (cumulative ok=%d bad=%d)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX,
                                           (int)g_dl_retry_ok, (int)g_dl_retry_bad);
                                g_dl_retry_n = 0;
                            }
                            if (g_dl_mode && g_dl_pend >= 0) {
                                dl_go(g_dl_pend, g_dl_pend_n,
                                      g_fb_back + (uint32_t)y0 * FB_STRIDE);
                                g_dl_buf = g_dl_pend; g_dl_pend = -1;
                                g_dl_inflight_sp = g_dl_pend_sp;   /* 成本行的 n= 跟着这张表走 */
                                if (g_dl_pend_last) { g_dl_pend_last = 0; hw_frame_pushed = 1; }
                            } else {
                                g_dl_inflight = 0;     /* 下一圈在下面那个分支里收尾/继续发 */
                            }
                        }
                    } else {
                        cpu_backoff(BLT_WAIT_NOP);
                    }
                } else {
                    /* 无在飞、无待发：要么发下一段，要么给本趟收尾 */
                    int fin = 0;
                    if (hw_frame_pushed) {
                        /* 半途打开 'l' 的情形：本趟的命令是逐条路径发的 ⇒ 用两条路径
                         * 共同的"引擎真的空闲"判据收尾（DFU 不忙 + 引擎 DONE/FIFO 空） */
                        if (poll && !(blt_rd(BLT_DL_STATUS) & DL_ST_BUSY) &&
                            blt_idle_st(blt_stat())) fin = 1;
                        else cpu_backoff(BLT_WAIT_NOP);
                    } else if (hw_i >= n) {
                        fin = 1;                   /* 防御：没有可发的段了 */
                    } else {
                        int c = 0, last = 0, b = 1 - g_dl_buf;
                        int i0  = hw_i;            /* ★v2.15：本段画了几个精灵（成本行的 n=）*/
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
                        /* 本趟起点：先拍快照 → 再做开画前的一次性动作（三缓冲：查 clean/
                         * 选目标/下清屏命令，它决定本趟要不要命令式重铺）→ 最后才建段。
                         * ★ 铺底只允许出现在**本趟第一段的首条**（hw_i==0）：否则它会盖掉
                         *   同一趟前面几段已经画好的块。 */
                        if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                        if (hw_i == 0 && !g_pass_armed) {
                            g_pass_armed = 1;
                            repaint_hw = hw_pass_arm(y0, hw_h(path));
                            rep = repaint_hw ? dl_rep_id(path) : -1;
                        }
#endif
                        {
                            /* ★v2.13：本趟第一段（hw_i==0）就是"打开后第一张表" ⇒ 记下块 0 的
                             * 精灵中心地址，等它跑完用它验"像素到底落没落"（见 dl_pixel_probe()）。
                             * FILL 场景的色块可能恰好就是背景色（1/65536），那种情况不做探针。 */
                            int first_seg = (hw_i == 0);
                            dl_build((uint32_t *)DL_LIST_ADDR(b), &hw_i, n, scene, alpha, clear_pp,
                                     rep, &c, &last);
                            if (rep >= 0) repaint_hw = 0;
                            if (g_dl_report && first_seg) {
                                blk_t *b0 = &g_sc[SIDE_HW][0];
                                g_dl_probe_px = 0;
                                if (!(scene == SC_FILL && b0->color == (uint16_t)COL_BG))
                                    g_dl_probe_px = g_fb_back
                                        + (uint32_t)(b0->ty + y0 + SPR_H / 2) * FB_STRIDE
                                        + (uint32_t)(b0->tx + SPR_W / 2) * 2u;
                            }
                        }
                        cache_evict();         /* 写穿屏障：描述符必须对 DDR/引擎可见 */
                        dl_go(b, c, g_fb_back + (uint32_t)y0 * FB_STRIDE);
                        g_dl_buf = b; g_dl_inflight = 1;
                        g_dl_inflight_sp = hw_i - i0;   /* ★v2.15：成本行按这张表算 */
                        if (last) hw_frame_pushed = 1;
                    }
                    if (fin) {
                        /* ★ 与逐条路径**完全同一段收尾**（口径不许有第二套） */
                        hw_frames++; hw_frame_pushed = 0; hw_i = 0;
                        hw_fifo_full = 0;
                        hw_done = 1;
                        if (clear_pp) repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                        g_pass_armed = 0;
#endif
                        /* ★v2.15：半途打开 'l' 时本趟的命令是逐条路径发的 ⇒ 它的秒表在这一刻
                         *   结算（成本行口径见 cmd_cost_report）。列表路径发的表 g_cmd_t0=0 ⇒ 空转。*/
                        cmd_cost_report(n);
                    }
                }
            }
            /* ============ 逐条下发路径（**默认**，渲染部分一行未改）============ */
            else if (hw_frame_pushed) {
                /* 等引擎把本趟画完：**一圈最多读一次 STATUS**，同一个状态字复用。
                 * 轮询节奏：SPLIT/CPU 模式下下面 CPU 段每圈都要画一块，退避会拖慢它
                 * ⇒ 那两种模式每圈照读；纯硬件模式 CPU 侧本来就无活可干 ⇒
                 * 每 4 圈读一次 + 其余圈纯 ALU 退避（与 COPY 窗口同一套参数）。 */
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
                if (poll && blt_idle_st(blt_stat())) {
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
                    hw_fifo_full = 0;          /* 新一趟从"未知"开始，第一圈就正常读 */
                    hw_done = 1;
                    if (clear_pp) repaint_hw = 1;
#if FB_TRIPLE_BUFFER
                    g_pass_armed = 0;          /* ★v2.7：下一趟开头重新做"查 clean + 选目标 + 下清屏命令" */
#endif
                    /* ★v2.15 成本行（同口径对照）：本趟是逐条路径推的 + 引擎已空闲 ⇒
                     *   用本趟起点到此刻的墙钟拍数算一次"逐条路径 pi/精灵"，与列表路径那行
                     *   直接比大小。1Hz 门控、稳态每秒最多一行（见 cmd_cost_report）。 */
                    cmd_cost_report(n);
                } else if (path == PATH_HW) {
                    cpu_backoff(BLT_WAIT_NOP);
                }
            } else {
                int y0 = hw_y0(path);
                /* ★ FIFO 余量：本圈**唯一**一次 COUNT 读。纯硬件模式下若上一圈已经读满，
                 *   先按 BLT_WAIT_MASK 退避几圈再读 —— 引擎取一条指令要几十 us、
                 *   而 FIFO 还有 200 条的缓冲，退避 4*~2us 绝不会把引擎饿着，却能把
                 *   "满时每圈一次 COUNT 读"降到 1/4（N=6000 那种长指令流时才走到这里）。
                 *   SPLIT/CPU 模式不这么干：下面 CPU 段每圈都要画一块，退避会拖慢
                 *   CPU 侧的诚实工作量。 */
                if (hw_fifo_full && path == PATH_HW && ((it & BLT_WAIT_MASK) != 0u)) {
                    cpu_backoff(BLT_WAIT_NOP);
                } else {
                    uint32_t room = blt_push_room();
                    uint32_t budget = HW_PUSH_BUDGET;
                    /* ★ 一趟的起点：把场景位置冻进 (tx,ty)（hw_i==0 且上一趟已完成）。
                     *   放在 FIFO 余量判断之前 —— 即使这圈 FIFO 满、一条都推不出去，
                     *   快照也已就位，本趟剩下所有块必然用同一个位置。
                     *   ★v2.15：这**也**是一趟的计时起点（成本行的逐条路径口径）：
                     *   只在本趟还没开始计时时置一次，跑完由 cmd_cost_report() 清零。 */
                    if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
                    if (hw_i == 0 && g_cmd_t0 == 0) g_cmd_t0 = tick32();
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                    /* ---------------- ★v2.7 三缓冲：本趟开画前的一次性动作 ----------------
                     * ①~⑤ 的顺序与理由见 hw_pass_arm() 的注释（列表路径共用同一段）。
                     *   ④ 不干净 → **退回改动前那条命令式区域清屏**（发一条 FILL 整片）：
                     *      语义与老版本逐位相同，宁可多花 568k 周期也绝不在一张脏底上作画。 */
                    if (hw_i == 0 && !g_pass_armed) {
                        g_pass_armed = 1;
                        repaint_hw = hw_pass_arm(y0, hw_h(path));
                    }
#endif
                    if (repaint_hw && room > 0u) {
                        blt_fill(g_fb_back + (uint32_t)y0 * FB_STRIDE, FB_STRIDE,
                                 FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
                        repaint_hw = 0;
                        room--;
                    }
                    while (hw_i < n && room > 0u && budget-- > 0u) {
                        blk_t *b = &g_sc[SIDE_HW][hw_i];
                        uint32_t need = 1u;
                        /* ★ 擦除条件（仅 clear_pp=0 时才会走到）：ALPHA **必须每次都擦**，
                         *   其余可以"没动就不擦"。FILL/KEY 是幂等的（重画同一块结果不变），
                         *   而 ALPHA 是 dest = blend(src, dest) —— 不擦就再混一次 ⇒ 一次比
                         *   一次暗。板级现象正是：方块不动时逐帧变暗、每次场景步进（移动后
                         *   才擦）亮度恢复 ⇒ 以 25Hz 周期性忽明忽暗。
                         *   擦 + 画是两条引擎指令 ⇒ need=2，两条一起凑够余量才发，绝不半发。 */
                        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
                            need = 2u;
                        if (room < need) break;
                        if (need == 2u)
                            blt_fill(g_fb_back + (uint32_t)(b->dy + y0) * FB_STRIDE
                                              + (uint32_t)b->dx * 2u,
                                     FB_STRIDE, b->sz, b->sz, COL_BG);
                        {                                              /* 立刻画到本趟快照位置 */
                            uint32_t dst = g_fb_back + (uint32_t)(b->ty + y0) * FB_STRIDE
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
                        room -= need;
                        if (++hw_i >= n) { hw_frame_pushed = 1; break; }
                    }
                    hw_fifo_full = (room == 0u) ? 1 : 0;   /* 满了 ⇒ 下一圈先退避 */
                }
            }
        }

        /* ---------------- CPU 侧：每圈一块，相邻式擦+画，同样用本趟快照 ----------------
         * ★ 语义与 comptest2 完全一致（先擦后画、逐块擦旧矩形），**不跟随 clear_pp**：
         *   这是"纯 CPU"该有的工作量，动了它 CPU-vs-HW 的帧率对比就不诚实了。 */
        if (!back_busy && path != PATH_HW) {
            int y0 = cpu_y0(path);
            blk_t *b;
            /* 一趟的起点（cpu_i==0）：CPU 侧的快照点，与硬件侧同理 */
            if (cpu_i == 0 && snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
            if (repaint_cpu) {                 /* 场景/路径刚变过 → 先把这片区域铺背景 */
                cpu_fill32(g_fb_back, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
                repaint_cpu = 0;
            }
            b = &g_sc[SIDE_CPU][cpu_i];
            /* 同硬件侧：ALPHA 必须每次重铺背景（否则混合逐次叠加、越来越暗） */
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
                cpu_fill32(g_fb_back, b->dx, b->dy + y0, b->sz, b->sz, COL_BG);
            if (scene == SC_FILL)
                cpu_fill32(g_fb_back, b->tx, b->ty + y0, b->sz, b->sz, b->color);
            else if (scene == SC_ALPHA)
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
            else
                cpu_key_sprite(b->tx, b->ty + y0);
            b->dx = b->tx; b->dy = b->ty;
            if (++cpu_i >= n) {
                cpu_i = 0; cpu_frames++;
                cpu_done = 1;
            }
        }

        /* ---------------- 信息条落屏（y 0..16，**在渲染区之外**） ----------------
         * y 0..16 不会被每趟的整片重铺碰到（硬件侧 FILL 从 y=16 起、CPU 侧从
         * cpu_y0()=16/280 起），所以字可以常驻，不会被渲染区擦掉。
         * ★ 事件驱动：只有 g_osd_dirty（内容真的变了）才重画 —— 稳态 1 次/秒（fps
         *   一秒才变一次）+ 按键；旧版按"≥16 个已发布帧且 ≥300ms"的固定节拍重画
         *   ≈3.3 次/秒，且每次都要铺满整条 960x16。
         * ★ 只在"上屏"不在飞时重画：显示缓冲正被引擎整帧搬运的过程中写后台缓冲，
         *   可能让某一帧拍到"半张信息条"（旧版没有这个门控）。
         * ★ FLIP 路径额外一条：信息条必须出现在**当前后台缓冲**里 —— 下一趟翻转
         *   就轮到它上屏。所以判据多一个 `!g_bar_ok[]`：内容变了（两个缓冲都作废）
         *   或本缓冲还没画过就重画。稳态下每个缓冲每种内容只画一次。 */
#if FB_FLIP_PUBLISH
#if FB_TRIPLE_BUFFER
        /* ★v2.7 三缓冲：信息条要落在**当前正在画的那块**（g_draw3）里 —— 下一趟就轮到它上屏 */
        if (!back_busy && (g_osd_dirty || !g_bar_ok[g_draw3])) {
            osd_blit(g_osd_line, path_label(path));
            /* 分隔条只在分屏模式画：单模式是整屏渲染，中间不该有一条线 */
            if (path == PATH_SPLIT)
                cpu_fill32(g_fb_back, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
            if (g_osd_dirty) { g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0; }
            g_bar_ok[g_draw3] = 1;
            g_osd_dirty = 0;
        }
#else
        if (!back_busy && (g_osd_dirty || !g_bar_ok[g_disp_sel ^ 1u])) {
            osd_blit(g_osd_line, path_label(path));
            /* 分隔条只在分屏模式画：单模式是整屏渲染，中间不该有一条线 */
            if (path == PATH_SPLIT)
                cpu_fill32(g_fb_back, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
            if (g_osd_dirty) { g_bar_ok[0] = 0; g_bar_ok[1] = 0; }  /* 内容变了：两块都作废 */
            g_bar_ok[g_disp_sel ^ 1u] = 1;                          /* 当前后台缓冲已画好 */
            g_osd_dirty = 0;
        }
#endif
#else
        if (g_osd_dirty && !back_busy) {
            osd_blit(g_osd_line, path_label(path));
            /* 分隔条只在分屏模式画：单模式是整屏渲染，中间不该有一条线 */
            if (path == PATH_SPLIT)
                cpu_fill32(g_fb_back, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
            g_osd_dirty = 0;
        }
#endif
    }
    return 0;
}
