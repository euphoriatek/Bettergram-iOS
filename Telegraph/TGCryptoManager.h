//
//  TGCryptoManager.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import <Foundation/Foundation.h>

#import "TGCryptoCurrency.h"
#import "TGCryptoPricesInfo.h"

@class MWFeedItem, TGFeedParser, TGResourceSection;

FOUNDATION_EXPORT NSString * const TGCryptoManagerAPIOutOfDate;
FOUNDATION_EXPORT NSTimeInterval const kPricesUpdateInterval;


@interface TGCryptoManager : NSObject

@property (nonatomic, strong, readonly) NSArray<TGCryptoCurrency *> *currencies;
@property (nonatomic, strong) TGCryptoCurrency *selectedCurrency;

@property (nonatomic, strong, readonly) TGFeedParser *newsFeedParser;
@property (nonatomic, strong, readonly) TGFeedParser *videosFeedParser;

@property (nonatomic, assign) TGCryptoPricePageInfo pricePageInfo;
@property (nonatomic, copy) void (^pageUpdateBlock)(TGCryptoPricesInfo *pricesInfo);

@property (nonatomic, assign) BOOL apiOutOfDate;

+ (instancetype)manager;
- (void)initialize;

- (void)updateBettergramResourceForKey:(NSString *)key completion:(void (^)(id json))completion;
- (void)fetchResources:(void (^)(NSArray<TGResourceSection *> *resourceSections))completion;
- (void)updateCoin:(TGCryptoCurrency *)coin favorite:(BOOL)favorite;
- (BOOL)loadCurrenciesIfNeeded:(void (^)(BOOL success))completion;
- (void)forceUpdatePrices;
- (TGCryptoCurrency *)cachedCurrencyWithCode:(NSString *)code;

- (void)subscribeToListsWithEmail:(NSString *)email includeCrypto:(BOOL)includeCrypto;
- (void)subscribeToListsIfNeeded;
- (void)subscribeToChannelsIfNeeded;

@end
