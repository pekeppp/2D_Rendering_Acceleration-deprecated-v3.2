# 2D BitBlt 像素吞吐瓶颈诊断报告（只读探针）

探针 = `rtl/tb/tb_perf_probe.v`（新增；**未改任何 RTL / 寄存器图 / FSM / 既有 TB**，未加入 `rtl/tb/run_regress.ps1`）。
复用 `rtl/tb/tb_blt_top.v` 的夹具与寄存器序列、`rtl/tb/axi_slave_mem.v` 存储模型（参数与 `tb_blt_top` 逐项相同）；所有内部量只读层次引用。
原始日志 = `doc/logs/log_tb_perf_probe.txt`。

## 1. 直接结论

限制吞吐的是**单 lane 打包器每个 16B 词强制插入的 1 拍冲刷**：整屏 FILL 585,387 拍中 518,400 拍推进像素（88.56%）、64,800 拍冲刷（11.07%）、FSM 开销仅 2,187 拍（0.37%）。数据侧一次没饿过（fg/bg FIFO 真空 = 0 拍），`wd` 一次没满（0 拍），而写主机已忙 77.5%（8 拍/词，只剩 1 拍余量）。读类算子另加 1 拍/词的 `stream_reader` 重装气泡 → 0.80 px/拍。**帧级 947 拍/块不是引擎成本**：32x32 FILL 结构下限 = 32×(32 px+4 冲刷) = 1152 拍，孤立与背靠背实测都是 1307 拍，64 块背靠背只藏住 63 拍（0.075%）——`ST_WDWAIT` 写提交屏障把命令完全串行化，不存在可利用的命令间重叠。

## 2. 逐算子表（除注明外均为单条孤立命令）

| 算子 | cycles(PERF 0x1C) | 写出像素 | cycles/px | 16B 词 | AW | 行周期 | 孤立 / 背靠背边际 |
|---|---|---|---|---|---|---|---|
| 960x540 FILL | **585,387**（板 585,941，+0.09%） | 518,400 | 1.1292 | 64,800 | 64,800 | 1083（min=max） | — |
| 960x540 COPY | 650,275 | 518,400 | 1.2544 | 64,800 | 64,800 | 1203 | — |
| 32x32 FILL（stride 64） | 1,307 | 1,024 | 1.2764 | 128 | 128 | 39 | 1307 / 1307（藏 0 拍） |
| 32x32 COPY | 1,460 | 1,024 | 1.4258 | 128 | 128 | 43 | — |
| 32x32 ALPHA α=128 | 1,464 | 1,024 | 1.4297 | 128 | 128 | 43 | 1464 / 1464（藏 0 拍） |
| 32x32 KEY | 1,460 | 713（键色跳 311） | 2.0477 | 124（4 词整词键色不提交） | 124 | 43 | — |
| 32x32 FILL @ fb stride 1920 | 1,307 | 1,024 | 1.2764 | 128 | 128 | 39 | 1307 / 1307（藏 0 拍） |

背靠背：T8=64 块、T9=32 块（FB stride）、T10=16 块 ALPHA，实测 **1307 / 1307 / 1464 拍/块，与孤立值逐拍相同**；命令间 IDLE 仅 1 拍/命令（不计入 PERF）。
**像素发射率 = 1 px/拍（单 lane）**：最长连续推进连击 `max_px_run = 8`（所有算子均为 8，从不为 16）；`out_px` 仅 16bit 一路、128bit acc 每拍只写一个 lane。0.884 px/拍 ≈ 8/9 由此成立。

## 3. 停顿归因直方图（口径 = 引擎非 IDLE 周期，与 PERF 同口径；单位 拍）

| 类别 | 960x540 FILL | % | 960x540 COPY | % | 32x32 FILL | % |
|---|---|---|---|---|---|---|
| PIX_KEEP 推进 1 像素 | 518,400 | 88.56 | 518,400 | 79.72 | 1,024 | 78.35 |
| FLUSH_WORD_COMMIT 冲刷并提交词 | **64,800** | **11.07** | 64,800 | 9.97 | **128** | **9.79** |
| FLUSH_HOLE（整词键色不提交） | 0 | 0 | 0 | 0 | 0 | 0 |
| FLUSH_BLOCKED_WD_FULL（冲刷被 wd 满挡） | **0** | 0 | 0 | 0 | 0 | 0 |
| STALL_FG / BG / 两侧（无像素） | **0** | 0 | 64,800 | 9.97 | 0 | 0 |
| ENG_POP_8WORDS | 15 | 0.00 | 15 | 0.00 | 15 | 1.15 |
| ENG_DEC / ENG_EXEC_INIT | 1 / 1 | 0.00 | 1 / 1 | 0.00 | 1 / 1 | 0.16 |
| ENG_WAIT_ROW0（等本行首词） | 0 | 0 | 26 | 0.00 | 0 | 0 |
| ENG_ROW_GAP（行间握手空档） | 1,620 | 0.28 | 1,682 | 0.26 | 96 | 7.35 |
| ENG_DRAIN | 540 | 0.09 | 540 | 0.08 | 32 | 2.45 |
| ENG_WDWAIT（写提交屏障） | 10 | 0.00 | 10 | 0.00 | 10 | 0.77 |
| OTHER / OTHER_PIX / IDLE_GAP | 0 | 0 | 0 | 0 | 0 | 0 |
| **求和** | **585,387** | 100 | **650,275** | 100 | **1,307** | 100 |
| **对账：hist_sum − PERF** | **0** | | **0** | | **0** | |

**对账说明**：窗口 = `u_blt.u_eng.st != IDLE` 的周期，与引擎 PERF 计数器逐拍同口径，六个算子 `hist_sum − PERF` 全为 0，未列类别全为 0（无"其他"黑洞）；`wall = PERF + 17~18 拍`（TB 轮询粒度）；背靠背里 `eng_window − hist_sum` = 命令间 IDLE（63/31/15 拍），已单列。
补充读数：`wd_full` 周期 = 0、`wd` FIFO 峰值 = 1 词；停顿中 "FIFO 真空" = 0 拍，COPY/KEY 的 64,800(128) 拍全是 `stream_reader` 每词 1 拍的结构性重装气泡；写主机状态分布（FILL）= IDLE 131,787 / BUF 64,800 / AW 64,800 / W 64,800 / B 259,200，即 **8 拍/词**。

## 4. 三个 what-if 的算术

| 改动 | 今天 | 改后 | 算术 | 前提 / 风险 |
|---|---|---|---|---|
| **(a)** 16B 打包寄存器乒乓，藏掉每词冲刷 | 9 拍/词 = 0.889 px/拍 | 整屏 FILL **520,587 拍**（0.996 px/拍，**−11.1%**，1.125×）；32x32 FILL 1307 → 1179 | 585,387 − 64,800（=全部冲刷拍） | 写主机实测就是 **8 拍/词**，改后与像素通路**打平、零余量**；板上 B 往返每多 1 拍整拍吃回。**必须先修写突发合并**，否则只是换瓶颈。读类只能到 9 拍/词（重装气泡不消失）：COPY 1460 → 1332（−8.8%）、整屏 COPY 650,275 → 585,475 |
| **(b)** 双 lane，2 px/拍 | 9 拍/词 | 不藏冲刷 5 拍/词 = **1.6 px/拍**（整屏 ≈ **326,000 拍，1.79×**）；连冲刷一起藏 4 拍/词 = **2.0 px/拍**（≈ **261,400 拍，2.24×**） | 8 px÷2 = 4 拍/词；518,400×0.625(+2,187) / ×0.5(+2,187) | 需写通道吃 **4 B/拍**，实测只有 16B/8 拍 = **2 B/拍 → 现在超 2 倍、不可行**；即便按板上 4.7 B/拍也是 85% 占用、零余量，且 COPY/ALPHA 双读流。墙在写通道；另需 2 路 acc 写+掩码，是真正的数据通路改造 |
| **(c)** 混合乘加搬进 DSP | ALPHA 1464 = COPY 1460 + 4 拍 | 吞吐 **0%** 收益 | +4/1460 = **+0.27%**；6 个乘法器纯组合、藏在像素推进拍内 | 只影响 Fmax/时序收敛，非吞吐；板上 ALPHA−KEY=428 拍/块来自第二条读流的 DDR 争用，DSP 拿不回。需时序报告判断 |

**额外发现（探针独立测到，性价比最高）**：16 拍写突发合并**对 BitBlt 流量完全没生效**——`AW_top = 16B 词数 = 64,800`、`burst_max = 1`（所有算子皆然）。原因：`axi_wr_master` 的 `S_BUF` 仅在 `!wd_empty` 时合并，而 `sync_fifo` 弹字后输出寄存器有 1 拍空窗，且像素通路（9 拍/词）比写主机（8 拍/词）慢 → `wd` 峰值只有 1 词，永远凑不出第二拍；清屏引擎是背靠背生产者故能合并（`tb_blt_top` T10：32 拍 → 2 笔 AW）。修它可把写主机每词成本从 8 拍降到 ~1–2 拍，是 (a)/(b) 兑现的前提；也印证"16× 减少 AW 对帧时间无影响"——**现在 AW 根本没减少，而它也确实不是瓶颈**。

> **★ 2026-09 更新（本轮已修，见 `rtl/功能清单.md` §23）**：上面这条"额外发现"已兑现，而且**根因比当时的判断更深一层**：把判据从 `!wd_empty` 换成 `wd_count` **仍然不合并**（实测 AW 仍 62,855 笔、`burst_avg` 1.03）——因为 `count` 口径里的 `mcnt` 是**还压在 BRAM 里**的字，弹字空窗那一拍 `out_v=0`、`dout` 还是旧词，却因 `mcnt>0` 被误判成"有新词"，于是拿旧地址去比连续性、必然失败。正确口径要**分开判**"本拍 `dout` 上真有没被消费的新词"（`dout_v`）与"吃掉队头后还有货"（`cnt_more`），并让 `S_BUF` **愿意等** `HOLD_MAX=16` 拍。改后本探针读数（同一份 `tb_perf_probe.v`）：
> ```
> PROBE OPSUM T1_960x540_FILL | words16B=64800 AW_top=4051 AW_wr=4051 Wbeats=64800 B=4051
> PROBE OPRATE T1 | burst_max=16 burst_avg=15.996050 | wd_full_cyc=0 wd_peak=4 | cyc/px=1.004321
> PROBE TABLE T1 | 520640 | 518400 | 1.004321 | 64800 | 4051
> PROBE OPDATA T1 | wrst_idle=4083 buf=431502 AW=4051 W=64800 B=16204
> ```
> 即 AW 64,800 → **4,051**（−93.7%，理论下限 4,050，只多 1 笔）、`burst_avg` 1.000 → **15.996**、写主机 AXI 事务成本 **8.0 → 1.13 拍/词**（(AW2+W16+B2+idle1.25)/16）；整屏 FILL 总拍数 520,588 → **520,640（+52 拍，+0.010%）**；32x32 FILL 1,180 → 1232（+52，全在 `ENG_WDWAIT` 桶，属每条命令一次的尾部常数）；`-DWR_MERGE_HOLD_OFF` 逐字回到本报告的全部读数。§4(a)(b) 的前提"写侧必须有 4 B/拍"随之变为"**AXI 侧够、但像素通路本身仍是 2 B/拍**"——即 (b) 双 lane 的墙已经从写主机移回**打包器/lane 宽度**（要 (b) 仍需 2 路 acc+掩码的数据通路改造）。

> **★ 2026-09 更新之二（本轮已修尾延迟，见 `rtl/功能清单.md` §24）**：上面那条"+52 拍尾部常数"已压到 **+19 拍**。做法 = 引擎在 `ST_WDWAIT` 给写主机一个"命令结束、立刻冲刷"的显式提示（`wr_cmd_end` → `axi_wr_master.cmd_end_flush`），写主机进"尾模式"：不再要求尾词有"同伴"、且 FIFO 排空后再等 `TAIL_GRACE=4` 拍就发车。同一份 `tb_perf_probe.v` 实测：
> ```
> PROBE OP T1_960x540_FILL | perf=520607 hist_sum=520607 delta=0     （改前 520,640）
> PROBE OPSUM T1 | words16B=64800 AW_top=4050 AW_wr=4050 Wbeats=64800 B=4050   （AW 4,051 → 4,050 = 理论下限）
> PROBE OPRATE T1 | burst_max=16 burst_avg=16.000000 wd_full_cyc=0 wd_peak=4
> PROBE HIST T1 | ENG_WDWAIT | 30                                    （改前 63）
> PROBE OP T3_32x32_FILL | perf=1199 hist_sum=1199 delta=0            （改前 1,232）
> PROBE B2B T8_B2B64_32x32_FILL | 1199 拍/块（AW/blk 9 → 8）
> ```
> 即 `+52` 里 33 拍是"等两次 `HOLD_MAX`"（纯浪费，已消）；剩下 **19 拍是合并本身的固有代价**（最后一整页 16 拍突发必须先 AW→W→B 回来引擎才允许报完成，单笔在飞 + 写序保证不可动）。`-DWR_CMD_END_FLUSH_OFF` 逐字回到本报告上面那组读数。原始日志 `doc/logs/log_tb_perf_probe_cmdtail_on.txt` / `..._off.txt`。

## 5. 文件与运行方式

新增 `rtl/tb/tb_perf_probe.v`（诊断台，不进 `run_regress.ps1`）。与回归同一套工具/flags（iverilog + vvp，`-g2001`），仓库根目录：

```powershell
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
iverilog -g2001 -s tb_perf_probe -o sim_tb_perf_probe.vvp `
  rtl/sync_fifo.v rtl/cmd_fifo.v rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v `
  rtl/axi_rd_master.v rtl/axi_wr_master.v rtl/stream_reader.v rtl/pixel_path.v `
  rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/clr_engine.v rtl/blt_top.v `
  rtl/tb/axi_slave_mem.v rtl/tb/tb_perf_probe.v
vvp sim_tb_perf_probe.vvp     # 编译 ~6s，仿真 ~62s（13.9e9 ps，输出逐字节可复现）
```

日志要点（原文，完整见 `doc/logs/log_tb_perf_probe.txt`）：

```
PROBE OP T1_960x540_FILL op=1 960x540 | perf=585387 wall=585404 active=585387 idle_gap=17 hist_sum=585387 delta=0
PROBE OPSUM T1_960x540_FILL | px_cons=518400 px_written=518400 words16B=64800 AW_top=64800 AW_wr=64800 Wbeats=64800 B=64800 rows=540
PROBE OPRATE T1_960x540_FILL | cyc/px=1.129219 px/cyc=0.885568 | max_px_run=8 px_run_cyc=583200 flush_word=64800 flush_hole=0 flush_wdful=0 | wd_full_cyc=0 wd_peak=1 burst_max=1 burst_avg=1.000000 | row_cyc_min=1083 avg=1083.000000 max=1083
PROBE OPDATA T1_960x540_FILL | stall_fg_fifo=0 stall_fg_reload=0 stall_fg_nordbusy=0 stall_bg_fifo=0 stall_bg_reload=0 | wrst_idle=131787 buf=64800 AW=64800 W=64800 B=259200
PROBE HIST T1_960x540_FILL | PIX_KEEP |   518400 |  88.56%
PROBE HIST T1_960x540_FILL | FLUSH_WORD_COMMIT |    64800 |  11.07%
PROBE HIST-END T1_960x540_FILL  sum_delta_vs_active=0
PROBE OP T3_32x32_FILL op=1 32x32 | perf=1307 wall=1324 active=1307 idle_gap=17 hist_sum=1307 delta=0
PROBE OP T5_32x32_ALPHA op=2 32x32 | perf=1464 ...    (T4_32x32_COPY perf=1460)
PROBE B2B T8_B2B64_32x32_FILL op=1 32x32 x64 | wall=83728 active(hist_sum)=83648 sumPERF=1307 idle_gap=80 eng_window=83711 inter_gap=63
PROBE B2BSUM T8_B2B64_32x32_FILL | px_written_total=65536 px_per_blk=1024.000000 words=8192 AW_top=8192 AW/blk=128.000000
PROBE TABLE_B2B T8_B2B64_32x32_FILL | 1307 | 1024 | 1.276367 | 128 | 128
PROBE SANITY T1_first_px @00004000 exp=f800 got=f800 OK
```

## 6. 没能确定的部分

| 项 | 说明 |
|---|---|
| 存储模型仅 32KB | iverilog 对大 `mem` 数组编译耗时爆炸（1MB >100s 不收敛、4MB 更甚），只能沿用 `tb_blt_top` 的 `MEM_BYTES=1<<15`。整屏算子**周期数有效**（写越界只是不落盘、读越界返回 0，时序与地址/数据无关；COPY/ALPHA 的 keep 恒 1，KEY 用 32KB 内区域 → 数据是真的）；但只有前 32KB 落盘，数据校验只在前 32KB 内做（T1 首/末像素 OK、T3 边界未越写 OK） |
| 行为从机无 DDR 带宽/换页/刷新争用 | 仿真里读侧从不饿（`stall_fg_fifo=0`），故 COPY/KEY/ALPHA 绝对值比板上乐观（板 KEY≈1741、ALPHA≈2169，仿真 1460/1464）。FILL 无读、与板吻合 0.09% → **FILL 结论可信；读类读数只用于相对比较** |
| 写侧 B 往返未知 | 仿真 `B_LAT=2`，"写主机 8 拍/词"是**下限**；板上真实 B 往返无法在仿真确定，而它正是 (a)/(b) 成败的关键未知量。**2026-09 更新**：该项已不再是 (a) 的成败关键 —— 合并修好后写主机 AXI 侧成本降到 **1.13 拍/词**（16 拍一笔），相对像素通路 8 拍/词有 7 倍余量，B 往返即使多几十拍也只吃掉余量、不会把 `wd` FIFO 顶满（`wd_peak=4`/深度 16，见 §23）。 |
| 帧级 947 拍/块无法复现 | 需帧级基准才能对齐其口径（块像素数 / 引擎是否为帧关键路径）；探针只能证明它低于结构下限 1152 拍、且背靠背零重叠 |
| (a)(b)(c) 是外推而非实测 | 按规则未改任何 RTL，数字由直方图外推；(c) 的 Fmax 影响需时序报告，周期仿真测不出。**2026-09 更新**：(a) 已兑现（§22：585,387 → 520,588）；§4 那条"必须先修写突发合并"的额外发现也已兑现（§23：AW 64,800 → 4,051、写侧 8.0 → 1.13 拍/词），本文档 §1/§3 里"写主机已忙 77.5%、只剩 1 拍余量"是针对**改前** RTL 的结论，改后不再成立 |

## 7. ★ 2026-09 更新之三：显示列表（S2）落地后的"每块开销拆分"实测

本轮给探针加了 **T11 / T12a / T12b / T12c** 四个用例（**既有 T1~T10 的编译与输出一行未动**，同一份 `tb_perf_probe.v` 的既有读数与 §24 的 ON 组**逐字节相同**：T1 `perf=520607 / AW=4050 / burst_avg=16.000000`、T3 `1199`、T4/T5/T6 `1447/1451/1443`、T7 `1187`、T8 `1199/块`）。RTL 侧见 `rtl/功能清单.md` §25，原始日志 `doc/logs/log_tb_perf_probe_dl.txt`。

**16×16 FILL（demo 当前精灵尺寸，256 px）每块开销的实测拆分**：

```
PROBE OP T11_16x16_FILL | perf=366 wall=384 active=366 hist_sum=366 delta=0
PROBE OPSUM T11 | px_cons=256 px_written=256 words16B=32 AW_top=3 Wbeats=32 rows=16
PROBE HIST T11 | PIX_KEEP 256 | ENG_POP_8WORDS 15 | ENG_DEC 1 | ENG_EXEC_INIT 1
                 ENG_ROW_GAP 48 | ENG_DRAIN 16 | ENG_WDWAIT 29     （sum_delta_vs_active=0）
PROBE PUSH T12a_PUSHONLY_32 | per_cmd=16.000000  （GO=0 先灌 32 条，纯 CPU 侧，引擎不跑）
PROBE B2B  T12b_B2B32_16x16_FILL | 11760 拍 / 32 条 = 367.5 拍/条（下发与执行重叠）
PROBE PUSH T12c_SERIAL_32        | 12288 拍 / 32 条 = 384.0 拍/条（push 一条 → 等跑完 → 再 push）
```

| 组成 | 拍/块 | 说明 |
| --- | --- | --- |
| 像素推进 `PIX_KEEP` | **256** | 1 px/拍（§22 之后 8 拍/词，16×16 恰好 32 个词、无冲刷拍残余可摊） |
| 引擎自身（`POP 15 + DEC 1 + INIT 1 + ROW_GAP 48 + DRAIN 16 + WDWAIT 29`） | **110** | 与设计文档 §2.3 的"16 行 ≈111 拍"**逐桶吻合**。S2 **不动 FSM** ⇒ 这 110 拍拿不掉 |
| CPU 侧下发/喂 FIFO | **16.5**（= 384.0 − 367.5，T12a 直接量到 16.0） | 本 TB 的 AXI-Lite 主机每次事务 ≈2 拍（1 读 `CMD_FIFO_COUNT` + 8 写 `CMD_FIFO_DATA`）；**板上走 APB 桥不是 16 拍而是 ~190 拍** |
| 合计（改前，串行口径） | **384.0** | 366 引擎/像素 + 16.5 CPU |
| 合计（列表路径，S2） | **367.2** | `tb_dl_basic` 实测 73448/200 = 367.2；`DL_PERF=73443` |

**结论（诚实版）**：
- 仿真里"CPU 侧"只有 16.5 拍/块，是因为测试台的 AXI-Lite 主机是理想化的（2 拍/事务）。**板级那 ~190 拍**（设计文档 §2.3 的推定）**仿真测不到**，只能由"板上 561 拍 − 仿真 366 拍 ≈ 195 拍"反推 —— 这条与 §6 "写侧 B 往返未知"同一性质。
- S2 消掉的是**这一整块 CPU 侧**（换成硬件展开，`tb_dl_basic` 实测列表路径 = 367 拍/精灵 = 引擎地板），**引擎自身那 110 拍一分没动** ⇒ 与设计文档 §14.2 的预判一致：**S2 单独到不了 5,300 块/帧**，要兑现必须再走 S2.5/S4"命令内多精灵"。
- 16×16 这个尺寸还额外暴露一条既有行为：32 个连续词的写被切成 **16+15+1 三笔 AW**（理论 2 笔），原因是 §24 的 `TAIL_GRACE=4` 恰好卡在边界。**CPU 路径逐项相同**（`tb_dl_basic` 实测 AW-len 1/15/16 = 200/200/200），不是 S2 引入的。

复现（仓库根目录）：
```powershell
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
iverilog -g2001 -s tb_perf_probe -o sim_tb_perf_probe.vvp `
  rtl/sync_fifo.v rtl/cmd_fifo.v rtl/blt_regs_axi_lite.v rtl/blt_addr_gen.v `
  rtl/axi_rd_master.v rtl/axi_wr_master.v rtl/stream_reader.v rtl/pixel_path.v `
  rtl/blt_engine_fsm.v ARC_2DRA/rtl/video/axi_wr_arb.v rtl/clr_engine.v rtl/dl_fetch.v rtl/blt_top.v `
  rtl/tb/axi_slave_mem.v rtl/tb/tb_perf_probe.v
vvp sim_tb_perf_probe.vvp
```

## 8. ★ 2026-09 更新之四：透明块跳过（S3）A/B 探针读数

本轮给探针加了 **T13~T17**（5 种精灵形状 × KEY/ALPHA/FILL 的"无掩码 vs 带掩码"对照，
**既有 T1~T12 一行未动**）。掩码通过命令字 `w0` 的空位下发（`w0={MASK[15:0],13'd0,MASK_EN,OP}`），
所以同一个 `run_op` 就能跑 A/B：`cur_mask=0` = 今天的行为。RTL 侧见 `rtl/功能清单.md` §26，
原始日志 `doc/logs/log_probe_s3_mask_on.txt`（默认）与 `doc/logs/log_probe_s3_mask_off.txt`（`-DMASK_SKIP_OFF`）。

**单条孤立命令（CPU 路径，`PERF 0x1C`，单位：core 拍）**：

| 用例 | 形状（键色/总像素） | op | 无掩码 | 带掩码 | Δ | 掩码 |
| --- | --- | --- | --- | --- | --- | --- |
| T13a | 16×16 demo 球 61/256 | KEY | 445 | 445 | **0（0.0%）** | 0x0000 |
| T13b | 同上 | ALPHA | 464 | 464 | 0（掩码无效） | 0x0000 |
| T13c | 同上 | FILL | 361 | 361 | **0（FILL 不变）** | 0x0000 |
| T14a | 32×32 demo 球 229/1024 | KEY | 1433 | 1433 | **0（0.0%）** | 0x0000 |
| T14b | 同上 | ALPHA | 1451 | 1451 | 0 | 0x0000 |
| T15a | 16×16 典型弹 143/256 | KEY | 425 | 406 | **−19（−4.5%）** | 0x9008 |
| T15b | 同上 | ALPHA | 464 | 464 | 0 | 0x9008 |
| T16a | 32×32 典型弹 647/1024 | KEY | 1419 | 1115 | **−304（−21.4%）** | 0x9009 |
| T17a | 32×32 小弹 875/1024 | KEY | 1419 | 452 | **−967（−68.1%）** | 0xf99f |
| T17b | 同上 | ALPHA | 1451 | 1451 | 0 | 0xf99f |

**诚实版结论**：
- 任务书点名的 demo 精灵（白环 + 渐变内芯、四角键色 61/256）**一点都省不了**：圆盘半径 8 几乎内切 16×16 包围盒，
  4×4 块里没有任何一块能被判成"整块透明"（四角块的内角 (3,3) 距圆心 √32≈5.66 < 8）。32×32 同形状（229/1024）同样是 0。
- 掩码真正兑现的是**覆盖率 35~50% 的弹幕弹**（−4.5% / −21.4%）与**小弹放在大图集格子里**（−68.1%，那是因为上下
  两条行带整带透明 ⇒ 那些行 0 次取数）。这三个数字与 `tb_dl_mask`（列表路径、16 条/列表、`DL_PERF`）**逐条吻合**。
- `-DMASK_SKIP_OFF` 下"带掩码"一列**逐条等于**"无掩码"（T16a 1419→1419、T17a 1419→1419）⇒ 逃生门 = 逐位回到 S2 之后的行为。
- ALPHA / FILL 在两种模式下都不动，且 ALPHA 即使喂"全透明 0xFFFF"掩码也**逐位不变** ⇒ 非 KEY 显式忽略掩码（RTL 安全规则）。

复现（A/B 只差一个宏）：
```powershell
iverilog -g2001 -s tb_perf_probe -o sim_tb_perf_probe_s3.vvp <同上源文件表>
vvp sim_tb_perf_probe_s3.vvp | Select-String 'S3 SHAPE|PROBE OP T1[3-7]'   # 默认（掩码生效）
iverilog -g2001 -DMASK_SKIP_OFF -s tb_perf_probe -o sim_tb_perf_probe_s3off.vvp <同上源文件表>
vvp sim_tb_perf_probe_s3off.vvp | Select-String 'S3 SHAPE|PROBE OP T1[3-7]'  # 逃生门（读数应两两相同）
```

## 9. ★ 2026-09 更新之五：双 lane（2 px/拍）落地后的 A/B 读数（§4(b) 结账）

§4(b) 那条"双 lane，2 px/拍"的外推本轮已兑现（RTL 取舍与证据见 `rtl/功能清单.md` §27）。**同一份
`tb_perf_probe.v` 一行未改**，A/B 只差 `-DPIXEL_PIXELS2_OFF`；日志 `doc/logs/log_probe_px2off.txt`
（= 今天之前的行为）/ `log_probe_px2on.txt`（默认 = 双 lane）。

| 用例 | 拍数 OFF → ON | px/拍 OFF → ON | 倍数 |
| --- | --- | --- | --- |
| T1 960x540 FILL | 520,607 → **261,407** | 0.995761 → **1.983114** | 1.99× |
| T2 960x540 COPY | 649,755 → **262,035** | 0.797839 → **1.978362** | 2.48× |
| T3 32x32 FILL | 1,199 → **687** | 0.854045 → 1.490539 | 1.75× |
| T4 32x32 COPY | 1,447 → **804** | 0.707671 → 1.273632 | 1.80× |
| T5 32x32 ALPHA α=128 | 1,451 → **868** | 0.705720 → 1.179724 | 1.67× |
| T6 32x32 KEY | 1,443 → **800** | 0.494109 → 0.891250 | 1.80× |
| T7 32x32 FILL @FB stride | 1,187 → **681** | 0.862679 → 1.503671 | 1.74× |
| T8 背靠背 ×64 | 1,199 → **687** 拍/块 | — | 1.75× |
| T11 16x16 FILL | 366 → **239** | — | 1.53× |
| T13a/b/c 16x16 demo KEY/ALPHA/FILL | 445/464/361 → **355/374/233** | — | 1.25/1.24/1.55× |
| T16a 32x32 弹 KEY | 1,419 → **775** | — | 1.83× |

写侧（T1）：`AW_top/AW_wr/Wbeats/B = 4050/4050/64,800/4050` 两模式相同、`burst_max=16`、
`burst_avg=16.000000`、`wd_full_cyc=0`、`wd_peak` 4 → 7（深 16）。直方图（T1）：`PIX_KEEP 259,200`（99.16%）
+ `ROW_GAP 1620 / DRAIN 540 / WDWAIT 30 / POP 15 / DEC 1 / INIT 1`，**无 FLUSH_* 桶、无新桶、
`sum_delta_vs_active=0`**；T2 只剩 `STALL_FG 540`（0.21%，= 每行首词载入那 1 拍）。

**三条结论（诚实版）**：
1. 整屏 FILL 落在 261,407 拍 —— §4(b) 里"连冲刷一起藏 4 拍/词 ≈ 261,400"的算术**误差 +7 拍（0.003%）**。
2. **读类不再是 0.889 px/拍**：§4(a)/§22.4 里那条"`stream_reader` 每词 1~2 拍重装气泡"本轮被双词槽预取
   消掉（弹词条数与引擎 drain 口径逐词不变），整屏 COPY 从 649,755 掉到 262,035（2.48×，比 FILL 的 1.99×
   还多，因为它同时吃掉了旧版的气泡与冲刷拍）。
3. **口径提醒（不粉饰）**：`px_cons / px_skipped / max_px_run` 是**按拍**统计，双 lane 下 1 拍 = 2 像素 ⇒
   `px_cons` 518,400 → 259,200、`max_px_run` 960 → 480（每行 960 像素仍**整行不断流**）、KEYCHK 的
   `px_skipped` 311 → 264。像素级口径（`px_written` 518,400/1024/713、`words16B` 64,800/128/124、
   SANITY 首末像素、KEY 留孔）两模式**逐字节相同** —— 位精确性判据一律用这些量。

复现：
```powershell
iverilog -g2001 -s tb_perf_probe -o sim_probe_on.vvp <§5 源文件表>
iverilog -g2001 -DPIXEL_PIXELS2_OFF -s tb_perf_probe -o sim_probe_off.vvp <§5 源文件表>
vvp sim_probe_off.vvp > log_probe_px2off.txt
vvp sim_probe_on.vvp  > log_probe_px2on.txt
```

