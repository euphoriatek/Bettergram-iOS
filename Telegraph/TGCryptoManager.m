//
//  TGCryptoManager.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import "TGCryptoManager.h"

#import <AFNetworking/AFNetworking.h>
#import <LegacyComponents/LegacyComponents.h>
#import "TGResourceSection.h"
#import "../../config.h"

#import "TGGlobalMessageSearchSignals.h"
#import "TGChannelManagementSignals.h"
#import "TGTelegraph.h"

NSString * const TGCryptoManagerAPIOutOfDate = @"TGCryptoManagerAPIOutOfDate";

static NSString *const kSuccessKey = @"success";
static NSString *const kDataKey = @"data";

static NSString *const kLastUpdateCurrenciesDateKey = @"Crypto.LastUpdateCurrenciesDateKey";
static NSString *const kSelectedCurrencyCodeKey = @"Crypto.SelectedCurrencyCodeKey";
static NSString *const kFavoriteCodesKey = @"Crypto.FavoriteCodesKey";

static NSString *const kImageKey = @"image";
static NSString *const kDateKey = @"date";

static NSTimeInterval const kDaySecons = 24 * 60 * 60;
NSTimeInterval const kPricesUpdateInterval = 60;

#define USER_DEFAULTS_KEY_WITH_LIST_ID(listID) [NSString stringWithFormat:@"cachedEmailForListID-%@", listID]


@interface TGCryptoManager () {
    AFHTTPSessionManager *_livecoinSessionManager;
    AFHTTPSessionManager *_bettergramSessionManager;
    NSDictionary<NSString *, TGCryptoCurrency *> *_currencies;
    NSTimeInterval _lastUpdateDate;
    
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *_httpHeaderImageURLs;
    
    AFHTTPSessionManager *_mailchimpSessionManager;
    AFNetworkReachabilityManager *_reachabilityManager;
    
    NSURLSessionDataTask *_updatePricesDataTask;
    __weak NSTimer *_updatePricesTimer;
    
    TGCryptoPricesInfo *_pricesInfo;
    __weak NSTimer *_archivePricesInfoTimer;
    
    SMetaDisposable *_subscriptionDisposable;
}

@end


@implementation TGCryptoManager

+ (instancetype)manager {
    static TGCryptoManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [self.alloc init];
    });
    return sharedMyManager;
}

- (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _reachabilityManager = [AFNetworkReachabilityManager managerForDomain:@"api.bettergram.io"];
        [_reachabilityManager startMonitoring];
        __weak TGCryptoManager *weakSelf = self;
        [_reachabilityManager setReachabilityStatusChangeBlock:^(__unused AFNetworkReachabilityStatus status) {
            __strong TGCryptoManager *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf->_reachabilityManager.isReachable && [strongSelf->_updatePricesTimer.userInfo boolValue])
                [strongSelf->_updatePricesTimer fire];
        }];
        
        _livecoinSessionManager = [AFHTTPSessionManager.alloc initWithBaseURL:[NSURL URLWithString:@"https://http-api.livecoinwatch.com/"]];
        _bettergramSessionManager = [AFHTTPSessionManager.alloc initWithBaseURL:[NSURL URLWithString:@"https://api.bettergram.io/v1/"]];
        
        NSDictionary *responseObject = [NSKeyedUnarchiver unarchiveObjectWithFile:[self currenciesResponseObjectFile]];
        if ([responseObject isKindOfClass:[NSDictionary class]])
        {
            if ([responseObject.allValues.firstObject isKindOfClass:[TGCryptoCurrency class]]) {
                _currencies = responseObject;
            }
            else {
                [self parseCurrenciesResponseObject:responseObject];
            }
        }
        _lastUpdateDate = [NSUserDefaults.standardUserDefaults doubleForKey:kLastUpdateCurrenciesDateKey];
        _pricesInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pricesInfoCacheFile]] ?: [TGCryptoPricesInfo.alloc init];
        [AFNetworkReachabilityManager.sharedManager startMonitoring];
    });
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
            [resourceSections addObject:[TGResourceSection.alloc initWithJSON:json]];
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
        _mailchimpSessionManager = [AFHTTPSessionManager.alloc initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.api.mailchimp.com/3.0/",dataCenterKey]]];
        _mailchimpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_mailchimpSessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"anystring" password:mailchimpAPIKey];
        _mailchimpSessionManager.responseSerializer.acceptableContentTypes = [_mailchimpSessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/problem+json"];
    }
    for (NSString *listID in info)
        [_mailchimpSessionManager POST:[NSString stringWithFormat:@"lists/%@/members",listID]
                            parameters:@{@"email_address":info[listID], @"status":@"subscribed"}
                               headers:nil
                              progress:^(__unused NSProgress * _Nonnull uploadProgress) {}
                               success:^(__unused NSURLSessionDataTask * _Nonnull task, __unused id  _Nullable responseObject) {
                                   [NSUserDefaults.standardUserDefaults removeObjectForKey:USER_DEFAULTS_KEY_WITH_LIST_ID(listID)];
                               } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                   id data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                                   if ([data isKindOfClass:[NSData class]]) {
                                       NSString *string = [NSString.alloc initWithData:data encoding:0];
                                       if ([string containsString:@"Member Exists"] || [string containsString:@"is already a list member"]) {
                                           [NSUserDefaults.standardUserDefaults removeObjectForKey:USER_DEFAULTS_KEY_WITH_LIST_ID(listID)];
                                       }
                                   }
                               }];
}

- (void)subscribeToChannelsIfNeeded
{
#ifndef DEBUG
    [self addUsernames:@[
                         @"bettergramapp",
                         ]
               atIndex:0];
#endif
}

- (void)addUsernames:(NSArray<NSString *> *)usernames atIndex:(NSUInteger)index
{
    if (TGTelegraphInstance.clientUserId == 0 || index >= usernames.count) return;
    NSString *username = usernames[index];
    __weak TGCryptoManager *weakSelf = self;
    if (_subscriptionDisposable == nil)
        _subscriptionDisposable = [[SMetaDisposable alloc] init];
    __block id<SDisposable> pendingDisposable = nil;
    void(^completion)(id<SDisposable> disposable) = ^(id<SDisposable> disposable) {
        __strong TGCryptoManager *strongSelf = weakSelf;
        if (disposable) {
            [strongSelf->_subscriptionDisposable setDisposable:pendingDisposable];
        }
        else {
            [strongSelf addUsernames:usernames atIndex:index + 1];
        }
    };
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@:%@",@(TGTelegraphInstance.clientUserId),username];
    if ([NSUserDefaults.standardUserDefaults boolForKey:userDefaultsKey]) {
        completion(nil);
        return;
    }
    void(^next)(id) = ^(id result) {
        TGDispatchOnMainThread(^{
            for (id key in result) for (id peer in result[key]) if ([peer isKindOfClass:[TGConversation class]]) {
                TGConversation *conversation = peer;
                if (conversation.username == nil ||
                    [conversation.username caseInsensitiveCompare:username] != NSOrderedSame) {
                    continue;
                }
                if (conversation.kind != TGConversationKindTemporaryChannel)
                    return;
                pendingDisposable = [[[TGChannelManagementSignals joinTemporaryChannel:conversation.conversationId] deliverOn:[SQueue mainQueue]]
                                     startWithNext:NULL
                                     error:^(__unused id error) {
                                         completion(nil);
                                     } completed:^{
                                         [NSUserDefaults.standardUserDefaults setBool:YES
                                                                               forKey:userDefaultsKey];
                                         completion(nil);
                                     }];
                return;
            }
        });
    };
    [_subscriptionDisposable setDisposable:[[TGGlobalMessageSearchSignals search:username
                                                                  includeMessages:NO
                                                                      itemMapping:^id(id item){
                                                                          return item;
                                                                      }]
                                            startWithNext:next
                                            error:^(__unused id error){
                                                completion(pendingDisposable);
                                            }
                                            completed:^{
                                                completion(pendingDisposable);
                                            }]];
}

#pragma mark - Coins

- (void)setPricePageInfo:(TGCryptoPricePageInfo)pricePageInfo
{
    BOOL sortingUpdated = _pricePageInfo.sorting != pricePageInfo.sorting;
    _pricePageInfo = pricePageInfo;
    if (sortingUpdated && isset(&pricePageInfo.sorting, TGSortingFavoritedBit)) {
        [_pricesInfo sortFavoritedWithSorting:pricePageInfo.sorting];
    }
    if (_pageUpdateBlock != NULL) {
        if (sortingUpdated)
            _pageUpdateBlock(_pricesInfo.copy);
        [self requestPage];
    }
}

- (void)setPageUpdateBlock:(void (^)(TGCryptoPricesInfo *))pageUpdateBlock
{
    _pageUpdateBlock = [pageUpdateBlock copy];
    if (pageUpdateBlock != NULL) {
        _pageUpdateBlock(_pricesInfo.copy);
        [self requestPage];
    }
    else {
        [_updatePricesDataTask cancel];
        [_updatePricesTimer invalidate];
    }
}

- (void)requestPage
{
    if (_apiOutOfDate) return;
    if (!NSThread.currentThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestPage];
        });
        return;
    }
    [_updatePricesDataTask cancel];
    [_updatePricesTimer invalidate];
    
    TGCryptoPricePageInfo pricePageInfo = _pricePageInfo;
    BOOL favorited = isset(&pricePageInfo.sorting, TGSortingFavoritedBit);
    TGCoinSorting sorting = clredbit(pricePageInfo.sorting, TGSortingFavoritedBit);
    
    __block BOOL updateNeeded = NO;
    NSArray<NSString *> *favoriteCurrencyCodes = nil;
    if (favorited) {
        NSMutableArray<NSString *> *allFavoriteCurrencyCodes = [NSMutableArray array];
        [_currencies enumerateKeysAndObjectsUsingBlock:^(__unused NSString * _Nonnull key, TGCryptoCurrency * _Nonnull obj, __unused BOOL * _Nonnull stop) {
            if (obj.favorite) {
                [allFavoriteCurrencyCodes addObject:obj.code];
            }
        }];
        favoriteCurrencyCodes = [_pricesInfo outOfDateFavoriteCurrencyCodes:allFavoriteCurrencyCodes];
    }
    else {
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(pricePageInfo.offset, pricePageInfo.limit)];
        NSIndexSet *enumerationIndexes = [indexes indexesPassingTest:^BOOL(NSUInteger idx, __unused BOOL * _Nonnull stop) {
            return idx < _pricesInfo.coinInfos[@(pricePageInfo.sorting)].count;
        }];
        if (enumerationIndexes.count > 0) {
            [_pricesInfo.coinInfos[@(pricePageInfo.sorting)] enumerateObjectsAtIndexes:enumerationIndexes
                                                                               options:0
                                                                            usingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, BOOL * _Nonnull stop)
             {
                 if (obj.updatedDate + kPricesUpdateInterval / 3 < NSDate.date.timeIntervalSince1970) {
                     *stop = updateNeeded = YES;
                 }
             }];
        }
        else {
            updateNeeded = YES;
        }
    }
    __block BOOL invalidatedCoins = NO;
    void(^completion)(BOOL) = ^(BOOL updated) {
        if (_pageUpdateBlock != NULL) {
            _pageUpdateBlock(updated ? _pricesInfo.copy : nil);
            if (invalidatedCoins) {
                [self requestPage];
            }
            else {
                [_updatePricesTimer invalidate];
                _updatePricesTimer = [NSTimer scheduledTimerWithTimeInterval:updated ? kPricesUpdateInterval : 10
                                                                      target:self
                                                                    selector:@selector(requestPage)
                                                                    userInfo:@(updated)
                                                                     repeats:NO];
            }
        }
    };
    if (!updateNeeded && favoriteCurrencyCodes.count == 0) {
        completion(NO);
        return;
    }
    [self loadCurrencies:^(BOOL success) {
        if (!success || _pageUpdateBlock == NULL) {
            completion(NO);
            return;
        }
        
        NSMutableDictionary *parameters = @{
                                            @"sort":[self sortParamForSorting:sorting],
                                            @"order":[self orderParamForSorting:sorting],
                                            @"currency":self.selectedCurrency.code ?: @"USD",
                                            }.mutableCopy;
        if (favorited) {
            parameters[@"limit"] = @0;
            parameters[@"favorites"] = [favoriteCurrencyCodes componentsJoinedByString:@","];
        }
        else {
            parameters[@"limit"] = @(pricePageInfo.limit);
            parameters[@"offset"] = @(pricePageInfo.offset);
        }
        _updatePricesDataTask = [_livecoinSessionManager GET:@"bettergram/coins"
                                                  parameters:parameters
                                                     headers:nil
                                                    progress:nil
                                                     success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
                                 {
                                     responseObject = [responseObject cleanedJSON];
                                     if (responseObject == nil ||
                                         ![responseObject isKindOfClass:[NSDictionary class]] ||
                                         ![[responseObject objectForKey:kSuccessKey] boolValue])
                                     {
                                         TGLog(@"TGCMError: Crypto currencies list invalid response: %@",responseObject);
                                         completion(NO);
                                         return;
                                     }
                                     NSArray<TGCryptoCurrency *> *newCoins = [_pricesInfo updateValuesWithJSON:responseObject
                                                                                                      pageInfo:pricePageInfo
                                                                                              invalidatedCoins:&invalidatedCoins];
                                     if (newCoins.count == 0) {
                                         completion(YES);
                                         [self setNeedsArchiveFeedItems];
                                         return;
                                     }
                                     // new coin added case
                                     NSMutableDictionary<NSString *, TGCryptoCurrency *> *newCurrencies = _currencies.mutableCopy;
                                     for (TGCryptoCurrency *newCoin in newCoins) {
                                         if (newCoin.code == nil || newCurrencies[newCoin.code] != nil) continue;
                                         newCurrencies[newCoin.code] = newCoin;
                                     }
                                     if (newCurrencies.count > 0) {
                                         _currencies = newCurrencies.copy;
                                     }
                                     _lastUpdateDate = 0;
                                     [NSUserDefaults.standardUserDefaults removeObjectForKey:kLastUpdateCurrenciesDateKey];
                                     [self loadCurrencies:^(BOOL success) {
                                         [self setNeedsArchiveFeedItems];
                                         completion(success);
                                     }];
                                 }
                                                     failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
                                                         [self checkResponceIfAPIIsOutOfDate:task.response];
                                                         TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                                         completion(NO);
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
            
        default:
            return @"rank";
    }
}

#pragma mark - Currencies

- (void)updateCoin:(TGCryptoCurrency *)coin favorite:(BOOL)favorite
{
    if (coin.favorite == favorite) return;
    coin.favorite = favorite;
    [_pricesInfo coin:coin favorited:favorite];
    [self setNeedsArchiveFeedItems];
}

- (NSArray<TGCryptoCurrency *> *)currencies
{
    NSMutableArray<TGCryptoCurrency *> *currencies = _currencies.allValues.mutableCopy;
    NSMutableArray<NSString *> *topCodes = @[
                                             @"USD",
                                             @"EUR",
                                             @"BTC",
                                             ].mutableCopy; {
                                                 NSString *localeCurrencyCode = [NSLocale currentLocale].currencyCode.uppercaseString;
                                                 NSInteger localeCurrencyCodeIndex = [topCodes indexOfObject:localeCurrencyCode];
                                                 if (localeCurrencyCodeIndex != NSNotFound) {
                                                     if (localeCurrencyCodeIndex != 0) {
                                                         [topCodes removeObjectAtIndex:localeCurrencyCodeIndex];
                                                         [topCodes insertObject:localeCurrencyCode atIndex:0];
                                                     }
                                                 }
                                                 else {
                                                     [topCodes insertObject:localeCurrencyCode atIndex:0];
                                                 }
                                             }
    NSMutableArray<TGCryptoCurrency *> *topCurrencies = [NSMutableArray array];
    NSMutableIndexSet *topCurrencyIndexes = [NSMutableIndexSet indexSet];
    [currencies enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull currency, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if ((currency.updatedDate > 0 && currency.rank < 6) ||
            (currency.code != nil && [topCodes containsObject:currency.code]) ||
            currency.requestsCount > 0)
        {
            [topCurrencies addObject:currency];
            [topCurrencyIndexes addIndex:idx];
        }
    }];
    [currencies removeObjectsAtIndexes:topCurrencyIndexes];
    [topCurrencies sortUsingComparator:^NSComparisonResult(TGCryptoCurrency * _Nonnull obj1, TGCryptoCurrency * _Nonnull obj2) {
        NSComparisonResult requestsCountCoparison = [@(obj2.requestsCount) compare:@(obj1.requestsCount)];
        if (requestsCountCoparison != NSOrderedSame) {
            return requestsCountCoparison;
        }
        if (obj1.rank != 0 && obj1.rank != 0) {
            return [@(obj1.rank) compare:@(obj2.rank)];
        }
        return [@([topCodes indexOfObject:obj1.code]) compare:@([topCodes indexOfObject:obj2.code])];
    }];
    [currencies sortUsingComparator:^NSComparisonResult(TGCryptoCurrency *  _Nonnull obj1, TGCryptoCurrency *  _Nonnull obj2) {
        return [obj1.name compare:obj2.name];
    }];
    [currencies insertObjects:topCurrencies atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, topCurrencies.count)]];
    return currencies;
}

- (void)setSelectedCurrency:(TGCryptoCurrency *)selectedCurrency
{
    if ([_pricesInfo.currency isEqual:selectedCurrency]) return;
    _pricesInfo.currency = selectedCurrency;
    [self requestPage];
}

- (TGCryptoCurrency *)selectedCurrency
{
    return _pricesInfo.currency ?: _currencies[@"USD"];
}

- (void)loadCurrencies:(void (^)(BOOL success))completion
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
    if (_currencies != nil && _lastUpdateDate + kDaySecons > NSDate.date.timeIntervalSince1970) {
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
                                                 BOOL success = [self parseCurrenciesResponseObject:[responseObject cleanedJSON]];
                                                 allBlocks(success);
                                                 _lastUpdateDate = NSDate.date.timeIntervalSince1970;
                                                 [NSUserDefaults.standardUserDefaults setDouble:_lastUpdateDate forKey:kLastUpdateCurrenciesDateKey];
                                             } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                 [self checkResponceIfAPIIsOutOfDate:task.response];
                                                 TGLog(@"TGCMError: Crypto currencies list get error: %@",error);
                                                 allBlocks(NO);
                                             }];
    getCurrenciesTask.priority = NSURLSessionTaskPriorityHigh;
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
    NSMutableDictionary<NSString *, TGCryptoCurrency *> *currencies = [NSMutableDictionary dictionary];
    for (NSDictionary *coinDictionary in data) {
        if (![coinDictionary isKindOfClass:[NSDictionary class]]) {
            TGLog(@"TGCMError: Crypto currencies list invalid response[data][i]: %@",coinDictionary);
            continue;
        }
        NSString *code = coinDictionary[@"code"];
        TGCryptoCurrency *cryptoCurrency = _currencies[code] ?: [TGCryptoCurrency.alloc initWithCode:code];
        [cryptoCurrency fillWithCurrencyJson:coinDictionary];
        
        currencies[cryptoCurrency.code.uppercaseString] = cryptoCurrency;
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

- (NSString *)pricesInfoCacheFile
{
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:@"pricesInfoCache"].path;
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

- (void)setNeedsArchiveFeedItems
{
    TGDispatchOnMainThread(^{
        [_archivePricesInfoTimer invalidate];
        _archivePricesInfoTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                  repeats:NO
                                                                    block:^(__unused NSTimer * _Nonnull timer)
                                   {
                                       [NSKeyedArchiver archiveRootObject:_pricesInfo
                                                                   toFile:self.pricesInfoCacheFile];
                                       [NSKeyedArchiver archiveRootObject:_currencies
                                                                   toFile:self.currenciesResponseObjectFile];
                                   }];
    });
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
