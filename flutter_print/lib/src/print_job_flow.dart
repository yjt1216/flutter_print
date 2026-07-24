import 'dart:async';

import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

import 'print_job_monitor.dart';
import 'print_job_status.dart';
import 'printer_helpers.dart';

/// printing_ffi-style entry: resolve [printerName], submit PDF, stream status.
///
/// [treatRetainedAsSuccess] matches HeartMonitorx treating Windows
/// [PrintJobStatus.retained] as a successful finish.
Stream<PrintJobInfo> printPdfAndStreamStatus(
  String printerName,
  String pdfFilePath, {
  String? docName,
  int? copies,
  Duration pollInterval = const Duration(seconds: 2),
  PrintOptions? options,
  bool treatRetainedAsSuccess = true,
  bool requirePrintedBeforeDequeue = false,
  bool watchPrinterStatus = false,
  bool failOnBlockingPrinterStatus = true,
  FlutterPrintPlatform? platform,
}) async* {
  final api = platform ?? FlutterPrintPlatform.instance;
  final address = await resolvePrinterAddressOrSelf(printerName, platform: api);
  final merged = _mergePrintOptions(
    options,
    printerAddress: address,
    documentTitle: docName,
    copies: copies,
  );
  yield* printWithStatus(
    pdfFilePath,
    options: merged,
    pollInterval: pollInterval,
    completionMode: PrintJobCompletionMode.dequeueSuccess,
    treatRetainedAsSuccess: treatRetainedAsSuccess,
    requirePrintedBeforeDequeue: requirePrintedBeforeDequeue,
    watchPrinterStatus: watchPrinterStatus,
    failOnBlockingPrinterStatus: failOnBlockingPrinterStatus,
    platform: api,
  );
}

/// Periodic snapshot of the entire queue (printing_ffi `listPrintJobsStream`).
Stream<List<PrintJobInfo>> listPrintJobsStream(
  String printerNameOrAddress, {
  Duration pollInterval = const Duration(seconds: 2),
  FlutterPrintPlatform? platform,
}) {
  late StreamController<List<PrintJobInfo>> controller;
  Timer? timer;

  Future<void> emitOnce() async {
    if (controller.isClosed) return;
    final api = platform ?? FlutterPrintPlatform.instance;
    final address =
        await resolvePrinterAddressOrSelf(printerNameOrAddress, platform: api);
    final jobs = await api.listPrintJobs(address);
    if (!controller.isClosed) controller.add(jobs);
  }

  controller = StreamController<List<PrintJobInfo>>(
    onListen: () {
      emitOnce().catchError(controller.addError);
      timer = Timer.periodic(pollInterval, (_) {
        emitOnce().catchError(controller.addError);
      });
    },
    onCancel: () => timer?.cancel(),
  );
  return controller.stream;
}

Future<bool> cancelPrintJobByName(
  String printerNameOrAddress,
  int jobId, {
  FlutterPrintPlatform? platform,
}) async {
  final api = platform ?? FlutterPrintPlatform.instance;
  final address =
      await resolvePrinterAddressOrSelf(printerNameOrAddress, platform: api);
  return api.cancelPrintJob(address, jobId);
}

Future<bool> pausePrintJobByName(
  String printerNameOrAddress,
  int jobId, {
  FlutterPrintPlatform? platform,
}) async {
  final api = platform ?? FlutterPrintPlatform.instance;
  final address =
      await resolvePrinterAddressOrSelf(printerNameOrAddress, platform: api);
  return api.pausePrintJob(address, jobId);
}

Future<bool> resumePrintJobByName(
  String printerNameOrAddress,
  int jobId, {
  FlutterPrintPlatform? platform,
}) async {
  final api = platform ?? FlutterPrintPlatform.instance;
  final address =
      await resolvePrinterAddressOrSelf(printerNameOrAddress, platform: api);
  return api.resumePrintJob(address, jobId);
}

PrintOptions _mergePrintOptions(
  PrintOptions? base, {
  required String printerAddress,
  String? documentTitle,
  int? copies,
}) {
  return PrintOptions(
    printerAddress: printerAddress,
    documentTitle: documentTitle ?? base?.documentTitle,
    pageSize: base?.pageSize,
    margins: base?.margins,
    copies: copies ?? base?.copies,
    landscape: base?.landscape,
    color: base?.color,
    duplexMode: base?.duplexMode,
  );
}

/// Alias for [PrintJobInfo.parsedStatus] (printing_ffi `PrintJob.status`).
extension PrintJobCompat on PrintJobInfo {
  PrintJobStatus get status => parsedStatus;
}
