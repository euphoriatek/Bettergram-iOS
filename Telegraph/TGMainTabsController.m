#import "TGMainTabsController.h"

@interface TGMainTabsController () {
    BOOL _initialized;
}
@end

@implementation TGMainTabsController

- (NSArray<TGTabBarButtonInfo *> *)buttonInfos
{
    NSArray<NSString *> *buttonIconsNames = @[
                                              @"tab_all_messages.png",
                                              @"tab_direct_messages.png",
                                              @"tab_groups.png",
                                              @"tab_announcements.png",
                                              @"tab_favorites.png",
                                              @"tab_crypto.png"
                                              ];
    __block NSMutableArray<TGTabBarButtonInfo *> *buttonInfos = [NSMutableArray arrayWithCapacity:buttonIconsNames.count];
    for (NSString *buttonIconsName in buttonIconsNames) {
        [buttonInfos addObject:[TGTabBarButtonInfo infoWithIcon:TGImageNamed(buttonIconsName)]];
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
    if (!_initialized && lastSelectedTabIndex < self.viewControllers.count)
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
