#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RussOverlayController : NSObject
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *floatingButton;
@property(nonatomic, assign) CGFloat firstPersonFOV;
@property(nonatomic, assign) CGFloat thirdPersonFOV;
@property(nonatomic, assign) CGFloat speedMultiplier;
@property(nonatomic, assign) BOOL routeEnabled;
@end

@implementation RussOverlayController

- (void)install {
    [self loadSettings];

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
    });
}

- (void)buildPanelInWindow:(UIWindow *)window {
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(84.0, 130.0, 250.0, 300.0)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.94];
    self.panel.layer.cornerRadius = 8.0;
    self.panel.hidden = YES;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 14.0, 210.0, 26.0)];
    title.text = @"Russ Rebuilt";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:17.0];
    [self.panel addSubview:title];

    [self addSliderWithTitle:@"First-person FOV" value:self.firstPersonFOV minimum:45.0 maximum:120.0 y:54.0 action:@selector(firstPersonFOVChanged:)];
    [self addSliderWithTitle:@"Third-person FOV" value:self.thirdPersonFOV minimum:45.0 maximum:120.0 y:120.0 action:@selector(thirdPersonFOVChanged:)];
    [self addSliderWithTitle:@"Speed" value:self.speedMultiplier minimum:0.5 maximum:3.0 y:186.0 action:@selector(speedChanged:)];

    UISwitch *routeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(172.0, 250.0, 0.0, 0.0)];
    routeSwitch.on = self.routeEnabled;
    [routeSwitch addTarget:self action:@selector(routeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.panel addSubview:routeSwitch];

    UILabel *routeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 252.0, 150.0, 28.0)];
    routeLabel.text = @"Route overlay";
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

- (void)firstPersonFOVChanged:(UISlider *)sender { self.firstPersonFOV = sender.value; [self saveSettings]; }
- (void)thirdPersonFOVChanged:(UISlider *)sender { self.thirdPersonFOV = sender.value; [self saveSettings]; }
- (void)speedChanged:(UISlider *)sender { self.speedMultiplier = sender.value; [self saveSettings]; }
- (void)routeChanged:(UISwitch *)sender { self.routeEnabled = sender.isOn; [self saveSettings]; }

- (void)loadSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.firstPersonFOV = [defaults objectForKey:@"russ.firstFOV"] ? [defaults floatForKey:@"russ.firstFOV"] : 75.0;
    self.thirdPersonFOV = [defaults objectForKey:@"russ.thirdFOV"] ? [defaults floatForKey:@"russ.thirdFOV"] : 75.0;
    self.speedMultiplier = [defaults objectForKey:@"russ.speed"] ? [defaults floatForKey:@"russ.speed"] : 1.0;
    self.routeEnabled = [defaults boolForKey:@"russ.route"];
}

- (void)saveSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setFloat:self.firstPersonFOV forKey:@"russ.firstFOV"];
    [defaults setFloat:self.thirdPersonFOV forKey:@"russ.thirdFOV"];
    [defaults setFloat:self.speedMultiplier forKey:@"russ.speed"];
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
