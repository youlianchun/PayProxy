//
//  Singleton.m
//  singleton
//
//  Created by YLCHUN on 2018/3/28.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import "Singleton.h"
#include <mutex>
#import <objc/runtime.h>

@implementation Singleton
{
   @private bool _initToken;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static char singletonKey;
    static std::mutex allocLock;
    std::lock_guard<std::mutex> lock(allocLock);
    
    id singleton = objc_getAssociatedObject(self, &singletonKey);
    if (!singleton)
    {
        [self _onceInit];
        singleton = [super allocWithZone:zone];
        objc_setAssociatedObject(self, &singletonKey, singleton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return singleton;
}

+(void)_onceInit
{
    static SEL sel = @selector(init);
    Method method = class_getInstanceMethod(self, sel);
    IMP init = method_getImplementation(method);
    IMP block = imp_implementationWithBlock(^id(Singleton *self) {
        static std::mutex initLock;
        std::lock_guard<std::mutex> lock(initLock);
        if (!self->_initToken) {
            self = ((id(*)(id, SEL))init)(self, sel);
        }
        return self;
    });
    class_replaceMethod(self, sel, block, method_getTypeEncoding(method));
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

-(id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

@end

