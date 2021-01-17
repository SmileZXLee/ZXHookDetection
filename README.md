# ZXHookDetection
### 越狱检测
1.使用NSFileManager通过检测一些越狱后的关键文件/路径是否可以访问来判断是否越狱
常见的文件/路径有
```objective-c
static char *JailbrokenPathArr[] = {"/Applications/Cydia.app","/usr/sbin/sshd","/bin/bash","/etc/apt","/Library/MobileSubstrate","/User/Applications/"};
```
`[防]`判断是否越狱(使用NSFileManager)
```objective-c
+ (BOOL)isJailbroken1{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:JailbrokenPathArr[i]]]){
            return YES;
        }
    }
    return NO;
}
```
调用isJailbroken1并将程序运行在越狱设备上，查看打印，检测出是越狱设备
```objective-c
2019-04-22 00:54:08.163918 ZXHookDetection[6933:1053473] isJailbroken1--1
```
`[攻]`攻击者可以通过hook NSFileManager的fileExistsAtPath方法来绕过检测
```objective-c
//绕过使用NSFileManager判断特定文件是否存在的越狱检测，此时直接返回NO势必会影响程序中对这个方法的正常使用，因此可以先打印一下path，然后判断如果path是用来判断是否越狱则返回NO，否则按照正常逻辑返回
%hook NSFileManager
- (BOOL)fileExistsAtPath:(NSString *)path{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        NSString *jPath = [NSString stringWithUTF8String:JailbrokenPathArr[i]];
        if([path isEqualToString:jPath]){
            return NO;
        }
    }
    return %orig;
}
%end
```
注入dylib后再次查看打印，已绕过越狱检测
```objective-c
2019-04-22 00:58:22.950881 ZXHookDetection[6941:1054289] isJailbroken1--0
```
2.使用C语言函数stat判断文件是否存在(注:stat函数用于获取对应文件信息，返回0则为获取成功，-1为获取失败)  

`[防]`判断是否越狱(使用stat)
```objective-c
+ (BOOL)isJailbroken2{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        struct stat stat_info;
        if (0 == stat(JailbrokenPathArr[i], &stat_info)) {
            return YES;
        }
    }
    return NO;
}
```
调用isJailbroken2并将程序运行在越狱设备上，查看打印，检测出是越狱设备
```objective-c
2019-04-22 00:54:08.164001 ZXHookDetection[6933:1053473] isJailbroken2--1
```
`[攻]`使用fishhook可hook C函数，fishhook通过在mac-o文件中查找并替换函数地址达到hook的目的
```objective-c
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
```
在动态库加载的时候，调用statHook
```objective-c
%ctor{
    [StatHook statHook];
}
```
注入dylib后再次查看打印，已绕过越狱检测
```objective-c
2019-04-22 00:58:22.950933 ZXHookDetection[6941:1054289] isJailbroken2--0
```
`[防]`判断stat的来源是否来自于系统库，因为fishhook通过交换函数地址来实现hook，若hook了stat，则stat来源将指向攻击者注入的动态库中
因此我们可以完善上方的isJailbroken2判断规则，若stat来源非系统库，则直接返回已越狱
```objective-c
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
```
注入dylib后再次查看打印，检测出stat非来自系统库，自动判定为越狱设备
```objective-c
2019-04-22 00:58:22.950933 ZXHookDetection[6941:1054289] isJailbroken2--1
```
3.通过环境变量DYLD_INSERT_LIBRARIES判断是否越狱，若获取到的为NULL，则未越狱
```objective-c
+ (BOOL)isJailbroken3{
    if(TARGET_IPHONE_SIMULATOR)return NO;
    return !(NULL == getenv("DYLD_INSERT_LIBRARIES"));
}
```
`[攻]`此时依然可以使用fishhook hook函数getenv，攻防方法同上，此处不再赘述。

***

### 非法动态库注入检测
`[防]`通过遍历dyld_image检测非法注入的动态库
```objective-c
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
```
攻击者注入dylib之后，已被检测出非法动态库注入
```objective-c
2019-04-22 00:58:22.951011 ZXHookDetection[6941:1054289] isExternalLibs--1
```
`[攻]`可以hook NSString的hasPrefix方法绕过检测
***

### 关键函数hook检测、阻止hook、hook白名单
#### 攻击者dylib动态库注入总是早于类中的+load方法调用，因此在+load方法中无法进行防护，我们可以先link一个自己的framework，并在framework中+load方法内进行防护
* 创建一个framework，并在其中创建一个名为ZXMyFramework的类，在+load中进行防护操作
* 防护操作基本思路是，我们在攻击者之前hook method_exchangeImplementations与method_setImplementation，使用fishhook进行函数指针交换，并使得我们可以轻松监控所有调用method_exchangeImplementations与method_setImplementation的情况，因Method Swizzle，Cydia Substrate进行方法交换均至少会调用以上两个方法中的一个，因此可以以此检测、阻止重要方法被hook
* 在示例demo中，我们在控制器的viewDidload方法中将当前控制器view的背景色设置为绿色，在hook项目中，通过hook ViewController的viewDidload方法，将控制器view的背景色设置为红色，以便我们可以清晰查看这一流程
原控制器viewDidload中代码
```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
}
```
攻击者hook部分代码
```objective-c
%hook ViewController

-(void)viewDidLoad{
    
    self.view.backgroundColor = [UIColor redColor];
}
%end
```
注入dylib后运行项目，发现控制器view已变为红色
* 开始防护，在ZXMyFramework的+load方法中，实现method_exchangeImplementations与method_setImplementation的方法交换，以下为ZXMyFramework.m中类的源码
```objective-c
#pragma mark 受保护的方法数组
static char *DefendSelStrs[] = {"viewDidLoad","bundleIdentifier"};

@implementation ZXMyFramework
void (* orig_exchangeImple)(Method _Nonnull m1, Method _Nonnull m2);
IMP _Nonnull (* orig_setImple)(Method _Nonnull m, IMP _Nonnull imp);
IMP _Nonnull (* getIMP)(Method _Nonnull m);

+(void)load{
    NSLog(@"ZXMyFrameworkLoaded!");
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
```
上方我们对viewDidLoad和bundleIdentifier方法进行了保护，若发现有代码在试图交换它们的方法，则禁止，若需要交换的方法不在保护的数组中，则放行。

* 我们开始模拟攻击者开始注入dylib攻击，查看效果
在攻击者的xm中，我们在动态库初始化的时候打印"AttackHookLoaded"，并hook ViewController的viewDidLoad方法和NSBundle的bundleIdentifier方法
```objective-c
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
```
* 查看防护效果，控制器view的背景色设置为红色已失效，查看打印信息，防护成功！
```objective-c
2019-04-22 01:32:22.457211 ZXHookDetection[6971:1059024] ZXMyFrameworkLoaded!
2019-04-22 01:32:22.546278 ZXHookDetection[6971:1059024] 
               🎉!!！congratulations!!！🎉
👍----------------insert dylib success----------------👍
2019-04-22 01:32:22.553715 ZXHookDetection[6971:1059024] AttackHookLoaded
2019-04-22 01:32:22.554384 ZXHookDetection[6971:1059024] 尝试hook受保护的方法:[viewDidLoad]，已禁止
2019-04-22 01:32:22.554525 ZXHookDetection[6971:1059024] 尝试hook受保护的方法:[bundleIdentifier]，已禁止
```
`[攻]`从上方打印可以看出，我们自己链接的动态库比攻击者注入的动态库早load，我们可以使用otool查看mach-o文件的loadCommand，验证我们的猜想，以下为loadcommand部分信息
```c
Load command 13
          cmd LC_LOAD_DYLIB
      cmdsize 76
         name @rpath/ZXHookFramework.framework/ZXHookFramework (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 1.0.0
compatibility version 1.0.0
Load command 14
          cmd LC_LOAD_DYLIB
      cmdsize 84
         name /System/Library/Frameworks/Foundation.framework/Foundation (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 1570.15.0
compatibility version 300.0.0
Load command 15
          cmd LC_LOAD_DYLIB
      cmdsize 52
         name /usr/lib/libobjc.A.dylib (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 228.0.0
compatibility version 1.0.0
Load command 16
          cmd LC_LOAD_DYLIB
      cmdsize 52
         name /usr/lib/libSystem.B.dylib (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 1252.250.1
compatibility version 1.0.0
Load command 17
          cmd LC_LOAD_DYLIB
      cmdsize 92
         name /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 1570.15.0
compatibility version 150.0.0
Load command 18
          cmd LC_LOAD_DYLIB
      cmdsize 76
         name /System/Library/Frameworks/UIKit.framework/UIKit (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 61000.0.0
compatibility version 1.0.0
Load command 19
          cmd LC_LOAD_DYLIB
      cmdsize 80
         name @executable_path/Frameworks/libZXHookAttackDylib.dylib (offset 24)
   time stamp 2 Thu Jan  1 08:00:02 1970
      current version 0.0.0
compatibility version 0.0.0
Load command 20
          cmd LC_RPATH
      cmdsize 40
         path @executable_path/Frameworks (offset 12)
```
显然，ZXHookFramework.framework(防护者)加载早于libZXHookAttackDylib.dylib(攻击者)，因此防护有效，因此我们可以通过修改mach-o文件的loadCommand来调整动态库加载顺序，使得libZXHookAttackDylib.dylib加载早于ZXHookFramework.framework即可使防护失效

***


### 签名校验
* 通过检测ipa中的embedded.mobileprovision中的我们打包Mac的公钥来确定是否签名被修改，但是需要注意的是此方法只适用于Ad Hoc或企业证书打包的情况，App Store上应用由苹果私钥统一打包，不存在embedded.mobileprovision文件
* 公钥读取写法来源于https://www.jianshu.com/p/a3fc10c70a29
```objective-c
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
```
***

### BundleID检测
* 进行BundleID检测可以有效防止多开
* 获取当前项目的BundleID有多种方法，此处不再赘述，绕过检测则是hook对应的方法，返回原有的BundleID
* 防止攻击者绕过检测，可以在自行link的framework中获取BundleID并进行检测，以在被hook前进行校验
* 可以通过getenv("XPC_SERVICE_NAME")来获取BundleID并进行校验以避免常见的BundleID获取方法被hook

***

### 其他
* 进行安全检测的类和函数不宜直接使用Defend，Detection，Hook类似的关键字，以避免相应的检测函数直接被hook，hook检测可以放在较隐蔽的地方或不以函数形式体现，可以多位置联合检测
* 若检测到hook行为，不宜直接弹窗，以避免攻击者通过关键字回溯，可以延迟一段时间执行异常函数或默默上报后台等。
* 加密key不要直接写在代码中，在汇编下很容易直接看出来  

原代码
```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *aesKey = @"TEST_AES_KEY";
    NSLog(@"aesKey--%@",aesKey);
    self.view.backgroundColor = [UIColor greenColor];
}
```
汇编下的代码[部分]
```assembly
self = X0               ; ViewController *const
_cmd = X1               ; SEL
SUB             SP, SP, #0x40
STP             X20, X19, [SP,#0x30+var_10]
STP             X29, X30, [SP,#0x30+var_s0]
ADD             X29, SP, #0x30
MOV             X19, self
self = X19              ; ViewController *const
NOP
LDR             X8, =_OBJC_CLASS_$_ViewController
STP             X0, X8, [SP,#0x30+var_20]
NOP
LDR             _cmd, =sel_viewDidLoad ; "viewDidLoad"
ADD             X0, SP, #0x30+var_20
BL              _objc_msgSendSuper2
ADR             X8, cfstr_TestAesKey ; "TEST_AES_KEY"
NOP
aesKey = X8             ; Foundation::NSString::NSString *
STR             aesKey, [SP,#0x30+var_30]
ADR             X0, cfstr_Aeskey ; "aesKey--%@"
```
* 若使用md5或aes等通用加密函数时，关键的加密前的数据或加密key不宜直接当作函数参数传入

### 字符串加密&代码混淆
* 字符串加密即关键的常量字符串不直接写死在代码中，而是通过一定的运算计算出来，加大攻击者破解难度
* 代码混淆一般是利用宏进行字符串替换，使得攻击者使用class-dump或ida等工具得出的类名和函数变成无意义的字符串，加大攻击者破解难度
* 推荐使用mj老师的[MJCodeObfuscation](https://github.com/CoderMJLee/MJCodeObfuscation)进行字符串加密与代码混淆，快捷高效
* 注意：大规模使用混淆可能会导致上架审核被拒，建议只处理核心类和方法

### 加密协议分析示例
* 点击访问👉 [创高体育App登录加密协议分析](https://github.com/SmileZXLee/CGEncryptBreak)
* 此示例为示例攻击者分析应用加密协议的大致流程，协议分析仅涉及登录请求，未涉及内部核心加密处理，请务必确保仅用于学习之用途
* 通过此示例开发者可以初步了解攻击者如何破解应用加密协议，以便更好地进行加固和防护

### 【iOS逆向】高效Tweak工具函数集，基于theos、monkeyDev
* 点击访问👉 [【iOS逆向】高效Tweak工具函数集，基于theos、monkeyDev](https://github.com/SmileZXLee/ZXHookUtil)

### 浅谈http、https与数据加密
* 点击访问👉 [浅谈http、https与数据加密](https://github.com/SmileZXLee/aboutHttp)











