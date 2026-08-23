#import <Foundation/Foundation.h>/*OC对象 nsuserdefault 通知*/
#import <UIKit/UIKit.h>/* uiview uibutton uislider ui界面*/
#import <dlfcn.h>/*动态找il2cpp原生c函数地址 */
#include <string.h>
#include <math.h>
#include <float.h>
#include <stdint.h>

typedef struct Il2CppDomain Il2CppDomain;
typedef struct Il2CppAssembly Il2CppAssembly;
typedef struct Il2CppImage Il2CppImage;
typedef struct MethodInfo MethodInfo;
typedef struct Il2CppObject Il2CppObject;
typedef struct Il2CppArray {
    void *klass;
    void *monitor;
    void *bounds;
    uintptr_t maxLength;
    Il2CppObject *objects[];
} Il2CppArray;
/* il2cpp基础前向声明 数组结构体*/
typedef Il2CppDomain *(*Il2CppDomainGet)(void);
typedef Il2CppAssembly **(*Il2CppDomainGetAssemblies)(const Il2CppDomain *domain, size_t *size);
typedef const Il2CppImage *(*Il2CppAssemblyGetImage)(const Il2CppAssembly *assembly);
typedef void *(*Il2CppClassFromName)(const Il2CppImage *image, const char *namespaze, const char *name);
typedef const MethodInfo *(*Il2CppClassGetMethodFromName)(void *klass, const char *name, int argumentsCount);
typedef void *(*Il2CppClassGetFieldFromName)(void *klass, const char *name);
typedef size_t (*Il2CppFieldGetOffset)(void *field);
typedef void (*Il2CppFieldSetValue)(void *object, void *field, void *value);
typedef Il2CppObject *(*Il2CppRuntimeInvoke)(const MethodInfo *method, void *object, void **parameters, Il2CppObject **exception);
typedef void *(*Il2CppThreadAttach)(Il2CppDomain *domain);
typedef Il2CppObject *(*Il2CppClassGetTypeObject)(void *klass);
typedef void *(*Il2CppObjectUnbox)(Il2CppObject *object);
/*ilcpp定义指针 dlsym调用 */
static Il2CppDomainGet gIl2CppDomainGet;
static Il2CppDomainGetAssemblies gIl2CppDomainGetAssemblies;
static Il2CppAssemblyGetImage gIl2CppAssemblyGetImage;
static Il2CppClassFromName gIl2CppClassFromName;
static Il2CppClassGetMethodFromName gIl2CppClassGetMethodFromName;
static Il2CppClassGetFieldFromName gIl2CppClassGetFieldFromName;
static Il2CppFieldGetOffset gIl2CppFieldGetOffset;
static Il2CppFieldSetValue gIl2CppFieldSetValue;
static Il2CppRuntimeInvoke gIl2CppRuntimeInvoke;
static Il2CppThreadAttach gIl2CppThreadAttach;
static Il2CppClassGetTypeObject gIl2CppClassGetTypeObject;
static Il2CppObjectUnbox gIl2CppObjectUnbox;
/*全局静态函数指针缓存 */
static BOOL ResolveIl2Cpp(void) {
    if (gIl2CppDomainGet != NULL) {
        return YES;
    }

    gIl2CppDomainGet = (Il2CppDomainGet)dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
    gIl2CppDomainGetAssemblies = (Il2CppDomainGetAssemblies)dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
    gIl2CppAssemblyGetImage = (Il2CppAssemblyGetImage)dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
    gIl2CppClassFromName = (Il2CppClassFromName)dlsym(RTLD_DEFAULT, "il2cpp_class_from_name");
    gIl2CppClassGetMethodFromName = (Il2CppClassGetMethodFromName)dlsym(RTLD_DEFAULT, "il2cpp_class_get_method_from_name");
    gIl2CppClassGetFieldFromName = (Il2CppClassGetFieldFromName)dlsym(RTLD_DEFAULT, "il2cpp_class_get_field_from_name");
    gIl2CppFieldGetOffset = (Il2CppFieldGetOffset)dlsym(RTLD_DEFAULT, "il2cpp_field_get_offset");
    gIl2CppFieldSetValue = (Il2CppFieldSetValue)dlsym(RTLD_DEFAULT, "il2cpp_field_set_value");
    gIl2CppRuntimeInvoke = (Il2CppRuntimeInvoke)dlsym(RTLD_DEFAULT, "il2cpp_runtime_invoke");
    gIl2CppThreadAttach = (Il2CppThreadAttach)dlsym(RTLD_DEFAULT, "il2cpp_thread_attach");
    gIl2CppClassGetTypeObject = (Il2CppClassGetTypeObject)dlsym(RTLD_DEFAULT, "il2cpp_class_get_type_object");
    gIl2CppObjectUnbox = (Il2CppObjectUnbox)dlsym(RTLD_DEFAULT, "il2cpp_object_unbox");

    return gIl2CppDomainGet != NULL && gIl2CppDomainGetAssemblies != NULL &&
        gIl2CppAssemblyGetImage != NULL && gIl2CppClassFromName != NULL &&
        gIl2CppClassGetMethodFromName != NULL && gIl2CppRuntimeInvoke != NULL;
}
/* 解析il2cpp全部api入口*/
static void *FindClass(const char *assemblyName, const char *namespaceName, const char *className) {
    if (!ResolveIl2Cpp()) return NULL;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NULL;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);
    size_t count = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &count);
    for (size_t i = 0; i < count; i++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[i]);
        const char *(*imageName)(const Il2CppImage *) = (const char *(*)(const Il2CppImage *))dlsym(RTLD_DEFAULT, "il2cpp_image_get_name");
        if (imageName != NULL && strcmp(imageName(image), assemblyName) != 0) continue;
        void *klass = gIl2CppClassFromName(image, namespaceName, className);
        if (klass != NULL) return klass;
    }
    return NULL;
}
/* findclass 工具函数 按照dll名 命名空间 类名查找c#*/
static void ApplyCameraFollow(float thirdPersonFov, float firstPersonFov) {
    void *klass = FindClass("UpdateScript_500.dll", "", "CameraFollow");
    if (klass == NULL || gIl2CppClassGetMethodFromName == NULL) return;
    const MethodInfo *getInstance = gIl2CppClassGetMethodFromName(klass, "get_instance", 0);
    Il2CppObject *exception = NULL;
    Il2CppObject *instance = getInstance ? gIl2CppRuntimeInvoke(getInstance, NULL, NULL, &exception) : NULL;
    if (instance == NULL || exception != NULL) return;

    float firstValue = (float)MAX(30.0, MIN(170.0, firstPersonFov));
    float thirdValue = (float)MAX(30.0, MIN(170.0, thirdPersonFov));
    if (gIl2CppClassGetFieldFromName == NULL || gIl2CppFieldSetValue == NULL) return;
    void *firstField = gIl2CppClassGetFieldFromName(klass, "UGC2FirstFOV");
    void *thirdField = gIl2CppClassGetFieldFromName(klass, "UGC2FOV");
    if (firstField != NULL && gIl2CppFieldGetOffset(firstField) != (size_t)-1) gIl2CppFieldSetValue(instance, firstField, &firstValue);
    if (thirdField != NULL && gIl2CppFieldGetOffset(thirdField) != (size_t)-1) gIl2CppFieldSetValue(instance, thirdField, &thirdValue);
}
/*修改camerafollow两个fov字段 */
static NSUInteger ApplyFieldOfView(CGFloat fieldOfView) {
    if (!ResolveIl2Cpp()) return 0;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return 0;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *cameraClass = NULL;
    for (size_t index = 0; index < assemblyCount && cameraClass == NULL; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        cameraClass = gIl2CppClassFromName(image, "UnityEngine", "Camera");
    }
    if (cameraClass == NULL) return 0;

    const MethodInfo *allCameras = gIl2CppClassGetMethodFromName(cameraClass, "get_allCameras", 0);
    const MethodInfo *setFieldOfView = gIl2CppClassGetMethodFromName(cameraClass, "set_fieldOfView", 1);
    const MethodInfo *getOrthographic = gIl2CppClassGetMethodFromName(cameraClass, "get_orthographic", 0);
    const MethodInfo *getTargetTexture = gIl2CppClassGetMethodFromName(cameraClass, "get_targetTexture", 0);
    if (allCameras == NULL || setFieldOfView == NULL) return 0;

    Il2CppObject *exception = NULL;
    Il2CppArray *cameras = (Il2CppArray *)gIl2CppRuntimeInvoke(allCameras, NULL, NULL, &exception);
    if (exception != NULL || cameras == NULL) return 0;

    float value = (float)MAX(45.0, MIN(120.0, fieldOfView));
    void *arguments[] = { &value };
    NSUInteger touched = 0;
    for (uintptr_t index = 0; index < cameras->maxLength; index++) {
        Il2CppObject *camera = cameras->objects[index];
        if (camera == NULL) continue;
        if (getOrthographic != NULL && gIl2CppObjectUnbox != NULL) {
            exception = NULL;
            Il2CppObject *orthoObj = gIl2CppRuntimeInvoke(getOrthographic, camera, NULL, &exception);
            if (exception == NULL && orthoObj != NULL) {
                BOOL isOrtho = *((BOOL *)gIl2CppObjectUnbox(orthoObj));
                if (isOrtho) continue;
            }
        }
        if (getTargetTexture != NULL) {
            exception = NULL;
            Il2CppObject *rtObj = gIl2CppRuntimeInvoke(getTargetTexture, camera, NULL, &exception);
            if (exception == NULL && rtObj != NULL) continue;
        }
        exception = NULL;
        gIl2CppRuntimeInvoke(setFieldOfView, camera, arguments, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*camera.get_allcameras遍历 跳过get_orthographic正交和get_targettexture渲染纹理 对剩余相机set_fieldofview */
static Il2CppArray *ScanObjectsByType(const char *targetClassName, BOOL includeInactive) {
    if (!ResolveIl2Cpp() || gIl2CppClassGetTypeObject == NULL) return NULL;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NULL;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *targetKlass = NULL;
    void *hostKlass = NULL;
    const char *hostClassName = includeInactive ? "Resources" : "Object";
    const char *methodName = includeInactive ? "FindObjectsOfTypeAll" : "FindObjectsOfType";
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (targetKlass == NULL) targetKlass = gIl2CppClassFromName(image, "UnityEngine", targetClassName);
        if (hostKlass == NULL) hostKlass = gIl2CppClassFromName(image, "UnityEngine", hostClassName);
        if (targetKlass != NULL && hostKlass != NULL) break;
    }
    if (targetKlass == NULL || hostKlass == NULL) return NULL;

    Il2CppObject *typeObject = gIl2CppClassGetTypeObject(targetKlass);
    if (typeObject == NULL) return NULL;

    const MethodInfo *findMethod = gIl2CppClassGetMethodFromName(hostKlass, methodName, 1);
    if (findMethod == NULL) return NULL;

    Il2CppObject *exception = NULL;
    void *arguments[] = { &typeObject };
    return (Il2CppArray *)gIl2CppRuntimeInvoke(findMethod, NULL, arguments, &exception);
}
/*统一扫描入口 false=object.findsoftoftype只扫激活 true=resources.findobjectsoftypeall含隐藏 */

static NSUInteger SetAllComponentsVisible(BOOL visible, BOOL includeInactive) {
    if (!ResolveIl2Cpp()) return 0;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return 0;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *componentKlass = NULL;
    void *gameObjKlass = NULL;
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (componentKlass == NULL) componentKlass = gIl2CppClassFromName(image, "UnityEngine", "Component");
        if (gameObjKlass == NULL) gameObjKlass = gIl2CppClassFromName(image, "UnityEngine", "GameObject");
        if (componentKlass != NULL && gameObjKlass != NULL) break;
    }
    if (componentKlass == NULL || gameObjKlass == NULL) return 0;

    Il2CppArray *result = ScanObjectsByType("MonoBehaviour", includeInactive);
    if (result == NULL) return 0;

    const MethodInfo *getGameObject = gIl2CppClassGetMethodFromName(componentKlass, "get_gameObject", 0);
    const MethodInfo *setActive = gIl2CppClassGetMethodFromName(gameObjKlass, "SetActive", 1);
    if (getGameObject == NULL || setActive == NULL) return 0;

    BOOL value = visible ? YES : NO;
    void *activeArgs[] = { &value };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < result->maxLength; index++) {
        Il2CppObject *behaviour = result->objects[index];
        if (behaviour == NULL) continue;
        exception = NULL;
        Il2CppObject *gameObject = gIl2CppRuntimeInvoke(getGameObject, behaviour, NULL, &exception);
        if (exception != NULL || gameObject == NULL) continue;
        exception = NULL;
        gIl2CppRuntimeInvoke(setActive, gameObject, activeArgs, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*object.findsoftype(typeof(monobehaviour))扫描全部组件 component.get_gameobject拿节点 gameobject.setactive切显隐 */
static void ApplyTimeScale(float multiplier) {
    if (!ResolveIl2Cpp()) return;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *timeKlass = NULL;
    for (size_t index = 0; index < assemblyCount && timeKlass == NULL; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        timeKlass = gIl2CppClassFromName(image, "UnityEngine", "Time");
    }
    if (timeKlass == NULL || gIl2CppClassGetMethodFromName == NULL) return;

    const MethodInfo *setTimeScale = gIl2CppClassGetMethodFromName(timeKlass, "set_timeScale", 1);
    if (setTimeScale == NULL) return;

    float value = (float)MAX(0.0, MIN(3.0, multiplier));
    void *arguments[] = { &value };
    Il2CppObject *exception = NULL;
    gIl2CppRuntimeInvoke(setTimeScale, NULL, arguments, &exception);
}
/*time.set_timescale静态调用 改全局时间倍率 0冻结1正常>1加速 */
static NSUInteger SetAllLineRenderersVisible(BOOL visible, BOOL includeInactive) {
    if (!ResolveIl2Cpp()) return 0;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return 0;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *lineKlass = NULL;
    void *rendererKlass = NULL;
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (lineKlass == NULL) lineKlass = gIl2CppClassFromName(image, "UnityEngine", "LineRenderer");
        if (rendererKlass == NULL) rendererKlass = gIl2CppClassFromName(image, "UnityEngine", "Renderer");
        if (lineKlass != NULL && rendererKlass != NULL) break;
    }
    if (lineKlass == NULL || rendererKlass == NULL) return 0;

    Il2CppArray *result = ScanObjectsByType("LineRenderer", includeInactive);
    if (result == NULL) return 0;

    const MethodInfo *setEnabled = gIl2CppClassGetMethodFromName(rendererKlass, "set_enabled", 1);
    if (setEnabled == NULL) return 0;

    BOOL value = visible ? YES : NO;
    void *enableArgs[] = { &value };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < result->maxLength; index++) {
        Il2CppObject *lineRenderer = result->objects[index];
        if (lineRenderer == NULL) continue;
        exception = NULL;
        gIl2CppRuntimeInvoke(setEnabled, lineRenderer, enableArgs, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*object.findsoftype(typeof(linerenderer))扫描全部linerenderer renderer.set_enabled切显隐 */
static BOOL CountLineRendererStats(NSUInteger *outLines, NSUInteger *outPoints, BOOL includeInactive) {
    if (outLines) *outLines = 0;
    if (outPoints) *outPoints = 0;
    if (!ResolveIl2Cpp() || gIl2CppObjectUnbox == NULL) return NO;

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(gIl2CppDomainGet(), &assemblyCount);
    void *lineKlass = NULL;
    for (size_t index = 0; index < assemblyCount && lineKlass == NULL; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        lineKlass = gIl2CppClassFromName(image, "UnityEngine", "LineRenderer");
    }
    if (lineKlass == NULL) return NO;

    Il2CppArray *result = ScanObjectsByType("LineRenderer", includeInactive);
    if (result == NULL) return NO;

    const MethodInfo *getPositionCount = gIl2CppClassGetMethodFromName(lineKlass, "get_positionCount", 0);
    if (getPositionCount == NULL) return NO;

    NSUInteger lines = 0;
    NSUInteger points = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < result->maxLength; index++) {
        Il2CppObject *line = result->objects[index];
        if (line == NULL) continue;
        lines++;
        exception = NULL;
        Il2CppObject *countObj = gIl2CppRuntimeInvoke(getPositionCount, line, NULL, &exception);
        if (exception != NULL || countObj == NULL) continue;
        int32_t count = *((int32_t *)gIl2CppObjectUnbox(countObj));
        if (count > 0) points += (NSUInteger)count;
    }
    if (outLines) *outLines = lines;
    if (outPoints) *outPoints = points;
    return YES;
}
/*linerenderer.get_positioncount统计线数和点数 */
static BOOL FindNearestObjectDistance(float *outDistance, BOOL includeInactive) {
    if (outDistance) *outDistance = 0.0f;
    if (!ResolveIl2Cpp() || gIl2CppObjectUnbox == NULL) return NO;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NO;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *componentKlass = NULL;
    void *cameraKlass = NULL;
    void *transformKlass = NULL;
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (componentKlass == NULL) componentKlass = gIl2CppClassFromName(image, "UnityEngine", "Component");
        if (cameraKlass == NULL) cameraKlass = gIl2CppClassFromName(image, "UnityEngine", "Camera");
        if (transformKlass == NULL) transformKlass = gIl2CppClassFromName(image, "UnityEngine", "Transform");
        if (componentKlass != NULL && cameraKlass != NULL && transformKlass != NULL) break;
    }
    if (componentKlass == NULL || cameraKlass == NULL || transformKlass == NULL) return NO;

    const MethodInfo *getMain = gIl2CppClassGetMethodFromName(cameraKlass, "get_main", 0);
    const MethodInfo *getTransform = gIl2CppClassGetMethodFromName(componentKlass, "get_transform", 0);
    const MethodInfo *getPosition = gIl2CppClassGetMethodFromName(transformKlass, "get_position", 0);
    if (getMain == NULL || getTransform == NULL || getPosition == NULL) return NO;

    Il2CppObject *exception = NULL;
    Il2CppObject *mainCam = gIl2CppRuntimeInvoke(getMain, NULL, NULL, &exception);
    if (exception != NULL || mainCam == NULL) return NO;
    exception = NULL;
    Il2CppObject *mainTransform = gIl2CppRuntimeInvoke(getTransform, mainCam, NULL, &exception);
    if (exception != NULL || mainTransform == NULL) return NO;
    exception = NULL;
    Il2CppObject *mainPosObj = gIl2CppRuntimeInvoke(getPosition, mainTransform, NULL, &exception);
    if (exception != NULL || mainPosObj == NULL) return NO;
    float *mainPos = (float *)gIl2CppObjectUnbox(mainPosObj);
    float mx = mainPos[0], my = mainPos[1], mz = mainPos[2];

    Il2CppArray *result = ScanObjectsByType("MonoBehaviour", includeInactive);
    if (result == NULL) return NO;

    float minDist = FLT_MAX;
    BOOL found = NO;
    for (uintptr_t index = 0; index < result->maxLength; index++) {
        Il2CppObject *behaviour = result->objects[index];
        if (behaviour == NULL) continue;
        exception = NULL;
        Il2CppObject *transform = gIl2CppRuntimeInvoke(getTransform, behaviour, NULL, &exception);
        if (exception != NULL || transform == NULL) continue;
        exception = NULL;
        Il2CppObject *posObj = gIl2CppRuntimeInvoke(getPosition, transform, NULL, &exception);
        if (exception != NULL || posObj == NULL) continue;
        float *pos = (float *)gIl2CppObjectUnbox(posObj);
        float dx = pos[0] - mx;
        float dy = pos[1] - my;
        float dz = pos[2] - mz;
        float dist = sqrtf(dx * dx + dy * dy + dz * dz);
        if (dist < minDist) {
            minDist = dist;
            found = YES;
        }
    }
    if (found && outDistance) *outDistance = minDist;
    return found;
}
/*camera.get_main主相机 component.get_transform transform.get_position 扫描monobehaviour算vector3距离 */
@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *floatingButton;
@property(nonatomic, assign) CGFloat firstPersonFOV;
@property(nonatomic, assign) CGFloat thirdPersonFOV;
@property(nonatomic, assign) CGFloat speedMultiplier;
@property(nonatomic, assign) CGFloat cameraDistance;
@property(nonatomic, assign) BOOL routeEnabled;
@property(nonatomic, assign) BOOL componentsVisible;
@property(nonatomic, strong) UILabel *componentsHint;
@property(nonatomic, assign) BOOL espEnabled;
@property(nonatomic, strong) NSTimer *espTimer;
@property(nonatomic, strong) UILabel *espHint;
@property(nonatomic, strong) UILabel *routeHint;
@property(nonatomic, strong) UILabel *cameraHint;
@property(nonatomic, assign) BOOL includeInactive;
@end
/* 悬浮ui控制器*/
@implementation RussOverlayController

- (void)install {
    [self loadSettings];


    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.windows.firstObject != nil) {
                window = windowScene.windows.firstObject;
                break;
            }
        }
        if (window == nil || self.floatingButton != nil) {
            return;
        }

        self.floatingButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.floatingButton.frame = CGRectMake(18.0, 180.0, 54.0, 54.0);
        self.floatingButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.55 blue:0.45 alpha:0.96];
        self.floatingButton.layer.cornerRadius = 27.0;
        [self.floatingButton setTitle:@"R" forState:UIControlStateNormal];
        [self.floatingButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self.floatingButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *buttonDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
        buttonDrag.cancelsTouchesInView = NO;
        [self.floatingButton addGestureRecognizer:buttonDrag];
        [window addSubview:self.floatingButton];

        [self buildPanelInWindow:window];
        ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV);
        ApplyTimeScale(self.speedMultiplier);
        if (self.espEnabled) {
            self.espHint.text = @"（扫描中...）";
            self.espTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateESP) userInfo:nil repeats:YES];
        }
    });
}
/* ui初始化入口*/
- (void)buildPanelInWindow:(UIWindow *)window {
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(84.0, 130.0, 280.0, 500.0)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
    self.panel.layer.cornerRadius = 8.0;
    self.panel.hidden = YES;

    UIPanGestureRecognizer *panelDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    [self.panel addGestureRecognizer:panelDrag];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 14.0, 210.0, 26.0)];
    title.text = @"视角调试";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:17.0];
    [self.panel addSubview:title];

    [self addSliderWithTitle:@"第一人称 FOV" value:self.firstPersonFOV minimum:30.0 maximum:170.0 y:54.0 action:@selector(firstPersonFOVChanged:)];
    [self addSliderWithTitle:@"第三人称 FOV" value:self.thirdPersonFOV minimum:30.0 maximum:170.0 y:120.0 action:@selector(thirdPersonFOVChanged:)];
    [self addSliderWithTitle:@"速度倍率" value:self.speedMultiplier minimum:0.5 maximum:3.0 y:186.0 action:@selector(speedChanged:)];

    UISwitch *routeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 250.0, 0.0, 0.0)];
    routeSwitch.on = self.routeEnabled;
    [routeSwitch addTarget:self action:@selector(routeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:routeSwitch];

    UILabel *routeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 252.0, 150.0, 28.0)];
    routeLabel.text = @"路线显示";
    routeLabel.textColor = UIColor.whiteColor;
    routeLabel.font = [UIFont systemFontOfSize:14.0];
    [self.panel addSubview:routeLabel];

    self.routeHint = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 280.0, 248.0, 14.0)];
    self.routeHint.text = @"（LineRenderer 待扫描）";
    self.routeHint.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.routeHint.font = [UIFont systemFontOfSize:11.0];
    [self.panel addSubview:self.routeHint];

    UISwitch *componentsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 300.0, 0.0, 0.0)];
    componentsSwitch.on = self.componentsVisible;
    [componentsSwitch addTarget:self action:@selector(componentsChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:componentsSwitch];

    UILabel *componentsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 302.0, 150.0, 28.0)];
    componentsLabel.text = @"组件显隐";
    componentsLabel.textColor = UIColor.whiteColor;
    componentsLabel.font = [UIFont systemFontOfSize:14.0];
    [self.panel addSubview:componentsLabel];

    self.componentsHint = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 332.0, 248.0, 18.0)];
    self.componentsHint.text = @"（FindObjectsOfType 待扫描）";
    self.componentsHint.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.componentsHint.font = [UIFont systemFontOfSize:11.0];
    [self.panel addSubview:self.componentsHint];

    UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 366.0, 0.0, 0.0)];
    espSwitch.on = self.espEnabled;
    [espSwitch addTarget:self action:@selector(espChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:espSwitch];

    UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 368.0, 150.0, 28.0)];
    espLabel.text = @"ESP 距离";
    espLabel.textColor = UIColor.whiteColor;
    espLabel.font = [UIFont systemFontOfSize:14.0];
    [self.panel addSubview:espLabel];

    self.espHint = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 398.0, 248.0, 18.0)];
    self.espHint.text = @"（关闭中）";
    self.espHint.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.espHint.font = [UIFont systemFontOfSize:11.0];
    [self.panel addSubview:self.espHint];

    self.cameraHint = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 424.0, 248.0, 18.0)];
    self.cameraHint.text = @"（FOV 待应用）";
    self.cameraHint.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.cameraHint.font = [UIFont systemFontOfSize:11.0];
    [self.panel addSubview:self.cameraHint];

    UISwitch *inactiveSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 450.0, 0.0, 0.0)];
    inactiveSwitch.on = self.includeInactive;
    [inactiveSwitch addTarget:self action:@selector(inactiveChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:inactiveSwitch];

    UILabel *inactiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 452.0, 150.0, 28.0)];
    inactiveLabel.text = @"包含隐藏对象";
    inactiveLabel.textColor = UIColor.whiteColor;
    inactiveLabel.font = [UIFont systemFontOfSize:14.0];
    [self.panel addSubview:inactiveLabel];
    [window addSubview:self.panel];
}
/* 深色半透明面板 标题视角调试 调用addsliderwithtitle快速生成3个滑块第一人fov第三人fov 速度倍率 路线显示 面板加在顶层window*/
- (void)addSliderWithTitle:(NSString *)title value:(CGFloat)value minimum:(CGFloat)minimum maximum:(CGFloat)maximum y:(CGFloat)y action:(SEL)action {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16.0, y, 210.0, 20.0)];
    label.text = title;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:13.0];
    [self.panel addSubview:label];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(16.0, y + 24.0, 218.0, 22.0)];
    slider.minimumValue = minimum;
    slider.maximumValue = maximum;
    slider.value = value;
    [slider addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:slider];
}
/*滑块封装工具方法 */
- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
}
/*点击隐藏悬浮 */
- (void)handleDrag:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    UIView *container = view.superview;
    if (view == nil || container == nil) return;
    CGPoint translation = [gesture translationInView:container];
    CGPoint center = view.center;
    center.x += translation.x;
    center.y += translation.y;

    CGFloat halfWidth = view.bounds.size.width * 0.5;
    CGFloat halfHeight = view.bounds.size.height * 0.5;
    CGRect safe = container.bounds;
    if ([container isKindOfClass:[UIWindow class]]) {
        UIWindow *window = (UIWindow *)container;
        safe = UIEdgeInsetsInsetRect(window.bounds, window.safeAreaInsets);
    }
    center.x = MAX(safe.origin.x + halfWidth, MIN(safe.origin.x + safe.size.width - halfWidth, center.x));
    center.y = MAX(safe.origin.y + halfHeight, MIN(safe.origin.y + safe.size.height - halfHeight, center.y));
    view.center = center;
    [gesture setTranslation:CGPointMake(0.0, 0.0) inView:container];
}
/*手指拖动悬浮按钮或面板 限制中心点不超出安全区域 */
- (void)firstPersonFOVChanged:(UISlider *)sender {
    self.firstPersonFOV = sender.value;
    [self saveSettings];
    ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV);
    NSUInteger touched = ApplyFieldOfView(self.firstPersonFOV);
    self.cameraHint.text = [NSString stringWithFormat:@"（FOV 已应用 %lu 个相机）", (unsigned long)touched];
}
- (void)thirdPersonFOVChanged:(UISlider *)sender {
    self.thirdPersonFOV = sender.value;
    [self saveSettings];
    ApplyCameraFollow(self.thirdPersonFOV, self.firstPersonFOV);
    NSUInteger touched = ApplyFieldOfView(self.thirdPersonFOV);
    self.cameraHint.text = [NSString stringWithFormat:@"（FOV 已应用 %lu 个相机）", (unsigned long)touched];
}
- (void)speedChanged:(UISlider *)sender { self.speedMultiplier = sender.value; [self saveSettings]; ApplyTimeScale(sender.value); }
- (void)routeChanged:(UISwitch *)sender {
    self.routeEnabled = sender.isOn;
    [self saveSettings];
    NSUInteger count = SetAllLineRenderersVisible(sender.isOn, self.includeInactive);
    NSUInteger lines = 0, points = 0;
    CountLineRendererStats(&lines, &points, self.includeInactive);
    self.routeHint.text = [NSString stringWithFormat:@"（%@ %lu 条线, %lu 个点）", sender.isOn ? @"已显示" : @"已隐藏", (unsigned long)count, (unsigned long)points];
}
- (void)componentsChanged:(UISwitch *)sender {
    self.componentsVisible = sender.isOn;
    [self saveSettings];
    NSUInteger count = SetAllComponentsVisible(sender.isOn, self.includeInactive);
    self.componentsHint.text = [NSString stringWithFormat:@"（%@ %lu 个）", sender.isOn ? @"已显示" : @"已隐藏", (unsigned long)count];
}
- (void)espChanged:(UISwitch *)sender {
    self.espEnabled = sender.isOn;
    [self saveSettings];
    if (sender.isOn) {
        self.espHint.text = @"（扫描中...）";
        self.espTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateESP) userInfo:nil repeats:YES];
    } else {
        [self.espTimer invalidate];
        self.espTimer = nil;
        self.espHint.text = @"（关闭中）";
    }
}
- (void)updateESP {
    float distance = 0.0f;
    if (FindNearestObjectDistance(&distance, self.includeInactive)) {
        self.espHint.text = [NSString stringWithFormat:@"（最近对象: %.2f 米）", distance];
    } else {
        self.espHint.text = @"（未找到对象）";
    }
}
- (void)inactiveChanged:(UISwitch *)sender {
    self.includeInactive = sender.isOn;
    [self saveSettings];
}
/*fov滑块拖动 更新成员变量 savesetting永久化 立刻调用applycamerafollow刷新游戏视角 同时applyfieldofview过滤正交/RT相机写fov 速度滑块调time.set_timescale 路线开关扫描linerenderer并renderer.set_enabled + get_positioncount统计 组件开关扫描monobehaviour拿gameobject.setactive切显隐 ESP开关扫描monobehaviour算vector3距离 包含隐藏开关切findobjectsoftype/findobjectsoftypeall */
- (void)loadSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.firstPersonFOV = [defaults objectForKey:@"russ.firstFOV"] ? [defaults floatForKey:@"russ.firstFOV"] : 75.0;
    self.thirdPersonFOV = [defaults objectForKey:@"russ.thirdFOV"] ? [defaults floatForKey:@"russ.thirdFOV"] : 75.0;
    self.speedMultiplier = [defaults objectForKey:@"russ.speed"] ? [defaults floatForKey:@"russ.speed"] : 1.0;
    self.cameraDistance = [defaults objectForKey:@"russ.distance"] ? [defaults floatForKey:@"russ.distance"] : 8.0;
    self.routeEnabled = [defaults boolForKey:@"russ.route"];
    self.componentsVisible = [defaults boolForKey:@"russ.components"];
    self.espEnabled = [defaults boolForKey:@"russ.esp"];
    self.includeInactive = [defaults boolForKey:@"russ.inactive"];
}
/* 加载本地持久化配置 从系统nsuserdefaults读取上次保存参数 不存在设置的默认值*/
- (void)saveSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setFloat:self.firstPersonFOV forKey:@"russ.firstFOV"];
    [defaults setFloat:self.thirdPersonFOV forKey:@"russ.thirdFOV"];
    [defaults setFloat:self.speedMultiplier forKey:@"russ.speed"];
    [defaults setFloat:self.cameraDistance forKey:@"russ.distance"];
    [defaults setBool:self.routeEnabled forKey:@"russ.route"];
    [defaults setBool:self.componentsVisible forKey:@"russ.components"];
    [defaults setBool:self.espEnabled forKey:@"russ.esp"];
    [defaults setBool:self.includeInactive forKey:@"russ.inactive"];
}
/* 保存配置到本地 下次打开延用fov*/
@end

static RussOverlayController *gOverlayController;

__attribute__((constructor))
static void RussRebuiltInitialize(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        gOverlayController = [RussOverlayController new];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:NSOperationQueue.mainQueue
                                                      usingBlock:^(__unused NSNotification *notification) {
            [gOverlayController install];
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [gOverlayController install];
        });
    });
}
/* dylib加载自动自动执行 不需要外调用*/
/* tweak注入*/