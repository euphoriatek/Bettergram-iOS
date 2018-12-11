//
//  TGCryptoTabViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 8/28/18.
//

#import "TGCryptoTabViewController.h"
#import "TGAppDelegate.h"
#import "CALayer+SketchShadow.h"


@interface TGCryptoTabViewController () {
    UINavigationItem *_targetNavigationItem;
    UIViewController *_titleController;
}

@end

@implementation TGCryptoTabViewController

- (void)loadView
{
    [super loadView];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:TGImageNamed(@"header_logo_live_coin_watch")];
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (NSArray<TGTabBarButtonInfo *> *)buttonInfos
{
    return @[
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_crypto_prices") title:TGLocalized(@"Crypto.Prices.TabTitle")],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_crypto_news") title:TGLocalized(@"Crypto.News.TabTitle")],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_crypto_videos") title:TGLocalized(@"Crypto.Videos.TabTitle")],
             [TGTabBarButtonInfo infoWithIcon:TGImageNamed(@"tab_crypto_resources") title:TGLocalized(@"Crypto.Resources.TabTitle")],
             ];
}

- (void)initializeTabBar
{
    [super initializeTabBar];
    [self.customTabBar.layer applySketchShadowWithColor:UIColor.blackColor
                                                opacity:20
                                                      x:0 y:-1
                                                   blur:6];

}

- (BOOL)isBarBarOnTop
{
    return YES;
}

- (void)updateNavigationItemOverride:(NSUInteger)selectedIndex
{
    int index = -1;
    for (UIViewController *viewController in self.customViewControllers)
    {
        index++;
        if ([viewController isKindOfClass:[TGViewController class]])
        {
            BOOL selected = index == (int)selectedIndex;
            [(TGViewController *)viewController setTargetNavigationItem:selected ? _targetNavigationItem ?: self.navigationItem : nil
                                                        titleController:selected ? _titleController ?: self : nil];
        }
    }
}   

- (void)setTargetNavigationItem:(UINavigationItem *)targetNavigationItem titleController:(UIViewController *)titleController
{
    _targetNavigationItem = targetNavigationItem;
    _titleController = titleController;
    [self updateNavigationItemOverride:self.selectedIndex];
}

- (void)scrollToTopRequested
{
    if ([self.selectedViewController respondsToSelector:@selector(scrollToTopRequested)])
        [self.selectedViewController scrollToTopRequested];
}

@end
