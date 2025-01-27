#import "TGRootController.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGAppDelegate.h"

#import "TGTabletMainView.h"

#import "TGDialogListController.h"
#import "TGTelegraphDialogListCompanion.h"
#import "TGContactsController.h"
#import "TGAccountSettingsController.h"
#import "TGRecentCallsController.h"
#import "TGMainTabsController.h"
#import "TGModernConversationController.h"
#import "TGCallStatusBarView.h"
#import "TGVolumeBarView.h"
#import "TGProxyWindow.h"

#import "TGCryptoTabViewController.h"
#import "TGCryptoPricesViewController.h"
#import "TGCryptoRssViewController.h"
#import "TGResourcesViewController.h"
#import "TGFeedParser.h"

#import "TGPresentation.h"

@interface TGRootController () <ASWatcher>
{
    TGTabletMainView *_mainView;
    
    TGNavigationController *_masterNavigationController;
    TGNavigationController *_detailNavigationController;
    
    TGCryptoTabViewController *_cryptoTabViewController;
    TGCryptoRssViewController *_newsRssController;
    TGCryptoRssViewController *_videosRssController;
    
    UIUserInterfaceSizeClass _currentSizeClass;
    
    SVariable *_sizeClassVariable;
    SMetaDisposable *_callDisposable;
    
    id<SDisposable> _presentationDisposable;
    
    NSMutableArray<TGDialogListController *> *_dialogListControllers;
}

@property (nonatomic, strong) ASHandle *actionHandle;

@end

@implementation TGRootController

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        [self setNavigationBarHidden:true animated:false];
        self.automaticallyManageScrollViewInsets = false;
        
        __weak TGRootController *weakSelf = self;
        _presentationDisposable = [TGPresentation.signal startWithNext:^(TGPresentation *next)
        {
            __strong TGRootController *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf setPresentation:next];
        }];
        
        NSMutableArray<TGDialogListController *> *dialogListControllers = [NSMutableArray array];
        for (int i = 0; i < 5; i++) {
            TGTelegraphDialogListCompanion *dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
            dialogListCompanion.filter = i;
            
            TGDialogListController *dialogListController = [[TGDialogListController alloc] initWithCompanion:dialogListCompanion];
            dialogListController.presentation = _presentation;
            [dialogListControllers addObject:dialogListController];
        }
        _dialogListControllers = [dialogListControllers copy];
        
        _contactsController = [[TGContactsController alloc] initWithContactsMode:TGContactsModeMainContacts | TGContactsModeRegistered | TGContactsModePhonebook | TGContactsModeSortByLastSeen];
        _contactsController.presentation = _presentation;
        
        _accountSettingsController = [[TGAccountSettingsController alloc] initWithUid:0];
        
        _callsController = [[TGRecentCallsController alloc] init];
        _callsController.presentation = _presentation;
        
        _cryptoTabViewController = [[TGCryptoTabViewController alloc] initWithPresentation:_presentation];
        [_cryptoTabViewController setViewControllers:
         @[
           [[TGCryptoPricesViewController alloc] initWithPresentation:_presentation],
           _newsRssController = [[TGCryptoRssViewController alloc] initWithPresentation:_presentation
                                                                          feedParserKey:@"news"
                                                                         isVideoContent:NO],
           _videosRssController = [[TGCryptoRssViewController alloc] initWithPresentation:_presentation
                                                                            feedParserKey:@"videos"
                                                                           isVideoContent:YES],
           [[TGResourcesViewController alloc] initWithPresentation:_presentation],
           ]];
        [_cryptoTabViewController setSelectedIndexCustom:0];
        
        _videosRssController.feedParser.unreadCountUpdatedBlock =
        _newsRssController.feedParser.unreadCountUpdatedBlock = ^() {
            __strong TGRootController *strongSelf = weakSelf;
            [strongSelf updateUnreadCountsIcludingBage:NO];
        };
        
        _mainTabsController = [[TGMainTabsController alloc] initWithPresentation:_presentation];
        {
            NSMutableArray *viewControllers = _dialogListControllers.mutableCopy;
            if (!TGIsPad()) {
                [viewControllers addObject:_cryptoTabViewController];
            }
            [_mainTabsController setViewControllers:viewControllers];
        }
        _mainTabsController.onControllerInsetUpdated = ^(CGFloat inset)
        {
            __strong TGRootController *strongSelf = weakSelf;
            if (strongSelf != nil)
                [strongSelf->_mainView updateBottomInset:inset];
        };
        
        _masterNavigationController = [TGNavigationController navigationControllerWithControllers:@[]];
        _detailNavigationController = [TGNavigationController navigationControllerWithControllers:@[]];
        if (TGIsPad()) {
            [_detailNavigationController setViewControllers:@[_cryptoTabViewController]];
        }
        [_detailNavigationController setDisplayPlayer:true];
        
        if (iosMajorVersion() >= 8)
        {
            _currentSizeClass = UIUserInterfaceSizeClassCompact;
        }
        else
        {
            switch ([UIDevice currentDevice].userInterfaceIdiom)
            {
                case UIUserInterfaceIdiomPad:
                    _currentSizeClass = UIUserInterfaceSizeClassRegular;
                    break;
                    
                default:
                    _currentSizeClass = UIUserInterfaceSizeClassCompact;
                    break;
            }
        }
        
        _sizeClassVariable = [[SVariable alloc] init];
        [_sizeClassVariable set:[SSignal single:@(_currentSizeClass)]];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
        [ActionStageInstance() dispatchOnStageQueue:^
         {
             [ActionStageInstance() removeWatcher:self];
             [ActionStageInstance() watchForPath:@"/tg/unreadCount" watcher:self];
         }];
        [self updateUnreadCountsIcludingBage:NO];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    if (self.isViewLoaded)
        self.view.backgroundColor = presentation.pallete.collectionMenuBackgroundColor;
    
    _mainView.presentation = presentation;
    
    [(TGNavigationBar *)_masterNavigationController.navigationBar setPallete:presentation.navigationBarPallete];
    [(TGNavigationBar *)_detailNavigationController.navigationBar setPallete:presentation.navigationBarPallete];
    [_mainTabsController setPresentation:presentation];
    [_contactsController setPresentation:presentation];
    [_callsController setPresentation:presentation];
    for (TGDialogListController *dialogListController in _dialogListControllers) {
        [dialogListController setPresentation:presentation];
    }
    
    if ([self.presentedViewController isKindOfClass:[TGNavigationController class]])
    {
        TGNavigationController *navController = (TGNavigationController *)self.presentedViewController;
        [(TGNavigationBar *)navController.navigationBar setPallete:presentation.navigationBarPallete];
    
        for (UIViewController *controller in navController.viewControllers)
        {
            if ([controller respondsToSelector:@selector(setPresentation:)])
                [controller performSelector:@selector(setPresentation:) withObject:presentation];
        }
        
        if ([navController respondsToSelector:@selector(setPresentation:)])
            [navController performSelector:@selector(setPresentation:) withObject:presentation];
    }
    
    for (UIViewController *controller in _detailNavigationController.viewControllers)
    {
        if ([controller respondsToSelector:@selector(setPresentation:)])
            [controller performSelector:@selector(setPresentation:) withObject:presentation];
    }
    
    if (_contactsController.presentedViewController != nil)
    {
        if ([_contactsController.presentedViewController respondsToSelector:@selector(setPresentation:)])
            [_contactsController.presentedViewController performSelector:@selector(setPresentation:) withObject:presentation];
    }
    
    [TGProgressWindow setDarkStyle:presentation.pallete.isDark];
    [TGProxyWindow setDarkStyle:presentation.pallete.isDark];
    
    _volumeBarView.presentation = presentation;
}

- (bool)shouldAutorotate {
    if (self.associatedWindowStack.count > 0) {
        return [[self.associatedWindowStack.lastObject rootViewController] shouldAutorotate];
    }
    return [(UIViewController *)[self viewControllers].lastObject shouldAutorotate];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = self.presentation.pallete.collectionMenuBackgroundColor;
    
    _mainView = [[TGTabletMainView alloc] initWithFrame:self.view.bounds];
    _mainView.presentation = self.presentation;
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_mainView];
    
    [self updateSizeClass];
    
    if (_masterNavigationController.viewControllers.count != 0) {
        [self addMasterController];
    }
    
    if (_detailNavigationController.viewControllers.count != 0) {
        [self addDetailController];
    }
    
    __weak TGRootController *weakSelf = self;
    _callStatusBarView = [[TGCallStatusBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    _callStatusBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _callStatusBarView.hidden = true;
    _callStatusBarView.visiblilityChanged = ^(bool hidden)
    {
        __strong TGRootController *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            [strongSelf->_masterNavigationController setShowCallStatusBar:!hidden];
            [strongSelf->_detailNavigationController setShowCallStatusBar:!hidden];
        }
    };
    
    if (!TGIsPad())
    {
        TGDispatchAfter(3.0, dispatch_get_main_queue(), ^
        {
            CGFloat inset = self.controllerSafeAreaInset.top > FLT_EPSILON ? self.controllerSafeAreaInset.top - 13.0f : 0.0f;
            _volumeBarView = [[TGVolumeBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 16.0f + inset)];
            _volumeBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _volumeBarView.safeAreaInset = self.controllerSafeAreaInset;
            _volumeBarView.presentation = self.presentation;
        });
    }
}

- (void)controllerInsetUpdated:(UIEdgeInsets)previousInset
{
    [super controllerInsetUpdated:previousInset];
    if ([self isViewLoaded])
    {
        CGFloat inset = self.controllerSafeAreaInset.top > FLT_EPSILON ? self.controllerSafeAreaInset.top - 13.0f : 0.0f;
        _volumeBarView.safeAreaInset = self.controllerSafeAreaInset;
        _volumeBarView.frame = CGRectMake(0, 0, self.view.frame.size.width, 16.0f + inset);
        
        if (TGIsPad()) {
            [_mainTabsController controllerInsetUpdated:self.controllerInset];
        }
    }
}

- (void)pushContentController:(UIViewController *)contentController {
    NSUInteger index = [_detailNavigationController.viewControllers indexOfObject:contentController];
    if (index != NSNotFound) {
        if (index != _detailNavigationController.viewControllers.count - 1) {
            [_detailNavigationController setViewControllers:[_detailNavigationController.viewControllers subarrayWithRange:NSMakeRange(0, index + 1)]
                                                   animated:YES];
        }
    }
    else {
        if (_detailNavigationController.viewControllers.count == 0) {
            [_detailNavigationController setViewControllers:@[contentController] animated:false];
            
            [self addDetailController];
        } else {
            [_detailNavigationController pushViewController:contentController animated:true];
        }
    }
}

- (void)replaceContentController:(UIViewController *)contentController {
    if (_currentSizeClass == UIUserInterfaceSizeClassCompact) {
        bool addDetail = _detailNavigationController.viewControllers.count == 0;
        if (iosMajorVersion() >= 11 && _detailNavigationController.viewControllers.count == 1)
        {
            if (_detailNavigationController.viewControllers.firstObject != _mainTabsController)
                [_detailNavigationController setViewControllers:@[_mainTabsController]];
            [_detailNavigationController pushViewController:contentController animated:true];
        }
        else
        {
            [_detailNavigationController setViewControllers:@[_mainTabsController, contentController] animated:true];
        }
        if (addDetail) {
            [self addDetailController];
        }
    } else {
        bool addDetail = _detailNavigationController.viewControllers.count == 0;
        [_detailNavigationController setViewControllers:@[_cryptoTabViewController, contentController] animated:false];
        if (addDetail) {
            [self addDetailController];
        }
    }
}

- (void)popToContentController:(UIViewController *)contentController {
    [_detailNavigationController popToViewController:contentController animated:true];
}

- (void)clearContentControllers {
    if (_currentSizeClass == UIUserInterfaceSizeClassCompact) {
        [_detailNavigationController popToRootViewControllerAnimated:true];
    } else if (_detailNavigationController.viewControllers.count != 0) {
        [_detailNavigationController setViewControllers:@[_cryptoTabViewController] animated:false];
    }
}

- (NSArray *)viewControllers {
    return [_masterNavigationController.viewControllers arrayByAddingObjectsFromArray:_detailNavigationController.viewControllers];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (_currentSizeClass != self.traitCollection.horizontalSizeClass && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        _currentSizeClass = self.traitCollection.horizontalSizeClass;
        [self updateSizeClass];
        [_sizeClassVariable set:[SSignal single:@(_currentSizeClass)]];
    }
    
    //[self setNeedsStatusBarAppearanceUpdate];
}

- (void)updateSizeClass {
    if (_currentSizeClass == UIUserInterfaceSizeClassCompact) {
        [self removeMasterController];
        
        NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
        if (_masterNavigationController.viewControllers.count != 0) {
            [viewControllers addObject:_masterNavigationController.viewControllers[0]];
        } else {
            [viewControllers addObject:_mainTabsController];
        }
        for (UIViewController *controller in _detailNavigationController.viewControllers) {
            if (![viewControllers containsObject:controller]) {
                [viewControllers addObject:controller];
            }
        }
        if (_masterNavigationController.viewControllers.count > 1) {
            for (NSUInteger i = 1; i < _masterNavigationController.viewControllers.count - 1; i++) {
                [viewControllers addObject:_masterNavigationController.viewControllers[i]];
            }
        }
        [_masterNavigationController setViewControllers:@[] animated:false];
        
        for (UIViewController *controller in [[NSArray alloc] initWithArray:_masterNavigationController.viewControllers]) {
            [controller willMoveToParentViewController:nil];
            [controller.view removeFromSuperview];
            [controller removeFromParentViewController];
            [controller didMoveToParentViewController:nil];
        }
        bool addDetail = _detailNavigationController.viewControllers.count == 0;
        [_detailNavigationController setViewControllers:viewControllers animated:false];
        if (addDetail) {
            [self addDetailController];
        }
        
        [_mainView setFullScreenDetail:true];
    } else {
        [_mainTabsController willMoveToParentViewController:nil];
        [_mainTabsController.view removeFromSuperview];
        [_mainTabsController removeFromParentViewController];
        [_mainTabsController didMoveToParentViewController:nil];
        
        NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithArray:_detailNavigationController.viewControllers];
        [viewControllers removeObject:_mainTabsController];
        [_detailNavigationController setViewControllers:viewControllers animated:false];
        [_masterNavigationController setViewControllers:@[_mainTabsController] animated:false];
        
        if (_masterNavigationController.viewControllers.count != 0) {
            [self addMasterController];
        }
        
        if (_detailNavigationController.viewControllers.count == 0) {
            [self removeDetailController];
        } else {
            [self addDetailController];
        }
        
        [_mainView setFullScreenDetail:false];
    }
}

- (void)localizationUpdated {
    [_mainTabsController localizationUpdated];
}

- (void)removeDetailController {
    if (_detailNavigationController.parentViewController != nil) {
        [_detailNavigationController willMoveToParentViewController:nil];
        [_detailNavigationController removeFromParentViewController];
        [_mainView setDetailView:nil];
        [_detailNavigationController didMoveToParentViewController:nil];
    }
}

- (void)addDetailController {
    if (_detailNavigationController.parentViewController != self) {
        [_detailNavigationController willMoveToParentViewController:self];
        [self addChildViewController:_detailNavigationController];
        [_mainView setDetailView:_detailNavigationController.view];
        [_detailNavigationController didMoveToParentViewController:self];
    }
}

- (void)removeMasterController {
    if (_masterNavigationController.parentViewController != nil) {
        [_masterNavigationController willMoveToParentViewController:nil];
        [_masterNavigationController removeFromParentViewController];
        [_mainView setMasterView:nil];
        [_masterNavigationController didMoveToParentViewController:nil];
    }
}

- (void)addMasterController {
    if (_masterNavigationController.parentViewController != self) {
        [_masterNavigationController willMoveToParentViewController:self];
        [self addChildViewController:_masterNavigationController];
        [_mainView setMasterView:_masterNavigationController.view];
        [_masterNavigationController didMoveToParentViewController:self];
    }
}

- (void)resetControllers
{
    if (_masterNavigationController.viewControllers.count > 1)
        [_masterNavigationController popToRootViewControllerAnimated:false];
    [self clearContentControllers];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_mainTabsController.presentedViewController != nil)
        return [_mainTabsController.presentedViewController preferredStatusBarStyle];
    
    if (_detailNavigationController.topViewController != nil) {
        return [_detailNavigationController.topViewController preferredStatusBarStyle];
    } else if (_masterNavigationController.topViewController != nil) {
        return [_masterNavigationController.topViewController preferredStatusBarStyle];
    } else {
        return [super preferredStatusBarStyle];
    }
}

- (BOOL)prefersStatusBarHidden
{
    if (!TGIsPad() && iosMajorVersion() >= 11 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        return true;
    
    if (_detailNavigationController.topViewController != nil) {
        return [_detailNavigationController.topViewController prefersStatusBarHidden];
    }
    if (_masterNavigationController.topViewController != nil) {
        return [_masterNavigationController.topViewController prefersStatusBarHidden];
    }
    return [super prefersStatusBarHidden];
}

- (SSignal *)sizeClass {
    return [_sizeClassVariable signal];
}

- (bool)isSplitView {
    if (iosMajorVersion() < 9 || !TGIsPad())
        return false;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
        return true;
    
    if (fabs(self.view.frame.size.width - [UIScreen mainScreen].bounds.size.width) > FLT_EPSILON)
        return true;
    
    return false;
}

- (bool)isSlideOver {
    if (![self isSplitView])
        return false;
    
    if (fabs(self.view.frame.size.height - [UIScreen mainScreen].bounds.size.height) > FLT_EPSILON)
        return true;
    
    return false;
}

- (CGRect)applicationBounds {
    CGSize screenSize = TGScreenSize();
    CGFloat min = MIN(screenSize.width, screenSize.height);
    CGFloat max = MAX(screenSize.width, screenSize.height);
    
    CGSize size = CGSizeZero;
    CGSize (^sizeByDeviceOrientation)(void) = ^CGSize {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            return CGSizeMake(min, max);
        else
            return CGSizeMake(max, min);
    };
    
    if (![self isSplitView])
        size = sizeByDeviceOrientation();
    else
        size = self.view.frame.size;
    
    return (CGRect){ CGPointZero, size };
}

- (UIUserInterfaceSizeClass)currentSizeClass {
    return _currentSizeClass;
}

- (bool)isRTL {
    static bool value = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (iosMajorVersion() >= 9) {
            value = [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:[self.view semanticContentAttribute]] == UIUserInterfaceLayoutDirectionRightToLeft;
        }
    });
    return value;
}

- (bool)callStatusBarHidden
{
    if (_callStatusBarView != nil)
        return _callStatusBarView.realHidden;
    return true;
}

#pragma mark - ASWatcher

- (void)actionStageResourceDispatched:(NSString *)path resource:(__unused id)resource arguments:(id)arguments
{
    if ([path isEqualToString:@"/tg/unreadCount"])
    {
        [self updateUnreadCountsIcludingBage:![arguments[@"previous"] boolValue]];
    }
}

#pragma mark - Helpers

- (void)updateUnreadCountsIcludingBage:(BOOL)includingBage
{
    dispatch_async(dispatch_get_main_queue(), ^{ // request to controller
        [TGDatabaseInstance() dispatchOnDatabaseThread:^{ // request to database
            int unreadCount = [TGDatabaseInstance() databaseState].unreadCount;
            NSArray<NSNumber *> *unreadCounts = TGDatabaseInstance().unreadCounts;
            TGDispatchOnMainThread(^{
                if (includingBage) {
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
                }
                if (unreadCount == 0)
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                
                _mainTabsController.unreadCounts = [unreadCounts arrayByAddingObject:@(_newsRssController.feedParser.unreadCount + _videosRssController.feedParser.unreadCount)];
                _cryptoTabViewController.unreadCounts = @[@0, @(_newsRssController.feedParser.unreadCount), @(_videosRssController.feedParser.unreadCount)];
            });
        } synchronous:false];
    });
}

@end
