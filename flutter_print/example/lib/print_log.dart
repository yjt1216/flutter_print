import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_print/flutter_print.dart';

const _logName = 'flutter_print_example';

/// Example-app log points for print APIs (visible in DevTools / `flutter run` console).
void logPrintExample(String event, [Object? detail]) {
  final line = detail == null ? event : '$event | $detail';
  developer.log(line, name: _logName);
  debugPrint('[$_logName] $line');
}

void logPrintJobUpdate(PrintJobInfo job) {
  logPrintExample(
    'print_job_update',
    'id=${job.id} title="${job.title}" raw=${job.rawStatus} '
    'parsed=${job.parsedStatus}',
  );
}

void logPrintJobsListed(String printerAddress, List<PrintJobInfo> jobs) {
  logPrintExample(
    'list_print_jobs',
    'printer="$printerAddress" count=${jobs.length}',
  );
  for (final job in jobs) {
    logPrintJobUpdate(job);
  }
}

void logPrintExampleError(Object error, StackTrace stackTrace) {
  logPrintExample('error', error);
  developer.log(
    'error',
    name: _logName,
    error: error,
    stackTrace: stackTrace,
  );
}
