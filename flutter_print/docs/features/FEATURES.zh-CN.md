# flutter_print 功能清单

用于排期与验收。状态：**已完成** / **部分** / **待做** / **应用层**（建议在 HeartMonitorx 做，插件只提供基础能力）。

---

## 1. 打印作业与状态流

| 功能 | 状态 | 说明 |
|------|------|------|
| `print` / `printPreview` / `printWidget` | 已完成 | 各平台已有实现 |
| `listPrinters` / `pickPrinter`（iOS） | 已完成 | Android/Web 枚举为空属预期 |
| `printSubmit` → jobId（或 -1） | 已完成 | Windows/Linux/Android；iOS/macOS 多为 -1 |
| `listPrintJobs` / `cancelPrintJob` | 已完成 | Windows Spooler、Linux CUPS、Android 跟踪作业 |
| `pausePrintJob` / `resumePrintJob` | 部分 | Windows/Linux 已实现；iOS/macOS/Web/Android 返回 false |
| `printWithStatus` / `watchPrintJob` | 已完成 | `Stream<PrintJobInfo>`，轮询 `listPrintJobs` |
| `PrintJobStatus` + `rawStatus` 解析 | 已完成 | Windows 位标志、CUPS 3–9、Android 映射 |
| `PrintJobCompletionMode.dequeueSuccess`（出队即成功） | 已完成 | 默认用于 `printWithStatus` / `printPdfAndStreamStatus` |
| `PrintJobCompletionMode.spoolerTerminal` | 已完成 | 见到 printed/completed 等即结束（printing_ffi 风格） |
| `treatRetainedAsSuccess` | 已完成 | Windows retained 可选当成功 |
| `printPdfAndStreamStatus` / `listPrintJobsStream` | 已完成 | printing_ffi 风格入口；按打印机名解析 address |
| `getDefaultPrinter` / `resolvePrinterAddress` | 已完成 | Dart 辅助 |
| `cancelPrintJob` 返回 `bool` | 已完成 | Pigeon 已改为 bool |
| 打印中合并 `printerStatus` 轮询 | 已完成 | `watchPrinterStatus` + `isBlockingOsPrinterStatus` |
| `spoolerComplete`（等 JOB_STATUS_COMPLETE + 出队 fallback） | 已完成 | [PrintJobCompletionMode.spoolerComplete] |
| 出队前要求见过 `printed`/`completed` | 已完成 | `requirePrintedBeforeDequeue` |
| macOS CUPS 队列 list/submit/cancel | 已完成 | `CupsBridge` + pause/resume |
| Web 作业状态 | 部分 | 仅 fallback（-1 + 单次 synthetic） |

---

## 2. 打印机信息与属性（识别机型 / Profile）

| 功能 | 状态 | 说明 |
|------|------|------|
| `PrinterInfo.label` / `address` | 已完成 | Windows 上多为队列名（如 KONICA MINOLTA C458SeriesPCL） |
| `PrinterInfo.details` | 部分 | Windows 为驱动注释 `pComment`，非「位置」 |
| `PrinterInfo.isAvailable` | 已完成 | macOS / Windows / Linux |
| `PrinterInfo.printerStatus`（原始位） | 已完成 | Windows `PRINTER_STATUS_*` |
| `describePrinterStatus()` | 已完成 | 粗粒度英文/通用文案 |
| **`driverName`（Windows `pDriverName`）** | 已完成 | `PrinterInfo.driverName` |
| **`portName`（USB / WSD / IP）** | 已完成 | `PrinterInfo.portName` |
| **`location`（Windows `pLocation`）** | 已完成 | `PrinterInfo.location`；Linux 用 `printer-location` 填 [details] |
| **`makeAndModel`（CUPS `printer-make-and-model`）** | 已完成 | Linux CUPS |
| **`deviceUri`（CUPS）** | 已完成 | Linux CUPS |
| `getPrinterProperties(queueName)` 聚合 API | 待做 | 对齐系统「打印机属性」对话框字段 |
| 按 profile 自动选厂家故障码表 | 应用层 | 插件提供识别字段 + OS 状态；0x11–0x14 表在业务配置 |

---

## 3. 打印选项与文档

| 功能 | 状态 | 说明 |
|------|------|------|
| `PrintOptions`（纸张、份数、颜色、双面等） | 已完成 | 各平台支持度见主 README 表 |
| `PrintOptions.documentTitle` | 已完成 | Windows GDI / Linux CUPS |
| PDF scaling / 页范围 / 对齐（printing_ffi 级） | 待做 | Windows DEVMODE / PDFium 暴露 |
| Windows 纸型/纸盒/介质 **ID**（capabilities） | 待做 | 对标 `getWindowsPrinterCapabilities` |

---

## 4. 故障与成功判定（产品语义）

| 功能 | 状态 | 说明 |
|------|------|------|
| Job 硬失败：`error` / `canceled` / `aborted` | 已完成 | `PrintJobStatusHelper.isFailure` + dequeue 模式下立即结束 |
| Job 软/阻断：`paperOut` / `userIntervention` / `blocked` | 部分 | 已解析为 enum，**未默认当 isFailure** |
| 统一 `PrintFaultType` + 阻断/预警 | 待做 | 可选插件层 `classifyPrintFault(job, printer)` |
| 厂家 SDK 状态（0–4 连接、0x10–0x14 设备） | 应用层 | 非 OS Spooler 标准码；与 SDK 并行 |
| 成功 = 出队 ∧ 无阻断故障 | 应用层 | 插件提供出队 + 状态；业务合并 SDK |
| IPP `printer-state-reasons` / `job-state-reasons` | 待做 | Linux 细粒度故障语义（keyword，非 0x11） |

---

## 5. 平台与兼容

| 功能 | 状态 | 说明 |
|------|------|------|
| `flutter_print_windows` 转发 job Pigeon API | 已完成 | `FlutterPrintWindowsImpl` |
| Windows 离线 PDFium vendor | 已完成 | 见根 README |
| printing_ffi 命名兼容（`printPdfAndStreamStatus` 等） | 已完成 | 见 `print_job_flow.dart` |
| `openPrinterProperties`（系统属性对话框） | 待做 | Windows 可选 |
| `rawDataToPrinter` / 字节直打 | 待做 | 心电 PDF 场景优先级低 |
| 同步 `listPrinters` | 不需要 | 保持 async |

---

## 6. 文档与示例

| 功能 | 状态 | 说明 |
|------|------|------|
| 主 README 打印作业状态章节 | 已完成 | `flutter_print/README.md` |
| Example `[flutter_print_example]` 日志 | 已完成 | direct print + list jobs |
| 打印作业生命周期 / 故障模型说明 | 待做 | 可链到 `docs/` 专题 |
| 本功能清单 | 已完成 | 本文件 |

---

## 7. 建议实现顺序（插件内）

1. **Windows `documentTitle` → 队列显示名**（心电「检测报告」）
2. **扩展 `PrinterInfo`：`driverName` / `portName` / `location`；CUPS `makeAndModel`**
3. **打印中 `printerStatus` + 扩展 `isBlockingFault`**
4. **macOS CUPS 作业 API**（若 macOS 生产需要状态流）
5. **Linux IPP reasons（可选）**、Windows 属性对话框、PDF 高级选项

---

## 8. 参考（外部标准，非本仓库实现）

- Windows：[JOB_STATUS_*](https://learn.microsoft.com/en-us/windows/win32/printdocs/job-status)、[PRINTER_STATUS_*](https://learn.microsoft.com/en-us/windows/win32/printdocs/printer-status)
- CUPS / IPP：job-state 3–9，`printer-state-reasons`（RFC 8011 / PWG）
- 厂家故障码：设备 SDK / 协议 PDF（如图 0x11–0x14），**非**全行业统一十六进制表
