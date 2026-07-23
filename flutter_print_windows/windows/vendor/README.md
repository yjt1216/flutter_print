# Offline PDFium (Windows)

CMake reads archives from here. **No network download** during `flutter build windows` when the matching `.tgz` is present (or a pre-extracted `pdfium/` tree).

Upstream: [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries) — release **chromium/7857**.

## Layout

```text
vendor/
  x86_64/
    pdfium-win-x64.tgz
    pdfium/                 # optional: pre-extracted (include/, lib/, bin/)
  aarch64/
    pdfium-win-arm64.tgz
    pdfium/
```

## Populate (maintainers, once per PDFium bump)

From this package directory:

```powershell
.\scripts\download_vendor.ps1
```

Then commit the `.tgz` files (Git LFS recommended for large binaries).

## SHA256 checksums

| File | SHA256 |
|------|--------|
| `x86_64/pdfium-win-x64.tgz` | `b904e3898f952984fb744e0c8eb36512b5ee527124796108ed419a5b4da3c6d9` |
| `aarch64/pdfium-win-arm64.tgz` | `12238aba08002328fb8adc7225921771427eee1cf463cca3694beecf41e4d7c5` |

License texts ship inside each archive under `licenses/` and `LICENSE`.
