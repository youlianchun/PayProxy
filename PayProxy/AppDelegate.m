//
//  AppDelegate.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/2.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "AppDelegate.h"
#import "PayProxy.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:@"pay://"];
//        [application openURL:url];
//        [self application:application handleOpenURL:url];
        [self application:application openURL:url options:@{}];

//    });
    return YES;
}
//-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
//    return YES;
//}
//-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
//    [self application:app openURL:url sourceApplication:nil annotation:self];
//    return YES;
//}
//-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//    return YES;
//}
@end

@implementation AppDelegate (pay)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PayProxy registerWXAppKey:@"wx73acdf06232c6a33"];
        [PayProxy registerAliAppKey:@"aliPayOpen"];
    });
}
@end
