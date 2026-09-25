# logs —— 仿真与回归日志

- `log_tb_*.txt`：每个 testbench 的仿真输出（由 `rtl/tb/run_regress.ps1` 产生）
- `compile_tb_*.txt`：编译阶段输出（多为空文件 = 无告警）
- `baseline_regress.txt` / `final_regress.txt`：改动前后的整轮回归汇总
- `on_wr_order.txt` / `off_wr_order.txt`：写屏障开/关的 A/B 对照
- `sim_scan.log`：早期扫描输出诊断
- `vvp/`：iverilog 编译出的仿真可执行文件（体积大、纯产物，可随时删）

## GameDemo（高负载互动弹幕游戏）相关

| 文件 | 内容 | 怎么重新生成 |
|---|---|---|
| `host_selfcheck_GameDemo.txt` | **主机全固件仿真**原始日志：把 `GameDemo.c` 原样 `#include` 进仿真宿主、用假引擎在 QEMU riscv32 上跑 600 个上屏帧，A/B/C/E/D 五组共 **74 项** | `powershell -ExecutionPolicy Bypass -File tools\host_selfcheck_game\build_and_run.ps1` |
| `game_console_selftest.txt` | 上位机协议自检（抽 HTML 的 PROTO 段在 Node 里跑）：**基础版 34 项 + 增强版 53 项**，两份都在同一个文件里 | `node tools\game_console_selftest.js` 与 `node tools\game_console_selftest.js tools\game_console1.html` |
| `board_gamedemo_limit_*.txt` | **上板**后抄下来的 `LIMIT` / 容量数（自动爬坡找到的 60FPS 极限 N） | 手动归档；格式见 `doc/GameDemo_高负载互动弹幕游戏.md` §10.3 |

重新跑回归会在脚本的工作目录重新生成这些文件；要避免再次堆在根目录，可先
`cd doc\logs` 再执行 `rtl\tb\run_regress.ps1`。
