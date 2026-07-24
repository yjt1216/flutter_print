import Cocoa

extension FlutterPrintPlugin {
  func listPrintJobs(
    printerAddress: String,
    completion: @escaping (Result<[PrintJobInfo], any Error>) -> Void
  ) {
    completion(.success([]))
  }

  func printSubmit(
    filePath: String,
    options: PrintOptions?,
    completion: @escaping (Result<Int64, any Error>) -> Void
  ) {
    completion(.success(-1))
  }

  func cancelPrintJob(
    printerAddress: String,
    jobId: Int64,
    completion: @escaping (Result<Void, any Error>) -> Void
  ) {
    completion(.failure(PigeonError(
      code: "UNSUPPORTED",
      message: "cancelPrintJob is not supported on macOS",
      details: nil)))
  }
}
