//
//  ZXHookDetection.m
//  ZXHookDetection
//
//  Created by 李兆祥 on 2019/4/20.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import "ZXHookDetection.h"
#import "fishhook.h"
#import <sys/stat.h>
#include <string.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static char *JailbrokenPathArr[] = {"/Applications/Cydia.app","/usr/sbin/sshd","/bin/bash","/etc/apt","/Library/MobileSubstrate","/User/Applications/"};
@implementation ZXHookDetection
#pragma mark - 越狱检测
#pragma mark 使用NSFileManager通过检测一些越狱后的关键文件是否可以访问来判断是否越狱
+ (BOOL)isJailbroken1{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:JailbrokenPathArr[i]]]){
            return YES;
        }
    }
    return NO;
}
#pragma mark 使用stat通过检测一些越狱后的关键文件是否可以访问来判断是否越狱
+ (BOOL)isJailbroken2{
    
    if(TARGET_IPHONE_SIMULATOR)return NO;
    int ret ;
    Dl_info dylib_info;
    int (*func_stat)(const char *, struct stat *) = stat;
    if ((ret = dladdr(func_stat, &dylib_info))) {
        NSString *fName = [NSString stringWithUTF8String:dylib_info.dli_fname];
        NSLog(@"fname--%@",fName);
        if(![fName isEqualToString:@"/usr/lib/system/libsystem_kernel.dylib"]){
            return YES;
        }
    }
    
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        struct stat stat_info;
        if (0 == stat(JailbrokenPathArr[i], &stat_info)) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark 通过环境变量DYLD_INSERT_LIBRARIES检测是否越狱
+ (BOOL)isJailbroken3{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    return !(NULL == getenv("DYLD_INSERT_LIBRARIES"));
}

#pragma mark - 通过遍历dyld_image检测非法注入的动态库
+ (BOOL)isExternalLibs{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    int dyld_count = _dyld_image_count();
    for (int i = 0; i < dyld_count; i++) {
        const char * imageName = _dyld_get_image_name(i);
        NSString *res = [NSString stringWithUTF8String:imageName];
        if([res hasPrefix:@"/var/containers/Bundle/Application"]){
            if([res hasSuffix:@".dylib"]){
                //这边还需要过滤掉自己项目中本身有的动态库
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - 通过检测ipa中的embedded.mobileprovision中的我们打包Mac的公钥来确定是否签名被修改，但是需要注意的是此方法只适用于Ad Hoc或企业证书打包的情况，App Store上应用由苹果私钥统一打包，不存在embedded.mobileprovision文件
+ (BOOL)isLegalPublicKey:(NSString *)publicKey{
    if(TARGET_IPHONE_SIMULATOR)return YES;
    //来源于https://www.jianshu.com/p/a3fc10c70a29
    NSString *embeddedPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:embeddedPath encoding:NSASCIIStringEncoding error:nil];
    NSArray *embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (int i = 0; i < embeddedProvisioningLines.count; i++) {
        if ([embeddedProvisioningLines[i] rangeOfString:@"application-identifier"].location != NSNotFound) {
            NSInteger fromPosition = [embeddedProvisioningLines[i+1] rangeOfString:@"<string>"].location+8;
            
            NSInteger toPosition = [embeddedProvisioningLines[i+1] rangeOfString:@"</string>"].location;
            NSRange range;
            range.location = fromPosition;
            range.length = toPosition - fromPosition;
            NSString *fullIdentifier = [embeddedProvisioningLines[i+1] substringWithRange:range];
            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
            NSString *appIdentifier = [identifierComponents firstObject];
            NSLog(@"appIdentifier--%@",appIdentifier);
            if (![appIdentifier isEqualToString:publicKey]) {
                return NO;
            }
        }
    }
    return YES;
}
@end
