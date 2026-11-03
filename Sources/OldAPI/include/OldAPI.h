#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Same shape as +[SFSpeechRecognizer requestAuthorization:]: a plain block named
/// `handler`, called back on a background queue. Closures from main-actor code keep
/// their isolation here, so Swift 6 mode checks them on entry.
@interface OldAPI : NSObject
+ (void)requestAnswer:(void (^)(NSInteger status))handler;
@end

/// Identical, except that the block is named `completionHandler`. Swift can import this
/// method as `async`, so since Swift 6.2 (SE-0463) the callback is `@Sendable`.
@interface OldAPICompletion : NSObject
+ (void)requestAnswer:(void (^)(NSInteger status))completionHandler;
@end

NS_ASSUME_NONNULL_END
