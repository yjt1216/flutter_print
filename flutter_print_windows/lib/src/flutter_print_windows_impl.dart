import 'package:flutter/widgets.dart';
import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

import 'print_preview/windows_print_dialog.dart';

class FlutterPrintWindowsImpl extends FlutterPrintPlatform {
  final _api = FlutterPrintApi();

  @override
  Future<void> print(String filePath, {PrintOptions? options}) {
    return _api.print(filePath, options: options);
  }

  @override
  Future<void> printPreview(
    String filePath, {
    PrintOptions? options,
    required BuildContext context,
  }) {
    if (!context.mounted) return Future.value();
    return showWindowsPrintDialog(context, filePath, options);
  }

  @override
  Future<List<PrinterInfo>> listPrinters() => _api.listPrinters();

  @override
  Future<PrinterInfo?> pickPrinter() => _api.pickPrinter();

  @override
  Future<List<PrintJobInfo>> listPrintJobs(String printerAddress) =>
      _api.listPrintJobs(printerAddress);

  @override
  Future<int> printSubmit(String filePath, {PrintOptions? options}) =>
      _api.printSubmit(filePath, options: options);

  @override
  Future<bool> cancelPrintJob(String printerAddress, int jobId) =>
      _api.cancelPrintJob(printerAddress, jobId);

  @override
  Future<bool> pausePrintJob(String printerAddress, int jobId) =>
      _api.pausePrintJob(printerAddress, jobId);

  @override
  Future<bool> resumePrintJob(String printerAddress, int jobId) =>
      _api.resumePrintJob(printerAddress, jobId);

  @override
  Future<bool> setDefaultPrinter(String printerAddress) =>
      _api.setDefaultPrinter(printerAddress);
}
