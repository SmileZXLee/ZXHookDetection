//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  ZXHookAttackDylib.h
//  ZXHookAttackDylib
//
//  Created by 李兆祥 on 2019/4/20.
//  Copyright (c) 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import <Foundation/Foundation.h>

#define INSERT_SUCCESS_WELCOME @"\n               🎉!!！congratulations!!！🎉\n👍----------------insert dylib success----------------👍"

@interface CustomViewController

@property (nonatomic, copy) NSString* newProperty;

+ (void)classMethod;

- (NSString*)getMyName;

- (void)newMethod:(NSString*) output;

@end
