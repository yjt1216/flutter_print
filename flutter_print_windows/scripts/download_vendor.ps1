# Downloads PDFium Windows binaries into windows/vendor/ for offline builds.
# Safe to re-run; skips files that already match the expected SHA256.

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$VendorWindows = Join-Path (Join-Path $Root "windows") "vendor"

$X64Dir = Join-Path $VendorWindows "x86_64"
$Arm64Dir = Join-Path $VendorWindows "aarch64"

foreach ($dir in @($X64Dir, $Arm64Dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function Get-FileSha256Hex([string]$Path) {
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

function Ensure-File([string]$Url, [string]$Dest, [string]$ExpectedSha256) {
    $expected = $ExpectedSha256.ToLowerInvariant()
    if (Test-Path $Dest) {
        $actual = Get-FileSha256Hex $Dest
        if ($actual -eq $expected) {
            Write-Host "OK (cached): $Dest"
            return
        }
        Write-Host "SHA256 mismatch, re-downloading: $Dest"
        Remove-Item -Force $Dest
    }

    Write-Host "Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing

    $actual = Get-FileSha256Hex $Dest
    if ($actual -ne $expected) {
        Remove-Item -Force $Dest
        throw "Integrity check failed for $Dest (expected $expected, got $actual)"
    }

    Write-Host "Saved: $Dest"
}

$Base = "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/7857"

Ensure-File `
    "$Base/pdfium-win-x64.tgz" `
    (Join-Path $X64Dir "pdfium-win-x64.tgz") `
    "b904e3898f952984fb744e0c8eb36512b5ee527124796108ed419a5b4da3c6d9"

Ensure-File `
    "$Base/pdfium-win-arm64.tgz" `
    (Join-Path $Arm64Dir "pdfium-win-arm64.tgz") `
    "12238aba08002328fb8adc7225921771427eee1cf463cca3694beecf41e4d7c5"

Write-Host ""
Write-Host "Vendor layout ready under: $VendorWindows"
Write-Host "Commit vendor/*.tgz (Git LFS recommended) so builds work without network access."
Write-Host "Optional: extract to vendor/<arch>/pdfium/ to skip extract at configure time."
