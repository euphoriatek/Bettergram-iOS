#import "TGPresentationPallete.h"

#import "TGWallpaperManager.h"

#import <LegacyComponents/TGColorWallpaperInfo.h>

@implementation TGPresentationPallete

+ (bool)hasWallpaper
{
    return ![[[TGWallpaperManager instance] currentWallpaperInfo] isKindOfClass:[TGColorWallpaperInfo class]];
}

- (bool)prefersLightStatusBar
{
    return self.isDark;
}

- (UIColor *)conversationInputPanelActionColor
{
    return self.accentColor;
}

@end
