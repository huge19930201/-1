#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/************************************************************
 *  微信输入法工具栏 + 键盘美化（全新实现，不含任何授权/激活代码）
 *  - 工具栏：在功能栏顶部叠加自定义按钮条（你好/谢谢/换行/删除）
 *  - 键盘美化：对微信输入法按键做圆角 / 边框 / 背景 / 阴影美化
 *  仅注入微信输入法键盘扩展 (com.tencent.wetype.keyboard)
 ************************************************************/

#pragma mark - 可自由调节的美化参数
static CGFloat kKeyCornerRadius = 8.0;     // 按键圆角
static CGFloat kKeyBorderWidth  = 1.0;     // 边框粗细
static CGFloat kKeyBorderAlpha  = 0.35;    // 边框透明度
static CGFloat kKeyBgAlpha      = 0.85;    // 按键背景透明度
static CGFloat kKeyShadowRadius = 3.0;     // 阴影模糊半径
static CGFloat kKeyShadowAlpha  = 0.25;    // 阴影透明度
static CGFloat kKeyShadowOffX   = 0.0;     // 阴影 X 偏移
static CGFloat kKeyShadowOffY   = 1.0;     // 阴影 Y 偏移

// 给一个按键视图应用美化
static void ApplyKeyAppearance(UIView *view) {
    if (!view) return;
    CALayer *layer = view.layer;
    layer.cornerRadius  = kKeyCornerRadius;
    layer.borderWidth   = kKeyBorderWidth;
    UIColor *border = [[UIColor labelColor] colorWithAlphaComponent:kKeyBorderAlpha];
    layer.borderColor   = border.CGColor;

    // 阴影（注意：需要 masksToBounds=NO 才能显示）
    layer.masksToBounds = NO;
    layer.shadowRadius  = kKeyShadowRadius;
    layer.shadowOpacity = (float)kKeyShadowAlpha;
    layer.shadowOffset  = CGSizeMake(kKeyShadowOffX, kKeyShadowOffY);
    layer.shadowColor   = [UIColor blackColor].CGColor;

    if (view.backgroundColor) {
        view.backgroundColor = [view.backgroundColor colorWithAlphaComponent:kKeyBgAlpha];
    }
}

#pragma mark - 工具栏按钮条
@interface WXKBEnhancerBar : UIView
- (void)layoutInHost:(UIView *)host;
@end

@implementation WXKBEnhancerBar

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.96];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self buildButtons];
    }
    return self;
}

- (void)buildButtons {
    NSArray *titles = @[@"你好", @"谢谢", @"换行", @"删除"];
    NSMutableArray *btns = [NSMutableArray array];
    for (NSString *t in titles) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:t forState:UIControlStateNormal];
        [b addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];
        b.titleLabel.font = [UIFont systemFontOfSize:14];
        b.tag = [titles indexOfObject:t];
        b.frame = CGRectMake(0, 0, 56, 36);
        [self addSubview:b];
        [btns addObject:b];
    }
    CGFloat x = 8;
    for (UIButton *b in btns) {
        b.frame = CGRectMake(x, 2, 56, 32);
        x += 60;
    }
    self.frame = CGRectMake(0, 0, x, 36);
}

- (UIInputViewController *)keyboardVC {
    UIResponder *r = self;
    while (r) {
        if ([r isKindOfClass:[UIInputViewController class]]) return (UIInputViewController *)r;
        r = [r nextResponder];
    }
    return nil;
}

- (void)onTap:(UIButton *)sender {
    UIInputViewController *kb = [self keyboardVC];
    if (!kb) return;
    id proxy = kb.textDocumentProxy;
    switch (sender.tag) {
        case 0: [proxy insertText:@"你好 "]; break;
        case 1: [proxy insertText:@"谢谢 "]; break;
        case 2: [proxy insertText:@"\n"];    break;
        case 3: [proxy deleteBackward];       break;
        default: break;
    }
}

- (void)layoutInHost:(UIView *)host {
    CGRect f = self.frame;
    f.origin.y = 0; f.origin.x = 0;
    f.size.width = host.bounds.size.width;
    self.frame = f;
    [host bringSubviewToFront:self];
}

@end

#pragma mark - Hook 微信输入法
static void *kEnhancerBarKey = &kEnhancerBarKey;

%group WeTypeKeyboard

// ---- 功能栏顶部加按钮条 ----
%hook WBFunctionToolBar
- (void)layoutSubviews {
    %orig;
    WXKBEnhancerBar *bar = objc_getAssociatedObject(self, kEnhancerBarKey);
    if (!bar) {
        bar = [[WXKBEnhancerBar alloc] init];
        objc_setAssociatedObject(self, kEnhancerBarKey, bar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self addSubview:bar];
    }
    [bar layoutInHost:self];
}
%end

%hook WBTopBar
- (void)layoutSubviews {
    %orig;
    WXKBEnhancerBar *bar = objc_getAssociatedObject(self, kEnhancerBarKey);
    if (!bar) {
        bar = [[WXKBEnhancerBar alloc] init];
        objc_setAssociatedObject(self, kEnhancerBarKey, bar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self addSubview:bar];
    }
    [bar layoutInHost:self];
}
%end

// ---- 按键外观美化（WBKeyView / WBSecKeyboardKeyView / WBKeyViewItem）----
%hook WBKeyView
- (void)layoutSubviews {
    %orig;
    ApplyKeyAppearance(self);
}
%end

%hook WBSecKeyboardKeyView
- (void)layoutSubviews {
    %orig;
    ApplyKeyAppearance(self);
}
%end

%hook WBKeyViewItem
- (void)layoutSubviews {
    %orig;
    ApplyKeyAppearance(self);
}
%end

%end

%ctor {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleId isEqualToString:@"com.tencent.wetype.keyboard"]) {
        %init(WeTypeKeyboard);
    }
}
