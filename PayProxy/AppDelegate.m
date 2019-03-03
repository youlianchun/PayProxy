//
//  AppDelegate.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/2.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "AppDelegate.h"
#import "PayProxy.h"
#import <objc/runtime.h>

@interface AppDelegate ()

@end


@implementation AppDelegate
-(BOOL)respondsToSelector:(SEL)aSelector {
    if (sel_isEqual(@selector(application:handleOpenURL:), aSelector)) {
        NSLog(@"");
    }
    return [super respondsToSelector:aSelector];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

//Safair打来 payProxy://
-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return YES;
}

//-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
//    return YES;
//}

//-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//    return YES;
//}

@end

@implementation AppDelegate (pay)
+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PayProxy registerWXAppKey:@"wx73acdf06232c6a33"];
        [PayProxy registerAliAppKey:@"aliPayOpen"];
    });
}
@end
