#import "TGModernConversationInputTextPanel.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGStickerKeyboardView.h"
#import "TGStickersSignals.h"

#import <MTProtoKit/MTTime.h>
#import <LegacyComponents/TGTimerTarget.h>

#import <LegacyComponents/HPGrowingTextView.h>
#import <LegacyComponents/HPTextViewInternal.h>

#import <LegacyComponents/TGModernButton.h>
#import <LegacyComponents/TGModernConversationInputMicButton.h>
#import "TGModernConversationInputAttachButton.h"

#import "TGGroupManagementSignals.h"

#import <LegacyComponents/TGModernConversationAssociatedInputPanel.h>
#import "TGStickerAssociatedInputPanel.h"
#import "TGCommandKeyboardView.h"
#import "TGModernConversationDimWindow.h"

#import "TGModenConcersationReplyAssociatedPanel.h"
#import "TGModernConversationCommandsAssociatedPanel.h"
#import "TGModernConversationMediaContextResultsAssociatedPanel.h"
#import "TGModernConversationGenericContextResultsAssociatedPanel.h"
#import "TGInlineBotsInputPanel.h"

#import "TGPresentationAssets.h"

#import "TGAppDelegate.h"
#import "TGLegacyComponentsContext.h"

#import <LegacyComponents/TGInputTextTag.h>

#import <MTProtoKit/MTProtoKit.h>

#import "TGPresentation.h"

static void removeViewAnimation(UIView *view, NSString *animationPrefix)
{
    for (NSString *key in view.layer.animationKeys)
    {
        if ([key hasPrefix:animationPrefix])
            [view.layer removeAnimationForKey:key];
    }
}

static void setViewFrame(UIView *view, CGRect frame)
{
    CGAffineTransform transform = view.transform;
    view.transform = CGAffineTransformIdentity;
    if (!CGRectEqualToRect(view.frame, frame))
        view.frame = frame;
    view.transform = transform;
}

static CGRect viewFrame(UIView *view)
{
    CGPoint center = view.center;
    CGSize size = view.bounds.size;
    
    return CGRectMake(center.x - size.width / 2, center.y - size.height / 2, size.width, size.height);
}

@implementation TGMessageEditingContext

+ (NSAttributedString *)attributedStringForText:(NSString *)text entities:(NSArray *)entities fontSize:(CGFloat)fontSize {
    if (text == nil) {
        return nil;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: TGSystemFontOfSize(fontSize)}];
    for (id entity in entities) {
        if ([entity isKindOfClass:[TGMessageEntityMentionName class]]) {
            TGMessageEntityMentionName *mentionEntity = entity;
            static int64_t nextId = 1000000;
            int64_t uniqueId = nextId;
            nextId++;
            @try {
                [attributedString addAttributes:@{TGMentionUidAttributeName: [[TGInputTextTag alloc] initWithUniqueId:uniqueId left:true attachment:@(mentionEntity.userId)]} range:mentionEntity.range];
            } @catch(NSException *e) {
                TGLog(@"attributedStringForText exception %@", e);
            }
        }
        else if (iosMajorVersion() >= 7) {
            if ([entity isKindOfClass:[TGMessageEntityBold class]]) {
                TGMessageEntityBold *boldEntity = entity;
                @try {
                    [attributedString addAttributes:@{NSFontAttributeName: TGBoldSystemFontOfSize(fontSize)} range:boldEntity.range];
                } @catch(NSException *e) {
                    TGLog(@"attributedStringForText exception %@", e);
                }
            } else if ([entity isKindOfClass:[TGMessageEntityItalic class]]) {
                TGMessageEntityItalic *italicEntity = entity;
                @try {
                    [attributedString addAttributes:@{NSFontAttributeName: TGItalicSystemFontOfSize(fontSize)} range:italicEntity.range];
                } @catch(NSException *e) {
                    TGLog(@"attributedStringForText exception %@", e);
                }
            }
        }
    }
    return attributedString;
}

- (instancetype)initWithText:(NSString *)text entities:(NSArray *)entities isCaption:(bool)isCaption hasMedia:(bool)hasMedia cid:(int64_t)cid messageId:(int32_t)messageId {
    self = [super init];
    if (self != nil) {
        _text = text;
        _entities = entities;
        _isCaption = isCaption;
        _hasMedia = hasMedia;
        _cid = cid;
        _messageId = messageId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSData *entitiesData = [aDecoder decodeObjectForKey:@"entities"];
    NSArray *entities = [[[PSKeyValueDecoder alloc] initWithData:entitiesData] decodeArrayForCKey:"_"];
    return [self initWithText:[aDecoder decodeObjectForKey:@"text"] entities:entities isCaption:[aDecoder decodeBoolForKey:@"isCaption"] hasMedia:[aDecoder decodeBoolForKey:@"hasMedia"] cid:[aDecoder decodeInt64ForKey:@"cid"] messageId:[aDecoder decodeInt32ForKey:@"messageId"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_text forKey:@"text"];
    PSKeyValueEncoder *coder = [[PSKeyValueEncoder alloc] init];
    [coder encodeArray:_entities forCKey:"_"];
    [aCoder encodeObject:[coder data] forKey:@"entities"];
    [aCoder encodeBool:_isCaption forKey:@"isCaption"];
    [aCoder encodeBool:_hasMedia forKey:@"hasMedia"];
    [aCoder encodeInt64:_cid forKey:@"cid"];
    [aCoder encodeInt32:_messageId forKey:@"messageId"];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TGMessageEditingContext class]] && TGStringCompare(((TGMessageEditingContext *)object)->_text, _text) && ((TGMessageEditingContext *)object)->_isCaption == _isCaption && ((TGMessageEditingContext *)object)->_hasMedia == _hasMedia && ((TGMessageEditingContext *)object)->_cid == _cid && ((TGMessageEditingContext *)object)->_messageId == _messageId && TGObjectCompare(_entities, ((TGMessageEditingContext *)object)->_entities)) {
        return true;
    }
    return false;
}

@end

@interface TGModernConversationInputTextPanel () <HPGrowingTextViewDelegate, TGModernConversationInputAttachButtonDelegate, TGModernConversationInputMicButtonDelegate>
{
    id<SDisposable> _stickerPacksDisposable;
    
    UIView *_stripeView;
    UIView *_backgroundView;
    
    CGFloat _sendButtonWidth;
    
    CGSize _messageAreaSize;
    CGFloat _keyboardHeight;
    CGFloat _contentAreaHeight;
    UIEdgeInsets _safeAreaInset;
    
#if TG_ENABLE_AUDIO_NOTES
    TGModernConversationInputMicButton *_micButton;
    UIImageView *_micButtonIconView;
    bool _pressingMicButton;
#endif
    
    UIView *_audioRecordingContainer;
    NSUInteger _audioRecordingDurationSeconds;
    NSUInteger _audioRecordingDurationMilliseconds;
    NSTimer *_audioRecordingTimer;
    UIImageView *_recordIndicatorView;
    UILabel *_recordDurationLabel;
    
    UIImageView *_slideToCancelArrow;
    UILabel *_slideToCancelLabel;
    
    TGModernButton *_cancelButton;
    
    CFAbsoluteTime _recordingInterfaceShowTime;
    
    bool _keepAssociatedPanelVisible;
    TGModernConversationAssociatedInputPanel *_associatedPanel;
    TGModernConversationAssociatedInputPanel *_disappearingAssociatedPanel;
    
    TGModernConversationAssociatedInputPanel *_firstExtendedPanel;
    TGModernConversationAssociatedInputPanel *_secondExtendedPanel;
    
    TGModernConversationAssociatedInputPanel *_currentExtendedPanel;
    
    UIView *_customKeyboardWrapperView;
    CGFloat _customKeyboardHeight;
    UIView<TGModernConversationKeyboardView> *_customKeyboardView;
    NSInteger _customKeyboardVersion;
    bool _animatingCustomKeyboard;
    TGModernConversationDimWindow *_dimWindow;
    UIView *_keyboardSnapshotView;
    bool _willRestoreFocus;
    
    TGModernButton *_keyboardModeButton;
    TGModernButton *_stickerModeButton;
    TGModernButton *_commandModeButton;
    TGModernButton *_slashModeButton;
    TGModernButton *_broadcastButton;
    TGModernButton *_progressButton;
    TGModernButton *_clearButton;
    TGModernButton *_atButton;
    UIActivityIndicatorView *_progressButtonIndicator;
    
    TGModernButton *_stickersArrowButton;
    
    NSArray *_modeButtons;
    NSArray *_allModeButtons;
    
    TGStickerKeyboardView *_stickerKeyboardView;
    bool _shouldShowKeyboardAutomatically;
    
    UIView *_overlayDisabledView;
    
    CGSize _parentSize;
    bool _associatedPanelVisible;
    
    bool _removeGifTabTextOnDeactivation;
    
    UILabel *_contextPlaceholderLabel;
    bool _recording;
    
    TGMessageEditingContext *_messageEditingContext;
    bool _messageEditingContextInvalidated;
    bool _hasEditingButton;
    
    TGInlineBotsInputPanel *_inlineBotsPanel;
    
    UIImpactFeedbackGenerator *_feedbackGenerator;
    
    bool _inputMediaAllowed;
    
    SSignal *_channelInfoSignal;
    
    id _inputTypeObserver;
    SMetaDisposable *_inputTypeKeyboardUpdateDisposable;
    
    bool _collapsed;
}

@end

@implementation TGModernConversationInputTextPanel

- (instancetype)initWithFrame:(CGRect)frame accessoryView:(UIView *)panelAccessoryView
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _sendButtonWidth = 45.0f;
        _panelAccessoryView = panelAccessoryView;
        
        _backgroundView = [[UIView alloc] init];
        [self addSubview:_backgroundView];
        
        _stripeView = [[UIView alloc] init];
        [self addSubview:_stripeView];
        
        _fieldBackground = [[UIImageView alloc] init];
        setViewFrame(_fieldBackground, CGRectMake(45, 6, self.frame.size.width - 45 - _sendButtonWidth - 1, 33));
        _fieldBackground.userInteractionEnabled = true;
        [_fieldBackground addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fieldBackgroundTapGesture:)]];
        [self addSubview:_fieldBackground];
        
        CGRect fieldBackgroundFrame = viewFrame(_fieldBackground);
        setViewFrame(_panelAccessoryView, CGRectMake(CGRectGetMaxX(fieldBackgroundFrame) - _panelAccessoryView.frame.size.width, fieldBackgroundFrame.origin.y - 1.0f, _panelAccessoryView.frame.size.width, _panelAccessoryView.frame.size.height));
        [self addSubview:_panelAccessoryView];
        
        CGPoint placeholderOffset = [self inputFieldPlaceholderOffset];
        _inputFieldPlaceholder = [[UIImageView alloc] init];
        [self _updatePlaceholderImage];
        setViewFrame(_inputFieldPlaceholder, CGRectOffset(_inputFieldPlaceholder.bounds, placeholderOffset.x, placeholderOffset.y));
        [_fieldBackground addSubview:_inputFieldPlaceholder];
        
        CGFloat modeWidth = 29.0f;
        _stickerModeButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, modeWidth, 33.0f)];
        [_stickerModeButton addTarget:self action:@selector(stickerModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _stickerModeButton.adjustsImageWhenHighlighted = false;
        _stickerModeButton.alpha = 0.0f;
        _stickerModeButton.userInteractionEnabled = false;
        
        _commandModeButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, modeWidth, 33.0f)];
        [_commandModeButton addTarget:self action:@selector(commandModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _commandModeButton.adjustsImageWhenHighlighted = false;
        _commandModeButton.alpha = 0.0f;
        _commandModeButton.userInteractionEnabled = false;
        
        _slashModeButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, modeWidth, 33.0f)];
        [_slashModeButton addTarget:self action:@selector(slashModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _slashModeButton.adjustsImageWhenHighlighted = false;
        _slashModeButton.alpha = 0.0f;
        _slashModeButton.userInteractionEnabled = false;
        
        _broadcastButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, modeWidth, 33.0f)];
        [_broadcastButton setContentEdgeInsets:UIEdgeInsetsMake(0.0f, -2.0f, 0.0f, -2.0f)];
        [_broadcastButton addTarget:self action:@selector(broadcastButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _broadcastButton.adjustsImageWhenHighlighted = false;
        _broadcastButton.alpha = 0.0f;
        _broadcastButton.userInteractionEnabled = false;
        
        _progressButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 33.0f, 33.0f)];
        [_progressButton addTarget:self action:@selector(clearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.extendedEdgeInsets = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 4.0f);
        _progressButton.alpha = 0.0f;
        _progressButton.userInteractionEnabled = false;
        
        _clearButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 33.0f, 33.0f)];
        [_clearButton setContentEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        _clearButton.layer.sublayerTransform = CATransform3DMakeTranslation(7.0f - 1.0f / TGScreenScaling(), 0.0f, 0.0f);
        [_clearButton addTarget:self action:@selector(clearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.adjustsImageWhenHighlighted = false;
        _clearButton.extendedEdgeInsets = UIEdgeInsetsMake(4.0f, 4.0f, 4.0f, 4.0f);
        _clearButton.alpha = 0.0f;
        _clearButton.userInteractionEnabled = false;
        
        _keyboardModeButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, modeWidth, 33.0f)];
        [_keyboardModeButton addTarget:self action:@selector(keyboardModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        _keyboardModeButton.adjustsImageWhenHighlighted = false;
        _keyboardModeButton.alpha = 0.0f;
        _keyboardModeButton.userInteractionEnabled = false;
        
        _allModeButtons = @[ _stickerModeButton, _keyboardModeButton, _commandModeButton, _slashModeButton, _broadcastButton, _progressButton, _clearButton ];
        
        TGModernButton *sendButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [self baseButtonWidth], [self baseHeight])];
        _sendButton = sendButton;
        _sendButton.adjustsImageWhenHighlighted = false;
        _sendButton.contentMode = UIViewContentModeCenter;
        [_sendButton addTarget:self action:@selector(sendButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_sendButton];
        
        __weak TGModernConversationInputTextPanel *weakSelf = self;
        _attachButton = [[TGModernConversationInputAttachButton alloc] initWithFrame:CGRectMake(9, 11, 30.0f, 30.0f)];
        ((TGModernConversationInputAttachButton *)_attachButton).delegate = self;
        ((TGModernConversationInputAttachButton *)_attachButton).extendedEdgeInsets = UIEdgeInsetsMake(0, 9, 0, 9);
        [_attachButton addTarget:self action:@selector(attachButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_attachButton];
        
        _micButton = [[TGModernConversationInputMicButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [self baseButtonWidth], [self baseHeight])];
        _micButton.delegate = self;
        _micButtonIconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
        _micButtonIconView.contentMode = UIViewContentModeCenter;
        _micButton.iconView = _micButtonIconView;
        [_micButton addSubview:_micButtonIconView];
        [self addSubview:_micButton];
        
        if (!TGIsPad())
        {
            _stickersArrowButton = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [self baseButtonWidth], [self baseHeight])];
            _stickersArrowButton.adjustsImageWhenHighlighted = false;
        }
        [_stickersArrowButton addTarget:self action:@selector(toggleCustomKeyboardExpanded) forControlEvents:UIControlEventTouchUpInside];
        _stickersArrowButton.contentMode = UIViewContentModeCenter;
        
        [self addSubview:_stickersArrowButton];
        
        [self updateSendButtonVisibility];
        [self updateModeButtonVisibility];
        
        _stickerPacksDisposable = [[[[TGStickersSignals stickerPacks] startOn:[SQueue concurrentDefaultQueue]] deliverOn:[SQueue mainQueue]] startWithNext:^(__unused NSDictionary *stickerPacks)
        {
            __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                [strongSelf updateModeButtonVisibility];
            }
        }];
        
        if (iosMajorVersion() >= 10)
            _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        
        [self updateButtonIcon];
        
        if (iosMajorVersion() >= 11) //emoji keyboard height update fix
        {
            _inputTypeKeyboardUpdateDisposable = [[SMetaDisposable alloc] init];
            _inputTypeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextInputCurrentInputModeDidChangeNotification object:nil queue:nil usingBlock:^(__unused NSNotification *note)
            {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf == nil)
                    return;

                NSString *inputMethod = [[UITextInputMode currentInputMode] primaryLanguage];
                CGFloat keyboardHeight = [strongSelf currentKeyboardHeight];
                if (([inputMethod isEqualToString:@"emoji"] || [inputMethod isEqualToString:@"dictation"]) && (strongSelf->_keyboardHeight > FLT_EPSILON))
                {
                    [strongSelf->_inputTypeKeyboardUpdateDisposable setDisposable:[[[SSignal complete] delay:0.1 onQueue:[SQueue mainQueue]] startWithNext:nil completed:^
                    {
                        __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                        if (strongSelf == nil)
                            return;
                        
                        CGFloat newKeyboardHeight = [strongSelf currentKeyboardHeight];
                        if (fabs(keyboardHeight - newKeyboardHeight) > FLT_EPSILON)
                        {
                            CGSize screenSize = [[TGLegacyComponentsContext shared] fullscreenBounds].size;
                            
                            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                            userInfo[UIKeyboardAnimationDurationUserInfoKey] = @0.0;
                            userInfo[UIKeyboardFrameEndUserInfoKey] = [NSValue valueWithCGRect:CGRectMake(0.0f, screenSize.height - newKeyboardHeight, screenSize.width, newKeyboardHeight)];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillChangeFrameNotification object:nil userInfo:userInfo];
                        }
                    }]];
                }
            }];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_inputTypeObserver];
    [_stickerPacksDisposable dispose];
    
    [self stopAudioRecordingTimer];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [super setPresentation:presentation];
    
    _micButton.pallete = presentation.micButtonPallete;
    
    _fieldBackground.image = presentation.images.chatInputFieldImage;
    [_attachButton setImage:presentation.images.chatInputAttachIcon forState:UIControlStateNormal];
    [_sendButton setImage:presentation.images.chatInputSendIcon forState:UIControlStateNormal];
    _backgroundView.backgroundColor = presentation.pallete.barBackgroundColor;
    _stripeView.backgroundColor = presentation.pallete.barSeparatorColor;
    
    _recordDurationLabel.textColor = presentation.pallete.textColor;
    _slideToCancelLabel.textColor = presentation.pallete.secondaryTextColor;
    
    _micButtonIconView.image = self.isVideoMessage ? presentation.images.chatInputVideoMessageIcon : presentation.images.chatInputMicrophoneIcon;
    
    [_stickerModeButton setImage:presentation.images.chatInputStickersIcon forState:UIControlStateNormal];
    [_commandModeButton setImage:presentation.images.chatInputBotKeyboardIcon forState:UIControlStateNormal];
    [_slashModeButton setImage:presentation.images.chatInputCommandsIcon forState:UIControlStateNormal];
    [_broadcastButton setImage:_isBroadcasting ? presentation.images.chatInputBroadcastActiveIcon : presentation.images.chatInputBroadcastIcon  forState:UIControlStateNormal];
    [_keyboardModeButton setImage:presentation.images.chatInputKeyboardIcon forState:UIControlStateNormal];
    [_clearButton setImage:presentation.images.chatInputClearIcon forState:UIControlStateNormal];
    
    if ([_panelAccessoryView respondsToSelector:@selector(setPresentation:)])
        [_panelAccessoryView performSelector:@selector(setPresentation:) withObject:presentation];
    
    UIImage *arrowImage = presentation.images.chatInputArrowIcon;
    UIImage *flippedArrowImage = [UIImage imageWithCGImage:arrowImage.CGImage scale:arrowImage.scale orientation:UIImageOrientationDown];
    [_stickersArrowButton setImage:flippedArrowImage forState:UIControlStateNormal];
    [_stickersArrowButton setImage:arrowImage forState:UIControlStateSelected];
    [_stickersArrowButton setImage:arrowImage forState:UIControlStateSelected | UIControlStateHighlighted];
    
    _inputField.textColor = presentation.pallete.chatInputTextColor;
    _inputField.accentColor = presentation.pallete.accentColor;
    
    [UIView performWithoutAnimation:^
    {
        bool shouldFlip = _inputField.internalTextView.isFirstResponder;
        if (shouldFlip)
            [_inputField.internalTextView resignFirstResponder];
        _inputField.internalTextView.keyboardAppearance = presentation.pallete.prefersDarkKeyboard ? UIKeyboardAppearanceAlert : UIKeyboardAppearanceDefault;
        if (shouldFlip)
            [_inputField.internalTextView becomeFirstResponder];
    }];
    _progressButtonIndicator.color = presentation.pallete.chatInputFieldButtonColor;
    
    _customKeyboardWrapperView.backgroundColor = presentation.pallete.barBackgroundColor;
    _customKeyboardView.presentation = presentation;
    
    [self _updatePlaceholderImage];
}

- (CGFloat)currentKeyboardHeight
{
    UIWindow *kbWindow = [[[UIApplication sharedApplication] windows] lastObject];
    NSString *className = NSStringFromClass([kbWindow class]);
    if ([className rangeOfString:@"Keyboard"].location == NSNotFound)
        return _keyboardHeight;
    
    UIView *kbView = [[[[kbWindow subviews] firstObject] subviews] firstObject];
    if (kbView != nil)
        return kbView.frame.size.height;
    
    return 0.0f;
}

- (void)setVideoMessageAvailable:(bool)videoMessageAvailable
{
    _videoMessageAvailable = videoMessageAvailable;
    [self updateButtonIcon];
}

- (void)setVideoMessage:(bool)videoMessage
{
    _videoMessage = videoMessage;
    [self updateButtonIcon];
}

- (void)_updatePlaceholderImage {
    if (self.presentation == nil)
        return;
    [self _updatePlaceholderImage:false];
}

- (void)_updatePlaceholderImage:(bool)animated {
    static int localizationVersion = 0;
    static UIColor *color = nil;
    static CGFloat fontSize = 0;
    static UIImage *placeholderImage = nil;
    static UIImage *placeholderCaptionImage = nil;
    static UIImage *placeholderBroadcastImage = nil;
    static UIImage *placeholderSilentBroadcastImage = nil;
    
    UIColor *placeholderColor = self.presentation.pallete.chatInputPlaceholderColor;
    CGFloat placeholderFontSize = [self fontSize];
    
    if (placeholderImage == nil || localizationVersion != TGLocalizedStaticVersion || ![color isEqual:placeholderColor] || fontSize != placeholderFontSize)
    {
        CGFloat inputPanelWidth = TGScreenSize().width;
        if (TGIsPad())
            inputPanelWidth = 448.0f;
        
        CGFloat maxPlaceholderWidth = inputPanelWidth - [self baseButtonWidth] * 2 - [self inputFieldInternalEdgeInsets].left - 70.0f;
        {
            NSString *placeholderText = TGLocalized(@"Conversation.InputTextPlaceholder");
            UIFont *placeholderFont = TGSystemFontOfSize(placeholderFontSize);
            CGSize placeholderSize = [placeholderText sizeWithFont:placeholderFont];
            placeholderSize.width += 2.0f;
            placeholderSize.height += 2.0f;
            
            UIGraphicsBeginImageContextWithOptions(placeholderSize, false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, placeholderColor.CGColor);
            [placeholderText drawAtPoint:CGPointMake(1.0f, 1.0f) withFont:placeholderFont];
            placeholderImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        {
            NSString *placeholderText = TGLocalized(@"Conversation.InputTextCaptionPlaceholder");
            UIFont *placeholderFont = TGSystemFontOfSize(placeholderFontSize);
            CGSize placeholderSize = [placeholderText sizeWithFont:placeholderFont];
            placeholderSize.width += 2.0f;
            placeholderSize.height += 2.0f;
            
            UIGraphicsBeginImageContextWithOptions(placeholderSize, false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, placeholderColor.CGColor);
            [placeholderText drawAtPoint:CGPointMake(1.0f, 1.0f) withFont:placeholderFont];
            placeholderCaptionImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        {
            CGFloat currentFontSize = placeholderFontSize;
            NSString *placeholderBroadcastText = TGLocalized(@"Conversation.InputTextBroadcastPlaceholder");
            UIFont *placeholderFont = TGSystemFontOfSize(currentFontSize);
            CGSize placeholderSize = [placeholderBroadcastText sizeWithFont:placeholderFont];
            while (placeholderSize.width > maxPlaceholderWidth) {
                currentFontSize -= 1.0f;
                placeholderFont = TGSystemFontOfSize(currentFontSize);
                placeholderSize = [placeholderBroadcastText sizeWithFont:placeholderFont];
            }
            placeholderSize.width += 2.0f;
            placeholderSize.height += 2.0f;
            
            UIGraphicsBeginImageContextWithOptions(placeholderSize, false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, placeholderColor.CGColor);
            [placeholderBroadcastText drawAtPoint:CGPointMake(1.0f, 1.0f) withFont:placeholderFont];
            placeholderBroadcastImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        {
            CGFloat currentFontSize = placeholderFontSize;
            NSString *placeholderSilentBroadcastText = TGLocalized(@"Conversation.InputTextSilentBroadcastPlaceholder");
            UIFont *placeholderFont = TGSystemFontOfSize(currentFontSize);
            CGSize placeholderSize = [placeholderSilentBroadcastText sizeWithFont:placeholderFont];
            while (placeholderSize.width > maxPlaceholderWidth) {
                currentFontSize -= 1.0f;
                placeholderFont = TGSystemFontOfSize(currentFontSize);
                placeholderSize = [placeholderSilentBroadcastText sizeWithFont:placeholderFont];
            }
            placeholderSize.width += 2.0f;
            placeholderSize.height += 2.0f;
            
            UIGraphicsBeginImageContextWithOptions(placeholderSize, false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, placeholderColor.CGColor);
            [placeholderSilentBroadcastText drawAtPoint:CGPointMake(1.0f, 1.0f) withFont:placeholderFont];
            placeholderSilentBroadcastImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        localizationVersion = TGLocalizedStaticVersion;
        color = placeholderColor;
        fontSize = placeholderFontSize;
    }
    
    if (animated) {
        UIImageView *previousPlaceholder = [[UIImageView alloc] initWithImage:_inputFieldPlaceholder.image];
        previousPlaceholder.frame = _inputFieldPlaceholder.frame;
        previousPlaceholder.alpha = _inputFieldPlaceholder.alpha;
        previousPlaceholder.hidden = _inputFieldPlaceholder.hidden;
        [_inputFieldPlaceholder.superview insertSubview:previousPlaceholder aboveSubview:_inputFieldPlaceholder];
        [UIView animateWithDuration:0.25 animations:^{
            previousPlaceholder.alpha = 0.0f;
        } completion:^(__unused BOOL finished) {
            [previousPlaceholder removeFromSuperview];
        }];
    }
    if (_inputDisabled) {
        _inputFieldPlaceholder.image = placeholderImage;
    } else if (_messageEditingContext != nil) {
        if (_messageEditingContext.isCaption)
            _inputFieldPlaceholder.image = placeholderCaptionImage;
        else
            _inputFieldPlaceholder.image = placeholderImage;
    } else if (_canBroadcast || _isAlwaysBroadcasting) {
        _inputFieldPlaceholder.image = _isBroadcasting ? placeholderBroadcastImage : placeholderSilentBroadcastImage;
    } else if (_isChannel) {
        _inputFieldPlaceholder.image = placeholderImage;
    } else {
        _inputFieldPlaceholder.image = placeholderImage;
    }
    [_inputFieldPlaceholder sizeToFit];
    setViewFrame(_inputFieldPlaceholder, CGRectMake([self inputFieldPlaceholderOffset].x, TGScreenPixelFloor((_fieldBackground.frame.size.height - _inputFieldPlaceholder.frame.size.height) / 2.0f), _inputFieldPlaceholder.frame.size.width, _inputFieldPlaceholder.frame.size.height));
    if (animated) {
        _inputFieldPlaceholder.alpha = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            _inputFieldPlaceholder.alpha = 1.0f;
        }];
    }
}

- (CGFloat)fontSize
{
    return MAX(TGPresentation.fontSize, 17.0f);
}

- (HPGrowingTextView *)maybeInputField
{
    return _inputField;
}

- (HPGrowingTextView *)inputField
{
    if (_inputField == nil)
    {
        CGRect inputFieldClippingFrame = _fieldBackground.frame;
        inputFieldClippingFrame.size.width -= _panelAccessoryView.frame.size.width;
        _inputFieldClippingContainer = [[UIView alloc] initWithFrame:inputFieldClippingFrame];
        _inputFieldClippingContainer.clipsToBounds = true;
        [self addSubview:_inputFieldClippingContainer];
        
        UIEdgeInsets inputFieldInternalEdgeInsets = [self inputFieldInternalEdgeInsets];
        
        _inputField = [[HPGrowingTextView alloc] initWithKeyCommandController:TGAppDelegateInstance.keyCommandController];
        _inputField.frame = CGRectMake(inputFieldInternalEdgeInsets.left, inputFieldInternalEdgeInsets.top, _inputFieldClippingContainer.frame.size.width - inputFieldInternalEdgeInsets.left, _inputFieldClippingContainer.frame.size.height);
        _inputField.placeholderView = _inputFieldPlaceholder;
        _inputField.font = TGSystemFontOfSize([self fontSize]);
        _inputField.clipsToBounds = true;
        _inputField.backgroundColor = nil;
        _inputField.opaque = false;
        _inputField.internalTextView.backgroundColor = nil;
        _inputField.internalTextView.opaque = false;
        _inputField.internalTextView.contentMode = UIViewContentModeLeft;
        _inputField.textColor = self.presentation.pallete.chatInputTextColor;
        _inputField.accentColor = self.presentation.pallete.accentColor;
        _inputField.maxNumberOfLines = [self _maxNumberOfLinesForSize:_parentSize];
        _inputField.delegate = self;
        _inputField.showPlaceholderWhenFocussed = true;
        _inputField.internalTextView.keyboardAppearance = self.presentation.pallete.prefersDarkKeyboard ? UIKeyboardAppearanceAlert : UIKeyboardAppearanceDefault;
        
        if (TGAppDelegateInstance.keyCommandController == nil)
            _inputField.receiveKeyCommands = true;
        
        _inputField.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(-inputFieldInternalEdgeInsets.top + 9.0f, 0, 11 - TGRetinaPixel, 5.0);
        
        [_inputFieldClippingContainer addSubview:_inputField];
        
        [self updateInputFieldLayout];
    }
    
    return _inputField;
}

- (BOOL)growingTextViewEnabled:(HPGrowingTextView *)__unused growingTextView
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(isInputPanelTextEnabled:)])
        return [delegate isInputPanelTextEnabled:self];
    
    return true;
}

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)__unused growingTextView
{
    if (self.isCustomKeyboardExpanded)
        [self setCustomKeyboardExpanded:false animated:true];
    [self setCustomKeyboard:nil animated:false force:false];
    return true;
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)__unused growingTextView
{
    [self updateAssociatedPanelVisibility:true];
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelFocused:)])
        [delegate inputPanelFocused:self];
    
    [self updateModeButtonVisibility:true reset:false];
}

- (void)replaceMention:(NSString *)mention username:(bool)username userId:(int32_t)userId {
    [TGModernConversationInputTextPanel replaceMention:mention inputField:_inputField username:username userId:userId];
}

+ (void)replaceMention:(NSString *)mention inputField:(HPGrowingTextView *)inputField {
    [self replaceMention:mention inputField:inputField username:true userId:0];
}

+ (void)replaceMention:(NSString *)mention inputField:(HPGrowingTextView *)inputField username:(bool)username userId:(int32_t)userId
{
    [HPGrowingTextView replaceMention:mention inputField:inputField username:username userId:userId];
}

- (void)replaceHashtag:(NSString *)hashtag
{
    [TGModernConversationInputTextPanel replaceHashtag:hashtag inputField:_inputField];
}

+ (void)replaceHashtag:(NSString *)hashtag inputField:(HPGrowingTextView *)inputField
{
    [HPGrowingTextView replaceHashtag:hashtag inputField:inputField];
}

- (NSString *)_inputTextForText:(NSString *)text byAddingString:(NSString *)string
{
    NSString *newText = nil;
    if (text.length > 0 && [[text substringFromIndex:text.length - 1] hasNonWhitespaceCharacters])
        newText = [NSString stringWithFormat:@"%@ %@", text, string];
    else
        newText = [NSString stringWithFormat:@"%@%@", text, string];
    
    return newText;
}

- (void)startMention
{
    self.inputField.text = [self _inputTextForText:self.inputField.text byAddingString:@"@"];
    
    self.inputField.internalTextView.enableFirstResponder = true;
    [self.inputField becomeFirstResponder];
}

- (void)startHashtag
{
    self.inputField.text = [self _inputTextForText:self.inputField.text byAddingString:@"#"];
    
    self.inputField.internalTextView.enableFirstResponder = true;
    [self.inputField becomeFirstResponder];
}

- (void)startCommand
{
    if (self.inputField.text.length > 0 && [self.inputField.text hasNonWhitespaceCharacters])
        return;
    
    self.inputField.text = @"/";
    self.inputField.internalTextView.enableFirstResponder = true;
    [self.inputField becomeFirstResponder];
}

+ (NSString *)linkCandidateInText:(NSString *)text
{
    if (text == nil) {
        return nil;
    }
    NSString *lowercaseText = [text lowercaseString];
    if ([lowercaseText rangeOfString:@"http://"].location == NSNotFound && [lowercaseText rangeOfString:@"https://"].location == NSNotFound)
    {
        return nil;
    }
    
    static NSDataDetector *dataDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      dataDetector = [NSDataDetector dataDetectorWithTypes:(int)(NSTextCheckingTypeLink) error:NULL];
                  });
    
    __block NSString *linkCandidate = nil;
    [[dataDetector matchesInString:text options:0 range:NSMakeRange(0, text.length)] enumerateObjectsUsingBlock:^(NSTextCheckingResult *result, __unused NSUInteger idx, BOOL *stop)
     {
         NSString *lowercaseScheme = [[result URL].scheme lowercaseString];
         if ([lowercaseScheme isEqualToString:@"http"] || [lowercaseScheme isEqualToString:@"https"])
         {
             linkCandidate = [[result URL] absoluteString];
             if (stop)
                 *stop = true;
         }
     }];
    
    return linkCandidate;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView afterSetText:(bool)afterSetText afterPastingText:(bool)afterPastingText
{
    if (!afterSetText && ![growingTextView.text isEqualToString:@"@gif "]) {
        _removeGifTabTextOnDeactivation = false;
    }
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    
    NSString *text = growingTextView.text;
    int textLength = (int)text.length;
    
    bool hasNonWhitespace = [text hasNonWhitespaceCharacters];
    
    UITextRange *selRange = _inputField.internalTextView.selectedTextRange;
    UITextPosition *selStartPos = selRange.start;
    NSInteger idx = [_inputField.internalTextView offsetFromPosition:_inputField.internalTextView.beginningOfDocument toPosition:selStartPos];
    idx--;
    
    NSString *candidateMention = nil;
    bool candidateMentionStartOfLine = false;
    NSString *candidateMentionText = nil;
    NSString *candidateHashtag = nil;
    NSString *candidateCommand = nil;
    NSString *candidateAlphacode = nil;
    
    static NSCharacterSet *characterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      characterSet = [NSCharacterSet alphanumericCharacterSet];
                  });
    
    if (idx >= 0 && idx < textLength)
    {
        for (NSInteger i = idx; i >= 0; i--)
        {
            unichar c = [text characterAtIndex:i];
            unichar previousC = 0;
            if (i > 0)
                previousC = [text characterAtIndex:i - 1];
            if (c == '@' && (previousC == 0 || ![characterSet characterIsMember:previousC]))
            {
                if (i == idx) {
                    candidateMention = @"";
                    candidateMentionStartOfLine = i == 0;
                }
                else
                {
                    @try {
                        candidateMention = [text substringWithRange:NSMakeRange(i + 1, idx - i)];
                        candidateMentionStartOfLine = i == 0;
                    } @catch(NSException *e) { }
                }
                break;
            }
            
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'))
                break;
        }
    }
    
    if (candidateMention == nil)
    {
        if (textLength != 0 && idx >= 0 && idx < textLength) {
            unichar c = [text characterAtIndex:0];
            if (c == '@') {
                for (NSInteger i = 1; i <= idx; i++) {
                    c = [text characterAtIndex:i];
                    if (![characterSet characterIsMember:c] && c != '_') {
                        if (c == ' ') {
                            @try {
                                NSInteger limit = textLength;
                                for (NSInteger j = i + 1; j < textLength; j++) {
                                    unichar c = [text characterAtIndex:j];
                                    if (c == '\n') {
                                        limit = j;
                                        break;
                                    }
                                }
                                candidateMention = [text substringWithRange:NSMakeRange(1, i - 1)];
                                candidateMentionText = [text substringWithRange:NSMakeRange(i + 1, limit - i - 1)];
                            } @catch(NSException *e) {
                            }
                        }
                        
                        break;
                    }
                }
            }
        }
        
        if (candidateMention == nil || candidateMentionText == nil) {
            if (idx >= 0 && idx < textLength)
            {
                for (NSInteger i = idx; i >= 0; i--)
                {
                    unichar c = [text characterAtIndex:i];
                    if (c == '#')
                    {
                        if (i == idx)
                            candidateHashtag = @"";
                        else
                        {
                            @try {
                                candidateHashtag = [text substringWithRange:NSMakeRange(i + 1, idx - i)];
                            } @catch(NSException *e) { }
                        }
                        
                        break;
                    }
                    
                    if (c == ' ' || (![characterSet characterIsMember:c] && c != '_'))
                        break;
                }
            }
            
            if (candidateHashtag == nil)
            {
                if (idx >= 0 && idx < textLength)
                {
                    for (NSInteger i = idx; i >= 0; i--)
                    {
                        unichar c = [text characterAtIndex:i];
                        if (c == '/' && i == 0)
                        {
                            if (i == idx)
                                candidateCommand = @"";
                            else
                            {
                                @try {
                                    candidateCommand = [text substringWithRange:NSMakeRange(i + 1, idx - i)];
                                } @catch(NSException *e) { }
                            }
                            
                            break;
                        }
                        
                        if (c == ' ' || (![characterSet characterIsMember:c] && c != '_'))
                            break;
                    }
                }
            }
            
            if (candidateCommand == nil)
            {
                if (idx >= 0 && idx < textLength)
                {
                    for (NSInteger i = idx; i >= 0; i--)
                    {
                        unichar c = [text characterAtIndex:i];
                        unichar previousC = 0;
                        if (i > 0)
                            previousC = [text characterAtIndex:i - 1];
                        if (c == ':' && (previousC == 0 || ![characterSet characterIsMember:previousC]))
                        {
                            if (i == idx) {
                                candidateAlphacode = nil;
                            }
                            else
                            {
                                @try {
                                    candidateAlphacode = [text substringWithRange:NSMakeRange(i + 1, idx - i)];
                                } @catch(NSException *e) { }
                            }
                            break;
                        }
                        
                        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'))
                            break;
                    }
                }
            }
        }
    }
    
    if (candidateMention.length != 0 && [candidateMention hasSuffix:@"bot"] && candidateMentionText == nil && _contextBotMode != nil) {
        candidateMentionText = @"";
    }
    
    if (candidateMentionText == nil) {
        if ([delegate respondsToSelector:@selector(inputPanelMentionEntered:mention:startOfLine:)])
            [delegate inputPanelMentionEntered:self mention:candidateMentionText == nil ? candidateMention : nil startOfLine:candidateMentionStartOfLine];
        
        if ([delegate respondsToSelector:@selector(inputPanelMentionTextEntered:mention:text:)]) {
            [delegate inputPanelMentionTextEntered:self mention:candidateMention text:candidateMentionText];
        }
    } else {
        if ([delegate respondsToSelector:@selector(inputPanelMentionTextEntered:mention:text:)])
            [delegate inputPanelMentionTextEntered:self mention:candidateMention text:candidateMentionText];
        
        if ([delegate respondsToSelector:@selector(inputPanelMentionEntered:mention:startOfLine:)])
            [delegate inputPanelMentionEntered:self mention:candidateMentionText == nil ? candidateMention : nil startOfLine:candidateMentionStartOfLine];
    }
    
    if ([delegate respondsToSelector:@selector(inputPanelHashtagEntered:hashtag:)])
        [delegate inputPanelHashtagEntered:self hashtag:candidateHashtag];
    
    if ([delegate respondsToSelector:@selector(inputPanelCommandEntered:command:)])
        [delegate inputPanelCommandEntered:self command:candidateCommand];
    
    if ([delegate respondsToSelector:@selector(inputPanelAlphacodeEntered:alphacode:)])
        [delegate inputPanelAlphacodeEntered:self alphacode:candidateAlphacode];
    
    NSString *linkCandidate = [TGModernConversationInputTextPanel linkCandidateInText:text];
    if ([delegate respondsToSelector:@selector(inputPanelLinkParsed:link:probablyComplete:)])
        [delegate inputPanelLinkParsed:self link:linkCandidate probablyComplete:afterPastingText];
    
    bool sendButtonEnabled = hasNonWhitespace;
    if ([delegate respondsToSelector:@selector(inputPanelSendShouldBeAlwaysEnabled:)])
    {
        if ([delegate inputPanelSendShouldBeAlwaysEnabled:self])
            sendButtonEnabled = true;
    }
    
    _sendButton.enabled = sendButtonEnabled;
    
    if ([delegate respondsToSelector:@selector(inputPanelTextChanged:text:)])
        [delegate inputPanelTextChanged:self text:text];
    
    bool animated = true; //!_inputField.ignoreChangeNotification;
    [self updateSendButtonVisibility:animated];
    [self updateModeButtonVisibility:animated reset:false];
    
    if (!afterSetText)
    {
        if (hasNonWhitespace)
        {
            id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
            if ([delegate respondsToSelector:@selector(inputTextPanelHasIndicatedTypingActivity:)])
                [delegate inputTextPanelHasIndicatedTypingActivity:self];
        }
    }
    
    if (!hasNonWhitespace)
    {
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(inputTextPanelHasCancelledTypingActivity:)])
            [delegate inputTextPanelHasCancelledTypingActivity:self];
    }
    
    if (_contextPlaceholderLabel.superview != nil) {
        [self setNeedsLayout];
    }
}

- (void)updateAttachButtonVisibility
{
    bool hidden = (_messageEditingContext != nil && !_messageEditingContext.hasMedia);
    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
    {
        _attachButton.alpha = hidden ? 0.25f : 1.0f;
    } completion:^(BOOL finished) {
        if (finished)
            _attachButton.userInteractionEnabled = !hidden;
    }];
    
}

- (void)updateModeButtonVisibility
{
    [self updateModeButtonVisibility:false reset:false];
}

- (void)updateModeButtonVisibility:(bool)animated reset:(bool)reset
{
    NSMutableArray *commands = [[NSMutableArray alloc] init];
    if ([self currentlyDisplayingContextResult]) {
        if (_displayProgress) {
            [commands addObject:_progressButton];
        } else {
            [commands addObject:_clearButton];
        }
    } else {
        if (_messageEditingContext == nil) {
            if (_customKeyboardView != nil) {
                [commands addObject:_keyboardModeButton];
                
                if (_canBroadcast && !_isAlwaysBroadcasting) {
                    [commands addObject:_broadcastButton];
                }
            } else
            {
                if (reset || _inputField.text.length == 0)
                {
                    [commands addObject:_stickerModeButton];
                    if ([self currentReplyMarkup] != nil)
                        [commands addObject:_commandModeButton];
                    else if (_hasBots)
                        [commands addObject:_slashModeButton];
                    
                    if (_canBroadcast && !_isAlwaysBroadcasting)
                        [commands addObject:_broadcastButton];
                }
                
                if (_displayProgress) {
                    [commands addObject:_progressButton];
                }
            }
        }
    }
    [self setModeButtons:commands forceLayout:reset animated:animated];
}

- (void)updateSendButtonVisibility
{
    [self updateSendButtonVisibility:false];
}

- (void)updateSendButtonVisibility:(bool)animated
{
    if ([self currentlyDisplayingContextResult]) {
        _sendButton.userInteractionEnabled = false;
        _sendButton.alpha = 0.0f;
        
        _micButton.userInteractionEnabled = false;
        _micButton.alpha = 0.0f;
        
        _stickersArrowButton.userInteractionEnabled = false;
        _stickersArrowButton.alpha = 0.0f;
        return;
    }
    
    bool hidden = _inputField == nil || _inputField.text.length == 0;
    
    if (!hidden)
    {
        NSString *text = _inputField.text;
        NSUInteger length = text.length;
        bool foundNonWhitespace = false;
        for (NSUInteger i = 0; i < length; i++)
        {
            unichar c = [text characterAtIndex:i];
            if (c != ' ' && c != '\n')
            {
                foundNonWhitespace = true;
                break;
            }
        }
        
        if (!foundNonWhitespace)
            hidden = true;
    }
    
    if (_messageEditingContext != nil) {
        if (!_hasEditingButton)
        {
            _hasEditingButton = true;
            [_sendButton setImage:self.presentation.images.chatInputConfirmIcon forState:UIControlStateNormal];
        }
        
        if (_messageEditingContext.isCaption) {
            _sendButton.enabled = true;
        } else {
            _sendButton.enabled = !hidden;
        }
        hidden = false;
    } else {
        if (_hasEditingButton)
        {
            _hasEditingButton = false;
            [_sendButton setImage:self.presentation.images.chatInputSendIcon forState:UIControlStateNormal];
        }
        
        _sendButton.enabled = true;
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(inputPanelSendShouldBeAlwaysEnabled:)])
        {
            if ([delegate inputPanelSendShouldBeAlwaysEnabled:self])
                hidden = false;
        }
    }
    
    if (iosMajorVersion() < 7)
        animated = false;
    
    UIButton *appearingButton;
    NSArray<UIButton *> *disappearingButtons;
    if (!TGIsPad() && [_customKeyboardView isKindOfClass:[TGStickerKeyboardView class]] && !_stickerKeyboardView.isGif)
    {
        appearingButton = _stickersArrowButton;
        disappearingButtons = @[_micButton, _sendButton];
    }
    else
    {
        if (hidden)
        {
            appearingButton = _micButton;
            disappearingButtons = TGIsPad() ? @[_sendButton] : @[_sendButton, _stickersArrowButton];
        }
        else
        {
            appearingButton = _sendButton;
            disappearingButtons = TGIsPad() ? @[_micButton] : @[_micButton, _stickersArrowButton];
        }
    }
    
    appearingButton.userInteractionEnabled = true;
    
    for (UIButton *button in disappearingButtons)
        button.userInteractionEnabled = false;
    
    if (animated)
    {
        if (appearingButton.layer.presentationLayer != nil)
            appearingButton.layer.transform = appearingButton.layer.presentationLayer.transform;
        removeViewAnimation(appearingButton, @"transform");
        
        if (appearingButton.layer.presentationLayer != nil)
            appearingButton.layer.opacity = appearingButton.layer.presentationLayer.opacity;
        removeViewAnimation(appearingButton, @"opacity");
        
        for (UIButton *button in disappearingButtons)
        {
            if (button.layer.presentationLayer != nil)
                button.layer.transform = button.layer.presentationLayer.transform;
            removeViewAnimation(button, @"transform");
        }
        
        for (UIButton *button in disappearingButtons)
        {
            if (button.layer.presentationLayer != nil)
                button.layer.opacity = button.layer.presentationLayer.opacity;
            removeViewAnimation(button, @"opacity");
        }
        
        if ((appearingButton.transform.a < 0.3f || appearingButton.transform.a > 1.0f) || appearingButton.alpha < FLT_EPSILON)
            appearingButton.transform = CGAffineTransformMakeScale(0.3f, 0.3f);
        
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:1.5 initialSpringVelocity:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
         {
             appearingButton.transform = CGAffineTransformIdentity;
             for (UIButton *button in disappearingButtons)
             {
                 button.transform = CGAffineTransformMakeScale(0.001f, 0.001f);
             }
         } completion:nil];
        
        [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
         {
             appearingButton.alpha = 1.0f;
             
             for (UIButton *button in disappearingButtons)
             {
                 button.alpha = 0.0f;
             }
         } completion:nil];
    }
    else
    {
        removeViewAnimation(_sendButton, @"transform");
        removeViewAnimation(_sendButton, @"opacity");
        _sendButton.transform = CGAffineTransformIdentity;
        
        removeViewAnimation(_micButton, @"transform");
        removeViewAnimation(_micButton, @"opacity");
        _micButton.transform = CGAffineTransformIdentity;
        
        removeViewAnimation(_stickersArrowButton, @"transform");
        removeViewAnimation(_stickersArrowButton, @"opacity");
        _stickersArrowButton.transform = CGAffineTransformIdentity;
        
        appearingButton.alpha = 1.0f;
        
        for (UIButton *button in disappearingButtons)
        {
            button.alpha = 0.0f;
        }
    }
}

- (void)fieldBackgroundTapGesture:(UILongPressGestureRecognizer *)__unused recognizer
{
    if (self.maybeInputField.isFirstResponder && _customKeyboardView != nil)
    {
        [self keyboardModeButtonPressed];
    }
    else
    {
        [self inputField].internalTextView.enableFirstResponder = true;
        [[self inputField].internalTextView becomeFirstResponder];
    }
}

- (void)sendButtonPressed
{
    if (_inputField.internalTextView.isFirstResponder)
        [TGHacks applyCurrentKeyboardAutocorrectionVariant];
    
    NSMutableString *text = [[NSMutableString alloc] initWithString:_inputField.text == nil ? @"" : _inputField.text];
    int textLength = (int)text.length;
    for (int i = 0; i < textLength; i++)
    {
        unichar c = [text characterAtIndex:i];
        
        if (c == ' ' || c == '\t' || c == '\n')
        {
            [text deleteCharactersInRange:NSMakeRange(i, 1)];
            i--;
            textLength--;
        }
        else
            break;
    }
    
    for (int i = textLength - 1; i >= 0; i--)
    {
        unichar c = [text characterAtIndex:i];
        
        if (c == ' ' || c == '\t' || c == '\n')
        {
            [text deleteCharactersInRange:NSMakeRange(i, 1)];
            textLength--;
        }
        else
            break;
    }
    
    bool enableSend = text.length != 0;
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelSendShouldBeAlwaysEnabled:)])
    {
        if ([delegate inputPanelSendShouldBeAlwaysEnabled:self])
            enableSend = true;
    }
    
    if (_messageEditingContext != nil && _messageEditingContext.isCaption) {
        enableSend = true;
    }
    
    if (enableSend)
    {
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(inputPanelRequestedSendMessage:text:entities:media:preparedMessage:)]) {
            __autoreleasing NSArray *entities = nil;
            NSString *text = [_inputField textWithEntities:&entities];
            [delegate inputPanelRequestedSendMessage:self text:text entities:entities media:nil preparedMessage:nil];
        } else if ([delegate respondsToSelector:@selector(inputPanelRequestedSendMessage:text:)]) {
            [delegate inputPanelRequestedSendMessage:self text:[_inputField text]];
        }
    }
}

- (void)attachButtonPressed
{
    if (self.isCustomKeyboardExpanded)
        [self setCustomKeyboardExpanded:false animated:true];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSendButtonVisibility:true];
        [self updateModeButtonVisibility:true reset:false];
        
    });
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRequestedAttachmentsMenu:)])
        [delegate inputPanelRequestedAttachmentsMenu:self];
}

- (void)attachButtonInteractionBegan
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRequestedFastCamera:)])
        [delegate inputPanelRequestedFastCamera:self];
}

- (void)attachButtonInteractionUpdate:(CGPoint)location
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelPannedFastCamera:location:)])
        [delegate inputPanelPannedFastCamera:self location:location];
}

- (void)attachButtonInteractionCompleted:(CGPoint)location
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelReleasedFastCamera:location:)])
        [delegate inputPanelReleasedFastCamera:self location:location];
}

- (void)updateButtonIcon
{
    bool videoMessage = self.isVideoMessage;
    
    UIColor *overlayColor = self.presentation.pallete.chatInputSendButtonIconColor;
    _micButton.icon = videoMessage ? TGTintedImage(self.presentation.images.chatInputVideoMessageIcon, overlayColor) : TGTintedImage(self.presentation.images.chatInputMicrophoneIcon, overlayColor);
    _micButtonIconView.image = videoMessage ? self.presentation.images.chatInputVideoMessageIcon : self.presentation.images.chatInputMicrophoneIcon;
}

- (bool)isVideoMessage
{
    return _videoMessageAvailable && _videoMessage;
}

- (void)decideMicButtonAction
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    
    bool videoMessageAvailable = _videoMessageAvailable;
    if (videoMessageAvailable && !_pressingMicButton)
    {
        _videoMessage = !_videoMessage;
        
        UIView *snapshotView = [_micButtonIconView snapshotViewAfterScreenUpdates:false];
        snapshotView.frame = _micButtonIconView.frame;
        [_micButtonIconView.superview insertSubview:snapshotView aboveSubview:_micButtonIconView];
        
        [self updateButtonIcon];
        _micButtonIconView.transform = CGAffineTransformMakeScale(0.3f, 0.3f);
        _micButtonIconView.alpha = 0.0f;
        [UIView animateWithDuration:0.3 delay:0.0 options:7 << 16 animations:^
         {
             _micButtonIconView.transform = CGAffineTransformIdentity;
             snapshotView.transform = CGAffineTransformMakeScale(0.001f, 0.001f);
         } completion:^(__unused BOOL finished) {
             [snapshotView removeFromSuperview];
         }];
        
        [UIView animateWithDuration:0.2 animations:^
         {
             snapshotView.alpha = 0.0f;
             _micButtonIconView.alpha = 1.0f;
         }];
        
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(inputPanelRecordingModeChanged:video:)])
            [delegate inputPanelRecordingModeChanged:self video:self.isVideoMessage];
        
        [_feedbackGenerator prepare];
        [_feedbackGenerator impactOccurred];
    }
    else
    {
        _micButtonIconView.alpha = 1.0f;
        _recording = true;
        
        if (self.isVideoMessage)
        {
            __weak TGModernConversationInputTextPanel *weakSelf = self;
            [delegate inputPanelAudioRecordingStart:self video:true completion:^{
                TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf setShowRecordingInterface:true video:true velocity:0.0f];
                    
                    [strongSelf->_feedbackGenerator prepare];
                    [strongSelf->_feedbackGenerator impactOccurred];
                }
            }];
        }
        else
        {
            [_feedbackGenerator prepare];
            [_feedbackGenerator impactOccurred];
            
            [self setShowRecordingInterface:true video:false velocity:0.0f];
            
            __weak TGModernConversationInputTextPanel *weakSelf = self;
            [delegate inputPanelAudioRecordingStart:self video:false completion:^{
                TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    
                }
            }];
        }
    }
}

- (void)micButtonInteractionBegan
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    _inputMediaAllowed = true;
    if ([delegate respondsToSelector:@selector(inputPanelAudioRecordingEnabled:)])
    {
        if (![delegate inputPanelAudioRecordingEnabled:self]) {
            _inputMediaAllowed = false;
            return;
        }
    }
    
    if ([delegate respondsToSelector:@selector(inputPanelAudioRecordingStart:video:completion:)]) {
        if ([self videoMessageAvailable])
        {
            _pressingMicButton = true;
            _micButtonIconView.alpha = 0.4f;
            
            [_feedbackGenerator prepare];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(decideMicButtonAction) withObject:nil afterDelay:0.17];
        }
        else
        {
            __weak TGModernConversationInputTextPanel *weakSelf = self;
            [delegate inputPanelAudioRecordingStart:self video:false completion:^{
                TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    strongSelf->_recording = true;
                    [strongSelf setShowRecordingInterface:true video:false velocity:0.0f];
                }
            }];
        }
    }
}

- (void)micButtonInteractionCancelled:(CGPoint)velocity
{
    if (!_inputMediaAllowed) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _pressingMicButton = false;
    
    if (_recording) {
        _recording = false;
        [self setShowRecordingInterface:false video:self.isVideoMessage velocity:velocity.x];
    }
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelAudioRecordingCancel:)])
        [delegate inputPanelAudioRecordingCancel:self];
}

- (void)micButtonInteractionCompleted:(CGPoint)velocity
{
    if (!_inputMediaAllowed) {
        return;
    }
    
    _pressingMicButton = false;
    
    if (_recording) {
        _recording = false;
        [self setShowRecordingInterface:false video:self.isVideoMessage velocity:velocity.x];
    } else if (_ignoreNextMicButtonEvent) {
        _ignoreNextMicButtonEvent = false;
    }
    else if ([self videoMessageAvailable]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self decideMicButtonAction];
    }
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelAudioRecordingComplete:)])
        [delegate inputPanelAudioRecordingComplete:self];
}

- (void)micButtonInteractionUpdate:(CGPoint)value
{
    if (!_inputMediaAllowed) {
        return;
    }
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelAudioButtonInteractionUpdate:value:)] && self.isVideoMessage)
        [delegate inputPanelAudioButtonInteractionUpdate:self value:value];
    
    CGFloat offsetX = MAX(0.0f, value.x * 300.0f - 5.0f);
    if (value.x <= 0.2f)
        offsetX = value.x / 0.5f * offsetX;
    else
        offsetX -= 0.11f * 300.0f;
    
    
    CGFloat offsetY = MAX(0.0f, value.y * 300.0f - 5.0f);
    if (value.y <= 0.2f)
        offsetY = value.y / 0.5f * offsetY;
    else
        offsetY -= 0.11f * 300.0f;
    
    if (fabs(offsetX) > fabs(offsetY))
        offsetY = 0.0f;
    else
        offsetX = 0.0f;
    
    _slideToCancelArrow.transform = CGAffineTransformMakeTranslation(-offsetX, 0.0f);
    
    CGAffineTransform labelTransform = CGAffineTransformIdentity;
    labelTransform = CGAffineTransformTranslate(labelTransform, -offsetX, 0.0f);
    _slideToCancelLabel.transform = labelTransform;
    
    CGAffineTransform indicatorTransform = CGAffineTransformIdentity;
    CGAffineTransform durationTransform = CGAffineTransformIdentity;
    
    static CGFloat freeOffsetLimit = 35.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      CGFloat labelWidth = [TGLocalized(@"Conversation.SlideToCancel") sizeWithFont:TGSystemFontOfSize(14.0f)].width;
                      CGFloat arrowOrigin = CGFloor((TGScreenSize().width - labelWidth) / 2.0f) - 9.0f - 6.0f;
                      CGFloat timerWidth = 90.0f;
                      
                      freeOffsetLimit = MAX(0.0f, arrowOrigin - timerWidth);
                  });
    
    if (offsetX > freeOffsetLimit)
    {
        indicatorTransform = CGAffineTransformMakeTranslation(freeOffsetLimit - offsetX, 0.0f);
        durationTransform = CGAffineTransformMakeTranslation(freeOffsetLimit - offsetX, 0.0f);
    }
    
    if (!CGAffineTransformEqualToTransform(indicatorTransform, _recordIndicatorView.transform))
        _recordIndicatorView.transform = indicatorTransform;
    
    if (!CGAffineTransformEqualToTransform(durationTransform, _recordDurationLabel.transform))
        _recordDurationLabel.transform = durationTransform;
}

- (void)setLocked
{
    [_micButton _commitLocked];
    [self micButtonInteractionLocked];
}

- (void)micButtonInteractionLocked
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRecordingLocked:video:)])
        [delegate inputPanelRecordingLocked:self video:self.isVideoMessage];
    
    if (!self.isVideoMessage)
    {
        CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, 22.0f);
        transform = CGAffineTransformScale(transform, 0.25f, 0.25f);
        _cancelButton.alpha = 0.0f;
        _cancelButton.transform = transform;
        _cancelButton.userInteractionEnabled = true;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:7 << 16 animations:^
         {
             _cancelButton.transform = CGAffineTransformIdentity;
             
             CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -22.0f);
             transform = CGAffineTransformScale(transform, 0.25f, 0.25f);
             _slideToCancelLabel.transform = transform;
         } completion:^(__unused BOOL finished)
         {
             _slideToCancelLabel.transform = CGAffineTransformIdentity;
         }];
        
        [UIView animateWithDuration:0.25 animations:^
         {
             _slideToCancelArrow.alpha = 0.0f;
             _slideToCancelLabel.alpha = 0.0f;
             _cancelButton.alpha = 1.0f;
         }];
    }
}

- (void)micButtonInteractionRequestedLockedAction
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRecordingRequestedLockedAction:)])
        [delegate inputPanelRecordingRequestedLockedAction:self];
}

- (void)micButtonInteractionStopped
{
    [self recordingStopped];
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRecordingStopped:)])
        [delegate inputPanelRecordingStopped:self];
}

- (bool)micButtonShouldLock
{
    return !self.lockImmediately;// && _recording;
}

- (int)_maxNumberOfLinesForSize:(CGSize)size
{
    if (size.height <= 320.0f - FLT_EPSILON) {
        return 3;
    } else if (size.height <= 480.0f - FLT_EPSILON) {
        return 5;
    } else {
        return 15;
    }
}

- (void)adjustForSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset
{
    [self adjustForSize:size keyboardHeight:keyboardHeight duration:duration animationCurve:animationCurve contentAreaHeight:contentAreaHeight safeAreaInset:safeAreaInset dismissOffset:0.0f];
}

- (void)adjustForSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset dismissOffset:(CGFloat)dismissOffset
{
    CGSize previousSize = _parentSize;
    _parentSize = size;
    if (ABS(previousSize.width - size.width) > FLT_EPSILON) {
        [self changeToSize:size keyboardHeight:keyboardHeight duration:0.0 contentAreaHeight:contentAreaHeight safeAreaInset:safeAreaInset];
    }
    
    [self _adjustForSize:size keyboardHeight:keyboardHeight inputFieldHeight:_inputField == nil ? 36.0f : _inputField.frame.size.height duration:duration animationCurve:animationCurve contentAreaHeight:contentAreaHeight safeAreaInset:safeAreaInset dismissOffset:dismissOffset];
}

- (CGFloat)baseButtonWidth
{
     CGFloat value = 45.0f;
    if (TGIsPad())
        value += 11.0f;
    return value;
}

- (CGFloat)baseHeight
{
    CGFloat value = 45.0f;
    switch ((int)[self fontSize])
    {
        case 19:
            value = 47.0f;
            break;
            
        case 23:
            value = 52.0f;
            break;
            
        case 26:
            value = 56.0f;
            break;
            
        default:
            value = 45.0f;
            break;
    }
    if (TGIsPad())
        value += 11.0f;
    return value;
}

- (bool)shouldDisplayPanels
{
    return [TGViewController hasLargeScreen] || _messageAreaSize.width <= _messageAreaSize.height || _keyboardHeight < FLT_EPSILON;
}

- (CGFloat)extendedPanelHeight
{
    return [self shouldDisplayPanels] ? [_currentExtendedPanel preferredHeight] : 0.0f;
}

- (UIEdgeInsets)inputFieldInsets
{
    static UIEdgeInsets insets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (!TGIsPad())
            insets = UIEdgeInsetsMake(6.0f, 45.0f, 6.0f, 0.0f);
        else
            insets = UIEdgeInsetsMake(11.0f, 54.0f, 11.0f, 10.0f);
    });
    
    return insets;
}

- (UIEdgeInsets)inputFieldInternalEdgeInsets
{
    static UIEdgeInsets insets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        insets = UIEdgeInsetsMake(-2.0f, 8.0f, 0.0f, 0.0f);
    });
    
    return insets;
}

- (CGPoint)inputFieldPlaceholderOffset
{
    static CGPoint offset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (!TGIsPad())
            offset = CGPointMake(12.0f, 5.0f);
        else
            offset = CGPointMake(12.0f, 5.0f);
    });
    
    return offset;
}

- (CGFloat)heightForInputFieldHeight:(CGFloat)inputFieldHeight
{
    if (_collapsed)
        return 0.0;
    
    if (TGIsPad())
        inputFieldHeight += 1;
    
    UIEdgeInsets inputFieldInsets = [self inputFieldInsets];
    CGFloat height = MAX([self baseHeight], inputFieldHeight - 4 + inputFieldInsets.top + inputFieldInsets.bottom);
    
    return height + [self extendedPanelHeight];
}

- (void)_adjustForSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight inputFieldHeight:(CGFloat)inputFieldHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset dismissOffset:(CGFloat)dismissOffset
{
    [_inputTypeKeyboardUpdateDisposable setDisposable:nil];
    
    dispatch_block_t block = ^
    {
        CGSize messageAreaSize = size;
        
        _messageAreaSize = messageAreaSize;
        _keyboardHeight = keyboardHeight;
        _contentAreaHeight = contentAreaHeight;
        _safeAreaInset = safeAreaInset;
    
        [UIView performWithoutAnimation:^
        {
            _customKeyboardView.safeAreaInset = safeAreaInset;
        }];
        
        CGFloat inputContainerHeight = [self heightForInputFieldHeight:inputFieldHeight];
        CGFloat customKeyboardHeight = [self customKeyboardHeight];
        CGFloat safeAreaHeight = keyboardHeight + customKeyboardHeight > FLT_EPSILON ? 0.0f : safeAreaInset.bottom;
        
        CGFloat actualKeyboardHeight = customKeyboardHeight > FLT_EPSILON ? customKeyboardHeight : keyboardHeight;
        CGFloat finalDismissOffset = MAX(0.0f, MIN(dismissOffset, actualKeyboardHeight - safeAreaInset.bottom));
        
        if (safeAreaInset.bottom > FLT_EPSILON && _customKeyboardView == _stickerKeyboardView && duration < FLT_EPSILON)
        {
            if (finalDismissOffset > actualKeyboardHeight - safeAreaInset.bottom - 20.0f)
                [_stickerKeyboardView setVisible:false animated:true];
            else
                [_stickerKeyboardView setVisible:true animated:true];
        }
        
        bool dontRelayout = fabs(self.frame.size.width - messageAreaSize.width) < FLT_EPSILON && fabs(self.frame.size.height - inputContainerHeight) < FLT_EPSILON;
        
        self.frame = CGRectMake(0, messageAreaSize.height - keyboardHeight - customKeyboardHeight - inputContainerHeight - safeAreaHeight + finalDismissOffset, messageAreaSize.width, inputContainerHeight);
        
        if (!dontRelayout)
            [self layoutSubviews];
    };
    
    if (duration > DBL_EPSILON)
        [UIView animateWithDuration:duration delay:0 options:animationCurve << 16 animations:block completion:nil];
    else
        block();
}

- (void)updateInputFieldLayout {
    NSRange range = _inputField.internalTextView.selectedRange;
    
    _inputField.delegate = nil;
    
    UIEdgeInsets inputFieldInsets = [self inputFieldInsets];
    UIEdgeInsets inputFieldInternalEdgeInsets = [self inputFieldInternalEdgeInsets];
    
    CGFloat sendAreaInset = 0.0f;
    if ([self currentlyDisplayingContextResult]) {
        sendAreaInset = 6.0f;
    } else {
        sendAreaInset = _sendButtonWidth + 1.0f;
    }
    
    CGRect inputFieldClippingFrame = CGRectMake(inputFieldInsets.left, inputFieldInsets.top, _parentSize.width - inputFieldInsets.left - inputFieldInsets.right - sendAreaInset - _panelAccessoryView.frame.size.width - _safeAreaInset.left - _safeAreaInset.right, 0.0f);
    
    CGRect inputFieldFrame = CGRectMake(inputFieldInternalEdgeInsets.left, inputFieldInternalEdgeInsets.top, inputFieldClippingFrame.size.width - inputFieldInternalEdgeInsets.left, 0.0f);
    
    setViewFrame(_inputField, inputFieldFrame);
    [_inputField setMaxNumberOfLines:[self _maxNumberOfLinesForSize:_parentSize]];
    [_inputField refreshHeight:false];
    
    _inputField.internalTextView.selectedRange = range;
    
    _inputField.delegate = self;
}

- (void)setContentAreaHeight:(CGFloat)contentAreaHeight {
    _contentAreaHeight = contentAreaHeight;
    [self setNeedsLayout];
}

- (void)changeToSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset
{
    _parentSize = size;
    
    CGSize messageAreaSize = size;
    _messageAreaSize = messageAreaSize;
    _keyboardHeight = keyboardHeight;
    _contentAreaHeight = contentAreaHeight;
    _safeAreaInset = safeAreaInset;
    
    UIView *inputFieldSnapshotView = nil;
    if (duration > DBL_EPSILON)
    {
        inputFieldSnapshotView = [_inputField.internalTextView snapshotViewAfterScreenUpdates:false];
        inputFieldSnapshotView.frame = CGRectOffset(_inputField.frame, _inputFieldClippingContainer.frame.origin.x, _inputFieldClippingContainer.frame.origin.y);
        [self addSubview:inputFieldSnapshotView];
    }
    
    [UIView performWithoutAnimation:^
     {
         [self updateInputFieldLayout];
     }];
    
    CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
    CGFloat customKeyboardHeight = [self customKeyboardHeight];
    CGFloat safeAreaHeight = keyboardHeight + customKeyboardHeight > FLT_EPSILON ? 0.0f : safeAreaInset.bottom;
    
    CGRect newInputContainerFrame = CGRectMake(0, messageAreaSize.height - keyboardHeight - customKeyboardHeight - inputContainerHeight - safeAreaHeight, messageAreaSize.width, inputContainerHeight);
    
    if (duration > DBL_EPSILON)
    {
        if (inputFieldSnapshotView != nil)
            _inputField.alpha = 0.0f;
        
        [UIView animateWithDuration:duration animations:^
         {
             self.frame = newInputContainerFrame;
             [self layoutSubviews];
             
             if (inputFieldSnapshotView != nil)
             {
                 _inputField.alpha = 1.0f;
                 inputFieldSnapshotView.frame = CGRectOffset(_inputField.frame, _inputFieldClippingContainer.frame.origin.x, _inputFieldClippingContainer.frame.origin.y);
                 inputFieldSnapshotView.alpha = 0.0f;
             }
         } completion:^(__unused BOOL finished)
         {
             [inputFieldSnapshotView removeFromSuperview];
         }];
    }
    else
    {
        self.frame = newInputContainerFrame;
    }
}

- (void)growingTextView:(HPGrowingTextView *)__unused growingTextView willChangeHeight:(CGFloat)height duration:(NSTimeInterval)duration animationCurve:(int)animationCurve
{
    UIEdgeInsets inputFieldInsets = [self inputFieldInsets];
    CGFloat inputContainerHeight = MAX([self baseHeight], height - 4 + inputFieldInsets.top + inputFieldInsets.bottom) + [self extendedPanelHeight];
    CGFloat customKeyboardHeight = [self customKeyboardHeight];
    
    [self updateCustomKeyboardFrame:inputContainerHeight];
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelWillChangeHeight:height:duration:animationCurve:)])
    {
        [delegate inputPanelWillChangeHeight:self height:inputContainerHeight + customKeyboardHeight duration:duration animationCurve:animationCurve];
    }
}

- (void)updateHeight {
    [_inputField refreshHeight:false];
    [_inputField notifyHeight];
}

- (CGFloat)modeButtonOffset
{
    CGFloat value = 0.0f;
    switch ((int)[self fontSize])
    {
        case 19:
            value = 7.0f;
            break;
            
        case 23:
            value = 10.0f - TGScreenPixel;
            break;
            
        case 26:
            value = 12.0f - TGScreenPixel;
            break;
            
        default:
            value = 6.0f;
            break;
    }
    
    if (TGIsPad())
        value += 5.0f + TGScreenPixel;
    
    return value;
}

- (void)updateMainLayout:(CGFloat)globalVerticalOffset
{
    CGRect frame = self.frame;
    
    _stripeView.frame = CGRectMake(-3.0f, globalVerticalOffset -TGScreenPixel, frame.size.width + 6.0f, TGScreenPixel);
    _stripeView.alpha = fabs(globalVerticalOffset) > FLT_EPSILON ? 0.0f : 1.0f;
    _backgroundView.frame = CGRectMake(-3.0f, globalVerticalOffset, frame.size.width + 6.0f, frame.size.height + MAX(16.0f, _safeAreaInset.bottom));
    
    bool displayPanels = [self shouldDisplayPanels];
    
    if (_currentExtendedPanel != nil)
    {
        _currentExtendedPanel.frame = CGRectMake(0.0f, globalVerticalOffset + 0.0f, frame.size.width, displayPanels ? [_currentExtendedPanel preferredHeight] : 0.0f);
        _currentExtendedPanel.safeAreaInset = _safeAreaInset;
    }
    
    UIEdgeInsets inputFieldInsets = [self inputFieldInsets];
    inputFieldInsets.left += _safeAreaInset.left;
    inputFieldInsets.right += _safeAreaInset.right;
    CGFloat sendAreaInset = 0.0f;
    
    if ([self currentlyDisplayingContextResult]) {
        sendAreaInset = 6.0f;
    } else {
        sendAreaInset = _sendButtonWidth;
    }
    
    CGFloat modeButtonVerticalOffset = -[self baseHeight] + [self modeButtonOffset];
    setViewFrame(_fieldBackground, CGRectMake(inputFieldInsets.left, globalVerticalOffset + inputFieldInsets.top + [self extendedPanelHeight], frame.size.width - inputFieldInsets.left - inputFieldInsets.right - sendAreaInset, frame.size.height - inputFieldInsets.top - inputFieldInsets.bottom - [self extendedPanelHeight]));
    setViewFrame(_inputFieldPlaceholder, CGRectMake([self inputFieldPlaceholderOffset].x, TGScreenPixelFloor((_fieldBackground.frame.size.height - _inputFieldPlaceholder.frame.size.height) / 2.0f), _inputFieldPlaceholder.frame.size.width, _inputFieldPlaceholder.frame.size.height));
    if (_panelAccessoryView != nil)
    {
        setViewFrame(_panelAccessoryView, CGRectMake(CGRectGetMaxX(_fieldBackground.frame) - _panelAccessoryView.frame.size.width - TGScreenPixel, globalVerticalOffset + frame.size.height + modeButtonVerticalOffset + 1.0f, _panelAccessoryView.frame.size.width, _panelAccessoryView.frame.size.height));
    }
    
    CGFloat accessoryViewInset = 0.0f;
    if (_panelAccessoryView != nil)
        accessoryViewInset = _panelAccessoryView.frame.size.width + 7.0f;
    accessoryViewInset += 5.0f;
    CGFloat modeButtonRightEdge = CGRectGetMaxX(_fieldBackground.frame) - accessoryViewInset - 1.0f;
    CGFloat modeButtonSpacing = 3.0f;
    for (UIButton *button in _allModeButtons)
    {
        if (button.superview == nil)
            continue;
        
        CGRect buttonFrame = viewFrame(button);
        CGFloat x = button.userInteractionEnabled ? modeButtonRightEdge - buttonFrame.size.width : buttonFrame.origin.x;
        CGRect newButtonFrame = CGRectMake(x, frame.size.height + modeButtonVerticalOffset, buttonFrame.size.width, buttonFrame.size.height);
        button.center = CGPointMake(CGRectGetMidX(newButtonFrame), globalVerticalOffset + CGRectGetMidY(newButtonFrame));
        if (button.userInteractionEnabled)
            modeButtonRightEdge -= modeButtonSpacing + buttonFrame.size.width;
    }
    
    CGRect inputFieldClippingFrame = _fieldBackground.frame;
    inputFieldClippingFrame.size.width -= _panelAccessoryView.frame.size.width;
    setViewFrame(_inputFieldClippingContainer, inputFieldClippingFrame);
    
    CGRect newSendButtonFrame = CGRectMake(frame.size.width - [self baseButtonWidth] - _safeAreaInset.right, frame.size.height - [self baseHeight], [self baseButtonWidth], [self baseHeight]);
    _sendButton.center = CGPointMake(CGRectGetMidX(newSendButtonFrame), globalVerticalOffset + CGRectGetMidY(newSendButtonFrame));
    
    setViewFrame(_attachButton, CGRectMake(TGIsPad() ? 1.0f : 0.0f + _safeAreaInset.left, globalVerticalOffset + frame.size.height - [self baseHeight], [self baseButtonWidth], [self baseHeight]));
    
    CGRect newArrowButtonFrame = CGRectMake(frame.size.width - [self baseButtonWidth] - _safeAreaInset.right, frame.size.height - [self baseHeight], [self baseButtonWidth], [self baseHeight]);
    _stickersArrowButton.center = CGPointMake(CGRectGetMidX(newArrowButtonFrame), globalVerticalOffset + CGRectGetMidY(newArrowButtonFrame));
    
    CGRect newMicButtonFrame = CGRectMake(frame.size.width - [self baseButtonWidth] - _safeAreaInset.right, frame.size.height - [self baseHeight], [self baseButtonWidth], [self baseHeight]);
    _micButton.center = CGPointMake(CGRectGetMidX(newMicButtonFrame), globalVerticalOffset + CGRectGetMidY(newMicButtonFrame));
    
    CGRect micButtonFrame = viewFrame(_micButton);
    CGRect newMicButtonIconViewFrame =  CGRectMake(CGFloor((micButtonFrame.size.width - _micButtonIconView.frame.size.width) / 2.0f), CGFloor((micButtonFrame.size.height - _micButtonIconView.frame.size.height) / 2.0f) + TGScreenPixel, _micButtonIconView.frame.size.width, _micButtonIconView.frame.size.height);
    _micButtonIconView.center = CGPointMake(CGRectGetMidX(newMicButtonIconViewFrame), CGRectGetMidY(newMicButtonIconViewFrame));;
    
    if (_slideToCancelLabel != nil)
    {
        CGRect slideToCancelLabelFrame = viewFrame(_slideToCancelLabel);
        setViewFrame(_slideToCancelLabel, CGRectMake(CGFloor((self.frame.size.width - slideToCancelLabelFrame.size.width) / 2.0f), _currentExtendedPanel.frame.size.height + CGFloor((self.frame.size.height - _currentExtendedPanel.frame.size.height - slideToCancelLabelFrame.size.height) / 2.0f), slideToCancelLabelFrame.size.width, slideToCancelLabelFrame.size.height));
        
        CGRect slideToCancelArrowFrame = viewFrame(_slideToCancelArrow);
        setViewFrame(_slideToCancelArrow, CGRectMake(CGFloor((self.frame.size.width - slideToCancelLabelFrame.size.width) / 2.0f) - slideToCancelArrowFrame.size.width - 7.0f, _currentExtendedPanel.frame.size.height + CGFloor((self.frame.size.height - _currentExtendedPanel.frame.size.height - slideToCancelLabelFrame.size.height) / 2.0f), slideToCancelArrowFrame.size.width, slideToCancelArrowFrame.size.height));
    }
    
    CGRect cancelFrame = viewFrame(_cancelButton);
    setViewFrame(_cancelButton, CGRectMake(CGFloor((self.frame.size.width - cancelFrame.size.width) / 2.0f), _currentExtendedPanel.frame.size.height + CGFloor((self.frame.size.height - _currentExtendedPanel.frame.size.height - cancelFrame.size.height) / 2.0f), cancelFrame.size.width, cancelFrame.size.height));
    
    if (_contextPlaceholderLabel.superview != nil) {
        NSString *text = _inputField.internalTextView.text;
        CGFloat textWidth = CGCeil([text sizeWithFont:_inputField.internalTextView.font].width);
        
        CGFloat maxWidth = modeButtonRightEdge - _fieldBackground.frame.origin.x - textWidth;
        if (maxWidth > 24.0f) {
            CGSize labelSize = [_contextPlaceholderLabel.text sizeWithFont:_contextPlaceholderLabel.font];
            labelSize.width = CGCeil(labelSize.width);
            labelSize.height = CGCeil(labelSize.height);
            _contextPlaceholderLabel.frame = CGRectMake(textWidth + 12.0f, TGIsPad() ? 6.0f : 5.0f + TGRetinaPixel, MIN(labelSize.width, maxWidth), labelSize.height);
        } else {
            _contextPlaceholderLabel.frame = CGRectZero;
        }
    }
    
    setViewFrame(_audioRecordingContainer, self.bounds);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    
    if (_overlayDisabledView != nil) {
        _overlayDisabledView.frame = self.bounds;
    }
    
    bool displayPanels = [self shouldDisplayPanels];
    
    if (_associatedPanel != nil)
    {
        CGRect associatedPanelFrame = CGRectZero;
        if ([_associatedPanel fillsAvailableSpace]) {
            associatedPanelFrame = CGRectMake(0.0f, -_contentAreaHeight + frame.size.height, frame.size.width, _contentAreaHeight - frame.size.height);
        } else {
            associatedPanelFrame = CGRectMake(0.0f, -[_associatedPanel preferredHeight] + _currentExtendedPanel.frame.size.height, frame.size.width, displayPanels ? [_associatedPanel preferredHeight] : 0.0f);
        }
        _associatedPanel.safeAreaInset = _safeAreaInset;
        if (!CGRectEqualToRect(associatedPanelFrame, _associatedPanel.frame)) {
            _associatedPanel.frame = associatedPanelFrame;
            //[_associatedPanel layoutSubviews];
        }
    }
    
    if (_disappearingAssociatedPanel != nil) {
        CGRect associatedPanelFrame = CGRectZero;
        if ([_disappearingAssociatedPanel fillsAvailableSpace]) {
            associatedPanelFrame = CGRectMake(0.0f, -_contentAreaHeight + frame.size.height, frame.size.width, _contentAreaHeight - frame.size.height);
        } else {
            associatedPanelFrame = CGRectMake(0.0f, -[_disappearingAssociatedPanel preferredHeight] + _currentExtendedPanel.frame.size.height, frame.size.width, displayPanels ? [_disappearingAssociatedPanel preferredHeight] : 0.0f);
        }
        if (!CGRectEqualToRect(associatedPanelFrame, _disappearingAssociatedPanel.frame)) {
            _disappearingAssociatedPanel.frame = associatedPanelFrame;
            [_disappearingAssociatedPanel layoutSubviews];
        }
    }
    
    if (_inlineBotsPanel != nil) {
        _inlineBotsPanel.frame = CGRectMake(0.0f, -_inlineBotsPanel.frame.size.height + _currentExtendedPanel.frame.size.height, frame.size.width, _inlineBotsPanel.frame.size.height);
    }
    
    CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
    [self updateCustomKeyboardFrame:inputContainerHeight];
    
    if (!_customKeyboardView.isInteracting)
    {
        CGFloat customKeyboardHeight = [self customKeyboardHeight];
        CGFloat verticalOffset = _customKeyboardView.isExpanded ? (customKeyboardHeight - _contentAreaHeight + inputContainerHeight) : 0.0f;
        [self updateMainLayout:verticalOffset];
    }
}

- (void)addRecordingDotAnimation {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = @[@1.0f, @1.0f, @0.0f];
    animation.keyTimes = @[@.0, @0.4546, @0.9091, @1];
    animation.duration = 0.5;
    animation.duration = 0.5;
    animation.autoreverses = true;
    animation.repeatCount = INFINITY;
    
    [_recordIndicatorView.layer addAnimation:animation forKey:@"opacity-dot"];
}

- (void)removeDotAnimation {
    [_recordIndicatorView.layer removeAnimationForKey:@"opacity-dot"];
}

- (bool)isLocked
{
    return _micButton.locked;
}

- (void)setShowRecordingInterface:(bool)show video:(bool)video velocity:(CGFloat)velocity
{
#if TG_ENABLE_AUDIO_NOTES
    CGFloat avoidOffset = 400.0f;
    CGFloat hideOffset = 60.0f;
    
    if (show)
    {
        _micButton.blocking = !video;
        [_micButton animateIn];
        _recordingInterfaceShowTime = CFAbsoluteTimeGetCurrent();
        
        _micButtonIconView.image = TGTintedImage(self.presentation.images.chatInputVideoMessageIcon, self.presentation.pallete.chatInputSendButtonIconColor);
        
        if (_audioRecordingContainer == nil)
        {
            _audioRecordingContainer = [[UIView alloc] initWithFrame:self.bounds];
            _audioRecordingContainer.clipsToBounds = true;
            [self insertSubview:_audioRecordingContainer aboveSubview:_backgroundView];
        }
        
        if (_recordIndicatorView == nil)
            _recordIndicatorView = [[UIImageView alloc] initWithImage:TGCircleImage(9.0f, self.presentation.pallete.chatInputRecordingColor)];
        
        setViewFrame(_recordIndicatorView, CGRectMake(11.0f + _safeAreaInset.left, _currentExtendedPanel.frame.size.height + CGFloor(([self baseHeight] - 9.0f) / 2.0f) + (TGIsPad() ? 1.0f : 0.0f), 9.0f, 9.0f));
        _recordIndicatorView.alpha = 0.0f;
        _recordIndicatorView.transform = CGAffineTransformMakeTranslation(-80.0f, 0.0f);
        
        if (_recordDurationLabel == nil)
        {
            _recordDurationLabel = [[UILabel alloc] init];
            _recordDurationLabel.backgroundColor = [UIColor clearColor];
            _recordDurationLabel.textColor = self.presentation.pallete.textColor;
            _recordDurationLabel.font = TGSystemFontOfSize(15.0f);
            _recordDurationLabel.text = @"0:00,00 ";
            [_recordDurationLabel sizeToFit];
            _recordDurationLabel.alpha = 0.0f;
            _recordDurationLabel.layer.anchorPoint = CGPointMake((26.0f - _recordDurationLabel.frame.size.width) / (2 * 26.0f), 0.5f);
            _recordDurationLabel.textAlignment = NSTextAlignmentLeft;
        }
        
        setViewFrame(_recordDurationLabel, CGRectMake(26.0f + _safeAreaInset.left, _currentExtendedPanel.frame.size.height + CGFloor(([self baseHeight] - _recordDurationLabel.frame.size.height) / 2.0f), _recordDurationLabel.frame.size.width, _recordDurationLabel.frame.size.height));
        
        _recordDurationLabel.transform = CGAffineTransformMakeTranslation(-80.0f, 0.0f);
        
        if (_slideToCancelLabel == nil)
        {
            _slideToCancelLabel = [[UILabel alloc] init];
            _slideToCancelLabel.backgroundColor = [UIColor clearColor];
            _slideToCancelLabel.textColor = self.presentation.pallete.secondaryTextColor;
            _slideToCancelLabel.font = TGSystemFontOfSize(15.0f);
            _slideToCancelLabel.text = TGLocalized(@"Conversation.SlideToCancel");
            _slideToCancelLabel.clipsToBounds = false;
            [_slideToCancelLabel sizeToFit];
            setViewFrame(_slideToCancelLabel, CGRectMake(CGFloor((self.frame.size.width - _slideToCancelLabel.frame.size.width) / 2.0f), CGFloor((self.frame.size.height - _slideToCancelLabel.frame.size.height) / 2.0f), _slideToCancelLabel.frame.size.width, _slideToCancelLabel.frame.size.height));
            _slideToCancelLabel.alpha = 0.0f;
            
            _slideToCancelArrow = [[UIImageView alloc] initWithImage:TGTintedImage(TGComponentsImageNamed(@"ModernConversationAudioSlideToCancel.png"), self.presentation.pallete.secondaryTextColor)];
            CGRect slideToCancelArrowFrame = viewFrame(_slideToCancelArrow);
            setViewFrame(_slideToCancelArrow, CGRectMake(CGFloor((self.frame.size.width - _slideToCancelLabel.frame.size.width) / 2.0f) - slideToCancelArrowFrame.size.width - 7.0f, CGFloor((self.frame.size.height - _slideToCancelLabel.frame.size.height) / 2.0f), slideToCancelArrowFrame.size.width, slideToCancelArrowFrame.size.height));
            _slideToCancelArrow.alpha = 0.0f;
            [self addSubview:_slideToCancelArrow];
            
            _slideToCancelArrow.transform = CGAffineTransformMakeTranslation(avoidOffset, 0.0f);
            _slideToCancelLabel.transform = CGAffineTransformMakeTranslation(avoidOffset, 0.0f);
            
            _cancelButton = [[TGModernButton alloc] init];
            _cancelButton.tag = 4242;
            _cancelButton.titleLabel.font = TGSystemFontOfSize(17.0f);
            [_cancelButton setTitle:TGLocalized(@"Common.Cancel") forState:UIControlStateNormal];
            [_cancelButton setTitleColor:self.presentation.pallete.accentColor];
            [_cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
            [_cancelButton sizeToFit];
            [self addSubview:_cancelButton];
            
            setViewFrame(_cancelButton, CGRectMake(CGFloor((self.frame.size.width - _cancelButton.frame.size.width) / 2.0f), CGFloor((self.frame.size.height - _cancelButton.frame.size.height) / 2.0f) - 1.0f, _cancelButton.frame.size.width, _cancelButton.frame.size.height));
        }
        
        if (!_micButton.locked || self.isVideoMessage)
        {
            _cancelButton.alpha = 0.0f;
            _cancelButton.userInteractionEnabled = false;
        }
        
        _recordDurationLabel.text = @"0:00,00";
        
        _slideToCancelArrow.transform = CGAffineTransformMakeTranslation(300.0f, 0.0f);
        _slideToCancelLabel.transform = CGAffineTransformMakeTranslation(300.0f, 0.0f);
        
        [UIView animateWithDuration:0.16 delay:0.0 options:0 animations:^
         {
             _inputFieldClippingContainer.alpha = 0.0f;
             _fieldBackground.alpha = 0.0f;
             _fieldBackground.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
             _panelAccessoryView.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
             _attachButton.transform = CGAffineTransformMakeTranslation(-avoidOffset, 0.0f);
             for (UIButton *button in _allModeButtons)
             {
                 button.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
                 if (button.userInteractionEnabled)
                     button.alpha = 0.0f;
             }
             _panelAccessoryView.alpha = 0.0f;
             _inputFieldPlaceholder.alpha = 0.0f;
         } completion:^(__unused BOOL finished)
         {
             if (self.lockImmediately) {
                 self.lockImmediately = false;
                 
                 [self setLocked];
             }
         }];
        
        int animationCurveOption = iosMajorVersion() >= 7 ? (7 << 16) : 0;
        
        if (!video)
        {
            if (_recordIndicatorView.superview == nil)
                [_audioRecordingContainer addSubview:_recordIndicatorView];
            [_recordIndicatorView.layer removeAllAnimations];
            
            if (_recordDurationLabel.superview == nil)
                [_audioRecordingContainer addSubview:_recordDurationLabel];
            [_recordDurationLabel.layer removeAllAnimations];
            
            [UIView animateWithDuration:0.25 delay:0.04 options:animationCurveOption animations:^
             {
                 _recordIndicatorView.transform = CGAffineTransformIdentity;
             } completion:^(BOOL finished)
             {
                 if (finished)
                     [self addRecordingDotAnimation];
             }];
            
            [UIView animateWithDuration:0.25 delay:0.0 options:animationCurveOption animations:^
             {
                 _recordDurationLabel.alpha = 1.0f;
                 _recordDurationLabel.transform = CGAffineTransformIdentity;
             } completion:nil];
            
            if (!_micButton.locked)
            {
                if (_slideToCancelLabel.superview == nil)
                    [_audioRecordingContainer addSubview:_slideToCancelLabel];
                
                [UIView animateWithDuration:0.18 delay:0.0 options:animationCurveOption animations:^
                 {
                     _slideToCancelArrow.alpha = 1.0f;
                     _slideToCancelArrow.transform = CGAffineTransformIdentity;
                     
                     _slideToCancelLabel.alpha = 1.0f;
                     _slideToCancelLabel.transform = CGAffineTransformIdentity;
                 } completion:nil];
            }
        }
    }
    else
    {
        [_micButton animateOut];
        [self removeDotAnimation];
        NSTimeInterval durationFactor = MIN(0.4, MAX(1.0, velocity / 1000.0));
        
        _micButtonIconView.image = self.isVideoMessage ? self.presentation.images.chatInputVideoMessageIcon : self.presentation.images.chatInputMicrophoneIcon;
        
        int options = 0;
        
        if (ABS(CFAbsoluteTimeGetCurrent() - _recordingInterfaceShowTime) < 0.2)
        {
            options = UIViewAnimationOptionBeginFromCurrentState;
        }
        else
        {
            _attachButton.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
            _fieldBackground.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
            
            for (UIButton *button in _allModeButtons)
            {
                button.transform = CGAffineTransformMakeTranslation(0.0f, hideOffset);
            }
        }
        
        [UIView animateWithDuration:0.22 delay:0.0 options:options animations:^
         {
             _inputFieldClippingContainer.alpha = 1.0f;
             _fieldBackground.alpha = 1.0f;
             _fieldBackground.transform = CGAffineTransformIdentity;
             _inputFieldPlaceholder.alpha = 1.0f;
             _panelAccessoryView.alpha = 1.0f;
             _panelAccessoryView.transform = CGAffineTransformIdentity;
             _attachButton.transform = CGAffineTransformIdentity;
             for (UIButton *button in _allModeButtons)
             {
                 button.transform = CGAffineTransformIdentity;
                 if (button.userInteractionEnabled)
                     button.alpha = 1.0f;
             }
         } completion:nil];
        
        int animationCurveOption = iosMajorVersion() >= 7 ? (7 << 16) : 0;
        [UIView animateWithDuration:0.25 * durationFactor delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurveOption animations:^
         {
             _recordIndicatorView.transform = CGAffineTransformMakeTranslation(-90.0f, 0.0f);
         } completion:^(BOOL finished)
         {
             if (finished)
                 [_recordIndicatorView removeFromSuperview];
         }];
        
        [UIView animateWithDuration:0.25 * durationFactor delay:0.05 * durationFactor options:UIViewAnimationOptionBeginFromCurrentState | animationCurveOption animations:^
         {
             _recordDurationLabel.alpha = 0.0f;
             _recordDurationLabel.transform = CGAffineTransformMakeTranslation(-90.0f, 0.0f);
         } completion:^(BOOL finished)
         {
             if (finished)
                 [_recordDurationLabel removeFromSuperview];
         }];
        
        [UIView animateWithDuration:0.2 * durationFactor delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurveOption animations:^
         {
             _slideToCancelArrow.alpha = 0.0f;
             _slideToCancelArrow.transform = CGAffineTransformMakeTranslation(-avoidOffset, 0.0f);
             
             _slideToCancelLabel.alpha = 0.0f;
             _slideToCancelLabel.transform = CGAffineTransformMakeTranslation(-avoidOffset, 0.0f);
             
             CGAffineTransform transform = CGAffineTransformMakeTranslation(0.0f, -22.0f);
             transform = CGAffineTransformScale(transform, 0.25f, 0.25f);
             _cancelButton.transform = transform;
             _cancelButton.alpha = 0.0f;
         } completion:nil];
    }
#endif
}

- (void)cancelPressed
{
    _pressingMicButton = false;
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self micButtonInteractionCancelled:CGPointZero];
                   });
}

- (void)startAudioRecordingTimer
{
    _recordDurationLabel.text = @"0:00,00";
    
    _audioRecordingDurationSeconds = 0;
    _audioRecordingDurationMilliseconds = 0.0;
    _audioRecordingTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(audioTimerEvent) interval:2.0 / 60.0 repeat:false];
}

- (void)audioTimerEvent
{
    if (_audioRecordingTimer != nil)
    {
        [_audioRecordingTimer invalidate];
        _audioRecordingTimer = nil;
    }
    
    NSTimeInterval recordingDuration = 0.0;
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelAudioRecordingDuration:)])
        recordingDuration = [delegate inputPanelAudioRecordingDuration:self];
    
    CFAbsoluteTime currentTime = MTAbsoluteSystemTime();
    NSUInteger currentAudioDurationSeconds = (NSUInteger)recordingDuration;
    NSUInteger currentAudioDurationMilliseconds = (int)(recordingDuration * 100.0f) % 100;
    if (currentAudioDurationSeconds == _audioRecordingDurationSeconds && currentAudioDurationMilliseconds == _audioRecordingDurationMilliseconds)
    {
        _audioRecordingTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(audioTimerEvent) interval:MAX(0.01, _audioRecordingDurationSeconds + 2.0 / 60.0 - currentTime) repeat:false];
    }
    else
    {
        _audioRecordingDurationSeconds = currentAudioDurationSeconds;
        _audioRecordingDurationMilliseconds = currentAudioDurationMilliseconds;
        _recordDurationLabel.text = [[NSString alloc] initWithFormat:@"%d:%02d,%02d", (int)_audioRecordingDurationSeconds / 60, (int)_audioRecordingDurationSeconds % 60, (int)_audioRecordingDurationMilliseconds];
        _audioRecordingTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(audioTimerEvent) interval:2.0 / 60.0 repeat:false];
    }
}

- (void)stopAudioRecordingTimer
{
    if (_audioRecordingTimer != nil)
    {
        [_audioRecordingTimer invalidate];
        _audioRecordingTimer = nil;
    }
}

- (void)audioRecordingStarted
{
    [self startAudioRecordingTimer];
}

- (void)audioRecordingFinished
{
    [self stopAudioRecordingTimer];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [_micButton updateOverlay];
}

- (void)recordingFinished
{
    _recording = false;
    _ignoreNextMicButtonEvent = true;
    [self setShowRecordingInterface:false video:true velocity:0.0f];
    
    _micButton.hidden = false;
}

- (void)recordingStopped
{
    _recording = false;
    [_micButton animateOut];
    _micButtonIconView.image = self.isVideoMessage ? [TGPresentationAssets inputPanelVideoMessageIcon:false] : [TGPresentationAssets inputPanelMicrophoneIcon:false];
    
    if ([self isVideoMessage])
        _micButton.hidden = true;
}

- (void)shakeControls
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < 8; i++)
    {
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(i % 2 == 0 ? -3.0f : 3.0f, 0.0f, 0.0f)]];
    }
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0.0f, 0.0f, 0.0f)]];
    animation.values = values;
    NSMutableArray *keyTimes = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < animation.values.count; i++)
        [keyTimes addObject:@((NSTimeInterval)i / (animation.values.count - 1.0))];
    animation.keyTimes = keyTimes;
    animation.duration = 0.5;
    [self.layer addAnimation:animation forKey:@"transform"];
    _micButton.userInteractionEnabled = false;
    TGDispatchAfter(0.5, dispatch_get_main_queue(), ^
    {
        _micButton.userInteractionEnabled = true;
    });
}

- (CGRect)attachmentButtonFrame
{
    return _attachButton.frame;
}

- (CGRect)micButtonFrame {
    return _micButton.frame;
}

- (CGRect)stickerButtonFrame {
    if (_stickerModeButton.superview != nil) {
        return _stickerModeButton.frame;
    } else {
        return CGRectZero;
    }
}

- (UIView *)stickerButton {
    if (_stickerModeButton.superview != nil) {
        return _stickerModeButton;
    }
    return nil;
}

- (CGRect)broadcastModeButtonFrame {
    if (_broadcastButton.superview != nil) {
        return _broadcastButton.frame;
    } else {
        return CGRectZero;
    }
}

- (UIView *)keyboardSnapshotView
{
    if (_keyboardSnapshotView != nil)
        return _keyboardSnapshotView;
    
    if (![self.maybeInputField.internalTextView isFirstResponder])
        return nil;
    
    _keyboardSnapshotView = [[TGHacks applicationKeyboardView] snapshotViewAfterScreenUpdates:false];;
    return _keyboardSnapshotView;
}

- (bool)willRestoreFocus
{
    return _willRestoreFocus;
}

- (void)prepareForResultPreviewAppearance:(bool)keepAssociatedPanel
{
    _customKeyboardVersion++;
    
    _keepAssociatedPanelVisible = keepAssociatedPanel;
    if ([self.maybeInputField.internalTextView isFirstResponder])
    {
        [self customKeyboardWrapperView].hidden = false;
        CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];

        _customKeyboardWrapperView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _customKeyboardWrapperView.frame = CGRectMake(0.0f, inputContainerHeight - 6.0f, self.bounds.size.width, _keyboardHeight + 6.0f);
        _customKeyboardHeight = _keyboardHeight;
        _keyboardSnapshotView = [self keyboardSnapshotView];
        
        _keyboardSnapshotView.frame = CGRectMake(self.frame.size.width - _keyboardSnapshotView.frame.size.width - (TGIsPad() ? 1.0f : 0.0), 6.0f, _keyboardSnapshotView.frame.size.width, _keyboardSnapshotView.frame.size.height);
        [_customKeyboardWrapperView addSubview:_keyboardSnapshotView];
        
        [UIView performWithoutAnimation:^
        {
            [self.maybeInputField.internalTextView resignFirstResponder];
        }];
    }
}

- (void)prepareForResultPreviewDismissal:(bool)restoreFocus
{
    if (_customKeyboardHeight < FLT_EPSILON)
        return;
    
    _keepAssociatedPanelVisible = false;
    _customKeyboardVersion++;
    
    NSInteger version = _customKeyboardVersion;
    TGDispatchAfter(0.45, dispatch_get_main_queue(), ^
    {
        if (version == _customKeyboardVersion)
        {
            [_keyboardSnapshotView removeFromSuperview];
            _keyboardSnapshotView = nil;
            [self customKeyboardWrapperView].hidden = true;
        }
    });
    _customKeyboardHeight = 0.0f;
    
    if (restoreFocus)
    {
        _willRestoreFocus = true;
        TGDispatchAfter(0.2, dispatch_get_main_queue(), ^
        {
            [UIView performWithoutAnimation:^
            {
                [self.maybeInputField.internalTextView becomeFirstResponder];
                _willRestoreFocus = false;
            }];
        });
    }
    else
    {
        CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
        CGFloat customKeyboardHeight = [self customKeyboardHeight];
        
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        NSTimeInterval duration = 0.2;
        UIViewAnimationCurve curve = 7;
        
        [delegate inputPanelWillChangeHeight:self height:inputContainerHeight + customKeyboardHeight duration:duration animationCurve:curve];
    }
}

- (TGModernConversationAssociatedInputPanel *)associatedPanel
{
    return _associatedPanel;
}

- (void)setAssociatedPanel:(TGModernConversationAssociatedInputPanel *)associatedPanel animated:(bool)animated
{
    if (_associatedPanel != associatedPanel)
    {
        bool wasDisplayingContextResult = [self currentlyDisplayingContextResult];
        
        __weak TGModernConversationInputTextPanel *weakSelf = self;
        TGModernConversationAssociatedInputPanel *currentPanel = _associatedPanel;
        if (currentPanel != nil)
        {
            if (animated)
            {
                _disappearingAssociatedPanel = currentPanel;
                [currentPanel animateOut:^{
                    __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                    if (strongSelf->_disappearingAssociatedPanel == currentPanel) {
                        strongSelf->_disappearingAssociatedPanel = nil;
                    }
                    [currentPanel removeFromSuperview];
                }];
            }
            else
                [currentPanel removeFromSuperview];
        }
        
        _associatedPanel = associatedPanel;
        _associatedPanel.pallete = self.presentation.associatedInputPanelPallete;
        _associatedPanel.safeAreaInset = _safeAreaInset;
        _associatedPanel.resultPreviewAppeared = ^{
            __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
            if (strongSelf != nil) {
                if (!TGIsPad() || [_associatedPanel isKindOfClass:[TGStickerAssociatedInputPanel class]])
                    [strongSelf prepareForResultPreviewAppearance:true];
            }
        };
        _associatedPanel.resultPreviewDisappeared = ^(bool restoreFocus) {
            __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf prepareForResultPreviewDismissal:restoreFocus];
            }
        };
        if (_associatedPanel != nil)
        {
            [self updateAssociatedPanelInset:false];
            
            if ([_associatedPanel fillsAvailableSpace]) {
                _associatedPanel.frame = CGRectMake(0.0f, -_contentAreaHeight + self.frame.size.height, self.frame.size.width, _contentAreaHeight - self.frame.size.height);
            } else {
                __weak TGModernConversationInputTextPanel *weakSelf = self;
                _associatedPanel.preferredHeightUpdated = ^
                {
                    __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        strongSelf->_associatedPanel.frame = CGRectMake(0.0f, -[strongSelf->_associatedPanel preferredHeight] + strongSelf->_currentExtendedPanel.frame.size.height, strongSelf.frame.size.width, [strongSelf shouldDisplayPanels] ? [strongSelf->_associatedPanel preferredHeight] : 0.0f);
                    }
                };
                _associatedPanel.frame = CGRectMake(0.0f, -[_associatedPanel preferredHeight] + _currentExtendedPanel.frame.size.height, self.frame.size.width, [self shouldDisplayPanels] ? [_associatedPanel preferredHeight] : 0.0f);
            }
            if (_inlineBotsPanel != nil) {
                [self insertSubview:_associatedPanel belowSubview:_inlineBotsPanel];
            } else {
                [self addSubview:_associatedPanel];
            }
            _associatedPanel.alpha = 0.0f;
            [self updateAssociatedPanelVisibility:false];
        }
        
        if ([self currentlyDisplayingContextResult] != wasDisplayingContextResult) {
            [UIView performWithoutAnimation:^{
                [self updateInputFieldLayout];
                [self updateSendButtonVisibility];
                [self updateModeButtonVisibility];
                [self layoutSubviews];
            }];
            [self updateHeight];
        }
        
        [self updateInlineBotPanelOffset];
    }
}

- (void)updateInlineBotPanelOffset {
    if (_associatedPanel == nil) {
        [_inlineBotsPanel setBarOffset:0.0f];
    } else {
        [_inlineBotsPanel setBarOffset:_associatedPanel.overlayBarOffset];
        __weak TGModernConversationInputTextPanel *weakSelf = self;
        __weak TGModernConversationAssociatedInputPanel *panel = _associatedPanel;
        _associatedPanel.updateOverlayBarOffset = ^(CGFloat offset) {
            __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf->_associatedPanel == panel) {
                [strongSelf->_inlineBotsPanel setBarOffset:offset];
            }
        };
    }
}

- (void)updateAssociatedPanelInset:(bool)animated {
    [_associatedPanel setBarInset:_inlineBotsPanel.frame.size.height animated:animated];
}

- (void)updateAssociatedPanelVisibility:(bool)animated {
    CGFloat targetAlpha = 1.0f;
    if ([_associatedPanel displayForTextEntryOnly]) {
        if (!_keepAssociatedPanelVisible && (![_inputField.internalTextView isFirstResponder] || _customKeyboardView != nil)) {
            targetAlpha = 0.0f;
        }
    }
    _associatedPanelVisible = targetAlpha > FLT_EPSILON;
    if (ABS(_associatedPanel.alpha - targetAlpha) > FLT_EPSILON) {
        if (animated) {
            _associatedPanel.alpha = 0.0f;
            [UIView animateWithDuration:0.18 animations:^ {
                _associatedPanel.alpha = targetAlpha;
            }];
        } else {
            _associatedPanel.alpha = targetAlpha;
        }
    }
}

- (bool)associatedPanelVisible
{
    return _associatedPanelVisible;
}

- (TGBotReplyMarkup *)currentReplyMarkup
{
    if ([_firstExtendedPanel isKindOfClass:[TGModenConcersationReplyAssociatedPanel class]])
    {
        TGMessage *message = ((TGModenConcersationReplyAssociatedPanel *)_firstExtendedPanel).message;
        if (message.replyMarkup != nil && !message.replyMarkup.isInline) {
            return message.replyMarkup;
        }
    }
    return _replyMarkup;
}

- (bool)currentlyDisplayingContextResult {
    if (_contextBotMode) {
        return true;
    }
    
    return _associatedPanel != nil && ([_associatedPanel isKindOfClass:[TGModernConversationMediaContextResultsAssociatedPanel class]] || [_associatedPanel isKindOfClass:[TGModernConversationGenericContextResultsAssociatedPanel class]]);
}

- (bool)shouldDisableAutocorrection
{
    if ([_firstExtendedPanel isKindOfClass:[TGModernConversationCommandsAssociatedPanel class]])
        return true;
    return false;
}

- (void)setPrimaryExtendedPanel:(TGModernConversationAssociatedInputPanel *)extendedPanel animated:(bool)animated
{
    [self setPrimaryExtendedPanel:extendedPanel animated:animated skipHeightAnimation:false];
}

- (void)setPrimaryExtendedPanel:(TGModernConversationAssociatedInputPanel *)extendedPanel animated:(bool)animated skipHeightAnimation:(bool)skipHeightAnimation
{
    TGBotReplyMarkup *previousReplyMarkup = [self currentReplyMarkup];
    
    _firstExtendedPanel = extendedPanel;
    if (_secondExtendedPanel == nil)
    {
        [self _setCurrentExtendedPanel:extendedPanel animated:animated skipHeightAnimation:skipHeightAnimation];
    }
    
    if (!TGObjectCompare(previousReplyMarkup, [self currentReplyMarkup]))
        [self setCurrentReplyMarkup:[self currentReplyMarkup]];
}

- (void)setSecondaryExtendedPanel:(TGModernConversationAssociatedInputPanel *)extendedPanel animated:(bool)animated
{
    [self setSecondaryExtendedPanel:extendedPanel animated:animated skipHeightAnimation:false];
}

- (void)setSecondaryExtendedPanel:(TGModernConversationAssociatedInputPanel *)extendedPanel animated:(bool)animated skipHeightAnimation:(bool)skipHeightAnimation
{
    _secondExtendedPanel = extendedPanel;
    if (_secondExtendedPanel == nil)
    {
        if (_firstExtendedPanel != nil)
        {
            [self _setCurrentExtendedPanel:_firstExtendedPanel animated:animated skipHeightAnimation:skipHeightAnimation];
        }
        else
        {
            [self _setCurrentExtendedPanel:nil animated:animated skipHeightAnimation:skipHeightAnimation];
        }
    }
    else
        [self _setCurrentExtendedPanel:extendedPanel animated:animated skipHeightAnimation:skipHeightAnimation];
}

- (void)_setCurrentExtendedPanel:(TGModernConversationAssociatedInputPanel *)currentExtendedPanel animated:(bool)animated skipHeightAnimation:(bool)skipHeightAnimation
{
    if (_currentExtendedPanel != currentExtendedPanel)
    {
        bool displayPanels = [self shouldDisplayPanels];
        
        if (animated)
        {
            UIView *previousExtendedPanel = _currentExtendedPanel;
            _currentExtendedPanel = currentExtendedPanel;
            
            if (_currentExtendedPanel != nil)
            {
                [_currentExtendedPanel setSendAreaWidth:_sendButtonWidth attachmentAreaWidth:[self inputFieldInsets].left];
                _currentExtendedPanel.pallete = self.presentation.associatedInputPanelPallete;
                _currentExtendedPanel.safeAreaInset = _safeAreaInset;
                _currentExtendedPanel.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, displayPanels ? [_currentExtendedPanel preferredHeight] : 0.0f);
                
                if (previousExtendedPanel != nil)
                    [self insertSubview:_currentExtendedPanel aboveSubview:previousExtendedPanel];
                else {
                    if (_inlineBotsPanel != nil) {
                        [self insertSubview:_currentExtendedPanel belowSubview:_inlineBotsPanel];
                    } else {
                        [self insertSubview:_currentExtendedPanel aboveSubview:_backgroundView];
                    }
                }
            }
            
            _currentExtendedPanel.alpha = 0.0f;
            [UIView animateWithDuration:0.2 delay:0 options:0 animations:^
             {
                 previousExtendedPanel.alpha = 0.0f;
                 _currentExtendedPanel.alpha = 1.0f;
             } completion:^(__unused BOOL finished)
             {
                 [previousExtendedPanel removeFromSuperview];
             }];
            
            if (!skipHeightAnimation)
            {
                CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
                CGFloat customKeyboardHeight = [self customKeyboardHeight];
                
                id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
                if ([delegate respondsToSelector:@selector(inputPanelWillChangeHeight:height:duration:animationCurve:)])
                {
                    [delegate inputPanelWillChangeHeight:self height:inputContainerHeight + customKeyboardHeight duration:0.2 animationCurve:0];
                }
            }
        }
        else
        {
            UIView *previousPrimaryExtendedPanel = _currentExtendedPanel;
            _currentExtendedPanel = currentExtendedPanel;
            
            if (_currentExtendedPanel != nil)
            {
                [_currentExtendedPanel setSendAreaWidth:_sendButtonWidth attachmentAreaWidth:[self inputFieldInsets].left];
                _currentExtendedPanel.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, displayPanels ? [_currentExtendedPanel preferredHeight] : 0.0f);
                _currentExtendedPanel.pallete = self.presentation.associatedInputPanelPallete;
                _currentExtendedPanel.safeAreaInset = _safeAreaInset;
                if (previousPrimaryExtendedPanel != nil)
                    [self insertSubview:_currentExtendedPanel aboveSubview:previousPrimaryExtendedPanel];
                else
                    [self insertSubview:_currentExtendedPanel aboveSubview:_backgroundView];
            }
            
            [previousPrimaryExtendedPanel removeFromSuperview];
            
            if (!skipHeightAnimation)
            {
                CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
                CGFloat customKeyboardHeight = [self customKeyboardHeight];
                
                id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
                if ([delegate respondsToSelector:@selector(inputPanelWillChangeHeight:height:duration:animationCurve:)])
                {
                    [delegate inputPanelWillChangeHeight:self height:inputContainerHeight + customKeyboardHeight duration:0.0 animationCurve:0];
                }
            }
        }
    }
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    bool sendButtonEnabled = [_inputField.internalTextView.text hasNonWhitespaceCharacters];
    if ([delegate respondsToSelector:@selector(inputPanelSendShouldBeAlwaysEnabled:)])
    {
        if ([delegate inputPanelSendShouldBeAlwaysEnabled:self])
            sendButtonEnabled = true;
    }
    
    _sendButton.enabled = sendButtonEnabled;
    
    [self updateSendButtonVisibility:animated];
}

- (TGModernConversationAssociatedInputPanel *)primaryExtendedPanel
{
    return _firstExtendedPanel;
}

- (TGModernConversationAssociatedInputPanel *)secondaryExtendedPanel
{
    return _secondExtendedPanel;
}

- (void)setAssociatedStickerList:(NSDictionary *)dictionary stickerSelected:(void (^)(TGDocumentMediaAttachment *))stickerSelected
{
    NSArray *documents = dictionary[@"documents"];
    if (documents.count != 0)
    {
        if ([_associatedPanel isKindOfClass:[TGStickerAssociatedInputPanel class]])
            [((TGStickerAssociatedInputPanel *)_associatedPanel) setDocumentList:dictionary];
        else
        {
            TGStickerAssociatedInputPanel *stickerPanel = [[TGStickerAssociatedInputPanel alloc] init];
            id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
            stickerPanel.controller = [delegate inputPanelParentViewController:self];
            stickerPanel.documentSelected = stickerSelected;
            [stickerPanel setDocumentList:dictionary];
            [stickerPanel setTargetOffset:136.0f];
            [self setAssociatedPanel:stickerPanel animated:true];
        }
    }
    else
    {
        [self setAssociatedPanel:nil animated:true];
    }
}

- (void)growingTextView:(HPGrowingTextView *)__unused growingTextView didPasteImages:(NSArray *)images andText:(NSString *)text
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRequestedSendImages:images:)])
        [delegate inputPanelRequestedSendImages:self images:images];
    if (text.length != 0) {
        if ([delegate respondsToSelector:@selector(inputPanelRequestedSendMessage:text:)]) {
            [delegate inputPanelRequestedSendMessage:self text:text];
        }
    }
}

- (void)growingTextView:(HPGrowingTextView *)__unused growingTextView didPasteData:(NSData *)data
{
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRequestedSendData:data:)])
        [delegate inputPanelRequestedSendData:self data:data];
}

- (void)growingTextView:(HPGrowingTextView *)__unused growingTextView receivedReturnKeyCommandWithModifierFlags:(UIKeyModifierFlags)flags
{
    if (flags & UIKeyModifierAlternate)
        [self addNewLine];
    else
        [self sendButtonPressed];
}

- (void)addNewLine
{
    self.inputField.text = [NSString stringWithFormat:@"%@\n", self.inputField.text];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)__unused event
{
    CGRect extendedRect = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height + _safeAreaInset.bottom);
    return CGRectContainsPoint(extendedRect, point);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_inputDisabled) {
        return nil;
    }
    
    if (_customKeyboardView.isInteracting)
        return _stripeView;
    
    for (UIButton *button in _modeButtons)
    {
        if (!button.hidden && CGRectContainsPoint(button.frame, point))
        {
            if (self.isCustomKeyboardExpanded)
            {
                if (button == _keyboardModeButton)
                    return button;
            }
            else
            {
                return button;
            }
        }
    }
    
    if (_inlineBotsPanel != nil && !_customKeyboardView.isExpanded) {
        UIView *result = [_inlineBotsPanel hitTest:[self convertPoint:point toView:_inlineBotsPanel] withEvent:event];
        if (result != nil)
            return result;
    }
    
    if (_associatedPanel != nil && !_customKeyboardView.isExpanded)
    {
        UIView *result = [_associatedPanel hitTest:[self convertPoint:point toView:_associatedPanel] withEvent:event];
        if (result != nil)
            return result;
    }
    
    if (_currentExtendedPanel != nil && !_customKeyboardView.isExpanded)
    {
        UIView *result = [_currentExtendedPanel hitTest:[self convertPoint:point toView:_currentExtendedPanel] withEvent:event];
        if (result != nil)
            return result;
    }
    
    if (_customKeyboardView != nil)
    {
        UIView *result = [_customKeyboardWrapperView hitTest:[self convertPoint:point toView:_customKeyboardWrapperView] withEvent:event];
        if (result != nil)
            return result;
    }
    
    if (_customKeyboardView.isExpanded)
    {
        UIView *result = [_stickersArrowButton hitTest:[self convertPoint:point toView:_stickersArrowButton] withEvent:event];
        if (result != nil)
            return result;
        
        result = [_attachButton hitTest:[self convertPoint:point toView:_attachButton] withEvent:event];
        if (result != nil)
            return result;
        
        if (_inputField != nil)
        {
            result = [_inputField hitTest:[self convertPoint:point toView:_inputField] withEvent:event];
            if (result != nil)
                return result;
        }
    }
    
    if (_panelAccessoryView != nil)
    {
        UIView *result = [_panelAccessoryView hitTest:[self convertPoint:point toView:_panelAccessoryView] withEvent:event];
        if (result != nil)
            return result;
    }
    
    if (CGRectContainsPoint(_fieldBackground.frame, point) && _customKeyboardView != nil)
    {
        return _fieldBackground;
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)setModeButtons:(NSArray *)modeButtons
{
    [self setModeButtons:modeButtons forceLayout:false animated:false];
}

- (void)setModeButtons:(NSArray *)modeButtons forceLayout:(bool)forceLayout animated:(bool)animated
{
    if ([_modeButtons isEqualToArray:modeButtons])
        return;
    
    if (iosMajorVersion() < 7)
        animated = false;
    
    if (animated)
    {
        for (UIButton *button in _modeButtons)
        {
            if ([modeButtons containsObject:button])
                continue;
            
            button.userInteractionEnabled = false;
            
            if (button.layer.presentationLayer != nil)
                button.layer.transform = button.layer.presentationLayer.transform;
            removeViewAnimation(button, @"transform");
            
            if (button.layer.presentationLayer != nil)
                button.layer.opacity = button.layer.presentationLayer.opacity;
            removeViewAnimation(button, @"opacity");
            
            [UIView animateWithDuration:0.2 animations:^
             {
                 button.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(button.transform.tx, 0.0f), 0.001f, 0.001f);
             } completion:nil];
            
            [UIView animateWithDuration:0.15 animations:^
             {
                 button.alpha = 0.0f;
             }];
        }
    }
    else
    {
        for (UIButton *button in _modeButtons)
        {
            removeViewAnimation(button, @"transform");
            removeViewAnimation(button, @"opacity");
            
            button.alpha = 0.0f;
            button.userInteractionEnabled = false;
            button.transform = CGAffineTransformMakeTranslation(button.transform.tx, 0.0f);
        }
    }
    
    _modeButtons = modeButtons;
    
    CGFloat inset = 4.0f;
    for (UIButton *button in _modeButtons)
    {
        if (button.superview == nil)
        {
            if (_overlayDisabledView.superview != nil)
            {
                [self insertSubview:button belowSubview:_overlayDisabledView];
            }
            else
            {
                if (_customKeyboardWrapperView != nil)
                    [self insertSubview:button belowSubview:_customKeyboardWrapperView];
                else
                    [self addSubview:button];
            }
        }
        
        button.userInteractionEnabled = true;
        
        if (animated)
        {
            if (button.layer.presentationLayer != nil)
                button.layer.transform = button.layer.presentationLayer.transform;
            removeViewAnimation(button, @"transform");
            
            if (button.layer.presentationLayer != nil)
                button.layer.opacity = button.layer.presentationLayer.opacity;
            removeViewAnimation(button, @"opacity");
            
            if ((button.transform.a < 0.3f || button.transform.a > 1.0f) || button.alpha < FLT_EPSILON)
            {
                button.alpha = 0.0f;
                button.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(button.transform.tx, 0.0f), 0.3f, 0.3f);
            }
            
            [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:1.5 initialSpringVelocity:0.0 options:kNilOptions animations:^
             {
                 button.transform = CGAffineTransformMakeTranslation(button.transform.tx, 0.0f);
             } completion:nil];
            
            [UIView animateWithDuration:0.15 delay:0.0 options:kNilOptions animations:^
             {
                 if ([button isKindOfClass:[TGModernButton class]]) {
                     button.alpha = [(TGModernButton *)button stateAlpha];
                 } else {
                     button.alpha = 1.0f;
                 }
             } completion:nil];
        }
        else
        {
            removeViewAnimation(button, @"transform");
            removeViewAnimation(button, @"opacity");
            button.transform = CGAffineTransformMakeTranslation(button.transform.tx, 0.0f);
            if ([button isKindOfClass:[TGModernButton class]]) {
                button.alpha = [(TGModernButton *)button stateAlpha];
            } else {
                button.alpha = 1.0f;
            }
        }
        
        inset += button.frame.size.width + 5.0f;
    }
    
    if (forceLayout)
        [self layoutSubviews];
    
    if (iosMajorVersion() >= 7 && !forceLayout) {
        UIEdgeInsets insets = _inputField.internalTextView.textContainerInset;
        if (ABS(inset - insets.right) > FLT_EPSILON) {
            insets.right = inset;
            _inputField.internalTextView.textContainerInset = insets;
            [_inputField refreshHeight:false];
        }
    }
    
    if (!forceLayout)
        [self setNeedsLayout];
}

- (void)keyboardModeButtonPressed
{
    if (_customKeyboardView == nil)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _stickerKeyboardView.enableAnimation = false;
        
        if (self.isCustomKeyboardExpanded)
            [self setCustomKeyboardExpanded:false animated:true];
        
        self.inputField.internalTextView.enableFirstResponder = true;
        [self.inputField becomeFirstResponder];
        
        [self updateSendButtonVisibility:true];
        [self updateModeButtonVisibility:true reset:false];
        [self updateAssociatedPanelVisibility:true];
        
        if (_replyMarkup != nil) {
            id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
            if ([delegate respondsToSelector:@selector(inputPanelRequestedToggleCommandKeyboard:showCommandKeyboard:)]) {
                [delegate inputPanelRequestedToggleCommandKeyboard:self showCommandKeyboard:false];
            }
        }
    });
}

- (void)stickerModeButtonPressed
{
    if ([_customKeyboardView isKindOfClass:[TGStickerKeyboardView class]])
        return;
    
    if (_canOpenStickersPanel != nil && !_canOpenStickersPanel()) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_stickerKeyboardView == nil)
        {
            _stickerKeyboardView = [[TGStickerKeyboardView alloc] init];
            _stickerKeyboardView.channelInfoSignal = _channelInfoSignal;
            id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
            _stickerKeyboardView.parentViewController = [delegate inputPanelParentViewController:self];
            __weak TGModernConversationInputTextPanel *weakSelf = self;
            _stickerKeyboardView.stickerSelected = ^(TGDocumentMediaAttachment *sticker)
            {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil)
                {
                    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)strongSelf.delegate;
                    [delegate inputPanelRequestedSendSticker:strongSelf sticker:sticker];
                    
                    if (strongSelf.isCustomKeyboardExpanded)
                        [strongSelf setCustomKeyboardExpanded:false animated:true];
                }
            };
            _stickerKeyboardView.gifSelected = ^(TGDocumentMediaAttachment *sticker)
            {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil)
                {
                    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)strongSelf.delegate;
                    [delegate inputPanelRequestedSendGif:strongSelf document:sticker];
                    
                    if (strongSelf.isCustomKeyboardExpanded)
                        [strongSelf setCustomKeyboardExpanded:false animated:true];
                }
            };
            _stickerKeyboardView.gifTabActive = ^(bool isActive) {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf updateGifsTabActive:isActive];
                }
            };
            _stickerKeyboardView.requestedExpand = ^(bool expand) {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf setCustomKeyboardExpanded:expand animated:true];
                }
            };
            _stickerKeyboardView.requestedCollapse = ^(bool collapse) {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf setCollapsed:collapse];
                }
            };
            _stickerKeyboardView.expandInteraction = ^(CGFloat offset) {
                __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf customKeyboardInteraction:offset];
                }
            };
            [_stickerKeyboardView sizeToFitForWidth:self.frame.size.width];
        }
        else
        {
            _stickerKeyboardView.hidden = false;
            [_stickerKeyboardView updateIfNeeded];
        }
        
        _stickerKeyboardView.enableAnimation = true;
        [self setCustomKeyboard:_stickerKeyboardView animated:true force:false];
    });
}

- (void)setCollapsed:(bool)collapsed
{
    _collapsed = collapsed;
}

- (void)showStickersPanel
{
    [self stickerModeButtonPressed];
}

- (void)updateGifsTabActive:(bool)isActive {
    [self updateSendButtonVisibility:false];
    
    if (isActive) {
        if (_inputField.text.length == 0) {
            [_inputField setText:@"@gif " animated:true];
            _removeGifTabTextOnDeactivation = true;
        }
    } else {
        if ([_inputField.text isEqualToString:@"@gif "]) {
            [_inputField setText:@"" animated:true];
        }
    }
}

- (void)slashModeButtonPressed
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if (self.maybeInputField.text.length == 0)
        {
            self.inputField.internalTextView.enableFirstResponder = true;
            self.inputField.text = @"/";
            [self.inputField becomeFirstResponder];
        }
    });
}

- (void)commandModeButtonPressed
{
    if ([_customKeyboardView isKindOfClass:[TGCommandKeyboardView class]])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self showCommandsKeyboard:true];
    });
}

- (void)showCommandsKeyboard:(bool)animated
{
    TGCommandKeyboardView *commandKeyboardView = [[TGCommandKeyboardView alloc] init];
    commandKeyboardView.matchDefaultHeight = [self currentReplyMarkup].matchDefaultHeight;
    [commandKeyboardView setReplyMarkup:[self currentReplyMarkup]];
    __weak TGModernConversationInputTextPanel *weakSelf = self;
    commandKeyboardView.commandActivated = ^(TGBotReplyMarkupButton *button, int32_t userId, int32_t messageId)
    {
        __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            if ([strongSelf currentReplyMarkup].hideKeyboardOnActivation)
                [strongSelf keyboardModeButtonPressed];
            
            id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)strongSelf.delegate;
            if ([delegate respondsToSelector:@selector(inputPanelRequestedActivateCommand:button:userId:messageId:)])
                [delegate inputPanelRequestedActivateCommand:strongSelf button:button userId:userId messageId:messageId];
        }
    };
    CGSize size = [commandKeyboardView sizeThatFits:self.frame.size];
    commandKeyboardView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
    
    [self setCustomKeyboard:commandKeyboardView animated:animated force:!animated];
    _stickerKeyboardView.enableAnimation = false;
    
    [self updateGifsTabActive:false];
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelRequestedToggleCommandKeyboard:showCommandKeyboard:)]) {
        [delegate inputPanelRequestedToggleCommandKeyboard:self showCommandKeyboard:true];
    }
}

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)__unused growingTextView
{
    if (self.maybeInputField != nil && ![self.maybeInputField.text hasNonWhitespaceCharacters])
        self.maybeInputField.text = nil;
    
    if (_removeGifTabTextOnDeactivation) {
        [self updateGifsTabActive:false];
    }
    
    [self updateAssociatedPanelVisibility:true];
}

- (void)setReplyMarkup:(TGBotReplyMarkup *)replyMarkup
{
    if (!TGObjectCompare(_replyMarkup, replyMarkup))
    {
        _replyMarkup = replyMarkup;
        
        [self setCurrentReplyMarkup:[self currentReplyMarkup]];
    }
}

- (void)setHasBots:(bool)hasBots
{
    if (_hasBots != hasBots)
    {
        _hasBots = hasBots;
        
        [self updateModeButtonVisibility];
    }
}

- (void)setCanBroadcast:(bool)canBroadcast {
    if (_canBroadcast != canBroadcast) {
        _canBroadcast = canBroadcast;
        
        [self updateModeButtonVisibility];
        [self _updatePlaceholderImage];
    }
}

- (void)setIsBroadcasting:(bool)isBroadcasting {
    if (_isBroadcasting != isBroadcasting) {
        _isBroadcasting = isBroadcasting;
        
        UIColor *modeIconColor = UIColorRGB(0xa0a7b0);
        UIImage *broadcastImage = TGTintedImage(_isBroadcasting ? TGImageNamed(@"ConversationInputFieldBroadcastIconActive.png") : TGImageNamed(@"ConversationInputFieldBroadcastIconInactive.png"), modeIconColor);
        [_broadcastButton setImage:broadcastImage forState:UIControlStateNormal];
        
        [self _updatePlaceholderImage:true];
        [self updateModeButtonVisibility];
    }
}

- (void)setIsAlwaysBroadcasting:(bool)isAlwaysBroadcasting {
    if (_isAlwaysBroadcasting != isAlwaysBroadcasting) {
        _isAlwaysBroadcasting = isAlwaysBroadcasting;
        
        [self updateModeButtonVisibility];
        [self _updatePlaceholderImage];
    }
}

- (void)setIsChannel:(bool)isChannel {
    if (_isChannel != isChannel) {
        _isChannel = isChannel;
        
        [self _updatePlaceholderImage];
    }
}

- (void)setInputDisabled:(bool)inputDisabled {
    if (_inputDisabled != inputDisabled) {
        _inputDisabled = inputDisabled;
        
        if (inputDisabled) {
            if (_overlayDisabledView == nil) {
                _overlayDisabledView = [[UIView alloc] init];
                _overlayDisabledView.backgroundColor = UIColorRGBA(0xf7f7f7, 0.5f);
            }
            if (_overlayDisabledView.superview == nil) {
                [self addSubview:_overlayDisabledView];
            }
            self.userInteractionEnabled = false;
        } else {
            if (_overlayDisabledView.superview != nil) {
                [_overlayDisabledView removeFromSuperview];
            }
            self.userInteractionEnabled = true;
        }
        
        [self _updatePlaceholderImage];
        [self setNeedsLayout];
    }
}

- (void)setCurrentReplyMarkup:(TGBotReplyMarkup *)replyMarkup
{
    if ([_customKeyboardView isKindOfClass:[TGCommandKeyboardView class]])
    {
        if (replyMarkup == nil || replyMarkup.rows.count == 0)
            [self keyboardModeButtonPressed];
        else
        {
            TGCommandKeyboardView *commandKeyboardView = (TGCommandKeyboardView *)_customKeyboardView;
            commandKeyboardView.matchDefaultHeight = replyMarkup.matchDefaultHeight;
            [commandKeyboardView setReplyMarkup:replyMarkup];
            
            CGSize size = [commandKeyboardView sizeThatFits:self.frame.size];
            commandKeyboardView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
            
            _stickerKeyboardView.enableAnimation = false;
            [self setCustomKeyboard:commandKeyboardView animated:true force:false];
            [self updateGifsTabActive:false];
        }
    }
    else if (self.maybeInputField.text.length == 0 && replyMarkup != nil && replyMarkup.rows.count != 0)
    {
        if (![_customKeyboardView isKindOfClass:[TGStickerKeyboardView class]])
        {
            if (_enableKeyboard)
                [self commandModeButtonPressed];
            else
                _shouldShowKeyboardAutomatically = true;
        }
    }
    
    [self updateModeButtonVisibility];
}

- (void)setEnableKeyboard:(bool)enableKeyboard
{
    if (!_enableKeyboard)
    {
        _enableKeyboard = enableKeyboard;
        if (_canShowKeyboardAutomatically && _shouldShowKeyboardAutomatically && [self currentReplyMarkup] != nil && (![self currentReplyMarkup].hideKeyboardOnActivation || ![self currentReplyMarkup].alreadyActivated) && ![self currentReplyMarkup].manuallyHidden)
        {
            [self showCommandsKeyboard:false];
        }
    }
    else
        _enableKeyboard = enableKeyboard;
    _shouldShowKeyboardAutomatically = false;
}

- (void)broadcastButtonPressed {
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelToggleBroadcastMode:)]) {
        [delegate inputPanelToggleBroadcastMode:self];
    }
}

- (void)setDisplayProgress:(bool)displayProgress {
    if (_displayProgress != displayProgress) {
        _displayProgress = displayProgress;
        UIActivityIndicatorView *progressIndicator = _progressButtonIndicator;
        if (_displayProgress) {
            if (progressIndicator == nil) {
                progressIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:4];
                progressIndicator.color = self.presentation.pallete.chatInputFieldButtonColor;
                [_progressButton addSubview:progressIndicator];
                progressIndicator.center = CGPointMake(_progressButton.frame.size.width / 2.0f + 8.0f, _progressButton.frame.size.height / 2.0f + 0.5f);
                _progressButtonIndicator = progressIndicator;
            }
            [progressIndicator startAnimating];
        } else {
            [progressIndicator stopAnimating];
        }
        [self updateModeButtonVisibility];
    }
}

- (void)setContextPlaceholder:(NSString *)contextPlaceholder {
    if (!TGStringCompare(_contextPlaceholder, contextPlaceholder)) {
        _contextPlaceholder = contextPlaceholder;
        
        if (contextPlaceholder.length == 0) {
            [_contextPlaceholderLabel removeFromSuperview];
        } else {
            if (_contextPlaceholderLabel == nil) {
                _contextPlaceholderLabel = [[UILabel alloc] init];
                _contextPlaceholderLabel.textColor = UIColorRGB(0xbebec0);
                _contextPlaceholderLabel.backgroundColor = [UIColor clearColor];
                _contextPlaceholderLabel.font = TGSystemFontOfSize([self fontSize]);
            }
            
            if (_contextPlaceholderLabel.superview == nil) {
                [_fieldBackground insertSubview:_contextPlaceholderLabel aboveSubview:_inputFieldPlaceholder];
            }
            
            _contextPlaceholderLabel.text = contextPlaceholder;
            
            [self setNeedsLayout];
        }
    }
}

- (void)setContextBotMode:(TGUser *)contextBotMode {
    if (_contextBotMode.uid != contextBotMode.uid) {
        bool wasDisplayingContextResult = [self currentlyDisplayingContextResult];
        
        _contextBotMode = contextBotMode;
        
        if ([self currentlyDisplayingContextResult] != wasDisplayingContextResult) {
            [UIView performWithoutAnimation:^{
                [self updateInputFieldLayout];
                [self updateSendButtonVisibility];
                [self updateModeButtonVisibility];
                [self layoutSubviews];
            }];
            [self updateHeight];
        }
        
        [self updateContextBotInputMode];
        
        [self growingTextViewDidChange:_inputField afterSetText:false afterPastingText:false];
    }
}

- (void)setContextBotInputMode:(bool)contextBotInputMode {
    if (_contextBotInputMode != contextBotInputMode) {
        _contextBotInputMode = contextBotInputMode;
        
        [self updateContextBotInputMode];
    }
}

- (void)setMentionTextMode:(NSString *)mentionTextMode {
    if ((_mentionTextMode == nil) != (mentionTextMode == nil)) {
        _mentionTextMode = mentionTextMode;
        
        [self updateContextBotInputMode];
    }
}

- (void)updateContextBotInputMode {
    /*if (_contextBotInputMode || _contextBotMode || _mentionTextMode != nil) {
     if (_inlineBotsPanel == nil) {
     _inlineBotsPanel = [[TGInlineBotsInputPanel alloc] init];
     __weak TGModernConversationInputTextPanel *weakSelf = self;
     _inlineBotsPanel.botSelected = ^(TGUser *user) {
     __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
     if (strongSelf != nil && user != nil) {
     [strongSelf replaceInlineBot:user.userName];
     }
     };
     [self addSubview:_inlineBotsPanel];
     [_inlineBotsPanel setCurrentBot:_contextBotMode];
     
     [UIView performWithoutAnimation:^{
     [self layoutSubviews];
     }];
     
     [_inlineBotsPanel animateIn];
     
     [self updateInlineBotPanelOffset];
     [self updateAssociatedPanelInset:true];
     } else {
     [_inlineBotsPanel setCurrentBot:_contextBotMode];
     }
     } else {
     if (_inlineBotsPanel != nil) {
     TGInlineBotsInputPanel *panel = _inlineBotsPanel;
     _inlineBotsPanel = nil;
     [panel animateOut:^{
     [panel removeFromSuperview];
     }];
     [self updateAssociatedPanelInset:true];
     }
     }*/
}

- (void)animateRecordingIn {
    [_micButton animateIn];
}

- (void)addMicLevel:(CGFloat)level {
    [_micButton addMicLevel:level];
}

- (void)setMessageEditingContext:(TGMessageEditingContext *)messageEditingContext {
    [self setMessageEditingContext:messageEditingContext animated:false];
}

- (void)setMessageEditingContext:(TGMessageEditingContext *)messageEditingContext animated:(bool)animated {
    if (messageEditingContext != _messageEditingContext) {
        _messageEditingContext = messageEditingContext;
        _messageEditingContextInvalidated = false;
        
        _sendButtonWidth = 45.0f;
        
        if (_messageEditingContext.hasMedia) {
            [_attachButton setImage:self.presentation.images.chatInputAttachEditIcon forState:UIControlStateNormal];
        } else {
            [_attachButton setImage:self.presentation.images.chatInputAttachIcon forState:UIControlStateNormal];
        }
        
        [self updateAttachButtonVisibility];
        [self updateModeButtonVisibility];
        [self updateSendButtonVisibility:true];
        [self _updatePlaceholderImage];
        
        [self updateInputFieldLayout];
        
        [self setNeedsLayout];
        [self layoutSubviews];
        
        [self.inputField setAttributedText:[TGMessageEditingContext attributedStringForText:messageEditingContext.text entities:messageEditingContext.entities fontSize:[self fontSize]] keepFormatting:true animated:animated];
        
        if (messageEditingContext != nil) {
            if (_customKeyboardView != nil) {
                [self keyboardModeButtonPressed];
            }
        }
    }
}

- (TGMessageEditingContext *)messageEditingContext {
    _messageEditingContextInvalidated = true;
    if (_messageEditingContextInvalidated) {
        if (_messageEditingContext != nil) {
            __autoreleasing NSArray *entities = nil;
            NSString *text = [_inputField textWithEntities:&entities];
            _messageEditingContext = [[TGMessageEditingContext alloc] initWithText:text entities:entities isCaption:_messageEditingContext.isCaption hasMedia:_messageEditingContext.hasMedia cid:_messageEditingContext.cid messageId:_messageEditingContext.messageId];
        }
        _messageEditingContextInvalidated = false;
    }
    return _messageEditingContext;
}

- (void)clearButtonPressed {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = _inputField.internalTextView.text;
        NSString *previousText = text;
        if (text.length != 0) {
            NSRange spaceRange = [text rangeOfString:@" "];
            if (spaceRange.location != NSNotFound) {
                text = [text substringToIndex:spaceRange.location + 1];
                if (![previousText isEqualToString:text]) {
                    [self.inputField setText:text animated:false];
                } else {
                    [self.inputField setText:@"" animated:false];
                }
            } else {
                [self.inputField setText:@"" animated:false];
            }
        }
    });
}

- (void)replaceInlineBot:(NSString *)username {
    NSString *text = _inputField.internalTextView.text;
    if ([text hasPrefix:@"@"] && ![text hasPrefix:[NSString stringWithFormat:@"@%@ ", username]]) {
        NSInteger endIndex = 1;
        while (endIndex < (NSInteger)text.length) {
            unichar c = [text characterAtIndex:endIndex];
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_')) {
                break;
            }
            endIndex++;
        }
        
        NSString *query = [text substringFromIndex:endIndex];
        if ([query hasPrefix:@" "]) {
            query = [query substringFromIndex:1];
        }
        
        id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(inputPanelMentionTextEntered:mention:text:)]) {
            [delegate inputPanelMentionTextEntered:self mention:@"" text:@""];
        }
        
        text = [NSString stringWithFormat:@"@%@ %@", username, query];
        
        [self.inputField setText:text animated:false];
    }
}

- (void)atButtonPressed {
    if (self.maybeInputField.text.length == 0)
    {
        self.inputField.internalTextView.enableFirstResponder = true;
        self.inputField.text = @"@";
        
        [self updateModeButtonVisibility];
    }
}

- (void)resign
{
    [UIView performWithoutAnimation:^
    {
        if ([self.maybeInputField.internalTextView isFirstResponder])
            [self.maybeInputField.internalTextView resignFirstResponder];
    }];
    
    if (_customKeyboardView != nil)
        [self setCustomKeyboard:nil animated:false force:false];
}

- (BOOL)endEditing:(BOOL)force
{
    bool result = [super endEditing:force];
    
    if (_customKeyboardView != nil)
    {
        if (_removeGifTabTextOnDeactivation) {
            [self updateGifsTabActive:false];
        }
        
        if (self.isCustomKeyboardExpanded)
            [self setCustomKeyboardExpanded:false animated:true];
        [self setCustomKeyboard:nil animated:true force:false];
    }
    return result;
}

- (UIView *)customKeyboardWrapperView
{
    if (_customKeyboardWrapperView == nil)
    {
        _customKeyboardWrapperView = [[UIView alloc] init];
        _customKeyboardWrapperView.backgroundColor = self.presentation.pallete.barBackgroundColor;
        [self addSubview:_customKeyboardWrapperView];
    }
    return _customKeyboardWrapperView;
}

- (void)setCustomKeyboard:(UIView<TGModernConversationKeyboardView> *)keyboardView animated:(bool)animated force:(bool)force
{
    UIView<TGModernConversationKeyboardView> *previousKeyboard = _customKeyboardView;
    _customKeyboardView = keyboardView;
    _customKeyboardView.safeAreaInset = _safeAreaInset;
    _customKeyboardView.presentation = self.presentation;
    
    if (animated)
        _animatingCustomKeyboard = true;
    
    bool isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
    CGFloat customKeyboardHeight = [keyboardView preferredHeight:isLandscape];
    
    if (keyboardView != nil)
        [self customKeyboardWrapperView].hidden = false;

    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ((animated || force) && [delegate respondsToSelector:@selector(inputPanelWillChangeHeight:height:duration:animationCurve:)])
    {
        NSTimeInterval duration = animated ? 0.2 : 0.0;
        UIViewAnimationCurve curve = animated ? 7 : 0;
        
        [delegate inputPanelWillChangeHeight:self height:inputContainerHeight + customKeyboardHeight duration:duration animationCurve:curve];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if (previousKeyboard == nil || keyboardView == nil)
            [self updateSendButtonVisibility:true];
        [self updateModeButtonVisibility:true reset:false];
        [self updateAssociatedPanelVisibility:true];
    });
    
    if (previousKeyboard != keyboardView)
        _customKeyboardVersion++;
    
    if (keyboardView != nil)
        [keyboardView setVisible:true animated:true];
    else
        [previousKeyboard setVisible:false animated:true];
    
    if (previousKeyboard == _stickerKeyboardView && keyboardView == nil)
        [_stickerKeyboardView showTabPanel];
    
    if (keyboardView == nil)
    {
        NSInteger version = _customKeyboardVersion;
        
        TGDispatchAfter(0.55, dispatch_get_main_queue(), ^
        {
            if (previousKeyboard != _stickerKeyboardView)
                [previousKeyboard removeFromSuperview];
            else if (_customKeyboardView != _stickerKeyboardView)
                previousKeyboard.hidden = true;
            
            if (_customKeyboardVersion != version)
                return;
            
            _customKeyboardWrapperView.hidden = true;
        });
        return;
    }
    
    CGFloat bottomInset = inputContainerHeight < FLT_EPSILON ? 45.0f : 0.0f;
    CGFloat topInset = bottomInset > FLT_EPSILON ? _currentExtendedPanel.frame.size.height : 0.0f;
    _customKeyboardWrapperView.frame = CGRectMake(0.0f, inputContainerHeight - 6.0f + topInset, self.bounds.size.width, customKeyboardHeight + 6.0f + bottomInset);
    _customKeyboardView.frame = CGRectMake(0.0f, 6.0f, self.bounds.size.width, customKeyboardHeight + bottomInset);
    [_customKeyboardWrapperView addSubview:_customKeyboardView];
    
    if (self.maybeInputField.isFirstResponder)
        [self.inputField resignFirstResponder];
    self.inputField.internalTextView.enableFirstResponder = true;
}

- (TGModernConversationDimWindow *)dimWindow
{
    if (_dimWindow == nil)
    {
        __weak TGModernConversationInputTextPanel *weakSelf = self;
        _dimWindow = [[TGModernConversationDimWindow alloc] init];
        _dimWindow.dimTapped = ^
        {
            __strong TGModernConversationInputTextPanel *strongSelf = weakSelf;
            if (strongSelf != nil && !strongSelf->_customKeyboardView.isInteracting)
            {
                [strongSelf setCustomKeyboardExpanded:false animated:true];
            }
        };
    }
    return _dimWindow;
}

- (void)toggleCustomKeyboardExpanded
{
    if (_customKeyboardView == _stickerKeyboardView && _stickerKeyboardView.isGif)
        return;
    
    [self setCustomKeyboardExpanded:!_customKeyboardView.isExpanded animated:true];
}

- (void)setCustomKeyboardExpanded:(bool)expanded animated:(bool)animated
{
    [_customKeyboardWrapperView.superview bringSubviewToFront:_customKeyboardWrapperView];
    
    if (_dimWindow == nil && expanded)
    {
        CGRect absoluteFrame = [self convertRect:self.bounds toView:nil];
        [[self dimWindow] setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, [self convertPoint:self.bounds.origin toView:nil].y)];
    }
    
    void (^block)(void) = ^
    {
        CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
        CGFloat bottomInset = inputContainerHeight < FLT_EPSILON ? 45.0f : 0.0f;
        CGFloat topInset = bottomInset > FLT_EPSILON ? _currentExtendedPanel.frame.size.height : 0.0f;
        CGFloat customKeyboardHeight = [self customKeyboardHeight];
        CGRect absoluteFrame = [self convertRect:self.bounds toView:nil];
        if (expanded)
        {
            CGFloat edgeInset = TGIsPad() ? -6.0f : 6.0f;
            _customKeyboardWrapperView.frame = CGRectMake(_customKeyboardWrapperView.frame.origin.x, customKeyboardHeight - _contentAreaHeight + 2 * inputContainerHeight - edgeInset + topInset, _customKeyboardWrapperView.frame.size.width, _contentAreaHeight - inputContainerHeight + bottomInset);
            _customKeyboardView.frame = CGRectMake(_customKeyboardView.frame.origin.x, _customKeyboardView.frame.origin.y, _customKeyboardView.frame.size.width, _contentAreaHeight - inputContainerHeight + bottomInset);
            [[self dimWindow] setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, _messageAreaSize.height - _contentAreaHeight)];
            [[self dimWindow] setDimAlpha:1.0f];
        }
        else
        {
            _customKeyboardWrapperView.frame = CGRectMake(_customKeyboardWrapperView.frame.origin.x, inputContainerHeight - 6.0f, _customKeyboardWrapperView.frame.size.width, customKeyboardHeight + 6.0f + bottomInset);
            _customKeyboardView.frame = CGRectMake(_customKeyboardView.frame.origin.x, _customKeyboardView.frame.origin.y, _customKeyboardView.frame.size.width, customKeyboardHeight + bottomInset);
            [[self dimWindow] setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, _messageAreaSize.height - customKeyboardHeight - inputContainerHeight)];
            [[self dimWindow] setDimAlpha:0.0f];
        }
        
        CGFloat verticalOffset = _customKeyboardView.isExpanded ? (customKeyboardHeight - _contentAreaHeight + inputContainerHeight) : 0.0f;
        [self updateMainLayout:verticalOffset];
    };
    
    void (^completion)(BOOL) = ^(__unused BOOL finished)
    {
        if (!expanded)
            _dimWindow = nil;
    };
    
    [_customKeyboardView setExpanded:expanded];
    
    id<TGModernConversationInputTextPanelDelegate> delegate = (id<TGModernConversationInputTextPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(inputPanelExpandedKeyboard:expanded:)])
        [delegate inputPanelExpandedKeyboard:self expanded:expanded];
    
    if (animated)
    {
        [UIView animateWithDuration:0.2 delay:0.0 options:7 << 16 animations:block completion:completion];
    }
    else
    {
        block();
        completion(true);
    }
    
    _stickersArrowButton.selected = expanded;
}

- (void)customKeyboardInteraction:(CGFloat)offset
{
    CGFloat inputContainerHeight = [self heightForInputFieldHeight:_inputField.frame.size.height];
    CGFloat customKeyboardHeight = [self customKeyboardHeight];
    CGFloat bottomInset = inputContainerHeight < FLT_EPSILON ? 45.0f : 0.0f;
    CGFloat topInset = bottomInset > FLT_EPSILON ? _currentExtendedPanel.frame.size.height : 0.0f;
    
    bool isExpanded = [_customKeyboardView isExpanded];
    if (_dimWindow == nil)
    {
        [[self dimWindow] setDimAlpha:0.0f];
        [UIView animateWithDuration:0.2 animations:^
        {
            [[self dimWindow] setDimAlpha:1.0f];
        }];
        
        if (!isExpanded && _customKeyboardView == _stickerKeyboardView)
            [_stickerKeyboardView updateExpanded];
    }

    CGFloat wrapperOrigin = isExpanded ? customKeyboardHeight - _contentAreaHeight + 2 * inputContainerHeight - 6.0f: inputContainerHeight - 6.0f;
    CGFloat keyboardHeight = isExpanded ? _contentAreaHeight - inputContainerHeight : customKeyboardHeight;
    CGFloat fadeHeight = isExpanded ? _messageAreaSize.height - _contentAreaHeight : _messageAreaSize.height - customKeyboardHeight - inputContainerHeight;
    CGRect absoluteFrame = [self convertRect:self.bounds toView:nil];
    
    CGFloat limit = fabs((customKeyboardHeight - _contentAreaHeight + inputContainerHeight));
    CGFloat value = fabs(offset);
    CGFloat sign = offset / value;
    if (value > limit)
        offset = sign * limit;
    
    _customKeyboardWrapperView.frame = CGRectMake(_customKeyboardWrapperView.frame.origin.x, wrapperOrigin + offset + topInset, _customKeyboardWrapperView.frame.size.width, keyboardHeight + 6.0f - offset + bottomInset);
    _customKeyboardView.frame = CGRectMake(_customKeyboardView.frame.origin.x, _customKeyboardView.frame.origin.y, _customKeyboardView.frame.size.width, keyboardHeight - offset + bottomInset);
    [_dimWindow setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, fadeHeight + offset)];
    
    if (isExpanded)
        offset = -limit + offset;
    
    [self updateMainLayout:offset];
}

- (void)updateCustomKeyboardFrame:(CGFloat)inputContainerHeight {
    if (_animatingCustomKeyboard)
    {
        _animatingCustomKeyboard = false;
        return;
    }
    
    if (_customKeyboardView != nil && !_customKeyboardView.isInteracting) {
        CGFloat customKeyboardHeight = [self customKeyboardHeight];
        CGFloat bottomInset = inputContainerHeight < FLT_EPSILON ? 45.0f : 0.0f;
        CGFloat topInset = bottomInset > FLT_EPSILON ? _currentExtendedPanel.frame.size.height : 0.0f;
        CGRect absoluteFrame = [self convertRect:self.bounds toView:nil];
        
        if (_customKeyboardView.isExpanded)
        {
            CGFloat edgeInset = TGIsPad() ? -6.0f : 6.0f;
            _customKeyboardWrapperView.frame = CGRectMake(_customKeyboardWrapperView.frame.origin.x, customKeyboardHeight - _contentAreaHeight + 2 * inputContainerHeight - edgeInset + topInset, self.frame.size.width, _contentAreaHeight + bottomInset);
            _customKeyboardView.frame = CGRectMake(0.0f, 6.0f, _customKeyboardWrapperView.frame.size.width, _contentAreaHeight - inputContainerHeight + bottomInset);
            
            if (_dimWindow != nil)
                [[self dimWindow] setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, _messageAreaSize.height - _contentAreaHeight)];
        }
        else
        {
            _customKeyboardWrapperView.frame = CGRectMake(_customKeyboardWrapperView.frame.origin.x, inputContainerHeight - 6.0f, self.frame.size.width, customKeyboardHeight + 6.0f + bottomInset);
            _customKeyboardView.frame = CGRectMake(0.0f, 6.0f, _customKeyboardWrapperView.frame.size.width, customKeyboardHeight + bottomInset);
            
            if (_dimWindow != nil)
                [[self dimWindow] setDimFrame:CGRectMake(absoluteFrame.origin.x, 0.0f, absoluteFrame.size.width, _messageAreaSize.height - customKeyboardHeight - inputContainerHeight)];
        }
    }
}

- (CGFloat)currentHeight
{
    CGFloat inputContainerHeight = self.frame.size.height;
    CGFloat customKeyboardHeight = [self customKeyboardHeight];
    
    return inputContainerHeight + customKeyboardHeight;
}

- (CGFloat)customKeyboardHeight
{
    bool isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (_customKeyboardView == nil && _customKeyboardHeight > FLT_EPSILON)
        return _customKeyboardHeight;
    else
        return [_customKeyboardView preferredHeight:isLandscape];
}

- (bool)isCustomKeyboardExpanded
{
    return _customKeyboardView.isExpanded;
}

- (void)willDisappear
{
    _dimWindow = nil;
}

- (bool)isCustomKeyboardActive
{
    return _customKeyboardView != nil;
}

- (bool)isActive
{
    return self.maybeInputField.isFirstResponder || _customKeyboardView != nil;
}

- (NSInteger)textCaretPosition {
    UITextRange *selRange = _inputField.internalTextView.selectedTextRange;
    UITextPosition *selStartPos = selRange.start;
    NSInteger idx = [_inputField.internalTextView offsetFromPosition:_inputField.internalTextView.beginningOfDocument toPosition:selStartPos];
    return idx;
}

- (void)setChannelInfoSignal:(SSignal *)signal
{
    _channelInfoSignal = signal;
    if (_stickerKeyboardView != nil)
        _stickerKeyboardView.channelInfoSignal = signal;
}

@end
