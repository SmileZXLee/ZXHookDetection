//
//  ZXHookDetection.h
//  ZXHookDetection
//
//  Created by 李兆祥 on 2019/4/20.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ZXHookDetection : NSObject
+ (BOOL)isJailbroken1;
+ (BOOL)isJailbroken2;
+ (BOOL)isJailbroken3;
+ (BOOL)isExternalLibs;
+ (BOOL)isLegalPublicKey:(NSString *)publicKey;
@end

NS_ASSUME_NONNULL_END
