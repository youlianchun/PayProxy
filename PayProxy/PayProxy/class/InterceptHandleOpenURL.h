//
//  "InterceptHandleOpenURL.h
//  PayProxy
//
//  Created by YLCHUN on 2018/4/9.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL(^HandleURL)(NSURL *url);

OBJC_EXTERN void interceptHandleOpenURL(HandleURL handle);
