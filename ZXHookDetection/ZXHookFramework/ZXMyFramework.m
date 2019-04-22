//
//  ZXMyLib.m
//  ZXHookDetection
//
//  Created by 李兆祥 on 2019/4/21.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import "ZXMyFramework.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "fishhook.h"
#pragma mark 受保护的方法数组
static char *DefendSelStrs[] = {"viewDidLoad","bundleIdentifier"};

@implementation ZXMyFramework
void (* orig_exchangeImple)(Method _Nonnull m1, Method _Nonnull m2);
IMP _Nonnull (* orig_setImple)(Method _Nonnull m, IMP _Nonnull imp);
IMP _Nonnull (* getIMP)(Method _Nonnull m);

+(void)load{
    NSLog(@"ZXMyFrameworkLoaded!");
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSLog(@"bundleId--%@",bundleId);
    if(TARGET_IPHONE_SIMULATOR)return;
    struct rebinding exchange_rebinding;
    exchange_rebinding.name = "method_exchangeImplementations";
    exchange_rebinding.replacement = hook_exchangeImple;
    exchange_rebinding.replaced=(void *)&orig_exchangeImple;
    
    struct rebinding setImple_rebinding;
    setImple_rebinding.name = "method_setImplementation";
    setImple_rebinding.replacement = hook_setImple;
    setImple_rebinding.replaced=(void *)&orig_setImple;
    
    struct rebinding rebindings[]={exchange_rebinding,setImple_rebinding};
    rebind_symbols(rebindings, 2);
}

void hook_exchangeImple(Method _Nonnull orig_method, Method _Nonnull changed_method){
    if(orig_method){
        SEL sel = method_getName(orig_method);
        bool in_def = in_defend_sel((char *)[NSStringFromSelector(sel) UTF8String]);
        if(in_def){
            NSLog(@"尝试hook受保护的方法:[%@]，已禁止",NSStringFromSelector(sel));
            return;
        }
    }
    orig_exchangeImple(orig_method,changed_method);
}
void hook_setImple(Method _Nonnull method, IMP _Nonnull imp){
    if(method){
        SEL sel = method_getName(method);
        bool in_def = in_defend_sel((char *)[NSStringFromSelector(sel) UTF8String]);
        if(in_def){
            NSLog(@"尝试hook受保护的方法:[%@]，已禁止",NSStringFromSelector(sel));
            return;
        }
    }
    orig_setImple(method,imp);
}

#pragma mark 判断被交换的方法是否是受保护的方法
bool in_defend_sel(char *selStr){
    for (int i = 0;i < sizeof(DefendSelStrs) / sizeof(char *);i++) {
        if(0 == strcmp(selStr, DefendSelStrs[i])){
            return true;
        }
    }
    return false;
}
@end
