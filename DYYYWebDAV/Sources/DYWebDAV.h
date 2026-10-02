#import <Foundation/Foundation.h>
@interface DYWebDAV : NSObject
+ (void)ensureDirectoryThenUploadFile:(NSURL *)fileURL filename:(NSString *)filename contentType:(NSString *)contentType completion:(void (^)(BOOL, NSString *))completion;
+ (void)testConnection:(void (^)(BOOL, NSString *))completion;
@end
