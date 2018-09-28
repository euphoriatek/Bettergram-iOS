//
//  TGCryptoManager.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import "TGCryptoManager.h"

#import "MWFeedParser.h"
#import <AFNetworking/AFNetworking.h>
#import <LegacyComponents/LegacyComponents.h>
#import <HTMLReader/HTMLReader.h>
#import "TGResourceSection.h"

static NSString *const kSuccessKey = @"success";
static NSString *const kDataKey = @"data";

static NSString *const kLastUpdateDateKey = @"Crypto.LastUpdateDateKey";
static NSString *const kSelectedCurrencyCodeKey = @"Crypto.SelectedCurrencyCodeKey";
static NSString *const kFavoriteCodesKey = @"Crypto.FavoriteCodesKey";

static NSString *const kImageKey = @"image";
static NSString *const kDateKey = @"date";

static NSTimeInterval const kDaySecons = 24 * 60 * 60;


@interface TGCryptoManager () {
    TGFeedParser *_newsFeedParser;
    TGFeedParser *_videosFeedParser;
    AFHTTPSessionManager *_livecoinSessionManager;
    AFHTTPSessionManager *_bettergramSessionManager;
    AFHTTPSessionManager *_httpParserSessionManager;
    NSDictionary<NSString *, TGCryptoCurrency *> *_currencies;
    NSMutableArray<NSString *> *_favoriteCurrencyCodes;
    NSTimeInterval _lastUpdateDate;
    
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *_httpHeaderImageURLs;
    
    dispatch_queue_t _processingQueue;
}

- (void)updateBettergramResourceForKey:(NSString *)key completion:(void (^)(id json))completion;

@end


@interface TGFeedParser () <MWFeedParserDelegate> {
    NSArray<MWFeedParser *> *_feedParsers;
    NSMutableArray<MWFeedItem *> *_feedItems;
    NSInteger _lastReportedFeedItemIndex;
    __weak NSTimer *_updateFeedTimer;
}

@end

@implementation TGFeedParser

- (instancetype)initWithKey:(NSString *)key
{
    if (self = [super init]) {
        _key = key;
        _lastReportedFeedItemIndex = NSNotFound;
        _feedItems = [self cachedFeedItemsForRssKey:key].mutableCopy;
        
        NSTimeInterval lastReadDate = [NSUserDefaults.standardUserDefaults doubleForKey:self.lastReadDateKey];
        _lastReadDate = lastReadDate > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadDate] : NSDate.date;
        [TGCryptoManager.manager updateBettergramResourceForKey:key completion:^(NSArray<NSString *> *urls) {
            _urls = urls;
            [self clearRemovedURLs];
            
            NSMutableArray<MWFeedParser *> *feedParsers = [NSMutableArray array];
            for (NSString *url in urls) {
                [feedParsers addObject:[self parserWithFeedURLString:url]];
            }
            _feedParsers = feedParsers;
            
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10 repeats:YES block:^(__unused NSTimer * _Nonnull timer) {
                for (MWFeedParser *parser in _feedParsers) {
                    [parser parse];
                }
            }];
            [timer fire];
        }];
    }
    return self;
}

- (NSString *)lastReadDateKey
{
    return [NSString stringWithFormat:@"lastRead%@Date",_key];
}

- (void)setLastReadDate:(NSDate *)lastReadDate
{
    if ( [_lastReadDate compare:lastReadDate] != NSOrderedAscending) return;
    _lastReadDate = lastReadDate;
    [NSUserDefaults.standardUserDefaults setDouble:lastReadDate.timeIntervalSince1970 forKey:self.lastReadDateKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (MWFeedParser *)parserWithFeedURLString:(NSString *)urlString
{
    MWFeedParser *feedParser = [[MWFeedParser alloc] initWithFeedURL:[NSURL URLWithString:urlString]];
    feedParser.delegate = self;
    feedParser.feedParseType = ParseTypeItemsOnly;
    feedParser.connectionType = ConnectionTypeAsynchronously;
    return feedParser;
}

- (void)setDelegate:(id<TGFeedParserDelegate>)delegate
{
    if (_delegate == delegate) return;
    _delegate = delegate;
    if (_delegate != nil) {
        _lastReportedFeedItemIndex = NSNotFound;
        [self reportNewFeedItems];
    }
}

#pragma mark - MWFeedParserDelegate

- (void)feedParser:(MWFeedParser *)__unused parser didParseFeedItem:(MWFeedItem *)item {
    for (MWFeedItem *feedItem in _feedItems) {
        if ([feedItem.identifier isEqualToString:item.identifier]) {
            return;
        }
    }
    [_feedItems addObject:item];
    [_updateFeedTimer invalidate];
    _updateFeedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reportNewFeedItems) userInfo:nil repeats:NO];
}

- (void)feedParserDidFinish:(MWFeedParser *)__unused parser
{
    __block BOOL parsing = NO;
    [_feedParsers enumerateObjectsUsingBlock:^(MWFeedParser * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.parsing) {
            parsing = YES;
            *stop = YES;
        }
    }];
    if (!parsing) {
        [self reportNewFeedItems];
        [_updateFeedTimer invalidate];
        [NSKeyedArchiver archiveRootObject:_feedItems toFile:[self feedItemsFileForRssKey:self.key]];
    }
}

- (void)reportNewFeedItems
{
    NSRange subarrayRange;
    subarrayRange.location = _lastReportedFeedItemIndex == NSNotFound ? 0 : _lastReportedFeedItemIndex + 1;
    subarrayRange.length = _feedItems.count - subarrayRange.location;
    if (subarrayRange.length > 0) {
        [_delegate feedParser:self fetchedItems:[_feedItems subarrayWithRange:subarrayRange]];
        _lastReportedFeedItemIndex = NSMaxRange(subarrayRange) - 1;
    }
}

- (void)clearRemovedURLs
{
    [_feedItems enumerateObjectsWithOptions:NSEnumerationReverse
                                 usingBlock:^(MWFeedItem * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                                     if (obj.feedURL && ![_urls containsObject:obj.feedURL]) {
                                         [_feedItems removeObjectAtIndex:idx];
                                     }
                                 }];
}

- (NSMutableArray<MWFeedItem *> *)cachedFeedItemsForRssKey:(NSString *)rssKey
{
    NSMutableArray<MWFeedItem *> *feedItems = [NSMutableArray array];
    for (MWFeedItem *feedItem in [NSKeyedUnarchiver unarchiveObjectWithFile:[self feedItemsFileForRssKey:rssKey]]) {
        if (![feedItem isKindOfClass:[MWFeedItem class]]) continue;
        if (-feedItem.date.timeIntervalSinceNow < kDaySecons * 7) {
            [feedItems addObject:feedItem];
        }
    }
    return feedItems.copy;
}

- (NSString *)feedItemsFileForRssKey:(NSString *)rssKey
{
    return [NSFileManager.defaultManager.temporaryDirectory
            URLByAppendingPathComponent:[NSString stringWithFormat:@"%@FeedItems",rssKey]].path;
}

@end

@implementation TGCryptoManager

+ (instancetype)manager {
    static TGCryptoManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _processingQueue = dispatch_queue_create("CryptoManagerProcessingQueue", NULL);
        _livecoinSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://http-api.livecoinwatch.com/"]];
        _bettergramSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.bettergram.io/v1/"]];
        _httpParserSessionManager = [[AFHTTPSessionManager alloc] init];
        _httpParserSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        id responseObject = [NSKeyedUnarchiver unarchiveObjectWithFile:[self currenciesResponseObjectFile]];
        if ([responseObject isKindOfClass:[NSDictionary class]] &&
            (_lastUpdateDate = [[responseObject objectForKey:kLastUpdateDateKey] doubleValue]) > 0 &&
            (NSDate.date.timeIntervalSince1970 - _lastUpdateDate < kDaySecons))
        {
            [self parseCurrenciesResponseObject:responseObject];
        }
        
        _httpHeaderImageURLs = [([NSKeyedUnarchiver unarchiveObjectWithFile:[self linkHeadersCacheFile]] ?: @{}) mutableCopy];
        [_httpHeaderImageURLs.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,id> * _Nonnull obj, __unused BOOL * _Nonnull stop) {
            if (NSDate.date.timeIntervalSince1970 - [obj[kDateKey] doubleValue] > kDaySecons * 5) {
                [_httpHeaderImageURLs removeObjectForKey:key];
            }
        }];
    }
    return self;
}

- (TGFeedParser *)newsFeedParser
{
    if (_newsFeedParser == nil) {
        _newsFeedParser = [[TGFeedParser alloc] initWithKey:@"news"];
    }
    return _newsFeedParser;
}

- (TGFeedParser *)videosFeedParser
{
    if (_videosFeedParser == nil) {
        _videosFeedParser = [[TGFeedParser alloc] initWithKey:@"videos"];
    }
    return _videosFeedParser;
}

- (NSURLSessionDataTask *)metaOgImageURLFromURL:(NSString *)url completion:(void (^)(NSString *url))completion
{
    NSString *imageUrl = _httpHeaderImageURLs[url][kImageKey];
    if (imageUrl != nil) {
        completion(imageUrl);
        return nil;
    }
    return [_httpParserSessionManager GET:url
                               parameters:nil
                                  headers:nil
                                 progress:nil
                                  success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      dispatch_async(_processingQueue, ^{
                                          NSString *contentType = nil;
                                          if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                                              NSDictionary *headers = [(NSHTTPURLResponse *)task.response allHeaderFields];
                                              contentType = headers[@"Content-Type"];
                                          }
                                          HTMLDocument *home = [HTMLDocument documentWithData:responseObject
                                                                            contentTypeHeader:contentType];
                                          for (HTMLElement *element in [home nodesMatchingSelector:@"meta"]) {
                                              if ([element.attributes[@"property"] isEqualToString:@"og:image"]) {
                                                  NSString *imageURL = element.attributes[@"content"];
                                                  completion(imageURL);
                                                  _httpHeaderImageURLs[url] = @{
                                                                                kImageKey: imageURL,
                                                                                kDateKey: @(NSDate.date.timeIntervalSince1970)
                                                                                };
                                                  static NSTimer *timer = nil;
                                                  [timer invalidate];
                                                  timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(__unused NSTimer * _Nonnull timer) {
                                                      [NSKeyedArchiver archiveRootObject:_httpHeaderImageURLs toFile:[self linkHeadersCacheFile]];
                                                  }];
                                                  return;
                                              }
                                          }
                                      });
                                  } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                  }];
}

- (void)fetchResources:(void (^)(NSArray<TGResourceSection *> *resourceSections))completion
{
    [self updateBettergramResourceForKey:@"resources" completion:^(id json) {
        NSArray *groups = nil;
        if (![json isKindOfClass:[NSDictionary class]] ||
            (groups = [json objectForKey:@"groups"]) == nil ||
            ![groups isKindOfClass:[NSArray class]])
        {
            TGLog(@"TGCMError: News list get parsing error: %@",groups);
            return;
        }
        NSMutableArray<TGResourceSection *> *resourceSections = [NSMutableArray array];
        for (id json in groups) {
            [resourceSections addObject:[[TGResourceSection alloc] initWithJSON:json]];
        }
        completion(resourceSections.copy);
    }];
}

- (void)updateBettergramResourceForKey:(NSString *)key completion:(void (^)(id json))completion
{
    NSString *filePath = [NSFileManager.defaultManager.temporaryDirectory
                          URLByAppendingPathComponent:[NSString stringWithFormat:@"%@FeedURLs",key]].path;
    NSDate *newsModificationDate = [self fileModificationDate:filePath];
    if (newsModificationDate != nil && -newsModificationDate.timeIntervalSinceNow < kDaySecons) {
        completion([NSKeyedUnarchiver unarchiveObjectWithFile:filePath]);
        return;
    }
    [_bettergramSessionManager GET:key
                        parameters:nil
                           headers:nil
                          progress:nil
                           success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                               id json = nil;
                               if (![responseObject isKindOfClass:[NSDictionary class]] ||
                                   ![[responseObject objectForKey:kSuccessKey] boolValue] ||
                                   (json = [responseObject objectForKey:key]) == nil)
                               {
                                   TGLog(@"TGCMError: News list get parsing error: %@",responseObject);
                                   return;
                               }
                               completion(json);
                               [NSKeyedArchiver archiveRootObject:json toFile:filePath];
                           } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                           }];
}

#pragma mark - Coins

- (void)fetchCoins:(NSUInteger)limit
            offset:(NSUInteger)offset
           sorting:(TGCoinSorting)sorting
         favorites:(BOOL)favorites
        completion:(void (^)(TGCryptoPricesInfo *pricesInfo))completion
{
    __weak static NSURLSessionDataTask *dataTask = nil;
    [dataTask cancel];
    [self loadCurrencies:^{
        dataTask = [_livecoinSessionManager GET:@"bettergram/coins"
                             parameters:@{
                                          @"sort":[self sortParamForSorting:sorting],
                                          @"order":[self orderParamForSorting:sorting],
                                          @"offset":@(offset),
                                          @"limit":@(favorites ? 0 : limit),
                                          @"favorites":favorites ? [_favoriteCurrencyCodes componentsJoinedByString:@","] : @"",
                                          @"currency":self.selectedCurrency.code,
                                          }
                                headers:nil
                               progress:nil
                                success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                    responseObject = [responseObject cleanedJSON];
                                    if (responseObject == nil ||
                                        ![responseObject isKindOfClass:[NSDictionary class]] ||
                                        ![[responseObject objectForKey:kSuccessKey] boolValue])
                                    {
                                        TGLog(@"TGCMError: Crypto currencies list invalid response: %@",responseObject);
                                        completion(nil);
                                        return;
                                    }
                                    TGCryptoPricesInfo *pricesInfo = [[TGCryptoPricesInfo alloc] initWithJSON:responseObject
                                                                                           ignoreUnknownCoins:NO
                                                                                                    favorites:favorites];
                                    if (pricesInfo != nil) {
                                        completion(pricesInfo);
                                        return;
                                    }
                                    // new coin added case
                                    [self loadCurrencies:^{
                                        completion([[TGCryptoPricesInfo alloc] initWithJSON:responseObject
                                                                         ignoreUnknownCoins:YES
                                                                                  favorites:favorites]);
                                    }
                                                   force:YES];
                                } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                    TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                    completion(nil);
                                }];
        dataTask.priority = NSURLSessionTaskPriorityHigh;
    }];
}

- (NSString *)orderParamForSorting:(TGCoinSorting)sorting
{
    switch (sorting) {
        case TGSortingCoinAscending:
        case TGSortingPriceAscending:
        case TGSorting24hAscending:
            return @"ascending";
            
        case TGSortingCoinDescending:
        case TGSortingPriceDescending:
        case TGSorting24hDescending:
            return @"descending";
    }
}

- (NSString *)sortParamForSorting:(TGCoinSorting)sorting
{
    switch (sorting) {
        case TGSortingCoinAscending:
        case TGSortingCoinDescending:
            return @"code";
            
        case TGSortingPriceAscending:
        case TGSortingPriceDescending:
            return @"price";
            
        case TGSorting24hAscending:
        case TGSorting24hDescending:
            return @"delta.minute";
    }
}

#pragma mark - Currencies

- (void)updateCoin:(TGCryptoCurrency *)coin favorite:(BOOL)favorite
{
    if (coin.favorite == favorite) return;
    coin.favorite = favorite;
    if (favorite) {
        [_favoriteCurrencyCodes addObject:coin.code];
    }
    else {
        [_favoriteCurrencyCodes removeObject:coin.code];
    }
    [NSUserDefaults.standardUserDefaults setObject:_favoriteCurrencyCodes forKey:kFavoriteCodesKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSArray<TGCryptoCurrency *> *)currencies
{
    return [_currencies.allValues sortedArrayUsingComparator:^NSComparisonResult(TGCryptoCurrency *  _Nonnull obj1, TGCryptoCurrency *  _Nonnull obj2) {
        return [obj1.name compare:obj2.name];
    }];
}

- (void)setSelectedCurrency:(TGCryptoCurrency *)selectedCurrency
{
    if ([_selectedCurrency isEqual:selectedCurrency]) return;
    _selectedCurrency = selectedCurrency;
    [NSUserDefaults.standardUserDefaults setObject:selectedCurrency.code forKey:kSelectedCurrencyCodeKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)loadCurrencies:(void (^)(void))completion
{
    [self loadCurrencies:completion force:NO];
}

- (void)loadCurrencies:(void (^)(void))completion force:(BOOL)force
{
    __weak static NSURLSessionDataTask *getCurrenciesTask = nil;
    static NSMutableArray<void (^)()> *pendingBlocks = nil;
    if (getCurrenciesTask != nil) {
        if (pendingBlocks == nil) {
            pendingBlocks = [NSMutableArray array];
        }
        [pendingBlocks addObject:[completion copy]];
        return;
    }
    if (!force && _currencies != nil && NSDate.date.timeIntervalSince1970 - _lastUpdateDate < kDaySecons) {
        completion();
        return;
    }
    getCurrenciesTask = [_livecoinSessionManager GET:@"currencies"
                                  parameters:nil
                                     headers:nil
                                    progress:nil
                                     success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                         responseObject = [responseObject cleanedJSON];
                                         if ([self parseCurrenciesResponseObject:responseObject]) {
                                             _lastUpdateDate = NSDate.date.timeIntervalSince1970;
                                             NSMutableDictionary *object = [responseObject mutableCopy];
                                             [object setObject:@(_lastUpdateDate) forKey:kLastUpdateDateKey];
                                             [NSKeyedArchiver archiveRootObject:object toFile:[self currenciesResponseObjectFile]];
                                             
                                             TGDispatchOnMainThread(^{
                                                 completion();
                                                 if (pendingBlocks != nil) {
                                                     for (void (^block)()  in pendingBlocks) {
                                                         block();
                                                     }
                                                     pendingBlocks = nil;
                                                 }
                                             });
                                         }
                                     } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                         TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                     }];
}

- (BOOL)parseCurrenciesResponseObject:(id)responseObject
{
    NSArray *data = nil;
    if (responseObject == nil ||
        ![responseObject isKindOfClass:[NSDictionary class]] ||
        ![[responseObject objectForKey:kSuccessKey] boolValue] ||
        !(data = [responseObject objectForKey:kDataKey]) ||
        ![data isKindOfClass:[NSArray class]])
    {
        TGLog(@"TGCMError: Crypto currencies list invalid response: %@",responseObject);
        return NO;
    }
    if (_favoriteCurrencyCodes == nil) {
        _favoriteCurrencyCodes = [NSUserDefaults.standardUserDefaults stringArrayForKey:kFavoriteCodesKey].mutableCopy ?: [NSMutableArray array];
    }
    NSString *selectedCurrencyCode = [[NSUserDefaults.standardUserDefaults stringForKey:kSelectedCurrencyCodeKey] ?: @"USD" uppercaseString];
    NSMutableDictionary<NSString *, TGCryptoCurrency *> *currencies = [NSMutableDictionary dictionary];
    for (NSDictionary *coinDictionary in data) {
        if (![coinDictionary isKindOfClass:[NSDictionary class]]) {
            TGLog(@"TGCMError: Crypto currencies list invalid response[data][i]: %@",coinDictionary);
            continue;
        }
        TGCryptoCurrency * cryptoCurrency = [[TGCryptoCurrency alloc] initWithJSON:coinDictionary];
        currencies[cryptoCurrency.code.uppercaseString] = cryptoCurrency;
        cryptoCurrency.favorite = [_favoriteCurrencyCodes containsObject:cryptoCurrency.code];
        if ([selectedCurrencyCode isEqualToString:cryptoCurrency.code]) {
            _selectedCurrency = cryptoCurrency;
        }
    }
    _currencies = currencies.copy;
    return YES;
}

- (TGCryptoCurrency *)cachedCurrencyWithCode:(NSString *)code
{
    return _currencies[code.uppercaseString];
}

#pragma mark - Support

- (NSString *)linkHeadersCacheFile
{
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:@"linkHeaders"].path;
    });
    return path;
}

- (NSString *)currenciesResponseObjectFile
{
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:@"currenciesResponseObject.json"].path;
    });
    return path;
}

- (NSDate *)fileModificationDate:(NSString *)file
{
    return [NSFileManager.defaultManager attributesOfItemAtPath:file error:nil].fileModificationDate;
}

@end


@implementation TGCryptoNumberFormatter

- (NSString *)stringFromNumber:(NSNumber *)number
{
    if (self.numberStyle == NSNumberFormatterCurrencyStyle) {
        if (number.doubleValue < 1) {
            self.maximumFractionDigits = 4;
            return [super stringFromNumber:number];
        }
        if (number.doubleValue < 10000) {
            self.maximumFractionDigits = 2;
            return [super stringFromNumber:number];
        }
        if (number.doubleValue < 1000000) {
            self.maximumFractionDigits = 0;
            return [super stringFromNumber:number];
        }
        self.maximumFractionDigits = 2;
    }
    if (number.doubleValue < 1000) {
        return [super stringFromNumber:number];
    }
    static NSArray* units;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        units = @[@"k",@"M",@"B",@"T",@"P",@"E"];
    });
    BOOL isPrecents = self.numberStyle == NSNumberFormatterPercentStyle;
    int exp = (int)MIN((log10l(number.doubleValue * (isPrecents ? 100 : 1)) / 3.f), units.count);
    return [NSString stringWithFormat:@"%@ %@", [super stringFromNumber:@(number.doubleValue / pow(1000, exp))], units[exp-1]];
}

@end
