//
//  TGResourceSection.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/28/18.
//

#import "TGResourceSection.h"

//"title": "Our favorite exchanges",
//"items": [
//{
//    "title": "Binance",
//    "description": "The undisputed leader for crypto trading",
//    "url": "https://www.binance.com",
//    "iconUrl": "https://assets.coingecko.com/coins/images/825/small/binance-coin-logo.png"
//},
//{
//    "title": "Bitmax",
//    "description": "Up 100x leverage for margin trading",
//    "url": "https://bitmax.ch",
//    "iconUrl": "https://qolczpnfu7-flywheel.netdna-ssl.com/wp-content/uploads/2014/02/bitoin.png"
//}
//          ]

@interface TGResourceItem ()

@end

@implementation TGResourceItem

- (instancetype)initWithJSON:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _title = dictionary[@"title"];
        _descriptionString = dictionary[@"description"];
        _urlString = dictionary[@"url"];
        _iconURLString = dictionary[@"iconUrl"];
#if DEBUG
        NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
        [unknownKeys removeObjectsInArray:@[@"title",@"description",@"url",@"iconUrl"]];
        if (unknownKeys.count > 0) {
            TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
            return nil;
        }
#endif
    }
    return self;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> title: %@", [self class], self, _title];
}

@end


@implementation TGResourceSection

- (instancetype)initWithJSON:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _title = dictionary[@"title"];
        
        NSMutableArray<TGResourceItem *> *resourceItems = [NSMutableArray array];
        for (id json in dictionary[@"items"]) {
            [resourceItems addObject:[[TGResourceItem alloc] initWithJSON:json]];
        }
        _resourceItems = resourceItems.copy;
#if DEBUG
        NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
        [unknownKeys removeObjectsInArray:@[@"title", @"items"]];
        if (unknownKeys.count > 0) {
            TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
            return nil;
        }
#endif
    }
    return self;
}

@end
