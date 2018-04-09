//
//  "InterceptHandleOpenURL.m
//  PayProxy
//
//  Created by YLCHUN on 2018/4/9.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "InterceptHandleOpenURL.h"
#import <objc/runtime.h>

static IMP blockImp(HandleURL handle, IMP imp, SEL sel)
{
    return imp_implementationWithBlock(^BOOL(id self, UIApplication *application, NSURL *url, ...) {
        if (handle(url)) return YES;
        if (imp && sel) {
            va_list args;
            va_start(args, url);
            BOOL b = ((BOOL(*)(id, SEL, ...))imp)(self, sel, application, url, va_arg(args, id), va_arg(args, id));
            va_end(args);
            return b;
        }
        return NO;
    });
}

static void replaceHandle(Class cls, SEL sel, HandleURL handle)
{
    Method method = class_getInstanceMethod(cls, sel);
    IMP imp = method_getImplementation(method);
    IMP block = blockImp(handle, imp, sel);
    class_replaceMethod(cls, sel, block, method_getTypeEncoding(method));
}

static void addHandle(Class cls, SEL sel, HandleURL handle, const char * types)
{
    IMP block = blockImp(handle, NULL, NULL);
    class_addMethod(cls, sel, block, types);
}

static void interceptHandle(HandleURL handle)
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
        replaceHandle(cls, sel_29, handle);
    }
    else if (!has_sel_49) {
        addHandle(cls, sel_29, handle, "B@:@@");
    }
    
    if (has_sel_49) {
        replaceHandle(cls, sel_49, handle);
    }
    else if (!has_sel_29) {
        addHandle(cls, sel_49, handle, "B@:@@@@");
    }
    
    if (has_sel_9n) {
        replaceHandle(cls, sel_9n, handle);
    }
    else {
        addHandle(cls, sel_9n, handle, "B@:@@@");
    }
}

void interceptHandleOpenURL(HandleURL handle)
{
    if (!handle) return;
    if ([UIApplication sharedApplication]) {
        interceptHandle(handle);
    }else {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            interceptHandle(handle);
        }];
    }
}
