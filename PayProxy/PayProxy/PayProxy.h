//
//  PayProxy.h
//  PayProxy
//
//  Created by YLCHUN on 2018/3/28.
//  Copyright © 2018年 lrlz. All rights reserved.
//
//  自带接入错误校验

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
 处理通过URL启动App时传递的数据

 @param url 启动第三方应用时传递过来的URL
 @return 是否为支付回调的数据
 */
+(BOOL)handleOpenURL:(NSURL *) url;

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
