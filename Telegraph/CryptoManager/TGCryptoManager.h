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

- (void)feedItemReadStateUpdated:(MWFeedItem *)feedItem;
- (NSURLSessionDataTask *)fillFeedItemThumbnailFromOGImage:(MWFeedItem *)feedItem completion:(void (^)(NSString *url))completion;

@end


@interface TGCryptoManager : NSObject

@property (nonatomic, strong, readonly) NSArray<TGCryptoCurrency *> *currencies;
@property (nonatomic, strong) TGCryptoCurrency *selectedCurrency;

@property (nonatomic, strong, readonly) TGFeedParser *newsFeedParser;
@property (nonatomic, strong, readonly) TGFeedParser *videosFeedParser;

+ (instancetype)manager;

- (void)fetchCoins:(NSUInteger)limit
            offset:(NSUInteger)offset
           sorting:(TGCoinSorting)sorting
         favorites:(BOOL)favorites
        completion:(void (^)(TGCryptoPricesInfo *pricesInfo))completion;
- (void)fetchResources:(void (^)(NSArray<TGResourceSection *> *resourceSections))completion;
- (void)updateCoin:(TGCryptoCurrency *)coin favorite:(BOOL)favorite;
- (void)loadCurrencies:(void (^)(void))completion;
- (TGCryptoCurrency *)cachedCurrencyWithCode:(NSString *)code;

@end

@interface TGCryptoNumberFormatter : NSNumberFormatter

@end
