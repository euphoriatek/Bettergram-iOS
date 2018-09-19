#import <UIKit/UIKit.h>

#import <LegacyComponents/LegacyComponents.h>

@class TGPresentation;

@interface TGTabBarButtonInfo : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *icon;

+ (instancetype)infoWithIcon:(UIImage *)icon;
+ (instancetype)infoWithIcon:(UIImage *)icon title:(NSString *)title;

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

@end
