# 加速器 RTL 设计规划（Verilog 实现版）

> 定位：从"文档 / C 驱动 / Python 模拟器已完成"到"Verilog RTL 可上板"之间的工程蓝图。
> 关联材料（本仓库已有）：
> - 需求与方案：《赛题二.md》《赛题二_方案设计与原理讲解.md》《分阶段路线图.md》
> - 地址与 IP 决策：《DDR3内存分配分析.md》《IP核复用分析.md》
> - **软硬件契约（已冻结，RTL 必须逐位对齐）**：`software/blt_regs.h`、`software/README.md`
> - **行为金标准（可复算、可比对）**：`simulator/sim_model.py`（引擎公式
>   `(fg*α + bg*(255−α) + 127) >> 8`、16B 行向量化突发、寄存器契约）
> - 开发语言：**Verilog-2001/2005**（兼容 Efinity 综合；文件与模块同名、一模块一文件）

---

## 0. 分辨率主线：960×540@60（qHD）★ 设计参数速查

> 本项目输出图像规模 = **960×540 @ 60fps**（qHD，1920×1080 的 1/4，16:9 宽屏）。
> 高于赛题最低要求 640×480@60；帧缓冲/行距/带宽等派生参数如下表（全文档统一使用）。

| 参数 | 值 | 说明 |
| --- | --- | --- |
| 有效像素 | 960 × 540 = **518,400 px/帧** | RGB565，2B/px |
| 帧缓冲单张 | 1,036,800 B = **0xFD200 ≈ 1.0MB** | < 1MB，双缓冲仍各占 1MB 窗 |
| 帧缓冲行距 | 1920B = 0x780 = **120×16B** | 行首天然 16B 对齐；64B 缓存行对齐（1920÷64=30） |
| 像素时钟 | **37.36MHz**（精确 37.3632MHz） | 非 DMT，业界 cvt modeline；PLL 就近合成（误差<0.5%，显示器可锁） |
| 行时序 | 960 / +48(前肩) / +32(同步) / +80(后肩) → **1120** | 极性 +HSYNC |
| 场时序 | 540 / +3 / +5 / +8 → **556** | 极性 −VSYNC |
| 刷新率 | 37.3632M ÷ (1120×556) ≈ **60.0 Hz** | |
| TMDS 线速率 | 37.36×10 = **373.6 Mbps/线** | 远低于 HSIO 1.5Gbps 上限 |
| 扫描输出读带宽 | 1,036,800B×60 ≈ **62.2 MB/s** | ≈ 可用带宽(1.0~1.2GB/s) 的 ~5% |
| 引擎满屏重画 | 518,400px ÷ 100Mpx/s ≈ **5.2ms/次** | 60fps 帧预算 16.7ms → 每帧约 3 遍满屏 |
| 32×32 精灵理论上限 | 1.67Mpx ÷ 1024px ≈ **1630 个/帧** | 未扣指令下发/清屏开销 |

帧缓冲分区保持《DDR3内存分配分析.md》不变：FB0 = DDR_BASE+0x300000、FB1 = +0x400000
（每张 0xFD200 < 1MB，间隔 1MB 依旧成立），精灵/程序区不变。
升 1080p 冲刺：像素率 ≈×4、像素时钟 148.5MHz、行距 3840B —— 结构与本规划完全一致，仅换参数。

---

## 1. 功能清单：这个加速器到底要实现哪些功能

从赛题基础要求 + 高阶挑战 + 三个规划文档逐条反推，RTL 侧功能清单如下（★=赛题点名项）：

### 1.1 指令引擎（BitBlt 核心）
| # | 功能 | 说明 | 对应赛题/文档 |
| --- | --- | --- | --- |
| E1 | **指令解析** | 一条指令 = 8×32bit 字（= `blt_cmd_t` 32B）：op/src_addr/dst_addr/src_stride/dst_stride/width/height/alpha/color | 基础① |
| E2 | **BLOCK_COPY** | 矩形位块搬运：源突发读 → 像素直通 → 目的突发写 | 基础① |
| E3 | **SOLID_FILL** | 纯色填充：不读源，生成常量色字节流写目的 | 基础① |
| E4 | **ALPHA_BLEND** | 硬件混合：读前景 + 读背景 → DSP 乘加 → 写回 | 高阶① |
| E5 | **COLOR_KEY** | 键色跳过（默认品红 0xF81F）：相等则不写目的 | 高阶② |
| E6 | **矩形行循环** | 两层 FSM：外层 height 次行循环、内层 width 次像素循环；每行结束地址 += stride | 基础①/原理 5.7 |
| E7 | **重叠检测**（文档级） | src 与 dst 矩形重叠时需反向拷贝；v1 约定驱动不产生重叠指令，v2 实现 | 原理 5.7 |

### 1.2 总线与存储（★基础②：突发 + FIFO）
| # | 功能 | 说明 |
| --- | --- | --- |
| B1 | **AXI-Lite 从机** | 寄存器组配置口（CTRL/STATUS/CMD_FIFO/IRQ…），接 SoC APB slave 窗口 |
| B2 | **AXI4 主机（读写两套通道）** | 引擎/扫描输出主动访问 DDR3 硬核的 AXI 从口，走 AXI 互联 |
| B3 | **突发传输** | INCR 突发，128bit 数据口下 8~16 拍/笔（128~256B），段式拆分见第 5/6 节 |
| B4 | **指令 FIFO（BRAM）** | 深度 256 条 ×32bit，GO 后自动消费、可批量超深度 |
| B5 | **源/像素/写三组 FIFO** | 解耦 DDR 延迟抖动，让像素通路匀速（深度参数化，见 5.5） |
| B6 | **16B 对齐与 WSTRB 掩码** | 行内任意 x 偏移的"首尾半拍"处理，绝不越界写（见 6.7） |

### 1.3 软硬协同（★基础③④）
| # | 功能 | 说明 |
| --- | --- | --- |
| S1 | GO 自动消费语义 | CTRL.GO 写一次后引擎自动消费 FIFO 直到空（与 blt_drv 一致） |
| S2 | DONE 电平 + 完成中断 | STATUS.DONE = FIFO 空且引擎空闲；IRQ_STATUS W1C（对接 PLIC User Int A，ID 16） |
| S3 | ERR 上报 | 非法 op/校验失败 → STATUS.ERR；后续指令继续 |
| S4 | 双缓冲 + VSYNC | 属扫描输出模块：FB_ADDR 寄存器 VSYNC 边界交换、VSYNC.LATCH W1C |

### 1.4 显示通路（独立外围：扫描输出控制器）
| # | 功能 | 说明 |
| --- | --- | --- |
| V1 | 960×540@60 时序 | pixel_clk 37.36MHz 计数器状态机：1120×556，DE/HSYNC/VSYNC |
| V2 | 行预取 + 行 FIFO | AXI 突发读 Front 帧缓冲 → 异步 FIFO（≥2 行）→ 像素节奏输出 |
| V3 | RGB565→RGB888 | 扩展后送 HDMI TX IP（复用 03 号 demo 的 RTL） |
| V4 | FB 指针可编程 | SCANOUT_FB_ADDR/STRIDE/CTRL.EN 寄存器（与 blt_regs.h 一致） |

### 1.5 可测性（加分）
| # | 功能 | 说明 |
| --- | --- | --- |
| D1 | 带宽/完成计数器 | 一段时间内完成字节数，供 P3 调突发用 |
| D2 | 寄存器回读快照 | 当前指令 8 字回读（定位 FSM bug 快一倍） |

> **一句话**：RTL 要交付 = ① 指令 FIFO + 4 种 op 的引擎 FSM（E1~E6）＋② AXI4 主机读写（B2/B3）＋③ AXI-Lite 从机与状态语义（B1/S1~S3）＋④ 像素通路（COPY/FILL/ALPHA/KEY）＋⑤ 扫描输出与双缓冲（V1~V4）。真正需要手写的硬件一共就这五块，其余（CPU/DDR/互联/FIFO IP）全部复用。

---

## 2. 顶层架构与模块划分

### 2.1 系统接线图（RTL 视角）

```
                 ┌─────────────────────── core_clk 100MHz ───────────────────────┐
                 │                                                                 │
   RISC-V CPU    │   APB/AXI-Lite   ┌───────────────────────┐                      │
  (Sapphire SoC) │─────────────────▶│ blt_top（本规划主体）   │  AXI4 M(R/W)         │
   (软件层已交付) │                  │  blt_regs_axi_lite ◀───┤──────────┐          │
                 │                  │  cmd_fifo              │          │          │
                 │                  │  blt_engine_fsm        │          ▼          │
                 │                  │   ├ addr_gen/burst_spl │  ┌───────┴──────┐   │
                 │                  │   ├ axi_rd_master      │  │ AXI 互联     │   │
                 │                  │   ├ axi_wr_master      │  │ (efx_axi_    │   │
                 │                  │   ├ src_fifo           │  │ interconnect │   │
                 │                  │   ├ pix_fifo / wd_fifo │  │ 3主→1从,128b) │   │
                 │                  │   └ pixel_path         │  └───┬───▲──────┘   │
                 │                  └───────────────────────┘      │   │           │
                 │  APB/AXI-Lite    ┌───────────────────────┐      │   │           │
                 │─────────────────▶│ scanout_top（扫描输出） │──────┘   │           │
                 │                  │  vga_timing (pixel_clk)│ AXI M(R) │           │
                 │                  │  line_fifo (异步)      │          │           │
                 │                  └───────────┬───────────┘          ▼           │
                 │                              │           ┌──────────────────┐   │
                 │                              │ DE/HS/VS  │ DDR3 硬核控制器   │   │
                 │  pixel_clk 37.36MHz          ▼ RGB       │ (Interface Des. │   │
                 │                       ┌──────────────┐   │  配置, AXI 从口) │   │
                 │                       │ HDMI TX RTL  │   └──────────────────┘   │
                 │                       │ (03号demo复用)│──▶ HDMI                 │
                 └───────────────────────┴──────────────┘                         ┘
```

### 2.2 顶层模块树与命名（一模块一文件，Verilog-2001）

```
rtl/
├── blt_top.v            # 引擎顶层：例化 regs + fifo + engine；只连 AXI 口
├── blt_regs_axi_lite.v  # AXI-Lite 从机：寄存器读写 + 状态/中断逻辑
├── cmd_fifo.v           # 同步 FIFO（BRAM 实现或 efx_fifo_2 包装），256×32
├── blt_engine_fsm.v     # 主控 FSM：POP_CMD / LINE_LOOP / PIXEL_LOOP
├── blt_addr_gen.v       # 行地址 + 段式突发拆分（头/中/尾）
├── axi_rd_master.v      # AXI4 主机读通道（AR/R），参数化数据宽度
├── axi_wr_master.v      # AXI4 主机写通道（AW/W/B），参数化数据宽度
├── src_fifo.v / pix_fifo.v / wd_fifo.v   # 引擎内数据 FIFO（或统一一个参数化 sync_fifo.v）
├── pixel_path.v         # 像素通路：COPY 直通 / FILL 常量 / KEY 比较 / ALPHA 乘加
├── scanout_top.v        # 扫描输出：寄存器 + 时序 + 行预取 + 行 FIFO
├── vga_timing.v         # 960×540 计数器状态机（pixel_clk，参数化）
└── line_fifo.v          # 异步 FIFO（或 efx_fifo_2 异步例化）
```

### 2.3 主要模块端口约定（示例）

```verilog
// —— blt_top ——
module blt_top #(
    parameter AXI_DATA_W = 128,   // 引擎 AXI 主机数据宽度：与互联/DDR 对齐
    parameter CMD_FIFO_DEPTH = 256
)(
    input  wire                 clk,          // core_clk 100MHz
    input  wire                 rst_n,
    // AXI-Lite 从机（CPU 配置口）
    input  wire [11:0]          s_axil_awaddr, input  wire s_axil_awvalid,
    output wire                 s_axil_awready, input  wire [31:0] s_axil_wdata,
    input  wire [3:0]           s_axil_wstrb,  input  wire s_axil_wvalid,
    output wire                 s_axil_wready, output wire s_axil_bvalid,
    output wire [1:0]           s_axil_bresp,  output wire s_axil_bready,
    input  wire [11:0]          s_axil_araddr, input  wire s_axil_arvalid,
    output wire                 s_axil_arready, output wire [31:0] s_axil_rdata,
    output wire [1:0]           s_axil_rresp,  output wire s_axil_rvalid,
    input  wire                 s_axil_rready,
    // AXI4 主机（访问 DDR3，经互联）
    output wire [31:0]          m_axi_araddr,  output wire [7:0] m_axi_arlen,
    output wire [2:0]           m_axi_arsize,  output wire [1:0] m_axi_arburst,
    output wire                 m_axi_arvalid, input  wire m_axi_arready,
    input  wire [AXI_DATA_W-1:0] m_axi_rdata,  input  wire [1:0] m_axi_rresp,
    input  wire                 m_axi_rlast,   input  wire m_axi_rvalid,
    output wire                 m_axi_rready,
    output wire [31:0]          m_axi_awaddr,  output wire [7:0] m_axi_awlen,
    output wire [2:0]           m_axi_awsize,  output wire [1:0] m_axi_awburst,
    output wire                 m_axi_awvalid, input  wire m_axi_awready,
    output wire [AXI_DATA_W-1:0] m_axi_wdata,  output wire [AXI_DATA_W/8-1:0] m_axi_wstrb,
    output wire                 m_axi_wlast,   output wire m_axi_wvalid,
    input  wire                 m_axi_wready,  input  wire m_axi_bvalid,
    input  wire [1:0]           m_axi_bresp,   output wire m_axi_bready,
    // 中断
    output wire                 irq_done
);
```

> **数据宽度决策（答辩要能讲）**：互联与 DDR 硬核 AXI 口配 128bit，引擎主机口也设
> **128bit**（1 beat = 16B = 8 个 RGB565 像素），避免互联做位宽转换、读回一拍多用。
> 仿真/首版可先参数化降成 32/64bit 便于 TB 编写，板级集成前统一 128。

---

## 3. 时钟 / 复位 / 面积预算

| 时钟域 | 频率 | 来源 | 用在哪 |
| --- | --- | --- | --- |
| core_clk | 100MHz | 25MHz × PLL | CPU / 互联 / blt_top / scanout 取数 / DDR 控制器 AXI 侧 |
| pixel_clk | 37.36MHz | PLL（按向导就近取 M/N；误差<0.5% 显示器可锁） | vga_timing、行 FIFO 读侧、HDMI TX |
| ddr 物理时钟 | 400MHz | PLL | DDR3 硬核内部（Interface Designer 配置，RTL 不直接碰） |

- 复位：统一异步复位/同步释放（`reset.v` 或 PLL 锁定后产生），core 域与 pixel 域各自复位。
- 跨域唯一通道：**异步 FIFO**（行 FIFO），禁止裸打一拍。
- 面积预算（依据《IP核复用分析.md》风险 5）：SoC 已占 ~11K LUT/82 BRAM；**引擎 + 扫描输出
  控制在 ≤15K LUT、≤40 块 BRAM、DSP ≤12 个**（Ti60 共 62K LE / 256 BRAM / 160 DSP，余量充足）。

---

## 4. 寄存器与指令：RTL 契约（逐位对齐 blt_regs.h）

RTL 侧寄存器偏移与位定义**必须**与 `software/blt_regs.h` 完全一致（驱动已按它写好）：

| 偏移 | 名称 | R/W | 位定义（RTL 实现要点） |
| --- | --- | --- | --- |
| 0x00 | CTRL | RW | bit0=GO：**写 1 使能自动消费**（引擎置 run_en；bit0 写 0 不停止在途指令，仅供软复位配合）<br>bit1=IRQ_EN　bit2=SOFT_RST（写 1 清 FIFO/FSM 回 IDLE、清 DONE/ERR） |
| 0x04 | STATUS | R | bit0=BUSY（引擎正在执行）bit1=DONE（电平：FIFO 空 && 引擎空闲）bit2=ERR bit3=FIFO_EMPTY |
| 0x08 | CMD_FIFO_DATA | W | 每写 1 字入 FIFO；**连写 8 字 = 一条指令**；FIFO 满时 wready 不拉高即可天然反压（也可写满丢弃+ERR） |
| 0x0C | CMD_FIFO_COUNT | R | 完整指令条数（字计数 >> 3） |
| 0x10 | IRQ_STATUS | W1C | bit0=DONE：DONE 且 IRQ_EN 时置位并输出 irq_done；写 1 清除 |
| 0x14 | IRQ_EN | RW | bit0=IRQ_EN 镜像（或并入 CTRL） |
| 0x18 | DBG_CUR_CMD | R | （可测性）当前执行指令前 2 字回读 |
| 0x1C | PERF | R | （可测性）带宽计数（完成字节数） |

**命令字 → 引擎内部寄存器**（POP_CMD 时从 FIFO 弹出 8 字装入，与 `blt_cmd_t` 布局一致）：

| 字段 | 位/字 | 说明 |
| --- | --- | --- |
| op | 字0 | 0=COPY 1=FILL 2=ALPHA 3=KEY；**其它值 → ERR，跳过本条** |
| src_addr | 字1 | 字节地址（FILL 忽略） |
| dst_addr | 字2 | 字节地址 |
| src_stride | 字3 | 源行距字节（FILL 忽略） |
| dst_stride | 字4 | 目的行距字节 |
| width/height | 字5[15:0]/[31:16] | 像素宽/行高 |
| alpha | 字6[15:0] | 0~255（仅 ALPHA） |
| color | 字7 | FILL 填充色 / KEY 键色 |

**状态语义（与 README 一致，RTL 千万别改成"GO 只跑一条"或"DONE 是脉冲"）**：
`run_en(GO)=1` 时引擎在 FIFO 非空即 POP 执行，执行完再查 FIFO；`FIFO空 && 引擎IDLE` → DONE=1
（电平）。CPU 批量下发可超 FIFO 深度而不死锁的前提正是这个语义。

---

## 5. BitBlt 引擎：FSM 与数据通路设计

### 5.1 主状态机

```
           ┌────────┐   fifo非空 && run_en   ┌──────────┐
  复位 ───▶│  IDLE  │───────────────────────▶│ POP_CMD  │
           │ DONE=1 │                        └────┬─────┘
           └───┬────┘                             │ 校验失败→ERR(STATUS)→IDLE
               ▲  height==0 置 DONE               ▼
           ┌───┴─────────────┐            ┌───────────────┐
           │ DONE_SET(IDLE)  │◀───────────│  LINE_LOOP    │  ← 行循环：行号/地址计算
           └─────────────────┘  行耗尽     └──────┬────────┘
                                          发起本行段式突发  │
                                          读/写事务完成      ▼
                                     ┌────────────────────────┐
                                     │  PIXEL_LOOP（随 op 变） │  ← 像素处理/攒写突发
                                     └────────────────────────┘
```

要点：
- **行是独立事务单元**：每行 = 独立的一组突发（读段+写段），行与行之间状态机回到
  LINE_LOOP 更新地址。好处：突发绝不跨行（天然不越 4KB、天然行距正确）。
- **POP_CMD 与执行解耦**：FIFO 弹出用独立的满/空握手，引擎执行期间 CPU 可继续推。

### 5.2 地址生成（addr_gen）

```verilog
// 行首字节地址（px=0..width-1, row=0..height-1）
src_row_addr = src_addr + row * src_stride + 0;
dst_row_addr = dst_addr + row * dst_stride + 0;
// 行内像素 p 的字节地址 = 行首 + p*2（RGB565）；16B 字内偏移 = (行首+p*2) & 4'hF
```

### 5.3 像素通路（pixel_path）四种 op 的数据流

| op | 读源 | 读背景 | 处理 | 写目的 |
| --- | --- | --- | --- | --- |
| COPY | src 突发 → src_fifo | 无 | 直通 | wd_fifo → 突发 |
| FILL | 无 | 无 | 常量 color 复制 width×height 次 | 同上 |
| KEY | src 突发 | 无 | `fg==key ? 丢弃 : 通过`（整行全透明→可省写突发） | 同上（带 WSTRB 掩码） |
| ALPHA | src 突发 | dst 原值突发 | `(fg8*α + bg8*(255−α)+127)>>8`，三通道 | 同上 |

- COPY 只需"读→写"两条腿；FILL 只需"写"一条腿（这是 P2 最快的两个 op）。
- ALPHA 是**三腿**：src 读、bg 读、dst 写。v1 实现：每行按"段"推进——先把一段的
  src 突发与 bg 突发并行发起，数据分别进两个 FIFO，像素通路逐像素混合后进 wd_fifo，
  攒够一段再写突发。段长 = 一个写突发的像素数（128bit 口 8 拍 = 64 像素）。
- 像素通路吞吐目标 1 px/clk @100MHz；混合只在 ALPHA op 时旁路使能，其余 op 不占 DSP 功耗/时序。

### 5.4 段式突发策略（16B 对齐 + 首尾掩码）★最容易错的地方

前提约定（尽量让内存满足，就省一半麻烦）：
1. 所有图/帧缓冲的**行距 16B 对齐**（FB stride=1920=120×16B ✓；精灵图分配时把
   stride 对齐到 16B，不足补 padding 字节）——这样**行首天然 16B 对齐**；
2. 精灵在行内可能出现在任意像素 x → 目的行首字节偏移 = 行首 + x*2 未必 16B 对齐。

因此**写**要拆三段（每段一笔或多笔突发）：

```
行宽 W 像素 = 2W 字节，dst 行首 = R（16B 对齐）… 实际起点 A = R + x*2（可能不齐）
┌────────────┬──────────────────────────────┬─────────────┐
│ HEAD 半拍  │  MID：整 16B 突发（全 WSTRB） │ TAIL 半拍    │
│ 1 beat     │  N beats × 16B               │ 1 beat      │
│ WSTRB 只选 │                               │ WSTRB 只选  │
│ 需要的字节  │                               │ 需要的字节   │
└────────────┴──────────────────────────────┴─────────────┘
```

- 读没有 WSTRB：**读用"覆盖式对齐读"**——从对齐起点读整拍，多读的 padding 像素
  在像素通路丢弃即可（前提：读地址落在已分配的 DDR 区内且行距有 padding，安全性在
  内存布局文档里已保证）。**行尾多读的像素**不得越过该图存储区末尾（软件按 16B
  padding 行距排布即可满足）。
- 若宽 W 很小（≤8 像素），HEAD+TAIL 可能重叠同一拍：此时只需 1 beat 且 WSTRB 按
  `[start_off +: 2W]` 取模掩码，**禁止产生负拍数**（拆分逻辑用拍数>0 判断，见 6.7 伪代码）。
- FILL 的行首如果也不对齐，同样三段处理；FILL 无读，成本最低。

### 5.5 FIFO 深度参数（BRAM 预算内）

| FIFO | 位宽 | 深度 | 用途 |
| --- | --- | --- | --- |
| cmd_fifo | 32 | 256 字（=32 条指令） | 指令排队（同域同步 FIFO） |
| src_fifo（读回） | 128 | 8~16 | 吸收读突发延迟（≥1 突发长） |
| bg_fifo（ALPHA 用） | 128 | 8~16 | 同上 |
| wd_fifo（待写） | 128 | 8~16 | 攒够一拍才发 W，给写通道退让 |
| 行 FIFO（scanout） | 16 | 2048 | 异步；一行 960 entries，≥2 行 = 1920 entries ≤ 2048 ✓ |

---

## 6. AXI 总线读写接口使用规范 ★（重点）

### 6.1 两个角色，两套规范（先分清再动手）

| 接口 | 角色 | 通道 | 用途 | 规范级别 |
| --- | --- | --- | --- | --- |
| s_axil_* | **从机**（CPU → 引擎） | AW/W/B/AR/R | 寄存器配置 | AXI-Lite（每笔 1 拍数据、无突发） |
| m_axi_* | **主机**（引擎 → DDR3） | AR/R + AW/W/B | 像素数据搬运 | AXI4 Full（突发、WSTRB、RLAST） |

引擎要同时会"当从机"（你写 CPU 时熟悉）和"当主机"（本赛题新增技能点）。

### 6.2 一切的基础：VALID/READY 握手规则（两种接口通用）

每个通道一对 VALID/READY，**数据在两者同为高的那个时钟沿传输**：

1. **发送方拉高 VALID 后不得撤销**，必须保持到握手完成（VALID & READY 同时为高）；
2. 接收方**可以随时拉高 READY**（不必等 VALID）；也可先给 READY 等 VALID；
3. 禁止组合环路：READY 的产生不能组合依赖本通道 VALID（反之亦然）——状态机里
   用寄存器记"忙"，READY 由"空闲"产生，VALID 由状态产生；
4. 通道之间互相独立握手，可以流水错开（如 W 数据可晚于 AW 地址若干拍到达，但
   AXI4 无 WID，**不同突发的写数据不得交织**，同突发内建议无气泡连续发）。

四种时序情形（都能正确工作，编码时全按情形 1 最省事）：

```
情形1(标准):       情形2(VALID先):     情形3(READY先):    情形4(同时撤):
CLK _|‾|_|‾|_      CLK _|‾|_|‾|_       CLK _|‾|_|‾|_      CLK _|‾|_|‾|_
VALID __|‾‾‾|___   VALID ____|‾‾|___   VALID __|‾‾|___    VALID _|‾|_____
READY ____|‾|____  READY _|‾‾‾|____   READY ____|‾|____   READY __|‾|____
        ^传输                ^传输              ^传输            ^传输
```

### 6.3 AXI-Lite 从机（寄存器口）规范要点

- 单笔事务：AW 握手一次 + W 握手一次 → 内部写寄存器；**先收齐 W 再落寄存器**
  （W 可能晚于 AW 到达）；写完后必须回 **B 响应**（BRESP=OKAY(2'b00)；地址越界可回
  DECERR(11)、寄存器不存在回 SLVERR(10)，建议非法地址回 SLVERR）。
- 读：AR 握手 → 数据在 **RVALID&RREADY** 拍返回（可插 1~2 拍延迟）；无突发无 RLAST。
- 简单安全的从机实现：**AWREADY/WREADY = 本通道空闲**；收到后把请求寄存一拍，下一拍
  BVALID；AR 同理 RVALID。所有响应用寄存器输出，满足 6.2 规则 3。
- 可写寄存器只在 `wstrb` 对应字节为 1 时更新（驱动是 32 位整字写，全使能即可，但
  规范上要做）；`IRQ_STATUS` 是 **W1C**（写 1 清 0），CTRL 是整字覆写。

### 6.4 AXI4 主机（数据口）规范要点

**读突发（AR/R 通道）**
- 每笔突发：`ARADDR + ARLEN + ARSIZE + ARBURST` 一次握手；从机回 `ARLEN+1` 个数据拍，
  最后一拍 **RLAST=1**；每拍都要等 RVALID&RREADY 握手。
- 字段取值（本设计）：`ARBURST=INCR(2'b01)`；`ARSIZE=log2(每拍字节数)`，
  128bit 口 → 每拍 16B → **ARSIZE=3'd4**；`ARLEN=拍数−1`（8~16 拍 → 7~15）；
  AXI4 INCR 突发**长度上限 256 拍**，且**不得跨 4KB 地址边界**（本设计行内 ≤1920B，安全）。
- 一拍地址粒度 = 总线字节数（128bit=16B），所以 **每拍地址必然 16B 对齐** —— 这就是
  "读覆盖式对齐、写靠 WSTRB"的根本原因。

**写突发（AW/W/B 通道）**
- `AWADDR/AWLEN/AWSIZE/AWBURST` 同读；每拍 `WDATA+WSTRB`，**最后一拍 WLAST=1**；
- **WSTRB 是唯一防越界写的手段**：每 bit 对应数据总线一个字节，1 才写。段式拆分里
  头/尾拍的 WSTRB 只置需要的字节；**宁可少写不可多写**；
- **必须收 B 响应**：每笔突发回一个 `BVALID&BRESP`（OKAY）。简单实现：完成一笔写才
  释放 wd_fifo 队列头、才允许发起下一笔写（保证 B 顺序与 AW 顺序一致、也避免覆盖
  未完成写导致读回脏数据——**写完 dst 后若还要读同一行做 ALPHA 的背景，必须等 B**）。

**主机侧反压处理**（引擎是连续流，最易踩坑）
- 读：src_fifo 将满 → 停发新 AR；R 每拍都收（rready 常拉高，数据来了就收）。
- 写：wd_fifo 有 ≥ 一拍数据才发 W；W 通道握不上（wready 低）就停像素通路取数，
  **绝不在中途撤 WVALID**；B 未回前不覆盖写队列条目。

### 6.5 主机读通道骨架（axi_rd_master.v，示意非完整）

```verilog
// 外部信号：rd_req / rd_addr / rd_len(拍数) / rd_ack / rdata_valid / rdata_last / rdata
reg               rd_busy;            // 正在一笔读突发中
reg [7:0]         rd_cnt;             // 已收拍数

// —— 发 AR（情形1：空闲且来请求，一拍发出；ARVALID 发出后保持到握手）——
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)              rd_busy <= 1'b0;
    else if (m_axi_arready && ar_valid) rd_busy <= 1'b1;
    else if (rd_done)        rd_busy <= 1'b0;   // rd_done = RLAST 握手
end
assign ar_valid = rd_req && !rd_busy;          // 不依赖 ARREADY → 无组合环
assign m_axi_araddr  = rd_addr;
assign m_axi_arlen   = rd_len - 8'd1;          // ARLEN = 拍数-1
assign m_axi_arsize  = AXI_SIZE;               // 3'd4 (16B/拍, 128bit)
assign m_axi_arburst = 2'b01;                  // INCR
// ARVALID 一旦发出保持到握手：见上面 rd_busy 的 ar_valid 表达式在握手后由
// rd_busy=1 关断，握手未完成时 !rd_busy 仍为 1 → ARVALID 保持。✓

// —— 收 R：数据来了就收（rready 常高）——
assign m_axi_rready = 1'b1;                    // 每拍都收（简化版；反压时关断）
always @(posedge clk) begin
    if (m_axi_rvalid && m_axi_rready) begin
        rdata_valid <= 1'b1;  rdata <= m_axi_rdata;
        rd_cnt <= rd_cnt + 1;
        if (m_axi_rlast) rdata_last <= 1'b1;   // 本突发最后一拍
    end else begin
        rdata_valid <= 1'b0;  rdata_last <= 1'b0;
    end
end
```

### 6.6 主机写通道骨架（axi_wr_master.v，示意非完整）

```verilog
// 外部：wr_req / wr_addr / wr_len / wd_valid / wd_data / wd_strb / wd_ready(背压)
// 简化模型：AW 与第一拍 W 一起发（规范允许 W 晚于 AW，一起发最简单）

reg               wr_busy;      // 地址已发出/正在写
reg [7:0]         w_cnt;        // 已发数据拍
reg               b_pending;

// 发 AW：空闲且有请求
assign m_axi_awvalid = wr_req && !wr_busy && !b_pending;
assign m_axi_awaddr  = wr_addr;
assign m_axi_awlen   = wr_len - 8'd1;
assign m_axi_awsize  = AXI_SIZE;
assign m_axi_awburst = 2'b01;
// W：一拍一拍发，最后一拍 WLAST
assign m_axi_wvalid  = wr_busy && wd_valid;     // 外部 FIFO 给数据+valid
assign m_axi_wdata   = wd_data;
assign m_axi_wstrb   = wd_strb;                 // 头/尾拍掩码由上层算好
assign m_axi_wlast   = (w_cnt == wr_len - 8'd1);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin wr_busy <= 1'b0; w_cnt <= 0; b_pending <= 1'b0; end
    else begin
        if (m_axi_awvalid && m_axi_awready) begin
            wr_busy <= 1'b1; w_cnt <= 0; b_pending <= 1'b1;  // B 还没回
        end
        if (m_axi_wvalid && m_axi_wready) begin
            w_cnt <= w_cnt + 1;
            if (m_axi_wlast) wr_busy <= 1'b0;               // 数据发完
        end
        if (m_axi_bvalid && m_axi_bready) begin
            b_pending <= 1'b0;                              // 允许下一笔
            // BRESP != OKAY → 置 ERR 状态（可后续查）
        end
    end
end
```

### 6.7 段式拆分伪代码（addr_gen 的灵魂，先写对再提速）

```text
// 每行调用一次：输入 A=行内起点字节地址(任意), L=本行要处理的字节数, 数据总线字节 B(16)
// 写侧返回若干 (addr, len拍数, 每拍 wstrb) 项；读侧返回对齐覆盖的 (addr, len)
head_bytes = B - (A mod B)                      // 起点到下一个 16B 边界的字节数
if (head_bytes == B) head_bytes = 0             // 起点已对齐 → 无头
tail_bytes = (A + L) mod B                      // 终点越过上一个 16B 边界的字节数
if (tail_bytes == 0) tail_bytes = 0

if (head_bytes > 0 && head_bytes >= L)
    → 单拍事务: addr=align(A), len=1, wstrb=掩码(start_off, L)   // 整行不足一拍
else:
    if (head_bytes > 0) → 事务1: addr=align(A), len=1, wstrb=掩码(start_off, head_bytes)
    mid_len = (L - head_bytes - tail_bytes)/B   // 整拍部分
    if (mid_len > 0) → 事务2: addr=align(A)+B, len=mid_len, wstrb=全1
    if (tail_bytes > 0) → 事务3: addr=align(A+L), len=1, wstrb=掩码(0, tail_bytes)

// wstrb 掩码(start_off, n)：把 [start_off, start_off+n) 字节位段置 1，
// 其它字节位清 0 —— 只写矩形内部的字节，padding 一律不写。
// 读侧忽略 wstrb，多读的 padding 在 pixel_path 丢弃。
```

### 6.8 AXI 常见错误清单（评审/自测对照）

| 错误 | 现象 | 修法 |
| --- | --- | --- |
| VALID 先撤 | 数据丢失/错位 | 握手完成才允许撤（寄存器化状态） |
| ARREADY 组合依赖 ARVALID | 组合环、时序烂 | READY 只由"空闲"产生 |
| 忘了收 B | 下一笔写覆盖未完成写、ALPHA 读回脏数据 | b_pending 门控下一笔 |
| WLAST 错位 | 从机认为突发不完整 | 计数器到 len−1 拍置 1 |
| 地址没 16B 对齐 | AXI 协议错误（size=4 时低 4 位必须 0） | 对齐起点 + 覆盖读 |
| WSTRB 没掩码越界写 | 相邻图/行被污染（难查！） | 严格按 6.7 生成掩码 |
| 突发跨 4KB | 从机不支持 → 挂死/报错 | 行内 ≤1920B + 行独立事务 |
| ARLEN 超从机上限 | DDR 硬核限制（查 IP 手册，常见 ≤16/32 拍） | 段长 ≤ 上限 |

---

## 7. 内部 DSP / 硬件乘法器编写规范 ★（重点）

### 7.1 像素定点数学（与金标准公式逐位一致）

赛题公式 `out = fg×α + bg×(1−α)`，α 用 0~255 整数（255=不透明）实现为：
`1−α = 255−α`，**最终定点式（与 sim_model.py / blt_drv 完全相同，防比对不一致）**：

```
out_ch = (fg_ch × α + bg_ch × (255 − α) + 127) >> 8     // +127 四舍五入
```

三通道（RGB565）并行各算一遍，通道先展开到 8bit 再算（提高精度、三通道对称好写）：
- R：`fg_r8 = {fg[15:11], fg[13:11]}`（即 r5<<3 | r5>>2，5→8 bit 位复制）
- G：`fg_g8 = {fg[10:5], fg[8:5]}`（6→8 bit：左移 2 补高 2 位）
- B：`fg_b8 = {fg[4:0], fg[2:0]}`

**位宽表（写 RTL 前先定死，防截断/溢出）**：

| 量 | 位宽 | 值域 | 依据 |
| --- | --- | --- | --- |
| fg_ch8 / bg_ch8 | 8 | 0~255 | 通道展开 |
| α / (255−α) | 8 | 0~255 | α_inv = 8'hFF − α（= ~α） |
| 乘积 fg×α | 16 | ≤ 65025 | 8×8 → 16bit 完整积 |
| 两积之和 | **18** | ≤ 130050 | 16bit+16bit 会溢出（130050>65535）→ 用 18bit 寄存器 |
| (+127) 后 >>8 | 8 | 0~255 | 取和[15:8]（低 8 位是舍入余数） |
| 回填 | 5/6/5 | — | R=sum[15:11]… 注意是 sum 右移 8 后的高 5/6/5 位 |

> 注记（答辩可讲）：因为 255≠256，`α=255` 时结果可能比 fg 小 1 LSB（如 fg=200 →
> 199）。8bit 域误差 ~0.4%，进 5bit 通道后不可见；**与软件/模拟器用同一公式即保证
> 逐位一致**，不引入二次误差。不要自作聪明改用 256 分母——那会和金标准对不上。

### 7.2 硬件乘法器的三种写法（由易到难，推荐 1 为主）

**写法 1：RTL 用 `*`，交给综合推断（推荐起点）**
Efinity 综合对 `a*b`、`a*b+c`、累加模式自动推断 DSP 块。Ti60 的 DSP（EFX_DSP48）单块
Normal 模式支持 **19×18 无/有符号乘法 + 48bit 加减**；像素 8×8 乘法可两两打包进
Dual 模式（一块做 11×10 和 8×8 两个乘法）。只需：
- 所有操作数声明为 **无符号**（RGB/α 非负，别误用 signed，符号扩展会把结果算错）；
- 乘积寄存器位宽 = 两操作数位宽之和（不截断）；
- 乘法器输入输出两侧放寄存器（第 7.3 流水线天然满足）——工具就能把寄存器
  吸进 DSP 的 A/B/P 寄存器，时序与功耗都最优。

**写法 2：属性强制/禁止**
若某处没被推断（报告里 DSP 用量为 0）或想禁止 DSP（面积优先），用 Efinity 综合属性：
```verilog
(* syn_use_dsp = "yes" *)  wire [15:0] p;
assign p = a8 * b8;
```
（属性名与取值以你安装的《Efinity Synthesis User Guide》为准——本地路径
`C:\Efinity\2026.1\doc\`，搜 "syn_use_dsp"；在线版 [Efinity Synthesis User Guide](https://www.efinixinc.com/docs/efinity-synthesis-v3.9.pdf)。）

**写法 3：直接例化原语（最终手段/最高控制）**
Ti60 DSP 原语 `EFX_DSP48`（A[18:0]×B[17:0] ± C[17:0]，O[47:0]，CE/RST 寄存、可级联），
Normal 模式即可覆盖 8×8 两两相加需求；像素三通道混合共 6 个乘法 ≈ **3 块 DSP48
（Dual 模式每块两个乘法）**，对比 Ti60 的 160 块 DSP 余量巨大。
原语时序细节见 Efinix 官方 [Designing with Efinix FPGA DSP Blocks](https://www.efinixinc.com/blog/blog-2026-dsp.html) 与本地
《Quantum Titanium Primitives User Guide》。
> **建议**：先写写法 1，综合后看报告（工程 outflow 里 `*.dsp_control_sets.csv` 会列出
> DSP 使用；`*.map.rpt` 报资源）。推断失败或要省面积再落写法 2/3。别一上来手搓原语。

### 7.3 Alpha 像素流水线（三段，1 px/clk 吞吐）

```
      s0(输入)          s1(乘法, DSP)          s2(求和)            s3(输出)
fg16 ─▶ 拆通道/展开 ─▶ fg_r8,bg_r8,α,α_inv  6 个 16bit 积 ─▶ 3 路 18bit 和(+127) ─▶ >>8 回填
bg16 ─▶ (寄存器)   ─▶ ×───────────────▶  (乘法器输出寄存器)  (加法树/一拍)    ─▶ 打包 RGB565
α8  ─▶             ─▶ 每个 DSP 乘法 2 拍内部完成
```

```verilog
// pixel_path.v 中的 ALPHA 数据通路（Verilog，可综合）
// s0：锁存输入（alpha_inv = ~alpha）
always @(posedge clk) begin
    if (px_valid) begin
        fg_r8 <= {fg_px[15:11], fg_px[13:11]};   // 5→8 位复制
        fg_g8 <= {fg_px[10:5],  fg_px[8:5]};     // 6→8
        fg_b8 <= {fg_px[4:0],   fg_px[2:0]};
        bg_r8 <= {bg_px[15:11], bg_px[13:11]};
        bg_g8 <= {bg_px[10:5],  bg_px[8:5]};
        bg_b8 <= {bg_px[4:0],   bg_px[2:0]};
        a_inv <= 8'hFF - alpha[7:0];             // = ~alpha
        a     <= alpha[7:0];
    end
end

// s1：乘法——直接写 `*`，工具推断 EFX_DSP48（输入/输出都有寄存器，正好被吸收）
wire [15:0] p_fg_r = fg_r8 * a;     wire [15:0] p_bg_r = bg_r8 * a_inv;
wire [15:0] p_fg_g = fg_g8 * a;     wire [15:0] p_bg_g = bg_g8 * a_inv;
wire [15:0] p_fg_b = fg_b8 * a;     wire [15:0] p_bg_b = bg_b8 * a_inv;

// s2：加法 + 舍入（18bit 防溢出），再打一拍对齐输出
always @(posedge clk) begin
    sum_r <= p_fg_r + p_bg_r + 16'd127;          // 130177 < 2^18，够
    sum_g <= p_fg_g + p_bg_g + 16'd127;
    sum_b <= p_fg_b + p_bg_b + 16'd127;
end

// s3：>>8 后打包回 RGB565（取右移 8 位后的 5/6/5 位）
assign out_px = {sum_r[15:11], sum_g[15:10], sum_b[15:11]};
```

> 注意：`p_fg_r = fg_r8 * a` 用 wire 连续赋值时，若综合在组合路径上推断 DSP 失败
> 会退化为 LUT 乘法器（8×8 ≈ 数十 LUT，可接受）。要确保走 DSP，把乘法输出寄存一拍
> （`always @(posedge clk) p_reg <= fg_r8 * a;`），让综合见到"寄存器-乘法-寄存器"
> 结构，推断命中率最高。上板后以 `*.dsp_control_sets.csv` 实际报告为准。

### 7.4 与金标准比对（防公式/位宽错误）

- 单元 TB：给固定 fg/bg/α 组合（含 α=0、α=255、fg=bg 等边界）→ 与
  `simulator/sim_model.py` 同函数逐像素比对（模拟器已有 13 项像素级断言可扩展）；
- 混合 op 只占 DSP 通路的一条旁路：非 ALPHA 指令必须**旁路掉乘法器**（输出直通），
  否则非混合像素也会吃 DSP 逻辑与功耗。

---

## 8. 扫描输出控制器（scanout_top，显示通路）

### 8.1 时序参数（960×540@60，cvt modeline）

| 段 | 水平 | 垂直 |
| --- | --- | --- |
| 有效 | 960 | 540 |
| 前肩 | 48 | 3 |
| 同步 | 32 | 5 |
| 后肩 | 80 | 8 |
| 合计 | 1120 | 556 |

像素时钟 **37.36MHz**（37.3632M ÷ (1120×556) ≈ 60.0Hz，极性 +HSYNC/−VSYNC）。
vga_timing.v 用参数化常量（H_ACTIVE/H_FP/H_SYNC/H_BP、V_ACTIVE/V_FP/V_SYNC/V_BP），
便于以后一键换 1080p（1920: 前肩 88/同步 44/后肩 148 → 2200；1080: 4/5/36 → 1125，148.5MHz）。

### 8.2 结构与流控

```
core_clk 域                    pixel_clk 域
AXI 读行 N（突发, 每行1920B=120拍@16B）
      │ 行FIFO(异步, ≥2行)                     vga_timing(h/v计数器)
      ▼ 写侧(填行)          读侧(像素节奏取)──▶ DE有效时出像素
   row_prefetch FSM        ┌───────────────────┐
   （提前 1~2 行预取）       │  out = fb[r][c]  │──▶ RGB565→888→HDMI TX
                           └───────────────────┘
```

- **预取策略**：显示到第 N 行前，预先向 AXI 发起第 N+1（N+2）行的突发读，填进行 FIFO；
  行 FIFO 深度 ≥ 2 行（16bit×2048；一行 960 entries，两行 1920 entries 放得下），
  行切换时读侧不断流（花屏 = 行 FIFO 下溢，最常见 bug）。
- **FB 交换**：`SCANOUT_FB_ADDR` 是 core 域寄存器，CPU 在 VSYNC 中断里改写；RTL 只保证
  "当前行突发发起时采样一次 FB_ADDR"，行中途不重采样 → 无撕裂。
- **VSYNC.LATCH**：每个 vsync 脉冲把 SCANOUT_VSYNC[0] 置 1，写 1 清除（W1C），供 CPU
  轮询/中断判断帧边界（`fb_swap()` 依赖它，别改语义）。
- 行距 16B 对齐（FB stride=1920=120×16 ✓），每行正好 120 拍对齐突发、无跨行碎块。

---

## 9. 验证与测试计划（RTL 仿真先行，别直接上板）

| 层次 | TB | 测什么 |
| --- | --- | --- |
| L1 单元 | `tb_blt_regs` | AXI-Lite 读写、W1C、GO/DONE/ERR 位语义、FIFO 满反压 |
| L1 单元 | `tb_cmd_fifo` | 8 字成条、深度、半满/空标志 |
| L1 单元 | `tb_pixel_path` | 4 种 op 逐像素输出，ALPHA 对拍金标准公式（α=0/255/127、边界 fg/bg） |
| L2 集成 | `tb_blt_top` | 自写 AXI BFM + 伪 DDR（行为 RAM 从机，128bit，模拟延迟/限突发长度）→ 下发 COPY/FILL 指令，DDR 内容断言 |
| L2 集成 | `tb_engine_align` | **非对齐宽度/偏移**（wstrb 掩码逐字节断言：矩形外像素一个都不许变）、多行 stride、跨 4KB、行尾 padding 不写 |
| L2 集成 | `tb_alpha_row` | ALPHA 三腿事务（src/bg 读 + dst 写）、B 响应顺序 |
| L3 系统 | `tb_scanout` | 时序 1120×556、行 FIFO 下溢注入、FB 交换无撕裂 |
| L4 上板 | 冒烟序列 | ① CPU 写 FB→扫描显示 ② blt_fill 全屏 ③ COPY 移动方块 ④ KEY 精灵 ⑤ ALPHA 光晕 ⑥ 压测 |

典型用例清单：COPY 1×1 / 宽=8px+1（非对齐）/ 整行 1920B；FILL 全屏（960×540）；
KEY 整行透明（应省写突发）；ALPHA α=255 输出≈fg±1、α=0 输出≈bg±1；FIFO 满时 CPU
继续推 300 条指令不死锁；GO=0 时指令静默排队。

---

## 10. 里程碑（衔接"当前进度 + 分阶段路线图"）

> 现状：文档 6 份 + `software/` 驱动与双 Demo + `simulator/` 行为模型（13 项断言通过）
> 已交付，**RTL 尚未开工**。以下把 RTL 工作拆成 6 个可验收里程碑，与路线图 P2~P5 对齐。

| 里程碑 | 内容 | 交付/验收 | 对应路线图 |
| --- | --- | --- | --- |
| **M0** | 建 `rtl/` 骨架：blt_top、blt_regs_axi_lite、cmd_fifo、L1 TB | AXI-Lite 读写/DONE/GO 仿真通过；综合 0 错误 | P2 前置 |
| **M1** | blt_engine_fsm + addr_gen（先对齐场景）+ axi 主机；**COPY/FILL 单条指令** | L2 集成 TB：DDR 内容断言通过（先用 32/64bit 小数据口仿真） | P2 |
| **M2** | 段式突发（任意 x 偏移 WSTRB 掩码）、多行 stride、反压、B 响应 | L2 对齐用例全过；带宽计数可看 | P2/P3 |
| **M3** | pixel_path 加入 KEY + ALPHA；DSP 推断检查（`*` → dsp_control_sets.csv 确认用量） | L2 alpha 用例与金标准逐位一致；资源报告 DSP≤12 | P4 |
| **M4** | scanout_top + vga_timing（960×540@60 参数）+ 行 FIFO；与 blt_top 一起接 128bit 互联 | 上板：DDR 回环→CPU 写 FB 显示→fill/copy 移动方块 | P1/P3 补课（若 DDR 通路已跑通则直接进入） |
| **M5** | 双 Demo（demo_compare/demo_game）上板联调、压测数据、文档收尾 | 软件 vs 硬件 FPS 表、MAX@60 数据；答辩材料 | P3/P5 |

> 建议节奏：M0+M1 与 DDR 通路并行（DDR 由 P1 按官方 demo 推进）；M3 的 ALPHA 公式
> 先在 L1 用金标准比对锁定，再进 M4 上板，避免"公式错 + 上板环境错"叠加难排。

---

## 11. 上板前检查清单（按踩坑概率排序）

1. `blt_regs.h` 的 DDR_BASE/BLT_BASE/SCANOUT_BASE 用**实际生成 soc.h** 的值（别用 0x8000_0000 占位）；
2. **缓存一致性**：CPU 直写 FB/精灵区后要 fence/清 D$（Sapphire D$ 4KB 直写回策略需确认），
   否则扫描输出/引擎直读 DDR 看到旧数据（模拟器无缓存模型，暴露不了这个）；
3. sdc 约束：core/pixel(37.36MHz)/ddr 时钟、复位释放、HDMI IO（参照 03/08 demo 的 .sdc）；
4. 跨时钟域只在行 FIFO；引擎内全部单时钟；
5. AXI 主机 ARLEN ≤ DDR 硬核从口上限（查 IP 手册），互联 slave 基址窗口配对；
6. WSTRB 掩码逐字节仿真断言过（最隐蔽的污染源）；
7. ALPHA 公式与金标准一致（含 +127 与 255−α，别"优化"成 256−α）；
8. 引擎 128bit 主机口上板前先在 L2 用同宽度伪 DDR 跑通；
9. FIFO 深度/半满标志与 FSM 反压联调（写通道退让、读通道停发 AR）；
10. 像素时钟 37.36MHz 若 PLL 只能就近取整（如 37.5/37.125MHz），同步把 1120×556 微调使
    刷新率落在 59.5~60.5Hz 即可（显示器容差内），并在文档记录实际 M/N。

---

## 12. 参考资料

- 本仓库：《赛题二_方案设计与原理讲解.md》第 3/5 节、《DDR3内存分配分析.md》、
  `software/blt_regs.h`、`simulator/sim_model.py`
- AXI：ARM [AMBA AXI4 协议规范](https://developer.arm.com/documentation/ihi0022/)（读通道/写通道/响应章节精读两遍）
- DSP：Efinix 官方 [Designing with Efinix FPGA DSP Blocks](https://www.efinixinc.com/blog/blog-2026-dsp.html)
  （EFX_DSP48 架构与模式）；[Efinity Synthesis User Guide](https://www.efinixinc.com/docs/efinity-synthesis-v3.9.pdf)
  （`syn_use_dsp` 等属性，本地 `C:\Efinity\2026.1\doc\` 有同版本文档）
- 时序：960×540@60 采用业界 cvt modeline（37.36MHz / 1120×556，多款显示器实测可锁，
  如 [Linux Mint 论坛记录](https://forums.linuxmint.com/viewtopic.php?t=437514)）；640×480 的 DMT 参数见 tinyvga 对照表
- 工具报告自查：工程 outflow 目录 `*.dsp_control_sets.csv`（DSP 使用）、`*.map.rpt`（LUT/FF/BRAM）
