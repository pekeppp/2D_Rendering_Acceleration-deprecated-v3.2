# firmware —— 固件留档

## GameDemo（赛题二 · 高阶挑战 3：高负载互动弹幕游戏，**输入走串口、板卡按键一个都不用**）

| 文件 | 大小 | SHA256(前12) | 内容 | **需要哪种位流** |
|---|---|---|---|---|
| `v3.2/GameDemo_v3.2_soc.hex` | 11,090,862 B | `0A11C35ADA23` | **位流 + 应用合一镜像**（3,696,954 B 原始数据），Efinity Programmer 选它、SPI Active，烧完**断电重上电** | v3.2（自带位流） |
| `GameDemo_v3.2.hex` | 75,815 B | `D9A7D4B1F4F9` | 应用固件（IDE 单独烧这个） | v3.2 最好；**旧位流也能跑**（ADD 档自动降级成 Color Key，HUD 的 `OP=` 会如实显示 KEY） |
| `GameDemo_v3.2.bin` | 26,938 B | `43856198787F` | 同上，裸二进制（给 `tools/make_soc_image.ps1` 用） | 同上 |

- 源码：`ARC_2DRA/par/ddr_demo_ti60/embedded_sw/soc/software/standalone/GameDemo/`（`src/GameDemo.c` 1886 行）。
- 上位机：`tools/game_console.html`（基础版）+ `tools/game_console1.html`（**增强版：带敌弹 FILL/ALPHA/ADD/KEY 显示模式切换**）。
- 一键流水线：`powershell -ExecutionPolicy Bypass -File tools\build_gamedemo.ps1`
  （编译 → 主机全固件仿真自检 → 上位机协议自检 → 合一镜像）。
- 设计说明 / 协议 / 上板验收判据：`doc/GameDemo_高负载互动弹幕游戏.md`。
- 自检记录：`doc/logs/host_selfcheck_GameDemo.txt`（**74 项 0 失败**）、
  `doc/logs/game_console_selftest.txt`（基础版 **34 项** + 增强版 **53 项**，均 0 失败）。
- 编译占用：`ram 98,816 B / 1 MB（9.42%）`。
- 状态：**基础版已上板跑通**；**增强版（敌弹显示模式）待上板验证**（见设计说明 §11）。

## 当前两版应用固件（FinalDemo）

| 文件 | 大小 | SHA256(前12) | 内容 | **需要哪种位流** |
|---|---|---|---|---|
| FinalDemo_allon.hex | 39786 B | 70CF7FF1F387 | 换页 + **三缓冲** + **预清屏引擎** + 中断节奏 | **必须是新位流**（含 FB_SEL[1:0]、CLR_* 0x2C~0x48、IRQ bit1）|
| FinalDemo_default.hex | 37610 B | 866401C1436F | 换页 + 双缓冲（等价 V2.0 行为）| 新旧位流都能用（只写 FB_SEL bit0）|

源码开关在 FinalDemo.c：FB_FLIP_PUBLISH=1 / FB_TRIPLE_BUFFER=1 / FB_IRQ_PACING=1（当前默认=全开）。
改开关后必须 Clean 再 Build（make 不跟踪编译选项变化）。各工程 build\<名>.hex 才是 IDE 直接烧的那个。

## 早期实验固件（bin 留档）

| bin | 来源工程（前缀 ARC_2DRA/par/ddr_demo_ti60/embedded_sw/soc/software/standalone/）|
|---|---|
| FinalDemo.bin | FinalDemo（早期版本）|
| comptest2.bin | comptest2 |
| comptest.bin | comptest |
| fulltest.bin | fulltest |
| FBtest.bin | FBtest |

过时固件（加三缓冲/中断开关之前的构建）已移到 backup\stale_firmware\。
