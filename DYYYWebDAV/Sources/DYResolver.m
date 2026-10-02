#import "DYResolver.h"
#import "DYConfig.h"

@implementation DYMediaItem
@end

static BOOL DYIsURLString(id value) {
    if (![value isKindOfClass:NSString.class]) return NO;
    NSString *s = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return s.length > 8 && ([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"]);
}

static NSString *DYTypeForKey(NSString *key) {
    NSString *k = key.lowercaseString;
    if ([k containsString:@"image"] || [k isEqualToString:@"img"] || [k containsString:@"photo"] || [k containsString:@"pic"] || [k containsString:@"cover"]) return @"image";
    if ([k containsString:@"music"] || [k containsString:@"audio"] || [k containsString:@"sound"]) return @"audio";
    if ([k containsString:@"live"] && [k containsString:@"video"]) return @"video";
    if ([k containsString:@"video"] || [k containsString:@"play"] || [k containsString:@"download"] || [k isEqualToString:@"url"] || [k containsString:@"media"]) return @"video";
    return nil;
}

static void DYWalkJSON(id node, NSString *hint, NSMutableArray<DYMediaItem *> *items, NSMutableSet<NSString *> *seen) {
    if ([node isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = node;
        // Prefer the most explicit URL fields before walking the object.
        NSArray *preferred = @[@"url", @"video_url", @"videoUrl", @"play_url", @"playUrl", @"download_url", @"downloadUrl", @"src", @"uri", @"image_url", @"imageUrl", @"cover_url", @"coverUrl", @"music_url", @"musicUrl", @"audio_url", @"audioUrl"];
        for (NSString *key in preferred) {
            id value = dict[key];
            if (DYIsURLString(value)) {
                NSString *type = DYTypeForKey(key) ?: hint ?: @"video";
                NSString *url = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (![seen containsObject:url]) {
                    DYMediaItem *m = [DYMediaItem new];
                    m.url = url;
                    m.type = type;
                    NSString *ext = [NSURL URLWithString:url].pathExtension.lowercaseString;
                    if (ext.length > 5 || ext.length == 0) {
                        if ([type isEqualToString:@"image"]) ext = @"jpg";
                        else if ([type isEqualToString:@"audio"]) ext = @"mp3";
                        else ext = @"mp4";
                    }
                    m.extension = ext;
                    [items addObject:m];
                    [seen addObject:url];
                }
            }
        }
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *childHint = DYTypeForKey(key) ?: hint;
            DYWalkJSON(obj, childHint, items, seen);
        }];
    } else if ([node isKindOfClass:NSArray.class]) {
        for (id obj in (NSArray *)node) DYWalkJSON(obj, hint, items, seen);
    } else if (DYIsURLString(node)) {
        NSString *url = [node stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![seen containsObject:url]) {
            DYMediaItem *m = [DYMediaItem new];
            m.url = url;
            m.type = hint ?: @"video";
            NSString *ext = [NSURL URLWithString:url].pathExtension.lowercaseString;
            if (ext.length > 5 || ext.length == 0) ext = [m.type isEqualToString:@"image"] ? @"jpg" : ([m.type isEqualToString:@"audio"] ? @"mp3" : @"mp4");
            m.extension = ext;
            [items addObject:m];
            [seen addObject:url];
        }
    }
}

@implementation DYResolver
+ (void)resolveShareURL:(NSString *)shareURL completion:(void (^)(NSArray<DYMediaItem *> *, NSString *))completion {
    NSString *base = [DYConfig shared].apiURL;
    if (base.length == 0) { completion(nil, @"解析 API 未配置"); return; }
    NSString *encoded = [shareURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString;
    if ([base containsString:@"{url}"]) urlString = [base stringByReplacingOccurrencesOfString:@"{url}" withString:encoded ?: @""];
    else {
        NSString *sep = [base containsString:@"?"] ? @"&" : @"?";
        urlString = [NSString stringWithFormat:@"%@%@url=%@", base, sep, encoded ?: @""];
    }
    NSURL *URL = [NSURL URLWithString:urlString];
    if (!URL) { completion(nil, @"解析 API 地址无效"); return; }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
    req.HTTPMethod = @"GET";
    req.timeoutInterval = 30;
    [req setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [req setValue:@"DYYYWebDAV/0.1" forHTTPHeaderField:@"User-Agent"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *err) {
        if (err) { dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, err.localizedDescription); }); return; }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, [NSString stringWithFormat:@"解析接口 HTTP %ld", (long)http.statusCode]); }); return;
        }
        NSError *je = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&je];
        if (!json) {
            NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (text.length > 0 && DYIsURLString(text)) json = @{ @"url": text };
            else { dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, @"解析接口返回的 JSON 无效"); }); return; }
        }

        NSMutableArray *items = [NSMutableArray array];
        NSMutableSet *seen = [NSMutableSet set];
        DYWalkJSON(json, nil, items, seen);

        // Filter obvious non-media URLs that recursive parsing can encounter.
        NSIndexSet *bad = [items indexesOfObjectsPassingTest:^BOOL(DYMediaItem *m, NSUInteger idx, BOOL *stop) {
            NSString *u = m.url.lowercaseString;
            return [u containsString:@"favicon"] || [u containsString:@"avatar"] || [u containsString:@"logo"] || [u hasSuffix:@".css"] || [u hasSuffix:@".js"];
        }];
        if (bad.count) [items removeObjectsAtIndexes:bad];

        if (items.count == 0) {
            NSString *msg = nil;
            if ([json isKindOfClass:NSDictionary.class]) {
                for (NSString *key in @[@"msg", @"message", @"error", @"detail", @"errmsg"]) {
                    id v = json[key]; if ([v isKindOfClass:NSString.class] && [v length]) { msg = v; break; }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{ completion(nil, msg ?: @"接口没有返回可下载资源"); });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(items, nil); });
    }];
    [task resume];
}
@end
