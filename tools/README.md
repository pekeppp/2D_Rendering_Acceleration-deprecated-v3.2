# 网页版串口上位机（Web Serial）· 使用说明

`serial_console.html` 是 FPGA 2D 渲染加速器 Demo 板的**单文件串口上位机**：
不依赖任何 CDN / 外部 JS / 外部 CSS / 外部字体，断网也能用；直接调浏览器的 **Web Serial API**，
不用装任何串口助手。

---

## 0. 先看这里：三个不同的固件配三个不同的上位机

| 固件 | 上位机 | 输入方式 |
| --- | --- | --- |
| `FinalDemo`（硬件 vs 纯 CPU 同屏对比） | `serial_console.html`（本说明第 1 节往下全是它） | 单字符命令 + `=N` 行命令 |
| `AdDemo`（v3.2 主 demo：属性/scissor/LUT） | `ad_demo_console.html` | 单字符命令 |
| **`GameDemo`（高负载互动弹幕游戏）** | **`game_console.html`**（基础版）<br>**`game_console1.html`（增强版：多一个「敌弹显示模式」面板）** | **PC 键盘 → `@HH\n` 按键包**（板载按键一个都不用）+ 单字符命令 |

> `game_console1.html` 是在 `game_console.html` 基础上**新建**的副本（原文件一字未改），
> 只多了「敌弹 FILL / ALPHA / ADD / KEY」这一块：一组模式按钮（`5`/`6`/`7`/`8`、`f` 循环）、
> 记分板多一格 `OP=`（显示**实际生效**的算子档），以及协议层的一张 `BUL_MODES` 表。
> 两个页面共用同一份 Node 自检：`node tools\game_console_selftest.js`（基础版 34 项）、
> `node tools\game_console_selftest.js tools\game_console1.html`（增强版 53 项）。

### GameDemo 用 `game_console.html`（赛题二 · 高阶挑战 3）

打开方式与 `serial_console.html` 完全一样（双击，或 `http://localhost:8000/tools/game_console.html`），
浏览器要求也一样（桌面版 Chrome/Edge + 安全上下文 + 115200 8N1）。它多出来的是：

| 功能 | 说明 |
| --- | --- |
| **键盘接管** | 页面有焦点时，`W/A/S/D`（或方向键）走位、`J/空格` 开火、`K/Shift` 慢速、`L/X` 炸弹、`P/回车` 暂停 —— 全部打包成 `@HH\n` 通过串口发给板子 |
| 虚拟手柄 | 鼠标/触屏也能玩；与键盘状态**按位或**合并 |
| 记分板 | 解析固件 4Hz 的 `ST ...` 行：`FPS` / `SW`（纯 CPU 分母）/ `N` / `ON`（同屏元素）/ `SCORE` / `LEVEL` / `HP` / `BOMB` / 渲染路径 |
| 极限行 | 自动爬坡（按 `g`）找到 60FPS 极限时，弹 `LIMIT N=… fps=… ON=…`，记分板同步 |
| 命令按钮 | `1/2/3/4` 负载档、`c`/`h` 切换纯 CPU / 硬件、`g` 爬坡、`b` 星空、`p`、`r`、`d`、`?`、`n`/`-`、`=N` |
| **敌弹显示模式**（**仅增强版**） | 按 `5`/`6`/`7`/`8` 把敌机子弹的画法在 **FILL / ALPHA / ADD / KEY** 之间切换，`f` 循环；记分板多一格 `OP=` 显示**实际生效**的算子档（ADD 档在没有属性侧口时会如实显示 KEY） |

**协议**（与 `GameDemo.c` 的 `kp_feed()` 逐位对应）：

```
PC → 板   '@' + 两位十六进制 + '\n'
          bit0 上(W/↑) 1 下(S/↓) 2 左(A/←) 3 右(D/→)
          bit4 开火(J/空格) 5 慢速(K/Shift) 6 炸弹(L/X) 7 暂停(P/回车)
          任一键状态变化立刻发；另外每 100ms 补发一次心跳
板 → PC   EV ...（命令回显）/ ST ...（4Hz 记分板）/ LIMIT ...（爬坡结论）
```

固件侧有 **500ms 看门狗**：收不到包就把所有键视为松开（标签切走 / 拔线都不会让自机一直飞）。

**自检**（不需要浏览器与串口）：

```bash
node tools/game_console_selftest.js     # 34 项，抽 game_console.html 的 PROTO 段在 Node 里跑
```

固件侧的完整主机仿真自检见 `tools/host_selfcheck_game/`（62 项，QEMU + 假引擎）。
设计说明与上板验收判据：`doc/GameDemo_高负载互动弹幕游戏.md`。

### 一键流水线

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_gamedemo.ps1
# 编译固件 → 主机仿真自检 → 上位机协议自检 → 位流+应用合一镜像
```

---

## 1. 怎么打开

**方式 A：双击（最省事）**

直接双击 `tools\serial_console.html`，用 Chrome / Edge 打开即可（`file://` 属于安全上下文）。

**方式 B：本地 HTTP 服务（推荐，行为与线上一致）**

在**仓库根目录**执行：

```bash
python -m http.server 8000
```

然后浏览器访问：

```
http://localhost:8000/tools/serial_console.html
```

> 换端口就改 `8000`；换机器访问把 `localhost` 换成该机器 IP（但**非 localhost 的普通 http 页面不是安全上下文，Web Serial 会被浏览器禁用**，所以请用 localhost）。

### 浏览器要求

| 要求 | 说明 |
| --- | --- |
| 浏览器 | **桌面版 Chrome / Edge**（Web Serial 只在 Chromium 桌面版提供） |
| 安全上下文 | `file://` 直接打开，或 `localhost` / `127.0.0.1` 的本地服务 |
| 其它 | Firefox / Safari / 手机浏览器不支持；页面会显示中文提示并禁用连接按钮，不会报错 |

不支持时页面顶部会出现黄色提示条：
「当前环境不支持 Web Serial（navigator.serial 不存在）…」，此时界面仍可查看，但串口功能不可用。

---

## 2. 连接步骤

1. 用 USB 线把 Demo 板接到电脑，确认设备管理器里出现串口（CP210x / FT232 / CH340 等）。
2. 打开页面，右上角**波特率**选 `115200（默认）`。
3. 点 **连接** → 在弹出的浏览器串口列表里选中的板子串口 → 点「连接」。
4. 状态灯变绿、显示「已连接 · 波特率 115200 · 8N1」，日志里应出现开机横幅与后续 `EV ...` 行。
5. 断开：点 **断开**；直接拔线也能被识别（状态变红「错误 / 串口设备已被拔出」）。**重新插上后直接再点「连接」即可，不用刷新页面。**

### 波特率：先看这里

- 固件波特率由 **BSP 自行设定**，本工程各 demo 一致使用 **115200 8N1**，所以上位机默认就是 115200。
- **日志出现乱码（花屏字符）＝ 波特率不匹配**：把波特率改回 `115200` 重新连接；若你的 BSP 改过时钟分频，就在 9600 / 19200 / 38400 / 57600 / 115200 / 230400 里挨个试。
- 数据位/校验/停止位固定 **8N1**，页面上不提供修改（与固件一致）。

---

## 3. 命令参考

### 3.1 单字符命令（**按下立即生效，不需要回车**）

| 键 | 功能 | 按钮/发送的字符 |
| --- | --- | --- |
| `1` | 场景 FILL：不透明色块 | `1` |
| `2` | 场景 ALPHA：半透明混合 | `2` |
| `3` | 场景 KEY：color-key 精灵 | `3` |
| `s` | 渲染路径：同屏对比 SPLIT（左硬件 / 右纯 CPU） | `s` |
| `c` | 渲染路径：纯 CPU | `c` |
| `h` | 渲染路径：纯硬件加速 | `h` |
| `n` 或 `+` | N 增加 25（超出上限时固件回绕到下限） | `n` |
| `-` | N 减少 25（低于下限时固件回绕到上限） | `-` |
| `a` | 透明度 alpha 减 32 | `a` |
| `A` | 透明度 alpha 加 32 | `A` |
| `e` | 每趟整片重铺（清屏模式）开关 | `e` |
| `t` | 帧率模式（按帧推进 ⇄ 按时间推进）开关 | `t` |
| `k` | **物块尺寸**：方块与 ALPHA/KEY 图集精灵一起在 **16x16 → 32x32 → 64x64 → 16x16** 上循环（固件按新尺寸重建图集与 4x4 掩码、重新初始化场景并重铺两侧） | `k` |
| `l` | **显示列表路径开关**：DDR 描述符表（硬件取指器展开）⇄ 原来的每块一次 CPU 下发。**默认关**，**待生效**：按键回 `EV dl on/off pending`，下一个帧边界生效（回 `EV dl on` / `EV dl off`），生效后信息条出现 `L` 标记；列表模式开着时也能按 `l` 关掉，不必重启 | `l` |
| `r` | 重置场景（换种子） | `r` |
| `?` | 打印固件帮助 | `?` |

### 3.2 行命令：`=N`（**精确设置 N**）

```
=N\n
```

- 形式：**`=` + 十进制数字**，必须以 **`\n`（换行，0x0A）** 结束；
- 固件把 N **钳位到 25 – 6000**；
- 固件回包：`EV N=<值>`（例：发 `=1375\n` → 回 `EV N=1375`）；
- 页面上的用法：拖 **N 滑块**（25–6000，步进 25）或直接填数字框，然后点 **应用 =N** —— 只有点「应用」才真正写串口，拖动滑块过程中不会发送任何数据。

### 3.3 固件回包

- 上电打印一次**开机横幅**（如 `===== FinalDemo: HW accel vs pure CPU, same screen =====`，
  以及 `blk: 16x16 sprite, runtime-switchable 16/32/64 (key k cycles 16->32->64->16,`）；
- 命令被接受时打印一行 `EV ...`：
  `EV scene=1 (0=FILL 1=ALPHA 2=KEY)`、`EV path=2 HW only`、`EV N=1375`、
  `EV alpha=64`、`EV clear_per_pass=1 ...`、`EV advance=1 ...`、`EV size=32`、`EV reset`、`EV N=...`。
- 看到 `EV N=<你设的值>` 就说明 `=N` 生效了。
- 按 `k` 切换物块尺寸后，回包是 `EV size=16` / `EV size=32` / `EV size=64`（按 `16 → 32 → 64 → 16` 循环）；屏幕信息条左侧的 `SZ=` 字段同步显示当前值。
- 按 `l` 切换显示列表路径时，**回包分两步**：按键立刻回 `EV dl on pending` / `EV dl off pending`
  （或待生效期间再按一次撤销：`EV dl … pending cancelled`），在**下一个帧边界**（本帧那张表已被
  取指器消费完、像素已写提交）真正生效时回 `EV dl on` / `EV dl off`。
  这样"列表模式开着"也能按 `l` 关掉 —— 旧版会因为"有表在飞"而回 `EV dl busy, retry`，实际上永远切不回去。
  打开时另外打印两行：`DL_VERSION=` / `geom=` / `lists=`（能力探测与两个列表缓冲的 DDR 地址），
  以及清屏引擎的累计计数 `clr fb=<n> to=<n> err=<n>`（`fb` = 目标缓冲不干净、本趟整片重铺退回到
  引擎关键路径的次数；`to`/`err` = 等清屏超时 / 硬件互斥拒绝）。稳态下这三个数都不该增长；
  切换前后各读一次、用差值即可判断"背景重铺是不是又跑在关键路径上了"。
  第一张表跑完时还会打印一次性读数 `EV dl 1st list: STATUS=... consumed=... perf=...`。
- 列表路径**出错**（`DL_ERR` 置位）时打印
  `EV DL_ERR code=<错误位> idx=<出错序号> unsup=<未实现位> fault=<FAULT_ADDR>` 与
  `EV list path OFF, fallback to per-command (key l re-arms)`：固件会**自动退回逐条下发**并停用列表
  路径（信息条的 `L` 标记消失），画面继续刷新，演示不会停；修好/想再试按一次 `l` 重新启用。
- 打开列表路径时会先做**能力探测**（读 `DL_VERSION` 0x80）：若这颗 bitstream 没有显示列表
  （bitstream 早于 v2.11，该地址读回 0），回包是 `EV dl not supported (DL_VERSION=0, need [15:0]>=2)`，
  开关**保持关闭**（避免"以为在跑列表、其实一条命令都没下发"的假成功）。

### 3.4 显示列表看门狗：超时值、出错现场与自动重试（v2.14）

**超时值**：`DL_TIMEOUT`（0x78）的单位是 **core 拍**（不是 us/ms），**复位 4096 拍 ≈47µs@87MHz，
写 0 = 关**。每次 arm 列表时固件显式把它写成字段上界 **65535 拍 ≈753µs@87MHz（16× 复位值）**，
并**把读回值一起打出来**：

```
EV dl arm ok: timeout=65535/65535 ticks (x16 reset 4096, ~753us@87MHz) GEOM_BASE=801000 GEOM_MAX=8
```

（`读出/写入` 两个数并排 —— 一眼看出到底写进去没有。若某颗位流没有 0x78，会先打
`EV dl arm WARN TIMEOUT: wrote ffff read <值> (0x78 missing? watchdog stays 4096 ticks)`，
列表路径照常使用：看门狗只影响**诊断灵敏度**，不影响画面。）

**出错现场**：`DL_ERR` 置位时除了原来那行，还会打印解码后的状态快照：

```
EV DL_ERR code=10 (WATCHDOG (one descriptor stuck > DL_TIMEOUT)) idx=20 unsup=0 fault=821130
EV dl status: DL_STATUS=00000005 BUSY=1 DONE=0 ERR=1 ABORTED=0 STALL=0 ACTIVE_BUF=0 CONSUMED=20 stall_seen=1
EV dl perf_prev=0 tmo=65535 (this list's PERF comes after BUSY=0)
EV dl clr: CLR_STAT=00000000 CLR_CYC=0 busy=0 fb=3 to=0 err=0
EV dl hint: geometry-table read failed -> only FILL(SIZE_OVR) would have drawn
```

等 DFU 真的落 `BUSY=0` 后再补一行（这一行的 `perf=` 才是**这张出错表**的真实周期数，
出错那一刻读到的是上一张表的）：

```
EV dl post-mortem: DL_STATUS=00140000 BUSY=0 DONE=0 ERR=0 ABORTED=0 STALL=0 ACTIVE_BUF=0 CONSUMED=20 stall_seen=1
EV dl post-mortem: perf=21480 tmo=65535 (this list, GO->ERR->BUSY=0)
```

- `CONSUMED=` 就是**出错时已经吃掉了多少条描述符**；
- `stall_seen=` 是"这张表在飞期间**有没有见过 `DL_STATUS.STALL`**"。★ `STALL` 本身是组合位，
  一进错误态就自动落 0 ⇒ 上面那行 `status:` 里的 `STALL=` **正常就是 0**（出错后再读它必然是 0），
  所以固件在轮询期间把这位**粘住**成 `stall_seen`；它才是
  **"取指被饿住（带宽争用，可调）"** 与 **"取指彻底死掉（要改 RTL）"** 的分界；
- `clr ...` 是清屏引擎计数器（`CLR_STAT`/`CLR_CYC` + 软件累计 `fb/to/err`）——后台清屏会与
  取指抢 DDR，是"被饿住"的头号嫌疑人。

**自动重试（只针对 WATCHDOG，最多 2 次）**：看门狗是**有界等待超时**，多半是取指被抢带宽，
重来一次可能就过；其余 `DL_ERR`（GEOM_INDEX / ZERO_SIZE / UNSUPPORTED / …）是确定性问题，
重试只会再错，**直接**退回逐条。看门狗错误的完整回包序列：

```
EV dl retry 1/2 pending (WATCHDOG: wait BUSY=0, re-arm, resend this pass)   ← 先等 DFU 落 BUSY=0
                                                                             （中间插上面那两行 post-mortem）
EV dl retry 1/2 start (fresh arm, this pass from hw_i=0)                   ← 重新 arm + 本趟从头重发
EV dl arm ok: timeout=65535/65535 ticks (...)                              ← 重新 arm 的读回校验
EV dl 1st list: STATUS=... consumed=... perf=...                           ← 重试表照样做首表读数 + 像素探针
EV dl retry 1/2 ok (cumulative ok=1 bad=0)                                 ← 成功 ⇒ 继续用列表路径
```

失败时：`EV dl retry 1/2 failed (code=10 WATCHDOG (one descriptor stuck > DL_TIMEOUT))`，
两次都失败（或重试的重新 arm 没过校验）才 `EV dl retry failed, staying on per-command`
＋ `EV list path OFF (DL_ERR), fallback to per-command (key l re-arms)`。
重试期间**始终留在列表路径**（`g_dl_mode` 不变）：不会一帧里混两条路径，也不会切在一张表中间；
重新 arm 只在 `BUSY=0` 之后做，所以"表还在被读"与"CPU 改列表缓冲"永不重叠。

**板上怎么判读**（三个结局对应三种结论）：

| 串口现象 | 结论 | 下一步 |
| --- | --- | --- |
| 打开 `l` 后再也不报 `DL_ERR`，`arm ok` 行的 `timeout=65535/65535` | 原来的 4096 拍只是**太短**：取指慢但有界（带宽争用） | 保持列表模式；想再快就调 `DL_CFG.CHUNK/FIFO_WM` 或仲裁权重（RTL 侧） |
| 仍报 `code=10`，但 `stall_seen=1` 且 `perf` 只比 `tmo` 大一点 | 确实被饿住，且有界 ⇒ 加大超时/调仲裁能治 | 先看 `clr busy` 是否长期为 1（清屏抢带宽），再考虑 RTL 调优 |
| 仍报 `code=10` 且 `stall_seen=0`（或 `perf` 远超 `tmo`、`CONSUMED` 卡在同一个数） | 取指**真的死了**：不是慢，是不回 | 这是硬饿死/死锁，需要 RTL 侧修；软件已自动退回逐条，演示不受影响 |
| `EV dl retry 1/2 ok` | 偶发抖动，自动恢复生效 | 什么都不用做；累计次数看 `cumulative ok=` |
| 连续 `retry failed` + `list path OFF` | 重试也救不回来 | 按 `l` 可重试一轮；仍失败就走逐条路径（画面照常，只是慢） |

---

## 4. 界面速览

| 区域 | 说明 |
| --- | --- |
| 顶栏 | 波特率下拉、**连接 / 断开**、状态灯（未连接 / 已连接 / 错误+原因） |
| N 精确设置 | 大号当前值 + 滑块 + 数字框（25–6000，自动钳位）+ **应用 =N** + **N −25 / N +25**（发 `-` / `+`） |
| 预设命令按钮 | 每个单字符命令一个大按钮，标题中文，按钮内**灰色小字**写明发送的字符与作用（含**「物块尺寸 16→32→64 · 发送 k」**、**「列表路径 · 发送 l」**，鼠标悬停有说明 tooltip） |
| 日志面板 | 全部收发内容，时间戳 `HH:MM:SS.mmm`；`自动滚动` 开关、`显示发送` 开关、`清空`、**`保存为 txt`**（导出带时间戳的日志文件） |
| 原始发送 | 文本框 + `发送`；勾选 **自动追加换行** 时自动补 `\n`；文本框内 **回车 = 发送**，**Esc = 清空** |
| 命令对照表 | 页面内完整命令表（含 `=N` 行），无需回来翻文档 |

日志细节：收到的字节流按**行缓冲**，半行不会乱插；`\r\n` 与裸 `\r` 都当换行处理；
夹在行中间的控制字符会显示成 `⟨0D⟩` 这样的可见记号，不会被吞掉。
长时间不换行的输出（例如进度条）会在停 400 ms 后作为半行显示，行尾带 `⋯` 标记。

---

## 5. 排错（Troubleshooting）

| 现象 | 原因 / 处理 |
| --- | --- |
| 顶部黄条「不支持 Web Serial」 | 用的不是桌面版 Chrome/Edge，或页面不是安全上下文。换 Chrome/Edge；用 `file://` 或 `localhost` 打开 |
| 点「连接」没有弹出串口列表 | ① 页面不是安全上下文；② 串口被别的软件（另一个串口助手 / IDE 串口终端）占用 → 关掉它；③ 驱动没装（设备管理器里没有 COM 口） |
| 提示「打开串口失败」/ Failed to open serial port | 串口被别人占用，或 USB 线只供电不传数据 → 换线/换口，拔插后重连 |
| **日志全是乱码** | **波特率不匹配**：改回 115200 重连；仍乱码就按 9600→230400 逐个试 |
| 日志有字但按命令没反应 | 焦点不在页面上（点一下页面）；或板子还在跑别的固件；按 `?` 看有没有帮助文本回包 |
| 发 `=1375` 没反应 | `=N` 是**行命令**，必须带换行：勾上「自动追加换行」，或用「应用 =N」按钮（它会自动补 `\n`） |
| 发 `=9000` 回的是 `EV N=6000` | 正常：固件把 N 钳位在 25–6000 |
| 拔线后状态一直「已连接」 | 点一次「断开」，或按 Ctrl+F5 刷新（正常情况下拔线会自动变红并提示） |
| 按钮点了没反应、状态变红「尚未连接串口」 | 还没连接：预设按钮不会静默丢弃，会在日志里明确写「未连接：命令 "1" 未发送」 |

---

## 6. 已知限制

- 只能在桌面版 Chromium 系浏览器用（浏览器厂商限制，非本页面问题）；
- 页面固定 **8N1**、无流控；如需其它帧格式，改 `connect()` 里 `port.open({...})` 的参数；
- 波特率下拉里的 230400 不一定被所有 USB 转串口芯片支持；
- 本页面**只在无串口设备的 headless Chrome 里做过渲染与逻辑自测**：真实板子上的收发（含 `=N` 的 `EV N=` 回包）需要接上 FPGA 才能最终确认。

---

## 7. 文件

```
tools/
├── serial_console.html         FinalDemo 的上位机（单文件，HTML+CSS+JS 全内联，离线可用）
├── ad_demo_console.html        AdDemo 的上位机
├── game_console.html           ★ GameDemo 的上位机（PC 键盘 → 串口，虚拟手柄 + 记分板）
├── game_console1.html          ★ GameDemo 上位机**增强版**（+ 敌弹 FILL/ALPHA/ADD/KEY 切换）
├── game_console_selftest.js    ★ 上位机协议自检（Node；可选 HTML 路径参数，34 / 53 项）
├── build_gamedemo.ps1          ★ 一键流水线：编固件 → 主机仿真自检 → 协议自检 → 合一镜像
├── make_soc_image.ps1          位流 + 应用 → 单个可直接烧写的 .hex
├── host_selfcheck/             AdDemo 的「抽标记段 + 手写期望值」主机自检（需要宿主 gcc）
├── host_selfcheck_game/        ★ GameDemo 的主机**全固件仿真**自检（QEMU riscv32，62 项）
│   ├── build_and_run.ps1         编译 + 跑 QEMU + 归档日志
│   └── sim/                      sim_main.c（原样 #include 固件）+ 假 BSP + 链接脚本
└── README.md                   本说明
```

★ = GameDemo 新增。
