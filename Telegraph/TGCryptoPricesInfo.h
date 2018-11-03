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
    TGSortingNone               = 0,
    TGSortingCoinAscending      = 1,
    TGSortingCoinDescending     = 2,
    TGSortingPriceAscending     = 3,
    TGSortingPriceDescending    = 4,
    TGSorting24hAscending       = 5,
    TGSorting24hDescending      = 6,
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
