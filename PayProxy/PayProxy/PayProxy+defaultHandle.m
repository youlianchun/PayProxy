//
//  PayProxy+defaultHandle.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/7.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "PayProxy.h"
#import <objc/runtime.h>

static void intercept(Class cls, SEL sel, id(^getBlock)(IMP imp))
{
    Method method = class_getInstanceMethod(cls, sel);
    IMP imp = method_getImplementation(class_getInstanceMethod(cls, sel));
    IMP block = imp_implementationWithBlock(getBlock(imp));
    class_replaceMethod(cls, sel, block, method_getTypeEncoding(method));
}

static void interceptHandle()
{
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    Class cls = [delegate class];
    SEL sel = @selector(application:handleOpenURL:);
    if ([delegate respondsToSelector:sel]) {
        intercept(cls, sel, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url) {
                if ([PayProxy handleOpenURL:url]) return YES;
                return ((BOOL(*)(id, SEL, UIApplication *, NSURL *))imp)(self, sel, application, url);
            };
        });
    }
    
    sel = @selector(application:openURL:sourceApplication:annotation:);
    if ([delegate respondsToSelector:sel]) {
        intercept(cls, sel, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation) {
                if ([PayProxy handleOpenURL:url]) return YES;
                return ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSString *, id))imp)(self, sel, application, url, sourceApplication, annotation);
            };
        });
    }
    
    sel = @selector(application:openURL:options:);
    if ([delegate respondsToSelector:sel]) {
        intercept(cls, sel, ^id(IMP imp) {
            return ^BOOL(id self, UIApplication *application, NSURL *url, NSDictionary *options) {
                if ([PayProxy handleOpenURL:url]) return YES;
                return ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSDictionary *))imp)(self, sel, application, url, options);
            };
        });
    }
}

@implementation PayProxy (defaultHandle)
+(void)defaultHandleOpenURL {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interceptHandle();
    });
}
@end
