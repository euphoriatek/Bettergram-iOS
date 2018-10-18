#import "TGNightPresentationPallete.h"
#import "TGPresentation.h"

@implementation TGNightPresentationPallete

- (UIColor *)dialogEditFavoriteColor
{
    return UIColorRGB(0x666666);
}

- (bool)isDark
{
    return true;
}

- (bool)underlineAllIncomingLinks
{
    return true;
}

- (bool)underlineAllOutgoingLinks
{
    return true;
}

- (UIColor *)backgroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)textColor
{
    return [UIColor whiteColor];
}

- (UIColor *)secondaryTextColor
{
    return UIColorRGB(0x8e8e93);
}

- (UIColor *)accentColor
{
    return [UIColor whiteColor];
}

- (UIColor *)accentContrastColor
{
    return [UIColor blackColor];
}

- (UIColor *)destructiveColor
{
    return UIColorRGB(0xee7b70);
}

- (UIColor *)selectionColor
{
    return UIColorRGB(0x151515);
}

- (UIColor *)separatorColor
{
    return UIColorRGB(0x252525);
}

- (UIColor *)linkColor
{
    return [self accentColor];
}

- (UIColor *)padSeparatorColor
{
    return [self barSeparatorColor];
}

- (UIColor *)barBackgroundColor
{
    return UIColorRGB(0x1c1c1d);
}

- (UIColor *)barSeparatorColor
{
    return [UIColor blackColor];
}
- (UIColor *)navigationTitleColor
{
    return [UIColor whiteColor];
}

- (UIColor *)navigationSubtitleColor
{
    return [self secondaryTextColor];
}
- (UIColor *)navigationDisabledButtonColor
{
    return UIColorRGB(0x525252);
}

- (UIColor *)navigationBadgeColor
{
    return [self accentColor];
}

- (UIColor *)navigationBadgeBorderColor
{
    return [self barBackgroundColor];
}

- (UIColor *)navigationSpinnerColor
{
    return [self navigationSubtitleColor];
}

- (UIColor *)tabIconColor
{
    return UIColorRGB(0x929292);
}

- (UIColor *)tabTextColor
{
    return [self tabIconColor];
}

- (UIColor *)tabBadgeColor
{
    return [self accentColor];
}

- (UIColor *)tabBadgeBorderColor
{
    return [self barBackgroundColor];
}

- (UIColor *)searchBarBackgroundColor
{
    return UIColorRGB(0x272728);
}

- (UIColor *)searchBarTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)searchBarMergedBackgroundColor
{
    return UIColorRGB(0x272728);
}

- (UIColor *)searchBarClearIconColor
{
    return [self searchBarBackgroundColor];
}

- (UIColor *)dialogTitleColor
{
    return [UIColor whiteColor];
}

- (UIColor *)dialogNameColor
{
    return [UIColor whiteColor];
}

- (UIColor *)dialogDraftColor
{
    return [self destructiveColor];
}

- (UIColor *)dialogDateColor
{
    return [self secondaryTextColor];
}

- (UIColor *)dialogChecksColor
{
    return [self accentColor];
}

- (UIColor *)dialogVerifiedBackgroundColor
{
    return UIColorRGB(0x58a6e1);
}

- (UIColor *)dialogPinnedIconColor
{
    return [self dialogBadgeMutedColor];
}

- (UIColor *)dialogEncryptedColor
{
    return UIColorRGB(0x28b772);
}

- (UIColor *)dialogBadgeTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)dialogBadgeMutedColor
{
    return UIColorRGB(0x666666);
}

- (UIColor *)dialogBadgeMutedTextColor
{
    return [UIColor blackColor];
}

- (UIColor *)dialogEditDeleteColor
{
    return [self destructiveColor];
}

- (UIColor *)dialogEditMuteColor
{
    return UIColorRGB(0x414141);
}

- (UIColor *)dialogEditPinColor
{
    return UIColorRGB(0x505050);
}

- (UIColor *)dialogEditGroupColor
{
    return self.barBackgroundColor;
}

- (UIColor *)dialogEditReadColor
{
    return UIColorRGB(0x414141);
}

- (UIColor *)dialogEditUnreadColor
{
    return UIColorRGB(0x666666);
}

- (UIColor *)chatIncomingBubbleColor
{
    return UIColorRGB(0x1f1f1f);
}

- (UIColor *)chatIncomingBubbleBorderColor
{
    return [self chatIncomingBubbleColor];
}

- (UIColor *)chatIncomingHighlightedBubbleColor
{
    return [[self chatIncomingBubbleColor] colorWithHueMultiplier:1.0f saturationMultiplier:1.0f brightnessMultiplier:1.25f];
}

- (UIColor *)chatIncomingHighlightedBubbleBorderColor
{
    return [self chatIncomingHighlightedBubbleColor];
}

- (UIColor *)chatIncomingTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatIncomingSubtextColor
{
    return UIColorRGB(0x909090);
}

- (UIColor *)chatIncomingAccentColor
{
    return self.accentContrastColor;
}

- (UIColor *)chatIncomingDateColor
{
    return [self chatIncomingSubtextColor];
}

- (UIColor *)chatIncomingButtonColor
{
    return UIColorRGB(0xa5a5a5);
}

- (UIColor *)chatIncomingLineColor
{
    return [self chatOutgoingAccentColor];
}

- (UIColor *)chatIncomingAudioBackgroundColor
{
    return [self chatIncomingSubtextColor];
}

- (UIColor *)chatOutgoingBubbleColor
{
    return UIColorRGB(0x313131);
}

- (UIColor *)chatOutgoingBubbleBorderColor
{
    return [self chatOutgoingBubbleColor];
}

- (UIColor *)chatOutgoingHighlightedBubbleColor
{
    return [[self chatOutgoingBubbleColor] colorWithHueMultiplier:1.0f saturationMultiplier:1.0f brightnessMultiplier:1.25f];
}

- (UIColor *)chatOutgoingHighlightedBubbleBorderColor
{
    return [self chatOutgoingHighlightedBubbleColor];
}

- (UIColor *)chatOutgoingTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatOutgoingSubtextColor
{
    return UIColorRGB(0x999999);
}

- (UIColor *)chatOutgoingAccentColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatOutgoingLinkColor
{
    return [self linkColor];
}

- (UIColor *)chatOutgoingDateColor
{
    return [self chatOutgoingSubtextColor];
}

- (UIColor *)chatOutgoingButtonColor
{
    return UIColorRGB(0xa5a5a5);
}

- (UIColor *)chatOutgoingLineColor
{
    return [self chatOutgoingAccentColor];
}

- (UIColor *)chatOutgoingAudioBackgroundColor
{
    return [self chatOutgoingSubtextColor];
}

- (UIColor *)chatOutgoingAudioForegroundColor
{
    return [self chatOutgoingAccentColor];
}

- (UIColor *)chatOutgoingAudioDotColor
{
    return [self chatOutgoingAccentColor];
}

- (UIColor *)chatIncomingCallSuccessfulColor
{
    return [self dialogEncryptedColor];
}

- (UIColor *)chatIncomingCallFailedColor
{
    return [self destructiveColor];
}

- (UIColor *)chatUnreadBackgroundColor
{
    return [self chatIncomingBubbleColor];
}

- (UIColor *)chatUnreadBorderColor
{
    return nil;
}

- (UIColor *)chatSystemBackgroundColor
{
    return UIColorRGBA(0x000000, 0.6f);
}

- (UIColor *)chatSystemTextColor
{
    return [self accentColor];
}

- (UIColor *)chatActionBackgroundColor
{
    return UIColorRGBA(0x000000, 0.6f);
}

- (UIColor *)chatActionIconColor
{
    return [self chatIncomingButtonColor];
}

- (UIColor *)chatActionBorderColor
{
    return [self chatIncomingBubbleColor];
}

- (UIColor *)chatReplyButtonBackgroundColor
{
    return UIColorRGBA(0x000000, 0.6f);
}

- (UIColor *)chatReplyButtonHighlightedBackgroundColor
{
    return UIColorRGBA(0x000000, 0.45f);
}

- (UIColor *)chatReplyButtonBorderColor
{
    return [self chatIncomingBubbleColor];
}

- (UIColor *)chatReplyButtonHighlightedBorderColor
{
    return [[self chatReplyButtonBorderColor] colorWithAlphaComponent:0.85f];
}

- (UIColor *)chatReplyButtonIconColor
{
    return [self chatIncomingAccentColor];
}

- (UIColor *)chatImageBorderColor
{
    return [self barBackgroundColor];
}

- (UIColor *)chatImageBorderShadowColor
{
    return [UIColor clearColor];
}

- (UIColor *)chatRoundMessageBackgroundColor
{
    return [self chatImageBorderColor];
}

- (UIColor *)chatRoundMessageBorderColor
{
    return [self chatIncomingBubbleBorderColor];
}

- (UIColor *)chatChecksColor
{
    return [self chatOutgoingDateColor];
}

- (UIColor *)chatServiceBackgroundColor
{
    return nil;
}

- (UIColor *)chatServiceTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatServiceIconColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatInputBackgroundColor
{
    return UIColorRGB(0x060606);
}

- (UIColor *)chatInputBorderColor
{
    return [self chatInputBackgroundColor];
}

- (UIColor *)chatInputTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)chatInputPlaceholderColor
{
    return UIColorRGB(0x7b7b7b);
}

- (UIColor *)chatInputButtonColor
{
    return UIColorRGB(0x808080);
}

- (UIColor *)chatInputFieldButtonColor
{
    return [self chatInputPlaceholderColor];
}

- (UIColor *)chatInputKeyboardBackgroundColor
{
    return [self backgroundColor];
}

- (UIColor *)chatInputKeyboardBorderColor
{
    return [self chatInputKeyboardBackgroundColor];
}

- (UIColor *)chatInputKeyboardHeaderColor
{
    return [self secondaryTextColor];
}

- (UIColor *)chatInputKeyboardSearchBarColor
{
    return [self barBackgroundColor];
}

- (UIColor *)chatInputSelectionColor
{
    return [self chatInputBackgroundColor];
}

- (UIColor *)chatInputRecordingColor
{
    return [self accentColor];
}

- (UIColor *)chatInputWaveformBackgroundColor
{
    return [self secondaryTextColor];
}

- (UIColor *)chatInputWaveformForegroundColor
{
    return [UIColor blackColor];
}

- (UIColor *)chatStickersBadgeColor
{
    return [self accentColor];
}

- (UIColor *)chatBotResultPlaceholderColor
{
    return [self secondaryTextColor];
}

- (UIColor *)chatInputBotKeyboardBackgroundColor
{
    return UIColorRGB(0x171a1f);
}

- (UIColor *)chatInputBotKeyboardButtonColor
{
    return UIColorRGB(0x5c5f62);
}

- (UIColor *)chatInputBotKeyboardButtonHighlightedColor
{
    return UIColorRGB(0x44474a);
}

- (UIColor *)chatInputBotKeyboardButtonShadowColor
{
    return UIColorRGB(0x0e1013);
}

- (UIColor *)chatInputBotKeyboardButtonTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)paymentsPayButtonColor
{
    return [self accentColor];
}

- (UIColor *)paymentsPayButtonDisabledColor
{
    return UIColorRGB(0x606060);
}

- (UIColor *)locationPinColor
{
    return [self accentColor];
}

- (UIColor *)locationAccentColor
{
    return [self accentColor];
}

- (UIColor *)locationLiveColor
{
    return [self destructiveColor];
}

- (UIColor *)musicControlsColor
{
    return [UIColor whiteColor];
}

- (UIColor *)volumeIndicatorBackgroundColor
{
    return [self collectionMenuVariantColor];
}

- (UIColor *)collectionMenuBackgroundColor
{
    return [self backgroundColor];
}

- (UIColor *)collectionMenuCellBackgroundColor
{
    return [self barBackgroundColor];
}

- (UIColor *)collectionMenuCellSelectionColor
{
    return UIColorRGB(0x101010);
}

- (UIColor *)collectionMenuTextColor
{
    return [UIColor whiteColor];
}

- (UIColor *)collectionMenuVariantColor
{
    return UIColorRGB(0x8e8e8e);
}

- (UIColor *)collectionMenuSeparatorColor
{
    return [self barSeparatorColor];
}

- (UIColor *)collectionMenuAccessoryColor
{
    return [self collectionMenuVariantColor];
}

- (UIColor *)collectionMenuCommentColor
{
    return [self secondaryTextColor];
}

- (UIColor *)collectionMenuBadgeColor
{
    return [self accentColor];
}

- (UIColor *)collectionMenuBadgeTextColor
{
    return [self accentContrastColor];
}

- (UIColor *)collectionMenuSwitchColor
{
    return [self accentColor];
}

- (UIColor *)collectionMenuSpinnerColor
{
    return [self collectionMenuAccessoryColor];
}

- (UIColor *)menuBackgroundColor
{
    return [self collectionMenuCellBackgroundColor];
}

- (UIColor *)menuSelectionColor
{
    return [self collectionMenuCellSelectionColor];
}

- (UIColor *)menuSeparatorColor
{
    return [self collectionMenuSeparatorColor];
}

- (UIColor *)menuLinkColor
{
    return [self accentColor];
}

- (UIColor *)menuSectionHeaderBackgroundColor
{
    return [[self sectionHeaderBackgroundColor] colorWithHueMultiplier:1.0f saturationMultiplier:1.0f brightnessMultiplier:0.8f];
}

- (UIColor *)checkButtonBorderColor
{
    return [self secondaryTextColor];
}

- (UIColor *)checkButtonBackgroundColor
{
    return [self accentColor];
}

- (UIColor *)checkButtonChatBorderColor
{
    return [TGPresentationPallete hasWallpaper] ? [UIColor whiteColor] : [self secondaryTextColor];
}

@end

