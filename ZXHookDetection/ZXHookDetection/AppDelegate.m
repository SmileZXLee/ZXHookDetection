//
//  AppDelegate.m
//  ZXHookDetection
//
//  Created by 李兆祥 on 2019/4/20.
//  Copyright © 2019 李兆祥. All rights reserved.
//  https://github.com/SmileZXLee/ZXHookDetection

#import "AppDelegate.h"
#import "ZXHookDetection.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //添加检测
    BOOL isJailbroken1 = [ZXHookDetection isJailbroken1];
    BOOL isJailbroken2 = [ZXHookDetection isJailbroken2];
    BOOL isJailbroken3 = [ZXHookDetection isJailbroken3];
    BOOL isExternalLibs = [ZXHookDetection isExternalLibs];
    BOOL isLegalLPublicKey = [ZXHookDetection isLegalPublicKey:@"4Y2YPWFYNQ"];
    NSLog(@"isJailbroken1--%d",isJailbroken1);
    NSLog(@"isJailbroken2--%d",isJailbroken2);
    NSLog(@"isJailbroken3--%d",isJailbroken3);
    NSLog(@"isExternalLibs--%d",isExternalLibs);
    NSLog(@"isLegalLPublicKey--%d",isLegalLPublicKey);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
