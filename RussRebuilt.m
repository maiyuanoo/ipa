#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <Foundation/Foundation.h>/*OC对象 nsuserdefault 通知*/
#import <UIKit/UIKit.h>/* uiview uibutton uislider ui界面*/
#import <dlfcn.h>/*动态找il2cpp原生c函数地址 */
#include <string.h>

typedef struct Il2CppDomain Il2CppDomain;
@@ -15,7 +15,7 @@
uintptr_t maxLength;
Il2CppObject *objects[];
} Il2CppArray;

/* il2cpp基础前向声明 数组结构体*/
typedef Il2CppDomain *(*Il2CppDomainGet)(void);
typedef Il2CppAssembly **(*Il2CppDomainGetAssemblies)(const Il2CppDomain *domain, size_t *size);
typedef const Il2CppImage *(*Il2CppAssemblyGetImage)(const Il2CppAssembly *assembly);
@@ -26,7 +26,7 @@
typedef void (*Il2CppFieldSetValue)(void *object, void *field, void *value);
typedef Il2CppObject *(*Il2CppRuntimeInvoke)(const MethodInfo *method, void *object, void **parameters, Il2CppObject **exception);
typedef void *(*Il2CppThreadAttach)(Il2CppDomain *domain);

/*ilcpp定义指针 dlsym调用 */
static Il2CppDomainGet gIl2CppDomainGet;
static Il2CppDomainGetAssemblies gIl2CppDomainGetAssemblies;
static Il2CppAssemblyGetImage gIl2CppAssemblyGetImage;
@@ -37,7 +37,7 @@
static Il2CppFieldSetValue gIl2CppFieldSetValue;
static Il2CppRuntimeInvoke gIl2CppRuntimeInvoke;
static Il2CppThreadAttach gIl2CppThreadAttach;

/*全局静态函数指针缓存 */
static BOOL ResolveIl2Cpp(void) {
if (gIl2CppDomainGet != NULL) {
return YES;
@@ -58,7 +58,7 @@ static BOOL ResolveIl2Cpp(void) {
gIl2CppAssemblyGetImage != NULL && gIl2CppClassFromName != NULL &&
gIl2CppClassGetMethodFromName != NULL && gIl2CppRuntimeInvoke != NULL;
}

/* 解析il2cpp全部api入口*/
static void *FindClass(const char *assemblyName, const char *namespaceName, const char *className) {
if (!ResolveIl2Cpp()) return NULL;
Il2CppDomain *domain = gIl2CppDomainGet();
@@ -75,7 +75,7 @@ static BOOL ResolveIl2Cpp(void) {
}
return NULL;
}

/* findclass 工具函数 按照dll名 命名空间 类名查找c#*/
static void ApplyCameraFollow(float thirdPersonFov, float firstPersonFov) {
void *klass = FindClass("UpdateScript_500.dll", "", "CameraFollow");
if (klass == NULL || gIl2CppClassGetMethodFromName == NULL) return;
@@ -92,7 +92,7 @@ static void ApplyCameraFollow(float thirdPersonFov, float firstPersonFov) {
if (firstField != NULL && gIl2CppFieldGetOffset(firstField) != (size_t)-1) gIl2CppFieldSetValue(instance, firstField, &firstValue);
if (thirdField != NULL && gIl2CppFieldGetOffset(thirdField) != (size_t)-1) gIl2CppFieldSetValue(instance, thirdField, &thirdValue);
}

/*修改camerafollow两个fov字段 */
static void ApplyFieldOfView(CGFloat fieldOfView) {
if (!ResolveIl2Cpp()) {
return;
@@ -138,7 +138,7 @@ static void ApplyFieldOfView(CGFloat fieldOfView) {
}
}
}

/*直接调用unityengine camera改fov */
@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *floatingButton;
@@ -148,7 +148,7 @@ @interface RussOverlayController : NSObject
@property(nonatomic, assign) CGFloat cameraDistance;
@property(nonatomic, assign) BOOL routeEnabled;
@end

/* 悬浮ui控制器*/
@implementation RussOverlayController

- (void)install {
@@ -173,7 +173,7 @@ - (void)install {
ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV);
});
}

/* ui初始化入口*/
- (void)buildPanelInWindow:(UIWindow *)window {
self.panel = [[UIView alloc] initWithFrame:CGRectMake(84.0, 130.0, 280.0, 300.0)];
self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
@@ -202,7 +202,7 @@ - (void)buildPanelInWindow:(UIWindow *)window {
[self.panel addSubview:routeLabel];
[window addSubview:self.panel];
}

/* 深色半透明面板 标题视角调试 调用addsliderwithtitle快速生成3个滑块第一人fov第三人fov 速度倍率 路线显示 面板加在顶层window*/
- (void)addSliderWithTitle:(NSString *)title value:(CGFloat)value minimum:(CGFloat)minimum maximum:(CGFloat)maximum y:(CGFloat)y action:(SEL)action {
UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16.0, y, 210.0, 20.0)];
label.text = title;
@@ -217,16 +217,16 @@ - (void)addSliderWithTitle:(NSString *)title value:(CGFloat)value minimum:(CGFlo
[slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
[self.panel addSubview:slider];
}

/*滑块封装工具方法 */
- (void)togglePanel {
self.panel.hidden = !self.panel.hidden;
}

/*点击隐藏悬浮 */
- (void)firstPersonFOVChanged:(UISlider *)sender { self.firstPersonFOV = sender.value; [self saveSettings]; ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV); }
- (void)thirdPersonFOVChanged:(UISlider *)sender { self.thirdPersonFOV = sender.value; [self saveSettings]; ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV); }
- (void)speedChanged:(UISlider *)sender { self.speedMultiplier = sender.value; [self saveSettings]; }
- (void)routeChanged:(UISwitch *)sender { self.routeEnabled = sender.isOn; [self saveSettings]; }

/*fov滑块拖动 更新成员变量 savesetting永久化 立刻调用applycamerafollow刷新游戏视角 速度路线只存配置没有底层ilcapp逻辑 */
- (void)loadSettings {
NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
self.firstPersonFOV = [defaults objectForKey:@"russ.firstFOV"] ? [defaults floatForKey:@"russ.firstFOV"] : 75.0;
@@ -235,7 +235,7 @@ - (void)loadSettings {
self.cameraDistance = [defaults objectForKey:@"russ.distance"] ? [defaults floatForKey:@"russ.distance"] : 8.0;
self.routeEnabled = [defaults boolForKey:@"russ.route"];
}

/* 加载本地持久化配置 从系统nsuserdefaults读取上次保存参数 不存在设置的默认值*/
- (void)saveSettings {
NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
[defaults setFloat:self.firstPersonFOV forKey:@"russ.firstFOV"];
@@ -244,7 +244,7 @@ - (void)saveSettings {
[defaults setFloat:self.cameraDistance forKey:@"russ.distance"];
[defaults setBool:self.routeEnabled forKey:@"russ.route"];
}

/* 保存配置到本地 下次打开延用fov*/
@end

static RussOverlayController *gOverlayController;
@@ -263,4 +263,6 @@ static void RussRebuiltInitialize(void) {
[gOverlayController install];
});
});
}
}
/* dylib加载自动自动执行 不需要外调用*/
/* tweak注入*/