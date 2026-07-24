import 'dart:io';

import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

/// Parsed print-job status (see [PrintJobInfo.rawStatus]).
enum PrintJobStatus {
  pending,
  processing,
  printed,
  completed,
  canceled,
  aborted,
  error,
  unknown,
  held,
  stopped,
  paused,
  spooling,
  deleting,
  restarting,
  offline,
  paperOut,
  userIntervention,
  blocked,
  retained,
}

/// Maps [PrintJobInfo.rawStatus] to [PrintJobStatus].
abstract final class PrintJobStatusHelper {
  static PrintJobStatus fromRaw(int rawStatus) {
    if (Platform.isMacOS || Platform.isLinux) {
      return switch (rawStatus) {
        3 => PrintJobStatus.pending,
        4 => PrintJobStatus.held,
        5 => PrintJobStatus.processing,
        6 => PrintJobStatus.stopped,
        7 => PrintJobStatus.canceled,
        8 => PrintJobStatus.aborted,
        9 => PrintJobStatus.completed,
        _ => PrintJobStatus.unknown,
      };
    }

    if (Platform.isWindows) {
      final status = rawStatus;
      if ((status & 2) != 0) return PrintJobStatus.error;
      if ((status & 1024) != 0) return PrintJobStatus.userIntervention;
      if ((status & 64) != 0) return PrintJobStatus.paperOut;
      if ((status & 32) != 0) return PrintJobStatus.offline;
      if ((status & 512) != 0) return PrintJobStatus.blocked;
      if ((status & 8192) != 0) return PrintJobStatus.retained;
      if ((status & 4096) != 0) return PrintJobStatus.completed;
      if ((status & 128) != 0) return PrintJobStatus.printed;
      if ((status & 256) != 0) return PrintJobStatus.canceled;
      if ((status & 4) != 0) return PrintJobStatus.deleting;
      if ((status & 2048) != 0) return PrintJobStatus.restarting;
      if ((status & 1) != 0) return PrintJobStatus.paused;
      if ((status & 16) != 0) return PrintJobStatus.processing;
      if ((status & 8) != 0) return PrintJobStatus.spooling;
      if (status == 0) return PrintJobStatus.pending;
      return PrintJobStatus.unknown;
    }

    if (Platform.isAndroid) {
      return switch (rawStatus) {
        1 => PrintJobStatus.pending,
        2 => PrintJobStatus.processing,
        3 => PrintJobStatus.processing,
        4 => PrintJobStatus.blocked,
        5 => PrintJobStatus.completed,
        6 => PrintJobStatus.canceled,
        7 => PrintJobStatus.error,
        _ => PrintJobStatus.unknown,
      };
    }

    return PrintJobStatus.unknown;
  }

  static bool isTerminal(PrintJobStatus status) {
    return switch (status) {
      PrintJobStatus.completed ||
      PrintJobStatus.printed ||
      PrintJobStatus.canceled ||
      PrintJobStatus.aborted ||
      PrintJobStatus.error =>
        true,
      _ => false,
    };
  }
}

extension PrintJobInfoStatus on PrintJobInfo {
  PrintJobStatus get parsedStatus => PrintJobStatusHelper.fromRaw(rawStatus);
}
