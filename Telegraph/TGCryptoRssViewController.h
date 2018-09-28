//
//  TGCryptoRssViewController.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/27/18.
//

#import <LegacyComponents/LegacyComponents.h>
#import "TGCryptoManager.h"

@class TGFeedParser;

@interface TGCryptoRssViewController : TGViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithPresentation:(TGPresentation *)presentation feedParser:(TGFeedParser *)feedParser isVideoContent:(BOOL)isVideoContent;

@property (nonatomic, strong, readonly) TGFeedParser *feedParser;

@end
