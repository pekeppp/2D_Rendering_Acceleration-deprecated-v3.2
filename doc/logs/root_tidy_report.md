# 仓库根目录清理记录（Deliverable 0）

清理原则：**根目录只留目录 + `.gitignore`**。用户自己的文件（`fbTest.c` / `userDef.h`）在 `doc/logs/` 里，未动。

## 1. 移动清单

| 类别 | 数量 | 从 | 到 |
| --- | --- | --- | --- |
| `compile_tb_*.txt` / `log_tb_*.txt` / `log_wr_order_*.txt`（仿真与回归产物） | 51 | 仓库根 | `doc/logs/` |
| `sim_*.vvp`（iverilog 仿真可执行文件） | 30 | 仓库根 | `doc/logs/vvp/` |
| `*.bin` / `*.hex` | 0 | 根目录本来就没有 | — |
| 临时目录（`build_logs/` 等） | 0 | 根目录本来就没有 | — |

- 同名冲突：`doc/logs/` 里原有 2026-09-13 那一轮的 `log_tb_*.txt` / `compile_*.txt` / `sim_*.vvp`，
  被根目录 2026-09-14 的**更新一轮同名产物覆盖**（= 重跑一次回归本来就会发生的事；两组文件都在 git 里，可随时回溯）。
- **未改任何软件**：只做文件搬运，没有改动 `rtl/`、`ARC_2DRA/`、`doc/`、`backup/`、`tools/`、`atlas/`、
  `port_analysis/`、`danmaku/`、`software/`、`simulator/` 里的任何内容（本轮 S1 的 RTL 改动不在本记录范围，见 `rtl/功能清单.md` §24）。
- 未执行任何 git 提交/暂存动作。

## 2. 清理前 / 清理后（根目录逐项）

机器可读的原始清单：`doc/logs/root_tidy_before.txt`、`doc/logs/root_tidy_after.txt`。

### 2.1 清理前（96 项 = 14 目录 + 82 文件）

```
DIR   .dsh-vision-router
DIR   .git
DIR   ARC_2DRA
DIR   atlas
DIR   backup
DIR   danmaku
DIR   doc
DIR   firmware
DIR   opencode_share_download
DIR   port_analysis
DIR   rtl
DIR   simulator
DIR   software
DIR   tools
       200  .gitignore
         0  compile_tb_alpha.txt                  …（共 25 个 compile_tb_*.txt，全部 0 字节）
         0  compile_tb_wr_order_off.txt
     13330  log_tb_alpha.txt                      …（共 26 个 log_*.txt，最大 26870 字节）
      3546  log_tb_wr_order_off.txt
      2426  log_wr_order_merge_on.txt
      3546  log_wr_order_order_off.txt
   7201764  sim_tb_alpha.vvp                      …（共 30 个 sim_*.vvp，合计约 82 MB）
   3766136  sim_wr_order_order_off.vvp
```
（完整 82 行见 `root_tidy_before.txt`；`compile_tb_*.txt` 全部为 0 字节 = 无告警。）

### 2.2 清理后（15 项 = 14 目录 + 1 文件）

```
DIR   .dsh-vision-router
DIR   .git
DIR   ARC_2DRA
DIR   atlas
DIR   backup
DIR   danmaku
DIR   doc
DIR   firmware
DIR   opencode_share_download
DIR   port_analysis
DIR   rtl
DIR   simulator
DIR   software
DIR   tools
       200  .gitignore
```

## 3. 后续回归的运行方式（不再污染根目录）

`rtl/tb/run_regress.ps1` 用**仓库相对路径**引用源码（`rtl/...`、`ARC_2DRA/...`），而产物落在**当前工作目录**。
因此本轮的做法是：在 `doc/logs/` 里用一个临时包装脚本把源码路径整体加 `../../` 前缀后执行原脚本：

```powershell
cd doc\logs
powershell -NoProfile -ExecutionPolicy Bypass -File .\_run_regress_in_logs.ps1
# 包装脚本内容 = 读 ../../rtl/tb/run_regress.ps1，把 "rtl/ → "../../rtl/、"ARC_2DRA/ → "../../ARC_2DRA/，再 Invoke-Expression
```

跑完把 `doc/logs/sim_*.vvp` 挪进 `doc/logs/vvp/`（体积大、纯产物），临时包装脚本删除。
探针（`doc/perf_probe_report.md §5` 的命令）同样在 `doc/logs` 下跑，源路径加 `../../` 前缀。

> 若希望脚本**原生**支持"在任意目录运行、产物固定落 doc/logs"，需要给 `run_regress.ps1` 加一个 `-Root`/`-OutDir`
> 参数（属改工具脚本，本轮按要求未改，只用包装脚本达成同样效果）。
