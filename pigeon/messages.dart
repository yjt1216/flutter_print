import 'package:pigeon/pigeon.dart';

// Run generation (from the workspace root, i.e. the directory containing this
// pigeon/ folder):
//
//   dart run pigeon --input pigeon/messages.dart
//
// macOS shares the same generated Swift file as iOS. After running the command
// above, copy the generated Swift file to the macOS source tree:
//
//   cp flutter_print/ios/flutter_print/Sources/flutter_print/Messages.swift \
//      flutter_print/macos/flutter_print/Sources/flutter_print/Messages.swift

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'flutter_print_platform_interface/lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    javaOut:
        'flutter_print/android/src/main/java/com/llfbandit/flutter_print/Messages.java',
    javaOptions: JavaOptions(package: 'com.llfbandit.flutter_print'),
    swiftOut:
        'flutter_print/ios/flutter_print/Sources/flutter_print/Messages.swift',
    swiftOptions: SwiftOptions(),
    gobjectHeaderOut: 'flutter_print/linux/messages.h',
    gobjectSourceOut: 'flutter_print/linux/messages.cc',
    gobjectOptions: GObjectOptions(module: 'FlutterPrint'),
    cppHeaderOut: 'flutter_print_windows/windows/messages.h',
    cppSourceOut: 'flutter_print_windows/windows/messages.cpp',
    cppOptions: CppOptions(namespace: 'flutter_print'),
  ),
)
// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------
/// Duplex (double-sided) printing mode.
enum DuplexMode {
  /// Single-sided printing.
  none,

  /// Double-sided, flip along the long edge (portrait binding).
  longEdge,

  /// Double-sided, flip along the short edge (landscape binding).
  shortEdge,
}

/// Color printing capability of a printer.
enum ColorCapability {
  /// Color capability could not be determined.
  unknown,

  /// Physical color printer — the user can choose between color and grayscale.
  supported,

  /// Monochrome-only printer — always prints in grayscale; the toggle is hidden.
  monochrome,

  /// Virtual/software printer (e.g. PDF, XPS, OneNote) — always outputs in
  /// color; the toggle is hidden and color mode is enforced.
  enforced,
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------
/// Identifies a paper size by either a well-known [name] or explicit
/// [width]/[height] dimensions in millimetres.
///
/// When both fields are present, [name] takes priority.
class PageSize {
  const PageSize({required this.name, this.width, this.height});

  /// Well-known paper-size identifier. Common values: `'A3'`, `'A4'`, `'A5'`,
  /// `'Letter'`, `'Legal'`. See each platform's documentation for the full
  /// list of accepted names.
  final String name;

  /// Page width in millimetres. Used when [name] is null or unrecognised.
  final double? width;

  /// Page height in millimetres. Used when [name] is null or unrecognised.
  final double? height;
}

/// Per-side page margins expressed in millimetres.
///
/// **iOS** — ignored; margins are controlled by the system print dialog.
/// **Windows** — ignored; the printable area is determined by the printer's
///   hardware (hardware margins are exposed via `getMinimumMargins`).
class PageMargins {
  const PageMargins({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  /// Top margin in millimetres.
  final double top;

  /// Bottom margin in millimetres.
  final double bottom;

  /// Left margin in millimetres.
  final double left;

  /// Right margin in millimetres.
  final double right;
}

/// Options controlling how a print or print-preview job is submitted.
///
/// Unsupported fields on a given platform are silently ignored.
class PrintOptions {
  const PrintOptions({
    this.printerAddress,
    this.documentTitle,
    this.pageSize,
    this.margins,
    this.copies,
    this.landscape,
    this.color,
    this.duplexMode,
  });

  /// Technical address of the target printer. Use [PrinterInfo.address] as
  /// the value. When `null` the platform system default printer is used.
  ///
  /// Platform notes:
  /// - **Android** — ignored; the user selects the printer inside the dialog.
  /// - **iOS** — must be a full AirPrint URL (e.g.
  ///   `'ipp://printer.local/ipp/print'`). When provided the job is sent
  ///   directly without showing a dialog.
  final String? printerAddress;

  /// Title shown in the print queue (Windows spooler document name, CUPS job
  /// title). When `null`, platforms use the file name.
  final String? documentTitle;

  /// Desired output page size.
  ///
  /// Platform support: Android, macOS, Linux (named sizes only), Windows
  /// (PDF, image, and text files).
  final PageSize? pageSize;

  /// Output page margins.
  ///
  /// Ignored on iOS and Windows.
  final PageMargins? margins;

  /// Number of copies to print. Must be ≥ 1.
  ///
  /// When `null` the platform/printer default is used.
  /// Ignored on iOS (controlled by the system dialog).
  final int? copies;

  /// Whether to print in landscape orientation.
  ///
  /// When `null` the platform/printer default orientation is used.
  final bool? landscape;

  /// Whether to print in colour. Set to `false` for greyscale/monochrome.
  ///
  /// When `null` the platform/printer default colour mode is used.
  final bool? color;

  /// Duplex (double-sided) printing mode.
  ///
  /// When `null` the platform default is used (typically single-sided).
  /// Ignored on iOS (controlled by the system dialog) and on Windows for
  /// unknown file types.
  final DuplexMode? duplexMode;
}

/// Capabilities of a specific printer as reported by the host platform.
///
/// Fields may be `null` when the platform does not provide that information.
class PrinterCapabilities {
  const PrinterCapabilities({
    required this.colorCapability,
    this.supportsDuplex,
    this.maxCopies,
    required this.supportedPageSizes,
  });

  /// Color printing capability of this printer.
  final ColorCapability colorCapability;

  /// Whether the printer supports duplex (double-sided) printing. `null` if
  /// unknown.
  final bool? supportsDuplex;

  /// Maximum number of copies the printer accepts in a single job. `null` if
  /// unknown or unlimited.
  final int? maxCopies;

  /// Well-known page-size names accepted by this printer (e.g. `'A4'`,
  /// `'Letter'`). Empty when the platform does not report supported sizes.
  final List<String> supportedPageSizes;
}

/// Describes a single printer returned by [FlutterPrintApi.listPrinters].
///
/// Use [label] / [address] for UI and [PrintOptions.printerAddress]. Optional
/// metadata fields ([driverName], [portName], [makeAndModel], …) help identify
/// the physical device or driver when building a **printer profile** (e.g.
/// which fault-handling rules apply). They do not replace vendor SDK status
/// codes — combine with [printerStatus], [isAvailable], and print-job status
/// streams from the main `flutter_print` package.
class PrinterInfo {
  const PrinterInfo({
    required this.label,
    this.address,
    this.details,
    required this.isDefault,
    required this.capabilities,
    this.isAvailable,
    this.printerStatus,
    this.driverName,
    this.portName,
    this.location,
    this.makeAndModel,
    this.deviceUri,
  });

  /// Human-readable display name shown to the user (e.g. `'HP LaserJet Pro'`).
  final String label;

  /// Platform-specific technical identifier used to address the printer.
  ///
  /// Pass this value as [PrintOptions.printerAddress] to send a job directly
  /// to this printer.
  ///
  /// Platform notes:
  /// - **iOS** — full AirPrint URL (e.g. `'ipp://printer.local/ipp/print'`).
  /// - **Android** — not set; the user selects the printer inside the dialog.
  final String? address;

  /// Optional extra text from the platform. Meaning varies by OS:
  ///
  /// - **Windows** — driver comment (`pComment`), not the same as [location].
  /// - **Linux (CUPS)** — often `printer-location` when set.
  ///
  /// Prefer [makeAndModel] on CUPS for model identification. May be `null`.
  final String? details;

  /// Whether this is the current system-default printer.
  final bool isDefault;

  /// Capabilities advertised by the printer.
  final PrinterCapabilities capabilities;

  /// Whether the printer is currently online and accepting jobs.
  ///
  /// `true` — printer is idle or processing (online).
  /// `false` — printer is offline or stopped.
  /// `null` — availability cannot be determined on this platform
  ///   (Android and iOS).
  ///
  /// Platform support: macOS, Windows, Linux.
  final bool? isAvailable;

  /// Raw printer status from the spooler when the platform exposes it.
  ///
  /// **Windows:** bit mask (`PRINTER_STATUS_*`). In application code, parse with
  /// helpers exported from the `flutter_print` package (`describePrinterStatus`,
  /// `isBlockingOsPrinterStatus`, or `printWithStatus` with
  /// `watchPrinterStatus: true`).
  ///
  /// **Other platforms:** usually `null`; rely on [isAvailable] on Linux/macOS.
  ///
  /// Not the same as per-job status — see [PrintJobInfo.rawStatus].
  final int? printerStatus;

  /// Installed print driver name (Windows queue properties → Driver).
  ///
  /// Use to distinguish queues that share a similar [label] (e.g. PCL vs PS
  /// driver for the same device) or to key a driver-based printer profile.
  ///
  /// **Platform:** Windows only; `null` elsewhere.
  final String? driverName;

  /// Port the queue is bound to (Windows `pPortName`).
  ///
  /// Examples: `USB001`, `WSD-…`, `IP_…`, `PORTPROMPT:` (virtual PDF/XPS).
  /// Helps infer **connection type** (USB vs network vs virtual sink).
  ///
  /// **Platform:** Windows only; `null` elsewhere.
  final String? portName;

  /// User-visible location string (Windows `pLocation`), e.g. room or site.
  ///
  /// Distinct from [details] on Windows (comment field). On Linux, location
  /// may appear in [details] instead; [location] stays `null`.
  ///
  /// **Platform:** Windows only; `null` elsewhere.
  final String? location;

  /// Manufacturer and model as reported by CUPS (`printer-make-and-model`),
  /// e.g. `KONICA MINOLTA bizhub C458`.
  ///
  /// Primary field for **model-based printer profiles** on Linux. On Windows,
  /// [label] often already contains the model; use [driverName] as a secondary
  /// key.
  ///
  /// **Platform:** Linux (CUPS); `null` on Windows/macOS/iOS/Android unless
  /// added later.
  final String? makeAndModel;

  /// Backend device URI from CUPS (`device-uri`), e.g. `ipp://192.168.1.10/ipp/print`,
  /// `usb://Vendor/Model?serial=…`, `socket://…`.
  ///
  /// Useful for debugging connectivity and telling IPP/USB/network backends
  /// apart; not required for normal printing ([address] is the queue name).
  ///
  /// **Platform:** Linux (CUPS); `null` elsewhere.
  final String? deviceUri;
}

/// A print job in the system queue (Windows Spooler / CUPS / Android PrintJob).
///
/// [rawStatus] is platform-specific. Parse with [PrintJobStatusHelper] in Dart.
class PrintJobInfo {
  const PrintJobInfo({
    required this.id,
    required this.title,
    required this.rawStatus,
  });

  /// Platform job identifier.
  final int id;

  /// Document / job title from the spooler.
  final String title;

  /// Raw status from the OS (Windows `JOB_STATUS_*` bits, CUPS IPP state, etc.).
  final int rawStatus;
}

// ---------------------------------------------------------------------------
// Host API — implemented natively, called from Dart
// ---------------------------------------------------------------------------

/// Native print API. All methods are implemented on the host side and invoked
/// from Dart through Pigeon-generated channels.
@HostApi()
abstract class FlutterPrintApi {
  /// Sends [filePath] directly to the printer described by [options].
  ///
  /// The file must exist and be readable by the process. Supported file
  /// formats depend on the platform and the installed printer drivers (PDF is
  /// universally accepted).
  ///
  /// **Android / iOS** — always opens the system print dialog (which includes
  /// a preview step). The [PrintOptions.printerAddress] field is ignored on
  /// Android; on iOS it must be a full AirPrint URL to bypass the dialog.
  ///
  /// **macOS** — For PDF files the job is rendered
  /// page-by-page using PDFKit. Other file types are opened with the default
  /// application instead.
  ///
  /// **Windows** — PDF, image, and text files are rendered directly to the
  /// printer. Other file types are delegated; the
  /// associated application handles rendering and most options are ignored.
  ///
  /// **Linux** — submits the job via CUPS (`cupsPrintFile`). Falls back to
  /// the `lp` command-line tool when CUPS is not available at build time.
  ///
  /// Throws a [PlatformException] if the file is not found, the file type is
  /// unsupported, or the print subsystem reports an error.
  @async
  void print(String filePath, {PrintOptions? options});

  /// Opens the native print-preview or print dialog for [filePath].
  ///
  /// **Android / iOS** — identical to [print]: the system print dialog always
  /// includes a preview step on these platforms.
  ///
  /// **macOS** — opens the system print dialog so the user can review and
  /// adjust settings before printing.
  ///
  /// **Windows** — opens a custom Flutter print dialog with a built-in
  /// preview for PDF, image, and text files.
  ///
  /// **Linux** — opens the file with `xdg-open`, delegating preview and
  /// printing to the default document viewer.
  ///
  /// Throws a [PlatformException] if the file is not found.
  @async
  void printPreview(String filePath, {PrintOptions? options});

  /// Returns all printers currently available on this device.
  ///
  /// **Android / iOS / Web** — always returns an empty list.
  ///
  /// **iOS** - use [pickPrinter] instead.
  @async
  List<PrinterInfo> listPrinters();

  /// Shows a native AirPrint printer-picker UI and returns the selected
  /// printer, or `null` if the user cancelled.
  ///
  /// Returns `null` on all other platforms.
  @async
  PrinterInfo? pickPrinter();

  /// Lists jobs in the queue for [printerAddress] (printer name or CUPS name).
  ///
  /// **Android** — tracked jobs started by this app via [printSubmit].
  /// **iOS / Web** — empty list.
  @async
  List<PrintJobInfo> listPrintJobs(String printerAddress);

  /// Submits [filePath] for printing and returns a spooler job id when available.
  ///
  /// Returns `-1` when the platform cannot track the job (silent paths without
  /// a queue id). Throws on error.
  ///
  /// **Android / iOS** — opens the system print UI for PDF; job id is assigned
  /// when the user confirms (same as [print] for images with immediate id).
  @async
  int printSubmit(String filePath, {PrintOptions? options});

  /// Cancels a queued job. Returns `false` when the OS rejects the operation.
  @async
  bool cancelPrintJob(String printerAddress, int jobId);

  /// Pauses a queued job. Returns `false` when unsupported or rejected.
  @async
  bool pausePrintJob(String printerAddress, int jobId);

  /// Resumes a paused job. Returns `false` when unsupported or rejected.
  @async
  bool resumePrintJob(String printerAddress, int jobId);
}
