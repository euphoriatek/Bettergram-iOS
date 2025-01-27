#import <LegacyComponents/LegacyComponents.h>

#import <LegacyComponents/ASWatcher.h>

#import "TGMessageRange.h"

#import "TGModernConversationInputPanel.h"
#import "TGModernConversationEmptyListPlaceholderView.h"
#import "TGModernConversationCompanion.h"
#import "TGViewController+OpenLink.h"

@class TGModernConversationCompanion;
@class TGModernViewStorage;
@class TGModernConversationItem;
@class TGUser;
@class TGMessage;
@class TGModernTemporaryView;

@class TGModernConversationTitlePanel;

@class TGModernViewInlineMediaContext;

@class TGBotReplyMarkup;

@class TGWebPageMediaAttachment;

@class TGConversationScrollState;
@class TGPIPSourceLocation;

@class TGPresentation;

@protocol TGStickerPackReference;

extern NSInteger TGModernConversationControllerUnloadHistoryLimit;
extern NSInteger TGModernConversationControllerUnloadHistoryThreshold;

#define migratedMessageIdOffset ((int32_t)1000000)

typedef enum {
    TGModernConversationInsertItemIntentGeneric = 0,
    TGModernConversationInsertItemIntentSendTextMessage = 1,
    TGModernConversationInsertItemIntentSendOtherMessage = 2,
    TGModernConversationInsertItemIntentLoadMoreMessagesAbove = 3,
    TGModernConversationInsertItemIntentLoadMoreMessagesBelow = 4
} TGModernConversationInsertItemIntent;

@interface TGModernConversationController : TGViewController <ASWatcher, TGModernConversationInputPanelDelegate>

@property (nonatomic, strong) ASHandle *actionHandle;

@property (nonatomic, strong) void (^onViewDidAppear)(void);

@property (nonatomic, strong) TGPresentation *presentation;
@property (nonatomic, strong) TGModernConversationCompanion *companion;
@property (nonatomic) bool shouldIgnoreAppearAnimationOnce;
@property (nonatomic) bool shouldOpenKeyboardOnce;

@property (nonatomic) bool canOpenKeyboardWhileInTransition;

@property (nonatomic, copy) void (^willChangeDim)(bool dim, UIView *keyboardSnapshotView, bool restoringFocus);

- (void)setInitialSnapshot:(CGImageRef)image backgroundView:(TGModernTemporaryView *)backgroundView viewStorage:(TGModernViewStorage *)viewStorage topEdge:(CGFloat)topEdge displayScrollDownButton:(bool)displayScrollDownButton;
- (TGMessage *)latestVisibleMessage;
- (NSArray *)visibleMessageIds;
- (NSArray *)_currentItems;
- (void)replaceItems:(NSArray *)newItems messageIdForVisibleHoleDirection:(int32_t)messageIdForVisibleHoleDirection;
- (void)replaceItems:(NSArray *)newItems positionAtMessageId:(int32_t)positionAtMessageId peerId:(int64_t)positionAtPeerId expandAt:(int32_t)expandMessageId jump:(bool)jump top:(bool)top messageIdForVisibleHoleDirection:(int32_t)messageIdForVisibleHoleDirection scrollBackMessageId:(int32_t)scrollBackMessageId animated:(bool)animated;
- (void)replaceItemsWithFastScroll:(NSArray *)newItems intent:(TGModernConversationInsertItemIntent)intent scrollToMessageId:(int32_t)scrollToMessageId peerId:(int64_t)scrollToPeerId scrollBackMessageId:(int32_t)scrollBackMessageId animated:(bool)animated;
- (void)replaceItems:(NSArray *)items atIndices:(NSIndexSet *)indices;
- (void)insertItems:(NSArray *)insertItems atIndices:(NSIndexSet *)indices animated:(bool)animated intent:(TGModernConversationInsertItemIntent)intent;
- (void)insertItems:(NSArray *)itemsArray atIndices:(NSIndexSet *)indexSet animated:(bool)animated intent:(TGModernConversationInsertItemIntent)intent removeAtIndices:(NSIndexSet *)removeIndexSet;
- (void)deleteItemsAtIndices:(NSIndexSet *)indices animated:(bool)animated;
- (void)_deleteItemsAtIndices:(NSIndexSet *)indices animated:(bool)animated animationFactor:(CGFloat)animationFactor;
- (void)moveItems:(NSArray *)moveIndexPairs;
- (void)updateItemAtIndex:(NSUInteger)index toItem:(TGModernConversationItem *)updatedItem delayAvailability:(bool)delayAvailability;
- (void)updateItemAtIndex:(NSUInteger)index toItem:(TGModernConversationItem *)updatedItem delayAvailability:(bool)delayAvailability animated:(bool)animated animateTransition:(bool)animateExpiration force:(bool)force;
- (void)updateItemProgressAtIndex:(NSUInteger)index toProgress:(CGFloat)progress animated:(bool)animated;
- (void)imageDataInvalidated:(NSString *)imageUrl;
- (void)updateCheckedMessages;
- (void)updateMessageAttributes:(int32_t)messageId;
- (void)updateAllMessageAttributes;
- (void)setHasUnseenMessagesBelow:(bool)hasUnseenMessagesBelow;
- (void)setUnreadMessageRangeIfAppropriate:(TGMessageRange)unreadMessageRange;

- (void)scrollToMessage:(int32_t)messageId peerId:(int64_t)peerId sourceMessageId:(int32_t)sourceMessageId animated:(bool)animated;
- (void)openMediaFromMessage:(int32_t)messageId peerId:(int64_t)peerId cancelPIP:(bool)cancelPIP;
- (void)openMediaFromMessage:(int32_t)messageId peerId:(int64_t)peerId instant:(bool)instant;
- (void)closeMediaFromMessage:(int32_t)messageId peerId:(int64_t)peerId instant:(bool)instant;
- (void)stopInlineMedia:(int32_t)excludeMid;
- (void)resumeInlineMedia;
- (void)openBrowserFromMessage:(int32_t)messageId url:(NSString *)url;
- (void)openLocationFromMessage:(TGMessage *)message previewMode:(bool)previewMode zoomToFitAll:(bool)zoomToFitAll;
- (void)showActionsMenuForUnsentMessage:(int32_t)messageId edit:(bool)edit;
- (void)highlightAndShowActionsMenuForMessage:(int32_t)messageId peerId:(int64_t)peerId groupedId:(int64_t)groupedId;
- (void)temporaryHighlightMessage:(int32_t)messageId automatically:(bool)automatically;
- (void)temporaryHighlightMessage:(int32_t)messageId grouped:(bool)grouped automatically:(bool)automatically;
- (void)showActionsMenuForContact:(TGUser *)contact isContact:(bool)isContact;
- (void)showAddContactMenu:(TGUser *)contact;
- (void)showCallNumberMenu:(NSArray *)phoneNumbers;
- (void)enterEditingMode;
- (void)leaveEditingMode;
- (void)openKeyboard;
- (void)hideTitlePanel;
- (void)endEditing;

- (void)reloadBackground;
- (void)refreshMetrics;
- (void)setInputText:(NSString *)inputText replace:(bool)replace selectRange:(NSRange)selectRange;
- (void)setInputText:(NSString *)inputText entities:(NSArray *)entities replace:(bool)replace replaceIfPrefix:(bool)replaceIfPrefix selectRange:(NSRange)selectRange forceSelectRange:(bool)forceSelectRange;
- (void)setMessageEditingContext:(TGMessageEditingContext *)messageEditingContext;
- (NSString *)inputText;
- (void)updateWebpageLinks;
- (void)setReplyMessage:(TGMessage *)replyMessage animated:(bool)animated;
- (void)setReplyMessage:(TGMessage *)replyMessage openKeyboard:(bool)openKeyboard animated:(bool)animated;
- (void)setForwardMessages:(NSArray *)forwardMessages completeGroups:(NSSet *)completeGroups animated:(bool)animated;
- (void)setInlineStickerList:(NSDictionary *)inlineStickerList;
- (void)setTitle:(NSString *)title;
- (void)setAvatarConversationId:(int64_t)conversationId title:(NSString *)title icon:(UIImage *)icon;
- (void)setAvatarConversationIds:(NSArray *)conversationIds titles:(NSArray *)titles;
- (void)setAvatarConversationId:(int64_t)conversationId firstName:(NSString *)firstName lastName:(NSString *)lastName;
- (void)setTitleIcons:(NSArray *)titleIcons;
- (void)setTitleModalProgressStatus:(NSString *)titleModalProgressStatus;
- (void)setAvatarUrl:(NSString *)avatarUrl;
- (void)setAvatarUrls:(NSArray *)avatarUrls;
- (void)setStatus:(NSString *)status accentColored:(bool)accentColored allowAnimation:(bool)allowAnimation toggleMode:(TGModernConversationControllerTitleToggle)toggleMode;
- (void)setAttributedStatus:(NSAttributedString *)status allowAnimation:(bool)allowAnimation;
- (void)setTypingStatus:(NSString *)typingStatus activity:(int)activity;
- (void)setGlobalUnreadCount:(int)unreadCount;
- (void)setUnreadMentionCount:(int32_t)unreadMentionCount;
- (void)setCustomInputPanel:(TGModernConversationInputPanel *)customInputPanel;
- (void)setDefaultInputPanel:(TGModernConversationInputPanel *)defaultInputPanel;

- (bool)hasNonTextInputPanel;
- (TGModernConversationInputPanel *)customInputPanel;
- (void)setPrimaryTitlePanel:(TGModernConversationTitlePanel *)titlePanel;
- (TGModernConversationTitlePanel *)primaryTitlePanel;
- (void)setSecondaryTitlePanel:(TGModernConversationTitlePanel *)secondaryTitlePanel;
- (void)setSecondaryTitlePanel:(TGModernConversationTitlePanel *)secondaryTitlePanel animated:(bool)animated;
- (TGModernConversationTitlePanel *)secondaryTitlePanel;
- (void)setEmptyListPlaceholder:(TGModernConversationEmptyListPlaceholderView *)emptyListPlaceholder;
- (void)setConversationHeader:(UIView *)conversationHeader;

- (void)setEnableAboveHistoryRequests:(bool)enableAboveHistoryRequests;
- (void)setEnableBelowHistoryRequests:(bool)enableBelowHistoryRequests;
- (void)setEnableUnloadHistoryRequests:(bool)enableUnloadHistoryRequests;
- (void)setEnableSendButton:(bool)enableSendButton;

- (bool)canReadHistory;

- (NSArray *)_items;
- (int32_t)_currentReplyMessageId;
- (NSArray *)_currentForwardMessageDescs;
- (TGConversationScrollState *)_currentScrollState;

- (void)setReplyMarkup:(TGBotReplyMarkup *)replyMarkup;
- (void)appendCommand:(NSString *)command;
- (void)setHasBots:(bool)hasBots;
- (void)setCanBroadcast:(bool)canBroadcast;
- (void)setIsBroadcasting:(bool)isBroadcasting;
- (void)setIsAlwaysBroadcasting:(bool)isBroadcasting;
- (void)setInputDisabled:(bool)inputDisabled;
- (void)setIsChannel:(bool)isChannel;
- (void)updateControllerShouldHideInputTextByDefault;

- (void)openEmbed:(TGWebPageMediaAttachment *)webPage forMessageId:(int32_t)messageId peerId:(int64_t)peerId;
- (void)openEmbedFromMessageId:(int32_t)messageId peerId:(int64_t)peerId cancelPIP:(bool)cancelPIP;

- (bool)openPIPSourceLocation:(TGPIPSourceLocation *)location;

- (void)openStickerPackForReference:(id<TGStickerPackReference>)packReference;
- (void)openStickerPackForMessageId:(int32_t)messageId peerId:(int64_t)peerId;

- (void)activateSearch;
- (void)forwardMessages:(NSArray *)messageIndices fastForward:(bool)fastForward grouped:(bool)grouped;

- (void)setExclusiveSearchQuery:(NSString *)query;

- (void)setLoadingMessages:(bool)loadingMessages;
- (void)messagesDeleted:(NSArray *)messageIds;

- (void)pushEarliestUnreadMessageId:(int32_t)messageId;

- (void)incrementScrollDownUnreadCount:(NSInteger)count;

- (bool)maybeShowDiscardRecordingAlert;
- (void)updateFeaturesAvailability;

- (SSignal *)messageVisiblitySignalForMessageId:(int32_t)messageId peerId:(int64_t)peerId;

- (void)setBannedStickers:(bool)bannedStickers;
- (void)setBannedMedia:(bool)bannedMedia;

- (void)_updateItemForReplySwipeInteraction:(int32_t)mid ended:(bool)ended;
- (void)_updateGroupedItemsForReplySwipeInteraction:(int32_t)mid groupedId:(int64_t)groupedId offset:(CGFloat)offset ended:(bool)ended;

- (void)_displayLocationPicker;

- (CGFloat)initialUnreadOffset;

- (void)setSecondaryController:(TGViewController *)secondaryController;

- (void)showNext;

- (void)maybeDisplayGifTooltip;

@end
