//
//  TGCryptoPricesInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoPricesInfo.h"
#import "TGCryptoManager.h"


@interface TGCryptoPricesInfo () {
    NSMutableDictionary<NSNumber *, NSMutableArray<TGCryptoCoinInfo *> *> *_coinInfos;
}

@end

@implementation TGCryptoPricesInfo

- (instancetype)init
{
    if (self = [super init]) {
        _coinInfos = [NSMutableDictionary dictionary];
        _coinInfos[@(TGSortingFavoritedBit)] = [NSMutableArray array];
    }
    return self;
}

- (BOOL)updateValuesWithJSON:(NSDictionary *)dictionary pageInfo:(TGCryptoPricePageInfo)pageInfo ignoreUnknownCoins:(BOOL)ignoreUnknownCoins
{
    TGCryptoCurrency *currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"currency"]];
    if (![_currency isEqual:currency]) {
        _currency = currency;
        NSMutableArray *favorited = [NSMutableArray array];
        for (TGCryptoCoinInfo *coinInfo in _coinInfos[@(TGSortingFavoritedBit)]) {
            [favorited addObject:[TGCryptoCoinInfo.alloc initWithCurrency:coinInfo.currency]];
        }
        [_coinInfos removeAllObjects];
        _coinInfos[@(TGSortingFavoritedBit)] = favorited;
    }
    _marketCap = [dictionary[@"cap"] doubleValue];
    _volume = [dictionary[@"volume"] doubleValue];
    _btcDominance = [dictionary[@"btcDominance"] doubleValue];
    
    BOOL favorites = isset(&pageInfo.sorting, TGSortingFavoritedBit);
    NSNumber *key = @(favorites ? TGSortingFavoritedBit : pageInfo.sorting);
    if (_coinInfos[key] == nil) {
        _coinInfos[key] = [NSMutableArray array];
    }
    NSUInteger index;
    if (!favorites) {
        index = pageInfo.offset;
        for (NSUInteger i = _coinInfos[key].count; index > _coinInfos[key].count; i++) {
            [_coinInfos[key] addObject:[TGCryptoCoinInfo.alloc init]];
        }
    }
    else {
        index = _coinInfos[key].count;
    }
    for (id json in dictionary[@"data"][favorites ? @"favorites" : @"list"]) {
        TGCryptoCoinInfo *coinInfo = [TGCryptoCoinInfo.alloc initWithJSON:json];
        if (!ignoreUnknownCoins && coinInfo.currency == nil) {
            return NO;
        }
        if (favorites || coinInfo.currency.favorite) {
            __block BOOL replaced = NO;
            [_coinInfos[@(TGSortingFavoritedBit)].copy enumerateObjectsUsingBlock:^(TGCryptoCoinInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.currency isEqual:coinInfo.currency]) {
                    [_coinInfos[@(TGSortingFavoritedBit)] replaceObjectAtIndex:idx withObject:coinInfo];
                    *stop = replaced = YES;
                }
            }];
            if (!replaced) {
                [_coinInfos[@(TGSortingFavoritedBit)] addObject:coinInfo];
            }
        }
        if (!favorites) {
            _coinInfos[key][index++] = coinInfo;
        }
    }
    if (favorites) {
        [self sortFavoritedWithSorting:pageInfo.sorting];
    }
    else {
        TGCryptoCoinInfo *coinInfo = nil;
        while (_coinInfos[key].lastObject.currency == nil) {
            coinInfo = [_coinInfos[key] lastObject];
            [_coinInfos[key] removeLastObject];
        }
        if (!coinInfo) {
            coinInfo = [TGCryptoCoinInfo.alloc init];
        }
        [_coinInfos[key] addObject:coinInfo];
    }
    return YES;
}

- (id)copyWithZone:(__unused NSZone *)zone
{
    TGCryptoPricesInfo *copy = [TGCryptoPricesInfo.alloc init];
    copy->_marketCap = _marketCap;
    copy->_volume = _volume;
    copy->_btcDominance = _btcDominance;
    copy->_coinInfos = _coinInfos.copy;
    copy->_currency = _currency;
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:[decoder decodeObjectForKey:@"code"]];
        _marketCap = [decoder decodeDoubleForKey:@"marketCap"];
        _volume = [decoder decodeDoubleForKey:@"volume"];
        _btcDominance = [decoder decodeDoubleForKey:@"btcDominance"];
        _coinInfos = [decoder decodeObjectForKey:@"coinInfos"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (_currency) [encoder encodeObject:_currency.code forKey:@"code"];
    [encoder encodeDouble:_marketCap forKey:@"marketCap"];
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_btcDominance forKey:@"btcDominance"];
    [encoder encodeObject:_coinInfos forKey:@"coinInfos"];
}

- (void)sortFavoritedWithSorting:(TGCoinSorting)sorting
{
    clrbit(&sorting, TGSortingFavoritedBit);
    [_coinInfos[@(TGSortingFavoritedBit)] sortUsingComparator:^NSComparisonResult(TGCryptoCoinInfo  *_Nonnull obj1, TGCryptoCoinInfo  *_Nonnull obj2) {
        BOOL isBothEmptyOrNot = (obj1.updatedDate != 0) == (obj2.updatedDate != 0);
        switch (sorting) {
            case TGSorting24hAscending:
            case TGSorting24hDescending:
                if (!isBothEmptyOrNot) break;
                return [obj1.dayDelta compare:obj2.dayDelta] * (sorting == TGSorting24hAscending ? 1 : -1);
                
            case TGSortingCoinAscending:
            case TGSortingCoinDescending:
                return [obj1.currency.name compare:obj2.currency.name] * (sorting == TGSortingCoinAscending ? 1 : -1);
                
            case TGSortingPriceAscending:
            case TGSortingPriceDescending:
                if (!isBothEmptyOrNot) break;
                return [@(obj1.price) compare:@(obj2.price)] * (sorting == TGSortingPriceAscending ? 1 : -1);
        }
        if (obj1.updatedDate == 0) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
}

- (void)coin:(TGCryptoCurrency *)coin favorited:(BOOL)favorited
{
    if (favorited) {
        for (id key in _coinInfos) {
            for (TGCryptoCoinInfo *coinInfo in _coinInfos[key]) {
                if ([coinInfo.currency isEqual:coin]) {
                    if (![key isEqual:@(TGSortingFavoritedBit)]) {
                        [_coinInfos[@(TGSortingFavoritedBit)] addObject:coinInfo];
                    }
                    return;
                }
            }
        }
        [_coinInfos[@(TGSortingFavoritedBit)] addObject:[TGCryptoCoinInfo.alloc initWithCurrency:coin]];
    }
    else {
        [_coinInfos[@(TGSortingFavoritedBit)].copy enumerateObjectsUsingBlock:^(TGCryptoCoinInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.currency isEqual:coin]) {
                [_coinInfos[@(TGSortingFavoritedBit)] removeObjectAtIndex:idx];
                *stop = YES;
            }
        }];
    }
}

@end
