#import "TGPresentationPallete.h"

#import "TGWallpaperManager.h"

#import <LegacyComponents/TGColorWallpaperInfo.h>

@implementation TGPresentationPallete

+ (bool)hasWallpaper
{
    return ![[[TGWallpaperManager instance] currentWallpaperInfo] isKindOfClass:[TGColorWallpaperInfo class]];
}

- (bool)prefersDarkKeyboard
{
    return self.isDark;
}

- (UIColor *)tabBarBackgroundColor
{
    return self.barBackgroundColor;
}

- (UIColor *)dialogEditFavoriteColor
{
    return self.accentColor;
}

- (UIColor *)tabBarSeparatorColor
{
    return self.barSeparatorColor;
}

- (UIColor *)conversationInputPanelActionColor
{
    return self.accentColor;
}

- (UIColor *)searchBarPlainBackgroundColor
{
    return self.backgroundColor;
}

@end
