#import "TGChannelInfoController.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGLegacyComponentsContext.h"

#import <LegacyComponents/ActionStage.h>
#import <LegacyComponents/SGraphObjectNode.h>

#import "TGDatabase.h"

#import <LegacyComponents/UIDevice+PlatformInfo.h>
#import "TGInterfaceAssets.h"

#import "TGAppDelegate.h"
#import "TGTelegraph.h"
#import "TGTelegramNetworking.h"

#import "TGInterfaceManager.h"
#import "TGTelegraphDialogListCompanion.h"
#import "TGConversationChangeTitleRequestActor.h"
#import "TGConversationChangePhotoActor.h"

#import "TGHeaderCollectionItem.h"
#import "TGSwitchCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGButtonCollectionItem.h"
#import "TGCommentCollectionItem.h"
#import "TGGroupInfoCollectionItem.h"
#import "TGGroupInfoUserCollectionItem.h"

#import "TGTelegraphUserInfoController.h"
#import "TGGroupInfoSelectContactController.h"
#import "TGBotUserInfoController.h"
#import "TGAlertSoundController.h"

#import <LegacyComponents/TGRemoteImageView.h>

#import "TGCustomAlertView.h"
#import "TGCustomActionSheet.h"

#import <LegacyComponents/TGModernGalleryController.h>
#import "TGGroupAvatarGalleryItem.h"
#import "TGGroupAvatarGalleryModel.h"

#import "TGUserInfoVariantCollectionItem.h"
#import "TGUserInfoTextCollectionItem.h"
#import "TGUserInfoUsernameCollectionItem.h"
#import "TGUserInfoButtonCollectionItem.h"

#import "TGSharedMediaController.h"

#import <LegacyComponents/TGTimerTarget.h>

#import "TGGroupManagementSignals.h"
#import <LegacyComponents/TGProgressWindow.h>

#import "TGGroupInfoShareLinkController.h"

#import "TGChannelLinkSetupController.h"
#import "TGChannelAboutSetupController.h"

#import "TGChannelManagementSignals.h"

#import "TGChannelMembersController.h"

#import "TGAccountSignals.h"

#import "TGReportPeerOtherTextController.h"

#import <LegacyComponents/TGMediaAvatarMenuMixin.h>
#import "TGWebSearchController.h"

#import "TGCollectionMultilineInputItem.h"

#import "TGShareMenu.h"
#import "TGSendMessageSignals.h"

#import <SafariServices/SafariServices.h>
#import "TGOpenInMenu.h"
#import "TGPresentation.h"

@interface TGChannelInfoController () <TGGroupInfoSelectContactControllerDelegate, TGAlertSoundControllerDelegate, ASWatcher>
{
    bool _editing;
    
    int64_t _peerId;
    TGConversation *_conversation;
    
    TGCollectionMenuSection *_groupInfoSection;
    
    TGGroupInfoCollectionItem *_groupInfoItem;
    TGButtonCollectionItem *_setGroupPhotoItem;
    
    TGCollectionMenuSection *_infoSection;
    TGUserInfoTextCollectionItem *_aboutItem;
    TGUserInfoUsernameCollectionItem *_linkItem;
    
    TGCollectionMenuSection *_leaveSection;
    TGUserInfoButtonCollectionItem *_leaveItem;
    
    TGCollectionMenuSection *_adminInfoSection;
    TGUserInfoVariantCollectionItem *_infoManagementItem;
    TGUserInfoVariantCollectionItem *_infoBlacklistItem;
    TGUserInfoVariantCollectionItem *_infoMembersItem;
    
    TGCollectionMenuSection *_editingInfoSection;
    TGCollectionMultilineInputItem *_channelAboutItem;
    TGVariantCollectionItem *_channelLinkItem;
    
    TGCollectionMenuSection *_editingSignMessagesSection;
    TGSwitchCollectionItem *_signMessagesItem;
    
    TGCollectionMenuSection *_deleteChannelSection;
    TGButtonCollectionItem *_deleteChannelItem;
    
    TGCollectionMenuSection *_notificationsAndMediaSection;
    TGUserInfoVariantCollectionItem *_notificationsItem;
    TGVariantCollectionItem *_editingNotificationsItem;
    TGVariantCollectionItem *_soundItem;
    TGUserInfoVariantCollectionItem *_sharedMediaItem;
    
    NSMutableDictionary *_defaultNotificationSettings;
    NSMutableDictionary *_groupNotificationSettings;
    NSInteger _sharedMediaCount;
    
    NSTimer *_muteExpirationTimer;
    
    id<SDisposable> _completeInfoDisposable;
    id<SDisposable> _cachedDataDisposable;
    SDisposableSet *_genericDisposables;
    
    NSString *_privateLink;
    
    TGMediaAvatarMenuMixin *_avatarMixin;
    bool _checked3dTouch;
    
    TGUserInfoButtonCollectionItem *_favoriteInfoItem;
}

@property (nonatomic, strong) ASHandle *actionHandle;

@end

@implementation TGChannelInfoController

- (instancetype)initWithPeerId:(int64_t)peerId
{
    self = [super init];
    if (self != nil)
    {
        __weak TGChannelInfoController *weakSelf = self;
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Back") style:UIBarButtonItemStylePlain target:self action:@selector(backPressed)];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _peerId = peerId;
        _groupNotificationSettings = [[NSMutableDictionary alloc] initWithDictionary:@{@"muteUntil": @(0), @"soundId": @(1)}];
        
        TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:_peerId];
        
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editPressed)] animated:false];
        
        [self setTitleText:TGLocalized(@"Channel.TitleInfo")];
        
        _groupInfoItem = [[TGGroupInfoCollectionItem alloc] init];
        _groupInfoItem.interfaceHandle = _actionHandle;
        _groupInfoItem.transparent = true;
        _groupInfoItem.isChannel = true;
        
        _setGroupPhotoItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.UpdatePhotoItem") action:@selector(setGroupPhotoPressed)];
        _setGroupPhotoItem.titleColor = self.presentation.pallete.collectionMenuAccentColor;
        _setGroupPhotoItem.deselectAutomatically = true;
        
        NSMutableArray *infoSectionItems = [[NSMutableArray alloc] init];
        [infoSectionItems addObject:_groupInfoItem];
        
        _groupInfoSection = [[TGCollectionMenuSection alloc] initWithItems:infoSectionItems];
        _groupInfoSection.insets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        
        NSString *linkText = _conversation.username.length == 0 ? @"" : [@"https://t.me/" stringByAppendingString:_conversation.username];
        _aboutItem = [[TGUserInfoTextCollectionItem alloc] init];
        _aboutItem.title = TGLocalized(@"Channel.Info.Description");
        _aboutItem.text = _conversation.about;
        _aboutItem.highlightLinks = true;
        _aboutItem.followLink = ^(NSString *link) {
            TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf followLink:link];
            }
        };
        _aboutItem.holdLink = ^(NSString *link) {
            TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf holdLink:link];
            }
        };
        _linkItem = [[TGUserInfoUsernameCollectionItem alloc] initWithLabel:TGLocalized(@"Channel.LinkItem") username:linkText];
        _linkItem.lastInList = true;
        _linkItem.action = @selector(sharePressed);
        _infoSection = [[TGCollectionMenuSection alloc] initWithItems:@[_aboutItem, _linkItem]];
        _infoSection.insets = UIEdgeInsetsMake(1.0f, 0.0f, 22.0f, 0.0f);
        
        TGUserInfoButtonCollectionItem *reportChannelItem = [[TGUserInfoButtonCollectionItem alloc] initWithTitle:TGLocalized(@"ReportPeer.Report") action:@selector(reportChannelPressed)];
        reportChannelItem.deselectAutomatically = true;
        
        _leaveItem = [[TGUserInfoButtonCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.LeaveChannel") action:@selector(leavePressed)];
        _leaveItem.titleColor = self.presentation.pallete.collectionMenuDestructiveColor;
        _leaveItem.deselectAutomatically = true;
        _leaveSection = [[TGCollectionMenuSection alloc] initWithItems:@[reportChannelItem, _leaveItem]];
        
        _deleteChannelItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"ChannelInfo.DeleteChannel") action:@selector(deleteChannelPressed)];
        _deleteChannelItem.titleColor = self.presentation.pallete.collectionMenuDestructiveColor;
        _deleteChannelItem.deselectAutomatically = true;
        _deleteChannelSection = [[TGCollectionMenuSection alloc] initWithItems:@[_deleteChannelItem]];
        
        _infoManagementItem = [[TGUserInfoVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.Info.Management") variant:@"" action:@selector(infoManagementPressed)];
        _infoBlacklistItem = [[TGUserInfoVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.Info.BlackList") variant:@"" action:@selector(infoBlacklistPressed)];
        _infoMembersItem = [[TGUserInfoVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.Info.Subscribers") variant:@"" action:@selector(infoMembersPressed)];
        _adminInfoSection = [[TGCollectionMenuSection alloc] initWithItems:@[_infoManagementItem, _infoMembersItem]];
        
        _channelAboutItem = [[TGCollectionMultilineInputItem alloc] init];
        _channelAboutItem.placeholder = TGLocalized(@"Channel.About.Placeholder");
        _channelAboutItem.text = _conversation.about;
        _channelAboutItem.textChanged = ^(__unused NSString *text) {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf.collectionLayout invalidateLayout];
                [strongSelf.collectionView layoutSubviews];
            }
        };
        _channelAboutItem.maxLength = 200;
        
        _channelLinkItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.Edit.LinkItem") action:@selector(linkPressed)];
        _channelLinkItem.variant = _conversation.username.length == 0 ? @"" : [@"/" stringByAppendingString:_conversation.username];
        
        _editingInfoSection = [[TGCollectionMenuSection alloc] initWithItems:@[_channelLinkItem, _channelAboutItem, [[TGCommentCollectionItem alloc] initWithFormattedText:TGLocalized(@"Channel.About.Help")]]];
        
        _signMessagesItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"Channel.SignMessages") isOn:false];
        _signMessagesItem.toggled = ^(bool value, __unused TGSwitchCollectionItem *item) {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf updateSignMessages:value];
            }
        };
        _editingSignMessagesSection = [[TGCollectionMenuSection alloc] initWithItems:@[_signMessagesItem, [[TGCommentCollectionItem alloc] initWithFormattedText:TGLocalized(@"Channel.SignMessages.Help")]]];
        
        _favoriteInfoItem = [[TGUserInfoButtonCollectionItem alloc] initWithTitle:conversation.isFavorited ? TGLocalized(@"UserInfo.Unfavorite") : TGLocalized(@"UserInfo.Favorite") action:@selector(favoriteInfoPressed)];
        _favoriteInfoItem.deselectAutomatically = true;
        _favoriteInfoItem.titleColor = self.presentation.pallete.collectionMenuAccentColor;
        
        _notificationsItem = [[TGUserInfoVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Notifications") variant:nil action:@selector(notificationsPressed)];
        _notificationsItem.deselectAutomatically = true;
        _editingNotificationsItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Notifications") variant:nil action:@selector(notificationsPressed)];
        _editingNotificationsItem.deselectAutomatically = true;
        _soundItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Sound") variant:nil action:@selector(soundPressed)];
        _soundItem.deselectAutomatically = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        
        _sharedMediaItem = [[TGUserInfoVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.SharedMedia") variant:@"" action:@selector(sharedMediaPressed)];
        
        _notificationsAndMediaSection = [[TGCollectionMenuSection alloc] initWithItems:@[
            _favoriteInfoItem,
            _notificationsItem, _sharedMediaItem
            ]];
        UIEdgeInsets notificationsAndMediaSectionInsets = _notificationsAndMediaSection.insets;
        notificationsAndMediaSectionInsets.bottom = 22.0f;
        _notificationsAndMediaSection.insets = notificationsAndMediaSectionInsets;
        
        [self _loadUsersAndUpdateConversation:conversation];
        
        [self _updateNotificationItems:false];
        [self _updateSharedMediaCount];
        
        int64_t accessHash = _conversation.accessHash;
        [ActionStageInstance() dispatchOnStageQueue:^
         {
             [ActionStageInstance() watchForPaths:@[
                                                    [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _peerId],
                                                    //@"/tg/userdatachanges",
                                                    //@"/tg/userpresencechanges",
                                                    //@"/as/updateRelativeTimestamps",
                                                    //[[NSString alloc] initWithFormat:@"/tg/sharedMediaCount/(%" PRIx64 ")", (int64_t)_conversationId]
                                                    ] watcher:self];
             
             [ActionStageInstance() watchForPath:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ")", _peerId] watcher:self];
             [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ",cachedOnly)", _peerId] options:@{@"peerId": @(_peerId), @"accessHash": @(accessHash)} watcher:self];
             
             [ActionStageInstance() watchForPath:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId32 ")", INT_MAX - 2] watcher:self];
             [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%d,cachedOnly)", INT_MAX - 2] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:INT_MAX - 2] forKey:@"peerId"] watcher:self];
             
             NSArray *changeTitleActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/changeTitle/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _peerId] watcher:self];
             NSArray *changeAvatarActions = [ActionStageInstance() rejoinActionsWithGenericPathNow:@"/tg/conversation/@/updateAvatar/@" prefix:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")", _peerId] watcher:self];
             
             NSString *updatingTitle = nil;
             if (changeTitleActions.count != 0)
             {
                 NSString *action = [changeTitleActions lastObject];
                 TGConversationChangeTitleRequestActor *actor = (TGConversationChangeTitleRequestActor *)[ActionStageInstance() executingActorWithPath:action];
                 if (actor != nil)
                     updatingTitle = actor.currentTitle;
             }
             
             UIImage *updatingAvatar = nil;
             bool haveUpdatingAvatar = false;
             if (changeAvatarActions.count != 0)
             {
                 NSString *action = [changeAvatarActions lastObject];
                 TGConversationChangePhotoActor *actor = (TGConversationChangePhotoActor *)[ActionStageInstance() executingActorWithPath:action];
                 if (actor != nil)
                 {
                     updatingAvatar = actor.currentImage;
                     haveUpdatingAvatar = true;
                 }
             }
             
             if (changeTitleActions.count != 0 || changeAvatarActions.count != 0)
             {
                 TGDispatchOnMainThread(^ {
                     [_groupInfoItem setUpdatingTitle:updatingTitle];
                     
                     [_groupInfoItem setUpdatingAvatar:updatingAvatar hasUpdatingAvatar:haveUpdatingAvatar];
                     [_setGroupPhotoItem setEnabled:!haveUpdatingAvatar];
                     
                     [self _loadUsersAndUpdateConversation:_conversation];
                 });
             }
         }];
        
        _completeInfoDisposable = [[TGChannelManagementSignals updateChannelExtendedInfo:_conversation.conversationId accessHash:_conversation.accessHash updateUnread:true] startWithNext:nil];
        
        _cachedDataDisposable = [[[TGDatabaseInstance() channelCachedData:_conversation.conversationId] deliverOn:[SQueue mainQueue]] startWithNext:^(TGCachedConversationData *cachedData) {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil && cachedData != nil) {
                [strongSelf->_infoManagementItem setVariant:[[NSString alloc] initWithFormat:@"%d", cachedData.managementCount]];
                [strongSelf->_infoBlacklistItem setVariant:[[NSString alloc] initWithFormat:@"%d", cachedData.blacklistCount]];
                [strongSelf->_infoMembersItem setVariant:[[NSString alloc] initWithFormat:@"%d", cachedData.memberCount]];
                strongSelf->_privateLink = cachedData.privateLink;
            }
        }];
        
        _genericDisposables = [[SDisposableSet alloc] init];
        
        [self _setupSections:false];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [super setPresentation:presentation];
    
    _leaveItem.titleColor = self.presentation.pallete.collectionMenuDestructiveColor;
    _deleteChannelItem.titleColor = self.presentation.pallete.collectionMenuDestructiveColor;
    _setGroupPhotoItem.titleColor = self.presentation.pallete.collectionMenuAccentColor;
    
    self.view.backgroundColor = _editing ? self.presentation.pallete.collectionMenuBackgroundColor : self.presentation.pallete.backgroundColor;
    self.collectionView.backgroundColor = self.presentation.pallete.backgroundColor;
}

- (void)_setupSections:(bool)editing {
    while (self.menuSections.sections.count != 0) {
        [self.menuSections deleteSection:0];
    }
    
    if (editing) {
        _groupInfoSection.insets = UIEdgeInsetsMake(0.0f, 0.0f, 35.0f, 0.0f);
        _groupInfoItem.transparent = false;
        if (_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canChangeInfo) {
            if ([_groupInfoSection indexOfItem:_setGroupPhotoItem] == NSNotFound) {
                [_groupInfoSection insertItem:_setGroupPhotoItem atIndex:1];
            }
        } else {
            [_groupInfoSection deleteItem:_setGroupPhotoItem];
        }
        
        [self.menuSections addSection:_groupInfoSection];
        
        while (_editingInfoSection.items.count != 0) {
            [_editingInfoSection deleteItemAtIndex:0];
        }
        
        if (_conversation.channelRole == TGChannelRoleCreator) {
            [_editingInfoSection addItem:_channelLinkItem];
        }
        
        if (_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canChangeInfo) {
            [_editingInfoSection addItem:_channelAboutItem];
            [_editingInfoSection addItem:[[TGCommentCollectionItem alloc] initWithFormattedText:TGLocalized(@"Channel.About.Help")]];
        }
        
        if (_editingInfoSection.items.count != 0) {
            [self.menuSections addSection:_editingInfoSection];
        }
        
        if (_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canChangeInfo) {
            [self.menuSections addSection:_editingSignMessagesSection];
        }
        
        while (_notificationsAndMediaSection.items.count != 0) {
            [_notificationsAndMediaSection deleteItemAtIndex:0];
        }
        
        [_notificationsAndMediaSection addItem:_editingNotificationsItem];
        [_notificationsAndMediaSection addItem:_soundItem];
        
        [self.menuSections addSection:_notificationsAndMediaSection];
        
        if (_conversation.channelRole == TGChannelRoleCreator) {
            [self.menuSections addSection:_deleteChannelSection];
        }
        
        self.collectionView.backgroundColor = self.presentation.pallete.collectionMenuBackgroundColor;
    } else {
        _groupInfoItem.transparent = true;
        [_groupInfoSection deleteItem:_setGroupPhotoItem];
        _groupInfoSection.insets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        
        [self.menuSections addSection:_groupInfoSection];
        [self.menuSections addSection:_infoSection];
        
        while (_adminInfoSection.items.count != 0) {
            [_adminInfoSection deleteItemAtIndex:0];
        }
        
        if (_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.hasAnyRights) {
            [_adminInfoSection addItem:_infoManagementItem];
            
            if (_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canBanUsers) {
                [_adminInfoSection addItem:_infoBlacklistItem];
            }
            
            [_adminInfoSection addItem:_infoMembersItem];
        }
        
        if (_adminInfoSection.items.count != 0) {
            [self.menuSections addSection:_adminInfoSection];
        }
        
        while (_notificationsAndMediaSection.items.count != 0) {
            [_notificationsAndMediaSection deleteItemAtIndex:0];
        }
        
        [_notificationsAndMediaSection addItem:_favoriteInfoItem];
        [_notificationsAndMediaSection addItem:_notificationsItem];
        [_notificationsAndMediaSection addItem:_sharedMediaItem];
        
        [self.menuSections addSection:_notificationsAndMediaSection];
        
        if (_conversation.kind == TGConversationKindPersistentChannel) {
            [self.menuSections addSection:_leaveSection];
        }
        self.collectionView.backgroundColor = self.presentation.pallete.backgroundColor;
    }
    
    [self.collectionView reloadData];
}

- (void)backPressed
{
    [self.navigationController popViewControllerAnimated:true];
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
    
    [_completeInfoDisposable dispose];
    [_cachedDataDisposable dispose];
    [_genericDisposables dispose];
}

#pragma mark -

- (void)_resetCollectionView
{
    [super _resetCollectionView];
    
    self.view.backgroundColor = self.presentation.pallete.backgroundColor;
    self.collectionView.backgroundColor = self.presentation.pallete.backgroundColor;
    [self.collectionView setAllowEditingCells:false animated:false];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self check3DTouch];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark -

- (void)editPressed
{
    if (!_editing)
    {
        _editing = true;
        
        [_groupInfoItem setEditing:_conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canChangeInfo animated:false];
        [self _setupSections:true];
        [self enterEditingMode:true];
        
        [self animateCollectionCrossfade];
    }
}

- (void)donePressed
{
    if (_editing)
    {
        __weak TGChannelInfoController *weakSelf = self;
        void (^block)() = ^{
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->_editing = false;
                
                if (!TGStringCompare(strongSelf->_conversation.chatTitle, [strongSelf->_groupInfoItem editingTitle]) && [strongSelf->_groupInfoItem editingTitle] != nil)
                    [strongSelf _commitUpdateTitle:[strongSelf->_groupInfoItem editingTitle]];
                
                [strongSelf->_groupInfoItem setEditing:false animated:false];
                [strongSelf _setupSections:false];
                [strongSelf leaveEditingMode:true];
                
                [strongSelf animateCollectionCrossfade];
            }
        };
        
        if (!TGStringCompare(_channelAboutItem.text, _conversation.about)) {
            TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
            [progressWindow showWithDelay:0.2];
            
            [[[[TGChannelManagementSignals updateChannelAbout:_conversation.conversationId accessHash:_conversation.accessHash about:_channelAboutItem.text] deliverOn:[SQueue mainQueue]] onDispose:^{
                TGDispatchOnMainThread(^{
                    [progressWindow dismiss:true];
                });
            }] startWithNext:nil error:^(__unused id error) {
                [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Login.UnknownError") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
            } completed:^{
                block();
            }];
        } else {
            block();
        }
    }
    
    [self leaveEditingMode:true];
}

- (void)didEnterEditingMode:(bool)animated
{
    [super didEnterEditingMode:animated];
    
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)] animated:true];
}

- (void)didLeaveEditingMode:(bool)animated
{
    [super didLeaveEditingMode:animated];
    
    [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editPressed)] animated:animated];
}

- (void)setGroupPhotoPressed
{
    if (_conversation.channelRole != TGChannelRoleCreator && !_conversation.channelAdminRights.canChangeInfo)
        return;
    
    __weak TGChannelInfoController *weakSelf = self;
    _avatarMixin = [[TGMediaAvatarMenuMixin alloc] initWithContext:[TGLegacyComponentsContext shared] parentController:self hasDeleteButton:(_conversation.chatPhotoSmall.length != 0) saveEditedPhotos:TGAppDelegateInstance.saveEditedPhotos saveCapturedMedia:TGAppDelegateInstance.saveCapturedMedia];
    _avatarMixin.didFinishWithImage = ^(UIImage *image)
    {
        __strong TGChannelInfoController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf _updateGroupProfileImage:image];
        strongSelf->_avatarMixin = nil;
    };
    _avatarMixin.didFinishWithDelete = ^
    {
        __strong TGChannelInfoController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf _commitDeleteAvatar];
        strongSelf->_avatarMixin = nil;
    };
    _avatarMixin.didDismiss = ^
    {
        __strong TGChannelInfoController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_avatarMixin = nil;
    };
    _avatarMixin.requestSearchController = ^TGViewController *(TGMediaAssetsController *assetsController) {
        __strong TGChannelInfoController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        TGWebSearchController *searchController = [[TGWebSearchController alloc] initWithContext:[TGLegacyComponentsContext shared] forAvatarSelection:true embedded:true allowGrouping:false];
        searchController.presentation = strongSelf.presentation;
        
        __weak TGMediaAssetsController *weakAssetsController = assetsController;
        __weak TGWebSearchController *weakController = searchController;
        searchController.avatarCompletionBlock = ^(UIImage *image) {
            __strong TGMediaAssetsController *strongAssetsController = weakAssetsController;
            if (strongAssetsController.avatarCompletionBlock == nil)
                return;
            
            strongAssetsController.avatarCompletionBlock(image);
        };
        searchController.dismiss = ^
        {
            __strong TGWebSearchController *strongController = weakController;
            if (strongController == nil)
                return;
            
            [strongController dismissEmbeddedAnimated:true];
        };
        searchController.parentNavigationController = assetsController;
        [searchController presentEmbeddedInController:assetsController animated:true];
        
        return searchController;
    };
    [_avatarMixin present];
}

- (void)_updateGroupProfileImage:(UIImage *)image
{
    if (image == nil)
        return;
    
    if (MIN(image.size.width, image.size.height) < 160.0f)
        image = TGScaleImageToPixelSize(image, CGSizeMake(160, 160));
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6f);
    if (imageData == nil)
        return;
    
    TGImageProcessor filter = [TGRemoteImageView imageProcessorForName:@"circle:64x64"];
    UIImage *avatarImage = filter(image);
    
    [_groupInfoItem setUpdatingAvatar:avatarImage hasUpdatingAvatar:true];
    [_setGroupPhotoItem setEnabled:false];
    
    NSMutableDictionary *uploadOptions = [[NSMutableDictionary alloc] init];
    [uploadOptions setObject:imageData forKey:@"imageData"];
    [uploadOptions setObject:[NSNumber numberWithLongLong:_conversation.conversationId] forKey:@"conversationId"];
    [uploadOptions setObject:avatarImage forKey:@"currentImage"];
    uploadOptions[@"accessHash"] = @(_conversation.accessHash);
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         static int actionId = 0;
         [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(updateAvatar%d)", _peerId, actionId] options:uploadOptions watcher:self];
         [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(updateAvatar%d)", _peerId, actionId++] options:uploadOptions watcher:TGTelegraphInstance];
     }];
}

- (void)_commitDeleteAvatar
{
    [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:true];
    [_setGroupPhotoItem setEnabled:false];
    
    NSMutableDictionary *uploadOptions = [[NSMutableDictionary alloc] init];
    [uploadOptions setObject:[NSNumber numberWithLongLong:_conversation.conversationId] forKey:@"conversationId"];
    uploadOptions[@"accessHash"] = @(_conversation.accessHash);
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         static int actionId = 0;
         [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(deleteAvatar%d)", _peerId, actionId] options:uploadOptions watcher:self];
         [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/(deleteAvatar%d)", _peerId, actionId++] options:uploadOptions watcher:TGTelegraphInstance];
     }];
}

- (void)_commitCancelAvatarUpdate
{
    [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
    [_setGroupPhotoItem setEnabled:true];
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         NSArray *actors = [ActionStageInstance() executingActorsWithPathPrefix:[NSString stringWithFormat:@"/tg/conversation/(%lld)/updateAvatar/", _peerId]];
         for (ASActor *actor in actors)
         {
             [ActionStageInstance() removeAllWatchersFromPath:actor.path];
         }
     }];
}

- (void)legacyCameraControllerCompletedWithNoResult
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void)favoriteInfoPressed
{
    [TGDatabaseInstance() toggleFavoritedConversation:[TGDatabaseInstance() loadConversationWithIdCached:_peerId]];
}

- (void)notificationsPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    bool defaultEnabled = [_defaultNotificationSettings[@"muteUntil"] intValue] <= [[TGTelegramNetworking instance] approximateRemoteTime];
    NSString *defaultTitle = defaultEnabled ? TGLocalized(@"UserInfo.NotificationsDefaultEnabled") : TGLocalized(@"UserInfo.NotificationsDefaultDisabled");
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:defaultTitle action:@"default"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"UserInfo.NotificationsEnable") action:@"enable"]];
    
    NSArray *muteIntervals = @[
                               @(1 * 60 * 60),
                               @(8 * 60 * 60),
                               @(2 * 24 * 60 * 60),
                               ];
    
    for (NSNumber *nMuteInterval in muteIntervals)
    {
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:[TGStringUtils stringForMuteInterval:[nMuteInterval intValue]] action:[[NSString alloc] initWithFormat:@"%@", nMuteInterval]]];
    }
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"UserInfo.NotificationsDisable") action:@"disable"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    [[[TGCustomActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGChannelInfoController *controller, NSString *action)
      {
          if ([action isEqualToString:@"enable"])
              [controller _commitEnableNotifications:@true orMuteFor:0];
          else if ([action isEqualToString:@"default"])
              [controller _commitEnableNotifications:nil orMuteFor:0];
          else if ([action isEqualToString:@"disable"])
              [controller _commitEnableNotifications:@false orMuteFor:0];
          else if (![action isEqualToString:@"cancel"])
              [controller _commitEnableNotifications:false orMuteFor:[action intValue]];
      } target:self] showInView:self.view];
}

- (void)_commitEnableNotifications:(NSNumber *)enable orMuteFor:(int)muteFor
{
    NSNumber *muteUntil = nil;
    if (muteFor == 0)
    {
        if (enable)
            muteUntil = enable.boolValue ? @0: @(INT_MAX);
    }
    else
    {
        muteUntil = @((int)([[TGTelegramNetworking instance] approximateRemoteTime] + muteFor));
    }
    
    if (!TGObjectCompare(muteUntil, _groupNotificationSettings[@"muteUntil"]))
    {
        if (muteUntil)
            _groupNotificationSettings[@"muteUntil"] = muteUntil;
        else
            [_groupNotificationSettings removeObjectForKey:@"muteUntil"];
        
        if (muteUntil == nil)
            muteUntil = @(INT32_MIN);
        
        static int actionId = 0;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(userInfoControllerMute%d)", _peerId, actionId++] options:@{@"peerId": @(_peerId), @"accessHash": @(_conversation.accessHash), @"muteUntil": muteUntil} watcher:TGTelegraphInstance];
        [self _updateNotificationItems:false];
    }
}

- (void)_commitUpdateTitle:(NSString *)title
{
    [_groupInfoItem setUpdatingTitle:title];
    
    [ActionStageInstance() dispatchOnStageQueue:^
     {
         static int actionId = 0;
         NSString *path = [[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/changeTitle/(groupInfoController%d)", _conversation.conversationId, actionId++];
         NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:@{@"conversationId": @(_peerId), @"title": title == nil ? @"" : title}];
         options[@"accessHash"] = @(_conversation.accessHash);
         
         [ActionStageInstance() requestActor:path options:options watcher:self];
         [ActionStageInstance() requestActor:path options:options watcher:TGTelegraphInstance];
     }];
}

- (void)leaveGroupPressed
{
    __weak typeof(self) weakSelf = self;
    
    [[[TGCustomActionSheet alloc] initWithTitle:TGLocalized(@"GroupInfo.DeleteAndExitConfirmation") actions:@[
                                                                                                        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.DeleteAndExit") action:@"leave" type:TGActionSheetActionTypeDestructive],
                                                                                                        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
                                                                                                        ] actionBlock:^(__unused id target, NSString *action)
      {
          if ([action isEqualToString:@"leave"])
          {
              TGChannelInfoController *strongSelf = weakSelf;
              [strongSelf _commitLeaveGroup];
          }
      } target:self] showInView:self.view];
}

- (void)_commitLeaveGroup
{
    [TGAppDelegateInstance.rootController.dialogListControllers[0].dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_peerId unreadCount:0 serviceUnreadCount:0] animated:false];
    
    if (self.popoverController != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [self.popoverController dismissPopoverAnimated:true];
                       });
    }
    else
        [self.navigationController popToRootViewControllerAnimated:true];
}

- (void)_changeNotificationSettings:(bool)enableNotifications
{
    _groupNotificationSettings[@"muteUntil"] = @(!enableNotifications ? INT_MAX : 0);
    
    static int actionId = 0;
    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(groupInfoController%d)", _conversation.conversationId, actionId++] options:@{@"peerId": @(_peerId), @"accessHash": @(_conversation.accessHash), @"muteUntil": @(!enableNotifications ? INT_MAX : 0)} watcher:TGTelegraphInstance];
}

- (void)soundPressed
{
    TGAlertSoundController *alertSoundController = [[TGAlertSoundController alloc] initWithTitle:TGLocalized(@"GroupInfo.Sound") soundInfoList:[self _soundInfoListForSelectedSoundId:_groupNotificationSettings[@"soundId"]] defaultId:_defaultNotificationSettings[@"soundId"]];
    alertSoundController.delegate = self;
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[alertSoundController] navigationBarClass:[TGWhiteNavigationBar class]];
    if ([self inPopover])
    {
        navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleChildInPopover;
    }
    
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)alertSoundController:(TGAlertSoundController *)__unused alertSoundController didFinishPickingWithSoundInfo:(NSDictionary *)soundInfo
{
    if (!TGObjectCompare(soundInfo[@"soundId"], _groupNotificationSettings[@"soundId"]))
    {
        int soundId = 0;
        if (soundInfo[@"soundId"] != nil)
        {
            _groupNotificationSettings[@"soundId"] = soundInfo[@"soundId"];
            soundId = [soundInfo[@"soundId"] intValue];
        }
        else
        {
            [_groupNotificationSettings removeObjectForKey:@"soundId"];
            soundId = INT32_MIN;
        }
        [self _updateNotificationItems:false];
        
        static int actionId = 0;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(groupInfoController%d)", _peerId, actionId++] options:@{@"peerId": @(_peerId), @"accessHash": @(_conversation.accessHash), @"soundId": @(soundId)} watcher:TGTelegraphInstance];
    }
}

- (NSArray *)_soundInfoListForSelectedSoundId:(NSNumber *)selectedSoundId
{
    NSMutableArray *infoList = [[NSMutableArray alloc] init];
    
    int index = -1;
    for (NSString *soundName in [TGAppDelegateInstance modernAlertSoundTitles])
    {
        index++;
        
        int soundId = 0;
        
        if (index == 1)
            soundId = 1;
        else if (index == 0)
            soundId = 0;
        else
            soundId = index + 100 - 1;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"title"] = soundName;
        if (selectedSoundId != nil)
            dict[@"selected"] = @(selectedSoundId.intValue == soundId);
        dict[@"soundName"] = [[NSString alloc] initWithFormat:@"%d", soundId];
        dict[@"soundId"] = @(soundId);
        dict[@"groupId"] = @(0);
        [infoList addObject:dict];
    }
    
    index = -1;
    for (NSString *soundName in [TGAppDelegateInstance classicAlertSoundTitles])
    {
        index++;
        
        int soundId = index + 2;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"title"] = soundName;
        if (selectedSoundId != nil)
            dict[@"selected"] = @(selectedSoundId.intValue == soundId);
        dict[@"soundName"] =  [[NSString alloc] initWithFormat:@"%d", soundId];
        dict[@"soundId"] = @(soundId);
        dict[@"groupId"] = @(1);
        [infoList addObject:dict];
    }
    
    return infoList;
}

#pragma mark -

- (void)_updateNotificationItems:(bool)__unused animated
{
    [_muteExpirationTimer invalidate];
    _muteExpirationTimer = nil;
    
    NSString *variant = TGLocalized(@"UserInfo.NotificationsEnabled");
    NSNumber *muteUntil = _groupNotificationSettings[@"muteUntil"];
    if (muteUntil == nil)
        muteUntil = _defaultNotificationSettings[@"muteUntil"];
    
    if (muteUntil.intValue <= [[TGTelegramNetworking instance] approximateRemoteTime])
    {
        variant = TGLocalized(@"UserInfo.NotificationsEnabled");
    }
    else
    {
        int muteExpiration = muteUntil.intValue - (int)[[TGTelegramNetworking instance] approximateRemoteTime];
        if (muteExpiration >= 7 * 24 * 60 * 60)
            variant = TGLocalized(@"UserInfo.NotificationsDisabled");
        else
        {
            variant = [TGStringUtils stringForRemainingMuteInterval:muteExpiration];
            
            _muteExpirationTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(updateMuteExpiration) interval:2.0 repeat:true];
        }
    }
    
    [_notificationsItem setVariant:variant];
    [_editingNotificationsItem setVariant:variant];
    
    bool isDefault = false;
    NSNumber *groupSoundId = _groupNotificationSettings[@"soundId"];
    if (groupSoundId == nil) {
        groupSoundId = _defaultNotificationSettings[@"soundId"];
        isDefault = true;
    }
    
    NSString *soundName = [TGAlertSoundController soundNameFromId:groupSoundId.intValue];
    _soundItem.variant = isDefault ? [NSString stringWithFormat:TGLocalized(@"UserInfo.NotificationsDefaultSound"), soundName] : soundName;
}

- (void)updateMuteExpiration
{
    NSString *variant = TGLocalized(@"UserInfo.NotificationsEnabled");
    NSNumber *muteUntil = _groupNotificationSettings[@"muteUntil"];
    if (muteUntil == nil)
        muteUntil = _defaultNotificationSettings[@"muteUntil"];
    if (muteUntil.intValue <= [[TGTelegramNetworking instance] approximateRemoteTime])
    {
        variant = TGLocalized(@"UserInfo.NotificationsEnabled");
    }
    else
    {
        int muteExpiration = muteUntil.intValue - (int)[[TGTelegramNetworking instance] approximateRemoteTime];
        variant = [TGStringUtils stringForRemainingMuteInterval:muteExpiration];
    }
    
    if (!TGStringCompare(_notificationsItem.variant, variant))
    {
        [_notificationsItem setVariant:variant];
        [_editingNotificationsItem setVariant:variant];
    }
}

- (void)_updateSharedMediaCount
{
}

- (void)_loadUsersAndUpdateConversation:(TGConversation *)conversation
{
    TGDispatchOnMainThread(^
    {
        bool reloadData = false;
        
        if (_conversation.channelRole != conversation.channelRole || !TGObjectCompare(_conversation.channelAdminRights, conversation.channelAdminRights)) {
            reloadData = true;
        }
        
        _conversation = conversation;
        [_groupInfoItem setConversation:_conversation];
        
        NSString *linkText = _conversation.username.length == 0 ? @"" : [@"https://t.me/" stringByAppendingString:_conversation.username];
        
        if (!TGStringCompare(_aboutItem.text, _conversation.about)) {
            reloadData = true;
        }
        
        _aboutItem.text = _conversation.about;
        _linkItem.username = linkText;
        
        if (_aboutItem.text.length == 0) {
            if ([_infoSection deleteItem:_aboutItem]) {
                reloadData = true;
            }
        } else {
            NSUInteger aboutIndex = [_infoSection indexOfItem:_aboutItem];
            if (aboutIndex == NSNotFound) {
                reloadData = true;
                [_infoSection insertItem:_aboutItem atIndex:0];
            }
        }
        
        if (_linkItem.username.length == 0) {
            if ([_infoSection deleteItem:_linkItem]) {
                reloadData = true;
            }
        } else {
            NSUInteger linkIndex = [_infoSection indexOfItem:_linkItem];
            if (linkIndex == NSNotFound) {
                reloadData = true;
                [_infoSection addItem:_linkItem];
            }
        }
        
        if (!_editing) {
            _channelAboutItem.text = conversation.about;
        }
        _channelLinkItem.variant = conversation.username.length == 0 ? @"" : [@"/" stringByAppendingString:conversation.username];
        
        bool forceReload = false;
        
        if (_signMessagesItem.isOn != _conversation.signaturesEnabled) {
            _signMessagesItem.isOn = _conversation.signaturesEnabled;
        }
        
        [self _updateConversationWithLoadedUsers:nil forceReload:forceReload];
        
        if (reloadData) {
            [self _setupSections:_editing];
        }
    });
}

- (void)_updateConversationWithLoadedUsers:(NSArray *)__unused participantUsers forceReload:(bool)__unused forceReload
{
}

- (void)_updateRelativeTimestamps
{
}

- (TGModernGalleryController *)createAvatarGalleryControllerForPreviewMode:(bool)previewMode
{
    TGRemoteImageView *avatarView = [_groupInfoItem avatarView];
    
    if (avatarView != nil && avatarView.image != nil)
    {
        TGModernGalleryController *modernGallery = [[TGModernGalleryController alloc] initWithContext:[TGLegacyComponentsContext shared]];
        modernGallery.previewMode = previewMode;
        if (previewMode)
            modernGallery.showInterface = false;
        
        modernGallery.model = [[TGGroupAvatarGalleryModel alloc] initWithPeerId:_conversation.conversationId accessHash:_conversation.accessHash messageId:0 legacyThumbnailUrl:_conversation.chatPhotoFullSmall legacyUrl:_conversation.chatPhotoFullBig imageSize:CGSizeMake(640.0f, 640.0f)];
        
        __weak TGChannelInfoController *weakSelf = self;
        __weak TGModernGalleryController *weakGallery = modernGallery;
        
        modernGallery.itemFocused = ^(id<TGModernGalleryItem> item)
        {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            __strong TGModernGalleryController *strongGallery = weakGallery;
            if (strongSelf != nil)
            {
                if (strongGallery.previewMode)
                    return;
                
                if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                {
                    ((UIView *)strongSelf->_groupInfoItem.avatarView).hidden = true;
                }
            }
        };
        
        modernGallery.beginTransitionIn = ^UIView *(id<TGModernGalleryItem> item, __unused TGModernGalleryItemView *itemView)
        {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            __strong TGModernGalleryController *strongGallery = weakGallery;
            if (strongSelf != nil)
            {
                if (strongGallery.previewMode)
                    return nil;
                
                if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                {
                    return strongSelf->_groupInfoItem.avatarView;
                }
            }
            
            return nil;
        };
        
        modernGallery.beginTransitionOut = ^UIView *(id<TGModernGalleryItem> item, __unused TGModernGalleryItemView *itemView)
        {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if ([item isKindOfClass:[TGGroupAvatarGalleryItem class]])
                {
                    return strongSelf->_groupInfoItem.avatarView;
                }
            }
            
            return nil;
        };
        
        modernGallery.completedTransitionOut = ^
        {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                ((UIView *)strongSelf->_groupInfoItem.avatarView).hidden = false;
            }
        };
        
        if (!previewMode)
        {
            TGOverlayControllerWindow *controllerWindow = [[TGOverlayControllerWindow alloc] initWithManager:[[TGLegacyComponentsContext shared] makeOverlayWindowManager] parentController:self contentController:modernGallery];
            controllerWindow.hidden = false;
        }
        else
        {
            CGFloat side = MIN(self.view.frame.size.width, self.view.frame.size.height);
            modernGallery.preferredContentSize = CGSizeMake(side, side);
        }
        
        return modernGallery;
    }

    return nil;
}

#pragma mark -

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"openUser"])
    {
        int32_t uid = [options[@"uid"] int32Value];
        if (uid != 0)
        {
            TGUser *user = [TGDatabaseInstance() loadUser:uid];
            if (user.kind == TGUserKindBot || user.kind == TGUserKindSmartBot)
            {
                TGBotUserInfoController *userInfoController = [[TGBotUserInfoController alloc] initWithUid:uid sendCommand:nil];
                [self.navigationController pushViewController:userInfoController animated:true];
            }
            else
            {
                TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:uid];
                [self.navigationController pushViewController:userInfoController animated:true];
            }
        }
    }
    else if ([action isEqualToString:@"editedTitleChanged"])
    {
        NSString *title = options[@"title"];
        
        if (_editing)
            self.navigationItem.rightBarButtonItem.enabled = title.length != 0;
    }
    else if ([action isEqualToString:@"openAvatar"])
    {
        if (_conversation.chatPhotoSmall.length == 0)
        {
            if (_setGroupPhotoItem.enabled)
                [self setGroupPhotoPressed];
        }
        else
        {
            [self createAvatarGalleryControllerForPreviewMode:false];
        }
    }
    else if ([action isEqualToString:@"showUpdatingAvatarOptions"])
    {
        [[[TGCustomActionSheet alloc] initWithTitle:nil actions:@[
                                                            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"GroupInfo.SetGroupPhotoStop") action:@"stop" type:TGActionSheetActionTypeDestructive],
                                                            [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
                                                            ] actionBlock:^(TGChannelInfoController *controller, NSString *action)
          {
              if ([action isEqualToString:@"stop"])
                  [controller _commitCancelAvatarUpdate];
          } target:self] showInView:self.view];
    }
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _peerId]])
    {
        TGConversation *conversation = ((SGraphObjectNode *)resource).object;
        TGDispatchOnMainThread(^{
            _favoriteInfoItem.title = conversation.isFavorited ? TGLocalized(@"UserInfo.Unfavorite") : TGLocalized(@"UserInfo.Favorite");
        });
        if (conversation != nil) {
            [self _loadUsersAndUpdateConversation:conversation];
        }
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    else if ([path isEqualToString:@"/as/updateRelativeTimestamps"])
    {
        TGDispatchOnMainThread(^
                               {
                                   [self _updateRelativeTimestamps];
                               });
    }
    else if ([path isEqualToString:@"/tg/userdatachanges"] || [path isEqualToString:@"/tg/userpresencechanges"])
    {
        //NSArray *users = ((SGraphObjectNode *)resource).object;
        
        TGDispatchOnMainThread(^
                               {
                                   //[self _updateUsers:users];
                               });
    }
    else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/sharedMediaCount/(%" PRIx64 ")", (int64_t)_peerId]])
    {
        TGDispatchOnMainThread(^
                               {
                                   _sharedMediaCount = [resource intValue];
                                   [self _updateSharedMediaCount];
                               });
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId32 "", INT_MAX - 2]])
    {
        TGDispatchOnMainThread(^
        {
            _defaultNotificationSettings = [((SGraphObjectNode *)result).object mutableCopy];
            [self _updateNotificationItems:false];
        });
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        if (status == ASStatusSuccess)
        {
            TGDispatchOnMainThread(^
            {
                _groupNotificationSettings = [((SGraphObjectNode *)result).object mutableCopy];
                [self _updateNotificationItems:false];
            });
        }
    }
    else if ([path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/changeTitle/", _conversation.conversationId]])
    {
        TGDispatchOnMainThread(^
                               {
                                   [_groupInfoItem setUpdatingTitle:nil];
                                   
                                   if (status == ASStatusSuccess)
                                   {
                                       TGConversation *resultConversation = ((SGraphObjectNode *)result).object;
                                       
                                       TGConversation *updatedConversation = [_conversation copy];
                                       updatedConversation.chatTitle = resultConversation.chatTitle;
                                       _conversation = updatedConversation;
                                       
                                       [_groupInfoItem setConversation:_conversation];
                                   }
                               });
    }
    else if ([path hasPrefix:[[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/updateAvatar/", _conversation.conversationId]])
    {
        TGDispatchOnMainThread(^
                               {
                                   if (status == ASStatusSuccess)
                                   {
                                       TGConversation *resultConversation = ((SGraphObjectNode *)result).object;
                                       
                                       TGConversation *updatedConversation = [_conversation copy];
                                       updatedConversation.chatPhotoSmall = resultConversation.chatPhotoSmall;
                                       updatedConversation.chatPhotoMedium = resultConversation.chatPhotoMedium;
                                       updatedConversation.chatPhotoBig = resultConversation.chatPhotoBig;
                                       updatedConversation.chatPhotoFileReferenceSmall = resultConversation.chatPhotoFileReferenceSmall;
                                       updatedConversation.chatPhotoFileReferenceBig = resultConversation.chatPhotoFileReferenceBig;
                                       _conversation = updatedConversation;
                                       
                                       [_groupInfoItem copyUpdatingAvatarToCacheWithUri:_conversation.chatPhotoSmall];
                                       [_groupInfoItem setConversation:_conversation];
                                       
                                       [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                                       [_setGroupPhotoItem setEnabled:true];
                                   }
                                   else
                                   {
                                       [_groupInfoItem setUpdatingAvatar:nil hasUpdatingAvatar:false];
                                       [_setGroupPhotoItem setEnabled:true];
                                   }
                               });
    }
}

- (void)aboutPressed {
    TGChannelAboutSetupController *aboutController = [[TGChannelAboutSetupController alloc] initWithConversation:_conversation];
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[aboutController]];
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)linkPressed {
    TGChannelLinkSetupController *linkController = [[TGChannelLinkSetupController alloc] initWithConversation:_conversation];
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[linkController]];
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)sharePressed
{
    __weak TGChannelInfoController *weakSelf = self;
    if (_conversation.username.length != 0)
    {
        NSString *linkString = [NSString stringWithFormat:@"https://t.me/%@", _conversation.username];
        NSString *shareString = linkString;
        NSString *externalString = shareString;
        if (_conversation.about.length > 0)
        {
            NSString *aboutText = _conversation.about;
            if (aboutText.length > 200)
                aboutText = [[aboutText substringToIndex:200] stringByAppendingString:@"..."];

            externalString = [NSString stringWithFormat:@"%@ %@", aboutText, externalString];
        }
        
        CGRect (^sourceRect)(void) = ^CGRect
        {
            __strong TGChannelInfoController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return CGRectZero;
            
            return [strongSelf->_linkItem.view convertRect:strongSelf->_linkItem.view.bounds toView:strongSelf.view];
        };
        
        [TGShareMenu presentInParentController:self menuController:nil buttonTitle:TGLocalized(@"ShareMenu.CopyShareLink") buttonAction:^
        {
            [[UIPasteboard generalPasteboard] setString:linkString];
        } shareAction:^(NSArray *peerIds, NSString *caption)
        {
            [[TGShareSignals shareText:shareString toPeerIds:peerIds caption:caption] startWithNext:nil];
            
            [[[TGProgressWindow alloc] init] dismissWithSuccess];
        } externalShareItemSignal:[SSignal single:externalString] sourceView:self.view sourceRect:sourceRect barButtonItem:nil];
    }
}

- (void)leavePressed {
    __weak typeof(self) weakSelf = self;
    
    [[[TGCustomActionSheet alloc] initWithTitle:nil actions:@[
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ChannelInfo.ConfirmLeave") action:@"leave" type:TGActionSheetActionTypeDestructive],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
        ] actionBlock:^(__unused id target, NSString *action)
    {
        if ([action isEqualToString:@"leave"])
        {
            TGChannelInfoController *strongSelf = weakSelf;
            [strongSelf _commitLeaveChannel];
        }
    } target:self] showInView:self.view];
}

- (void)_commitLeaveChannel
{
    [TGAppDelegateInstance.rootController.dialogListControllers[0].dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_peerId unreadCount:0 serviceUnreadCount:0] animated:false];
    
    if (self.popoverController != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.popoverController dismissPopoverAnimated:true];
        });
    }
    else
        [self.navigationController popToRootViewControllerAnimated:true];
}

- (void)_commitDeleteChannel
{
    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
    [progressWindow show:true];
    
    [[[[TGChannelManagementSignals deleteChannel:_conversation.conversationId accessHash:_conversation.accessHash] deliverOn:[SQueue mainQueue]] onDispose:^{
        TGDispatchOnMainThread(^{
            [progressWindow dismiss:true];
        });
    }] startWithNext:nil completed:^{
        [TGAppDelegateInstance.rootController.dialogListControllers[0].dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_peerId unreadCount:0 serviceUnreadCount:0] animated:false];
        
        if (self.popoverController != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.popoverController dismissPopoverAnimated:true];
            });
        }
        else
            [self.navigationController popToRootViewControllerAnimated:true];
    }];
}

- (void)infoManagementPressed {
    [self.navigationController pushViewController:[[TGChannelMembersController alloc] initWithConversation:_conversation mode:TGChannelMembersModeAdmins] animated:true];
}

- (void)infoBlacklistPressed {
    [self.navigationController pushViewController:[[TGChannelMembersController alloc] initWithConversation:_conversation mode:TGChannelMembersModeBannedAndRestricted] animated:true];
}

- (void)infoMembersPressed {
    [self.navigationController pushViewController:[[TGChannelMembersController alloc] initWithConversation:_conversation mode:TGChannelMembersModeMembers] animated:true];
}

- (void)sharedMediaPressed {
    TGSharedMediaController *controller = [[TGSharedMediaController alloc] initWithPeerId:_peerId accessHash:_conversation.accessHash important:true];
    controller.channelAllowDelete = _conversation.channelRole == TGChannelRoleCreator || _conversation.channelAdminRights.canDeleteMessages;
    [self.navigationController pushViewController:controller animated:true];
}

- (void)deleteChannelPressed {
    __weak typeof(self) weakSelf = self;
    
    [[[TGCustomActionSheet alloc] initWithTitle:TGLocalized(@"ChannelInfo.DeleteChannelConfirmation") actions:@[
                                                        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ChannelInfo.DeleteChannel") action:@"leave" type:TGActionSheetActionTypeDestructive],
                                                        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
                                                        ] actionBlock:^(__unused id target, NSString *action)
    {
        if ([action isEqualToString:@"leave"])
        {
            TGChannelInfoController *strongSelf = weakSelf;
            [strongSelf _commitDeleteChannel];
        }
    } target:self] showInView:self.view];
}

- (void)reportChannelPressed {
    __weak TGChannelInfoController *weakSelf = self;
    [[[TGCustomActionSheet alloc] initWithTitle:nil actions:@[
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonSpam") action:@"spam"],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonViolence") action:@"violence"],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonPornography") action:@"pornography"],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonCopyright") action:@"copyright"],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonOther") action:@"other"],
        [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]] actionBlock:^(__unused id target, NSString *action) {
        __strong TGChannelInfoController *strongSelf = weakSelf;
        if (strongSelf != nil) {
            if (![action isEqualToString:@"cancel"]) {
                TGReportPeerReason reason = TGReportPeerReasonSpam;
                if ([action isEqualToString:@"spam"]) {
                    reason = TGReportPeerReasonSpam;
                } else if ([action isEqualToString:@"violence"]) {
                    reason = TGReportPeerReasonViolence;
                } else if ([action isEqualToString:@"pornography"]) {
                    reason = TGReportPeerReasonPornography;
                } else if ([action isEqualToString:@"copyright"]) {
                    reason = TGReportPeerReasonCopyright;
                } else if ([action isEqualToString:@"other"]) {
                    reason = TGReportPeerReasonOther;
                }
                
                void (^reportBlock)(NSString *) = ^(NSString *otherText) {
                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                    [progressWindow showWithDelay:0.1];
                    
                    [[[[TGAccountSignals reportPeer:strongSelf->_conversation.conversationId accessHash:strongSelf->_conversation.accessHash reason:reason otherText:otherText] deliverOn:[SQueue mainQueue]] onDispose:^{
                        TGDispatchOnMainThread(^{
                            [progressWindow dismiss:true];
                        });
                    }] startWithNext:nil error:^(__unused id error) {
                        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Login.UnknownError") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    } completed:^{
                        __strong TGChannelInfoController *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            [strongSelf dismissViewControllerAnimated:true completion:nil];
                        }
                        
                        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"ReportPeer.AlertSuccess") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    }];
                };
                
                if (reason == TGReportPeerReasonOther) {
                    TGReportPeerOtherTextController *controller = [[TGReportPeerOtherTextController alloc] initWithCompletion:^(NSString *text) {
                        if (text.length != 0) {
                            reportBlock(text);
                        }
                    }];
                    __strong TGChannelInfoController *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        [strongSelf presentViewController:[TGNavigationController navigationControllerWithControllers:@[controller]] animated:true completion:nil];
                    }
                } else {
                    reportBlock(nil);
                }
            }
        }
    } target:self] showInView:self.view];
}

- (void)updateSignMessages:(bool)value {
    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
    [progressWindow showWithDelay:0.2];
    
    [[[[TGChannelManagementSignals updateChannelSignaturesEnabled:_conversation.conversationId accessHash:_conversation.accessHash enabled:value] deliverOn:[SQueue mainQueue]] onDispose:^{
        TGDispatchOnMainThread(^{
            [progressWindow dismiss:true];
        });
    }] startWithNext:nil];
}

- (void)followLink:(NSString *)link {
    if ([link hasPrefix:@"mention://"])
    {
        NSString *domain = [link substringFromIndex:@"mention://".length];
        [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/resolveDomain/(%@,profile)", domain] options:@{@"domain": domain, @"profile": @true} flags:0 watcher:TGTelegraphInstance];
    }
    else if ([link hasPrefix:@"hashtag://"])
    {
        NSString *hashtag = [link substringFromIndex:@"hashtag://".length];
        [[TGInterfaceManager instance] displayHashtagOverview:[@"#" stringByAppendingString:hashtag] conversationId:_conversation.conversationId];
    }
    else if ([link hasPrefix:@"cashtag://"])
    {
        NSString *cashtag = [link substringFromIndex:@"cashtag://".length];
        [[TGInterfaceManager instance] displayHashtagOverview:[@"$" stringByAppendingString:cashtag] conversationId:_conversation.conversationId];
    }
    else {
        @try {
            NSURL *url = [NSURL URLWithString:link];
            if (url != nil) {
                if ([url.host.lowercaseString isEqualToString:@"telegra.ph"]) {
                    [TGAppDelegateInstance handleOpenInstantView:link disableActions:false];
                } else {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        } @catch (NSException *e) {
        }
    }
}

- (void)check3DTouch
{
    if (_checked3dTouch)
        return;
    
    _checked3dTouch = true;
    if (iosMajorVersion() >= 9)
    {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
        {
            [self registerForPreviewingWithDelegate:(id)self sourceView:_groupInfoItem.avatarView];
        }
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)__unused location
{
    if (_conversation.chatPhotoSmall.length > 0)
    {
        previewingContext.sourceRect = previewingContext.sourceView.bounds;
        return [self createAvatarGalleryControllerForPreviewMode:true];
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)__unused previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    if ([viewControllerToCommit isKindOfClass:[TGModernGalleryController class]])
    {
        TGModernGalleryController *controller = (TGModernGalleryController *)viewControllerToCommit;
        controller.previewMode = false;
        
        TGOverlayControllerWindow *controllerWindow = [[TGOverlayControllerWindow alloc] initWithManager:[[TGLegacyComponentsContext shared] makeOverlayWindowManager] parentController:self contentController:controller];
        controllerWindow.hidden = false;
    }
}

- (void)holdLink:(NSString *)url
{
    if (url.length == 0)
        return;
    
    if ([url hasPrefix:@"tel:"])
    {
        TGCustomActionSheet *actionSheet = [[TGCustomActionSheet alloc] initWithTitle:url.length < 70 ? url : [[url substringToIndex:70] stringByAppendingString:@"..."] actions:@
        [
         [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"UserInfo.PhoneCall") action:@"call"],
         [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogCopy") action:@"copy"],
         [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]
         ] actionBlock:^(__unused TGChannelInfoController *controller, NSString *action)
        {
            if ([action isEqualToString:@"call"])
            {
                [TGAppDelegateInstance performPhoneCall:[NSURL URLWithString:url]];
            }
            else if ([action isEqualToString:@"copy"])
            {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                if (pasteboard != nil)
                {
                    NSString *copyString = url;
                    if ([url hasPrefix:@"mailto:"])
                        copyString = [url substringFromIndex:7];
                    else if ([url hasPrefix:@"tel:"])
                        copyString = [url substringFromIndex:4];
                    [pasteboard setString:copyString];
                }
            }
        } target:self];
        [actionSheet showInView:self.view];
    }
    else
    {
        NSString *displayString = url;
        if ([url hasPrefix:@"hashtag://"])
            displayString = [@"#" stringByAppendingString:[url substringFromIndex:@"hashtag://".length]];
        else if ([url hasPrefix:@"cashtag://"])
            displayString = [@"$" stringByAppendingString:[url substringFromIndex:@"cashtag://".length]];
        else if ([url hasPrefix:@"mention://"])
            displayString = [@"@" stringByAppendingString:[url substringFromIndex:@"mention://".length]];
        
        
        NSURL *link = [NSURL URLWithString:url];
        if (link.scheme.length == 0)
            link = [NSURL URLWithString:[@"http://" stringByAppendingString:url]];
        
        bool useOpenIn = false;
        bool isWeblink = false;
        if ([link.scheme isEqualToString:@"http"] || [link.scheme isEqualToString:@"https"])
        {
            isWeblink = true;
            if ([TGOpenInMenu hasThirdPartyAppsForURL:link])
                useOpenIn = true;
        }
        
        NSMutableArray *actions = [[NSMutableArray alloc] init];
        if (useOpenIn)
        {
            TGActionSheetAction *openInAction = [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.FileOpenIn") action:@"openIn"];
            openInAction.disableAutomaticSheetDismiss = true;
            [actions addObject:openInAction];
        }
        else
        {
            [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogOpen") action:@"open"]];
        }
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.LinkDialogCopy") action:@"copy"]];
        
        if (isWeblink && iosMajorVersion() >= 7)
            [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Conversation.AddToReadingList") action:@"addToReadingList"]];
        
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
        
        TGCustomActionSheet *actionSheet = [[TGCustomActionSheet alloc] initWithTitle:displayString.length < 70 ? displayString : [[displayString substringToIndex:70] stringByAppendingString:@"..."] actions:actions menuController:nil advancedActionBlock:^(TGMenuSheetController *menuController, TGChannelInfoController *controller, NSString *action)
        {
            if ([action isEqualToString:@"open"])
            {
                [controller followLink:url];
            }
            else if ([action isEqualToString:@"openIn"])
            {
                [TGOpenInMenu presentInParentController:self menuController:menuController title:TGLocalized(@"Map.OpenIn") url:link buttonTitle:nil buttonAction:nil sourceView:self.view sourceRect:nil barButtonItem:nil];
            }
            else if ([action isEqualToString:@"copy"])
            {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                if (pasteboard != nil)
                {
                    NSString *copyString = url;
                    if ([url hasPrefix:@"mailto:"])
                        copyString = [url substringFromIndex:7];
                    else if ([url hasPrefix:@"tel:"])
                        copyString = [url substringFromIndex:4];
                    else if ([url hasPrefix:@"hashtag://"])
                        copyString = [@"#" stringByAppendingString:[url substringFromIndex:@"hashtag://".length]];
                    else if ([url hasPrefix:@"cashtag://"])
                        copyString = [@"$" stringByAppendingString:[url substringFromIndex:@"cashtag://".length]];
                    else if ([url hasPrefix:@"mention://"])
                        copyString = [@"@" stringByAppendingString:[url substringFromIndex:@"mention://".length]];
                    [pasteboard setString:copyString];
                }
            }
            else if ([action isEqualToString:@"addToReadingList"])
            {
                [[SSReadingList defaultReadingList] addReadingListItemWithURL:[NSURL URLWithString:url] title:@"" previewText:nil error:NULL];
            }
        } target:self];
        [actionSheet showInView:self.view];
    }
}

@end
