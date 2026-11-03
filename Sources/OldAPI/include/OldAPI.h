#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OldAPI : NSObject

/// Same shape as +[SFSpeechRecognizer requestAuthorization:]: a plain block named
/// `handler`, called back on a background queue. Closures from main-actor code keep
/// their isolation here, so Swift 6 mode checks them on entry.
+ (void)requestAnswer:(void (^)(NSInteger status))handler;

/// Identical, except that the block is named `completionHandler`. Swift can import this
/// method as `async`, so since Swift 6.2 (SE-0463) the callback is `@Sendable`.
+ (void)fetchAnswer:(void (^)(NSInteger status))completionHandler;

@end

NS_ASSUME_NONNULL_END
