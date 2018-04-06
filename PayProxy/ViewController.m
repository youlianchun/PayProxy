//
//  ViewController.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/2.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "ViewController.h"
#import "PayProxy.h"
#import "ApplePay.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)wxPay {
    NSDictionary *signData = @{@"partnerid":@"", @"prepayid":@"", @"package":@"", @"noncestr":@"", @"timestamp":@"", @"sign":@""};//服务器签名后的数据
    [PayProxy wxPay:signData callback:^(BOOL success) {
        if (success) {
            //支付成功 ...
        }else {
            //支付失败 ...
        }
    }];
}

- (void)aliPay {
    NSString *signData = @"";//服务器签名后的数据
    [PayProxy aliPay:signData callback:^(BOOL success) {
        if (success) {
            //支付成功 ...
        }else {
            //支付失败 ...
        }
    }];
}

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
@end
