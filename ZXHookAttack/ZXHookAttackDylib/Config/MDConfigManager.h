//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MDConfigManager.h
//  MonkeyDev
//
//  Created by AloneMonkey on 2018/4/24.
//  Copyright © 2018年 AloneMonkey. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MDCONFIG_CYCRIPT_KEY            @"Cycript"
#define MDCONFIG_TRACE_KEY              @"MethodTrace"
#define MDCONFIG_ENABLE_KEY             @"ENABLE"
#define MDCONFIG_CLASS_LIST             @"CLASS_LIST"
#define MDCONFIG_LOADATLAUNCH_KEY       @"LoadAtLaunch"

@interface MDConfigManager : NSObject

+ (instancetype)sharedInstance;

- (NSDictionary*)readConfigByKey:(NSString*) key;

@end
