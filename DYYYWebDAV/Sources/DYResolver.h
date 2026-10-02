#import <Foundation/Foundation.h>
@interface DYMediaItem : NSObject
@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *type;
@property(nonatomic, copy) NSString *extension;
@end
@interface DYResolver : NSObject
+ (void)resolveShareURL:(NSString *)shareURL completion:(void (^)(NSArray<DYMediaItem *> *, NSString *))completion;
@end
