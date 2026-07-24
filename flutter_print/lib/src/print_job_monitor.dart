import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

import 'print_job_status.dart';

/// Polls the native spooler for [jobId] on [printerAddress] and emits updates.
Stream<PrintJobInfo> watchPrintJob(
  String printerAddress,
  int jobId, {
  Duration pollInterval = const Duration(seconds: 2),
  FlutterPrintPlatform? platform,
}) {
  final api = platform ?? FlutterPrintPlatform.instance;

  PrintJobInfo? findJob(List<PrintJobInfo> jobs) {
    for (final job in jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  }

  late StreamController<PrintJobInfo> controller;
  Timer? poller;
  PrintJobInfo? last;

  Future<void> poll() async {
    if (controller.isClosed) {
      poller?.cancel();
      return;
    }
    try {
      final jobs = await api.listPrintJobs(printerAddress);
      final current = findJob(jobs);
      if (current != null) {
        if (last == null || current.rawStatus != last!.rawStatus) {
          controller.add(current);
        }
        last = current;
        if (PrintJobStatusHelper.isTerminal(current.parsedStatus)) {
          poller?.cancel();
          await controller.close();
        }
        return;
      }

      if (last != null &&
          !PrintJobStatusHelper.isTerminal(last!.parsedStatus)) {
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

/// Submits a print job and streams spooler status until a terminal state.
Stream<PrintJobInfo> printWithStatus(
  String filePath, {
  PrintOptions? options,
  Duration pollInterval = const Duration(seconds: 2),
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
