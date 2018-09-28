//
//  TGCryptoPricesInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoPricesInfo.h"
#import "TGCryptoManager.h"

@interface TGCryptoPricesInfo () {
    NSMutableArray<TGCryptoCoinInfo *> *_coinInfos;
}

@end

@implementation TGCryptoPricesInfo

- (instancetype)initWithJSON:(NSDictionary *)dictionary ignoreUnknownCoins:(BOOL)ignoreUnknownCoins favorites:(BOOL)favorites
{
    if (self = [super init]) {
        _marketCap = [dictionary[@"cap"] doubleValue];
        _volume = [dictionary[@"volume"] doubleValue];
        _btcDominance = [dictionary[@"btcDominance"] doubleValue];
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"currency"]];
        
        _coinInfos = [NSMutableArray array];
        for (id json in dictionary[@"data"][favorites ? @"favorites" : @"list"]) {
            TGCryptoCoinInfo *coinInfo = [[TGCryptoCoinInfo alloc] initWithJSON:json];
            if (!ignoreUnknownCoins && coinInfo.currency == nil) {
                return nil;
            }
            [_coinInfos addObject:coinInfo];
        }
    }
    return self;
}

- (void)coinInfoAtIndexUnfavorited:(NSUInteger)index
{
    [_coinInfos removeObjectAtIndex:index];
}

//- (NSArray *)mergedCoinsFromJSON:(NSDictionary *)dictionary
//{
//    NSArray *list = dictionary[@"data"][@"list"];
//    NSArray *favorites = dictionary[@"data"][@"favorites"];
//    NSString *sortKey = dictionary[@"sort"];
//    NSComparisonResult order = NSOrderedSame;
//    {
//        NSString *orderString = dictionary[@"order"];
//        if ([orderString isEqualToString:@"ascending"]) {
//            order = NSOrderedAscending;
//        }
//        else if ([orderString isEqualToString:@"descending"]) {
//            order = NSOrderedDescending;
//        }
//    }
//    NSMutableArray *coins = [NSMutableArray array];
//    NSUInteger i = 0, j = 0;
//    while (i < list.count && j < favorites.count) {
//        if ([list[i][@"code"] isEqualToString:favorites[j][@"code"]]) {
//            [coins addObject:list[i]];
//            i++; j++;
//            continue;
//        }
//        if ([list[i][sortKey] compare:favorites[j][sortKey]] != order) {
//            [coins addObject:list[i++]];
//        }
//        else {
//            [coins addObject:favorites[j++]];
//        }
//    }
//    while (i < list.count) {
//        [coins addObject:list[i++]];
//    }
//    while (j < favorites.count) {
//        [coins addObject:favorites[j++]];
//    }
//    return coins;
//}

@end
