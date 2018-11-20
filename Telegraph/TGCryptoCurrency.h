//
//  TGCryptoCurrency.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import <Foundation/Foundation.h>
#import "TGCryptoPricesInfo.h"

typedef enum : NSUInteger {
    TGCryptoCurrencyTypeUnknown = 0,
    TGCryptoCurrencyTypeCoin    = 1,
    TGCryptoCurrencyTypeFiat    = 2,
} TGCryptoCurrencyType;


@interface TGCryptoCurrency : NSObject <NSCoding>

@property (readonly, nonatomic, strong) NSString *code;
@property (readonly, nonatomic, strong) NSString *name;
@property (readonly, nonatomic, strong) NSString *url;
@property (readonly, nonatomic, strong) NSString *symbol;
@property (readonly, nonatomic, strong) NSString *iconURL;
@property (readonly, nonatomic, assign) TGCryptoCurrencyType type;

@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) NSUInteger requestsCount;

- (instancetype)initWithCode:(NSString *)code;
- (void)fillWithCurrencyJson:(NSDictionary *)dictionary
                     baseURL:(NSString *)baseURL
        baseIconURLGenerator:(NSString *(^)(TGCryptoCurrencyType type))baseIconURLGenerator;
- (BOOL)validateFilter:(NSString *)filter;

// Coin info

@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double cap;
@property (readonly, nonatomic, assign) NSInteger rank;
@property (readonly, nonatomic, strong) NSNumber *price;
@property (readonly, nonatomic, strong) NSNumber *minDelta;
@property (readonly, nonatomic, strong) NSNumber *dayDelta;

@property (readonly, nonatomic, assign) NSTimeInterval updatedDate;
@property (readonly, nonatomic, assign) NSTimeInterval priceSortingUpdatedDate;
@property (readonly, nonatomic, assign) NSTimeInterval rankSortingUpdatedDate;
@property (readonly, nonatomic, assign) NSTimeInterval deltaSortingUpdatedDate;

- (NSTimeInterval)updatedDateForSorting:(TGCoinSorting)sorting;
- (void)setUpdatedDate:(NSTimeInterval)updatedDate sorting:(TGCoinSorting)sorting;

- (void)fillWithCoinInfoJson:(NSDictionary *)dictionary sorting:(TGCoinSorting)sorting;
- (void)clean;

@end
