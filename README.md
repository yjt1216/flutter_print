# flutter_print (workspace)

[简体中文](./README.zh-CN.md)

Monorepo for the [**flutter_print**](https://pub.dev/packages/flutter_print) federated plugin — print PDF, images, widgets, and other content on mobile, desktop, and web.

Package documentation and API usage live in **[flutter_print/README.md](./flutter_print/README.md)**.

## Packages

| Directory | Pub name | Role |
|-----------|----------|------|
| [flutter_print](./flutter_print/) | `flutter_print` | Main plugin (Android, iOS, macOS, Linux) |
| [flutter_print_platform_interface](./flutter_print_platform_interface/) | `flutter_print_platform_interface` | Shared platform API |
| [flutter_print_windows](./flutter_print_windows/) | `flutter_print_windows` | Windows implementation (PDF preview, print UI) |
| [flutter_print_web](./flutter_print_web/) | `flutter_print_web` | Web implementation |

Examples: `flutter_print/example`, and per-package `example/` folders where present.

## Requirements

- **Dart** `^3.12.0`
- **Flutter** `>=3.44.0` (stable 3.44.x recommended)

## Development

From the repository root:

```bash
dart pub get
dart run melos bootstrap
```

Run the main example:

```bash
cd flutter_print/example
flutter run -d windows   # or macos, linux, chrome, …
```

Format all packages:

```bash
dart run melos run format
```

Regenerate Pigeon bindings after editing `pigeon/messages.dart`:

```bash
dart run pigeon --config pigeon/pigeon.yaml
```

## Windows: offline PDFium

The Windows implementation renders PDFs with [PDFium](https://pdfium.googlesource.com/pdfium/). Prebuilt binaries are **vendored** under `flutter_print_windows/windows/vendor/` so **`flutter build windows` does not download from the network** when the archives are present.

**Maintainers** (first clone or after bumping PDFium):

```powershell
cd flutter_print_windows
.\scripts\download_vendor.ps1
```

Details: [flutter_print_windows/README.md](./flutter_print_windows/README.md) and [flutter_print_windows/windows/vendor/README.md](./flutter_print_windows/windows/vendor/README.md).

Commit the `.tgz` files under `vendor/` ( **Git LFS** recommended for large binaries).

## License

See license files in each package (upstream [llfbandit/flutter_print](https://github.com/llfbandit/flutter_print)).
