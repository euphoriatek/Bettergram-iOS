#import "TGMainTabsController.h"

@interface TGMainTabsController () {
    BOOL _initialized;
}
@end

@implementation TGMainTabsController

- (NSArray<TGTabBarButtonInfo *> *)buttonInfos
{
    return @[
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_all_messages.png") accessibilityTitle:@"DialogList.Title.AM"],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_direct_messages.png") accessibilityTitle:@"DialogList.Title.DM"],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_groups.png") accessibilityTitle:@"DialogList.Title.Groups"],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_announcements.png") accessibilityTitle:@"DialogList.Title.Announcements"],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_favorites.png") accessibilityTitle:@"DialogList.Title.Favorites"],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_crypto.png") accessibilityTitle:@"DialogList.Title.Crypto"],
             ];
}

- (BOOL)isBarBarOnTop
{
    return NO;
}

- (void)setSelectedIndexCustom:(NSUInteger)selectedIndex
{
    NSUInteger lastSelectedTabIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSelectedTabIndex"];
    if (!_initialized && lastSelectedTabIndex < self.customViewControllers.count)
    {
        selectedIndex = lastSelectedTabIndex;
        _initialized = true;
    }
    
    [super setSelectedIndexCustom:selectedIndex];
    
    if (lastSelectedTabIndex != selectedIndex) {
        [[NSUserDefaults standardUserDefaults] setInteger:selectedIndex forKey:@"lastSelectedTabIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (!_initialized) {
        [self setSelectedIndexCustom:selectedIndex];
    }
    [super setSelectedIndex:selectedIndex];
}

@end
