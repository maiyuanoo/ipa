#import <Foundation/Foundation.h>/*OC对象 nsuserdefault 通知*/
#import <UIKit/UIKit.h>/* uiview uibutton uislider ui界面*/
#import <QuartzCore/CADisplayLink.h>/*cadisplaylink每帧回调*/
#import <dlfcn.h>/*动态找il2cpp原生c函数地址 */
#import <mach-o/dyld.h>/*枚举已加载镜像找unityframework完整路径*/
#import <mach/mach.h>
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
typedef struct UnityColor {
    float r;
    float g;
    float b;
    float a;
} UnityColor;
/*UnityEngine.Color 为四个连续 float；原版通过 Graphic.get_color/set_color 读写完整16字节*/
/* il2cpp基础前向声明 数组结构体(头16字节klass+monitor bounds 8 max_length 8 数据从32开始)*/

typedef Il2CppDomain *(*Il2CppDomainGet)(void);
typedef Il2CppAssembly **(*Il2CppDomainGetAssemblies)(const Il2CppDomain *domain, size_t *size);
typedef const Il2CppImage *(*Il2CppAssemblyGetImage)(const Il2CppAssembly *assembly);
typedef void *(*Il2CppClassFromName)(const Il2CppImage *image, const char *namespaze, const char *name);
typedef const MethodInfo *(*Il2CppClassGetMethodFromName)(void *klass, const char *name, int argumentsCount);
typedef void *(*Il2CppClassGetFieldFromName)(void *klass, const char *name);
typedef size_t (*Il2CppFieldGetOffset)(void *field);
typedef void (*Il2CppFieldGetValue)(void *object, void *field, void *value);
typedef void (*Il2CppFieldSetValue)(void *object, void *field, void *value);
typedef Il2CppObject *(*Il2CppRuntimeInvoke)(const MethodInfo *method, void *object, void **parameters, Il2CppObject **exception);
typedef void *(*Il2CppThreadAttach)(Il2CppDomain *domain);
typedef void *(*Il2CppObjectUnbox)(Il2CppObject *object);
typedef const char *(*Il2CppImageGetName)(const Il2CppImage *image);
typedef const void *(*Il2CppClassGetType)(void *klass);
typedef Il2CppObject *(*Il2CppTypeGetObject)(const void *type);
typedef void (*Il2CppFieldStaticGetValue)(void *field, void *value);
typedef void *(*Il2CppClassGetParent)(void *klass);
typedef uint32_t (*Il2CppGCHandleNew)(Il2CppObject *object, BOOL pinned);
typedef Il2CppObject *(*Il2CppGCHandleGetTarget)(uint32_t handle);
typedef void (*Il2CppGCHandleFree)(uint32_t handle);
/*il2cpp api函数指针类型 原版dylib同款全套(import表已验证)*/

static Il2CppDomainGet gIl2CppDomainGet;
static Il2CppDomainGetAssemblies gIl2CppDomainGetAssemblies;
static Il2CppAssemblyGetImage gIl2CppAssemblyGetImage;
static Il2CppClassFromName gIl2CppClassFromName;
static Il2CppClassGetMethodFromName gIl2CppClassGetMethodFromName;
static Il2CppClassGetFieldFromName gIl2CppClassGetFieldFromName;
static Il2CppFieldGetOffset gIl2CppFieldGetOffset;
static Il2CppFieldGetValue gIl2CppFieldGetValue;
static Il2CppFieldSetValue gIl2CppFieldSetValue;
static Il2CppRuntimeInvoke gIl2CppRuntimeInvoke;
static Il2CppThreadAttach gIl2CppThreadAttach;
static Il2CppObjectUnbox gIl2CppObjectUnbox;
static Il2CppImageGetName gIl2CppImageGetName;
static const void *(*gIl2CppClassGetType)(void *klass);
static Il2CppObject *(*gIl2CppTypeGetObject)(const void *type);
static void (*gIl2CppFieldStaticGetValue)(void *field, void *value);
static void *(*gIl2CppClassGetParent)(void *klass);
static Il2CppGCHandleNew gIl2CppGCHandleNew;
static Il2CppGCHandleGetTarget gIl2CppGCHandleGetTarget;
static Il2CppGCHandleFree gIl2CppGCHandleFree;

static void *gUnityFrameworkHandle;
static uintptr_t gUnityFrameworkBase;
static BOOL gIl2CppSymbolsResolved;
static BOOL gIl2CppThreadReady;
/*unityframework句柄 符号解析完成标记 主线程attach标记*/

static BOOL ResolveIl2CppSymbols(void) {
    if (gIl2CppSymbolsResolved) return YES;

    /* 关键修复:照原版dylib(0x1bb10)枚举dyld已加载镜像,
       拿UnityFramework的完整绝对路径再dlopen。
       相对路径dlopen在iOS上必失败(按CWD=/解析),
       RTLD_DEFAULT在两级命名空间下也找不到UnityFramework符号,
       这是之前所有功能全部无效的根因。 */
    if (gUnityFrameworkHandle == NULL) {
        uint32_t imageCount = _dyld_image_count();
        for (uint32_t i = 0; i < imageCount; i++) {
            const char *name = _dyld_get_image_name(i);
            if (name == NULL) continue;
            if (strstr(name, "UnityFramework.framework/UnityFramework") == NULL) continue;
            gUnityFrameworkHandle = dlopen(name, RTLD_LAZY | RTLD_GLOBAL);
            break;
        }
    }
    if (gUnityFrameworkHandle == NULL) {
        gUnityFrameworkHandle = dlopen("@rpath/UnityFramework.framework/UnityFramework", RTLD_LAZY | RTLD_GLOBAL);
    }
    if (gUnityFrameworkHandle == NULL) {
        gUnityFrameworkHandle = dlopen("UnityFramework.framework/UnityFramework", RTLD_LAZY | RTLD_GLOBAL);
    }
    if (gUnityFrameworkBase == 0) {
        uint32_t imageCount = _dyld_image_count();
        for (uint32_t i = 0; i < imageCount; i++) {
            const char *name = _dyld_get_image_name(i);
            if (name == NULL || strstr(name, "UnityFramework.framework/UnityFramework") == NULL) continue;
            gUnityFrameworkBase = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }

    void *base = gUnityFrameworkHandle != NULL ? gUnityFrameworkHandle : RTLD_DEFAULT;
    gIl2CppDomainGet = (Il2CppDomainGet)dlsym(base, "il2cpp_domain_get");
    gIl2CppDomainGetAssemblies = (Il2CppDomainGetAssemblies)dlsym(base, "il2cpp_domain_get_assemblies");
    gIl2CppAssemblyGetImage = (Il2CppAssemblyGetImage)dlsym(base, "il2cpp_assembly_get_image");
    gIl2CppClassFromName = (Il2CppClassFromName)dlsym(base, "il2cpp_class_from_name");
    gIl2CppClassGetMethodFromName = (Il2CppClassGetMethodFromName)dlsym(base, "il2cpp_class_get_method_from_name");
    gIl2CppClassGetFieldFromName = (Il2CppClassGetFieldFromName)dlsym(base, "il2cpp_class_get_field_from_name");
    gIl2CppFieldGetOffset = (Il2CppFieldGetOffset)dlsym(base, "il2cpp_field_get_offset");
    gIl2CppFieldGetValue = (Il2CppFieldGetValue)dlsym(base, "il2cpp_field_get_value");
    gIl2CppFieldSetValue = (Il2CppFieldSetValue)dlsym(base, "il2cpp_field_set_value");
    gIl2CppRuntimeInvoke = (Il2CppRuntimeInvoke)dlsym(base, "il2cpp_runtime_invoke");
    gIl2CppThreadAttach = (Il2CppThreadAttach)dlsym(base, "il2cpp_thread_attach");
    gIl2CppObjectUnbox = (Il2CppObjectUnbox)dlsym(base, "il2cpp_object_unbox");
    gIl2CppImageGetName = (Il2CppImageGetName)dlsym(base, "il2cpp_image_get_name");
    gIl2CppClassGetType = (const void *(*)(void *))dlsym(base, "il2cpp_class_get_type");
    gIl2CppTypeGetObject = (Il2CppObject *(*)(const void *))dlsym(base, "il2cpp_type_get_object");
    gIl2CppFieldStaticGetValue = (void (*)(void *, void *))dlsym(base, "il2cpp_field_static_get_value");
    gIl2CppClassGetParent = (void *(*)(void *))dlsym(base, "il2cpp_class_get_parent");
    gIl2CppGCHandleNew = (Il2CppGCHandleNew)dlsym(base, "il2cpp_gchandle_new");
    gIl2CppGCHandleGetTarget = (Il2CppGCHandleGetTarget)dlsym(base, "il2cpp_gchandle_get_target");
    gIl2CppGCHandleFree = (Il2CppGCHandleFree)dlsym(base, "il2cpp_gchandle_free");

    if (gIl2CppDomainGet == NULL || gIl2CppDomainGetAssemblies == NULL ||
        gIl2CppAssemblyGetImage == NULL || gIl2CppClassFromName == NULL ||
        gIl2CppClassGetMethodFromName == NULL || gIl2CppRuntimeInvoke == NULL ||
        gIl2CppFieldGetOffset == NULL) {
        return NO;
    }
    gIl2CppSymbolsResolved = YES;
    return YES;
}
/*一次性解析全部il2cpp符号(主+二级+gchandle) 必需项缺失则下次重试*/

static BOOL EnsureIl2CppThread(void) {
    if (!ResolveIl2CppSymbols()) return NO;
    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) return NO;/*unity尚未初始化完成 引擎tick会持续重试*/
    if (!gIl2CppThreadReady && gIl2CppThreadAttach != NULL) {
        if (gIl2CppThreadAttach(domain) != NULL) gIl2CppThreadReady = YES;
    }
    return YES;
}
/*所有invoke前统一走这里:符号+域+线程attach三重保障 主线程unity已attach重复调用无害*/

static Il2CppObject *GetTypeObjectForClass(void *klass) {
    if (klass == NULL) return NULL;
    if (gIl2CppClassGetType == NULL || gIl2CppTypeGetObject == NULL) return NULL;
    const void *type = gIl2CppClassGetType(klass);
    if (type == NULL) return NULL;
    return gIl2CppTypeGetObject(type);
}
/*class→system.type对象 已验证class_get_type/type_get_object均导出*/

static void *FindClassInAllAssemblies(const char *namespaceName, const char *className) {
    if (!EnsureIl2CppThread()) return NULL;
    Il2CppDomain *domain = gIl2CppDomainGet();
    size_t count = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &count);
    if (assemblies == NULL || count == 0 || count > 4096) return NULL;
    for (size_t i = 0; i < count; i++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[i]);
        if (image == NULL) continue;
        void *klass = gIl2CppClassFromName(image, namespaceName, className);
        if (klass != NULL) return klass;
    }
    return NULL;
}
/*跨全部程序集找类(照原版0x178a0循环):热更类camerafollow/ugcobjectcoffin命名空间为"" 引擎类为"UnityEngine" dll已验证*/

#define kRussTypeCacheMax 12
static void *gTypeCacheKlass[kRussTypeCacheMax];
static uint32_t gTypeCacheHandle[kRussTypeCacheMax];
/*类型对象缓存:用gchandle钉住type对象防GC回收 照原版gchandle用法*/

static Il2CppObject *GetTypeObjectForClassCached(void *klass) {
    if (klass == NULL) return NULL;
    for (int i = 0; i < kRussTypeCacheMax; i++) {
        if (gTypeCacheKlass[i] == NULL) break;
        if (gTypeCacheKlass[i] != klass) continue;
        if (gTypeCacheHandle[i] != 0 && gIl2CppGCHandleGetTarget != NULL) {
            return gIl2CppGCHandleGetTarget(gTypeCacheHandle[i]);
        }
        return NULL;
    }
    Il2CppObject *typeObject = GetTypeObjectForClass(klass);
    if (typeObject == NULL) return NULL;
    for (int i = 0; i < kRussTypeCacheMax; i++) {
        if (gTypeCacheKlass[i] != NULL) continue;
        gTypeCacheKlass[i] = klass;
        if (gIl2CppGCHandleNew != NULL) {
            gTypeCacheHandle[i] = gIl2CppGCHandleNew(typeObject, NO);
        }
        break;
    }
    return typeObject;
}
/*带缓存的type对象获取 扫描功能每0.5s调用避免重复构造*/

static void *gCameraFollowKlass;
static void *gCameraFollowFieldKlass;
static void *gUGC2FOVField;
static void *gUGC2FirstFOVField;
static BOOL gThirdPersonFovSaved;
static BOOL gFirstPersonFovSaved;
static float gOriginalThirdPersonFov;
static float gOriginalFirstPersonFov;
/*camerafollow类/字段句柄缓存(fieldinfo属于静态元数据不会被GC 照原版field_get_offset后直写等价)*/

static BOOL ValidateInstanceOfClass(Il2CppObject *instance, void *klass) {
    if (instance == NULL || klass == NULL) return NO;
    void *objKlass = *(void **)instance;/*il2cpp对象头第一个字段=class指针 原版0x17cac同款校验*/
    if (objKlass == klass) return YES;
    if (gIl2CppClassGetParent != NULL) {
        for (int i = 0; i < 8 && objKlass != NULL; i++) {
            objKlass = gIl2CppClassGetParent(objKlass);
            if (objKlass == klass) return YES;
        }
    }
    return NO;
}
/*实例类校验:对象头class指针匹配或父类链匹配 防野指针/错拿*/

static Il2CppObject *GetCameraFollowInstance(void) {
    if (!EnsureIl2CppThread()) return NULL;
    if (gCameraFollowKlass == NULL) {
        gCameraFollowKlass = FindClassInAllAssemblies("", "CameraFollow");
        if (gCameraFollowKlass == NULL) return NULL;
    }

    /* 1) 原版首选(0x192d4):单例静态字段 <BAMKDIBPDKB>k__BackingField
       热更dll里没有这个名字时class_get_field_from_name返回null自然跳过 */
    if (gIl2CppFieldStaticGetValue != NULL && gIl2CppClassGetFieldFromName != NULL) {
        static const char *kInstanceFields[] = {
            "<BAMKDIBPDKB>k__BackingField", "instance", "Instance",
            "_instance", "mInstance", "m_instance"
        };
        for (size_t i = 0; i < 6; i++) {
            void *field = gIl2CppClassGetFieldFromName(gCameraFollowKlass, kInstanceFields[i]);
            if (field == NULL) continue;
            Il2CppObject *instance = NULL;
            gIl2CppFieldStaticGetValue(field, &instance);
            if (ValidateInstanceOfClass(instance, gCameraFollowKlass)) return instance;
        }
    }

    /* 2) 原版次选(0x19454):get_instance属性 getter返回即权威结果 */
    const MethodInfo *getInstance = gIl2CppClassGetMethodFromName(gCameraFollowKlass, "get_instance", 0);
    if (getInstance != NULL) {
        Il2CppObject *exception = NULL;
        Il2CppObject *instance = gIl2CppRuntimeInvoke(getInstance, NULL, NULL, &exception);
        if (exception == NULL && instance != NULL) return instance;
    }
    return NULL;
}
/*camerafollow单例获取:静态字段→get_instance 双路径照原版顺序 每次现取不缓存实例防GC后野指针*/

static BOOL ReadCameraFollowFloat(Il2CppObject *instance, void *field, float *value) {
    if (instance == NULL || field == NULL || value == NULL || gIl2CppFieldGetValue == NULL) return NO;
    gIl2CppFieldGetValue(instance, field, value);
    return isfinite(*value);
}

static BOOL WriteCameraFollowFloat(Il2CppObject *instance, void *field, float value) {
    if (instance == NULL || field == NULL || !isfinite(value)) return NO;
    if (gIl2CppFieldSetValue != NULL) {
        gIl2CppFieldSetValue(instance, field, &value);
        return YES;
    }
    if (gIl2CppFieldGetOffset == NULL) return NO;
    size_t offset = gIl2CppFieldGetOffset(field);
    /* Il2CppObject 头固定为 klass 与 monitor 两个指针，共 16 字节。 */
    if (offset < 0x10) return NO;
    *(float *)((uint8_t *)instance + offset) = value;
    return YES;
}

static BOOL ApplyCameraFollow(float thirdPersonFov, BOOL thirdPersonEnabled,
                              float firstPersonFov, BOOL firstPersonEnabled) {
    if (!EnsureIl2CppThread()) return NO;
    Il2CppObject *instance = GetCameraFollowInstance();
    if (instance == NULL) return NO;
    void *objKlass = *(void **)instance;
    if (objKlass == NULL) return NO;

    /* 字段句柄随实例类缓存 热更换代(类指针变化)自动重解析 */
    if (objKlass != gCameraFollowFieldKlass || (gUGC2FOVField == NULL && gUGC2FirstFOVField == NULL)) {
        gCameraFollowFieldKlass = objKlass;
        gUGC2FOVField = gIl2CppClassGetFieldFromName(objKlass, "UGC2FOV");
        gUGC2FirstFOVField = gIl2CppClassGetFieldFromName(objKlass, "UGC2FirstFOV");
        gThirdPersonFovSaved = NO;
        gFirstPersonFovSaved = NO;
    }
    if (gUGC2FOVField == NULL && gUGC2FirstFOVField == NULL) return NO;

    BOOL changed = NO;
    if (gUGC2FOVField != NULL) {
        if (thirdPersonEnabled) {
            if (!gThirdPersonFovSaved && ReadCameraFollowFloat(instance, gUGC2FOVField, &gOriginalThirdPersonFov)) {
                gThirdPersonFovSaved = YES;
            }
            if (gThirdPersonFovSaved) {
                changed |= WriteCameraFollowFloat(instance, gUGC2FOVField, (float)MAX(30.0, MIN(170.0, thirdPersonFov)));
            }
        } else if (gThirdPersonFovSaved) {
            changed |= WriteCameraFollowFloat(instance, gUGC2FOVField, gOriginalThirdPersonFov);
            gThirdPersonFovSaved = NO;
        }
    }
    if (gUGC2FirstFOVField != NULL) {
        if (firstPersonEnabled) {
            if (!gFirstPersonFovSaved && ReadCameraFollowFloat(instance, gUGC2FirstFOVField, &gOriginalFirstPersonFov)) {
                gFirstPersonFovSaved = YES;
            }
            if (gFirstPersonFovSaved) {
                changed |= WriteCameraFollowFloat(instance, gUGC2FirstFOVField, (float)MAX(30.0, MIN(170.0, firstPersonFov)));
            }
        } else if (gFirstPersonFovSaved) {
            changed |= WriteCameraFollowFloat(instance, gUGC2FirstFOVField, gOriginalFirstPersonFov);
            gFirstPersonFovSaved = NO;
        }
    }
    return changed;
}
/*原版分别保存并恢复 UGC2FOV/UGC2FirstFOV；仅对启用字段持续写入，范围 [30,170]。*/

static void *gCameraKlass;
static const MethodInfo *gGetAllCamerasMethod;
static const MethodInfo *gSetFieldOfViewMethod;
static const MethodInfo *gGetOrthographicMethod;
static const MethodInfo *gGetTargetTextureMethod;
static const MethodInfo *gGetMainMethod;
static const MethodInfo *gWorldToScreenMethod;
/*camera类及方法缓存(引擎类静态元数据永生 可安全缓存)*/

static BOOL EnsureCameraApi(void) {
    if (gCameraKlass != NULL && gGetAllCamerasMethod != NULL && gSetFieldOfViewMethod != NULL) return YES;
    if (!EnsureIl2CppThread()) return NO;
    if (gCameraKlass == NULL) {
        gCameraKlass = FindClassInAllAssemblies("UnityEngine", "Camera");
        if (gCameraKlass == NULL) return NO;
    }
    if (gGetAllCamerasMethod == NULL) gGetAllCamerasMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "get_allCameras", 0);
    if (gSetFieldOfViewMethod == NULL) gSetFieldOfViewMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "set_fieldOfView", 1);
    if (gGetOrthographicMethod == NULL) gGetOrthographicMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "get_orthographic", 0);
    if (gGetTargetTextureMethod == NULL) gGetTargetTextureMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "get_targetTexture", 0);
    if (gGetMainMethod == NULL) gGetMainMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "get_main", 0);
    if (gWorldToScreenMethod == NULL) gWorldToScreenMethod = gIl2CppClassGetMethodFromName(gCameraKlass, "WorldToScreenPoint", 1);
    return gGetAllCamerasMethod != NULL && gSetFieldOfViewMethod != NULL;
}
/*camera api一次性解析 每帧fov写不再重复查找*/

static NSUInteger ApplyFieldOfView(CGFloat fieldOfView) {
    if (!EnsureCameraApi()) return 0;

    Il2CppObject *exception = NULL;
    Il2CppArray *cameras = (Il2CppArray *)gIl2CppRuntimeInvoke(gGetAllCamerasMethod, NULL, NULL, &exception);
    if (exception != NULL || cameras == NULL) return 0;

    float value = (float)MAX(30.0, MIN(170.0, fieldOfView));
    void *arguments[] = { &value };
    NSUInteger touched = 0;
    for (uintptr_t index = 0; index < cameras->maxLength; index++) {
        Il2CppObject *camera = cameras->objects[index];
        if (camera == NULL) continue;
        if (gGetOrthographicMethod != NULL && gIl2CppObjectUnbox != NULL) {
            exception = NULL;
            Il2CppObject *orthoObj = gIl2CppRuntimeInvoke(gGetOrthographicMethod, camera, NULL, &exception);
            if (exception == NULL && orthoObj != NULL) {
                BOOL isOrtho = *((BOOL *)gIl2CppObjectUnbox(orthoObj));
                if (isOrtho) continue;
            }
        }
        if (gGetTargetTextureMethod != NULL) {
            exception = NULL;
            Il2CppObject *rtObj = gIl2CppRuntimeInvoke(gGetTargetTextureMethod, camera, NULL, &exception);
            if (exception == NULL && rtObj != NULL) continue;
        }
        exception = NULL;
        gIl2CppRuntimeInvoke(gSetFieldOfViewMethod, camera, arguments, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*camera.get_allcameras遍历 跳过正交和渲染纹理相机 set_fieldofview clamp[30,170]照原版*/

static void *gObjectKlass;
static void *gResourcesKlass;
static const MethodInfo *gFindObjectsOfTypeMethod;
static const MethodInfo *gFindObjectsOfTypeAllMethod;
/*object/resources类+扫描方法缓存*/

static BOOL EnsureScanApi(void) {
    if (gObjectKlass != NULL && gResourcesKlass != NULL &&
        gFindObjectsOfTypeMethod != NULL && gFindObjectsOfTypeAllMethod != NULL) return YES;
    if (!EnsureIl2CppThread()) return NO;
    if (gObjectKlass == NULL) gObjectKlass = FindClassInAllAssemblies("UnityEngine", "Object");
    if (gResourcesKlass == NULL) gResourcesKlass = FindClassInAllAssemblies("UnityEngine", "Resources");
    if (gObjectKlass == NULL || gResourcesKlass == NULL) return NO;
    if (gFindObjectsOfTypeMethod == NULL) {
        gFindObjectsOfTypeMethod = gIl2CppClassGetMethodFromName(gObjectKlass, "FindObjectsOfType", 1);
    }
    if (gFindObjectsOfTypeAllMethod == NULL) {
        gFindObjectsOfTypeAllMethod = gIl2CppClassGetMethodFromName(gResourcesKlass, "FindObjectsOfTypeAll", 1);
    }
    return gFindObjectsOfTypeMethod != NULL && gFindObjectsOfTypeAllMethod != NULL;
}
/*扫描api缓存:object.findobjectsoftype(可见)+resources.findobjectsoftypeall(含隐藏) 照原版0x1a5b0*/

static Il2CppArray *ScanObjectsOfClass(void *targetKlass, BOOL includeInactive) {
    if (targetKlass == NULL || !EnsureScanApi()) return NULL;
    Il2CppObject *typeObject = GetTypeObjectForClassCached(targetKlass);
    if (typeObject == NULL) return NULL;
    const MethodInfo *findMethod = includeInactive ? gFindObjectsOfTypeAllMethod : gFindObjectsOfTypeMethod;
    Il2CppObject *exception = NULL;
    void *arguments[] = { typeObject };/*引用类型参数直接传对象指针(不能取地址!)*/
    return (Il2CppArray *)gIl2CppRuntimeInvoke(findMethod, NULL, arguments, &exception);
}
/*统一扫描:findobjectsoftypeall含隐藏对象开关 type对象gchandle缓存*/

static Il2CppArray *ScanObjectsOfTypeInNamespace(const char *namespaceName, const char *className, BOOL includeInactive) {
    if (!EnsureIl2CppThread()) return NULL;
    void *targetKlass = FindClassInAllAssemblies(namespaceName, className);
    if (targetKlass == NULL) return NULL;
    return ScanObjectsOfClass(targetKlass, includeInactive);
}
/*任意命名空间类型扫描 棺材(qqpd.modules.scene)等热更类用*/

static void *gTimeKlass;
static const MethodInfo *gGetTimeScaleMethod;
static const MethodInfo *gSetTimeScaleMethod;
static BOOL gTimeScaleSaved;
static float gOriginalTimeScale = 1.0f;
/*time类缓存+原始timescale保存(照原版0x17e5c先get缓存原值再set 关时还原)*/

static void ApplyTimeScale(float multiplier) {
    if (!EnsureIl2CppThread()) return;
    if (gTimeKlass == NULL) {
        gTimeKlass = FindClassInAllAssemblies("UnityEngine", "Time");
        if (gTimeKlass == NULL) return;
    }
    if (gGetTimeScaleMethod == NULL) gGetTimeScaleMethod = gIl2CppClassGetMethodFromName(gTimeKlass, "get_timeScale", 0);
    if (gSetTimeScaleMethod == NULL) gSetTimeScaleMethod = gIl2CppClassGetMethodFromName(gTimeKlass, "set_timeScale", 1);
    if (gSetTimeScaleMethod == NULL) return;

    /* Russ _YYGameMemorySetGlobalSpeed 将有效倍率收敛到 [1, 10]。 */
    float value = (float)MAX(1.0, MIN(10.0, multiplier));
    Il2CppObject *exception = NULL;
    if (value == 1.0f) {
        if (gTimeScaleSaved) {
            void *restoreArgs[] = { &gOriginalTimeScale };
            gIl2CppRuntimeInvoke(gSetTimeScaleMethod, NULL, restoreArgs, &exception);
            gTimeScaleSaved = NO;
        }
        return;
    }
    if (!gTimeScaleSaved && gGetTimeScaleMethod != NULL && gIl2CppObjectUnbox != NULL) {
        exception = NULL;
        Il2CppObject *current = gIl2CppRuntimeInvoke(gGetTimeScaleMethod, NULL, NULL, &exception);
        if (exception == NULL && current != NULL) {
            gOriginalTimeScale = *((float *)gIl2CppObjectUnbox(current));
            gTimeScaleSaved = YES;
        }
    }
    void *arguments[] = { &value };
    exception = NULL;
    gIl2CppRuntimeInvoke(gSetTimeScaleMethod, NULL, arguments, &exception);
}
/*time.set_timescale 首次修改前保存原值 倍率回1.0时还原原值 照原版逻辑*/

static void *gRenderSettingsKlass;
static const MethodInfo *gSetFogMethod;
static const MethodInfo *gSetFogDensityMethod;
static const MethodInfo *gGetFogMethod;
static const MethodInfo *gGetFogDensityMethod;
static BOOL gFogSaved;
static BOOL gOriginalFog;
static float gOriginalFogDensity = 0.01f;
static uintptr_t gFogStateAddresses[2];
static uint32_t gFogStateOriginalValues[2];
static BOOL gNativeFogStateSaved;
typedef kern_return_t (*MachVmReadOverwrite)(mach_port_t task, mach_vm_address_t address,
                                             mach_vm_size_t size, mach_vm_address_t data,
                                             mach_vm_size_t *outSize);
typedef kern_return_t (*VmWrite)(vm_map_t task, vm_address_t address,
                                 vm_offset_t data, mach_msg_type_number_t dataCount);
static MachVmReadOverwrite gMachVmReadOverwrite;
static VmWrite gVmWrite;
/*RenderSettings 后备路径和 Russ 原版 Unity 内存状态缓存*/

static BOOL ReadProcessMemory(uintptr_t address, void *output, size_t length) {
    if (address < 0x10000 || output == NULL || length == 0) return NO;
    if (gMachVmReadOverwrite == NULL) {
        gMachVmReadOverwrite = (MachVmReadOverwrite)dlsym(RTLD_DEFAULT, "mach_vm_read_overwrite");
    }
    if (gMachVmReadOverwrite == NULL) return NO;
    mach_vm_size_t copied = 0;
    kern_return_t result = gMachVmReadOverwrite(mach_task_self(), (mach_vm_address_t)address,
                                                (mach_vm_size_t)length, (mach_vm_address_t)output, &copied);
    return result == KERN_SUCCESS && copied == length;
}

static BOOL WriteProcessMemory(uintptr_t address, const void *input, size_t length) {
    if (address < 0x10000 || input == NULL || length == 0) return NO;
    if (gVmWrite == NULL) gVmWrite = (VmWrite)dlsym(RTLD_DEFAULT, "vm_write");
    if (gVmWrite == NULL) return NO;
    return gVmWrite(mach_task_self(), (vm_address_t)address,
                    (vm_offset_t)input, (mach_msg_type_number_t)length) == KERN_SUCCESS;
}

static BOOL ResolveUnityPointerChain(const uintptr_t *offsets, size_t count, uintptr_t *result) {
    if (gUnityFrameworkBase == 0 || offsets == NULL || count == 0 || result == NULL) return NO;
    uintptr_t address = gUnityFrameworkBase + offsets[0];
    for (size_t index = 1; index < count; index++) {
        uintptr_t pointer = 0;
        if (!ReadProcessMemory(address, &pointer, sizeof(pointer)) || pointer < 0x10000) return NO;
        address = pointer + offsets[index];
    }
    *result = address;
    return YES;
}

static BOOL ApplyRussNativeFogRemoval(BOOL remove) {
    static const uintptr_t kFogChains[2][8] = {
        { 0x66138f8, 0x1a0, 0xb8, 0x160, 0x150, 0x18, 0x30, 0x35c },
        { 0x660ba38, 0x30, 0x8, 0x678, 0x2c4, 0, 0, 0 }
    };
    static const size_t kFogChainLengths[2] = { 8, 5 };

    for (size_t index = 0; index < 2; index++) {
        uintptr_t address = 0;
        if (!ResolveUnityPointerChain(kFogChains[index], kFogChainLengths[index], &address)) return NO;
        if (!gNativeFogStateSaved || gFogStateAddresses[index] != address) {
            uint32_t original = 0;
            if (!ReadProcessMemory(address, &original, sizeof(original))) return NO;
            gFogStateAddresses[index] = address;
            gFogStateOriginalValues[index] = original;
        }
    }
    gNativeFogStateSaved = YES;

    for (size_t index = 0; index < 2; index++) {
        uint32_t value = remove ? 0 : gFogStateOriginalValues[index];
        if (!WriteProcessMemory(gFogStateAddresses[index], &value, sizeof(value))) return NO;
    }
    return YES;
}
/*原版 FUN_00019afc：两条 UnityFramework 指针链各写4字节，关闭时恢复首次读取值*/

static BOOL ApplyFogRemoval(BOOL remove) {
    if (ResolveIl2CppSymbols() && ApplyRussNativeFogRemoval(remove)) return YES;
    if (!EnsureIl2CppThread()) return NO;
    if (gRenderSettingsKlass == NULL) {
        gRenderSettingsKlass = FindClassInAllAssemblies("UnityEngine", "RenderSettings");
        if (gRenderSettingsKlass == NULL) return NO;
    }
    if (gSetFogMethod == NULL) gSetFogMethod = gIl2CppClassGetMethodFromName(gRenderSettingsKlass, "set_fog", 1);
    if (gSetFogDensityMethod == NULL) gSetFogDensityMethod = gIl2CppClassGetMethodFromName(gRenderSettingsKlass, "set_fogDensity", 1);
    if (gGetFogMethod == NULL) gGetFogMethod = gIl2CppClassGetMethodFromName(gRenderSettingsKlass, "get_fog", 0);
    if (gGetFogDensityMethod == NULL) gGetFogDensityMethod = gIl2CppClassGetMethodFromName(gRenderSettingsKlass, "get_fogDensity", 0);
    if (gSetFogMethod == NULL) return NO;

    if (remove && !gFogSaved && gGetFogMethod != NULL && gGetFogDensityMethod != NULL && gIl2CppObjectUnbox != NULL) {
        Il2CppObject *exception = NULL;
        Il2CppObject *fogObj = gIl2CppRuntimeInvoke(gGetFogMethod, NULL, NULL, &exception);
        if (exception == NULL && fogObj != NULL) {
            gOriginalFog = *((BOOL *)gIl2CppObjectUnbox(fogObj));
        }
        exception = NULL;
        Il2CppObject *densityObj = gIl2CppRuntimeInvoke(gGetFogDensityMethod, NULL, NULL, &exception);
        if (exception == NULL && densityObj != NULL) {
            gOriginalFogDensity = *((float *)gIl2CppObjectUnbox(densityObj));
        }
        gFogSaved = YES;
    }

    BOOL fog = remove ? NO : (gFogSaved ? gOriginalFog : YES);
    float density = remove ? 0.0f : gOriginalFogDensity;
    void *fogArgs[] = { &fog };
    Il2CppObject *exception = NULL;
    gIl2CppRuntimeInvoke(gSetFogMethod, NULL, fogArgs, &exception);
    if (gSetFogDensityMethod != NULL) {
        void *densityArgs[] = { &density };
        exception = NULL;
        gIl2CppRuntimeInvoke(gSetFogDensityMethod, NULL, densityArgs, &exception);
    }
    return exception == NULL;
}
/*优先使用 Russ 原版内存状态链；仅在链不匹配当前 UnityFramework 时回退 RenderSettings*/

static void *gLightKlass;
static const MethodInfo *gGetIntensityMethod;
static const MethodInfo *gSetIntensityMethod;
static uintptr_t gHighlightStateAddress;
static float gOriginalHighlightState[7];
static BOOL gNativeHighlightStateSaved;
enum { kRussLightCacheMax = 1024 };
typedef struct RussLightCacheEntry {
    uint32_t handle;
    float originalIntensity;
} RussLightCacheEntry;
static RussLightCacheEntry gLightCache[kRussLightCacheMax];
/*高亮仅恢复本功能实际改写过的 Light，不能假定所有灯的默认强度都是 1。*/

static NSInteger FindLightCacheEntry(Il2CppObject *light) {
    if (light == NULL || gIl2CppGCHandleGetTarget == NULL) return NSNotFound;
    for (NSInteger index = 0; index < kRussLightCacheMax; index++) {
        if (gLightCache[index].handle != 0 &&
            gIl2CppGCHandleGetTarget(gLightCache[index].handle) == light) return index;
    }
    return NSNotFound;
}

static NSUInteger RestoreHighlight(void) {
    if (gSetIntensityMethod == NULL || gIl2CppGCHandleGetTarget == NULL) return 0;
    NSUInteger restored = 0;
    for (NSInteger index = 0; index < kRussLightCacheMax; index++) {
        RussLightCacheEntry *entry = &gLightCache[index];
        if (entry->handle == 0) continue;
        Il2CppObject *light = gIl2CppGCHandleGetTarget(entry->handle);
        if (light != NULL && isfinite(entry->originalIntensity)) {
            void *arguments[] = { &entry->originalIntensity };
            Il2CppObject *exception = NULL;
            gIl2CppRuntimeInvoke(gSetIntensityMethod, light, arguments, &exception);
            if (exception == NULL) restored++;
        }
        if (gIl2CppGCHandleFree != NULL) gIl2CppGCHandleFree(entry->handle);
        entry->handle = 0;
    }
    return restored;
}

static BOOL ApplyRussNativeHighlight(BOOL enabled, float brightness) {
    static const uintptr_t kHighlightChain[] = {
        0x65f82e8, 0x560, 0x50, 0xb8, 0x20, 0xb0, 0xb0
    };
    uintptr_t address = 0;
    if (!ResolveUnityPointerChain(kHighlightChain, sizeof(kHighlightChain) / sizeof(kHighlightChain[0]), &address)) return NO;

    float state[7] = { 0 };
    if (!ReadProcessMemory(address, state, sizeof(state))) return NO;
    for (NSUInteger index = 0; index < 7; index++) {
        if (!isfinite(state[index])) return NO;
    }
    if (!gNativeHighlightStateSaved || gHighlightStateAddress != address) {
        memcpy(gOriginalHighlightState, state, sizeof(state));
        gHighlightStateAddress = address;
        gNativeHighlightStateSaved = YES;
    }

    if (!enabled) {
        static const size_t kOffsets[] = { 0x0, 0x8, 0x10, 0x18 };
        for (NSUInteger index = 0; index < 4; index++) {
            size_t offset = kOffsets[index];
            if (!WriteProcessMemory(address + offset, &gOriginalHighlightState[offset / sizeof(float)], sizeof(float))) return NO;
        }
        return YES;
    }

    float marker = 9999.0f;/*原版 FUN_00019624 的 0x461c3c00 标记值*/
    float intensity = (float)MAX(1.0, MIN(10.0, brightness));
    return WriteProcessMemory(address, &marker, sizeof(marker)) &&
           WriteProcessMemory(address + 0x8, &intensity, sizeof(intensity)) &&
           WriteProcessMemory(address + 0x10, &marker, sizeof(marker)) &&
           WriteProcessMemory(address + 0x18, &intensity, sizeof(intensity));
}
/*Russ FUN_00019624：定位 0x1c 字节状态块，写入 marker/亮度交错字段，关闭时恢复原始四字段。*/

static NSUInteger ApplyHighlight(BOOL on, float brightness) {
    if (ResolveIl2CppSymbols() && ApplyRussNativeHighlight(on, brightness)) return 2;
    if (!EnsureIl2CppThread()) return 0;
    if (gLightKlass == NULL) {
        gLightKlass = FindClassInAllAssemblies("UnityEngine", "Light");
        if (gLightKlass == NULL) return 0;
    }
    if (gSetIntensityMethod == NULL) {
        gGetIntensityMethod = gIl2CppClassGetMethodFromName(gLightKlass, "get_intensity", 0);
        gSetIntensityMethod = gIl2CppClassGetMethodFromName(gLightKlass, "set_intensity", 1);
        if (gGetIntensityMethod == NULL || gSetIntensityMethod == NULL || gIl2CppObjectUnbox == NULL ||
            gIl2CppGCHandleNew == NULL) return 0;
    }
    if (!on) return RestoreHighlight();
    Il2CppArray *lights = ScanObjectsOfClass(gLightKlass, YES);
    if (lights == NULL) return 0;
    float value = (float)MAX(1.0, MIN(10.0, brightness));
    void *arguments[] = { &value };
    NSUInteger touched = 0;
    Il2CppObject *exception = NULL;
    for (uintptr_t index = 0; index < lights->maxLength; index++) {
        Il2CppObject *light = lights->objects[index];
        if (light == NULL) continue;
        NSInteger slot = FindLightCacheEntry(light);
        if (slot == NSNotFound) {
            for (NSInteger candidate = 0; candidate < kRussLightCacheMax; candidate++) {
                if (gLightCache[candidate].handle == 0) {
                    slot = candidate;
                    break;
                }
            }
            if (slot == NSNotFound) continue;
            exception = NULL;
            Il2CppObject *current = gIl2CppRuntimeInvoke(gGetIntensityMethod, light, NULL, &exception);
            if (exception != NULL || current == NULL) continue;
            float *original = (float *)gIl2CppObjectUnbox(current);
            if (original == NULL || !isfinite(*original)) continue;
            uint32_t handle = gIl2CppGCHandleNew(light, NO);
            if (handle == 0) continue;
            gLightCache[slot].handle = handle;
            gLightCache[slot].originalIntensity = *original;
        }
        exception = NULL;
        gIl2CppRuntimeInvoke(gSetIntensityMethod, light, arguments, &exception);
        if (exception == NULL) touched++;
    }
    return touched;
}
/*高亮按原版 [1,10] 收敛；每盏灯首次改写前保存其实际强度，关闭时精确恢复。*/

static void *gComponentKlass;
static void *gGameObjectKlass;
static const MethodInfo *gGetGameObjectMethod;
static const MethodInfo *gSetActiveMethod;
/*component/gameobject缓存*/

static BOOL EnsureGameObjectApi(void) {
    if (gComponentKlass != NULL && gGameObjectKlass != NULL &&
        gGetGameObjectMethod != NULL && gSetActiveMethod != NULL) return YES;
    if (!EnsureIl2CppThread()) return NO;
    if (gComponentKlass == NULL) gComponentKlass = FindClassInAllAssemblies("UnityEngine", "Component");
    if (gGameObjectKlass == NULL) gGameObjectKlass = FindClassInAllAssemblies("UnityEngine", "GameObject");
    if (gComponentKlass == NULL || gGameObjectKlass == NULL) return NO;
    if (gGetGameObjectMethod == NULL) gGetGameObjectMethod = gIl2CppClassGetMethodFromName(gComponentKlass, "get_gameObject", 0);
    if (gSetActiveMethod == NULL) gSetActiveMethod = gIl2CppClassGetMethodFromName(gGameObjectKlass, "SetActive", 1);
    return gGetGameObjectMethod != NULL && gSetActiveMethod != NULL;
}
/*gameobject.setactive api缓存*/

enum { kRussCoffinColorCacheMax = 512 };
typedef struct RussCoffinColorCacheEntry {
    uint32_t handle;
    UnityColor originalColor;
} RussCoffinColorCacheEntry;
/*原版以 gchandle 保存被修改的 Image；关闭功能时只恢复这些对象，避免影响无关 UI*/

static void *gCoffinSourceKlass;
static void *gCoffinPageKlass;
static void *gCoffinEntryKlass;
static void *gImageKlass;
static void *gGraphicKlass;
static const MethodInfo *gCoffinGetPageMethod;
static const MethodInfo *gCoffinGetEntryMethod;
static const MethodInfo *gGraphicGetColorMethod;
static const MethodInfo *gGraphicSetColorMethod;
static void *gCoffinEntryListField;
static uint32_t gCoffinPage = 1;
static BOOL gCoffinRevealEnabled;
static float gDemagnetizationFactor;
static RussCoffinColorCacheEntry gCoffinColorCache[kRussCoffinColorCacheMax];
/*Russ 0x17720：EAKGFFFBKDG.DCODHFKCBGO → GAKFOICFFGF.DGFGHBCDENH →
  JJKENHNKEJP.IDBNHPMAGCN；只处理该链产生的 Image，不扫描全局 Graphic*/

static BOOL IsFiniteUnityColor(const UnityColor *color) {
    if (color == NULL) return NO;
    return isfinite(color->r) && isfinite(color->g) && isfinite(color->b) && isfinite(color->a) &&
           color->a >= 0.0f && color->a <= 1.0f;
}

static NSInteger FindCoffinColorCacheEntry(Il2CppObject *graphic) {
    if (graphic == NULL || gIl2CppGCHandleGetTarget == NULL) return NSNotFound;
    for (NSInteger index = 0; index < kRussCoffinColorCacheMax; index++) {
        if (gCoffinColorCache[index].handle == 0) continue;
        if (gIl2CppGCHandleGetTarget(gCoffinColorCache[index].handle) == graphic) return index;
    }
    return NSNotFound;
}

static NSUInteger RestoreCoffinGraphicColors(void) {
    if (gGraphicSetColorMethod == NULL || gIl2CppGCHandleGetTarget == NULL) return 0;
    NSUInteger restored = 0;
    for (NSInteger index = 0; index < kRussCoffinColorCacheMax; index++) {
        RussCoffinColorCacheEntry *entry = &gCoffinColorCache[index];
        if (entry->handle == 0) continue;
        Il2CppObject *graphic = gIl2CppGCHandleGetTarget(entry->handle);
        if (graphic != NULL && ValidateInstanceOfClass(graphic, gImageKlass)) {
            void *arguments[] = { &entry->originalColor };
            Il2CppObject *exception = NULL;
            gIl2CppRuntimeInvoke(gGraphicSetColorMethod, graphic, arguments, &exception);
            if (exception == NULL) restored++;
        }
        if (gIl2CppGCHandleFree != NULL) gIl2CppGCHandleFree(entry->handle);
        entry->handle = 0;
    }
    return restored;
}

static BOOL CacheAndApplyCoffinGraphicAlpha(Il2CppObject *graphic, float alphaFactor) {
    if (graphic == NULL || !ValidateInstanceOfClass(graphic, gImageKlass) ||
        gGraphicGetColorMethod == NULL || gGraphicSetColorMethod == NULL ||
        gIl2CppObjectUnbox == NULL || gIl2CppGCHandleNew == NULL) return NO;

    NSInteger slot = FindCoffinColorCacheEntry(graphic);
    if (slot == NSNotFound) {
        for (NSInteger index = 0; index < kRussCoffinColorCacheMax; index++) {
            if (gCoffinColorCache[index].handle == 0) {
                slot = index;
                break;
            }
        }
        if (slot == NSNotFound) return NO;

        Il2CppObject *exception = NULL;
        Il2CppObject *boxedColor = gIl2CppRuntimeInvoke(gGraphicGetColorMethod, graphic, NULL, &exception);
        if (exception != NULL || boxedColor == NULL) return NO;
        UnityColor *original = (UnityColor *)gIl2CppObjectUnbox(boxedColor);
        if (!IsFiniteUnityColor(original)) return NO;

        uint32_t handle = gIl2CppGCHandleNew(graphic, NO);
        if (handle == 0) return NO;
        gCoffinColorCache[slot].handle = handle;
        gCoffinColorCache[slot].originalColor = *original;
    }

    UnityColor adjustedColor = gCoffinColorCache[slot].originalColor;
    adjustedColor.a *= (float)MAX(0.0, MIN(1.0, alphaFactor));
    void *arguments[] = { &adjustedColor };
    Il2CppObject *exception = NULL;
    gIl2CppRuntimeInvoke(gGraphicSetColorMethod, graphic, arguments, &exception);
    return exception == NULL;
}

static NSUInteger ApplyCoffinEntryList(Il2CppObject *listObject, float alphaFactor) {
    if (listObject == NULL) return 0;

    /*原版最终按 List._items(+0x10)、List._size(+0x18) 取得条目数组，随后按数组0x20、条目0x18读取；
      每条仅在 state >= 0 且对象确为 UnityEngine.UI.Image 时修改。*/
    uintptr_t itemsAddress = 0;
    int32_t count = 0;
    if (!ReadProcessMemory((uintptr_t)listObject + 0x10, &itemsAddress, sizeof(itemsAddress)) ||
        !ReadProcessMemory((uintptr_t)listObject + 0x18, &count, sizeof(count)) ||
        itemsAddress < 0x10000 || count <= 0 || count > 4096) return 0;

    uintptr_t maxLength = 0;
    if (!ReadProcessMemory(itemsAddress + 0x18, &maxLength, sizeof(maxLength)) || maxLength == 0 || maxLength > 8192) return 0;
    NSUInteger limit = (NSUInteger)MIN((uint64_t)count, (uint64_t)maxLength);
    NSUInteger touched = 0;
    for (NSUInteger index = 0; index < limit; index++) {
        uintptr_t entryAddress = itemsAddress + 0x20 + index * 0x18;
        int32_t state = -1;
        Il2CppObject *graphic = NULL;
        if (!ReadProcessMemory(entryAddress, &state, sizeof(state)) || state < 0 ||
            !ReadProcessMemory(entryAddress + 0x10, &graphic, sizeof(graphic))) continue;
        if (CacheAndApplyCoffinGraphicAlpha(graphic, alphaFactor)) touched++;
    }
    return touched;
}

static NSUInteger ApplyCoffinVisualState(void) {
    if (!EnsureIl2CppThread() || gIl2CppFieldGetValue == NULL) return 0;
    if (gCoffinSourceKlass == NULL) gCoffinSourceKlass = FindClassInAllAssemblies("", "EAKGFFFBKDG");
    if (gCoffinPageKlass == NULL) gCoffinPageKlass = FindClassInAllAssemblies("", "GAKFOICFFGF");
    if (gCoffinEntryKlass == NULL) gCoffinEntryKlass = FindClassInAllAssemblies("", "JJKENHNKEJP");
    if (gImageKlass == NULL) gImageKlass = FindClassInAllAssemblies("UnityEngine.UI", "Image");
    if (gGraphicKlass == NULL) gGraphicKlass = FindClassInAllAssemblies("UnityEngine.UI", "Graphic");
    if (gCoffinSourceKlass == NULL || gCoffinPageKlass == NULL || gCoffinEntryKlass == NULL ||
        gImageKlass == NULL || gGraphicKlass == NULL) return 0;

    if (gCoffinGetPageMethod == NULL) gCoffinGetPageMethod = gIl2CppClassGetMethodFromName(gCoffinSourceKlass, "DCODHFKCBGO", 0);
    if (gCoffinGetEntryMethod == NULL) gCoffinGetEntryMethod = gIl2CppClassGetMethodFromName(gCoffinPageKlass, "DGFGHBCDENH", 1);
    if (gCoffinEntryListField == NULL) gCoffinEntryListField = gIl2CppClassGetFieldFromName(gCoffinEntryKlass, "IDBNHPMAGCN");
    if (gGraphicGetColorMethod == NULL) gGraphicGetColorMethod = gIl2CppClassGetMethodFromName(gGraphicKlass, "get_color", 0);
    if (gGraphicSetColorMethod == NULL) gGraphicSetColorMethod = gIl2CppClassGetMethodFromName(gGraphicKlass, "set_color", 1);
    if (gCoffinGetPageMethod == NULL || gCoffinGetEntryMethod == NULL || gCoffinEntryListField == NULL ||
        gGraphicGetColorMethod == NULL || gGraphicSetColorMethod == NULL) return 0;

    Il2CppObject *exception = NULL;
    Il2CppObject *pageSource = gIl2CppRuntimeInvoke(gCoffinGetPageMethod, NULL, NULL, &exception);
    if (exception != NULL || !ValidateInstanceOfClass(pageSource, gCoffinPageKlass)) return 0;

    int32_t page = (int32_t)gCoffinPage;
    void *arguments[] = { &page };
    exception = NULL;
    Il2CppObject *entry = gIl2CppRuntimeInvoke(gCoffinGetEntryMethod, pageSource, arguments, &exception);
    gCoffinPage = gCoffinPage >= 4 ? 1 : gCoffinPage + 1;/*原版按 1~4 分批拉取，避免一帧集中修改*/
    if (exception != NULL || !ValidateInstanceOfClass(entry, gCoffinEntryKlass)) return 0;

    Il2CppObject *listObject = NULL;
    gIl2CppFieldGetValue(entry, gCoffinEntryListField, &listObject);
    float hidingFactor = gCoffinRevealEnabled ? 1.0f : gDemagnetizationFactor;
    return ApplyCoffinEntryList(listObject, 1.0f - hidingFactor);
}
/*Russ 0x17720：目标 Image 的 alpha = 原 alpha × (1 - 强度)，每次仅处理一个分页。*/

static NSUInteger ApplyCoffinReveal(BOOL reveal) {
    gCoffinRevealEnabled = reveal;
    if (!gCoffinRevealEnabled && gDemagnetizationFactor <= 0.0f) return RestoreCoffinGraphicColors();
    return ApplyCoffinVisualState();
}

static NSUInteger ApplyDemagnetization(float strengthPercent) {
    gDemagnetizationFactor = (float)MAX(0.0, MIN(100.0, strengthPercent)) / 100.0f;
    if (!gCoffinRevealEnabled && gDemagnetizationFactor <= 0.0f) return RestoreCoffinGraphicColors();
    return ApplyCoffinVisualState();
}
/*消磁沿用原版 EAK→GAK→JJK Image 链：强度 0~100% 直接控制原 alpha 的衰减。*/

static void *gFindPathLineCtrlKlass;
static void *gLineRendererKlass;
static void *gRouteLineRendererField;
static void *gRoutePointsListField;
/*路线控制器/字段/LineRenderer缓存；Russ 原版只读取它来校验和投影，不改写游戏渲染状态*/

static NSUInteger SetIslandRouteVisible(BOOL visible) {
    if (!EnsureIl2CppThread()) return 0;
    if (gFindPathLineCtrlKlass == NULL || gLineRendererKlass == NULL) {
        gFindPathLineCtrlKlass = FindClassInAllAssemblies("", "FindPathLineCtrl");
        gLineRendererKlass = FindClassInAllAssemblies("UnityEngine", "LineRenderer");
        if (gFindPathLineCtrlKlass == NULL || gLineRendererKlass == NULL) return 0;
    }
    if (gRouteLineRendererField == NULL) {
        gRouteLineRendererField = gIl2CppClassGetFieldFromName(gFindPathLineCtrlKlass, "lineRender");
        gRoutePointsListField = gIl2CppClassGetFieldFromName(gFindPathLineCtrlKlass, "pointsList");
        if (gRouteLineRendererField == NULL || gRoutePointsListField == NULL || gIl2CppFieldGetValue == NULL) return 0;
    }
    Il2CppArray *result = ScanObjectsOfClass(gFindPathLineCtrlKlass, YES);
    if (result == NULL) return 0;
    if (!visible) return 0;
    NSUInteger touched = 0;
    for (uintptr_t index = 0; index < result->maxLength; index++) {
        Il2CppObject *routeController = result->objects[index];
        if (routeController == NULL) continue;
        Il2CppObject *lineRenderer = NULL;
        Il2CppObject *pointsList = NULL;
        gIl2CppFieldGetValue(routeController, gRouteLineRendererField, &lineRenderer);
        gIl2CppFieldGetValue(routeController, gRoutePointsListField, &pointsList);
        if (ValidateInstanceOfClass(lineRenderer, gLineRendererKlass) && pointsList != NULL) touched++;
    }
    return touched;
}
/*原版只校验 FindPathLineCtrl.lineRender/pointsList；显示由 UIKit 路线覆盖层完成，不触碰游戏 LineRenderer*/

static NSUInteger CopyIslandRouteWorldPoints(float *output, NSUInteger capacity) {
    if (output == NULL || capacity < 2 || !EnsureIl2CppThread()) return 0;
    if (gFindPathLineCtrlKlass == NULL) {
        gFindPathLineCtrlKlass = FindClassInAllAssemblies("", "FindPathLineCtrl");
        if (gFindPathLineCtrlKlass == NULL) return 0;
    }
    if (gRoutePointsListField == NULL) {
        gRoutePointsListField = gIl2CppClassGetFieldFromName(gFindPathLineCtrlKlass, "pointsList");
        if (gRoutePointsListField == NULL || gIl2CppFieldGetValue == NULL) return 0;
    }
    Il2CppArray *controllers = ScanObjectsOfClass(gFindPathLineCtrlKlass, YES);
    if (controllers == NULL) return 0;

    Il2CppObject *bestList = NULL;
    int32_t bestCount = 0;
    for (uintptr_t index = 0; index < controllers->maxLength; index++) {
        Il2CppObject *controller = controllers->objects[index];
        Il2CppObject *pointsList = NULL;
        if (controller == NULL) continue;
        gIl2CppFieldGetValue(controller, gRoutePointsListField, &pointsList);
        int32_t count = 0;
        if (pointsList == NULL || !ReadProcessMemory((uintptr_t)pointsList + 0x18, &count, sizeof(count)) ||
            count < 2 || count > 4096 || count <= bestCount) continue;
        bestList = pointsList;
        bestCount = count;
    }
    if (bestList == NULL) return 0;

    /*Russ 0x8f48：List<Vector3> 的 _items 位于+0x10、_size 位于+0x18，
      Vector3[] 数据从数组+0x20开始，每个元素12字节。*/
    uintptr_t items = 0;
    uintptr_t maxLength = 0;
    if (!ReadProcessMemory((uintptr_t)bestList + 0x10, &items, sizeof(items)) || items < 0x10000 ||
        !ReadProcessMemory(items + 0x18, &maxLength, sizeof(maxLength)) || maxLength < 2 || maxLength > 4096) return 0;
    NSUInteger count = (NSUInteger)MIN((uint64_t)bestCount, (uint64_t)maxLength);
    count = MIN(count, capacity);
    size_t byteLength = count * 3 * sizeof(float);
    if (!ReadProcessMemory(items + 0x20, output, byteLength)) return 0;
    for (NSUInteger index = 0; index < count * 3; index++) {
        if (!isfinite(output[index]) || fabsf(output[index]) > 1000000.0f) return 0;
    }
    return count;
}
/*原版 YYIslandRouteCopyScreenPoints 的数据源：选取有效 pointsList 并读取其 Vector3 路径点*/

static void *gTransformKlass;
static const MethodInfo *gGetTransformMethod;
static const MethodInfo *gGetPositionMethod;
/*transform缓存*/

static BOOL EnsureTransformApi(void) {
    if (gTransformKlass != NULL && gGetTransformMethod != NULL && gGetPositionMethod != NULL) return YES;
    if (!EnsureIl2CppThread()) return NO;
    if (gComponentKlass == NULL) gComponentKlass = FindClassInAllAssemblies("UnityEngine", "Component");
    if (gTransformKlass == NULL) gTransformKlass = FindClassInAllAssemblies("UnityEngine", "Transform");
    if (gComponentKlass == NULL || gTransformKlass == NULL) return NO;
    if (gGetTransformMethod == NULL) gGetTransformMethod = gIl2CppClassGetMethodFromName(gComponentKlass, "get_transform", 0);
    if (gGetPositionMethod == NULL) gGetPositionMethod = gIl2CppClassGetMethodFromName(gTransformKlass, "get_position", 0);
    return gGetTransformMethod != NULL && gGetPositionMethod != NULL;
}
/*坐标api缓存*/

static Il2CppObject *GetMainCameraObject(void) {
    if (!EnsureCameraApi() || gGetMainMethod == NULL) return NULL;
    Il2CppObject *exception = NULL;
    Il2CppObject *camera = gIl2CppRuntimeInvoke(gGetMainMethod, NULL, NULL, &exception);
    if (exception != NULL || camera == NULL) return NULL;
    return camera;
}
/*camera.get_main拿主相机*/

static BOOL GetObjectWorldPosition(Il2CppObject *component, float *outX, float *outY, float *outZ) {
    if (component == NULL || !EnsureTransformApi() || gIl2CppObjectUnbox == NULL) return NO;
    Il2CppObject *exception = NULL;
    Il2CppObject *transform = gIl2CppRuntimeInvoke(gGetTransformMethod, component, NULL, &exception);
    if (exception != NULL || transform == NULL) return NO;
    exception = NULL;
    Il2CppObject *posObj = gIl2CppRuntimeInvoke(gGetPositionMethod, transform, NULL, &exception);
    if (exception != NULL || posObj == NULL) return NO;
    float *pos = (float *)gIl2CppObjectUnbox(posObj);
    if (pos == NULL) return NO;
    if (outX) *outX = pos[0];
    if (outY) *outY = pos[1];
    if (outZ) *outZ = pos[2];
    return YES;
}
/*component.get_transform transform.get_position unbox出vector3*/

static BOOL ProjectWorldToScreen(Il2CppObject *camera, float wx, float wy, float wz, float *outX, float *outY, float *outZ) {
    if (camera == NULL || !EnsureCameraApi() || gWorldToScreenMethod == NULL || gIl2CppObjectUnbox == NULL) return NO;
    struct { float x, y, z; } world = { wx, wy, wz };
    void *arguments[] = { &world };
    Il2CppObject *exception = NULL;
    Il2CppObject *screenObj = gIl2CppRuntimeInvoke(gWorldToScreenMethod, camera, arguments, &exception);
    if (exception != NULL || screenObj == NULL) return NO;
    float *screen = (float *)gIl2CppObjectUnbox(screenObj);
    if (screen == NULL) return NO;
    if (outX) *outX = screen[0];
    if (outY) *outY = screen[1];
    if (outZ) *outZ = screen[2];
    return YES;
}
/*camera.worldtoscreenpoint投影世界坐标到屏幕 棺材esp标记用*/

@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *mainPanel;
@property(nonatomic, strong) UIScrollView *panelScroll;
@property(nonatomic, strong) UIButton *floatingButton;
@property(nonatomic, strong) UIView *welcomePanel;
@property(nonatomic, strong) UITextField *cardField;
@property(nonatomic, strong) UILabel *welcomeHint;
@property(nonatomic, strong) UILabel *engineStatus;
@property(nonatomic, assign) NSInteger engineStatusState;
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
@property(nonatomic, assign) NSUInteger markerFrameTick;
@property(nonatomic, assign) uint32_t coffinArrayHandle;
@property(nonatomic, assign) Il2CppArray *coffinArrayRaw;
@property(nonatomic, strong) CADisplayLink *routeDisplayLink;
@property(nonatomic, strong) UIView *routeOverlay;
@property(nonatomic, strong) CAShapeLayer *routeShadowLayer;
@property(nonatomic, strong) CAShapeLayer *routeLineLayer;
@property(nonatomic, strong) CADisplayLink *runtimeDisplayLink;
@property(nonatomic, assign) NSUInteger runtimeFrameTick;
@property(nonatomic, assign) BOOL lifecycleObserversInstalled;
@end
/*照原版menuview结构 mainpanel featurestates 4滑块值 验证passed 面板visible 棺材标记overlay+gchandle数组 引擎状态标签*/

@implementation RussOverlayController

- (void)install {
    [self loadSettings];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self installLifecycleObserversIfNeeded];
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
        [self startRuntimeEngine];
        [self restoreFeatureRuntime];
    });
}
/*入口 悬浮按钮russ可拖动 点击开面板 构建ui+欢迎页 引擎常驻(重试连接+状态刷新) 恢复上次功能状态*/

- (void)installLifecycleObserversIfNeeded {
    if (self.lifecycleObserversInstalled) return;
    self.lifecycleObserversInstalled = YES;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(pauseOverlayRendering) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(pauseOverlayRendering) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(shutdownFeatureRuntime) name:UIApplicationWillTerminateNotification object:nil];
    [center addObserver:self selector:@selector(resumeOverlayRendering) name:UIApplicationDidBecomeActiveNotification object:nil];
}
/*对齐辞月 hookui_pauseRendering/hookui_resumeRendering：失焦、后台、终止均暂停帧回调，回前台后恢复*/

- (void)pauseOverlayRendering {
    self.runtimeDisplayLink.paused = YES;
    self.coffinDisplayLink.paused = YES;
    self.routeDisplayLink.paused = YES;
}

- (void)shutdownFeatureRuntime {
    [self pauseOverlayRendering];
    ApplyHighlight(NO, 1.0f);
    ApplyCoffinReveal(NO);
    ApplyFogRemoval(NO);
    ApplyDemagnetization(0.0f);
    ApplyTimeScale(1.0f);
    ApplyCameraFollow(0.0f, NO, 0.0f, NO);
    [self stopCoffinMarkers];
    [self stopIslandRouteOverlay];
}
/*对齐 _YYGameMemoryShutdown：终止时撤销本 dylib 修改的状态并释放覆盖层对象。*/

- (void)resumeOverlayRendering {
    self.runtimeDisplayLink.paused = NO;
    self.coffinDisplayLink.paused = NO;
    self.routeDisplayLink.paused = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self restoreFeatureRuntime];
        [self tickRuntime];
    });
}
/*辞月恢复逻辑在主线程延迟200ms后恢复 MTK 绘制；本实现重建 Unity 状态并立刻补一次运行时刷新*/

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

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 10.0, 150.0, 24.0)];
    title.text = @"Russ公益";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:18.0];
    [self.mainPanel addSubview:title];

    self.engineStatus = [[UILabel alloc] initWithFrame:CGRectMake(190.0, 13.0, 100.0, 18.0)];
    self.engineStatus.font = [UIFont boldSystemFontOfSize:11.0];
    self.engineStatus.textAlignment = NSTextAlignmentRight;
    self.engineStatus.textColor = [UIColor orangeColor];
    self.engineStatus.text = @"引擎:连接中";
    [dragBar addSubview:self.engineStatus];
    self.engineStatusState = 0;

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
/*主面板 russ公益 标题+44pt拖动条+引擎连接状态 右侧滚动区9张功能卡片 + 欢迎验证页*/

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
        @"wide": @{@"title": @"广角视角", @"icon": @"viewfinder.circle.fill", @"desc": @"视野扩展到66度"},
        @"islandRoute": @{@"title": @"岛屿路线", @"icon": @"map.fill", @"desc": @"显示 LineRenderer 路线"},
        @"firstPersonFOV": @{@"title": @"第一人称 FOV", @"icon": @"person.crop.circle", @"slider": @YES, @"min": @30.0, @"max": @170.0, @"unit": @"°"},
        @"thirdPersonFOV": @{@"title": @"第三人称 FOV", @"icon": @"figure.walking", @"slider": @YES, @"min": @30.0, @"max": @170.0, @"unit": @"°"},
        @"demagnetization": @{@"title": @"消磁强度", @"icon": @"bolt.slash.fill", @"slider": @YES, @"min": @0.0, @"max": @100.0, @"unit": @"%"},
        @"globalSpeed": @{@"title": @"速度倍率", @"icon": @"hare.fill", @"slider": @YES, @"min": @1.0, @"max": @10.0, @"unit": @"x"}
    };
}
/*9张卡片定义 图标照原版sfsymbols 标题/说明/滑块范围 广角默认66度照原版widefov值*/

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
    if ([key isEqualToString:@"globalSpeed"]) {
        ApplyTimeScale(sender.value);
    } else if ([key isEqualToString:@"demagnetization"]) {
        if ([self.featureStates[@"demagnetization"] boolValue] || sender.value > 0.0) {
            ApplyDemagnetization(sender.value);
        }
    }
    [self updateCardValueLabel:key spec:spec];
    [self saveSettings];
    [self refreshEngineFrameRate];
}
/*滑块回调 存值 速度消磁即时写 fov由引擎每帧写 照原版featuresliderchanged */

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
    [self refreshEngineFrameRate];
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
        CGFloat thirdFOV = enabled ? 66.0 : [self sliderValueForKey:@"thirdPersonFOV"];
        CGFloat firstFOV = [self sliderValueForKey:@"firstPersonFOV"];
        ApplyCameraFollow((float)thirdFOV, enabled, (float)firstFOV, firstFOV != 75.0);
        [self setCardHint:key text:enabled ? @"已调整角色相机视角" : @"已恢复角色相机视角"];
    } else if ([key isEqualToString:@"islandRoute"]) {
        NSUInteger count = SetIslandRouteVisible(enabled);
        if (enabled) [self startIslandRouteOverlay];
        else [self stopIslandRouteOverlay];
        [self setCardHint:key text:[NSString stringWithFormat:@"%@", enabled ? [NSString stringWithFormat:@"已显示 %lu 条路线", (unsigned long)count] : @"已隐藏所有路线"]];
    } else if ([key isEqualToString:@"demagnetization"]) {
        NSUInteger count = enabled ? ApplyDemagnetization([self sliderValueForKey:@"demagnetization"]) : ApplyDemagnetization(0.0);
        [self setCardHint:key text:[NSString stringWithFormat:@"%@", enabled ? [NSString stringWithFormat:@"已消磁 %lu 个物体", (unsigned long)count] : @"已恢复磁性"]];
    }
}
/*功能分发 setfeature后即时生效一次 引擎每帧/每0.5s持续维持 广角66度照原版widefov默认值 */

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
    [self refreshEngineFrameRate];
    [self.runtimeDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
/*引擎常驻启动:连接重试+状态刷新+功能维持 有功能60帧无功能降到10帧省电 */

- (void)refreshEngineFrameRate {
    if (self.runtimeDisplayLink == nil) return;
    NSInteger fps = [self anyFeatureActive] ? 60 : 10;
    if (self.runtimeDisplayLink.preferredFramesPerSecond != fps) {
        self.runtimeDisplayLink.preferredFramesPerSecond = fps;
    }
}
/*动态帧率:功能激活60fps 维持写入 空闲10fps只做连接重试+状态 */

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

- (void)updateEngineStatus:(BOOL)connected {
    NSInteger state = connected ? 1 : 0;
    if (state == self.engineStatusState) return;
    self.engineStatusState = state;
    if (self.engineStatus == nil) return;
    if (connected) {
        self.engineStatus.text = @"引擎:已连接";
        self.engineStatus.textColor = [UIColor colorWithRed:0.30 green:0.85 blue:0.70 alpha:1.0];
    } else {
        self.engineStatus.text = @"引擎:连接中";
        self.engineStatus.textColor = [UIColor orangeColor];
    }
}
/*引擎连接状态显示 拖动栏右侧 未连接橙色/已连接绿色 状态变化才刷新避免每帧布局 */

- (void)tickRuntime {
    self.runtimeFrameTick++;
    BOOL connected = EnsureIl2CppThread();
    [self updateEngineStatus:connected];
    if (!connected) return;

    BOOL anyActive = [self anyFeatureActive];
    BOOL heavyTick = (self.runtimeFrameTick % 30 == 0);
    if (heavyTick) [self refreshEngineFrameRate];
    if (!anyActive) return;

    CGFloat firstFOV = [self sliderValueForKey:@"firstPersonFOV"];
    CGFloat thirdFOV = [self sliderValueForKey:@"thirdPersonFOV"];
    BOOL wide = [self.featureStates[@"wide"] boolValue];
    CGFloat speed = [self sliderValueForKey:@"globalSpeed"];

    if ([self.featureStates[@"fog"] boolValue]) ApplyFogRemoval(YES);
    if (speed != 1.0) ApplyTimeScale((float)speed);
    ApplyCameraFollow((float)(wide ? 66.0 : thirdFOV), wide || thirdFOV != 75.0,
                      (float)firstFOV, firstFOV != 75.0);
    if (heavyTick) {
        if ([self.featureStates[@"highlight"] boolValue]) ApplyHighlight(YES, 2.5f);
        if ([self.featureStates[@"demagnetization"] boolValue]) ApplyDemagnetization([self sliderValueForKey:@"demagnetization"]);
        if ([self.featureStates[@"coffin"] boolValue]) ApplyCoffinReveal(YES);
        if ([self.featureStates[@"islandRoute"] boolValue]) SetIslandRouteVisible(YES);
    }
}
/*每帧: 引擎连接重试+状态刷新(常驻) fog/timescale/camerafollow字段/相机fov轻量invoke 每30帧(0.5s):灯/刚体/棺材/路线扫描 热更程序集加载后自动生效 新对象自动覆盖 */

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
    self.markerFrameTick = 0;
    self.coffinDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateCoffinMarkers)];
    [self.coffinDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
/*棺材透视开启 全屏透明overlay+8标记池 cadisplaylink每帧 照原版displaylink架构 */

- (void)startIslandRouteOverlay {
    if (self.routeDisplayLink != nil) return;
    UIWindow *window = self.floatingButton.window;
    if (window == nil) return;
    self.routeOverlay = [[UIView alloc] initWithFrame:window.bounds];
    self.routeOverlay.backgroundColor = UIColor.clearColor;
    self.routeOverlay.userInteractionEnabled = NO;
    self.routeOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.routeShadowLayer = [CAShapeLayer layer];
    self.routeShadowLayer.strokeColor = [UIColor colorWithWhite:0.0 alpha:0.72].CGColor;
    self.routeShadowLayer.fillColor = UIColor.clearColor.CGColor;
    self.routeShadowLayer.lineWidth = 7.0;
    self.routeShadowLayer.lineCap = kCALineCapRound;
    self.routeShadowLayer.lineJoin = kCALineJoinRound;
    [self.routeOverlay.layer addSublayer:self.routeShadowLayer];

    self.routeLineLayer = [CAShapeLayer layer];
    self.routeLineLayer.strokeColor = [UIColor colorWithRed:0.16 green:0.83 blue:1.0 alpha:0.95].CGColor;
    self.routeLineLayer.fillColor = UIColor.clearColor.CGColor;
    self.routeLineLayer.lineWidth = 3.0;
    self.routeLineLayer.lineCap = kCALineCapRound;
    self.routeLineLayer.lineJoin = kCALineJoinRound;
    [self.routeOverlay.layer addSublayer:self.routeLineLayer];
    [window addSubview:self.routeOverlay];

    self.routeDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateIslandRouteOverlay)];
    [self.routeDisplayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}
/*Russ 路线覆盖层：原版同样使用 displayLink、shadowLayer 和 routeLayer 双层路径*/

- (void)stopIslandRouteOverlay {
    [self.routeDisplayLink invalidate];
    self.routeDisplayLink = nil;
    self.routeShadowLayer.path = nil;
    self.routeLineLayer.path = nil;
    [self.routeOverlay removeFromSuperview];
    self.routeOverlay = nil;
    self.routeShadowLayer = nil;
    self.routeLineLayer = nil;
}
/*关闭时清路径并移除覆盖层，对齐原版 setRouteEnabled:NO*/

- (void)updateIslandRouteOverlay {
    if (self.routeOverlay == nil || self.routeLineLayer == nil || self.routeShadowLayer == nil) return;
    float worldPoints[512 * 3] = {0};
    NSUInteger pointCount = CopyIslandRouteWorldPoints(worldPoints, 512);
    Il2CppObject *camera = GetMainCameraObject();
    if (pointCount < 2 || camera == NULL) {
        self.routeShadowLayer.path = nil;
        self.routeLineLayer.path = nil;
        return;
    }

    CGFloat width = self.routeOverlay.bounds.size.width;
    CGFloat height = self.routeOverlay.bounds.size.height;
    UIBezierPath *path = [UIBezierPath bezierPath];
    BOOL hasSegment = NO;
    BOOL canContinue = NO;
    for (NSUInteger index = 0; index < pointCount; index++) {
        float sx = 0.0f, sy = 0.0f, depth = -1.0f;
        if (!ProjectWorldToScreen(camera, worldPoints[index * 3], worldPoints[index * 3 + 1], worldPoints[index * 3 + 2], &sx, &sy, &depth) ||
            depth <= 0.0f || sx < -width || sx > width * 2.0 || sy < -height || sy > height * 2.0) {
            canContinue = NO;
            continue;
        }
        CGPoint point = CGPointMake(sx, height - sy);
        if (!canContinue) [path moveToPoint:point];
        else [path addLineToPoint:point];
        canContinue = YES;
        hasSegment = YES;
    }
    CGPathRef renderedPath = hasSegment ? path.CGPath : nil;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.routeShadowLayer.frame = self.routeOverlay.bounds;
    self.routeLineLayer.frame = self.routeOverlay.bounds;
    self.routeShadowLayer.path = renderedPath;
    self.routeLineLayer.path = renderedPath;
    [CATransaction commit];
}
/*按原版 pointsList → 屏幕点的处理链实时绘制；无有效点或镜头后点会清空断开片段*/

- (void)stopCoffinMarkers {
    [self.coffinDisplayLink invalidate];
    self.coffinDisplayLink = nil;
    [self.coffinOverlay removeFromSuperview];
    self.coffinOverlay = nil;
    self.coffinMarkers = nil;
    if (self.coffinArrayHandle != 0 && gIl2CppGCHandleFree != NULL) {
        gIl2CppGCHandleFree(self.coffinArrayHandle);
    }
    self.coffinArrayHandle = 0;
    self.coffinArrayRaw = NULL;
}
/*棺材透视关闭 停帧移除overlay 释放数组gchandle */

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
    self.markerFrameTick++;
    if (self.markerFrameTick % 30 == 1 || self.coffinArrayRaw == NULL) {
        /* 重扫:先释放旧gchandle再钉住新数组 照原版gchandle_new/free防GC回收 */
        if (self.coffinArrayHandle != 0) {
            if (gIl2CppGCHandleFree != NULL) gIl2CppGCHandleFree(self.coffinArrayHandle);
            self.coffinArrayHandle = 0;
        }
        Il2CppArray *scanned = ScanObjectsOfTypeInNamespace("Qqpd.Modules.Scene", "UGCObjectCoffin", YES);
        self.coffinArrayRaw = scanned;
        if (scanned != NULL && gIl2CppGCHandleNew != NULL) {
            self.coffinArrayHandle = gIl2CppGCHandleNew((Il2CppObject *)scanned, NO);
        }
    }

    Il2CppArray *coffins = self.coffinArrayRaw;
    if (self.coffinArrayHandle != 0 && gIl2CppGCHandleGetTarget != NULL) {
        Il2CppObject *target = gIl2CppGCHandleGetTarget(self.coffinArrayHandle);
        if (target != NULL) coffins = (Il2CppArray *)target;
    }
    Il2CppObject *camera = GetMainCameraObject();
    if (camera == NULL) return;
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
/*每0.5s扫描ugcobjectcoffin(数组gchandle钉住) 每帧取坐标 worldtoscreen投影 橙框+距离文字 镜头后或出屏隐藏 */

- (void)restoreFeatureRuntime {
    if ([self anyFeatureActive]) {
        [self refreshEngineFrameRate];
    }
    if ([self.featureStates[@"coffin"] boolValue]) {
        [self startCoffinMarkers];
    }
    if ([self.featureStates[@"islandRoute"] boolValue]) {
        [self startIslandRouteOverlay];
    }
    CGFloat thirdFOV = [self sliderValueForKey:@"thirdPersonFOV"];
    CGFloat firstFOV = [self sliderValueForKey:@"firstPersonFOV"];
    BOOL wide = [self.featureStates[@"wide"] boolValue];
    ApplyCameraFollow((float)(wide ? 66.0 : thirdFOV), wide || thirdFOV != 75.0,
                      (float)firstFOV, firstFOV != 75.0);
    ApplyTimeScale([self sliderValueForKey:@"globalSpeed"]);
}
/*启动恢复 有功能开着引擎60帧维持(热更程序集加载后自动补上) 照原版restorefeatureruntime */

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
    self.highlightBrightness = 2.5;
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
