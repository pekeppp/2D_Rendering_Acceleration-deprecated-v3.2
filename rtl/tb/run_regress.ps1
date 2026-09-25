# BitBlt 回归脚本（必测 + tb_alpha + 总线仲裁压力 tb_arb_deadlock + 写提交顺序专项）
#   ★v2.11：源文件路径一律按**仓库根**解析（由本脚本位置推出），产物
#   （sim_*.vvp / log_*.txt / compile_*.txt）落在**当前目录** —— 于是约定：
#     cd doc\logs ; powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\rtl\tb\run_regress.ps1
#   这样回归不再往仓库根丢临时文件（tidy 规则）。在仓库根直接跑也照旧可用。
# 表项字段：n=测试名（= 顶层模块名，除非另给 m）f=源文件列表 d=额外编译参数
#           x=1 表示"预期失败"（A/B 对照：-DBLT_WR_ORDER_OFF 必须复现旧 bug）
$env:PATH = "C:\oss-cad-suite\bin;C:\oss-cad-suite\lib;$env:PATH"
$ErrorActionPreference = "Continue"
$IV  = (Get-Command iverilog).Source
$VVP = (Get-Command vvp).Source
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # rtl/tb -> rtl -> 仓库根
function RepoPath([string]$p) { return (Join-Path $root $p) }

$acc = @("rtl/sync_fifo.v","rtl/cmd_fifo.v","rtl/blt_regs_axi_lite.v","rtl/blt_addr_gen.v",
         "rtl/axi_rd_master.v","rtl/axi_wr_master.v","rtl/stream_reader.v","rtl/pixel_path.v",
         "rtl/blt_engine_fsm.v","ARC_2DRA/rtl/video/axi_wr_arb.v","rtl/clr_engine.v",
         "rtl/dl_fetch.v","rtl/blt_top.v")

$tests = @(
  @{n="tb_blt_top";       f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_top.v"))},
  @{n="tb_blt_apb";       f=(@("ARC_2DRA/rtl/blt/blt_apb_top.v") + $acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_apb.v"))},
  @{n="tb_cmd_fifo";      f=@("rtl/cmd_fifo.v","rtl/tb/tb_cmd_fifo.v")},
  @{n="tb_regs_axi_lite"; f=@("rtl/blt_regs_axi_lite.v","rtl/cmd_fifo.v","rtl/tb/tb_regs_axi_lite.v")},
  @{n="tb_blt_unalign";   f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_unalign.v"))},
  @{n="tb_fifo_full";     f=@("rtl/blt_regs_axi_lite.v","rtl/cmd_fifo.v","rtl/tb/tb_fifo_full.v")},
  @{n="tb_blt_burst";     f=(@("ARC_2DRA/rtl/blt/blt_apb_top.v") + $acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_burst.v"))},
  @{n="tb_alpha";         f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_alpha.v"))}
  # ★v2.8 像素打包乒乓的 A/B 对照项：-DPIXEL_PACK_PINGPONG_OFF 回到旧节拍（9 拍/词），
  #   位精确性必须与默认（8 拍/词）完全一致 ⇒ 这两项也**必须 PASS**（不是预期失败项）。
  @{n="tb_blt_unalign_off"; m="tb_blt_unalign"; d="-DPIXEL_PACK_PINGPONG_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_unalign.v"))}
  @{n="tb_alpha_off";       m="tb_alpha";       d="-DPIXEL_PACK_PINGPONG_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_alpha.v"))}
  # ★v2.10 命令末尾冲刷提示（cmd_end_flush）的 A/B 对照项：-DWR_CMD_END_FLUSH_OFF 关掉
  #   提示 ⇒ 尾突发仍等满 HOLD_MAX=16 拍（= v2.9 的 1,232 拍 / ENG_WDWAIT 63）。
  #   位精确性、AW→W→B 结构与写顺序必须与默认**完全一致** ⇒ 这三项也必须 PASS。
  @{n="tb_alpha_cmdtail_off";       m="tb_alpha";       d="-DWR_CMD_END_FLUSH_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_alpha.v"))}
  @{n="tb_blt_unalign_cmdtail_off"; m="tb_blt_unalign"; d="-DWR_CMD_END_FLUSH_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_unalign.v"))}
  @{n="tb_blt_burst_cmdtail_off";   m="tb_blt_burst";   d="-DWR_CMD_END_FLUSH_OFF"; f=(@("ARC_2DRA/rtl/blt/blt_apb_top.v") + $acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_burst.v"))}
  #   写提交顺序专项也要在"提示关掉"的模式下过（H1 完成时无未发写词 / H2 在飞突发 ≤1）。
  @{n="tb_wr_order_cmdtail_off";    m="tb_wr_order";    d="-DWR_CMD_END_FLUSH_OFF"; f=($acc + @("rtl/tb/axi_slave_mem_ord.v","rtl/tb/tb_wr_order.v"))}
  @{n="tb_arb_deadlock";  f=@("ARC_2DRA/rtl/video/axi_rd_arb.v","ARC_2DRA/rtl/video/axi_wr_arb.v","rtl/tb/tb_arb_deadlock.v")}
  @{n="tb_fb_scanout";    f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","ARC_2DRA/rtl/video/tb/tb_fb_scanout.v")}
  @{n="tb_scanout_scale"; f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","ARC_2DRA/rtl/video/tb/tb_scanout_scale.v")}
  @{n="tb_scanout_wd";    f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","ARC_2DRA/rtl/video/tb/tb_scanout_wd.v")}
  @{n="tb_axi_rd_arb";    f=@("ARC_2DRA/rtl/video/axi_rd_arb.v","ARC_2DRA/rtl/video/tb/tb_axi_rd_arb.v")}
  @{n="tb_rd_arb_leak";  f=@("ARC_2DRA/rtl/video/axi_rd_arb.v","ARC_2DRA/rtl/video/tb/tb_rd_arb_leak.v")}
  @{n="tb_wr_order";     f=($acc + @("rtl/tb/axi_slave_mem_ord.v","rtl/tb/tb_wr_order.v"))}
  @{n="tb_wr_order_off"; m="tb_wr_order"; x=1; d="-DBLT_WR_ORDER_OFF"; f=($acc + @("rtl/tb/axi_slave_mem_ord.v","rtl/tb/tb_wr_order.v"))}
  @{n="tb_scanout_flip"; f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","rtl/tb/tb_scanout_flip.v")}
  @{n="tb_scanout_flip_off"; m="tb_scanout_flip"; x=1; d="-DFLIP_UNLATCHED"; f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","rtl/tb/tb_scanout_flip.v")}
  # ★v2.7 并发清屏引擎：吞吐/AW 合并/内容/互斥/仲裁（含 -DCLEAR_MUTEX_OFF 的 A/B 对照项）
  @{n="tb_clear_engine";     f=@("rtl/clr_engine.v","ARC_2DRA/rtl/video/axi_wr_arb.v","rtl/tb/tb_clear_engine.v")}
  @{n="tb_clear_engine_off"; m="tb_clear_engine"; x=1; d="-DCLEAR_MUTEX_OFF"; f=@("rtl/clr_engine.v","ARC_2DRA/rtl/video/axi_wr_arb.v","rtl/tb/tb_clear_engine.v")}
  # ★v2.11 显示列表（S2）：主测试台 + 畸形列表保护 + A/B 逃生门（-DDL_OFF）
  #   `tb_dl_basic_off` / `tb_blt_top_dloff` / `tb_wr_order_dloff` 都是**必须 PASS**
  #   的 A/B 项：-DDL_OFF 把 DFU 整体旁路 ⇒ 列表路径零活动、老路径读数逐位一致。
  @{n="tb_dl_basic";      f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_basic.v"))}
  @{n="tb_dl_basic_off";  m="tb_dl_basic"; d="-DDL_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_basic.v"))}
  # ★v2.13 显示列表"固件真实描述符"专项：把 FinalDemo.c 的 dl_build()/dl_geom_build()
  #   原样输出（FILL/ALPHA/KEY × 16/32、贴边位置 + 整片重铺）逐字节喂进真实 RTL，
  #   比命令字 + 比像素；并复现"只有精灵条目会踩"的两类失败签名（几何表内容错/读不到
  #   ⇒ ZERO_SIZE；GEOM_MAX 写被 BUSY 丢掉 ⇒ GEOM_INDEX，而 FILL+SIZE_OVR 不受影响）。
  #   自带伪 DDR 模型（dl_demo_mem，寄存器读），不需要 axi_slave_mem.v。
  @{n="tb_dl_demo";       f=($acc + @("rtl/tb/tb_dl_demo.v"))}
  @{n="tb_dl_malformed";  f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_malformed.v"))}
  @{n="tb_blt_top_dloff"; m="tb_blt_top";  d="-DDL_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_top.v"))}
  @{n="tb_wr_order_dloff";m="tb_wr_order"; d="-DDL_OFF"; f=($acc + @("rtl/tb/axi_slave_mem_ord.v","rtl/tb/tb_wr_order.v"))}
  # ★v2.12（S3）透明块跳过（KEY + 4×4 块掩码）：位精确 / 非 KEY 必须忽略掩码 /
  #   真省了多少（DL_PERF、读 beat、写词）/ MASK_MODE 编码检查。
  #   `tb_dl_mask_off` 是 -DMASK_SKIP_OFF 的 A/B 逃生门：掩码位被强行清零 ⇒
  #   所有"带掩码"的用例必须与"无掩码"逐位同拍，本项**必须 PASS**。
  @{n="tb_dl_mask";     f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_mask.v"))}
  @{n="tb_dl_mask_off"; m="tb_dl_mask"; d="-DMASK_SKIP_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_mask.v"))}
  # ★v2.12 三流读仲裁共存（S2 最大未验证风险）：fg/bg/desc（axi_rd_master 内部）
  #   + CPU/扫描输出（axi_rd_arb 两级）同时压 DDR。独立 DUT，不走 $acc。
  @{n="tb_dl_arb";      f=@("rtl/axi_rd_master.v","ARC_2DRA/rtl/video/axi_rd_arb.v","rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_arb.v")}
  # ★v3.1 双 lane（2 px/拍）像素通路：单元级「位精确 + 背压」台（真 sync_fifo 当源，
  #   TB 自己做写侧从机 ⇒ 可以把 wd FIFO 任意逼满：深满+慢排空 / 每 N 拍只收 1 词）。
  #   `tb_px_path_off` / `tb_blt_unalign_px2off` / `tb_alpha_px2off` / `tb_dl_basic_px2off`
  #   都是 -DPIXEL_PIXELS2_OFF 的 A/B 逃生门：逐字回到 v2.8 单 lane 行为，
  #   位精确性与背压结果必须与默认**完全一致** ⇒ 这四项也必须 PASS。
  @{n="tb_px_path";           f=@("rtl/sync_fifo.v","rtl/stream_reader.v","rtl/pixel_path.v","rtl/tb/tb_px_path.v")}
  @{n="tb_px_path_off";       m="tb_px_path"; d="-DPIXEL_PIXELS2_OFF"; f=@("rtl/sync_fifo.v","rtl/stream_reader.v","rtl/pixel_path.v","rtl/tb/tb_px_path.v")}
  @{n="tb_blt_unalign_px2off";m="tb_blt_unalign"; d="-DPIXEL_PIXELS2_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_blt_unalign.v"))}
  @{n="tb_alpha_px2off";      m="tb_alpha"; d="-DPIXEL_PIXELS2_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_alpha.v"))}
  @{n="tb_dl_basic_px2off";   m="tb_dl_basic"; d="-DPIXEL_PIXELS2_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_dl_basic.v"))}
  # ★v3.2（S5）属性侧口 / scissor / 扫描输出颜色 LUT：
  #   tb_attr_blend  = 0x8C 属性字与命令**按序配对**、逐像素 alpha（ARGB1555/ARGB4444）、
  #                    alpha/加算/乘法三种混合、alpha 测试与 force-opaque、空 FIFO 默认字
  #                    兼容档；内含 **7 条手算期望值**（L1~L6）与逐位模型互校。
  #   tb_scissor     = 0x90~0xA0 裁剪矩形：关闭即逐位兼容、半开区间边界、整行/整列/整体
  #                    在外、非对齐 dst、命令起始锁存（中途改寄存器不撕裂本命令）。
  #   tb_scanout_lut = 0xA4~0xB0 扫描输出颜色 LUT：关闭/恒等表=逐像素等于老输出、
  #                    非平凡表映射正确、bank 切换只在帧边界（整场同表）、写另一个 bank
  #                    期间屏幕零变化（逐像素监视）、LUT_STAT 回读一致。
  #   三个 `_off` 项分别是 -DATTR_PORT_OFF / -DSCISSOR_OFF / -DLUT_OFF 的 A/B 逃生门：
  #   关掉新功能后**同一份 TB 的期望值换成兼容支**，必须同样 ALL PASS。
  #   `tb_px_path_blendoff` 是 -DBLEND_OFF（把混合数据通路整体编掉）的等价性证据。
  @{n="tb_attr_blend";      f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_attr_blend.v"))}
  @{n="tb_attr_blend_off";  m="tb_attr_blend"; d="-DATTR_PORT_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_attr_blend.v"))}
  @{n="tb_scissor";         f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_scissor.v"))}
  @{n="tb_scissor_off";     m="tb_scissor";    d="-DSCISSOR_OFF"; f=($acc + @("rtl/tb/axi_slave_mem.v","rtl/tb/tb_scissor.v"))}
  @{n="tb_scanout_lut";     f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","rtl/tb/tb_scanout_lut.v")}
  @{n="tb_scanout_lut_off"; m="tb_scanout_lut"; d="-DLUT_OFF"; f=@("ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","rtl/tb/tb_scanout_lut.v")}
  # ★v3.2 端到端「LUT 真实链路 + AdDemo 四步发布协议」台：把 blt_regs_axi_lite 与
  #   fb_scanout 接成板上的接法（AXI-Lite 0xA4/0xA8/0xAC → 写脉冲 → LUT RAM → 屏幕 → 0xB0），
  #   逐轮回放 AdDemo.c 的 LUT_BANK 协议，断言 T1 像素真的变 / T2 写表期间整场零变化 /
  #   T3 0xB0 与像素一致 / T4 恒等表 + 使能 = 关 LUT。既有 tb_scanout_lut（只戳单元端口）
  #   与 tb_regs_axi_lite（0xB0 钉 0）之间那段真实连线，只有这一项在跑。
  #   ★ 首次运行即抓到 T4 不成立（fb_scanout.v:856-858 旁路展开取字段低位 vs 841-846
  #     LUT 输出级复制字段高位，与 rtl/pixel_path.v:182-190 的口径不一致）——
  #     这是**真实的 RTL/文档不符**，不是回归：修 RTL 前本项会一直红。
  @{n="tb_lut_proto";       f=@("rtl/blt_regs_axi_lite.v","rtl/cmd_fifo.v","ARC_2DRA/rtl/video/fb_scanout.v","ARC_2DRA/rtl/video/video_timing_1080p.v","ARC_2DRA/rtl/common/simple_dual_port_ram.v","rtl/tb/tb_lut_proto.v")}
  @{n="tb_px_path_blendoff";m="tb_px_path";    d="-DBLEND_OFF"; f=@("rtl/sync_fifo.v","rtl/stream_reader.v","rtl/pixel_path.v","rtl/tb/tb_px_path.v")}
)

$fail = 0
foreach ($t in $tests) {
  $n = $t.n
  $mod = $n
  if ($t.m) { $mod = $t.m }
  $tbfile = ($t.f | Where-Object { $_ -match ('/' + $mod + '\.v$') } | Select-Object -First 1)
  if (-not $tbfile) { $tbfile = "rtl/tb/$mod.v" }
  if (-not (Test-Path (RepoPath $tbfile))) { Write-Host ("{0,-18} SKIP (no tb)" -f $n); continue }
  $out = "sim_" + $n + ".vvp"
  $log = "log_" + $n + ".txt"
  $src = @($t.f | ForEach-Object { RepoPath $_ })
  $defs = @()
  if ($t.d) { $defs = @($t.d) }
  & $IV -g2001 @defs -s $mod -o $out @src 2>&1 | Out-File -Encoding utf8 ("compile_" + $n + ".txt")
  if ($LASTEXITCODE -ne 0) { Write-Host ("{0,-18} COMPILE FAIL" -f $n); $fail++; continue }
  & $VVP $out > $log 2>&1
  $verdict = (Select-String -Path $log -Pattern "ALL PASS|FAILED" | Select-Object -Last 1).Line
  $nfail   = (Select-String -Path $log -Pattern "^FAIL:").Count
  if ($t.x) {
    # A/B 对照项：必须**失败**才算对（证明关掉屏障后旧 bug 复现）
    if ($verdict -match "FAILED") {
      Write-Host ("{0,-18} A/B OK: 屏障 OFF → {1}" -f $n, $verdict)
    } else {
      Write-Host ("{0,-18} A/B BAD: 屏障 OFF 却没复现 bug → {1}" -f $n, $verdict)
      $fail++
    }
    continue
  }
  Write-Host ("{0,-18} {1}   (FAIL 行数={2})" -f $n, $verdict, $nfail)
  if ($verdict -notmatch "ALL PASS") { $fail++ }
}
Write-Host ("==== regress failures: {0} ====" -f $fail)
