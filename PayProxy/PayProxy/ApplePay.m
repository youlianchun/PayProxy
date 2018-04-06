//
//  ApplePay.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/6.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "ApplePay.h"
#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

static UIViewController *currentViewControllerFrom(UIViewController *vc)
{
    if([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tvc = (UITabBarController *)vc;
        return currentViewControllerFrom(tvc.selectedViewController);
    }
    else if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nvc = (UINavigationController *)vc;
        return currentViewControllerFrom(nvc.viewControllers.lastObject);
    }
    else if (vc.presentedViewController) {
        return currentViewControllerFrom(vc.presentedViewController);
    }
    else {
        return vc;
    }
}

static UIViewController* currentViewController()
{
    UIViewController *rvc = [UIApplication sharedApplication].delegate.window.rootViewController;
    return  currentViewControllerFrom(rvc);
}


@interface ApplePay ()<PKPaymentAuthorizationViewControllerDelegate>
{
    void(^_authCallback)(NSData *token, void(^authRet)(BOOL success, NSString* errMsg));
    void(^_callback)(BOOL success);
    BOOL _paySuccess;
    NSString *_merchantId;
}
@end

@implementation ApplePay
+(instancetype)share {
    return [[ApplePay alloc] init];
}
-(void)setMerchantId:(NSString*)merchantId serverAuth:(void(^)(NSData *token, void(^authRet)(BOOL success, NSString* errMsg)))authCallback
{
    _merchantId = merchantId;
    _authCallback = authCallback;
}

-(PKPaymentRequest *)paymentRequest:(NSDictionary *)data
{
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    //设置支付的地区
    request.countryCode = data[@"countryCode"] ?: @"CN";
    //设置币种
    request.currencyCode = data[@"currencyCode"] ?: @"CNY";
    //限制支付卡或者是商家所支持的卡的类型
    if (@available(iOS 9.2, *)) {
        request.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkChinaUnionPay, PKPaymentNetworkPrivateLabel];
    } else {
        request.supportedNetworks = @[PKPaymentNetworkVisa];
    }
    //商家的支付能力
    if (@available(iOS 9.0, *)) {
        request.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV | PKMerchantCapabilityDebit | PKMerchantCapabilityCredit;
    } else {
        request.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV ;
    }
    //设置商户ID
    request.merchantIdentifier = data[@"merchantId"] ?: _merchantId;
    //2.存储额外信息  applicationData  这个存储一些你的应用中， 关于这次支付的唯一标示信息，比如:一个购物车中的商品ID，在用户授权后这个applicationData的希望值就会出现在这次支付的Token中
    id orderNum = data[@"orderNum"];
    if (orderNum) {
        request.applicationData = [[NSString stringWithFormat:@"orderNum:%@", orderNum] dataUsingEncoding:NSUTF8StringEncoding];
    }
    //3.商品的支付页面信息
    NSString *amount = data[@"amount"];
    NSString *merchantName = data[@"merchantName"];
    PKPaymentSummaryItem *item = [PKPaymentSummaryItem summaryItemWithLabel:@"订单金额" amount:[NSDecimalNumber decimalNumberWithString:amount]];
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:merchantName amount:item.amount];
    request.paymentSummaryItems = @[item, item1];
    return request;
}

-(void)aplePay:(NSDictionary *)data callback:(void(^)(BOOL success))callback;
{
    _callback = callback;
    _paySuccess = NO;
    PKPaymentRequest *request = [self paymentRequest:data];
    PKPaymentAuthorizationViewController *controller = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
    controller.delegate = self;
    [currentViewController() presentViewController:controller animated:YES completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus status))completion
{
    __weak typeof(self) wself = self;
    _authCallback(payment.token.paymentData, ^(BOOL success, NSString* errMsg) {
        __strong typeof(self) sself = wself;
        if (sself) {
            sself->_paySuccess = success;
        }
        if (success) {
            completion(PKPaymentAuthorizationStatusSuccess);
        }else {
            completion(PKPaymentAuthorizationStatusFailure);
        }
    });
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        self->_callback(self->_paySuccess);
    }];
}

@end


