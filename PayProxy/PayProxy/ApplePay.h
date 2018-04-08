//
//  ApplePay.h
//  PayProxy
//
//  Created by YLCHUN on 2018/4/6.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//
//  服务器未对接调试

#import <Foundation/Foundation.h>
#import "Singleton.h"

@interface ApplePay : Singleton
+(instancetype)share;

//-(void)setMerchantId:(NSString*)merchantId serverAuth:(void(^)(NSData *token, void(^authRet)(BOOL success, NSString *errMsg)))authCallback;
-(void)setMerchantId:(NSString*)merchantId authUrl:(NSString*)authUrl;
/**
 <#Description#>

 @param data <#data description#>
 
 countryCode
 currencyCode
 merchantId
 orderNum
 amount
 merchantName
 
 @param callback <#callback description#>
 */
-(void)aplePay:(NSDictionary *)data callback:(void(^)(BOOL success))callback;

/*
 -(void)applePay {
 NSDictionary *orderData = @{@"orderNum":@"123456", @"amount":@"100.0", @"merchantName":@"商户名称"};
 [[ApplePay share] aplePay:orderData callback:^(BOOL success) {
 if (success) {
 //支付成功 ...
 }else {
 //支付失败 ...
 }
 }];
 }
 */
@end
