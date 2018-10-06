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

+ (bool)hasWallpaper
{
    return ![[[TGWallpaperManager instance] currentWallpaperInfo] isKindOfClass:[TGColorWallpaperInfo class]];
}

- (bool)prefersDarkKeyboard
{
    return self.isDark;
}

@end
