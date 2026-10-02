#import "DYWebDAV.h"
#import "DYConfig.h"

@implementation DYWebDAV
+ (NSURL *)baseURL { NSString *s=[DYConfig shared].webdavURL; return [NSURL URLWithString:s]; }
+ (NSString *)authValue { NSString *x=[NSString stringWithFormat:@"%@:%@",[DYConfig shared].username ?: @"",[DYConfig shared].password ?: @""]; NSData *d=[x dataUsingEncoding:NSUTF8StringEncoding]; return [NSString stringWithFormat:@"Basic %@",[d base64EncodedStringWithOptions:0]]; }
+ (NSURL *)directoryURL { NSURL *base=[self baseURL]; if(!base)return nil; NSString *p=[DYConfig shared].remotePath ?: @"/Douyin/"; if(![p hasPrefix:@"/"])p=[@"/" stringByAppendingString:p]; if(![p hasSuffix:@"/"])p=[p stringByAppendingString:@"/"]; return [NSURL URLWithString:p relativeToURL:base]; }
+ (void)ensureDirectoryThenUploadFile:(NSURL *)fileURL filename:(NSString *)filename contentType:(NSString *)contentType completion:(void (^)(BOOL, NSString *))completion {
    if(![self baseURL] || ![DYConfig shared].webdavURL.length){ completion(NO,@"WebDAV 地址未配置"); return; }
    NSURL *dir=[self directoryURL]; if(!dir){ completion(NO,@"WebDAV 路径无效"); return; }
    NSMutableURLRequest *mk=[NSMutableURLRequest requestWithURL:dir]; mk.HTTPMethod=@"MKCOL"; [mk setValue:[self authValue] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *t=[[NSURLSession sharedSession] dataTaskWithRequest:mk completionHandler:^(NSData *d,NSURLResponse *r,NSError *e){
        NSInteger code=[(NSHTTPURLResponse *)r statusCode]; if(e || (code!=0 && code!=201 && code!=405)){ completion(NO,e.localizedDescription ?: [NSString stringWithFormat:@"MKCOL HTTP %ld",(long)code]); return; }
        NSString *safe=[filename stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]; NSURL *dest=[NSURL URLWithString:safe relativeToURL:dir];
        NSMutableURLRequest *put=[NSMutableURLRequest requestWithURL:dest]; put.HTTPMethod=@"PUT"; [put setValue:[self authValue] forHTTPHeaderField:@"Authorization"]; [put setValue:contentType ?: @"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionUploadTask *up=[[NSURLSession sharedSession] uploadTaskWithRequest:put fromFile:fileURL completionHandler:^(NSData *d2,NSURLResponse *r2,NSError *e2){ NSInteger c=[(NSHTTPURLResponse *)r2 statusCode]; BOOL ok=!e2 && c>=200 && c<300; completion(ok,ok?nil:(e2.localizedDescription ?: [NSString stringWithFormat:@"PUT HTTP %ld",(long)c])); }]; [up resume];
    }]; [t resume];
}
+ (void)testConnection:(void (^)(BOOL, NSString *))completion { NSURL *u=[self directoryURL]; if(!u){completion(NO,@"WebDAV 地址未配置");return;} NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:u]; r.HTTPMethod=@"OPTIONS"; [r setValue:[self authValue] forHTTPHeaderField:@"Authorization"]; [[[NSURLSession sharedSession] dataTaskWithRequest:r completionHandler:^(NSData*d,NSURLResponse*resp,NSError*e){ NSInteger c=[(NSHTTPURLResponse*)resp statusCode]; completion(!e && c>=200&&c<400,e?e.localizedDescription:[NSString stringWithFormat:@"HTTP %ld",(long)c]); }] resume]; }
@end
