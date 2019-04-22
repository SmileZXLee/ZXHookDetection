//
//  StatHook.m
//  ZXHookAttackDylib
//
//  Created by 李兆祥 on 2019/4/21.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import "StatHook.h"
#import "fishhook.h"
@implementation StatHook
static int (*orig_stat)(char *c, struct stat *s);
int hook_stat(char *c, struct stat *s){
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        if(0 == strcmp(c, JailbrokenPathArr[i])){
            return 0;
        }
    }
    return orig_stat(c,s);
}
+(void)statHook{
    struct rebinding stat_rebinding = {"stat", hook_stat, (void *)&orig_stat};
    rebind_symbols((struct rebinding[1]){stat_rebinding}, 1);
}
@end
