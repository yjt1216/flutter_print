#pragma once

#include <optional>
#include <string>
#include <vector>

#include "messages.h"

namespace flutter_print {

struct JobEntry {
  int id;
  std::string title;
  int raw_status;
};

std::vector<JobEntry> ListPrintJobsForPrinter(const std::wstring& printer_name);

bool CancelPrintJobOnPrinter(const std::wstring& printer_name, int job_id);

}  // namespace flutter_print
