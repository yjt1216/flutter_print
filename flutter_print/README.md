# flutter_print

A Flutter plugin focusing on print, that's it.

**PDF and image files** are rendered natively on every platform.

**All other file types** (HTML, plain text, Office documents, …) are forwarded to the platform's default handler for that format.
`PrintOptions` fields other than `printerAddress` may not be forwarded in this case.

**Widgets** are rendered as image in a (single page) pdf.

---

## Usage

### Basic print

```dart
import 'package:flutter_print/flutter_print.dart';

// List available printers
final List<PrinterInfo> printers = await FlutterPrint.listPrinters();

// Print with default settings
await FlutterPrint.print('/path/to/document.pdf');

// On the web `filePath` must be a URL accessible from the page's origin.
// The browser's native print dialog (which includes a preview) is always shown.
// Blob URL is OK too.
await FlutterPrint.print('https://example.com/document.pdf');
```

### Print with options

```dart
await FlutterPrint.print(
  '/path/to/document.pdf',
  options: PrintOptions(
    // Target a specific printer (uses system default when omitted).
    printerAddress: 'my_printer',

    // Use a named page size preset.
    // Or via PageSize(width: w, height: h)
    pageSize: PaperSizes.a4,

    // Margins in millimetres.
    margins: PageMargins(top: 10, bottom: 10, left: 15, right: 15),

    copies: 2,
    landscape: false,
    color: true,
  ),
);
```

### Widget print

Render any Flutter widget off-screen and print it directly — no file needed.
`printWidget` rasterises the widget into a single-page PDF and sends it to the
printer. `previewWidget` does the same but returns PNG bytes you can display
with `Image.memory` before printing.

```dart
// Print a widget
await FlutterPrint.printWidget(
  (ctx) => Theme(data: Theme.of(ctx), child: MyReceiptWidget()),
  context: context,
  options: PrintOptions(pageSize: PaperSizes.a4),
);

// Preview a widget in-app before printing
final png = await FlutterPrint.previewWidget(
  (ctx) => Theme(data: Theme.of(ctx), child: MyReceiptWidget()),
  context: context,
  options: PrintOptions(pageSize: PaperSizes.a4),
);
Image.memory(png);
```

### Print job status

Track spooler progress with a **`Stream<PrintJobInfo>`** (similar in spirit to
desktop print-job APIs). Each event carries `id`, `title`, and `rawStatus`; use
`job.parsedStatus` for a cross-platform [`PrintJobStatus`](lib/src/print_job_status.dart)
enum.

See the [feature backlog](./docs/features/FEATURES.zh-CN.md) (中文) for planned work.

**Recommended:** call `listPrinters()`, set `PrintOptions.printerAddress` to the
queue name (`PrinterInfo.address` on Windows / Linux / macOS), then use
`printWithStatus`.

**Completion modes** ([`PrintJobCompletionMode`](lib/src/print_job_status.dart)):
default **`dequeueSuccess`** (job leaves queue); **`spoolerTerminal`** (printed/
completed while queued); **`spoolerComplete`** (Windows `JOB_STATUS_COMPLETE` or
CUPS state `9`, with dequeue fallback for virtual printers).

```dart
await for (final job in FlutterPrint.printWithStatus(
  '/path/to/document.pdf',
  options: PrintOptions(printerAddress: 'Microsoft Print to PDF'),
  pollInterval: const Duration(seconds: 2),
)) {
  debugPrint('${job.id} ${job.parsedStatus} (raw ${job.rawStatus})');
}

// Or submit manually and watch an existing job id.
final jobId = await FlutterPrint.printSubmit(
  '/path/to/document.pdf',
  options: PrintOptions(printerAddress: 'my_printer'),
);
if (jobId >= 0) {
  await for (final job in FlutterPrint.watchPrintJob('my_printer', jobId)) {
    debugPrint('${job.parsedStatus}');
  }
}

// List jobs in a queue (desktop spooler or Android jobs from this app).
final jobs = await FlutterPrint.listPrintJobs('my_printer');

// Cancel when supported.
await FlutterPrint.cancelPrintJob('my_printer', jobId);

// Optional: spooler document title (Windows queue name, CUPS job title).
await for (final job in FlutterPrint.printWithStatus(
  '/path/to/document.pdf',
  options: PrintOptions(
    printerAddress: 'my_printer',
    documentTitle: '检测报告',
  ),
  requirePrintedBeforeDequeue: true,
  watchPrinterStatus: true,
)) {
  debugPrint('${job.parsedStatus}');
}

// PrinterInfo also exposes driverName, portName, location (Windows) and
// makeAndModel, deviceUri (Linux CUPS) from listPrinters().
```

When the platform cannot return a job id (`printSubmit` returns **`-1`**), e.g.
iOS system print UI or Web, `printWithStatus` falls back to a normal
`FlutterPrint.print()` and emits a single completion event.

### printing_ffi-style API (in this package)

For apps migrating from **printing_ffi** / HeartMonitorx-style flows:

```dart
final defaultPrinter = await FlutterPrint.getDefaultPrinter();
final address = await FlutterPrint.resolvePrinterAddress(savedPrinterName);

await for (final job in FlutterPrint.printPdfAndStreamStatus(
  savedPrinterName,
  reportPdfPath,
  docName: '检测报告',
  pollInterval: const Duration(seconds: 1),
  treatRetainedAsSuccess: true, // Windows retained jobs count as done
)) {
  print('${job.id} ${job.status}');
}

await FlutterPrint.cancelPrintJobByName(savedPrinterName, jobId);
// Or: FlutterPrint.listPrintJobsStream(printerName);
// describePrinterStatus(printer) for PrinterInfo.printerStatus (Windows)
```

See also top-level helpers in `print_job_flow.dart`, `printer_helpers.dart`,
`printer_status_helper.dart`.

The **example app** (`flutter_print/example`) logs these events to the console
with the `[flutter_print_example]` prefix when you use **Print — direct** (file
sources) or **List jobs**.

---

## Feature support by platform

| Feature        | Android | iOS | macOS | Windows | Linux | Web |
|----------------|---------|-----|-------|---------|-------|-----|
| Direct print   |         | ✔️† | ✔️   | ✔️      | ✔️   |     |
| Setup & print  | ✔️      | ✔️ | ✔️   | ✔️      | ✔️§  | ✔️  |
| List printers  |         |     | ✔️   | ✔️      | ✔️   |     |
| Print job stream | ✔️‡  | ‡   | ✔️¶  | ✔️      | ✔️¶  | ‡   |
| List / cancel jobs | ✔️‡ |     | ✔️¶  | ✔️      | ✔️¶  |     |

‡ **Job id** — Android tracks jobs started via `printSubmit` in this app; iOS /
Web return `-1` or empty lists (no spooler API). **macOS** and **Linux** use
CUPS (`printSubmit`, `listPrintJobs`, cancel/pause/resume). **Stream** still
works via `printWithStatus` fallback where id is unavailable.

¶ **CUPS** — macOS and Linux queue APIs; Linux requires CUPS at build time.

† On iOS, direct print without the system dialog requires
`PrintOptions.printerAddress` from `FlutterPrint.ios?.pickPrinter()` (e.g.
`ipp://printer.local./ipp/print`).

§ On Linux, **Setup & print** uses `xdg-open` to open the file in its default viewer.

## Option support by platform

Not all options are honoured on every platform. Unsupported fields are silently
ignored.

| Option           | Android | iOS | macOS | Windows | Linux | Web |
|------------------|---------|-----|-------|---------|-------|-----|
| `printerAddress` |         | ✔️† | ✔️   | ✔️      | ✔️   |     |
| `pageSize`       | ✔️      |     | ✔️   | ✔️‡     | ✔️§  |     |
| `margins`        | ✔️      |     | ✔️   |         | ✔️§  |     |
| `copies`         |         |     | ✔️   | ✔️‡     | ✔️   |     |
| `landscape`      | ✔️      | ✔️  | ✔️   | ✔️‡    | ✔️   |    |
| `color`          | ✔️      | ✔️  | ✔️¶  | ✔️‡    | ✔️   |    |
| `duplexMode`     | ✔️      | ✔️  | ✔️¶  | ✔️‡    | ✔️§  |    |

† On iOS, with a `printerAddress` from `FlutterPrint.ios?.pickPrinter()` (e.g. `ipp://printer.local./ipp/print`).

‡ Windows — options are fully applied for **PDF** files and **image** files.
All other file types are delegated to their associated application with its own defaults.  

§ Linux — requires CUPS.  

¶ macOS — `color` and `duplexMode` can't be reflected in preview panel. 

---

## Image support by platform

| Format | Windows | macOS | iOS | Android | Linux |
|--------|---------|-------|-----|---------|-------|
| JPEG   | ✔️      | ✔️   | ✔️  | ✔️     | ✔️    |
| PNG    | ✔️      | ✔️   | ✔️  | ✔️     | ✔️    |
| BMP    | ✔️      | ✔️   | ✔️  | ✔️     | ✔️    |
| GIF    | ✔️      | ✔️   | ✔️  | ✔️     | ✔️    |
| TIFF   | ✔️      | ✔️   | ✔️  | ✔️     | ✔️    |
| WebP   | ✔️¹     | ✔️²  | ✔️² | ✔️     | ✔️³   |
| HEIC   | ✔️¹     | ✔️²  | ✔️² | ✔️     | ✔️³   |

¹ Requires the WebP or HEIC codec from the Microsoft Store (built into Windows 11 for HEIC).  
² Requires macOS / iOS 11 or later.  
³ Requires the matching GDK-Pixbuf loader: `webp-pixbuf-loader` for WebP, `libheif` + `heif-pixbuf-loader` for HEIC.

---

## Setup

### macOS

You must add print entitlement to your app:

`macos/Runner/Release.entitlements` and `macos/Runner/DebugProfile.entitlements`
```xml
<dict>
  <key>com.apple.security.print</key>
  <true/>
</dict>
```

PDF and image files are rendered and printed natively (honouring the print
options). Any other file type is printed silently through the `lp`
command-line tool — but a **sandboxed** app cannot spawn `lp`, so in that case
the file is opened in its default application instead. Disable the App Sandbox
if you need silent printing of non‑PDF/image files.

### Linux

Printer enumeration and direct printing require the **CUPS** development
libraries. Install them before building the application:

```sh
# Debian / Ubuntu
sudo apt install libcups2-dev

# Fedora / RHEL / CentOS
sudo dnf install cups-devel

# Arch Linux
sudo pacman -S cups
```

When `libcups2-dev` is absent the plugin still compiles, but `listPrinters`
returns an empty list and `print` falls back to the `lp` command-line tool
(which requires CUPS to be running at runtime).
