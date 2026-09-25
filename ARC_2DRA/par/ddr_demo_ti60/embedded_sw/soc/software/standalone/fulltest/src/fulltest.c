/* =========================================================================
 * fulltest.c — 2DRA BitBlt 加速器裸机端到端测试 v2.2（批量下发路径修复版）
 * -------------------------------------------------------------------------
 * 链路：RISC-V(软核, 裸机) --APB slave0--> BitBlt 引擎寄存器(BLT_BASE)
 *       引擎 --AXI 主设备--> DDR3（精灵区 / 帧缓冲）
 *       DDR3 帧缓冲 --> fb_scanout --> TMDS --> HDMI
 *
 * v2.1 -> v2.2 只动「[7] 多精灵压测」与「[demo] 无限演示」的下发/等待/诊断路径；
 * [5]/[6] 的 17 项功能测试与最终汇总格式一字未改（4 项 ALPHA FAIL 是 RTL 已知
 * 问题，期望值不许改）。修复内容（对应上板日志
 *   "stress frame: timeout! STATUS=0x1 FIFO_COUNT=30 / eng/frm=0 / 画面残影"）：
 *   ① **一条指令不可能再被拆断**：全文件唯一的 FIFO 写入口 blt_emit_cmd() 只有
 *      8 条无条件 store（反汇编可核对：中间没有任何条件分支），所有边界检查/
 *      看门狗/超时判断都在调用点之前，即只可能落在两条指令之间；检查失败时
 *      这条指令一个字都不写（整条丢弃），FIFO 仍停在整条指令边界上。
 *   ② **任何中止都不留半条指令**：超时/ERR/丢字/熔断统一走 op_fail() ->
 *      blt_restore_boundary()：先打印现场，再看 FIFO 是否在整条指令边界上，
 *      不干净就 SOFT_RST 清 FIFO+引擎并复查；清不干净才熔断。
 *   ③ **超时打印完整现场**：本帧已推入条数/累计条数/帧号/档位、STATUS 逐位、
 *      CMD_FIFO_COUNT（条，并折算字数）、FIFO_EMPTY、最后一条完整下发的
 *      op/src/dst/w/h、引擎 DBG_CUR_CMD，以及"引擎大约卡在第几条"。
 *      注意 CMD_FIFO_COUNT 的单位是**指令条数**（= floor(word_count/8)，见
 *      rtl/cmd_fifo.v 的 cmd_count 与 userDef.h），不是字数：30 表示 30 条
 *      已排队指令（约 240~247 字），不能读成"3 条 + 6 个残字"；
 *      字级残量（1..7 个字）唯一的证据是 COUNT==0 且 FIFO_EMPTY==0。
 *   ④ **eng/frm=0 修好**：记账帧不再因为本档出过错被跳过；且必须"逐条等 DONE
 *      再读 BLT_PERF"求和（批量连推时读到的是陈旧值甚至 0）；PERF 读回 0 的
 *      样本单独计数，表格用 '!' / '?' 标注，不再显示成 0。
 *   ⑤ **默认退回"逐条下发 + 每条等 DONE"**（STRESS_BATCH_PUSH 默认 0），
 *      批量实现保留为开关（置 1 启用），先把画面与压测跑对。
 *   ⑥ 帧末哨兵/丢字检测保留，但只在引擎 IDLE 的**稳定态**判，并把采样在时间上
 *      拉开（busy_loop 间隔 + 连续 N 次），不再因 POP 期间的瞬时窗口误报。
 *   ⑦ [5]/[6] 的 17 项与汇总格式未动。
 *
 * v2.0 -> v2.1 只动「[7] 多精灵压测」与「[demo] 无限演示」；[5]/[6] 功能测试与最终
 * 汇总格式一字未改（它们是功能正确性证据，8 项已知 RTL bug 的 FAIL 保持原样）。
 * 优化针对实测结论「cpu/frm ≈ 4 × eng/frm，瓶颈在 CPU 侧」，每项都留了编译期开关
 * 便于上板 A/B（[7] 开头的配置行会打印本轮实际生效的取值）：
 *   ① STRESS_BATCH_PUSH：一帧的 2N+1 条指令**连推**，只在跨批边界查一次
 *      CMD_FIFO_COUNT（旧路径是每条指令前都读一次 COUNT）。
 *      批大小×8 字 + 开批残留上限 << 2048 字 → **永远写不到 FIFO 满**，绕开 RTL 的 full bug。
 *   ② STRESS_EVICT_MODE / CACHE_EVICT_WORDS：每帧冲刷 / 按需冲刷 / 每 N 帧冲刷三态，
 *      冲刷缓冲字数可缩小（默认仍 8KB=2048 字；可改 1088 字=4KB+64B，由 [3] 自检兜底）。
 *   ③ 一帧只等一次 DONE（帧末），帧内不读 PERF（eng/frm 由每档末尾的「记账帧」采样求和）；
 *      并删掉旧路径里每次等 DONE 后的 busy_loop(200) 稳定延时（同一时钟域，无 CDC 需求）。
 *   ④ STRESS_ERASE_MODE：逐精灵 FILL / 旧∪新包围盒一次 FILL / 帧首整屏 FILL 三态对照。
 *   ⑤ 帧末 1 条 1x1 FILL 哨兵 + 回读校验：端到端证明"本帧指令全部执行"；配合
 *      帧末（引擎 IDLE、状态稳定时）的 COUNT/FIFO_EMPTY 残字判定与跨批双看门狗，
 *      RTL 即使丢字也能在软件侧发现并熔断，不把正确性押在硬件上。
 *
 * 串口输出顺序（每一步都打印，任何等待都有 tick 上限，超时打印错误而不是死等）：
 *   [1] banner：程序名/版本 + 各地址宏 + FB 规格 + 冲刷缓冲字数
 *   [2] CLINT 时间基准自检
 *   [3] 缓存一致性自检（CPU 写 -> cache_evict -> invalidate -> 回读比对）
 *   [4] 引擎寄存器探测（全 0/全 F -> APB 未接通，跳过后续）+ blt_init()
 *   [5] 联通性：最小 FILL + 指令 FIFO 不丢指令（2×300 条突发：带 COUNT 等待 / 裸写靠 APB 反压）
 *   [6] A. FILL 边界 / B. COPY 边界 / C. KEY 边界 / D. ALPHA 金标准 + α 扫描
 *   [7] 多精灵压测：N = 25/50/100/200/400/800 逐档 60 帧 -> 60fps 同屏精灵上限表
 *       （新增 ins/frm 列、evict% 列，以及 MAX 档的 eng/cpu/冲刷占比与理论上限）
 *   [8] 汇总 ========== fulltest ALL PASS ========== / FAILED: n
 *   [demo] 之后进入简化版无限演示（HDMI 保持动画，程序不再返回；已在打印里说明）
 *
 * 硬性纪律（都是踩过的坑，务必保持）：
 *   ① 不用 csr_read(mcycle)：这颗 SoC 上读 mcycle 会触发非法指令异常直接死机；
 *      时间基准一律用 CLINT mtime（clint_getTime(BSP_CLINT)，100MHz）。
 *   ② CPU 写完精灵/源数据/背景 -> 引擎（外部主设备）要读它：必须先 cache_evict()
 *      （顺序写 CACHE_EVICT_WORDS 个字到 FLUSH_SCRATCH，作为 store 有序屏障；
 *       实测该 SoC 的 D$ tag 无 dirty 位=写穿，所以它不承担"回写脏行"的职责）。
 *       CPU 一个字都没写过的那一帧不需要冲（压测默认 STRESS_EVICT_MODE=1 即按此执行）。
 *   ③ 引擎写完 DDR -> CPU 要回读校验：回读前必须 data_cache_invalidate_all()
 *      （D$ 无 dirty 位，invalidate 只丢干净副本，因此任何时刻调用都安全）。
 *   ④ bsp_printf 只支持 %c %s %d %x %X（没有 %u）：无符号量一律转 (int)。
 *   ⑤ 不依赖 libc（freestanding），循环/比较全部手写。
 *   ⑥ 引擎寄存器探测若为全 0 / 全 F 视为 APB 未接通：只提示并跳过，不反复写。
 *   ⑦ 任何等待都有 tick 上限；连续 3 次引擎超时/ERR 就熔断（g_blt_alive=0），避免 ×2s 串行死等。
 *   ⑧ 压测不把正确性押在硬件上：FIFO 永远写不到满、跨批双看门狗、帧末在引擎 IDLE
 *      的稳定状态校验 DONE && COUNT==0 && FIFO_EMPTY（并有残字判丢字），
 *      再用 1x1 FILL 哨兵像素做端到端确认。
 *
 * 关键硬件行为假设（与 rtl/blt_*.v 对齐，测试正是围绕它们设计）：
 *    H1 dst 行首非 16B 对齐时，首词只写有效 lane（AXI WSTRB 字节掩码），
 *       **行首之前的字节保留目的原值**（A2/C4/D4 专门验证）。
 *    H2 行尾不足 16B 的词只写有效字节（B3 宽 13 专门验证）。
 *    H3 KEY：源像素 == 键色则整像素不写（掩码为 0 时连写事务都不发），
 *       所以整行键色时目的一个字节都不改（C2 用梯度值验证）。
 *    H4 ALPHA 读目的当前内容作为背景，且是 8bit 通道展开后混合（D1..D4）。
 *    H5 PERF = 上一条指令从 POP 到 WDWAIT 结束的引擎时钟周期数（引擎与 CLINT 同源 100MHz）。
 *    H6 CMD_FIFO_COUNT = floor(字级 FIFO 占用/8)（rtl/cmd_fifo.v）：COUNT==0 并不代表
 *       字级为空（可能有 1..7 个残字），所以帧末判空必须同时看 STATUS.FIFO_EMPTY。
 * ========================================================================= */
#include <stdint.h>
#include "bsp.h"               /* 已含 soc.h / uart.h / clint.h / print.h */
#include "userDef.h"
#include "vexriscv.h"          /* data_cache_invalidate_all() */

/* ======================= 参数 ======================= */
#define TICK_HZ            BSP_CLINT_HZ          /* CLINT 100MHz：1 tick ≈ 1 个 CPU 周期 */
#define FRAME_TICKS        (TICK_HZ / 60)        /* ~60fps 的每帧节流周期 */
#define BLT_TIMEOUT_TICKS  200000000UL           /* 单条指令等待上限 2s，超时打印错误而不是死等 */
#define BLT_FAST_TICKS     (TICK_HZ / 5u)        /* 压测档位用的短超时 0.2s，故障时不长时间挂住 */
#define BLT_PICKUP_GUARD   2000UL                /* 极短指令专用：DONE 已高且等待超过它即视为完成 */
#define BLT_SETTLE_LOOPS   200UL                 /* 读寄存器前的少量稳定延时（跨时钟域同步） */
#define MAX_MIS_PRINT      8                     /* 每个测试最多打印多少条失配明细 */
#define BLT_FIFO_HIWATER   200u                  /* 指令 FIFO 深度 256：>=200 条就先等引擎消费 */
#define SENT               0x1234u               /* 「绝不能被改写」的哨兵像素值 */

/* ======================= [7] 压测优化开关（上板 A/B 对比用） =======================
 * 全部是编译期宏，改一个就能单独量化一项优化的收益；[7] 开头的配置行会把当前
 * 取值打进串口，避免"忘了这轮跑的是哪套开关"。
 *
 *  v2.0 老路径的每指令 CPU 开销（实测 ≈ 3800 ticks/条，N=200 时 cpu/frm 是 eng/frm 的 4 倍）：
 *    8 次 APB 写 + 1 次 CMD_FIFO_COUNT 轮询 + DONE 轮询(STATUS+COUNT+CLINT)
 *    + busy_loop(BLT_SETTLE_LOOPS=200) 稳定延时 + 1 次 PERF 读
 *  v2.1 默认全开：一帧连推 + 帧末只等一次 DONE + 帧内不读 PERF + 按需冲刷。
 * ------------------------------------------------------------------------- */
/* v2.2：**默认退回「逐条下发 + 每条等 DONE」**（批量实现保留为开关，置 1 可再启用）。
 * 为什么默认关（上板实测 + 代码结构两条理由）：
 *   ① 批量下发时 CPU **不等 DONE**，在"引擎 BUSY、FIFO 里还有货"的状态下继续灌指令。
 *      上板日志（N=25 第 7 帧）卡死：STATUS=0x1(BUSY) + CMD_FIFO_COUNT=30 直到超时。
 *      一旦 FIFO 里的字流出现字级残量/错位，后续指令就整体按错误的 8 字边界译码
 *      （画面不动物块残影 = 部分擦除 FILL 被算到错误位置或被跳过），而错位发生在
 *      硬件内部，软件无法回溯"是哪一条被拆断了"；
 *   ② 逐条等 DONE 时 FIFO 里最多只有 1 条指令，每条指令都是
 *      "引擎 IDLE -> 边界检查 -> 连续写 8 字 -> 等 DONE"的闭环，
 *      不存在"上一条没做完就灌下一条"的窗口；再配合每帧开头的整条指令边界检查
 *      （blt_frame_begin）与任何中止后的 SOFT_RST 清 FIFO（blt_restore_boundary），
 *      "一条指令被拆断 / 残字留给引擎"在结构上不可能发生（见 blt_emit_cmd 的说明）。
 *   ③ 批量路径的现场诊断已经补齐（卡住时打印 op/dst/w/h + COUNT + DBG_CUR_CMD），
 *      修好之后再置 1 做 A/B 对比即可。
 * 代价：cpu/frm 变大、fps 下降（每条多一次 COUNT 查询 + 一次 DONE 等待），所以默认
 * 档位的 [7] 表格数字代表"最保守路径"的 CPU 侧开销，不代表引擎能力上限。 */
#define STRESS_BATCH_PUSH      0   /* 1=一帧指令连推(仅跨批查一次 COUNT) 0=逐条下发 + 每条等 DONE */
#define STRESS_PUSH_BATCH      160 /* 每批最多连推的指令条数（×8 字 = 1280 字，FIFO 共 2048 字） */
#define STRESS_BATCH_HEADROOM  48  /* 开新批时允许 FIFO 里残留的指令条数（<=48 条 = <=384 字） */
                                   /* 最坏占用 384+1280 = 1664 < 2048：写到满的路只在极端情况经过 */
#define STRESS_WD_TICKS        (TICK_HZ / 2u)      /* 跨批等待总上限 0.5s（硬看门狗，绝不死等） */
#define STRESS_WD_STALL_TICKS  (TICK_HZ / 10u)     /* COUNT 连续 100ms 不下降 -> 判引擎异常 */
#define STRESS_FRAME_TO_TICKS  (TICK_HZ / 2u)      /* 帧末 DONE 等待上限 0.5s（60fps 预算的 30 倍） */
#define STRESS_LOST_N          4                   /* 引擎 IDLE 时连续 N 次都看到残留字 -> 判丢字 */

#define STRESS_EVICT_MODE      1   /* 0=每帧冲刷(v2.0 老路径) 1=只在必要时(本压测=每档一次) 2=每 N 帧 */
#define STRESS_EVICT_EVERY     8   /* 模式 2 的 N */
#define CACHE_EVICT_WORDS      FLUSH_WORDS
                                   /* 冲刷缓冲字数：2048=8KB（最稳）；改 1088=4KB+64B 可省一半
                                    * 时间，正确性由 [3] 一致性自检 + [6] 全部边界测试兜底。
                                    * 依据（netlist 实证）：本 SoC 的 VexRiscv DataCache 的 tag
                                    * 只有 {valid, error, address[31:12]} 三个字段，**没有 dirty 位**
                                    * → D$ 是写穿(write-through)的，任何时刻都不存在"脏行"，
                                    * cache_evict() 真正起的作用是"把 CPU 的 store 按序推出去"
                                    * （store buffer / 桥的发泄屏障），不是回写脏数据。
                                    * 所以压测帧内 CPU 完全不写 DDR 时，一帧都不冲也是安全的。 */

#define STRESS_ERASE_MODE      0   /* 0=每精灵 1 条 FILL 擦旧矩形 1=旧∪新包围盒一次 FILL(仅 N>=100 档启用) */
                                   /* 2=帧首 1 条整屏 FILL 回填，精灵不再擦除（大 N 对照宏） */
#define STRESS_BBOX_MINN       100 /* 模式 1 只对 N >= 该值的档位生效（小 N 时包围盒反而更贵） */
#define STRESS_SENTINEL        1   /* 1=每帧末尾插 1 条 1x1 FILL 哨兵并回读校验（丢字/异常可发现） */
#define STRESS_PERF_EACH       0   /* 1=帧内逐条读 PERF(v2.0) 0=只在每档末尾的"记账帧"里逐条读 */

/* ---------- 测试数据在精灵区的落点（互不重叠） ---------- */
#define SA_COPY   (SPRITE_BASE + 0x00001000UL)   /* B1 源 32x8  stride 64 */
#define SA_COPYB  (SPRITE_BASE + 0x00002000UL)   /* B2 源（含 x=3 非对齐入口） */
#define SA_KEY    (SPRITE_BASE + 0x00003000UL)   /* C1 源 16x8  stride 32 隔像素键色 */
#define SA_ALPHA  (SPRITE_BASE + 0x00005000UL)   /* D1/D2/D3 源 16x8 stride 32 */
#define SA_KEYROW (SPRITE_BASE + 0x00006000UL)   /* C2 源 16x4 全键色 */
#define SA_SPR    (SPRITE_BASE + 0x00007000UL)   /* C3 源 32x32 键色边框实心块 */
#define SA_KEYUN  (SPRITE_BASE + 0x00008000UL)   /* C4 源 16x8 */
#define SA_ALPH4  (SPRITE_BASE + 0x00009000UL)   /* D4 源 1 像素 x 6 α，stride 32 */
#define SA_LINK   (SPRITE_BASE + 0x0000A000UL)   /* [5] 联通性最小 FILL */
#define SA_ATLAS  (SPRITE_BASE + 0x00010000UL)   /* [7] 8 张精灵图集，每张 0x800 */
#define ATLAS_SLOT 0x800UL
#define ATLAS_STRIDE 64UL                        /* 32 像素/行 × 2B */

/* ---------- [5] 联通性 ---------- */
#define LINK_W 16
#define LINK_H 8
#define LINK_COLOR 0xF800UL                      /* 红 */

/* ---------- [5] FIFO 突发（不丢指令） 300 条 1x1 FILL ---------- */
#define BURST_N     300
#define BURST_COLS  20
#define BURST_X     600
#define BURST_Y     400

/* ---------- [7] 压测 ---------- */
#define STRESS_BG      0x0010u                   /* 整屏背景：深蓝（= C_DBLUE） */
#define STRESS_NSLOT   8                         /* 图集里的精灵种类数 */
#define STRESS_MAXN    800                       /* 最大同屏精灵数（档位上限） */
#define STRESS_FRAMES  60                        /* 每档帧数 */
#define STRESS_NRUNG   6
#define STRESS_DEMO_N  12                        /* [demo] 无限演示的同屏精灵数 */

/* 哨兵像素：FB1 里 A/B/C/D 四组测试用到 y<=370，这里取最后一行靠右的角落，
 * 既不与任何测试矩形重叠，也不在 HDMI 扫描的 FB 上。每帧末尾用一条 1x1 FILL
 * 写它，等完 DONE 再回读 —— 这是"本帧指令确实全部执行了"的端到端证据。 */
#define SA_SENT  PIX(FB1_BASE, FB_STRIDE, 900, 530)

/* 擦除策略文案（[7] 开头的配置行 + 指令口径说明） */
#if (STRESS_ERASE_MODE == 0)
#define STRESS_ERASE_TAG   "每精灵 1 条 FILL 擦旧矩形"
#define STRESS_INS_FORMULA "稳态 ins/frm = 2N+1（N 擦除 + N blit + 1 哨兵）"
#elif (STRESS_ERASE_MODE == 1)
#define STRESS_ERASE_TAG   "擦除=旧∪新包围盒一次 FILL（N>=STRESS_BBOX_MINN 档生效）"
#define STRESS_INS_FORMULA "稳态 ins/frm = 2N+1（指令数同 0，但 FILL 覆盖面积更大）"
#else
#define STRESS_ERASE_TAG   "帧首 1 条整屏 FILL 回填，精灵不再擦除（大 N 对照）"
#define STRESS_INS_FORMULA "稳态 ins/frm = N+2（1 整屏 FILL + N blit + 1 哨兵）"
#endif

/* ======================= 全局状态 ======================= */
static int g_blt_alive = 1;      /* APB 窗口/引擎是否可用（[4]/[5] 判定，失败可熔断） */
static int g_fail      = 0;      /* 失败的测试项计数（用于汇总） */
static int g_mis       = 0;      /* 当前测试的失配像素数 */
static int g_mis_shown = 0;      /* 当前测试已打印的失配明细条数 */
static int g_eng_errs  = 0;      /* 引擎超时/ERR 次数（>3 熔断） */
static int g_tb_ok     = 1;      /* [2] 时间基准是否可用（不可用就关掉帧节流） */
static uint32_t g_perf    = 0;   /* 最近一条指令的引擎周期数（BLT_PERF） */
static uint32_t g_opticks = 0;   /* 最近一条指令「下发 -> DONE」的 tick 差 */
static uint32_t g_wait_to = BLT_TIMEOUT_TICKS;  /* 当前等待上限（压测档位会临时调小） */

/* 像素地址：base + y*stride + x*2（RGB565，2 字节/像素） */
#define PIX(base, stride, x, y) ((base) + (uint32_t)(y) * (stride) + (uint32_t)(x) * 2u)

/* ======================= 基础工具 ======================= */
static uint64_t tick(void)
{
    return clint_getTime(BSP_CLINT);          /* 只读 MMIO，绝不会异常 */
}

/* 空循环防优化：返回累加值供调用方打印（顺便证明循环没被编译器删掉） */
static uint32_t busy_loop(uint32_t n)
{
    volatile uint32_t sink = 0;
    while (n--) sink += n;
    return sink;
}

static void wr16(uint32_t addr, uint16_t v)
{
    *(volatile uint16_t *)addr = v;
}

static uint16_t rd16(uint32_t addr)
{
    return *(volatile uint16_t *)addr;
}

static void blt_wr(uint32_t off, uint32_t val)
{
    *(volatile uint32_t *)(BLT_BASE + off) = val;
}

static uint32_t blt_rd(uint32_t off)
{
    return *(volatile uint32_t *)(BLT_BASE + off);
}

/* CPU 直接填充矩形（16bit 写）：准备测试数据 / 画精灵 / 引擎不可用时的兜底 */
static void fill_rect_cpu(uint32_t base, uint32_t stride, int x, int y, int w, int h, uint16_t color)
{
    int i, j;
    for (j = 0; j < h; j++) {
        uint32_t row = base + (uint32_t)(y + j) * stride + (uint32_t)x * 2u;
        for (i = 0; i < w; i++)
            wr16(row + (uint32_t)i * 2u, color);
    }
}

/* 把 CPU 刚写的数据按序推给外部主设备（引擎）可见：顺序写 CACHE_EVICT_WORDS 个字到
 * FLUSH_SCRATCH。默认 2048 字 = 8KB。
 * 实证（netlist 反查 EfxSapphireSoc.v 里的 DataCache）：tag 只有 {valid,error,address}，
 * 没有 dirty 位 → D$ 写穿，不存在脏行；这个函数的真正作用是"store 有序发泄屏障"。
 * 因而不变量是：**CPU 写过 DDR 之后、引擎要读之前**必须调用（顺序保证）；
 * 反过来，CPU 一个字都没写过的那一帧不需要冲（见 STRESS_EVICT_MODE=1 的说明）。
 * 想省时间可把 CACHE_EVICT_WORDS 改成 1088（4KB+64B），正确性由 [3] 一致性自检 +
 * [6] 全部回读比对兜底 —— 上板 A/B 时看 [3] 是否仍 PASS。 */
static void cache_evict(void)
{
    volatile uint32_t *scratch = (volatile uint32_t *)FLUSH_SCRATCH;
    uint32_t i;
    for (i = 0; i < (uint32_t)CACHE_EVICT_WORDS; i++)
        scratch[i] = 0xA5A50000UL + i;
}

/* 带计时的冲刷：用来在压测里统计 cache_evict 占每帧时间的比例 */
static uint32_t cache_evict_timed(void)
{
    uint64_t t0 = tick();
    cache_evict();
    return (uint32_t)(tick() - t0);
}

/* 回读校验前的准备：作废整个 D$，强制后续读走 DDR */
static void cache_invalidate(void)
{
    data_cache_invalidate_all();
}

/* ======================= 失配明细 ======================= */
static void mis_reset(void)
{
    g_mis = 0;
    g_mis_shown = 0;
}

static void expect_px(int x, int y, uint32_t got, uint32_t exp)
{
    if (got == exp) return;
    g_mis++;
    if (g_mis_shown < MAX_MIS_PRINT) {
        g_mis_shown++;
        bsp_printf("      mismatch (x=%d,y=%d) got=0x%x exp=0x%x\r\n",
                   x, y, (int)got, (int)exp);
    }
}

/* 整块比对：base+stride 上 [x,x+w) × [y,y+h) 必须全等于 exp */
static void chk_rect(uint32_t base, uint32_t stride, int x, int y, int w, int h, uint32_t exp)
{
    int i, j;
    for (j = 0; j < h; j++)
        for (i = 0; i < w; i++)
            expect_px(x + i, y + j, rd16(PIX(base, stride, x + i, y + j)), exp);
}

/* 图案比对：期望值 = pat + j*rowmul + i（i/j 相对矩形左上角） */
static void chk_pat(uint32_t base, uint32_t stride, int x, int y, int w, int h,
                    uint32_t pat, uint32_t rowmul)
{
    int i, j;
    for (j = 0; j < h; j++)
        for (i = 0; i < w; i++)
            expect_px(x + i, y + j, rd16(PIX(base, stride, x + i, y + j)),
                      pat + (uint32_t)j * rowmul + (uint32_t)i);
}

/* 严格比对「带洞」的哨兵区：整个 [x,x+w)×[y,y+h) 内，除子矩形 (ix,iy,iw,ih)
 * 之外的每一个像素都必须等于 exp。用来证明引擎没有多写哪怕一个像素。 */
static void chk_outside(uint32_t base, uint32_t stride, int x, int y, int w, int h,
                        int ix, int iy, int iw, int ih, uint32_t exp)
{
    int i, j;
    for (j = 0; j < h; j++) {
        for (i = 0; i < w; i++) {
            int ax = x + i, ay = y + j;
            if (ax >= ix && ax < ix + iw && ay >= iy && ay < iy + ih) continue;
            expect_px(ax, ay, rd16(PIX(base, stride, ax, ay)), exp);
        }
    }
}

/* ======================= 8bit 通道展开 + ALPHA 参考模型 =======================
 * 与 rtl/pixel_path.v 完全一致（不是"近似"）：
 *   exp5(v) = (v<<3)|(v>>2)      5bit -> 8bit（位复制：v4v3v2v1v0 v4v3v2）
 *   exp6(v) = (v<<2)|(v>>4)      6bit -> 8bit
 *   out_r8  = (fr8*α + br8*(255-α) + 127) >> 8         （三通道各算一遍）
 *   回写 RGB565 = {r8[7:3], g8[7:2], b8[7:3]}          （直接截高位）
 * 用 0xFFFF/0x0000/α=128 校验过：得到 0x7BEF（与硬件金标准一致）。 */
static uint32_t exp5(uint32_t v) { return (v << 3) | (v >> 2); }
static uint32_t exp6(uint32_t v) { return (v << 2) | (v >> 4); }

static uint32_t alpha_ref(uint32_t fg, uint32_t bg, uint32_t a)
{
    uint32_t fr  = exp5((fg >> 11) & 0x1Fu);
    uint32_t fgc = exp6((fg >> 5) & 0x3Fu);
    uint32_t fb  = exp5(fg & 0x1Fu);
    uint32_t br  = exp5((bg >> 11) & 0x1Fu);
    uint32_t bgc = exp6((bg >> 5) & 0x3Fu);
    uint32_t bb  = exp5(bg & 0x1Fu);
    uint32_t ai  = 255u - a;
    uint32_t r8  = (fr  * a + br  * ai + 127u) >> 8;
    uint32_t g8  = (fgc * a + bgc * ai + 127u) >> 8;
    uint32_t b8  = (fb  * a + bb  * ai + 127u) >> 8;
    return ((r8 >> 3) << 11) | ((g8 >> 2) << 5) | (b8 >> 3);
}

static uint32_t ch_r(uint32_t p) { return (p >> 11) & 0x1Fu; }
static uint32_t ch_g(uint32_t p) { return (p >> 5)  & 0x3Fu; }
static uint32_t ch_b(uint32_t p) { return p & 0x1Fu; }

/* ======================= 引擎驱动 ======================= */
static void blt_init(void)
{
    /* 复位引擎 -> 清 DONE 中断标志 -> 写一次 GO（之后引擎自动消费指令 FIFO）。
     * 注意：CTRL 的 bit1 与 0x14 都写 IRQ_EN，这里用轮询，所以保持关中断。 */
    blt_wr(BLT_IRQ_EN, 0);
    blt_wr(BLT_IRQ_STATUS, 1);            /* W1C 清 DONE */
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);  /* SOFT_RST：1 拍脉冲 */
    busy_loop(BLT_SETTLE_LOOPS);
    blt_wr(BLT_CTRL, 0);
    blt_wr(BLT_IRQ_STATUS, 1);
    blt_wr(BLT_CTRL, BLT_CTRL_GO);        /* 写一次即可 */
    busy_loop(BLT_SETTLE_LOOPS);
}

/* 指令 FIFO 满的处理（双保险，两条路都保证不丢指令）：
 *   (a) 这里显式读 CMD_FIFO_COUNT：>= BLT_FIFO_HIWATER(200/256) 就先等引擎消费，
 *       留 56 条余量，一条指令 8 个字必然装得下；
 *   (b) 真正写满时 rtl/blt_apb_top.v 的 AXI-Lite 桥会把 awready/wready 拉低、
 *       PREADY 不拉高，CPU 的 store 自然停顿（APB 反压），一个字都不会丢。
 * 返回 0=有空间 / -2=引擎 ERR / -1=等超时。
 * 注意：这个检查必须**在写之前**做——卡在满 FIFO 的 MMIO store 上时 CPU 无法用 tick
 * 超时自救，所以宁可放弃这条指令也不能盲写。 */
static int blt_fifo_room(void)
{
    uint64_t t0 = tick();

    while (blt_rd(BLT_CMD_FIFO_COUNT) >= BLT_FIFO_HIWATER) {
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;   /* 引擎 ERR：不会消费了 */
        if ((uint32_t)(tick() - t0) > BLT_TIMEOUT_TICKS) return -1;
    }
    return 0;
}

/* ======================= 下发现场与统计（诊断用） =======================
 * 这些量只用于"出错时能说清楚卡在哪一条指令上"，不参与任何功能判定。
 * 一条指令的 8 个字一旦开写就必须写完，所以"当前指令"的现场是在**写完之后**
 * 记录的：任何现场打印出来的 op/dst/w/h 一定是最后一条**完整**进入 FIFO 的
 * 指令，绝不会是半条（半条压根不会存在）。 */
typedef struct {
    uint32_t op, src, dst, sstride, dstride, w, h, alpha, color;
} blt_cmd_t;

static blt_cmd_t g_last_cmd;        /* 最后一条完整写入 FIFO 的指令（现场） */
static uint32_t  g_last_seq  = 0;   /* 它在本帧内的序号（1 起） */
static uint32_t  g_ins_frame = 0;   /* 本帧已完整推入 FIFO 的指令条数（ins/frm） */
static uint32_t  g_ins_total = 0;   /* 累计推入条数（跨帧，用于现场打印） */
static uint32_t  g_frame_no  = 0;   /* [7] 当前帧序号（stress_frame 写入） */
static uint32_t  g_rung_n    = 0;   /* [7] 当前档位 N（stress_frame 写入） */
static int       g_scene_ctx = 0;   /* 1=当前在 [7] 压测帧内 / 0=[5][6] 的单条指令操作 */

/* 一条指令 = BLT_CMD_WORDS 个字。下面这个函数硬编码 8 条 store，宏改了必须同步改。 */
#if (BLT_CMD_WORDS != 8)
#error "blt_emit_cmd() hardcodes 8 words: BLT_CMD_WORDS changed, update it in sync"
#endif

/* =========================================================================
 * 全文件**唯一**的指令 FIFO 写入口：一次调用 = 一条完整指令 = 连续 8 个字。
 * 「一条指令永远不会被拆断」由这个函数的结构保证（改它之前请读这段）：
 *   ① 函数体里只有 8 条 store（经 blt_wr —— 一个"只做一条 volatile store"的
 *      叶子函数发出）：**没有任何条件分支**，唯一的控制流就是这 8 次调用和
 *      结尾的 ret。这一点可以直接用反汇编核对（-Og 下实测就是
 *      8×(li a0,8 + jalr blt_wr) + 现场赋值 + ret，中间没有一条 beq/bne/blt/bge/j）
 *      —— 既没有检查、也没有"提前退出"的点，编译器无法在这里插桩；
 *   ② 所有边界检查（blt_fifo_room / blt_batch_ready）、看门狗、tick 超时判断
 *      都在**调用点之前**完成，只可能落在两条指令之间；一条指令的内部没有任何
 *      可被打断的检查点，所以"检查把一条指令打断"在结构上不存在；
 *   ③ 8 条 store 无条件执行：FIFO 真满时由 rtl/blt_regs_axi_lite.v 的
 *      awready/wready 反压把 CPU 停在这一条 store 上（fifo_wr_en 与握手同拍，
 *      满时既不握手也不丢字），不存在"跳过某一个字"的路径；
 *   ④ 唯一的"中止"发生在调用点之前的检查失败时，那时**一个字都还没写**，
 *      FIFO 依然停在整条指令边界上（见 push_cmd_fast 的 ①/② 顺序）。
 * 于是 FIFO 里的字流永远是"整条指令 × n"，引擎的 8 字边界不可能错位。
 * ========================================================================= */
static void blt_emit_cmd(uint32_t op, uint32_t src, uint32_t dst, uint32_t sstride,
                         uint32_t dstride, uint32_t w, uint32_t h, uint32_t alpha,
                         uint32_t color)
{
    blt_wr(BLT_CMD_FIFO_DATA, op);
    blt_wr(BLT_CMD_FIFO_DATA, src);
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    blt_wr(BLT_CMD_FIFO_DATA, sstride);
    blt_wr(BLT_CMD_FIFO_DATA, dstride);
    blt_wr(BLT_CMD_FIFO_DATA, ((h & 0xFFFFUL) << 16) | (w & 0xFFFFUL));
    blt_wr(BLT_CMD_FIFO_DATA, alpha & 0xFFUL);
    blt_wr(BLT_CMD_FIFO_DATA, color & 0xFFFFUL);

    /* ---- 到这里 8 个字已全部进入 FIFO，才允许记录现场/计数 ---- */
    g_last_cmd.op      = op;       g_last_cmd.src     = src;
    g_last_cmd.dst     = dst;      g_last_cmd.sstride = sstride;
    g_last_cmd.dstride = dstride;  g_last_cmd.w       = w;
    g_last_cmd.h       = h;        g_last_cmd.alpha   = alpha;
    g_last_cmd.color   = color;
    g_ins_total++;
}

/* 带 FIFO 空间检查（正常路径）：**检查在前**，没空间就一条都不下发并返回失败 */
static int blt_push_cmd(uint32_t op, uint32_t src, uint32_t dst, uint32_t sstride,
                        uint32_t dstride, uint32_t w, uint32_t h, uint32_t alpha,
                        uint32_t color)
{
    int room = blt_fifo_room();                 /* 只在两条指令之间做 */
    if (room != 0) return room;                 /* 失败：一个字都没写，边界干净 */
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);   /* 连续 8 字 */
    return 0;
}

/* 不带空间检查（专门用来压 APB 反压）：FIFO 满时靠桥反压停顿，同样 8 字连续写 */
static void blt_push_cmd_raw(uint32_t op, uint32_t src, uint32_t dst, uint32_t sstride,
                             uint32_t dstride, uint32_t w, uint32_t h, uint32_t alpha,
                             uint32_t color)
{
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);
}

/* ======================= 整条指令边界 / 现场打印 / 中止恢复 =======================
 * 「整条指令边界」判据：只在引擎 IDLE（STATUS.DONE=1）的**稳定态**判 ——
 * rtl/cmd_fifo.v 是"同步读 + 输出寄存器"结构，引擎 POP 期间存在
 * word_count>=8 但 empty=1 的瞬时窗口，那时读寄存器做判断会误报。
 * 注意 CMD_FIFO_COUNT 的单位是**完整指令条数**（= floor(word_count/8)，
 * 见 rtl/cmd_fifo.v 的 cmd_count 与 userDef.h 的注释），不是字数；字级残量
 * （1..7 个字）唯一的证据是 COUNT==0 且 FIFO_EMPTY==0。
 * 返回 1=干净 / 0=不干净（含引擎还在跑、ERR、有残字）。 */
static int blt_fifo_clean(void)
{
    uint32_t st  = blt_rd(BLT_STATUS);
    uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);

    if (st & BLT_STATUS_ERR) return 0;            /* 引擎停机：不算干净 */
    if (!(st & BLT_STATUS_DONE)) return 0;        /* 还在跑/POP：状态不稳，不能判 */
    return (cnt == 0u && (st & BLT_STATUS_FIFO_EMPTY)) ? 1 : 0;
}

/* 出错现场：一次把定位需要的量全打出来（旧代码只有一行 timeout!）。
 *   ① 本帧已完整推入多少条 / 累计多少条 / 帧号 / 档位；
 *   ② STATUS 逐位 + CMD_FIFO_COUNT（条）+ 折算字数 + FIFO_EMPTY + 字级残量推断；
 *   ③ 最后一条完整下发的指令（op/dst/w/h/src）与引擎侧的 DBG_CUR_CMD；
 *   ④ 由"已推入条数 − FIFO 剩余条数"估出引擎正卡在第几条，直接指着嫌疑指令。 */
static void blt_print_scene(const char *tag, int rc)
{
    uint32_t st  = blt_rd(BLT_STATUS);
    uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    uint32_t dw  = blt_rd(BLT_DBG_CUR_CMD);
    int      busy = (st & BLT_STATUS_BUSY) ? 1 : 0;
    int      done = (st & BLT_STATUS_DONE) ? 1 : 0;
    int      err  = (st & BLT_STATUS_ERR) ? 1 : 0;
    int      emp  = (st & BLT_STATUS_FIFO_EMPTY) ? 1 : 0;
    int      residual  = (cnt == 0u && !emp) ? 1 : 0;

    if (rc == -2)
        bsp_printf("      %s: engine ERR! STATUS=0x%x -> SOFT_RST 复位\r\n", tag, (int)st);
    else if (rc == -3)
        bsp_printf("      %s: FIFO 状态矛盾/丢字! STATUS=0x%x COUNT=%d FIFO_EMPTY=%d -> SOFT_RST 复位\r\n",
                   tag, (int)st, (int)cnt, emp);
    else
        bsp_printf("      %s: timeout! STATUS=0x%x FIFO_COUNT=%d\r\n", tag, (int)st, (int)cnt);

    bsp_printf("        现场: BUSY=%d DONE=%d ERR=%d FIFO_EMPTY=%d | CMD_FIFO_COUNT=%d 条(=floor(字数/8)，约 %d~%d 字) -> %s\r\n",
               busy, done, err, emp, (int)cnt, (int)(cnt * 8u), (int)(cnt * 8u + 7u),
               residual ? "有 1~7 个残字（半条指令）" : "字级边界干净");
    if (g_scene_ctx) {
        int stuck_ins = ((int)g_ins_frame - (int)cnt > 0) ? ((int)g_ins_frame - (int)cnt + 1) : 1;
        bsp_printf("        本帧已完整推入 %d 条（累计 %d 条），帧号=%d 档位 N=%d，FIFO 还剩 %d 条 -> 引擎大约卡在第 %d 条\r\n",
                   (int)g_ins_frame, (int)g_ins_total, (int)g_frame_no, (int)g_rung_n,
                   (int)cnt, stuck_ins);
    } else {
        bsp_printf("        本条操作已完整下发 %d 条（单条指令操作，不属于压测帧），累计 %d 条，FIFO 还剩 %d 条\r\n",
                   (int)g_ins_frame, (int)g_ins_total, (int)cnt);
    }
    bsp_printf("        最后完整下发: #%d op=0x%x src=0x%x dst=0x%x ss=%d ds=%d w=%d h=%d alpha=%d color=0x%x\r\n",
               (int)g_last_seq, (int)g_last_cmd.op, (int)g_last_cmd.src, (int)g_last_cmd.dst,
               (int)g_last_cmd.sstride, (int)g_last_cmd.dstride,
               (int)g_last_cmd.w, (int)g_last_cmd.h, (int)g_last_cmd.alpha,
               (int)g_last_cmd.color);
    bsp_printf("        引擎 DBG_CUR_CMD=0x%x（引擎正在执行的指令 op=0x%x；BUSY=1 时为它卡住的那条）\r\n",
               (int)dw, (int)(dw & 3u));
}

/* 中止之后必须把 FIFO 拉回「整条指令边界」再继续，绝不能把残字留给引擎：
 *   - 已经是干净边界（引擎 IDLE + COUNT==0 + FIFO_EMPTY=1）：什么都不做；
 *   - 否则（BUSY 卡住 / 还有指令 / 有残字）：SOFT_RST 清指令 FIFO + 引擎 FSM
 *     （rtl/blt_top.v: int_rst_n = rst_n & ~soft_rst，FIFO/引擎/读写主机一起复位），
 *     再回来确认。**留 1~7 个残字是最坏的情况**：下一条指令会补上这个缺口，
 *     引擎从此按错误的 8 字边界译码，后面所有指令全部错位。
 * 返回 0=边界已干净 / -1=清不干净（调用方应熔断，别再往下推指令）。 */
static int blt_restore_boundary(const char *tag)
{
    int k;

    if (blt_fifo_clean()) return 0;               /* 常见情形：本来就在边界上 */

    bsp_printf("      %s: FIFO 不在整条指令边界(STATUS=0x%x COUNT=%d FIFO_EMPTY=%d) -> SOFT_RST 清 FIFO/引擎\r\n",
               tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
               (int)((blt_rd(BLT_STATUS) & BLT_STATUS_FIFO_EMPTY) ? 1 : 0));
    blt_init();                                   /* SOFT_RST -> CTRL=0 -> 清 IRQ -> GO */

    for (k = 0; k < 8; k++) {                     /* 复位后确认边界确实干净 */
        if (blt_fifo_clean()) {
            bsp_printf("      %s: SOFT_RST 后边界已干净（STATUS=0x%x COUNT=%d FIFO_EMPTY=1）\r\n",
                       tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT));
            return 0;
        }
        busy_loop(BLT_SETTLE_LOOPS);
    }
    bsp_printf("      %s: SOFT_RST 后 FIFO 仍不干净（STATUS=0x%x COUNT=%d FIFO_EMPTY=%d）\r\n",
               tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
               (int)((blt_rd(BLT_STATUS) & BLT_STATUS_FIFO_EMPTY) ? 1 : 0));
    return -1;
}

/* =========================================================================
 * [7] 批量下发 / 帧级同步（v2.2：默认逐条等 DONE，批量实现留给开关）
 * -------------------------------------------------------------------------
 * 【默认路径 STRESS_BATCH_PUSH=0：逐条下发 + 每条等 DONE（最保守）】
 *   一条指令 = "查一次空间 -> 连续写 8 字 -> 等 DONE -> 稳态复查 FIFO 边界"，
 *   FIFO 里最多只有 1 条指令，引擎不存在"边跑边被灌"的窗口。
 *   所有会中断的地方都只可能落在**两条指令之间**，所以任何一条指令要么整条
 *   进去、要么一个字都不进去（详见 blt_emit_cmd / push_cmd_fast）。
 *
 * 【批量路径 STRESS_BATCH_PUSH=1：一帧连推，只在跨批边界查一次 COUNT】
 *   批大小 160 条 = 1280 字，开批条件 COUNT<=48 条（<=384 字），最坏占用
 *   1664/2048 字，正常不会写到 FIFO 满；一帧只等一次 DONE。
 *   默认关掉的原因见文件开头 STRESS_BATCH_PUSH 的说明（上板出现过错位卡死）。
 *
 * 【三道防线：正确性不押在 RTL 上】
 *   ① 帧首 blt_frame_begin()：新一帧必须在"整条指令边界"开始，上一帧的残字/
 *      卡死在这里就被拦住（旧的"COUNT<=HEADROOM 就放行"会把残字传染给下一帧）；
 *   ② 逐条路径每条指令等完 DONE 后做 blt_boundary_after_cmd()：引擎 IDLE 的
 *      稳态下 FIFO 必须整条干净，硬件丢字（残留 1..7 个字）当场发现 -> SOFT_RST；
 *      批量路径由帧末 blt_wait_frame_done() 统一判（同样只在 IDLE 稳态判，
 *      并把采样在时间上拉开，避免 POP 期间的瞬时窗口误报）；
 *   ③ 任何中止（超时/ERR/丢字/熔断）都走 op_fail -> blt_restore_boundary()：
 *      先把 FIFO 拉回整条指令边界（必要时 SOFT_RST 清 FIFO+引擎），
 *      绝不把残字留给引擎 —— 残字 + 下一条指令 = 引擎从此按错误的 8 字边界
 *      译码（画面不动物块残影的来源）；
 *   ④ 帧末 1x1 FILL 哨兵像素回读：端到端确认"本帧指令确实全部执行了"。
 * ========================================================================= */
static int      g_push_err   = 0;   /* 本帧下发阶段的异常码（0 正常） */
static uint32_t g_sent_seq   = 0;   /* 哨兵像素的期望值序列（每帧 +1，保证每帧不同色） */
/* 注：g_ins_frame / g_last_cmd / g_ins_total 等现场量在「引擎驱动」一节声明
 * （blt_emit_cmd 是唯一写入口，它要记录现场，所以声明必须在它之前）。 */
static int      g_push_left  = 0;   /* 批量路径：当前批还能连推多少条 */
static int      g_push_batch = STRESS_BATCH_PUSH;  /* 本帧是否走批量路径（记账帧恒为 0） */
static int      g_push_acct  = 0;   /* 1=本帧是"记账帧"：逐条等 DONE + 逐条读 PERF */
static uint32_t g_perf_sum   = 0;   /* 记账帧：逐条 BLT_PERF 累加（有效样本） */
static uint32_t g_perf_good  = 0;   /* 记账帧：有效采样条数（PERF != 0） */
static uint32_t g_perf_zero  = 0;   /* 记账帧：PERF 读回 0/异常的条数（表里标注，不当 0 求和） */

/* 一个"静默且一致"的 FIFO 状态：COUNT<=HEADROOM。**只在 STRESS_BATCH_PUSH=1 的
 * 批量路径的跨批边界调用**（一帧最多十几次），绝不在指令流中间调用。
 * 注意：这里**不做** COUNT 与 FIFO_EMPTY 的一致性判断 —— rtl/cmd_fifo.v 是
 * "同步读 + 输出寄存器"结构，引擎 POP 期间会出现 out_v=0 而 mcnt!=0 的瞬时窗口
 * （word_count>=8 但 empty=1），此时读寄存器做一致性判断会误报。真正的
 * "丢字/整条指令边界"判定放在帧末或逐条等完 DONE 之后（引擎 IDLE 时状态稳定，
 * 见 blt_wait_frame_done / blt_boundary_after_cmd）。
 * 返回 0=可以开批 / -1=等超时 / -2=引擎 ERR / -3=COUNT 长时间不下降。 */
static int blt_batch_ready(void)
{
    uint64_t t0 = tick();
    uint64_t t_drop = t0;
    uint32_t last = 0xFFFFFFFFUL;
    int first = 1;

    for (;;) {
        uint32_t st  = blt_rd(BLT_STATUS);
        uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);

        if (st & BLT_STATUS_ERR) return -2;
        if (cnt <= (uint32_t)STRESS_BATCH_HEADROOM) return 0;

        if (first || cnt < last) { last = cnt; t_drop = tick(); first = 0; }
        if ((uint32_t)(tick() - t_drop) > (uint32_t)STRESS_WD_STALL_TICKS)
            return -3;                                     /* 引擎长时间不消费：判异常 */
        if ((uint32_t)(tick() - t0) > (uint32_t)STRESS_WD_TICKS)
            return -1;
    }
}

/* 帧末只等一次 DONE。同一时钟域，APB 读就是当拍快照，不需要 v2.0 的 busy_loop(200) 延时。
 * 判定：DONE && COUNT==0 && FIFO_EMPTY。
 *   - DONE 高 ⟹ 引擎 FSM 在 IDLE ⟹ 此时 FIFO 无 POP 活动、状态稳定，
 *     所以这一刻读到的 COUNT/FIFO_EMPTY 才是可信的（POP 期间的空闲标志有瞬时抖动）；
 *   - DONE 只要求"FIFO 里不足 8 字"，半条指令（丢字/失步）时 DONE 仍然是 1，
 *     但 COUNT==0 且 FIFO_EMPTY==0 -> 残留字数，连续 STRESS_LOST_N 次都这样即判丢字。
 * 返回 0=完成 / -1=超时 / -2=引擎 ERR / -3=有残留字（疑似丢字）。 */
static int blt_wait_frame_done(uint32_t timeout_ticks)
{
    uint64_t t0 = tick();
    uint32_t st, cnt;
    int residual = 0;

    for (;;) {
        st  = blt_rd(BLT_STATUS);
        cnt = blt_rd(BLT_CMD_FIFO_COUNT);

        if (st & BLT_STATUS_ERR) return -2;

        if (st & BLT_STATUS_DONE) {                       /* 引擎 IDLE：只有这里状态稳定 */
            if (cnt == 0u && (st & BLT_STATUS_FIFO_EMPTY)) return 0;
            /* DONE 高但 FIFO 不干净：可能真的残留 1..7 个字（丢字/半条指令的典型
             * 特征），也可能是"刚 push 完、引擎还没接手"的瞬态。为了不误报：
             * 每个样本之间插入 BLT_SETTLE_LOOPS 稳定延时把采样在**时间上拉开**，
             * 并要求连续 STRESS_LOST_N 个这样的样本 —— 瞬态窗口只有 1 拍，
             * 不可能连续 N 次跨过延时都被撞上，而真残留是稳态、必然被抓到。 */
            residual++;
            if (residual >= STRESS_LOST_N) return -3;
            busy_loop(BLT_SETTLE_LOOPS);
        } else {
            residual = 0;                                 /* 引擎在跑/POP：状态不稳，不判 */
        }

        if ((uint32_t)(tick() - t0) > timeout_ticks) return -1;
    }
}

/* 帧首同步：新一帧必须在「整条指令边界」（引擎 IDLE + FIFO 空）上开始。
 * 比旧的"COUNT <= HEADROOM 就放行"严格得多 —— 旧判据即使 FIFO 里还剩半条指令
 * 也会放行，于是上一帧的异常会以"残字"的形式传染给下一帧，让整帧的指令错位。
 * 返回 0=可以开帧 / -2=引擎 ERR / -1=超时（有指令/残字清不掉）。 */
static int blt_frame_begin(void)
{
    uint64_t t0 = tick();

    for (;;) {
        if (blt_fifo_clean()) return 0;                   /* 稳态干净：直接开帧 */
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;
        if ((uint32_t)(tick() - t0) > (uint32_t)STRESS_FRAME_TO_TICKS) return -1;
        busy_loop(BLT_SETTLE_LOOPS);                      /* 采样拉开：等引擎把上一帧做完 */
    }
}

/* 前向声明：push_cmd_fast 的"逐条/记账"路径要在写完 8 字之后等 DONE，
 * 而 blt_wait_done 定义在本函数之后。 */
static int blt_wait_done(uint32_t timeout_ticks);

/* 逐条路径每次等完 DONE 之后的收尾检查：此刻引擎已经 IDLE，是**稳态**，
 * 所以"COUNT==0 且 FIFO_EMPTY==1"可以放心地当判据（POP 期间的瞬时窗口不存在了）。
 * 这是"字级丢字"的最后一道防线：硬件若丢了一个字，FIFO 里会剩 1~7 个残字，
 * 下一条指令会去补这个缺口 → 引擎从此按错误的 8 字边界译码（画面残影）。
 * 这里当场发现（返回 -3），交给 op_fail 打印现场 + SOFT_RST 清残字，
 * 绝不让它传染给后面的指令。只在逐条等 DONE 的路径调用；批量路径由帧末
 * blt_wait_frame_done 统一判。
 * 返回 0=边界干净 / -3=有残字或 COUNT 与 FIFO_EMPTY 矛盾。 */
static int blt_boundary_after_cmd(void)
{
    int k;
    for (k = 0; k < 4; k++) {                 /* 多次采样，避免撞上 1 拍瞬态 */
        if (blt_fifo_clean()) return 0;
        busy_loop(BLT_SETTLE_LOOPS);
    }
    return -3;
}

/* 下发一条指令（压测路径）。三条硬性纪律，顺序不能换：
 *   ① 边界检查只发生在**两条指令之间**（逐条路径=写前查一次空间；批量路径=
 *      只在跨批边界查一次 COUNT）。检查失败时**一个字都不写**，FIFO 停在整条
 *      指令边界上，这条指令被整条丢弃而不是写一半 —— 这是"永不拆断"的关键；
 *   ② 检查通过后调用 blt_emit_cmd()：8 个字无条件连续写完，中间没有检查点；
 *   ③ 逐条路径（默认 STRESS_BATCH_PUSH=0）或记账帧：写完立刻等 DONE，保证
 *      FIFO 里最多只有 1 条指令，引擎不存在"边跑边被灌"的窗口；批量路径不等
 *      DONE，由帧末的 blt_wait_frame_done 统一等一次。
 * 异常只记录在 g_push_err，由调用方统一处理（含边界恢复）。 */
static void push_cmd_fast(uint32_t op, uint32_t src, uint32_t dst, uint32_t sstride,
                          uint32_t dstride, uint32_t w, uint32_t h, uint32_t alpha,
                          uint32_t color)
{
    int rc = 0;
    int wait_each;

    if (g_push_err) return;                     /* 本帧已中止：后面一条都不再写 */

    /* ---------- ① 边界检查（永远在两条指令之间） ---------- */
    if (g_push_batch && !g_push_acct) {
        if (g_push_left <= 0) {                 /* 批量路径：只在跨批边界查一次 */
            rc = blt_batch_ready();
            if (rc == 0) g_push_left = STRESS_PUSH_BATCH;
        }
    } else {
        rc = blt_fifo_room();                   /* 逐条路径/记账帧：写之前查一次空间 */
    }
    if (rc != 0) { g_push_err = rc; return; }    /* 失败：一个字都没写，边界干净 */

    /* ---------- ② 一条指令的 8 个字：无条件连续写完（唯一写入口） ---------- */
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);

    /* ---------- ③ 记账/计数（写完之后） ---------- */
    if (g_push_batch && !g_push_acct) g_push_left--;
    g_ins_frame++;
    g_last_seq = g_ins_frame;

    /* ---------- ④ 需要时在"下一条指令之前"等 DONE / 采 PERF ---------- */
    wait_each = (!g_push_batch || g_push_acct) ? 1 : 0;
    if (wait_each) {
        rc = blt_wait_done(g_wait_to);
        if (rc != 0) { g_push_err = rc; return; }
        rc = blt_boundary_after_cmd();          /* 引擎 IDLE 稳态：FIFO 必须整条干净 */
        if (rc != 0) { g_push_err = rc; return; }
        if (g_push_acct) {
            /* 逐条等完 DONE 再读 PERF，读到的才是这条指令的周期数
             * （PERF = 上一条指令 POP->WDWAIT 的引擎周期，见 H5）。
             * 批量连推时 PERF 是好几条之前的陈旧值甚至还是 0 —— 那是旧代码
             * eng/frm=0 的直接原因。读回 0 视为无效样本，单独计数并在表里标注。 */
            uint32_t p = blt_rd(BLT_PERF);
            if (p == 0u) g_perf_zero++;
            else { g_perf_sum += p; g_perf_good++; }
        }
    }
}

/* 等 DONE。STATUS.DONE 是电平（= FIFO 空且引擎空闲），所以：
 *   - 先等"引擎确实接手了这条指令"（BUSY 起来或 FIFO 里还有指令），
 *     否则刚 push 完立刻读可能还看到上一次的 DONE=1，造成假通过；
 *   - 再看 DONE=1 判定完成；
 *   - 极短指令（读到时已经跑完）用 PICKUP_GUARD 兜底。
 * 返回 0=完成 / -1=超时 / -2=引擎 ERR（停机，需 SOFT_RST）。 */
static int blt_wait_done(uint32_t timeout_ticks)
{
    uint64_t t0 = tick();
    uint32_t st, cnt, el;
    int seen = 0;

    for (;;) {
        st  = blt_rd(BLT_STATUS);
        cnt = blt_rd(BLT_CMD_FIFO_COUNT);

        if (st & BLT_STATUS_ERR) return -2;

        if (!(st & BLT_STATUS_DONE) || cnt != 0u)
            seen = 1;                          /* 引擎已接手 / FIFO 还有货 */
        else if (seen) {
            busy_loop(BLT_SETTLE_LOOPS);       /* 让 PERF/STATUS 的跨时钟域同步跟上 */
            return 0;
        }

        el = (uint32_t)(tick() - t0);
        if (!seen && el > BLT_PICKUP_GUARD) {  /* DONE 已高且等待足够久：认为已完成 */
            busy_loop(BLT_SETTLE_LOOPS);
            return 0;
        }
        if (el > timeout_ticks) return -1;
    }
}

/* 操作失败统一处理：打印**完整现场**、记熔断计数，并把 FIFO/引擎拉回整条指令边界。
 * 任何中止（超时/ERR/丢字）都必须走这里：残字绝不允许留给引擎 —— 下一条指令会
 * 去补那个缺口，引擎从此按错误的 8 字边界译码（画面残影的直接来源）。 */
static int op_fail(int rc, const char *tag)
{
    if (rc == 0) return 0;
    g_eng_errs++;

    blt_print_scene(tag, rc);              /* 现场：本帧条数/COUNT/STATUS/最后一条指令 */

    /* 中止前先把 FIFO 拉回整条指令边界（干净就不动，脏就 SOFT_RST 清掉） */
    if (blt_restore_boundary(tag) != 0) {
        if (g_blt_alive) {
            g_blt_alive = 0;
            bsp_printf("      %s: 边界清不干净 -> 熔断，跳过后续引擎测试\r\n", tag);
        }
    }

    if (g_eng_errs > 3 && g_blt_alive) {
        g_blt_alive = 0;
        bsp_printf("      引擎连续失败 %d 次 -> 熔断：跳过后续引擎测试（不再每条等 2s）\r\n",
                   g_eng_errs);
    }
    return rc;
}

/* 下发一条指令 + 等 DONE + 抓 PERF/耗时。返回 0 表示成功且 PERF 有效。
 * [5]/[6] 与档位背景用的都是"单条指令"操作：这里把现场上下文标成"非压测帧"，
 * 这样出错打印的现场不会把上一帧 [7] 的计数当成这一条的。 */
static int blt_op(uint32_t op, uint32_t src, uint32_t dst, uint32_t ss, uint32_t ds,
                  uint32_t w, uint32_t h, uint32_t alpha, uint32_t color)
{
    uint64_t t0 = tick();
    uint32_t ec;
    int rc;

    g_scene_ctx = 0;
    g_ins_frame = 0;
    g_last_seq  = 0;
    rc = blt_push_cmd(op, src, dst, ss, ds, w, h, alpha, color);   /* 内含 FIFO 空间检查 */
    if (rc == 0) { g_ins_frame = 1; g_last_seq = 1; }
    if (rc == 0) rc = blt_wait_done(g_wait_to);
    ec = (uint32_t)(tick() - t0);
    g_opticks = ec;
    g_perf    = (rc == 0) ? blt_rd(BLT_PERF) : 0u;
    return rc;
}

static int blt_fill(uint32_t dst, uint32_t dstride, uint32_t w, uint32_t h, uint32_t color)
{
    return blt_op(BLT_OP_FILL, 0u, dst, 0u, dstride, w, h, 0xFFu, color);
}

static int blt_copy(uint32_t src, uint32_t dst, uint32_t sstride, uint32_t dstride,
                    uint32_t w, uint32_t h)
{
    return blt_op(BLT_OP_COPY, src, dst, sstride, dstride, w, h, 0xFFu, 0u);
}

static int blt_key(uint32_t src, uint32_t dst, uint32_t sstride, uint32_t dstride,
                   uint32_t w, uint32_t h, uint32_t key)
{
    return blt_op(BLT_OP_KEY, src, dst, sstride, dstride, w, h, 0xFFu, key);
}

static int blt_alpha(uint32_t src, uint32_t dst, uint32_t sstride, uint32_t dstride,
                     uint32_t w, uint32_t h, uint32_t alpha)
{
    return blt_op(BLT_OP_ALPHA, src, dst, sstride, dstride, w, h, alpha, 0u);
}

/* ======================= 单项结论行 ======================= */
/* 每项一行：名称 + PERF + 失配数 + PASS/FAIL。mis<0 表示引擎层面失败（超时/ERR）。 */
static int item(const char *name, uint32_t perf, int mis)
{
    if (mis != 0) g_fail++;
    if (mis < 0)
        bsp_printf("  %s  PERF=%d  -> FAIL (engine timeout/ERR, 见上)\r\n",
                   name, (int)perf);
    else
        bsp_printf("  %s  PERF=%d  mis=%d  -> %s\r\n",
                   name, (int)perf, mis, mis ? "FAIL" : "PASS");
    return mis != 0;
}

/* 引擎已熔断：直接记 FAIL 并跳过，避免每条都等超时 */
#define SKIP_IF_DEAD(name)                                        \
    do {                                                          \
        if (!g_blt_alive) { item(name, 0u, -1); return; }          \
    } while (0)

/* 帧节流：先测量完本帧真实耗时，再由调用方决定是否补足到 FRAME_TICKS。
 * 时间基准异常时直接不节流（否则会退化成空转死等）。 */
static void frame_throttle(uint64_t t_frame)
{
    uint32_t guard = 0;
    if (!g_tb_ok) return;
    while ((uint32_t)(tick() - t_frame) < FRAME_TICKS) {
        if (++guard > 20000000UL) break;      /* 兜底：时间基准抽风也不死等 */
    }
}

/* ======================= [3] 缓存一致性自检 ======================= */
/* 写模式 -> 挤出 D$ -> 作废 D$ -> 从 DDR 回读比对（用 FB1，不动上屏画面）。
 * 返回 0=PASS，否则返回第一个不一致的字序号+1。 */
static int coherency_check(void)
{
    volatile uint32_t *p = (volatile uint32_t *)FB1_BASE;
    uint32_t i;

    for (i = 0; i < 256u; i++) p[i] = 0x5A5A0000UL + i;
    cache_evict();
    cache_invalidate();
    for (i = 0; i < 256u; i++)
        if (p[i] != (0x5A5A0000UL + i)) return (int)(i + 1u);
    return 0;
}

/* =========================================================================
 * [6a] A. FILL 边界测试
 * ========================================================================= */

/* A1：16B 对齐的常规 FILL 32x16，四周留哨兵确认没写出去 */
static void tf_a1(void)
{
    SKIP_IF_DEAD("A1 FILL 32x16 aligned @FB1(0,0)");

    bsp_printf("  A1: FILL 32x16 -> FB1(0,0) color=0x%x，四周哨兵 0x%x（dst 16B 对齐）\r\n",
               (int)C_GREEN, (int)SENT);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 0, 40, 18, (uint16_t)SENT);   /* 32x16 + 右侧/下方哨兵 */
    cache_evict();

    if (op_fail(blt_fill(FB1_BASE, FB_STRIDE, 32u, 16u, C_GREEN), "A1 FILL")) {
        item("A1 FILL 32x16 aligned @FB1(0,0)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_rect(FB1_BASE, FB_STRIDE, 0, 0, 32, 16, C_GREEN);           /* 目标块全绿 */
    chk_outside(FB1_BASE, FB_STRIDE, 0, 0, 40, 18, 0, 0, 32, 16, SENT);  /* 右侧/下方哨兵 */
    item("A1 FILL 32x16 aligned @FB1(0,0)", g_perf, g_mis);
}

/* A2：dst 起点奇数像素（x=3 -> 字节偏移 6，非 16B 对齐）。
 * 验证 H1：行首之前的 3 个像素必须保留原值；行尾词不足部分也必须保留。 */
static void tf_a2(void)
{
    SKIP_IF_DEAD("A2 FILL 32x16 @x=3 (dst unaligned)");

    bsp_printf("  A2: FILL 32x16 -> FB1(3,40) color=0x%x（行首字节偏移 6，px_skip=3，覆盖读改写）\r\n",
               (int)C_GREEN);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 39, 40, 18, (uint16_t)SENT);  /* x0..39, y39..56 */
    cache_evict();

    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 3, 40), FB_STRIDE, 32u, 16u, C_GREEN), "A2 FILL")) {
        item("A2 FILL 32x16 @x=3 (dst unaligned)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_rect(FB1_BASE, FB_STRIDE, 3, 40, 32, 16, C_GREEN);   /* 目标块 */
    /* 带洞哨兵：行首左侧 x=0,1,2（首词未写 lane）、行尾右侧 x=35..39（尾词未写 lane）、
     * 以及上下相邻两行，全部必须原样 = H1 的直接证据 */
    chk_outside(FB1_BASE, FB_STRIDE, 0, 39, 40, 18, 3, 40, 32, 16, SENT);
    item("A2 FILL 32x16 @x=3 (dst unaligned)", g_perf, g_mis);
}

/* A3：整屏 960x540 FILL 到 FB_BASE（HDMI 扫描的那块），抽验 4 角 + 中心 + 越界哨兵 */
static void tf_a3(void)
{
    uint32_t p_perf;
    SKIP_IF_DEAD("A3 FILL fullscreen 960x540 -> FB");

    bsp_printf("  A3: FILL 整屏 %dx%d -> FB_BASE(0x%x) color=0x%x（4 角+中心+末尾越界哨兵）\r\n",
               FB_WIDTH, FB_HEIGHT, (int)FB_BASE, (int)STRESS_BG);

    /* 紧贴缓冲区末尾之后的 2 个像素放哨兵：确认整屏 FILL 不越界写 */
    wr16(FB_BASE + FB_BYTES, (uint16_t)SENT);
    wr16(FB_BASE + FB_BYTES + 2u, (uint16_t)SENT);
    cache_evict();

    if (op_fail(blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG), "A3 FILL fullscreen")) {
        item("A3 FILL fullscreen 960x540 -> FB", 0u, -1);
        return;
    }
    p_perf = g_perf;
    cache_invalidate();
    mis_reset();
    expect_px(0, 0, rd16(PIX(FB_BASE, FB_STRIDE, 0, 0)), STRESS_BG);
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), STRESS_BG);
    expect_px(0, FB_HEIGHT - 1, rd16(PIX(FB_BASE, FB_STRIDE, 0, FB_HEIGHT - 1)), STRESS_BG);
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), STRESS_BG);
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), STRESS_BG);
    expect_px(FB_WIDTH / 2, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, 0)), STRESS_BG);
    expect_px(0, FB_HEIGHT / 2, rd16(PIX(FB_BASE, FB_STRIDE, 0, FB_HEIGHT / 2)), STRESS_BG);
    expect_px(FB_WIDTH, FB_HEIGHT, rd16(FB_BASE + FB_BYTES), SENT);          /* 越界哨兵 */
    expect_px(FB_WIDTH + 1, FB_HEIGHT, rd16(FB_BASE + FB_BYTES + 2u), SENT);

    /* 引擎周期 vs CPU 实测 tick：两者同源 100MHz，可直接对比 */
    bsp_printf("      PERF=%d cycles, CPU 侧下发到 DONE=%d ticks（含轮询/APB 开销）\r\n",
               (int)p_perf, (int)g_opticks);
    item("A3 FILL fullscreen 960x540 -> FB", p_perf, g_mis);
}

/* A4：退化尺寸——宽 1 像素的竖条 + 高 1 像素的横条 */
static void tf_a4(void)
{
    uint32_t pc, pr;
    SKIP_IF_DEAD("A4 FILL degenerate 1x64 & 200x1");

    /* (a) 竖条：1 像素宽 × 64 高，x=500,y=10；左右与上下留哨兵 */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 498, 8, 6, 68, (uint16_t)SENT);   /* x498..503, y8..75 */
    cache_evict();
    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 500, 10), FB_STRIDE, 1u, 64u, C_RED), "A4 col")) {
        item("A4 FILL degenerate 1x64 & 200x1", 0u, -1);
        return;
    }
    pc = g_perf;

    /* (b) 横条：200 像素宽 × 1 高，x=10,y=300（行首字节偏移 4 -> 非 16B 对齐，尾词只写 4 字节） */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 8, 298, 204, 5, (uint16_t)SENT);  /* x8..211, y298..302 */
    cache_evict();
    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 10, 300), FB_STRIDE, 200u, 1u, C_YELLOW), "A4 row")) {
        item("A4 FILL degenerate 1x64 & 200x1", pc, -1);
        return;
    }
    pr = g_perf;

    cache_invalidate();
    mis_reset();
    /* (a) 竖条：目标 1 像素宽 x64 高，四周（含左右各 1/3 列与上下 2 行）必须原样 */
    chk_rect(FB1_BASE, FB_STRIDE, 500, 10, 1, 64, C_RED);
    chk_outside(FB1_BASE, FB_STRIDE, 498, 8, 6, 68, 500, 10, 1, 64, SENT);
    /* (b) 横条：目标 200x1，其余（含行首左侧 2 像素、行尾右侧 2 像素）必须原样 */
    chk_rect(FB1_BASE, FB_STRIDE, 10, 300, 200, 1, C_YELLOW);
    chk_outside(FB1_BASE, FB_STRIDE, 8, 298, 204, 5, 10, 300, 200, 1, SENT);

    bsp_printf("      竖条 PERF=%d cycles / 横条 PERF=%d cycles（横条行首偏移 4B，尾词只写 4B）\r\n",
               (int)pc, (int)pr);
    item("A4 FILL degenerate 1x64 & 200x1", pc + pr, g_mis);
}

/* =========================================================================
 * [6b] B. COPY 边界测试
 * ========================================================================= */

/* B1：常规 COPY，src/dst stride 不同（64 vs 1920），图案每像素唯一便于定位 */
static void tb1(void)
{
    int i, j;
    SKIP_IF_DEAD("B1 COPY 32x8 src(stride 64)->FB1(40,20)");

    bsp_printf("  B1: COPY 32x8 src=0x%x(stride %d) -> FB1(40,20)(stride %d)\r\n",
               (int)SA_COPY, (int)ATLAS_STRIDE, FB_STRIDE);

    for (j = 0; j < 8; j++)
        for (i = 0; i < 32; i++)
            wr16(PIX(SA_COPY, ATLAS_STRIDE, i, j), (uint16_t)(0x2000u + (uint32_t)j * 32u + (uint32_t)i));
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 38, 18, 38, 12, (uint16_t)SENT);  /* x38..75, y18..29 */
    cache_evict();

    if (op_fail(blt_copy(SA_COPY, PIX(FB1_BASE, FB_STRIDE, 40, 20), ATLAS_STRIDE, FB_STRIDE,
                         32u, 8u), "B1 COPY")) {
        item("B1 COPY 32x8 src(stride 64)->FB1(40,20)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_pat(FB1_BASE, FB_STRIDE, 40, 20, 32, 8, 0x2000u, 32u);
    chk_outside(FB1_BASE, FB_STRIDE, 38, 18, 38, 12, 40, 20, 32, 8, SENT);
    item("B1 COPY 32x8 src(stride 64)->FB1(40,20)", g_perf, g_mis);
}

/* B2：src 非对齐（源行内 x=3 起）+ dst 非对齐（x=13，字节偏移 26 -> px_skip=5） */
static void tb2(void)
{
    int i, j;
    uint32_t src = SA_COPYB + 6u;                 /* 行内第 3 个像素，字节偏移 6 */
    SKIP_IF_DEAD("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)");

    bsp_printf("  B2: COPY 20x8 src=0x%x(行内 x=3 非对齐) -> FB1(13,60)(字节偏移 26)\r\n",
               (int)src);

    for (j = 0; j < 8; j++)
        for (i = 0; i < 20; i++)
            wr16(PIX(SA_COPYB, ATLAS_STRIDE, 3 + i, j), (uint16_t)(0x3000u + (uint32_t)j * 32u + (uint32_t)i));
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 10, 58, 28, 12, (uint16_t)SENT);  /* x10..37, y58..69 */
    cache_evict();

    if (op_fail(blt_copy(src, PIX(FB1_BASE, FB_STRIDE, 13, 60), ATLAS_STRIDE, FB_STRIDE,
                         20u, 8u), "B2 COPY")) {
        item("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_pat(FB1_BASE, FB_STRIDE, 13, 60, 20, 8, 0x3000u, 32u);
    /* 行首左侧 x=11,12（首词未写 lane）与行尾右侧 x=33..37（尾词未写 lane）必须原样 */
    chk_outside(FB1_BASE, FB_STRIDE, 10, 58, 28, 12, 13, 60, 20, 8, SENT);
    item("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)", g_perf, g_mis);
}

/* B3：宽度不是 8 的倍数（13 像素）——专门覆盖 H2「行尾不足 16B 的词只写有效字节」。
 * dst 16B 对齐（x=200 -> 400B = 25 词），所以只有行尾词是半满的。 */
static void tb3(void)
{
    int i, j;
    SKIP_IF_DEAD("B3 COPY 13x9 width%8!=0 (row tail)");

    bsp_printf("  B3: COPY 13x9（宽 13 = 26B，行尾词只写 10B）src=0x%x -> FB1(200,100)\r\n",
               (int)SA_COPY);

    for (j = 0; j < 9; j++)
        for (i = 0; i < 13; i++)
            wr16(PIX(SA_COPY, ATLAS_STRIDE, i, j), (uint16_t)(0x4000u + (uint32_t)j * 16u + (uint32_t)i));
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 198, 98, 22, 13, (uint16_t)SENT); /* x198..219, y98..110 */
    cache_evict();

    if (op_fail(blt_copy(SA_COPY, PIX(FB1_BASE, FB_STRIDE, 200, 100), ATLAS_STRIDE, FB_STRIDE,
                         13u, 9u), "B3 COPY")) {
        item("B3 COPY 13x9 width%8!=0 (row tail)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_pat(FB1_BASE, FB_STRIDE, 200, 100, 13, 9, 0x4000u, 16u);
    /* x213/214/215 落在行尾那个只写了 10 字节的 16B 词里：必须保持哨兵 = H2 的直接证据 */
    chk_outside(FB1_BASE, FB_STRIDE, 198, 98, 22, 13, 200, 100, 13, 9, SENT);
    item("B3 COPY 13x9 width%8!=0 (row tail)", g_perf, g_mis);
}

/* B4：整屏 COPY 960x540，两个方向都做（FB1 -> FB -> FB1）。
 * FB1 先由引擎 FILL 出三段色带（每段 180 行），这样能同时验证整屏行寻址与带边界。 */
static void tb4(void)
{
    uint32_t p1 = 0, p2 = 0, p3 = 0, p4 = 0, p5 = 0;
    SKIP_IF_DEAD("B4 COPY fullscreen 960x540 (FB1->FB->FB1)");

    bsp_printf("  B4: 整屏 COPY %dx%d —— FB1 三段色带 -> FB -> FB1\r\n", FB_WIDTH, FB_HEIGHT);

    if (op_fail(blt_fill(FB1_BASE, FB_STRIDE, FB_WIDTH, 180u, 0x07E0u), "B4 band0")) {
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", 0u, -1);
        return;
    }
    p1 = g_perf;
    if (op_fail(blt_fill(FB1_BASE + 180UL * FB_STRIDE, FB_STRIDE, FB_WIDTH, 180u, 0x001Fu), "B4 band1")) {
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1, -1);
        return;
    }
    p2 = g_perf;
    if (op_fail(blt_fill(FB1_BASE + 360UL * FB_STRIDE, FB_STRIDE, FB_WIDTH, 180u, 0xFD20u), "B4 band2")) {
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2, -1);
        return;
    }
    p3 = g_perf;

    cache_invalidate();
    mis_reset();
    /* FB1 上的色带自身先自检一下（顺带验证整屏行寻址） */
    expect_px(0, 0, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    expect_px(FB_WIDTH - 1, 179, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 179)), 0x07E0u);
    expect_px(0, 180, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    expect_px(0, 360, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    expect_px(FB_WIDTH - 1, 539, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 539)), 0xFD20u);

    /* FB1 -> FB */
    if (op_fail(blt_copy(FB1_BASE, FB_BASE, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT), "B4 fwd")) {
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3, -1);
        return;
    }
    p4 = g_perf;
    cache_invalidate();
    expect_px(0, 0, rd16(PIX(FB_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), 0x07E0u);
    expect_px(FB_WIDTH - 1, 179, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 179)), 0x07E0u);
    expect_px(0, 180, rd16(PIX(FB_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    expect_px(0, 360, rd16(PIX(FB_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), 0xFD20u);
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), 0x001Fu);

    /* FB -> FB1 */
    if (op_fail(blt_copy(FB_BASE, FB1_BASE, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT), "B4 back")) {
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3 + p4, -1);
        return;
    }
    p5 = g_perf;
    cache_invalidate();
    expect_px(0, 0, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), 0x07E0u);
    expect_px(0, 180, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    expect_px(0, 360, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
              rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), 0xFD20u);
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
              rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), 0x001Fu);

    bsp_printf("      PERF 带0/带1/带2/前向整屏/回向整屏 = %d/%d/%d/%d/%d cycles\r\n",
               (int)p1, (int)p2, (int)p3, (int)p4, (int)p5);
    item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3 + p4 + p5, g_mis);
}

/* B5：重叠/自拷贝（src == dst 同地址）。写-读同源时结果必须与原内容完全一致。 */
static void tb5(void)
{
    int i, j;
    uint32_t dst = PIX(FB1_BASE, FB_STRIDE, 400, 120);
    SKIP_IF_DEAD("B5 COPY self-copy src==dst");

    bsp_printf("  B5: COPY 32x8 src==dst==0x%x（自拷贝/重叠，结果须与原内容一致）\r\n", (int)dst);

    fill_rect_cpu(FB1_BASE, FB_STRIDE, 396, 116, 40, 16, (uint16_t)SENT);  /* 先铺哨兵... */
    for (j = 0; j < 8; j++)                                                /* ...再把图案盖回目标区 */
        for (i = 0; i < 32; i++)
            wr16(PIX(FB1_BASE, FB_STRIDE, 400 + i, 120 + j),
                 (uint16_t)(0x5000u + (uint32_t)j * 32u + (uint32_t)i));
    cache_evict();

    if (op_fail(blt_copy(dst, dst, FB_STRIDE, FB_STRIDE, 32u, 8u), "B5 COPY self")) {
        item("B5 COPY self-copy src==dst", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_pat(FB1_BASE, FB_STRIDE, 400, 120, 32, 8, 0x5000u, 32u);
    chk_outside(FB1_BASE, FB_STRIDE, 396, 116, 40, 16, 400, 120, 32, 8, SENT);
    item("B5 COPY self-copy src==dst", g_perf, g_mis);
}

/* =========================================================================
 * [6c] C. KEY 边界测试
 * ========================================================================= */

/* C1：隔像素键色（偶数 x 透明），目的预填 0x1111：键色位必须保留，非键色位必须写入 */
static void tc1(void)
{
    int i, j, keep_ok = 0, write_ok = 0;
    SKIP_IF_DEAD("C1 KEY 16x8 alternating key px");

    bsp_printf("  C1: KEY 16x8 key=0x%x src=0x%x(隔像素键色) -> FB1(40,140)(预填 0x%x)\r\n",
               (int)KEY_COLOR, (int)SA_KEY, (int)0x1111);

    for (j = 0; j < 8; j++)
        for (i = 0; i < 16; i++)
            wr16(PIX(SA_KEY, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 38, 138, 20, 12, (uint16_t)SENT);  /* x38..57, y138..149 */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 40, 140, 16, 8, 0x1111u);          /* 目的预填 */
    cache_evict();

    if (op_fail(blt_key(SA_KEY, PIX(FB1_BASE, FB_STRIDE, 40, 140), 32u, FB_STRIDE,
                        16u, 8u, KEY_COLOR), "C1 KEY")) {
        item("C1 KEY 16x8 alternating key px", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    for (j = 0; j < 8; j++) {
        for (i = 0; i < 16; i++) {
            uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 40 + i, 140 + j));
            if (i & 1) {
                if (got == C_CYAN) write_ok++;
                expect_px(40 + i, 140 + j, got, C_CYAN);
            } else {
                if (got == 0x1111u) keep_ok++;
                expect_px(40 + i, 140 + j, got, 0x1111u);
            }
        }
    }
    chk_outside(FB1_BASE, FB_STRIDE, 38, 138, 20, 12, 40, 140, 16, 8, SENT);
    bsp_printf("      键色位保留 %d/64，非键色位写入 %d/64\r\n", keep_ok, write_ok);
    item("C1 KEY 16x8 alternating key px", g_perf, g_mis);
}

/* C2：整行（整块）全是键色 -> 目的一个字节都不许被改写。
 * 目的预填的是「每像素都不同」的梯度值，所以任何一次写入都会被抓到。 */
static void tc2(void)
{
    int i, j;
    SKIP_IF_DEAD("C2 KEY 16x4 all-key -> dst untouched (byte exact)");

    bsp_printf("  C2: KEY 16x4 源全键色 0x%x -> FB1(40,160)（目的梯度值，须逐字节原样）\r\n",
               (int)KEY_COLOR);

    for (j = 0; j < 4; j++)
        for (i = 0; i < 16; i++)
            wr16(PIX(SA_KEYROW, 32u, i, j), (uint16_t)KEY_COLOR);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 32, 158, 32, 8, (uint16_t)SENT);   /* x32..63, y158..165 */
    for (j = 0; j < 4; j++)                                               /* 目的块：唯一梯度 */
        for (i = 0; i < 16; i++)
            wr16(PIX(FB1_BASE, FB_STRIDE, 40 + i, 160 + j), (uint16_t)(0x1000u + (uint32_t)j * 16u + (uint32_t)i));
    cache_evict();

    if (op_fail(blt_key(SA_KEYROW, PIX(FB1_BASE, FB_STRIDE, 40, 160), 32u, FB_STRIDE,
                        16u, 4u, KEY_COLOR), "C2 KEY all-key")) {
        item("C2 KEY 16x4 all-key -> dst untouched", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_pat(FB1_BASE, FB_STRIDE, 40, 160, 16, 4, 0x1000u, 16u);   /* 目的块逐像素原样 */
    chk_outside(FB1_BASE, FB_STRIDE, 32, 158, 32, 8, 40, 160, 16, 4, SENT);
    item("C2 KEY 16x4 all-key -> dst untouched (byte exact)", g_perf, g_mis);
}

/* C3：最接近真实用法的精灵——32x32 四边键色边框 + 实心内部，叠在棋盘背景上 */
static void tc3(void)
{
    int i, j, border_ok = 0, inner_ok = 0;
    SKIP_IF_DEAD("C3 KEY 32x32 key-border sprite over checkerboard");

    bsp_printf("  C3: KEY 32x32（边=键色 0x%x，内=0x%x）-> FB1(304,140) 棋盘背景\r\n",
               (int)KEY_COLOR, (int)C_ORANGE);

    for (j = 0; j < 32; j++) {
        for (i = 0; i < 32; i++) {
            uint16_t c;
            if (i == 0 || j == 0 || i == 31 || j == 31) c = (uint16_t)KEY_COLOR;
            else                                        c = (uint16_t)C_ORANGE;
            wr16(PIX(SA_SPR, ATLAS_STRIDE, i, j), c);
        }
    }
    /* 背景：x300..339, y136..175 的棋盘 */
    for (j = 136; j < 176; j++)
        for (i = 300; i < 340; i++)
            wr16(PIX(FB1_BASE, FB_STRIDE, i, j), (uint16_t)(((i + j) & 1) ? 0x1111u : 0x2222u));
    cache_evict();

    if (op_fail(blt_key(SA_SPR, PIX(FB1_BASE, FB_STRIDE, 304, 140), ATLAS_STRIDE, FB_STRIDE,
                        32u, 32u, KEY_COLOR), "C3 KEY sprite")) {
        item("C3 KEY 32x32 key-border sprite", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    /* 内部 30x30 必须被实心色覆盖 */
    for (j = 1; j < 31; j++) {
        for (i = 1; i < 31; i++) {
            uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 304 + i, 140 + j));
            if (got == C_ORANGE) inner_ok++;
            expect_px(304 + i, 140 + j, got, C_ORANGE);
        }
    }
    /* 四边边框必须保留棋盘原值 */
    for (j = 0; j < 32; j++) {
        for (i = 0; i < 32; i++) {
            int isb = (i == 0 || j == 0 || i == 31 || j == 31);
            if (!isb) continue;
            {
                uint32_t exp = (uint32_t)(((304 + i + 140 + j) & 1) ? 0x1111u : 0x2222u);
                uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 304 + i, 140 + j));
                if (got == exp) border_ok++;
                expect_px(304 + i, 140 + j, got, exp);
            }
        }
    }
    /* 块外整圈（含上下左右各 4 像素与 4 个角外侧）也必须是棋盘原值 */
    for (j = 136; j < 176; j++) {
        for (i = 300; i < 340; i++) {
            uint32_t exp2;
            if (i >= 304 && i < 336 && j >= 140 && j < 172) continue;   /* 块内已单独查过 */
            exp2 = (uint32_t)(((i + j) & 1) ? 0x1111u : 0x2222u);
            expect_px(i, j, rd16(PIX(FB1_BASE, FB_STRIDE, i, j)), exp2);
        }
    }

    bsp_printf("      内部写入 %d/900，边框保留 %d/124\r\n", inner_ok, border_ok);
    item("C3 KEY 32x32 key-border sprite", g_perf, g_mis);
}

/* C4：非对齐 dst 的 KEY（x=7 -> 字节偏移 14，px_skip=7，首词只写最后 1 个 lane） */
static void tc4(void)
{
    int i, j, keep_ok = 0, write_ok = 0;
    SKIP_IF_DEAD("C4 KEY 16x8 @x=7 (dst unaligned)");

    bsp_printf("  C4: KEY 16x8 src=0x%x -> FB1(7,200)（字节偏移 14，首词只写 1 个 lane）\r\n",
               (int)SA_KEYUN);

    for (j = 0; j < 8; j++)
        for (i = 0; i < 16; i++)
            wr16(PIX(SA_KEYUN, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    /* 目的带 x0..31, y199..208 先铺哨兵，再把目标矩形写成唯一梯度（既是"保留"证据，
     * 也是"哪一行哪一列错位"的定位依据） */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 199, 32, 10, (uint16_t)SENT);
    for (j = 0; j < 8; j++)
        for (i = 0; i < 16; i++)
            wr16(PIX(FB1_BASE, FB_STRIDE, 7 + i, 200 + j),
                 (uint16_t)(0x3000u + (uint32_t)j * 40u + (uint32_t)i));
    cache_evict();

    if (op_fail(blt_key(SA_KEYUN, PIX(FB1_BASE, FB_STRIDE, 7, 200), 32u, FB_STRIDE,
                        16u, 8u, KEY_COLOR), "C4 KEY unaligned")) {
        item("C4 KEY 16x8 @x=7 (dst unaligned)", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    for (j = 0; j < 8; j++) {
        for (i = 0; i < 16; i++) {
            uint32_t orig = 0x3000u + (uint32_t)j * 40u + (uint32_t)i;
            uint32_t exp  = (i & 1) ? C_CYAN : orig;
            uint32_t got  = rd16(PIX(FB1_BASE, FB_STRIDE, 7 + i, 200 + j));
            if (i & 1) { if (got == exp) write_ok++; }
            else       { if (got == exp) keep_ok++;  }
            expect_px(7 + i, 200 + j, got, exp);
        }
    }
    /* 首词只写了最后 1 个 lane（x=7），x=0..6 与 x=23..31 以及上下两行必须原样 */
    chk_outside(FB1_BASE, FB_STRIDE, 0, 199, 32, 10, 7, 200, 16, 8, SENT);
    bsp_printf("      键色位保留 %d/64，非键色位写入 %d/64\r\n", keep_ok, write_ok);
    item("C4 KEY 16x8 @x=7 (dst unaligned)", g_perf, g_mis);
}

/* =========================================================================
 * [6d] D. ALPHA 边界测试
 * 背景色专门挑「展开后通道 >= 128」的值（0xC618），用来暴露 +127 舍入的行为。
 * ========================================================================= */

/* D1：α=0 -> 结果必须等于纯背景（含 8bit 展开 + 舍入后的精确值） */
static void td1(void)
{
    uint32_t exp;
    SKIP_IF_DEAD("D1 ALPHA a=0 -> pure bg");

    exp = alpha_ref(0xFFFFu, 0xC618u, 0u);
    bsp_printf("  D1: ALPHA α=0 fg=0xffff bg=0xc618 -> FB1(96,240)，期望 = 背景 0x%x\r\n", (int)exp);

    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFFFFu);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 238, 28, 12, (uint16_t)SENT);   /* x92..119, y238..249 */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 240, 16, 8, 0xC618u);
    cache_evict();

    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 240), 32u, FB_STRIDE,
                          16u, 8u, 0u), "D1 ALPHA a=0")) {
        item("D1 ALPHA a=0 -> pure bg", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_rect(FB1_BASE, FB_STRIDE, 96, 240, 16, 8, exp);
    chk_outside(FB1_BASE, FB_STRIDE, 92, 238, 28, 12, 96, 240, 16, 8, SENT);
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始背景 0xc618 %s\r\n",
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 240)), (int)exp,
               (exp == 0xC618u) ? "完全一致" : "不同(=展开/舍入模型值)");
    item("D1 ALPHA a=0 -> pure bg", g_perf, g_mis);
}

/* D2：α=255 -> 结果必须等于纯前景 */
static void td2(void)
{
    uint32_t exp;
    SKIP_IF_DEAD("D2 ALPHA a=255 -> pure fg");

    exp = alpha_ref(0xFD20u, 0x0010u, 255u);
    bsp_printf("  D2: ALPHA α=255 fg=0xfd20 bg=0x0010 -> FB1(96,250)，期望 = 前景 0x%x\r\n", (int)exp);

    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFD20u);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 248, 28, 12, (uint16_t)SENT);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 250, 16, 8, 0x0010u);
    cache_evict();

    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 250), 32u, FB_STRIDE,
                          16u, 8u, 255u), "D2 ALPHA a=255")) {
        item("D2 ALPHA a=255 -> pure fg", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_rect(FB1_BASE, FB_STRIDE, 96, 250, 16, 8, exp);
    chk_outside(FB1_BASE, FB_STRIDE, 92, 248, 28, 12, 96, 250, 16, 8, SENT);
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始前景 0xfd20 %s\r\n",
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 250)), (int)exp,
               (exp == 0xFD20u) ? "完全一致" : "不同(=展开/舍入模型值)");
    item("D2 ALPHA a=255 -> pure fg", g_perf, g_mis);
}

/* D3：α=128 金标准——白叠黑必须得到 0x7BEF */
static void td3(void)
{
    SKIP_IF_DEAD("D3 ALPHA a=128 white/black -> 0x7BEF");

    bsp_printf("  D3: ALPHA α=128 fg=0xffff(白) bg=0x0000(黑) -> FB1(96,260)，硬件金标准 0x7bef\r\n");

    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFFFFu);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 258, 28, 12, (uint16_t)SENT);
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 260, 16, 8, 0x0000u);
    cache_evict();

    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 260), 32u, FB_STRIDE,
                          16u, 8u, 128u), "D3 ALPHA a=128")) {
        item("D3 ALPHA a=128 white/black -> 0x7BEF", 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    chk_rect(FB1_BASE, FB_STRIDE, 96, 260, 16, 8, 0x7BEFu);
    chk_outside(FB1_BASE, FB_STRIDE, 92, 258, 28, 12, 96, 260, 16, 8, SENT);
    bsp_printf("      got(0,0)=0x%x exp=0x7bef（模型算出 0x%x）\r\n",
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 260)),
               (int)alpha_ref(0xFFFFu, 0x0000u, 128u));
    item("D3 ALPHA a=128 white/black -> 0x7BEF", g_perf, g_mis);
}

/* D4：α 扫描 32/64/96/160/192/224，逐点与软件公式（8bit 通道展开）比对；
 * 同时检查三条通道随 α 的单调方向。每点用 1x1 ALPHA（顺带覆盖退化尺寸）。 */
static void td4(void)
{
    static const uint32_t av[6] = { 32u, 64u, 96u, 160u, 192u, 224u };
    uint32_t exp[6], gotv[6], psum = 0;
    int k, mono_ok = 1;

    SKIP_IF_DEAD("D4 ALPHA sweep a=32..224 vs model");

    bsp_printf("  D4: ALPHA α 扫描 fg=0xfd20(橙) bg=0x0010(深蓝) 1x1 -> FB1(0,200..205)\r\n");

    for (k = 0; k < 6; k++)
        wr16(SA_ALPH4 + (uint32_t)k * 32u, (uint16_t)0xFD20u);            /* strided 1 像素/α */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 199, 8, 8, (uint16_t)SENT);     /* x0..7, y199..206 */
    for (k = 0; k < 6; k++)
        wr16(PIX(FB1_BASE, FB_STRIDE, 0, 200 + k), 0x0010u);              /* 目的背景 */
    cache_evict();

    for (k = 0; k < 6; k++) {
        if (op_fail(blt_alpha(SA_ALPH4 + (uint32_t)k * 32u,
                              PIX(FB1_BASE, FB_STRIDE, 0, 200 + k),
                              32u, FB_STRIDE, 1u, 1u, av[k]), "D4 ALPHA sweep")) {
            item("D4 ALPHA sweep a=32..224 vs model", psum, -1);
            return;
        }
        psum += g_perf;
        exp[k] = alpha_ref(0xFD20u, 0x0010u, av[k]);
    }

    cache_invalidate();
    mis_reset();
    for (k = 0; k < 6; k++) {
        gotv[k] = rd16(PIX(FB1_BASE, FB_STRIDE, 0, 200 + k));
        expect_px((int)av[k], 200 + k, gotv[k], exp[k]);
    }
    /* 哨兵：目标像素之外必须原样（1x1 也不许乱写相邻字节） */
    chk_rect(FB1_BASE, FB_STRIDE, 1, 199, 7, 8, SENT);
    chk_rect(FB1_BASE, FB_STRIDE, 0, 199, 1, 1, SENT);
    chk_rect(FB1_BASE, FB_STRIDE, 0, 206, 1, 1, SENT);

    /* 单调性：R/G 随 α 不减（fg 通道更大），B 随 α 不增（bg 通道更大） */
    for (k = 1; k < 6; k++) {
        if (ch_r(gotv[k]) < ch_r(gotv[k - 1])) mono_ok = 0;
        if (ch_g(gotv[k]) < ch_g(gotv[k - 1])) mono_ok = 0;
        if (ch_b(gotv[k]) > ch_b(gotv[k - 1])) mono_ok = 0;
    }
    bsp_printf("      ");
    for (k = 0; k < 6; k++)
        bsp_printf("a=%d exp=0x%x got=0x%x  ", (int)av[k], (int)exp[k], (int)gotv[k]);
    bsp_printf("\r\n      R 通道 %d..%d（↑）G %d..%d（↑）B %d..%d（↓）单调=%s\r\n",
               (int)ch_r(gotv[0]), (int)ch_r(gotv[5]),
               (int)ch_g(gotv[0]), (int)ch_g(gotv[5]),
               (int)ch_b(gotv[0]), (int)ch_b(gotv[5]),
               mono_ok ? "PASS" : "FAIL");
    if (!mono_ok) g_mis++;
    item("D4 ALPHA sweep a=32..224 vs model", psum, g_mis);
}

/* =========================================================================
 * [7] 多精灵压测
 * ========================================================================= */
typedef struct {
    int      n;
    int      frames;
    uint32_t ins_avg;      /* 每帧推入 FIFO 的指令条数（批量下发的统计口径） */
    uint32_t eng_avg;      /* 「记账帧」里逐条等 DONE 后累加 BLT_PERF 得到的每帧引擎周期 */
    uint32_t cpu_avg;      /* 帧起始 -> 帧末 DONE + 哨兵校验(+按模式冲刷) 的平均 tick（未节流） */
    uint32_t period_avg;   /* 含节流的帧周期平均 */
    uint32_t evict_avg;    /* 本档每帧真正花在 cache_evict 上的平均 tick */
    uint32_t fps;          /* 由 cpu_avg 推出的真实可达到帧率 */
    uint32_t fps_period;   /* 由 period_avg 推出的实际帧率 */
    uint32_t perf_good;    /* 记账帧里 PERF 有效的采样条数（= 参与 eng_avg 求和的条数） */
    uint32_t perf_zero;    /* 记账帧里 PERF 读回 0/异常的条数（表格用 '!' 标注） */
    int      errs;
} stress_row_t;

/* 8 种精灵：4 张 32x32 + 4 张 16x16，四周一圈键色边框，内部不同亮色。
 * 最后两种（slot 6/7）用 ALPHA blit，其余用 KEY blit（符合"两个精灵用 ALPHA"）。 */
static const uint16_t s_sprw[STRESS_NSLOT] = { 32, 32, 32, 32, 16, 16, 16, 16 };
static const uint16_t s_sprh[STRESS_NSLOT] = { 32, 32, 32, 32, 16, 16, 16, 16 };
static const uint16_t s_sprc[STRESS_NSLOT] = { 0x07FF, 0xFD20, 0xFFE0, 0x07E0,
                                               0xF800, 0xFFFF, 0x8410, 0xFC1F };
static const uint8_t  s_spra[STRESS_NSLOT] = { 0, 0, 0, 0, 0, 0, 1, 1 };

/* 64 点整数正弦表（幅度 ±127，避免浮点/libm） */
static const int16_t sin_tab[64] = {
      0,  12,  25,  37,  49,  60,  71,  81,  90,  98, 106, 112, 117, 122, 125, 126,
    127, 126, 125, 122, 117, 112, 106,  98,  90,  81,  71,  60,  49,  37,  25,  12,
      0, -12, -25, -37, -49, -60, -71, -81, -90, -98,-106,-112,-117,-122,-125,-126,
   -127,-126,-125,-122,-117,-112,-106, -98, -90, -81, -71, -60, -49, -37, -25, -12
};

static int16_t sp_x[STRESS_MAXN], sp_y[STRESS_MAXN];      /* 当前位置 */
static int16_t sp_px[STRESS_MAXN], sp_py[STRESS_MAXN];    /* 上一帧位置（要擦除的矩形） */
static int16_t sp_y0[STRESS_MAXN];                        /* 垂直正弦的中心 */
static int8_t  sp_vx[STRESS_MAXN];                        /* 水平速度（碰到边界反向） */
static uint8_t sp_seen[STRESS_MAXN];                      /* 本档是否已经有上一帧 */

/* CPU 在精灵区画 8 张精灵并把它们挤出 D$，再回读确认真的落在 DDR（引擎要读它） */
static int stress_setup(void)
{
    int s, x, y, bad = 0;

    for (s = 0; s < STRESS_NSLOT; s++) {
        uint32_t base = SA_ATLAS + (uint32_t)s * ATLAS_SLOT;
        int w = (int)s_sprw[s], h = (int)s_sprh[s];
        for (y = 0; y < h; y++) {
            for (x = 0; x < w; x++) {
                uint16_t c;
                if (x == 0 || y == 0 || x == w - 1 || y == h - 1)
                    c = (uint16_t)KEY_COLOR;                         /* 四周一圈键色 */
                else if (x >= 4 && x < 12 && y >= 4 && y < 12)
                    c = (uint16_t)C_BLACK;                           /* 方向标记 */
                else
                    c = s_sprc[s];
                wr16(base + (uint32_t)y * ATLAS_STRIDE + (uint32_t)x * 2u, c);
            }
        }
    }
    cache_evict();          /* CPU 写 -> 引擎读：必须挤出 D$ */
    cache_invalidate();     /* 再从 DDR 回读验证 */
    for (s = 0; s < STRESS_NSLOT; s++) {
        uint32_t base = SA_ATLAS + (uint32_t)s * ATLAS_SLOT;
        int w = (int)s_sprw[s], h = (int)s_sprh[s];
        /* 左上角与右下角必须是键色边框；(12,12) 必然是内部实心色（不在 8x8 标记块里） */
        if (rd16(base) != (uint16_t)KEY_COLOR) bad++;
        if (rd16(base + (uint32_t)(w - 1) * 2u + (uint32_t)(h - 1) * ATLAS_STRIDE)
            != (uint16_t)KEY_COLOR) bad++;
        if (rd16(base + 12u * 2u + 12u * ATLAS_STRIDE) != (uint16_t)s_sprc[s]) bad++;
    }
    bsp_printf("      [7] 图集 8 张（4x32x32 + 4x16x16，键色边框 0x%x）@0x%x stride=%d，DDR 回读自检 %s\r\n",
               (int)KEY_COLOR, (int)SA_ATLAS, (int)ATLAS_STRIDE, bad ? "FAIL" : "PASS");
    if (bad) g_fail++;
    return bad;
}

/* 复位某一档的精灵状态（不擦屏，调用方先整屏刷背景） */
static void stress_prepare(int n)
{
    int i;
    for (i = 0; i < n; i++) {
        int sl = i & (STRESS_NSLOT - 1);
        int w  = (int)s_sprw[sl];
        int maxx = FB_WIDTH - w;
        sp_x[i]  = (int16_t)((uint32_t)(i * 61) % (uint32_t)maxx);
        sp_y0[i] = (int16_t)(24u + (uint32_t)(i * 53) % 468u);
        sp_y[i]  = sp_y0[i];
        sp_vx[i] = (int8_t)(1 + (i & 3));
        sp_seen[i] = 0;
        sp_px[i] = sp_x[i];
        sp_py[i] = sp_y[i];
    }
}

/* 位置更新：水平匀速弹跳（碰边反向）+ 垂直正弦摆动（整数表，无浮点）。
 * 拆出来是为了让 demo 在引擎挂掉时能只用 CPU 搬动精灵。 */
static void spr_move(int i, int f)
{
    int sl   = i & (STRESS_NSLOT - 1);
    int w    = (int)s_sprw[sl];
    int maxx = FB_WIDTH - w;
    int maxy = FB_HEIGHT - (int)s_sprh[sl];
    int nx, ny, off;

    nx = (int)sp_x[i] + (int)sp_vx[i];
    if (nx < 0)              { nx = 0;    sp_vx[i] = (int8_t)(-(int)sp_vx[i]); }
    else if (nx > maxx)      { nx = maxx; sp_vx[i] = (int8_t)(-(int)sp_vx[i]); }
    sp_x[i] = (int16_t)nx;

    off = (int)(((int32_t)sin_tab[((uint32_t)f * 2u + (uint32_t)i * 11u) & 63u] * 20) >> 7);
    ny  = (int)sp_y0[i] + off;
    if (ny < 0)         ny = 0;
    else if (ny > maxy) ny = maxy;
    sp_y[i] = (int16_t)ny;
}

/* 把一个精灵本帧的指令**推入 FIFO**（不等 DONE，等 DONE 由帧末统一做一次）。
 * 指令序列 = [擦除] + 1 条 KEY/ALPHA blit；擦除方式由 STRESS_ERASE_MODE 决定：
 *   0：1 条 FILL 回填上一帧矩形（v2.0 行为）
 *   1：1 条 FILL 回填「旧∪新」包围盒（水平弹跳时只多 dx*dy，N 大时才划算；
 *      只对 n>=STRESS_BBOX_MINN 的档位生效，小 N 时反而更贵）
 *   2：不擦（本帧的背景回填由帧首那条整屏 FILL 负责，见 stress_frame）
 * 返回 0 正常，非 0 为下发异常码（g_push_err）。 */
static int spr_emit(int i, int f, int n, int bbox)
{
    int sl  = i & (STRESS_NSLOT - 1);
    int w   = (int)s_sprw[sl];
    int h   = (int)s_sprh[sl];
    uint32_t src = SA_ATLAS + (uint32_t)sl * ATLAS_SLOT;
    int ox = (int)sp_px[i], oy = (int)sp_py[i];
    int nx, ny;

#if (STRESS_ERASE_MODE == 2)
    (void)n; (void)bbox;
#else
    (void)n;
#endif

    spr_move(i, f);                       /* 用旧位置判反向 -> 更新 sp_x/sp_y */
    nx = (int)sp_x[i];
    ny = (int)sp_y[i];

#if (STRESS_ERASE_MODE == 0)
    (void)bbox;
    if (sp_seen[i]) {                     /* 擦旧矩形 */
        push_cmd_fast(BLT_OP_FILL, 0u, PIX(FB_BASE, FB_STRIDE, ox, oy), 0u, FB_STRIDE,
                      (uint32_t)w, (uint32_t)h, 0xFFu, STRESS_BG);
        if (g_push_err) return g_push_err;
    }
#elif (STRESS_ERASE_MODE == 1)
    if (sp_seen[i]) {
        /* bbox=1：一条 FILL 覆盖「旧∪新」包围盒；bbox=0（小 N 档）：退回只擦旧矩形 */
        int x0 = ox, y0 = oy, x1 = ox + w, y1 = oy + h;
        if (bbox) {
            if (nx < x0)      x0 = nx;
            if (ny < y0)      y0 = ny;
            if (nx + w > x1)  x1 = nx + w;
            if (ny + h > y1)  y1 = ny + h;
        }
        push_cmd_fast(BLT_OP_FILL, 0u, PIX(FB_BASE, FB_STRIDE, x0, y0), 0u, FB_STRIDE,
                      (uint32_t)(x1 - x0), (uint32_t)(y1 - y0), 0xFFu, STRESS_BG);
        if (g_push_err) return g_push_err;
    }
#else
    (void)ox; (void)oy; (void)bbox;       /* 模式 2：帧首整屏 FILL 已回填 */
#endif

    if (s_spra[sl])
        push_cmd_fast(BLT_OP_ALPHA, src, PIX(FB_BASE, FB_STRIDE, nx, ny), ATLAS_STRIDE, FB_STRIDE,
                      (uint32_t)w, (uint32_t)h, 160u, 0u);
    else
        push_cmd_fast(BLT_OP_KEY, src, PIX(FB_BASE, FB_STRIDE, nx, ny), ATLAS_STRIDE, FB_STRIDE,
                      (uint32_t)w, (uint32_t)h, 0xFFu, (uint32_t)KEY_COLOR);
    if (g_push_err) return g_push_err;

    sp_px[i] = sp_x[i];
    sp_py[i] = sp_y[i];
    sp_seen[i] = 1;
    return 0;
}

/* 一帧的完整流程（v2.2 核心）：
 *   ① 帧首同步到「整条指令边界」（blt_frame_begin：引擎 IDLE + COUNT==0 + FIFO_EMPTY；
 *      上一帧的残字/卡死在这里就会被拦住并走 op_fail 复位，不会传染给本帧）；
 *   ② 按开关下发本帧的 2N 条指令：
 *        默认 STRESS_BATCH_PUSH=0 -> 逐条下发 + 每条等 DONE（FIFO 里最多 1 条指令）；
 *        置 1 -> 一帧连推，只在跨批边界查一次 COUNT（保留的批量实现）；
 *   ③ 帧尾插 1 条 1x1 FILL 哨兵；
 *   ④ 等 DONE，判定 DONE && COUNT==0 && FIFO_EMPTY（只在引擎 IDLE 稳态判）；
 *   ⑤ 回读哨兵像素：证明本帧指令确实全部执行（丢字/漏执行立刻暴露）；
 *   ⑥ 按 STRESS_EVICT_MODE 决定这一帧要不要 cache_evict，并返回其耗时。
 * perf_each=1（记账帧）：强制走逐条路径，每条等完 DONE 立刻读 BLT_PERF 求和 ——
 * 批量连推时读到的 PERF 是陈旧值（旧代码 eng/frm=0 的原因）。eng/evict 可为 NULL。
 * 返回 0=正常 / -1 超时 / -2 引擎 ERR / -3 FIFO 状态矛盾或哨兵不符（疑似丢字）。 */
static int stress_frame(int n, int f, int perf_each, uint32_t *eng, uint32_t *evict)
{
    uint16_t sv;
    int i, rc, bbox;

    g_sent_seq++;
    sv = (uint16_t)(0x1000u + (g_sent_seq & 0xFFFu));   /* 每帧一个不同颜色（16bit 内唯一） */

    g_ins_frame  = 0;
    g_push_err   = 0;
    g_scene_ctx  = 1;                     /* 现场上下文：[7] 压测帧内 */
    g_frame_no   = (uint32_t)f;
    g_rung_n     = (uint32_t)n;
    g_push_acct  = perf_each ? 1 : 0;
    /* 记账帧强制逐条（否则读不到这条指令自己的 PERF） */
    g_push_batch = (STRESS_BATCH_PUSH && !perf_each) ? 1 : 0;

    rc = blt_frame_begin();               /* 帧首：必须是整条指令边界 */
    if (rc != 0) return rc;
    g_push_left = STRESS_PUSH_BATCH;      /* 批量路径的批预算（帧首已确认边界干净） */

#if (STRESS_ERASE_MODE == 1)
    bbox = (n >= STRESS_BBOX_MINN) ? 1 : 0;
#else
    bbox = 0;
#endif

#if (STRESS_ERASE_MODE == 2)
    /* 帧首一条整屏 FILL 回填背景（对照宏：585k 周期/条，只在 N 大时划算） */
    push_cmd_fast(BLT_OP_FILL, 0u, FB_BASE, 0u, FB_STRIDE,
                  (uint32_t)FB_WIDTH, (uint32_t)FB_HEIGHT, 0xFFu, STRESS_BG);
    rc = g_push_err;
#endif

    /* 逐条路径下每条指令都在 push_cmd_fast 里等过 DONE；批量路径在这里连续推。
     * 这里不再读 PERF（旧代码"滞后 1 条采样"在批量路径下读到的是陈旧值/0）。 */
    for (i = 0; i < n && rc == 0; i++)
        rc = spr_emit(i, f, n, bbox);

#if STRESS_SENTINEL
    if (rc == 0) {
        push_cmd_fast(BLT_OP_FILL, 0u, SA_SENT, 0u, FB_STRIDE, 1u, 1u, 0xFFu, (uint32_t)sv);
        rc = g_push_err;
    }
#endif

    if (rc == 0) rc = blt_wait_frame_done((uint32_t)STRESS_FRAME_TO_TICKS);   /* 一帧只等一次 */

#if STRESS_SENTINEL
    if (rc == 0) {
        cache_invalidate();               /* 引擎写完 DDR -> CPU 回读前必须作废 D$ */
        if (rd16(SA_SENT) != sv) rc = -3; /* 最后一条指令没落地 = 丢字/漏执行 */
    }
#endif

    if (evict) {
#if (STRESS_EVICT_MODE == 0)
        *evict = cache_evict_timed();     /* v2.0 老路径：每帧都冲刷 */
#elif (STRESS_EVICT_MODE == 2)
        *evict = ((f % STRESS_EVICT_EVERY) == 0) ? cache_evict_timed() : 0u;
#else
        *evict = 0u;                      /* 模式 1：本压测帧内 CPU 不写 DDR，不需要冲刷 */
#endif
    }
    /* 记账帧：eng = 本帧逐条 BLT_PERF 的有效样本之和（= 本帧引擎周期数）。
     * 采样在 push_cmd_fast 里完成（每条等完 DONE 再读），这里只把结果带出去。 */
    if (eng) *eng = perf_each ? g_perf_sum : 0u;
    return rc;
}

/* 跑一档：N 个精灵 × frames 帧。
 * 每帧（默认路径）：逐条下发 + 每条等 DONE -> 帧末稳态校验 + 哨兵校验（-> 按模式冲刷）。
 * 先量本帧真实耗时，再决定是否补足到 16.67ms；fps 用「未节流的真实工作时间」算，
 * 所以节流不会掩盖真实能力（cpu/frm 现在 = 下发 + 引擎执行的全过程）。
 * eng/frm 由本档末尾额外跑的一个「记账帧」逐条等 DONE 后采样 PERF 求和得到
 * （不计入 fps 统计）。 */
static void stress_rung(int n, int frames, stress_row_t *row)
{
    uint64_t t_prev = 0;
    uint32_t eng_sum = 0, wall_sum = 0, period_sum = 0, ins_sum = 0, ev_sum = 0;
    int f, errs = 0, done_frames = 0;

    row->n = n;
    row->frames = 0;
    row->ins_avg = 0;
    row->eng_avg = 0;
    row->cpu_avg = 0;
    row->period_avg = 0;
    row->evict_avg = 0;
    row->fps = 0;
    row->fps_period = 0;
    row->errs = 0;
    row->perf_good = 0;
    row->perf_zero = 0;

    stress_prepare(n);

    /* 每档先整屏刷一次背景，清掉上一档的残留（这条不计入本节拍统计） */
    if (g_blt_alive) {
        int brc = blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG);
        if (brc != 0) op_fail(brc, "stress bg FILL");
    }

    /* 模式 1「按需冲刷」：本档里 CPU 往 DDR 写的东西（图集）在 stress_setup() 里已经
     * 冲过一次；压测帧内 CPU 只往 APB 写指令，不碰 DDR，所以整档不需要再冲。
     * 这里再冲一次只是"档与档之间"的保险，成本 1 次 / 档。 */
    if (STRESS_EVICT_MODE == 1) (void)cache_evict_timed();

    g_wait_to = BLT_FAST_TICKS;      /* 逐条等 DONE 的超时（故障时快速失败，不长时间挂住） */

    for (f = 0; f < frames; f++) {
        uint64_t t_frame = tick();
        uint32_t ev = 0;
        int rc;

        if (f) period_sum += (uint32_t)(t_frame - t_prev);
        t_prev = t_frame;

        rc = stress_frame(n, f, STRESS_PERF_EACH, 0, &ev);
        ev_sum += ev;
        if (rc != 0) { errs = rc; op_fail(rc, "stress frame"); break; }

        ins_sum += g_ins_frame;
        wall_sum += (uint32_t)(tick() - t_frame);
        done_frames++;

        frame_throttle(t_frame);     /* 测量已完成，这里才补足到 ~60fps */
    }

    /* 记账帧：逐条等 DONE + 逐条读 BLT_PERF 求和 -> eng/frm（1/61 的额外开销，不污染 fps）。
     * 三条修正（旧代码 eng/frm=0 的根因）：
     *   ① **不再因为本档出过错就跳过**（旧代码 `if (errs == 0 && ...)`）——出错档恰恰
     *      最需要知道引擎周期数；出错时 op_fail 已经把边界复位干净，可以继续测；
     *   ② 采样必须"逐条等 DONE 再读 PERF"（见 push_cmd_fast ④）：批量连推时 PERF
     *      是好几条之前的陈旧值甚至还是 0，求和没有意义；
     *   ③ PERF 读回 0 的样本单独计数（perf_zero），表里用 '!' 标注，不冒充 0 混进求和。
     * 超时仍用短超时 BLT_FAST_TICKS（本档内统一的 g_wait_to）：故障时 0.2s 快速失败，
     * 不会因为一条卡死的指令把整档拖成几十秒。 */
    g_perf_sum = 0; g_perf_good = 0; g_perf_zero = 0;
    if (g_blt_alive) {
        uint32_t ev2 = 0;
        int rc2 = stress_frame(n, frames, 1, &eng_sum, &ev2);
        row->perf_good = g_perf_good;
        row->perf_zero = g_perf_zero;
        if (rc2 != 0) { errs = rc2; op_fail(rc2, "stress acct frame"); }
        else ev_sum += ev2;
    }
    g_wait_to = BLT_TIMEOUT_TICKS;   /* 本档结束，恢复默认超时 */

    if (done_frames == 0) done_frames = 1;
    row->frames     = done_frames;
    row->errs       = errs;
    row->ins_avg    = ins_sum / (uint32_t)done_frames;
    row->eng_avg    = g_perf_good ? eng_sum : 0u;   /* 没采到有效样本时留 0，由表格标注 */
    row->cpu_avg    = wall_sum / (uint32_t)done_frames;
    row->evict_avg  = ev_sum / (uint32_t)done_frames;
    row->period_avg = (done_frames > 1) ? (period_sum / (uint32_t)(done_frames - 1)) : row->cpu_avg;
    row->fps        = row->cpu_avg ? ((uint32_t)TICK_HZ + row->cpu_avg / 2u) / row->cpu_avg : 0u;
    row->fps_period = row->period_avg ? ((uint32_t)TICK_HZ + row->period_avg / 2u) / row->period_avg : 0u;
}

/* 数字右补空格，让表格在没有 %-Nd 的情况下也能对齐 */
static int ndig(int v)
{
    int n = 1;
    if (v < 0) { n = 2; v = -v; }
    while (v >= 10) { v /= 10; n++; }
    return n;
}

static void pnum(int v, int w)
{
    int n = ndig(v);
    bsp_printf("%d", v);
    while (n++ < w) bsp_printf(" ");
}

/* 打印占比（整数运算，无浮点/libc）：part/whole -> "12.3%" */
static void ppct(uint32_t part, uint32_t whole, int w)
{
    uint32_t pm = whole ? (part * 1000u) / whole : 0u;    /* 千分比 */
    int n = ndig((int)(pm / 10u)) + 3;                    /* 整数位 + '.' + 1 位 + '%' */
    bsp_printf("%d.%d%%", (int)(pm / 10u), (int)(pm % 10u));
    while (n++ < w) bsp_printf(" ");
}

static void stress_all(void)
{
    static const int ladder[STRESS_NRUNG] = { 25, 50, 100, 200, 400, 800 };
    stress_row_t row[STRESS_NRUNG];
    int r, ran = 0, last60 = 0, last55 = 0, best = -1;
    int stop_n = 0;
    uint32_t floor_avg;
    int k;

    bsp_printf("\r\n---------- [7] 多精灵压测（每档 %d 帧，节流 %d ticks@%dHz） ----------\r\n",
               STRESS_FRAMES, (int)FRAME_TICKS, (int)TICK_HZ);
    bsp_printf("      优化开关: 批量下发=%d(每批%d条/开批允许残留%d条) 冲刷模式=%d(每%d帧,%d字) 擦除模式=%d 哨兵=%d 帧内读PERF=%d\r\n",
               STRESS_BATCH_PUSH, STRESS_PUSH_BATCH, STRESS_BATCH_HEADROOM,
               STRESS_EVICT_MODE, STRESS_EVICT_EVERY, CACHE_EVICT_WORDS,
               STRESS_ERASE_MODE, STRESS_SENTINEL, STRESS_PERF_EACH);
    bsp_printf("      擦除策略: %s\r\n", STRESS_ERASE_TAG);
    bsp_printf("      指令口径: %s；ins/frm = 每帧实际推入 FIFO 的指令条数（含哨兵）\r\n",
               STRESS_INS_FORMULA);
#if STRESS_BATCH_PUSH
    bsp_printf("      下发路径: 批量连推（每批 %d 条，只在跨批边界查 COUNT）—— 非默认，"
               "上板出现过错位/卡死，现场见 op_fail 打印的 op/dst/w/h。\r\n", STRESS_PUSH_BATCH);
#else
    bsp_printf("      下发路径: **逐条下发 + 每条等 DONE**（默认，最保守）：FIFO 里最多 1 条指令，"
               "一条指令的 8 个字连续写完、中间无检查点，中止后 SOFT_RST 保证不留残字。\r\n");
#endif
    bsp_printf("      位置: 水平匀速弹跳 + 垂直正弦（整数表，无浮点）；帧末在引擎 IDLE 稳态校验"
               " DONE && COUNT==0 && FIFO_EMPTY 并回读哨兵像素。\r\n");
    bsp_printf("      eng/frm 口径: 每档末尾 1 个「记账帧」逐条等 DONE 后读 BLT_PERF 求和"
               "（PERF 读回 0 的样本单独计数，表里标 '!'）。\r\n");

    stress_setup();

    /* 空帧地板：只做一次 cache_evict 的开销（让 cpu/frm 与 evict%% 可解读） */
    {
        uint32_t acc = 0;
        for (k = 0; k < 10; k++) acc += cache_evict_timed();
        floor_avg = acc / 10u;
    }
    bsp_printf("      基线：单次 cache_evict(%d 字) 的空帧开销 ≈ %d ticks；"
               "本档模式 %d 下每帧真正冲刷的次数见 evict%% 列\r\n",
               (int)CACHE_EVICT_WORDS, (int)floor_avg, STRESS_EVICT_MODE);

    for (r = 0; r < STRESS_NRUNG; r++) {
        int n = ladder[r];
        if (!g_blt_alive) break;
        stress_rung(n, STRESS_FRAMES, &row[ran]);
        ran++;
        /* eng/frm 一定要打印出来：没采到有效 PERF 就写 NA、有坏样本就标注，
         * 绝不显示成 0（0 会被误读成"引擎没花时间"）。 */
        if (row[ran - 1].perf_good == 0)
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=NA(未采到有效 PERF, 坏样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
                       (int)row[ran - 1].perf_zero, (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
                       (row[ran - 1].errs ? "ENGINE-ERR" :
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
        else if (row[ran - 1].perf_zero)
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d(坏PERF样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
                       (int)row[ran - 1].eng_avg, (int)row[ran - 1].perf_zero,
                       (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
                       (row[ran - 1].errs ? "ENGINE-ERR" :
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
        else
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d cpu/frm=%d fps=%d -> 60fps %s\r\n",
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
                       (int)row[ran - 1].eng_avg, (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
                       (row[ran - 1].errs ? "ENGINE-ERR" :
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
        if (row[ran - 1].errs) { stop_n = n; break; }
        if (row[ran - 1].fps >= 60u) { last60 = n; best = ran - 1; }
        if (row[ran - 1].fps >= 55u) last55 = n;
        else { stop_n = n; break; }                    /* fps < 55：停止升档 */
    }

    /* ---- 汇总表 ---- */
    bsp_printf("\r\n  ---- 同屏精灵数 vs 帧率（每档 %d 帧；eng/cpu/period 单位=100MHz 周期） ----\r\n",
               STRESS_FRAMES);
    bsp_printf("  spr   frames  ins/frm  eng/frm  cpu/frm  period   fps    fps(period) evict%%  verdict\r\n");
    bsp_printf("  (eng/frm 列: 记账帧逐条等 DONE 后采样 BLT_PERF 求和;"
               " '!'=有 PERF 读回 0/异常的坏样本(已单独计数,未计入求和), '?'=一条有效样本都没采到)\r\n");
    for (r = 0; r < ran; r++) {
        bsp_printf("  ");
        pnum(row[r].n, 6);
        pnum(row[r].frames, 8);
        pnum((int)row[r].ins_avg, 9);
        pnum((int)row[r].eng_avg, 8);
        bsp_printf("%c", (row[r].perf_good == 0) ? '?' : (row[r].perf_zero ? '!' : ' '));
        pnum((int)row[r].cpu_avg, 9);
        pnum((int)row[r].period_avg, 9);
        pnum((int)row[r].fps, 7);
        pnum((int)row[r].fps_period, 13);
        ppct(row[r].evict_avg, row[r].cpu_avg, 8);
        bsp_printf("%s\r\n", row[r].errs ? "ENGINE-ERR" :
                            (row[r].fps >= 60u ? "OK" : "FAIL(<60fps)"));
    }
    if (last60 == 0)
        bsp_printf("\r\n  MAX N @60FPS = 0（连 N=25 都不到 60fps）\r\n");
    else if (stop_n)
        bsp_printf("\r\n  MAX N @60FPS = %d（下一档 N=%d fps<55 -> 停止升档；N=%d 时 fps>=55）\r\n",
                   last60, stop_n, last55);
    else
        bsp_printf("\r\n  MAX N @60FPS = %d（最后一档仍 >=60fps，未探到上限）\r\n", last60);

    /* 达到 60fps 的最高档的账（eng/frm、cpu/frm、cache_evict 占比、指令条数） */
    if (best >= 0) {
        uint32_t per_spr = (uint32_t)row[best].cpu_avg / (uint32_t)row[best].n;
        uint32_t lim     = per_spr ? ((uint32_t)FRAME_TICKS / per_spr) : 0u;
        uint32_t eng_pm  = row[best].cpu_avg ? (row[best].eng_avg * 1000u) / row[best].cpu_avg : 0u;
        uint32_t ev_pm   = row[best].cpu_avg ? (row[best].evict_avg * 1000u) / row[best].cpu_avg : 0u;

        bsp_printf("  本档 N=%d: ins/frm=%d eng/frm=%d%s (占 cpu %d.%d%%) cpu/frm=%d "
                   "cache_evict=%d ticks/帧 (占 cpu %d.%d%%)\r\n",
                   row[best].n, (int)row[best].ins_avg, (int)row[best].eng_avg,
                   (row[best].perf_good == 0) ? "(NA:未采到有效 PERF)"
                                              : (row[best].perf_zero ? "(有坏样本,见表)" : ""),
                   (int)(eng_pm / 10u), (int)(eng_pm % 10u), (int)row[best].cpu_avg,
                   (int)row[best].evict_avg, (int)(ev_pm / 10u), (int)(ev_pm % 10u));
        bsp_printf("  60fps 预算 %d 周期/帧 -> 本档每精灵 %d 周期（每指令 %d），据此理论同屏上限 ≈ %d 精灵\r\n",
                   (int)FRAME_TICKS, (int)per_spr,
                   (int)(row[best].ins_avg ? ((uint32_t)row[best].cpu_avg / row[best].ins_avg) : 0u),
                   (int)lim);
    }

    if (ran == 0 || row[ran - 1].errs) g_fail++;
}

/* =========================================================================
 * [demo] 简化版无限演示：保持 HDMI 上有动画（跑完压测/汇总之后才进入）
 * 用和压测同一条帧路径（默认逐条下发+每条等 DONE，帧末整条指令边界校验 +
 * 哨兵自检），所以演示期间也一直在做"引擎是否还正常"的自检；连续出错就退回
 * CPU 搬块，HDMI 不黑屏。
 * ========================================================================= */
static void demo_loop(void)
{
    int i, f = 0, errs = 0, cpu_mode = 0;
    const int n = STRESS_DEMO_N;

    stress_prepare(n);
    if (g_blt_alive) {
        if (blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG) != 0) cpu_mode = 1;
    } else {
        cpu_mode = 1;
    }
    if (cpu_mode) bsp_printf("[demo] 引擎不可用，直接用 CPU 搬块（HDMI 动画继续）\r\n");

    for (;;) {
        uint64_t t0 = tick();

        if (!cpu_mode) {
            int rc = stress_frame(n, f, 0, 0, 0);
            if (rc != 0) {
                errs++;
                /* 任何中止都要打印现场并把 FIFO 拉回整条指令边界（不留残字给引擎），
                 * 否则下一帧会带着残字开跑，一路错位下去。 */
                op_fail(rc, "demo frame");
                if (errs >= 3) {
                    cpu_mode = 1;
                    bsp_printf("[demo] 引擎连续出错(最后 rc=%d)，改用 CPU 搬块（HDMI 动画继续）\r\n", rc);
                }
            }
        }
        if (cpu_mode) {
            /* CPU 兜底：擦旧块 + 画新块（只为 HDMI 不黑屏，不做任何判定） */
            for (i = 0; i < n; i++) {
                int sl = i & (STRESS_NSLOT - 1);
                int w  = (int)s_sprw[sl];
                int h  = (int)s_sprh[sl];

                fill_rect_cpu(FB_BASE, FB_STRIDE, sp_px[i], sp_py[i], w, h, (uint16_t)STRESS_BG);
                spr_move(i, f);
                fill_rect_cpu(FB_BASE, FB_STRIDE, sp_x[i], sp_y[i], w, h, s_sprc[sl]);
                sp_px[i] = sp_x[i];
                sp_py[i] = sp_y[i];
            }
            cache_evict();          /* CPU 写过 DDR -> 挤出 D$，屏幕内容才与内存一致 */
        }
        frame_throttle(t0);
        f++;
    }
}

/* ======================= 汇总 ======================= */
static void print_summary(int fails)
{
    if (fails == 0)
        bsp_printf("\r\n========== fulltest ALL PASS ==========\r\n");
    else
        bsp_printf("\r\n========== fulltest FAILED: %d ==========\r\n", fails);
}

/* ======================= [6] 驱动 ======================= */
static void run_group_abcd(void)
{
    bsp_printf("\r\n---------- [6a] A. FILL 边界测试 ----------\r\n");
    tf_a1(); tf_a2(); tf_a4(); tf_a3();

    bsp_printf("\r\n---------- [6b] B. COPY 边界测试 ----------\r\n");
    tb1(); tb2(); tb3(); tb5(); tb4();      /* B4 整屏会清掉 FB1，排在最后 */

    bsp_printf("\r\n---------- [6c] C. KEY 边界测试 ----------\r\n");
    tc1(); tc2(); tc3(); tc4();

    bsp_printf("\r\n---------- [6d] D. ALPHA 边界测试 ----------\r\n");
    td1(); td2(); td3(); td4();
}

/* ======================= [5] 联通性 + FIFO 突发 ======================= */
static void test_burst(int raw)
{
    int i, stuck = 0;
    const char *tag = raw ? "5c FIFO 突发 300 条 1x1 FILL（裸写，靠 APB 反压）"
                          : "5b FIFO 突发 300 条 1x1 FILL（带 CMD_FIFO_COUNT 等待）";

    SKIP_IF_DEAD(tag);

    /* 目的先铺哨兵，300 个像素各写一个唯一颜色：少一条指令就会露馅 */
    fill_rect_cpu(FB1_BASE, FB_STRIDE, BURST_X, BURST_Y, BURST_COLS, BURST_N / BURST_COLS,
                  (uint16_t)SENT);
    cache_evict();

    g_scene_ctx = 0;                 /* 现场上下文：突发不属于压测帧（只影响出错打印） */
    g_ins_frame = 0;
    g_last_seq  = 0;

    for (i = 0; i < BURST_N; i++) {
        uint32_t dst   = PIX(FB1_BASE, FB_STRIDE, BURST_X + (i % BURST_COLS),
                             BURST_Y + (i / BURST_COLS));
        uint32_t color = 0x4000u + (uint32_t)i;

        if (raw) {
            /* 裸写路径故意不查 COUNT（就是要压 APB 反压）。但每 32 条做一次看门狗：
             * 引擎 ERR、或 FIFO 已满且长时间不消费时停止灌入——否则 CPU 会永久卡在
             * APB store 上（那是唯一无法用 tick 超时救回的等待）。 */
            if ((i & 31) == 0) {
                if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
                if (blt_rd(BLT_CMD_FIFO_COUNT) >= (BLT_CMD_FIFO_DEPTH - 1)) {
                    uint64_t wt = tick();
                    while (blt_rd(BLT_CMD_FIFO_COUNT) >= (BLT_CMD_FIFO_DEPTH - 1)) {
                        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
                        if ((uint32_t)(tick() - wt) > BLT_FAST_TICKS) { stuck = 1; break; }
                    }
                    if (stuck) break;
                }
            }
            blt_push_cmd_raw(BLT_OP_FILL, 0u, dst, 0u, FB_STRIDE, 1u, 1u, 0xFFu, color);
        } else {
            int pr = blt_push_cmd(BLT_OP_FILL, 0u, dst, 0u, FB_STRIDE, 1u, 1u, 0xFFu, color);
            if (pr != 0) { op_fail(pr, "5b burst push"); stuck = 1; break; }
        }
        g_ins_frame++;                 /* 现场计数：只影响出错打印，不影响任何判定 */
        g_last_seq = g_ins_frame;
    }
    if (stuck) {
        bsp_printf("      突发被中止：引擎 ERR / FIFO 长时间不消费（已灌入 %d/%d 条）\r\n",
                   i, BURST_N);
        item(tag, 0u, -1);
        return;
    }
    /* 300 条 = 2400 个字 > FIFO 2048 字：必然触发"满"，这一段就是反压/不丢指令的证据 */
    if (op_fail(blt_wait_done(BLT_TIMEOUT_TICKS), raw ? "5c burst raw" : "5b burst")) {
        item(tag, 0u, -1);
        return;
    }
    cache_invalidate();
    mis_reset();
    for (i = 0; i < BURST_N; i++)
        expect_px(BURST_X + (i % BURST_COLS), BURST_Y + (i / BURST_COLS),
                  rd16(PIX(FB1_BASE, FB_STRIDE, BURST_X + (i % BURST_COLS),
                           BURST_Y + (i / BURST_COLS))),
                  0x4000u + (uint32_t)i);
    item(tag, blt_rd(BLT_PERF), g_mis);
}

/* ======================= main ======================= */
int main(void)
{
    uint32_t ctrl, st, cnt, sink, dt, perf, got;
    uint64_t ta, tb;
    int idx, rc, ok, dead;

    bsp_init();                               /* UART 115200 8N1（与其它 demo 一致） */

    /* ---------------- [1] banner ---------------- */
    bsp_printf("\r\n\r\n***** fulltest v2.2 : 2DRA BitBlt end-to-end + 边界 + 多精灵压测(逐条等DONE/批量开关) *****\r\n");
    bsp_printf("[1] BLT_BASE =0x%x (APB slave0, 引擎寄存器)\r\n", (int)BLT_BASE);
    bsp_printf("    DDR_BASE =0x%x  FB_BASE=0x%x (HDMI 扫描输出)\r\n",
               (int)DDR_BASE, (int)FB_BASE);
    bsp_printf("    FB1_BASE =0x%x  SPRITE_BASE=0x%x  FLUSH_SCRATCH=0x%x (冲刷 %d 字/%d B)\r\n",
               (int)FB1_BASE, (int)SPRITE_BASE, (int)FLUSH_SCRATCH,
               (int)CACHE_EVICT_WORDS, (int)CACHE_EVICT_WORDS * 4);
    bsp_printf("    FB %dx%d RGB565 stride=%d B  size=%d B  FIFO=%d cmds x %d words\r\n",
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES, BLT_CMD_FIFO_DEPTH, BLT_CMD_WORDS);
    bsp_printf("    测试计划: [5]联通性+FIFO突发  [6]A-FILL B-COPY C-KEY D-ALPHA  [7]压测 N=25..800\r\n");

    /* ---------------- [2] 时间基准自检 ---------------- */
    ta   = tick();
    sink = busy_loop(20000u);
    tb   = tick();
    dt   = (uint32_t)(tb - ta);
    g_tb_ok = (dt != 0u && dt < 100000000UL);
    bsp_printf("[2] timebase: CLINT mtime @0x%x %d Hz, 20000-loop=%d ticks (sink=0x%x) -> %s\r\n",
               (int)BSP_CLINT, (int)BSP_CLINT_HZ, (int)dt, (int)sink,
               g_tb_ok ? "PASS" : "FAIL(时间基准异常，已关闭帧节流)");
    if (!g_tb_ok) { g_fail++; }

    /* ---------------- [3] 缓存一致性自检 ---------------- */
    idx = coherency_check();
    if (idx != 0) {
        g_fail++;
        bsp_printf("[3] coherency: FAIL at word %d (FB1 回读值与写入值不一致 -> D$ 一致性有问题)\r\n",
                   idx - 1);
    } else {
        bsp_printf("[3] coherency: PASS (FB1 写 256 字 -> cache_evict -> invalidate -> 回读比对)\r\n");
    }

    /* ---------------- [4] 引擎寄存器探测 + blt_init ---------------- */
    ctrl = blt_rd(BLT_CTRL);
    st   = blt_rd(BLT_STATUS);
    cnt  = blt_rd(BLT_CMD_FIFO_COUNT);
    bsp_printf("[4] reg probe: CTRL=0x%x STATUS=0x%x CMD_FIFO_COUNT=%d IRQ_STATUS=0x%x DBG=0x%x PERF=%d\r\n",
               (int)ctrl, (int)st, (int)cnt, (int)blt_rd(BLT_IRQ_STATUS),
               (int)blt_rd(BLT_DBG_CUR_CMD), (int)blt_rd(BLT_PERF));

    dead = (ctrl == 0xFFFFFFFFUL) || (st == 0xFFFFFFFFUL) || (cnt == 0xFFFFFFFFUL) ||
           (ctrl == 0UL && st == 0UL);
    if (dead) {
        g_blt_alive = 0;
        g_fail++;
        bsp_printf("    警告：读数是全 F / 全 0 -> APB 窗口 0x%x 可能未接通！\r\n", (int)BLT_BASE);
        bsp_printf("    (排查：bitstream 是否已加载、APB slave0 地址译码、BLT_BASE 是否与 soc.h 一致)\r\n");
        bsp_printf("    跳过 blt_init() 与后续全部引擎测试\r\n");
    } else {
        bsp_printf("    APB 窗口已接通：STATUS.DONE(bit1)=%d FIFO_EMPTY(bit3)=%d BUSY(bit0)=%d ERR(bit2)=%d\r\n",
                   (int)((st >> 1) & 1u), (int)((st >> 3) & 1u),
                   (int)(st & 1u), (int)((st >> 2) & 1u));
        blt_init();
        bsp_printf("    blt_init(): SOFT_RST->0->清 IRQ->CTRL.GO 写一次; 现在 CTRL=0x%x STATUS=0x%x\r\n",
                   (int)blt_rd(BLT_CTRL), (int)blt_rd(BLT_STATUS));
    }

    /* ---------------- [5] 寄存器/指令联通性 ---------------- */
    bsp_printf("\r\n---------- [5] 联通性 + 指令 FIFO 背压 ----------\r\n");
    if (g_blt_alive) {
        bsp_printf("  [5a] FILL %dx%d color=0x%x -> SPRITE+0xA000 (0x%x)\r\n",
                   LINK_W, LINK_H, (int)LINK_COLOR, (int)SA_LINK);
        rc   = blt_fill(SA_LINK, 32u, LINK_W, LINK_H, LINK_COLOR);
        perf = g_perf;
        if (rc == 0) {
            cache_invalidate();
            got = rd16(SA_LINK);
            ok  = (got == LINK_COLOR);
            bsp_printf("      STATUS=0x%x CMD_FIFO_COUNT=%d DBG_CUR_CMD=0x%x(期望 op=FILL=0x%x) PERF=%d cycles\r\n",
                       (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
                       (int)blt_rd(BLT_DBG_CUR_CMD), (int)BLT_OP_FILL, (int)perf);
            item("5a link FILL 16x8 -> SPRITE+0xA000", perf, ok ? 0 : 1);
            if (!ok) bsp_printf("      像素(0,0)=0x%x 期望 0x%x\r\n", (int)got, (int)LINK_COLOR);
        } else {
            op_fail(rc, "5a link FILL");
            item("5a link FILL 16x8 -> SPRITE+0xA000", 0u, -1);
            g_blt_alive = 0;
        }
        if (g_blt_alive) test_burst(0);
        if (g_blt_alive) test_burst(1);
    } else {
        bsp_printf("  [5] SKIP（APB 窗口未接通）\r\n");
        g_fail += 3;
    }

    /* ---------------- [6] A/B/C/D 边界测试 ---------------- */
    if (g_blt_alive) {
        run_group_abcd();
    } else {
        bsp_printf("[6] SKIP：引擎未响应（见 [4]/[5]）\r\n");
        g_fail += 17;
    }

    /* ---------------- [7] 多精灵压测 ---------------- */
    stress_all();

    /* ---------------- [8] 汇总 ---------------- */
    print_summary(g_fail);

    /* ---------------- [demo] 保持上屏：简化版无限动画 ---------------- */
    bsp_printf("[demo] 测试与汇总结束，进入简化版无限演示（12 精灵 KEY/ALPHA 循环，程序不退出）\r\n");
    bsp_printf("[demo] 说明：此循环只负责让 HDMI 持续有动画，不再做任何判定与打印，也不再返回。\r\n");
    demo_loop();

    /* demo_loop() 内部是无限循环，正常不会走到这里 */
    return 0;
}
