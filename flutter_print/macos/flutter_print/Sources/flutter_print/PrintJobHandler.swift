import Cocoa

extension FlutterPrintPlugin {
  func listPrintJobs(
    printerAddress: String,
    completion: @escaping (Result<[PrintJobInfo], any Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let dest: NSString? = printerAddress.isEmpty
        ? nil
        : printerAddress as NSString
      let jobs = FlutterPrintCupsListJobs(dest)
      let mapped: [PrintJobInfo] = jobs.compactMap { item in
        guard let job = item as? FlutterPrintCupsJobInfo else { return nil }
        return PrintJobInfo(
          id: job.jobId,
          title: job.title,
          rawStatus: job.rawStatus
        )
      }
      completion(.success(mapped))
    }
  }

  func printSubmit(
    filePath: String,
    options: PrintOptions?,
    completion: @escaping (Result<Int64, any Error>) -> Void
  ) {
    guard FileManager.default.fileExists(atPath: filePath) else {
      completion(.failure(PigeonError(
        code: "FILE_NOT_FOUND",
        message: "File not found: \(filePath)",
        details: nil)))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let dest: NSString? = {
        guard let addr = options?.printerAddress, !addr.isEmpty else { return nil }
        return addr as NSString
      }()
      var duplex = 0
      if let mode = options?.duplexMode {
        switch mode {
        case .longEdge: duplex = 1
        case .shortEdge: duplex = 2
        default: break
        }
      }
      let copies = options?.copies.map { Int($0) } ?? 1
      var nsError: NSError?
      let jobId = FlutterPrintCupsSubmitFile(
        dest,
        filePath as NSString,
        options?.documentTitle as NSString?,
        copies > 1 ? copies : 1,
        options?.landscape == true,
        options?.color == false,
        duplex,
        &nsError
      )
      if jobId > 0 {
        completion(.success(Int64(jobId)))
      } else if let nsError {
        completion(.failure(PigeonError(
          code: "PRINT_ERROR",
          message: nsError.localizedDescription,
          details: nil)))
      } else {
        completion(.success(-1))
      }
    }
  }

  func cancelPrintJob(
    printerAddress: String,
    jobId: Int64,
    completion: @escaping (Result<Bool, any Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let dest = printerAddress.isEmpty ? nil : printerAddress as NSString
      completion(.success(FlutterPrintCupsCancelJob(dest, jobId)))
    }
  }

  func pausePrintJob(
    printerAddress: String,
    jobId: Int64,
    completion: @escaping (Result<Bool, any Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let dest = printerAddress.isEmpty ? nil : printerAddress as NSString
      completion(.success(FlutterPrintCupsHoldJob(dest, jobId)))
    }
  }

  func resumePrintJob(
    printerAddress: String,
    jobId: Int64,
    completion: @escaping (Result<Bool, any Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let dest = printerAddress.isEmpty ? nil : printerAddress as NSString
      completion(.success(FlutterPrintCupsReleaseJob(dest, jobId)))
    }
  }
}
