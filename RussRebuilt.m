#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#include <string.h>

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

typedef Il2CppDomain *(*Il2CppDomainGet)(void);
typedef Il2CppAssembly **(*Il2CppDomainGetAssemblies)(const Il2CppDomain *domain, size_t *size);
typedef const Il2CppImage *(*Il2CppAssemblyGetImage)(const Il2CppAssembly *assembly);
typedef void *(*Il2CppClassFromName)(const Il2CppImage *image, const char *namespaze, const char *name);
typedef const MethodInfo *(*Il2CppClassGetMethodFromName)(void *klass, const char *name, int argumentsCount);
typedef void *(*Il2CppClassGetFieldFromName)(void *klass, const char *name);
typedef void *(*Il2CppClassGetType)(void *klass);
typedef void *(*Il2CppTypeGetObject)(void *type);
typedef size_t (*Il2CppFieldGetOffset)(void *field);
typedef void (*Il2CppFieldSetValue)(void *object, void *field, void *value);
typedef Il2CppObject *(*Il2CppRuntimeInvoke)(const MethodInfo *method, void *object, void **parameters, Il2CppObject **exception);
typedef void *(*Il2CppThreadAttach)(Il2CppDomain *domain);

static Il2CppDomainGet gIl2CppDomainGet;
static Il2CppDomainGetAssemblies gIl2CppDomainGetAssemblies;
static Il2CppAssemblyGetImage gIl2CppAssemblyGetImage;
static Il2CppClassFromName gIl2CppClassFromName;
static Il2CppClassGetMethodFromName gIl2CppClassGetMethodFromName;
static Il2CppClassGetFieldFromName gIl2CppClassGetFieldFromName;
static Il2CppClassGetType gIl2CppClassGetType;
static Il2CppTypeGetObject gIl2CppTypeGetObject;
static Il2CppFieldGetOffset gIl2CppFieldGetOffset;
static Il2CppFieldSetValue gIl2CppFieldSetValue;
static Il2CppRuntimeInvoke gIl2CppRuntimeInvoke;
static Il2CppThreadAttach gIl2CppThreadAttach;

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
    gIl2CppClassGetType = (Il2CppClassGetType)dlsym(RTLD_DEFAULT, "il2cpp_class_get_type");
    gIl2CppTypeGetObject = (Il2CppTypeGetObject)dlsym(RTLD_DEFAULT, "il2cpp_type_get_object");
    gIl2CppFieldGetOffset = (Il2CppFieldGetOffset)dlsym(RTLD_DEFAULT, "il2cpp_field_get_offset");
    gIl2CppFieldSetValue = (Il2CppFieldSetValue)dlsym(RTLD_DEFAULT, "il2cpp_field_set_value");
    gIl2CppRuntimeInvoke = (Il2CppRuntimeInvoke)dlsym(RTLD_DEFAULT, "il2cpp_runtime_invoke");
    gIl2CppThreadAttach = (Il2CppThreadAttach)dlsym(RTLD_DEFAULT, "il2cpp_thread_attach");

    return gIl2CppDomainGet != NULL && gIl2CppDomainGetAssemblies != NULL &&
        gIl2CppAssemblyGetImage != NULL && gIl2CppClassFromName != NULL &&
        gIl2CppClassGetMethodFromName != NULL && gIl2CppRuntimeInvoke != NULL;
}

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

static const MethodInfo *FindMethod(void *klass, const char *name, int argumentCount) {
    if (klass == NULL || gIl2CppClassGetMethodFromName == NULL) return NULL;
    return gIl2CppClassGetMethodFromName(klass, name, argumentCount);
}

static void *FindField(void *klass, const char *name) {
    if (klass == NULL || gIl2CppClassGetFieldFromName == NULL) return NULL;
    return gIl2CppClassGetFieldFromName(klass, name);
}

static BOOL SetFloatField(void *object, void *klass, const char *name, float value) {
    void *field = FindField(klass, name);
    if (object == NULL || field == NULL || gIl2CppFieldSetValue == NULL || gIl2CppFieldGetOffset == NULL) return NO;
    if (gIl2CppFieldGetOffset(field) == (size_t)-1) return NO;
    gIl2CppFieldSetValue(object, field, &value);
    return YES;
}

static BOOL InvokeFloatSetter(void *object, void *klass, const char *name, float value) {
    const MethodInfo *method = FindMethod(klass, name, 1);
    if (method == NULL || gIl2CppRuntimeInvoke == NULL) return NO;
    Il2CppObject *exception = NULL;
    void *arguments[] = { &value };
    gIl2CppRuntimeInvoke(method, object, arguments, &exception);
    return exception == NULL;
}

static void ApplyCameraFollow(float thirdPersonFov, float firstPersonFov) {
    void *klass = FindClass("UpdateScript_500.dll", "", "CameraFollow");
    if (klass == NULL || gIl2CppClassGetMethodFromName == NULL) return;
    const MethodInfo *getInstance = FindMethod(klass, "get_instance", 0);
    Il2CppObject *exception = NULL;
    Il2CppObject *instance = getInstance ? gIl2CppRuntimeInvoke(getInstance, NULL, NULL, &exception) : NULL;
    if (instance == NULL || exception != NULL) return;

    float firstValue = (float)MAX(30.0, MIN(170.0, firstPersonFov));
    float thirdValue = (float)MAX(30.0, MIN(170.0, thirdPersonFov));
    SetFloatField(instance, klass, "UGC2FirstFOV", firstValue);
    SetFloatField(instance, klass, "UGC2FOV", thirdValue);
    InvokeFloatSetter(instance, klass, "set_FOV", thirdValue);
}

static void ApplyCameraDistance(float distance) {
    void *klass = FindClass("UpdateScript_500.dll", "", "CameraFollow");
    if (klass == NULL || gIl2CppRuntimeInvoke == NULL) return;
    const MethodInfo *getInstance = FindMethod(klass, "get_instance", 0);
    if (getInstance == NULL) return;
    Il2CppObject *exception = NULL;
    Il2CppObject *instance = gIl2CppRuntimeInvoke(getInstance, NULL, NULL, &exception);
    if (instance == NULL || exception != NULL) return;
    float value = (float)MAX(0.5, MIN(100.0, distance));
    if (InvokeFloatSetter(instance, klass, "set_Distance", value)) return;
    if (InvokeFloatSetter(instance, klass, "set_Radius", value)) return;
    SetFloatField(instance, klass, "UGC2Distance", value);
    SetFloatField(instance, klass, "Distance", value);
    SetFloatField(instance, klass, "Radius", value);
}

static void ApplyTimeScale(float multiplier) {
    void *klass = FindClass("UnityEngine.CoreModule.dll", "UnityEngine", "Time");
    if (klass == NULL) klass = FindClass("UnityEngine.dll", "UnityEngine", "Time");
    if (klass == NULL) return;
    float value = (float)MAX(0.1, MIN(10.0, multiplier));
    InvokeFloatSetter(NULL, klass, "set_timeScale", value);
}

static void ApplyRouteVisibility(BOOL enabled) {
    if (!ResolveIl2Cpp() || gIl2CppClassGetType == NULL || gIl2CppTypeGetObject == NULL) return;
    void *lineClass = FindClass("UnityEngine.CoreModule.dll", "UnityEngine", "LineRenderer");
    if (lineClass == NULL) lineClass = FindClass("UnityEngine.dll", "UnityEngine", "LineRenderer");
    if (lineClass == NULL) return;
    void *type = gIl2CppClassGetType(lineClass);
    Il2CppObject *typeObject = type != NULL ? (Il2CppObject *)gIl2CppTypeGetObject(type) : NULL;
    void *objectClass = FindClass("UnityEngine.CoreModule.dll", "UnityEngine", "Object");
    if (objectClass == NULL) objectClass = FindClass("UnityEngine.dll", "UnityEngine", "Object");
    const MethodInfo *findObjects = FindMethod(objectClass, "FindObjectsOfType", 1);
    const MethodInfo *setEnabled = FindMethod(lineClass, "set_enabled", 1);
    if (typeObject == NULL || findObjects == NULL || setEnabled == NULL) return;
    void *arguments[] = { typeObject };
    Il2CppObject *exception = NULL;
    Il2CppArray *objects = (Il2CppArray *)gIl2CppRuntimeInvoke(findObjects, NULL, arguments, &exception);
    if (objects == NULL || exception != NULL) return;
    BOOL value = enabled;
    for (uintptr_t index = 0; index < objects->maxLength; index++) {
        if (objects->objects[index] == NULL) continue;
        void *setterArguments[] = { &value };
        exception = NULL;
        gIl2CppRuntimeInvoke(setEnabled, objects->objects[index], setterArguments, &exception);
    }
}

static void ReapplyRuntimeValues(float firstFov, float thirdFov, float distance, float speed, BOOL routeEnabled) {
    ApplyCameraFollow(thirdFov, firstFov);
    ApplyCameraDistance(distance);
    ApplyTimeScale(speed);
    ApplyRouteVisibility(routeEnabled);
}

static void ApplyFieldOfView(CGFloat fieldOfView) {
    if (!ResolveIl2Cpp()) {
        return;
    }

    Il2CppDomain *domain = gIl2CppDomainGet();
    if (domain == NULL) {
        return;
    }
    if (gIl2CppThreadAttach != NULL) {
        gIl2CppThreadAttach(domain);
    }

    size_t assemblyCount = 0;
    Il2CppAssembly **assemblies = gIl2CppDomainGetAssemblies(domain, &assemblyCount);
    void *cameraClass = NULL;
    for (size_t index = 0; index < assemblyCount && cameraClass == NULL; index++) {
        const Il2CppImage *image = gIl2CppAssemblyGetImage(assemblies[index]);
        cameraClass = gIl2CppClassFromName(image, "UnityEngine", "Camera");
    }
    if (cameraClass == NULL) {
        return;
    }

    const MethodInfo *allCameras = gIl2CppClassGetMethodFromName(cameraClass, "get_allCameras", 0);
    const MethodInfo *setFieldOfView = gIl2CppClassGetMethodFromName(cameraClass, "set_fieldOfView", 1);
    if (allCameras == NULL || setFieldOfView == NULL) {
        return;
    }

    Il2CppObject *exception = NULL;
    Il2CppArray *cameras = (Il2CppArray *)gIl2CppRuntimeInvoke(allCameras, NULL, NULL, &exception);
    if (exception != NULL || cameras == NULL) {
        return;
    }

    float value = (float)MAX(45.0, MIN(120.0, fieldOfView));
    void *arguments[] = { &value };
    for (uintptr_t index = 0; index < cameras->maxLength; index++) {
        if (cameras->objects[index] != NULL) {
            exception = NULL;
            gIl2CppRuntimeInvoke(setFieldOfView, cameras->objects[index], arguments, &exception);
        }
    }
}

@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *floatingButton;
@property(nonatomic, assign) CGFloat firstPersonFOV;
@property(nonatomic, assign) CGFloat thirdPersonFOV;
@property(nonatomic, assign) CGFloat speedMultiplier;
@property(nonatomic, assign) CGFloat cameraDistance;
@property(nonatomic, assign) BOOL routeEnabled;
@property(nonatomic, strong) NSTimer *refreshTimer;
@end

@implementation RussOverlayController

- (void)install {
    [self loadSettings];

    if (self.refreshTimer == nil) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(reapplyRuntimeValues) userInfo:nil repeats:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
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
        [window addSubview:self.floatingButton];

        [self buildPanelInWindow:window];
        [self reapplyRuntimeValues];
    });
}

- (void)buildPanelInWindow:(UIWindow *)window {
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(84.0, 130.0, 280.0, 370.0)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
    self.panel.layer.cornerRadius = 8.0;
    self.panel.hidden = YES;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 14.0, 210.0, 26.0)];
    title.text = @"视角调试";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:17.0];
    [self.panel addSubview:title];

    [self addSliderWithTitle:@"第一人称 FOV" value:self.firstPersonFOV minimum:30.0 maximum:170.0 y:54.0 action:@selector(firstPersonFOVChanged:)];
    [self addSliderWithTitle:@"第三人称 FOV" value:self.thirdPersonFOV minimum:30.0 maximum:170.0 y:120.0 action:@selector(thirdPersonFOVChanged:)];
    [self addSliderWithTitle:@"速度倍率（待适配）" value:self.speedMultiplier minimum:0.5 maximum:3.0 y:186.0 action:@selector(speedChanged:)];

    [self addSliderWithTitle:@"Camera Distance" value:self.cameraDistance minimum:0.5 maximum:30.0 y:252.0 action:@selector(cameraDistanceChanged:)];

    UISwitch *routeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 316.0, 0.0, 0.0)];
    routeSwitch.on = self.routeEnabled;
    [routeSwitch addTarget:self action:@selector(routeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:routeSwitch];

    UILabel *routeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 318.0, 150.0, 28.0)];
    routeLabel.text = @"路线显示（待适配）";
    routeLabel.textColor = UIColor.whiteColor;
    routeLabel.font = [UIFont systemFontOfSize:14.0];
    [self.panel addSubview:routeLabel];
    [window addSubview:self.panel];
}

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

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
}

- (void)firstPersonFOVChanged:(UISlider *)sender { self.firstPersonFOV = sender.value; [self saveSettings]; [self reapplyRuntimeValues]; }
- (void)thirdPersonFOVChanged:(UISlider *)sender { self.thirdPersonFOV = sender.value; [self saveSettings]; [self reapplyRuntimeValues]; }
- (void)speedChanged:(UISlider *)sender { self.speedMultiplier = sender.value; [self saveSettings]; ApplyTimeScale(self.speedMultiplier); }
- (void)cameraDistanceChanged:(UISlider *)sender { self.cameraDistance = sender.value; [self saveSettings]; ApplyCameraDistance(self.cameraDistance); }
- (void)routeChanged:(UISwitch *)sender { self.routeEnabled = sender.isOn; [self saveSettings]; ApplyRouteVisibility(self.routeEnabled); }

- (void)reapplyRuntimeValues {
    ReapplyRuntimeValues((float)self.firstPersonFOV, (float)self.thirdPersonFOV, (float)self.cameraDistance, (float)self.speedMultiplier, self.routeEnabled);
}

- (void)loadSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.firstPersonFOV = [defaults objectForKey:@"russ.firstFOV"] ? [defaults floatForKey:@"russ.firstFOV"] : 75.0;
    self.thirdPersonFOV = [defaults objectForKey:@"russ.thirdFOV"] ? [defaults floatForKey:@"russ.thirdFOV"] : 75.0;
    self.speedMultiplier = [defaults objectForKey:@"russ.speed"] ? [defaults floatForKey:@"russ.speed"] : 1.0;
    self.cameraDistance = [defaults objectForKey:@"russ.distance"] ? [defaults floatForKey:@"russ.distance"] : 8.0;
    self.routeEnabled = [defaults boolForKey:@"russ.route"];
}

- (void)saveSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setFloat:self.firstPersonFOV forKey:@"russ.firstFOV"];
    [defaults setFloat:self.thirdPersonFOV forKey:@"russ.thirdFOV"];
    [defaults setFloat:self.speedMultiplier forKey:@"russ.speed"];
    [defaults setFloat:self.cameraDistance forKey:@"russ.distance"];
    [defaults setBool:self.routeEnabled forKey:@"russ.route"];
}

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
