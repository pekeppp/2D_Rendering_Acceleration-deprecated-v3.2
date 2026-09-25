# 显示列表 / 描述符表（Display List）设计规格 —— S2

> 状态：**设计规格（本文档不含 RTL，不实现）**。落地版本号建议 `v2.11`。
> 上游动机 = 板级实测的"每块 305 拍命令开销"；下游 = S3 掩码跳过（见 §13）。
> 相关文档：`doc/perf_probe_report.md`（只读探针）、`rtl/功能清单.md` §22/§23（打包乒乓、写突发合并）、
> `doc/加速器设计规划_RTL实现.md` §4（寄存器与指令契约）、`software/blt_drv.c`（现有 CPU 下发路径）。

---

## 1. 一句话与不变式

**一句话**：在 DDR 里放一张"精灵描述符表"，硬件取指器（DFU）把每条 16B 描述符**展开成现有的 8 字命令**、推进**现有的指令 FIFO**，引擎 FSM 一行不改 —— 换掉的只是"谁把命令写进 FIFO"（CPU 的 9 次 AXI-Lite 事务 → 硬件的 1 次 16B 读）。

**贯穿全文的四条不变式（S2 不得破坏）**：

| # | 不变式 | 为什么 |
|---|---|---|
| I1 | 命令字格式仍是 8×32bit，引擎 FSM / 像素通路 / 地址生成**零改动** | 已收敛的逻辑不再动，S2 的风险面只剩"新增的取指器" |
| I2 | `cmd_fifo` 是唯一的命令入口；DFU 与 CPU 在**整条命令粒度**上互斥（不会交错半个命令） | 8 字命令的对齐不能被打断 |
| I3 | 每精灵的写顺序 = 描述符顺序；写完成判据仍是 `ST_WDWAIT` + `b_pending`/`wr_commit_idle` | 写后读危险（z 序闪）不得回归 |
| I4 | 描述符预取/译码允许跑在引擎前面，但**只提前"进 FIFO"**，不提前任何一次写 | 预取不影响可见顺序 |

---

## 2. 动机：实测数字与目标

### 2.1 现状（板级 + 只读探针实测）

每块（一次命令）成本模型：

```
每块周期 ≈ 305（命令开销，与尺寸无关） + 像素数 × k
k = 1.00 FILL / 2.12 ALPHA / 1.70 KEY   （@1 像素/拍，板级实测）
```

16×16 块（demo 当前精灵尺寸，256 px）：

| op | 每块周期 = 256×k + 305 | 其中命令开销 | 占比 |
|---|---|---|---|
| FILL（k=1.00） | 256 + 305 = 561 | 305 | **54%** |
| KEY（k=1.70） | 435 + 305 = 740 | 305 | 41% |
| ALPHA（k=2.12） | 543 + 305 = 848 | 305 | 36% |

帧预算口径（与"2,600 → 5,300 块@60fps"一致的算法）：当前每帧 ≈ 2,600 块 × 561 拍 ≈ **1.46 M 拍**。
若每块开销 305 → 20，则每块 276 拍 ⇒ 1.46 M / 276 ≈ **5,300 块/帧**（+104%）。

### 2.2 为什么必须新增描述符（而不是把字段塞进命令）

现有命令格式**已满**（`software/blt_regs.h::blt_cmd_t`，32B = 8 字，`_Static_assert` 锁定）：

| 字 | 位域 | 含义 |
|---|---|---|
| w0 | [1:0] | op：0=COPY 1=FILL 2=ALPHA 3=KEY；[31:2] 当前未用（`dbg_opword` 只显示） |
| w1 | [31:0] | src 字节地址（FILL 忽略） |
| w2 | [31:0] | dst 字节地址 |
| w3 | [31:0] | src 行距（字节） |
| w4 | [31:0] | dst 行距（字节） |
| w5 | [15:0]/[31:16] | W / H（像素） |
| w6 | [7:0] | alpha（仅 ALPHA） |
| w7 | [15:0] | FILL=填充色；KEY=键色；其余忽略 |

w0 的 [31:2] 虽然空着，但**放不下**一组"位置 + 图集 id + 逐精灵 alpha + 混合/op 标志 + 透明掩码"的字段，
而且它也不解决真正的开销来源：**每精灵一次 CPU 下发**。所以选择"表 + 硬件展开"。

### 2.3 305 拍的构成（**需要原型实测确认**，见 §14.1）

从仿真可确认的部分（`tb_perf_probe` 直方图，32×32 FILL，S1 之后 1,199 拍）：

```
引擎自身每条命令的地板 = POP_8WORDS 15 + DEC 1 + EXEC_INIT 1
                        + ROW_GAP 96（32 行 × 3）+ DRAIN 32 + WDWAIT 30  = 175 拍
按行数折算到 16 行 ≈ 15+1+1+48+16+30 = 111 拍
```

推定模型：`305 ≈ 111（引擎自身）+ ~190（CPU 侧 9 次 AXI-Lite 事务 + FIFO 被"边写边喂"的 POP 等待）`。
**S2 能消掉的是后面那 ~190**；前面的 ~111 是引擎逐命令的固有开销，S2 不动 FSM 就拿不掉 —— 这是
§14.1 的第一条待测量项，也是 §14.2 "5,300 块目标需要追加一步"的原因。

---

## 3. 总体架构

```
        CPU（软件）
          │  ①每帧 3~4 次 MMIO：DL_BASE*、DL_COUNT、DL_CTRL.GO
          ▼
   ┌──────────────┐   AXI-Lite 寄存器（0x4C~0x80）
   │ blt_regs_    │──────────────┐
   │ axi_lite     │              │ 配置/状态
   └──────────────┘              ▼
          ▲              ┌───────────────────┐   16B/拍（正好 1 个 128bit beat）
          │ 状态         │  DFU 取指器         │◄──────── DDR：描述符表
          │              │  F_CHUNK/F_AR/…    │          （DL_BASE0/1，16B/条）
          │              └───────┬───────────┘
          │                      │ 展开
          │                      ▼
          │              ┌───────────────┐   ATTR FIFO（S3 预留，见 §13）
          │              │  8 字命令展开  │──────────►（引擎侧 hook，S2 不消费）
          │              └───────┬───────┘
          │                      │ 8 字，整条命令粒度互斥
          │                      ▼
          │              ┌───────────────┐        ┌────────────────────┐
          └──────────────│  cmd_fifo     │───────►│ blt_engine_fsm     │ ← 一行不改
                         │（CPU 也走这里）│        │ POP→DEC→EXEC→WDWAIT│
                         └───────────────┘        └─────────┬──────────┘
                                                            │ pixel_path
                                                            ▼
                        axi_rd_master（fg/bg/**desc** 三流共用，见 §7） → 像素源读
                        axi_wr_master（写，S1 尾冲刷提示已生效）
```

**新增模块**：`rtl/dl_fetch.v`（DFU：取指 + 展开 + 边界检查 + 看门狗）。
**改动模块**：`rtl/blt_regs_axi_lite.v`（新寄存器 + cmd_fifo 写口仲裁）、`rtl/blt_top.v`（连线 + 写口 mux）、
`rtl/axi_rd_master.v`（第三路 tag + desc FIFO 写口）——**`rtl/blt_engine_fsm.v` / `rtl/pixel_path.v` /
`rtl/blt_addr_gen.v` / `rtl/axi_wr_master.v` 不动**。

---

## 4. 寄存器映射（新增，偏移接在现有 0x48 之后）

现有映射见 `rtl/blt_regs_axi_lite.v` 头注释（0x00~0x48，清屏引擎占 0x2C~0x48）。
新增块从 **0x4C** 开始，地址位宽 `ADDR_W=12` 仍够用。所有寄存器复位值 = 0（除注明）。

| 偏移 | 名字 | W/R | 位域 | 语义 |
|---|---|---|---|---|
| 0x4C | `DL_BASE0` | RW | [31:4] 列表 A 基地址；[3:0] 只写 0（读回 0） | 16B 对齐；未对齐写入 → 忽略 + `DL_ERR.DESC_RANGE` |
| 0x50 | `DL_BASE1` | RW | [31:4] 列表 B 基地址 | 乒乓的另一张 |
| 0x54 | `DL_COUNT` | RW | [15:0] 本列表描述符条数（1~4095） | 上限 4095 = `DL_COUNT_MAX`；0 = 合法"空列表"（GO 后立即 DONE，不取指） |
| 0x58 | `DL_CTRL` | W/RW | bit0 `GO`（1 拍脉冲，写 1 启动）<br>bit1 `ABORT`（1 拍脉冲，停止取指/展开）<br>bit2 `BUF_SEL`（RW，读回；0=用 BASE0，1=用 BASE1）<br>bit3 `IRQ_EN`（列表结束中断使能，RW）<br>bit4 `AUTO_GO`（默认 1：DFU 首条命令入队后自动置 `CTRL.GO`）<br>bit5 `STRICT_BOUNDS`（默认 1：越界即报错停机） | `GO` 在 `BUSY=1` 时被忽略（不排队、不报错）；`ABORT` 只停"还没进 FIFO 的命令"，已入队的照跑（见 §8.4） |
| 0x5C | `DL_STATUS` | R | bit0 `BUSY`（取指器活动）<br>bit1 `DONE`（电平：本列表全部描述符已展开 + 引擎 `done_out`=1，即写已提交）<br>bit2 `ERR`（锁存，见 0x60）<br>bit3 `ABORTED`<br>bit4 `STALL`（正在等 cmd_fifo 空间或等引擎）<br>[31:16] `CONSUMED`（已展开下发的描述符数，实时） | `DONE` = "可以安全改写这张列表"的硬件判据；`DONE` 在写 `DL_CTRL.GO` 或写 `DL_BASE*` 时清 0 |
| 0x60 | `DL_ERR` | R/W1C | bit0 `DESC_RANGE`（描述符地址越界/未对齐）<br>bit1 `GEOM_INDEX`（`SPR_ID ≥ DL_GEOM_MAX`）<br>bit2 `GEOM_RANGE`（几何表地址越界/未对齐）<br>bit3 `SPRITE_BOUNDS`（X/Y/W/H 越屏且未允许裁剪）<br>bit4 `WATCHDOG`（单条描述符超 `DL_TIMEOUT`）<br>bit5 `AXI_RRESP`（R 通道非 OKAY）<br>bit6 `DESC_COUNT`（条数超上限/END 与 COUNT 冲突）<br>bit7 `ZERO_SIZE`（W 或 H = 0）<br>[23:16] 出错时的描述符序号<br>[31:24] 保留 | 任一位置起 ⇒ `DL_STATUS.ERR=1` 并停机 |
| 0x64 | `DL_FAULT_ADDR` | R | [31:0] 出错时正在访问的地址（描述符或几何表） | 诊断用 |
| 0x68 | `DL_GEOM_BASE` | RW | [31:4] 精灵几何表基地址 | 16B/条，见 §5.2 |
| 0x6C | `DL_GEOM_MAX` | RW | [15:0] 几何表条目数（1~1023）；0 = 关闭几何表（此时描述符必须自带 W/H/stride，见 §5.1 的 `SIZE_OVR`） | `SPR_ID` 的合法上界 |
| 0x70 | `DL_DST_BASE` | RW | [31:0] 本列表的目标缓冲基地址（= 软件给 `DRAW_SEL` 选中的那块 FB 的基址） | 描述符的 X/Y 相对它解析；**不由硬件从 `DRAW_SEL` 推导**，避免 FB 基址表再进硬件 |
| 0x74 | `DL_CFG` | RW | bit0 `PREFETCH_EN`（默认 1）<br>bit1 `GEOM_CACHE_EN`（默认 1）<br>[7:4] `CHUNK`（每次 AXI 读几条描述符，默认 8 = 128B）<br>[11:8] `FIFO_WM`（预取水位，默认 4：剩余 ≤4 条就发下一块）<br>[15:12] 保留 | |
| 0x78 | `DL_TIMEOUT` | RW | [15:0] 单条描述符看门狗上限（core 拍，默认 4096；0 = 关闭） | 4096 拍 ≈ 47µs@87MHz |
| 0x7C | `DL_PERF` | R | [31:0] 上一次列表的 core 周期数（GO→DONE） | 与 `PERF 0x1C` 同风格 |
| 0x80 | `DL_VERSION` | R | [7:0]=0x02（S2）、[15:8]=0x00、[31:16]=0x0210 | 软件能力探测 |

**对既有寄存器的两处追加**（不改既有位）：

- `IRQ_STATUS 0x10` 追加 **bit2 = `DL_DONE`**（列表结束，W1C）。
- `IRQ_EN 0x14` 追加 **bit2 = `DL_DONE` 使能**。

**读写语义要点**：

1. `DL_BASE0/1`、`DL_COUNT`、`DL_GEOM_*`、`DL_CFG`、`DL_TIMEOUT` 只在 `DL_STATUS.BUSY=0` 时被 DFU 采样；
   `BUSY=1` 期间写入被接受（寄存器更新）但**本列表不生效**，并在 `DL_STATUS` 置 `STALL`？——**不**：为免歧义，
   规定 `BUSY=1` 时写这些寄存器**被忽略**（读回仍是旧值），软件必须先 `ABORT` 或等 `DONE`。
2. `BUF_SEL` 指向的那张列表在 `BUSY=1` 期间**禁止被改写**：硬件层面 `DL_BASE0/1` 写入已被第 1 条挡住，
   DDR 里的表内容由软件保证（§10）。
3. `DL_ERR` 是 W1C；写 1 清对应位；全部清 0 且 `DL_STATUS.ERR` 的锁存也随之清（`ERR = |DL_ERR`）。
4. `GO` 与 `ABORT` 都是**写 1 产生 1 拍脉冲**，写 0 无副作用；不要用读改写（`|=`）去点它们。

---

## 5. 描述符记录与几何表

### 5.1 描述符记录 = **16 字节 = 4 字 = 恰好 1 个 128bit AXI beat**

小端。所有"保留"位**必须写 0**，硬件读入后忽略（前向兼容：将来 S3/S4 直接在这些位上长功能）。

```
dw0  [31:0]  X[15:0]  (signed, 像素)   |  Y[31:16] (signed, 像素)
dw1  [15:0]  SPR_ID   (几何表索引)
     [31:16] FLAGS
dw2  [15:0]  KEY[15:0]  (0xFFFF = 用几何表的默认键色)
     [23:16] ALPHA[7:0] (逐精灵透明度；仅 OP=ALPHA 有效)
     [31:24] PRIO[7:0]  (0~255，仅用于软件排序/调试；本版本硬件不排序，保留)
dw3  [15:0]  MASK_ID[15:0]  (S3 掩码表索引；S2 必须原样送出，见 §13)
     [23:16] W_OVR[7:0]     (0 = 用几何表宽；1~255 = 覆盖宽，像素)
     [31:24] H_OVR[7:0]     (0 = 用几何表高)
```

`dw1[31:16] FLAGS` 逐位：

| 位 | 名 | 语义 |
|---|---|---|
| [1:0] | `OP` | 00=COPY 01=FILL 10=ALPHA 11=KEY —— **与 `w0[1:0]` 编码逐位一致**，直接搬运，不做推导 |
| 2 | `MIRROR_X` | 源行内水平镜像（DFU 侧调整 src 起点，或留给 S3 的像素通路；S2 建议先报 `ERR` = "未实现"，见 §14.6） |
| 3 | `MIRROR_Y` | 同上，垂直 |
| 4 | `CLIP_EN` | 越屏时自动裁剪成屏内矩形；0 且 `STRICT_BOUNDS=1` ⇒ 报 `SPRITE_BOUNDS` |
| 5 | `SIZE_OVR` | 1 = 用 `dw3` 的 `W_OVR/H_OVR` 而非几何表尺寸 |
| 6 | `SRC_OFF_EN` | 1 = `dw3[15:8]`… **保留**（S2 一律 0；atlas 内的子矩形走几何表） |
| 7 | `MASK_EN` | **S3 预留**：启用逐像素/逐块掩码跳过 |
| [9:8] | `MASK_MODE` | **S3 预留**：00=1bit 跳过(0 跳过) 01=1bit 跳过(1 跳过) 10=8bit alpha 阈值 11=保留 |
| 10 | `END_OF_LIST` | 本描述符是列表最后一条（与 `DL_COUNT` 取**较小者**生效） |
| 11 | `IRQ_AFTER` | 本条命令完成后置 `IRQ_STATUS[2]`（用于分段的软同步） |
| 12 | `CHAIN` | 下一条描述符在 `dw3` 指定的链接地址（本版本保留，必须 0） |
| [15:13] | 保留 | 必须 0 |

**FILL 的语义**：`X/Y/OP=01` + `dw2[15:0]` 作为填充色（此时 `KEY` 字段复用为 COLOR）。
**COPY/ALPHA/KEY 的源**：`SRC = GEOM.ATLAS_BASE + (SY + r)*GEOM.ATLAS_STRIDE + SX*2`。

### 5.2 精灵几何表（atlas geometry table）— 16B/条

`DL_GEOM_BASE + SPR_ID*16`，由 `DL_GEOM_MAX` 界定合法范围。可被 16 条 × 16B 的 BRAM cache 缓存（`DL_CFG.GEOM_CACHE_EN`）。

```
gw0  [31:0] ATLAS_BASE    源（图集/精灵）起始字节地址，16B 对齐建议
gw1  [15:0] ATLAS_STRIDE  源行距（字节）
     [31:16] KEY_DEFAULT  默认色键（RGB565）
gw2  [15:0] W              精灵宽（像素，1~255）
     [31:16] H             精灵高（像素，1~255）
gw3  [15:0] SX             在 atlas 内的列偏移（像素）
     [31:16] SY            在 atlas 内的行偏移（像素）
     （若要做"一条几何表条目 = 整张 atlas + 子矩形"，就靠 SX/SY + W/H 组合；
       本版本不做 sprite sheet 的自动切分，切分由软件填表）
```

> 为什么几何表要单独一张表：**同一精灵会被画很多次**（demo 里子弹/敌机/战机各一张图，
> 一帧几十次）。把 `ATLAS_BASE/STRIDE/W/H/KEY` 放进 16B 描述符会让描述符膨胀到 28B+ 且
> 每帧的写带宽翻倍；放进表里则每条描述符只带一个 16bit 索引，且几何表条目**整个 demo 生命周期不变**（cache 命中 ≈100%）。

### 5.3 展开：描述符 → 8 字命令（DFU 内的一张纯组合映射表）

| 命令字 | 来源 |
|---|---|
| `w0` | `{30'd0, FLAGS.OP}` |
| `w1` | `OP==FILL ? 32'd0 : (GEOM.ATLAS_BASE + SY*GEOM.ATLAS_STRIDE + SX*2)`（`MIRROR_*` 置位时另行调整，见 §14.6） |
| `w2` | `DL_DST_BASE + Y*FB_STRIDE + X*2`（**带符号**加；越屏由 `CLIP_EN` 先裁剪再算） |
| `w3` | `GEOM.ATLAS_STRIDE`（FILL 忽略） |
| `w4` | `FB_STRIDE`（来自寄存器：新增只读 `DL_DST_STRIDE`，或复用 0x70 的高半字 —— **建议在 0x70 上加 [31:16] `DST_STRIDE_PX`**，见 §14.7） |
| `w5` | `{H, W}`（`SIZE_OVR` 时取 `dw3`，否则取几何表） |
| `w6` | `{24'd0, ALPHA}` |
| `w7` | `OP==FILL ? COLOR : KEY`（`KEY==0xFFFF` 时取 `GEOM.KEY_DEFAULT`） |

展开后 `w2` 的非 16B 对齐、半词掩码等**全部仍由既有 `blt_addr_gen` + `pixel_path` 处理**（它们本来就吃任意字节地址）——
这正是"引擎零改动"的关键：描述符只负责产生"和 CPU 今天写的一模一样的 8 个字"。

---

## 6. 取指 / 展开状态机（`rtl/dl_fetch.v`）

```
F_IDLE      : 等 DL_CTRL.GO 上升沿。锁存 DL_BASE*/COUNT/GEOM*/DST_BASE/CFG 到影子寄存器，
              consumed<=0, ERR/DONE 清 0, BUSY<=1。
F_CHUNK     : 算下一块的 {desc_addr, beats}：beats = min(CHUNK, COUNT-consumed, 到 4KB 边界剩余, 剩余 128B 对齐)。
              beats==0 ⇒ 去 F_END。
F_AR        : 发一笔 AXI 读（128bit INCR，arsize=4，同 axi_rd_master 口径）。等 arready。
F_FILL      : 每个 R beat（16B = 一条描述符）写入 desc FIFO；rresp!=OKAY ⇒ F_ERR(AXI_RRESP)。
              rlast 或 beats 收满 ⇒ 回 F_CHUNK（若 FIFO 还有空间且还需预取）或去 F_HEAD。
F_HEAD      : 从 desc FIFO 取一条描述符（FIFO 空则等；同时按 FIFO_WM 触发 F_CHUNK 的预取）。
              做四项检查（§8.1），任一失败 ⇒ F_ERR。
F_GEOM      : 需要几何表条目：查 cache（GEOM_CACHE_EN）。命中 ⇒ 直接展开；
              未命中 ⇒ 发一笔 16B 读，等 R beat，写回 cache，再展开。
F_PUSH      : 把展开出的 8 个字按 w0→w7 顺序写入 cmd_fifo 写口（每拍 1 字；8 字 = 8 拍）。
              写口被 CPU 占用或 FIFO 满 ⇒ 停在这里（DL_STATUS.STALL=1）。写完 consumed++。
F_END       : consumed==COUNT 或遇到 END_OF_LIST ⇒ 停取指。
              等引擎 done_out（= cmd_fifo 空 & 引擎 IDLE & wr_commit_idle）⇒ DL_STATUS.DONE<=1, BUSY<=0。
F_ERR       : 锁存 DL_ERR/DL_FAULT_ADDR/序号，停取指；**已入 cmd_fifo 的命令继续跑完**。
              BUSY 保持 1 直到引擎 done_out（否则软件会以为可以立刻改列表），然后 BUSY<=0, ERR=1。
F_ABORT     : 同 F_ERR，但置 ABORTED 而非 ERR；不写 DL_ERR。
```

**与 cmd_fifo 的接口（I2 的落地）**：

- DFU 通过 `dl_cmd_wr_en / dl_cmd_wr_data` 写；顶层把 `fifo_wr_en/fifo_wr_data` 与它做 mux 后接 `cmd_fifo.wr_en/din`。
- 仲裁规则：**整条命令粒度**。DFU 在 `F_PUSH` 的第一拍申请端口，获得后一直持有到第 8 个字写完；
  CPU 侧的 `CMD_FIFO_DATA` 写在此期间把 `s_axil_awready` 压低（AXI 层反压，不是静默丢弃）。
  反向：CPU 正在写一条命令（`regs` 内部"命令进行中"标志）时，DFU 等它写完 8 个字再拿端口。
  ⇒ 任何时刻 FIFO 里的字序列都是"整条整条"的命令，`cmd_pop` 的 8 字对齐（`pcnt 0..7`）永不错位。
- `AUTO_GO`：DFU 推入第一条命令后自动置 `ctrl_go`（等价于软件写 `CTRL.GO`），
  这样软件只需 `DL_CTRL.GO` 一次即可跑完整张表；若软件坚持自己管 `CTRL.GO`，把 `AUTO_GO=0`。

---

## 7. 预取策略与读通道共享

### 7.1 预取参数

| 项 | 值 | 理由 |
|---|---|---|
| 块大小 `CHUNK` | 8 条 = 128 B = 8 拍 INCR | 一条 128bit beat 正好一条描述符；128B 突发是 DDR 的甜点，且不跨 4KB |
| 水位 `FIFO_WM` | 剩余 ≤ 4 条就发下一块 | 双缓冲语义：一块在飞、一块在解 |
| desc FIFO | 深度 16 × 16B（256B，BRAM） | 2 个块 + 抖动余量；推断 BRAM（同 `sync_fifo` 的同步读形式） |
| geometry cache | 16 条 × 16B，直接映射（`SPR_ID[3:0]`） | demo 的精灵种类 < 16，命中率 ≈100% |
| 允许在飞 | desc 读 ≤ 1 笔未完成 | 与像素读共享 `axi_rd_master`，不抢占信用 |

**预取跑多前**：最多"已进 FIFO 未执行"的命令条数 = `cmd_fifo` 深度（256 字 = 32 条）。
DFU 可以一路把 32 条命令灌满（这就是想要的：引擎永不停），但**不会再往前**——因为唯一的出口是 cmd_fifo。

### 7.2 读通道共享（三流共用一个 AXI 读主机）

现状（`ARC_2DRA/rtl/ddr3_example_top.v`）：

```
CPU ──c_─┐
         ├─ u_rd_arb_l1 (axi_rd_arb) ──c_─┐
BitBlt ──s_─┘   (s_hold=0)               ├─ u_axi_rd_arb (axi_rd_arb) ── DDR 控制器读口
                     扫描输出 ──s_─ (s_hold=整行取数期间钳住)
```

BitBlt 的读主机（`blt_ar_*`）挂在 **L1 仲裁器的 s_ 侧**，而 L1 与扫描输出再在 DDR 仲裁器上汇合（`c_` 侧=L1 流，`s_`=扫描输出）。
S2 新增的描述符读**不新增 AXI 端口**，而是复用 `axi_rd_master`：

- `rd_bg`（1bit tag）扩成 `rd_sel[1:0]`：`00=fg 01=bg 10=desc`，新增 `desc_rvalid` 写口进 desc FIFO。
- 仲裁（`axi_rd_master` 内部，发 AR 时按下述优先级挑一路，每拍最多 1 笔）：
  **fg > bg > desc**；任何一路等待超过 `AGE_MAX=64` 拍则提权一笔（防饿死）。
- 为什么 desc 最低：像素源读在引擎关键路径上（缺词直接停像素，`STALL_FG/BG`），而 desc 读有 16 条 FIFO 垫底，
  迟 100 拍也无感；但**不能不给**，所以有 age 提权。
- 与扫描输出：机制不变（`axi_rd_arb` 的 owner 规则 + `s_hold` + `WAIT_MAX` 有界优先 + `LEAK_TO` 兜底），
  S2 只是让 L1 侧多了一点读流量：每精灵 +16B（几何表未命中再 +16B）。
  量化：16×16 KEY 精灵一帧的读 ≈ 512B(src) + 16B(desc) = +3.1%；整屏 FILL 场景下 desc 流量占比 <0.5%。
  **扫描输出的欠载证据看 `SCAN_DBG 0x20`**：S2 上板后该寄存器仍须恒 0，否则回退 `PREFETCH_EN=0` 做二分。

---

## 8. 畸形列表保护

### 8.1 检查清单（每条描述符展开前，`F_HEAD` 内做，全部**组合**、单拍完成）

| 检查 | 条件 | 违反时 |
|---|---|---|
| 条数上限 | `CONSUMED < min(DL_COUNT, DL_COUNT_MAX=4095)` | 到时正常结束（不报错）；`DL_COUNT > 4095` ⇒ `DESC_COUNT` |
| 描述符地址 | `addr ∈ [DL_BASE, DL_BASE + COUNT*16)` 且 `addr[3:0]==0` 且在程序化的 DDR 窗口 `[DL_MIN, DL_MAX]` 内 | `DESC_RANGE` + `DL_FAULT_ADDR` |
| 几何索引 | `SPR_ID < DL_GEOM_MAX`（`DL_GEOM_MAX=0` 时改由 `SIZE_OVR` 必须为 1，否则 `GEOM_INDEX`） | `GEOM_INDEX` |
| 几何地址 | `DL_GEOM_BASE + SPR_ID*16` 在窗口内且 16B 对齐 | `GEOM_RANGE` |
| 尺寸 | `W!=0 && H!=0`；`W≤FB_W && H≤FB_H` | `ZERO_SIZE` / `SPRITE_BOUNDS` |
| 位置 | `X ∈ [-W, FB_W)`、`Y ∈ [-H, FB_H)`；越界且 `CLIP_EN=0 && STRICT_BOUNDS=1` | `SPRITE_BOUNDS`（`CLIP_EN=1` 时裁剪，不报错） |
| 保留位 | 保留位非 0 **不报错**（前向兼容：旧硬件忽略新位） | — |

### 8.2 看门狗

- 单条描述符从 `F_HEAD` 进入（或 `F_GEOM`/`F_PUSH` 停留）开始计数；
  超过 `DL_TIMEOUT` 拍（默认 4096）仍未完成 ⇒ `WATCHDOG` + `DL_FAULT_ADDR` = 停住的那一步的地址。
- 起点/终点：`F_HEAD` 取到描述符 ⇒ 计数清 0；8 个字写完 ⇒ 计数停。
- **为什么需要**：AXI 从机若不回 R（DDR 控制器异常）、或 `cmd_fifo` 长时间满（引擎卡死），
  DFU 会永远停在那里，软件看到的是"BUSY 永不落" —— 看门狗把它变成一次可诊断的 ERR。
- 注意：看门狗**不会**去打断已经进 FIFO 的命令；引擎侧的卡死由既有 `STATUS.BUSY` + 软件超时处理。

### 8.3 出错后的状态与恢复

1. `DL_STATUS.BUSY` 保持 1 直到引擎 `done_out`（已下发的写必须落盘，I3），然后 `BUSY=0, ERR=1`。
2. `DL_STATUS.CONSUMED` 停在出错前的条数；`DL_ERR[23:16]` 给出出错序号；`DL_FAULT_ADDR` 给出地址。
3. 恢复：写 `DL_ERR` W1C 清位 → 修列表 → `DL_CTRL.GO`。**不需要 SOFT_RST**（引擎状态没被污染）。
4. 若引擎自己进了 `err_out`（非法 op 等），`DL_STATUS.DONE` 永远不会置起；软件应同时看 `STATUS.ERR 0x04 bit2`。

### 8.4 ABORT 语义

`DL_CTRL.ABORT` 只停"取指 + 展开 + 未入队的命令"。已经进 `cmd_fifo` 的命令**照跑完**（否则会撕掉一个半执行的命令，
而且与"写顺序"矛盾）。因此 ABORT 后 `DL_STATUS.BUSY` 仍可能为 1 若干微秒（等 FIFO 排空 + 写提交），
`ABORTED` 位在 ABORT 当拍就置起，软件以 `ABORTED=1 && BUSY=0` 作为"真的停了"。

---

## 9. 顺序规则（与 S1/写屏障的关系）

1. **展开顺序 = 描述符顺序 = 入 FIFO 顺序 = 引擎执行顺序**：DFU 是单条流水（`F_HEAD→F_GEOM→F_PUSH` 顺序执行），
   预取（`F_CHUNK/F_AR/F_FILL`）与译码**并行但只写 FIFO 不写内存**。⇒ 每精灵的写顺序被结构性保证（I4）。
2. 逐命令完成判据不变：`blt_engine_fsm` 的 `ST_WDWAIT` 出口仍是
   `wd_empty && !wd_busy && wr_commit_idle`（`wr_commit_idle = wr_idle_committed && wd_count==0 && !wd_busy`），
   其中 `wr_idle_committed = (b_pending==0) && (wr_master.st==S_IDLE)` —— "同一时刻最多一笔写突发在飞"仍是结构保证，
   S2 一行都不碰它。
3. **不能因为 DFU 提前灌命令而让命令 k+1 的写越过命令 k**：这一点由引擎的串行执行 + 上述屏障保证，
   与 FIFO 里排了多少条命令无关。
4. S1 的"命令末尾冲刷提示"（`wr_cmd_end`，见 `rtl/axi_wr_master.v`）在 S2 下**每条展开出来的命令照旧生效**，
   于是每精灵仍然付 ~30 拍尾活（而不是 ~63）；S2 不改变这个数。

---

## 10. 双缓冲协议（列表乒乓）与三缓冲显示翻转

### 10.1 两张列表 + 三个显示缓冲

- 列表：`DL_BASE0/1` 乒乓，`DL_CTRL.BUF_SEL` 选择本帧用哪张。
- 显示缓冲：`FB_SEL 0x24`（请求）→ `FB_STAT 0x28`（在下一个帧边界生效，`fb_cur_sel`；`frame_cnt` 场计数）。
  三缓冲 0/1/2，与列表的 2 张**互相独立**（列表是"命令从哪来"，缓冲是"画到哪/显示哪"）。

### 10.2 何时可以改写一张列表

**判据（硬件）**：`DL_STATUS.DONE==1`（该列表消费完 **且** 引擎 `done_out`）——`done_out` 内含
`wr_commit_idle`，所以 `DONE` 等价于"这张表产生的像素已经真的落进 DDR（B 已回）"，而不是"看起来不忙"。

**判据（软件流程）**：

```
等待 IRQ_STATUS.FRAME（0x10 bit1，场边界）            ← 把改写时机锁到场边界，避免撕裂与抖动
  && STATUS.BUSY==0（0x04 bit0）                      ← 引擎空闲
  && DL_STATUS.DONE==1（且 BUF_SEL 指向的是"上一帧那张"，不是即将消费的那张）
⇒ 改写"上一帧用完的那张列表"；改完写 DL_CTRL.BUF_SEL=另一张，再写 DL_BASE*/COUNT/GO
```

**最低要求**（不做也可以，但会掉帧）：只有 `DONE` 是正确性必需的；`FRAME` 只是节奏对齐。

### 10.3 与显示翻转的配合（推荐时序，帧 n）

| 时刻 | 软件动作 | 硬件状态 |
|---|---|---|
| 帧 n 开始 | 取列表 `L[n%2]`（上一帧已 build 好），写 `BUF_SEL`、`COUNT`、`DL_DST_BASE=B_n`、`GO` | DFU 取指、展开、灌 FIFO；引擎逐精灵画到 B_n |
| 画的同时 | **改写 `L[(n+1)%2]`**（这张的 `DONE` 在帧 n-1 末已置起） | 显示仍在 B_{n-1} |
| `DL_STATUS.DONE` | 请求 `FB_SEL = B_n`（0x24） | 扫描输出在下一个帧边界锁存，`fb_cur_sel` 变 B_n |
| 等 `IRQ_STATUS.FRAME` | 确认翻转生效（读 `FB_STAT`），准备帧 n+1 | 显示 B_n |

三缓冲的意义在这里体现：**渲染缓冲**（B_n）、**显示缓冲**（B_{n-1}）、**即将被覆盖的缓冲**（B_{n-2}）
三者互不重合，所以"写完再翻"永远不会翻到正在画的缓冲；`DRAW_SEL 0x44` + 清屏引擎的互斥逻辑照旧管"别画正在显示的"。

**硬件防呆（建议实现）**：`BUSY=1` 期间对 `DL_BASE0/1` 的写被忽略（§4 语义 1），
且在 `DL_STATUS` 上加只读位 `[15:8] = ACTIVE_BUF`（DFU 正在消费哪张），软件改写前可以自查。

---

## 11. 软件 API 草图

### 11.1 头文件（建议加入 `software/blt_regs.h`）

```c
/* —— S2 显示列表 —— */
#define BLT_DL_BASE0      0x4C
#define BLT_DL_BASE1      0x50
#define BLT_DL_COUNT      0x54
#define BLT_DL_CTRL       0x58
#define BLT_DL_STATUS     0x5C
#define BLT_DL_ERR        0x60
#define BLT_DL_GEOM_BASE  0x68
#define BLT_DL_GEOM_MAX   0x6C
#define BLT_DL_DST_BASE   0x70
#define BLT_DL_PERF       0x7C

#define DL_CTRL_GO        (1u<<0)
#define DL_CTRL_ABORT     (1u<<1)
#define DL_CTRL_BUF_SEL   (1u<<2)
#define DL_ST_BUSY        (1u<<0)
#define DL_ST_DONE        (1u<<1)
#define DL_ST_ERR         (1u<<2)

typedef struct {                    /* 16B，必须 16B 对齐（一条 = 一个 AXI beat） */
    int16_t  x, y;                  /* dw0 */
    uint16_t spr_id;                /* dw1[15:0] */
    uint16_t flags;                 /* dw1[31:16] */
    uint16_t key;                   /* dw2[15:0]，0xFFFF = 用几何表 */
    uint8_t  alpha;                 /* dw2[23:16] */
    uint8_t  prio;                  /* dw2[31:24] */
    uint16_t mask_id;               /* dw3[15:0]，S3 */
    uint8_t  w_ovr, h_ovr;          /* dw3[23:16]/[31:24] */
} __attribute__((packed, aligned(16))) dl_desc_t;

typedef struct {                    /* 16B */
    uint32_t atlas_base;  uint16_t atlas_stride, key_default;
    uint16_t w, h;        uint16_t sx, sy;
} __attribute__((packed, aligned(16))) dl_geom_t;
```

### 11.2 一帧的用法（乒乓）

```c
static dl_desc_t list[2][DL_MAX_DESC] __attribute__((aligned(16)));

void frame(int n) {
    dl_desc_t *L = list[(n+1) & 1];        /* 本帧要"填"的那张 */
    int k = 0;

    /* build：纯内存写，无 MMIO（DDR cache 命中） */
    for (each active entity e) {
        L[k].x = e->x;  L[k].y = e->y;
        L[k].spr_id = e->spr;  L[k].flags = DL_OP_KEY;    /* + CLIP_EN | MIRROR_X … */
        L[k].key = 0xFFFF;  L[k].alpha = 0;  L[k].prio = e->z;
        k++;
    }
    L[k-1].flags |= DL_FLAG_END;

    while (blt_busy() || !(REG32(BLT_DL_STATUS) & DL_ST_DONE)) { }   /* 上一张跑完 */
    REG32(BLT_DL_BASE0 + 4*((n+1)&1)) = (uint32_t)L;
    REG32(BLT_DL_DST_BASE) = fb_back_addr((n+1) % 3);
    REG32(BLT_DL_COUNT)    = k;
    REG32(BLT_DL_CTRL)     = DL_CTRL_GO | DL_CTRL_BUF_SEL;           /* 3 次 MMIO/帧 */
}
```

### 11.3 每精灵 CPU 开销

| 路径 | 每精灵 CPU 成本 | 说明 |
|---|---|---|
| 今天（`blt_push_cmd`） | **9 次 AXI-Lite 事务**（1 读 `CMD_FIFO_COUNT` + 8 写 `CMD_FIFO_DATA`）+ 结构体装配 | 每次非缓存外设访问 ≈ 5~20 拍 ⇒ 50~200 拍/精灵，且**与引擎抢 FIFO 写口** |
| S2 | 4 次字存储（16B，cache 写）+ 帧尾 3~4 次 MMIO | 约 **15~25 拍/精灵**，MMIO 从 9/精灵 降到 ~0 |
| 收益 | 一帧 5,300 精灵 ≈ 0.1 M 拍 CPU（约占 87MHz 下 60fps 帧预算 1.46M 拍的 7%） | CPU 从"下发工"变成"只写表" |

---

## 12. 测试台计划（S2 落地时）

| TB | 覆盖 | 判据 |
|---|---|---|
| `tb_dl_basic` | 一张 64 条描述符的表（COPY/FILL/KEY/ALPHA 各 16 条） | 与"CPU 逐条 push 同样 64 条命令"的 DDR 内容**逐字节相同**（复用 `axi_slave_mem.v`） |
| `tb_dl_overhead` | 1,000 条 16×16 FILL 的描述符表 | 每精灵开销 = (总拍 − 256×1000)/1000；与 CPU-push 路径对照；**探针直方图加一档 `DL_FETCH`**，要求 `hist_sum − PERF = 0` |
| `tb_dl_malformed` | `COUNT=0`、`COUNT>4095`、`BASE` 未对齐、`BASE` 越窗、`SPR_ID ≥ GEOM_MAX`、`W=0`、`X=-1e6`、描述符只回 rlast 不回数（短突发）、从机永不回 R（看门狗）、中途 `ABORT` | 每种都要在**有限拍内**落到 `BUSY=0` + 正确的 `DL_ERR` 位 + 正确的 `DL_ERR[23:16]` 序号 + `DL_FAULT_ADDR`；已入 FIFO 的命令必须跑完 |
| `tb_dl_order` | 交错的 KEY 精灵（重叠区域），列表路径 vs CPU 路径 | 复用 `tb_wr_order` 的"写后读危险"检查：不允许出现"后一条命令的写早于前一条的 B" |
| `tb_dl_arb` | desc 读 + fg/bg 像素读 + 扫描输出（`axi_rd_arb`）同时压 | fg 饥饿拍数 = 0；desc 等待有上界（`AGE_MAX` 生效）；扫描输出 `dbg_underrun=0`（扩 `tb_arb_deadlock`/`tb_rd_arb_leak` 的场景） |
| `tb_dl_axi_wr` | 列表路径下的 AW/W/B 计数 | `burst_max=16`、AW ≈ 词数/16、`b_pending` 恒 0/1 |
| A/B `ifdef` | `-DDL_OFF`：DFU 全部旁路（`dl_cmd_wr_en=0`，CPU 写口直通） | 读数与 S1 后逐字节一致（回归里新增 `tb_dl_*` 与 `tb_dl_*_off` 成对条目，`run_regress.ps1` 风格同 `tb_alpha_off`） |

测试向量沿用既有金标准（`tb_blt_top` / `tb_blt_unalign` / `tb_alpha` 的 FILL/COPY/KEY/ALPHA/非对齐/行尾向量），
列表路径必须**逐位**复现它们。

---

## 13. S3（掩码跳过）如何挂在描述符的空位上

S2 要为 S3 预留（**只预留 + 原样搬运，不实现**）：

1. **描述符位**：`dw1.FLAGS[7]=MASK_EN`、`[9:8]=MASK_MODE`、`dw3[15:0]=MASK_ID`。
2. **旁路通路**：8 字命令格式已满（§2.2），掩码字段**进不了命令**。因此 S2 要顺手做一个
   **平行属性 FIFO（ATTR FIFO）**：DFU 在推 8 字命令的**同一时刻**推入 1 个 32bit 属性字
   （内容 = `{MASK_MODE, MASK_EN, MASK_ID}`）；`blt_engine_fsm` 在 `ST_DEC` 弹一个字（S2 里弹了不用）。
   写口/读口深度与 `cmd_fifo` 的命令数对齐（32 条深即可）。这样 S3 = 纯增量：
   - 引擎侧：`ST_DEC` 读 attr → 像素通路按 `MASK_ID` 取掩码行（第三路读流，复用 `axi_rd_master` 的 `rd_sel=11`）；
     或按 `MASK_MODE` 做"整块跳过"（整条命令都不发）。
   - DFU 侧：可选地在 `F_HEAD` 直接把"整条掩码全 0"的描述符**丢掉不下发**（最省的一档：连命令都不产生）。
3. **S3 的两种实现档次**（写进 S3 规格时二选一）：
   - **块级跳过**：每精灵一张 1bpp 的"有效块位图"（如 16×16 精灵 = 4×4 块 = 16bit），
     DFU/引擎按位决定"这一块要不要画"—— 硬件增量最小，适合弹幕（子弹/爆炸大量透明边角）。
   - **像素级掩码**：像素通路增加"keep = mask_bit"的门控 —— 与现有 KEY 的 `keep` 门控同构
     （`pixel_path.v` 已有 `keep` 通路），改动集中在像素通路，但需要第三路读流与 `STALL` 计数。
   **建议先做块级**，用 `tb_dl_overhead` 量"跳过比例 vs 收益"再决定是否做像素级。

---

## 14. 不确定项 / 必须先做的原型测量

> 这一节是本文档最重要的部分：下面每一条都可能推翻上面的某个数字或某个设计选择。

1. **305 拍的构成（最高优先级）**。本文推定为 `~111 引擎自身 + ~190 CPU 下发/喂 FIFO`，但**没有直接实测**。
   测法：写一个只读探针（扩 `rtl/tb/tb_perf_probe.v` 的直方图，加 `DL_FETCH` 桶），
   跑"16×16 FILL × 1,000 条"两种下发方式：(a) CPU 逐条 9 次 MMIO（现状），(b) 硬件从 DDR 展开（DFU 原型）。
   两者之差就是 S2 的真实收益；两者各自的 `POP_8WORDS`/`STALL_*` 桶给出指令喂入侧的占比。
2. **"每精灵 ~20 拍"是否可达**。按 §2.3 的算术，S2 **不动 FSM** ⇒ 引擎自身的 `POP/DEC/EXEC_INIT/DRAIN/ROW_GAP`
   （16 行时 ≈ 111 拍）拿不掉，S2 单独只能到 ~130 拍/精灵（16×16 FILL 561 → ~390，≈ 3,700 块/帧，+42%），
   **达不到 5,300**。要兑现 5,300 必须再追加一步（S2.5/S4）：**命令内多精灵**（一条命令里带 N 个精灵，
   引擎保持 `ST_EXEC` 不重新 `POP/DEC/INIT/DRAIN`）——那才是"每精灵 ~20 拍"的来源。
   **建议**：S2 先落地（收益确定、风险低），同时把 S4 的可行性用 1 的探针一起量。
3. **预取与扫描输出在板上的相互影响**。仿真里读侧从不饿（见 `perf_probe_report.md` §6），
   板上 DDR 有换页/刷新争用。判据：`SCAN_DBG 0x20` 的欠载行数与 `stall_fg/bg` 计数在 S2 前后不变。
   若变差 ⇒ 降 `CHUNK`、抬 `FIFO_WM`、或把 desc 读的 `AGE_MAX` 调大。
4. **几何表放 DDR 还是 BRAM**。16 条 cache 是按"demo 精灵种类 < 16"估的；真实项目若有几百个精灵
   （子弹拖尾、爆炸帧），命中率会掉。测法：统计 miss 率与平均 miss 惩罚；必要时把整表做成
   512B~2KB 的 BRAM（每帧由软件/CPU 灌一次）。
5. **一条描述符 = 16B 的粒度是否最优**。若精灵数极大（>10k/帧），16B 的表带宽会变成 DDR 上的可观流量
   （10k × 16B × 60 = 9.6 MB/s，仍 <3% 的 ~400MB/s，可接受）；但如果将来要"同尺寸批处理"，
   16B 可能不是最省的编码 —— 需要按真实场景实测再调。
6. **`MIRROR_X/Y` 与 `SRC_OFF_EN` 的实现位置**。镜像要么在 DFU 把 src 地址+行内方向换掉（需要
   `blt_addr_gen` 支持负步进），要么在像素通路做；两者都碰引擎侧，**S2 建议先报"未实现"错误位**，
   把镜像留给 S3/S4，不要偷偷改变 src 语义。
7. **`FB_STRIDE` 从哪来**。本文假设在 `DL_DST_BASE (0x70)` 的高半字加 `DST_STRIDE_PX`。
   另一种做法是复用 `DRAW_SEL (0x44)` + 一张 3 项的 FB 基址/行距小表（更省寄存器，但硬件多一个小表）。
   这条是纯接口口味问题，**需要和 `software/blt_regs.h` 的现有风格对齐后二选一**。
8. **`DL_STATUS.DONE` 与 `IRQ_STATUS[2]` 的中断语义**：是否需要在"列表结束但引擎还在跑"时先给一次中断
   （软硬件重叠更多）还是只在全部提交后给一次（现在这样）。前者更快、后者更简单 —— 需要实测 CPU 侧的空转成本。

---

## 15. 交付边界（明确不做的）

- 本文档**不含 RTL**，不改任何现有 `.v` 文件。
- S2 不改 `blt_engine_fsm.v` / `pixel_path.v` / `blt_addr_gen.v` / `axi_wr_master.v` 的行为
  （唯一例外是给 FSM 加一个 `ST_DEC` 的 ATTR FIFO 读口做 S3 hook，S2 里该读口悬空不影响时序）。
- S2 不改 `axi_rd_arb.v`（读仲裁规则不变，desc 流在 `axi_rd_master` 内部消化）。
- S2 不实现 `MIRROR_*`、`CHAIN`、逐像素掩码（分别是 §14.6、§5.1、§13 的后续步骤）。
