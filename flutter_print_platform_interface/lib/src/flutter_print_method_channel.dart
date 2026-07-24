import 'package:flutter/widgets.dart';

import '../flutter_print_platform_interface.dart';

class MethodChannelFlutterPrint extends FlutterPrintPlatform {
  @visibleForTesting
  FlutterPrintApi api = FlutterPrintApi();

  @override
  Future<void> print(String filePath, {PrintOptions? options}) =>
      api.print(filePath, options: options);

  @override
  Future<void> printPreview(
    String filePath, {
    PrintOptions? options,
    required BuildContext context,
  }) => api.printPreview(filePath, options: options);

  @override
  Future<List<PrinterInfo>> listPrinters() => api.listPrinters();

  @override
  Future<PrinterInfo?> pickPrinter() => api.pickPrinter();

  @override
  Future<List<PrintJobInfo>> listPrintJobs(String printerAddress) =>
      api.listPrintJobs(printerAddress);

  @override
  Future<int> printSubmit(String filePath, {PrintOptions? options}) =>
      api.printSubmit(filePath, options: options);

  @override
  Future<void> cancelPrintJob(String printerAddress, int jobId) =>
      api.cancelPrintJob(printerAddress, jobId);
}
