//
//  NSDictionary+ZXDetection.m
//  ZXHookDetection
//
//  Created by 李兆祥 on 2019/4/20.
//  Copyright © 2019 李兆祥. All rights reserved.
//  测试用的

#import "NSDictionary+ZXDetection.h"
#import <objc/runtime.h>
#include <string.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <mach-o/arch.h>
#import <objc/runtime.h>
@implementation NSDictionary (ZXDetection)
+(void)load{
    Class dictCls = objc_getClass("__NSDictionaryM");
    Method orgMethod = class_getInstanceMethod(dictCls, @selector(setObject:forKey:));
    Method swizMethod = class_getInstanceMethod(dictCls, @selector(sw_setObject:forKey:));
    method_exchangeImplementations(orgMethod, swizMethod);
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    NSString *res = [NSString stringWithFormat:@"%s",env];
    char *env2 = getenv("XPC_SERVICE_NAME");
    NSString *res2 = [NSString stringWithFormat:@"%s",env2];
    NSLog(@"res2--%@",res2);
    NSLog(@"res--%@",res);
    
}

-(void)sw_setObject:(id)obj forKey:(id)key{
    if(![obj isKindOfClass:[objc_getClass("FBSSceneImpl") class]]){
        //NSLog(@"anObject :%@ key: %@ ",obj,key);
    }
    if([key isKindOfClass:[NSString class]] && [key isEqualToString:@"XPC_SERVICE_NAME"]){
        if([obj containsString:@"cn.zxlee.ZXHookDetection"]){
            
        }
        
    }
    
    [self sw_setObject:obj forKey:key];
}
@end
