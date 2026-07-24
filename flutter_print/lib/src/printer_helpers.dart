import 'package:flutter_print_platform_interface/flutter_print_platform_interface.dart';

/// Returns the system default printer, or the first listed printer.
Future<PrinterInfo?> getDefaultPrinter({FlutterPrintPlatform? platform}) async {
  final api = platform ?? FlutterPrintPlatform.instance;
  final printers = await api.listPrinters();
  for (final p in printers) {
    if (p.isDefault) return p;
  }
  return printers.isEmpty ? null : printers.first;
}

/// Maps a saved display name or queue name to [PrinterInfo.address].
///
/// On Windows/Linux the queue name is usually both [PrinterInfo.label] and
/// [PrinterInfo.address]. Matching is case-insensitive when exact match fails.
Future<String?> resolvePrinterAddress(
  String nameOrAddress, {
  FlutterPrintPlatform? platform,
}) async {
  final needle = nameOrAddress.trim();
  if (needle.isEmpty) return null;

  final api = platform ?? FlutterPrintPlatform.instance;
  final printers = await api.listPrinters();

  for (final p in printers) {
    if (p.address == needle || p.label == needle) return p.address;
  }

  final lower = needle.toLowerCase();
  for (final p in printers) {
    if (p.address?.toLowerCase() == lower || p.label.toLowerCase() == lower) {
      return p.address;
    }
  }
  return null;
}

/// Like [resolvePrinterAddress] but falls back to [nameOrAddress] when no
/// printer list entry matches (caller already has a queue name).
Future<String> resolvePrinterAddressOrSelf(
  String nameOrAddress, {
  FlutterPrintPlatform? platform,
}) async {
  final resolved = await resolvePrinterAddress(nameOrAddress, platform: platform);
  return resolved ?? nameOrAddress;
}
