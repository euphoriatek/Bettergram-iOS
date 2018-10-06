//
//  TGCryptoPricesInfo.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import <Foundation/Foundation.h>

@class TGCryptoCoinInfo;
@class TGCryptoCurrency;

@interface TGCryptoPricesInfo : NSObject

@property (readonly, nonatomic, assign) double marketCap;
@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double btcDominance;
@property (readonly, nonatomic, assign) TGCryptoCurrency *currency;
@property (readonly, nonatomic, strong) NSArray<TGCryptoCoinInfo *> *coinInfos;

- (instancetype)initWithJSON:(NSDictionary *)dictionary ignoreUnknownCoins:(BOOL)ignoreUnknownCoins favorites:(BOOL)favorites;

- (void)coinInfoAtIndexUnfavorited:(NSUInteger)index;

@end
