#import "TGMainTabsController.h"

#import <LegacyComponents/LegacyComponents.h>

#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>

#import "TGAppDelegate.h"
#import "TGDebugController.h"

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
        frame.size.width = MAX(kHeight, textWidth + 10 + TGScreenPixel * 2.0f);
        frame.size.height = kHeight;
        frame.origin.x = _backgroundView.superview.frame.size.width - frame.size.width - 1.0f;
        frame.origin.y = -1.0f;
        _backgroundView.frame = frame;
        
        _label.center = _backgroundView.center;
    }
}

@end

@interface TGTabBarButton : UIView
{
    TGPresentation *_presentation;
}

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, assign, getter=isSelected) bool selected;
@property (nonatomic, assign) bool landscape;

@property (nonatomic, assign) int unreadCount;
@property (nonatomic, strong) TGTabBarBadge *badge;

@end

@implementation TGTabBarButton

- (instancetype)initWithImage:(UIImage *)image presentation:(TGPresentation *)presentation
{
    self = [super init];
    if (self != nil)
    {
        _presentation = presentation;
        
        self.accessibilityTraits = UIAccessibilityTraitButton;
        
        _imageView = [[UIImageView alloc] initWithImage:TGTintedImage(image, presentation.pallete.tabIconColor)];
        [self addSubview:_imageView];
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
}

- (void)setSelected:(bool)selected
{
    _selected = selected;
    if (_imageView.highlightedImage == nil && selected)
        _imageView.highlightedImage = TGTintedImage(_imageView.image, _presentation.pallete.tabActiveIconColor);
    _imageView.highlighted = selected;
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
    _imageView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    if (_badge != nil)
    {
        if (self.landscape)
        {
            _badge.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
            _badge.center = CGPointMake(self.imageView.center.x + 10.0f, 10.0f);
        }
        else
        {
            _badge.transform = CGAffineTransformIdentity;
            CGRect badgeFrame = _badge.frame;
            badgeFrame.origin.x = self.frame.size.width / 2.0f + 6.0f + TGRetinaPixel;
            badgeFrame.origin.y = 2 - self.frame.origin.y;
            _badge.frame = badgeFrame;
        }
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

@end


@interface TGTabBar : UIView <UIGestureRecognizerDelegate>
{
    bool _skipNextLayout;
}

@property (nonatomic, weak) id<TGTabBarDelegate> tabDelegate;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *stripeView;

@property (nonatomic, strong) NSArray<TGTabBarButton *> *tabButtons;

@property (nonatomic, assign) UIEdgeInsets safeAreaInset;
@property (nonatomic, assign) bool landscape;

@property (nonatomic) int selectedIndex;

@property (nonatomic, copy) NSArray<NSNumber *> *unreadCounts;

@property (nonatomic, strong) TGPresentation *presentation;
@end

@implementation TGTabBar

- (instancetype)initWithFrame:(CGRect)frame presentation:(TGPresentation *)presentation
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.multipleTouchEnabled = false;
        self.exclusiveTouch = true;
        
        _presentation = presentation;
        
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = presentation.pallete.tabBarBackgroundColor;
        _backgroundView.frame = self.bounds;
        [self addSubview:_backgroundView];
        
        _stripeView = [[UIView alloc] init];
        _stripeView.backgroundColor = presentation.pallete.tabBarSeparatorColor;
        [self addSubview:_stripeView];
        
        NSArray *tabButtonsImages = @[
                                      TGImageNamed(@"tab_all_messages.png"),
                                      TGImageNamed(@"tab_direct_messages.png"),
                                      TGImageNamed(@"tab_groups.png"),
                                      TGImageNamed(@"tab_announcements.png"),
                                      TGImageNamed(@"tab_favorites.png"),
                                      TGImageNamed(@"tab_crypto.png")
                                      ];
        NSMutableArray<TGTabBarButton *> *tabButtons = [NSMutableArray arrayWithCapacity:tabButtonsImages.count];
        for (UIImage *buttonImage in tabButtonsImages)
        {
            TGTabBarButton *button = [[TGTabBarButton alloc] initWithImage:buttonImage presentation:presentation];
            [tabButtons addObject:button];
            [self addSubview:button];
        }
        _tabButtons = [tabButtons copy];
        
        UILongPressGestureRecognizer *pressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        pressGestureRecognizer.minimumPressDuration = 0.0;
        pressGestureRecognizer.allowableMovement = 1.0f;
        pressGestureRecognizer.delegate = self;
        [self addGestureRecognizer:pressGestureRecognizer];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    _backgroundView.backgroundColor = presentation.pallete.tabBarBackgroundColor;
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
        
        if (_safeAreaInset.bottom > FLT_EPSILON && self.frame.size.height - location.y < _safeAreaInset.bottom + 4.0f)
            return;
        
        int index = MAX(0, MIN((int)buttonsCount - 1, (int)(location.x / (self.frame.size.width / buttonsCount))));
        if (buttonsCount == 3 && index > 0)
            index += 1;
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
    
    CGSize viewSize = self.frame.size;
    
    _backgroundView.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
    CGFloat stripeHeight = TGScreenPixel;
    _stripeView.frame = CGRectMake(0, -stripeHeight, viewSize.width, stripeHeight);
    
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

@interface TGMainTabsController () <UITabBarControllerDelegate, TGTabBarDelegate>
{
    NSTimeInterval _lastSameIndexTapTime;
    int _tapsInSuccession;
    
    bool _initialized;
    
    CGFloat _keyboardHeight;
    bool _ignoreKeyboardFrameChange;
    
    id<SDisposable> _presentationDisposable;
    TGPresentation *_presentation;
}

@property (nonatomic, strong) TGTabBar *customTabBar;

@end

@implementation TGMainTabsController

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
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (self.view.frame.size.width > self.view.frame.size.height)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    UIEdgeInsets safeAreaInset = [TGViewController safeAreaInsetForOrientation:orientation];
    CGFloat inset = 0.0f;
    if (iosMajorVersion() >= 11 && safeAreaInset.bottom > FLT_EPSILON)
        inset = safeAreaInset.bottom;

    bool landscape = !TGIsPad() && iosMajorVersion() >= 11 && UIInterfaceOrientationIsLandscape(orientation);
    _customTabBar = [[TGTabBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [TGTabBar tabBarHeight:landscape] - inset, self.view.frame.size.width, [TGTabBar tabBarHeight:landscape] + inset) presentation:_presentation];
    _customTabBar.safeAreaInset = safeAreaInset;
    _customTabBar.landscape = landscape;
    _customTabBar.tabDelegate = self;
    [self.view insertSubview:_customTabBar aboveSubview:self.tabBar];
    
    self.tabBar.hidden = true;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    [_customTabBar setPresentation:presentation];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (self.view.frame.size.width > self.view.frame.size.height)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    UIEdgeInsets safeAreaInset = [TGViewController safeAreaInsetForOrientation:orientation];
    CGFloat inset = 0.0f;
    if (iosMajorVersion() >= 11 && safeAreaInset.bottom > FLT_EPSILON)
        inset = safeAreaInset.bottom;
    
    bool landscape = !TGIsPad() && iosMajorVersion() >= 11 && UIInterfaceOrientationIsLandscape(orientation);
    _customTabBar.safeAreaInset = safeAreaInset;
    _customTabBar.landscape = landscape;
    _customTabBar.frame = CGRectMake(0.0f, self.view.frame.size.height - [TGTabBar tabBarHeight:landscape] - inset, self.view.frame.size.width, [TGTabBar tabBarHeight:landscape] + inset);
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
    _keyboardHeight = newInset.bottom;
    
    if (_ignoreKeyboardFrameChange)
        return;
    
    [self _updateForKeyboardHeight:_keyboardHeight];
}

- (void)_updateForKeyboardHeight:(CGFloat)keyboardHeight
{
    _customTabBar.frame = CGRectMake(0.0f, self.view.frame.size.height - [TGTabBar tabBarHeight:false] - keyboardHeight, self.view.frame.size.width, [TGTabBar tabBarHeight:false]);
    
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
    self.debugReady();
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
    TGViewController *selectedViewController = [self.viewControllers objectAtIndex:index];
    if ((int)self.selectedIndex != index)
    {
        [self tabBarController:self shouldSelectViewController:selectedViewController];
        [self setSelectedIndex:index];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.selectedViewController respondsToSelector:@selector(scrollToTopRequested)])
            [self.selectedViewController performSelector:@selector(scrollToTopRequested)];
#pragma clang diagnostic pop
    }
    
    if ([selectedViewController isKindOfClass:[TGAccountSettingsController class]]) {
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

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    NSUInteger lastSelectedTabIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedTabIndex"];
    if (!_initialized && lastSelectedTabIndex < self.viewControllers.count)
    {
        selectedIndex = lastSelectedTabIndex;
        _initialized = true;
    }
    
    [super setSelectedIndex:selectedIndex];
    
    [self _updateNavigationItemOverride:selectedIndex];
    
    [_customTabBar setSelectedIndex:(int)selectedIndex];
    if (lastSelectedTabIndex != selectedIndex) {
        [[NSUserDefaults standardUserDefaults] setInteger:selectedIndex forKey:@"lastSelectedTabIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    [super setViewControllers:viewControllers animated:animated];
    
    [self _updateNavigationItemOverride:self.selectedIndex];
}

- (void)_updateNavigationItemOverride:(NSUInteger)selectedIndex
{
    int index = -1;
    for (UIViewController *viewController in self.viewControllers)
    {
        index++;
        
        if ([viewController isKindOfClass:[TGViewController class]])
        {
            if (index == (int)selectedIndex)
                [(TGViewController *)viewController setTargetNavigationItem:self.navigationItem titleController:self];
            else
                [(TGViewController *)viewController setTargetNavigationItem:nil titleController:nil];
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
    _unreadCounts = unreadCounts;
    [_customTabBar setUnreadCounts:_unreadCounts];
}

- (void)localizationUpdated
{
    _customTabBar.tabDelegate = nil;
    [_customTabBar removeFromSuperview];
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (self.view.frame.size.width > self.view.frame.size.height)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    UIEdgeInsets safeAreaInset = [TGViewController safeAreaInsetForOrientation:orientation];
    CGFloat inset = 0.0f;
    if (iosMajorVersion() >= 11 && safeAreaInset.bottom > FLT_EPSILON)
        inset = safeAreaInset.bottom;
    
    bool landscape = !TGIsPad() && iosMajorVersion() >= 11 && UIInterfaceOrientationIsLandscape(orientation);
    _customTabBar = [[TGTabBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [TGTabBar tabBarHeight:landscape] - inset, self.view.frame.size.width, [TGTabBar tabBarHeight:landscape] + inset) presentation:_presentation];
    _customTabBar.safeAreaInset = safeAreaInset;
    _customTabBar.landscape = landscape;
    _customTabBar.tabDelegate = self;
    [self.view insertSubview:_customTabBar aboveSubview:self.tabBar];
    
    [_customTabBar setSelectedIndex:(int)self.selectedIndex];
    [_customTabBar setUnreadCounts:_unreadCounts];
    
    for (TGViewController *controller in self.viewControllers)
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

- (CGRect)frameForRightmostTab {
    return [(TGTabBarButton *)_customTabBar.tabButtons.lastObject frame];
}

- (UIView *)viewForRightmostTab {
    return _customTabBar.tabButtons.lastObject;
}

@end
