#import "TGPresentationPallete.h"

#import "TGWallpaperManager.h"

#import <LegacyComponents/TGColorWallpaperInfo.h>

@implementation TGPresentationPallete

- (UIColor *)tabBarBackgroundColor
{
    return self.barBackgroundColor;
}

- (UIColor *)tabBarSeparatorColor
{
    return self.barSeparatorColor;
}

- (UIColor *)dialogEditFavoriteColor
{
    return self.accentColor;
}

- (UIColor *)cryptoSortArrowColor
{
    return self.secondaryTextColor;
}

- (UIColor *)cryptoFavoritedCoinColor
{
    return UIColorRGB(0xF5A623);
}

- (UIColor *)searchBarPlainBackgroundColor
{
    return self.backgroundColor;
}

- (UIColor *)conversationInputPanelActionColor
{
    return self.accentColor;
}

- (UIColor *)chatTitleMutedColor
{
    return self.dialogBadgeMutedColor;
}

- (UIColor *)navigationTextColor
{
    if (self.navigationButtonColor == self.accentContrastColor) {
        return self.accentColor;
    }
    return self.accentContrastColor;
}

//

+ (bool)hasWallpaper
{
    return ![[[TGWallpaperManager instance] currentWallpaperInfo] isKindOfClass:[TGColorWallpaperInfo class]];
}

- (bool)prefersDarkKeyboard
{
    return self.isDark;
}

- (UIColor *)sectionHeaderBackgroundColor
{
    return [self barBackgroundColor];
}

- (UIColor *)sectionHeaderTextColor
{
    return [self secondaryTextColor];
}

- (UIColor *)navigationActiveSubtitleColor
{
    return [self accentColor];
}

- (UIColor *)navigationButtonColor
{
    return [self accentColor];
}

- (UIColor *)navigationBadgeColor
{
    return [self destructiveColor];
}

- (UIColor *)navigationBadgeTextColor
{
    return [self accentContrastColor];
}

- (UIColor *)tabActiveIconColor
{
    return [self accentColor];
}

- (UIColor *)tabBadgeColor
{
    return [self destructiveColor];
}

- (UIColor *)tabBadgeTextColor
{
    return [self accentContrastColor];
}

- (UIColor *)searchBarPlaceholderColor
{
    return [self secondaryTextColor];
}

- (UIColor *)dialogTextColor
{
    return [self secondaryTextColor];
}

- (UIColor *)dialogVerifiedIconColor
{
    return [self accentContrastColor];
}

- (UIColor *)dialogPinnedBackgroundColor
{
    return [self barBackgroundColor];
}

- (UIColor *)dialogBadgeColor
{
    return [self accentColor];
}

- (UIColor *)dialogUnsentColor
{
    return [self destructiveColor];
}

- (UIColor *)dialogEditTextColor
{
    return [self accentContrastColor];
}

- (UIColor *)chatIncomingAccentColor
{
    return [self accentColor];
}

- (UIColor *)chatIncomingLinkColor
{
    return [self linkColor];
}

- (UIColor *)chatIncomingButtonIconColor
{
    return [self chatIncomingBubbleColor];
}

- (UIColor *)chatIncomingAudioForegroundColor
{
    return [self chatIncomingAccentColor];
}

- (UIColor *)chatIncomingAudioDotColor
{
    return [self chatIncomingAccentColor];
}

- (UIColor *)chatOutgoingButtonIconColor
{
    return [self chatOutgoingBubbleColor];
}

- (UIColor *)chatOutgoingCallSuccessfulColor
{
    return [self chatIncomingCallSuccessfulColor];
}

- (UIColor *)chatOutgoingCallFailedColor
{
    return [self chatIncomingCallFailedColor];
}

- (UIColor *)chatUnreadTextColor
{
    return [self secondaryTextColor];
}

- (UIColor *)chatChecksMediaColor
{
    return [self accentContrastColor];
}

- (UIColor *)chatInputSendButtonColor
{
    return [self accentColor];
}

- (UIColor *)chatInputSendButtonIconColor
{
    return [self accentContrastColor];
}

- (UIColor *)chatStickersBadgeColor
{
    return [self destructiveColor];
}

- (UIColor *)callsOutgoingIconColor
{
    return [self dialogBadgeMutedColor];
}

- (UIColor *)volumeIndicatorForegroundColor
{
    return [self textColor];
}

- (UIColor *)collectionMenuCellSelectionColor
{
    return [self selectionColor];
}

- (UIColor *)collectionMenuPlaceholderColor
{
    return [self collectionMenuAccessoryColor];
}

- (UIColor *)collectionMenuAccentColor
{
    return [self accentColor];
}

- (UIColor *)collectionMenuDestructiveColor
{
    return [self destructiveColor];
}

- (UIColor *)collectionMenuCheckColor
{
    return [self accentColor];
}

- (UIColor *)menuSelectionColor
{
    return [self selectionColor];
}

- (UIColor *)menuTextColor
{
    return [self textColor];
}

- (UIColor *)menuSecondaryTextColor
{
    return [self secondaryTextColor];
}

- (UIColor *)menuAccentColor
{
    return [self accentColor];
}

- (UIColor *)menuDestructiveColor
{
    return [self destructiveColor];
}

- (UIColor *)menuSpinnerColor
{
    return [self collectionMenuAccessoryColor];
}

- (UIColor *)checkButtonCheckColor
{
    return [self accentContrastColor];
}

- (UIColor *)checkButtonBlueColor
{
    return [self accentColor];
}

@end
