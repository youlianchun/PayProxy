//
//  PayProxy.m
//  JYC
//
//  Created by YLCHUN on 2018/3/28.
//  Copyright © 2018年 lrlz. All rights reserved.
//

#import "PayProxy.h"
#import <AlipaySDK/AlipaySDK.h>
#import "WXApi.h"
#import "InterceptHandleOpenURL.h"

static NSString * const kwxPay = @"wxPay";
static NSString * const kaliPay = @"aliPay";

@interface PayProxy()<WXApiDelegate>
{
    NSString *_payType;
    void(^_callback)(BOOL success);

    NSString *_wxAppkey;
    NSString *_aliAppkey;
}
@end
@implementation PayProxy

-(instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (_payType == kwxPay || _payType == kaliPay)
    {
        [self logErr:-99 msg:@"用户放弃支付：其他途径返回app"];
        [self callPayResult:NO];
    }
}

-(void)registerWXAppKey:(NSString *)appKey
{
    _wxAppkey = appKey;
    [WXApi registerApp:_wxAppkey];
}

-(void)registerAliAppKey:(NSString *)appKey
{
    _aliAppkey = appKey;
}

-(void)wxPay:(NSDictionary*)signData callback:(void(^)(BOOL success))callback
{
    _payType = kwxPay;
    _callback = callback;
    if (_wxAppkey.length == 0) {
        [self regErr];
        return;
    }
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = signData[@"partnerid"];
    request.prepayId = signData[@"prepayid"];
    request.package = signData[@"package"];
    request.nonceStr = signData[@"noncestr"];
    request.timeStamp = [signData[@"timestamp"] unsignedIntValue];
    request.sign = signData[@"sign"];
    if (![WXApi sendReq:request]) {
        [self logErr:WXErrCodeCommon msg:@"原因：签名数据错误。"];
        [self callPayResult:NO];
    }
}

-(void)aliPay:(NSString*)signData callback:(void(^)(BOOL success))callback
{
    _payType = kaliPay;
    _callback = callback;
    if (_aliAppkey.length == 0) {
        [self regErr];
        return;
    }
    [[AlipaySDK defaultService] payOrder:signData fromScheme:_aliAppkey callback:[self aliPayCallback]];
}

-(BOOL)handleOpenURL:(NSURL *) url
{
    if ([self alipayHandleOpenURL:url]) return YES;
    if ([self wxpayHandleOpenURL:url]) return YES;
    return NO;
}

-(BOOL)wxpayHandleOpenURL:(NSURL *) url
{
    if (_payType == kwxPay && [url.scheme isEqualToString:_wxAppkey]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    return NO;
}

- (void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[PayResp class]]) {
        BOOL success = resp.errCode == WXSuccess;
        if (!success) {
            [self logErr:resp.errCode msg:resp.errStr];
        }
        [self callPayResult:success];
    }
}

-(BOOL)alipayHandleOpenURL:(NSURL *) url
{
    if (_payType == kaliPay && [url.scheme isEqualToString:_aliAppkey]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:[self aliPayCallback]];
        return YES;
    }
    return NO;
}

-(CompletionBlock)aliPayCallback
{
    static CompletionBlock kCallback;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kCallback = ^(NSDictionary *resultDic) {
            int code = [resultDic[@"resultStatus"] intValue];
            BOOL success = code == 9000;
            if (!success) {
                [self logErr:code msg:resultDic[@"result"]];
            }
            [self callPayResult:success];
        };
    });
    return kCallback;
}

-(void)callPayResult:(BOOL) success
{
    _payType = nil;
    if (_callback)
    {
        void(^callback)(BOOL success) = _callback;
        _callback = nil;
        callback(success);
    }
}

-(void)logErr:(int)code msg:(NSString*)msg
{
    NSLog(@"PayProxyError: %@, code: %d, message: %@", _payType, code, msg);
}

-(void)regErr
{
    NSString *clsStr = NSStringFromClass([[UIApplication sharedApplication].delegate class]);
    NSString *err = [NSString stringWithFormat:@"原因：PayProxy尚未注册Appkey。请检查 -[%@ application: didFinishLaunchingWithOptions: ]", clsStr];
    [self logErr:-100 msg:err];
    [self callPayResult:NO];
}

@end


#pragma mark - extension 方法扩展
@implementation PayProxy (extension)
+(instancetype)share {
    return [[self alloc] init];
}

+(BOOL)handleOpenURL:(NSURL *) url {
    if ([[PayProxy share] handleOpenURL:url]) return YES;
    return NO;
}
+(void)registerWXAppKey:(NSString *)appKey {
    [[PayProxy share] registerWXAppKey:appKey];
}
+(void)registerAliAppKey:(NSString *)appKey {
    [[PayProxy share] registerAliAppKey:appKey];
}
+(void)wxPay:(NSDictionary*)signData callback:(void(^)(BOOL success))callback {
    [[PayProxy share] wxPay:signData callback:callback];
}
+(void)aliPay:(NSString*)signData callback:(void(^)(BOOL success))callback {
    [[PayProxy share] aliPay:signData callback:callback];
}

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_t queue = dispatch_queue_create("listening", NULL);
        dispatch_async(queue, ^{
            while (!UIApplication.sharedApplication) {}
            interceptHandleOpenURL(^BOOL(NSURL *url) {
                return [self handleOpenURL:url];
            });
        });
    });
}
@end

