# AdDemo 主机自检（第 1 步）：把 AdDemo.c 里 ==== NAME_BEGIN/END ==== 标记之间的源码
# **原样**摘出来，生成 sections.h 给 check.c 编译用。
#
# 用法（在任意目录）：
#   pwsh -File tools/host_selfcheck/extract.ps1        # 默认取 AdDemo/src/AdDemo.c
#   pwsh -File tools/host_selfcheck/extract.ps1 -Src <AdDemo.c> -Out <sections.h>
# 若被执行策略挡住： powershell -ExecutionPolicy Bypass -File tools\host_selfcheck\extract.ps1
#
# ★ 段名列表必须与 AdDemo.c 里的标记一一对应：漏一个段 ⇒ check.c 里引用该段符号的用例
#   会以 "undeclared" 编译失败（CONTENT_RECT 就这样漏过一次，见 2026-09-16 记录）。
param(
  [string]$Src = "$PSScriptRoot\..\..\ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\AdDemo\src\AdDemo.c",
  [string]$Out = "$PSScriptRoot\sections.h"
)
$ErrorActionPreference = 'Stop'
$sections = @('ATTR_ENC','ARGB4444','LUT_TAB','FONT_TABLE','ATLAS_GEN','SCENE_BOUNDS',
              'OSD_FMT','CLIP_GUARD','EMIT','CLIP_XLATE','DECOR_RECT','CONTENT_RECT',
              'CLIP_IO','LUT_BANK','ST_TIMEOUT')
$lines = [System.IO.File]::ReadAllLines($Src)          # 原样按 \n 切行（UTF-8 无 BOM）
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* 由 extract.ps1 从 AdDemo.c 原样摘出的源码段（注释里的行号 = AdDemo.c 行号） */")
foreach ($s in $sections) {
    $bPat = "==== ${s}_BEGIN ===="
    $ePat = "==== ${s}_END ===="
    $b = -1; $e = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($b -lt 0 -and $lines[$i].Contains($bPat)) { $b = $i }
        elseif ($b -ge 0 -and $e -lt 0 -and $lines[$i].Contains($ePat)) { $e = $i; break }
    }
    if ($b -lt 0 -or $e -lt 0) { throw "section not found: $s (begin=$b end=$e)" }
    # BEGIN 标记在注释块里：跳过注释，代码从第一个含 */ 的行的下一行开始
    $codeStart = $b
    while ($codeStart -lt $e -and -not $lines[$codeStart].Contains('*/')) { $codeStart++ }
    $codeStart++
    if ($codeStart -ge $e) { throw "empty section: $s" }
    [void]$sb.AppendLine("/* ---- $s : AdDemo.c lines $($codeStart+1)..$e ---- */")
    for ($i = $codeStart; $i -lt $e; $i++) { [void]$sb.AppendLine($lines[$i]) }
    Write-Host ("  {0,-14} AdDemo.c lines {1}..{2}" -f $s, ($codeStart+1), $e)
}
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "wrote $Out"
