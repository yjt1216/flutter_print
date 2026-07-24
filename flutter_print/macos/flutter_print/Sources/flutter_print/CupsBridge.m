#import "CupsBridge.h"

#include <cups/cups.h>

static const char *ResolveDest(NSString *_Nullable dest) {
  if (dest.length > 0) {
    return dest.UTF8String;
  }
  const char *def = cupsGetDefault();
  return def ? def : "";
}

@implementation FlutterPrintCupsJobInfo
@end

NSArray<FlutterPrintCupsJobInfo *> *FlutterPrintCupsListJobs(NSString *_Nullable dest) {
  const char *d = ResolveDest(dest);
  if (!d[0]) {
    return @[];
  }

  int num_jobs = 0;
  cups_job_t *jobs = cupsGetJobs(&num_jobs, d, 0, CUPS_WHICHJOBS_ALL);
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)num_jobs];
  for (int i = 0; i < num_jobs; i++) {
    FlutterPrintCupsJobInfo *info = [[FlutterPrintCupsJobInfo alloc] init];
    info.jobId = jobs[i].id;
    const char *title = jobs[i].title;
    info.title = title && title[0] ? @(title) : @"Print job";
    info.rawStatus = jobs[i].state;
    [result addObject:info];
  }
  cupsFreeJobs(num_jobs, jobs);
  return result;
}

int FlutterPrintCupsSubmitFile(NSString *_Nullable dest,
                               NSString *path,
                               NSString *_Nullable title,
                               int copies,
                               BOOL landscape,
                               BOOL monochrome,
                               int duplexMode,
                               NSError **_Nullable errorOut) {
  const char *d = ResolveDest(dest);
  if (!d[0]) {
    if (errorOut) {
      *errorOut = [NSError errorWithDomain:@"flutter_print"
                                      code:1
                                  userInfo:@{NSLocalizedDescriptionKey : @"No printer destination"}];
    }
    return 0;
  }

  int num_options = 0;
  cups_option_t *options = NULL;

  if (copies > 1) {
    num_options = cupsAddOption("copies", [[NSString stringWithFormat:@"%d", copies] UTF8String],
                                num_options, &options);
  }
  if (landscape) {
    num_options = cupsAddOption("orientation-requested", "4", num_options, &options);
  }
  if (monochrome) {
    num_options = cupsAddOption("print-color-mode", "monochrome", num_options, &options);
  }
  switch (duplexMode) {
    case 1:
      num_options = cupsAddOption("sides", "two-sided-long-edge", num_options, &options);
      break;
    case 2:
      num_options = cupsAddOption("sides", "two-sided-short-edge", num_options, &options);
      break;
    default:
      break;
  }

  const char *job_name =
      (title.length > 0) ? title.UTF8String : "Flutter Print Job";
  int job_id = cupsPrintFile(d, path.UTF8String, job_name, num_options, options);
  cupsFreeOptions(num_options, options);

  if (job_id == 0 && errorOut) {
    *errorOut = [NSError errorWithDomain:@"flutter_print"
                                    code:2
                                userInfo:@{NSLocalizedDescriptionKey : @(cupsLastErrorString())}];
  }
  return job_id;
}

BOOL FlutterPrintCupsCancelJob(NSString *_Nullable dest, int64_t jobId) {
  const char *d = ResolveDest(dest);
  if (!d[0]) return NO;
  ipp_status_t st = cupsCancelJob(d, (int)jobId);
  return st <= IPP_STATUS_OK_EVENTS_COMPLETE;
}

BOOL FlutterPrintCupsHoldJob(NSString *_Nullable dest, int64_t jobId) {
  const char *d = ResolveDest(dest);
  if (!d[0]) return NO;
  ipp_status_t st = cupsHoldJob(d, (int)jobId);
  return st <= IPP_STATUS_OK_EVENTS_COMPLETE;
}

BOOL FlutterPrintCupsReleaseJob(NSString *_Nullable dest, int64_t jobId) {
  const char *d = ResolveDest(dest);
  if (!d[0]) return NO;
  ipp_status_t st = cupsReleaseJob(d, (int)jobId);
  return st <= IPP_STATUS_OK_EVENTS_COMPLETE;
}
