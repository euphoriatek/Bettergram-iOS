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
    
    TGSortingSearch             = 7,
} TGCoinSorting;

#define TGSortingFavoritedKey @(-1)

@interface TGCryptoPricePageInfo: NSObject

@property (nonatomic, assign) NSUInteger limit;
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, assign) TGCoinSorting sorting;
@property (nonatomic, assign) BOOL isFavorited;
@property (nonatomic, strong) NSString *searchString;

+ (instancetype)pageInfoWithLimit:(NSUInteger)limit
                           offset:(NSUInteger)offset
                          sorting:(TGCoinSorting)sorting
                     searchString:(NSString *)searchString;
@end


@interface TGCryptoPricesInfo : NSObject <NSCoding, NSCopying>

@property (readonly, nonatomic, assign) double marketCap;
@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double btcDominance;
@property (readonly, nonatomic, assign) NSTimeInterval statsUpdatedDate;

@property (nonatomic, strong) TGCryptoCurrency *currency;
@property (readonly, nonatomic, strong) NSDictionary<NSNumber *, NSArray<TGCryptoCurrency *> *> *coinInfos;

- (void)updateStatsWithJSON:(NSDictionary *)dictionary;
- (NSArray<TGCryptoCurrency *> *)updateValuesWithJSON:(NSDictionary *)dictionary
                                             pageInfo:(TGCryptoPricePageInfo *)pageInfo
                                     invalidatedCoins:(BOOL *)invalidatedCoins;
- (void)sortFavoritedWithSorting:(TGCoinSorting)sorting;
- (void)coin:(TGCryptoCurrency *)coin favorited:(BOOL)favorited;
- (NSArray<NSString *> *)outOfDateFavoriteCurrencyCodes:(NSArray<NSString *> *)favoriteCurrencyCodes;
- (void)resetDateForSorting:(TGCoinSorting)sorting;

- (void)updateSearchResults:(NSArray<TGCryptoCurrency *> *)searchResults;

@end
