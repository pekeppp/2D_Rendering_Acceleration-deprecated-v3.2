# convert_rgb565.ps1 -- convert PNG/JPG/BMP into the RGB565 format the accelerator uses
#
# Usage (from the repo root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File atlas\convert_rgb565.ps1 `
#       -In atlas\my.png -Out atlas\my [-Key] [-Pad64] [-FlipY]
#
# Outputs:
#   <Out>.raw  -- raw RGB565 little-endian pixels (route B: store in flash, copy to DDR at run time)
#   <Out>.h    -- C array (route A: small images only, see atlas/README.md for the size limit)
#
# Pixel format (identical to the framebuffer / what the engine reads):
#   per pixel 16 bit little-endian:  byte0 = G[2:0]<<5 | B[4:0]
#                                    byte1 = R[4:0]<<3 | G[5:3]
#   RGB888 -> RGB565:  R>>3, G>>2, B>>3
param(
    [Parameter(Mandatory=$true)][string]$In,
    [Parameter(Mandatory=$true)][string]$Out,
    [switch]$Key,      # fully transparent pixels (alpha<128) -> key colour 0xF81F
    [switch]$Pad64,    # pad each row to a multiple of 64 bytes
    [switch]$FlipY     # flip vertically
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $In)) { Write-Error "source image not found: $In"; exit 1 }

$img = [System.Drawing.Image]::FromFile((Resolve-Path $In).Path)
$bmp = [System.Drawing.Bitmap]::new($img)
[int]$W = $bmp.Width
[int]$H = $bmp.Height

[int]$stridePx = $W
if ($Pad64) { $stridePx = [int]([math]::Ceiling(($W * 2) / 64.0) * 32) }   # 32px == 64B
[int]$strideB = $stridePx * 2

Write-Host ("src {0}  {1}x{2} -> stride {3}px ({4} bytes)" -f (Split-Path $In -Leaf), $W, $H, $stridePx, $strideB)

$KEY565 = 0xF81F
$buf = [byte[]]::new($strideB * $H)

$rect = [System.Drawing.Rectangle]::new(0, 0, $W, $H)
$mode = [System.Drawing.Imaging.ImageLockMode]::ReadOnly
$pfmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
$data = $bmp.LockBits($rect, $mode, $pfmt)

[int]$rowBytes = $data.Stride
$all = [byte[]]::new($rowBytes * $H)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $all, 0, $all.Length)
$bmp.UnlockBits($data)

for ($y = 0; $y -lt $H; $y++) {
    $sy = $y
    if ($FlipY) { $sy = $H - 1 - $y }
    $srcRow = $sy * $rowBytes
    $dstRow = $y  * $strideB
    for ($x = 0; $x -lt $W; $x++) {
        $o = $srcRow + $x * 4
        $bb = [int]$all[$o]
        $gg = [int]$all[$o + 1]
        $rr = [int]$all[$o + 2]
        $aa = [int]$all[$o + 3]
        if ($Key -and ($aa -lt 128)) {
            $px = $KEY565
        } else {
            $px = ((($rr -shr 3) -band 0x1F) -shl 11) -bor ((($gg -shr 2) -band 0x3F) -shl 5) -bor (($bb -shr 3) -band 0x1F)
        }
        $d = $dstRow + $x * 2
        $buf[$d]     = [byte]($px -band 0xFF)          # little-endian: low byte first
        $buf[$d + 1] = [byte](($px -shr 8) -band 0xFF)
    }
    for ($x = $W; $x -lt $stridePx; $x++) {            # padding -> key colour
        $d = $dstRow + $x * 2
        $buf[$d]     = [byte]($KEY565 -band 0xFF)
        $buf[$d + 1] = [byte](($KEY565 -shr 8) -band 0xFF)
    }
}

$rawPath = "$Out.raw"
[System.IO.File]::WriteAllBytes($rawPath, $buf)
Write-Host ("wrote {0}  ({1} bytes, RGB565 little-endian)" -f $rawPath, $buf.Length)

$name = ([System.IO.Path]::GetFileName($Out) -replace '[^A-Za-z0-9_]', '_').ToUpper()
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("/* auto-generated from $In : ${W}x${H} RGB565 little-endian, stride=${stridePx}px */")
[void]$sb.AppendLine("#define ${name}_W        $W")
[void]$sb.AppendLine("#define ${name}_H        $H")
[void]$sb.AppendLine("#define ${name}_STRIDE   $strideB")
[void]$sb.AppendLine("static const unsigned short ${name}[${H} * ${stridePx}] = {")
for ($y = 0; $y -lt $H; $y++) {
    $line = "    "
    for ($x = 0; $x -lt $stridePx; $x++) {
        $d = $y * $strideB + $x * 2
        $v = [int]$buf[$d] -bor ([int]$buf[$d + 1] -shl 8)
        $line += ("0x{0:X4}," -f $v)
        if ($line.Length -gt 96) { [void]$sb.AppendLine($line); $line = "    " }
    }
    if ($line.Trim().Length -gt 0) { [void]$sb.AppendLine($line) }
}
[void]$sb.AppendLine("};")
$hPath = "$Out.h"
[System.IO.File]::WriteAllText($hPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("wrote {0}  (C array -- small images only; big images use flash + spiFlash_f2m)" -f $hPath)

$bmp.Dispose()
$img.Dispose()
