# GameDemo 主机自检 —— 把**真固件**放在假引擎上跑（QEMU riscv32）

与 `tools/host_selfcheck`（AdDemo 那套「抽标记段 + 手写期望值」）不同，这里**不抽段**：
`sim/sim_main.c` 把 `src/GameDemo.c` **原样 `#include` 进来**，只覆盖三个**基址**
（`DDR_BASE` / `BLT_BASE` / `UART_TERM`，见 `GameDemo.c` 里那三个 `#ifndef` 的注释），
用一块 RAM 假装是 DDR 和引擎寄存器，然后**在 QEMU 上把真主循环跑起来**。

于是主循环、三缓冲 FLIP 轮转、清屏引擎互斥、绘制清单构建（含裁剪）、
游戏逻辑、串口协议 —— **全部真的被执行**，每帧还能对绘制清单做不变量检查。

## 跑法

```powershell
pwsh -File tools\host_selfcheck_game\build_and_run.ps1
#    被执行策略挡住时： powershell -ExecutionPolicy Bypass -File tools\host_selfcheck_game\build_and_run.ps1
```

需要 Efinity RISC-V IDE 自带的两个东西（路径写在脚本顶部）：

| 用途 | 路径 |
| --- | --- |
| 交叉编译 | `C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin\riscv-none-elf-gcc.exe` |
| 运行 | `C:\Efinity\efinity-riscv-ide-2026.1\qemu\qemu-system-riscv32.exe` |

输出落到 `doc/logs/host_selfcheck_GameDemo.txt`，末行必须是：

```
===== GameDemo host self-check: NN passed / 0 failed =====
```

## 假外设是怎么搭的

| 硬件 | 仿真里是什么 | 怎么做到的 |
| --- | --- | --- |
| DDR（帧缓冲/图集/屏障区） | `0x81000000` 起的一块裸 RAM | `-DDDR_BASE=0x81000000UL`，其余地址全部由它派生 ⇒ 相对布局一位不变 |
| 引擎寄存器组 | `0x82000000` 起的一块裸 RAM | `-DBLT_BASE=0x82000000UL`，`sim_tick()` 负责刷新只读寄存器 |
| UART | `0x82100000` 起的一块裸 RAM | `-DUART_TERM=0x82100000UL`；RX 恒空（MMIO 读没法挂副作用） |
| 时钟 | `clint_getTimeLow()` 每次调用推进 4096 拍 | 它就是整个仿真的**心跳**（`sim_tick()`） |
| 场边界 | 每 1,666,667 拍把 `FB_STAT = FB_SEL` | ⇒ FLIP 的"确认条件"是**真被满足**的，帧率口径不受影响 |
| 引擎完成 | `STATUS` 恒为 `DONE\|FIFO_EMPTY`，`CMD_FIFO_COUNT` 恒 0 | 命令发出去就被"消费" |
| 清屏引擎 | 每 7 个场强制报一次"不干净" | 把"命令式整片重铺"那条退化路径也真的跑到 |
| 退出 | 跑满 600 个上屏帧后写 SiFive test 设备 | QEMU 自行退出，不靠超时 |

`sim/sim_main.c` 里为假 BSP 只实现了 `bsp_init` / `bsp_printf` / `clint_getTimeLow` 三个函数；
`bsp_printf` 故意**只认 `%c %s %d %X %x`**（与 BSP 的 mini print.h 同一份限制）。

## 四组判据

| 组 | 覆盖 | 条数 |
| --- | --- | --- |
| A | 属性字编解码、定点混合手算期望值、**帧预算模型复现板测点**（16×16 FILL/KEY/ALPHA = 514/719/856；64×64 ALPHA = 6743） | 10 |
| B | 串口协议：按键包定向向量 + **2058 条穷举**（只有 `@HH\n` 能返回 KP_OK）+ 命令字节不被吞 + `=N` 语义 + `uart_poll_char` 只看 `status[31:24]` | 19 |
| C | 游戏逻辑：`ent_clamp` 只反越界那一轴、圆-圆碰撞边界、弹池容量与快路径、`isqrt32`、sin/cos 表、**1800 帧无渲染长跑**、自动爬坡收敛 | 15 |
| D | **主循环仿真 600 帧**：帧数跑满 / 每帧矩形全在界内（裁剪守门人）/ 精灵号合法 / 清单不溢出 / 走过退化重铺路径 / 按键真的驱动自机 / N 真的被抬高 / **同屏元素 > 600** / 帧率贴住 60 / 无 `blt_recover` / 无翻转超时 | 18 |

合计 **62 项**（`0 failed`）。

## ★ 三条口径差别（**如实记录，不要当成通过**）

1. **假引擎瞬时完成** ⇒ 仿真里的帧率恒为 60，**不能**用来测吞吐 / 极限 N。
   极限 N 只能上板用固件自带的 `g` 自动爬坡量。
2. **帧边界中断在仿真里是电平恒高**（没有 W1C 的读副作用可模仿）⇒
   FLIP 的确认仍被 `FB_STAT` 卡在真正的场边界上（帧率口径不受影响），
   但 `EV flip timeout` 那条有界超时分支在仿真里**走不到**。
3. **UART 的 RX 在仿真里恒为空**（MMIO 读没法挂副作用）⇒ `serial_drain()` 的
   "无数据"路径被走到；**解析本身**由 B 组把 `kp_feed` / `nline_feed` 直接喂满，
   再由 C/D 组验证解析出来的按键状态真的驱动了自机与命令。

## 为什么需要 `#ifndef` 那三个基址

`GameDemo.c` 里只有 `DDR_BASE` / `BLT_BASE` / `UART_TERM` 三个**基址宏**带 `#ifndef` 守卫，
其余地址（`FB_BASE`、`ATLAS_BASE`、`FLUSH_SCRATCH`、所有寄存器偏移…）全部由它们派生。
板级构建一个都不给 ⇒ 用的就是默认值，与 `FinalDemo`/`AdDemo` 逐位一致；
仿真只搬这三个基址 ⇒ DDR 内部的相对布局一位不变。

## 编译参数里两个"看着多余但必须有"的开关

| 开关 | 为什么 |
| --- | --- |
| `-Wl,--no-relax` | 不关的话链接器会把 `lui/addi` 松弛成 gp 相对寻址，而自制链接脚本里 `__global_pointer$` 与 `.srodata` 距离超范围 ⇒ `relocation truncated to fit: R_RISCV_GPREL_I` |
| `-msmall-data-limit=0` | 同理，避免 gcc 主动生成 gp 相对访问（仿真不需要链接期优化） |
