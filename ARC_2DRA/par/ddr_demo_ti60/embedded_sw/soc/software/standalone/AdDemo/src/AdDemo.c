/* =============================================================================
 * AdDemo.c — FPGA 2D 加速器「纯硬件渲染」演示（AdDemo）
 * -----------------------------------------------------------------------------
 * ★ 与 FinalDemo（约 2840 行）的根本区别：**一个 CPU 像素都没有**
 *   FinalDemo 的卖点是"硬件加速 vs 纯 CPU 同屏对比"，右半屏由 CPU 逐像素直写；
 *   AdDemo 把 CPU 彻底赶出像素通路 —— 屏幕上**每一个像素**（含信息条上的每一个字）
 *   都由加速器写出来。CPU 只做四件事：
 *     ① **烘焙资源**：开机把三张图集（RGB565 圆盘 / ARGB4444 辉光 / 8x8 字形）与
 *        一张 960x524 的程序化背景写进 DDR —— 一次性，与 FinalDemo 的 build_atlas 同源；
 *     ② **组命令流**：每精灵「1 个属性字（ATTR_PORT）+ 8 个命令字」推进 CMD FIFO；
 *     ③ **调度清屏引擎 + 帧边界发布**：三缓冲 FLIP，整帧一次 DDR 搬运都不做；
 *     ④ 串口/UI + 每秒统计。
 *   渲染路径上没有任何 `fb[x] = c` 这样的语句 —— 这是本 Demo 的核心主张。
 *
 * ★ 屏幕布局（帧缓冲 960x540，三缓冲轮转：显示 A / 画 B / 预清 C）
 *      y   0 ..  16   信息条（**在渲染区之外**：每趟的整片重铺不会碰它）
 *                      左：FPS=nn N=nnnn SZ=nn MPX=nnnn SCd:NAME A=nnn B=nnn [FR][F][X][Y][Q]
 *                      右：HW ONLY（右对齐）
 *      y  16 .. 540   渲染区（960x524）—— 全部由引擎的 FILL/COPY/ALPHA/KEY 写
 *   ★ 信息条是**引擎画的**：先 FILL 一条黑底，再把每个字符当成 8x8 的 KEY 精灵从
 *     字形图集里抠出来。所以"纯硬件渲染"这句话在屏幕上是自洽的。
 *
 * ★ 五个场景（串口键 1..5，全部是"现代引擎"该有的观感）
 *   1 GLOW  辉光粒子场：ARGB4444 精灵 + **加算混合** + 每精灵独立 alpha（ATTR 侧口）
 *   2 FADE  LUT 淡入淡出：扫描输出颜色 LUT 全屏淡到黑再淡回来（**零 DDR 带宽**）
 *   3 CLIP  裁剪演示：scissor 把 playfield 锁在中央矩形；矩形外的 HUD 侧栏照画不误
 *           （按 'x' 关掉 scissor ⇒ 立刻看到精灵/扫掠条糊到 HUD 上 = 最直观的 A/B）
 *   4 LAYER 分层：整幅背景 COPY（大图搬移）+ 大量加算辉光 + 周期性白闪
 *   5 THRU  吞吐：把精灵数顶到帧预算边缘，屏幕上直接读 FPS / N / Mpx/s / 引擎占用
 *
 * ★ 冻结的 RTL 接口（本文件按它编程；下面每条都在主机自检里逐位验过）
 *   ① 属性侧口 ATTR_PORT(0x8C, W)：每写 1 个 32bit 属性字 = 给**下一条命令**的属性，
 *      引擎每条命令弹 1 个，按序配对 ⇒ **属性字必须写在命令 8 个字之前**。
 *      FIFO 为空 = 硬件默认（blend 0 / RGB565 / global_alpha 255 / flags 0）
 *      = **0x0000_3FC0** = 今天的行为；本文件一条属性都不写时，硬件看到的就是它。
 *      位域：[3:0] blend(0=op 默认 1=alpha 2=加算 3=乘) [5:4] fmt(0=565 1=1555 2=4444 3=保留)
 *            [13:6] global_alpha(255=无) [15:14][23:16] 保留 [31:24] flags(bit0 跳过 alpha 测试,
 *            bit1 强制不透明)
 *   ② scissor：CLIP_X0(0x90，**含**) X1(0x94，**不含**) Y0(0x98，含) Y1(0x9C，不含)
 *      CLIP_CTRL(0xA0, bit0=使能，**可回读**)，默认关。区间**半开** [x0,x1) x [y0,y1)；
 *      坐标是**本条命令目的矩形的局部坐标**（原点 = 该命令 dst_base 那个像素，
 *      第 0 行 = 第一行）⇒ 屏幕坐标的窗口必须按每条命令的 dst 平移一次（clip_local()）；
 *      平移后与目标矩形无交集 ⇒ 这条命令**整条不发**（引擎也不会为它取数）。
 *      全屏目的矩形时局部坐标 == 屏幕坐标。引擎在**命令起始**锁存这组寄存器。
 *      ★★ 因此信息条 / HUD 侧栏 / 裁剪边框 / 场景底图（"屏幕骨架"）**只能在 CLIP_CTRL
 *      关着的时候下发**：它们的 dst 在 (8,4) 这种位置，平移后窗口与字形矩形无交集，
 *      裁开就整条消失（上板症状 = 场景 3 信息条与 HUD 不见了）。这条不变量由
 *      CLIP_GUARD（下发出口的唯一守卫）+ clip_off_verified()（回读确认）两道保证。
 *   ③ 扫描输出 LUT（双 bank，显示 bank 只在帧边界换）：
 *      LUT_ADDR(0xA4, [9:8]=通道 0=R 1=G 2=B（**两位**，3 保留）, [7:0]=下标)
 *      LUT_DATA(0xA8, 8bit，写它就产生 1 拍写脉冲)
 *      LUT_CTRL(0xAC, bit0=使能（请求，**立即**生效）, bit1=**LUT_DATA 写进哪个 bank**)
 *      LUT_STAT(0xB0, bit0 = **正在显示** 的 bank)
 *      **显示读的是 ~(帧边界锁存的 bit1)** ⇒ 写口与显示口永远指向不同的 bank，
 *      写表在物理上碰不到正在显示的那张表。
 *      ★ 正确的发布序列（按 rtl/video/fb_scanout.v + rtl/tb/tb_scanout_lut.v 的实测语义）：
 *        ① 读 0xB0 → D = 现在显示的 bank；
 *        ② 0xAC bit1 = **~D** ⇒ 新表整张写进**非显示** bank；
 *        ③ 写 3x256 项（R/G/B）；
 *        ④ 0xAC bit1 = **D**（写表之前正在显示的那个 bank）⇒ 帧边界锁存后显示 = ~D
 *           = 刚写好的那张表。★ 早期规格写的"bit1 = 刚写的 bank"**差一个反相**：照它
 *           做显示 bank 永远不动（表写进去了却一辈子不上屏 = 没有 fade、白闪表洗不掉）。
 *
 * ★★ 配对纪律（本文件最重要的一条软件约定，改动前必读）
 *   ATTR 是**一条 FIFO**，引擎只是"每条命令弹一个"，它**不知道**你写了几个。
 *   所以一旦开始用属性，就必须**每条命令都写、且只写一个**：
 *     用属性时 —— 想要默认行为的那条命令也要写 ATTR_DEFAULT(=0x00003FC0)；
 *     不用属性时 —— 一条都不写（'y' 关掉属性侧口），此时逐位回到 FinalDemo 的语义。
 *   ★ 混合"写了/没写"必然错位：后写的属性字会被前面那条没写属性的命令吃掉。
 *   本工程把这件事收敛到**唯一一个函数 blt_emit()** 里（见"引擎指令"一节），
 *   没有任何一条命令绕过它 ⇒ 错位在结构上不可能发生（启动自检里也断言了这条）。
 *
 * ★★ 原先要"猜"、现在已冻结的几条（本文件的实现方式；上板按这里重点验）
 *   a) **CLIP_* 的采样时刻**：引擎在**命令起始**锁存这组寄存器 ⇒ 命令中途改不会撕裂
 *      正在画的那条。于是"每画一条换一次局部窗口"必须在**引擎彻底空闲**时写寄存器：
 *      本文件把它做成独立的一步（ST_CLIP，只有窗口真的变了才走），并且**窗口相同的
 *      连续命令共用**同一个窗口（整幅落在窗口里的精灵都是 [0,SZ)x[0,SZ)，不重写）。
 *      代价是场景 3 里每个"窗口变化"一次空闲等待，换来的是裁剪结果与 RTL 逐像素一致。
 *      ★ 这个"空闲等待"必须有界：引擎一旦停机（STATUS.ERR = 非法 op 电平锁存，只有软复位
 *      能清），无限等下去就是上板看到的"卡死在场景 3、切不回去"。见下面 (h)。
 *   b) **属性字的 global_alpha 与命令字 w6 的 alpha 谁优先**仍然没有规定。本文件的做法是
 *      "**从不同时依赖两者**"：要每精灵 alpha 时把 alpha 放进属性字、w6 写 0xFF（=无）；
 *      走默认路径时一条属性都不写、alpha 照旧放 w6。两种语义下结果都相同。
 *   c) **LUT 的 bank 协议**：以 RTL 实测语义为准（见上面 ③ 的四步）——**发布值 = 写 bank 的
 *      反相 = 写表之前读到的那个显示 bank**。上板症状（信息条糊、fade 完全不生效、场景 4
 *      一片白洗不掉）就是老文档那句"bit1 = 刚写的 bank"造成的：显示 bank 永远不动，
 *      写进去的表一辈子不上屏、屏上永远停着最早那张（白闪）表。
 *      极性不认文档、**实测标定**（lut_bank_calib）：写一张已知表 → 按权威语义发布 →
 *      等一个帧边界 → 回读 0xB0；显示 bank 变成"刚写的那张"⇒ display=~write（权威），
 *      没变 ⇒ display=write（老语义）。结果打在 `EV lut polarity` 行里，用户可直接读。
 *      开机还把**两个** bank 都灌成恒等表 ⇒ 之后任何时刻显示 bank 里要么是本文件刚写的表、
 *      要么是恒等表；不需要 LUT 的场景一律发布"恒等表 + 使能 0"（陈旧表洗不了屏）。
 *   h) **所有"等引擎"的等待都有界**（本次修的第三个问题）：引擎停机（STATUS bit2 = ERR，
 *      电平锁存、只有软复位能清）时 DONE/FIFO_EMPTY 永远不成立 ⇒ 老代码在
 *      ST_RESTART/ST_FENCE/ST_CLIP/ST_WAIT 与"等 FIFO 余量"处无限空转：屏幕冻结、
 *      切场景也看不出变化（串口循环还在跑，但一帧都画不出来）。现在每个等待超过
 *      ST_WAIT_TICKS（200ms ≈ 12 场）就打印一次诊断（带 STATUS/COUNT）、软复位引擎、
 *      忘掉 CLIP 镜像、重开本趟；翻转确认连续失败也会"认下这次翻转继续走" ⇒
 *      **任何时刻都能切场景，串口命令循环绝不被阻塞**。
 *   d) **ATTR_PORT 只写、读不回**，无法直接探测它是否存在。本文件用"同一颗新 bitstream
 *      才会一起出现的 CLIP_* / LUT_* 读回校验"来判定（feat_probe）：两组新寄存器都能
 *      写进读出 ⇒ 认为属性侧口也在；否则自动退回"不发属性字"的默认路径并打印原因。
 *      ⇒ 今天这颗 bitstream 上 AdDemo 也能跑（只是没有加算辉光/裁剪/LUT 效果）。
 *   e) **ARGB4444 的通道排布**已冻结为 **A4R4G4B4**（A[15:12] R[11:8] G[7:4] B[3:0]），
 *      RTL 侧把 4bit 字段**位复制**成 8bit（a4=8 ⇒ a8=136）；打包收敛到 argb4444_pack()
 *      一处，自检按四个"抽头"（argb4444_a/r/g/b）逐位读回验。**不是** ARGB1555 那种
 *      "RGB565 字段位置 + bit15 = A"的排布（1555 本 Demo 不生成，规则只写在注释里）。
 *   f) **CLIP 窗口端点**已冻结为**半开** [x0,x1) x [y0,y1)（X1/Y1 不含）⇒ 窗口直接写
 *      [200,760)x[112,488)，不需要再 -1；边框照旧画在窗口外 2 像素，边界一眼可见。
 *   g) **显示列表（DL）路径没有 ATTR 槽位**（16B 描述符 4 个字全部占满，冻结接口也没给
 *      描述符留属性字段）⇒ AdDemo **只用逐条下发路径**，这样每个精灵都能带自己的属性。
 *      若以后要让 DL 也支持属性，需要先在 RTL/接口里定义"属性从哪来"。
 *
 * ★ printf 雷区（BSP 的 print.h 是 mini 版）：**只认 %c %s %d %X %x**。
 *   出现 %u / 宽度数字 / %% 会让它错位消耗 va_arg，后面的 %s 拿整数当指针直接挂死。
 *   本文件所有无符号量都先 (int)/(unsigned) 强转再用 %d/%x。
 * ============================================================================= */

#include <stdint.h>
#include "bsp.h"
#include "compatibility.h"      /* SYSTEM_UART_0_IO_CTRL 等外设映射 */

/* ============================== 地址与寄存器 ============================== */
#define FB_WIDTH      960
#define FB_HEIGHT     540
#define FB_STRIDE     (FB_WIDTH * 2)               /* 1920 B/行 */

#define DDR_BASE      0x00001000UL
#define ATLAS_BASE    (DDR_BASE + 0x00200000UL)    /* RGB565 圆盘图集（KEY 抠图源） */
#define GLOW_BASE     (DDR_BASE + 0x00210000UL)    /* ARGB4444 辉光图集（加算混合源） */
#define FONT_BASE     (DDR_BASE + 0x00220000UL)    /* 8x8 字形图集（信息条 KEY 抠图源） */
#define FB_BASE       (DDR_BASE + 0x00300000UL)    /* 显示缓冲 0 */
#define FB_BACK       (DDR_BASE + 0x00500000UL)    /* 缓冲 1 */
#define FLUSH_SCRATCH (DDR_BASE + 0x00600000UL)    /* 缓存写穿屏障/对齐自检用的 8KB 临时区 */
#define BG_BASE       (DDR_BASE + 0x00604000UL)    /* 960x524 程序化背景（开机烘焙一次） */
#define FB_BUF2       (DDR_BASE + 0x00700000UL)    /* 缓冲 2（三缓冲 FLIP 用） */
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)
/* 背景图占 960*524*2 = 0x000F5A00 B：0x604000 + 0xF5A00 = 0x6F9A00 < FB_BUF2(0x700000) ✓
 * （FLUSH_SCRATCH 只用到 0x602000 为止，两者不重叠） */

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
#define   BLT_IRQ_FRAME     (1UL << 1)     /* 扫描输出帧边界中断（0x10 W1C / 0x14 使能） */
#define BLT_IRQ_EN          0x14
#define BLT_SCAN_DBG        0x20
/* ★ SCAN_DBG(0x20) 的位域（RTL 口径）：{abort[31:16], underrun[15:0]}
 *   abort    = 扫描输出被**中断**（读请求被抢占/放弃）的累计次数；
 *   underrun = 扫描输出**取数欠载**（FIFO 空、这一场没数据可显示）的累计次数。
 *   只在这里解码一次：开机自检行与每秒的 EV diag 行共用 ⇒ 两处口径不可能不一致。 */
#define BLT_SCAN_ABORT(sc)    (((sc) >> 16) & 0xFFFFUL)
#define BLT_SCAN_UNDERRUN(sc) ((sc) & 0xFFFFUL)
#define BLT_FB_SEL          0x24           /* [1:0] 请求显示哪块缓冲（帧边界生效） */
#define BLT_FB_STAT         0x28           /* [1:0] 已生效选择 [31:16] 场计数 */
#define BLT_CLR_ADDR        0x2C           /* 并发清屏引擎：起始字节地址 */
#define BLT_CLR_STRIDE      0x30           /*                 字节/行 */
#define BLT_CLR_WH          0x34           /*                 (h<<16)|w */
#define BLT_CLR_COLOR       0x38           /*                 RGB565 背景色 */
#define BLT_CLR_CTRL        0x3C           /* bit0=GO(1 拍) [3:2]=目标缓冲 bit4=ERR_CLR */
#define   BLT_CLR_GO        (1UL << 0)
#define   BLT_CLR_ERRCLR    (1UL << 4)
#define BLT_CLR_STAT        0x40           /* bit0=BUSY bit1=目标已清 [5:2]=四块 clean 位图 bit6=ERR */
#define   BLT_CLR_STAT_BUSY (1UL << 0)
#define   BLT_CLR_STAT_ERR  (1UL << 6)
#define BLT_DRAW_SEL        0x44           /* [1:0]=引擎正在画的缓冲（硬件互斥的另一半） */
#define BLT_CLR_CYC         0x48           /* 上次 clear 的周期数 */

/* ★ 本次新增（冻结接口）：属性侧口 / scissor / 扫描输出颜色 LUT */
#define BLT_ATTR_PORT       0x8C           /* W：每写 1 个字 = 给下一条命令的属性 */
#define BLT_CLIP_X0         0x90           /* 局部坐标，含 */
#define BLT_CLIP_X1         0x94           /* 局部坐标，**不含**（半开） */
#define BLT_CLIP_Y0         0x98           /* 含 */
#define BLT_CLIP_Y1         0x9C           /* 不含 */
#define BLT_CLIP_CTRL       0xA0           /* bit0=使能（RW，**回读 bit0 = 实机状态**） */
#define   BLT_CLIP_EN       (1UL << 0)
#define BLT_LUT_ADDR        0xA4           /* [9:8]=通道(0=R 1=G 2=B，两位) [7:0]=下标 */
#define BLT_LUT_DATA        0xA8           /* 8bit 通道值（写它 = 1 拍写脉冲） */
#define BLT_LUT_CTRL        0xAC           /* bit0=使能（立即生效） bit1=**写** bank */
#define   BLT_LUT_EN        (1UL << 0)
#define   BLT_LUT_BANK      (1UL << 1)     /* LUT_DATA 写进哪个 bank（写口 = 当前值） */
#define BLT_LUT_STAT        0xB0
#define   BLT_LUT_STAT_BANK (1UL << 0)     /* 正在**显示** 的 bank（= ~帧边界锁存的 bit1） */

/* CMD_FIFO_COUNT 的单位是**指令条数**（rtl/cmd_fifo.v: cmd_count = word_count/8）。
 * ★ 属性字进的是**另一条** FIFO，不占命令条数 ⇒ 余量记账口径与 FinalDemo 一致。 */
#define BLT_FIFO_DEPTH      256
#define HW_FIFO_MARGIN      56
#define BLT_PUSH_LIMIT      (BLT_FIFO_DEPTH - HW_FIFO_MARGIN)      /* 200 条 */

/* 引擎操作码（与 rtl/pixel_path.v / blt_engine_fsm.v 一致） */
#define BLT_OP_COPY   0UL
#define BLT_OP_FILL   1UL
#define BLT_OP_ALPHA  2UL
#define BLT_OP_KEY    3UL

/* ============================== ★ 属性字编码（冻结接口 ①） ==============================
 * ==== ATTR_ENC_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 位域（与冻结接口逐位对应）：
 *   [3:0]   blend_mode   0=op 默认 1=alpha 2=加算 3=乘
 *   [5:4]   src_format   0=RGB565 1=ARGB1555 2=ARGB4444 3=保留
 *   [13:6]  global_alpha 255=无
 *   [15:14] / [23:16] 保留（必须 0）
 *   [31:24] flags        bit0=跳过 alpha 测试  bit1=强制不透明
 * ★ ATTR_DEFAULT 就是"FIFO 为空时硬件的默认值"的**等价字**：
 *   blend 0 / RGB565 / global_alpha 255 / flags 0 ⇒ 0x00003FC0。
 *   自检里断言 attr_word(0,0,255,0) == ATTR_DEFAULT，并逐位解回来验。 */
#define ATTR_BLEND_OP     0u
#define ATTR_BLEND_ALPHA  1u
#define ATTR_BLEND_ADD    2u
#define ATTR_BLEND_MUL    3u
#define ATTR_FMT_565      0u
#define ATTR_FMT_1555     1u
#define ATTR_FMT_4444     2u
#define ATTR_FLAG_ATEST   1u        /* bit0：跳过 alpha 测试 */
#define ATTR_FLAG_OPAQUE  2u        /* bit1：强制不透明 */

static uint32_t attr_word(unsigned blend, unsigned fmt, unsigned ga, unsigned flags)
{
    return ((uint32_t)(blend & 0xFu) << 0)
         | ((uint32_t)(fmt   & 0x3u) << 4)
         | ((uint32_t)(ga    & 0xFFu) << 6)
         | ((uint32_t)(flags & 0x3u) << 24);
}
static unsigned attr_blend(uint32_t w) { return (unsigned)(w & 0xFu); }
static unsigned attr_fmt(uint32_t w)   { return (unsigned)((w >> 4) & 0x3u); }
static unsigned attr_ga(uint32_t w)    { return (unsigned)((w >> 6) & 0xFFu); }
static unsigned attr_flags(uint32_t w) { return (unsigned)((w >> 24) & 0x3u); }

#define ATTR_DEFAULT  attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u)   /* = 0x00003FC0 */
/* ==== ATTR_ENC_END ==== */

/* ============================== ★ ARGB4444 打包（冻结接口 ①：A4R4G4B4） ==============================
 * ==== ARGB4444_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 位域（与 RTL 的展开**逐位对应**；G/B 一换，每个辉光精灵都会偏色）：
 *   [15:12] A(4bit)   [11:8] R(4bit)   [7:4] G(4bit)   [3:0] B(4bit)
 * ★ RTL 把每个 4bit 字段**位复制**成 8bit（v8 = (v4 << 4) | v4 ⇒ a4=8 → a8=136）
 *   ⇒ 自检要比的真值就是"4bit 字段"，8bit 展开只是它的位复制（rep4to8）。
 * ★ ARGB1555 **不是**这个排布：它保持 RGB565 的字段位置（[15]=A、[14:10]=R、
 *   [9:5]=G、[4:0]=B），本 Demo 不生成 1555 图集，只在这里写明规则。
 * ★ 打包/读回都只走下面这一组函数 ⇒ "写进去的字段"与"读回来的字段"不可能各写各的。 */
#define A4444_A_SH   12
#define A4444_R_SH   8
#define A4444_G_SH   4
#define A4444_B_SH   0
#define A4444_MASK   0xFu

static uint16_t argb4444_pack(unsigned a4, unsigned r4, unsigned g4, unsigned b4)
{
    return (uint16_t)(((a4 & A4444_MASK) << A4444_A_SH) |
                      ((r4 & A4444_MASK) << A4444_R_SH) |
                      ((g4 & A4444_MASK) << A4444_G_SH) |
                      ((b4 & A4444_MASK) << A4444_B_SH));
}
/* 四个"抽头"：图上/屏上读回来的字段（自检按这四个函数逐位回验打包） */
static unsigned argb4444_a(uint16_t c) { return (unsigned)((c >> A4444_A_SH) & A4444_MASK); }
static unsigned argb4444_r(uint16_t c) { return (unsigned)((c >> A4444_R_SH) & A4444_MASK); }
static unsigned argb4444_g(uint16_t c) { return (unsigned)((c >> A4444_G_SH) & A4444_MASK); }
static unsigned argb4444_b(uint16_t c) { return (unsigned)((c >> A4444_B_SH) & A4444_MASK); }
/* RTL 侧的 4bit → 8bit 展开（位复制）：a4=8 ⇒ 136；自检按这条验"屏幕上的 8bit 值" */
static unsigned rep4to8(unsigned v4) { v4 &= A4444_MASK; return (v4 << 4) | v4; }
/* ==== ARGB4444_END ==== */

/* ============================== ★ LUT 表格（冻结接口 ③） ==============================
 * ==== LUT_TAB_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 两级**同一条公式**串起来（都在 0..255 上做定点、四舍五入）：
 *   先按 fade 压暗（fade=255 恒等、fade=0 全黑），再按 flash 提亮（flash=0 恒等、flash=255 全白）。
 * ★ LUT 在**扫描输出**侧、按 8bit 通道值查表 ⇒ 全屏特效**一次 DDR 读写都不做**
 *   （这正是"效果代码别和被测对象抢 DDR"那条教训的兑现）。
 * ★ 表格是**算出来的**（不是预算常量表）：fade/flash 每变一次就重算 3x256 项写进非生效 bank。 */
static unsigned lut_chan(unsigned v, unsigned fade, unsigned flash)
{
    unsigned x = (v * fade + 127u) / 255u;
    if (x > 255u) x = 255u;
    x = x + ((255u - x) * flash + 127u) / 255u;
    if (x > 255u) x = 255u;
    return x;
}

/* ---- 冻结接口 ③ 的两个纯函数（自检直接测这两个；量都在 [9:8]/[0] 上） ---- */
/* LUT_ADDR = (ch << 8) | index，ch = 0/1/2 = R/G/B。
 * ★ 通道字段是 [9:8] **两位**：老写法"[8] = 通道"只能编出 0/1 ⇒ **通道 2（蓝）永远
 *   寻不到**（(2 & 1) << 8 = 0，直接撞到 R 的表上）。 */
#define BLT_LUT_CH_SH   8
#define BLT_LUT_CH_N    3
static uint32_t lut_addr(unsigned ch, unsigned idx)
{
    return ((uint32_t)(ch & 3u) << BLT_LUT_CH_SH) | (uint32_t)(idx & 0xFFu);
}
/* LUT_STAT[0] = **正在显示** 的 bank；写口（0xAC bit1）只能指另一半 ⇒ 写表不撕裂。 */
static unsigned lut_write_bank(unsigned stat) { return (unsigned)(stat & 1u) ^ 1u; }

/* ---- ★ fade / flash 时间线（毫秒域；自检直接测这三个纯函数） ----
 * 上板 bug：这两个常数本来是**毫秒**，却被直接当 CLINT 拍数用（100MHz ⇒ 1ms = 100000 拍）
 *   ⇒ FADE_PERIOD_MS=3600 实际 36µs、FLASH_MS=220 实际 2.2µs：fade 相位每次取值都是随机的
 *   （看起来"根本没淡"），白闪 2.2µs 就衰减到 0 且每 30µs 重新点火（看起来"卡在全白"）。
 * 现在单位只允许在**这里**换算：外面一律走 fx_elapsed_ms()，拍数绝不再当毫秒用。 */
#define MS_TICKS       (BSP_CLINT_HZ / 1000u)       /* 1 毫秒 = 多少 CLINT 拍（100MHz ⇒ 100000） */
#define FADE_PERIOD_MS 3600u                        /* 淡入淡出整周期 3.6s（毫秒，真毫秒） */
#define FLASH_MS       220u                         /* 白闪持续 220ms（毫秒，真毫秒） */
#define FLASH_REARM_MS 3000u                        /* 分层场景自动白闪间隔 3s（毫秒） */
/* CLINT 拍差 → 毫秒（唯一的换算点；回绕靠无符号减法） */
static uint32_t fx_elapsed_ms(uint32_t now, uint32_t t0)
{
    return (uint32_t)((now - t0) / MS_TICKS);
}
/* 相位（毫秒）→ fade 表值：255 恒等、0 全黑；3.6s 一循环 = 淡出 1.2s → 停 0.3s → 淡入 1.2s → 停 0.9s */
static unsigned fx_fade_of_ms(uint32_t ph_ms)
{
    ph_ms = ph_ms % FADE_PERIOD_MS;
    if (ph_ms < 1200u) return 255u - (unsigned)((ph_ms * 255u) / 1200u);
    if (ph_ms < 1500u) return 0u;
    if (ph_ms < 2700u) return (unsigned)(((ph_ms - 1500u) * 255u) / 1200u);
    return 255u;
}
/* 白闪剩余毫秒 → flash 表值：220ms 处全白、线性衰减到 0 */
static unsigned fx_flash_of_ms(uint32_t left_ms)
{
    if (left_ms > FLASH_MS) left_ms = FLASH_MS;
    return (unsigned)((left_ms * 255u) / FLASH_MS);
}
/* ==== LUT_TAB_END ==== */

/* ============================== 画面分区 ============================== */
#define OSD_H        16
#define TOP_Y0       OSD_H                       /* 渲染区起点 */
#define PLAY_H       (FB_HEIGHT - TOP_Y0)        /* 524 */
#define OSD_GLYPH_W  8
#define OSD_GLYPH_H  8
#define OSD_TEXT_Y   4
#define OSD_TEXT_X0  8

/* ★ 信息条宽度上界（**静态可证**，启动自检里用真实 fmt_stat 再证一遍）：
 *   左串最长 = "FPS=99 N=6000 SZ=64 MPX=9999 SC5:LAYER A=255 B=100 FR F X Y Q"
 *            = 61 字符 = 488px ⇒ 文字 x ∈ [8, 496)，最后一个像素列 495；
 *   黑底按 OSD_LEFT_CH=72 字符铺 ⇒ x ∈ [8, 584)（留 11 个字符位余量）；
 *   右标签 "HW ONLY" = 7 字符 = 56px，右对齐 ⇒ x ∈ [904, 960)
 *     （右对齐的黑底按 OSD_RIGHT_PX = 8 字符 = 64px 预留 ⇒ x ∈ [896, 960)）。
 *   ⇒ 最坏情况左文字末端 496 与右标签起点 904 之间仍空 408px，**不可能重叠**。 */
#define OSD_LEFT_CH  72
#define OSD_LEFT_PX  (OSD_GLYPH_W * OSD_LEFT_CH)
#define OSD_RIGHT_PX (OSD_GLYPH_W * 8)
#define OSD_LABEL    "HW ONLY"

/* ============================== 场景枚举 ============================== */
#define SC_GLOW   0
#define SC_FADE   1
#define SC_CLIP   2
#define SC_LAYER  3
#define SC_THRU   4
#define SC_N      5

/* ★ 数量 N：钳位区间与步进（'+'/'n'/'-' 与 '=' 精确设置共用这一处枚举） */
#define N_MIN   16
#define N_MAX   6000
#define N_STEP  32
#define MAXPT   N_MAX

/* ============================== 颜色 ============================== */
#define COL_BG        0x0008u                    /* 渲染区背景（近黑，clear 引擎用它） */
#define COL_OSD_BG    0x0000u
#define COL_WHITE     0xFFFFu
#define COL_CYAN      0x07FFu
#define COL_AMBER     0xFD20u
#define COL_PANEL     0x1082u
#define COL_PANEL2    0x2104u
#define COL_CLIPEDGE  0x4A69u
#define KEY_COLOR     0xF81Fu                    /* 色键（洋红）：图集透明处 */

/* ============================== 精灵几何（唯一边长来源 = g_blk） ==============================
 * ★ 'k' 在 16 → 32 → 64 → 16 上循环；下面所有尺寸都是 g_blk 的别名，
 *   改尺寸只改 g_blk 一处（图集 / 场景 / 命令三边一起跟着走）。 */
#define BLK_LO   16
#define BLK_MID  32
#define BLK_HI   64
#define BLK_N    3
static const int g_blk_tab[BLK_N] = { BLK_LO, BLK_MID, BLK_HI };
static int g_blk = BLK_MID;              /* ★ 唯一边长来源（开机默认中档，观感最好） */

static int blk_idx(int sz) { int i; for (i = 0; i < BLK_N; i++) if (g_blk_tab[i] == sz) return i; return 0; }
static int blk_next(int sz) { return g_blk_tab[(blk_idx(sz) + 1) % BLK_N]; }

#define SPR_W       g_blk
#define SPR_H       g_blk
#define SPR_STRIDE  (SPR_W * 2)
#define SPR_RING    (SPR_W / 8)              /* 圆盘白环厚度：16→2px 32→4px 64→8px */

#define GLOW_VARIANTS   4                    /* 辉光配色档数（图集里纵向堆 4 张） */
#define GLOW_VAR_STRIDE (SPR_H * SPR_STRIDE) /* 每一档在图集里的字节跨度 */

/* ============================== 图集生成（纯函数，可在主机上重跑） ==============================
 * ==== ATLAS_GEN_BEGIN ====（主机自检原样取本段源码）
 * 需要外部先声明：static int g_blk; 以及 KEY_COLOR / COL_WHITE 两个宏、
 * SPR_W / SPR_H / SPR_RING 三个宏（本文件上面那几行原样抄即可）。
 * 两张图集都是**程序化生成**的（没有外部素材），尺寸跟随 g_blk：
 *   ① disc_color：RGB565 圆盘 —— 四角 = 色键、外圈白环、内部渐变（与 FinalDemo 同一套公式）。
 *      用途：CLIP 场景的抠图精灵 + 属性侧口不可用时的降级精灵。
 *   ② glow_color：ARGB4444 辉光 —— 圆外全透明黑、内部径向 alpha 平方衰减，
 *      颜色由白芯过渡到暖色；加算混合下 alpha 就是"发光强度"。
 *      ★ 打包**只走 argb4444_pack()**（A4R4G4B4，见上面 ARGB4444 段）⇒ 字段顺序不可能
 *        与自检/ RTL 各写各的。 */
static uint16_t disc_color(int i, int j)
{
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    int d2 = dx * dx + dy * dy;
    int r2 = (SPR_W / 2) * (SPR_W / 2);
    int ri = SPR_W / 2 - SPR_RING;       /* 白环内边界半径（外边界 = SPR_W/2） */
    unsigned rr, gg, bb;
    if (d2 > r2)      return (uint16_t)KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    if (d2 > ri * ri) return (uint16_t)COL_WHITE;      /* 白环 */
    rr = (unsigned)((i * 31) / (SPR_W - 1));
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
}

/* 第 v 档辉光配色（v = 0..GLOW_VARIANTS-1）：白芯 → 各档色边（ARGB4444） */
static uint16_t glow_color(int i, int j, int v)
{
    int dx = i * 2 - SPR_W + 1, dy = j * 2 - SPR_H + 1;   /* 以中心为原点（x2 提精度） */
    int d2 = dx * dx + dy * dy;
    int r2 = SPR_W * SPR_W;
    unsigned t, a, r4, g4, b4;
    if (d2 >= r2) return 0x0000u;                    /* 圆外：全透明（加算 = 无贡献） */
    t = (unsigned)((d2 * 255) / r2);                 /* 0 = 圆心，255 = 边缘 */
    a = 255u - t;
    a = (a * a) / 255u;                              /* 平方衰减：中心亮、边缘柔 */
    switch (v & 3) {
    case 0:  r4 = 15u; g4 = 15u - (t * 10u) / 255u; b4 = 15u - (t * 14u) / 255u; break; /* 暖白 */
    case 1:  r4 = 15u - (t * 12u) / 255u; g4 = 15u - (t * 6u) / 255u;  b4 = 15u; break; /* 青 */
    case 2:  r4 = 15u; g4 = 15u - (t * 13u) / 255u; b4 = 15u - (t * 6u) / 255u;  break; /* 品红 */
    default: r4 = 15u - (t * 8u) / 255u; g4 = 15u; b4 = 15u - (t * 10u) / 255u;  break; /* 绿 */
    }
    return argb4444_pack(a >> 4, r4, g4, b4);        /* ★ A[15:12] R[11:8] G[7:4] B[3:0] */
}
/* ==== ATLAS_GEN_END ==== */

/* 8x8 字体（信息条用）。★ 字符集**必须**覆盖 fmt_stat / 场景名 / 右标签用到的每一个字符，
 * 缺字会退回空格 ⇒ 屏上只是少笔画。新增字段前先看这里有没有对应字形。 */
/* ==== FONT_TABLE_BEGIN ====（主机自检原样取本段源码，逐字符查"最坏串用到的字形在不在"） */
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
    { 'J', {0x1E,0x0C,0x0C,0x0C,0x0C,0x6C,0x38,0x00} },
    { 'K', {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00} },
    { 'L', {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00} },
    { 'M', {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00} },
    { 'N', {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00} },
    { 'O', {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'P', {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00} },
    { 'Q', {0x3C,0x66,0x66,0x66,0x66,0x3C,0x0E,0x00} },
    { 'R', {0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00} },
    { 'S', {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00} },
    { 'T', {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00} },
    { 'U', {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00} },
    { 'V', {0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00} },
    { 'W', {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00} },
    { 'X', {0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00} },
    { 'Y', {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00} },
    { 'Z', {0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00} },
    { '=', {0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00} },
    { '.', {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00} },
    { ':', {0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00} },
    { '/', {0x06,0x0C,0x18,0x30,0x60,0x40,0x00,0x00} },
    { '-', {0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00} },
};
#define FONT_N       ((int)(sizeof(g_font) / sizeof(g_font[0])))
/* ★ 上板 bug（信息条糊）根因就是这两个跨度被当成同一个数：
 *   `FONT_STRIDE 16` 既是"源行跨度"（8px × 2B），又被当成"字形间距"用了 ——
 *   builder 按 p[j*8+i] 写 8 行（每行 16B ⇒ 一个字形实占 128B），emitter 却按
 *   `FONT_BASE + idx*16` 去读 ⇒ 单元 idx 的 8 行取到的是 (idx..idx+7) 这 8 个
 *   **字形的第 0 行**（第 1 行对、2~8 行全是别的字的顶行）⇒ 满屏横杠。
 *   现在把两个跨度分开命名，并且基址只留一个算式 FONT_GLYPH_OFF() 给两处共用。 */
#define FONT_ROW_BYTES   16                      /* 8px × 2B：**源行跨度**（= blt_key 的 ss） */
#define FONT_GLYPH_BYTES (FONT_ROW_BYTES * 8)    /* 一个 8x8 字形的字节跨度（= 相邻字形基址之差） */
#define FONT_GLYPH_OFF(v) ((uint32_t)(v) * FONT_GLYPH_BYTES)   /* builder 与 emitter **唯一**的基址算式 */
#define FONT_REGION_BYTES 0x00040000UL           /* 图集可用区间（到 FLUSH_SCRATCH 还有 4MB，留足） */
static int glyph_idx(char c)
{
    int i;
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return i;
    return 0;                                /* 未定义字符 → 空格（画面上只是少笔画） */
}
/* ==== FONT_TABLE_END ==== */

/* ============================== 基础原语 ============================== */
/* 时间基：CLINT mtime 低 32 位（1 次总线读；本程序所有时间量都是 ≤1s 的差值，回绕安全） */
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }

/* 有界退避：**纯寄存器空转**，不读外设、不碰内存 ⇒ 不产生一次总线事务
 * （在"引擎正在吃 DDR 带宽"的窗口里，这一点比省 CPU 更重要）。 */
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

/* 缓冲号 → 字节基址（三块都在 DDR 里，互不重叠；与 RTL 侧 FB_BASE/FB_BASE1/FB_BASE2 一致） */
static uint32_t fb_of_sel(uint32_t s)
{
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
}
/* FB_STAT(0x28) [1:0] = 扫描输出**已经生效**的显示缓冲选择 */
static uint32_t fb_stat_sel(void) { return blt_rd(BLT_FB_STAT) & 3UL; }

/* ============================== 三缓冲 + 并发清屏引擎的全局状态 ============================== */
static uint32_t g_fb_back    = FB_BACK;   /* 本趟绘制目标缓冲的字节基址（随轮转变） */
static int      g_disp_sel   = 0;         /* 已确认在屏的缓冲（0/1/2） */
static uint32_t g_flip_req   = 0;         /* 已写下、还没确认的翻转请求 */
static uint32_t g_flip_to    = 0;         /* 翻转有界等待超时次数（正常恒 0） */
static int      g_draw3      = -1;        /* 本趟绘制目标（0..2），-1 = 还没选 */
static int      g_clr3       = -1;        /* 交给清屏引擎预清的那块（0..2） */
static int      g_clr_need   = 0;         /* 1 = 本趟开始时要给清屏引擎下一条清屏命令 */
static int      g_pass_armed = 0;         /* 本趟是否已经做过"查 clean + 选目标 + 下清屏命令" */
static uint32_t g_clr_fb     = 0;         /* clean 不干净 → 退回命令式整片重铺的次数 */
static uint32_t g_clr_to     = 0;         /* 等清屏引擎超时次数（正常恒 0） */
static uint32_t g_clr_err    = 0;         /* 硬件互斥拒绝/打断次数（正常恒 0；>0 说明软件违约过） */
static uint8_t  g_bar_ok[3]  = {0, 0, 0}; /* 信息条（当前内容）是否已经在本缓冲里 */

static uint32_t clr_stat(void)  { return blt_rd(BLT_CLR_STAT); }
static int      clr_busy(void)  { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }

/* 有界等待清屏引擎空闲：超时返回 0（调用方据此退回命令式重铺，绝不无限等） */
#define CLR_WAIT_TICKS  (BSP_CLINT_HZ / 100u)      /* 10ms（实测整片清 ≈2.1ms） */
static int clr_wait_idle(void)
{
    uint32_t t0 = tick32();
    int      guard = 0;
    while (clr_busy()) {
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
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
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
}

/* 一趟开画前的**一次性动作**（前四步与 FinalDemo 逐位相同）：
 *   ① 有界等待清屏引擎空闲 ② 读 clean 位图 ③ 写 DRAW_SEL（在 ② 之后，它会清 clean 位）
 *   ④ sticky ERR 清掉 ⑤ 给第三块下清屏命令
 * want_clr=0（分层场景：每趟本来就要整幅背景 COPY）时不下清屏命令、直接返回"要重铺"。
 * 返回 1 = 本趟需要命令式重铺；0 = 目标缓冲已被清屏引擎预清干净。 */
static int hw_pass_arm(int y0, int h, int want_clr)
{
    int clean_k;
    (void)clr_wait_idle();
    clean_k = clr_is_clean((uint32_t)g_draw3);
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);
    if (clr_stat() & BLT_CLR_STAT_ERR) {
        g_clr_err++;
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    }
    if (want_clr && g_clr_need) { clr_start((uint32_t)g_clr3, y0, h); g_clr_need = 0; }
    if (!want_clr) return 1;
    if (!clean_k) g_clr_fb++;
    return clean_k ? 0 : 1;
}

/* CPU 写完 DDR 后、引擎紧接着要读的场合调用（D$ 是写穿，本质是 store 有序屏障）。
 * ★ 本 Demo 的渲染路径上 CPU **一个像素都不写**，所以屏障只在开机烘焙之后用一次；
 *   FinalDemo 那种"每帧发布前冲一遍 8KB"的开销这里不再需要。 */
static void cache_evict(void)
{
    volatile uint32_t *s = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
}

/* ============================== scissor / 属性 / LUT 的运行时开关 ============================== */
static int g_feat_clip = 0;      /* CLIP_* 写回读校验通过 */
static int g_feat_lut  = 0;      /* LUT_*  写回读校验通过 */
static int g_feat_attr = 0;      /* 认为属性侧口存在（= clip && lut，见文件头 (d)） */
static int g_scis_on   = 1;      /* 串口 'x'：scissor 使能（只在 SC_CLIP 场景生效） */
static int g_attr_user = 1;      /* 串口 'y'：属性侧口用不用（关掉 = 逐位回到默认语义） */
static int g_clip_pass = 0;      /* 本趟内容段的决定（**每趟开始拍快照** ⇒ 一趟之内不会变） */

/* ==== CLIP_GUARD_BEGIN ====（主机自检原样取本段源码；需要外部提供 bsp_printf）
 * ★★ 本次修的第二个问题：**信息条 / HUD 侧栏 / 裁剪边框 / 场景底图**这类"屏幕骨架"
 *    只允许在 CLIP_CTRL = 0 的时候下发，只有 playfield 内容（精灵 + 扫掠条）可以被裁。
 *    为什么：scissor 的坐标是**该命令目的矩形的局部坐标**，信息条字形命令的 dst 在
 *    (8,4) 这种位置，窗口按 dst 平移后与字形矩形（8x8）无交集 ⇒ 裁开就整条信息条消失
 *    （上板症状：场景 3 信息条/HUD 不见了）。判据只此一处：板上下发出口与主机自检共用。 */
#define CLIP_CLS_FIELD  0        /* playfield 内容：唯一允许被 scissor 裁的一类 */
#define CLIP_CLS_DECOR  1        /* 屏幕骨架（信息条/HUD/边框/底图）：绝不允许被裁 */

static int g_clip_on    = 0;                 /* 软件镜像：CLIP_CTRL bit0（最后写进寄存器的值） */
static int g_emit_cls   = CLIP_CLS_DECOR;    /* 当前正在下发的绘制类别 */
static int g_clip_viol  = 0;                 /* DECOR 类在裁剪开着时下发的次数（正常恒 0） */
static int g_clip_warn  = 0;                 /* 违约/回读失败的告警只打一次 */

static int clip_cls_can_clip(int cls) { return (cls == CLIP_CLS_FIELD) ? 1 : 0; }

/* 下发出口（blt_emit）的唯一守卫：DECOR 类碰上"裁剪开着"⇒ 记一次 + **立刻永久放弃裁剪**
 * （宁可没有裁剪，也不能丢信息条/HUD）。返回 1 = 本类允许在当前裁剪状态下下发。 */
static int clip_emit_guard(void)
{
    if (clip_cls_can_clip(g_emit_cls) || !g_clip_on) return 1;
    g_clip_viol++;
    g_scis_on   = 0;                        /* 'x' 的 A/B 开关一起关掉：屏幕上立刻看得见 */
    g_clip_pass = 0;
    if (!g_clip_warn) {
        g_clip_warn = 1;
        bsp_printf("EV clip WARN: DECOR draw while scissor armed -> scissor disabled\r\n");
    }
    return 0;
}
/* ==== CLIP_GUARD_END ==== */

/* ============================== 引擎指令 ==============================
 * ★★ 全工程**唯一**的下发出口。属性字与命令 8 字在这里成对出现，
 *    没有任何一条命令绕过它 ⇒ "属性错位"在结构上不可能发生（见文件头配对纪律）。 */
/* ==== EMIT_BEGIN ====（主机自检原样取本段源码）
 * 需要外部提供：BLT_ATTR_PORT/BLT_CMD_FIFO_DATA 偏移、BLT_OP_* 操作码、FB_STRIDE、
 * SPR_W/SPR_H/SPR_STRIDE/GLOW_VAR_STRIDE、ATLAS_BASE、CLIP_GUARD 段（类别守卫），
 * 以及一个 blt_wr() 桩（自检里把每次写记进 trace ⇒ 就能逐字验证"属性字在命令 8 字之前、
 * 且每条命令一个"；同一个 trace 还能验证"DECOR 类只在裁剪关着时下发"）。 */
static int g_attr_on = 0;                /* 1 = 每条命令前写 1 个属性字（feat_probe 之后才可能为 1） */

static void blt_emit(uint32_t attr, uint32_t op, uint32_t src, uint32_t dst,
                     uint32_t ss, uint32_t ds, uint32_t w, uint32_t h,
                     uint32_t alpha, uint32_t color)
{
    (void)clip_emit_guard();                      /* ★ 屏幕骨架绝不在裁剪开着时下发 */
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);   /* ★ 属性字必须在命令的 8 个字**之前** */
    blt_wr(BLT_CMD_FIFO_DATA, op);
    blt_wr(BLT_CMD_FIFO_DATA, src);
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    blt_wr(BLT_CMD_FIFO_DATA, color);
}
static void e_copy(uint32_t attr, uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                   uint32_t w, uint32_t h)
{ blt_emit(attr, BLT_OP_COPY, src, dst, ss, ds, w, h, 0xFFu, 0u); }
static void e_fill(uint32_t attr, uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{ blt_emit(attr, BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color); }
static void e_alpha(uint32_t attr, uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                    uint32_t w, uint32_t h, uint32_t alpha)
{ blt_emit(attr, BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u); }
static void e_key(uint32_t attr, uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                  uint32_t w, uint32_t h, uint32_t key)
{ blt_emit(attr, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key); }

/* 便捷包装：走**默认属性**的三条（FILL / COPY / KEY）。
 * ★ 属性侧口打开时它们也会各写一个 ATTR_DEFAULT —— 这正是配对纪律要求的"每条都写"。 */
static void blt_fill(uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{ e_fill(ATTR_DEFAULT, dst, ds, w, h, color); }
static void blt_copy(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds, uint32_t w, uint32_t h)
{ e_copy(ATTR_DEFAULT, src, dst, ss, ds, w, h); }
static void blt_key(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                    uint32_t w, uint32_t h, uint32_t key)
{ e_key(ATTR_DEFAULT, src, dst, ss, ds, w, h, key); }

/* ★ 辉光精灵（本 Demo 的主角）：
 *   属性侧口可用 ⇒ **加算混合 + ARGB4444 + 每精灵 global_alpha**（每精灵一个属性字）；
 *   不可用      ⇒ 逐位退回 FinalDemo 语义（RGB565 图集 + 命令字 w6 里的 alpha）。
 *   ★ w6 与属性里的 alpha **从不同时给**（前者 0xFF = 无、后者 255 = 无）⇒ 无论 RTL 把
 *     "属性 global_alpha"理解成乘数还是覆盖，结果都是同一个 alpha（见文件头 (b)）。 */
static void blt_glow(uint32_t src, uint32_t dst, uint32_t ga)
{
    if (g_attr_on)
        e_alpha(attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, ga, 0u), src, dst,
                SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, 0xFFu);
    else
        e_alpha(ATTR_DEFAULT, ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, ga);
}
/* ==== EMIT_END ==== */

static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }

/* 空闲判定：**从已经读到手的状态字**判定 ⇒ 一圈之内最多读一次 BLT_STATUS。 */
static int blt_idle_st(uint32_t st)
{
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
}
/* FIFO 余量：由**当前条数**现算（只会更保守，绝不会写满挂死）。
 * ★ 唯一调用点是 blt_room_bounded()：它顺带用同一个条数做"引擎有没有在动"的进度判据
 *   （见"有界等待"一节）⇒ 余量 0 时能区分"引擎在排空（继续等）"与"引擎停机（恢复）"。 */
static uint32_t blt_push_room_of(uint32_t cnt)
{
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
}
static void blt_init(void)
{
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    blt_wr(BLT_IRQ_STATUS, 0xFFFFFFFFu);               /* W1C：清掉所有挂起 */
    blt_wr(BLT_IRQ_EN, 0u);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
}

/* scissor 的软件镜像与寄存器写入在"场景 3 的几何"一节（clip_apply/clip_off/clip_arm）：
 * 窗口是**每条命令的局部坐标**，内容段里会频繁改它 —— 只有"真的要变"才写寄存器，
 * 而写寄存器**只能在引擎空闲时**做（寄存器在命令起始锁存，见文件头 (a)）。
 * 段 0（信息条/HUD/边框/底图）进入前一律走 clip_off_verified()：写 0 + **回读确认**。 */

/* ---- 扫描输出颜色 LUT（双 bank；显示 bank 只在帧边界换）----
 * ==== LUT_BANK_BEGIN ====（主机自检原样取本段源码；需要 <stdint.h> + blt_wr/blt_rd/
 * bsp_printf/tick32 桩 + `static int g_feat_lut;` + BSP_CLINT_HZ/BLT_FB_STAT 宏
 * —— 自检用一个小硬件模型把 0xA4/0xA8/0xAC/0xB0 跑起来：写 bank = bit1（当前值）、
 *    显示 bank = ~(帧边界锁存的 bit1)、0xB0 回读显示 bank）
 * ★ 权威语义（rtl/video/fb_scanout.v + rtl/tb/tb_scanout_lut.v）：
 *   0xAC bit1 = **LUT_DATA 写进哪个 bank**（写口用当前值）；显示读的是 **~(帧边界锁存的
 *   bit1)**；0xB0 bit0 = 正在显示的那个 bank。复位：bit1=0 ⇒ 写 bank0、显示 bank1，
 *   而两张表都是未初始化内容 ⇒ **开机必须先灌恒等表**（否则白闪/陈旧表能整屏洗白）。
 * ★ 四步发布序列（本文件的实现，就是权威语义的那四步）：
 *   ① 读 0xB0 → disp = 现在**显示**的 bank；
 *   ② wr = ~disp，写 0xAC bit1 = wr ⇒ 新表整张落进**非显示** bank；
 *   ③ 写 3x256 项（ch = 0/1/2 = R/G/B；LUT_ADDR = (ch<<8)|idx；写 LUT_DATA 出 1 拍脉冲）；
 *   ④ 0xAC bit1 = **disp**（写表之前正在显示的那个 bank）⇒ 帧边界锁存后显示 = ~disp
 *      = 刚写好的 wr。★ 早期规格那句"bit1 = 刚写的 bank"差一个反相（发布值 = wr 时
 *      显示仍是 disp ⇒ 表永远不上屏、屏上永远停着最早那张白闪表）。 */
static uint32_t g_lut_disp     = 0;   /* 软件镜像：LUT_STAT[0]（当前显示 bank） */
static int      g_lut_pend     = -1;  /* 待发布：新表写进了哪个 bank（-1 = 无） */
static int      g_lut_pend_en  = 0;   /* 待发布的使能状态（帧边界才写进寄存器） */
static int      g_lut_en       = 0;   /* 已发布的使能状态 */
static int      g_lut_inv      = 1;   /* 发布极性：1 = **权威语义**（显示 = ~bit1 ⇒ 发布值 =
                                       * 写 bank 的反相）；0 = 老语义（显示 = bit1 ⇒ 发布 wr） */
static unsigned g_lut_f        = 255u;/* 上一次写进表里的 fade（255 = 恒等） */
static unsigned g_lut_g        = 0u;  /* 上一次写进表里的 flash（0 = 恒等） */
static int      g_lut_stage_en = 0;   /* 上一次写表时的使能意图 */
static uint32_t g_lut_pend_t0  = 0;   /* 待发布起点（发布超时兜底用） */
static uint32_t g_lut_to       = 0;   /* 发布超时次数（正常恒 0） */
static int      g_lut_cal      = 0;   /* 1 = 极性已由实测标定确认 */

#define LUT_PEND_TICKS  (BSP_CLINT_HZ / 5u)      /* 200ms ≈ 12 场：发布兜底 */

static uint32_t frame_count(void) { return blt_rd(BLT_FB_STAT) >> 16; }

/* ④ 的发布值（**纯函数**，主机自检按两种极性各跑一遍）：
 *   显示 = ~bit1（g_lut_inv=1）⇒ 想让下一帧显示 wr，就得写 bit1 = ~wr；
 *   显示 =  bit1（g_lut_inv=0）⇒ 直接写 bit1 = wr。 */
static unsigned lut_pub_bank(unsigned wr) { return (unsigned)((wr & 1u) ^ (unsigned)(g_lut_inv & 1)); }

/* 把一张 (fade,flash) 表整张写进**指定** bank（写口 = bit1 = bank；en 一般传"已发布的使能"
 * ⇒ 写表期间屏幕逐像素不变）。开机灌恒等表、标定、正常写表都走这一个出口。 */
static void lut_fill_bank(unsigned bank, unsigned fade, unsigned flash, int en)
{
    unsigned ch, i;
    blt_wr(BLT_LUT_CTRL, (en ? BLT_LUT_EN : 0UL) | ((uint32_t)(bank & 1u) << 1));
    for (ch = 0; ch < BLT_LUT_CH_N; ch++) {
        for (i = 0; i < 256u; i++) {
            blt_wr(BLT_LUT_ADDR, lut_addr(ch, i));         /* [9:8] = 0/1/2 = R/G/B（含蓝） */
            blt_wr(BLT_LUT_DATA, lut_chan(i, fade, flash));
        }
    }
}

/* ★★ 安全档：**两个 bank 都是恒等表 + 使能 0**。开机、标定收尾、以及"不需要 LUT 的场景"
 *    都落到这一档 ⇒ 显示 bank 里永远要么是本文件刚写的表、要么是恒等表，
 *    未初始化的 BRAM / 上一次的白闪表在物理上再也上不了屏（"陈旧表绝不洗白屏"）。 */
static void lut_identity_safe_off(void)
{
    unsigned d, w;
    if (!g_feat_lut) return;
    d = (unsigned)(blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK);
    w = lut_write_bank(d);
    blt_wr(BLT_LUT_CTRL, (uint32_t)w << 1);          /* ① 先关使能（立即生效）⇒ 刷表屏幕无变化 */
    lut_fill_bank(w, 255u, 0u, 0);                   /* ② 非显示 bank = 恒等表 */
    lut_fill_bank(d, 255u, 0u, 0);                   /* ③ 显示 bank 也刷成恒等表（内容相同） */
    blt_wr(BLT_LUT_CTRL, (uint32_t)lut_pub_bank(d) << 1);   /* ④ 显示仍是 d、使能 = 0 */
    g_lut_en = 0; g_lut_f = 255u; g_lut_g = 0u; g_lut_stage_en = 0;
    g_lut_disp = d; g_lut_pend = -1; g_lut_pend_en = 0;
}

/* ★★ 极性标定：**实测**，不认文档（LUT 关着做 ⇒ 屏幕上完全看不出来；只花一个帧边界）
 *   ① 读 0xB0 → d0 = 现在显示的 bank；
 *   ② 把一张**已知表**（恒等表：既好辨认、又绝不会洗白屏）整张写进 w = ~d0（非显示 bank）；
 *   ③ 按**权威语义**发布一次：bit1 = ~w = d0（"写表之前正在显示的那个 bank"）；
 *   ④ 等一个帧边界 → 回读 0xB0 → d1：
 *        d1 == w  ⇒ 显示真的跟着"刚写的那张"走 ⇒ 权威语义成立 ⇒ 发布值 = 写 bank 的反相
 *        d1 == d0 ⇒ 显示跟着 bit1 直接走（老语义）      ⇒ 发布值 = 写 bank 本身
 *   超时（扫描输出没在跑 / 帧计数不动）⇒ 保持权威默认 + 一行 WARN（屏幕上仍是安全档）。
 *   判据与结果都打在 `EV lut polarity` 行里（用户上板可直接读）。 */
#define LUT_CAL_TICKS  (BSP_CLINT_HZ / 10u)                 /* 100ms（≈6 场 @60Hz） */
static void lut_bank_calib(void)
{
    uint32_t d0, d1, fc0, t0;
    unsigned w;
    if (!g_feat_lut) {
        bsp_printf("EV lut polarity: not tested (LUT registers readback failed)\r\n");
        return;
    }
    d0 = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    w  = lut_write_bank(d0);                              /* ② 非显示 bank */
    lut_fill_bank(w, 255u, 0u, 0);                        /*    已知表 = 恒等表，使能 0 */
    blt_wr(BLT_LUT_CTRL, (uint32_t)(w ^ 1u) << 1);         /* ③ 权威语义的发布值（= ~w） */
    fc0 = frame_count();
    t0  = tick32();
    while (frame_count() == fc0) {
        if ((uint32_t)(tick32() - t0) > (uint32_t)LUT_CAL_TICKS) {
            g_lut_disp = d0;
            bsp_printf("EV lut WARN: polarity not confirmed (frame counter not moving); assuming display=~write\r\n");
            lut_identity_safe_off();
            return;
        }
    }
    d1 = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    g_lut_inv  = (d1 == w) ? 1 : 0;                       /* ④ 显示 bank 真的跟着走了吗 */
    g_lut_cal  = 1;
    g_lut_disp = d1;
    bsp_printf("EV lut polarity: %s (confirmed by live test) disp=%d->%d written=%d\r\n",
               g_lut_inv ? "display=~write" : "display=write",
               (int)d0, (int)d1, (int)w);
    lut_identity_safe_off();                              /* 收尾：两个 bank 恒等 + 使能 0 */
}

/* 把当前 fade/flash 的三张 256 项通道表写进**非显示** bank（① ② ③ 步；发布留到帧边界） */
static void lut_write_table(unsigned fade, unsigned flash, int want_en)
{
    unsigned disp = (unsigned)(blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK);   /* ① 现读显示 bank */
    unsigned wr   = lut_write_bank(disp);                                   /* ② 写另一半 */
    lut_fill_bank(wr, fade, flash, g_lut_en);       /* ③ 写表；使能保持"已发布"值 */
    g_lut_f        = fade;
    g_lut_g        = flash;
    g_lut_stage_en = want_en;
    g_lut_disp     = disp;              /* 这一刻显示 bank 还没换（换在帧边界） */
    g_lut_pend     = (int)wr;
    g_lut_pend_en  = want_en;
    g_lut_pend_t0  = tick32();
}

/* ④ 步的发布：帧边界（翻转确认那一刻）才真正换 bank —— 一场里只有一个 LUT 生效，不撕裂。
 * 注意 bit0（使能）在 RTL 里是**立即**生效的：所以发布瞬间屏幕会先用旧 bank 的表输出
 * 一拍内的画面，再在帧边界换到新表；安全档保证旧 bank 里也永远是"刚写过的表/恒等表"。 */
static void lut_publish(void)
{
    uint32_t pb;
    if (!g_feat_lut || g_lut_pend < 0) return;
    pb = (uint32_t)lut_pub_bank((unsigned)g_lut_pend);          /* ④ bit1 = ~wr（权威语义） */
    blt_wr(BLT_LUT_CTRL, (g_lut_pend_en ? BLT_LUT_EN : 0UL) | (pb << 1));
    g_lut_en   = g_lut_pend_en;
    g_lut_disp = (uint32_t)g_lut_pend;                          /* 帧边界起显示的就是它 */
    g_lut_pend = -1;
}

/* ★ 板上可读的 LUT 状态行（用户上板第一眼看这行）：三个字段都是**回读实机寄存器**得到的
 *   —— en = 0xAC bit0、disp = 0xB0、write = 0xAC bit1（下一项 LUT_DATA 写进哪个 bank）。 */
static void lut_state_line(const char *tag)
{
    uint32_t ctl  = g_feat_lut ? blt_rd(BLT_LUT_CTRL) : 0UL;
    uint32_t disp = g_feat_lut ? (blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK) : 0UL;
    bsp_printf("EV lut %s: en=%d disp=%d write=%d polarity=%s fade=%d flash=%d pend=%d to=%d\r\n",
               tag, (int)(ctl & BLT_LUT_EN), (int)disp, (int)((ctl >> 1) & 1UL),
               g_lut_inv ? "display=~write" : "display=write",
               (int)g_lut_f, (int)g_lut_g, g_lut_pend, (int)g_lut_to);
}
/* ==== LUT_BANK_END ==== */

/* ============================== 开机自检 ============================== */
/* ① 32bit 存储对齐自检：CPU 曾经因为"奇数 x 做 32bit 存储"整机静默停死（未对齐异常）。
 *    AdDemo 的渲染路径已经没有 CPU 像素写入，但**资源烘焙 / 屏障**仍在写 DDR，
 *    所以这道检查继续保留；写点改到 FLUSH_SCRATCH（不再往帧缓冲里写测试像素）。*/
static void align_selfcheck(void)
{
    volatile uint16_t *p = (volatile uint16_t *)(FLUSH_SCRATCH + 1024u);
    *(volatile uint32_t *)(FLUSH_SCRATCH + 1024u) = 0xF800F800UL;   /* 偶半字地址 32bit 存储 */
    *(volatile uint32_t *)(FLUSH_SCRATCH + 1026u) = 0x07E007E0UL;   /* ★ 奇半字地址（曾整机停死） */
    bsp_printf("aligncheck %x %x %x (expect f800 07e0 07e0; odd-addr 32bit store survived)\r\n",
               (unsigned)p[0], (unsigned)p[1], (unsigned)p[2]);
}

/* ② 属性编码自检：几组已知画法的属性字，**逐位解回来**再打出来
 *    （板上跑的编码 = 自检的编码；主机自检用同一段源码跑更大的一张表）。 */
static void attr_selfcheck(void)
{
    static const struct { unsigned blend, fmt, ga, fl; } t[4] = {
        { ATTR_BLEND_OP,    ATTR_FMT_565,  255u, 0u },                  /* 默认 */
        { ATTR_BLEND_ALPHA, ATTR_FMT_4444, 128u, 0u },                  /* 半透明 4444 */
        { ATTR_BLEND_ADD,   ATTR_FMT_4444,  96u, 0u },                  /* 加算辉光 */
        { ATTR_BLEND_MUL,   ATTR_FMT_1555,  64u, ATTR_FLAG_ATEST },     /* 乘 + 跳过 alpha 测试 */
    };
    int i;
    uint32_t d = attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u);
    bsp_printf("attr default=%x (FIFO empty = blend0/565/ga255) match=%d\r\n",
               (unsigned)d, (d == (uint32_t)ATTR_DEFAULT) ? 1 : 0);
    for (i = 0; i < 4; i++) {
        uint32_t w = attr_word(t[i].blend, t[i].fmt, t[i].ga, t[i].fl);
        bsp_printf("attr[%d] w=%x blend=%d fmt=%d ga=%d flags=%d\r\n", i, (unsigned)w,
                   (int)attr_blend(w), (int)attr_fmt(w), (int)attr_ga(w), (int)attr_flags(w));
    }
    bsp_printf("attr pairing: every command goes through blt_emit() -> 1 attr per command\r\n");
}

/* ②b ARGB4444 打包自检：把辉光图集的**圆心像素**原样解回来（A4R4G4B4 + RTL 的位复制展开）。
 *    "写进去的字段"和"读回来的字段"走同一组函数（argb4444_pack / argb4444_a/r/g/b），
 *     主机自检再把 16^4 组组合全跑一遍 ⇒ 字段顺序错了（例如 G/B 互换）当场就会被抓出来。 */
static void argb_selfcheck(void)
{
    uint16_t c = glow_color(SPR_W / 2, SPR_H / 2, 0);        /* v=0 档圆心：白芯 */
    bsp_printf("argb4444 c=%x a=%d r=%d g=%d b=%d -> a8=%d r8=%d g8=%d b8=%d\r\n",
               (unsigned)c, (int)argb4444_a(c), (int)argb4444_r(c),
               (int)argb4444_g(c), (int)argb4444_b(c),
               (int)rep4to8(argb4444_a(c)), (int)rep4to8(argb4444_r(c)),
               (int)rep4to8(argb4444_g(c)), (int)rep4to8(argb4444_b(c)));
    bsp_printf("argb4444 field probe 1234=%x 0f00=%x 00f0=%x 000f=%x (expect A/R/G/B, a8 of 8=%d)\r\n",
               (unsigned)argb4444_pack(1u, 2u, 3u, 4u), (unsigned)argb4444_pack(0u, 15u, 0u, 0u),
               (unsigned)argb4444_pack(0u, 0u, 15u, 0u), (unsigned)argb4444_pack(0u, 0u, 0u, 15u),
               (int)rep4to8(8u));
}

/* ③ 新寄存器探测：CLIP_* / LUT_* 逐个写回读 —— 两边都通过才认为这颗 bitstream
 *    带上了冻结接口里的新特性（属性侧口只写、读不回，只能这样间接判定）。 */
static void feat_probe(void)
{
    uint32_t lc;
    blt_wr(BLT_CLIP_X0, 0x00000123UL); blt_wr(BLT_CLIP_X1, 0x00000456UL);
    blt_wr(BLT_CLIP_Y0, 0x00000789UL); blt_wr(BLT_CLIP_Y1, 0x00000AB0UL);
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);

    blt_wr(BLT_LUT_CTRL, 0u);
    lc = blt_rd(BLT_LUT_CTRL) & 3UL;
    blt_wr(BLT_LUT_CTRL, BLT_LUT_EN | BLT_LUT_BANK);
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    blt_wr(BLT_LUT_CTRL, 0u);                       /* 先关掉；真正开是在第一次 lut_publish */

    g_lut_disp  = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    g_feat_attr = (g_feat_clip && g_feat_lut) ? 1 : 0;   /* 见文件头 (d) */
    g_attr_on   = (g_feat_attr && g_attr_user) ? 1 : 0;

    bsp_printf("feat: clip=%d lut=%d attr=%d (attr off => per-command default path)\r\n",
               g_feat_clip, g_feat_lut, g_feat_attr);
    if (!g_feat_clip)
        bsp_printf("feat WARN: CLIP_* readback failed -> scissor disabled (scene 3 = full-screen playfield)\r\n");
    if (!g_feat_lut)
        bsp_printf("feat WARN: LUT_* readback failed -> fade/flash disabled (needs the next P&R)\r\n");
    if (!g_feat_attr)
        bsp_printf("feat WARN: attribute side-port assumed ABSENT -> RGB565 + per-command alpha fallback\r\n");
    bsp_printf("feat: LUT_STAT bank=%d (disp; write target = the other bank)\r\n", (int)g_lut_disp);
    lut_bank_calib();                               /* ★ 实测发布极性 + 两个 bank 灌恒等表 */
    lut_state_line("state");                        /* ★ 上板可直接读的 LUT 状态行 */
}

/* ============================== 资源烘焙（开机一次，之后一帧都不再碰） ============================== */
static void build_atlas(void)
{
    volatile uint16_t *d = (volatile uint16_t *)ATLAS_BASE;
    int v, i, j;
    for (j = 0; j < SPR_H; j++)
        for (i = 0; i < SPR_W; i++)
            d[j * SPR_W + i] = disc_color(i, j);                 /* ① RGB565 圆盘 */
    for (v = 0; v < GLOW_VARIANTS; v++) {                        /* ② 4 档 ARGB4444 辉光 */
        volatile uint16_t *g = (volatile uint16_t *)(GLOW_BASE + (uint32_t)v * GLOW_VAR_STRIDE);
        for (j = 0; j < SPR_H; j++)
            for (i = 0; i < SPR_W; i++)
                g[j * SPR_W + i] = glow_color(i, j, v);
    }
    for (v = 0; v < FONT_N; v++) {                               /* ③ 8x8 字形（白字 + 色键底） */
        /* ★ 基址走 FONT_GLYPH_OFF（= 128B/字形），行内下标走 FONT_ROW_BYTES/2 个 uint16
         *   —— 与 emitter 的 (FONT_GLYPH_OFF, FONT_ROW_BYTES) 是同一对常量，不可能再错开。 */
        volatile uint16_t *p = (volatile uint16_t *)(FONT_BASE + FONT_GLYPH_OFF(v));
        for (j = 0; j < 8; j++) {
            uint8_t bits = g_font[v].r[j];
            for (i = 0; i < 8; i++)
                p[j * (FONT_ROW_BYTES / 2) + i] =
                    (uint16_t)((bits & (uint8_t)(0x80u >> i)) ? COL_WHITE : KEY_COLOR);
        }
    }
    bsp_printf("bake: disc %dx%d @%x  glow %dx%d x%d @%x  font %d glyphs @%x\r\n",
               SPR_W, SPR_H, (unsigned)ATLAS_BASE, SPR_W, SPR_H, GLOW_VARIANTS,
               (unsigned)GLOW_BASE, FONT_N, (unsigned)FONT_BASE);
}

/* 960x524 程序化背景（分层场景的"大图搬移"源）：深蓝→紫竖直渐变 + 中心光晕 + 细网格。
 * ★ 只在开机烘焙一次；运行期每趟用**一条 COPY 命令**把它搬进帧缓冲（引擎干活）。 */
static uint16_t bg_px(unsigned gx, unsigned gy)
{
    unsigned r5 = 2u + (gx * 6u) / 255u;
    unsigned g5 = 2u + (gy * 5u) / 255u;
    unsigned b5 = 9u + (gy * 11u) / 255u;
    int dx = (int)gx - 128, dy = (int)gy - 128;
    unsigned d2 = (unsigned)(dx * dx + dy * dy);
    if (d2 < 16384u) {                                  /* 中心光晕 */
        unsigned halo = ((16384u - d2) * 9u) / 16384u;
        b5 += halo; g5 += halo / 2u; r5 += halo / 3u;
    }
    if ((gx & 31u) == 0u || (gy & 31u) == 0u) { r5++; g5++; b5++; }   /* 细网格 */
    if (r5 > 31u) r5 = 31u;
    if (g5 > 63u) g5 = 63u;
    if (b5 > 31u) b5 = 31u;
    return (uint16_t)((r5 << 11) | (g5 << 5) | b5);
}
static void build_bg(void)
{
    volatile uint32_t *p = (volatile uint32_t *)BG_BASE;
    int y, x;
    /* 960 与 524 都是偶数 ⇒ 32bit 存储天然对齐，两像素一次写（开机更快） */
    for (y = 0; y < PLAY_H; y++) {
        unsigned gy = (unsigned)(y * 255 / (PLAY_H - 1));
        for (x = 0; x < FB_WIDTH; x += 2) {
            unsigned g0 = (unsigned)(x * 255 / (FB_WIDTH - 1));
            unsigned g1 = (unsigned)((x + 1) * 255 / (FB_WIDTH - 1));
            p[(y * FB_WIDTH + x) >> 1] =
                (uint32_t)bg_px(g0, gy) | ((uint32_t)bg_px(g1, gy) << 16);
        }
    }
    bsp_printf("bake: bg %dx%d @%x (one COPY per pass in scene 4)\r\n",
               FB_WIDTH, PLAY_H, (unsigned)BG_BASE);
}

/* ============================== 场景（粒子） ============================== */
typedef struct {
    int16_t x, y;      /* 目标位置（所有精灵按同一规则推进） */
    int16_t vx, vy;
    int16_t tx, ty;    /* **本趟快照**：一趟之内位置恒定（无尾迹、记账自洽） */
    uint8_t a;         /* 每精灵 alpha（ATTR global_alpha 的来源） */
    uint8_t v;         /* 辉光配色档（0..GLOW_VARIANTS-1） */
} part_t;
static part_t   g_pt[MAXPT];

/* ==== SCENE_BOUNDS_BEGIN ====（主机自检原样取本段源码）
 * 需要外部先声明：part_t 类型与 g_pt 数组、MAXPT/TOP_Y0 宏，以及
 * FB_WIDTH/FB_HEIGHT/SPR_W/SPR_H/GLOW_VARIANTS 宏。
 * 不变量（自检对三种尺寸 x 4000 步全跑一遍断言）：**每个粒子的包围盒恒在渲染区内**
 * （x ∈ [0, FB_WIDTH-SPR_W]、y ∈ [TOP_Y0, FB_HEIGHT-SPR_H]）——包括第 0 帧。
 * ★ 注意：AdDemo 不再需要"偶数 x"这个约束（渲染路径上没有 CPU 的 32bit 存储），
 *   所以 scene_step 里没有 FinalDemo 那个 `x & ~1`（它会让 vx=±1 的粒子卡住不动）。 */
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }

static void scene_init(int n, uint32_t seed)
{
    int i;
    int xr = FB_WIDTH - SPR_W;              /* 起点上界（右/下各留一个精灵位） */
    int yr = PLAY_H   - SPR_H;
    uint32_t s = seed;
    if (n > MAXPT) n = MAXPT;
    for (i = 0; i < n; i++) {
        part_t *p = &g_pt[i];
        uint32_t r1 = lcg(&s), r2 = lcg(&s), r3 = lcg(&s);
        p->vx = (int16_t)((int)(r1 % 7u) - 3);
        p->vy = (int16_t)((int)(r2 % 5u) - 2);
        if (!p->vx) p->vx = 1;
        if (!p->vy) p->vy = 1;
        p->x  = (int16_t)(r1 % (uint32_t)xr);
        p->y  = (int16_t)((int)(r2 % (uint32_t)yr) + TOP_Y0);
        p->a  = (uint8_t)(64u + (r3 & 0xBFu));            /* 每精灵 alpha：64..255 */
        p->v  = (uint8_t)((r3 >> 8) % (uint32_t)GLOW_VARIANTS);
        /* 兜底钳位：把"初始位置也在区内"变成代码保证，而不是只靠上面的余量 */
        if (p->x > xr) p->x = (int16_t)xr;
        if (p->y > yr + TOP_Y0) p->y = (int16_t)(yr + TOP_Y0);
        p->tx = p->x; p->ty = p->y;
    }
}

/* 只推进**目标位置**；不动 tx/ty（本趟快照）—— 一趟内位置恒定 ⇒ 记账自洽、无尾迹 */
static void scene_step(int n)
{
    int i;
    const int xmin = 0, xmax = FB_WIDTH;
    const int ymin = TOP_Y0, ymax = FB_HEIGHT;
    for (i = 0; i < n; i++) {
        part_t *p = &g_pt[i];
        int x = p->x + p->vx, y = p->y + p->vy, w = SPR_W;
        if (x < xmin)          { x = xmin;     p->vx = (int16_t)(-p->vx); }
        else if (x + w > xmax) { x = xmax - w; p->vx = (int16_t)(-p->vx); }
        if (y < ymin)          { y = ymin;     p->vy = (int16_t)(-p->vy); }
        else if (y + w > ymax) { y = ymax - w; p->vy = (int16_t)(-p->vy); }
        p->x = (int16_t)x;
        p->y = (int16_t)y;
    }
}
/* 给场景拍快照：把当前 x,y 冻进 tx,ty（调用点只在"没有在途命令"的时刻） */
static void scene_snap(int n)
{
    int i;
    for (i = 0; i < n; i++) { g_pt[i].tx = g_pt[i].x; g_pt[i].ty = g_pt[i].y; }
}
/* ==== SCENE_BOUNDS_END ==== */

static const char *scene_name(int s);
static int slen(const char *s);

/* ============================== 信息条组串 ==============================
 * ==== OSD_FMT_BEGIN ====（主机自检原样取本段源码，用来量"最坏情况到底多宽"）
 * 需要外部先声明：OSD_LEFT_CH 宏、scene_name() 函数原型。 */
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
static char *appn(char *p, unsigned v, int w)
{
    char d[12]; int n = 0, i;
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    for (i = 0; i < w - n; i++) *p++ = ' ';
    while (n) *p++ = d[--n];
    return p;
}
static int sseq(const char *a, const char *b)
{
    while (*a && *a == *b) { a++; b++; }
    return (*a == *b) ? 1 : 0;
}
static void scpy(char *d, const char *s) { while ((*d++ = *s++) != 0) { } }

/* 组串：**本 Demo 的卖点全在这一行里**（每一段都是钳位过的定宽，数值变短不会留残字）：
 *   FPS=  真正上屏的帧率 = 翻转被扫描输出**确认生效**的次数/秒（FLIP 路径的口径）
 *   N=    每帧精灵数   SZ=  精灵边长（'k' 循环）
 *   MPX=  等效像素吞吐 = N * SZ * SZ * FPS / 1e6（Mpx/s，**由精灵数与尺寸算出来的**）
 *   SCd:NAME  场景号 + 人读得懂的名字
 *   A=    主 alpha 微调（乘到每精灵 alpha 上）
 *   B=    引擎占用率（主循环慢时间片里对 BLT_STATUS 采样得到的忙比例，0..100）
 *   FR=按已发布帧推进   F=LUT 特效开   X=scissor 开   Y=属性侧口开   Q=自动爬坡开
 * ★ 宽度上界见 OSD_LEFT_CH 处的静态证明；启动自检用本函数跑最坏值再证一遍。 */
static void fmt_stat(char *line, uint32_t fps, int n, int scene, int sz, unsigned alpha,
                     unsigned mpx, unsigned busy, int frame_adv, int fx, int scis,
                     int attr, int autoq)
{
    char *p = line;
    if (fps   >   99u) fps   =   99u;    /* 钳位只为把最长串钉死在上界内 */
    if (mpx   > 9999u) mpx   = 9999u;
    if (alpha >  255u) alpha =  255u;
    if (busy  >  100u) busy  =  100u;
    p = app(p, "FPS="); p = appn(p, fps, 2);
    p = app(p, " N=");  p = appn(p, (unsigned)n, 4);
    p = app(p, " SZ="); p = appn(p, (unsigned)sz, 2);
    p = app(p, " MPX=");p = appn(p, mpx, 4);
    p = app(p, " SC");  p = appn(p, (unsigned)(scene + 1), 1);
    p = app(p, ":");    p = app(p, scene_name(scene));
    p = app(p, " A=");  p = appn(p, alpha, 3);
    p = app(p, " B=");  p = appn(p, busy, 3);
    if (frame_adv) p = app(p, " FR");
    if (fx)        p = app(p, " F");
    if (scis)      p = app(p, " X");
    if (attr)      p = app(p, " Y");
    if (autoq)     p = app(p, " Q");
    *p = 0;
}
/* ==== OSD_FMT_END ==== */

static const char *scene_name(int s)
{
    if (s == SC_FADE)  return "FADE";
    if (s == SC_CLIP)  return "CLIP";
    if (s == SC_LAYER) return "LAYER";
    if (s == SC_THRU)  return "THRU";
    return "GLOW";
}
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }

/* 信息条状态：**事件驱动** —— g_osd_dirty 只在"要显示的内容真的变了"时置位 */
static char     g_osd_line[OSD_LEFT_CH + 2];
static int      g_osd_dirty = 1;
static uint32_t g_osd_t0    = 0;
static uint32_t g_fps       = 0;   /* 已发布帧率 */
static unsigned g_mpx       = 0;   /* 等效像素吞吐 Mpx/s */
static unsigned g_busy      = 0;   /* 引擎占用率 % */
static uint32_t g_busy_n    = 0, g_busy_s = 0;   /* 忙采样数 / 总采样数（1Hz 清零） */

static void osd_build(int n, int scene, unsigned alpha, int frame_adv, int fx, int scis,
                      int attr, int autoq)
{
    char tmp[OSD_LEFT_CH + 2];
    fmt_stat(tmp, g_fps, n, scene, g_blk, alpha, g_mpx, g_busy, frame_adv, fx, scis, attr, autoq);
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
}

/* 1Hz 统计：三个数（帧率 / 吞吐 / 占用）共用同一个窗口、同一次清零 */
static int osd_service(uint32_t t_now, uint32_t scr_frames, int n, int scene,
                       unsigned alpha, int frame_adv, int fx, int scis, int attr, int autoq)
{
    uint32_t el = (uint32_t)(t_now - g_osd_t0);
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;
    g_osd_t0 = t_now;
    g_fps    = (uint32_t)(((uint64_t)scr_frames * (uint64_t)BSP_CLINT_HZ) / el);
    /* 等效像素吞吐：N 个 SZxSZ 精灵、每秒 FPS 帧 ⇒ N*SZ*SZ*FPS 像素/秒。
     * 用 64bit 中间量（N=6000/SZ=64/FPS=99 时约 2.4e9），最后才 /1e6。 */
    g_mpx = (unsigned)(((uint64_t)(uint32_t)n * (uint64_t)(uint32_t)(g_blk * g_blk) *
                         (uint64_t)g_fps) / 1000000ull);
    g_busy = (g_busy_s > 0u) ? (unsigned)((g_busy_n * 100u) / g_busy_s) : 0u;
    g_busy_n = 0; g_busy_s = 0;
    osd_build(n, scene, alpha, frame_adv, fx, scis, attr, autoq);
    return 1;
}

/* ============================== 串口（非阻塞） ==============================
 * uart_writeAvailability = (status >> 16) & 0xFF  → TX 剩余空间
 * uart_readOccupancy     = (status >> 24)         → RX 已收字节数
 * 只在"慢时间片"（每 32 圈）里调用，不再每圈都碰 UART 状态寄存器。 */
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
 * 与 FinalDemo 同一套协议、同一条代码路径：
 *   =1375\n  ⇒ N 精确等于 1375，回显 EV N=1375
 *   =10\n    ⇒ 钳到 N_MIN ⇒ EV N=16      （只钳不拒，回显**实际生效**的值）
 *   =9999\n  ⇒ 钳到 N_MAX ⇒ EV N=6000
 *   非数字 / 位数超过行缓冲 / '=' 后一个数字都没有 ⇒ EV N=ERR
 * ★ 缓冲**只在看到 '=' 之后才启用**，没启用时每个字符都原样交回单字符命令分支。 */
#define NLINE_MAX 12
#define NL_NONE    0
#define NL_MORE    1
#define NL_OK      2
#define NL_ERR   (-1)

static char     g_nl[NLINE_MAX];
static unsigned g_nl_n  = 0;
static int      g_nl_on = 0;

static int nline_feed(int c, int *out)
{
    unsigned v, i;
    if (!g_nl_on) {
        if (c != '=') return NL_NONE;
        g_nl_on = 1; g_nl_n = 0;
        return NL_MORE;
    }
    if (c == '\n' || c == '\r') {
        g_nl_on = 0;
        if (g_nl_n == 0u) return NL_ERR;
        v = 0u;
        for (i = 0; i < g_nl_n; i++) {
            v = v * 10u + (unsigned)(g_nl[i] - '0');
            if (v > (unsigned)N_MAX) v = (unsigned)N_MAX;       /* 边收边钳，不会溢出 */
        }
        if (v < (unsigned)N_MIN) v = (unsigned)N_MIN;
        *out = (int)v;
        return NL_OK;
    }
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) {
        g_nl_on = 0;
        return NL_ERR;
    }
    g_nl[g_nl_n++] = (char)c;
    return NL_MORE;
}

/* ============================== 场景 3 的几何（裁剪窗口 + HUD 侧栏） ============================== */
#define PLAY_X0   200
#define PLAY_X1   760
#define PLAY_Y0   96
#define PLAY_Y1   472
#define SWEEP_T   6                       /* 扫掠条厚度（横 6px 高 / 竖 6px 宽） */
#define HUD_X0    776
#define HUD_Y0    24
#define HUD_W     176
#define HUD_H     508
#define HUD_BARS  4
#define HUD_ITEMS (1 + 4 + HUD_BARS)      /* 底板 + 4 条边框 + N 根动画条 */

/* ---- ★ ⑨ scissor：屏幕坐标 → 每条命令的**局部**坐标（冻结接口 ②） ----
 * ==== CLIP_XLATE_BEGIN ====（主机自检原样取本段源码）
 * 需要外部先声明：PLAY_X0/PLAY_X1/PLAY_Y0/PLAY_Y1/TOP_Y0 五个宏。
 * RTL：X0/Y0 **含**、X1/Y1 **不含**（半开区间 [x0,x1) x [y0,y1)）；坐标是**本条命令目的
 *      矩形的局部坐标**（原点 = 该命令 dst_base 那个像素，第 0 行 = 第一行）；寄存器在
 *      **命令起始**锁存。全屏目的矩形时局部坐标 == 屏幕坐标。
 * ⇒ 本文件把窗口按**屏幕坐标**定义一次（下面四个常量），每条命令再平移进它自己的局部系；
 *    平移后与目标矩形**无交集** ⇒ 这条命令整条不发（画了也全在窗口外）。 */
#define CLIP_SX0   PLAY_X0                /* 屏幕坐标半开窗口 [SX0,SX1) x [SY0,SY1) */
#define CLIP_SX1   PLAY_X1
#define CLIP_SY0   (TOP_Y0 + PLAY_Y0)
#define CLIP_SY1   (TOP_Y0 + PLAY_Y1)

typedef struct { int x0, x1, y0, y1; } iclip_t;     /* 局部窗口（半开） */
typedef struct { int dx, dy, w, h; }  irect_t;      /* 目标矩形（屏幕坐标 + 尺寸） */

/* 屏幕窗口 → 某条命令的局部窗口，并按该命令的目标矩形夹取。
 * 返回 1 = 有交集（out 有效）；0 = **完全不相交** ⇒ 调用方把整条命令省掉。
 * ★ 三种"宽条"（全屏宽的横扫条 960x6、全屏高的竖扫条 6x524、以及整幅底图 960x524）
 *   都走这同一个出口 ⇒ 平移只可能错一次、不可能各算各的（主机自检按这三种尺寸逐例核对过：
 *   全屏矩形时局部 == 屏幕坐标；竖扫条的局部窗口 = [0,6)x[96,472) ⇒ 条本身一根像素不少）。 */
static int clip_local(int dx, int dy, int w, int h, iclip_t *out)
{
    int x0 = CLIP_SX0 - dx, x1 = CLIP_SX1 - dx;
    int y0 = CLIP_SY0 - dy, y1 = CLIP_SY1 - dy;
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > w) x1 = w;
    if (y1 > h) y1 = h;
    out->x0 = x0; out->x1 = x1; out->y0 = y0; out->y1 = y1;
    return (x0 < x1 && y0 < y1) ? 1 : 0;
}
/* ==== CLIP_XLATE_END ==== */

/* ---- 屏幕骨架（信息条 / HUD / 裁剪边框 / 底图）的**屏幕矩形**：绘制与主机自检共用 ----
 * ==== DECOR_RECT_BEGIN ====（主机自检原样取本段源码；需要 OSD_xxx / HUD_xxx / PLAY_xxx /
 * TOP_Y0 这些宏）
 * ★ 这些矩形是"绝不允许被 scissor 裁"的那一类（见 CLIP_GUARD）。把它们抽成纯函数只有
 *   一个目的：**绘制用哪块地方**与**自检断言哪块地方不被裁**是同一份算式 —— 不是注释里的
 *   君子协定（信息条字形就在 dst=(8,4) 这种位置，一旦被裁是整条消失，肉眼很容易漏）。 */
static void osd_strip_rect(irect_t *r) { r->dx = 0;  r->dy = 0;         r->w = FB_WIDTH;   r->h = OSD_H; }
static void osd_glyph_rect(int k, int len, irect_t *r, int left)
{
    r->dx = left ? (OSD_TEXT_X0 + OSD_GLYPH_W * k)
                 : (FB_WIDTH - OSD_GLYPH_W * len + OSD_GLYPH_W * k);
    r->dy = OSD_TEXT_Y; r->w = OSD_GLYPH_W; r->h = OSD_GLYPH_H;
}
static void clip_edge_rect(int k, irect_t *r)
{
    if (k == 0)      { r->dx = PLAY_X0;         r->dy = TOP_Y0 + PLAY_Y0 - 2; r->w = PLAY_X1 - PLAY_X0; r->h = 2; }
    else if (k == 1) { r->dx = PLAY_X0;         r->dy = TOP_Y0 + PLAY_Y1;     r->w = PLAY_X1 - PLAY_X0; r->h = 2; }
    else if (k == 2) { r->dx = PLAY_X0 - 2;     r->dy = TOP_Y0 + PLAY_Y0;     r->w = 2;                 r->h = PLAY_Y1 - PLAY_Y0; }
    else             { r->dx = PLAY_X1;         r->dy = TOP_Y0 + PLAY_Y0;     r->w = 2;                 r->h = PLAY_Y1 - PLAY_Y0; }
}
static void hud_rect(int k, irect_t *r)
{
    r->dx = HUD_X0; r->dy = TOP_Y0 + HUD_Y0; r->w = HUD_W; r->h = HUD_H;
    if (k == 0) return;                                  /* 底板 */
    if (k <= 4) {                                        /* 4 条边框 */
        if (k == 1) { r->h = 2; }
        else if (k == 2) { r->dy += HUD_H - 2; r->h = 2; }
        else if (k == 3) { r->w = 2; }
        else { r->dx += HUD_W - 2; r->w = 2; }
        return;
    }
    {   /* 动画条：底板 + 长度条（两根 FILL，长度按 g_anim 走三角波） */
        int i = k - 5;
        r->dx = HUD_X0 + 16; r->dy = TOP_Y0 + HUD_Y0 + 28 + i * 40; r->w = 144; r->h = 10;
    }
}
/* ==== DECOR_RECT_END ==== */

/* scissor 寄存器写入 + 软件镜像：**只有真的变了才写**，且调用点必须已确认引擎空闲
 * （寄存器在命令起始锁存 ⇒ 引擎没空闲就改，会串到前面那条命令上，见文件头 (a)） */
/* ==== CLIP_IO_BEGIN ====（主机自检原样取本段源码；需要外部：g_feat_clip / g_clip_on /
 * g_scis_on / g_clip_pass / g_clip_viol / g_clip_warn、BLT_CLIP_xxx 宏、iclip_t、blt_wr/blt_rd、
 * bsp_printf —— 自检用一个小模型把 0x90~0xA0 跑起来，专门验"回读说还开着 ⇒ 永久放弃裁剪"） */
static int g_cx0 = 0, g_cx1 = 0, g_cy0 = 0, g_cy1 = 0;

static void clip_apply(int on, int x0, int x1, int y0, int y1)
{
    if (!g_feat_clip) { g_clip_on = 0; return; }
    if (on) {
        blt_wr(BLT_CLIP_X0, (uint32_t)x0);
        blt_wr(BLT_CLIP_X1, (uint32_t)x1);
        blt_wr(BLT_CLIP_Y0, (uint32_t)y0);
        blt_wr(BLT_CLIP_Y1, (uint32_t)y1);
        blt_wr(BLT_CLIP_CTRL, BLT_CLIP_EN);
    } else {
        blt_wr(BLT_CLIP_CTRL, 0u);
    }
    g_clip_on = on; g_cx0 = x0; g_cx1 = x1; g_cy0 = y0; g_cy1 = y1;
}
/* 关掉 scissor（段 0 与"裁剪关闭"的 A/B 都走它） */
static void clip_off(void) { clip_apply(0, 0, 0, 0, 0); }
/* ★★ 段 0（信息条/HUD/边框/底图）进入前的硬保证：写 0 **并回读 0xA0 bit0 确认**。
 *   回读说还开着 ⇒ 说明这颗 bitstream 的 CLIP_CTRL 写不进/读不回 ⇒ 永久放弃裁剪
 *   （g_scis_on=0）并打一行 WARN：**宁可没有裁剪，也绝不让信息条被裁掉**。
 *   调用点必须已确认引擎空闲（寄存器在命令起始锁存）。 */
static int clip_off_verified(void)
{
    if (!g_feat_clip) { g_clip_on = 0; return 0; }
    clip_off();
    if (blt_rd(BLT_CLIP_CTRL) & BLT_CLIP_EN) {
        g_clip_on = 0; g_scis_on = 0; g_clip_pass = 0;
        g_clip_viol++;
        if (!g_clip_warn) {
            g_clip_warn = 1;
            bsp_printf("EV clip WARN: CLIP_CTRL readback still enabled -> scissor disabled\r\n");
        }
        return 0;
    }
    return 1;
}
/* 引擎软复位会把 CLIP_* 打回复位值：软件镜像必须一起"忘掉"，
 * 否则 clip_same() 会以为窗口还在 ⇒ 该裁的不裁（内容漏到窗口外）。 */
static void clip_forget(void) { g_clip_on = 0; g_cx0 = 0; g_cx1 = 0; g_cy0 = 0; g_cy1 = 0; }
/* 把某条命令的**局部**窗口写进 CLIP_*（调用点必须已确认引擎空闲） */
static void clip_arm(const iclip_t *w) { clip_apply(1, w->x0, w->x1, w->y0, w->y1); }
/* 当前 CLIP_* 是否已经等于这条命令要的局部窗口（相等就不重写 ⇒ 少一次空闲等待） */
static int clip_same(const iclip_t *w)
{
    return (g_clip_on && w->x0 == g_cx0 && w->x1 == g_cx1 && w->y0 == g_cy0 && w->y1 == g_cy1) ? 1 : 0;
}
/* ==== CLIP_IO_END ==== */

/* ============================== 全局演示状态 ============================== */
static int      g_scene   = SC_GLOW;
static int      g_n       = 320;
static unsigned g_alpha   = 255u;          /* 主 alpha 微调（乘到每精灵 alpha 上） */
static int      g_frame_adv = 0;           /* 0 = 按墙钟推进（25 步/秒） 1 = 每发布一帧推一步 */
static int      g_fx      = 1;             /* LUT 特效（淡入淡出 + 白闪）总开关 */
static int      g_auto    = 0;             /* 吞吐场景的自动爬坡 */
static uint32_t g_seed    = 0x12345678u;
static uint32_t g_anim    = 0;             /* 每步 +1：给扫掠条 / HUD 动画用 */

static uint32_t g_sc_frames = 0;           /* 已发布帧（1Hz 窗口） */
static uint32_t g_t_fx0     = 0;           /* fade 循环时间基 */
static uint32_t g_flash_ms  = 0;           /* 白闪剩余毫秒 */
static uint32_t g_flash_t0  = 0;           /* 白闪计时基点 */
static uint32_t g_flash_next= 0;           /* 分层场景下一次自动白闪的时刻 */
static uint32_t g_cmd_t0    = 0;           /* 本趟计时起点（成本行用） */
static uint32_t g_cost_t0   = 0;           /* 成本行 1Hz 门控 */

/* ============================== 一趟的两段结构 ==============================
 * 段 0 DECOR   ：scissor **关** —— 每趟底（清屏引擎没预清时）/ 场景底图 / HUD 侧栏 /
 *                裁剪边框 / 信息条
 * 段 1 CONTENT ：scissor **逐条按局部坐标** —— N 个精灵（+ 裁剪场景的两条扫掠条）
 * 中间夹一道**引擎空闲围栏**，段 1 内部再按"窗口变了"插 ST_CLIP：
 * 改 CLIP_* 之前必须确认引擎彻底空闲（寄存器在命令起始锁存，文件头 (a)）。
 * 段 0 的命令数很少（≤ 1 + HUD_ITEMS + 信息条 81 条），一次慢时间片内基本能推完。 */
#define ST_RESTART 0
#define ST_DECOR   1
#define ST_FENCE   2
#define ST_CONTENT 3
#define ST_CLIP    4
#define ST_WAIT    5
#define DEC_REPAINT 0
#define DEC_SCENE   1
#define DEC_BAR     2
#define DEC_DONE    3

static int      g_st        = ST_RESTART;
static int      g_decor_st  = DEC_REPAINT;
static int      g_decor_i   = 0;
static int      g_bar_need  = 0;
static int      g_bar_len   = 0;
static int      g_lbl_len   = 0;
static int      hw_i        = 0;
static int      hw_frame_pushed = 0;
static int      hw_done     = 0;
static int      back_busy   = 0;
static uint32_t back_t0     = 0;
static int      g_repaint   = 1;           /* 本趟要不要命令式重铺底 */
static int      snap_need   = 0;           /* 快照失效（位置变过） */
static uint32_t g_it        = 0;           /* 主循环圈计数 */
static iclip_t  g_clip_want;               /* ST_CLIP 要写进去的窗口（规划与写入分离） */
static int      g_clip_want_on = 0;        /* ST_CLIP 要写的是"开 + 该窗口"还是"关" */

#define SLOW_MASK      31u
#define BLT_WAIT_MASK   3u
#define BLT_WAIT_NOP   48u
#define HW_PUSH_BUDGET 64u
#define FLIP_TIMEOUT_TICKS (BSP_CLINT_HZ / 10u)     /* 100ms ≈ 6 场 @60Hz */
#define FLIP_GIVEUP_N   3                           /* 连续几次翻转不确认就"认下"继续走 */
#define ST_WAIT_TICKS  (BSP_CLINT_HZ / 5u)          /* 200ms ≈ 12 场：段机等待的上界 */
#define SCENE_TICKS    (BSP_CLINT_HZ / 25u)         /* 场景推进周期 40ms（25 步/秒） */
#define MAX_STEPS      8
/* ★ fade/flash 的毫秒常数与"拍→毫秒"换算已上移到 LUT_TAB 段（fx_elapsed_ms / fx_fade_of_ms /
 *   fx_flash_of_ms，主机自检能直接测）—— 上板"场景 2 不淡、场景 4 惨白"就是单位混用所致。 */

/* ---- ★ 有界等待 / 引擎停机恢复（本次修的第三个问题）----
 * 机理：引擎一旦停机（STATUS.ERR = 非法 op，**电平锁存、只有软复位能清**），DONE 永远不成立
 * ⇒ 老代码在 ST_RESTART / ST_FENCE / ST_CLIP / ST_WAIT 与"等 FIFO 余量"处无限空转：
 * 屏幕冻在最后一帧（上板看起来就是"场景 3 卡死、之后切不回去"），串口循环还在跑但一帧都
 * 画不出来。现在每个等待都有上界；超了就打印一次诊断 + 软复位引擎（顺带清命令 FIFO）+
 * 忘掉 CLIP 镜像 + 重开本趟 ⇒ **一定继续前进**，串口命令循环绝不被阻塞。 */
#define ST_WAIT_MORE   0
#define ST_WAIT_IDLE   1
#define ST_WAIT_TIMEO  2
#define STW_RESTART    0
#define STW_FENCE      1
#define STW_CLIP       2
#define STW_CONTENT    3
#define STW_ROOM       4

static uint32_t g_st_t0    = 0;      /* 当前等待起点 */
static int      g_st_which = -1;     /* 当前等待的归属（换归属就重置计时） */
static uint32_t g_st_prog  = 0xFFFFFFFFu; /* 上次看到的命令 FIFO 条数（进度判据） */
static uint32_t g_st_to    = 0;      /* 等待超时（= 引擎被软复位）次数，正常恒 0 */
static int      g_st_warn  = 0;      /* 超时诊断行只打前几次，避免刷屏 */

/* ==== ST_TIMEOUT_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 一次"有界等待"的判据（板上 blt_idle_bounded / blt_room_bounded 与主机自检共用同一份）：
 *   idle=1（或余量够）⇒ ST_WAIT_IDLE 并把计时器清掉；否则第一次进入时记时，
 *   超过 ticks 就返回 ST_WAIT_TIMEO ⇒ 调用方**必须**走恢复（软复位 + 重开本趟）。
 * ★ 返回值只有三种，永远不存在"继续无限等"这一档：自检拿"引擎停机（idle 恒 0）"的模型
 *   逐拍跑到第 ticks+1 拍，断言一定拿到 ST_WAIT_TIMEO —— 这就是上板"卡死"的守门人。 */
static int st_wait_state(int which, int idle, uint32_t now, uint32_t ticks,
                         int *cur_which, uint32_t *cur_t0)
{
    if (idle) { *cur_which = -1; return ST_WAIT_IDLE; }
    if (*cur_which != which) { *cur_which = which; *cur_t0 = now; }
    if ((uint32_t)(now - *cur_t0) > ticks) return ST_WAIT_TIMEO;
    return ST_WAIT_MORE;
}
/* 进度判据（和上面那条一起构成"有界但不误判"）：命令 FIFO 条数变了 ⇒ 引擎在动，
 * 这是"慢"不是"卡"，把等待计时器往前推。★ 没有这一条，N=6000 的吞吐场景（一整趟
 * 要 0.2s 以上）会被当成停机误恢复 ⇒ 永远画不完；有了它，只有"计数完全冻住"才超时。 */
static int st_wait_progress(uint32_t cnt, uint32_t *last, uint32_t now, uint32_t *cur_t0)
{
    if (cnt == *last) return 0;
    *last = cnt;
    *cur_t0 = now;
    return 1;
}
/* ==== ST_TIMEOUT_END ==== */

/* 一次"等引擎彻底空闲"的有界判定（非阻塞：只在 poll 圈读 STATUS，其余圈纯空转） */
static int blt_idle_bounded(int which)
{
    uint32_t st, cnt;
    int      r;
    if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); return ST_WAIT_MORE; }
    st  = blt_stat();
    cnt = blt_cnt();
    if (blt_idle_st(st)) { g_st_which = -1; g_st_prog = cnt; return ST_WAIT_IDLE; }
    (void)st_wait_progress(cnt, &g_st_prog, tick32(), &g_st_t0);
    r = st_wait_state(which, 0, tick32(), (uint32_t)ST_WAIT_TICKS, &g_st_which, &g_st_t0);
    if (r == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    return r;
}
/* FIFO 余量的有界等待：*room = 余量（只在返回 ST_WAIT_IDLE 时有效）。
 * 余量 0 又长时间**没有任何进度**（引擎停机 ⇒ 永远排不空）⇒ ST_WAIT_TIMEO ⇒ 调用方恢复。 */
static int blt_room_bounded(uint32_t *room)
{
    uint32_t cnt = blt_cnt();
    int      r;
    *room = blt_push_room_of(cnt);
    (void)st_wait_progress(cnt, &g_st_prog, tick32(), &g_st_t0);
    r = st_wait_state(STW_ROOM, (*room > 0u) ? 1 : 0, tick32(), (uint32_t)ST_WAIT_TICKS,
                      &g_st_which, &g_st_t0);
    if (r == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    return r;
}
/* 恢复：软复位引擎 + 忘掉 CLIP 镜像 + 重开本趟。硬件侧 blt_wr(0x00, SOFT_RST→GO) 会把
 * err_out / 命令 FIFO / 引擎状态机一起清掉（rtl/blt_top.v: int_rst_n = rst_n & ~soft_rst）。 */
static void blt_recover(const char *why, int which)
{
    uint32_t st = blt_stat();
    g_st_to++;
    if (g_st_warn < 4) {
        g_st_warn++;
        bsp_printf("\r\nEV st timeout: %s st=%d STATUS=%x COUNT=%d CLR=%x -> engine soft reset\r\n",
                   why, which, (unsigned)st, (int)blt_cnt(), (unsigned)clr_stat());
    }
    blt_init();                     /* 软复位 + GO：停机 ERROR 与 FIFO 一起清 */
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);   /* ★ 软复位会关帧中断 ⇒ 重新打开 */
    clip_forget();                  /* CLIP_* 被打回复位值 ⇒ 镜像一起忘掉 */
    g_clip_pass  = 0;
    g_pass_armed = 0;
    g_repaint    = 1;
    hw_i = 0; hw_frame_pushed = 0;
    g_decor_st = DEC_REPAINT; g_decor_i = 0;
    g_st = ST_RESTART;
    g_st_which = -1;
    g_st_t0 = tick32();
}

/* 每帧内容项数 = N + （裁剪场景的 2 条扫掠条） */
static int content_total(void) { return g_n + ((g_scene == SC_CLIP) ? 2 : 0); }

/* ---- 段 0 的各个"条目" ---- */
/* 每趟底：清屏引擎已经把目标缓冲预清过就用不着；不干净时在这里补一条。
 * 分层场景用**整幅背景 COPY** 代替纯色 FILL —— 它同时就是那张"大图搬移"。 */
static void decor_repaint_emit(void)
{
    uint32_t dst = g_fb_back + (uint32_t)TOP_Y0 * FB_STRIDE;
    if (g_scene == SC_LAYER)
        blt_copy(BG_BASE, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, (uint32_t)PLAY_H);
    else
        blt_fill(dst, FB_STRIDE, FB_WIDTH, (uint32_t)PLAY_H, COL_BG);
}
/* 裁剪窗口的 4 条边框（画在窗口**外面**，且这一段 scissor 是关的 ⇒ 一定看得见），
 * 用来把"裁剪边界到底在哪"钉死在屏幕上。几何全部来自 clip_edge_rect()（自检同一份）。 */
static void decor_clip_edge_emit(int k)
{
    irect_t r;
    clip_edge_rect(k, &r);
    blt_fill(g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u,
             FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_CLIPEDGE);
}
/* HUD 侧栏（**在裁剪窗口之外**，所以只能在 scissor 关着的段 0 里画）：
 * 底板 + 4 条边框 + 若干根随时间伸缩的条 —— 全部是引擎 FILL。
 * 几何全部来自 hud_rect()（自检同一份）。 */
static void decor_hud_emit(int k)
{
    irect_t  r;
    uint32_t dst;
    hud_rect(k, &r);
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    if (k == 0) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL); return; }
    if (k <= 4) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL2); return; }
    /* 动画条：长度按 g_anim + i 走一条三角波 ⇒ "HUD 在动"一眼可见（底板 + 长度条两根） */
    {
        int      i     = k - 5;
        uint32_t phase = (uint32_t)((g_anim / 3u + (uint32_t)i * 37u) % 200u);
        uint32_t w     = (phase < 100u) ? (phase * 2u) : ((200u - phase) * 2u);
        blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL2);
        blt_fill(dst, FB_STRIDE, (w * (uint32_t)r.w) / 200u, (uint32_t)r.h,
                 (i & 1) ? COL_AMBER : COL_CYAN);
    }
}
/* 段 0 的推进器：返回 1 = 段 0 全部推完（可以进围栏了）。
 * ★ 这里下发的每一条都是 CLIP_CLS_DECOR（屏幕骨架）⇒ 段 0 的调用点必须先 clip_off_verified()，
 *   blt_emit() 出口还有一道 clip_emit_guard() 兜底（两处任一处漏了都会立刻可见/可诊断）。 */
static int decor_step(uint32_t *room)
{
    g_emit_cls = CLIP_CLS_DECOR;
    while (*room > 0u) {
        if (g_decor_st == DEC_REPAINT) {
            if (g_repaint) { decor_repaint_emit(); g_repaint = 0; (*room)--; break; }
            g_decor_st = DEC_SCENE; g_decor_i = 0; break;
        }
        if (g_decor_st == DEC_SCENE) {
            if (g_scene == SC_CLIP) {
                if (g_decor_i < 4) { decor_clip_edge_emit(g_decor_i++); (*room)--; break; }
                if (g_decor_i < 4 + HUD_ITEMS) { decor_hud_emit(g_decor_i++ - 4); (*room)--; break; }
            }
            g_decor_st = DEC_BAR; g_decor_i = 0; break;
        }
        if (g_decor_st == DEC_BAR) {
            if (g_bar_need) {
                irect_t  r;
                uint32_t dst;
                if (g_decor_i == 0) {                     /* ① 一条黑底铺满整条信息条 */
                    osd_strip_rect(&r);
                    blt_fill(g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u,
                             FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_OSD_BG);
                    g_decor_i = 1; (*room)--; break;
                }
                if (g_decor_i <= g_bar_len) {              /* ② 左串逐个字形（KEY 抠图） */
                    int c = g_decor_i - 1;
                    osd_glyph_rect(c, g_bar_len, &r, 1);
                    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
                    blt_key(FONT_BASE + FONT_GLYPH_OFF(glyph_idx(g_osd_line[c])),
                            dst, FONT_ROW_BYTES, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h,
                            (uint32_t)KEY_COLOR);
                    g_decor_i++; (*room)--; break;
                }
                if (g_decor_i <= g_bar_len + g_lbl_len) {  /* ③ 右标签（右对齐） */
                    int c = g_decor_i - g_bar_len - 1;
                    osd_glyph_rect(c, g_lbl_len, &r, 0);
                    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
                    blt_key(FONT_BASE + FONT_GLYPH_OFF(glyph_idx(OSD_LABEL[c])),
                            dst, FONT_ROW_BYTES, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h,
                            (uint32_t)KEY_COLOR);
                    g_decor_i++; (*room)--; break;
                }
                /* 整条信息条推完 ⇒ 记账（下一趟轮到同一块缓冲时不必再画） */
                if (g_osd_dirty) { g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0; g_osd_dirty = 0; }
                g_bar_ok[(uint32_t)g_draw3] = 1;
            }
            g_decor_st = DEC_DONE; break;
        }
        return 1;                                    /* DEC_DONE */
    }
    return 0;
}

/* ---- 段 1 的各个"条目"（几何与裁剪规划**共用** content_rect()，不会各算各的） ---- */
/* ==== CONTENT_RECT_BEGIN ====（主机自检原样取本段源码；需要 part_t/g_pt/g_n/MAXPT、
 * SPR_W/SPR_H、FB_WIDTH/PLAY_H、SWEEP_T、TOP_Y0、PLAY_X0/PLAY_Y0/PLAY_X1/PLAY_Y1、g_anim
 * —— 自检按"精灵的每种相对位置 + 三种宽条"逐例核对局部窗口的平移结果） */
static int g_sw_y = PLAY_Y0;      /* 横扫条 y（屏幕坐标，**本趟快照**） */
static int g_sw_x = PLAY_X0;      /* 竖扫条 x（同上） */
static void sweep_snap(void)
{
    g_sw_y = PLAY_Y0 + (int)(g_anim % (uint32_t)(PLAY_Y1 - PLAY_Y0 - SWEEP_T));
    g_sw_x = PLAY_X0 + (int)((g_anim * 2u) % (uint32_t)(PLAY_X1 - PLAY_X0 - SWEEP_T));
}
/* 内容项 k → 目标矩形（屏幕坐标 + 尺寸）。一维定义：绘制与裁剪都从这里取几何。 */
static void content_rect(int k, irect_t *r)
{
    if (k < g_n) {                                  /* 精灵 */
        r->dx = (int)g_pt[k].tx; r->dy = (int)g_pt[k].ty;
        r->w  = SPR_W;           r->h  = SPR_H;
    } else if (k == g_n) {                          /* 横扫条：整屏宽 x SWEEP_T */
        r->dx = 0;               r->dy = TOP_Y0 + g_sw_y;
        r->w  = FB_WIDTH;        r->h  = SWEEP_T;
    } else {                                        /* 竖扫条：SWEEP_T x 渲染区高 */
        r->dx = g_sw_x;          r->dy = TOP_Y0;
        r->w  = SWEEP_T;         r->h  = PLAY_H;
    }
}
/* ==== CONTENT_RECT_END ==== */
static void sprite_emit(int i)
{
    part_t  *p = &g_pt[i];
    irect_t  r;
    unsigned ga = ((unsigned)p->a * g_alpha) / 255u;
    uint32_t dst;
    content_rect(i, &r);
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    if (g_scene == SC_CLIP)
        /* 裁剪场景用 RGB565 色键圆盘（硬边、看得清有没有越界） */
        blt_key(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, (uint32_t)KEY_COLOR);
    else
        blt_glow(GLOW_BASE + (uint32_t)p->v * GLOW_VAR_STRIDE, dst, ga);
}
/* 裁剪场景的两条**扫掠条**：整屏宽 / 整屏高，跨度远超裁剪窗口。
 * 只有落在窗口里的那一段能画出来 —— "裁剪不会漏出去"的最直观证据（'x' 一关立刻糊满全屏）。 */
static void sweep_emit(int k)
{
    irect_t  r;
    uint32_t dst;
    content_rect(g_n + k, &r);                      /* k = 0 横扫 / 1 竖扫 */
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, (k == 0) ? COL_CYAN : COL_AMBER);
}
static void content_emit(int k)
{
    g_emit_cls = CLIP_CLS_FIELD;                    /* ★ 段 1 = playfield 内容：唯一允许被裁的一类 */
    if (k < g_n)                 sprite_emit(k);
    else if (g_scene == SC_CLIP) sweep_emit(k - g_n);
}
/* 内容项的裁剪规划（只在 g_clip_pass 时平移/跳过）：
 *   返回 1 = 目标矩形与窗口**无交集** ⇒ 这条命令整条省掉（画了也全在窗口外）；
 *   返回 0 = 可以发；*need = 1 表示发之前必须先把 CLIP_* 改成 *w（要走 ST_CLIP 的围栏）。 */
static int content_plan(int k, iclip_t *w, int *need)
{
    irect_t r;
    *need = 0;
    if (!g_clip_pass) {                             /* 裁剪关（含 'x' 的 A/B）⇒ 逐位回到全屏 playfield */
        if (g_clip_on) { *need = 1; w->x0 = w->x1 = w->y0 = w->y1 = 0; }
        return 0;
    }
    content_rect(k, &r);
    if (!clip_local(r.dx, r.dy, r.w, r.h, w)) return 1;   /* 不相交 ⇒ 跳过 */
    if (clip_same(w)) return 0;                           /* 窗口没变 ⇒ 不用重写寄存器 */
    *need = 1;
    return 0;
}

/* ============================== 特效：LUT 的 fade / flash 时间线 ==============================
 * fade 只在场景 2（FADE）里走一条 3.6s 的循环：淡到黑 → 停 → 淡回来 → 停。
 * flash 是**全场景**的：切场景时自动来一下，串口 'b' 或分层场景每 3s 也来一下。
 * ★ 不需要 LUT 的场景（不是 FADE 且当前没白闪）一律发布 **恒等表 + 使能 0**
 *   （want_en=0 ⇒ 表就是恒等表）⇒ 陈旧表/白闪表绝不可能留在屏上洗不掉。 */
static void fx_update(uint32_t now)
{
    unsigned f = 255u, g = 0u;
    int      want_en = 0;

    if (g_fx && g_feat_lut) {
        if (g_scene == SC_FADE)
            f = fx_fade_of_ms(fx_elapsed_ms(now, g_t_fx0));   /* ★ 拍→毫秒只在这里换算一次 */
        if (g_flash_ms > 0u)
            g = fx_flash_of_ms(g_flash_ms);                   /* g_flash_ms 本来就是毫秒 */
        want_en = ((f != 255u) || (g != 0u)) ? 1 : 0;
    }
    /* 表格内容或使能意图任一变过 ⇒ 重算 3x256 项写进**非显示** bank，等帧边界发布 */
    if (f != g_lut_f || g != g_lut_g || want_en != g_lut_stage_en) {
        lut_write_table(f, g, want_en);
    }
}

/* ============================== ★ EV diag：扫描输出通路的每秒诊断 ==============================
 * 背景：板级症状（引擎画的信息条糊、场景 3 整屏条纹）在软件三处修复之后**依然存在**
 *   ⇒ 主导假设换成"显示/扫描输出通路本身被饿死"（开机日志 SCAN=00070108 = abort 7 /
 *   underrun 264，正是 0x20 上的累计值），需要**随时间变化**的数字来证实或推翻它。
 * 这一行只做一件事：把五个寄存器**现读**出来（不缓存），配上一组开机累计计数，
 * 让"扫描饿死"和"渲染器画错"在串口上可区分：
 *   fps/n/sz    已发布帧率 / 精灵数 / 精灵边长（这帧到底跑成什么样）；
 *   scn/ab/un   SCAN_DBG 原始值 + 解码后的 abort[31:16] / underrun[15:0]；
 *               ★ 每秒都在涨 ⇒ 扫描输出被饿死（显示通路问题，不是渲染问题）；
 *   st          引擎 STATUS(0x04) 原始值（bit2=ERR / bit1=DONE / bit3=FIFO_EMPTY）；
 *   clip/lut/lbank  CLIP_CTRL(0xA0) / LUT_CTRL(0xAC) / LUT_STAT(0xB0) 的实时回读；
 *   stto        引擎等待超时（含 ST_CLIP 围栏）累计次数（= blt_recover 次数，正常 0）；
 *   flp/flpt    翻转**确认** / 翻转**超时**累计次数（flpt 一直涨 ⇒ 帧边界不来 = 扫描没跑）。
 * ★ 代价：每 1Hz 只有 5 次寄存器读 + 1 行 UART（约 130 字符）；没有逐像素工作、
 *   没有新的忙等，且从**既有的慢时间片**里打印 ⇒ 渲染循环时序不变。 */
static uint32_t g_diag_t0  = 0;    /* EV diag 行的 1Hz 门控（与 osd / cost 各自独立，互不干扰） */
static uint32_t g_flip_ok  = 0;    /* 开机以来**已确认**的翻转次数（= 真正上屏的帧数） */
static uint32_t g_flip_bad = 0;    /* 开机以来翻转确认超时次数（正常恒 0；连涨 3 次后给放弃） */

static void ev_diag_line(void)
{
    uint32_t scan = blt_rd(BLT_SCAN_DBG);      /* 0x20：{abort[31:16], underrun[15:0]}，现读 */
    uint32_t stat = blt_stat();                /* 0x04：引擎状态，现读 */
    uint32_t clip = blt_rd(BLT_CLIP_CTRL);     /* 0xA0：裁剪使能（回读 = 实机状态） */
    uint32_t lctl = blt_rd(BLT_LUT_CTRL);      /* 0xAC：LUT 使能 + 写 bank */
    uint32_t lst  = blt_rd(BLT_LUT_STAT);      /* 0xB0：正在显示的 bank */
    /* ★ 只用 %d/%x（BSP 的 mini printf 只认 %c %s %d %X %x；出现 %u 会错位消耗 va_arg）。
     *   原始值与解码值一起打：scn= 是 0x20 的原样 8 位十六进制，ab=/un= 是它解出来的十进制。 */
    bsp_printf("EV diag: fps=%d n=%d sz=%d scn=%x ab=%d un=%d st=%x clip=%x lut=%x lbank=%x stto=%d flp=%d flpt=%d\r\n",
               (int)g_fps, g_n, (int)SPR_W,
               (unsigned)scan, (int)BLT_SCAN_ABORT(scan), (int)BLT_SCAN_UNDERRUN(scan),
               (unsigned)stat, (unsigned)clip, (unsigned)lctl, (unsigned)lst,
               (int)g_st_to, (int)g_flip_ok, (int)g_flip_bad);
}

/* ============================== 主程序 ============================== */
static void banner(void)
{
    bsp_printf("\r\n===== AdDemo: hardware renderer only -- zero CPU pixels =====\r\n");
    bsp_printf("FB=%x BACK=%x BUF2=%x ATLAS=%x GLOW=%x FONT=%x BG=%x\r\n",
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)FB_BUF2, (unsigned)ATLAS_BASE,
               (unsigned)GLOW_BASE, (unsigned)FONT_BASE, (unsigned)BG_BASE);
    bsp_printf("layout: info 0-%d (engine-drawn) | render %d-%d (%dx%d)\r\n",
               OSD_H, TOP_Y0, FB_HEIGHT, FB_WIDTH, PLAY_H);
    bsp_printf("sprite %dx%d, 'k' cycles %d/%d/%d (atlas+scene rebuilt)\r\n",
               SPR_W, SPR_H, BLK_LO, BLK_MID, BLK_HI);
    bsp_printf("cmd: 1=GLOW 2=FADE 3=CLIP 4=LAYER 5=THRU  scene\r\n");
    bsp_printf("     n or +  N+%d   -  N-%d   =N exact N (%d..%d clamped, e.g. =1500)\r\n",
               N_STEP, N_STEP, N_MIN, N_MAX);
    bsp_printf("     k  size 16/32/64   t  advance time/frame   a/A  master alpha -/+\r\n");
    bsp_printf("     f  LUT fade/flash on/off   b  flash now   x  scissor on/off (A/B)\r\n");
    bsp_printf("     y  attribute side-port on/off (A/B)   q  auto count ramp (scene 5)\r\n");
    bsp_printf("     r  reset scene (new seed)   ?  help\r\n");
    bsp_printf("     d  EV diag line now (it also prints once per second)\r\n");
    bsp_printf("attr: write ATTR_PORT BEFORE the 8 command words; 1 word per command\r\n");
    bsp_printf("      1 command = 1 attr word + 8 cmd words (default=%X = blend0/565/ga255)\r\n",
               (unsigned)ATTR_DEFAULT);
    bsp_printf("frozen: scissor [x0,x1)x[y0,y1) in DST-LOCAL coords | LUT 0xAC.bit1=WRITE bank,\r\n");
    bsp_printf("        display=~latched bit1, 0xB0=displayed bank: read 0xB0 -> write ~disp ->\r\n");
    bsp_printf("        publish 0xAC.bit1=disp (4 steps; polarity tested live, see 'EV lut' lines)\r\n");
    bsp_printf("osd: FPS published | N sprites | MPX = N*SZ*SZ*FPS/1e6 | B = engine busy %c\r\n", '%');
    bsp_printf("cost: EV cmd path done: n=.. cycles=.. cyc/sprite=.. (1 line/s)\r\n");
    bsp_printf("diag: EV diag: fps=.. n=.. sz=.. scn=.. ab=.. un=.. st=.. clip=.. lut=.. lbank=.. stto=.. flp=.. flpt=..\r\n");
    bsp_printf("      (1 line/s + on demand with 'd'; scn=SCAN 0x20 raw, ab=[31:16], un=[15:0];\r\n");
    bsp_printf("       ab/un climbing every second = scanout starved, flat = renderer problem)\r\n");
}

/* 启动自检的"信息条最坏宽度"证明：用**真实的 fmt_stat** 跑最坏取值 */
static void osd_selfcheck(void)
{
    char worst[OSD_LEFT_CH + 2];
    int  len;
    fmt_stat(worst, 99u, N_MAX, SC_LAYER, BLK_HI, 255u, 9999u, 100u, 1, 1, 1, 1, 1);
    len = slen(worst);
    bsp_printf("osd worst: len=%d px=%d text x=[%d,%d) strip x=[%d,%d) label x=[%d,%d) fit=%d\r\n",
               len, len * OSD_GLYPH_W, OSD_TEXT_X0, OSD_TEXT_X0 + len * OSD_GLYPH_W,
               OSD_TEXT_X0, OSD_TEXT_X0 + OSD_LEFT_PX,
               FB_WIDTH - OSD_RIGHT_PX, FB_WIDTH, (len <= OSD_LEFT_CH) ? 1 : 0);
    bsp_printf("osd worst: \"%s\"\r\n", worst);
}

int main(int argc, char **argv)
{
    uint32_t t_now, t_scene;
    int      n_cmd = N_MIN;
    int      pend_adv = 0;
    int      size_repaint = 0;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */
    banner();

    blt_init();
    /* 先与实际在屏的缓冲对齐（不假设复位值），再定三缓冲轮转初值 */
    g_disp_sel = (int)fb_stat_sel();
    g_draw3    = (int)(((uint32_t)g_disp_sel + 1u) % 3u);
    g_clr3     = (int)(((uint32_t)g_disp_sel + 2u) % 3u);
    g_clr_need = 1;
    g_pass_armed = 0;
    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    g_flip_req = (uint32_t)g_disp_sel;

    feat_probe();
    align_selfcheck();
    attr_selfcheck();
    argb_selfcheck();
    build_atlas();
    build_bg();
    cache_evict();

    /* ★ 开机自检行也把 SCAN_DBG 解出来（与每秒的 EV diag 行同一组宏、同一口径）：
     *   SCAN=00070108 ⇒ ab=7 un=264 —— 上板第一眼就能看到扫描输出是否已经在报错。 */
    {
        uint32_t scan0 = blt_rd(BLT_SCAN_DBG);
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x ab=%d un=%d FB=%x\r\n",
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)scan0,
                   (int)BLT_SCAN_ABORT(scan0), (int)BLT_SCAN_UNDERRUN(scan0),
                   (unsigned)blt_rd(BLT_FB_STAT));
    }

    /* 三块缓冲各用**引擎**铺一次底（CPU 一个像素都不写）。
     * 本趟要画的那块（g_fb_back）不铺 —— 信息条随即由段 0 画进去。 */
    {
        int k;
        for (k = 0; k < 3; k++) {
            if (k == g_draw3) continue;
            blt_fill(fb_of_sel((uint32_t)k) + (uint32_t)TOP_Y0 * FB_STRIDE, FB_STRIDE,
                     FB_WIDTH, (uint32_t)PLAY_H, COL_BG);
            blt_fill(fb_of_sel((uint32_t)k), FB_STRIDE, FB_WIDTH, (uint32_t)OSD_H, COL_OSD_BG);
        }
    }
    /* 开 IRQ 帧节拍：翻转确认改由扫描输出的帧边界事件驱动 */
    blt_wr(BLT_IRQ_STATUS, 0xFFFFFFFFu);
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);

    scene_init(g_n, g_seed);
    t_now = tick32();
    g_osd_t0 = t_now; t_scene = t_now; g_t_fx0 = t_now;
    g_diag_t0 = t_now;                 /* ★ EV diag 行从开机起也走 1Hz（与 osd 同一个起点） */
    g_flash_t0 = t_now; g_flash_ms = FLASH_MS; g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
    osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto);
    osd_selfcheck();
    bsp_printf("publish: FLIPx3 disp=%d draw=%d clr=%d (clear engine on)\r\n",
               g_disp_sel, g_draw3, g_clr3);
    bsp_printf("scenes ready: 1 GLOW 2 FADE 3 CLIP 4 LAYER 5 THRU, N=%d, SZ=%d\r\n", g_n, SPR_W);

    for (;;) {
        g_it++;

        /* ============ 慢时间片（每 32 圈）：UART + 时间 + 场景 + 1Hz 统计 + 占用采样 ============ */
        if ((g_it & SLOW_MASK) == 0u) {
            int      c  = uart_poll_char();
            uint32_t st = blt_stat();          /* ★ 本圈唯一一次 STATUS 读：顺便当占用采样 */
            t_now = tick32();
            g_busy_s++;
            if (!blt_idle_st(st)) g_busy_n++;

            /* ---------------- 串口命令 ---------------- */
            if (c) {
                int scene_change = 0, disp_change = 0;
                int nl = nline_feed(c, &n_cmd);
                if (nl == NL_OK) {
                    g_n = n_cmd;
                    scene_change = 1; disp_change = 1;
                    g_auto = 0;                            /* 手动给数 ⇒ 关掉自动爬坡 */
                    bsp_printf("\r\nEV N=%d\r\n", g_n);
                } else if (nl == NL_ERR) {
                    bsp_printf("\r\nEV N=ERR\r\n");
                } else if (nl == NL_NONE) {
                    if (c >= '1' && c <= '5') {
                        g_scene = c - '1';
                        scene_change = 1; disp_change = 1;
                        g_auto = (g_scene == SC_THRU) ? 1 : 0;
                        g_flash_ms = FLASH_MS;                 /* 切场景给一下白闪 */
                        g_flash_t0 = t_now;
                        g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
                        g_t_fx0 = t_now;
                        bsp_printf("\r\nEV scene=%d (%s)\r\n", g_scene, scene_name(g_scene));
                    } else if (c == 'n' || c == 'N' || c == '+') {
                        g_n += N_STEP; if (g_n > N_MAX) g_n = N_MAX;   /* 只钳不绕 */
                        scene_change = 1; disp_change = 1; g_auto = 0;
                        bsp_printf("\r\nEV N=%d\r\n", g_n);
                    } else if (c == '-') {
                        g_n -= N_STEP; if (g_n < N_MIN) g_n = N_MIN;
                        scene_change = 1; disp_change = 1; g_auto = 0;
                        bsp_printf("\r\nEV N=%d\r\n", g_n);
                    } else if (c == 'k' || c == 'K') {
                        g_blk = blk_next(g_blk);
                        build_atlas();                 /* 尺寸一变必须重建图集（跨度也变了） */
                        scene_change = 1; disp_change = 1;
                        size_repaint = 2;              /* 另外两块缓冲里还是旧尺寸，各补铺一次 */
                        bsp_printf("\r\nEV size=%d\r\n", g_blk);
                    } else if (c == 't' || c == 'T') {
                        g_frame_adv = !g_frame_adv;
                        t_scene = t_now;
                        disp_change = 1;
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
                                   g_frame_adv);
                    } else if (c == 'f' || c == 'F') {
                        g_fx = !g_fx;
                        if (!g_fx) g_flash_ms = 0u;      /* 关掉特效 ⇒ 立刻回到恒等表 + 使能 0 */
                        disp_change = 1;
                        bsp_printf("\r\nEV lut=%d (1=LUT fade+flash on)\r\n", g_fx);
                    } else if (c == 'b' || c == 'B') {
                        g_flash_ms = FLASH_MS; g_flash_t0 = t_now;
                        bsp_printf("\r\nEV flash\r\n");
                    } else if (c == 'x' || c == 'X') {
                        g_scis_on = !g_scis_on;
                        disp_change = 1;
                        bsp_printf("\r\nEV scissor=%d (scene 3 only; needs CLIP_* in RTL)\r\n", g_scis_on);
                    } else if (c == 'y' || c == 'Y') {
                        g_attr_user = !g_attr_user;
                        g_attr_on = (g_feat_attr && g_attr_user) ? 1 : 0;
                        disp_change = 1;
                        bsp_printf("\r\nEV attr=%d (1=one ATTR word per command)\r\n", g_attr_on);
                    } else if (c == 'q' || c == 'Q') {
                        g_auto = !g_auto;
                        disp_change = 1;
                        bsp_printf("\r\nEV auto=%d (scene 5 count ramp)\r\n", g_auto);
                    } else if (c == 'a') {
                        if (g_alpha >= 32u) g_alpha -= 32u;
                        disp_change = 1;
                        bsp_printf("\r\nEV alpha=%d\r\n", (int)g_alpha);
                    } else if (c == 'A') {
                        if (g_alpha <= 223u) g_alpha += 32u;
                        disp_change = 1;
                        bsp_printf("\r\nEV alpha=%d\r\n", (int)g_alpha);
                    } else if (c == 'r' || c == 'R') {
                        scene_change = 1; g_seed += 0x9E3779B9u;
                        bsp_printf("\r\nEV reset\r\n");
                    } else if (c == 'd' || c == 'D') {
                        /* ★ 随按随打：与 1Hz 那行**同一条代码路径、同一格式**（不动画面、
                         *   不动任何状态，只是把当前寄存器读出来）⇒ 远端诊断按需取一份快照。 */
                        bsp_printf("\r\n");
                        ev_diag_line();
                    } else if (c == '?') {
                        bsp_printf("\r\ncmd: 1..5 = scene GLOW/FADE/CLIP/LAYER/THRU\r\n"
                                   "     n or + = N+%d   - = N-%d   =N = exact N (%d..%d clamped)\r\n"
                                   "     k = sprite size %d/%d/%d (cycles; atlas+scene rebuilt)\r\n"
                                   "     t = advance time(25 step/s) <-> per published frame\r\n"
                                   "     a/A = master alpha -/+   f = LUT fade/flash on/off   b = flash now\r\n"
                                   "     x = scissor on/off (A/B, scene 3)   y = attribute side-port on/off\r\n"
                                   "     q = auto count ramp (scene 5)   r = reset scene   ? = help\r\n"
                                   "     d = EV diag line now (also 1 line/s): fps n sz | scn/ab/un = scanout\r\n"
                                   "         st=STATUS clip=CLIP_CTRL lut=LUT_CTRL lbank=LUT_STAT stto flp flpt\r\n"
                                   "     (=N is a LINE command: needs CR/LF, e.g. =1500 + Enter)\r\n"
                                   "     osd: FPS published | N sprites/frame | MPX=N*SZ*SZ*FPS/1e6\r\n"
                                   "          B = engine busy percent (sampled) | FR F X Y Q = mode flags\r\n",
                                   N_STEP, N_STEP, N_MIN, N_MAX, BLK_LO, BLK_MID, BLK_HI);
                    }
                }
                if (scene_change) {
                    if (g_n > N_MAX) g_n = N_MAX;
                    if (g_n < N_MIN) g_n = N_MIN;
                    scene_init(g_n, g_seed);
                    hw_i = 0; hw_frame_pushed = 0; hw_done = 0; pend_adv = 0;
                    g_repaint = 1; snap_need = 0; g_pass_armed = 0;
                    g_st = ST_RESTART;                 /* 改 CLIP / 目标缓冲之前先等引擎空闲 */
                    g_decor_st = DEC_REPAINT; g_decor_i = 0;
                }
                if (disp_change)
                    osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto);
                /* ★ 事件驱动地把 LUT 状态打给用户（切场景 / 'f' / 'b' / 'x' 之后读这一行就知道
                 *   当前使能与显示 bank；三个字段都是回读实机寄存器，不是软件自说自话） */
                if (disp_change && g_feat_lut)
                    lut_state_line(g_scene == SC_FADE ? "fade" : "state");
            }

            /* ---------------- 场景推进：两种模式互斥 ---------------- */
            if (!g_frame_adv) {
                pend_adv = 0;
                if ((uint32_t)(t_now - t_scene) >= (uint32_t)SCENE_TICKS) {
                    int steps = 0;
                    t_scene = t_now;
                    do { scene_step(g_n); steps++; g_anim++; snap_need = 1; }
                    while ((uint32_t)(tick32() - t_scene) >= (uint32_t)SCENE_TICKS && steps < MAX_STEPS);
                }
            } else if (pend_adv > 0) {
                scene_step(g_n); g_anim++; snap_need = 1; pend_adv--;
            }

            /* ---------------- 白闪时间线 ---------------- */
            if (g_flash_ms > 0u) {
                uint32_t el_ms = fx_elapsed_ms(t_now, g_flash_t0);   /* ★ 拍 → 毫秒 */
                if (el_ms > 0u) {
                    g_flash_t0 += el_ms * MS_TICKS;      /* 只吃掉整毫秒，余数留给下一圈 */
                    g_flash_ms  = (g_flash_ms > el_ms) ? (g_flash_ms - el_ms) : 0u;
                }
            }
            if (g_fx && g_feat_lut && g_scene == SC_LAYER &&
                ((int32_t)(t_now - g_flash_next) >= 0)) {
                g_flash_ms = FLASH_MS; g_flash_t0 = t_now;
                g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
            }
            fx_update(t_now);
            /* ★ LUT 发布兜底：帧边界一直没确认（翻转在等/扫描输出没跑）时也不能让 LUT 状态
             *   永远停在"待发布"——那等于 fade 完全不动、或白闪表洗不掉。超时就地发布一次
             *   （写 bank 与显示 bank 仍然互补 ⇒ 不会撕裂），并打一行诊断。 */
            if (g_feat_lut && g_lut_pend >= 0 &&
                (uint32_t)(t_now - g_lut_pend_t0) > (uint32_t)LUT_PEND_TICKS) {
                g_lut_to++;
                lut_publish();
                if (g_lut_to <= 4u)
                    bsp_printf("\r\nEV lut WARN: publish timeout (flip not confirmed) -> published\r\n");
                lut_state_line("state");
            }

            /* ---------------- 1Hz 统计（值没变就不重画信息条）---------------- */
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, g_sc_frames, g_n, g_scene, g_alpha,
                            g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto)) {
                g_sc_frames = 0;
                /* ---- 场景 5 的自动爬坡：把 N 顶到帧预算边缘 ----
                 * 每秒调一次（与 fps 同一个窗口 ⇒ 判据用的就是屏幕上那个 FPS）：
                 * 掉到 52fps 以下退一大步，稳在 58fps 以上进一步。 */
                if (g_scene == SC_THRU && g_auto) {
                    int nn = g_n;
                    if (g_fps <  52u) nn -= N_STEP * 2;
                    else if (g_fps >= 58u) nn += N_STEP;
                    if (nn < N_MIN) nn = N_MIN;
                    if (nn > N_MAX) nn = N_MAX;
                    if (nn != g_n) {
                        g_n = nn;
                        scene_init(g_n, g_seed);
                        hw_i = 0; hw_frame_pushed = 0; hw_done = 0;
                        g_repaint = 1; snap_need = 0; g_pass_armed = 0;
                        g_st = ST_RESTART; g_decor_st = DEC_REPAINT; g_decor_i = 0;
                        osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on,
                                  g_attr_on, g_auto);
                    }
                }
            }

            /* ---------------- ★ 1Hz 诊断行：扫描输出/显示通路有没有被饿死 ----------------
             * 独立门控（不看 osd_service 的返回值、也不等"本趟画完"）：引擎卡住或扫描输出
             * 不报帧边界时，这一行照样每秒出来 —— 正好用来区分"扫描饿死"与"渲染器画错"
             * （判读方法见 ev_diag_line 上方的注释）。整段只多 5 次寄存器读 + 1 行 UART。 */
            if ((uint32_t)(t_now - g_diag_t0) >= (uint32_t)BSP_CLINT_HZ) {
                g_diag_t0 = t_now;
                ev_diag_line();                /* 与串口 'd' 完全同一条代码路径 */
            }
        }

        /* ---------------- 翻转在飞的窗口：做下一趟的活 + 有界等待 ---------------- */
        if (back_busy) {
            if (snap_need) { scene_snap(g_n); snap_need = 0; }
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, g_sc_frames, g_n, g_scene, g_alpha,
                            g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto)) {
                g_sc_frames = 0;
            }
            if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); continue; }
            {
                int      flip_ev = 0;
                uint32_t irq = blt_rd(BLT_IRQ_STATUS);
                if (irq & BLT_IRQ_FRAME) {
                    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);      /* W1C：清本场中断 */
                    flip_ev = 1;
                }
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
                    /* ---- 帧边界：这一帧真的上屏了 ---- */
                    int old_disp = g_disp_sel;
                    back_busy  = 0;
                    g_flip_to  = 0;
                    g_disp_sel = (int)g_flip_req;
                    g_draw3    = g_clr3;
                    g_clr3     = old_disp;
                    g_clr_need = 1;                 /* 下一趟开始时给清屏引擎下新命令 */
                    g_pass_armed = 0;
                    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
                    g_st       = ST_RESTART;
                    g_decor_st = DEC_REPAINT; g_decor_i = 0;
                    g_sc_frames++;
                    g_flip_ok++;                    /* ★ EV diag 的 flp：开机以来确认的翻转数 */
                    if (g_frame_adv && pend_adv < MAX_STEPS) pend_adv++;
                    lut_publish();                  /* ★ LUT 两 bank 只在帧边界切换 */
                    if (size_repaint > 0) { g_repaint = 1; size_repaint--; }
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
                    g_flip_to++;
                    g_flip_bad++;                        /* ★ EV diag 的 flpt：开机以来超时数 */
                    blt_wr(BLT_FB_SEL, g_flip_req);      /* 重发请求，继续有界等待 */
                    back_t0 = tick32();
                    if (g_flip_to <= FLIP_GIVEUP_N) {
                        if (g_flip_to == 1u)
                            bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
                                       (unsigned)blt_rd(BLT_FB_STAT));
                    } else {
                        /* ★ 连续多次确认不到（扫描输出没跑 / FB_STAT 不跟）⇒ 不再无限等：
                         * 认下这次翻转继续走。屏幕上可能是"慢半拍"，但绝不冻结，
                         * 串口随时能切场景（这正是上板"切不回去"的那个死点之一）。 */
                        int old_disp2 = g_disp_sel;
                        g_flip_to  = 0;
                        back_busy  = 0;
                        g_disp_sel = (int)g_flip_req;
                        g_draw3    = g_clr3;
                        g_clr3     = old_disp2;
                        g_clr_need = 1;
                        g_pass_armed = 0;
                        g_fb_back  = fb_of_sel((uint32_t)g_draw3);
                        g_st       = ST_RESTART;
                        g_decor_st = DEC_REPAINT; g_decor_i = 0;
                        bsp_printf("\r\nEV flip giveup after %d timeouts (FB_STAT=%x) -> continue\r\n",
                                   (int)FLIP_GIVEUP_N, (unsigned)blt_rd(BLT_FB_STAT));
                        lut_publish();               /* 帧边界没确认也要把 LUT 状态推上去 */
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
            }
        } else if (hw_done) {
            /* ---------------- 发布：请求翻到"刚画好的这一块"（一次 DDR 搬运都不做）---------------- */
            g_flip_req = (uint32_t)g_draw3;
            blt_wr(BLT_FB_SEL, g_flip_req);
            back_busy = 1;
            back_t0   = tick32();
            hw_done   = 0;
        } else {
            /* ---------------- 段机：把本趟的命令流推出去 ---------------- */
            switch (g_st) {
            case ST_RESTART: {
                /* 改 CLIP / 拍快照 / 改目标缓冲之前，先确认引擎彻底空闲（文件头 (a)）；
                 * ★ 等待有界：超时（引擎停机）⇒ 软复位 + 重开本趟，绝不无限空转 */
                int r = blt_idle_bounded(STW_RESTART);
                if (r == ST_WAIT_MORE) break;
                if (r == ST_WAIT_TIMEO) { blt_recover("restart", STW_RESTART); break; }
                clip_off_verified();           /* ★ 段 0 之前：写 0 + 回读确认（信息条绝不被裁） */
                hw_i = 0; hw_frame_pushed = 0;
                g_pass_armed = 0;
                g_decor_st = DEC_REPAINT; g_decor_i = 0;
                g_st = ST_DECOR;
                break; }

            case ST_DECOR: {
                uint32_t room = 0u;
                int      rr   = blt_room_bounded(&room);
                /* 一趟起点的一次性动作：拍快照 → 查 clean/选目标/下清屏命令（决定要不要重铺） */
                if (!g_pass_armed) {
                    if (snap_need) { scene_snap(g_n); snap_need = 0; }
                    sweep_snap();                        /* 扫掠条位置也按趟冻结（规划/绘制必须同值） */
                    /* 本趟内容段要不要按局部窗口裁剪：整趟一个决定 ⇒ 'x' 的 A/B 在趟边界生效 */
                    g_clip_pass = (g_scene == SC_CLIP && g_scis_on && g_feat_clip) ? 1 : 0;
                    g_pass_armed = 1;
                    g_repaint = hw_pass_arm(TOP_Y0, PLAY_H, (g_scene == SC_LAYER) ? 0 : 1);
                    g_bar_need = (g_osd_dirty || !g_bar_ok[(uint32_t)g_draw3]) ? 1 : 0;
                    g_bar_len  = slen(g_osd_line);
                    g_lbl_len  = slen(OSD_LABEL);
                    if (g_bar_len > OSD_LEFT_CH) g_bar_len = OSD_LEFT_CH;
                }
                if (rr == ST_WAIT_MORE) break;             /* 余量不够：下一圈再来 */
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room", STW_ROOM); break; }
                if (decor_step(&room)) {
                    if (g_cmd_t0 == 0u) g_cmd_t0 = tick32();
                    g_st = ST_FENCE;
                }
                break; }

            case ST_FENCE: {
                /* ★ 围栏：段 0（scissor 关着画的那一段）全部画完之后才允许动 CLIP 状态 */
                int r = blt_idle_bounded(STW_FENCE);
                if (r == ST_WAIT_MORE) break;
                if (r == ST_WAIT_TIMEO) { blt_recover("fence", STW_FENCE); break; }
                clip_off_verified();           /* 段 0 正好结束：再回读确认一次（信息条/HUD 安全） */
                g_st = ST_CONTENT;
                break; }

            case ST_CONTENT: {
                uint32_t room   = 0u;
                uint32_t budget = HW_PUSH_BUDGET;
                int      rr     = blt_room_bounded(&room);
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room(content)", STW_ROOM); break; }
                while (room > 0u && budget > 0u && hw_i < content_total()) {
                    iclip_t w; int need;
                    if (content_plan(hw_i, &w, &need)) {   /* 与裁剪窗口不相交 ⇒ 整条省掉 */
                        hw_i++;
                        continue;
                    }
                    if (need) {                            /* 窗口是**局部**坐标 ⇒ 常常要换 */
                        g_clip_want    = w;
                        g_clip_want_on = g_clip_pass;
                        g_st = ST_CLIP;
                        break;
                    }
                    content_emit(hw_i);
                    hw_i++; room--; budget--;
                }
                if (g_st == ST_CLIP) break;                /* 先去把窗口写进寄存器 */
                if (hw_i >= content_total()) { hw_frame_pushed = 1; g_st = ST_WAIT; }
                else if (rr == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
                break; }

            case ST_CLIP: {
                /* ★ 改 CLIP_* 前必须确认引擎**彻底空闲**（寄存器在命令起始锁存，见文件头 (a)）。
                 * 一次围栏换一条命令的局部窗口；窗口没变的连续命令（整幅落在窗口里的精灵都是
                 * [0,SZ)x[0,SZ)）不会走到这里 ⇒ 场景 3 的额外代价只有"窗口变化"那几次。
                 * ★ 这个等待正是上板"场景 3 卡死、之后切不回去"的那一点：现在有界 + 能恢复。 */
                int r = blt_idle_bounded(STW_CLIP);
                if (r == ST_WAIT_MORE) break;
                if (r == ST_WAIT_TIMEO) { blt_recover("clip fence", STW_CLIP); break; }
                if (g_clip_want_on) clip_arm(&g_clip_want);
                else                clip_off();
                g_st = ST_CONTENT;
                break; }

            default: /* ST_WAIT：等本趟内容画完 */
                if (hw_frame_pushed) {
                    int r = blt_idle_bounded(STW_CONTENT);
                    if (r == ST_WAIT_TIMEO) { blt_recover("content wait", STW_CONTENT); break; }
                    if (r != ST_WAIT_IDLE) break;
                    hw_done = 1;
                    /* ★ 1Hz 成本行（与 FinalDemo 同口径同格式）：本趟起点 → 引擎空闲的墙钟拍数 */
                    if (g_cmd_t0 != 0u) {
                        uint32_t now = tick32();
                        if ((uint32_t)(now - g_cost_t0) >= (uint32_t)BSP_CLINT_HZ) {
                            uint32_t dt = (uint32_t)(now - g_cmd_t0);
                            g_cost_t0 = now;
                            bsp_printf("EV cmd path done: n=%d cycles=%d cyc/sprite=%d\r\n",
                                       g_n, (int)dt, (g_n > 0) ? ((int)dt / g_n) : 0);
                        }
                        g_cmd_t0 = 0;
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
                break;
            }
        }
    }
    return 0;
}
