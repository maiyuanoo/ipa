#import <Foundation/Foundation.h>/*OC对象 nsuserdefault 通知*/
#import <UIKit/UIKit.h>/* uiview uibutton uislider ui界面*/
#import <QuartzCore/CADisplayLink.h>/*cadisplaylink每帧回调*/
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
typedef Il2CppObject *(*Il2CppObjectUnbox)(Il2CppObject *object);
typedef const char *(*Il2CppImageGetName)(const Il2CppImage *image);
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
static Il2CppObjectUnbox gIl2CppObjectUnbox;
static void *gUnityFrameworkHandle;
static const void *(*gIl2CppClassGetType)(void *klass);
static Il2CppObject *(*gIl2CppTypeGetObject)(const void *type);
static void (*gIl2CppFieldStaticGetValue)(void *field, void *value);
static Il2CppImageGetName gIl2CppImageGetName;
/*unityframework句柄+二级api class_get_type+type_get_object替代未导出的get_type_object */
static BOOL ResolveIl2Cpp(void) {
    if (gIl2CppDomainGet != NULL) {
        return YES;
    }
    gUnityFrameworkHandle = dlopen("UnityFramework.framework/UnityFramework", RTLD_LAZY | RTLD_GLOBAL);
    void *base = gUnityFrameworkHandle != NULL ? gUnityFrameworkHandle : RTLD_DEFAULT;
    gIl2CppDomainGet = (Il2CppDomainGet)dlsym(base, "il2cpp_domain_get");
    gIl2CppDomainGetAssemblies = (Il2CppDomainGetAssemblies)dlsym(base, "il2cpp_domain_get_assemblies");
    gIl2CppAssemblyGetImage = (Il2CppAssemblyGetImage)dlsym(base, "il2cpp_assembly_get_image");
    gIl2CppClassFromName = (Il2CppClassFromName)dlsym(base, "il2cpp_class_from_name");
    gIl2CppClassGetMethodFromName = (Il2CppClassGetMethodFromName)dlsym(base, "il2cpp_class_get_method_from_name");
    gIl2CppClassGetFieldFromName = (Il2CppClassGetFieldFromName)dlsym(base, "il2cpp_class_get_field_from_name");
    gIl2CppFieldGetOffset = (Il2CppFieldGetOffset)dlsym(base, "il2cpp_field_get_offset");
    gIl2CppFieldSetValue = (Il2CppFieldSetValue)dlsym(base, "il2cpp_field_set_value");
    gIl2CppRuntimeInvoke = (Il2CppRuntimeInvoke)dlsym(base, "il2cpp_runtime_invoke");
    gIl2CppThreadAttach = (Il2CppThreadAttach)dlsym(base, "il2cpp_thread_attach");
    gIl2CppObjectUnbox = (Il2CppObjectUnbox)dlsym(base, "il2cpp_object_unbox");
    return gIl2CppDomainGet != NULL && gIl2CppDomainGetAssemblies != NULL &&
        gIl2CppAssemblyGetImage != NULL && gIl2CppClassFromName != NULL &&
        gIl2CppClassGetMethodFromName != NULL && gIl2CppRuntimeInvoke != NULL;
}
/*照原版显式dlopen unityframework 失败回退rtld_default */
static void ResolveSecondaryApi(void) {
    if (gIl2CppDomainGet == NULL) return;
    void *base = gUnityFrameworkHandle != NULL ? gUnityFrameworkHandle : RTLD_DEFAULT;
    if (gIl2CppClassGetType == NULL) gIl2CppClassGetType = (const void *(*)(void *))dlsym(base, "il2cpp_class_get_type");
    if (gIl2CppTypeGetObject == NULL) gIl2CppTypeGetObject = (Il2CppObject *(*)(const void *))dlsym(base, "il2cpp_type_get_object");
    if (gIl2CppFieldStaticGetValue == NULL) gIl2CppFieldStaticGetValue = (void (*)(void *, void *))dlsym(base, "il2cpp_field_static_get_value");
    if (gIl2CppImageGetName == NULL) gIl2CppImageGetName = (Il2CppImageGetName)dlsym(base, "il2cpp_image_get_name");
}
/*首次调用时解析二级api */
static Il2CppObject *GetTypeObjectForClass(void *klass) {
    if (klass == NULL) return NULL;
    ResolveSecondaryApi();
    if (gIl2CppClassGetType == NULL || gIl2CppTypeGetObject == NULL) return NULL;
    const void *type = gIl2CppClassGetType(klass);
    if (type == NULL) return NULL;
    return gIl2CppTypeGetObject(type);
}
/*class→system.type对象 已验证class_get_type/type_get_object均导出 */
static Il2CppObject *GetTypeObjectForClass(void *klass);
static void *FindClassInAllAssemblies(const char *namespaceName, const char *className);
/*前置声明 避免调用顺序问题 */
static void *FindClass(const char *assemblyName, const char *namespaceName, const char *className) {
    if (!ResolveIl2Cpp()) return NULL;
    ResolveSecondaryApi();
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NULL;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);
    size_t count = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &count);
    for (size_t i = 0; i < count; i++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[i]);
        if (gIl2CppImageGetName != NULL && assemblyName != NULL) {
            const char *name = gIl2CppImageGetName(image);
            if (name == NULL || strstr(name, assemblyName) != name) {
                void *tryKlass = gIl2CppClassFromName(image, namespaceName, className);
                if (tryKlass != NULL) return tryKlass;
                continue;
            }
        }
        void *klass = gIl2CppClassFromName(image, namespaceName, className);
        if (klass != NULL) return klass;
    }
    return NULL;
}
/* findclass 按程序集名(子串匹配 兼容热更assembly.load大小写) 命名空间 类名查c#类 */
static void *gCameraFollowKlass;
/*camerafollow类缓存(热更程序集晚加载 首次找到后缓存) 实例每次现取防野指针 */
static Il2CppObject *GetCameraFollowInstance(void) {
    if (!ResolveIl2Cpp()) return NULL;
    if (gCameraFollowKlass == NULL) {
        gCameraFollowKlass = FindClass("UpdateScript_500", "", "CameraFollow");
        if (gCameraFollowKlass == NULL) return NULL;
    }
    Il2CppObject *exception = NULL;
    const MethodInfo *getInstance = gIl2CppClassGetMethodFromName(gCameraFollowKlass, "get_instance", 0);
    if (getInstance != NULL) {
        Il2CppObject *instance = gIl2CppRuntimeInvoke(getInstance, NULL, NULL, &exception);
        if (exception == NULL && instance != NULL) return instance;
    }
    ResolveSecondaryApi();
    static const char *kInstanceNames[] = { "instance", "Instance", "_instance", "mInstance", "m_instance" };
    for (size_t i = 0; i < 5 && gIl2CppFieldStaticGetValue != NULL; i++) {
        void *field = gIl2CppClassGetFieldFromName(gCameraFollowKlass, kInstanceNames[i]);
        if (field == NULL) continue;
        Il2CppObject *instance = NULL;
        gIl2CppFieldStaticGetValue(field, &instance);
        if (instance != NULL) return instance;
    }
    return NULL;
}
/*原版dylib确认调用get_instance 备用静态字段instance 每次现取不缓存防gc/销毁后野指针 */
static BOOL ApplyCameraFollow(float thirdPersonFov, float firstPersonFov) {
    Il2CppObject *instance = GetCameraFollowInstance();
    if (instance == NULL) return NO;
    void *klass = gCameraFollowKlass != NULL ? gCameraFollowKlass : *(void **)instance;
    if (gIl2CppClassGetFieldFromName == NULL || gIl2CppFieldSetValue == NULL) return NO;
    float firstValue = (float)MAX(30.0, MIN(170.0, firstPersonFov));
    float thirdValue = (float)MAX(30.0, MIN(170.0, thirdPersonFov));
    void *firstField = gIl2CppClassGetFieldFromName(klass, "UGC2FirstFOV");
    void *thirdField = gIl2CppClassGetFieldFromName(klass, "UGC2FOV");
    BOOL done = NO;
    if (firstField != NULL) {
        gIl2CppFieldSetValue(instance, firstField, &firstValue);
        done = YES;
    }
    if (thirdField != NULL) {
        gIl2CppFieldSetValue(instance, thirdField, &thirdValue);
        done = YES;
    }
    return done;
}
/*camerafollow.ugc2fov/ugc2firstfov字段直写 fieldsetvalue 原版同款字段名 dll已验证 */
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

    float value = (float)MAX(20.0, MIN(175.0, fieldOfView));
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
    if (!ResolveIl2Cpp()) return NULL;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NULL;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *targetKlass = NULL;
    void *hostKlass = NULL;
    const char *hostClassName = includeInactive ? "Resources" : "Object";
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (targetKlass == NULL) targetKlass = gIl2CppClassFromName(image, "UnityEngine", targetClassName);
        if (hostKlass == NULL) hostKlass = gIl2CppClassFromName(image, "UnityEngine", hostClassName);
        if (targetKlass != NULL && hostKlass != NULL) break;
    }
    if (targetKlass == NULL || hostKlass == NULL) return NULL;

    const MethodInfo *findMethod = NULL;
    if (includeInactive) {
        findMethod = gIl2CppClassGetMethodFromName(hostKlass, "FindObjectsOfTypeAll", 1);
        if (findMethod == NULL) {
            void *objectKlass = FindClassInAllAssemblies("UnityEngine", "Object");
            if (objectKlass != NULL) findMethod = gIl2CppClassGetMethodFromName(objectKlass, "FindObjectsOfTypeAll", 1);
        }
    } else {
        findMethod = gIl2CppClassGetMethodFromName(hostKlass, "FindObjectsOfType", 1);
    }
    if (findMethod == NULL) return NULL;

    Il2CppObject *typeObject = GetTypeObjectForClass(targetKlass);
    if (typeObject == NULL) return NULL;

    Il2CppObject *exception = NULL;
    void *arguments[] = { typeObject };
    return (Il2CppArray *)gIl2CppRuntimeInvoke(findMethod, NULL, arguments, &exception);
}
/*统一扫描 gettypeobjectforclass拿type 引用类型参数直接传对象指针(不能取地址!) host为resources.findobjectsoftypeall或object.findobjectsoftype */

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
static void *gCameraKlass;
static void *gComponentKlass;
static void *gTransformKlass;
/*缓存camerA/component/transform类避免每帧重复查 */
static BOOL EnsureUnityKlasses(void) {
    if (gCameraKlass != NULL && gComponentKlass != NULL && gTransformKlass != NULL) return YES;
    if (!ResolveIl2Cpp()) return NO;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NO;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);
    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    for (size_t index = 0; index < assemblyCount; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        if (gCameraKlass == NULL) gCameraKlass = gIl2CppClassFromName(image, "UnityEngine", "Camera");
        if (gComponentKlass == NULL) gComponentKlass = gIl2CppClassFromName(image, "UnityEngine", "Component");
        if (gTransformKlass == NULL) gTransformKlass = gIl2CppClassFromName(image, "UnityEngine", "Transform");
    }
    return gCameraKlass != NULL && gComponentKlass != NULL && gTransformKlass != NULL;
}
/*遍历程序集找三个unity基类并缓存 */

static Il2CppObject *GetMainCameraObject(void) {
    if (!EnsureUnityKlasses() || gIl2CppClassGetMethodFromName == NULL) return NULL;
    const MethodInfo *getMain = gIl2CppClassGetMethodFromName(gCameraKlass, "get_main", 0);
    if (getMain == NULL) return NULL;
    Il2CppObject *exception = NULL;
    Il2CppObject *camera = gIl2CppRuntimeInvoke(getMain, NULL, NULL, &exception);
    if (exception != NULL || camera == NULL) return NULL;
    return camera;
}
/*camera.get_main拿主相机 */

static BOOL GetObjectWorldPosition(Il2CppObject *component, float *outX, float *outY, float *outZ) {
    if (component == NULL || gIl2CppObjectUnbox == NULL) return NO;
    const MethodInfo *getTransform = gIl2CppClassGetMethodFromName(gComponentKlass, "get_transform", 0);
    const MethodInfo *getPosition = gIl2CppClassGetMethodFromName(gTransformKlass, "get_position", 0);
    if (getTransform == NULL || getPosition == NULL) return NO;
    Il2CppObject *exception = NULL;
    Il2CppObject *transform = gIl2CppRuntimeInvoke(getTransform, component, NULL, &exception);
    if (exception != NULL || transform == NULL) return NO;
    exception = NULL;
    Il2CppObject *posObj = gIl2CppRuntimeInvoke(getPosition, transform, NULL, &exception);
    if (exception != NULL || posObj == NULL) return NO;
    float *pos = (float *)gIl2CppObjectUnbox(posObj);
    if (outX) *outX = pos[0];
    if (outY) *outY = pos[1];
    if (outZ) *outZ = pos[2];
    return YES;
}
/*component.get_transform transform.get_position unbox出vector3 */

static BOOL ProjectWorldToScreen(Il2CppObject *camera, float wx, float wy, float wz, float *outX, float *outY, float *outZ) {
    if (camera == NULL || gIl2CppObjectUnbox == NULL) return NO;
    const MethodInfo *worldToScreen = gIl2CppClassGetMethodFromName(gCameraKlass, "WorldToScreenPoint", 1);
    if (worldToScreen == NULL) return NO;
    struct { float x, y, z; } world = { wx, wy, wz };
    void *arguments[] = { &world };
    Il2CppObject *exception = NULL;
    Il2CppObject *screenObj = gIl2CppRuntimeInvoke(worldToScreen, camera, arguments, &exception);
    if (exception != NULL || screenObj == NULL) return NO;
    float *screen = (float *)gIl2CppObjectUnbox(screenObj);
    if (outX) *outX = screen[0];
    if (outY) *outY = screen[1];
    if (outZ) *outZ = screen[2];
    return YES;
}
/*camera.worldtoscreenpoint投影世界坐标到屏幕 */

static void *FindClassInAllAssemblies(const char *namespaceName, const char *className) {
    if (!ResolveIl2Cpp()) return NULL;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NULL;
    if (gIl2CppThreadAttach != NULL) gIl2CppThreadAttach(domain);
    size_t count = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &count);
    for (size_t i = 0; i < count; i++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[i]);
        void *klass = gIl2CppClassFromName(image, namespaceName, className);
        if (klass != NULL) return klass;
    }
    return NULL;
}
/*跨程序集找类 含热更dll(qqpd.modules.scene等) */

static Il2CppArray *ScanObjectsOfTypeInNamespace(const char *namespaceName, const char *className, BOOL includeInactive) {
    if (!ResolveIl2Cpp()) return NULL;
    void *targetKlass = FindClassInAllAssemblies(namespaceName, className);
    if (targetKlass == NULL) return NULL;
    const MethodInfo *findMethod = NULL;
    if (includeInactive) {
        void *resourcesKlass = FindClassInAllAssemblies("UnityEngine", "Resources");
        if (resourcesKlass != NULL) findMethod = gIl2CppClassGetMethodFromName(resourcesKlass, "FindObjectsOfTypeAll", 1);
        if (findMethod == NULL) {
            void *objectKlass = FindClassInAllAssemblies("UnityEngine", "Object");
            if (objectKlass != NULL) findMethod = gIl2CppClassGetMethodFromName(objectKlass, "FindObjectsOfTypeAll", 1);
        }
    } else {
        void *objectKlass = FindClassInAllAssemblies("UnityEngine", "Object");
        if (objectKlass != NULL) findMethod = gIl2CppClassGetMethodFromName(objectKlass, "FindObjectsOfType", 1);
    }
    if (findMethod == NULL) return NULL;
    Il2CppObject *typeObject = GetTypeObjectForClass(targetKlass);
    if (typeObject == NULL) return NULL;
    Il2CppObject *exception = NULL;
    void *arguments[] = { typeObject };
    return (Il2CppArray *)gIl2CppRuntimeInvoke(findMethod, NULL, arguments, &exception);
}
/*任意命名空间类型扫描 棺材等热更类用 引用类型参数直接传对象指针 */

static BOOL ApplyFogRemoval(BOOL remove) {
    void *klass = FindClassInAllAssemblies("UnityEngine", "RenderSettings");
    if (klass == NULL || gIl2CppClassGetMethodFromName == NULL) return NO;
    const MethodInfo *setFog = gIl2CppClassGetMethodFromName(klass, "set_fog", 1);
    const MethodInfo *setDensity = gIl2CppClassGetMethodFromName(klass, "set_fogDensity", 1);
    if (setFog == NULL) return NO;
    BOOL fog = remove ? NO : YES;
    void *fogArgs[] = { &fog };
    Il2CppObject *exception = NULL;
    gIl2CppRuntimeInvoke(setFog, NULL, fogArgs, &exception);
    if (setDensity != NULL) {
        float density = remove ? 0.0f : 0.01f;
        void *densityArgs[] = { &density };
        exception = NULL;
        gIl2CppRuntimeInvoke(setDensity, NULL, densityArgs, &exception);
    }
    return exception == NULL;
}
/*rendersettings.set_fog(false)+set_fogdensity(0)去雾 dump.cs:516027/516057 恢复时fog(true)+density(0.01) */

static NSUInteger ApplyHighlight(BOOL on, float brightness) {
    void *lightKlass = FindClassInAllAssemblies("UnityEngine", "Light");
    if (lightKlass == NULL || gIl2CppClassGetMethodFromName == NULL) return 0;
    const MethodInfo *setIntensity = gIl2CppClassGetMethodFromName(lightKlass, "set_intensity", 1);
    if (setIntensity == NULL) return 0;
    Il2CppArray *lights = ScanObjectsOfTypeInNamespace("UnityEngine", "Light", YES);
    if (lights == NULL) return 0;
    float value = on ? brightness : 1.0f;
    void *arguments[] = { &value };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < lights->maxLength; index++) {
        Il2CppObject *light = lights->objects[index];
        if (light == NULL) continue;
        exception = NULL;
        gIl2CppRuntimeInvoke(setIntensity, light, arguments, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*light.set_intensity全场景灯亮度 高亮dump.cs 光照增强 关时恢复1.0 */

static NSUInteger ApplyCoffinReveal(BOOL reveal) {
    void *componentKlass = FindClassInAllAssemblies("UnityEngine", "Component");
    void *gameObjectKlass = FindClassInAllAssemblies("UnityEngine", "GameObject");
    if (componentKlass == NULL || gameObjectKlass == NULL) return 0;
    const MethodInfo *getGameObject = gIl2CppClassGetMethodFromName(componentKlass, "get_gameObject", 0);
    const MethodInfo *setActive = gIl2CppClassGetMethodFromName(gameObjectKlass, "SetActive", 1);
    if (getGameObject == NULL || setActive == NULL) return 0;
    Il2CppArray *coffins = ScanObjectsOfTypeInNamespace("Qqpd.Modules.Scene", "UGCObjectCoffin", YES);
    if (coffins == NULL) return 0;
    BOOL value = reveal ? YES : NO;
    void *activeArgs[] = { &value };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < coffins->maxLength; index++) {
        Il2CppObject *coffin = coffins->objects[index];
        if (coffin == NULL) continue;
        exception = NULL;
        Il2CppObject *gameObject = gIl2CppRuntimeInvoke(getGameObject, coffin, NULL, &exception);
        if (exception != NULL || gameObject == NULL) continue;
        exception = NULL;
        gIl2CppRuntimeInvoke(setActive, gameObject, activeArgs, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*扫描热更dll的ugcobjectcoffin gameobject.setactive强制显示棺材透视 */

static NSUInteger ApplyDemagnetization(BOOL on) {
    void *rigidKlass = FindClassInAllAssemblies("UnityEngine", "Rigidbody");
    if (rigidKlass == NULL || gIl2CppClassGetMethodFromName == NULL) return 0;
    const MethodInfo *setDrag = gIl2CppClassGetMethodFromName(rigidKlass, "set_drag", 1);
    const MethodInfo *setAngularDrag = gIl2CppClassGetMethodFromName(rigidKlass, "set_angularDrag", 1);
    if (setDrag == NULL) return 0;
    Il2CppArray *bodies = ScanObjectsOfTypeInNamespace("UnityEngine", "Rigidbody", YES);
    if (bodies == NULL) return 0;
    float drag = on ? 0.0f : 1.0f;
    void *dragArgs[] = { &drag };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < bodies->maxLength; index++) {
        Il2CppObject *body = bodies->objects[index];
        if (body == NULL) continue;
        exception = NULL;
        gIl2CppRuntimeInvoke(setDrag, body, dragArgs, &exception);
        if (setAngularDrag != NULL) {
            exception = NULL;
            gIl2CppRuntimeInvoke(setAngularDrag, body, dragArgs, &exception);
        }
        if (exception == NULL) touched++;
    }
    return touched;
}
/*rigidbody.set_drag/set_angulardrag归零 消磁dump.cs:947119/947125 关时恢复1.0 */

@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *mainPanel;
@property(nonatomic, strong) UIScrollView *panelScroll;
@property(nonatomic, strong) UIButton *floatingButton;
@property(nonatomic, strong) UIView *welcomePanel;
@property(nonatomic, strong) UITextField *cardField;
@property(nonatomic, strong) UILabel *welcomeHint;
@property(nonatomic, assign) BOOL verificationPassed;
@property(nonatomic, assign) BOOL panelVisible;
@property(nonatomic, strong) NSMutableDictionary *featureStates;
@property(nonatomic, assign) CGFloat firstPersonFOV;
@property(nonatomic, assign) CGFloat thirdPersonFOV;
@property(nonatomic, assign) CGFloat demagnetizationStrength;
@property(nonatomic, assign) CGFloat globalSpeedMultiplier;
@property(nonatomic, assign) CGFloat highlightBrightness;
@property(nonatomic, strong) CADisplayLink *coffinDisplayLink;
@property(nonatomic, strong) UIView *coffinOverlay;
@property(nonatomic, strong) NSMutableArray *coffinMarkers;
@property(nonatomic, strong) CADisplayLink *runtimeDisplayLink;
@property(nonatomic, assign) NSUInteger runtimeFrameTick;
@end
/*照原版menuview结构 mainpanel featurestates 4滑块值 验证passed 面板visible 棺材标记overlay*/
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
        [self.floatingButton setTitle:@"Russ" forState:UIControlStateNormal];
        self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        [self.floatingButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self.floatingButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *buttonDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
        buttonDrag.cancelsTouchesInView = NO;
        [self.floatingButton addGestureRecognizer:buttonDrag];
        [window addSubview:self.floatingButton];

        [self buildInterfaceInWindow:window];
        [self restoreFeatureRuntime];
    });
}
/*入口 悬浮按钮russ可拖动 点击开面板 构建ui+欢迎页 恢复上次功能状态*/
- (void)buildInterfaceInWindow:(UIWindow *)window {
    CGFloat screenHeight = window.bounds.size.height;
    CGFloat scrollHeight = MIN(440.0, screenHeight - 140.0);

    self.mainPanel = [[UIView alloc] initWithFrame:CGRectMake(10.0, 100.0, 300.0, scrollHeight + 44.0)];
    self.mainPanel.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.95];
    self.mainPanel.layer.cornerRadius = 12.0;
    self.mainPanel.hidden = YES;

    UIView *dragBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 44.0)];
    UIPanGestureRecognizer *panelDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanelDrag:)];
    [dragBar addGestureRecognizer:panelDrag];
    [self.mainPanel addSubview:dragBar];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 10.0, 220.0, 24.0)];
    title.text = @"Russ公益";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:18.0];
    [self.mainPanel addSubview:title];

    self.panelScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 44.0, 300.0, scrollHeight)];
    self.panelScroll.contentSize = CGSizeMake(300.0, 688.0);
    self.panelScroll.showsVerticalScrollIndicator = YES;
    [self.mainPanel addSubview:self.panelScroll];

    NSDictionary *cardSpecs = [self cardSpecifications];
    NSArray *order = [self featureOrder];
    CGFloat y = 6.0;
    for (NSString *key in order) {
        NSDictionary *spec = cardSpecs[key];
        BOOL isSlider = [spec[@"slider"] boolValue];
        CGFloat height = isSlider ? 70.0 : 66.0;
        [self buildFeatureCard:key spec:spec frame:CGRectMake(6.0, y, 288.0, height)];
        y += height + 4.0;
    }
    [window addSubview:self.mainPanel];
    [self buildWelcomeInWindow:window];
}
/*主面板 russ公益 标题+44pt拖动条 uiscrollview内9张功能卡片 contentSize688可正常滚动 + 欢迎验证页*/

- (NSArray *)featureOrder {
    return @[@"highlight", @"coffin", @"fog", @"wide", @"islandRoute",
             @"firstPersonFOV", @"thirdPersonFOV", @"demagnetization", @"globalSpeed"];
}
/*卡片顺序 高亮 棺材透视 去雾 广角 岛屿路线 第一人fov 第三人fov 消磁 速度 */

- (NSDictionary *)cardSpecifications {
    return @{
        @"highlight": @{@"title": @"高亮", @"icon": @"sun.max.fill", @"desc": @"增强场景光照亮度"},
        @"coffin": @{@"title": @"棺材透视", @"icon": @"shippingbox.fill", @"desc": @"显示所有棺材并标记位置"},
        @"fog": @{@"title": @"去雾", @"icon": @"cloud.fog.fill", @"desc": @"关闭场景雾效"},
        @"wide": @{@"title": @"广角视角", @"icon": @"viewfinder.circle.fill", @"desc": @"所有相机扩展到120度"},
        @"islandRoute": @{@"title": @"岛屿路线", @"icon": @"map.fill", @"desc": @"显示 LineRenderer 路线"},
        @"firstPersonFOV": @{@"title": @"第一人称 FOV", @"icon": @"person.crop.circle", @"slider": @YES, @"min": @30.0, @"max": @170.0, @"unit": @"°"},
        @"thirdPersonFOV": @{@"title": @"第三人称 FOV", @"icon": @"figure.walking", @"slider": @YES, @"min": @30.0, @"max": @170.0, @"unit": @"°"},
        @"demagnetization": @{@"title": @"消磁强度", @"icon": @"bolt.slash.fill", @"slider": @YES, @"min": @0.0, @"max": @100.0, @"unit": @"%"},
        @"globalSpeed": @{@"title": @"速度倍率", @"icon": @"hare.fill", @"slider": @YES, @"min": @0.5, @"max": @3.0, @"unit": @"x"}
    };
}
/*9张卡片定义 图标照原版sfsymbols 标题/说明/滑块范围 */

- (void)buildFeatureCard:(NSString *)key spec:(NSDictionary *)spec frame:(CGRect)frame {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [self.featureStates[key] boolValue] ? [UIColor colorWithWhite:0.20 alpha:0.95] : [UIColor colorWithWhite:0.14 alpha:0.95];
    card.layer.cornerRadius = 10.0;
    card.tag = [self cardTagForKey:key];
    [self.panelScroll addSubview:card];

    UIImage *icon = [UIImage systemImageNamed:spec[@"icon"]];
    if (icon != nil) {
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(12.0, 12.0, 24.0, 24.0)];
        iconView.image = icon;
        iconView.tintColor = [UIColor colorWithRed:0.30 green:0.85 blue:0.70 alpha:1.0];
        [card addSubview:iconView];
    }

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(44.0, 10.0, 160.0, 20.0)];
    titleLabel.text = spec[@"title"];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [card addSubview:titleLabel];

    if ([spec[@"slider"] boolValue]) {
        CGFloat value = [self sliderValueForKey:key];
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10.0, 40.0, 196.0, 24.0)];
        slider.minimumValue = [spec[@"min"] floatValue];
        slider.maximumValue = [spec[@"max"] floatValue];
        slider.value = value;
        slider.tag = [self cardTagForKey:key];
        [slider addTarget:self action:@selector(featureSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [card addSubview:slider];

        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(208.0, 10.0, 70.0, 20.0)];
        valueLabel.tag = 91;
        valueLabel.text = [self formatSliderValue:value spec:spec];
        valueLabel.textColor = [UIColor colorWithRed:0.30 green:0.85 blue:0.70 alpha:1.0];
        valueLabel.font = [UIFont boldSystemFontOfSize:13.0];
        valueLabel.textAlignment = NSTextAlignmentRight;
        [card addSubview:valueLabel];
    } else {
        UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(44.0, 32.0, 172.0, 14.0)];
        descLabel.tag = 90;
        descLabel.text = spec[@"desc"];
        descLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
        descLabel.font = [UIFont systemFontOfSize:10.0];
        [card addSubview:descLabel];

        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectMake(224.0, 18.0, 51.0, 31.0)];
        toggle.on = [self.featureStates[key] boolValue];
        toggle.tag = [self cardTagForKey:key];
        [toggle addTarget:self action:@selector(featureToggleChanged:) forControlEvents:UIControlEventValueChanged];
        [card addSubview:toggle];
    }
}
/*功能卡片 图标+标题+说明+开关或滑块 开关卡背景随激活变亮 照原版featurecard.active */

- (NSInteger)cardTagForKey:(NSString *)key {
    NSArray *order = [self featureOrder];
    NSUInteger index = [order indexOfObject:key];
    if (index == NSNotFound) return 0;
    return 1000 + (NSInteger)index;
}
/*key→tag(1000+序号) */

- (NSString *)keyForCardTag:(NSInteger)tag {
    NSArray *order = [self featureOrder];
    NSInteger index = tag - 1000;
    if (index < 0 || index >= (NSInteger)order.count) return nil;
    return order[index];
}
/*tag→key */

- (CGFloat)sliderValueForKey:(NSString *)key {
    NSNumber *saved = self.featureStates[key];
    if ([saved isKindOfClass:[NSNumber class]]) return saved.floatValue;
    if ([key isEqualToString:@"firstPersonFOV"]) return 75.0;
    if ([key isEqualToString:@"thirdPersonFOV"]) return 75.0;
    if ([key isEqualToString:@"demagnetization"]) return 50.0;
    if ([key isEqualToString:@"globalSpeed"]) return 1.0;
    return 0.0;
}
/*滑块当前值 featurestates存了用存的 否则默认 */

- (NSString *)formatSliderValue:(CGFloat)value spec:(NSDictionary *)spec {
    NSString *unit = spec[@"unit"];
    if ([unit isEqualToString:@"x"]) return [NSString stringWithFormat:@"%.1fx", value];
    if ([unit isEqualToString:@"%"]) return [NSString stringWithFormat:@"%.0f%%", value];
    return [NSString stringWithFormat:@"%.0f°", value];
}
/*滑块值格式化 %.1fx %.0f%% %.0f° 照原版格式 */

- (void)buildWelcomeInWindow:(UIWindow *)window {
    if (self.verificationPassed) return;
    self.welcomePanel = [[UIView alloc] initWithFrame:CGRectMake(40.0, 180.0, 240.0, 260.0)];
    self.welcomePanel.backgroundColor = [UIColor colorWithWhite:0.07 alpha:0.97];
    self.welcomePanel.layer.cornerRadius = 12.0;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 22.0, 200.0, 26.0)];
    title.text = @"欢迎使用 Russ公益";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:17.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.welcomePanel addSubview:title];

    UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 52.0, 208.0, 16.0)];
    subtitle.text = @"请输入卡密以进入 Russ公益";
    subtitle.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:12.0];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [self.welcomePanel addSubview:subtitle];

    self.cardField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 84.0, 200.0, 36.0)];
    self.cardField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    self.cardField.layer.cornerRadius = 8.0;
    self.cardField.textColor = UIColor.whiteColor;
    self.cardField.font = [UIFont systemFontOfSize:14.0];
    self.cardField.placeholder = @"请输入卡密";
    self.cardField.textAlignment = NSTextAlignmentCenter;
    [self.welcomePanel addSubview:self.cardField];

    UIButton *verifyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    verifyButton.frame = CGRectMake(20.0, 132.0, 200.0, 38.0);
    verifyButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.55 blue:0.45 alpha:1.0];
    verifyButton.layer.cornerRadius = 8.0;
    [verifyButton setTitle:@"在线验证" forState:UIControlStateNormal];
    [verifyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    verifyButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [verifyButton addTarget:self action:@selector(beginVerificationFlow) forControlEvents:UIControlEventTouchUpInside];
    [self.welcomePanel addSubview:verifyButton];

    UIButton *enterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    enterButton.frame = CGRectMake(20.0, 178.0, 200.0, 38.0);
    enterButton.backgroundColor = [UIColor colorWithWhite:0.20 alpha:1.0];
    enterButton.layer.cornerRadius = 8.0;
    [enterButton setTitle:@"进入 Russ公益" forState:UIControlStateNormal];
    [enterButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    enterButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [enterButton addTarget:self action:@selector(applyAuthorization) forControlEvents:UIControlEventTouchUpInside];
    [self.welcomePanel addSubview:enterButton];

    self.welcomeHint = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 226.0, 208.0, 16.0)];
    self.welcomeHint.text = @"";
    self.welcomeHint.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    self.welcomeHint.font = [UIFont systemFontOfSize:11.0];
    self.welcomeHint.textAlignment = NSTextAlignmentCenter;
    [self.welcomePanel addSubview:self.welcomeHint];

    [window addSubview:self.welcomePanel];
}
/*欢迎验证页照原版 欢迎使用russ公益/请输入卡密以进入/卡密输入框/在线验证/进入russ公益 */

- (void)beginVerificationFlow {
    self.welcomeHint.text = @"（验证中...）";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.welcomeHint != nil) {
            self.welcomeHint.text = @"（验证通过，点击下方按钮进入）";
        }
    });
}
/*在线验证按钮 本地模拟验证流程(无服务器) */

- (void)applyAuthorization {
    self.verificationPassed = YES;
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"RussPublic.ThomeAuth.SavedCard.v1"];
    [self.welcomePanel removeFromSuperview];
    self.welcomePanel = nil;
    self.cardField = nil;
    self.welcomeHint = nil;
    [self setPanelVisible:YES animated:YES];
}
/*进入russ公益 关闭欢迎页 打开主面板 verificationpassed=true照原版 */
- (void)togglePanel {
    [self setPanelVisible:!self.panelVisible animated:YES];
}
/*点击悬浮按钮开/关主面板 */
- (void)closePanel {
    [self setPanelVisible:NO animated:YES];
}
/*关闭主面板 照原版方法名 */
- (void)setPanelVisible:(BOOL)visible animated:(BOOL)animated {
    self.panelVisible = visible;
    void (^apply)(void) = ^{
        self.mainPanel.hidden = !visible;
        self.mainPanel.alpha = visible ? 1.0 : 0.0;
    };
    if (animated) {
        [UIView animateWithDuration:0.22 animations:apply];
    } else {
        apply();
    }
}
/*面板显隐动画 照原版setpanelvisible:animated */
- (void)show {
    [self setPanelVisible:YES animated:YES];
}
- (void)hide {
    [self setPanelVisible:NO animated:YES];
}
/*show/hide 照原版 */
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
/*手指拖动悬浮按钮 限制中心点不超出安全区域 */
- (void)handlePanelDrag:(UIPanGestureRecognizer *)gesture {
    UIView *view = self.mainPanel;
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
/*拖动面板顶部44pt拖动条 移动整个面板 不与卡片滑动冲突 */

- (void)featureToggleChanged:(UISwitch *)sender {
    NSString *key = [self keyForCardTag:sender.tag];
    if (key == nil) return;
    [self setFeature:key enabled:sender.isOn notify:YES persist:YES];
}
/*统一开关回调 按tag找key 走setfeature分发 照原版featuretogglechanged */

- (void)featureSliderChanged:(UISlider *)sender {
    NSString *key = [self keyForCardTag:sender.tag];
    if (key == nil) return;
    NSDictionary *spec = [self cardSpecifications][key];
    self.featureStates[key] = @(sender.value);
    [self startRuntimeEngine];
    if ([key isEqualToString:@"globalSpeed"]) {
        ApplyTimeScale(sender.value);
    } else if ([key isEqualToString:@"demagnetization"]) {
        ApplyDemagnetization(YES);
    }
    [self updateCardValueLabel:key spec:spec];
    [self saveSettings];
    [self stopRuntimeEngineIfIdle];
}
/*滑块回调 存值启动引擎 fov/相机fov由引擎每帧写 速度消磁即时写 照原版featuresliderchanged */

- (void)updateCardValueLabel:(NSString *)key spec:(NSDictionary *)spec {
    NSInteger tag = [self cardTagForKey:key];
    for (UIView *card in self.panelScroll.subviews) {
        if (card.tag != tag) continue;
        for (UIView *sub in card.subviews) {
            if (sub.tag == 91 && [sub isKindOfClass:[UILabel class]]) {
                UILabel *valueLabel = (UILabel *)sub;
                valueLabel.text = [self formatSliderValue:[self sliderValueForKey:key] spec:spec];
            }
        }
    }
}
/*找到卡片上的值标签刷新文本 */

- (void)setFeature:(NSString *)key enabled:(BOOL)enabled notify:(BOOL)notify persist:(BOOL)persist {
    self.featureStates[key] = @(enabled);
    if (persist) [self saveSettings];
    [self updateCardAppearance:key enabled:enabled];
    [self startRuntimeEngine];
    if (!notify) return;

    if ([key isEqualToString:@"highlight"]) {
        NSUInteger count = enabled ? ApplyHighlight(YES, 2.5f) : ApplyHighlight(NO, 1.0f);
        [self setCardHint:key text:[NSString stringWithFormat:@"%@", enabled ? [NSString stringWithFormat:@"已增强 %lu 盏灯", (unsigned long)count] : @"已恢复默认亮度"]];
    } else if ([key isEqualToString:@"coffin"]) {
        NSUInteger count = ApplyCoffinReveal(enabled);
        if (enabled) {
            [self startCoffinMarkers];
            [self setCardHint:key text:[NSString stringWithFormat:@"已显示 %lu 个棺材", (unsigned long)count]];
        } else {
            [self stopCoffinMarkers];
            [self setCardHint:key text:@"已关闭棺材透视"];
        }
    } else if ([key isEqualToString:@"fog"]) {
        ApplyFogRemoval(enabled);
        [self setCardHint:key text:enabled ? @"雾效已关闭" : @"雾效已恢复"];
    } else if ([key isEqualToString:@"wide"]) {
        NSUInteger count = enabled ? ApplyFieldOfView(120.0) : ApplyFieldOfView([self sliderValueForKey:@"thirdPersonFOV"]);
        [self setCardHint:key text:[NSString stringWithFormat:@"%@", enabled ? [NSString stringWithFormat:@"%lu 个相机已扩展", (unsigned long)count] : @"已恢复默认视角"]];
    } else if ([key isEqualToString:@"islandRoute"]) {
        NSUInteger count = SetAllLineRenderersVisible(enabled, YES);
        [self setCardHint:key text:[NSString stringWithFormat:@"%@", enabled ? [NSString stringWithFormat:@"已显示 %lu 条路线", (unsigned long)count] : @"已隐藏所有路线"]];
    }
    [self stopRuntimeEngineIfIdle];
}
/*功能分发 setfeature后启动持续引擎即时反馈+每帧维持 关时停引擎 */

- (void)setCardHint:(NSString *)key text:(NSString *)text {
    NSInteger tag = [self cardTagForKey:key];
    for (UIView *card in self.panelScroll.subviews) {
        if (card.tag != tag) continue;
        for (UIView *sub in card.subviews) {
            if (sub.tag == 90 && [sub isKindOfClass:[UILabel class]]) {
                UILabel *hint = (UILabel *)sub;
                hint.text = text;
            }
        }
    }
}
/*更新卡片说明行为状态文字 */

- (void)updateCardAppearance:(NSString *)key enabled:(BOOL)enabled {
    NSInteger tag = [self cardTagForKey:key];
    for (UIView *card in self.panelScroll.subviews) {
        if (card.tag == tag) {
            card.backgroundColor = enabled ? [UIColor colorWithWhite:0.20 alpha:0.95] : [UIColor colorWithWhite:0.14 alpha:0.95];
        }
    }
}
/*卡片激活背景变亮 照原版featurecard.setactive */
- (void)startRuntimeEngine {
    if (self.runtimeDisplayLink != nil) return;
    self.runtimeFrameTick = 0;
    self.runtimeDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tickRuntime)];
    [self.runtimeDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
/*开启持续生效引擎 照原版displaylink架构 */
- (BOOL)anyFeatureActive {
    if ([self.featureStates[@"highlight"] boolValue]) return YES;
    if ([self.featureStates[@"coffin"] boolValue]) return YES;
    if ([self.featureStates[@"fog"] boolValue]) return YES;
    if ([self.featureStates[@"wide"] boolValue]) return YES;
    if ([self.featureStates[@"islandRoute"] boolValue]) return YES;
    if ([self.featureStates[@"demagnetization"] boolValue]) return YES;
    if ([self sliderValueForKey:@"globalSpeed"] != 1.0) return YES;
    if ([self sliderValueForKey:@"firstPersonFOV"] != 75.0) return YES;
    if ([self sliderValueForKey:@"thirdPersonFOV"] != 75.0) return YES;
    return NO;
}
/*判断是否有功能需要持续维持 */
- (void)stopRuntimeEngineIfIdle {
    if (self.runtimeDisplayLink != nil && ![self anyFeatureActive]) {
        [self.runtimeDisplayLink invalidate];
        self.runtimeDisplayLink = nil;
    }
}
/*无功能激活时停引擎省电 */
- (void)tickRuntime {
    self.runtimeFrameTick++;
    BOOL heavyTick = (self.runtimeFrameTick % 30 == 0);
    CGFloat firstFOV = [self sliderValueForKey:@"firstPersonFOV"];
    CGFloat thirdFOV = [self sliderValueForKey:@"thirdPersonFOV"];
    BOOL wide = [self.featureStates[@"wide"] boolValue];
    CGFloat effectiveFOV = wide ? 120.0 : thirdFOV;
    CGFloat speed = [self sliderValueForKey:@"globalSpeed"];

    if ([self.featureStates[@"fog"] boolValue]) ApplyFogRemoval(YES);
    if (speed != 1.0) ApplyTimeScale((float)speed);
    ApplyCameraFollow((float)thirdFOV, (float)firstFOV);
    if (wide || effectiveFOV != 75.0) ApplyFieldOfView(effectiveFOV);

    if (heavyTick) {
        if ([self.featureStates[@"highlight"] boolValue]) ApplyHighlight(YES, 2.5f);
        if ([self.featureStates[@"demagnetization"] boolValue]) ApplyDemagnetization(YES);
        if ([self.featureStates[@"coffin"] boolValue]) ApplyCoffinReveal(YES);
        if ([self.featureStates[@"islandRoute"] boolValue]) SetAllLineRenderersVisible(YES, YES);
    }
    if (heavyTick) [self stopRuntimeEngineIfIdle];
}
/*每帧: fog/timescale/camerafollow字段/相机fov 轻量invoke 每30帧(0.5s): 灯/刚体/棺材/路线扫描 热更程序集加载后自动生效 新场景对象自动覆盖 */
- (void)startCoffinMarkers {
    if (self.coffinDisplayLink != nil) return;
    UIWindow *window = self.floatingButton.window;
    if (window == nil) return;
    self.coffinOverlay = [[UIView alloc] initWithFrame:window.bounds];
    self.coffinOverlay.backgroundColor = [UIColor clearColor];
    self.coffinOverlay.userInteractionEnabled = NO;
    self.coffinMarkers = [NSMutableArray arrayWithCapacity:8];
    for (NSInteger i = 0; i < 8; i++) {
        UIView *marker = [self buildCoffinMarker];
        [self.coffinMarkers addObject:marker];
        [self.coffinOverlay addSubview:marker];
    }
    [window addSubview:self.coffinOverlay];
    self.coffinDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCoffinMarkers)];
    [self.coffinDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
/*棺材透视开启 全屏透明overlay+8标记池 cadisplaylink每帧 照原版islandroute的displaylink架构 */

- (void)stopCoffinMarkers {
    [self.coffinDisplayLink invalidate];
    self.coffinDisplayLink = nil;
    [self.coffinOverlay removeFromSuperview];
    self.coffinOverlay = nil;
    self.coffinMarkers = nil;
}
/*棺材透视关闭 停帧移除overlay */

- (UIView *)buildCoffinMarker {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(-100.0, -100.0, 64.0, 38.0)];
    container.userInteractionEnabled = NO;
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(21.0, 0.0, 22.0, 22.0)];
    box.backgroundColor = [UIColor colorWithRed:0.95 green:0.55 blue:0.10 alpha:0.85];
    box.layer.cornerRadius = 4.0;
    box.layer.borderColor = [UIColor whiteColor].CGColor;
    box.layer.borderWidth = 1.5;
    [container addSubview:box];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 26.0, 64.0, 12.0)];
    label.tag = 101;
    label.font = [UIFont systemFontOfSize:10.0];
    label.textColor = UIColor.whiteColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    label.text = @"棺材";
    [container addSubview:label];
    container.hidden = YES;
    return container;
}
/*单个棺材标记 橙色方框白边+文字 */

- (void)updateCoffinMarkers {
    if (self.coffinOverlay == nil || self.coffinMarkers == nil) return;
    static NSUInteger frameTick = 0;
    static Il2CppArray *cachedCoffins = NULL;
    frameTick++;
    if (frameTick % 30 == 1) {
        cachedCoffins = ScanObjectsOfTypeInNamespace("Qqpd.Modules.Scene", "UGCObjectCoffin", YES);
    }
    Il2CppObject *camera = GetMainCameraObject();
    if (camera == NULL) return;
    Il2CppArray *coffins = cachedCoffins;
    float camX = 0.0f, camY = 0.0f, camZ = 0.0f;
    GetObjectWorldPosition(camera, &camX, &camY, &camZ);
    CGFloat screenW = self.coffinOverlay.bounds.size.width;
    CGFloat screenH = self.coffinOverlay.bounds.size.height;
    NSUInteger shown = 0;
    for (NSUInteger i = 0; i < self.coffinMarkers.count; i++) {
        UIView *marker = self.coffinMarkers[i];
        marker.hidden = YES;
        if (coffins == NULL || i >= coffins->maxLength) continue;
        Il2CppObject *coffin = coffins->objects[i];
        if (coffin == NULL) continue;
        float wx = 0.0f, wy = 0.0f, wz = 0.0f;
        if (!GetObjectWorldPosition(coffin, &wx, &wy, &wz)) continue;
        float sx = 0.0f, sy = 0.0f, sz = -1.0f;
        if (!ProjectWorldToScreen(camera, wx, wy, wz, &sx, &sy, &sz)) continue;
        if (sz <= 0.0f || sx < 0.0f || sx > screenW) continue;
        float dx = wx - camX, dy = wy - camY, dz = wz - camZ;
        float dist = sqrtf(dx * dx + dy * dy + dz * dz);
        marker.frame = CGRectMake((CGFloat)sx - 32.0, screenH - (CGFloat)sy - 19.0, 64.0, 38.0);
        UILabel *label = (UILabel *)[marker viewWithTag:101];
        if (label != nil) label.text = [NSString stringWithFormat:@"%.0f米", dist];
        marker.hidden = NO;
        shown++;
    }
}
/*每帧 扫描ugcobjectcoffin 取前8个 worldtoscreen投影 橙框+距离文字 镜头后或出屏隐藏 */

- (void)restoreFeatureRuntime {
    if ([self anyFeatureActive]) {
        [self startRuntimeEngine];
    }
    if ([self.featureStates[@"coffin"] boolValue]) {
        [self startCoffinMarkers];
    }
    ApplyCameraFollow([self sliderValueForKey:@"thirdPersonFOV"], [self sliderValueForKey:@"firstPersonFOV"]);
    ApplyTimeScale([self sliderValueForKey:@"globalSpeed"]);
}
/*启动恢复 有功能开着→引擎接管持续生效(热更程序集加载后自动补上) 照原版restorefeatureruntime */

- (void)loadSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSDictionary *saved = [defaults dictionaryForKey:@"RussPublic.Menu.Configuration.v1"];
    if (saved != nil && [saved isKindOfClass:[NSDictionary class]]) {
        self.featureStates = [NSMutableDictionary dictionaryWithDictionary:saved];
    } else {
        self.featureStates = [NSMutableDictionary dictionary];
    }
    self.firstPersonFOV = [self sliderValueForKey:@"firstPersonFOV"];
    self.thirdPersonFOV = [self sliderValueForKey:@"thirdPersonFOV"];
    self.demagnetizationStrength = [self sliderValueForKey:@"demagnetization"];
    self.globalSpeedMultiplier = [self sliderValueForKey:@"globalSpeed"];
    self.verificationPassed = [defaults boolForKey:@"RussPublic.ThomeAuth.SavedCard.v1"];
}
/*读配置 key照原版russpublic.menu.configuration.v1 字典结构 featurestates一次存全部 */

- (void)saveSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:self.featureStates forKey:@"RussPublic.Menu.Configuration.v1"];
}
/*存配置 整个featurestates字典一次写入 照原版 */
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