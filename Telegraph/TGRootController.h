#import <LegacyComponents/LegacyComponents.h>

#import <SSignalKit/SSignalKit.h>

@class TGDialogListController;
@class TGContactsController;
@class TGAccountSettingsController;
@class TGRecentCallsController;
@class TGMainTabsController;
@class TGCallStatusBarView;
@class TGVolumeBarView;
@class TGPresentation;
@class TGCryptoTabViewController;
@class TGTelegraphDialogListCompanion;

@interface TGRootController : TGViewController

@property (nonatomic, strong, readonly) TGMainTabsController *mainTabsController;
@property (nonatomic, strong, readonly) NSArray<TGDialogListController *> *dialogListControllers;
@property (nonatomic, strong, readonly) TGContactsController *contactsController;
@property (nonatomic, strong) TGAccountSettingsController *accountSettingsController;
@property (nonatomic, strong, readonly) TGRecentCallsController *callsController;
@property (nonatomic, strong, readonly) TGCallStatusBarView *callStatusBarView;
@property (nonatomic, strong, readonly) TGVolumeBarView *volumeBarView;

@property (nonatomic, readonly) TGPresentation *presentation;

- (SSignal *)sizeClass;
- (bool)isSplitView;
- (bool)isSlideOver;
- (CGRect)applicationBounds;

- (bool)callStatusBarHidden;

- (void)pushContentController:(UIViewController *)contentController;
- (void)replaceContentController:(UIViewController *)contentController;
- (void)popToContentController:(UIViewController *)contentController;
- (void)clearContentControllers;
- (NSArray *)viewControllers;

- (void)resetControllers;

- (void)localizationUpdated;

- (bool)isRTL;

@end
