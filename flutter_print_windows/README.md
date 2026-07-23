# flutter_print_windows

Windows platform implementation of [flutter_print](https://pub.dev/packages/flutter_print) plugin.

## Offline PDFium

Windows PDF preview/ rendering uses [PDFium](https://pdfium.googlesource.com/pdfium/) via prebuilt binaries from [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries).

Binaries are **vendored** under `windows/vendor/` so `flutter build windows` does not download from the network when archives are present.

Maintainers: run once (or after bumping the PDFium release):

```powershell
.\scripts\download_vendor.ps1
```

See [windows/vendor/README.md](./windows/vendor/README.md) for layout and checksums. Commit the `.tgz` files (Git LFS recommended).
