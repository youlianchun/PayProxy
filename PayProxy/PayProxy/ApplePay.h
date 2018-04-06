//
//  ApplePay.h
//  PayProxy
//
//  Created by YLCHUN on 2018/4/6.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

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

@end
