//
//  "InterceptHandleOpenURL.h
//  PayProxy
//
//  Created by YLCHUN on 2018/4/9.
//  Copyright © 2018年 YLCHUN. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Definition of `C_EXTERN'. */
#if !defined(C_EXTERN)
#  if defined(__cplusplus)
#   define C_EXTERN extern "C"
#  else
#   define C_EXTERN extern
#  endif
#endif /* !defined(C_EXTERN) */

typedef BOOL(^HandleURL)(NSURL *url);

C_EXTERN void interceptHandleOpenURL(HandleURL handle);
