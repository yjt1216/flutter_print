#include "print_jobs.h"

#include <windows.h>

#include "flutter_print_utils.h"

namespace flutter_print {

std::vector<JobEntry> ListPrintJobsForPrinter(const std::wstring& printer_name) {
  std::vector<JobEntry> result;
  if (printer_name.empty()) return result;

  HANDLE hPrinter = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &hPrinter, nullptr)) {
    return result;
  }

  DWORD needed = 0;
  DWORD returned = 0;
  EnumJobsW(hPrinter, 0, 0xFFFFFFFF, 2, nullptr, 0, &needed, &returned);
  if (needed == 0) {
    ClosePrinter(hPrinter);
    return result;
  }

  std::vector<BYTE> buffer(needed);
  if (!EnumJobsW(hPrinter, 0, 0xFFFFFFFF, 2, buffer.data(), needed, &needed,
                 &returned)) {
    ClosePrinter(hPrinter);
    return result;
  }

  auto* jobs = reinterpret_cast<JOB_INFO_2W*>(buffer.data());
  result.reserve(returned);
  for (DWORD i = 0; i < returned; ++i) {
    JobEntry entry;
    entry.id = static_cast<int>(jobs[i].JobId);
    entry.title = WideToUtf8(jobs[i].pDocument ? jobs[i].pDocument : L"");
    entry.raw_status = static_cast<int>(jobs[i].Status);
    result.push_back(std::move(entry));
  }

  ClosePrinter(hPrinter);
  return result;
}

bool CancelPrintJobOnPrinter(const std::wstring& printer_name, int job_id) {
  if (printer_name.empty() || job_id <= 0) return false;

  HANDLE hPrinter = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &hPrinter, nullptr)) {
    return false;
  }

  const BOOL ok = SetJobW(hPrinter, static_cast<DWORD>(job_id), 0, nullptr,
                          JOB_CONTROL_CANCEL);
  ClosePrinter(hPrinter);
  return ok != FALSE;
}

bool PausePrintJobOnPrinter(const std::wstring& printer_name, int job_id) {
  if (printer_name.empty() || job_id <= 0) return false;
  HANDLE hPrinter = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &hPrinter, nullptr)) {
    return false;
  }
  const BOOL ok = SetJobW(hPrinter, static_cast<DWORD>(job_id), 0, nullptr,
                          JOB_CONTROL_PAUSE);
  ClosePrinter(hPrinter);
  return ok != FALSE;
}

bool ResumePrintJobOnPrinter(const std::wstring& printer_name, int job_id) {
  if (printer_name.empty() || job_id <= 0) return false;
  HANDLE hPrinter = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &hPrinter, nullptr)) {
    return false;
  }
  const BOOL ok = SetJobW(hPrinter, static_cast<DWORD>(job_id), 0, nullptr,
                          JOB_CONTROL_RESUME);
  ClosePrinter(hPrinter);
  return ok != FALSE;
}

}  // namespace flutter_print
