#import "ObjCFake.h"
@implementation ObjCFake
+ (void)answerOffMain:(void (^)(NSInteger status))handler {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ handler(3); });
}
+ (void)answerOffMainSendable:(void (NS_SWIFT_SENDABLE ^)(NSInteger status))handler {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ handler(3); });
}
@end
