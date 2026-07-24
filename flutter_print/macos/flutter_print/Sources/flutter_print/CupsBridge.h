#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterPrintCupsJobInfo : NSObject
@property(nonatomic) int64_t jobId;
@property(nonatomic, copy) NSString *title;
@property(nonatomic) int64_t rawStatus;
@end

/// Lists jobs on CUPS destination `dest` (queue name). Empty string uses default printer.
NSArray<FlutterPrintCupsJobInfo *> *FlutterPrintCupsListJobs(NSString *_Nullable dest);

/// Submits `path` to `dest`. Returns job id (>0) or 0 on failure; sets `errorOut` when non-nil.
int FlutterPrintCupsSubmitFile(NSString *_Nullable dest,
                               NSString *path,
                               NSString *_Nullable title,
                               int copies,
                               BOOL landscape,
                               BOOL monochrome,
                               int duplexMode,  // 0 none, 1 long, 2 short
                               NSError **_Nullable errorOut);

BOOL FlutterPrintCupsCancelJob(NSString *_Nullable dest, int64_t jobId);
BOOL FlutterPrintCupsHoldJob(NSString *_Nullable dest, int64_t jobId);
BOOL FlutterPrintCupsReleaseJob(NSString *_Nullable dest, int64_t jobId);

NS_ASSUME_NONNULL_END
