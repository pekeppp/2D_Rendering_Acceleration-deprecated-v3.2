# =============================================================================
# make_soc_image.ps1 -- build an Efinity-compatible "FPGA Soc Image" .hex
# -----------------------------------------------------------------------------
# Equivalent of: Efinity Programmer -> "Combine Multiple Image Files"
#                -> Mode: Generic Image Combination
#                    Bitstream  (raw hex)  @ 0x00000000
#                    App binary (.bin)     @ 0x00380000
#
# Format reverse-engineered from the images this repo already produced
# (outflow\*.hex + their Efinity Programming Tool Generation Reports):
#
#   file byte k  ==  flash byte k
#     [0x000000 .. 0x0000FF]  256-byte ASCII preamble carried over verbatim from
#                             the bitstream .hex (Version/Generated/Project/
#                             Family/Device/Width/Mode/Die Name/... \n-padded)
#     [0x000100 ..           ]  bitstream payload (the bitstream .hex minus its
#                             own 256-byte preamble)
#     [ .. 0x37FFFF]           0xFF filler up to the application slot
#     [0x380000 ..           ]  application .bin, as produced by the RISC-V IDE
#
#   encoding: every byte is written as 2 uppercase hex chars + LF (3 bytes/byte)
#
# The addresses match the SoC bootloader (standalone\bootloader\src\
# bootloaderConfig.h): USER_SOFTWARE_FLASH 0x00380000 -> USER_SOFTWARE_MEMORY
# 0x00001000, USER_SOFTWARE_SIZE 0x01F000 (124 KB copy window).
#
# Usage (repo root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\make_soc_image.ps1 `
#       -BitstreamHex firmware\v3.2\ddr_demo_ti60_v3.2.hex `
#       -AppBin       firmware\v3.2\AdDemo_v3.2.bin `
#       -Out          firmware\v3.2\AdDemo_v3.2_soc.hex
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BitstreamHex,
    [Parameter(Mandatory = $true)][string]$AppBin,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$AppFlashAddr = 0x380000,
    [int]$BootloaderMaxBytes = 0x1F000
)

$ErrorActionPreference = 'Stop'

function Read-EfxHex {
    param([string]$Path)
    $text = [System.IO.File]::ReadAllText($Path)
    $hex  = $text.Replace("`r", "").Replace("`n", "")
    if ($hex.Length % 2 -ne 0) { throw "hex text length is odd: $($hex.Length)" }
    if ($hex -notmatch '^[0-9A-Fa-f]*$') { throw "non-hex character found in $Path" }
    return [System.Runtime.Remoting.Metadata.W3cXsd2001.SoapHexBinary]::Parse($hex).Value
}

function Write-EfxHex {
    param([byte[]]$Bytes, [string]$Path)
    $sw = New-Object System.IO.StreamWriter($Path, $false, [System.Text.Encoding]::ASCII)
    try {
        $chunk = 1MB
        for ($i = 0; $i -lt $Bytes.Length; $i += $chunk) {
            $n = [Math]::Min($chunk, $Bytes.Length - $i)
            $part = New-Object byte[] $n
            [Array]::Copy($Bytes, $i, $part, 0, $n)
            # "AA-BB-CC" -> "AA\nBB\nCC"
            $sw.Write([System.BitConverter]::ToString($part).Replace('-', "`n"))
            $sw.Write("`n")
        }
    } finally { $sw.Close() }
}

function Compare-Segment {
    param([byte[]]$A, [int]$AOff, [byte[]]$B, [int]$BOff, [int]$Len, [string]$Label)
    $diff = 0
    $firstBad = -1
    for ($i = 0; $i -lt $Len; $i++) {
        if ($A[$AOff + $i] -ne $B[$BOff + $i]) {
            $diff++
            if ($firstBad -lt 0) { $firstBad = $i }
            if ($diff -gt 4096) { break }
        }
    }
    if ($diff -eq 0) { Write-Host ("  OK   {0}: {1} bytes identical" -f $Label, $Len) }
    else             { Write-Host ("  FAIL {0}: {1}+ differing bytes, first at +0x{2:X}" -f $Label, $diff, $firstBad) }
    return ($diff -eq 0)
}

# ---------------------------------------------------------------- inputs -----
Write-Host "bitstream : $BitstreamHex"
Write-Host "app       : $AppBin"
Write-Host "output    : $Out"
Write-Host ""

$bsRaw = Read-EfxHex -Path $BitstreamHex
if ($bsRaw.Length -le 256) { throw "bitstream hex too short ($($bsRaw.Length) bytes)" }
$preamble = New-Object byte[] 256
[Array]::Copy($bsRaw, 0, $preamble, 0, 256)
$payload  = New-Object byte[] ($bsRaw.Length - 256)
[Array]::Copy($bsRaw, 256, $payload, 0, $payload.Length)
$app      = [System.IO.File]::ReadAllBytes($AppBin)

Write-Host ("bitstream preamble : 256 bytes")
Write-Host ("bitstream payload  : {0} bytes (0x{0:X})" -f $payload.Length)
Write-Host ("app binary         : {0} bytes (0x{0:X})" -f $app.Length)
Write-Host ""

if ($app.Length -gt $BootloaderMaxBytes) {
    throw ("app is {0} bytes but the bootloader only copies 0x{1:X} ({1}) bytes; grow " +
           "USER_SOFTWARE_SIZE and rebuild the bootloader first" -f $app.Length, $BootloaderMaxBytes)
}
$bsEnd = 0x100 + $payload.Length
if ($bsEnd -ge $AppFlashAddr) {
    throw ("bitstream payload ends at 0x{0:X}, past the app slot 0x{1:X} -- it does not fit" -f $bsEnd, $AppFlashAddr)
}

# ---------------------------------------------------------------- build ------
$padLen = $AppFlashAddr - $bsEnd
$total  = $AppFlashAddr + $app.Length
Write-Host ("layout : preamble 0x000000-0x0000FF | bitstream 0x000100-0x" + ('{0:X}' -f ($bsEnd - 1)) +
            " | 0xFF fill 0x" + ('{0:X}' -f $bsEnd) + "-0x" + ('{0:X}' -f ($AppFlashAddr - 1)) +
            " | app 0x" + ('{0:X}' -f $AppFlashAddr) + "-0x" + ('{0:X}' -f ($total - 1)))
Write-Host ("total  : {0} bytes (0x{1:X})  ->  about {2:N1} MB as hex text" -f `
            $total, $total, ($total * 3 / 1MB))
Write-Host ""

$img = New-Object byte[] $total
[Array]::Copy($preamble, 0, $img, 0, 256)
[Array]::Copy($payload,  0, $img, 256, $payload.Length)
for ($i = $bsEnd; $i -lt $AppFlashAddr; $i++) { $img[$i] = 0xFF }
[Array]::Copy($app, 0, $img, $AppFlashAddr, $app.Length)

Write-EfxHex -Bytes $img -Path $Out
Write-Host ("written: {0} ({1} bytes on disk)" -f $Out, (Get-Item $Out).Length)
Write-Host ""

# ---------------------------------------------------------------- verify -----
Write-Host "verify (re-reading the file we just wrote):"
$back = Read-EfxHex -Path $Out
$ok = $true
if ($back.Length -ne $total) { Write-Host ("  FAIL length: {0} != {1}" -f $back.Length, $total); $ok = $false }
else { Write-Host ("  OK   length: {0} bytes" -f $back.Length) }
$ok = (Compare-Segment -A $back -AOff 0 -B $img -BOff 0 -Len 256 -Label "preamble") -and $ok
$ok = (Compare-Segment -A $back -AOff 0x100 -B $payload -BOff 0 -Len $payload.Length -Label "bitstream segment") -and $ok
$ok = (Compare-Segment -A $back -AOff $AppFlashAddr -B $app -BOff 0 -Len $app.Length -Label "app segment") -and $ok
$nz = 0
for ($i = $bsEnd; $i -lt $AppFlashAddr; $i++) { if ($back[$i] -ne 0xFF) { $nz++ } }
if ($nz -eq 0) { Write-Host ("  OK   filler 0x{0:X}-0x{1:X} is all 0xFF" -f $bsEnd, ($AppFlashAddr - 1)) }
else           { Write-Host ("  FAIL filler has {0} non-0xFF bytes" -f $nz); $ok = $false }

Write-Host ""
if ($ok) {
    Write-Host "RESULT: OK -- burn this file with Efinity Programmer, Programming Mode = SPI Active,"
    Write-Host "        then power-cycle the board."
} else {
    Write-Host "RESULT: FAILED -- do not burn this file."
    exit 1
}
