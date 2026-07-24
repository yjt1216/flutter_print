import 'dart:io';

import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

/// Human-readable hint for [PrinterInfo.printerStatus] (Windows `PRINTER_STATUS_*`).
String describePrinterStatus(PrinterInfo printer) {
  final raw = printer.printerStatus;
  if (raw == null) {
    if (printer.isAvailable == false) return 'Offline or unavailable';
    if (printer.isAvailable == true) return 'Ready';
    return 'Unknown';
  }
  if (!Platform.isWindows) return 'Status $raw';

  if ((raw & 0x00000080) != 0) return 'Offline';
  if ((raw & 0x00000200) != 0) return 'Paper out';
  if ((raw & 0x00000008) != 0) return 'Paper jam or intervention';
  if ((raw & 0x00000002) != 0) return 'Error';
  if ((raw & 0x00000001) != 0) return 'Paused';
  if ((raw & 0x00000400) != 0) return 'Busy';
  if ((raw & 0x00000000) == 0 && printer.isAvailable == true) return 'Ready';
  return 'Status $raw';
}

/// Whether the OS reports a condition that should block treating a print as
/// successful (Windows `PRINTER_STATUS_*`; CUPS `isAvailable == false`).
///
/// Does not cover vendor SDK fault codes — only spooler-reported state.
bool isBlockingOsPrinterStatus(PrinterInfo printer) {
  if (printer.isAvailable == false) return true;

  final raw = printer.printerStatus;
  if (raw == null || !Platform.isWindows) return false;

  const offline = 0x00000080;
  const paperOut = 0x00000200;
  const paperProblem = 0x00000008;
  const error = 0x00000002;
  const notAvailable = 0x00001000;
  const userIntervention = 0x00100000;

  if ((raw & offline) != 0) return true;
  if ((raw & paperOut) != 0) return true;
  if ((raw & paperProblem) != 0) return true;
  if ((raw & error) != 0) return true;
  if ((raw & notAvailable) != 0) return true;
  if ((raw & userIntervention) != 0) return true;
  return false;
}

PrinterInfo? findPrinterByAddress(List<PrinterInfo> printers, String address) {
  for (final p in printers) {
    if (p.address == address) return p;
  }
  for (final p in printers) {
    if (p.label == address) return p;
  }
  return null;
}

/// Thrown when [watchPrintJob] ends because the queue reports a blocking
/// printer status while [watchPrinterStatus] is enabled.
class PrintBlockedByPrinterStatus implements Exception {
  PrintBlockedByPrinterStatus(this.printer, this.description);

  final PrinterInfo printer;
  final String description;

  @override
  String toString() => 'PrintBlockedByPrinterStatus: $description';
}

/// Thrown when the job left the queue before any `printed`/`completed` status
/// was observed and [requirePrintedBeforeDequeue] is enabled.
class PrintJobDequeuedWithoutProgress implements Exception {
  PrintJobDequeuedWithoutProgress(this.jobId);

  final int jobId;

  @override
  String toString() =>
      'PrintJobDequeuedWithoutProgress: job $jobId left queue without printed/completed';
}
