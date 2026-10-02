#import <UIKit/UIKit.h>
#import "Sources/DYTransfer.h"
#import "Sources/DYSettings.h"

@interface AWEAwemeModel : NSObject
@property(nonatomic, copy) NSString *shareURL;
@end
@interface AWELongPressPanelBaseViewModel : NSObject
@property(nonatomic, strong) AWEAwemeModel *awemeModel;
@property(nonatomic, assign) NSInteger actionType;
@property(nonatomic, copy) NSString *duxIconName;
@property(nonatomic, copy) NSString *describeString;
@property(nonatomic, copy) void (^action)(void);
@end
@interface AWELongPressPanelViewGroupModel : NSObject
@property(nonatomic, assign) NSInteger groupType;
@property(nonatomic, assign) BOOL isModern;
@property(nonatomic, strong) NSArray *groupArr;
@end

static UIViewController *DYTopVC(void){ UIWindow *w=UIApplication.sharedApplication.keyWindow; UIViewController *v=w.rootViewController; while(v.presentedViewController)v=v.presentedViewController; return v; }
static NSArray *DYAppend(NSArray *orig, AWEAwemeModel *model){
    if(!model.shareURL.length) return orig ?: @[];
    Class vmc=NSClassFromString(@"AWELongPressPanelBaseViewModel"); Class gc=NSClassFromString(@"AWELongPressPanelViewGroupModel");
    if(!vmc||!gc)return orig ?: @[];
    NSMutableArray *items=[NSMutableArray array];
    AWELongPressPanelBaseViewModel *upload=[[%c(AWELongPressPanelBaseViewModel) alloc] init]; upload.awemeModel=model; upload.actionType=9001; upload.duxIconName=@"ic_cloudarrowdown_outlined_20"; upload.describeString=@"解析并上传"; upload.action=^{[DYTransfer startWithShareURL:model.shareURL];}; [items addObject:upload];
    AWELongPressPanelBaseViewModel *settings=[[%c(AWELongPressPanelBaseViewModel) alloc] init]; settings.awemeModel=model; settings.actionType=9002; settings.duxIconName=@"ic_setting_outlined"; settings.describeString=@"WebDAV 设置"; settings.action=^{[DYSettings presentFrom:DYTopVC()];}; [items addObject:settings];
    AWELongPressPanelViewGroupModel *g=[[%c(AWELongPressPanelViewGroupModel) alloc] init]; g.groupType=11; g.isModern=YES; g.groupArr=items; NSMutableArray *out=[NSMutableArray arrayWithObject:g]; if(orig)[out addObjectsFromArray:orig]; return out;
}
%hook AWEModernLongPressPanelTableViewController
- (NSArray *)dataArray { return DYAppend(%orig, [self valueForKey:@"awemeModel"]); }
%end
%hook AWELongPressPanelTableViewController
- (NSArray *)dataArray { return DYAppend(%orig, [self valueForKey:@"awemeModel"]); }
%end
