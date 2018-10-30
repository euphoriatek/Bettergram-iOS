#import <UIKit/UIKit.h>

#import <LegacyComponents/LegacyComponents.h>

@class TGPresentation;

@interface TGTabBarButtonInfo : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *accessibilityTitle;
@property (nonatomic, strong) UIImage *icon;

+ (instancetype)infoWithIcon:(UIImage *)icon;
+ (instancetype)infoWithIcon:(UIImage *)icon title:(NSString *)title;
+ (instancetype)infoWithIcon:(UIImage *)icon accessibilityTitle:(NSString *)accessibilityTitle;

@end

@interface TGTabBarViewController : UITabBarController <TGViewControllerNavigationBarAppearance, TGNavigationControllerTabsController>

@property (nonatomic, copy) void (^debugReady)(void);
@property (nonatomic, copy) void (^onControllerInsetUpdated)(CGFloat);
@property (nonatomic, copy) NSArray<NSNumber *> *unreadCounts;
@property (nonatomic, readonly) BOOL isBarBarOnTop;
@property (nonatomic, readonly) NSArray<TGTabBarButtonInfo *> *buttonInfos;

- (instancetype)initWithPresentation:(TGPresentation *)presentation;
- (void)setPresentation:(TGPresentation *)presentation;

- (void)setIgnoreKeyboardFrameChange:(bool)ignore restoringFocus:(bool)restoringFocus;

- (void)localizationUpdated;

- (CGRect)frameForRightmostTab;
- (UIView *)viewForRightmostTab;

- (void)controllerInsetUpdated:(UIEdgeInsets)newInset;
- (void)setSelectedIndexCustom:(NSUInteger)selectedIndex;

- (void)updateNavigationItemOverride:(NSUInteger)selectedIndex;

@property (nonatomic, assign) BOOL tabBarHidden;
- (void)setTabBarHidden:(bool)tabBarHidden animated:(BOOL)animated;

@end
