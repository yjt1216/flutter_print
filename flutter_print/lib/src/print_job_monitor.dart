import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

import 'print_job_status.dart';
import 'printer_status_helper.dart';

/// Polls the native spooler for [jobId] on [printerAddress] and emits updates.
Stream<PrintJobInfo> watchPrintJob(
  String printerAddress,
  int jobId, {
  Duration pollInterval = const Duration(seconds: 2),
  PrintJobCompletionMode completionMode = PrintJobCompletionMode.spoolerTerminal,
  bool treatRetainedAsSuccess = false,
  bool requirePrintedBeforeDequeue = false,
  bool watchPrinterStatus = false,
  bool failOnBlockingPrinterStatus = true,
  FlutterPrintPlatform? platform,
}) {
  final api = platform ?? FlutterPrintPlatform.instance;

  PrintJobInfo? findJob(List<PrintJobInfo> jobs) {
    for (final job in jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  }

  bool isProgressStatus(PrintJobStatus status) {
    if (status == PrintJobStatus.printed || status == PrintJobStatus.completed) {
      return true;
    }
    if (treatRetainedAsSuccess && status == PrintJobStatus.retained) {
      return true;
    }
    return false;
  }

  late StreamController<PrintJobInfo> controller;
  Timer? poller;
  PrintJobInfo? last;
  var seenProgress = false;
  int? lastPrinterStatusRaw;

  Future<void> checkPrinterStatus() async {
    if (!watchPrinterStatus || controller.isClosed) return;
    final printers = await api.listPrinters();
    final printer = findPrinterByAddress(printers, printerAddress);
    if (printer == null) return;

    final raw = printer.printerStatus;
    if (raw != null && raw != lastPrinterStatusRaw) {
      lastPrinterStatusRaw = raw;
    }

    if (failOnBlockingPrinterStatus && isBlockingOsPrinterStatus(printer)) {
      poller?.cancel();
      if (!controller.isClosed) {
        controller.addError(
          PrintBlockedByPrinterStatus(
            printer,
            describePrinterStatus(printer),
          ),
        );
        await controller.close();
      }
    }
  }

  Future<void> finishOnDequeueSuccess() async {
    if (requirePrintedBeforeDequeue && !seenProgress) {
      poller?.cancel();
      if (!controller.isClosed) {
        controller.addError(PrintJobDequeuedWithoutProgress(jobId));
        await controller.close();
      }
      return;
    }

    if (last == null) {
      controller.add(
        PrintJobInfo(
          id: jobId,
          title: '',
          rawStatus: _syntheticCompletedRaw(),
        ),
      );
    } else if (!PrintJobStatusHelper.isFailure(last!.parsedStatus)) {
      final syntheticRaw = _syntheticCompletedRaw();
      if (syntheticRaw != last!.rawStatus) {
        controller.add(
          PrintJobInfo(
            id: jobId,
            title: last!.title,
            rawStatus: syntheticRaw,
          ),
        );
      }
    }
    poller?.cancel();
    await controller.close();
  }

  Future<void> poll() async {
    if (controller.isClosed) {
      poller?.cancel();
      return;
    }
    try {
      await checkPrinterStatus();
      if (controller.isClosed) return;

      final jobs = await api.listPrintJobs(printerAddress);
      final current = findJob(jobs);
      if (current != null) {
        if (isProgressStatus(current.parsedStatus)) {
          seenProgress = true;
        }
        if (last == null || current.rawStatus != last!.rawStatus) {
          controller.add(current);
        }
        last = current;

        if (completionMode == PrintJobCompletionMode.dequeueSuccess) {
          if (PrintJobStatusHelper.isFailure(current.parsedStatus)) {
            poller?.cancel();
            await controller.close();
          }
          return;
        }

        if (completionMode == PrintJobCompletionMode.spoolerComplete) {
          if (PrintJobStatusHelper.isFailure(current.parsedStatus)) {
            poller?.cancel();
            await controller.close();
            return;
          }
          if (PrintJobStatusHelper.isSpoolerCompleteRaw(current.rawStatus)) {
            seenProgress = true;
            poller?.cancel();
            await controller.close();
          }
          return;
        }

        if (PrintJobStatusHelper.isTerminal(
          current.parsedStatus,
          treatRetainedAsSuccess: treatRetainedAsSuccess,
        )) {
          poller?.cancel();
          await controller.close();
        }
        return;
      }

      // Job no longer in the queue.
      if (completionMode == PrintJobCompletionMode.dequeueSuccess ||
          completionMode == PrintJobCompletionMode.spoolerComplete) {
        await finishOnDequeueSuccess();
        return;
      }

      if (last != null &&
          !PrintJobStatusHelper.isTerminal(
            last!.parsedStatus,
            treatRetainedAsSuccess: treatRetainedAsSuccess,
          )) {
        final syntheticRaw = _syntheticCompletedRaw();
        if (syntheticRaw != last!.rawStatus) {
          controller.add(
            PrintJobInfo(id: jobId, title: last!.title, rawStatus: syntheticRaw),
          );
        }
      }
      poller?.cancel();
      await controller.close();
    } catch (e, s) {
      if (!controller.isClosed) {
        controller.addError(e, s);
        poller?.cancel();
        await controller.close();
      }
    }
  }

  controller = StreamController<PrintJobInfo>(
    onListen: () {
      poll();
      poller = Timer.periodic(pollInterval, (_) => poll());
    },
    onCancel: () => poller?.cancel(),
  );

  return controller.stream;
}

int _syntheticCompletedRaw() {
  if (Platform.isWindows) return 128;
  if (Platform.isAndroid) return 5;
  return 9;
}

/// Submits a print job and streams spooler status until completion.
Stream<PrintJobInfo> printWithStatus(
  String filePath, {
  PrintOptions? options,
  Duration pollInterval = const Duration(seconds: 2),
  PrintJobCompletionMode completionMode = PrintJobCompletionMode.dequeueSuccess,
  bool treatRetainedAsSuccess = false,
  bool requirePrintedBeforeDequeue = false,
  bool watchPrinterStatus = false,
  bool failOnBlockingPrinterStatus = true,
  FlutterPrintPlatform? platform,
}) async* {
  final p = platform ?? FlutterPrintPlatform.instance;
  final printer = options?.printerAddress ?? await _defaultPrinterAddress(p);
  if (printer == null || printer.isEmpty) {
    throw StateError('No printer address for printWithStatus');
  }

  final jobId = await p.printSubmit(filePath, options: options);
  if (jobId < 0) {
    await p.print(filePath, options: options);
    yield PrintJobInfo(id: -1, title: filePath, rawStatus: 9);
    return;
  }

  yield* watchPrintJob(
    printer,
    jobId,
    pollInterval: pollInterval,
    completionMode: completionMode,
    treatRetainedAsSuccess: treatRetainedAsSuccess,
    requirePrintedBeforeDequeue: requirePrintedBeforeDequeue,
    watchPrinterStatus: watchPrinterStatus,
    failOnBlockingPrinterStatus: failOnBlockingPrinterStatus,
    platform: p,
  );
}

Future<String?> _defaultPrinterAddress(FlutterPrintPlatform platform) async {
  final printers = await platform.listPrinters();
  for (final pr in printers) {
    if (pr.isDefault && pr.address != null) return pr.address;
  }
  for (final pr in printers) {
    if (pr.address != null) return pr.address;
  }
  return null;
}
