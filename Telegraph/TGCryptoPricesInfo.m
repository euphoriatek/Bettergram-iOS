//
//  TGCryptoPricesInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoPricesInfo.h"
#import "TGCryptoManager.h"

@implementation TGCryptoPricePageInfo

+ (instancetype)pageInfoWithLimit:(NSUInteger)limit
                           offset:(NSUInteger)offset
                          sorting:(TGCoinSorting)sorting
                     searchString:(NSString *)searchString
{
    TGCryptoPricePageInfo *result = [[TGCryptoPricePageInfo alloc] init];
    result->_limit = limit;
    result->_offset = offset;
    result->_sorting = sorting;
    result->_searchString = searchString;
    return result;
}

@end


@interface TGCryptoPricesInfo () {
    NSMutableDictionary<NSNumber *, NSMutableArray<TGCryptoCurrency *> *> *_coinInfos;
}

@end

@implementation TGCryptoPricesInfo

- (instancetype)init
{
    if (self = [super init]) {
        _coinInfos = [NSMutableDictionary dictionary];
        _coinInfos[TGSortingFavoritedKey] = [NSMutableArray array];
    }
    return self;
}

- (void)setCurrency:(TGCryptoCurrency *)currency
{
    if ([_currency isEqual:currency]) return;
    _currency = currency;
    _marketCap = 0;
    _volume = 0;
    _btcDominance = 0;
    _statsUpdatedDate = 0;
    [_coinInfos enumerateKeysAndObjectsUsingBlock:^(__unused NSNumber * _Nonnull key, NSMutableArray<TGCryptoCurrency *> * _Nonnull obj, __unused BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [obj clean];
        }];
    }];
}

- (void)updateStatsWithJSON:(NSDictionary *)dictionary
{
    _statsUpdatedDate = NSDate.date.timeIntervalSince1970;
    _marketCap = [dictionary[@"cap"] doubleValue];
    _volume = [dictionary[@"volume"] doubleValue];
    _btcDominance = [dictionary[@"btcDominance"] doubleValue];
}

- (NSArray<TGCryptoCurrency *> *)updateValuesWithJSON:(NSDictionary *)dictionary
                                             pageInfo:(TGCryptoPricePageInfo *)pageInfo
                                     invalidatedCoins:(BOOL *)invalidatedCoins
{
    self.currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"currency"]];
    self.currency.requestsCount++;
    
    BOOL favorites = pageInfo.isFavorited;
    NSNumber *key = favorites ? TGSortingFavoritedKey : @(pageInfo.sorting);
    if (_coinInfos[key] == nil) {
        _coinInfos[key] = [NSMutableArray array];
    }
    NSUInteger index;
    if (!favorites && pageInfo.sorting != TGSortingSearch) {
        index = pageInfo.offset;
        for (NSUInteger i = _coinInfos[key].count; index > _coinInfos[key].count; i++) {
            [_coinInfos[key] addObject:[TGCryptoCurrency.alloc init]];
        }
    }
    else {
        index = _coinInfos[key].count;
    }
    NSMutableArray<TGCryptoCurrency *> *newCoins = [NSMutableArray array];
    NSMutableArray<TGCryptoCurrency *> *addedCoins = [NSMutableArray array];
    for (id json in dictionary[@"data"]) {
        TGCryptoCurrency *currency = [TGCryptoManager.manager cachedCurrencyWithCode:json[@"code"]];
        if (currency == nil){
            currency = [TGCryptoCurrency.alloc initWithCode:json[@"code"]];
            [newCoins addObject:currency];
        }
        else {
            if (!favorites) {
                [addedCoins addObject:currency];
            }
        }
        [currency fillWithCoinInfoJson:json sorting:pageInfo.sorting];
        if (pageInfo.sorting != TGSortingSearch) {
            if ((favorites || currency.favorite) && ![_coinInfos[TGSortingFavoritedKey] containsObject:currency]) {
                [_coinInfos[TGSortingFavoritedKey] addObject:currency];;
            }
            if (!favorites) {
                _coinInfos[key][index++] = currency;
            }
        }
    }
    *invalidatedCoins = NO;
    if (favorites) {
        [self sortFavoritedWithSorting:pageInfo.sorting];
    }
    else if (pageInfo.sorting != TGSortingSearch) {
        // Last object is an empty one to show loading indicator
        TGCryptoCurrency *currency = nil;
        while (_coinInfos[key].lastObject.code == nil) {
            currency = [_coinInfos[key] lastObject];
            [_coinInfos[key] removeLastObject];
        }
        if (!currency) {
            currency = [TGCryptoCurrency.alloc init];
        }
        [_coinInfos[key] addObject:currency];
        // removing duplicates
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _coinInfos[key].count)];
        [indexSet removeIndexesInRange:NSMakeRange(pageInfo.offset, pageInfo.limit)];
        [_coinInfos[key].mutableCopy enumerateObjectsAtIndexes:indexSet
                                                       options:0
                                                    usingBlock:^(TGCryptoCurrency * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                                                        if ([addedCoins containsObject:obj]) {
                                                            _coinInfos[key][idx] = [TGCryptoCurrency.alloc init];
                                                            *invalidatedCoins = YES;
                                                        }
                                                    }];
    }
    return newCoins;
}

- (void)updateSearchResults:(NSArray<TGCryptoCurrency *> *)searchResults
{
    _coinInfos[@(TGSortingSearch)] = searchResults.mutableCopy;
}

- (id)copyWithZone:(__unused NSZone *)zone
{
    TGCryptoPricesInfo *copy = [TGCryptoPricesInfo.alloc init];
    copy->_marketCap = _marketCap;
    copy->_volume = _volume;
    copy->_btcDominance = _btcDominance;
    copy->_coinInfos = [[NSMutableDictionary alloc] initWithDictionary:_coinInfos copyItems:YES];
    copy->_currency = _currency;
    return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:[decoder decodeObjectForKey:@"code"]];
        _marketCap = [decoder decodeDoubleForKey:@"marketCap"];
        _volume = [decoder decodeDoubleForKey:@"volume"];
        _btcDominance = [decoder decodeDoubleForKey:@"btcDominance"];
        
        _coinInfos = [NSMutableDictionary dictionary];
        _coinInfos[TGSortingFavoritedKey] = [NSMutableArray array];
        NSDictionary<NSNumber *, NSArray<NSString *> *> *coinInfoCodes = [decoder decodeObjectForKey:@"coinInfosCodes"];
        if ([coinInfoCodes isKindOfClass:NSDictionary.class])
            [coinInfoCodes enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray<NSString *> * _Nonnull obj, __unused BOOL * _Nonnull stop) {
                if (![key isKindOfClass:NSNumber.class] || ![obj isKindOfClass:NSArray.class]) {
                    return;
                }
                NSMutableArray<TGCryptoCurrency *> *currencies = [NSMutableArray array];
                _coinInfos[key] = currencies;
                [obj enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                    if (![obj isKindOfClass:NSString.class]) {
                        return;
                    }
                    TGCryptoCurrency *currency = [TGCryptoManager.manager cachedCurrencyWithCode:obj];
                    if (currency)
                        [currencies addObject:currency];
                }];
            }];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (_currency) [encoder encodeObject:_currency.code forKey:@"code"];
    [encoder encodeDouble:_marketCap forKey:@"marketCap"];
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_btcDominance forKey:@"btcDominance"];
    
    NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *coinInfoCodes = [NSMutableDictionary dictionary];
    [_coinInfos enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray<TGCryptoCurrency *> * _Nonnull obj, __unused BOOL * _Nonnull stop) {
        NSMutableArray<NSString *> *codes = [NSMutableArray array];
        coinInfoCodes[key] = codes;
        [obj enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            if (obj.code)
                [codes addObject:obj.code];
        }];
    }];
    [encoder encodeObject:coinInfoCodes forKey:@"coinInfosCodes"];
}

- (void)sortFavoritedWithSorting:(TGCoinSorting)sorting
{
    [_coinInfos[TGSortingFavoritedKey] sortUsingComparator:^NSComparisonResult(TGCryptoCurrency  *_Nonnull obj1, TGCryptoCurrency  *_Nonnull obj2) {
        if ((obj1.updatedDate != 0) == (obj2.updatedDate != 0) ||
            sorting == TGSortingCoinAscending || sorting == TGSortingCoinDescending)
        {
            switch (sorting) {
                case TGSorting24hAscending:
                case TGSorting24hDescending:
                    return [obj1.dayDelta compare:obj2.dayDelta] * (sorting == TGSorting24hAscending ? 1 : -1);
                    
                case TGSortingCoinAscending:
                case TGSortingCoinDescending:
                    return [obj1.name compare:obj2.name] * (sorting == TGSortingCoinAscending ? 1 : -1);
                    
                case TGSortingPriceAscending:
                case TGSortingPriceDescending: {
                    NSComparisonResult result = NSOrderedSame;
                    if ((obj1.price == nil) != (obj2.price == nil)) {
                        result = obj1.price == nil ? NSOrderedAscending : NSOrderedDescending;
                    }
                    else {
                        result = [obj1.price compare:obj2.price];
                    }
                    return result * (sorting == TGSortingPriceAscending ? 1 : -1);
                }
                    
                case TGSortingNone:
                    return [@(obj1.rank) compare:@(obj2.rank)];
                    
                case TGSortingSearch:
                    return 0;
            }
        }
        if (obj1.updatedDate == 0) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
}

- (void)coin:(TGCryptoCurrency *)coin favorited:(BOOL)favorited
{
    if (coin == nil) return;
    if (favorited) {
        if ([_coinInfos[TGSortingFavoritedKey] containsObject:coin])
            return;
        [_coinInfos[TGSortingFavoritedKey] addObject:coin];
    }
    else {
        NSInteger index = [_coinInfos[TGSortingFavoritedKey] indexOfObject:coin];
        if (index != NSNotFound) {
            [_coinInfos[TGSortingFavoritedKey] removeObjectAtIndex:index];
        }
    }
}

- (NSArray<NSString *> *)outOfDateFavoriteCurrencyCodes:(NSArray<NSString *> *)favoriteCurrencyCodes
{
    NSMutableArray<NSString *> *outOfDateCoinCodes = favoriteCurrencyCodes.mutableCopy;
    [_coinInfos[TGSortingFavoritedKey] enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop)
     {
         if (obj.updatedDate + kPricesUpdateInterval / 3 > NSDate.date.timeIntervalSince1970) {
             [outOfDateCoinCodes removeObject:obj.code];
         }
     }];
    return outOfDateCoinCodes;
}

- (void)resetDateForSorting:(TGCoinSorting)sorting
{
    [self.coinInfos[@(sorting)] enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop)
     {
         [obj setUpdatedDate:0 sorting:sorting];
     }];
    _statsUpdatedDate = 0;
}

@end
