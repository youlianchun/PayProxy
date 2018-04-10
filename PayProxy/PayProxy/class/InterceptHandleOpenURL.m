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
            BOOL b = ((BOOL(*)(id, SEL, ...))imp)(self, sel, application, url, va_arg(args, void*), va_arg(args, void*));
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
    method_setImplementation(method, block);
}

static void addHandle(Class cls, SEL sel, HandleURL handle)
{
    Protocol *proto = @protocol(UIApplicationDelegate);
    struct objc_method_description desc = protocol_getMethodDescription(proto, sel, NO, YES);
    IMP block = blockImp(handle, NULL, NULL);
    class_addMethod(cls, sel, block, desc.types);
}

static void interceptHandle(HandleURL handle)
{
    Class cls = object_getClass(UIApplication.sharedApplication.delegate);
    
    SEL sel_29 = @selector(application:handleOpenURL:);
    SEL sel_49 = @selector(application:openURL:sourceApplication:annotation:);
    SEL sel_9n = @selector(application:openURL:options:);
    
    BOOL has_sel_29 = class_respondsToSelector(cls, sel_29);
    BOOL has_sel_49 = class_respondsToSelector(cls, sel_49);
    BOOL has_sel_9n = class_respondsToSelector(cls, sel_9n);
    
    if (has_sel_29) {
        replaceHandle(cls, sel_29, handle);
    }
    else if (!has_sel_49) {
        addHandle(cls, sel_29, handle);
    }
    
    if (has_sel_49) {
        replaceHandle(cls, sel_49, handle);
    }
    else if (!has_sel_29) {
        addHandle(cls, sel_49, handle);
    }
    
    if (has_sel_9n) {
        replaceHandle(cls, sel_9n, handle);
    }
    else {
        addHandle(cls, sel_9n, handle);
    }
}

static dispatch_queue_t listeningQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("listening", NULL);
    });
    return queue;
}

void interceptHandleOpenURL(HandleURL handle)
{
    if (!handle) return;
    
    if (UIApplication.sharedApplication) {
        interceptHandle(handle);
    }
    else {
        dispatch_async(listeningQueue(), ^{
            while (!UIApplication.sharedApplication) {}
            dispatch_async(dispatch_get_main_queue(), ^{
                interceptHandle(handle);
            });
        });
    }
}
