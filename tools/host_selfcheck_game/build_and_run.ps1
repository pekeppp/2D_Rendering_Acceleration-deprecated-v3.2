# =============================================================================
# build_and_run.ps1 -- GameDemo host self-check: build + run on QEMU + archive log
# -----------------------------------------------------------------------------
# NOTE: this file is intentionally ASCII-only. Windows PowerShell 5.1 reads
#       BOM-less .ps1 as ANSI, so non-ASCII text here would be mangled (see the
#       "UTF-8 source only through an editor" lesson in doc/).
#
# Usage (from anywhere):
#     powershell -ExecutionPolicy Bypass -File tools\host_selfcheck_game\build_and_run.ps1
#
# What it does:
#   1) Builds sim/sim_main.c into a bare-metal RV32 ELF with the RISC-V GCC that
#      ships with the Efinity RISC-V IDE. sim_main.c **#includes the firmware
#      source verbatim** (src/GameDemo.c) and overrides only the three base
#      addresses, so the code under test is byte-for-byte the code that gets
#      flashed on the board.
#   2) Runs it under qemu-system-riscv32 (also shipped with the IDE).
#   3) Writes the full transcript to doc\logs\host_selfcheck_GameDemo.txt and
#      checks the final "N passed / M failed" line.
#
# Exit code: 0 = all passed; 1 = failures; 2 = build/run environment problem.
# =============================================================================
$ErrorActionPreference = 'Continue'
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = (Resolve-Path (Join-Path $here '..\..')).Path
$fw     = Join-Path $root 'ARC_2DRA\par\ddr_demo_ti60\embedded_sw\soc\software\standalone\GameDemo\src\GameDemo.c'
$fwdir  = Split-Path -Parent $fw
$sim    = Join-Path $here 'sim\sim_main.c'
$ld     = Join-Path $here 'sim\link.ld'
$start  = Join-Path $here 'sim\start.S'
$logdir = Join-Path $root 'doc\logs'
$log    = Join-Path $logdir 'host_selfcheck_GameDemo.txt'
$elf    = Join-Path $env:TEMP 'gamedemo_sim.elf'

$tc   = 'C:\Efinity\efinity-riscv-ide-2026.1\toolchain\bin'
$qemu = 'C:\Efinity\efinity-riscv-ide-2026.1\qemu\qemu-system-riscv32.exe'
if (-not (Test-Path (Join-Path $tc 'riscv-none-elf-gcc.exe'))) { Write-Host "RISC-V toolchain not found: $tc"; exit 2 }
if (-not (Test-Path $qemu))                                    { Write-Host "QEMU not found: $qemu"; exit 2 }
if (-not (Test-Path $fw))                                      { Write-Host "firmware source not found: $fw"; exit 2 }

# ---- build ------------------------------------------------------------------
# Only DDR_BASE / BLT_BASE / UART_TERM are overridden (see the #ifndef guards in
# GameDemo.c). Everything else -- framebuffer layout, atlas, engine registers --
# keeps its board address, just relocated relative to DDR_BASE.
$cflags = @(
    '-march=rv32im', '-mabi=ilp32', '-Os', '-std=gnu99', '-Wall', '-Wextra',
    '-Wno-unused-parameter', '-ffreestanding', '-nostdlib', '-nostartfiles',
    '-msmall-data-limit=0', '-Wl,--no-relax',
    '-DDDR_BASE=0x81000000UL', '-DBLT_BASE=0x82000000UL', '-DUART_TERM=0x82100000UL',
    "-I$here\sim", "-I$fwdir", '-T', $ld, '-o', $elf, $start, $sim,
    '-lgcc', '-Wl,--no-warn-rwx-segment', '-Wl,--no-relax'
)
Write-Host "CC  sim_main.c (includes GameDemo.c verbatim)"
$build = & (Join-Path $tc 'riscv-none-elf-gcc.exe') @cflags 2>&1
$buildTxt = ($build | Out-String)
if ($LASTEXITCODE -ne 0) { Write-Host $buildTxt; Write-Host "BUILD FAILED"; exit 2 }
$myWarn = $build | Select-String -Pattern 'sim_main\.c|GameDemo\.c' | Select-String -Pattern 'warning|error'
if ($myWarn) {
    Write-Host "warnings/errors in our own sources:"
    $myWarn | ForEach-Object { Write-Host $_ }
    exit 2
}
if ($buildTxt.Trim().Length -gt 0) { Write-Host $buildTxt.Trim() }

New-Item -ItemType Directory -Force -Path $logdir | Out-Null

# ---- run --------------------------------------------------------------------
# -bios loads our ELF directly; the program writes the SiFive test device at the
# end, which makes QEMU exit by itself (no timeout needed).
Write-Host "RUN qemu-system-riscv32 (bare-metal, no OS)"
$run = & $qemu -machine virt -m 128M -nographic -bios $elf 2>&1
$txt = ($run | Out-String)
Write-Host $txt
Set-Content -Path $log -Value $txt -Encoding UTF8

$last = ($txt -split "`n" | Where-Object { $_ -match 'GameDemo host self-check:' } | Select-Object -Last 1)
if (-not $last) { Write-Host "no summary line found (hang or timeout?)"; exit 1 }
if ($last -match '(\d+) passed / (\d+) failed') {
    $p = [int]$Matches[1]; $f = [int]$Matches[2]
    Write-Host ("RESULT: {0} passed / {1} failed  (log: {2})" -f $p, $f, $log)
    if ($f -ne 0) { exit 1 }
    exit 0
}
Write-Host "could not parse summary line: $last"
exit 1
