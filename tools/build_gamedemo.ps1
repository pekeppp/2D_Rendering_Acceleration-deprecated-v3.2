# =============================================================================
# build_gamedemo.ps1 -- one-command pipeline for the GameDemo firmware
# -----------------------------------------------------------------------------
# NOTE: ASCII-only on purpose (Windows PowerShell 5.1 reads BOM-less .ps1 as ANSI).
#
# Usage (from anywhere):
#     powershell -ExecutionPolicy Bypass -File tools\build_gamedemo.ps1
#
# Steps:
#   1) make the firmware           -> .../standalone/GameDemo/build/GameDemo.hex|.bin|.elf|.map
#   2) host self-check (QEMU)      -> doc/logs/host_selfcheck_GameDemo.txt
#   3) console protocol self-test  -> doc/logs/game_console_selftest.txt
#   4) bitstream+app combined image-> firmware/v3.2/GameDemo_v3.2_soc.hex
#
# Exit code 0 = everything green.
# =============================================================================
$ErrorActionPreference = 'Continue'

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$root  = (Resolve-Path (Join-Path $here '..')).Path
$proj  = Join-Path $root 'ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\GameDemo'
$tc    = 'C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin'
$gitbin= 'C:\Program Files\Git\usr\bin'          # provides mkdir/rm for the makefiles
$logs  = Join-Path $root 'doc\logs'
$fail  = 0

New-Item -ItemType Directory -Force -Path $logs | Out-Null

# ---------------------------------------------------------------- 1) firmware
Write-Host "`n=== [1/4] build firmware (make) ===" -ForegroundColor Cyan
if (-not (Test-Path (Join-Path $tc 'riscv-none-elf-gcc.exe'))) {
    Write-Host "RISC-V toolchain not found: $tc"; exit 2
}
# The stock makefiles call `mkdir -p` / `rm -rf`; GNU make on Windows runs them
# through cmd.exe where those are not executables, so put Git's coreutils first.
$env:PATH = "$gitbin;$tc;" + $env:PATH
$mk = & make -C $proj BSP=efinix/EfxSapphireSoc "RISCV_BIN=$tc/riscv-none-elf-" 2>&1
$mkTxt = ($mk | Out-String)
Write-Host $mkTxt
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $proj 'build\GameDemo.hex'))) {
    Write-Host "FIRMWARE BUILD FAILED"; exit 2
}
$hex = Join-Path $proj 'build\GameDemo.hex'
$bin = Join-Path $proj 'build\GameDemo.bin'
Write-Host ("    OK  {0}  ({1} bytes)" -f $hex, (Get-Item $hex).Length)

# ------------------------------------------------------- 2) host self-check
Write-Host "`n=== [2/4] host self-check (QEMU riscv32, real firmware + mock engine) ===" -ForegroundColor Cyan
& powershell -ExecutionPolicy Bypass -File (Join-Path $here 'host_selfcheck_game\build_and_run.ps1') 2>&1 |
    Out-String -Width 200 | Write-Host
if ($LASTEXITCODE -ne 0) { Write-Host "HOST SELF-CHECK FAILED"; $fail = 1 }

# --------------------------------------------------- 3) console protocol test
Write-Host "`n=== [3/4] game_console protocol self-test (Node) ===" -ForegroundColor Cyan
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "    (skipped: node not found)"
} else {
    $acc = ''
    # Run both pages: game_console.html (34 checks) and game_console1.html
    # (same 34 plus group [7] for the enemy-bullet display-mode switch).
    # NOTE: keep this file ASCII-only -- PowerShell 5.1 reads BOM-less .ps1 as ANSI.
    foreach ($page in @('game_console.html', 'game_console1.html')) {
        $p = Join-Path $here $page
        if (-not (Test-Path $p)) { Write-Host "    (skip missing $page)"; continue }
        $out = & node (Join-Path $here 'game_console_selftest.js') $p 2>&1
        $txt = ($out | Out-String)
        Write-Host $txt
        $acc += $txt + "`r`n"
        if ($LASTEXITCODE -ne 0) { Write-Host "CONSOLE SELF-TEST FAILED ($page)"; $fail = 1 }
    }
    Set-Content -Path (Join-Path $logs 'game_console_selftest.txt') -Value $acc -Encoding UTF8
}

# ------------------------------------------------------ 4) combined SOC image
Write-Host "`n=== [4/4] bitstream + app combined image ===" -ForegroundColor Cyan
$bitHex = Join-Path $root 'firmware\v3.2\ddr_demo_ti60_v3.2.hex'
$outHex = Join-Path $root 'firmware\v3.2\GameDemo_v3.2_soc.hex'
if (-not (Test-Path $bitHex)) {
    Write-Host "    (skipped: bitstream hex not found at $bitHex)"
} else {
    & powershell -ExecutionPolicy Bypass -File (Join-Path $here 'make_soc_image.ps1') `
        -BitstreamHex $bitHex -AppBin $bin -Out $outHex 2>&1 | Out-String -Width 200 | Write-Host
    if ($LASTEXITCODE -ne 0) { Write-Host "SOC IMAGE FAILED"; $fail = 1 }
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "ALL GREEN." -ForegroundColor Green
    Write-Host "  firmware : $hex"
    Write-Host "  image    : $outHex   (Efinity Programmer, SPI Active, then power-cycle)"
    Write-Host "  console  : tools\game_console.html  +  tools\game_console1.html (bullet-op switch)"
    Write-Host "  logs     : $logs"
    exit 0
} else {
    Write-Host "SOMETHING FAILED (see above)." -ForegroundColor Red
    exit 1
}
