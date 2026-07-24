# flutter_print（工作区）

[English](./README.md)

[**flutter_print**](https://pub.dev/packages/flutter_print) 联邦插件的 Monorepo：在移动端、桌面端和 Web 上打印 PDF、图片、Widget 等内容。

插件 API 与用法见 **[flutter_print/README.md](./flutter_print/README.md)**（含打印作业状态 Stream 等章节）。

规划中的能力与排期见 **[功能清单](./flutter_print/docs/features/FEATURES.zh-CN.md)**。

## 包结构

| 目录 | Pub 名称 | 说明 |
|------|----------|------|
| [flutter_print](./flutter_print/) | `flutter_print` | 主插件（Android、iOS、macOS、Linux） |
| [flutter_print_platform_interface](./flutter_print_platform_interface/) | `flutter_print_platform_interface` | 跨平台公共接口 |
| [flutter_print_windows](./flutter_print_windows/) | `flutter_print_windows` | Windows 实现（PDF 预览、打印对话框） |
| [flutter_print_web](./flutter_print_web/) | `flutter_print_web` | Web 实现 |

示例工程：`flutter_print/example`，以及各子包下的 `example/`（如有）。

### 打印作业状态（用法）

主插件提供 **`FlutterPrint.printWithStatus`**、**`watchPrintJob`**、
**`listPrintJobs`**、**`printSubmit`**、**`cancelPrintJob`**，用于在桌面端
（Windows 后台打印、Linux CUPS）及 Android（本应用通过 `printSubmit` 发起的任务）
跟踪队列状态。完整说明与平台对照表见
**[flutter_print/README.md](./flutter_print/README.md#print-job-status)**（英文）。

快速示例（已知打印机队列名时）：

```dart
await for (final job in FlutterPrint.printWithStatus(
  filePath,
  options: PrintOptions(printerAddress: printerQueueName),
)) {
  print('${job.id} ${job.parsedStatus}');
}
```

在 **`flutter_print/example`** 中体验：先 **List printers** 选择队列，再
**Print — direct** 或 **List jobs**；控制台日志前缀为 `[flutter_print_example]`。

## 环境要求

- **Dart** `^3.12.0`
- **Flutter** `>=3.44.0`（建议使用 stable 3.44.x）

## 本地开发

在仓库根目录执行：

```bash
dart pub get
dart run melos bootstrap
```

运行主示例：

```bash
cd flutter_print/example
flutter run -d windows   # 也可 macos、linux、chrome 等
```

格式化所有包：

```bash
dart run melos run format
```

修改 `pigeon/messages.dart` 后重新生成 Pigeon 代码：

```bash
dart run pigeon --config pigeon/pigeon.yaml
```

## Windows：离线 PDFium

Windows 端使用 [PDFium](https://pdfium.googlesource.com/pdfium/) 渲染 PDF。预编译库放在 **`flutter_print_windows/windows/vendor/`**，在已提交或已下载 `.tgz` 的前提下，**`flutter build windows` 构建阶段不会从外网下载**。

**维护者**（首次克隆或升级 PDFium 版本时）：

```powershell
cd flutter_print_windows
.\scripts\download_vendor.ps1
```

更多说明：

- [flutter_print_windows/README.md](./flutter_print_windows/README.md)
- [flutter_print_windows/windows/vendor/README.md](./flutter_print_windows/windows/vendor/README.md)

请将 `vendor/` 下的 `.tgz` 纳入版本库（体积较大，建议使用 **Git LFS**）。

## 许可证

各子包内的 LICENSE 文件；上游仓库：[llfbandit/flutter_print](https://github.com/llfbandit/flutter_print)。
