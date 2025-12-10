#import <UIKit/UIKit.h>
#import <spawn.h>
#import <sys/wait.h>

extern char **environ;

// 执行 Shell 命令
static void run_cmd(const char *cmd) {
    pid_t pid;
    const char *argv[] = {"sh", "-c", cmd, NULL};
    int status = 0;
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char * const *)argv, environ);
    waitpid(pid, &status, 0);
}

// 找一个可用的 window
static UIWindow *ac_mainWindow(void) {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow) return keyWindow;

    for (UIWindow *win in [UIApplication sharedApplication].windows) {
        if (win.isKeyWindow) return win;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

// 弹窗提示
static void show_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = ac_mainWindow();
        UIViewController *rootVC = window.rootViewController;
        if (!rootVC) return;

        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"清理助手"
                                                message:msg
                                         preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好的"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

// 悬浮球类
@interface FloatyButton : UIButton
@end

@implementation FloatyButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.masksToBounds = YES;
        [self setTitle:@"清" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];

        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)handleTap {
    // 1. 杀掉 Filza
    run_cmd("killall Filza 2>/dev/null");

    // 2. 清理缓存
    run_cmd("rm -rf /var/mobile/Library/Caches/*");
    run_cmd("rm -rf /var/mobile/Library/Cookies/*");
    run_cmd("rm -rf /var/mobile/Library/SplashBoard/*");
    run_cmd("rm -rf /var/log/*");

    // 3. 调起巨魔安装 IPA
    NSString *ipaPath = @"/var/mobile/media/downloads/3.86改5.11-18.6.ipa";
    NSString *urlStr =
        [NSString stringWithFormat:@"apple-magnifier://install?url=file://%@", ipaPath];
    NSURL *url = [NSURL URLWithString:urlStr];

    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        show_alert(@"清理完成，正在调起巨魔安装...");
    } else {
        NSString *cmd =
            [NSString stringWithFormat:
                 "uiopen 'apple-magnifier://install?url=file://%@'", ipaPath];
        run_cmd([cmd UTF8String]);
        show_alert(@"已执行清理。如果未自动跳转，请检查巨魔 URL Scheme。");
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)p {
    UIWindow *window = ac_mainWindow();
    CGPoint panPoint = [p locationInView:window];

    if (p.state == UIGestureRecognizerStateChanged) {
        self.center = panPoint;
    } else if (p.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            self.center = CGPointMake(30, panPoint.y);
        }];
    }
}

@end

// 注入 SpringBoard
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIWindow *window = ac_mainWindow();
        if (!window) return;

        FloatyButton *btn = [[FloatyButton alloc] initWithFrame:CGRectMake(30, 300, 50, 50)];
        [window addSubview:btn];
    });
}
%end
