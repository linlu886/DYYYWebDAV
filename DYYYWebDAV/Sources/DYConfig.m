#import "DYConfig.h"

static NSString * const kAPI = @"DYWebDAV.APIURL";
static NSString * const kDAV = @"DYWebDAV.WebDAVURL";
static NSString * const kUser = @"DYWebDAV.Username";
static NSString * const kPass = @"DYWebDAV.Password";
static NSString * const kPath = @"DYWebDAV.RemotePath";
static NSString * const kAuto = @"DYWebDAV.AutoUpload";

@implementation DYConfig
+ (instancetype)shared { static DYConfig *x; static dispatch_once_t once; dispatch_once(&once, ^{ x=[DYConfig new]; [x load]; }); return x; }
- (instancetype)init { if ((self=[super init])) { _apiURL=@"https://api.51web.eu.org/"; _webdavURL=@""; _remotePath=@"/Douyin/"; _autoUpload=YES; } return self; }
- (void)load { NSUserDefaults *d=[NSUserDefaults standardUserDefaults]; NSString *s;
    s=[d stringForKey:kAPI]; if(s.length) _apiURL=s; s=[d stringForKey:kDAV]; if(s.length) _webdavURL=s;
    s=[d stringForKey:kUser]; if(s) _username=s; s=[d stringForKey:kPass]; if(s) _password=s;
    s=[d stringForKey:kPath]; if(s.length) _remotePath=s; if([d objectForKey:kAuto]) _autoUpload=[d boolForKey:kAuto]; }
- (void)save { NSUserDefaults *d=[NSUserDefaults standardUserDefaults]; [d setObject:self.apiURL ?: @"" forKey:kAPI]; [d setObject:self.webdavURL ?: @"" forKey:kDAV]; [d setObject:self.username ?: @"" forKey:kUser]; [d setObject:self.password ?: @"" forKey:kPass]; [d setObject:self.remotePath ?: @"/Douyin/" forKey:kPath]; [d setBool:self.autoUpload forKey:kAuto]; [d synchronize]; }
@end
