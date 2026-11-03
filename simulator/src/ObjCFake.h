#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/// Same shape as +[SFSpeechRecognizer requestAuthorization:]: a plain Objective-C block
/// with no Sendable annotation, called back on a background queue.
@interface ObjCFake : NSObject
+ (void)answerOffMain:(void (^)(NSInteger status))handler;
/// Same, but the block carries Apple's Sendable annotation, the shape URLSession and PHPhotoLibrary use.
+ (void)answerOffMainSendable:(void (NS_SWIFT_SENDABLE ^)(NSInteger status))handler;
@end
NS_ASSUME_NONNULL_END
