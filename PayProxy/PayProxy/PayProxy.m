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

#pragma mark - interceptHandleOpenURL

#import <objc/runtime.h>
typedef BOOL(*IMP_29)(id, SEL, UIApplication *, NSURL *);
typedef BOOL(*IMP_49)(id, SEL, UIApplication *, NSURL *, NSString *, id);
typedef BOOL(*IMP_9n)(id, SEL, UIApplication *, NSURL *, NSDictionary *);

static void replaceMethod(Class cls, SEL sel, id(^getBlock)(IMP imp))
{
    Method method = class_getInstanceMethod(cls, sel);
    IMP imp = method_getImplementation(class_getInstanceMethod(cls, sel));
    IMP block = imp_implementationWithBlock(getBlock(imp));
    class_replaceMethod(cls, sel, block, method_getTypeEncoding(method));
}

static void interceptHandleOpenURL(BOOL(^handle)(NSURL *url))
{
    if (!handle) return;
    
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    Class cls = [delegate class];
    SEL sel_29 = @selector(application:handleOpenURL:);
    SEL sel_49 = @selector(application:openURL:sourceApplication:annotation:);
    SEL sel_9n = @selector(application:openURL:options:);
    
    BOOL has_sel_29 = [delegate respondsToSelector:sel_29];
    BOOL has_sel_49 = [delegate respondsToSelector:sel_49];
    BOOL has_sel_9n = [delegate respondsToSelector:sel_9n];
    
    if (has_sel_29) {
        replaceMethod(cls, sel_29, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url) {
                if (handle(url)) return YES;
                return ((IMP_29)imp)(self, sel_29, application, url);
            };
        });
    }
    else if (!has_sel_49) {
        IMP block = imp_implementationWithBlock(^BOOL(id self, UIApplication *application, NSURL *url) {
            return handle(url);
        });
        class_addMethod(cls, sel_29, block, "B@:@@");
    }
    
    if (has_sel_49) {
        replaceMethod(cls, sel_49, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation) {
                if (handle(url)) return YES;
                return ((IMP_49)imp)(self, sel_49, application, url, sourceApplication, annotation);
            };
        });
    }
    else if (!has_sel_29) {
        IMP block = imp_implementationWithBlock(^BOOL(id self, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation) {
            return handle(url);
        });
        class_addMethod(cls, sel_49, block, "B@:@@@@");
    }
    
    if (has_sel_9n) {
        replaceMethod(cls, sel_9n, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url, NSDictionary *options) {
                if (handle(url)) return YES;
                return ((IMP_9n)imp)(self, sel_9n, application, url, options);
            };
        });
    }
    else {
        IMP block = imp_implementationWithBlock(^BOOL(id self, UIApplication *application, NSURL *url, NSDictionary *options) {
            return handle(url);
        });
        class_addMethod(cls, sel_9n, block, "B@:@@@");
    }
}

#pragma mark - extension 方法扩展
@implementation PayProxy (extension)
+(instancetype)share {
    return [[self alloc] init];
}

+(void)defaultHandleOpenURL
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interceptHandleOpenURL(^BOOL(NSURL *url) {
            return [PayProxy handleOpenURL:url];
        });
    });
}

+(BOOL)handleOpenURL:(NSURL *) url {
    if ([[PayProxy share] handleOpenURL:url]) return YES;
    return NO;
}
+(void)registerWXAppKey:(NSString *)appKey {
    [[PayProxy share] registerWXAppKey:appKey];
    [self defaultHandleOpenURL];
}
+(void)registerAliAppKey:(NSString *)appKey {
    [[PayProxy share] registerAliAppKey:appKey];
    [self defaultHandleOpenURL];
}
+(void)wxPay:(NSDictionary*)signData callback:(void(^)(BOOL success))callback {
    [[PayProxy share] wxPay:signData callback:callback];
}
+(void)aliPay:(NSString*)signData callback:(void(^)(BOOL success))callback {
    [[PayProxy share] aliPay:signData callback:callback];
}
@end


//#pragma mark - verify 接入校验
//@implementation PayProxy (verify)
//static NSString * const kverify = @"verify";
//
//-(BOOL)verify
//{
//    static BOOL success = NO;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        success = [self verify_89] && [self verify_9n];
//        if (!success) {
//            NSString *clsStr = NSStringFromClass([[UIApplication sharedApplication].delegate class]);
//            NSString *err = [NSString stringWithFormat:@"PayProxyError: 请检App OpenURL查代理是否执行 +[PayProxy handleOpenURL:] \n\
//                             -[%@ application: handleOpenURL: ]\n\
//                             -[%@ application: openURL: sourceApplication: annotation: ]\n\
//                             -[%@ application: openURL: options: ]\n\
//                             或者在registerAppKey 之前 执行 +[PayProxy defaultHandleOpenURL]", clsStr, clsStr, clsStr];
//            NSLog(@"%@", err);
//        }
//    });
//    return success;
//}
//
//-(BOOL)verify_89
//{
//    BOOL v_29 = [self verify:@selector(application:handleOpenURL:) perform:^(UIApplication *application, NSURL *url) {
//        [application.delegate application:application handleOpenURL:url];
//    }];
//    if (v_29) return YES;
//
//    BOOL v_49 = [self verify:@selector(application:openURL:sourceApplication:annotation:) perform:^(UIApplication *application, NSURL *url) {
//        [application.delegate application:application openURL:url sourceApplication:@"" annotation:[NSNull new]];
//    }];
//    if (v_49) return YES;
//
//    return NO;
//}
//
//-(BOOL)verify_9n
//{
//   return [self verify:@selector(application:openURL:options:) perform:^(UIApplication *application, NSURL *url) {
//       [application.delegate application:application openURL:url options:@{}];
//    }];
//}
//
//-(BOOL)verify:(SEL)sel perform:(void(^)(UIApplication *application, NSURL *url))perform
//{
//    _payType = kverify;
//    UIApplication *application = [UIApplication sharedApplication];
//    if ([application.delegate respondsToSelector:sel]) {
//        NSURL *url = [NSURL URLWithString:@"payProxyVerify://"];
//        perform(application, url);
//    }
//    BOOL success = !_payType;
//    _payType = nil;
//    return success;
//}
//
//-(BOOL)verifyHandleOpenURL:(NSURL *) url
//{
//    if (_payType == kverify) {
//        _payType = nil;
//        return YES;
//    }
//    return NO;
//}
//
//@end
