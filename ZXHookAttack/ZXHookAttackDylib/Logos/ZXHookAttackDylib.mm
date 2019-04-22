#line 1 "/Users/lzx/Desktop/程序/ZXHookAttack/ZXHookAttackDylib/Logos/ZXHookAttackDylib.xm"



#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class NSFileManager; @class NSBundle; @class ViewController; 
static void (*_logos_orig$_ungrouped$ViewController$viewDidLoad)(_LOGOS_SELF_TYPE_NORMAL ViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$ViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL ViewController* _LOGOS_SELF_CONST, SEL); static id (*_logos_orig$_ungrouped$NSBundle$bundleIdentifier)(_LOGOS_SELF_TYPE_NORMAL NSBundle* _LOGOS_SELF_CONST, SEL); static id _logos_method$_ungrouped$NSBundle$bundleIdentifier(_LOGOS_SELF_TYPE_NORMAL NSBundle* _LOGOS_SELF_CONST, SEL); static BOOL (*_logos_orig$_ungrouped$NSFileManager$fileExistsAtPath$)(_LOGOS_SELF_TYPE_NORMAL NSFileManager* _LOGOS_SELF_CONST, SEL, NSString *); static BOOL _logos_method$_ungrouped$NSFileManager$fileExistsAtPath$(_LOGOS_SELF_TYPE_NORMAL NSFileManager* _LOGOS_SELF_CONST, SEL, NSString *); 

#line 3 "/Users/lzx/Desktop/程序/ZXHookAttack/ZXHookAttackDylib/Logos/ZXHookAttackDylib.xm"
#import <UIKit/UIKit.h>
#import "fishhook.h"
#import "StatHook.h"
static __attribute__((constructor)) void _logosLocalCtor_6abe01d2(int __unused argc, char __unused **argv, char __unused **envp){
    [StatHook statHook];
    NSLog(@"AttackHookLoaded");
}
@interface ViewController:UIViewController

@end


static void _logos_method$_ungrouped$ViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL ViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd){
    
    self.view.backgroundColor = [UIColor redColor];
}



static id _logos_method$_ungrouped$NSBundle$bundleIdentifier(_LOGOS_SELF_TYPE_NORMAL NSBundle* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd){
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    if(dladdr((void *)[address[2] longLongValue], &info) == 0) {
        return _logos_orig$_ungrouped$NSBundle$bundleIdentifier(self, _cmd);
    }
    NSString *path = [NSString stringWithUTF8String:info.dli_fname];
    if ([path hasPrefix:NSBundle.mainBundle.bundlePath]) {
        NSLog(@"getBundleIdentifier");
        return @"cn.newBundelId";
    } else {
        return _logos_orig$_ungrouped$NSBundle$bundleIdentifier(self, _cmd);
    }
}




static BOOL _logos_method$_ungrouped$NSFileManager$fileExistsAtPath$(_LOGOS_SELF_TYPE_NORMAL NSFileManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * path){
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        NSString *jPath = [NSString stringWithUTF8String:JailbrokenPathArr[i]];
        if([path isEqualToString:jPath]){
            return NO;
        }
    }
    return YES;
}


static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$ViewController = objc_getClass("ViewController"); MSHookMessageEx(_logos_class$_ungrouped$ViewController, @selector(viewDidLoad), (IMP)&_logos_method$_ungrouped$ViewController$viewDidLoad, (IMP*)&_logos_orig$_ungrouped$ViewController$viewDidLoad);Class _logos_class$_ungrouped$NSBundle = objc_getClass("NSBundle"); MSHookMessageEx(_logos_class$_ungrouped$NSBundle, @selector(bundleIdentifier), (IMP)&_logos_method$_ungrouped$NSBundle$bundleIdentifier, (IMP*)&_logos_orig$_ungrouped$NSBundle$bundleIdentifier);Class _logos_class$_ungrouped$NSFileManager = objc_getClass("NSFileManager"); MSHookMessageEx(_logos_class$_ungrouped$NSFileManager, @selector(fileExistsAtPath:), (IMP)&_logos_method$_ungrouped$NSFileManager$fileExistsAtPath$, (IMP*)&_logos_orig$_ungrouped$NSFileManager$fileExistsAtPath$);} }
#line 51 "/Users/lzx/Desktop/程序/ZXHookAttack/ZXHookAttackDylib/Logos/ZXHookAttackDylib.xm"
