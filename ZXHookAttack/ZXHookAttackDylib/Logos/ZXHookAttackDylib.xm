// See http://iphonedevwiki.net/index.php/Logos
// https://github.com/SmileZXLee/ZXHookDetection
#import <UIKit/UIKit.h>
#import "fishhook.h"
#import "StatHook.h"
%ctor{
    [StatHook statHook];
    NSLog(@"AttackHookLoaded");
}
@interface ViewController:UIViewController

@end
%hook ViewController

-(void)viewDidLoad{
    
    self.view.backgroundColor = [UIColor redColor];
}
%end

%hook NSBundle
-(id)bundleIdentifier{
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    if(dladdr((void *)[address[2] longLongValue], &info) == 0) {
        return %orig;
    }
    NSString *path = [NSString stringWithUTF8String:info.dli_fname];
    if ([path hasPrefix:NSBundle.mainBundle.bundlePath]) {
        NSLog(@"getBundleIdentifier");
        return @"cn.newBundelId";
    } else {
        return %orig;
    }
}
%end

//绕过使用NSFileManager判断特定文件是否存在的越狱检测，此时直接返回NO势必会影响程序中对这个方法的正常使用，因此可以先打印一下path，然后判断如果path是用来判断是否越狱则返回NO，否则按照正常逻辑返回
%hook NSFileManager
- (BOOL)fileExistsAtPath:(NSString *)path{
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        NSString *jPath = [NSString stringWithUTF8String:JailbrokenPathArr[i]];
        if([path isEqualToString:jPath]){
            return NO;
        }
    }
    return YES;
}
%end

