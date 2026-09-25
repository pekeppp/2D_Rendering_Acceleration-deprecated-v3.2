# HDMI 输出通路集成说明（ARC_2DRA / ddr_demo_ti60）

> 目标：在现有 SoC 工程里搭起 **"软核写帧缓冲 → HDMI 扫描输出读 DDR 并上屏"** 的最小闭环。
> 输出规格 **1080p@60**；画面里 **960×540 的帧缓冲内容**放在左上角，其余全黑。
> 原则：**复用板卡 03_hdmi_tx_demo 的 HDMI 实现，不改它的核心代码**；地址一律以开发文档为准
> （《DDR3内存分配分析.md》《板级集成接线清单.md》），不沿用旧代码里的 0x01000000。

---

## 1. 数据通路总览

```
 RISC-V 软核                 DDR3 控制器
 (efx_soc)                   (rtl/ddr3_controller)
    │  写 AW/W/B 直连 ────────────►│
    │  读 AR/R ──┐                │
    │            ▼                │
    │      ┌───────────────┐      │
    │      │ axi_rd_arb    │─────►│  ← 读通道 2 选 1（CPU / 扫描输出）
    │      └───────▲───────┘      │
    │              │ AR/R         │
    │      ┌───────┴────────┐     │
    │      │ fb_scanout     │◄────┘  按行取 960×540 帧缓冲（1920B/行）
    │      │ 双行缓冲 ping-pong     │
    │      └───────┬────────┘
    │              │ RGB888 + DE/HS/VS（pixel_clk 148.75MHz）
    │      ┌───────▼────────┐
    │      │ dvi_encoder    │  ← 直接复制板卡 demo 的 TMDS 编码器（未修改）
    │      └───────┬────────┘
    │              │ 10bit TMDS ×4
    │      ┌───────▼────────┐
    │      │ HSIO 10:1 串化  │  ← 由 Interface Designer 的 LVDS 引脚配置完成
    └─────►└───────┬────────┘
                   ▼  HDMI 显示器
```

- **写通路**：CPU 写 DDR 的 AW/W/B 仍然直连 DDR 控制器，完全不受影响。
- **读通路**：CPU 与扫描输出经 `axi_rd_arb` 共享；扫描输出有请求时优先拿到通道，
  队列空了立刻归还 CPU（同一时刻只允许一个主机，保证 R 回程不错路）。
- **像素时钟**：`hdmi_tx_slow_clk` = 148.75MHz（25MHz × 119 ÷ 20，与板卡 demo 的
  `pll_hdmi` 完全一致）→ 1080p 时序下实际约 60.1Hz，显示器可锁。

---

## 2. 文件清单

### 2.1 新增（都在 `ARC_2DRA/rtl/video/`）

| 文件 | 作用 |
| --- | --- |
| `video_timing_1080p.v` | 1080p@60（CEA-861）时序发生器：1920×1080，H 2200 / V 1125，HS/VS 正极性 |
| `fb_scanout.v` | 帧缓冲扫描输出：AXI4 读主机 + 双行缓冲（跨时钟）+ 960×540 窗口 + 黑边 + RGB565→888 |
| `axi_rd_arb.v` | AXI 读通道 2 选 1 仲裁（CPU ↔ 扫描输出），写通道不受影响 |
| `dvi_tx/dvi_encoder.v`、`dvi_tx/encode.v` | **原样复制**自 `03_hdmi_tx_demo`（TMDS 8b/10b 编码），一行未改 |

### 2.2 修改

| 文件 | 修改内容 |
| --- | --- |
| `ARC_2DRA/rtl/ddr3_example_top.v` | 新增 HDMI 端口（`hdmi_tx_locked`/`hdmi_tx_slow_clk`/TMDS ×4 及 OE/RST）；SoC 读通道改接 `axi_rd_arb`；例化 `fb_scanout`、`axi_rd_arb`、`dvi_encoder`；像素域复位同步器 |
| `ARC_2DRA/par/ddr_demo_ti60/ddr_demo_ti60.peri.xml` | 加入 `pll_hdmi`（PLL_BR0，25MHz→148.75MHz）与 4 对 TMDS LVDS 发送引脚（GPIOR_PN_10/13/11/12，10:1 串化）——均自 demo 原样移植，参考时钟名改为本工程的 `clk_25m` |
| `ARC_2DRA/par/ddr_demo_ti60/ddr_demo_ti60.xml` | 设计文件列表登记上面 5 个新 RTL |
| `software/standalone/application/fbTest/`（新增应用） | `makefile` + `src/fbTest.c` + `src/userDef.h`：**地址按开发文档修正**，并实现动态画面 |
| 仓库根 `fbTest.c`、`userDef.h` | 与工程内版本保持同一份内容（同步更新） |

---

## 3. 地址约定（重要：旧代码地址不对）

| 项 | 旧 `userDef.h` | **本次修正（以开发文档为准）** |
| --- | --- | --- |
| DDR 基址 | 未定义 | `0x00001000`（`soc.h` 的 `SYSTEM_DDR_BMB`） |
| 帧缓冲 0（HDMI 读的就是它） | `0x01000000` ❌ | **`0x00301000`** = DDR_BASE + 0x300000 |
| 帧缓冲 1 | `0x01100000` ❌ | `0x00401000` = DDR_BASE + 0x400000 |
| 分辨率 / 行距 | 640×480 / 1280B ❌ | **960×540 / 1920B**（与 `fb_scanout.v`、`blt_regs.h` 一致） |
| 每帧字节 | 614,400 ❌ | 1,036,800 |

> 为什么旧地址不对：`0x01000000` 落在文档布局的"空闲区"，而赛题/文档规定帧缓冲在
> **程序区(1MB) + 精灵区(2MB) 之后**，即 `DDR_BASE + 0x300000`。硬件 `fb_scanout` 的
> `FB_BASE` 参数与软件 `FB_BASE` 宏必须**逐位一致**，否则屏幕上看不到内容。

**唯一需要现场确认的一点**：CPU 访问 DDR 时，SoC 的 AXI 主口是原样透传地址（`0x00301000`），
还是减掉了 DDR 窗口基址（则扫描输出应读 `0x00300000`）。验证方法：
1. 先按当前设置（都是 `0x00301000`）上板；
2. 若屏幕**全黑且串口自检 PASS**，把 `ARC_2DRA/rtl/ddr3_example_top.v` 里
   `fb_scanout #(.FB_BASE(32'h0030_1000) …)` 改成 `32'h0030_0000` 重新综合即可；
   （软件侧不用动。）

---

## 4. 在 Efinity 里要做的操作

1. **打开工程**：`ARC_2DRA/par/ddr_demo_ti60/ddr_demo_ti60.xml`；
2. 让工程重新读取接口配置：Efinity 会用同目录的 `ddr_demo_ti60.peri.xml`
   （本次已注入 `pll_hdmi` 与 TMDS 引脚）。打开 **Interface Designer** 核对：
   - PLL：`pll_hdmi` 位于 **PLL_BR0**，参考时钟 `clk_25m`，输出 `hdmi_tx_slow_clk`(÷20)、
     `hdmi_tx_fast_clk`(÷4, 相位 2)，锁定信号 `hdmi_tx_locked`；
   - LVDS：`tmds_clk`(GPIOR_PN_10)、`tmds_data0`(PN_13)、`tmds_data1`(PN_11)、`tmds_data2`(PN_12)，
     均为 **TX / 10:1 串化 / half-rate**；
   - 确认这三组资源与现有 DDR3 引脚、`pll_inst1`(PLL_TL0)、`DDR3_PLL`(PLL_TR0) **不冲突**；
3. **约束**：HDMI 的时钟与 `set_output_delay` 约束由 Interface Designer 自动生成
   （参考 demo 生成的 `led_test.pt.sdc` 里的 `create_clock … hdmi_tx_slow_clk 6.723ns`）；
   本工程原有的 `sdc/ddr3.sdc` 不需要改；
4. 重新 **综合 → 布局布线 → 生成 bitstream**，下载到板卡。

## 5. 软件编译与运行

```bash
cd ARC_2DRA/par/ddr_demo_ti60/embedded_sw/soc/software/standalone/application/fbTest
make                     # 产出 fbTest.elf（BSP 路径见 makefile）
```
- 用 Efinity RISC-V IDE 导入该应用目录（或把 `src/*.c` 加进已有工程）编译、下载；
- 串口 115200 应看到：
  ```
  *** 2DRA: CPU writes DDR framebuffer -> HDMI scanout ***
  FB0=0x301000  FB1=0x401000  960x540 RGB565  stride=1920  bytes=1036800
  coherency check: PASS (CPU writes reach DDR)
  background color bars written, start animation ...
  frame=30  box=(...)  small=(...)
  ```

## 6. 上板预期现象与排查

| 现象 | 判断 / 处理 |
| --- | --- |
| 显示器显示 1920×1080，左上角有 **8 条彩条 + 两个移动方块**，其余全黑 | ✅ 目标达成 |
| 无信号 / 显示器不锁 | 检查 `pll_hdmi` 是否锁定（可引 `hdmi_tx_locked` 到 LED）、TMDS 引脚分配极性、HDMI 线 |
| 全黑但串口 `coherency check: PASS` | 1) 试把硬件 `FB_BASE` 改 `0x0030_0000`（见第 3 节）；2) 用逻辑分析仪看 `u_fb_scanout` 的 `m_axi_arvalid` 是否有突发 |
| 只有彩条 / 满屏白（彩条或白框以外的画面内容看不到） | **先查硬件**：这是行缓冲取数门控死锁的典型表现（见 6.3 ①，两种现象根因相同，只取决于 FB 第 0/1 行画的是什么）。已修复；若再出现，用 `tb_fb_scanout` 复现 |
| 只有彩条、方块不动（彩条本身正常推进） | CPU 每帧数据没进 DDR：确认 `cache_evict()` 与 `data_cache_invalidate_all()` 被执行（串口 frame 计数在涨） |
| 静态画面正确但完全不动、串口停在 `static pattern` | 时间基准踩了未实现的 `mcycle` CSR（见 6.5）；v3 已改用 CLINT mtime，并加了 step1~step6 分步自检（见 6.6） |
| 画面整体偏色（尤其绿色发灰/发紫） | RGB565→RGB888 的通道扩展位宽写错（见 6.3 ④） |
| 画面整体右移 1 像素、最右一列异常 | 行缓冲写口或读地址的流水错位（见 6.3 ②③） |
| 画面偶发"回跳"一行 | 该行取数没赶上（见 8.1 ① 的余量），加大行缓冲数量 |
| 画面卡在某一帧 | 读仲裁把 CPU 饿死或反之：检查 `axi_rd_arb` 的 `owner` 是否长期不变 |
| 画面出现斜纹/花屏 | 行缓冲跨时钟写读时序：确认 `simple_dual_port_ram` 用的确实是双时钟版本 |
| 彩条位置整体偏移/上下半屏错位 | DDR 地址差 0x1000（同"全黑"排查第 1 条），或 `FB_STRIDE` 与软件 stride 不一致 |

### 6.1 已遇到并已修复的编译期问题

**① `ERROR: io_bank_rule_lvds: I/O Voltage has to be set to 1.8 V when LVDS Tx is used`（bank 3A）**

- 原因：TMDS 引脚 `GPIOR_PN_10..13` 位于 **I/O bank 3A**，LVDS 发送强制要求该 bank 为 **1.8 V**；
  而本工程沿用了软核 DDR demo 的默认值 `3A = 1.5 V LVCMOS`（原工程没有 LVDS 引脚，所以一直没暴露）。
- 依据（板卡官方工程，引脚组合与本工程完全一致）：
  - `10_Ti60f225_sc431hai2hdmi_demo`：`ddr_ck`=GPIOR_P_09、TMDS=PN_10/13/11/12，
    其 bank 配置正是 **3A=1.8V、3B/4A/4B=1.5V**；
  - `09_Ti60F225_hdmi2dsi_Demo`：同样 `ddr_ck`=GPIOR_P_09，3A 也是 1.8V。
  → 即：**DDR 在 3B/4A/4B（1.5V），HDMI 在 3A（1.8V）**，两不冲突。
- 修复：`ddr_demo_ti60.peri.xml` 中 `<efxpt:iobank name="3A" iostd="1.8 V LVCMOS" …>`（本次已改）。

**② `warning: lvds_rule_tx_distance … GPIOR_P_09`**

- 含义：DDR 时钟 `ddr_ck`（GPIOR_P_09）与 HDMI 时钟 `tmds_clk`（GPIOR_PN_10）在板上是**相邻引脚对**，
  工具提示可能噪声耦合。这是**板卡硬件布线决定的，无法规避**（官方 09/10 号 demo 同样如此），
  属 warning，不影响流程通过。若后续 HDMI 时钟抖动导致偶发花屏，可优先检查 DDR 与 HDMI 的电源/地处理。

### 6.2 软件侧已修复的问题（屏上只有彩条、看不到方块）

**根因 1（主因）：每帧整屏重画背景。**
v1 的动画循环每帧都调用 `fill_bg_bars()` 重画 960×540 全部背景（约 1MB，**259,200 次 32bit 写**）。
本 SoC 每次写 DDR 都要走 AXI → 软核 DDR3 控制器，单次开销几十个周期，整屏重画需要几十毫秒；
而方块只在"画完 → 下一帧被背景盖掉"之间存在于 DDR 中，占一帧的比例只有百分之几，
显示器的扫描输出几乎永远扫不到它（彩条是背景，所以一直看得见）。

**根因 2：每帧调用 `data_cache_invalidate_all()`。**
该指令是"作废"语义：写回（write-back）模式下会**丢弃脏行**。对"CPU 写 → 外部主设备（扫描输出）读"
这个方向，正确操作是 **flush/挤出**（代码里的 `cache_evict()` 写 8KB 冲刷缓冲），而不是 invalidate；
invalidate 还可能丢掉栈上的脏数据导致程序行为异常。

**根因 3（次要）：`dx2 = -9`** 等奇数步进破坏了 32bit 写（两像素打包）的像素对齐。

**修复后的做法（`application/fbTest/src/fbTest.c` v2）**：
1. 静态内容只在开机画一次：8 条彩条 + 白色边框 + 固定红块（后两者兼作"非彩条内容也能上屏"的静态证据）；
2. 每帧只重画两个方块自己的矩形（用彩条颜色按列恢复背景），每帧约 1.4 万次 32bit 写，比原来少 18 倍；
3. 用 `csr_read(mcycle)` 按固定周期（`FRAME_CYCLES = 1,670,000` ≈ 16.7ms ≈ 60fps）节流，
   方块在 DDR 中的停留时间由周期保证，不再被慢速内存写挤掉；
4. 每帧末尾只 `cache_evict()`，**不再** per-frame invalidate；
5. 每 60 帧打印 `draw=… cyc period=… cyc (~xx fps)`，便于现场判断是"内存写太慢"还是"缓存没刷"。

> 现场判断技巧：白边框与固定红块是"静态写入"的证据。
> 若彩条、边框、红块都在、只有方块不见 → 写入通路正常，问题在动态元素的可见时间（节奏）；
> 若连边框/红块都不见 → 说明首帧之后的写入没有真正落到 DDR，需要继续查缓存/地址。

### 6.3 硬件侧已修复的问题（RTL 自测发现；屏上表现为"只有彩条"或"满屏白"）

上板"只有彩条"和后来的"满屏白"两个现象，根因都在这条硬件通路上。三个 bug 都是**自测平台先复现、
再定位、再修**的，证据如下（`tb_fb_scanout.v` 里的 `DUMP` 行与 `LINE` 行）。

**① 取数门控用了 `buf_ready`（主因，直接导致"只有彩条"/"满屏白"）**

`fb_scanout` 的取数条件里带了 `buf_ready[next_y[0]] == 0`。该标志**只在取数开始时清 0**，
两个行缓冲各取满一次之后就再也没人清它 → 取数永久停在第 0/1 行，屏幕一直重复显示这两行。
- 软件 v1 的 FB 第 0/1 行正好是彩条背景 → **"只有彩条"**；
- 软件 v2 的第 0/1 行是顶部白色边框 → **"满屏白"**。
两者现象相反、根因同一个，这也反过来说明写入通路一直是好的。
- 修复：门控改成"最多比显示侧正在消费的行超前 1 行 + 不写正在显示的那个缓冲"：

```verilog
else if ((next_y < FB_H) &&
         (next_y <= (cons_s + 12'd1)) &&     // cons_s = 显示侧正在消费的行号（gray 码跨时钟）
         (next_y[0] != par_s1)) begin        // 不写"正在被显示"的那个缓冲
```

**② 行缓冲写口错位（画面整体右移 1 像素、丢最后一个像素）**

写使能、写数据、写地址是**在同一个时钟沿寄存**的，于是 RAM 写沿上看到的是"地址已经 +1、
数据还是上一拍" → 第 k 个像素写进了第 k+1 个地址。
- 证据（修复前 `DUMP`）：`mem[0]=0x0000 buf0[0]=0xxxxx`、`mem[1]=0x0001 buf0[1]=0x0000`……
  即 `buf[0]` 永远是 X、`buf[k]` 存的是第 k-1 个像素。
- 修复：写地址用寄存器（每拆一个像素 +1），**写使能与写数据改为组合产生**，
  保证三者属于同一拍：

```verilog
wire        buf_we    = (st == S_R) && unpacking;
wire [15:0] buf_wdata = beat_d[unpack*16 +: 16];
```

**③ 行缓冲读地址多寄存了一拍 → 数据比控制晚 1 个像素**

原来 `raddr_r <= hcnt - WIN_X`（寄存）＋RAM 自带 1 拍输出寄存＋`px1/px2` 两级＝数据 4 拍，
而控制只有 `win_d1/ctrl1/ctrl2` 3 拍 → 每行第一个窗口像素显示的是**上一行的残留**，整幅画面右移 1 像素。
- 修复：读地址改为组合地址（= 当前列号），数据与控制都恰好 3 拍，严格对齐：

```verilog
assign raddr_w = (hcnt >= WIN_X) ? (hcnt - WIN_X) : 10'd0;
```

**④ RGB565→RGB888 的绿分量拼接位宽写错（绿色通道比特全错位）**

```verilog
wire [7:0] g8 = {px2[10:5], px2[8:5]};   // 错：6+4=10 位，赋给 8 位被截断成低 8 位
wire [7:0] g8 = {px2[10:5], px2[7:6]};   // 对：6 位绿 + 补低 2 位
```
绿通道 6 位，只能补 2 位。截断后 `g8` 的比特顺序变成 `{G3 G2 G1 G0 G5 G4 G3 G2}`，
绿分量整体错乱——**上板看是偏色，而在自测里更致命**：测试台把"行号/列号"编码进像素值再读回来校验，
绿通道一乱，读出的行列号全错，一度把定位带偏（表现为"行号不递增、列号跳到 64"）。
红/蓝两个 5 位分量的拼接本来就是对的，所以只坏绿色。

> 诊断经验：自测里"读回来的数据整体像被比特打乱"时，优先怀疑**通道扩展/位宽拼接**，
> 而不是先怀疑时序或地址——先确认 `DUMP` 出来的行缓冲内容与源数据是否逐位一致，
> 这一步能把"存储通路"和"重建通路"彻底分开。

### 6.4 自测平台本身踩过的坑（避免误判 RTL）

| 坑 | 症状 | 原因 / 处理 |
| --- | --- | --- |
| 像素时钟设得和核时钟一样快 | "行号十几行才推进一次" | 自测里一条显示行只有 960ns，而取一行要 120 拍×8 周期＝9.6us，显示侧比取数快 10 倍。**真实 1080p 是 14.8us/行 vs 9.6us 取数**，自测必须保持同样比例（现用 19.2us/行） |
| 复位释放早于第一个像素时钟沿 | `hcnt/vcnt` 恒为 X、窗口像素一个都不输出 | 复位必须在**至少一个 pclk 上升沿之后**才释放，否则像素域的 `always` 块第一次看到的就是 `prst_n=1`，寄存器永远拿不到复位值 |
| 在 `posedge pclk` 上同时采样 `ctrl2` 和像素值 | 行列号出现"跨行混搭"的假错误 | 同一时刻读控制与数据有竞争；改到 `negedge pclk` 采样，两者必然同拍 |
| 第一帧参与判定 | 第 1 行少 3 个像素 | 复位后行缓冲还没取到数、"就绪"标志跨时钟域还要 2 拍同步；第一帧只统计不判定 |

### 6.5 软件侧第二轮（静态画面正确、但画面不动且串口停在 `static pattern`）

**上板现象**：彩条 + 白边框 + 右上角固定红块全部正确，但画面完全不动；
串口停在 `static pattern: ...` 之后再无输出（连一次 `frame=` 都没有）。

**定位链（纯靠现象推理，不需要额外仪器）**

1. 屏幕上看到的内容 = 循环**之前**的 `draw_static_marks()` 画的东西
   （右上角那个红块就是它画在 `x=820,y=16` 的固定标记）；
2. 而动画循环体**第一件事**就是把 120×90 的大方块画到左上角 (8,8)，颜色表
   第 0 项是红色 —— 屏上**没有**这个方块 ⇒ 循环第一轮根本没走完；
3. 日志最后一行是 `static pattern: ...`，紧接着的下一条语句正是
   `t_prev = csr_read(mcycle);` ⇒ 嫌疑最大的是这次 CSR 读。

**根因**：`mcycle` 属于**可选实现**的 CSR。SoC 只保证 `Zicsr` 指令可用
（`SYSTEM_RISCV_ISA_EXT_ZICSR=1`），并不保证周期计数器存在；读一个未实现的 CSR
会触发**非法指令异常**，跳进 BSP 的默认 trap 处理（死循环）→ 程序就此停住、
串口不再有任何输出，屏幕上保留最后一帧内容 —— 与现象完全一致。
旁证：BSP 与厂商 demo 的计时**一律用 CLINT `mtime`**（coremark / dhrystone 都是
`clint_getTime(BSP_CLINT)`，BSP 的延时函数也是 `clint_uDelay`），全树里 `mcycle`
只出现在一个未被使用的宏里 —— 说明这条路径在本 SoC 上从来不是被验证过的用法。

**修复（`application/fbTest/src/fbTest.c` v3）**：时间基准改用
`clint_getTime(BSP_CLINT)`（`BSP_CLINT+0xBFF8` 的 mtime，普通 MMIO 读，
不可能陷入异常），节流循环另加次数上限兜底。

### 6.6 v3 的分步自检怎么读（下一步排查全靠它）

v3 把"卡在哪"变成串口上可见的事实，上电顺序如下：

| 串口输出 | 含义与判读 |
| --- | --- |
| `step1 timebase: ... -> OK/BAD` | CLINT mtime 是否真的在走（`BAD` 说明时间基准不可用，代码会自动退化成空循环延时，仍会动） |
| `step2 coherency check: PASS` | CPU 写 → D$ 挤出 → 从 DDR 回读一致，写入通路通 |
| `step3 write probe: N ticks/word` | **实测单次 32bit 写 DDR 的开销**（关键数字） |
| `step3 budget: M words/frame -> est … ticks (~fps)` | 按实测开销预算的每帧时间与 fps，用来和后面的实测值对照 |
| `step4 bars: … ticks (… ticks/word avg)` | 整屏 259,200 字重画的实际耗时 → 也能量出每字开销 |
| `step5 blink test` + `blink N ON/OFF` | **实时上屏自检**：在 (400,240) 画 160×120 品红块→0.5s→擦掉，重复 3 次。屏幕跟着闪 ⇒ "运行中的 CPU 写 → 扫描输出立刻可见"这条实时通路完全没问题 |
| `step6 entering main loop` + `frame=1..3` | 循环已经跑起来（前 3 帧立刻打印，不用等 60 帧） |
| `frame=… draw=… period=… (~fps)` | 每帧实际耗时与帧率；`draw` 大 ⇒ 该减每帧写次数 |

判读表：

| 现象 | 结论 / 下一步 |
| --- | --- |
| 有 `step5` 且屏幕闪了 3 次，但 `step6` 之后没有 `frame=` | 问题在循环体内部，按最后出现的 step 定位 |
| `frame=` 正常刷出但屏幕还是不动 | 写入没落到 DDR（缓存）或扫描输出没看到 —— 回看 `step5` 是否闪 |
| `step5` 的 ON/OFF 打了但屏幕不闪 | 实时上屏通路有问题（缓存挤出/地址），此时静态画面正常只说明"一次性画完"那条路径通 |
| `frame=` 出得来但 fps 很低 | 看 `step3` 的 ticks/word：每帧约 16,000 次写，若每字开销大就必须减少每帧写次数（缩小方块、或只擦"方块让出来的 L 形区域"） |

### 6.7 软件侧第三轮（静态红块被移动方块"碰掉"）

**上板现象**：画面动起来了（v3 生效），但右上角那个静态红块只要被移动方块压到
就消失，方块走开后也不再恢复。

**根因**：擦除函数 `restore_bg()` 的语义是"把这块**整片铺回彩条**"，它并不知道
那里还有一层静态标记。大方块的移动范围是 x∈[8,832]、y∈[8,442]，而固定红块在
(820..931, 16..95)，两者必然相交 → 擦除时红块被涂成彩条；而 `draw_static_marks()`
只在开机调用过一次，所以红块**永久消失**（方块压着的时候看不出来，方块一走就露馅）。
白边框没事，是因为动态方块被限制在边框内侧，擦除矩形永远碰不到它。

**这不是"显示异常"，而是演示程序少了图层概念** —— 正确的层次应当是
**彩条(底) < 静态标记 < 动态方块(顶)**。

**修复（v4）**：把红块的位置/尺寸提成 `MARK_X/Y/W/H` 常量（两处共用，避免不一致），
擦除后再按相交区域把静态标记补画回来：

```c
static void restore_bg(int x, int y, int w, int h) {
    ... 铺回彩条 ...
    redraw_marks(x, y, w, h);   /* 被这次擦除波及的静态标记补回 */
}
```

> 通用教训：这类"CPU 直接写帧缓冲"的演示里，**擦除必须知道背景由哪些图层组成**。
> 本例用"按相交区域补画"手写图层合成；等自研 BitBlt 引擎接进来之后，这类
> 擦除/合成应该交给硬件（背景填充 + 精灵叠加），软件就不需要维护图层规则了。

## 7. 自测方法（无板卡也能复现）

两个测试台都在 `ARC_2DRA/rtl/video/tb/`，用 OSS CAD Suite 的 iverilog 跑（当前实测输出见下）。

```powershell
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
cd ARC_2DRA\rtl\video

# 1) 扫描输出：行取数 / 行缓冲 / 窗口对齐
iverilog -g2012 -o sim_scan.vvp tb\tb_fb_scanout.v fb_scanout.v video_timing_1080p.v ..\common\simple_dual_port_ram.v
vvp sim_scan.vvp
#   → 检查结果: 显示行数=71, 出现过的 FB 行掩码=0xffff, 错误=0
#   → ========== tb_fb_scanout ALL PASS ==========

# 2) 读通道仲裁：R 数据分路 / 不丢拍 / 不饿死
iverilog -g2012 -o sim_arb.vvp tb\tb_axi_rd_arb.v axi_rd_arb.v
vvp sim_arb.vvp
#   → CPU : 突发=160 拍=1040 错误=0
#   → SCAN: 突发=160 拍=1040 错误=0
#   → ========== tb_axi_rd_arb ALL PASS ==========
```

`tb_fb_scanout` 判定条件（全部满足才 PASS）：
1. 每行窗口的**第一个**像素列号为 0，行内列号严格 +1；
2. 相邻显示行的 FB 行号严格 +1（循环 0..15）——**死锁时会失败，这是"只有彩条/满屏白"的回归护栏**；
3. 每行窗口像素数正好等于 `FB_W`（少一个就说明该行有像素被判为"缓冲未就绪"）；
4. 两帧内 16 个 FB 行全部出现过（掩码 `0xffff`）。

`tb_axi_rd_arb` 判定条件：两个主机**同时**不停发读请求，从机按"地址决定数据"返回，
两侧各自校验每个 beat 的数据是否等于自己请求的地址；R 回程是靠 `owner` 分路的，
一旦 owner 在突发未收完时切换就会错路报错。当前两侧各 160 突发 / 1040 拍、0 错误。

## 8. 本次的简化与后续优化

- **单缓冲 + 无 VSYNC 交换**：CPU 直接画当前帧缓冲，可能出现轻微撕裂；下一步可加双缓冲
  （`FB1_BASE` 已按文档预留，扫描输出加 `FB_ADDR` 寄存器在 VSYNC 时切换）。
- **1:1 显示**：960×540 只占 1080p 的四分之一面积（宽高各一半），其余黑边；
  当前窗口放在**左上角**（`WIN_X=WIN_Y=0`）。想居中只需改一个地方——
  `ddr3_example_top.v` 里 `u_fb_scanout` 的 `.WIN_X(12'd480), .WIN_Y(12'd270)`；
  想"填满半屏"则加行/列复制（2 倍放大）。
- **整行预取**：每行 120 拍一次性取完再显示（正确性优先），突发流水留作后续提速。
- **CPU 显示通路尚未接入 BitBlt 引擎**：仓库 `rtl/` 里的自研 BitBlt 引擎后续可按
  《板级集成接线清单.md》挂到同一条互联上，与扫描输出共享 DDR。

### 8.1 剩余的时序余量（上板前值得知道的两个数）

**① 取数 vs 显示的时间余量（当前约 27%，够用但不算宽裕）**

在 1080p 下：一条显示行 = 2200 像素 ÷ 148.75MHz ≈ **14.8us**；
而取一条 FB 行 = 120 拍 × 9 个核时钟（1 拍握手 + 8 拍把一个 128bit beat 拆成 8 个像素）
= 1080 × 10ns ≈ **10.8us** → 余量 ≈ 4us。

这意味着：**取数必须在这条显示行结束前完成**，否则该行会重复上一行（表现为轻微"回跳/撕裂"，
不会花屏）。目前门控只允许超前 1 行，所以整行取数都被压在这一行的时间里。
若上板后发现偶发回跳（尤其在软件频繁读写内存时），最直接的改法是**把行缓冲从 2 个加到 3~4 个**
（门控放宽成 `next_y <= cons_s + 2/3`，用行号低位做环形选择），把取数窗口从 1 行放宽到 2~3 行。

**② 读通道在扫描输出手里时，CPU 的"读"会被挤（写不受影响）**

扫描输出每拍要花 8 个核时钟拆像素，期间会反压 `rready`，所以 `axi_rd_arb` 会
**在整行取数期间（≈10.8us / 14.8us ≈ 73% 的时间）一直握着读通道**（必须握着：
R 回程是按 `owner` 分路的，突发没收完就切换会把数据送错主机）。
- 影响：CPU 的**取指/取数**（I$/D$ miss 走读通道）在窗口行期间会变慢；
- **不受影响**：CPU 往帧缓冲**写**数据走的是 AW/W/B 直连通道，完全不经仲裁，
  所以软件的绘制速度不受这个策略影响；
- 想改善公平性：把 `fb_scanout` 的 `MAX_BURST` 调小、并让仲裁器在每个突发收完后
  只要 CPU 有请求就立刻归还（`cnt_s==0 && c_arvalid → owner<=0`）。
  代价是扫描输出的取数可能被 CPU 读流量拖慢 → 上面 ① 的余量会被吃掉，
  所以**演示优先保画面**时建议先维持现状。

## 9. BitBlt 2D 加速器接入（渲染链路跑通）

### 9.1 总线拓扑（已实现，RTL 在工程里）

```
                    ┌─────────────────────── SoC (RISC-V 软核) ───────────────────────┐
   CPU 写寄存器 ────▶ io_apbSlave_0 (0xF8100000, 64KB)                                │
                    │        │                                                       │
                    │        ▼                                                       │
                    │  blt_apb_top (APB3→AXI-Lite 桥 + blt_top)                      │
                    │        │  AXI4 读主机 ─┐        AXI4 写主机 ─┐                  │
                    │        │               │                     │                  │
   CPU DDR 访问 ────▶ io_ddrA_ar ──▶ axi_rd_arb(L1) ──▶ axi_rd_arb(L2) ──▶ DDR 控制器 AR/R
   CPU DDR 访问 ────▶ io_ddrA_aw/w ◀── axi_wr_arb ─────────────────────▶ DDR 控制器 AW/W/B
                                          ▲                     ▲
                    扫描输出 fb_scanout ──┘(接 L2 的 S 侧)       │
                                        BitBlt 引擎写主机 ──────┘
```
- **读通道两级仲裁**：L1 = CPU / BitBlt，L2 = (L1) / 扫描输出 ⇒ 优先级 **扫描输出 > BitBlt > CPU**
  （扫描输出必须最高，否则显示断流）。复用已经验证过的 `axi_rd_arb` 两级级联，不新写 3 输入仲裁器。
- **写通道仲裁**：新增 `axi_wr_arb`（CPU / BitBlt）。B 响应按 owner 分路，**在飞写突发未收完绝不切换**；
  CPU 优先、BitBlt 等满 32 拍强制插队、BitBlt 连发 4 笔后让回 CPU（防双向饿死）。
- **寄存器口**：SoC 的 APB slave 0（`soc.h: IO_APB_SLAVE_0_INPUT = 0xf8100000`）→ `blt_apb_top`。
  APB→AXI-Lite 桥每个事务都有独立响应相位（PREADY 只拉 1 拍），保证"写完立刻读"能读到新值。
- 加速器的 AXI 地址就是 CPU 看到的 DDR 绝对地址（同一套地址空间，软硬件一致）。

### 9.2 接入时踩到并修掉的坑（重要）

**顶层 `ddr3_example_top.v` 里 `apb_paddr / apb_pwdata / apb_prdata` 从未声明** ——`default_nettype wire`
下 Verilog 会把它们变成**1 位隐式线网**，32 位地址/数据被截断。原 demo 的 `apb3_top` 只用到 1 位数据、
且其 `sig` 输出悬空（未被任何逻辑使用），所以这个坑一直没暴露；接加速器前**必须显式声明**：

```verilog
  wire [31:0] apb_paddr;
  wire [0:0]  apb_psel;
  wire        apb_penable, apb_pwrite, apb_pready, apb_pslverror;
  wire [31:0] apb_pwdata, apb_prdata;
```
自测方法：整体 elaboration 时开 `iverilog -Wimplicit`，应输出 **0 条 implicit 告警**（现在就是 0）。

### 9.3 软件：`standalone/fulltest`（RISC-V IDE 工程）

软件写在**已有的 IDE 工程** `embedded_sw/soc/software/standalone/fulltest/` 里
（该目录含 `.cproject/.project/*.launch`，用 `STANDALONE=..`，与 `application/*` 的 makefile 不同）：

| 文件 | 说明 |
| --- | --- |
| `src/fulltest.c` | 全部测试与演示（约 720 行） |
| `src/userDef.h` | 保留厂商模板内容，**追加**了本工程的地址宏/寄存器宏/指令布局/颜色宏 |
| `makefile` | 你原来的（`PROJ_NAME=fulltest`，`STANDALONE=..`），未改动 |

地址宏与硬件逐一对齐：`BLT_BASE=0xF8100000`、`FB_BASE=0x00301000`、`SPRITE_BASE=0x00101000`、
`FB1_BASE=0x00401000`、`FLUSH_SCRATCH=0x00501000`、FB 960×540/stride 1920。

串口输出顺序（**每一步都打印，便于定位**）：

| 步骤 | 内容 |
| --- | --- |
| [1] | banner：所有地址宏 + FB 规格 + FIFO 深度 |
| [2] | CLINT 时间基准自检（读两次 tick 夹一段循环，打印差值） |
| [3] | 缓存一致性自检（FB1 写→`cache_evict`→`invalidate`→回读比对） |
| [4] | **寄存器探测**：读 CTRL/STATUS/FIFO_COUNT/IRQ_STATUS；若读到全 F/全 0 会明确提示 **"APB 窗口 0xF8100000 可能未接通"** 并给出排查提示，然后跳过初始化（不会对着死窗口反复写） |
| [5] | 联通性：一条最小 FILL + 等 DONE + 打印 `STATUS / DBG_CUR_CMD / PERF` + 像素回读 |
| [6] | T1 FILL / T2 COPY / T3 KEY / T4 ALPHA：每个都"准备数据→下发→等 DONE→invalidate→回读比对"，打印 **PERF 周期数** 与 PASS/FAIL，失配时打印最多 8 条 `mismatch (x,y) got/exp` |
| [7] | **整条链路演示**：引擎整屏 FILL(深蓝) → CPU 画 32×32 精灵（四边键色 0xF81F）→ 无限 KEY blit 右移循环（先 FILL 回填上一帧矩形、每帧 `cache_evict`、tick 节流 ~60fps），每 60 帧打印 `frame=%d x=%d eng_cycles=%d fps=%d` |
| [8] | `========== fulltest ALL PASS ==========` / `FAILED: N`；之后保持无限动画，HDMI 上一直有画面 |

健壮性设计：所有等待都有 tick 上限（单条指令 2s）超时打印现场而不是死等；引擎 ERR 自动 SOFT_RST；
引擎整体无响应时 T1~T4 打 SKIP 并计入 FAILED、演示退化为 CPU 绘制（保证 HDMI 仍有画面）。

### 9.4 验证证据（无需板卡即可复现）

| 测试台 | 覆盖 | 结果 |
| --- | --- | --- |
| `rtl/tb/tb_blt_top.v` | 引擎功能 T1~T8（含多行列比对）+ PERF 周期 | **ALL PASS** |
| `rtl/tb/tb_blt_apb.v` | **APB→寄存器→引擎→AXI→DDR 全链路**（软件实际走的路径） | **ALL PASS** |
| `rtl/tb/tb_axi_wr_arb.v` | 写仲裁：两主机各 1250+ 笔、无饿死、B 不错路、数据逐字节一致 | **ALL PASS** |
| `ARC_2DRA/rtl/video/tb/tb_axi_rd_arb.v` | 读仲裁：R 分路/不丢拍/不饿死 | **ALL PASS** |
| `rtl/tb/tb_cmd_fifo.v` / `tb_regs_axi_lite.v` | 指令 FIFO / 寄存器组（含满时反压） | **ALL PASS** |
| 整体 elaboration | `ddr3_example_top` 全设计（厂商加密模块用 stub） | **0 error / 0 implicit** |

复现命令（顶层整体检查，stub 已随仓库提供）：

```powershell
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
iverilog -g2012 -t null -s ddr3_example_top -Wimplicit -I ARC_2DRA/rtl -I ARC_2DRA/rtl/ddr3_controller `
  ARC_2DRA/rtl/ddr3_example_top.v ARC_2DRA/rtl/tb/stub_vendor.v `
  ARC_2DRA/rtl/video/{video_timing_1080p,fb_scanout,axi_rd_arb,axi_wr_arb}.v `
  ARC_2DRA/rtl/video/dvi_tx/{dvi_encoder,encode}.v ARC_2DRA/rtl/common/simple_dual_port_ram.v `
  ARC_2DRA/rtl/blt/blt_apb_top.v rtl/{blt_top,blt_regs_axi_lite,blt_engine_fsm,blt_addr_gen}.v `
  rtl/{axi_rd_master,axi_wr_master,stream_reader,pixel_path,cmd_fifo,sync_fifo}.v
```
> `ARC_2DRA/rtl/tb/stub_vendor.v` 是自动生成的空壳（`soc` / `ddr3_top` 端口全 input），
> 只用于 elaboration 检查连线与端口名，不参与综合。

### 9.5 上板步骤

1. **重新综合比特流**：工程 RTL 清单已加入 10 个加速器文件（用 `../../../rtl/...` 引用仓库根目录的
   **唯一真源**，不复制副本）+ `ARC_2DRA/rtl/blt/blt_apb_top.v` + `ARC_2DRA/rtl/video/axi_wr_arb.v`。
   若 Efinity 不接受工程目录之外的相对路径，把那 10 个文件复制到 `ARC_2DRA/rtl/blt/` 再改清单路径即可。
2. **编译并下载 fulltest**（RISC-V IDE 里选 `fulltest` 工程，源码已在 `standalone/fulltest/src/`），
   串口 115200 观察分步日志。
3. **期望现象**：串口按 [1]~[8] 依次打印，T1~T4 全 PASS 且带 PERF 周期；HDMI 上先出现深蓝底 + 一个
   左右移动的方形精灵（由 BitBlt 引擎绘制），同时每 60 帧打印一次 `frame/x/eng_cycles/fps`。
4. 若 [4] 提示窗口未接通：检查 `peri.xml` 里 APB slave 0 是否使能、`BLT_BASE` 是否与 `soc.h` 一致。
   若 [5]/T1~T4 失败但 [4] 正常：先看失配像素的位置与 `STATUS.ERR`，再查 DDR 地址与缓存冲刷。

---

## 10. 画面"左侧三角形黑色闪烁"根因与整改（v3 扫描输出）

### 10.1 现象与判据

引擎真正跑起来之后，960×540 帧缓冲窗口（画面左上角）出现**从左边缘起始的黑色楔形/三角形**，
由上到下往复扫过；引擎空闲时不出现。这是"**扫描输出取数赶不上显示行**"的典型表现 ——
显示侧对未就绪的行走黑（`win_d1 = win_now && buf_ok`），而取数 FSM 串行 → 一行迟到使下一行更迟 →
黑区逐行变宽 = 三角形。

### 10.2 三条叠加原因（详见 `rtl/功能清单.md` §13）

| 原因 | 数据 |
| --- | --- |
| 取一行占显示行 **73%** | v2 每拍拆 8 像素(9 core 周期) → 120 拍 ≈1080 周期 / 每行 1481 周期 |
| 扫描输出**抢不到**读通道 | L2 让位条件 `cnt_c==0 && !c_ar_hs` 几乎不可达；实测单行取数最长等 **16071 周期 ≈ 80 行** |
| 行缓冲只有 2 个、只超前 1 行 | 没有任何延迟容忍 → 迟到一行立刻出黑并累积 |

### 10.3 整改（4 处）

1. `axi_rd_arb.v` 新增 `S_PRIO`，L2 例化取 1：s 侧（扫描输出）挂起 AR 时不再受理 c 侧新 AR，
   让位延迟被钉死在"当前在飞的那一笔突发"内（16071 → 211 周期）。
2. `fb_scanout.v` 行缓冲**改存 128bit 拍**（每拍 1 周期进缓冲，取一行 ≈120 拍 + 延迟），
   显示侧用 `列号[2:0]` 从拍里选 16bit 像素；**AR 连续下发**把通道"钉"住整行。
3. 行缓冲 2 → **4 行环**，允许超前 `PRE=3` 行（延迟容忍 ≈3 个显示行）。
4. 增加**取数重同步**（显示追过待取行时跳到 `cons_s+1`）与**看门狗**（超时中止 + 欠账丢弃），
   保证 DDR 竞争再激烈也不会永久钉死或持续取过期行。

### 10.4 板级量化：寄存器 `0x20 SCAN_DBG`（只读，新增）

| 位域 | 含义 | 正常值 |
| --- | --- | --- |
| `[15:0]` | 欠载行数（窗口内因该行未就绪而输出黑的行数） | 0 |
| `[31:16]` | 取数看门狗中止次数 | 0 |

软件侧（`fulltest.c` 里加一个宏即可）：

```c
#define BLT_SCAN_DBG   (*(volatile uint32_t*)(BLT_BASE + 0x20))
uint32_t d = BLT_SCAN_DBG;
printf("SCAN_DBG: underrun=%u abort=%u\r\n", d & 0xFFFF, d >> 16);
```

**判据**：跑压测（引擎满载）时若两者始终为 0，说明显示通路已彻底修好；非 0 则按数值大小判断
残余抢占程度。这两个计数器原来的现象就发生在你说的那条黑三角上，属于"板上可复现、可量化"的证据。

### 10.5 仿真证据

- `ARC_2DRA/rtl/video/tb/tb_fb_scanout.v`：像素级正确性（行号/列号编码自检）**ALL PASS**，
  证明 128bit 拍缓冲 + 4 行环 + 重同步没有引入错位。
- `ARC_2DRA/rtl/video/tb/tb_scanout_bw.v`（新）：真实时序比例 + 板级真实仲裁拓扑的欠载复现/对照 TB，
  引擎空闲 **0 欠载**、引擎满载大量欠载（修复前）→ 修复后显著下降。
- `rtl/tb/run_regress.ps1`：**11 项全 ALL PASS**。

