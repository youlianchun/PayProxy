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
    return imp_implementationWithBlock(^BOOL(id self, UIApplication *application, NSURL *url,  void* op0, void* op1) {
        if (handle(url)) return YES;
        if (imp && sel) {
            BOOL b = ((BOOL(*)(id, SEL, ...))imp)(self, sel, application, url, op0, op1);
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
    else if(!has_sel_49 && !has_sel_29) {
        addHandle(cls, sel_9n, handle);
    }
}

void interceptHandleOpenURL(HandleURL handle)
{
    if (!handle) return;
    interceptHandle(handle);
}


