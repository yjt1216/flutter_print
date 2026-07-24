#ifndef FLUTTER_PLUGIN_FLUTTER_PRINT_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_PRINT_PLUGIN_H_

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "messages.h"

#include <atomic>
#include <functional>
#include <memory>
#include <optional>
#include <string>

namespace flutter_print {

class FlutterPrintPlugin : public flutter::Plugin, public FlutterPrintApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit FlutterPrintPlugin(HWND hwnd);
  ~FlutterPrintPlugin() override;

  FlutterPrintPlugin(const FlutterPrintPlugin&) = delete;
  FlutterPrintPlugin& operator=(const FlutterPrintPlugin&) = delete;

  // FlutterPrintApi
  void Print(const std::string& file_path, const PrintOptions* options,
             std::function<void(std::optional<FlutterError> reply)> result) override;
  void PrintPreview(const std::string& file_path, const PrintOptions* options,
                    std::function<void(std::optional<FlutterError> reply)> result) override;
  void PickPrinter(
      std::function<void(ErrorOr<std::optional<PrinterInfo>>)> result) override;
  void ListPrinters(
      std::function<void(ErrorOr<flutter::EncodableList>)> result) override;
  void ListPrintJobs(
      const std::string& printer_address,
      std::function<void(ErrorOr<flutter::EncodableList> reply)> result) override;
  void PrintSubmit(
      const std::string& file_path, const PrintOptions* options,
      std::function<void(ErrorOr<int64_t> reply)> result) override;
  void CancelPrintJob(
      const std::string& printer_address, int64_t job_id,
      std::function<void(ErrorOr<bool> reply)> result) override;
  void PausePrintJob(
      const std::string& printer_address, int64_t job_id,
      std::function<void(ErrorOr<bool> reply)> result) override;
  void ResumePrintJob(
      const std::string& printer_address, int64_t job_id,
      std::function<void(ErrorOr<bool> reply)> result) override;

  // Windows-specific extras: PDF preview rendering for the Flutter print dialog.
  void HandleWindowsMethod(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // Synchronous core of Print(); the public override forwards its result to the
  // Pigeon completion callback.
  std::optional<FlutterError> PrintInternal(const std::string& file_path,
                                            const PrintOptions* options,
                                            int* out_job_id = nullptr);

  using WinResult =
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>;

  void HandleGetMimeType(const flutter::EncodableMap& args, WinResult result);
  void HandleGetPdfPageCount(const flutter::EncodableMap& args, WinResult result);
  void HandleRenderPdfPageToPng(const flutter::EncodableMap& args, WinResult result);
  void HandleDecodeTextFile(const flutter::EncodableMap& args, WinResult result);
  void HandleGetMinimumMargins(const flutter::EncodableMap& args, WinResult result);
  void HandleOpenInDefaultApp(const flutter::EncodableMap& args, WinResult result);

  HWND hwnd_;
  std::shared_ptr<std::atomic<bool>> alive_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      windows_channel_;
};

}  // namespace flutter_print

#endif  // FLUTTER_PLUGIN_FLUTTER_PRINT_PLUGIN_H_
