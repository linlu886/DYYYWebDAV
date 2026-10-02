#import <Foundation/Foundation.h>

@interface DYConfig : NSObject
+ (instancetype)shared;
@property(nonatomic, copy) NSString *apiURL;
@property(nonatomic, copy) NSString *webdavURL;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *remotePath;
@property(nonatomic, assign) BOOL autoUpload;
- (void)save;
@end
