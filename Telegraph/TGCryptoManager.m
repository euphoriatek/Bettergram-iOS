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
#import "../../config.h"

NSString * const TGCryptoManagerAPIOutOfDate = @"TGCryptoManagerAPIOutOfDate";

static NSString *const kSuccessKey = @"success";
static NSString *const kDataKey = @"data";

static NSString *const kLastUpdateDateKey = @"Crypto.LastUpdateDateKey";
static NSString *const kSelectedCurrencyCodeKey = @"Crypto.SelectedCurrencyCodeKey";
static NSString *const kFavoriteCodesKey = @"Crypto.FavoriteCodesKey";

static NSString *const kImageKey = @"image";
static NSString *const kDateKey = @"date";

static NSTimeInterval const kDaySecons = 24 * 60 * 60;

#define USER_DEFAULTS_KEY_WITH_LIST_ID(listID) [NSString stringWithFormat:@"cachedEmailForListID-%@", listID]


@interface TGCryptoManager () {
    TGFeedParser *_newsFeedParser;
    TGFeedParser *_videosFeedParser;
    AFHTTPSessionManager *_livecoinSessionManager;
    AFHTTPSessionManager *_bettergramSessionManager;
    NSDictionary<NSString *, TGCryptoCurrency *> *_currencies;
    NSMutableArray<NSString *> *_favoriteCurrencyCodes;
    NSTimeInterval _lastUpdateDate;
    
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *_httpHeaderImageURLs;
    
    AFHTTPSessionManager *_mailchimpSessionManager;
    AFNetworkReachabilityManager *_reachabilityManager;
    
    NSURLSessionDataTask *_updatePricesDataTask;
    __weak NSTimer *_updatePricesTimer;
}

- (void)updateBettergramResourceForKey:(NSString *)key completion:(void (^)(id json))completion;

@end


@interface TGFeedParser () <MWFeedParserDelegate> {
    NSArray<MWFeedParser *> *_feedParsers;
    NSMutableArray<MWFeedItem *> *_feedItems;
    NSUInteger _lastReportedFeedItemIndex;
    __weak NSTimer *_updateFeedTimer;
    
    NSMutableDictionary<NSString *, NSDate *> *_parsersOldestDate;
    
    __weak NSTimer *_archiveFeedItemsTimer;
    AFHTTPSessionManager *_httpParserSessionManager;
    
    dispatch_queue_t _processingQueue;
    NSTimer *_globalTimer;
}

@end

@implementation TGFeedParser

- (instancetype)initWithKey:(NSString *)key
{
    if (self = [super init]) {
        _processingQueue = dispatch_queue_create("FeedParserProcessingQueue", NULL);
        _httpParserSessionManager = [[AFHTTPSessionManager alloc] init];
        _httpParserSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _parsersOldestDate = [NSMutableDictionary dictionary];
        _key = key;
        _lastReportedFeedItemIndex = NSNotFound;
        _feedItems = [self cachedFeedItemsForRssKey:key].mutableCopy;
        
        NSTimeInterval lastReadDate = [NSUserDefaults.standardUserDefaults doubleForKey:self.lastReadDateKey];
        _lastReadDate = lastReadDate > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadDate] : NSDate.date;
        [TGCryptoManager.manager updateBettergramResourceForKey:key completion:^(id urls) {
            if ([urls isKindOfClass:[NSSet class]]) {
                _urls = urls;
            }
            else if ([urls isKindOfClass:[NSArray class]]) {
                _urls = [NSSet setWithArray:urls];
            }
            [self clearRemovedURLs];
            
            NSMutableArray<MWFeedParser *> *feedParsers = [NSMutableArray array];
            for (NSString *url in _urls) {
                [feedParsers addObject:[self parserWithFeedURLString:url]];
            }
            _feedParsers = feedParsers;
            
            [self initTimer];
            [NSNotificationCenter.defaultCenter addObserver:self
                                                   selector:@selector(reachabilityStatusChanged) name:AFNetworkingReachabilityDidChangeNotification
                                                     object:nil];
        }];
    }
    return self;
}

- (void)initTimer
{
    [_globalTimer invalidate];
    _globalTimer = [NSTimer scheduledTimerWithTimeInterval:60 * 20 repeats:YES block:^(__unused NSTimer * _Nonnull timer) {
        for (MWFeedParser *parser in _feedParsers) {
            [parser parse];
        }
    }];
    [_globalTimer fire];
}

- (void)reachabilityStatusChanged
{
    if (!AFNetworkReachabilityManager.sharedManager.isReachable) return;
    NSDate *date = [[NSFileManager.defaultManager attributesOfItemAtPath:[self feedItemsFileForRssKey:self.key]
                                                                   error:nil] objectForKey:NSFileModificationDate];
    if (date.timeIntervalSinceNow > 60 * 20)
        [self initTimer];
}

- (NSString *)lastReadDateKey
{
    return [NSString stringWithFormat:@"lastRead%@Date",_key];
}

- (void)setLastReadDate:(NSDate *)lastReadDate
{
    if ([_lastReadDate compare:lastReadDate] != NSOrderedAscending) return;
    _lastReadDate = lastReadDate;
    [NSUserDefaults.standardUserDefaults setDouble:lastReadDate.timeIntervalSince1970 forKey:self.lastReadDateKey];
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

- (void)setNeedsArchiveFeedItems
{
    TGDispatchOnMainThread(^{
        [_archiveFeedItemsTimer invalidate];
        _archiveFeedItemsTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                 repeats:NO
                                                                   block:^(__unused NSTimer * _Nonnull timer) {
                                                                       [NSKeyedArchiver archiveRootObject:_feedItems toFile:[self feedItemsFileForRssKey:self.key]];
                                                                   }];
    });
}

#pragma mark - MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser
{
    _parsersOldestDate[parser.url.absoluteString] = [NSDate date];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    if ([_parsersOldestDate[parser.url.absoluteString] compare:item.date] == NSOrderedDescending) {
        _parsersOldestDate[parser.url.absoluteString] = item.date;
    }
    for (MWFeedItem *feedItem in _feedItems) {
        if ([feedItem.identifier isEqualToString:item.identifier]) {
            return;
        }
    }
    [_feedItems addObject:item];
    [_updateFeedTimer invalidate];
    _updateFeedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reportNewFeedItems) userInfo:nil repeats:NO];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
    [_feedItems.copy enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(MWFeedItem * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
                                          if ([parser.url.absoluteString isEqualToString:obj.feedURL] &&
                                              [_parsersOldestDate[obj.feedURL] compare:obj.date] == NSOrderedDescending)
                                          {
                                              [_feedItems removeObjectAtIndex:idx];
                                              if (_lastReportedFeedItemIndex < _feedItems.count && idx <= _lastReportedFeedItemIndex) {
                                                  _lastReportedFeedItemIndex--;
                                              }
                                          }
                                      }];
    __block BOOL parsing = NO;
    [_feedParsers enumerateObjectsUsingBlock:^(MWFeedParser * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop) {
        *stop = parsing = obj.parsing;
    }];
    [self setNeedsArchiveFeedItems];
    if (!parsing) {
        [_updateFeedTimer fire];
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
        if ([feedItem isKindOfClass:[MWFeedItem class]]) {
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

- (NSString *)linkHeadersCacheFile
{
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:@"linkHeaders"].path;
    });
    return path;
}

- (NSURLSessionDataTask *)fillFeedItemThumbnailFromOGImage:(MWFeedItem *)feedItem completion:(void (^)(NSString *url))completion
{
    if (feedItem.thumbnailURL) {
        completion(feedItem.thumbnailURL);
        return nil;
    }
    return [_httpParserSessionManager GET:feedItem.link
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
                                                  feedItem.thumbnailURL = element.attributes[@"content"];
                                                  completion(feedItem.thumbnailURL);
                                                  [self setNeedsArchiveFeedItems];
                                                  return;
                                              }
                                          }
                                      });
                                  } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      TGLog(@"TGCMError: OG image get error: %@",error);
                                      completion(nil);
                                  }];
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
        _reachabilityManager = [AFNetworkReachabilityManager managerForDomain:@"api.bettergram.io"];
        [_reachabilityManager startMonitoring];
        __weak TGCryptoManager *weakSelf = self;
        [_reachabilityManager setReachabilityStatusChangeBlock:^(__unused AFNetworkReachabilityStatus status) {
            __strong TGCryptoManager *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf->_reachabilityManager.isReachable && [strongSelf->_updatePricesTimer.userInfo boolValue])
                [strongSelf->_updatePricesTimer fire];
        }];
        
        _livecoinSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://http-api.livecoinwatch.com/"]];
        _bettergramSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.bettergram.io/v1/"]];
        
        id responseObject = [NSKeyedUnarchiver unarchiveObjectWithFile:[self currenciesResponseObjectFile]];
        if ([responseObject isKindOfClass:[NSDictionary class]] &&
            (_lastUpdateDate = [[responseObject objectForKey:kLastUpdateDateKey] doubleValue]) > 0 &&
            (NSDate.date.timeIntervalSince1970 - _lastUpdateDate < kDaySecons))
        {
            [self parseCurrenciesResponseObject:responseObject];
        }
        [AFNetworkReachabilityManager.sharedManager startMonitoring];
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

- (void)fetchResources:(void (^)(NSArray<TGResourceSection *> *resourceSections))completion
{
    [self updateBettergramResourceForKey:@"resources" completion:^(id json) {
        NSArray *groups = nil;
        if (![json isKindOfClass:[NSDictionary class]] ||
            (groups = [json objectForKey:@"groups"]) == nil ||
            ![groups isKindOfClass:[NSArray class]])
        {
            TGLog(@"TGCMError: News list get parsing error: %@",groups);
            completion(nil);
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
    if (newsModificationDate != nil && (-newsModificationDate.timeIntervalSinceNow < kDaySecons || _apiOutOfDate)) {
        completion([NSKeyedUnarchiver unarchiveObjectWithFile:filePath]);
        return;
    }
    if (_apiOutOfDate) {
        completion(nil);
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
                               [self checkResponceIfAPIIsOutOfDate:task.response];
                               completion(nil);
                           }];
}

- (void)subscribeToListsIfNeeded
{
    [self subscribeToListsWithEmail:nil includeCrypto:NO];
}

- (void)subscribeToListsWithEmail:(NSString *)email includeCrypto:(BOOL)includeCrypto
{
    static NSString *baseListID, *newsletterListID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SETUP_MAILCHIMP_CRITICAL_NEWSLETTER_LIST_ID(baseListID);
        SETUP_MAILCHIMP_CRYPTO_NEWSLETTER_LIST_ID(newsletterListID);
    });
    if (email) {
        [NSUserDefaults.standardUserDefaults setObject:email forKey:USER_DEFAULTS_KEY_WITH_LIST_ID(baseListID)];
        if (includeCrypto) {
            [NSUserDefaults.standardUserDefaults setObject:email forKey:USER_DEFAULTS_KEY_WITH_LIST_ID(newsletterListID)];
        }
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    for (NSString *listID in @[baseListID, newsletterListID]) {
        NSString *email = [NSUserDefaults.standardUserDefaults objectForKey:USER_DEFAULTS_KEY_WITH_LIST_ID(listID)];
        if (email) {
            info[listID] = email;
        }
    }
    if (info.count == 0) return;
    if (_mailchimpSessionManager == nil) {
        NSString *mailchimpAPIKey = nil;
        SETUP_MAILCHIMP_API(mailchimpAPIKey);
        NSString *dataCenterKey = [mailchimpAPIKey componentsSeparatedByString:@"-"].lastObject;
        _mailchimpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.api.mailchimp.com/3.0/",dataCenterKey]]];
        _mailchimpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_mailchimpSessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"anystring" password:mailchimpAPIKey];
        _mailchimpSessionManager.responseSerializer.acceptableContentTypes = [_mailchimpSessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/problem+json"];
    }
    for (NSString *listID in info) {
            [_mailchimpSessionManager POST:[NSString stringWithFormat:@"lists/%@/members",listID]
                                parameters:@{@"email_address":info[listID], @"status":@"subscribed"}
                                   headers:nil
                                  progress:^(__unused NSProgress * _Nonnull uploadProgress) {}
                                   success:^(__unused NSURLSessionDataTask * _Nonnull task, __unused id  _Nullable responseObject) {
                                       [NSUserDefaults.standardUserDefaults removeObjectForKey:USER_DEFAULTS_KEY_WITH_LIST_ID(listID)];
                                   } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                       id data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                                       if ([data isKindOfClass:[NSData class]]) {
                                           NSString *string = [[NSString alloc] initWithData:data encoding:0];
                                           if ([string containsString:@"Member Exists"] || [string containsString:@"is already a list member"]) {
                                               [NSUserDefaults.standardUserDefaults removeObjectForKey:USER_DEFAULTS_KEY_WITH_LIST_ID(listID)];
                                           }
                                       }
                                   }];
        }
}

#pragma mark - Coins

- (void)setPricePageInfo:(struct TGCryptoPricePageInfo)pricePageInfo
{
    _pricePageInfo = pricePageInfo;
    [self requestPage];
}

- (void)setPageUpdateBlock:(void (^)(TGCryptoPricesInfo *))pageUpdateBlock
{
    _pageUpdateBlock = [pageUpdateBlock copy];
    if (pageUpdateBlock != NULL)
        [self requestPage];
    else {
        [_updatePricesDataTask cancel];
        [_updatePricesTimer invalidate];
    }
}

- (void)requestPage
{
    [_updatePricesDataTask cancel];
    [_updatePricesTimer invalidate];
    if (_apiOutOfDate) return;
    void(^completion)(TGCryptoPricesInfo *pricesInfo) = ^(TGCryptoPricesInfo *pricesInfo) {
        if (_pageUpdateBlock != NULL)
            _pageUpdateBlock(pricesInfo);
        _updatePricesTimer = [NSTimer scheduledTimerWithTimeInterval:pricesInfo != nil ? 60 : 10
                                                              target:self
                                                            selector:@selector(requestPage)
                                                            userInfo:@(pricesInfo == nil)
                                                             repeats:NO];
    };
    [self loadCurrencies:^(BOOL success) {
        if (!success || _pageUpdateBlock == NULL) {
            completion(nil);
            return;
        }
        _updatePricesDataTask = [_livecoinSessionManager GET:@"bettergram/coins"
                                     parameters:@{
                                                  @"sort":[self sortParamForSorting:_pricePageInfo.sorting],
                                                  @"order":[self orderParamForSorting:_pricePageInfo.sorting],
                                                  @"offset":@(_pricePageInfo.offset),
                                                  @"limit":@(_pricePageInfo.favorites ? 0 : _pricePageInfo.limit),
                                                  @"favorites":_pricePageInfo.favorites ? [_favoriteCurrencyCodes componentsJoinedByString:@","] : @"",
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
                                                                                                            favorites:_pricePageInfo.favorites];
                                            if (pricesInfo != nil) {
                                                completion(pricesInfo);
                                                return;
                                            }
                                            // new coin added case
                                            [self loadCurrencies:^(BOOL success) {
                                                if (!success) {
                                                    _lastUpdateDate = 0;
                                                    completion(nil);
                                                    return;
                                                }
                                                completion([[TGCryptoPricesInfo alloc] initWithJSON:responseObject
                                                                                 ignoreUnknownCoins:YES
                                                                                          favorites:_pricePageInfo.favorites]);
                                            }
                                                           force:YES];
                                        } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                                  [self checkResponceIfAPIIsOutOfDate:task.response];
                                            TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                            completion(nil);
                                        }];
        _updatePricesDataTask.priority = NSURLSessionTaskPriorityHigh;
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
            return @"name";
            
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
}

- (void)loadCurrencies:(void (^)(BOOL success))completion
{
    [self loadCurrencies:completion force:NO];
}

- (void)loadCurrencies:(void (^)(BOOL success))completion force:(BOOL)force
{
    __weak static NSURLSessionDataTask *getCurrenciesTask = nil;
    static NSMutableArray<void (^)(BOOL)> *pendingBlocks = nil;
    if (getCurrenciesTask != nil) {
        if (pendingBlocks == nil) {
            pendingBlocks = [NSMutableArray array];
        }
        [pendingBlocks addObject:[completion copy]];
        return;
    }
    if (!force && _currencies != nil && NSDate.date.timeIntervalSince1970 - _lastUpdateDate < kDaySecons) {
        completion(YES);
        return;
    }
    if (_apiOutOfDate) {
        completion(NO);
        return;
    }
    void(^allBlocks)(BOOL success) = ^(BOOL success) {
        TGDispatchOnMainThread(^{
            completion(success);
            if (pendingBlocks != nil) {
                for (void (^block)() in pendingBlocks) {
                    block(success);
                }
                pendingBlocks = nil;
            }
        });
    };
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
                                                     allBlocks(YES);
                                                 }
                                                 else {
                                                     allBlocks(NO);
                                                 }
                                             } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                 [self checkResponceIfAPIIsOutOfDate:task.response];
                                                 TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                                 allBlocks(NO);
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

- (void)checkResponceIfAPIIsOutOfDate:(NSURLResponse *)response
{
    if (!_apiOutOfDate &&
        [response isKindOfClass:[NSHTTPURLResponse class]] &&
        ((NSHTTPURLResponse *)response).statusCode == 410)
    {
        _apiOutOfDate = YES;
        [NSNotificationCenter.defaultCenter postNotificationName:TGCryptoManagerAPIOutOfDate object:nil];
    }
}

@end


@implementation TGCryptoNumberFormatter

- (NSString *)stringFromNumber:(NSNumber *)number
{
    switch (self.numberStyle) {
        case NSNumberFormatterCurrencyStyle:
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
            break;
            
        case NSNumberFormatterPercentStyle:
            
            break;
            
        default:
            break;
    }
    static NSArray* units;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        units = @[@"k",@"M",@"B",@"T",@"P",@"E"];
    });
    BOOL isPrecents = self.numberStyle == NSNumberFormatterPercentStyle;
    NSUInteger exp = (NSUInteger)(log10l(number.doubleValue * (isPrecents ? 100 : 1)) / 3.f);
    if (exp - 1 < units.count)
        return [NSString stringWithFormat:@"%@ %@", [super stringFromNumber:@(number.doubleValue / pow(1000, exp))], units[exp-1]];
    return [super stringFromNumber:number];
}

@end
