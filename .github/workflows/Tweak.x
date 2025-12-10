#import <UIKit/UIKit.h>
#import <spawn.h>
#import <sys/wait.h>

extern char **environ;

// 执行Shell命令
void run_cmd(const char *cmd) {
    pid_t pid;
    const char *argv[] = {"sh", "-c", cmd, NULL};
    int status;
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char* const*)argv, environ);
    waitpid(pid, &status, 0);
}

// 弹窗提示
void show_alert(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIViewController *rootVC = keyWindow.rootViewController;
        if (rootVC) {
             UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清理助手" message:msg preferredStyle:UIAlertControllerStyleAlert];
             [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
             [rootVC presentViewController:alert animated:YES completion:nil];
        }
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
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        [self setTitle:@"清" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)handleTap {
    // 1. 杀掉Filza
    run_cmd("killall Filza");
    
    // 2. 强力清理缓存 (模拟 varClean)
    run_cmd("rm -rf /var/mobile/Library/Caches/*");
    run_cmd("rm -rf /var/mobile/Library/Cookies/*");
    run_cmd("rm -rf /var/mobile/Library/SplashBoard/*");
    run_cmd("rm -rf /var/log/*");
    
    // 3. 安装 IPA
    NSString *ipaPath = @"/var/mobile/media/downloads/3.86改5.11-18.6.ipa";
    
    // 生成 TrollStore 安装链接
    NSString *urlStr = [NSString stringWithFormat:@"apple-magnifier://install?url=file://%@", ipaPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
         [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
         show_alert(@"清理完成，正在调起巨魔安装...");
    } else {
        // 尝试备用方案
        NSString *cmd = [NSString stringWithFormat:@"uiopen 'apple-magnifier://install?url=file://%@'", ipaPath];
        run_cmd([cmd UTF8String]);
        show_alert(@"已执行清理。如果在 iOS 16 上未自动跳转，请检查巨魔 URL Scheme 设置。");
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)p {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGPoint panPoint = [p locationInView:window];
    
    if (p.state == UIGestureRecognizerStateChanged) {
        self.center = panPoint;
    } else if (p.state == UIGestureRecognizerStateEnded) {
        // 自动吸附到左侧
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
    
    // 延时加载，确保不卡开机
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            FloatyButton *btn = [[FloatyButton alloc] initWithFrame:CGRectMake(30, 300, 50, 50)];
            [window addSubview:btn];
        }
    });
}
%end
