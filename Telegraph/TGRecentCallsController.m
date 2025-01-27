#import "TGRecentCallsController.h"

#import <LegacyComponents/LegacyComponents.h>

#import <pthread.h>
#import <time.h>

#import "TGAppDelegate.h"
#import "TGTelegraph.h"
#import "TGInterfaceManager.h"
#import "TGTelegramNetworking.h"

#import "TGMessageSearchSignals.h"

#import "TGUserSignal.h"
#import "TGCallDiscardReason.h"

#import <LegacyComponents/TGModernBarButton.h>
#import <LegacyComponents/TGListsTableView.h>
#import <LegacyComponents/TGSearchBar.h>
#import <LegacyComponents/TGSearchDisplayMixin.h>
#import "TGCallCell.h"
#import "TGSwitchCollectionItemView.h"

#import "TGSelectContactController.h"

#import "TGPresentation.h"

@interface TGRecentCallsController () <UITableViewDelegate, UITableViewDataSource, TGSwitchCollectionItemViewDelegate, ASWatcher>
{
    bool _inSettings;
    bool _editingMode;
    bool _missed;
    bool _loading;
    bool _initialized;
    
    NSArray *_listModel;
    NSDictionary *_usersModel;
    
    NSArray *_displayListModel;
    NSArray *_displayFilteredListModel;
    
    UISegmentedControl *_segmentedControl;
    
    SVariable *_reloadReady;
    TGListsTableView *_tableView;
    UILabel *_placeholderLabel;
    
    TGSwitchCollectionItemView *_settingsItemView;
    UILabel *_settingsCommentLabel;
    
    SQueue *_queue;
    SMetaDisposable *_disposable;
    SSignal *_currentLoadMoreSignal;
    
    NSInteger _lastMissedCount;
    
    id<SDisposable> _localizationUpdatedDisposable;
}

@property (nonatomic, strong) ASHandle *actionHandle;

@end

@implementation TGRecentCallsController

- (instancetype)init
{
    return [self initWithController:nil];
}

- (instancetype)initWithController:(TGRecentCallsController *)controller
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self];
        
        if (controller != nil)
            _inSettings = true;
        
        _queue = [[SQueue alloc] init];
        _reloadReady = [[SVariable alloc] init];
        [self setReloadReady:true];
        
        if (controller != nil)
        {
            [controller->_queue dispatchSync:^
            {
                _usersModel = [controller->_usersModel copy];
                _listModel = [controller->_listModel copy];
                _currentLoadMoreSignal = controller->_currentLoadMoreSignal;
            }];
            
            _displayListModel = [controller->_displayListModel copy];
            _displayFilteredListModel = [controller->_displayFilteredListModel copy];
        }
        else
        {
            _usersModel = [[NSDictionary alloc] init];
            _listModel = [[NSArray alloc] init];
        }
        
        __weak TGRecentCallsController *weakSelf = self;
        _localizationUpdatedDisposable = [[TGAppDelegateInstance.localizationUpdated deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next) {
            __strong TGRecentCallsController *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf updateLocalization];
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = _presentation.pallete.backgroundColor;
    _tableView.backgroundColor = self.view.backgroundColor;
    _tableView.separatorColor = _presentation.pallete.separatorColor;
    _placeholderLabel.textColor = _presentation.pallete.collectionMenuCommentColor;
    
    [_segmentedControl setPallete:presentation.segmentedControlPallete];
    
    for (UITableViewCell *cell in _tableView.visibleCells)
    {
        if ([cell isKindOfClass:[TGCallCell class]])
            [(TGCallCell *)cell setPresentation:presentation];
    }
    
    [self updateBarButtonItemsAnimated:false];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = _presentation.pallete.backgroundColor;
    
    NSArray *items = @[TGLocalized(@"Calls.All"), TGLocalized(@"Calls.Missed")];
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    if (iosMajorVersion() >= 11)
        _segmentedControl.translatesAutoresizingMaskIntoConstraints = false;
    
    CGFloat width = 0.0f;
    for (NSString *itemName in items)
    {
        CGSize size = [[[NSAttributedString alloc] initWithString:itemName attributes:@{NSFontAttributeName: TGSystemFontOfSize(13)}] boundingRectWithSize:CGSizeMake(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        if (size.width > width)
            width = size.width;
    }
    width = (width + 34.0f) * 2.0f;
    
    _segmentedControl.frame = CGRectMake((self.view.frame.size.width - width) / 2.0f, 8.0f, width, 29.0f);
    _segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [_segmentedControl setPallete:_presentation.segmentedControlPallete];
    
    [_segmentedControl setSelectedSegmentIndex:0];
    [_segmentedControl addTarget:self action:@selector(segmentedControlChanged) forControlEvents:UIControlEventValueChanged];
    
    [self setTitleView:_segmentedControl];
    
    [self updateBarButtonItemsAnimated:false];
    
    CGRect tableFrame = self.view.bounds;
    _tableView = [[TGListsTableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    if (iosMajorVersion() >= 11)
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.opaque = true;
    _tableView.backgroundColor = nil;
    _tableView.showsVerticalScrollIndicator = true;
    
    __weak TGRecentCallsController *weakSelf = self;
    ((TGListsTableView *)_tableView).onHitTest = ^(CGPoint point) {
        __strong TGRecentCallsController *strongSelf = weakSelf;
        if (strongSelf != nil) {
            [strongSelf dismissEditingControls:point force:false];
        }
    };

    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (iosMajorVersion() >= 7) {
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = _presentation.pallete.separatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0.0f, 85.0f, 0.0f, 0.0f);
    }
    
    _tableView.alwaysBounceVertical = true;
    _tableView.bounces = true;
    
    [self.view addSubview:_tableView];
    
    _placeholderLabel = [[UILabel alloc] init];
    _placeholderLabel.backgroundColor = [UIColor clearColor];
    _placeholderLabel.textColor = _presentation.pallete.collectionMenuCommentColor;
    _placeholderLabel.font = TGSystemFontOfSize(16.0f);
    _placeholderLabel.text = TGLocalized(@"Calls.NoCallsPlaceholder");
    _placeholderLabel.textAlignment = NSTextAlignmentCenter;
    _placeholderLabel.numberOfLines = 0;
    _placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:_placeholderLabel];

    if (![self _updateControllerInset:false])
        [self controllerInsetUpdated:UIEdgeInsetsZero];
    
    [self updatePlaceholder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_loading && (_displayListModel.count == 0 || !_initialized))
        [self initialize];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.missedCountChanged != nil)
        self.missedCountChanged(0);
    
    NSMutableSet *peerIds = [[NSMutableSet alloc] init];
    for (TGMessage *message in _listModel)
    {
        if (!message.outgoing && [message.actionInfo.actionData[@"reason"] intValue] == TGCallDiscardReasonMissed)
        {
            if (![peerIds containsObject:@(message.fromUid)])
            {
                TGConversation *conversation = [TGDatabaseInstance() loadConversationWithIdCached:message.cid];
                if ([conversation isMessageUnread:message])
                    [peerIds addObject:@(message.fromUid)];
            }
        }
    }
    
    NSMutableArray *requests = [[NSMutableArray alloc] init];
    for (NSNumber *peerId in peerIds) {
        [requests addObject:[[TGReadPeerMessagesRequest alloc] initWithPeerId:peerId.int64Value maxMessageIndex:nil date:0 length:0 unread:false]];
    }
    
    if (peerIds.count > 0)
    {
        [TGDatabaseInstance() dispatchOnDatabaseThread:^
        {
            [TGDatabaseInstance() transactionReadHistoryForPeerIds:requests];
        } synchronous:false];
    }
}

- (void)switchCollectionItemViewChangedValue:(TGSwitchCollectionItemView *)__unused switchItemView isOn:(bool)isOn
{
}

- (void)controllerInsetUpdated:(UIEdgeInsets)previousInset
{
    _settingsItemView.safeAreaInset = self.controllerSafeAreaInset;
    [super controllerInsetUpdated:previousInset];
}

- (void)updatePlaceholder
{
    bool hidden = [self listModel].count > 0;
    NSString *text = _missed ? TGLocalized(@"Calls.NoMissedCallsPlacehoder") : TGLocalized(@"Calls.NoCallsPlaceholder");
    _placeholderLabel.hidden = hidden;
    if (![text isEqualToString:_placeholderLabel.text])
    {
        _placeholderLabel.text = text;
        [self.view setNeedsLayout];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    CGRect frame = _segmentedControl.frame;
    if (navigationBar.frame.size.height >= 44)
    {
        frame.size.height = 29.0f;
        frame.origin.y = (navigationBar.frame.size.height - 29.0f) / 2.0f;
    }
    else
    {
        frame.origin.y = 4.0f;
        frame.size.height = navigationBar.frame.size.height - frame.origin.y * 2;
    }
    _segmentedControl.frame = frame;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize boundsSize = CGSizeMake(self.view.bounds.size.width - 20.0f, CGFLOAT_MAX);
    
    CGSize textSize = [_placeholderLabel sizeThatFits:boundsSize];
    _placeholderLabel.frame = CGRectMake(CGFloor((self.view.bounds.size.width - textSize.width) / 2.0f), _tableView.contentInset.top + CGFloor((self.view.bounds.size.height - _tableView.contentInset.top - textSize.height) / 2.0f), textSize.width, textSize.height);
    
    if (_settingsCommentLabel != nil)
    {
        UIEdgeInsets safeAreaInset = [self calculatedSafeAreaInset];
        CGSize size = [_settingsCommentLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width - 15.0f * 2 - safeAreaInset.left - safeAreaInset.right, 100.0f)];
        _settingsCommentLabel.frame = CGRectMake(15.0f + safeAreaInset.left, _settingsCommentLabel.frame.origin.y, size.width, size.height);
        
        CGFloat height = ceil(size.height) + 106;
        CGRect frame = CGRectMake(_tableView.tableHeaderView.frame.origin.x, _tableView.tableHeaderView.frame.origin.y, _tableView.tableHeaderView.frame.size.width, MAX(123.0f, height));
        
        if (fabs(frame.size.height - _tableView.tableHeaderView.frame.size.height) > FLT_EPSILON)
        {
            _tableView.tableHeaderView.frame = frame;
            _tableView.tableHeaderView = _tableView.tableHeaderView;
        }
    }
}

- (UIBarButtonItem *)editBarButtonItem
{
    if (!_editingMode)
    {
        return [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Edit") style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed)];
    }
    else
    {
        return [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonPressed)];
    }
}

- (UIBarButtonItem *)actionBarButtonItem
{
    //if (_editingMode)
    //{
    //    return [[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Calls.Clear") style:UIBarButtonItemStylePlain target:self action:@selector(clearButtonPressed)];
    //}
    return nil;
}

- (UIBarButtonItem *)controllerLeftBarButtonItem
{
    return _inSettings ? [self actionBarButtonItem] : [self editBarButtonItem];
}

- (UIBarButtonItem *)controllerRightBarButtonItem
{
    if (_inSettings)
        return [self editBarButtonItem];
    else if (_editingMode)
        return [self actionBarButtonItem];
    
    TGModernBarButton *newCallButton = [[TGModernBarButton alloc] initWithImage:TGPresentation.current.images.callsNewIcon];
    CGPoint portraitOffset = CGPointZero;
    CGPoint landscapeOffset = CGPointZero;
    if (iosMajorVersion() >= 11)
    {
        portraitOffset.x = 2.0f;
        portraitOffset.y = 5.0f;
        landscapeOffset.x = 5.0f;
        landscapeOffset.y = 5.0f;
    }
    newCallButton.portraitAdjustment = CGPointMake(2 + portraitOffset.x, -4 + portraitOffset.y);
    newCallButton.landscapeAdjustment = CGPointMake(2 + landscapeOffset.x, -4 + landscapeOffset.y);
    [newCallButton addTarget:self action:@selector(newCallButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:newCallButton];
}

#pragma mark - Interface Logic

- (void)segmentedControlChanged
{
    [self dismissEditingControls:CGPointZero force:true];
    
    _missed = _segmentedControl.selectedSegmentIndex == 1;
    [self reloadDataAnimated:true];
}

- (void)newCallButtonPressed
{
    if ([TGAppDelegateInstance isDisplayingPasscodeWindow])
        return;
    
    [self dismissEditingControls:CGPointZero force:true];
    
    TGSelectContactController *selectController = [[TGSelectContactController alloc] initWithCreateGroup:false createEncrypted:false createBroadcast:false createChannel:false inviteToChannel:false showLink:false call:true];
    selectController.onCall = ^(TGUser *user)
    {
        [[TGInterfaceManager instance] callPeerWithId:user.uid completion:^
        {
            [TGAppDelegateInstance.rootController clearContentControllers];
        }];
    };
    [TGAppDelegateInstance.rootController pushContentController:selectController];
}

- (void)updateBarButtonItemsAnimated:(bool)animated
{
    [self setLeftBarButtonItem:[self controllerLeftBarButtonItem] animated:animated];
    [self setRightBarButtonItem:[self controllerRightBarButtonItem] animated:animated];
}

- (void)editButtonPressed
{
    [self setupEditingMode:!_editingMode];
    
    [self updateBarButtonItemsAnimated:true];
}

- (void)doneButtonPressed
{
    [self setupEditingMode:!_editingMode];
    
    [self updateBarButtonItemsAnimated:true];
}

- (void)clearButtonPressed
{
    
}

#pragma mark - Table View Data Source

- (NSArray *)listModel
{
    return _missed ? _displayFilteredListModel : _displayListModel;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return [self listModel].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *listModel = [self listModel];
    TGCallGroup *callGroup = indexPath.row < listModel.count ? listModel[indexPath.row] : nil;
    
    static NSString *CallCellIdentifier = @"CC";
    TGCallCell *cell = [tableView dequeueReusableCellWithIdentifier:CallCellIdentifier];
    if (cell == nil)
    {
        __weak TGRecentCallsController *weakSelf = self;
        cell = [[TGCallCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CallCellIdentifier];
        cell.inSettings = _inSettings;
        
        __weak TGCallCell *weakCell = cell;
        cell.infoPressed = ^
        {
            __strong TGRecentCallsController *strongSelf = weakSelf;
            __strong TGCallCell *strongCell = weakCell;
            if (strongSelf != nil && strongCell != nil)
            {
                NSIndexPath *indexPath = [strongSelf->_tableView indexPathForCell:strongCell];
                TGCallGroup *callGroup = [strongSelf listModel][indexPath.row];
                
                [[TGInterfaceManager instance] navigateToProfileOfUser:callGroup.peer.uid callMessages:callGroup.messages];
                
                if ([strongCell isEditingControlsExpanded])
                    [strongCell setEditingConrolsExpanded:false animated:true];
            }
        };
        
        cell.deletePressed = ^
        {
            __strong TGRecentCallsController *strongSelf = weakSelf;
            __strong TGCallCell *strongCell = weakCell;
            if (strongSelf != nil && strongCell != nil)
            {
                NSIndexPath *indexPath = [strongSelf->_tableView indexPathForCell:strongCell];
                TGCallGroup *callGroup = [strongSelf listModel][indexPath.row];
                [strongSelf deleteCallGroup:callGroup];
            }
        };
    }
    
    cell.presentation = _presentation;
    [cell setupWithCallGroup:callGroup];
    
    return cell;
}

- (void)tableView:(UITableView *)__unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    if (iosMajorVersion() < 7 && [cell isKindOfClass:[TGCallCell class]])
        cell.backgroundColor = _inSettings ? self.presentation.pallete.collectionMenuCellBackgroundColor : self.presentation.pallete.backgroundColor;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return 56.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    TGCallGroup *group = [self listModel][indexPath.row];
    [[TGInterfaceManager instance] callPeerWithId:group.peer.uid];
}

- (void)tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)__unused editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self deleteCallGroup:[self listModel][indexPath.row]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    if (tableView.editing)
        return UITableViewCellEditingStyleDelete;
    
    return UITableViewCellEditingStyleNone;
}

- (void)scrollToTopRequested
{
    [_tableView scrollToTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)__unused scrollView
{
    [self _maybeLoadMore];
}

#pragma mark - Editing

- (void)setupEditingMode:(bool)editing
{
    if (editing)
        [self dismissEditingControls:CGPointZero force:true];
    
    _editingMode = editing;
    [_tableView setEditing:editing animated:true];
}

#pragma mark - Data

- (void)reloadDataAnimated:(bool)animated
{
    [self reloadDataAnimated:animated oldEntries:_missed ? _displayListModel : _displayFilteredListModel newEntries:_missed ? _displayFilteredListModel : _displayListModel force:false];
}

- (void)reloadDataAnimated:(bool)animated oldEntries:(NSArray *)oldEntries newEntries:(NSArray *)newEntries force:(bool)force
{
    if (![self isViewLoaded])
        return;
    
    SSignal *signal = force ? [SSignal complete] : [self reloadReadySignal];
    
    [signal startWithNext:nil completed:^{
        if (animated)
        {
            [self setReloadReady:false];
            
            [CATransaction begin];
            
            [CATransaction setCompletionBlock:^
            {
                [self setReloadReady:true];
                
                TGDispatchAfter(0.1, dispatch_get_main_queue(), ^
                {
                    if (_missed)
                        [self _maybeLoadMore];
                });
            }];
    
            [_tableView beginUpdates];
            
            NSMutableArray *rowsToDelete = [NSMutableArray array];
            NSMutableArray *rowsToInsert = [NSMutableArray array];
            
            for (NSUInteger i = 0; i < oldEntries.count; i++ )
            {
                TGCallGroup *entry = [oldEntries objectAtIndex:i];
                bool contains = false;
                for (NSUInteger j = 0; j < newEntries.count; j++ )
                {
                    TGCallGroup *newEntry = [newEntries objectAtIndex:j];
                    if ([newEntry.identifier isEqualToString: entry.identifier])
                    {
                        contains = true;
                        break;
                    }
                }
                
                if (!contains)
                    [rowsToDelete addObject: [NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            for (NSUInteger i = 0; i < newEntries.count; i++)
            {
                TGCallGroup *entry = [newEntries objectAtIndex:i];
                bool contains = false;
                for (NSUInteger j = 0; j < oldEntries.count; j++ )
                {
                    TGCallGroup *oldEntry = [oldEntries objectAtIndex:j];
                    if ([oldEntry.identifier isEqualToString:entry.identifier])
                    {
                        contains = true;
                        break;
                    }
                }
                
                if (!contains)
                    [rowsToInsert addObject: [NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            [_tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationFade];
            [_tableView insertRowsAtIndexPaths:rowsToInsert withRowAnimation:UITableViewRowAnimationFade];
            
            [_tableView endUpdates];
            
            [CATransaction commit];
        }
        else
        {
            [_tableView reloadData];
        }
        
        [self updatePlaceholder];
    }];
}

- (void)setReloadReady:(bool)ready
{
    [_reloadReady set:[SSignal single:@(ready)]];
    _segmentedControl.userInteractionEnabled = ready;
}

- (SSignal *)reloadReadySignal
{
    return [[_reloadReady.signal filter:^bool(NSNumber *value) {
        return value.boolValue;
    }] take:1];
}

+ (SSignal *)_mapMessages:(NSArray *)messages
{
    NSMutableIndexSet *userIds = [[NSMutableIndexSet alloc] init];
    for (TGMessage *message in messages)
        [userIds addIndex:(int32_t)(message.outgoing ? message.toUid : message.fromUid)];
    
    NSMutableArray *userSignals = [[NSMutableArray alloc] init];
    [userIds enumerateIndexesUsingBlock:^(NSUInteger uid, __unused BOOL *stop)
    {
        if (uid != 0)
            [userSignals addObject:[[TGUserSignal userWithUserId:(int32_t)uid] take:1]];
    }];
    
    return [[SSignal combineSignals:userSignals] map:^id(NSArray *users)
    {
        NSMutableDictionary *usersMap = [[NSMutableDictionary alloc] init];
        for (TGUser *user in users)
        {
            usersMap[@(user.uid)] = user;
        }
        
        return @{@"calls": messages, @"users": usersMap};
    }];
}

- (NSArray *)_filterFailedGroups:(NSArray *)groups
{
    NSMutableArray *filteredGroups = [[NSMutableArray alloc] init];
    for (TGCallGroup *group in groups)
    {
        if (group.failed)
            [filteredGroups addObject:group];
    }
    return filteredGroups;
}

- (NSArray *)_collapseMessages:(NSArray *)messages
{
    NSMutableArray *collapsedMessages = [[NSMutableArray alloc] init];
    if (messages.count == 0)
        return collapsedMessages;
    
    NSMutableArray *currentMessages = nil;
    TGUser *currentPeer = nil;
    bool currentFailed = false;
    struct tm currentTimeinfo;
    
    NSUInteger i = 0;
    for (TGMessage *message in messages)
    {
        i++;
        
        TGUser *peer = _usersModel[@(message.outgoing ? message.toUid : message.fromUid)];
        bool outgoing = message.outgoing;
        int reason = [message.actionInfo.actionData[@"reason"] intValue];
        bool missed = reason == TGCallDiscardReasonMissed || reason == TGCallDiscardReasonBusy;
        bool failed = !outgoing && missed;
        
        struct tm timeinfo;
        time_t t = (int)message.date;
        localtime_r(&t, &timeinfo);
        
        if (currentPeer != nil)
        {
            if (currentPeer.uid == peer.uid && currentFailed == failed && currentTimeinfo.tm_year == timeinfo.tm_year && currentTimeinfo.tm_yday == timeinfo.tm_yday)
            {
                [currentMessages addObject:message];
                continue;
            }
            else
            {
                [collapsedMessages addObject:[[TGCallGroup alloc] initWithMessages:currentMessages peer:currentPeer failed:currentFailed]];
            }
        }
        
        currentPeer = peer;
        currentMessages = [[NSMutableArray alloc] initWithObjects:message, nil];
        currentFailed = failed;
        currentTimeinfo = timeinfo;
    }
    
    [collapsedMessages addObject:[[TGCallGroup alloc] initWithMessages:currentMessages peer:currentPeer failed:currentFailed]];
    
    return collapsedMessages;
}

- (bool)_processDictionary:(NSDictionary *)dictionary append:(bool)append
{
    if ([dictionary isKindOfClass:[NSDictionary class]])
    {
        if (append)
            _listModel = [_listModel arrayByAddingObjectsFromArray:dictionary[@"calls"]];
        else
            _listModel = dictionary[@"calls"];
        
        NSMutableDictionary *users = _usersModel != nil ? [[NSMutableDictionary alloc] initWithDictionary:_usersModel] : [[NSMutableDictionary alloc] init];
        [users addEntriesFromDictionary:dictionary[@"users"]];
        _usersModel = users;
        
        NSArray *collapsedListModel = [self _collapseMessages:_listModel];
        NSArray *filteredListModel = [self _filterFailedGroups:collapsedListModel];
        
        TGDispatchOnMainThread(^
        {
            if (append == false)
                _initialized = true;

            _displayListModel = collapsedListModel;
            _displayFilteredListModel = filteredListModel;
            [self reloadDataAnimated:false];
        });
        
        return [(NSArray *)dictionary[@"calls"] count] > 0;
    }
    
    return false;
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    [_queue dispatch:^
    {
        if ([path isEqualToString:@"/tg/userdatachanges"])
        {
            NSArray *users = (((SGraphObjectNode *)resource).object);
            
            NSMutableDictionary *usersModel = [[NSMutableDictionary alloc] initWithDictionary:_usersModel];
            NSMutableSet *updatedPeers = [[NSMutableSet alloc] init];
            for (TGUser *user in users)
            {
                NSNumber *uid = @(user.uid);
                if (_usersModel[uid] != nil)
                {
                    usersModel[uid] = user;
                    [updatedPeers addObject:uid];
                }
            }
            
            if (usersModel.count == 0)
                return;
            
            _usersModel = usersModel;
            
            NSArray *collapsedListModel = [self _collapseMessages:_listModel];
            NSArray *filteredListModel = [self _filterFailedGroups:collapsedListModel];
        
            TGDispatchOnMainThread(^
            {
                _displayListModel = collapsedListModel;
                _displayFilteredListModel = filteredListModel;
        
                [[self listModel] enumerateObjectsUsingBlock:^(TGCallGroup *callGroup, NSUInteger index, __unused BOOL *stop)
                {
                    if (index == NSNotFound)
                        return;
                    
                    if ([updatedPeers containsObject:@(callGroup.peer.uid)])
                    {
                        TGCallCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                        [cell setupWithCallGroup:callGroup];
                    }
                }];
            });
        }
        else if ([path isEqualToString:@"/tg/calls/added"])
        {
            NSMutableArray *messages = [((SGraphObjectNode *)resource).object mutableCopy];
            [messages sortUsingComparator:^NSComparisonResult(TGMessage *lhs, TGMessage *rhs)
            {
                return lhs.date < rhs.date ? NSOrderedDescending : NSOrderedAscending;
            }];
            
            NSArray *listModel = [_listModel copy];
            
            NSMutableIndexSet *userIds = [[NSMutableIndexSet alloc] init];
            for (TGMessage *message in messages)
                [userIds addIndex:(int32_t)(message.outgoing ? message.toUid : message.fromUid)];
            
            NSMutableIndexSet *indexesToDelete = [[NSMutableIndexSet alloc] init];
            [messages enumerateObjectsUsingBlock:^(TGMessage *message, NSUInteger index, __unused BOOL *stop)
            {
                for (TGMessage *existingMessage in listModel)
                {
                    if (existingMessage.fromUid == message.fromUid && existingMessage.mid == message.mid)
                        [indexesToDelete addIndex:index];
                }
            }];
            [messages removeObjectsAtIndexes:indexesToDelete];
            
            NSMutableArray *userSignals = [[NSMutableArray alloc] init];
            [userIds enumerateIndexesUsingBlock:^(NSUInteger uid, __unused BOOL *stop)
            {
                if (uid != 0)
                    [userSignals addObject:[[TGUserSignal userWithUserId:(int32_t)uid] take:1]];
            }];
            
            [[[SSignal combineSignals:userSignals] deliverOn:_queue] startWithNext:^(NSArray *users)
            {
                NSMutableDictionary *usersModel = [[NSMutableDictionary alloc] initWithDictionary:_usersModel];
                for (TGUser *user in users)
                {
                    usersModel[@(user.uid)] = user;
                }
                _usersModel = usersModel;
                
                _listModel = [messages arrayByAddingObjectsFromArray:_listModel];
                
                NSArray *collapsedListModel = [self _collapseMessages:_listModel];
                NSArray *filteredListModel = [self _filterFailedGroups:collapsedListModel];
                
                TGDispatchOnMainThread(^
                {
                    _displayListModel = collapsedListModel;
                    _displayFilteredListModel = filteredListModel;
                    
                    [self reloadDataAnimated:false];
                    
                    [self updateMissedCallsCount];
                });
            }];
        }
        else if ([path isEqualToString:@"/tg/messagesDeleted"])
        {
            NSDictionary *dictionary = ((SGraphObjectNode *)resource).object;
            
            int64_t peerId = [dictionary[@"peerId"] int64Value];
            NSArray *messageIds = dictionary[@"messageIds"];
            
            NSMutableSet *initialMids = [[NSMutableSet alloc] init];
            for (NSNumber *mid in messageIds)
                [initialMids addObject:mid];
            
            NSMutableSet *mids = [initialMids mutableCopy];
            NSMutableIndexSet *indexesToDelete = [[NSMutableIndexSet alloc] init];
            
            NSArray *initialListModel = [_listModel copy];
            [initialListModel enumerateObjectsUsingBlock:^(TGMessage *message, NSUInteger index, BOOL *stop)
            {
                if (index == NSNotFound)
                    return;
                
                int64_t messagePeerId = message.outgoing ? message.toUid : message.fromUid;
                if (messagePeerId == peerId && [mids containsObject:@(message.mid)])
                {
                    [indexesToDelete addIndex:index];
                    [mids removeObject:@(message.mid)];
                }
                
                if (mids.count == 0)
                    *stop = true;
            }];
            
            NSMutableArray *listModel = [initialListModel mutableCopy];
            [listModel removeObjectsAtIndexes:indexesToDelete];
            _listModel = listModel;
            
            NSArray *collapsedListModel = [self _collapseMessages:_listModel];
            NSArray *filteredListModel = [self _filterFailedGroups:collapsedListModel];
        
            bool shouldUpdate = _listModel.count != initialListModel.count;
            if (shouldUpdate)
            {
                TGDispatchOnMainThread(^
                {
                    _displayListModel = collapsedListModel;
                    _displayFilteredListModel = filteredListModel;
                    
                    [self reloadDataAnimated:false];
                    
                    [self updateMissedCallsCount];
                });
            }
        }
        else if ([path isEqualToString:@"/tg/conversationsCleared"])
        {
            NSDictionary *dictionary = ((SGraphObjectNode *)resource).object;
            NSSet *peerIds = [[NSSet alloc] initWithArray:dictionary[@"peerIds"]];
            
            NSMutableIndexSet *indexesToDelete = [[NSMutableIndexSet alloc] init];
            
            NSArray *initialListModel = [_listModel copy];
            [initialListModel enumerateObjectsUsingBlock:^(TGMessage *message, NSUInteger index, __unused BOOL *stop)
            {
                if (index == NSNotFound)
                    return;
                
                NSNumber *peerId = @(message.outgoing ? message.toUid : message.fromUid);
                if ([peerIds containsObject:peerId])
                {
                    [indexesToDelete addIndex:index];
                }
            }];
            
            NSMutableArray *listModel = [initialListModel mutableCopy];
            [listModel removeObjectsAtIndexes:indexesToDelete];
            _listModel = listModel;
            
            [indexesToDelete removeAllIndexes];
            
            NSArray *collapsedListModel = [self _collapseMessages:_listModel];
            NSArray *filteredListModel = [self _filterFailedGroups:collapsedListModel];
            
            bool shouldUpdate = _listModel.count != initialListModel.count;
            if (shouldUpdate)
            {
                TGDispatchOnMainThread(^
                {
                    _displayListModel = collapsedListModel;
                    _displayFilteredListModel = filteredListModel;
                    
                    [self reloadDataAnimated:false];
                    
                    [self updateMissedCallsCount];
                    
                    if (_displayListModel.count == 0)
                        [self initialize];
                });
            }
        }
        else if ([path isEqualToString:@"/tg/readPeerHistories"])
        {
            if (_lastMissedCount == 0)
                return;
            
            NSMutableSet *peerIds = [[NSMutableSet alloc] init];;
            for (TGReadPeerMessagesRequest *request in ((SGraphObjectNode *)resource).object) {
                [peerIds addObject:@(request.peerId)];
            }
            
            NSArray *listModel = [_listModel copy];
            
            bool shouldUpdate = false;
            for (TGMessage *message in listModel)
            {
                if (!message.outgoing && [message.actionInfo.actionData[@"reason"] intValue] == TGCallDiscardReasonMissed)
                {
                    if ([peerIds containsObject:@(message.cid)])
                    {
                        shouldUpdate = true;
                        break;
                    }
                }
            }
            
            if (shouldUpdate)
            {
                TGDispatchOnMainThread(^
                {
                    [self updateMissedCallsCount];
                });
            }
        }
        else if ([path isEqualToString:@"/tg/updatedMaxIncomingReadIds"])
        {
            if (_lastMissedCount == 0)
                return;
            
            NSArray *peerIdsArray = [((SGraphObjectNode *)resource).object allKeys];
            NSSet *peerIds = [NSSet setWithArray:peerIdsArray];
            
            NSArray *listModel = [_listModel copy];
            
            bool shouldUpdate = false;
            for (TGMessage *message in listModel)
            {
                if (!message.outgoing && [message.actionInfo.actionData[@"reason"] intValue] == TGCallDiscardReasonMissed)
                {
                    if ([peerIds containsObject:@(message.cid)])
                    {
                        shouldUpdate = true;
                        break;
                    }
                }
            }
            
            if (shouldUpdate)
            {
                TGDispatchOnMainThread(^
                {
                    [self updateMissedCallsCount];
                });
            }
        }
    }];
}

- (void)initialize
{
    _loading = true;
    
    __weak TGRecentCallsController *weakSelf = self;
    __block bool gotItems = false;
    
    SSignal *signal = [[TGDatabaseInstance() modify:^id{ return nil; }] mapToSignal:^SSignal *(__unused id value) {
        if (TGTelegraphInstance.clientUserId != 0) {
            [TGTelegramNetworking instance];
        }
        
        return [[[SSignal single:nil] deliverOn:[SQueue wrapConcurrentNativeQueue:[ActionStageInstance() globalStageDispatchQueue]]] mapToSignal:^SSignal *(__unused id value)
        {
            return [self searchSignalWithQuery:nil maxMessageId:0 count:32];
        }];
    }];
    
    _disposable = [[SMetaDisposable alloc] init];
    [_disposable setDisposable:[[[signal mapToSignal:^SSignal *(id messages) {
        return [TGRecentCallsController _mapMessages:messages];
    }] deliverOn:_queue] startWithNext:^(id next) {
        __strong TGRecentCallsController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if ([next isKindOfClass:[NSNumber class]])
            strongSelf->_loading = false;
        else
            gotItems = [strongSelf _processDictionary:next append:false];
    } error:^(__unused id error) {
        __strong TGRecentCallsController *strongSelf = weakSelf;
        if (strongSelf != nil)
            strongSelf->_loading = false;
    } completed:^
    {
        __strong TGRecentCallsController *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            TGDispatchOnMainThread(^
            {
                strongSelf->_loading = false;
                [strongSelf updateLoadMoreSignal:gotItems];
                [strongSelf subscribeToUpdates];
                
                if (strongSelf->_displayListModel.count < 12)
                    [strongSelf _maybeLoadMore:true];
            });
        }
    }]];
}

- (void)subscribeToUpdates
{
    [ActionStageInstance() watchForPaths:@
    [
        @"/tg/userdatachanges",
        @"/as/updateRelativeTimestamps",
        @"/tg/calls/added",
        @"/tg/messagesDeleted",
        @"/tg/conversationsCleared",
        @"/tg/readPeerHistories",
        @"/tg/updatedMaxIncomingReadIds"
    ] watcher:self];
}

- (void)_maybeLoadMore
{
    [self _maybeLoadMore:false];
}

- (void)_maybeLoadMore:(bool)force
{
    if (_currentLoadMoreSignal != nil && (force || _tableView.contentOffset.y > _tableView.contentSize.height - _tableView.bounds.size.height))
    {
        SSignal *currentLoadMoreSignal = _currentLoadMoreSignal;
        _currentLoadMoreSignal = nil;
        __weak TGRecentCallsController *weakSelf = self;
        
        __block bool gotItems = false;
        [_disposable setDisposable:[[[currentLoadMoreSignal mapToSignal:^SSignal *(id messages) {
            return [TGRecentCallsController _mapMessages:messages];
        }] deliverOn:_queue] startWithNext:^(id next)
        {
            gotItems = [self _processDictionary:next append:true];
        } error:nil completed:^
        {
            __strong TGRecentCallsController *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                TGDispatchOnMainThread(^
                {
                    [strongSelf updateLoadMoreSignal:gotItems];
                    [strongSelf _maybeLoadMore];
                });
            }
        }]];
    }
}

- (void)updateLoadMoreSignal:(bool)gotMore
{
    int32_t minMessageId = INT_MAX;
    for (TGCallGroup *group in _displayListModel)
    {
        for (TGMessage *message in group.messages)
        {
            if (message.mid != 0)
                minMessageId = MIN(message.mid, minMessageId);
        }
    }
    
    if (minMessageId != INT_MAX && gotMore)
        _currentLoadMoreSignal = [self searchSignalWithQuery:nil maxMessageId:minMessageId count:128];
    else
        _currentLoadMoreSignal = nil;
}

- (void)deleteCallGroup:(TGCallGroup *)callGroup
{
    if (callGroup == nil)
        return;

    [self setReloadReady:false];
    
    NSArray *oldEntries = [[self listModel] copy];
    
    NSInteger listIndex = [_displayListModel indexOfObject:callGroup];
    if (listIndex == NSNotFound)
    {
        [self setReloadReady:true];
        return;
    }
    
    NSMutableArray *listModel = [_displayListModel mutableCopy];
    [listModel removeObjectAtIndex:listIndex];
    _displayListModel = listModel;
    _displayFilteredListModel = [self _filterFailedGroups:_displayListModel];
    
    if (listIndex != NSNotFound)
        [self reloadDataAnimated:true oldEntries:oldEntries newEntries:[self listModel] force:true];
    
    NSMutableArray *mids = [[NSMutableArray alloc] init];
    for (TGMessage *message in callGroup.messages)
        [mids addObject:@(message.mid)];
    
    static int uniqueId = 100000;
    [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/conversation/(%d)/deleteMessages/(%s%d)", callGroup.peer.uid, __PRETTY_FUNCTION__, uniqueId++] options:@{@"mids": mids, @"forEveryone": @false} watcher:TGTelegraphInstance];
}

- (void)dismissEditingControls:(CGPoint)point force:(bool)force
{
    for (NSIndexPath *indexPath in [_tableView indexPathsForVisibleRows]) {
        TGCallCell *cell = (TGCallCell *)[_tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[TGCallCell class]]) {
            if ([cell isEditingControlsExpanded]) {
                CGRect rect = [cell convertRect:cell.bounds toView:_tableView];
                if (force || !CGRectContainsPoint(rect, point)) {
                    [cell setEditingConrolsExpanded:false animated:true];
                }
            }
        }
    }
}

- (void)clearData
{
    [_disposable dispose];
    _disposable = nil;
    
    _usersModel = [[NSDictionary alloc] init];
    _listModel = [[NSArray alloc] init];
    _displayListModel = nil;
    _displayFilteredListModel = nil;
    _missed = false;
    [_tableView reloadData];
}

- (SSignal *)searchSignalWithQuery:(NSString *)query maxMessageId:(int32_t)maxMessageId count:(int32_t)count
{
    if (TGTelegraphInstance.clientUserId != 0) {
        return [TGMessageSearchSignals searchPeer:0 accessHash:0 query:query filter:TGMessageSearchFilterPhoneCalls maxMessageId:maxMessageId limit:count];
    } else {
        return [SSignal never];
    }
}

- (void)updateMissedCallsCount
{
    [TGDatabaseInstance() dispatchOnDatabaseThread:^
    {
        NSInteger count = 0;
        for (TGMessage *message in _listModel)
        {
            if (!message.outgoing && [message.actionInfo.actionData[@"reason"] intValue] == TGCallDiscardReasonMissed)
            {
                TGConversation *conversation = [TGDatabaseInstance() loadConversationWithIdCached:message.cid];
                if ([conversation isMessageUnread:message])
                    count++;
            }
        }
        
        [_queue dispatch:^
        {
            _lastMissedCount = count;
            
            TGDispatchOnMainThread(^
            {
                if (self.missedCountChanged != nil)
                    self.missedCountChanged(count);
            });
        }];
    } synchronous:false];
}

- (void)updateLocalization {
    NSArray *items = @[TGLocalized(@"Calls.All"), TGLocalized(@"Calls.Missed")];
    for (NSUInteger i = 0; i < items.count; i++) {
        [_segmentedControl setTitle:items[i] forSegmentAtIndex:i];
    }
    
    _placeholderLabel.text = TGLocalized(@"Calls.NoCallsPlaceholder");
    [self updatePlaceholder];
    
    [self.view layoutSubviews];
    
    [self updateBarButtonItemsAnimated:false];
    
    [_tableView reloadData];
}

@end
