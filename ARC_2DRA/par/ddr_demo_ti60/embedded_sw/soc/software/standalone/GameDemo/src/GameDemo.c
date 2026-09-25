/* =============================================================================
 * GameDemo.c — 高负载互动游戏 Demo（赛题二 · 高阶挑战 3）
 * -----------------------------------------------------------------------------
 * 一句话：**在 RISC-V 上跑一个真·可玩的纵版弹幕游戏，画面里成百上千个活动
 *         Sprite 全部由 FPGA 2D 加速引擎搬运 + Alpha 混合 + Color Keying，
 *         操作全部来自 PC 键盘（经串口下发），板载按键一个都不用**。
 *
 * ============================== 0. 与赛题的对应关系 ==============================
 *   「高阶挑战 3：在 RISC-V 上运行一个具有极高同屏元素数量的游戏 Demo（如
 *     《吸血鬼幸存者》简化版或弹幕射击），在开启硬件加速（Alpha 混合 + Color
 *     Keying）的情况下，挑战保持 60 FPS 稳定运行时的同屏活动元素数量极限。」
 *
 *   → 本 Demo 就是「东方 Project 风」的纵版弹幕：
 *       · 同屏元素 = 敌弹 + 自机弹 + 敌机 + 自机 + 爆点火花 + 星空（全部走引擎）；
 *       · Alpha 混合 = 辉光弹的**加算混合**（ATTR_PORT blend=ADD）+ 每精灵 alpha；
 *       · Color Keying = 图集用 **0x0000（纯黑）** 作键色（`OP=KEY`，w7=0）；
 *       · 60 FPS 极限 = 串口键 `g` 自动爬坡，逐秒抬 N 直到帧率跌破 58，
 *         把「极限 N」直接打到串口 + 屏幕上（可复现，不用人工试）。
 *
 * ============================== 1. 输入：PC 键盘 → 串口（**不用板卡按键**） ==============
 *   板载 4 个用户按键**一个都不用**。所有操作都从 USB-UART（115200 8N1）来：
 *
 *   ① 按键状态包（连续量：移动 / 开火 / 慢速 / 炸弹 / 暂停）
 *        PC → 板：  '@' + 两个十六进制数字 + '\n'      例如 "@05\n"
 *        位图（bit0..bit7）：
 *          0 上 (W / ↑)     1 下 (S / ↓)     2 左 (A / ←)     3 右 (D / →)
 *          4 开火 (J / 空格)  5 慢速 (K / Shift)  6 炸弹 (L / X)  7 暂停 (P / 回车)
 *        · 上位机在**任意键状态变化时立刻发**，另外每 100ms 补发一次心跳；
 *        · 固件有 **500ms 看门狗**：超时没收到包 ⇒ 全部按键视为松开
 *          （浏览器标签被切走 / 拔线都不会让自机一直往一个方向飞）；
 *        · 4 字节/包，30Hz 也才 120 B/s，对 115200 的串口是噪声级开销；
 *        · 炸弹/暂停按**上升沿**处理（按住不会连发）。
 *
 *   ② 单字符命令（按下即生效，**不需要回车**）
 *        1 / 2 / 3 / 4      预设负载档（N = 256 / 640 / 1280 / 2400）
 *        n 或 +             N += 64（超上限回绕到下限）
 *        -                  N -= 64（低于下限回绕到上限）
 *        =N\n               精确设置 N（十进制行命令，钳到 [64, 2400]）
 *        c                  渲染路径 = 纯 CPU（对照，帧率会当场崩下来）
 *        h                  渲染路径 = 硬件加速（默认）
 *        g                  自动爬坡开关（找 60FPS 下的极限 N）
 *        b                  星空背景开关
 *        p                  暂停 / 继续（与按键 bit7 等价）
 *        r                  重开一局
 *        d                  打一行诊断（引擎寄存器现场）
 *        ?                  帮助
 *
 *   ③ 固件 → PC 的回报
 *        · 上电横幅 + 命令回显 `EV ...`（与 FinalDemo/AdDemo 同一套风格）；
 *        · `ST ...` 状态行 **4Hz**（fps / 同屏数 / 分数 / 关卡 / 生命 / 路径）；
 *        · 自动爬坡找到极限时打 `LIMIT ...`（一行，含当时的同屏数与帧率）。
 *      ★ BSP 的 print.h 是 mini 版，**只认 %c %s %d %X %x**；
 *        %u / 宽度数字 / %% 会让它错位消耗 va_arg，后面的 %s 当整数解引用 → 挂死。
 *
 * ============================== 2. 渲染架构（为什么能顶住几千个精灵） ==============
 *   · **帧缓冲 960x540 RGB565，三缓冲 FLIP**：一趟画完只写一个寄存器换显示基址，
 *     不做整屏 COPY。板级实测整帧 COPY ≈1.89M 拍 ≈19ms > 16.7ms 场周期，
 *     会把上限钉死在 ~53fps；FLIP 把这段全省下来给内容。
 *   · **并发清屏引擎**：下一块缓冲的背景由硬件在后台铺，不进关键路径；
 *     目标 = 正在显示 / 正在画的缓冲时硬件直接拒写（互斥是硬件保证）。
 *   · **逐条下发（不走显示列表）**：v3.2 的属性字只有「每条命令配一个」这一种
 *     配对方式，16B 的显示列表描述符**没有属性槽位** ⇒ 要每精灵不同 alpha/混合
 *     就只能逐条下发。同时 v2.14~v2.15 的板级记录里，ALPHA/KEY 场景的列表取指
 *     被 DDR 争用饿过看门狗（stall_seen=1），所以本 Demo 明确只用逐条路径。
 *   · **每条命令恰好一个属性字**：全部收敛到唯一出口 `blt_emit()`；
 *     位流不支持属性侧口时一条都不写（`g_attr_on=0`），绝不会错位。
 *   · **口径诚实**：`HW=` 是硬件路径实测帧率，`SW=` 是纯 CPU 渲染实测帧率，
 *     两个数**都留在屏幕上**，按 `c`/`h` 来回切就能做实时对比。
 *
 * ============================== 3. 图集与「黑=透明」这个统一约定 ====================
 *   所有精灵都是**程序化生成**的 RGB565（没有外部素材），透明处一律写 **0x0000**。
 *   于是两条路径用**同一张图集**，不需要按位流能力准备两套素材：
 *     · 有属性侧口（v3.2 位流）：辉光弹走 `OP=ALPHA + attr(blend=ADD, fmt=565)`
 *       ⇒ 数学是 out = min(255, ⌊fg·A/255⌋ + bg)：黑像素加 0 = 背景不变（天然透明），
 *       彩色像素把光**加上去** ⇒ 真辉光；`global_alpha(A)` 就是辉光强度
 *       （爆点火花靠它随寿命衰减）。
 *     · 没有属性侧口（旧位流）：辉光弹走 `OP=KEY + w7=0x0000`
 *       ⇒ 黑像素被硬件比较器整像素丢弃 ⇒ 硬边精灵，**观感降级但画面完全正确**。
 *   ★ 所以「位流有没有 v3.2 属性侧口」只影响好不好看，**不影响能不能跑**。
 *     探测方式与 AdDemo 一致：CLIP_x / LUT_x 两组新寄存器写回读
 *     （ATTR_PORT 只写不可读，没法直接探）。
 *   ★ 加算混合是**可交换**的 ⇒ 辉光弹之间没有 z 序问题，画的先后不影响结果。
 *
 * ============================== 4. 必须守住的硬约束（改本文件前先读） ==============
 *   ① **32bit 访存必须 4 字节对齐**：CPU 直写像素一律用 16bit 存储（地址恒偶对齐），
 *      批量铺底 cpu_fill32 内部对奇数 x 用 16bit 收头/收尾。曾经因为奇数 x 做
 *      32bit 存储触发未对齐异常 ⇒ 整机静默停死（屏幕定格 + 串口无声）。
 *   ② **FIFO 满时写 0x08 会把 CPU 挂在 AXI-Lite 上**：每条命令下发前必须先看余量
 *      （`blt_push_room()`，软上限 200 条 / 深度 256 条）。
 *   ③ **CPU 写完 DDR、引擎紧接着要读** ⇒ `cache_evict()`（向 FLUSH_SCRATCH 写 8KB，
 *      本质是 store 有序屏障）。**不要**用 data_cache_invalidate_all() 代替 flush。
 *   ④ **绝不往可能正在上屏的缓冲里画**：只写 FB_SEL 请求，等 FB_STAT 确认；
 *      确认前不动下一块缓冲。有界超时（100ms）后重发请求，不退化成撕裂。
 *   ⑤ **所有「等引擎」都必须有界且可恢复**：超时走 blt_recover()（软复位 + 重开本趟），
 *      串口命令循环绝不被阻塞 —— 这是 AdDemo 用整颗 bitstream 换来的教训。
 *   ⑥ 信息条用 CPU 直接写 y<16 的信息条区（**渲染区之外**，清屏引擎与引擎命令
 *      都不会碰它）；中央字幕画在游戏区里，必须**等引擎空闲之后**再写，
 *      而且要**每帧重画**（清屏引擎会把上一帧的字幕擦掉）。
 * ============================================================================= */

#include <stdint.h>
#include "bsp.h"
#include "compatibility.h"

/* ============================== 地址与寄存器 ============================== */
#define FB_WIDTH      960
#define FB_HEIGHT     540
#define FB_STRIDE     (FB_WIDTH * 2)               /* 1920 B/行 */

/* ★ 三个**基址**允许被命令行覆盖（只有主机仿真会用到，见 tools/host_selfcheck_game/）：
 *   板级构建一个都不给 ⇒ 用的就是下面这三个默认值，与 FinalDemo/AdDemo 逐位一致。
 *   其余地址全部由它们派生，所以仿真只要搬这三个基址，DDR 内部的相对布局一位不变。 */
#ifndef DDR_BASE
#define DDR_BASE      0x00001000UL
#endif
#ifndef BLT_BASE
#define BLT_BASE      0xF8100000UL
#endif
#ifndef UART_TERM
#define UART_TERM     SYSTEM_UART_0_IO_CTRL
#endif

#define FB_BASE       (DDR_BASE + 0x00300000UL)    /* 显示缓冲（引擎/扫描输出） */
#define FB_BACK       (DDR_BASE + 0x00500000UL)    /* 后台缓冲 */
#define FB_BUF2       (DDR_BASE + 0x00700000UL)    /* 第三块缓冲 */
#define ATLAS_BASE    (DDR_BASE + 0x00200000UL)    /* 精灵图集（开机由 CPU 生成） */
#define FLUSH_SCRATCH (DDR_BASE + 0x00600000UL)    /* 缓存写穿屏障用的 8KB 临时区 */
#define FLUSH_WORDS   (8UL * 1024UL / 4UL)

#define BLT_CTRL            0x00
#define   BLT_CTRL_GO       (1UL << 0)
#define   BLT_CTRL_SOFT_RST (1UL << 2)
#define BLT_STATUS          0x04
#define   BLT_STATUS_DONE       (1UL << 1)
#define   BLT_STATUS_ERR        (1UL << 2)
#define   BLT_STATUS_FIFO_EMPTY (1UL << 3)
#define BLT_CMD_FIFO_DATA   0x08
#define BLT_CMD_FIFO_COUNT  0x0C
#define BLT_IRQ_STATUS      0x10
#define BLT_IRQ_EN          0x14
#define   BLT_IRQ_FRAME     (1UL << 1)     /* 扫描输出帧边界中断（W1C / 使能） */
#define BLT_SCAN_DBG        0x20
#define BLT_FB_SEL          0x24
#define BLT_FB_STAT         0x28
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

/* ★ v3.2（S5）新增：属性侧口 / scissor / 扫描输出 LUT。
 *   属性字：[3:0] blend  [5:4] fmt  [13:6] global_alpha  [31:24] flags；
 *   ATTR_PORT **只写不可读** ⇒ 只能用同批出现的 CLIP_x / LUT_x 读回探测位流能力。 */
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
#define BLT_DL_VERSION      0x80

/* 引擎操作码（与 rtl/pixel_path.v、blt_engine_fsm.v 一致） */
#define BLT_OP_COPY   0UL
#define BLT_OP_FILL   1UL
#define BLT_OP_ALPHA  2UL
#define BLT_OP_KEY    3UL

/* CMD_FIFO_COUNT 的单位是**指令条数**（rtl/cmd_fifo.v: cmd_count = word_count/8），
 * FIFO 共 256 条。属性字进的是**另一条** FIFO，不占命令条数。 */
#define BLT_FIFO_DEPTH      256
#define HW_FIFO_MARGIN      56
#define BLT_PUSH_LIMIT      (BLT_FIFO_DEPTH - HW_FIFO_MARGIN)      /* 200 条 */

/* 主循环节流参数（单位是「圈」，不是毫秒）：
 *   BLT_WAIT_MASK  等引擎/等帧边界时每 4 圈才读一次状态字，其余圈纯 ALU 退避；
 *   BLT_WAIT_NOP   每次退避的空转量（≈150~190 周期 ≈1.5~1.9us @100MHz）；
 *   HW_PUSH_BUDGET 一圈最多推几条引擎指令（64 条 = 512 次 FIFO 写 ≈2~3k 周期）
 *                  ⇒ 慢时间片（串口轮询）的间隔仍有上界，N=2400 也不会把输入饿太久。 */
#define BLT_WAIT_MASK     3u
#define BLT_WAIT_NOP     48u
#define HW_PUSH_BUDGET   64u

/* ============================== 属性字编码（冻结接口 ①） ==============================
 * ==== ATTR_ENC_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 位域（与 rtl/blt_regs_axi_lite.v / pixel_path.v 逐位对应）：
 *   [3:0]   blend_mode   0=按算子默认 1=alpha 混合 2=加算(饱和) 3=乘法
 *   [5:4]   src_format   0=RGB565 1=ARGB1555 2=ARGB4444 3=保留
 *   [13:6]  global_alpha 255 = 不淡
 *   [15:14] / [23:16]    保留（必须 0）
 *   [31:24] flags        bit0=alpha 测试(置位生效) bit1=强制不透明
 * ★ 空 FIFO 的默认字 = 0x00003FC0 = attr_word(0, 0, 255, 0)（自检里断言这条等式）。
 * ★ 混合数学（rtl 侧原文）：A = ⌊sprite_alpha·global_alpha/255⌋；
 *     alpha 混合 out = (fg·A + bg·(255−A) + 127) >> 8
 *     加算     out = min(255, ⌊fg·A/255⌋ + bg)
 *     乘法     out = (fg·bg) >> 8
 *   本 Demo 的辉光弹 = blend=ADD + fmt=565 + sprite_alpha(w6)=255 ⇒ out = min(255, fg + bg)
 *   ⇒ **黑像素(0x0000)加 0**，天然透明；这就是「一张图集同时服务两条路径」的依据。 */
#define ATTR_BLEND_OP     0u
#define ATTR_BLEND_ALPHA  1u
#define ATTR_BLEND_ADD    2u
#define ATTR_BLEND_MUL    3u
#define ATTR_FMT_565      0u
#define ATTR_FMT_1555     1u
#define ATTR_FMT_4444     2u
#define ATTR_FLAG_ATEST   1u
#define ATTR_FLAG_OPAQUE  2u

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

/* ============================== 画面分区 ============================== */
#define OSD_H        16
#define PLAY_Y0      OSD_H                            /* 游戏区起点（信息条之下） */
#define PLAY_W       FB_WIDTH
#define PLAY_H       (FB_HEIGHT - PLAY_Y0)            /* 524 */
#define PLAY_Y1      (PLAY_Y0 + PLAY_H)               /* 540 */

#define OSD_GLYPH_W  8
#define OSD_GLYPH_H  8
#define OSD_TEXT_Y   4
#define OSD_TEXT_X0  8
/* 信息条宽度上界（**静态可证**，开机用真实 fmt_stat 再证一遍）：
 *   左串最长 = "HW=999 SW=999 N=2400 ON=9999 SC=999999 LV=99 HP=9 A S G" = 55 字符 = 440px
 *   黑底按 OSD_LEFT_CH=64 字符铺 ⇒ x ∈ [8, 520)，文字末端最远 448 ⇒ 留 9 个字符位余量；
 *   右标签最长 "PURE CPU" = 8 字符 = 64px，右对齐 ⇒ x ∈ [896, 960)。
 *   ⇒ 最坏情况左文字末端 448 与右标签起点 896 之间仍空 448px，**不可能重叠**。 */
#define OSD_LEFT_CH  64
#define OSD_LEFT_PX  (OSD_GLYPH_W * OSD_LEFT_CH)
#define OSD_RIGHT_PX (OSD_GLYPH_W * 8)

/* ============================== 颜色 ============================== */
#define COL_BG        0x0008u                    /* 游戏区背景（近黑，清屏引擎用它） */
#define COL_OSD_BG    0x0000u
#define COL_WHITE     0xFFFFu
#define COL_CYAN      0x07FFu
#define COL_AMBER     0xFD20u
#define COL_RED       0xF800u
#define COL_GREEN     0x07E0u
#define COL_GRAY      0x8410u
#define COL_DIM       0x18E3u
#define TRANS_KEY     0x0000u                    /* ★ 全图集统一的「透明」= 纯黑 */

/* ============================== 位流能力探测结果（feat_probe() 填） ==============================
 * ★ 放在**精灵表之前**：渲染层的 `bulm_eff_name()` / `dl_bullet()` / `e_glow()`
 *   都要读 `g_glow`，而它们在文件里排在"引擎指令"一节之前。 */
static int g_glow      = 0;    /* 属性侧口可用 ⇒ 辉光走加算（ADD 档） */
static int g_feat_clip = 0;    /* CLIP_x 能写回读 ⇒ 位流带 v3.2 那一批寄存器 */
static int g_feat_lut  = 0;    /* LUT_x  能写回读 ⇒ 同上（两项都过才认为 ATTR 存在） */

/* ============================== 精灵表 ==============================
 * 全部程序化生成、RGB565、透明处 = TRANS_KEY(0x0000)。尺寸与偏移是**编译期常量**。 */
#define S_PR   0     /* 自机   32x32 */
#define S_EN   1     /* 敌机   32x32 */
#define S_SH   2     /* 自机弹 16x16 辉光（青）   */
#define S_B0   3     /* 敌弹0  16x16 辉光（品红） */
#define S_B1   4     /* 敌弹1  16x16 辉光（青）   */
#define S_B2   5     /* 敌弹2  16x16 辉光（琥珀） */
#define S_B3   6     /* 敌弹3  16x16 辉光（绿）   */
#define S_SP   7     /* 爆点   16x16 辉光（白）   */
#define S_N    8

#define SZ_PR  32
#define SZ_EN  32
#define SZ_B   16
#define SZ_SP  16

#define OFF_PR  0u
#define OFF_EN  (OFF_PR + (uint32_t)(SZ_PR * SZ_PR * 2))
#define OFF_SH  (OFF_EN + (uint32_t)(SZ_EN * SZ_EN * 2))
#define OFF_B0  (OFF_SH + (uint32_t)(SZ_B  * SZ_B  * 2))
#define OFF_B1  (OFF_B0 + (uint32_t)(SZ_B  * SZ_B  * 2))
#define OFF_B2  (OFF_B1 + (uint32_t)(SZ_B  * SZ_B  * 2))
#define OFF_B3  (OFF_B2 + (uint32_t)(SZ_B  * SZ_B  * 2))
#define OFF_SP  (OFF_B3 + (uint32_t)(SZ_B  * SZ_B  * 2))
#define ATLAS_BYTES (OFF_SP + (uint32_t)(SZ_SP * SZ_SP * 2))

static const uint32_t g_spr_off[S_N] = { OFF_PR, OFF_EN, OFF_SH, OFF_B0, OFF_B1, OFF_B2, OFF_B3, OFF_SP };
static const uint8_t  g_spr_sz[S_N]  = { SZ_PR, SZ_EN, SZ_B,  SZ_B,  SZ_B,  SZ_B,  SZ_B,  SZ_SP };

/* ============================== ★ 敌弹显示模式（FILL / ALPHA / ADD / KEY） ==============================
 * 串口 `f` 循环、`5/6/7/8` 直选。**只作用于敌机放出的那些弹**（同屏元素的主体），
 * 自机弹与火花保持原来的加算辉光 —— 这样切模式时只有"弹幕"这一种元素的画法在变，
 * 一眼就能看出三种算子在**同一场景**下的观感与代价差别。
 *
 *   FILL   引擎算子 1：纯色方块。**没有源、没有键色、没有 alpha** —— 最省（A=252/B=1.025），
 *          但就是一块实心方块，会盖住底下的东西。用来量"同屏元素数量的理论上限"。
 *   ALPHA  引擎算子 2 + 命令字 alpha（`blend=0` 的老路径，任何位流都逐位正确）：
 *          经典半透明 `out = (fg·α + bg·(255−α) + 127)>>8`。
 *          ★ 图集是**矩形**的，圆盘四角是纯黑 ⇒ 半透明会把背景在方框范围内压暗，
 *            看起来每颗弹外面套一个暗方块。**这不是 bug，正是 Color Key 存在的理由**，
 *            切到 KEY 就能立刻看出差别。
 *   ADD    引擎算子 2 + 属性字 `blend=ADD`：`out = min(255, ⌊fg·A/255⌋ + bg)`。
 *         黑像素加 0 = 背景不变（天然透明）⇒ 真辉光；也是本 Demo 的默认档。
 *         位流没有属性侧口时**自动降级成 KEY**（HUD 的 OP= 会显示实际生效的那一档）。
 *   KEY    引擎算子 3：色键 0x0000 整像素丢弃 ⇒ 硬边抠图，块与块之间没有 z 序问题。
 *
 * 四个档的作用不止观感：`d` 诊断行会把三档的**理论容量**一起打出来
 * （同样 70% 帧预算下能塞多少颗 16x16），切模式 + 按 `g` 就能把"观感 vs 极限数量"对上号。 */
#define BULM_FILL   0
#define BULM_ALPHA  1
#define BULM_ADD    2
#define BULM_KEY    3
#define BULM_N      4
#define BUL_ALPHA_V 160u          /* ALPHA 档的不透明度（0..255）。取 160 ≈ 63%：
                                   * 半透明肉眼可辨，又不至于把弹幕糊成一片看不清弹道。 */
static const char *g_bulm_name[BULM_N] = { "FILL", "ALPHA", "ADD", "KEY" };
static int g_bulm = BULM_ADD;              /* 开机由 main 按位流能力定档（无 attr ⇒ KEY） */
/* 精灵号 → FILL 模式下用的纯色（只有敌弹会用到，其余是兜底） */
static const uint16_t g_spr_fill[S_N] = {
    COL_WHITE,          /* S_PR 自机 */
    0x7800u,            /* S_EN 敌机（深红外壳色） */
    COL_CYAN,           /* S_SH 自机弹 */
    0xF81Fu,            /* S_B0 敌弹·品红 */
    COL_CYAN,           /* S_B1 敌弹·青 */
    COL_AMBER,          /* S_B2 敌弹·琥珀 */
    COL_GREEN,          /* S_B3 敌弹·绿 */
    COL_WHITE           /* S_SP 火花 */
};
/* 实际生效的档名：ADD 在没有属性侧口时会降级成 KEY，HUD 必须报**真的**那一档 */
static const char *bulm_eff_name(void)
{
    if (g_bulm == BULM_ADD && !g_glow) return g_bulm_name[BULM_KEY];
    return g_bulm_name[g_bulm];
}

/* ============================== 图集生成（纯函数） ==============================
 * ==== ATLAS_GEN_BEGIN ====（主机自检原样取本段源码；只需要 <stdint.h>）
 * 需要外部先声明：S_* / SZ_* 宏、COL_* 宏、TRANS_KEY。
 * 约定：**透明 = 0x0000**（见文件头 §3）。所有函数返回 RGB565。 */
static int iabs(int v) { return (v < 0) ? -v : v; }

/* 自机：尖头朝上的三角机体（黑底 = 透明） */
static uint16_t spr_player(int i, int j)
{
    int cx = SZ_PR / 2;
    int ax = i - cx;
    int halfw;
    if (j < 2 || j > 29) return TRANS_KEY;
    halfw = 1 + (j * 12) / 29;                 /* j=2 → 1 ; j=29 → 13 */
    if (iabs(ax) > halfw) return TRANS_KEY;
    if (j >= 20 && iabs(ax) > halfw - 3) return COL_DIM;      /* 机翼 */
    if (iabs(ax) <= 3 && j < 22)         return COL_CYAN;     /* 座舱 */
    if (j > 26)                          return COL_AMBER;    /* 尾焰口 */
    return COL_WHITE;
}
/* 敌机：菱形核心（黑底 = 透明） */
static uint16_t spr_enemy(int i, int j)
{
    int cx = SZ_EN / 2;
    int m  = iabs(i - cx) + iabs(j - cx);
    if (m > 14) return TRANS_KEY;
    if (m > 11) return 0x7800u;                               /* 深红外壳 */
    if (m > 6)  return COL_RED;
    if (m > 2)  return COL_AMBER;
    return COL_WHITE;
}
/* 辉光弹 / 爆点：径向平方衰减，黑底。`base` 是该档的满强度色。
 * ★ 衰减到 1/8 以下直接返回 0 ⇒ 加算路径上等于「不发光」，
 *   KEY 路径上等于「被键色丢掉」，两条路径的边缘都干净。 */
static uint16_t spr_glow(int i, int j, uint16_t base)
{
    int n  = SZ_B;
    int dx = i * 2 - n + 1;
    int dy = j * 2 - n + 1;
    int d2 = dx * dx + dy * dy;
    int r2 = n * n;
    unsigned t, i8, r, g, b;
    if (d2 >= r2) return TRANS_KEY;
    t  = (unsigned)((d2 * 255) / r2);          /* 0 圆心 .. 255 边缘 */
    i8 = 255u - t;
    i8 = (i8 * i8) / 255u;                     /* 平方衰减：中心亮、边缘柔 */
    if (i8 < 32u) return TRANS_KEY;
    r = (unsigned)(((base >> 11) & 0x1Fu) * i8 / 255u);
    g = (unsigned)(((base >>  5) & 0x3Fu) * i8 / 255u);
    b = (unsigned)(( base        & 0x1Fu) * i8 / 255u);
    return (uint16_t)((r << 11) | (g << 5) | b);
}
/* 精灵号 → 像素（唯一入口；图上与自检的真值都从这里取） */
static uint16_t spr_pixel(int id, int i, int j)
{
    switch (id) {
    case S_PR: return spr_player(i, j);
    case S_EN: return spr_enemy(i, j);
    case S_SH: return spr_glow(i, j, COL_CYAN);
    case S_B0: return spr_glow(i, j, 0xF81Fu);
    case S_B1: return spr_glow(i, j, 0x07FFu);
    case S_B2: return spr_glow(i, j, COL_AMBER);
    case S_B3: return spr_glow(i, j, COL_GREEN);
    default:   return spr_glow(i, j, COL_WHITE);
    }
}
/* ==== ATLAS_GEN_END ==== */

/* ============================== 8x8 字体（信息条用） ==============================
 * ★ 字符集必须覆盖 fmt_stat / 路径标签用到的每一个字符；缺字退回空格（屏上只是少笔画）。 */
/* ==== FONT_TABLE_BEGIN ====（主机自检原样取本段源码） */
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
#define FONT_N ((int)(sizeof(g_font) / sizeof(g_font[0])))
static int glyph_found(char c)
{
    int i;
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return 1;
    return 0;
}
static const uint8_t *glyph_of(char c)
{
    int i;
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    return g_font[0].r;
}
/* ==== FONT_TABLE_END ==== */

/* ============================== 基础原语 ============================== */
/* 时间基：CLINT mtime **低 32 位**（1 次总线读；本程序所有时间量都是 ≤1s 的差值，回绕安全） */
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }

/* 有界退避：**纯寄存器空转**，不读外设、不碰内存 ⇒ 不产生一次总线事务 */
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

/* 缓冲号 → 字节基址（与 RTL 的 FB_BASE/FB_BASE1/FB_BASE2 逐位一致） */
static uint32_t fb_of_sel(uint32_t s)
{
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
}
static uint32_t fb_stat_sel(void) { return blt_rd(BLT_FB_STAT) & 3UL; }

/* CPU 写完 DDR 后、引擎紧接着要读的场合调用（D$ 写穿，本质是 store 有序屏障） */
static void cache_evict(void)
{
    volatile uint32_t *s = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
}

/* ★ 对齐安全铺底：32bit 存储要求列号 x 为偶数，奇数 x 用 16bit 收头/收尾。
 *   曾经的「整机静默停死」就是这里少了这两行（未对齐异常 → trap 死循环）。 */
static void cpu_fill32(uint32_t base, int x, int y, int w, int h, uint16_t color)
{
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    int odd = (x & 1);
    int j, i;
    if (w <= 0 || h <= 0) return;
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

/* ============================== 引擎指令（**唯一出口**） ==============================
 * ★★ 属性配对纪律：ATTR_PORT 是一条 FIFO，引擎「每条命令弹一个」，它不知道你写了几个。
 *    所以属性**只能**在这里写，且「每条命令恰好一个」：开属性时连想要默认行为的那条
 *    也要写 ATTR_DEFAULT，关属性时一条都不写。混着写 = 后续属性整体错位（静默错模式）。 */
static int g_attr_on = 0;                    /* feat_probe() 之后才可能为 1 */

static void blt_emit(uint32_t attr, uint32_t op, uint32_t src, uint32_t dst, uint32_t ss,
                     uint32_t ds, uint32_t w, uint32_t h, uint32_t alpha, uint32_t color)
{
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);       /* ★ 必须在 8 个命令字之前 */
    blt_wr(BLT_CMD_FIFO_DATA, op);
    blt_wr(BLT_CMD_FIFO_DATA, src);
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    blt_wr(BLT_CMD_FIFO_DATA, color);
}
/* 三个语义化封装 —— 所有绘制都从这里走 */
static void e_fill(uint32_t dst, uint32_t ds, uint32_t w, uint32_t h, uint32_t color)
{ blt_emit(ATTR_DEFAULT, BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color); }
static void e_key(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                  uint32_t w, uint32_t h, uint32_t key)
{ blt_emit(ATTR_DEFAULT, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key); }
/* 加算辉光：blend=ADD 的数学是 out = min(255, ⌊fg·A/255⌋ + bg) ⇒ A(ga) 就是发光强度 */
static void e_glow(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                   uint32_t w, uint32_t h, uint32_t ga)
{
    if (g_attr_on)
        blt_emit(attr_word(ATTR_BLEND_ADD, ATTR_FMT_565, ga, 0u),
                 BLT_OP_ALPHA, src, dst, ss, ds, w, h, 0xFFu, 0u);
    else
        blt_emit(ATTR_DEFAULT, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, TRANS_KEY);
}
/* ★ 经典半透明：**故意走 `blend=0` + 命令字 alpha 的老路径**（w6 = alpha）。
 *   理由：这条路径在 v2.x 就上过板、逐位可复现，任何位流都正确；
 *   而 v3.2 的 attr `blend=ALPHA` 走的是 `A = ⌊w6·ga/255⌋`，取 w6=255 时 A == ga，
 *   数学完全等价 ⇒ 没必要为了"用上新寄存器"去多担一份未上板的风险。
 *   （想验证 attr 路径的话，切到 ADD 档就是在用它。） */
static void e_alpha(uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                    uint32_t w, uint32_t h, uint32_t alpha)
{
    blt_emit(ATTR_DEFAULT, BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha & 0xFFu, 0u);
}

static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
static int blt_idle_st(uint32_t st)
{
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
}
/* 写 FIFO 前先确认有空间：FIFO 满时写 DATA 会把 CPU 挂在 AXI-Lite 上 */
static uint32_t blt_push_room(void)
{
    uint32_t cnt = blt_cnt();
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
}
static void blt_init(void)
{
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    blt_wr(BLT_IRQ_STATUS, 7u);                        /* W1C 三位全清 */
    blt_wr(BLT_IRQ_EN, 0u);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
}

/* ============================== FLIP 三缓冲 + 并发清屏引擎 ==============================
 * 显示 A / 画 B / 预清 C 三块轮转：
 *   · 硬件「并发清屏引擎」在后台把 C 的**游戏区**铺成背景色 ⇒ 整片重铺不进关键路径；
 *   · 每趟开画前查目标缓冲的 clean 位：不干净就退回命令式整片 FILL（有界、绝不无限等）；
 *   · 写 DRAW_SEL = 本趟要画的那块 ⇒ 硬件互斥的另一半生效（清屏目标 == 正在画的
 *     缓冲时硬件一个像素都不写并置 ERR）。 */
#define FLIP_TIMEOUT_TICKS  (BSP_CLINT_HZ / 10u)   /* 有界等待：100ms ≈ 6 场 @60Hz */
#define CLR_WAIT_TICKS      (BSP_CLINT_HZ / 100u)  /* 清屏引擎有界等待：10ms（实测整片 ≈2.1ms） */

static uint32_t g_fb_back  = FB_BACK;   /* 本趟绘制目标 */
static uint32_t g_disp_sel = 0;         /* 已确认在屏的缓冲（0/1/2） */
static uint32_t g_flip_req = 0;         /* 已写下、还没确认的请求 */
static uint32_t g_flip_to  = 0;         /* 翻转有界等待超时次数（正常恒 0） */
static int      g_draw3    = -1;
static int      g_clr3     = -1;
static int      g_clr_need = 0;
static uint8_t  g_bar_ok[3] = {0, 0, 0 };/* 信息条是否已经画进 buf[0]/[1]/[2] */
static uint32_t g_clr_fb = 0, g_clr_to = 0, g_clr_err = 0;
static uint32_t g_stto   = 0;           /* 等引擎超时（blt_recover）累计，正常 0 */

static uint32_t clr_stat(void) { return blt_rd(BLT_CLR_STAT); }
static int      clr_busy(void) { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }

static int clr_wait_idle(void)
{
    uint32_t t0 = tick32();
    int guard = 0;
    while (clr_busy()) {
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
        if (++guard > 64) { guard = 0; cpu_backoff(48u); }
    }
    return 1;
}
/* 给清屏引擎下一条「把 k 的游戏区清成背景色」的命令 */
static void clr_start(uint32_t k)
{
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)PLAY_Y0 * FB_STRIDE);
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    blt_wr(BLT_CLR_WH,     ((uint32_t)PLAY_H << 16) | (uint32_t)PLAY_W);
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
}
/* 本趟开画前的**一次性动作**（顺序不能改）：
 *   ① 有界等清屏空闲 ② 读 clean 位 ③ 写 DRAW_SEL（它会清该缓冲的 clean 位）
 *   ④ 不干净 ⇒ 返回 1（调用方补一条命令式整片 FILL）⑤ 给第三块下清屏命令
 * 返回 1 = 本趟需要命令式重铺。 */
static int hw_pass_arm(void)
{
    int clean_k;
    (void)clr_wait_idle();                                     /* ① 超时交给硬件互斥兜底 */
    clean_k = clr_is_clean((uint32_t)g_draw3);                 /* ② */
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);                   /* ③ */
    if (clr_stat() & BLT_CLR_STAT_ERR) {                       /*    清掉互斥留下的 sticky 错误 */
        g_clr_err++;
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    }
    if (!clean_k) g_clr_fb++;                                  /* ④ */
    if (g_clr_need) { clr_start((uint32_t)g_clr3); g_clr_need = 0; }   /* ⑤ */
    return clean_k ? 0 : 1;
}

/* ============================== 串口（非阻塞轮询） ==============================
 * 状态寄存器两个字段必须分清（driver/uart.h）：
 *   uart_writeAvailability = (status >> 16) & 0xFF  → TX 剩余空间
 *   uart_readOccupancy     = (status >> 24)         → RX 已收字节数
 * ★ 早期误用 >>16 ⇒ TX 一忙就当成「有数据」、跑去读空 RX，串口指令完全无效。
 * ★ 本 Demo 把轮询放到**每 4 圈**（不是 FinalDemo 的每 32 圈慢时间片）：
 *   游戏要的是输入延迟；主循环一圈 ≈ 一两百拍 ⇒ 轮询间隔 ≈几十 µs。 */
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

/* ============================== 按键状态包 '@HH'（游戏输入） ==============================
 * ==== KEYPACK_BEGIN ====（主机自检原样取本段源码）
 * 语法：'@' + 两个十六进制数字 + '\n'（'\r' 也当行结束）。
 * ★ 与 FinalDemo 的 '=' 行缓冲同一条设计原则：
 *   - 没看到 '@' 时返回 KP_NONE，字符**原样交回**单字符命令分支；
 *   - 一旦开始收，后续字符由本函数消费，直到结算或作废；
 *   - 任何非法字符立刻作废并复位 ⇒ 一个坏包最多影响它自己。 */
#define KP_NONE   0
#define KP_MORE   1
#define KP_OK     2
#define KP_ERR  (-1)

#define KEY_UP     0x01u
#define KEY_DOWN   0x02u
#define KEY_LEFT   0x04u
#define KEY_RIGHT  0x08u
#define KEY_FIRE   0x10u
#define KEY_FOCUS  0x20u
#define KEY_BOMB   0x40u
#define KEY_PAUSE  0x80u

static int kp_hexval(int c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}
static int      g_kp_on = 0;
static int      g_kp_n  = 0;
static unsigned g_kp_v  = 0;
static int kp_feed(int c, unsigned *mask)
{
    int h;
    if (!g_kp_on) {
        if (c != '@') return KP_NONE;        /* 与本包无关：原样交回命令分支 */
        g_kp_on = 1; g_kp_n = 0; g_kp_v = 0u;
        return KP_MORE;
    }
    if (c == '\n' || c == '\r') {            /* 行结束：结算，必须恰好两位 */
        g_kp_on = 0;
        if (g_kp_n != 2) return KP_ERR;
        *mask = g_kp_v & 0xFFu;
        return KP_OK;
    }
    h = kp_hexval(c);
    if (h < 0 || g_kp_n >= 2) { g_kp_on = 0; return KP_ERR; }   /* 非十六进制 / 太长：作废 */
    g_kp_v = (g_kp_v << 4) | (unsigned)h;
    g_kp_n++;
    return KP_MORE;
}
/* ==== KEYPACK_END ==== */

/* ============================== '=N' 精确设置（行缓冲） ==============================
 * ==== NLINE_BEGIN ====（主机自检原样取本段源码）
 * 语义与 FinalDemo/AdDemo 完全一致：只钳不拒，回显**实际生效**的值。 */
#define NLINE_MAX 12
#define NL_NONE    0
#define NL_MORE    1
#define NL_OK      2
#define NL_ERR   (-1)

static char     g_nl[NLINE_MAX];
static unsigned g_nl_n  = 0;
static int      g_nl_on = 0;
static int nline_feed(int c, int *out, int nmin, int nmax)
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
            if (v > (unsigned)nmax) v = (unsigned)nmax;
        }
        if (v < (unsigned)nmin) v = (unsigned)nmin;
        *out = (int)v;
        return NL_OK;
    }
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) { g_nl_on = 0; return NL_ERR; }
    g_nl[g_nl_n++] = (char)c;
    return NL_MORE;
}
/* ==== NLINE_END ==== */

/* ============================== 游戏配置（纯常量） ==============================
 * ==== GAME_CFG_BEGIN ====（主机自检原样取本段源码） */
#define N_MIN       64
#define N_MAX       2400        /* 敌弹同屏上限（= 弹池容量；`N=` 显示的就是它） */
#define N_STEP      64
#define PLR_SLOTS   32          /* 自机弹专用槽位：**永远不被敌弹挤掉** */
#define BUL_TOTAL   (N_MAX + PLR_SLOTS)
#define DRAW_MAX    (BUL_TOTAL + 64 + 64 + 32)   /* 弹 + 火花 + 星空 + 敌机/自机/余量 */
/* 敌机上限定成 24 而不是"够用就行"：**它是「同屏弹幕能不能被喂到 N」的天花板**。
 * 每架敌机每 ENEMY_FIRE_T 帧放一圈 k 发 ⇒ 稳态弹数 ≈ 敌机数 × k × 弹寿命 / ENEMY_FIRE_T。
 * 24 × 22 × 240 / 46 ≈ 2750 ⇒ N_MAX=2400 这一档才真的能被填满（否则 N 设了也到不了，
 * 用户会以为"加速器顶不住"，其实是被生成器卡住了）。 */
#define ENEMY_MAX   24
#define SPARK_MAX   96
#define STAR_MAX    64

#define Q3          3                       /* 位置/速度用 1/8 像素定点 */
/* ★ 用乘法而不是左移：FP(-50) 这种「负常量的左移」在 C 里是 UB（-Wshift-negative-value），
 *   三者等价而乘法没有这个坑（编译器照样会把它优化成移位）。 */
#define FP(v)       ((int)(v) * (1 << Q3))
#define PX(v)       ((v) >> Q3)

#define PLR_SPD     40                      /* Q3/帧 = 5.0 px/帧 */
#define PLR_SPD_F   20                      /* Q3/帧 = 2.5 px/帧（慢速） */
#define PLR_HIT_R   4                       /* 自机判定半径（弹幕风：小判定） */
#define PLR_SHOT_T  7                       /* 每 7 帧一对自机弹 */
#define INVULN_T    100                     /* 中弹后无敌帧数 */

#define ENEMY_SPAWN_T   16                  /* 敌机生成节拍（帧）；每拍最多补 4 架 */
#define ENEMY_TOPUP     4                   /* 每拍最多补几架（N 一跳就快速跟上，不拖半分钟） */
#define ENEMY_FIRE_T    46                  /* 敌机开火间隔（帧） */
#define LEVEL_TICKS     1800                /* 30 秒一关（60fps） */

#define SCORE_PER_ENEMY 100
#define SCORE_PER_TICK  1
#define SCORE_TICK_DIV  10
#define SCORE_CAP       999999

#define BULLET_LIFE     240                 /* 敌弹寿命（帧），到期回收防泄漏 */
#define ENEMY_LIFE      600
/* ==== GAME_CFG_END ==== */

/* ============================== 随机数与三角函数表 ==============================
 * ==== RNG_BEGIN ====（主机自检原样取本段源码） */
static uint32_t g_seed = 0x1BADF00Du;
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
static uint32_t rnd(void) { return lcg(&g_seed); }
/* 64 点正弦表：sin(i·2π/64) 定标到 256（i=0..63；cos(i) = sin(i+16)） */
static const int16_t g_sin64[64] = {
       0,   25,   50,   74,   98,  121,  142,  162,  181,  198,  213,  226,  237,  245,  251,  255,
     256,  255,  251,  245,  237,  226,  213,  198,  181,  162,  142,  121,   98,   74,   50,   25,
       0,  -25,  -50,  -74,  -98, -121, -142, -162, -181, -198, -213, -226, -237, -245, -251, -255,
    -256, -255, -251, -245, -237, -226, -213, -198, -181, -162, -142, -121,  -98,  -74,  -50,  -25
};
static int isin(int a) { return (int)g_sin64[a & 63]; }
static int icos(int a) { return (int)g_sin64[(a + 16) & 63]; }
/* 整数平方根（只用于「瞄准自机」这一个方向的归一化；RISC-V 没有硬件除法器也够快） */
static int isqrt32(uint32_t v)
{
    uint32_t r = 0u, b = 1u << 30;
    while (b > v) b >>= 2;
    while (b) {
        if (v >= r + b) { v -= r + b; r = (r >> 1) + b; } else { r >>= 1; }
        b >>= 2;
    }
    return (int)r;
}
/* ==== RNG_END ==== */

/* ============================== 实体 ============================== */
typedef struct {
    int16_t x, y;      /* Q3 位置（屏幕像素 << 3） */
    int16_t vx, vy;    /* Q3 速度 */
    uint8_t kind;      /* 精灵号 */
    uint8_t sz;        /* 边长（像素） */
    uint8_t r;         /* 碰撞半径（像素） */
    uint8_t life;      /* 剩余寿命（帧） */
} ent_t;

typedef struct {
    int16_t x, y;      /* Q3 */
    int16_t vx, vy;
    int16_t hp;
    uint8_t kind;
    uint8_t fire;
    uint8_t phase;
    uint8_t pad;
    int16_t t;         /* 剩余寿命（帧）；0 = 空闲槽 */
} enemy_t;

typedef struct {
    int16_t  x, y;     /* 目的左上角（**已裁剪**到游戏区，屏幕像素） */
    uint16_t arg;      /* 精灵号（KEY/ALPHA/GLOW）或 RGB565（FILL） */
    uint8_t  op;       /* DRAW_* */
    uint8_t  w, h;     /* **裁剪后**的宽高（像素）；DRAW_FILL_FULL 时 h=0 */
    uint8_t  ga;       /* 强度：DRAW_GLOW = 加算强度；DRAW_ALPHA = 不透明度 */
    uint8_t  sx, sy;   /* 源裁剪偏移（像素）—— 精灵有一部分在区外时从这里开始取数 */
    uint8_t  rsv;
} draw_t;

#define DRAW_FILL_FULL 0   /* 整片重铺游戏区 */
#define DRAW_FILL      1   /* 纯色方块 FILL（星空 / FILL 档敌弹） */
#define DRAW_KEY       2   /* Color Key 精灵（自机/敌机；KEY 档敌弹） */
#define DRAW_GLOW      3   /* 加算辉光精灵（ADD 档敌弹 / 火花） */
#define DRAW_ALPHA     4   /* ★ 经典半透明精灵（ALPHA 档敌弹） */

static ent_t    g_bul[BUL_TOTAL];    /* 弹池：前 PLR_SLOTS 个是自机弹，其后是敌弹 */
static ent_t    g_spk[SPARK_MAX];    /* 爆点火花池 */
static enemy_t  g_en[ENEMY_MAX];     /* 敌机 */
static draw_t   g_dl[DRAW_MAX];      /* 本帧待下发清单（引擎与 CPU 路径共用） */
static int      g_dl_n = 0;
static int      g_dl_i = 0;
static int      g_clip_drop = 0;     /* 完全落在区外、被裁掉的条数（诊断用，正常很少） */

/* 星空（背景装饰，2x2 FILL；`b` 键开关） */
typedef struct { int16_t x, y; uint16_t col; uint8_t spd; } star_t;
static star_t   g_star[STAR_MAX];
static int      g_star_n = STAR_MAX;

/* ============================== 游戏状态 ============================== */
#define GS_TITLE 0
#define GS_PLAY  1
#define GS_OVER  2

#define MD_HW 2
#define MD_SW 1

static int      g_state   = GS_TITLE;
static int      g_pause   = 0;
static int      g_mode    = MD_HW;      /* 渲染路径：硬件 / 纯 CPU 对照 */
static int      g_ncap    = 256;        /* 敌弹同屏上限（N） */
static int      g_auto    = 0;          /* 自动爬坡 */

static int16_t  g_px = 0, g_py = 0;     /* 自机 Q3 */
static int      g_invuln = 0;
static int      g_hp     = 3;
static int      g_bomb   = 3;
static int      g_level  = 1;
static int      g_score  = 0;
static int      g_shot_t = 0;
static int      g_level_t = 0;
static unsigned g_keymask = 0u;
static int      g_bomb_req = 0;         /* 炸弹的**上升沿**请求 */
static uint32_t g_key_t   = 0;          /* 最后一次收到按键包的时刻 */
static int      g_keys_live = 0;
static uint32_t g_frames  = 0;

/* 帧率统计（两个路径各自记一个数，都留在屏幕上 ⇒ 同屏对比） */
static uint32_t g_hw_fps = 0, g_sw_fps = 0;
static uint32_t g_hw_frames = 0, g_sw_frames = 0;
static uint32_t g_t_fps = 0;            /* 1Hz 窗口起点（切换渲染路径时重置，见 serial_cmd） */
static int      g_on_screen = 0;        /* 本帧实际下发的 sprite 数（含星空） */
static int      g_lim_n = 0;            /* 自动爬坡找到的极限 N */

/* ============================== 游戏逻辑（纯函数段） ==============================
 * ==== GAMELOGIC_BEGIN ====（主机自检原样取本段源码）
 * 需要外部：PLAY_* / Q3 / ent_t / enemy_t / g_sin64 / isin / icos / isqrt32 / rnd。
 * 这一段**不碰任何硬件**：所有函数只读写传入的结构体与全局实体数组，
 * 所以可以在 PC/QEMU 上原样跑几十万帧来验「不出界、不越界、不泄漏」。 */

/* 把实体夹在游戏区内（左上角坐标系：x ∈ [0, PLAY_W-sz]，y ∈ [PLAY_Y0, PLAY_Y1-sz]） */
static void ent_clamp(ent_t *e)
{
    int sz = (int)e->sz;
    int x = PX(e->x), y = PX(e->y);
    if (x < 0) { x = 0; e->vx = (int16_t)(-e->vx); }
    if (x > PLAY_W - sz) { x = PLAY_W - sz; e->vx = (int16_t)(-e->vx); }
    if (y < PLAY_Y0) { y = PLAY_Y0; e->vy = (int16_t)(-e->vy); }
    if (y > PLAY_Y1 - sz) { y = PLAY_Y1 - sz; e->vy = (int16_t)(-e->vy); }
    e->x = (int16_t)FP(x); e->y = (int16_t)FP(y);
}
/* 从 [from, to) 里取一个空闲弹槽；满了返回 -1（**这就是「同屏上限」的物理含义**）。
 * ★ 自机弹与敌弹分段：自机弹永远拿得到槽位，不会因为屏幕被敌弹塞满而开不出火。 */
static int bul_alloc(int from, int to)
{
    int i;
    for (i = from; i < to; i++) if (g_bul[i].life == 0) return i;
    return -1;
}
/* ★ 存活敌弹计数：**给「池满」加一条 O(1) 快路径**。
 *   没有它的话，池满时每一次发射都要把 2400 个槽线性扫一遍；一帧里最多有
 *   「敌机数 × 环弹数」次发射（16 × 24 = 384 次）⇒ 最坏 92 万次循环 ≈ 2~3M 拍，
 *   比一帧预算（1.67M 拍）还长 —— 表现就是「弹幕铺满的一瞬间掉帧」。
 *   计数每帧在 game_tick 的子弹循环里**重算一次**（那里本来就要遍历），帧内靠 ++ 记账；
 *   子弹在别处被回收时计数会暂时偏大 —— 那只会让判断更保守，不会漏发。 */
static int g_bul_live = 0;
static int bul_alloc_enemy(void)
{
    if (g_bul_live >= g_ncap) return -1;          /* 快路径：池满直接拒绝，不扫描 */
    return bul_alloc(PLR_SLOTS, PLR_SLOTS + g_ncap);
}
/* 按角度索引发射（角度单位 = 1/64 圈） */
static void bul_fire(int x, int y, int ang, int spd, int variant)
{
    int i = bul_alloc_enemy();
    ent_t *b;
    if (i < 0) return;
    b = &g_bul[i];
    b->x = (int16_t)x; b->y = (int16_t)y;
    b->vx = (int16_t)((icos(ang) * spd) >> 8);
    b->vy = (int16_t)((isin(ang) * spd) >> 8);
    if (b->vx == 0 && b->vy == 0) b->vy = 8;
    b->kind = (uint8_t)(S_B0 + (variant & 3));
    b->sz   = SZ_B;
    b->r    = 4;                       /* 敌弹判定半径（比看起来小：弹幕礼仪） */
    b->life = BULLET_LIFE;
    g_bul_live++;
}
/* 瞄准自机 + 侧向扇开（`off` = 加在垂直单位向量上的横向分量） */
static void bul_fire_aim(int x, int y, int off, int spd, int variant)
{
    int i = bul_alloc_enemy();
    ent_t *b;
    int dx, dy, d, px, py;
    if (i < 0) return;
    b = &g_bul[i];
    dx = (int)g_px - x; dy = (int)g_py - y;
    d  = isqrt32((uint32_t)(dx * dx + dy * dy));
    if (d < 1) d = 1;
    px = (-dy * 256) / d; py = (dx * 256) / d;      /* 垂直单位向量（定标 256） */
    b->x = (int16_t)x; b->y = (int16_t)y;
    b->vx = (int16_t)((dx * spd) / d + (px * off) / 256);
    b->vy = (int16_t)((dy * spd) / d + (py * off) / 256);
    if (b->vx == 0 && b->vy == 0) b->vy = 8;
    b->kind = (uint8_t)(S_B0 + (variant & 3));
    b->sz   = SZ_B;
    b->r    = 4;
    b->life = BULLET_LIFE;
    g_bul_live++;
}
/* 推进一个实体。wrap=1 时夹在游戏区内；wrap=0 时出界即回收。返回 1 = 还活着 */
static int ent_step(ent_t *e, int wrap)
{
    int x, y;
    if (e->life == 0) return 0;
    e->life--;
    e->x = (int16_t)(e->x + e->vx);
    e->y = (int16_t)(e->y + e->vy);
    x = PX(e->x); y = PX(e->y);
    if (wrap) { ent_clamp(e); return 1; }
    if (x < -32 || x > PLAY_W + 32 || y < PLAY_Y0 - 48 || y > PLAY_Y1 + 48) { e->life = 0; return 0; }
    return 1;
}
/* 圆-圆碰撞：比较距离平方（不开方，省 CPU） */
static int hit_cc(int ax, int ay, int ar, int bx, int by, int br)
{
    int dx = ax - bx, dy = ay - by, rr = ar + br;
    return (dx * dx + dy * dy) <= (rr * rr);
}
/* 敌机开火（关卡越高弹越多越快） —— 这是「同屏元素数量」的主要来源 */
static void enemy_fire(enemy_t *e, int level)
{
    int i, k, spd, ph;
    spd = 14 + level * 2; if (spd > 34) spd = 34;
    ph  = (int)e->phase;
    switch (e->kind & 3) {
    case 0:                                   /* 环弹：环的粗细也随 N 上限长（N 越大弹幕越密） */
        k = 8 + level * 2 + g_ncap / 192; if (k > 24) k = 24;
        for (i = 0; i < k; i++) bul_fire(e->x, e->y, ph + (i * 64) / k, spd, i);
        break;
    case 1:                                   /* 瞄准多连扇 */
        k = 3 + level; if (k > 7) k = 7;
        for (i = 0; i < k; i++) bul_fire_aim(e->x, e->y, (i - (k - 1) / 2) * 26, spd + 6, 1);
        break;
    default:                                  /* 双螺旋 */
        bul_fire(e->x, e->y, ph, spd + 4, 2);
        bul_fire(e->x, e->y, ph + 32, spd + 4, 2);
        break;
    }
    e->phase = (uint8_t)(ph + 5);
}
/* ==== GAMELOGIC_END ==== */

/* ============================== 帧预算模型 ==============================
 * ==== COSTMODEL_BEGIN ====（主机自检原样取本段源码）
 * 板级实测（v2.16 口径，逐条下发、单 lane）：每块 = A + B×px
 *   FILL A=252 B=1.025 | KEY A=398 B=1.255 | ALPHA A=464 B=1.533
 * v3.1 双 lane 把**像素项**减半（固定项 A 不变）——官方只到仿真（1.5~1.8×），
 * 所以这里同时给出「保守（单 lane）」与「乐观（双 lane）」两个估计；
 * 面板上按**实测帧率**决策，模型只用来解释现象与写文档。 */
#define FRAME_TICKS_60FPS   1666667u
#define CYC_A_FILL   252u
#define CYC_B_FILL   1025u        /* ×1000 定点 */
#define CYC_A_KEY    398u
#define CYC_B_KEY    1255u
#define CYC_A_ALPHA  464u
#define CYC_B_ALPHA  1533u

static uint32_t cyc_of(int op, int sz)
{
    uint32_t a, b;
    if (op == DRAW_KEY)                                 { a = CYC_A_KEY;   b = CYC_B_KEY;   }
    else if (op == DRAW_GLOW || op == DRAW_ALPHA)       { a = CYC_A_ALPHA; b = CYC_B_ALPHA; }
    else                                                { a = CYC_A_FILL;  b = CYC_B_FILL;  }
    return a + ((uint32_t)(sz * sz) * b) / 1000u;
}
/* 给定「满帧预算 × pct%」能塞下多少个 sz×sz 的精灵（dual=1 走双 lane 估计） */
static uint32_t cost_capacity(int op, int sz, int pct, int dual)
{
    uint32_t per = cyc_of(op, sz);
    uint32_t a   = (op == DRAW_KEY) ? CYC_A_KEY
                 : ((op == DRAW_GLOW || op == DRAW_ALPHA) ? CYC_A_ALPHA : CYC_A_FILL);
    uint32_t budget = (FRAME_TICKS_60FPS / 100u) * (uint32_t)pct;
    if (dual) per = a + (per - a) / 2u;
    if (per == 0u) return 0u;
    return budget / per;
}
/* ==== COSTMODEL_END ==== */

/* ============================== 自动爬坡：找 60FPS 下的极限 N ==============================
 * ==== RAMP_BEGIN ====（主机自检原样取本段源码）
 * 规则（每一步都要能复现）：
 *   · 每秒判一次（与 1Hz 帧率窗口同一个节拍）；
 *   · 测得帧率 ≥ 58 ⇒ N 抬高一档（+max(N_STEP, N/8)），继续；
 *   · 测得帧率 <  58 ⇒ **回退一档**、记下 LIMIT、关掉自动爬坡。
 * ★ 「极限」的定义 = 在**这一颗位流 + 当前场景**下仍然稳定跑满 60fps 的最大 N。
 *   上屏是垂直同步锁定的，帧率只会是 60 / 30 / 20… 台阶 ⇒ 判据用 58 而不是 45。
 * 返回值：1 = 已抬高；2 = 顶到 N_MAX 停下；-1 = 帧率不足，已停并给出 LIMIT；0 = 无动作。 */
static int ramp_apply(int fps, int *ncap, int *lim_n, int *auto_on)
{
    int prev = *ncap;
    int step;
    if (!*auto_on) return 0;
    if (fps <= 0) return 0;                       /* 还没有效窗口 */
    if (fps >= 58) {
        step = prev / 8;
        if (step < N_STEP) step = N_STEP;
        if (prev + step >= N_MAX) { *ncap = N_MAX; *lim_n = N_MAX; *auto_on = 0; return 2; }
        *ncap = prev + step;
        return 1;
    }
    *ncap = (prev > N_MIN) ? (prev - prev / 8) : N_MIN;
    *lim_n = *ncap;
    *auto_on = 0;
    return -1;
}
/* ==== RAMP_END ==== */

/* ============================== 绘制清单构建 ==============================
 * ★★ **裁剪是硬要求，不是美化**：弹幕会飞出游戏区，而目的地址算的是
 *    `FB + y*FB_STRIDE + x*2`；int16 的负数一旦被转成 uint32 参与乘加，就会写到
 *    帧缓冲之外的 DDR（甚至算成巨大的偏移）—— 那是「画面花掉 + 别的缓冲区被踩」级别的事故。
 *    所以**每一条精灵在进清单之前**都先按游戏区裁成矩形，并记下源偏移 (sx,sy)；
 *    完全在区外的条目直接丢弃。屏幕骨架（信息条）同时也被保护：y 一律裁到 PLAY_Y0 以下。
 *    （引擎的显示列表路径有 CLIP_EN 可以做这件事，但逐条路径没有 ⇒ 软件自己裁。） */
static void dl_push(uint8_t op, int x, int y, uint16_t arg, int w, int h,
                    uint8_t ga, uint8_t sx, uint8_t sy)
{
    draw_t *d;
    if (g_dl_n >= DRAW_MAX) return;
    d = &g_dl[g_dl_n++];
    d->x = (int16_t)x; d->y = (int16_t)y;
    d->arg = arg; d->op = op;
    d->w = (uint8_t)w; d->h = (uint8_t)h;
    d->ga = ga; d->sx = sx; d->sy = sy; d->rsv = 0;
}
/* 以**中心**（Q3）给位置，按游戏区裁剪后进清单。
 * ★★ 裁剪是硬要求，不是美化：见文件头 §5.2 —— 弹幕会飞出游戏区，
 *    int16 的负数一旦被转成 uint32 参与乘加，就会写到帧缓冲之外。 */
static void dl_rect_op(int op, uint16_t arg, int cx, int cy, int sz, uint8_t ga)
{
    int x0 = PX(cx) - sz / 2, y0 = PX(cy) - sz / 2;
    int x1 = x0 + sz, y1 = y0 + sz;
    int sx = 0, sy = 0;
    if (x0 < 0)                { sx = -x0; x0 = 0; }
    if (y0 < PLAY_Y0)          { sy = PLAY_Y0 - y0; y0 = PLAY_Y0; }
    if (x1 > FB_WIDTH)         x1 = FB_WIDTH;
    if (y1 > FB_HEIGHT)        y1 = FB_HEIGHT;
    if (x1 <= x0 || y1 <= y0)  { g_clip_drop++; return; }      /* 完全在区外 */
    dl_push((uint8_t)op, x0, y0, arg, x1 - x0, y1 - y0, ga, (uint8_t)sx, (uint8_t)sy);
}
static void dl_sprite(int spr, int cx, int cy, uint8_t ga)
{
    dl_rect_op((spr == S_PR || spr == S_EN) ? DRAW_KEY : DRAW_GLOW,
               (uint16_t)spr, cx, cy, (int)g_spr_sz[spr], ga);
}
/* ★ 敌弹：按 `g_bulm` 选算子（FILL / ALPHA / ADD / KEY）。
 *   自机弹与火花不走这里（它们固定用加算辉光），所以切模式时**只有弹幕**在变。 */
static void dl_bullet(const ent_t *b)
{
    int sz = (int)b->sz;
    switch (g_bulm) {
    case BULM_FILL:
        /* FILL 没有源/键色/alpha：一块纯色方块；sx/sy 对 FILL 无意义 */
        dl_rect_op(DRAW_FILL, g_spr_fill[b->kind], b->x, b->y, sz, 0u);
        break;
    case BULM_ALPHA:
        dl_rect_op(DRAW_ALPHA, (uint16_t)b->kind, b->x, b->y, sz, BUL_ALPHA_V);
        break;
    case BULM_ADD:
        dl_rect_op(DRAW_GLOW, (uint16_t)b->kind, b->x, b->y, sz, 255u);
        break;
    default:
        dl_rect_op(DRAW_KEY, (uint16_t)b->kind, b->x, b->y, sz, 0u);
        break;
    }
}
/* 顺序：重铺 → 星空 → 弹 → 敌机 → 自机 → 火花。
 * · 加算可交换 ⇒ 弹之间没有 z 序问题；
 * · 无属性侧口时弹走 KEY（覆盖式）⇒ 必须画在敌机/自机**之前**，否则会把机体抠掉。 */
static void build_draw_list(int repaint)
{
    int i;
    g_dl_n = 0;
    g_clip_drop = 0;
    /* ★ DRAW_FILL_FULL 的 w/h 走 PLAY_W/PLAY_H（960x524 放不进 uint8）⇒ 这里传 0，
     *   由 push_chunk / cpu_render_frame 按常量展开。 */
    if (repaint) dl_push(DRAW_FILL_FULL, 0, PLAY_Y0, COL_BG, 0, 0, 0u, 0u, 0u);
    for (i = 0; i < g_star_n; i++) {
        int sx = g_star[i].x, sy = g_star[i].y;
        if (sx > FB_WIDTH - 2) sx = FB_WIDTH - 2;               /* 2x2 不许出右边界 */
        if (sy > PLAY_Y1 - 2)  sy = PLAY_Y1 - 2;
        dl_push(DRAW_FILL, sx, sy, g_star[i].col, 2, 2, 0u, 0u, 0u);
    }
    for (i = 0; i < BUL_TOTAL; i++)
        if (g_bul[i].life) {
            if (i < PLR_SLOTS) dl_sprite(g_bul[i].kind, g_bul[i].x, g_bul[i].y, 255u); /* 自机弹固定加算 */
            else               dl_bullet(&g_bul[i]);                                  /* 敌弹按 g_bulm */
        }
    for (i = 0; i < ENEMY_MAX; i++)
        if (g_en[i].t) dl_sprite(S_EN, g_en[i].x, g_en[i].y, 0u);
    if (g_state != GS_OVER && !(g_invuln && ((g_frames >> 1) & 1u)))
        dl_sprite(S_PR, g_px, g_py, 0u);
    for (i = 0; i < SPARK_MAX; i++) {
        unsigned a;
        if (!g_spk[i].life) continue;
        a = (unsigned)g_spk[i].life * 255u / 20u;
        if (a > 255u) a = 255u;
        dl_sprite(S_SP, g_spk[i].x, g_spk[i].y, (uint8_t)a);
    }
}
static int dl_sprite_count(void)
{
    int i, n = 0;
    for (i = 0; i < g_dl_n; i++) if (g_dl[i].op != DRAW_FILL_FULL) n++;
    return n;
}

/* ============================== 把清单推进引擎（分块、有界） ============================== */
static void spark_add(int cx, int cy)
{
    int i;
    for (i = 0; i < SPARK_MAX; i++) {
        if (g_spk[i].life == 0) {
            g_spk[i].x = (int16_t)cx; g_spk[i].y = (int16_t)cy;
            g_spk[i].vx = 0; g_spk[i].vy = 0;
            g_spk[i].kind = S_SP; g_spk[i].sz = SZ_SP; g_spk[i].r = 0;
            g_spk[i].life = 20;
            return;
        }
    }
}
static void push_chunk(void)
{
    uint32_t room = blt_push_room();
    uint32_t budget = HW_PUSH_BUDGET;
    if (room == 0u) { cpu_backoff(BLT_WAIT_NOP); return; }   /* 引擎没跟上：纯 ALU 退避 */
    while (g_dl_i < g_dl_n && room > 0u && budget-- > 0u) {
        draw_t *d = &g_dl[g_dl_i];
        if (d->op == DRAW_FILL_FULL) {
            e_fill(g_fb_back + (uint32_t)PLAY_Y0 * FB_STRIDE, FB_STRIDE, PLAY_W, PLAY_H, d->arg);
        } else if (d->op == DRAW_FILL) {
            e_fill(g_fb_back + (uint32_t)d->y * FB_STRIDE + (uint32_t)d->x * 2u,
                   FB_STRIDE, d->w, d->h, d->arg);
        } else {
            uint32_t ss  = (uint32_t)g_spr_sz[d->arg] * 2u;
            uint32_t src = ATLAS_BASE + g_spr_off[d->arg]
                         + (uint32_t)d->sy * ss + (uint32_t)d->sx * 2u;   /* ★ 源裁剪偏移 */
            uint32_t dst = g_fb_back + (uint32_t)d->y * FB_STRIDE + (uint32_t)d->x * 2u;
            if (d->op == DRAW_GLOW)       e_glow(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
            else if (d->op == DRAW_ALPHA) e_alpha(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
            else                          e_key(src, dst, ss, FB_STRIDE, d->w, d->h, TRANS_KEY);
        }
        g_dl_i++;
        room--;
    }
}

/* ============================== CPU 参考渲染器（对照用） ==============================
 * ★ 这是「纯软件 CPU 渲染」的**诚实分母**：逐像素 16bit 读改写 + 全屏铺底，不做任何批量化。
 *   （16bit 存储地址恒偶对齐 ⇒ 永远不会踩未对齐异常。） */
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
/* 加算（与 RTL 的 blend=ADD 同式）：out_c8 = min(255, ⌊fg_c8·ga/255⌋ + bg_c8) */
static uint16_t add565(uint16_t fg, uint16_t bg, unsigned ga)
{
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    unsigned r = f8r * ga / 255u + b8r;
    unsigned g = f8g * ga / 255u + b8g;
    unsigned b = f8b * ga / 255u + b8b;
    if (r > 255u) r = 255u;
    if (g > 255u) g = 255u;
    if (b > 255u) b = 255u;
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
}
/* 与引擎同口径的裁剪：目的 (x,y,w,h) + 源偏移 (sx,sy) */
static void cpu_blit(int spr, int x, int y, int w, int h, int sx, int sy, unsigned ga, int mode)
{
    const volatile uint16_t *s = (const volatile uint16_t *)(ATLAS_BASE + g_spr_off[spr]);
    int sw = (int)g_spr_sz[spr];
    int j, i;
    for (j = 0; j < h; j++) {
        volatile uint16_t *d = (volatile uint16_t *)(g_fb_back
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
        const volatile uint16_t *sr = s + (j + sy) * sw + sx;
        for (i = 0; i < w; i++) {
            uint16_t c = sr[i];
            if (mode == 1)      d[i] = add565(c, d[i], ga);        /* 加算 */
            else if (mode == 2) d[i] = blend565(c, d[i], ga);      /* 经典半透明 */
            else if (c != TRANS_KEY) d[i] = c;                     /* Color Key */
        }
    }
}
static void cpu_render_frame(void)
{
    int i;
    cpu_fill32(g_fb_back, 0, PLAY_Y0, PLAY_W, PLAY_H, COL_BG);   /* 纯软件：整屏铺底也自己干 */
    for (i = 0; i < g_dl_n; i++) {
        draw_t *d = &g_dl[i];
        if (d->op == DRAW_FILL_FULL)      cpu_fill32(g_fb_back, 0, PLAY_Y0, PLAY_W, PLAY_H, d->arg);
        else if (d->op == DRAW_FILL)      cpu_fill32(g_fb_back, d->x, d->y, d->w, d->h, d->arg);
        else if (d->op == DRAW_GLOW)      cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 1);
        else if (d->op == DRAW_ALPHA)     cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 2);
        else                              cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, 0u, 0);
    }
}

/* ============================== 信息条（OSD） ============================== */
/* ==== OSD_FMT_BEGIN ====（主机自检原样取本段源码，用来量「最坏串到底多宽」） */
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
static char *appn(char *p, unsigned v, int w)
{
    char d[12]; int n = 0, i;
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    for (i = 0; i < w - n; i++) *p++ = ' ';
    while (n) *p++ = d[--n];
    return p;
}
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }

/* ★ `op` 传的是**实际生效**的敌弹档名（`bulm_eff_name()`，ADD 无属性侧口时会报 KEY）。
 *   宽度上界（**静态可证**，开机自检用真实 fmt_stat 再证一遍）：
 *     "HW=999 SW=999 N=2400 ON=9999 SC=999999 LV=99 HP=9 OP=ALPHA S G" = 62 字符 = 496px
 *     ≤ OSD_LEFT_CH*8 = 512px 的黑底；右标签最长 "PURE CPU" 右对齐起点 896 ⇒ 仍空 400px。 */
static void fmt_stat(char *line, uint32_t hw_fps, uint32_t sw_fps, int ncap, int non,
                     int score, int level, int hp, const char *op, int star, int autq)
{
    char *p = line;
    if (hw_fps > 999u) hw_fps = 999u;
    if (sw_fps > 999u) sw_fps = 999u;
    if (score > SCORE_CAP) score = SCORE_CAP;
    if (non > 9999) non = 9999;
    p = app(p, "HW=");  p = appn(p, hw_fps, 3);
    p = app(p, " SW="); p = appn(p, sw_fps, 3);
    p = app(p, " N=");  p = appn(p, (unsigned)ncap, 4);
    p = app(p, " ON="); p = appn(p, (unsigned)non, 4);
    p = app(p, " SC="); p = appn(p, (unsigned)score, 6);
    p = app(p, " LV="); p = appn(p, (unsigned)(level > 99 ? 99 : level), 2);
    p = app(p, " HP="); p = appn(p, (unsigned)(hp < 0 ? 0 : (hp > 9 ? 9 : hp)), 1);
    p = app(p, " OP="); p = app(p, op ? op : "?");
    if (star) p = app(p, " S");
    if (autq) p = app(p, " G");
    *p = 0;
}
/* ==== OSD_FMT_END ==== */

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
static const char *path_label(void) { return (g_mode == MD_SW) ? "PURE CPU" : "HW ACCEL"; }
static char g_osd_line[OSD_LEFT_CH + 2];

static void osd_build(void)
{
    fmt_stat(g_osd_line, g_hw_fps, g_sw_fps, g_ncap, g_on_screen, g_score, g_level, g_hp,
             bulm_eff_name(), g_star_n > 0, g_auto);
}
/* 落屏：只清「文字真的会落到」的两块黑底（不整条 960px 铺黑）。
 * ★ 信息条在 y<16，**渲染区之外**，清屏引擎与引擎命令都不会碰它。 */
static void osd_blit(void)
{
    const char *lbl = path_label();
    int lw = slen(g_osd_line);
    int lx = OSD_GLYPH_W * lw;
    if (lw > OSD_LEFT_CH) { lw = OSD_LEFT_CH; lx = OSD_LEFT_PX; }
    cpu_fill32(g_fb_back, OSD_TEXT_X0, 0, lx, OSD_H, COL_OSD_BG);
    cpu_fill32(g_fb_back, FB_WIDTH - OSD_RIGHT_PX, 0, OSD_RIGHT_PX, OSD_H, COL_OSD_BG);
    osd_text(OSD_TEXT_X0, OSD_TEXT_Y, g_osd_line, COL_WHITE);
    osd_text(FB_WIDTH - OSD_GLYPH_W * slen(lbl), OSD_TEXT_Y, lbl, COL_CYAN);
}
/* 中央字幕：画在游戏区里 ⇒ 必须**等引擎空闲之后**写，而且**每帧重画** */
static void center_text(const char *s, int y, uint16_t fg)
{
    int n = slen(s);
    int x = (FB_WIDTH - OSD_GLYPH_W * n) / 2;
    if (x < 8) x = 8;
    if (x + OSD_GLYPH_W * n + 8 > FB_WIDTH) return;
    cpu_fill32(g_fb_back, x - 8, y - 4, OSD_GLYPH_W * n + 16, OSD_GLYPH_H + 8, COL_OSD_BG);
    osd_text(x, y, s, fg);
}
static void overlay_draw(void)
{
    int y = PLAY_Y0 + 200;
    if (g_state == GS_TITLE) {
        center_text("DANMAKU SURVIVAL", y - 40, COL_CYAN);
        center_text("HW 2D ACCEL DEMO", y - 16, COL_WHITE);
        center_text("PRESS FIRE (J / SPACE)", y + 28, COL_AMBER);
        center_text("WASD MOVE  K FOCUS  L BOMB", y + 52, COL_GRAY);
    } else if (g_pause) {
        center_text("PAUSED", y, COL_AMBER);
    } else if (g_state == GS_OVER) {
        center_text("GAME OVER", y - 16, COL_RED);
        center_text("PRESS FIRE TO RESTART", y + 20, COL_WHITE);
    }
}

/* ============================== 能力探测：这颗位流有没有 v3.2 属性侧口？ ==============================
 * ATTR_PORT(0x8C) **只写不可读**，没法直接探。用「同批出现的 CLIP_x / LUT_x 能不能写回读」
 * 来判定 —— 与 AdDemo 的 feat_probe 同一套判据（宁可降级也不要假成功）。 */
static void feat_probe(void)
{
    uint32_t lc;
    blt_wr(BLT_CLIP_X0, 0x00000123UL); blt_wr(BLT_CLIP_X1, 0x00000456UL);
    blt_wr(BLT_CLIP_Y0, 0x00000789UL); blt_wr(BLT_CLIP_Y1, 0x00000AB0UL);
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    blt_wr(BLT_CLIP_CTRL, 0UL);                 /* ★ 本 Demo 不用裁剪：必须显式关掉 */
    blt_wr(BLT_LUT_CTRL, 0UL);
    lc = blt_rd(BLT_LUT_CTRL) & 3UL;
    blt_wr(BLT_LUT_CTRL, BLT_LUT_EN | BLT_LUT_BANK);
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    blt_wr(BLT_LUT_CTRL, 0UL);                  /* 关掉：没写表就不是恒等表，开了会黑屏 */
    g_glow = (g_feat_clip && g_feat_lut) ? 1 : 0;
    g_attr_on = g_glow;                         /* ★ 属性字只在确认存在时才写（配对纪律） */
    /* ★ 敌弹默认档：有属性侧口就用加算辉光（观感最好），没有就退到 Color Key
     *   （硬边但完全正确）—— 也就是**保持本次改动之前的默认行为不变**。 */
    g_bulm = g_glow ? BULM_ADD : BULM_KEY;
    bsp_printf("feat: clip=%d lut=%d attr=%d (attr=>glow ADD, else KEY fallback)\r\n",
               g_feat_clip, g_feat_lut, g_glow);
    bsp_printf("bulm: default=%s  (f cycles, 5=FILL 6=ALPHA 7=ADD 8=KEY)\r\n",
               bulm_eff_name());
    if (!g_glow)
        bsp_printf("feat WARN: v3.2 attr side-port ABSENT -> bullets use Color Key (still correct)\r\n");
}

/* ============================== 开机自检（把「只能上板才知道」的那几类挡在这里） ==============
 * 与 AdDemo 的 attr_selfcheck / spr 自检同一套思路：**纯算式 + 手算期望值**，
 * 上板第一屏就能看出对不对；同样的向量在主机自检里会再跑一遍（QEMU，见 tools/host_selfcheck）。
 * 覆盖：属性字编解码、混合/加算定点式、图集「黑=透明」、字形覆盖、帧预算模型。 */
static void boot_selfcheck(void)
{
    /* ---- ① 属性字：编码 → 解码必须逐字段回来；默认字必须等于硬件空 FIFO 的默认值 ---- */
    {
        struct { unsigned blend, fmt, ga, fl; } tv[4];
        int i, bad = 0;
        uint32_t d;
        tv[0].blend = ATTR_BLEND_OP;    tv[0].fmt = ATTR_FMT_565;  tv[0].ga = 255u; tv[0].fl = 0u;
        tv[1].blend = ATTR_BLEND_ALPHA; tv[1].fmt = ATTR_FMT_4444; tv[1].ga = 128u; tv[1].fl = 0u;
        tv[2].blend = ATTR_BLEND_ADD;   tv[2].fmt = ATTR_FMT_565;  tv[2].ga = 96u;  tv[2].fl = 0u;
        tv[3].blend = ATTR_BLEND_MUL;   tv[3].fmt = ATTR_FMT_1555; tv[3].ga = 64u;
        tv[3].fl = ATTR_FLAG_ATEST;
        for (i = 0; i < 4; i++) {
            uint32_t w = attr_word(tv[i].blend, tv[i].fmt, tv[i].ga, tv[i].fl);
            if (attr_blend(w) != tv[i].blend || attr_fmt(w) != tv[i].fmt ||
                attr_ga(w) != tv[i].ga || attr_flags(w) != tv[i].fl) bad++;
        }
        d = attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u);
        bsp_printf("selfcheck attr: decode_err=%d default=%x match=%d\r\n",
                   bad, (unsigned)d, (d == (uint32_t)ATTR_DEFAULT) ? 1 : 0);
    }
    /* ---- ② 定点混合：手算期望值（RTL 公式见文件头 §3 / rtl/pixel_path.v） ----
     *   blend565(红, 蓝, 128) = 0x780F ；add565(红, 蓝, 255) = 0xF81F ；
     *   add565(黑, X, 255) = X（**辉光弹「黑=透明」的数学依据**）。 */
    bsp_printf("selfcheck mix: blend=%x (exp 780F) add=%x (exp F81F) addblack=%x (exp 1234)\r\n",
               (unsigned)blend565(0xF800u, 0x001Fu, 128u),
               (unsigned)add565(0xF800u, 0x001Fu, 255u),
               (unsigned)add565(0x0000u, 0x1234u, 255u));
    /* ---- ③ 图集：每张精灵的边界像素必须是透明键色，圆心必须不透明 ---- */
    {
        int id, bad = 0;
        for (id = 0; id < S_N; id++) {
            int w = (int)g_spr_sz[id];
            if (spr_pixel(id, 0, 0) != TRANS_KEY) bad++;                 /* 左上角（圆/三角外） */
            if (spr_pixel(id, w - 1, 0) != TRANS_KEY) bad++;             /* 右上角 */
            if (spr_pixel(id, w / 2, w / 2) == TRANS_KEY) bad++;         /* 中心必须实心 */
        }
        bsp_printf("selfcheck atlas: corner_err=%d bytes=%d\r\n", bad, (int)ATLAS_BYTES);
    }
    /* ---- ④ 信息条最坏串：宽度上界 + 每个字符都得有字形（缺字会静默变空格） ---- */
    {
        char worst[OSD_LEFT_CH + 2];
        int i, miss = 0;
        fmt_stat(worst, 999u, 999u, N_MAX, 9999, SCORE_CAP, 99, 9, "ALPHA", 1, 1);
        for (i = 0; worst[i]; i++) if (!glyph_found(worst[i])) miss++;
        for (i = 0; path_label()[i]; i++) if (!glyph_found(path_label()[i])) miss++;
        bsp_printf("selfcheck osd: len=%d px=%d limit=%d gap=%d missing_glyph=%d\r\n",
                   slen(worst), slen(worst) * OSD_GLYPH_W, OSD_LEFT_PX,
                   (FB_WIDTH - OSD_RIGHT_PX) - slen(worst) * OSD_GLYPH_W, miss);
    }
    /* ---- ⑤ ★ 敌弹显示模式表：四个档名必须都被字形覆盖，且档序与串口命令一致 ---- */
    {
        int i, miss = 0;
        for (i = 0; i < BULM_N; i++)
            { int k; for (k = 0; g_bulm_name[i][k]; k++) if (!glyph_found(g_bulm_name[i][k])) miss++; }
        bsp_printf("selfcheck bulm: cur=%s eff=%s names_glyph_missing=%d (keys f cycle, 5=FILL 6=ALPHA 7=ADD 8=KEY)\r\n",
                   g_bulm_name[g_bulm], bulm_eff_name(), miss);
    }
    /* ---- ⑥ 帧预算模型：60fps 下 16x16 三种算子的理论容量（这一行就是"切档为什么值得"的答案） ---- */
    bsp_printf("cap model 16x16 70pct budget: FILL=%d ALPHA=%d KEY=%d (single-lane board cal)\r\n",
               (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 0),
               (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 0),
               (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 0));
    bsp_printf("cap model 16x16 70pct budget: ... dual-lane estimate FILL=%d ALPHA=%d KEY=%d\r\n",
               (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 1),
               (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 1),
               (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 1));
}

static void stars_reset(void)
{
    int i;
    for (i = 0; i < STAR_MAX; i++) {
        g_star[i].x = (int16_t)(rnd() % (uint32_t)(FB_WIDTH - 2));
        g_star[i].y = (int16_t)(PLAY_Y0 + (rnd() % (uint32_t)(PLAY_H - 2)));
        g_star[i].col = (uint16_t)((rnd() & 1u) ? 0x18E3u : 0x0841u);
        g_star[i].spd = (uint8_t)(1u + (rnd() % 3u));
    }
}
static void game_reset(void)
{
    int i;
    for (i = 0; i < BUL_TOTAL; i++) g_bul[i].life = 0;
    for (i = 0; i < SPARK_MAX; i++) g_spk[i].life = 0;
    g_bul_live = 0;
    for (i = 0; i < ENEMY_MAX; i++) {
        g_en[i].t = 0; g_en[i].x = 0; g_en[i].y = 0; g_en[i].vx = 0; g_en[i].vy = 0;
        g_en[i].hp = 0; g_en[i].kind = 0; g_en[i].fire = 0; g_en[i].phase = 0;
    }
    g_px = (int16_t)FP(FB_WIDTH / 2);
    g_py = (int16_t)FP(PLAY_Y1 - 70);
    g_invuln = 90; g_hp = 3; g_bomb = 3; g_level = 1; g_score = 0;
    g_shot_t = 0; g_level_t = 0; g_bomb_req = 0;
    g_state = GS_PLAY; g_pause = 0;
    g_frames = 0;
}

/* ============================== 一帧的游戏推进（CPU 只算不画） ============================== */
static void player_step(void)
{
    int spd = (g_keymask & KEY_FOCUS) ? PLR_SPD_F : PLR_SPD;   /* Q3/帧 */
    int nx = (int)g_px, ny = (int)g_py;
    int i;
    if (g_keymask & KEY_LEFT)  nx -= spd;
    if (g_keymask & KEY_RIGHT) nx += spd;
    if (g_keymask & KEY_UP)    ny -= spd;
    if (g_keymask & KEY_DOWN)  ny += spd;
    if (nx < FP(16)) nx = FP(16);
    if (nx > FP(FB_WIDTH - 16)) nx = FP(FB_WIDTH - 16);
    if (ny < FP(PLAY_Y0 + 16)) ny = FP(PLAY_Y0 + 16);
    if (ny > FP(PLAY_Y1 - 16)) ny = FP(PLAY_Y1 - 16);
    g_px = (int16_t)nx; g_py = (int16_t)ny;

    /* 自机弹：按住开火键即连发（标题/结束页按一下开火 = 开始） */
    if (g_state == GS_PLAY && (g_keymask & KEY_FIRE)) {
        if (--g_shot_t <= 0) {
            g_shot_t = PLR_SHOT_T;
            for (i = 0; i < 2; i++) {
                int k = bul_alloc(0, PLR_SLOTS);
                if (k >= 0) {
                    ent_t *b = &g_bul[k];
                    b->x = (int16_t)(g_px + (i ? FP(6) : -FP(6)));
                    b->y = (int16_t)(g_py - FP(20));
                    b->vx = 0; b->vy = (int16_t)(-56);
                    b->kind = S_SH; b->sz = SZ_B; b->r = 4; b->life = 90;
                }
            }
        }
    }
    /* 炸弹（上升沿）：清光敌弹换成火花，敌机各掉 3 点血 */
    if (g_bomb_req) {
        int k = 0;
        g_bomb_req = 0;
        if (g_state == GS_PLAY && g_bomb > 0) {
            for (i = PLR_SLOTS; i < BUL_TOTAL; i++)
                if (g_bul[i].life) {
                    if ((k++ & 3) == 0) spark_add(g_bul[i].x, g_bul[i].y);
                    g_bul[i].life = 0;
                }
            for (i = 0; i < ENEMY_MAX; i++) if (g_en[i].t) g_en[i].hp -= 3;
            g_bomb--; g_invuln = 60;
            bsp_printf("\r\nEV bomb left=%d\r\n", g_bomb);
        }
    }
}

static void game_tick(void)
{
    int i;
    if (g_state == GS_TITLE) {
        g_px = (int16_t)FP(FB_WIDTH / 2 + (isin((int)(g_frames & 63)) * 120) / 256);
        g_py = (int16_t)FP(PLAY_Y1 - 70);
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV start\r\n"); }
        g_frames++;
        return;
    }
    if (g_state == GS_OVER) {
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV restart\r\n"); }
        g_frames++;
        return;
    }
    if (g_pause) return;

    g_frames++;
    player_step();
    if (g_invuln > 0) g_invuln--;

    /* 关卡 / 分数 */
    if (++g_level_t >= LEVEL_TICKS) {
        g_level_t = 0;
        if (g_level < 99) g_level++;
        bsp_printf("\r\nEV level=%d\r\n", g_level);
    }
    if ((g_frames % (uint32_t)SCORE_TICK_DIV) == 0) g_score += SCORE_PER_TICK;
    if (g_score > SCORE_CAP) g_score = SCORE_CAP;

    /* 敌机生成：场上敌机数随 N 上限成长（N 越大越"顶得住"就越多）。
     * ★ 每拍**补到 want**（每拍最多 ENEMY_TOPUP 架），而不是"每拍只补一架"：
     *   后者在 N 从 256 跳到 2400 时要 27×16=432 帧（7 秒）才把敌机铺开 ⇒ 用户按 '4'
     *   之后要等半分钟弹幕才密起来，看起来像"加速器带不动"。主机自检就是靠
     *   「N=2400 时同屏元素数必须 >600」这条断言把这个坑钉住的。 */
    if ((g_frames % (uint32_t)ENEMY_SPAWN_T) == 0) {
        int want = 2 + g_ncap / 80;
        int alive = 0, topup;
        if (want > ENEMY_MAX) want = ENEMY_MAX;
        for (i = 0; i < ENEMY_MAX; i++) if (g_en[i].t) alive++;
        topup = want - alive;
        if (topup > ENEMY_TOPUP) topup = ENEMY_TOPUP;
        while (topup-- > 0) {
            for (i = 0; i < ENEMY_MAX; i++) {
                if (g_en[i].t == 0) {
                    enemy_t *e = &g_en[i];
                    e->kind  = (uint8_t)(rnd() % 3u);
                    e->x     = (int16_t)FP(60 + (int)(rnd() % (uint32_t)(FB_WIDTH - 120)));
                    e->y     = (int16_t)FP(PLAY_Y0 + 40);
                    e->vx    = 0;
                    e->vy    = (int16_t)(4 + (int)(rnd() % 4u));
                    e->hp    = 3;
                    e->t     = ENEMY_LIFE;
                    e->fire  = (uint8_t)(20 + (int)(rnd() % 30u));
                    e->phase = (uint8_t)(rnd() & 63u);
                    break;
                }
            }
        }
    }
    /* 敌机推进 + 开火 */
    for (i = 0; i < ENEMY_MAX; i++) {
        enemy_t *e = &g_en[i];
        if (!e->t) continue;
        e->t--;
        e->y = (int16_t)(e->y + e->vy);
        e->x = (int16_t)(e->x + (isin((int)((g_frames + (uint32_t)i * 8u) & 63u)) * 2));
        if (PX(e->x) < 40) e->x = (int16_t)FP(40);
        if (PX(e->x) > FB_WIDTH - 40) e->x = (int16_t)FP(FB_WIDTH - 40);
        if (PX(e->y) > PLAY_Y0 + 220) e->vy = 0;
        if (e->fire > 0) e->fire--;
        if (e->fire == 0) { enemy_fire(e, g_level); e->fire = ENEMY_FIRE_T; }
        if (e->y > FP(PLAY_Y1 + 60)) e->t = 0;
    }

    /* 子弹推进 + 碰撞 */
    for (i = 0; i < BUL_TOTAL; i++) {
        ent_t *b = &g_bul[i];
        int bx, by;
        if (!b->life) continue;
        if (!ent_step(b, 0)) continue;
        bx = PX(b->x); by = PX(b->y);
        if (i < PLR_SLOTS) {                         /* 自机弹 → 打敌机 */
            int k;
            for (k = 0; k < ENEMY_MAX; k++) {
                enemy_t *e = &g_en[k];
                if (!e->t) continue;
                if (hit_cc(bx, by, (int)b->r, PX(e->x), PX(e->y), 15)) {
                    b->life = 0;
                    if (--e->hp <= 0) {
                        e->t = 0;
                        spark_add(e->x, e->y);
                        g_score += SCORE_PER_ENEMY * g_level;
                        if (g_score > SCORE_CAP) g_score = SCORE_CAP;
                    }
                    break;
                }
            }
        } else {                                     /* 敌弹 → 打自机 */
            if (g_invuln == 0 && g_state == GS_PLAY &&
                hit_cc(bx, by, (int)b->r, PX(g_px), PX(g_py), PLR_HIT_R)) {
                b->life = 0;
                spark_add(b->x, b->y);
                g_hp--;
                g_invuln = INVULN_T;
                bsp_printf("\r\nEV hit hp=%d\r\n", g_hp);
                if (g_hp <= 0) {
                    int q;
                    for (q = PLR_SLOTS; q < BUL_TOTAL; q++)
                        if (g_bul[q].life && (q & 7) == 0) spark_add(g_bul[q].x, g_bul[q].y);
                    g_state = GS_OVER;
                    bsp_printf("\r\nEV gameover score=%d level=%d on=%d n=%d\r\n",
                               g_score, g_level, g_on_screen, g_ncap);
                    return;
                }
            }
        }
    }
    /* 火花生命递减 */
    for (i = 0; i < SPARK_MAX; i++) if (g_spk[i].life) g_spk[i].life--;
    /* ★ 每帧重算存活敌弹数（上面刚遍历过全部子弹，这里只需要再数一遍；
     *   它是 bul_alloc_enemy() 那条 O(1) 快路径的依据，见该函数注释） */
    {
        int live = 0;
        for (i = PLR_SLOTS; i < BUL_TOTAL; i++) if (g_bul[i].life) live++;
        g_bul_live = live;
    }
    /* 星空滚动 */
    for (i = 0; i < g_star_n; i++) {
        g_star[i].y = (int16_t)(g_star[i].y + (int)g_star[i].spd);
        if (g_star[i].y > PLAY_Y1) {
            g_star[i].y = (int16_t)PLAY_Y0;
            g_star[i].x = (int16_t)(rnd() % FB_WIDTH);
        }
    }
}

/* ★ 单字符命令的**唯一实现**。抽成独立函数有两个理由：
 *   ① serial_drain() 里只剩「协议分派」，读起来一条线；
 *   ② 主机自检（tools/host_selfcheck_game）可以直接调用它来驱动真·固件的命令分支，
 *      而不是在测试里重抄一份 switch（那样测的就不是固件了）。 */
static void serial_cmd(int c)
{
    switch (c) {
    case '1': g_ncap = 256;  g_auto = 0; bsp_printf("\r\nEV N=%d (preset low)\r\n", g_ncap); break;
    case '2': g_ncap = 640;  g_auto = 0; bsp_printf("\r\nEV N=%d (preset mid)\r\n", g_ncap); break;
    case '3': g_ncap = 1280; g_auto = 0; bsp_printf("\r\nEV N=%d (preset high)\r\n", g_ncap); break;
    case '4': g_ncap = 2400; g_auto = 0; bsp_printf("\r\nEV N=%d (preset max)\r\n", g_ncap); break;
    case 'n': case 'N': case '+':
        g_ncap += N_STEP; if (g_ncap > N_MAX) g_ncap = N_MIN; g_auto = 0;
        bsp_printf("\r\nEV N=%d\r\n", g_ncap); break;
    case '-':
        g_ncap -= N_STEP; if (g_ncap < N_MIN) g_ncap = N_MAX; g_auto = 0;
        bsp_printf("\r\nEV N=%d\r\n", g_ncap); break;
    case 'c': case 'C':
        g_mode = MD_SW; g_sw_fps = 0; g_sw_frames = 0;
        g_t_fps = tick32();     /* ★ 1Hz 窗口从头开始：否则切换那一秒会读到一个"半个窗口"的假帧率 */
        bsp_printf("\r\nEV path=SW pure CPU (same scene, honest per-pixel blit)\r\n"); break;
    case 'h': case 'H':
        g_mode = MD_HW; g_hw_fps = 0; g_hw_frames = 0;
        g_t_fps = tick32();
        bsp_printf("\r\nEV path=HW accel\r\n"); break;
    case 'g': case 'G':
        g_auto = !g_auto;
        bsp_printf("\r\nEV auto=%d (ramp N while fps>=58; LIMIT line on stop)\r\n", g_auto);
        break;
    case 'b': case 'B':
        g_star_n = g_star_n ? 0 : STAR_MAX;
        bsp_printf("\r\nEV stars=%d\r\n", g_star_n); break;
    /* ---- ★ 敌弹显示模式：'5' FILL / '6' ALPHA / '7' ADD / '8' KEY / 'f' 循环 ---- */
    case '5': case '6': case '7': case '8': case 'f': case 'F': {
        int next = (c == 'f' || c == 'F') ? ((g_bulm + 1) % BULM_N)
                 : (c - '5');
        g_bulm = next;
        bsp_printf("\r\nEV bulm=%s (requested; effective=%s)\r\n",
                   g_bulm_name[g_bulm], bulm_eff_name());
        if (g_bulm == BULM_ALPHA)
            bsp_printf("     ALPHA: rect sprite + alpha %d -> corners darken the bg (that is why KEY exists)\r\n",
                       (int)BUL_ALPHA_V);
        if (g_bulm == BULM_ADD && !g_glow)
            bsp_printf("     WARN: attr side-port absent -> ADD falls back to Color Key\r\n");
        if (g_bulm == BULM_FILL)
            bsp_printf("     FILL: solid %dx%d squares, no src/key/alpha -> cheapest op\r\n",
                       SZ_B, SZ_B);
        break;
    }
    case 'p': case 'P':
        if (g_state == GS_PLAY) { g_pause = !g_pause; bsp_printf("\r\nEV pause=%d\r\n", g_pause); }
        break;
    case 'r': case 'R':
        g_seed += 0x9E3779B9u; game_reset();
        bsp_printf("\r\nEV reset\r\n"); break;
    case 'd': case 'D':
        bsp_printf("\r\nEV diag: N=%d ON=%d HW=%d SW=%d SC=%d LV=%d HP=%d BOMB=%d\r\n",
                   g_ncap, g_on_screen, (int)g_hw_fps, (int)g_sw_fps, g_score, g_level,
                   g_hp, g_bomb);
        bsp_printf("     STATUS=%x COUNT=%d SCAN=%x FBSTAT=%x DRAW=%x CLR=%x clip=%x lut=%x\r\n",
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
                   (unsigned)blt_rd(BLT_FB_STAT), (unsigned)blt_rd(BLT_DRAW_SEL),
                   (unsigned)blt_rd(BLT_CLR_STAT), (unsigned)blt_rd(BLT_CLIP_CTRL),
                   (unsigned)blt_rd(BLT_LUT_CTRL));
        bsp_printf("     flipto=%d clr fb=%d to=%d err=%d stto=%d attr=%d glow=%d clipdrop=%d\r\n",
                   (int)g_flip_to, (int)g_clr_fb, (int)g_clr_to, (int)g_clr_err,
                   (int)g_stto, g_attr_on, g_glow, g_clip_drop);
        bsp_printf("     bulm=%s (req) %s (eff) alpha=%d | 16x16 70pct cap: FILL=%d ALPHA=%d KEY=%d\r\n",
                   g_bulm_name[g_bulm], bulm_eff_name(), (int)BUL_ALPHA_V,
                   (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 0),
                   (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 0),
                   (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 0));
        bsp_printf("     cap16 glow 70pct budget: single-lane %d, dual-lane %d sprites/frame\r\n",
                   (int)cost_capacity(DRAW_GLOW, SZ_B, 70, 0),
                   (int)cost_capacity(DRAW_GLOW, SZ_B, 70, 1));
        break;
    case '?':
        bsp_printf("\r\ncmd: 1/2/3/4=load presets N=256/640/1280/2400\r\n"
                   "     n or + =N+%d   - =N-%d   =N (line cmd, \\n) exact N %d..%d\r\n"
                   "     c=pure CPU path (compare fps)   h=HW accel path\r\n"
                   "     g=auto ramp (find the 60fps limit)  b=starfield  p=pause\r\n"
                   "     f=cycle enemy-bullet op, 5=FILL 6=ALPHA 7=ADD 8=KEY\r\n"
                   "     r=restart   d=diag line   ?=help\r\n"
                   "keys: send '@HH\\n' from the PC (NOT board buttons)\r\n"
                   "     bit0 up 1 down 2 left 3 right 4 fire 5 focus 6 bomb 7 pause\r\n"
                   "     W/Up A/Left S/Down D/Right  J/Space  K/Shift  L/X  P/Enter\r\n"
                   "pad: HW=hw fps SW=cpu fps N=cap ON=sprites SC=score LV HP OP=bullet op\r\n",
                   N_STEP, N_STEP, N_MIN, N_MAX);
        break;
    default: break;                                /* 其它字节静默忽略 */
    }
}

/* ============================== 串口命令处理 ============================== */
static void serial_apply_key(unsigned mask)
{
    unsigned old = g_keymask;
    g_keymask = mask;
    g_key_t = tick32();
    g_keys_live = 1;
    if ((mask & KEY_PAUSE) && !(old & KEY_PAUSE) && g_state == GS_PLAY) {
        g_pause = !g_pause;
        bsp_printf("\r\nEV pause=%d\r\n", g_pause);
    }
    if ((mask & KEY_BOMB) && !(old & KEY_BOMB)) g_bomb_req = 1;   /* 上升沿 */
}
static void serial_drain(void)
{
    int guard = 64;
    while (guard-- > 0) {
        int c = uart_poll_char();
        int kp, nl, ncmd = 0;
        unsigned mask = 0u;
        if (!c) break;
        kp = kp_feed(c, &mask);
        if (kp == KP_OK) { serial_apply_key(mask); continue; }
        if (kp != KP_NONE) continue;                  /* KP_MORE / KP_ERR：本函数已消费 */
        nl = nline_feed(c, &ncmd, N_MIN, N_MAX);
        if (nl == NL_OK) { g_ncap = ncmd; g_auto = 0; bsp_printf("\r\nEV N=%d\r\n", g_ncap); continue; }
        if (nl == NL_ERR) { bsp_printf("\r\nEV N=ERR\r\n"); continue; }
        if (nl == NL_MORE) continue;
        serial_cmd(c);                                /* ★ 单字符命令的唯一实现 */
    }
}

/* ============================== 主程序 ============================== */
#define ENGINE_TO_TICKS  (BSP_CLINT_HZ / 100u)     /* 等引擎的有界上界：10ms */
#define KEY_WD_TICKS     (BSP_CLINT_HZ / 2u)       /* 按键包看门狗：500ms */
#define ST_PERIOD_TICKS  (BSP_CLINT_HZ / 4u)       /* ST 状态行 4Hz */

/* 等引擎落空闲（有界 + 可恢复）。返回 0 = 超时（调用方走 blt_recover）。 */
static int wait_engine_idle(void)
{
    uint32_t t0 = tick32();
    uint32_t spin = 0;
    for (;;) {
        if ((spin & BLT_WAIT_MASK) == 0u) {
            if (blt_idle_st(blt_stat())) return 1;
            if ((uint32_t)(tick32() - t0) > (uint32_t)ENGINE_TO_TICKS) return 0;
        }
        spin++;
        cpu_backoff(BLT_WAIT_NOP);
    }
}
/* ★ 有界恢复：软复位引擎 + 重开本趟。
 *   没有这条路，任何一次硬件异常都会让屏幕永久冻结、串口命令循环被阻塞。 */
static void blt_recover(const char *why)
{
    g_stto++;
    bsp_printf("\r\nEV recover (%s) STATUS=%x COUNT=%d\r\n",
               why, (unsigned)blt_stat(), (unsigned)blt_cnt());
    blt_init();
    g_clr_need = 1;
    g_dl_i = 0;
    g_clr_fb++;
}

int main(int argc, char **argv)
{
    uint32_t it = 0;
    uint32_t t_now, t_st;
    int      frame_started = 0;
    int      back_busy = 0;
    uint32_t back_t0 = 0;
    int      repaint = 1;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */

    bsp_printf("\r\n===== GameDemo: high-load interactive danmaku, serial-controlled =====\r\n");
    bsp_printf("FB=%x BACK=%x BUF2=%x ATLAS=%x bytes=%d\r\n",
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)FB_BUF2,
               (unsigned)ATLAS_BASE, (int)ATLAS_BYTES);
    bsp_printf("playfield: x 0..%d  y %d..%d (info bar y<16 is CPU text)\r\n",
               FB_WIDTH, PLAY_Y0, PLAY_Y1);
    bsp_printf("publish: FLIP x3 (no full-screen COPY) + concurrent clear engine\r\n");
    bsp_printf("default: N=%d path=HW stars=%d sprites 16x16 glow + 32x32 keyed\r\n",
               g_ncap, g_star_n);
    bsp_printf("input: PC keyboard over UART 115200 -> '@'+2 hex digits+'\\n'\r\n");
    bsp_printf("       bit0 up 1 down 2 left 3 right 4 fire 5 focus 6 bomb 7 pause\r\n");
    bsp_printf("cmd: 1/2/3/4 presets, n/+/-/=N, c=CPU h=HW, g=auto-ramp, b, p, r, d, ?\r\n");
    bsp_printf("     f=cycle enemy-bullet op FILL/ALPHA/ADD/KEY (also 5/6/7/8)\r\n");

    /* ---- 图集：开机由 CPU 生成（引擎与 CPU 参考实现都从这里取数） ---- */
    {
        int id, i, j;
        for (id = 0; id < S_N; id++) {
            volatile uint16_t *p = (volatile uint16_t *)(ATLAS_BASE + g_spr_off[id]);
            int w = (int)g_spr_sz[id];
            for (j = 0; j < w; j++)
                for (i = 0; i < w; i++)
                    p[j * w + i] = spr_pixel(id, i, j);
        }
    }
    cache_evict();

    /* ---- 引擎与位流能力 ---- */
    blt_init();
    feat_probe();
    g_disp_sel = fb_stat_sel();                 /* 与实际在屏的缓冲对齐（重跑程序也安全） */
    g_draw3    = (int)((g_disp_sel + 1u) % 3u);
    g_clr3     = (int)((g_disp_sel + 2u) % 3u);
    g_clr_need = 1;
    g_fb_back  = fb_of_sel((uint32_t)g_draw3);

    /* ---- 三块缓冲各自铺一次底（此后背景由清屏引擎负责） ---- */
    stars_reset();
    {
        int k;
        uint32_t sv = g_fb_back;
        for (k = 0; k < 3; k++) {
            g_fb_back = fb_of_sel((uint32_t)k);
            cpu_fill32(g_fb_back, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
            g_bar_ok[k] = 0;
        }
        g_fb_back = sv;
    }
    g_flip_req = g_disp_sel;
    cache_evict();
    bsp_printf("publish: FLIPx3 (disp=%d draw=%d clr=%d)\r\n",
               (int)g_disp_sel, g_draw3, g_clr3);

    /* ---- 帧边界中断使能：翻转确认由扫描输出的场边界事件驱动（不依赖 trap） ---- */
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);
    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);

    /* ---- 开机自检：未对齐存储 / 精灵夹紧 / 属性字 / 定点混合 / 图集 / 信息条 / 帧预算 ---- */
    {
        uint16_t px0, px1;
        ent_t t;
        cpu_fill32(g_fb_back, 33, 500, 8, 2, 0xF800u);
        cpu_fill32(g_fb_back, 32, 502, 9, 2, 0x07E0u);
        px0 = *(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 33u * 2u);
        px1 = *(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 40u * 2u);
        bsp_printf("aligncheck %x %x (expect f800 07e0)\r\n", (unsigned)px0, (unsigned)px1);
        /* ent_clamp 的边界行为（与主机自检里跑的是同一份源码） */
        t.x = (int16_t)FP(-50); t.y = (int16_t)FP(PLAY_Y1 + 99); t.vx = 8; t.vy = 8;
        t.sz = SZ_B; t.r = 4; t.kind = S_B0; t.life = 1;
        ent_clamp(&t);
        bsp_printf("clampcheck x=%d y=%d vx=%d (expect 0 %d neg)\r\n",
                   PX(t.x), PX(t.y), (int)t.vx, PLAY_Y1 - SZ_B);
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x DL_VER=%x\r\n",
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
                   (unsigned)blt_rd(BLT_DL_VERSION));
    }
    boot_selfcheck();

    game_reset();
    g_state = GS_TITLE;
    osd_build();
    osd_blit();
    g_bar_ok[g_draw3] = 1;
    cache_evict();

    t_now = tick32(); g_t_fps = t_now; t_st = t_now;

    for (;;) {
        it++;

        /* ---------- 串口：每 4 圈一次（输入延迟 ≈ 几十 µs，远小于一帧） ---------- */
        if ((it & 3u) == 0u) {
            serial_drain();
            if ((it & 255u) == 0u) {
                t_now = tick32();
                /* 按键看门狗：500ms 没收到包 ⇒ 全部松开（标签切走/拔线都安全） */
                if (g_keys_live && (uint32_t)(t_now - g_key_t) > (uint32_t)KEY_WD_TICKS) {
                    g_keys_live = 0;
                    g_keymask = 0u;
                }
                /* 1Hz 帧率窗口：两个路径各记一个数，**都留在屏幕上** */
                if ((uint32_t)(t_now - g_t_fps) >= (uint32_t)BSP_CLINT_HZ) {
                    uint32_t el = (uint32_t)(t_now - g_t_fps);
                    int f_hw = (int)(((uint64_t)g_hw_frames * (uint64_t)BSP_CLINT_HZ) / el);
                    int f_sw = (int)(((uint64_t)g_sw_frames * (uint64_t)BSP_CLINT_HZ) / el);
                    int fps_now;
                    g_t_fps = t_now;
                    g_hw_frames = 0; g_sw_frames = 0;
                    if (g_mode == MD_HW) { g_hw_fps = (uint32_t)f_hw; fps_now = f_hw; }
                    else                 { g_sw_fps = (uint32_t)f_sw; fps_now = f_sw; }
                    /* ★ 自动爬坡：每秒一步（规则见 ramp_apply） */
                    {
                        int r = ramp_apply(fps_now, &g_ncap, &g_lim_n, &g_auto);
                        if (r == 1)
                            bsp_printf("\r\nEV ramp N=%d fps=%d\r\n", g_ncap, fps_now);
                        else if (r == 2)
                            bsp_printf("\r\nLIMIT N=%d fps=%d ON=%d (hit N_MAX)\r\n",
                                       g_lim_n, fps_now, g_on_screen);
                        else if (r < 0)
                            bsp_printf("\r\nLIMIT N=%d fps=%d ON=%d path=%s (max stable at 60fps)\r\n",
                                       g_lim_n, fps_now, g_on_screen, path_label());
                    }
                }
            }
        }

        /* ---------- 上一帧还在飞：等帧边界确认 ---------- */
        if (back_busy) {
            if ((it & BLT_WAIT_MASK) == 0u) {
                int flip_ev = 0;
                uint32_t irq = blt_rd(BLT_IRQ_STATUS);
                if (irq & BLT_IRQ_FRAME) { blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME); flip_ev = 1; }
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
                    int old_disp;
                    back_busy  = 0;
                    old_disp   = (int)g_disp_sel;
                    g_disp_sel = g_flip_req;
                    g_draw3    = g_clr3;
                    g_clr3     = old_disp;
                    g_clr_need = 1;
                    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
                    if (g_mode == MD_SW) g_sw_frames++; else g_hw_frames++;
                    frame_started = 0;                 /* 下一圈开新的一帧 */
                    /* ★ 4Hz 状态行：给上位机做记分板用。
                     *   为什么不每帧打：115200 下 ~87µs/字节是**阻塞**的（uart_write 等 TX 余量），
                     *   每帧一行的串口时间会直接吃掉帧预算。4Hz × ~48B ≈ 190B/s ≈ 1.7% CPU。 */
                    if ((uint32_t)(tick32() - t_st) >= (uint32_t)ST_PERIOD_TICKS) {
                        t_st = tick32();
                        bsp_printf("ST fps=%d n=%d on=%d sc=%d lv=%d hp=%d bm=%d md=%s\r\n",
                                   (g_mode == MD_SW) ? (int)g_sw_fps : (int)g_hw_fps,
                                   g_ncap, g_on_screen, g_score, g_level, g_hp, g_bomb,
                                   (g_mode == MD_SW) ? "SW" : "HW");
                    }
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
                    g_flip_to++;
                    if (g_flip_to == 1u)
                        bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
                                   (unsigned)blt_rd(BLT_FB_STAT));
                    blt_wr(BLT_FB_SEL, g_flip_req);    /* 重发请求，继续有界等待 */
                    back_t0 = tick32();
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
            } else {
                cpu_backoff(BLT_WAIT_NOP);
            }
            continue;
        }

        /* ---------- 本帧起点：推进一帧游戏 + 组清单 + 画信息条 ---------- */
        if (!frame_started) {
            game_tick();
            repaint = hw_pass_arm();
            build_draw_list(repaint);
            g_on_screen = dl_sprite_count();
            osd_build();
            osd_blit();
            g_bar_ok[g_draw3] = 1;
            g_dl_i = 0;
            frame_started = 1;
            continue;
        }

        /* ---------- 纯 CPU 对照路径：整帧由 CPU 画（诚实分母） ---------- */
        if (g_mode == MD_SW) {
            cpu_render_frame();
            overlay_draw();
            cache_evict();
            blt_wr(BLT_FB_SEL, (uint32_t)g_draw3);
            g_flip_req = (uint32_t)g_draw3;
            back_busy  = 1;
            back_t0    = tick32();
            continue;
        }

        /* ---------- 硬件路径：分块把本帧清单推进 FIFO ---------- */
        if (g_dl_i < g_dl_n) { push_chunk(); continue; }

        /* ---------- 清单推完：等引擎空闲（有界）→ 画中央字幕 → 请求翻转 ---------- */
        if (!wait_engine_idle()) { blt_recover("engine never went idle"); frame_started = 0; continue; }
        overlay_draw();                        /* ★ 必须等引擎画完再写，否则会被引擎覆盖 */
        cache_evict();
        blt_wr(BLT_FB_SEL, (uint32_t)g_draw3);
        g_flip_req = (uint32_t)g_draw3;
        back_busy  = 1;
        back_t0    = tick32();
    }
    return 0;
}
