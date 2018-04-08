//
//  PayProxy.h
//  PayProxy
//
//  Created by YLCHUN on 2018/3/28.
//  Copyright © 2018年 lrlz. All rights reserved.
//
//  白名单配置 Info.plist[@"LSApplicationQueriesSchemes"] >= @[@"weixin", @"alipay"]

#import <Foundation/Foundation.h>
#import "Singleton.h"

@interface PayProxy : Singleton
@end


@interface PayProxy (extension)

/**
 注册微信 APPID

 @param appKey 设置项目属性中的URL Schemes，微信开放平台APP的唯一标识APPID
 */
+(void)registerWXAppKey:(NSString *)appKey;

/**
 注册支付宝 URL Schemes

 @param appKey 设置项目属性中的URL Schemes
 */
+(void)registerAliAppKey:(NSString *)appKey;

/**
 微信支付

 @param signData 签名后的数据
 @param callback 支付回调
 */
+(void)wxPay:(NSDictionary*)signData callback:(void(^)(BOOL success))callback;

/**
 支付宝支付
 
 @param signData 签名后的数据
 @param callback 支付回调
 */
+(void)aliPay:(NSString*)signData callback:(void(^)(BOOL success))callback;
@end


