# Elitestek IDE 2026.1（Efinity 26.1.132 Elitestek 版）自带 IP 核复用分析

> 适用赛题：【赛题二】基于 RISC-V 与 FPGA 异构架构的 2D 图形渲染加速引擎（Ti60F225I3 板卡）
> 目标：盘点 IDE 自带 IP 核 → 分析哪些可直接复用 → 给出具体配置方法。

---

## 1. 工具链与 IP 位置

| 项 | 值 |
| --- | --- |
| 主软件 | Efinity Software - **Elitestek Edition 2026.1**（v26.1.132），安装于 `C:\Efinity\2026.1\` |
| RISC-V 软件 | Efinity RISC-V Embedded Software IDE 2026.1（v26.1.0.7，Eclipse + Ashling RiscFree），`C:\Efinity\efinity-riscv-ide-2026.1\` |
| IP 核目录 | `C:\Efinity\2026.1\ipm\ip\`（38 个 IP，每个含 RTL 源、IPM 定义、**HTML 用户指南**、仿真 testbench、参考工程） |
| 权威支持表 | `C:\Efinity\2026.1\doc\topics\ipmgr-supported-ip-byfamily.html`（按 Trion/Titanium/Topaz 列出各 IP 支持情况） |

每个 IP 的用户指南在 `ipm\ip\<ip名>\ipm\doc\topics\*.html`，可直接用浏览器打开（或 IDE 内 Help → IP Help）。

---

## 2. 全量 IP 清单（38 个，版本号取自 ip_component.xml）

| 分类 | IP | 版本 | Ti60F225 支持 |
| --- | --- | --- | --- |
| AXI 基础设施 | efx_axi_data_fifo | 5.3 | ✅ |
| | efx_axi_interconnect | 5.6 | ✅ |
| | efx_axi_stream_switch | 5.4 | ✅ |
| 算术 | efx_cordic | 5.1 | ✅ |
| | efx_divider / efx_divider_2 | 5.3 | ✅ |
| | efx_integer_square_root | — | ✅ |
| 桥接/适配 | efx_apb_interconnect | 1.0 | ✅ |
| | efx_apb3_2_axi4_lite | 5.2 | ✅ |
| | efx_data_pipeline | 6.4 | ✅ |
| | efx_dma | 6.4.2 | ✅ |
| | efx_pcie_dma | — | ❌（Ti85+） |
| | efx_pma_64b66b_gb | — | ❌（Ti85+） |
| 以太网 | efx_tsemac（三速 MAC） | — | ✅ |
| | efx_mac10gbe / efx_usxgmii_an_37 | — | ❌（Ti85+） |
| 基础 | efx_pll_cfg（动态重配置） | 1.3 | ❌（Ti85+） |
| | efx_pll_autoreset（Trion PLL 复位，Ti 可用） | 1.1 | ✅ |
| 存储 | efx_bram | 6.4 | ✅（含 Ti60F225 例程） |
| | efx_fifo_2 | 8.1 | ✅ |
| 存储控制器 | efx_flash_controller（ASMI SPI Flash） | 5.4 | ✅（含 Ti60F225 例程） |
| | **DDR 硬核控制器（芯片内建）** + efx_ddr_reset_controller | 5.2 | ✅（Titanium All） |
| | efx_ddr3_soft_controller | 5.16 | ✅（含 Ti60F225_engboard 例程） |
| | efx_hyper_ram_2 | 6.13 | ✅（本板无 HyperRAM，用不上） |
| | efx_sdram_controller（SDR） | 5.6 | ❌（Trion 用） |
| | efx_sd_host_controller | — | ✅（本板无 SD 卡座，用不上） |
| MIPI | efx_csi2（CSI-2 RX/TX、2.5G RX/TX） | — | ✅ |
| | efx_dsi（DSI RX/TX、2.5G） | — | ✅ |
| | efx_dphy（D-PHY RX/TX/Bidir） | — | ✅ |
| 处理器与外设 | **efx_soc（Sapphire RV32 SoC）** | — | ✅ |
| | efx_soc_rv64（RV64 SoC） | 1.0.0 | ✅ |
| | efx_hard_soc（高性能 SoC） | 1.23.0 | ❌（Ti165/Ti240/Ti375） |
| 串行接口 | efx_i2c_controller | 5.4 | ✅（含 Ti60F225 例程） |
| | efx_uart | 5.3 | ✅（含 Ti60F225 例程） |
| | efx_jtag | 1.1 | ✅ |
| | efx_jtag2spi_flash | — | ✅ |

> ⚠️ **注意**：**HDMI TX/RX IP 不在 2026.1 自带目录里**（板卡 HDMI 是通过高速 IO 实现的，官方 demo `03_hdmi_tx_demo` 自带完整 RTL，直接复用它，或用板卡资料里的 HDMI IP 包）。

---

## 3. 三个关键结论（先看这个）

1. **Ti60F225 的 DDR3 走"硬核控制器"**：芯片内建 DDR PHY + 控制器（不可旁路），配置在 **Interface Designer**（不是 IPM），对外提供 AXI 接口；复位/初始化用 `efx_ddr_reset_controller`（上电自动初始化）。`efx_ddr3_soft_controller` 也可用于 Ti60（有 `Ti60F225_engboard` 参考工程），但硬核更省资源、更稳，**首选硬核**。
2. **RISC-V 直接用 `efx_soc`（Sapphire RV32 SoC）**：自带 CPU 核、AXI 互联、UART/SPI/I2C/GPIO/定时器、PLIC 中断、软件 BSP、Eclipse IDE 与 OpenOCD 调试全链条——这正是我此前方案文档里推荐的路线，IP 目录证实它完整可用。
3. **本项目真正需要自己写的只有三块**：① BitBlt 引擎（指令 FIFO + 状态机 + 像素通路）；② 扫描输出控制器（960×540 时序 + 行 FIFO + AXI 读）；③ 精灵/Alpha/键控像素逻辑。**其余全部有现成 IP**：CPU、DDR、总线互联、FIFO/BRAM、UART、定时器、中断、Flash、甚至可选 DMA。

---

## 4. 复用映射表（子系统 → IP → 赛题对应）

| 子系统 | 复用 IP / 资源 | 配置要点 | 对应赛题要求 |
| --- | --- | --- | --- |
| CPU 子系统 | **efx_soc**（Sapphire RV32，VexRiscv 核） | 1 核 100MHz；I$/D$ 4KB；外部存储接口开 AXI4 全双工；APB slave 0 挂引擎寄存器 | RISC-V 端跑逻辑/驱动 |
| 内存 | Ti60 **硬核 DDR3** + efx_ddr_reset_controller | Interface Designer 建 DDR block（16bit、800MT/s）；FREQ=100 | 帧缓冲/精灵图/程序区 |
| 总线互联 | **efx_axi_interconnect** | 3 主（SoC/引擎/扫描输出）→ 1 从（DDR 控制器 AXI 口）；AXI4、128bit、优先级仲裁 | 加速器通过总线访问内存 |
| 寄存器口 | efx_apb3_2_axi4_lite（可选）/ SoC APB slave 0 | 引擎寄存器挂 SoC 的 APB slave 0 窗口（默认 0xf8100000） | 驱动配置寄存器 |
| 指令 FIFO | **efx_fifo_2**（同域） | 深度 256、32bit、标准模式 | 指令队列批量下发 |
| 行 FIFO / 源目的 FIFO | **efx_fifo_2**（异步） | 深度≥2 行（960×2B×2≈3.75KB，深度 2048×16bit）、16bit、FWFT | 突发解耦、跨时钟域 |
| 精灵缓存/ROM | **efx_bram** | SDP/TDP、初始化文件（.mem/.hex 放精灵图） | 精灵图存储 |
| 调试串口 | SoC 内置 **UART0**（BSP 提供 uart_write/printf） | 115200，8N1 | 打印/按键调试 |
| 定时器 | SoC 内置 **User Timer 0** / CLINT | 中断号 19；`clint_uDelay` | FPS 统计时钟（sys_ms） |
| 中断 | SoC **PLIC** + User Interrupt A | 中断号 16 接 BitBlt 完成中断 | 软硬协同（指令完成中断） |
| 备选：通用搬运 | **efx_dma** | 8 通道、SG、mem-to-mem、读写硬件队列、APB3 CSR | 可评估"扫描输出取数/大块拷贝"用 DMA |
| 备选：其他 | efx_i2c（外设）、efx_flash_controller（SPI Flash 读数据）、efx_jtag、efx_cordic/divider（坐标/除法）、efx_axi_data_fifo | 按需 | 加分项（摄像头/网络等） |
| 不用 | efx_pll_cfg（Ti60 不支持动态重配）、efx_hard_soc/10G MAC/PCIe/PMA（Ti60 不支持）、efx_sdram_controller（SDR 时代）、efx_hyper_ram_2（板上是 DDR3） | — | — |

---

## 5. 关键 IP 的详细配置方法

### 5.1 efx_soc（Sapphire RV32 SoC）—— 最重要

**例化路径**：Efinity → IP Catalog → Processors and Peripherals → Sapphire Soc（与板卡文档 08 号 demo 一致）。
**生成产物**：`EfxSapphireSoc.v`（+模板）、`soc.h`（**内存映射**）、BSP（`embedded_sw\bsp\efinix\EfxSapphireSoc\`：bsp.h、soc.h、uart.h、clint.h、linker 脚本、OpenOCD 配置）。

**配置向导参数（按本项目推荐值）**：

| 页签 | 参数 | 推荐 | 说明 |
| --- | --- | --- | --- |
| SOC | Option | **Standard** | 性能最好（Lite 省面积但有功能裁剪） |
| SOC | Core Number | 1 | |
| SOC | Frequency | 100 MHz | 与板卡 demo 一致 |
| SOC | Cache | On | I$ 与 D$ 都开 |
| Cache/Memory | Cache Size | 4 KB×2（1 路） | 例程默认 |
| Cache/Memory | **External Memory Interface** | **On** | 关键：打开到 DDR 的 AXI 口 |
| Cache/Memory | AXI Interface Type | **AXI4（全双工）** | 板卡文档强调"使能双工" |
| Cache/Memory | External Memory Data Width | **128** | 带宽最好；DDR 控制器侧匹配 |
| Cache/Memory | On-Chip RAM Size | 4 KB~64 KB | 放引导代码/小数据 |
| Cache/Memory | Custom On-Chip RAM Application | Off（默认） | 用 SPI Flash bootloader 启动 |
| Debug | RISC-V Standard Debug | On | OpenOCD 断点调试 |
| 外设 | UART0 / SPI0 / I2C0 / GPIO0 | 按需开（至少 UART0+GPIO0） | 例程会自动连顶层引脚 |
| 接口 | **AXI Slave（APB slave 0/1）** | 开 1~2 个 | 挂 BitBlt 引擎寄存器与扫描控制器 |
| 中断 | **User Interrupt A** | On（ID=16） | 接引擎"完成"中断 |
| 定时器 | **User Timer 0** | On（ID=19） | FPS 时钟 |

**生成后的内存映射（示例 soc.h，以你实际生成为准）**：

| 外设 | 地址 | 备注 |
| --- | --- | --- |
| UART0 | 0xF801_0000 | bsp_putChar / uart_write |
| SPI0 / I2C0 / GPIO0 | 0xF801_4000 / 0xF801_6000 / 0xF801_5000 | |
| User Timer 0 | 0xF801_7000 | |
| PLIC | 0xF8C0_0000 | 中断号：UART=1、GPIO=12/13、**User A=16**、Timer0=19、AXI_A=30 |
| CLINT | 0xF8B0_0000 | 100MHz |
| **APB Slave 0（IO_APB_SLAVE_0）** | **0xF810_0000** | **→ 挂 BitBlt 引擎寄存器（BLT_BASE）** |
| APB Slave 1 | 0xF820_0000 | → 挂扫描输出控制器（SCANOUT_BASE） |
| On-Chip RAM | 0xF900_0000 | |

**资源占用**（官方 Ti60 例程）：约 **11,178 LUT / 9,973 FF / 82 块 BRAM / 180 MHz fmax**——只占 Ti60 62K LE 的 ~18%，给 BitBlt 引擎和扫描输出留足了资源。

**软件链**：Efinity RISC-V IDE 2026.1（自带 xPack GNU RISC-V GCC **13.4.0** + 定制 OpenOCD **0.11.0**）。BSP 提供 `bsp_putChar`、`clint_uDelay`、printf（`ENABLE_BSP_PRINTF`）。链接脚本在 `linker\default.ld`（内部 RAM 版）等，用户程序经 bootloader 从 SPI Flash 加载到 DDR 运行。

### 5.2 DDR3 —— 用硬核控制器

- **配置位置**：Interface Designer（工具菜单），不是 IPM。Ti60F225：DDR Resource 选 DDR_0、**Data Width 16**、DDR3、800 MT/s（具体行/列/组以板卡 demo 09/10 的 `.peri.xml/.sdc` 为准，demo 里 sdram_clk 为 400MHz=2.5ns）。
- **接口**：硬核控制器提供 **AXI 从口**（A/D 两路，全双工），CPU（经 SoC 外部存储接口）、BitBlt 引擎、扫描输出控制器三路主设备经 efx_axi_interconnect 接入。**不可旁路直连 PHY**。
- **复位/初始化**：`efx_ddr_reset_controller`（IPM），参数 **Clock Frequency: 100**（与 clk 匹配）；上电时 FPGA 配置期间会自动完成 DDR 初始化，一般无需手动复位。
- **备选软核**：`efx_ddr3_soft_controller`（IPM）参数：Interface=**AXI4**、Data Rate=800D/800E、DQ Width=16、DDR Frequency=400MHz、Column/Rows 按 MT41J128M16（2Gb x16：Row 14 / Col 10 / Bank 3 / Rank 1，以工具自动/板级例程为准）、Arbiter Read 优先。参考工程 `fpga\Ti60F225_engboard` 已配好器件/引脚（example_top.v + constraint.sdc）。软核占资源、时序难收敛，仅当硬核路径受阻时用。

### 5.3 efx_axi_interconnect（总线互联）

参数：Protocol=**AXI4**；Arbitration=**PRIORITY**（扫描输出给最高优先级防断流）；Number of Slave Interfaces=3（接 SoC 外部存储口、BitBlt 引擎主机、扫描输出主机）；Number of Master Interfaces=1（接 DDR 控制器 AXI 从口）；Data Width=128（与 DDR/SoC 一致）；每个 slave 的 Base Address 设为 DDR 地址窗口。

### 5.4 efx_fifo_2（FIFO）

参数：Clock Mode=**Asynchronous**（跨时钟域）或 Synchronous（同域指令 FIFO）；Depth 16~131072（指令 FIFO=256，行 FIFO=2048）；Data Bus Width 1~512bit（像素 16/32bit）；FIFO Mode=STANDARD/FWFT；可配 prog_full/almost 标志与 datacount。**用途**：指令 FIFO（同域、32bit×256）、扫描行 FIFO（异步、16bit×2048≈2 行）、引擎源/目的 FIFO（异步、16bit、1~2 个突发长）。

### 5.5 efx_bram（BRAM 包装）

参数：SP/SDP/TDP RAM、ROM；对称/非对称端口（1:16~16:1）；单/双时钟；**支持初始化文件**（把精灵图烧进 ROM）。含 Ti60F225 例程。**用途**：精灵图 ROM（用 init 文件），指令 FIFO 的存储体（配合自研指针），行缓冲。

### 5.6 efx_dma（备选加速）

参数：Memory Interface 选 AXI4 全双工；External Width 64/128；Buffer Bank Words/Width/Count 按带宽配；**Memory Read/Write Queue 打开**（硬件队列提吞吐）；Channel 0/1 开 SG 模式与 AXI4-Stream 口；CSR 接口 APB3。**在本项目的价值**：a) 扫描输出控制器可以简化为"AXI4-Stream 输出 + DMA 拉数据"；b) 大块 memcpy 场景可省去自研读状态机——但 2D 矩形搬运用自研 BitBlt 仍是正解（带 stride/处理能力），DMA 只做补充。

### 5.7 其他小 IP（一句话配置）

- `efx_apb3_2_axi4_lite`：把 SoC 的 APB 转成 AXI-Lite，适合引擎寄存器挂在 AXI 域；
- `efx_apb_interconnect`：多个 APB 外设分地址；
- `efx_axi_data_fifo`：AXI 通道上的缓冲/CDC；
- `efx_uart`：非 SoC 场景的独立串口（SoC 场景直接用内置 UART0）；
- `efx_pll_autoreset`：PLL 失锁自动复位（Ti60 可用）；
- `efx_flash_controller`：QSPI Flash 读写（GD25LQ64 8MB），可把精灵图/配置存 Flash 上电加载；
- `efx_i2c_controller`：接传感器等；
- `efx_jtag / efx_jtag2spi_flash`：调试与 Flash 烧写辅助。

---

## 6. 与已交付软件层（software/）的对接

之前的驱动/demo 代码基于"假定的地址宏"，现在有了确切锚点，按下面改 `software/blt_regs.h`：

```c
/* SoC 生成的 soc.h 里：
   IO_APB_SLAVE_0_INPUT = 0xf8100000  → 引擎寄存器
   IO_APB_SLAVE_1_INPUT = 0xf8200000  → 扫描输出寄存器       */
#define BLT_BASE        0xF8100000UL   // 或经 apb3→axi4lite 桥后的地址
#define SCANOUT_BASE    0xF8200000UL

/* 帧缓冲/精灵区：偏移相对 DDR_BASE（布局见《DDR3内存分配分析.md》；
   用户程序由 bootloader 加载进 DDR，DDR 基址以生成的 soc.h/链接脚本为准，
   官方 Ti60 demo 为 0x1000，PC 模拟暂用 0x80000000） */
#define DDR_BASE        0x80000000UL   // ← 按实际生成 soc.h 改
#define FB0_BASE        (DDR_BASE + 0x00300000UL)   // Front ★
#define FB1_BASE        (DDR_BASE + 0x00400000UL)   // Back
#define SPRITE_BASE     (DDR_BASE + 0x00100000UL)   // 精灵/图集
```

`software/sys.c` 的钩子换成 BSP 实现：

| 钩子 | BSP 实现 |
| --- | --- |
| sys_putchar / sys_getchar | `bsp_putChar(c)`（BSP 已有）或 uart 读写寄存器（0xF801_0000） |
| sys_ms | 用 `clint_uDelay`/User Timer 0（0xF801_7000）计数，或直接读 CLINT mtime（0xF8B0_0000） |
| sys_wait_irq | PLIC 开 User Interrupt A（ID 16）后 `wfi`；引擎完成中断 → `blt_irq_done_handler()` |

工程集成：把 `blt_drv.c display.c fps.c sys.c` 与 demo 加进 RISC-V IDE 工程（BSP 模板 `EfinixBSPTemplate_RV32`），链接脚本用 BSP 提供版本。

---

## 7. 风险与注意

1. **DDR 基址与 soc.h 地址以"实际生成"为准**——IP 版本/配置不同地址会变，改 blt_regs.h 前先读生成目录里的 soc.h；
2. **PLL 动态重配置（efx_pll_cfg）不支持 Ti60**（Ti85+ 才有）；时钟用 PLL 原语 + efx_pll_autoreset；
3. **硬核 DDR 不可旁路**，别想着自己写 PHY 时序；DDR 参数（行/列/组）务必与板级 demo 一致，否则初始化失败；
4. IP 用 2026.1 版本例化，避免与 IDE 版本不匹配；例程（DDR3 的 Ti60F225_engboard、SoC 的 Ti60 test 工程）是排错的第一参考；
5. SoC 例程已占 ~18% LUT / 82 块 BRAM，引擎 + 扫描输出 + 行 FIFO 预算控制在 ~15K LUT / ~40 块 BRAM 内比较稳妥（总量 62K LE / 256 块 BRAM）；
6. HDMI TX 需用板卡 demo 03 的现成 RTL（不在本 IDE IPM 目录内），别在 IPM 里找。

---

## 8. 结论

- **直接复用**：efx_soc、Ti60 硬核 DDR3 + ddr_reset_controller、efx_axi_interconnect、efx_fifo_2、efx_bram、（可选）efx_dma、SoC 内置 UART/Timer/PLIC——这 8 类覆盖了赛题基础要求 ~80% 的硬件工作；
- **必须自研**：BitBlt 引擎（含 Alpha/键控）、扫描输出控制器、游戏/驱动软件（已交付 software/）；
- **建议路线**：Phase 1 用 efx_soc 官方例程（08 号 demo 模板）跑通"CPU→DDR→AXI"通路 → Phase 1.5 用 Interface Designer 配好硬核 DDR3 → Phase 2 例化 axi_interconnect 把自研引擎/扫描输出接入 → 后续按《赛题二_方案设计与原理讲解.md》推进。
