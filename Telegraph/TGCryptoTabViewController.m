//
//  TGCryptoTabViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 8/28/18.
//

#import "TGCryptoTabViewController.h"


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

- (BOOL)isBarBarOnTop
{
    return YES;
}

- (void)updateNavigationItemOverride:(NSUInteger)selectedIndex
{
    int index = -1;
    for (UIViewController *viewController in self.viewControllers)
    {
        index++;
        BOOL selected = index == (int)selectedIndex;
        if ([viewController isKindOfClass:[TGViewController class]])
        {
            [(TGViewController *)viewController setTargetNavigationItem:selected ? _targetNavigationItem : nil
                                                        titleController:selected ? _titleController : nil];
        }
    }
}

- (void)setTargetNavigationItem:(UINavigationItem *)targetNavigationItem titleController:(UIViewController *)titleController
{
    _targetNavigationItem = targetNavigationItem;
    _titleController = titleController;
    [self updateNavigationItemOverride:self.selectedIndex];
}

@end
