//
//  TGCryptoManager.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import <Foundation/Foundation.h>

#import "TGCryptoCurrency.h"
#import "TGCryptoCoinInfo.h"
#import "TGCryptoPricesInfo.h"

typedef enum : NSUInteger {
    TGSortingCoinAscending,
    TGSortingCoinDescending,
    TGSortingPriceAscending,
    TGSortingPriceDescending,
    TGSorting24hAscending,
    TGSorting24hDescending,
} TGCoinSorting;

@class MWFeedItem, TGFeedParser, TGResourceSection;


@protocol TGFeedParserDelegate <NSObject>

- (void)feedParser:(TGFeedParser *)feedParser fetchedItems:(NSArray<MWFeedItem *> *)feedItems;

@end


@interface TGFeedParser : NSObject 

@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong, readonly) NSSet<NSString *> *urls;

@property (nonatomic, strong) NSDate *lastReadDate;

@property (nonatomic, weak) id<TGFeedParserDelegate> delegate;

- (void)setNeedsArchiveFeedItems;
- (NSURLSessionDataTask *)fillFeedItemThumbnailFromOGImage:(MWFeedItem *)feedItem completion:(void (^)(NSString *url))completion;

@end


struct TGCryptoPricePageInfo {
    NSUInteger limit;
    NSUInteger offset;
    TGCoinSorting sorting;
    BOOL favorites;
};


@interface TGCryptoManager : NSObject

@property (nonatomic, strong, readonly) NSArray<TGCryptoCurrency *> *currencies;
@property (nonatomic, strong) TGCryptoCurrency *selectedCurrency;

@property (nonatomic, strong, readonly) TGFeedParser *newsFeedParser;
@property (nonatomic, strong, readonly) TGFeedParser *videosFeedParser;

+ (instancetype)manager;

@property (nonatomic, assign) struct TGCryptoPricePageInfo pricePageInfo;
@property (nonatomic, copy) void (^pageUpdateBlock)(TGCryptoPricesInfo *pricesInfo);

- (void)fetchResources:(void (^)(NSArray<TGResourceSection *> *resourceSections))completion;
- (void)updateCoin:(TGCryptoCurrency *)coin favorite:(BOOL)favorite;
- (void)loadCurrencies:(void (^)(BOOL success))completion;
- (TGCryptoCurrency *)cachedCurrencyWithCode:(NSString *)code;

- (void)subscribeToListsWithEmail:(NSString *)email includeCrypto:(BOOL)includeCrypto;
- (void)subscribeToListsIfNeeded;

@end

@interface TGCryptoNumberFormatter : NSNumberFormatter

@end
