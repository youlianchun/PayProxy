# PayProxy
支付宝、微信支付 回调封装

### 使用示例
AppDelegate
```
@implementation AppDelegate (pay)
+(void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PayProxy registerWXAppKey:@"wx73acdf06232c6a33"];
        [PayProxy registerAliAppKey:@"aliPayOpen"];
    });
}
@end
```

viewController
```
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
```
