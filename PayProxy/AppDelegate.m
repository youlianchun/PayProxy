//
//  AppDelegate.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/2.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "AppDelegate.h"
#import "PayProxy.h"
#import "ApplePay.h"

// 全局查找替换 (shift + command + f)
static NSString * const kAliPayKey = @"aliPayOpen";
static NSString * const kWxPayKey = @"wx73acdf06232c6a33";

@interface AppDelegate ()

@end

@implementation AppDelegate


-(void)registerPayProxy {
    [PayProxy registerWXAppKey:kWxPayKey];
    [PayProxy registerAliAppKey:kAliPayKey];
    [[ApplePay share] setMerchantId:@"com.ylchun.PayProxy" authUrl:@"https://payproxy.com.cn/auth"];
    
//    [[ApplePay share] setMerchantId:@"com.ylchun.PayProxy" serverAuth:^(NSData *token, void (^authRet)(BOOL success, NSString *errMsg)) {
//        [self uploadApplePayToken:token callback:^(BOOL success, NSDictionary *ret) {
//            bool b = NO;
//            NSString *err;
//            if (success) {
//                int code = [ret[@"code"] intValue];
//                b = code == 200;
//                if (!b) {
//                    err = ret[@"message"];
//                }
//            }
//            authRet(b, err);
//        }];
//    }];
}

//-(void)uploadApplePayToken:(NSData*)token callback:(void(^)(BOOL success, NSDictionary *ret))callback {
//    callback(YES, @{@"code":@(200), @"message":@"success"});
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerPayProxy];
    
    //other ...
    return YES;
}

#pragma mark - UIApplicationDelegate openURL

// 4_2 ~ 9_0
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self handleOpenURL:url];
}
// 9_0 ~
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    return [self handleOpenURL:url];
}

#pragma mark -

- (BOOL)handleOpenURL:(NSURL*)url {
    if ([PayProxy handleOpenURL:url]) return YES;
    //other ...
    return YES;
}

@end

