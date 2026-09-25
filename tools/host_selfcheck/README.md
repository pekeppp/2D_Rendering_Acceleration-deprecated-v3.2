# AdDemo 主机自检（不依赖板卡、不依赖串口）

把 `AdDemo.c` 里带 `==== NAME_BEGIN/END ====` 标记的**源码段原样摘出来**，和一份手写期望值表
（`check.c`）一起在 PC 上编译运行。**改 AdDemo.c 之后必须先跑这个**，再谈上板——它挡住的是
"上板才知道错"的那一类：定点算式、寄存器字段极性、寻址跨度、时间基准单位。

## 跑法

```powershell
# 1) 摘段（段名列表在脚本里，必须与 AdDemo.c 的标记一一对应）
pwsh -File tools/host_selfcheck/extract.ps1
#    被执行策略挡住时： powershell -ExecutionPolicy Bypass -File tools\host_selfcheck\extract.ps1

# 2) 编译 + 运行
gcc -O1 -o check.exe tools/host_selfcheck/check.c
./check.exe
```

最后一行必须是 `===== AdDemo host self-check: N passed / 0 failed =====`，
并把输出追加到 `doc/logs/host_selfcheck_AdDemo.txt`。

## 分组

| 组 | 覆盖 |
| --- | --- |
| A/B | 属性字编码 + 默认字（`0x0000_3FC0`）逐位展开 |
| C | 已知绘制/属性-命令配对 |
| D | LUT 表格数学（`lut_chan` / `lut_addr` / 写 bank 极性的 4 步发布） |
| E | 图集烘焙：RGB565 圆盘 + ARGB4444 辉光（3 种尺寸） |
| F | 场景边界：3 尺寸 × 4000 步不出界 |
| G | 信息条宽度（最坏串不越界、右侧标签不重叠） |
| H | LUT 4 步发布 + 极性标定 |
| I | 信息条/HUD 永不被裁（计划规则 + 下发守卫 + 回读） |
| J | 逐条命令的局部坐标平移（宽条 + 精灵位置） |
| K | 有界等待 / `ST_CLIP` 超时恢复路径（死了的引擎模型） |
| L | **字形图集寻址回读** + **fade/flash 时间基准**（2026-09-16 两处上板 bug 的守门人） |

## L 组为什么存在（两次教训）

1. `FONT_STRIDE` 同时被当成"源行跨度（16B）"和"字形间距"用，而 `build_atlas()` 每个字形
   写 8 行（实占 128B）⇒ 单元 `idx` 读到的是 `idx..idx+7` 这 8 个字形的**第 0 行**，
   信息条看起来就是一排排横杠。L1 用"写入布局 → 按 `blt_key(base, FONT_ROW_BYTES)` 回读"
   逐字形逐行比对；L2/L3 钉住间距关系与图集区间。
2. `FADE_PERIOD_MS` / `FLASH_MS` 是**毫秒**，却被直接当 CLINT 拍数用（100MHz ⇒ 1ms=100000 拍）
   ⇒ 3.6s 的淡入淡出变成 36µs、220ms 的白闪变成 2.2µs（每 30µs 重新点火）⇒ "场景 2 不淡、
   场景 4 惨白"。现在换算只允许在 `fx_elapsed_ms()` 里做，L4/L5/L6/L7 直接测这三个纯函数
   和"效果到底持续多少帧"。

> 段名列表漏一项（例如 `CONTENT_RECT`）会让 `check.c` 以 `undeclared` 编译失败——
> 这是**故意的**：宁可硬失败，也不要静默少测一段。
