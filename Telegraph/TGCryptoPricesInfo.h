//
//  TGCryptoPricesInfo.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import <Foundation/Foundation.h>

#define    clredbit(a,i)    ((a) & ~(1<<((i)%NBBY)))

@class TGCryptoCurrency;

typedef enum : NSUInteger {
    TGSortingCoinAscending      = 0,
    TGSortingCoinDescending     = 1,
    TGSortingPriceAscending     = 2,
    TGSortingPriceDescending    = 3,
    TGSorting24hAscending       = 4,
    TGSorting24hDescending      = 5,
} TGCoinSorting;

static const NSUInteger TGSortingFavoritedBit = 7;

struct TGCryptoPricePageInfo {
    NSUInteger limit;
    NSUInteger offset;
    TGCoinSorting sorting;
};
typedef struct TGCryptoPricePageInfo TGCryptoPricePageInfo;

@interface TGCryptoPricesInfo : NSObject <NSCoding, NSCopying>

@property (readonly, nonatomic, assign) double marketCap;
@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double btcDominance;
@property (nonatomic, strong) TGCryptoCurrency *currency;
@property (readonly, nonatomic, strong) NSDictionary<NSNumber *, NSArray<TGCryptoCurrency *> *> *coinInfos;

- (NSArray<TGCryptoCurrency *> *)updateValuesWithJSON:(NSDictionary *)dictionary
                                             pageInfo:(TGCryptoPricePageInfo)pageInfo
                                     invalidatedCoins:(BOOL *)invalidatedCoins;
- (void)sortFavoritedWithSorting:(TGCoinSorting)sorting;
- (void)coin:(TGCryptoCurrency *)coin favorited:(BOOL)favorited;
- (NSArray<NSString *> *)outOfDateFavoriteCurrencyCodes:(NSArray<NSString *> *)favoriteCurrencyCodes;

@end
