//
//  TGCryptoTabViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 8/28/18.
//

#import "TGCryptoTabViewController.h"

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

@end
