#import <UIKit/UIKit.h>
#import <spawn.h>

// 声明外部变量
extern char **environ;

// 执行命令的工具函数
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
             UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AutoCleaner" message:msg preferredStyle:UIAlertControllerStyleAlert];
             [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
             [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// 悬浮按钮类
@interface FloatyButton : UIButton
@end

@implementation FloatyButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8]; // 蓝色半透明
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        [self setTitle:@"清" forState:UIControlStateNormal];
        
        // 点击事件
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        // 拖拽手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)handleTap {
    // 1. 杀掉Filza
    run_cmd("killall Filza");
    
    // 2. 清理缓存 (对应你的图3路径)
    run_cmd("rm -rf /var/mobile/Library/Caches/*");
    run_cmd("rm -rf /var/mobile/Library/Cookies/*");
    run_cmd("rm -rf /var/mobile/Library/SplashBoard/*");
    // 这里添加更多你想清理的路径，比如 roothide 的 varclean 可能会清理的全部目录
    
    // 3. 安装IPA
    NSString *ipaPath = @"/var/mobile/media/downloads/3.86改5.11-18.6.ipa";
    
    // 尝试使用 TrollStore URL Scheme 安装
    // 注意：不同版本的巨魔 URL Scheme 不同，这里尝试最通用的 apple-magnifier
    NSString *urlStr = [NSString stringWithFormat:@"apple-magnifier://install?url=file://%@", ipaPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
         [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
         show_alert(@"已清理缓存，正在调起巨魔安装...");
    } else {
        // 如果失败，尝试用 uiopen 命令
        NSString *cmd = [NSString stringWithFormat:@"uiopen 'apple-magnifier://install?url=file://%@'", ipaPath];
        run_cmd([cmd UTF8String]);
        show_alert(@"尝试命令行安装，请观察巨魔是否弹出。");
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

// Hook SpringBoard (桌面)
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    // 延时5秒显示，确保桌面加载完毕
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            FloatyButton *btn = [[FloatyButton alloc] initWithFrame:CGRectMake(0, 300, 60, 60)];
            [window addSubview:btn];
            
            // 初始吸附动画
            [UIView animateWithDuration:0.5 animations:^{
                btn.center = CGPointMake(30, 300);
            }];
        }
    });
}
%end
