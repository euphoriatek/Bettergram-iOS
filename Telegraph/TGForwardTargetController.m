#import "TGForwardTargetController.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGTelegraph.h"
#import "TGDialogListController.h"
#import "TGTelegraphDialogListCompanion.h"
#import "TGContactsController.h"

#import "TGInterfaceManager.h"
#import "TGInterfaceAssets.h"

#import "TGSendMessageSignals.h"

#import "TGDatabase.h"

#import "TGCustomAlertView.h"
#import "TGAlertView.h"

#import "TGAppDelegate.h"

#import "TGPresentation.h"

@interface TGForwardContactsController : TGContactsController

@property (nonatomic, strong) ASHandle *watcher;

@end

@implementation TGForwardContactsController

@synthesize watcher = _watcher;

- (void)singleUserSelected:(TGUser *)user
{
    [_watcher requestAction:@"userSelected" options:[NSDictionary dictionaryWithObjectsAndKeys:user, @"user", nil]];
}

@end

#pragma mark -

@interface TGForwardTargetController ()
{
    NSString *_confirmationCustomFormat;
    bool _targetMode;
    bool _privacyMode;
    bool _groupMode;
    bool _dialogsMode;
}

@property (nonatomic) bool blockMode;

@property (nonatomic, strong) UIView *toolbarContainerView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) TGDialogListController *dialogListController;
@property (nonatomic, strong) TGTelegraphDialogListCompanion *dialogListCompanion;
@property (nonatomic, strong) TGForwardContactsController *contactsController;

@property (nonatomic, strong) TGViewController *currentViewController;

@property (nonatomic, strong) id selectedTarget;

@property (nonatomic, strong) NSArray *forwardMessages;
@property (nonatomic, strong) NSDictionary *shareLink;
@property (nonatomic, strong) NSArray *sendMessages;
@property (nonatomic, strong) NSURL *documentFileUrl;
@property (nonatomic, strong) NSArray *documentFileDescs;

@end

@implementation TGForwardTargetController

- (id)initWithForwardMessages:(NSArray *)forwardMessages sendMessages:(NSArray *)sendMessages shareLink:(NSDictionary *)shareLink showSecretChats:(bool)showSecretChats
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _confirmationDefaultPersonFormat = TGLocalized(@"Conversation.ForwardToPersonFormat");
        _confirmationDefaultGroupFormat = TGLocalized(@"Conversation.ForwardToGroupFormat");
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.showSecretInForwardMode = showSecretChats;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _forwardMessages = forwardMessages;
        _sendMessages = sendMessages;
        _shareLink = shareLink;
    }
    return self;
}

- (id)initWithSelectBlockTarget
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _confirmationDefaultPersonFormat = _confirmationDefaultGroupFormat = @"%@";
        _controllerTitle = TGLocalized(@"BlockedUsers.BlockTitle");
        _blockMode = true;
    }
    return self;
}

- (id)initWithSelectPrivacyTarget:(NSString *)title placeholder:(NSString *)placeholder
{
    return [self initWithSelectPrivacyTarget:title placeholder:placeholder dialogs:false];
}

- (id)initWithSelectPrivacyTarget:(NSString *)title placeholder:(NSString *)placeholder dialogs:(bool)dialogs
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.privacyMode = true;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately | TGContactsModeCompose];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        _contactsController.composePlaceholder = placeholder;
        
        _controllerTitle = title;
        _privacyMode = true;
        _dialogsMode = dialogs;
    }
    return self;
}

- (id)initWithSelectTarget:(bool)showSecretChats
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.showSecretInForwardMode = showSecretChats;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _controllerTitle = TGLocalized(@"BroadcastListInfo.AddRecipient");
        _targetMode = true;
    }
    return self;
}

- (id)initWithSelectTarget {
    return [self initWithSelectTarget:true];
}

- (id)initWithSelectPrivate:(NSSet *)excludedIds
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        _groupMode = true;
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = false;
        _dialogListCompanion.showPrivateOnly = true;
        _dialogListCompanion.excludedIds = excludedIds;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.customSearchPlaceholder = @"Common.Search";
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _controllerTitle = TGLocalized(@"Notifications.AddExceptionTitle");
        _targetMode = true;
    }
    return self;
}

- (id)initWithSelectGroup:(NSSet *)excludedIds
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        _groupMode = true;
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = false;
        _dialogListCompanion.showGroupsAndChannelsOnly = true;
        _dialogListCompanion.excludedIds = excludedIds;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.customSearchPlaceholder = @"Common.Search";
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _controllerTitle = TGLocalized(@"Notifications.AddExceptionTitle");
        _targetMode = true;
    }
    return self;
}

- (id)initWithSelectGroup
{
    self = [super init];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        _groupMode = true;
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.filter = TGDialogFilterGroups;
        _dialogListCompanion.botStartMode = true;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _controllerTitle = TGLocalized(@"Target.SelectGroup");
        
        _confirmationDefaultPersonFormat = _confirmationDefaultGroupFormat = TGLocalized(@"Target.InviteToGroupConfirmation");
    }
    return self;
}

- (id)initWithDocumentFile:(NSURL *)fileUrl size:(int)size
{
    self = [super init];
    if (self != nil)
    {
        NSString *genericFormat = TGLocalized(@"Document.TargetConfirmationFormat");
        NSRange range = [genericFormat rangeOfString:@"{size}"];
        if (range.location != 0)
        {
            NSString *sizeString = nil;
            
            if (size < 1024)
                sizeString = [[NSString alloc] initWithFormat:@"%dB", size];
            else if (size < 1024 * 1024)
                sizeString = [[NSString alloc] initWithFormat:@"%dKB", size / 1024];
            else
                sizeString = [[NSString alloc] initWithFormat:@"%.2fMB", size / (1024.0f * 1024.0f)];
            
            genericFormat = [genericFormat stringByReplacingCharactersInRange:range withString:sizeString];
            
            NSRange targetRange = [genericFormat rangeOfString:@"{target}"];
            if (targetRange.location != NSNotFound)
                genericFormat = [genericFormat stringByReplacingCharactersInRange:targetRange withString:@"%@"];
            
            _confirmationCustomFormat = genericFormat;
        }
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _confirmationDefaultPersonFormat = TGLocalized(@"Conversation.ForwardToPersonFormat");
        _confirmationDefaultGroupFormat = TGLocalized(@"Conversation.ForwardToGroupFormat");
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.showSecretInForwardMode = true;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _documentFileUrl = fileUrl;
    }
    return self;
}

- (NSString *)stringForMultipleFilesConfirmation:(NSUInteger)count
{
    return [effectiveLocalization() getPluralized:@"Forward.ConfirmMultipleFiles" count:(int32_t)count];
}

- (id)initWithDocumentFiles:(NSArray *)fileDescs
{
    self = [super init];
    if (self != nil)
    {
        NSString *genericFormat = [self stringForMultipleFilesConfirmation:fileDescs.count];
            
        NSRange targetRange = [genericFormat rangeOfString:@"{target}"];
        if (targetRange.location != NSNotFound)
            genericFormat = [genericFormat stringByReplacingCharactersInRange:targetRange withString:@"%@"];
            
        _confirmationCustomFormat = genericFormat;
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _confirmationDefaultPersonFormat = TGLocalized(@"Conversation.ForwardToPersonFormat");
        _confirmationDefaultGroupFormat = TGLocalized(@"Conversation.ForwardToGroupFormat");
        
        _dialogListCompanion = [[TGTelegraphDialogListCompanion alloc] init];
        _dialogListCompanion.forwardMode = true;
        _dialogListCompanion.showSecretInForwardMode = true;
        _dialogListCompanion.conversatioSelectedWatcher = _actionHandle;
        _dialogListController = [[TGDialogListController alloc] initWithCompanion:_dialogListCompanion];
        _dialogListController.presentation = TGPresentation.current;
        _dialogListController.customParentViewController = self;
        _dialogListController.doNotHideSearchAutomatically = true;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/dialoglist/(%d)", INT_MAX] options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:25], @"limit", [NSNumber numberWithInt:INT_MAX], @"date", nil] watcher:_dialogListCompanion];
        
        _contactsController = [[TGForwardContactsController alloc] initWithContactsMode:TGContactsModeRegistered | TGContactsModeClearSelectionImmediately];
        _contactsController.presentation = TGPresentation.current;
        _contactsController.watcher = _actionHandle;
        _contactsController.customParentViewController = self;
        
        _documentFileDescs = fileDescs;
    }
    return self;
}

- (void)dealloc
{
    [self doUnloadView];
    
    _dialogListController.customParentViewController = nil;
    _contactsController.customParentViewController = nil;
    
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (UIBarStyle)requiredNavigationBarStyle
{
    if (_currentViewController != nil && [_currentViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance) ] && [_currentViewController respondsToSelector:@selector(requiredNavigationBarStyle)])
        return [(id<TGViewControllerNavigationBarAppearance>)_currentViewController requiredNavigationBarStyle];
    return UIBarStyleDefault;
}

- (bool)navigationBarShouldBeHidden
{
    if (_currentViewController != nil && [_currentViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance) ] && [_currentViewController respondsToSelector:@selector(navigationBarShouldBeHidden)])
        return [(id<TGViewControllerNavigationBarAppearance>)_currentViewController navigationBarShouldBeHidden];
    return false;
}

- (bool)shouldBeRemovedFromNavigationAfterHiding
{
    return true;
}

- (void)loadView
{
    [super loadView];
    
    self.titleText = _controllerTitle != nil ? _controllerTitle : TGLocalized(@"Conversation.ForwardTitle");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
    
    if (_contactsController != nil)
    {
        CGFloat offset = self.controllerSafeAreaInset.bottom;
        _toolbarContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44 - offset, self.view.frame.size.width, 44 + offset)];
        _toolbarContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        TGPresentation *presentation = TGPresentation.current;
        
        UIView *backgroundView = [TGBackdropView viewWithLightNavigationBarStyle];
        backgroundView.backgroundColor = presentation.pallete.barBackgroundColor;
        backgroundView.frame = _toolbarContainerView.bounds;
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_toolbarContainerView addSubview:backgroundView];
        
        UIView *stripeView = [[UIView alloc] init];
        stripeView.frame = CGRectMake(0.0f, 0.0f, _toolbarContainerView.frame.size.width, TGScreenPixel);
        stripeView.backgroundColor = presentation.pallete.barSeparatorColor;
        stripeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_toolbarContainerView addSubview:stripeView];
        
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[TGLocalized(@"DialogList.TabTitle"), TGLocalized(@"Contacts.TabTitle")]];
        _segmentedControl.frame = CGRectMake(CGFloor((_toolbarContainerView.frame.size.width - 182.0f) / 2), 8, 182.0f, 29.0f);
        _segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        [_segmentedControl setPallete:presentation.segmentedControlPallete];
        
        [_segmentedControl setSelectedSegmentIndex:0];
        [_segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];
        
        [_toolbarContainerView addSubview:_segmentedControl];
        
        if (_privacyMode && !_dialogsMode)
        {
            [self setCurrentViewController:_contactsController];
            [_segmentedControl setSelectedSegmentIndex:1];
        }
        else
            [self setCurrentViewController:_dialogListController];
        
        [self.view addSubview:_toolbarContainerView];
    }
    else
    {
        [self setCurrentViewController:_dialogListController];
    }
}

- (void)controllerInsetUpdated:(UIEdgeInsets)previousInset
{
    [super controllerInsetUpdated:previousInset];
    
    CGFloat offset = self.controllerSafeAreaInset.bottom;
    _toolbarContainerView.frame = CGRectMake(0, self.view.frame.size.height - 44 - offset, self.view.frame.size.width, 44 + offset);
}

- (void)viewWillAppear:(BOOL)animated
{
    CGFloat offset = self.controllerSafeAreaInset.bottom;
    _toolbarContainerView.frame = CGRectMake(0, self.view.frame.size.height - 44 - offset, self.view.frame.size.width, 44 + offset);
    _segmentedControl.frame = CGRectMake(CGFloor((_toolbarContainerView.frame.size.width - 182.0f) / 2), 8, 182.0f, 29.0f);
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (iosMajorVersion() < 7)
        [self.view.window makeKeyWindow];
}

- (void)doUnloadView
{
    [self setCurrentViewController:nil];
    
    if (_dialogListController.isViewLoaded)
        _dialogListController.view = nil;
    if (_contactsController.isViewLoaded)
        _contactsController.view = nil;
}

- (void)setCurrentViewController:(TGViewController *)currentViewController
{
    if (_currentViewController != nil)
    {
        [_currentViewController willMoveToParentViewController:nil];
        [_currentViewController.view removeFromSuperview];
        [_currentViewController removeFromParentViewController];
        [_currentViewController didMoveToParentViewController:nil];
    }
    
    _currentViewController = currentViewController;
    
    if (_currentViewController != nil)
    {
        _currentViewController.parentInsets = UIEdgeInsetsMake(0, 0, _toolbarContainerView.frame.size.height, 0);
        
        [_currentViewController willMoveToParentViewController:self];
        [_currentViewController.view setFrame:self.view.bounds];
        [self.view insertSubview:_currentViewController.view atIndex:0];
        [self addChildViewController:_currentViewController];
        [_currentViewController didMoveToParentViewController:self];
    }
    
    if (_privacyMode)
    {
        if (currentViewController == _contactsController)
        {
            [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)]];
        }
        else
            [self setRightBarButtonItem:nil];
    }
}

- (void)donePressed
{
    if (_privacyMode)
    {
        [_watcherHandle requestAction:@"multipleUsersSelected" options:_contactsController.selectedComposeUsers];
    }
}

/*- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    _toolbarContainerView.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    if (_currentViewController != nil)
    {
        [_currentViewController.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - _toolbarContainerView.frame.size.height)];
    }
}*/

#pragma mark -

- (void)doneButtonPressed
{
    [self dismissSelf];
}

- (void)dismissSelf
{
    [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.childViewControllers.count != 0)
        return [self.childViewControllers[0] preferredStatusBarStyle];
    
    return [super preferredStatusBarStyle];
}

- (void)segmentedControlChanged
{
    int index = (int)_segmentedControl.selectedSegmentIndex;
    
    if (index == 0)
    {
        if (_currentViewController != _dialogListController)
            [self setCurrentViewController:_dialogListController];
    }
    else if (index == 1)
    {
        if (_currentViewController != _contactsController)
            [self setCurrentViewController:_contactsController];
    }
}

#pragma mark -

- (void)actionStageActionRequested:(NSString *)action options:(NSDictionary *)options
{
    if ([action isEqualToString:@"userSelected"])
    {
        TGUser *user = [options objectForKey:@"user"];
        if (user != nil)
        {
            if (_blockMode || _privacyMode)
            {
                [_watcherHandle requestAction:@"blockUser" options:user];
            }
            else
            {
                _selectedTarget = user;
                
                if (_targetMode)
                {
                    [_watcherHandle requestAction:@"userSelected" options:user];
                }
                else
                {
                    if (!_skipConfirmation)
                    {
                        NSString *alertText = nil;
                        if (_confirmationCustomFormat != nil)
                            alertText = [[NSString alloc] initWithFormat:_confirmationCustomFormat, user.displayName];
                        else
                            alertText = [NSString stringWithFormat:_confirmationDefaultPersonFormat, user.displayName];
                     
                         __weak TGForwardTargetController *weakSelf = self;
                         [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.No") okButtonTitle:TGLocalized(@"Common.Yes") completionBlock:^(bool okButtonPressed)
                          {
                              __strong TGForwardTargetController *strongSelf = weakSelf;
                              [strongSelf alertViewFinished:okButtonPressed];
                          }];
                    }
                    else
                    {
                        [self confirmAction];
                    }
                }
            }
        }
    }
    else if ([action isEqualToString:@"conversationSelected"])
    {
        TGConversation *conversation = [options objectForKey:@"conversation"];
        if (conversation != nil)
        {
            _selectedTarget = conversation;
        
            if (_targetMode)
            {
                if (conversation.isChat || conversation.isChannel || conversation.isChannelGroup)
                    [_watcherHandle requestAction:@"conversationSelected" options:conversation];
                else
                {
                    TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)conversation.conversationId];
                    if (user != nil)
                        [_watcherHandle requestAction:@"userSelected" options:user];
                }
            }
            else
            {
                if ((conversation.isChat && conversation.conversationId > INT_MIN) || conversation.isChannel)
                {
                    _selectedTarget = conversation;
                    
                    if (!_skipConfirmation)
                    {
                        NSString *alertText = nil;
                        if (_privacyMode)
                        {
                            NSString *alertText = [effectiveLocalization() getPluralized:@"PrivacyLastSeenSettings.AddUsers" count:(int32_t)conversation.chatParticipants.chatParticipantUids.count];
                            
                            __weak TGForwardTargetController *weakSelf = self;
                            [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.No") okButtonTitle:TGLocalized(@"Common.Yes") completionBlock:^(bool okButtonPressed)
                             {
                                 __strong TGForwardTargetController *strongSelf = weakSelf;
                                 [strongSelf alertViewFinished:okButtonPressed];
                             }];
                        }
                        else
                        {
                            if (_blockMode) {
                                NSString *prefix = TGLocalized(@"BlockedUsers.LeavePrefix");
                                if ([prefix rangeOfString:@" "].location == NSNotFound) {
                                    prefix = [prefix stringByAppendingString:@" "];
                                }
                                alertText = [NSString stringWithFormat:@"%@\"%@\"?", prefix, conversation.chatTitle];
                            }
                            else if (_confirmationCustomFormat != nil)
                                alertText = [[NSString alloc] initWithFormat:_confirmationCustomFormat, conversation.chatTitle];
                            else
                                alertText = [NSString stringWithFormat:_confirmationDefaultGroupFormat, conversation.chatTitle];
                            
                            __weak TGForwardTargetController *weakSelf = self;
                            [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.No") okButtonTitle:TGLocalized(@"Common.Yes") completionBlock:^(bool okButtonPressed)
                             {
                                 __strong TGForwardTargetController *strongSelf = weakSelf;
                                 [strongSelf alertViewFinished:okButtonPressed];
                             }];
                        }
                    }
                    else
                        [self confirmAction];
                }
                else
                {
                    int uid = 0;
                    
                    if (conversation.isChat)
                    {
                        if (conversation.chatParticipants.chatParticipantUids.count != 0)
                            uid = [conversation.chatParticipants.chatParticipantUids[0] intValue];
                    }
                    else
                        uid = (int)conversation.conversationId;
                    
                    TGUser *user = [TGDatabaseInstance() loadUser:uid];
                    if (user != nil)
                    {
                        if (_blockMode || _privacyMode)
                        {
                            [_watcherHandle requestAction:@"blockUser" options:user];
                        }
                        else
                        {
                            _selectedTarget = conversation.isChat ? conversation : user;
                            
                            if (!_skipConfirmation)
                            {
                                NSString *alertText = nil;
                                if (_confirmationCustomFormat != nil)
                                    alertText = [[NSString alloc] initWithFormat:_confirmationCustomFormat, user.displayName];
                                else
                                    alertText = [NSString stringWithFormat:_confirmationDefaultPersonFormat, user.displayName];
                                
                                __weak TGForwardTargetController *weakSelf = self;
                                [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.No") okButtonTitle:TGLocalized(@"Common.Yes") completionBlock:^(bool okButtonPressed)
                                {
                                    __strong TGForwardTargetController *strongSelf = weakSelf;
                                    [strongSelf alertViewFinished:okButtonPressed];
                                }];
                            }
                            else
                                [self confirmAction];
                        }
                    }
                }
            }
        }
    }
}

- (void)alertViewFinished:(bool)okButtonPressed
{
    if (okButtonPressed && _selectedTarget != nil)
    {
        if (_blockMode || _privacyMode)
        {
            if ([_selectedTarget isKindOfClass:[TGUser class]])
                [_watcherHandle requestAction:@"blockUser" options:_selectedTarget];
            else if ([_selectedTarget isKindOfClass:[TGConversation class]])
                [_watcherHandle requestAction:@"leaveConversation" options:_selectedTarget];
        }
        else
        {
            [self confirmAction];
        }
    }
}

- (void)confirmAction
{
    if ([_selectedTarget isKindOfClass:[TGConversation class]])
    {
        TGConversation *conversation = (TGConversation *)_selectedTarget;
        if (conversation.isChannel && !conversation.currentUserCanSendMessages) {
            [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Forward.ChannelReadOnly") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
            return;
        }
    }
    
    id<ASWatcher> watcher = _watcherHandle.delegate;
    if (watcher != nil && [watcher respondsToSelector:@selector(actionStageActionRequested:options:)])
        [watcher actionStageActionRequested:@"willForwardMessages" options:[[NSDictionary alloc] initWithObjectsAndKeys:self, @"controller", _selectedTarget, @"target", nil]];
    
    if (watcher == nil || _doNothing) {
        [self dismissSelf];
    }
 
    if (!_groupMode)
    {
        if (_documentFileDescs != nil)
        {
            if ([_selectedTarget isKindOfClass:[TGUser class]])
            {
                TGUser *user = (TGUser *)_selectedTarget;
                [[TGInterfaceManager instance] navigateToConversationWithId:user.uid conversation:nil performActions:@{@"forwardMessages": [NSArray arrayWithArray:_forwardMessages], @"sendFiles": _documentFileDescs} animated:false];
            }
            else if ([_selectedTarget isKindOfClass:[TGConversation class]])
            {
                TGConversation *conversation = (TGConversation *)_selectedTarget;
                [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:nil performActions:@{@"forwardMessages": [NSArray arrayWithArray:_forwardMessages], @"sendFiles": _documentFileDescs} animated:false];
            }
        }
        else
        {
            if ([_selectedTarget isKindOfClass:[TGUser class]])
            {
                TGUser *user = (TGUser *)_selectedTarget;
                
                if (user.uid == TGTelegraphInstance.clientUserId && _forwardMessages.count > 0)
                {
                    NSMutableArray *batches = [[NSMutableArray alloc] init];
                    NSUInteger i = 0;
                    int64_t currentGroupedId = 0;
                    int64_t currentPeerId = 0;
                    NSMutableDictionary *accessHashes = [[NSMutableDictionary alloc] init];
                    for (TGMessage *message in _forwardMessages)
                    {
                        int64_t peerId = message.cid;
                        int64_t accessHash = 0;
                        if (accessHashes[@(peerId)] != nil) {
                            accessHash = [accessHashes[@(peerId)] int64Value];
                        } else {
                            accessHash = [TGDatabaseInstance() loadConversationWithId:peerId].accessHash;
                            accessHashes[@(peerId)] = @(accessHash);
                        }
                        
                        int64_t groupedId = 0;
                        if (message.groupedId != 0 && [self.completeGroups containsObject:@(message.groupedId)])
                            groupedId = message.groupedId;
                        
                        if ((groupedId != currentGroupedId || currentPeerId != peerId) && batches.count > 0)
                            i++;
                        
                        currentPeerId = peerId;
                        currentGroupedId = groupedId;
                        
                        NSMutableArray *batch = nil;
                        if (batches.count > i)
                        {
                            batch = batches[i][@"items"];
                        }
                        else
                        {
                            batch = [[NSMutableArray alloc] init];
                            NSDictionary *batchDict = @{@"items": batch, @"peerId": @(peerId), @"accessHash": @(accessHash), @"grouped": @(currentGroupedId != 0)};
                            [batches addObject:batchDict];
                        }
                        
                        [batch addObject:@(message.mid)];
                    }
                    
                    for (NSDictionary *batch in batches)
                    {
                        bool grouped = [batch[@"grouped"] boolValue];
                        int64_t fromPeerId = [batch[@"peerId"] int64Value];
                        int64_t fromPeerAccessHash = [batch[@"accessHash"] int64Value];
                        [[TGSendMessageSignals forwardMessagesWithMessageIds:batch[@"items"] toPeerIds:@[@(user.uid)] fromPeerId:fromPeerId fromPeerAccessHash:fromPeerAccessHash grouped:grouped] startWithNext:nil];
                    }
                    
                    [[[TGProgressWindow alloc] init] dismissWithSuccess];
                    
                    [TGAppDelegateInstance.rootController.dialogListControllers[0] requestSavedMessagesTooltip];
                }
                else
                {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"forwardMessages": [NSArray arrayWithArray:_forwardMessages], @"sendMessages": [NSArray arrayWithArray:_sendMessages], @"sendFiles": _documentFileUrl == nil ? @[] : @[@{@"url": _documentFileUrl}], @"shareLink": _shareLink == nil ? @{} : _shareLink}];
                    if (_shareLink[@"text"] != nil && [_shareLink[@"replace"] boolValue]) {
                        dict[@"replaceInitialText"] = _shareLink[@"text"];
                    }
                    
                    if (self.completeGroups != nil)
                        dict[@"completeGroups"] = self.completeGroups;
                    
                    [[TGInterfaceManager instance] navigateToConversationWithId:user.uid conversation:nil performActions:dict atMessage:nil clearStack:true openKeyboard:[_shareLink[@"replace"] boolValue] canOpenKeyboardWhileInTransition:false animated:true];
                }
            }
            else if ([_selectedTarget isKindOfClass:[TGConversation class]])
            {
                TGConversation *conversation = (TGConversation *)_selectedTarget;
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"forwardMessages": [NSArray arrayWithArray:_forwardMessages], @"sendMessages": [NSArray arrayWithArray:_sendMessages], @"sendFiles": _documentFileUrl == nil ? @[] : @[@{@"url": _documentFileUrl}], @"shareLink": _shareLink == nil ? @{} : _shareLink}];
                if (_shareLink[@"text"] != nil && [_shareLink[@"replace"] boolValue]) {
                    dict[@"replaceInitialText"] = _shareLink[@"text"];
                }
                
                if (self.completeGroups != nil)
                    dict[@"completeGroups"] = self.completeGroups;
                
                [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:nil performActions:dict atMessage:nil clearStack:true openKeyboard:[_shareLink[@"replace"] boolValue]canOpenKeyboardWhileInTransition:false animated:true];
            }
        }
    }
}

- (TGContactsController *)contactsController
{
    return _contactsController;
}

@end
