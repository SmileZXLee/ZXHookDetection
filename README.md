# ZXHookDetection
### 越狱检测
1.使用NSFileManager通过检测一些越狱后的关键文件/路径是否可以访问来判断是否越狱
常见的文件/路径有
```objective-c
static char *JailbrokenPathArr[] = {"/Applications/Cydia.app","/usr/sbin/sshd","/bin/bash","/etc/apt","/Library/MobileSubstrate","/User/Applications/"};
```
[防]判断是否越狱(使用NSFileManager)
```objective-c
+ (BOOL)isJailbroken1{
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:JailbrokenPathArr[i]]]){
            return YES;
        }
    }
    return NO;
}
```
[攻]攻击者可以通过hook NSFileManager的fileExistsAtPath方法来绕过检测
```objective-c
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
```
2.使用C语言函数stat判断文件是否存在(注:stat函数用于获取对应文件信息，返回0则为获取成功，-1为获取失败)  

[防]判断是否越狱(使用stat)
```objective-c
+ (BOOL)isJailbroken2{
    for (int i = 0;i < sizeof(JailbrokenPathArr) / sizeof(char *);i++) {
        struct stat stat_info;
        if (0 == stat(JailbrokenPathArr[i], &stat_info)) {
            return YES;
        }
    }
    return NO;
}
```
[攻]使用fishhook可hook C函数，fishhook通过在mac-o文件中查找并替换函数地址达到hook的目的
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
[防]判断stat的来源是否来自于系统库，因为fishhook通过交换函数地址来实现hook，若hook了stat，则stat来源将指向攻击者注入的动态库中
因此我们可以完善上方的isJailbroken2判断规则，若stat来源非系统库，则直接返回已越狱
```objective-c
+ (BOOL)isJailbroken2{
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
3.通过环境变量DYLD_INSERT_LIBRARIES判断是否越狱，若获取到的为NULL，则未越狱
```objective-c
+ (BOOL)isJailbroken3{
    return !(NULL == getenv("DYLD_INSERT_LIBRARIES"));
}
```
[攻]此时依然可以使用fishhook hook函数getenv，攻防方法同上，此处不再赘述。

### 未完待续，剩下明天写...

