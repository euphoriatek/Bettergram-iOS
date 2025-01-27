#import "TGTabBarViewController.h"

#import <LegacyComponents/LegacyComponents.h>

#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>

#import "TGAppDelegate.h"
#import "TGDebugController.h"

#import "TGCryptoTabViewController.h"

#import "TGPresentation.h"

@protocol TGTabBarDelegate <NSObject>

- (void)tabBarSelectedItem:(int)index;
- (void)tabBarLongPressedItem:(int)index;

@end


@interface TGTabBarBadge : UIView
{
    UIImageView *_backgroundView;
    UILabel *_label;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) int count;

@end

@implementation TGTabBarBadge

static CGFloat kHeight = 18;

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    self = [super initWithFrame:CGRectMake(0, 0, kHeight, kHeight)];
    if (self != nil)
    {
        self.hidden = true;
        self.userInteractionEnabled = false;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        _backgroundView = [[UIImageView alloc] init];
        [self addSubview:_backgroundView];
        
        _label = [[UILabel alloc] init];
        _label.text = @"1";
        _label.text = nil;
        _label.backgroundColor = [UIColor clearColor];
        _label.font = TGBoldSystemFontOfSize(10);
        _label.textAlignment = NSTextAlignmentCenter;
        [_label sizeToFit];
        [self addSubview:_label];
        
        [self setPresentation:presentation];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _backgroundView.image = presentation.images.tabBarBadgeImage;
    _label.textColor = presentation.pallete.tabBadgeTextColor;
}

- (void)setCount:(int)count
{
    _count = count;
    if (count <= 0)
    {
        self.hidden = true;
    }
    else
    {
        NSString *text = nil;
        
        if (TGIsLocaleArabic())
        {
            text = [TGStringUtils stringWithLocalizedNumber:count];
        }
        else
        {
            if (count < 1000)
                text = [[NSString alloc] initWithFormat:@"%d", count];
            else if (count < 1000000)
                text = [[NSString alloc] initWithFormat:@"%dK", count / 1000];
            else
                text = [[NSString alloc] initWithFormat:@"%dM", count / 1000000];
        }
        
        _label.text = text;
        [_label sizeToFit];
        self.hidden = text.length == 0;
        
        CGRect frame = _backgroundView.frame;
        CGFloat textWidth = ceil(_label.frame.size.width);
        frame.size.width = MAX(kHeight, textWidth + 10);
        frame.size.height = kHeight;
        frame.origin.x = _backgroundView.superview.frame.size.width - frame.size.width;
        frame.origin.y = 0;
        _backgroundView.frame = frame;
        
        _label.center = _backgroundView.center;
    }
}

@end

@implementation TGTabBarButtonInfo

- (instancetype)initWithIconIcon:(UIImage *)icon title:(NSString *)title accessibilityTitle:(NSString *)accessibilityTitle
{
    if (self = [super init]) {
        _icon = icon;
        _title = title;
        _accessibilityTitle = accessibilityTitle;
    }
    return self;
}

+ (instancetype)infoWithIcon:(UIImage *)icon
{
    return [[TGTabBarButtonInfo alloc] initWithIconIcon:icon title:nil accessibilityTitle:nil];
}

+ (instancetype)infoWithIcon:(UIImage *)icon title:(NSString *)title
{
    return [[TGTabBarButtonInfo alloc] initWithIconIcon:icon title:title accessibilityTitle:title];
}

+ (instancetype)infoWithIcon:(UIImage *)icon accessibilityTitle:(NSString *)accessibilityTitle
{
    return [[TGTabBarButtonInfo alloc] initWithIconIcon:icon title:nil accessibilityTitle:accessibilityTitle];
}

@end

@interface TGTabBarButton : UIView
{
    TGPresentation *_presentation;
    UILabel *_label;
    UIView *_underscoreView;
}

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, assign, getter=isSelected) bool selected;
@property (nonatomic, assign) bool landscape;

@property (nonatomic, assign) int unreadCount;
@property (nonatomic, strong) TGTabBarBadge *badge;

@end

@implementation TGTabBarButton

- (instancetype)initWithInfo:(TGTabBarButtonInfo *)info isBarBarOnTop:(BOOL)isBarBarOnTop
{
    self = [super init];
    if (self != nil)
    {
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.accessibilityLabel = info.accessibilityTitle;
        
        _imageView = [[UIImageView alloc] initWithImage:info.icon];
        [self addSubview:_imageView];
        
        if (info.title != nil) {
            _label = [[UILabel alloc] init];
            _label.backgroundColor = [UIColor clearColor];
            _label.font = [TGTabBarButton labelFont];
            _label.text = info.title;
            _label.textAlignment = NSTextAlignmentLeft;
            [_label sizeToFit];
            [self addSubview:_label];
        }
        if (isBarBarOnTop) {
            _underscoreView = [[UIView alloc] init];
            [self addSubview:_underscoreView];
        }
    }
    return self;
}

- (void)setImage:(UIImage *)image presentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    _imageView.image = TGTintedImage(image, presentation.pallete.tabIconColor);
    if (_imageView.highlighted)
    {
        _imageView.highlightedImage = TGTintedImage(image, presentation.pallete.tabActiveIconColor);
        _imageView.highlighted = false;
        _imageView.highlighted = true;
    }
    else
        _imageView.highlightedImage = nil;
    [_badge setPresentation:presentation];
    
    _label.textColor = presentation.pallete.tabTextColor;
    _label.highlightedTextColor = presentation.pallete.tabActiveIconColor;
    _underscoreView.backgroundColor = presentation.pallete.tabActiveIconColor;
}

- (void)setSelected:(bool)selected
{
    _selected = selected;
    if (_imageView.highlightedImage == nil && selected)
        _imageView.highlightedImage = TGTintedImage(_imageView.image, _presentation.pallete.tabActiveIconColor);
    _imageView.highlighted = selected;
    _underscoreView.hidden = !selected;
    _label.highlighted = selected;
}

- (void)setUnreadCount:(int)unreadCount {
    if (_unreadCount == unreadCount) return;
    _unreadCount = unreadCount;
    if (unreadCount > 0 && _badge == nil) {
        _badge = [[TGTabBarBadge alloc] initWithPresentation:_presentation];
        [self addSubview:_badge];
        [self.superview setNeedsLayout];
    }
    _badge.count = _unreadCount;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGAffineTransform transform = _landscape ? CGAffineTransformMakeScale(2.0/3, 2.0/3) : CGAffineTransformIdentity;
    if (!CGAffineTransformEqualToTransform(transform, _imageView.transform)) {
        [UIView animateWithDuration:0.2 animations:^
         {
             _imageView.transform = transform;
         }];
    }
    
    if (_label != nil) {
        _label.font = self.landscape ? [TGTabBarButton landscapeLabelFont] : [TGTabBarButton labelFont];
        if (_landscape) {
            CGRect labelFrame = CGRectZero;
            labelFrame.size = [_label sizeThatFits:CGSizeZero];
            
            CGRect imageViewFrame = _imageView.frame;
            imageViewFrame.origin.y = (self.frame.size.height - imageViewFrame.size.height) / 2;
            imageViewFrame.origin.x = (self.frame.size.width - (imageViewFrame.size.width + labelFrame.size.width + 5)) / 2;
            _imageView.frame = imageViewFrame;
            
            labelFrame.origin.y = (self.frame.size.height - labelFrame.size.height) / 2;
            labelFrame.origin.x = CGRectGetMaxX(imageViewFrame) + 5;
            _label.frame = labelFrame;
        }
        else {
            {
                CGRect frame = _imageView.frame;
                frame.origin.y = 10;
                frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
                _imageView.frame = frame;
            }{
                CGRect frame = CGRectZero;
                frame.size = [_label sizeThatFits:CGSizeZero];
                frame.origin.y = self.frame.size.height - frame.size.height - 10;
                frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
                _label.frame = frame;
            }
        }
    }
    else {
        _imageView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    }
    
    if (_badge != nil)
    {
        _badge.transform = transform;
        CGRect badgeFrame = _badge.frame;
        badgeFrame.origin.x = MIN(_imageView.frame.origin.x + _imageView.frame.size.width * 2/3, self.frame.size.width - badgeFrame.size.width - 1);
        badgeFrame.origin.y = MAX(_imageView.frame.origin.y + _imageView.frame.size.height / 3 - badgeFrame.size.height, 1);
        _badge.frame = badgeFrame;
    }{
        CGRect frame = CGRectZero;
        frame.size.height = 2;
        if (_landscape) {
            frame.origin.x = CGRectGetMinX(_imageView.frame);
            frame.size.width = CGRectGetMaxX((_label ?: _imageView).frame) - frame.origin.x;
        }
        else {
            frame.size.width = MAX(_imageView.frame.size.width, _label.frame.size.width);
            frame.origin.x = (self.frame.size.width - frame.size.width) / 2;
        }
        frame.origin.y = self.frame.size.height - frame.size.height;
        _underscoreView.frame = frame;
    }
}

- (void)setLandscape:(bool)landscape
{
    if (_landscape != landscape)
    {
        _landscape = landscape;
        [self setNeedsLayout];
    }
}

- (CGFloat)labelVerticalOffset
{
    static CGFloat offset = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      if (!TGIsPad())
                          offset = 35 - TGScreenPixel;
                      else
                          offset = 36;
                  });
    return offset;
}

+ (UIFont *)labelFont
{
    static UIFont *font = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      if (!TGIsPad())
                          font = TGSystemFontOfSize(10);
                      else
                          font = TGSystemFontOfSize(11);
                  });
    return font;
}

+ (UIFont *)landscapeLabelFont
{
    static UIFont *font = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      font = TGSystemFontOfSize(12);
                  });
    return font;
}

@end


@interface TGTabBar : UIView <UIGestureRecognizerDelegate>
{
    bool _skipNextLayout;
    BOOL _isBarBarOnTop;
}

@property (nonatomic, weak) id<TGTabBarDelegate> tabDelegate;
@property (nonatomic, strong) UIView *stripeView;

@property (nonatomic, strong) NSArray<TGTabBarButton *> *tabButtons;

@property (nonatomic, assign) UIEdgeInsets safeAreaInset;
@property (nonatomic, assign) bool landscape;

@property (nonatomic) int selectedIndex;

@property (nonatomic, copy) NSArray<NSNumber *> *unreadCounts;

@property (nonatomic, strong) TGPresentation *presentation;
@end

@implementation TGTabBar

- (instancetype)initWithButtonInfos:(NSArray<TGTabBarButtonInfo *> *)buttonInfos
                      isBarBarOnTop:(BOOL)isBarBarOnTop
                       presentation:(TGPresentation *)presentation
{
    self = [super init];
    if (self != nil)
    {
        self.multipleTouchEnabled = false;
        self.exclusiveTouch = true;
        
        _presentation = presentation;
        _isBarBarOnTop = isBarBarOnTop;
        
        _stripeView = [[UIView alloc] init];
        [self addSubview:_stripeView];
        
        NSMutableArray<TGTabBarButton *> *tabButtons = [NSMutableArray arrayWithCapacity:buttonInfos.count];
        for (TGTabBarButtonInfo *buttonInfo in buttonInfos) {
            [tabButtons addObject:[[TGTabBarButton alloc] initWithInfo:buttonInfo isBarBarOnTop:isBarBarOnTop]];
        }
        _tabButtons = [tabButtons copy];
        
        [self addSubviews:tabButtons];
        
        UILongPressGestureRecognizer *pressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        pressGestureRecognizer.minimumPressDuration = 0.0;
        pressGestureRecognizer.allowableMovement = 1.0f;
        pressGestureRecognizer.delegate = self;
        [self addGestureRecognizer:pressGestureRecognizer];
        
        [self setPresentation:presentation];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.backgroundColor = presentation.pallete.tabBarBackgroundColor;
    _stripeView.backgroundColor = presentation.pallete.tabBarSeparatorColor;
    
    for (TGTabBarButton *button in _tabButtons) {
        [button setImage:button.imageView.image presentation:presentation];
    }
}

- (CGFloat)sideIconOffsetForWidth:(CGFloat)width
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return 0.0f;
    if (width < 320.0f + FLT_EPSILON)
        return 0.0f;
    
    return CGFloor(width / 21.5f);
}

- (void)setSelectedIndex:(int)selectedIndex
{
    _selectedIndex = selectedIndex;
    
    [_tabButtons enumerateObjectsUsingBlock:^(TGTabBarButton *button, NSUInteger index, __unused BOOL *stop)
     {
         [button setSelected:((int)index == selectedIndex)];
     }];
}

- (void)handlePress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        NSInteger buttonsCount = _tabButtons.count;
        CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
        if (location.y > [TGTabBar tabBarHeight:_landscape])
            return;
        
        if (!_isBarBarOnTop && _safeAreaInset.bottom > FLT_EPSILON && self.frame.size.height - location.y < _safeAreaInset.bottom + 4.0f)
            return;
        
        int index = MAX(0, MIN((int)buttonsCount - 1, (int)(location.x / (self.frame.size.width / buttonsCount))));
        [self setSelectedIndex:index];
        
        __strong id<TGTabBarDelegate> delegate = _tabDelegate;
        [delegate tabBarSelectedItem:index];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        __strong id<TGTabBarDelegate> delegate = _tabDelegate;
        [delegate tabBarLongPressedItem:2];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)__unused gestureRecognizer
{
    if (gestureRecognizer.view == self)
        return true;
    else
        return _selectedIndex == 2;
}

- (void)setUnreadCounts:(NSArray<NSNumber *> *)unreadCounts {
    if ([_unreadCounts isEqualToArray:unreadCounts]) return;
    _unreadCounts = [unreadCounts copy];
    [_tabButtons enumerateObjectsUsingBlock:^(TGTabBarButton * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if (idx < _unreadCounts.count) {
            obj.unreadCount = [_unreadCounts[idx] intValue];
        }
    }];
}

- (void)layoutButtons
{
    CGSize viewSize = self.frame.size;
    
    CGFloat width = viewSize.width - self.safeAreaInset.left - self.safeAreaInset.right;
    
    NSUInteger buttonsCount = _tabButtons.count;
    CGFloat buttonWidth = floor(width / buttonsCount);
    
    [_tabButtons enumerateObjectsUsingBlock:^(TGTabBarButton *button, NSUInteger index, __unused BOOL *stop)
     {
         button.landscape = self.landscape;
         button.frame = CGRectMake(self.safeAreaInset.left + index * buttonWidth, 0, buttonWidth, [TGTabBar tabBarHeight:_landscape]);
     }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat stripeHeight = TGScreenPixel;
    _stripeView.frame = CGRectMake(0, -stripeHeight, self.frame.size.width, stripeHeight);
    
    [self layoutButtons];
}

+ (CGFloat)tabBarHeight:(bool)landscape
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        return iosMajorVersion() >= 11 ? (landscape ? 32.0f : 49.0f) : 49.0f;
    else
        return 56.0f;
}

@end

#pragma mark -

@interface TGTabsContainerSubview : UIView

@end

@implementation TGTabsContainerSubview

- (void)layoutSubviews
{
    static void (*nativeImpl)(id, SEL) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      nativeImpl = (void (*)(id, SEL))freedomNativeImpl([self class], _cmd);
                  });
    
    if (nativeImpl != NULL)
        nativeImpl(self, _cmd);
    
    CGSize screenSize = [TGViewController screenSizeForInterfaceOrientation:self.frame.size.width > 320.0f + FLT_EPSILON ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait];
    
    for (UIView *subview in self.subviews)
    {
        subview.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, screenSize.height);
    }
}

@end

#pragma mark -

@interface TGTabBarViewController () <UITabBarControllerDelegate, TGTabBarDelegate>
{
    NSTimeInterval _lastSameIndexTapTime;
    int _tapsInSuccession;
    
    CGFloat _keyboardHeight;
    bool _ignoreKeyboardFrameChange;
    
    id<SDisposable> _presentationDisposable;
    TGPresentation *_presentation;
    
    NSArray<UIViewController *> *_viewControllers;
    NSUInteger _selectedIndex;
}

@property (nonatomic, strong) TGTabBar *customTabBar;

@end

@implementation TGTabBarViewController

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.delegate = self;
        
        if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
            [self setAutomaticallyAdjustsScrollViewInsets:false];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem.possibleTitles = [NSSet setWithObject:TGLocalized(@"Common.Back")];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    if (iosMajorVersion() <= 6 && [NSStringFromClass([self.view.subviews.firstObject class]) isEqualToString:TGEncodeText(@"VJUsbotjujpoWjfx", -1)])
    {
        Class subclass = freedomMakeClass([self.view.subviews.firstObject class], [TGTabsContainerSubview class]);
        object_setClass(self.view.subviews.firstObject, subclass);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeTabBar];
    self.tabBar.hidden = true;
}

- (void)initializeTabBar
{
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (self.view.frame.size.width > self.view.frame.size.height)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    _customTabBar = [[TGTabBar alloc] initWithButtonInfos:self.buttonInfos isBarBarOnTop:self.isBarBarOnTop presentation:_presentation];
    _customTabBar.tabDelegate = self;
    [self.view insertSubview:_customTabBar aboveSubview:self.tabBar];
    [self.view setNeedsLayout];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    [_customTabBar setPresentation:presentation];
    for (UIViewController *viewController in self.customViewControllers) {
        if ([viewController respondsToSelector:@selector(setPresentation:)]) {
            [(id)viewController setPresentation:presentation];
        }
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _customTabBar.frame = [self tabBarFrame];
    if (_customTabBar.layer.animationKeys.count > 0) {
        [self setTabBarHidden:_tabBarHidden animated:YES force:YES];
    }
}

- (CGRect)tabBarFrame
{
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (self.view.frame.size.width > self.view.frame.size.height)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    UIEdgeInsets safeAreaInset = [TGViewController safeAreaInsetForOrientation:orientation];
    bool landscape = !TGIsPad() && iosMajorVersion() >= 11 && UIInterfaceOrientationIsLandscape(orientation);
    _customTabBar.safeAreaInset = safeAreaInset;
    _customTabBar.landscape = landscape;
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, [TGTabBar tabBarHeight:landscape]);
    if (self.isBarBarOnTop) {
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        if (navigationBar != nil) {
            frame.origin.y = CGRectGetMaxY([UIApplication.sharedApplication.keyWindow convertRect:navigationBar.frame fromView:navigationBar.superview]);
        }
    }
    else {
        frame.origin.y = self.view.frame.size.height - [TGTabBar tabBarHeight:landscape] - MAX(safeAreaInset.bottom, _keyboardHeight);
        frame.size.height += safeAreaInset.bottom;
    }
    return frame;
}

- (void)setTabBarHidden:(BOOL)tabBarHidden
{
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(bool)tabBarHidden animated:(BOOL)animated
{
    [self setTabBarHidden:tabBarHidden animated:animated force:NO];
}

- (void)setTabBarHidden:(bool)tabBarHidden animated:(BOOL)animated force:(BOOL)force
{
    if (!force && _tabBarHidden == tabBarHidden) return;
    _tabBarHidden = tabBarHidden;
    if (!animated) {
        _customTabBar.hidden = tabBarHidden;
        _customTabBar.frame = [self tabBarFrame];
        return;
    }
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    CGRect hiddenFrame = _customTabBar.frame;
    hiddenFrame.origin.y = -hiddenFrame.size.height;
    void(^animations)() = ^() {
        _customTabBar.frame = tabBarHidden ? hiddenFrame : [self tabBarFrame];;
    };
    void(^completion)(BOOL) = NULL;
    if (tabBarHidden) {
        completion = ^(BOOL finished) {
            _customTabBar.hidden = finished;
        };
        options |= UIViewAnimationOptionCurveEaseIn;
    }
    else {
        _customTabBar.hidden = NO;
        _customTabBar.frame = hiddenFrame;
        options |= UIViewAnimationOptionCurveEaseOut;
    }
    if (!force) {
        [self.view setNeedsLayout];
    }
    [UIView animateWithDuration:0.3
                          delay:0
                        options:options
                     animations:animations
                     completion:completion];
}

- (void)setIgnoreKeyboardFrameChange:(bool)ignoreKeyboardFrameChange restoringFocus:(bool)restoringFocus
{
    _ignoreKeyboardFrameChange = ignoreKeyboardFrameChange;
    
    if (!ignoreKeyboardFrameChange && !restoringFocus)
    {
        [UIView animateWithDuration:0.2 delay:0.0 options:7 << 16 animations:^
         {
             [self _updateForKeyboardHeight:_keyboardHeight];
         } completion:nil];
    }
}

- (void)controllerInsetUpdated:(UIEdgeInsets)newInset
{
    if (TGIsPad()) {
        _keyboardHeight = newInset.bottom;
        
        if (_ignoreKeyboardFrameChange)
            return;
        
        [self _updateForKeyboardHeight:_keyboardHeight];
    }
}

- (void)_updateForKeyboardHeight:(CGFloat)keyboardHeight
{
    _customTabBar.frame = [self tabBarFrame];
    
    if (self.onControllerInsetUpdated != nil)
        self.onControllerInsetUpdated(keyboardHeight);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [TGViewController autorotationAllowed] && (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)shouldAutorotate
{
    return [TGViewController autorotationAllowed];
}

- (UIBarStyle)requiredNavigationBarStyle
{
    if (self.selectedViewController == nil)
        return UIBarStyleDefault;
    else if ([self.selectedViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)])
        return [(id<TGViewControllerNavigationBarAppearance>)self.selectedViewController requiredNavigationBarStyle];
    else
        return UIBarStyleDefault;
}

- (bool)navigationBarShouldBeHidden
{
    if (self.selectedViewController == nil)
        return false;
    else if ([self.selectedViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)])
        return [(id<TGViewControllerNavigationBarAppearance>)self.selectedViewController navigationBarShouldBeHidden];
    else
        return false;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.view layoutIfNeeded];
    if (self.debugReady != NULL) {
        self.debugReady();
    }
    [super viewWillAppear:animated];
}

- (BOOL)tabBarController:(UITabBarController *)__unused tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == self.selectedViewController)
        return false;
    
    return true;
}

- (void)tabBarLongPressedItem:(int)index
{
    if ((int)self.selectedIndex == index)
    {
        if ([self.selectedViewController respondsToSelector:@selector(scrollToTop)])
            [self.selectedViewController performSelector:@selector(scrollToTop)];
    }
}

- (void)tabBarSelectedItem:(int)index
{
    if ((int)self.selectedIndex != index)
    {
        [self tabBarController:self shouldSelectViewController:self.customViewControllers[index]];
        [self setSelectedIndexCustom:index];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.selectedViewController respondsToSelector:@selector(scrollToTopRequested)])
            [self.selectedViewController performSelector:@selector(scrollToTopRequested)];
#pragma clang diagnostic pop
    }
    
    if ((NSUInteger)index == self.customViewControllers.count - 1) {
        NSTimeInterval t = CACurrentMediaTime();
        if (_lastSameIndexTapTime < DBL_EPSILON || t < _lastSameIndexTapTime + 0.5) {
            _lastSameIndexTapTime = t;
            _tapsInSuccession++;
            if (_tapsInSuccession == 10) {
                _tapsInSuccession = 0;
                _lastSameIndexTapTime = 0.0;
                
                [TGAppDelegateInstance.rootController pushContentController:[[TGDebugController alloc] init]];
            }
        } else {
            _lastSameIndexTapTime = 0.0;
            _tapsInSuccession = 0;
        }
    }
}

- (void)setSelectedIndexCustom:(NSUInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    NSArray *selectedVC = @[_viewControllers[selectedIndex]];
    if (![[super viewControllers] isEqual:selectedVC]) {
        [super setViewControllers:selectedVC animated:false];
    }
    [self updateNavigationItemOverride:selectedIndex];
    
    [_customTabBar setSelectedIndex:(int)selectedIndex];
}

- (NSUInteger)selectedIndex
{
    return _selectedIndex;
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers animated:(BOOL)animated
{
    _viewControllers = viewControllers;
    [super setViewControllers:@[viewControllers[self.selectedIndex]] animated:animated];
    
    [self updateNavigationItemOverride:self.selectedIndex];
}

- (NSArray<UIViewController *> *)customViewControllers
{
    return _viewControllers;
}

- (void)updateNavigationItemOverride:(NSUInteger)selectedIndex
{
    int index = -1;
    for (UIViewController *viewController in self.customViewControllers)
    {
        index++;
        BOOL selected = index == (int)selectedIndex;
        if ([viewController isKindOfClass:[TGViewController class]])
        {
            [(TGViewController *)viewController setTargetNavigationItem:selected ? self.navigationItem : nil
                                                        titleController:selected ? self : nil];
        }
        else if ([viewController isKindOfClass:[TGCryptoTabViewController class]]) {
            [(TGCryptoTabViewController *)viewController setTargetNavigationItem:selected ? self.navigationItem : nil
                                                                 titleController:selected ? self : nil];
        }
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    NSString *backTitle = title == nil || ![title isEqualToString:TGLocalized(@"DialogList.Title")] ? TGLocalized(@"Common.Back") : title;
    
    if (!TGStringCompare(self.navigationItem.backBarButtonItem.title, backTitle))
        self.navigationItem.backBarButtonItem.title = backTitle;
}

- (void)setUnreadCounts:(NSArray<NSNumber *> *)unreadCounts {
    if ([_unreadCounts isEqualToArray:unreadCounts]) return;
    _unreadCounts = unreadCounts.copy;
    [_customTabBar setUnreadCounts:_unreadCounts];
}

- (void)localizationUpdated
{
    _customTabBar.tabDelegate = nil;
    [_customTabBar removeFromSuperview];
    
    [self initializeTabBar];
    
    [_customTabBar setSelectedIndex:(int)self.selectedIndex];
    [_customTabBar setUnreadCounts:_unreadCounts];
    
    for (TGViewController *controller in self.customViewControllers)
    {
        [controller localizationUpdated];
    }
    
    [_customTabBar layoutSubviews];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    [self.navigationController setToolbarHidden:true animated:false];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (!TGAppDelegateInstance.rootController.callStatusBarHidden)
        return UIStatusBarStyleLightContent;
    else {
        if (iosMajorVersion() >= 7) {
            return _presentation.pallete.isDark ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
        } else {
            return UIStatusBarStyleDefault;
        }
    }
}

- (BOOL)prefersStatusBarHidden
{
    return self.selectedViewController.prefersStatusBarHidden;
}

- (CGRect)frameForRightmostTab {
    return [(TGTabBarButton *)_customTabBar.tabButtons.lastObject frame];
}

- (UIView *)viewForRightmostTab {
    return _customTabBar.tabButtons.lastObject;
}

@end
