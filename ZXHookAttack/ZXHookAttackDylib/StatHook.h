//
//  StatHook.h
//  ZXHookAttackDylib
//
//  Created by 李兆祥 on 2019/4/21.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

static char *JailbrokenPathArr[] = {"/Applications/Cydia.app","/usr/sbin/sshd","/bin/bash","/etc/apt","/Library/MobileSubstrate","/User/Applications/"};

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface StatHook : NSObject
+(void)statHook;
@end

NS_ASSUME_NONNULL_END
