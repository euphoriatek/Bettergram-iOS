#import <UIKit/UIKit.h>

#import <LegacyComponents/LegacyComponents.h>

@class TGPresentation;

@interface TGMainTabsController : UITabBarController <TGViewControllerNavigationBarAppearance, TGNavigationControllerTabsController>

@property (nonatomic, copy) void (^debugReady)(void);
@property (nonatomic, copy) void (^onControllerInsetUpdated)(CGFloat);
@property (nonatomic, copy) NSArray<NSNumber *> *unreadCounts;

- (instancetype)initWithPresentation:(TGPresentation *)presentation;
- (void)setPresentation:(TGPresentation *)presentation;

- (void)setIgnoreKeyboardFrameChange:(bool)ignore restoringFocus:(bool)restoringFocus;

- (void)localizationUpdated;

- (CGRect)frameForRightmostTab;
- (UIView *)viewForRightmostTab;

- (void)controllerInsetUpdated:(UIEdgeInsets)newInset;
- (void)setSelectedIndexCustom:(NSUInteger)selectedIndex;

@end
