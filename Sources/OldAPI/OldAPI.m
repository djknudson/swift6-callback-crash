#import "OldAPI.h"

@implementation OldAPI

+ (void)requestAnswer:(void (^)(NSInteger status))handler {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
                   ^{ handler(3); });
}

+ (void)fetchAnswer:(void (^)(NSInteger status))completionHandler {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
                   ^{ completionHandler(3); });
}

@end
