//
//  BGSubscribeViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/5/18.
//

#import "BGSubscribeViewController.h"

@interface BGSubscribeViewController () {
    UIImageView *_logoImageView;
//    UITextView
}

@end

@implementation BGSubscribeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _logoImageView = [[UIImageView alloc] initWithImage:TGImageNamed(@"logo_big.png")];
}

@end
