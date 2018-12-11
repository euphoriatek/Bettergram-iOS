#import "TGMainTabsController.h"

#define ButtonInfo(x, y) [TGTabBarButtonInfo infoWithIcon:TGImageNamed(x) accessibilityTitle:y]

@interface TGMainTabsController () {
    BOOL _initialized;
}
@end

@implementation TGMainTabsController

- (NSArray<TGTabBarButtonInfo *> *)buttonInfos
{
    NSMutableArray<TGTabBarButtonInfo *> *buttonInfos =
    @[
      ButtonInfo(@"tab_all_messages.png", @"DialogList.Title.AM"),
      ButtonInfo(@"tab_direct_messages.png", @"DialogList.Title.DM"),
      ButtonInfo(@"tab_groups.png", @"DialogList.Title.Groups"),
      ButtonInfo(@"tab_announcements.png", @"DialogList.Title.Announcements"),
      ButtonInfo(@"tab_favorites.png", @"DialogList.Title.Favorites")
      ].mutableCopy;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        [buttonInfos addObject:ButtonInfo(@"tab_crypto.png", @"DialogList.Title.Crypto")];
    }
    return buttonInfos;
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
