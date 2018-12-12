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
        
    AFHTTPSessionManager *_mailchimpSessionManager;
    AFNetworkReachabilityManager *_reachabilityManager;
    
    NSMutableDictionary<NSIndexSet *, NSURLSessionDataTask *> *_updatePricesDataTasks;
    __weak NSTimer *_updatePricesTimer;
    
    TGCryptoPricesInfo *_pricesInfo;
    __weak NSTimer *_archivePricesInfoTimer;
    
    SMetaDisposable *_subscriptionDisposable;
    
    void (^_statsUpdateBlock)(TGCryptoPricesInfo *pricesInfo);
    void (^_pageUpdateBlock)(TGCryptoPricesInfo *pricesInfo);
}

@property (nonatomic, strong) NSArray<TGCryptoCurrency *> *searchResults;

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
        _updatePricesDataTasks = [NSMutableDictionary dictionary];
        
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
            TGLogCMD(@"TGCMError parsing error: %@",groups);
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
        [NSTimer scheduledTimerWithTimeInterval:kDaySecons + newsModificationDate.timeIntervalSinceNow
                                        repeats:NO
                                          block:^(__unused NSTimer * _Nonnull timer) {
                                              [self updateBettergramResourceForKey:key completion:completion];
                                          }];
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
                                   TGLogCMD(@"TGCMError parsing error: %@",responseObject);
                                   return;
                               }
                               completion(json);
                               [NSKeyedArchiver archiveRootObject:json toFile:filePath];
                               [NSTimer scheduledTimerWithTimeInterval:kDaySecons
                                                               repeats:NO
                                                                 block:^(__unused NSTimer * _Nonnull timer) {
                                                                     [self updateBettergramResourceForKey:key completion:completion];
                                                                 }];
                           } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                               TGLogCMD(@"TGCMError error: %@",error);
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
                         @"livecoinwatchofficial",
                         @"bettergramchannel",
                         @"bgsecuritytokens"
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

- (void)updateStats
{
    if (_pricesInfo.statsUpdatedDate + kPricesUpdateInterval > NSDate.date.timeIntervalSince1970) {
        return;
    }
    [_livecoinSessionManager GET:@"stats"
                      parameters:@{@"currency":self.selectedCurrency.code ?: @"USD"}
                         headers:nil
                        progress:nil
                         success:^(__unused NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
         responseObject = [responseObject cleanedJSON];
         if (responseObject == nil ||
             ![responseObject isKindOfClass:[NSDictionary class]] ||
             ![[responseObject objectForKey:kSuccessKey] boolValue])
         {
             TGLogCMD(@"TGCMError invalid response: %@",responseObject);             
             return;
         }
         [_pricesInfo updateStatsWithJSON:responseObject];
         if (_statsUpdateBlock != NULL) {
             _statsUpdateBlock(_pricesInfo);
         }
     }
                         failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
                             if (error.code == NSURLErrorCancelled) return;
                             [self checkResponceIfAPIIsOutOfDate:task.response];
                             TGLogCMD(@"TGCMError error: %@",error);
                         }];
}

- (void)forceUpdatePrices
{
    [_pricesInfo resetDateForSorting:_pricePageInfo.isFavorited ? TGSortingFavoritedKey.integerValue : _pricePageInfo.sorting];
    [self cancelPriceRequests];
    [self requestPage];
}

- (void)setPricePageInfo:(TGCryptoPricePageInfo *)pricePageInfo
{
    if (TGObjectCompare(_pricePageInfo, pricePageInfo)) {
        return;
    }
    BOOL sortingUpdated = _pricePageInfo.sorting != pricePageInfo.sorting || _pricePageInfo.isFavorited != pricePageInfo.isFavorited;
    if (_pricePageInfo.sorting == TGSortingSearch && _pricePageInfo.sorting != pricePageInfo.sorting) {
        [_pricesInfo updateSearchResults:nil];
    }
    _pricePageInfo = pricePageInfo;
    if (sortingUpdated) {
        [_updatePricesDataTasks.allValues makeObjectsPerformSelector:@selector(cancel)];
        [_updatePricesDataTasks removeAllObjects];
        if (pricePageInfo.isFavorited) {
            [_pricesInfo sortFavoritedWithSorting:pricePageInfo.sorting];
        }
    }
    if (_pageUpdateBlock != NULL) {
        if (sortingUpdated) {
            _pageUpdateBlock(_pricesInfo.copy);
        }
        [self requestPage];
    }
}

- (void)setStatsUpdateBlock:(void (^)(TGCryptoPricesInfo *))statsUpdateBlock pageUpdateBlock:(void (^)(TGCryptoPricesInfo *))pageUpdateBlock
{
    _statsUpdateBlock = [statsUpdateBlock copy];
    _pageUpdateBlock = [pageUpdateBlock copy];
    if (statsUpdateBlock != NULL || pageUpdateBlock != NULL) {
        TGCryptoPricesInfo *pricesInfo = _pricesInfo.copy;
        if (statsUpdateBlock != NULL)
            statsUpdateBlock(pricesInfo);
        if (pageUpdateBlock != NULL)
            pageUpdateBlock(pricesInfo);
        [self requestPage];
    }
    else {
        [self cancelPriceRequests];
    }
}

- (void)requestPage
{
    if (_apiOutOfDate || _pageUpdateBlock == NULL) return;
    if (!NSThread.currentThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestPage];
        });
        return;
    }
    [_updatePricesTimer invalidate];
    
    TGCryptoPricePageInfo *pricePageInfo = _pricePageInfo;
    
    NSMutableArray<TGCryptoCurrency *> *requestingCurrencies = [NSMutableArray array];
    if (_pricePageInfo.sorting == TGSortingSearch) {
        NSArray<TGCryptoCurrency *> *searchResults = nil;
        if (_pricePageInfo.searchString.length >= 2) {
            NSArray<TGCryptoCurrency *> *currencies = _currencies.allValues;
            if (_pricePageInfo.isFavorited) {
                currencies = [currencies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TGCryptoCurrency * _Nullable evaluatedObject,
                                                                                              __unused NSDictionary<NSString *,id> * _Nullable bindings)
                                                         {
                                                             return evaluatedObject.favorite;
                                                         }]];
            }
            searchResults = [currencies filteredArrayUsingMatchingString:_pricePageInfo.searchString
                                                               levenshteinMatchGain:3
                                                                        missingCost:1
                                                                   fieldGetterBlock:^NSArray<NSString *> *(TGCryptoCurrency *obj) {
                                                                       if (obj.type == TGCryptoCurrencyTypeCoin) {
                                                                           return @[ obj.name, obj.code ];
                                                                       }
                                                                       return nil;
                                                                   }
                                                                          threshold:0.5
                                                                equalCaseComparator:^NSComparisonResult(TGCryptoCurrency *obj1, TGCryptoCurrency *obj2) {
                                                                    return [@(obj1.rank) compare:@(obj2.rank)];
                                                                }];
            [searchResults enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                if ([obj updatedDateForSorting:pricePageInfo.sorting] + kPricesUpdateInterval / 3 < NSDate.date.timeIntervalSince1970)
                {
                    [requestingCurrencies addObject:obj];
                }
            }];
        }
        [_pricesInfo updateSearchResults:searchResults];
        if (_pageUpdateBlock != NULL && (requestingCurrencies.count != 0 || searchResults.count == 0)) {
            _pageUpdateBlock(_pricesInfo.copy);
        }
        if (searchResults.count == 0) {
            return;
        }
        pricePageInfo.offset = 0;
        pricePageInfo.limit = requestingCurrencies.count;
    }
    else if (_pricePageInfo.isFavorited) {
        [_currencies enumerateKeysAndObjectsUsingBlock:^(__unused NSString * _Nonnull key, TGCryptoCurrency * _Nonnull obj, __unused BOOL * _Nonnull stop)
         {
             if (obj.favorite &&
                 [obj updatedDateForSorting:pricePageInfo.sorting] + kPricesUpdateInterval / 3 < NSDate.date.timeIntervalSince1970)
             {
                 [requestingCurrencies addObject:obj];
             }
         }];
        pricePageInfo.offset = 0;
        pricePageInfo.limit = requestingCurrencies.count;
    }
    else {
        NSMutableIndexSet *missingIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(pricePageInfo.offset, pricePageInfo.limit)];
        [_updatePricesDataTasks.allKeys enumerateObjectsUsingBlock:^(NSIndexSet * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [missingIndexes removeIndexes:obj];
        }];
        NSIndexSet *enumerationIndexes = [missingIndexes indexesPassingTest:^BOOL(NSUInteger idx, __unused BOOL * _Nonnull stop) {
            return idx < _pricesInfo.coinInfos[@(pricePageInfo.sorting)].count;
        }];
        [_pricesInfo.coinInfos[@(pricePageInfo.sorting)] enumerateObjectsAtIndexes:enumerationIndexes
                                                                           options:0
                                                                        usingBlock:^(TGCryptoCurrency * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop)
         {
             if ([obj updatedDateForSorting:pricePageInfo.sorting] + kPricesUpdateInterval / 3 > NSDate.date.timeIntervalSince1970) {
                 [missingIndexes removeIndex:idx];
             }
             else if (obj.code != nil) {
                 [requestingCurrencies addObject:obj];
             }
         }];
        NSUInteger limit = missingIndexes.lastIndex - missingIndexes.firstIndex + 1;
        if (missingIndexes.count == 0 || limit < pricePageInfo.limit / 3) {
            pricePageInfo.limit = 0;
            [requestingCurrencies removeAllObjects];
        }
        else {
            pricePageInfo.offset = missingIndexes.firstIndex;
            pricePageInfo.limit = limit;
        }
    }
    __block BOOL invalidatedCoins = NO;
    __block NSIndexSet *indexSet = nil;
    void(^completion)(BOOL) = ^(BOOL updated) {
        if (indexSet != nil)
            [_updatePricesDataTasks removeObjectForKey:indexSet];
        if (_pageUpdateBlock != NULL) {
            _pageUpdateBlock(updated ? _pricesInfo.copy : nil);
            if (invalidatedCoins) {
                [self requestPage];
            }
            else {
                [_updatePricesTimer invalidate];
                _updatePricesTimer = [NSTimer scheduledTimerWithTimeInterval:updated ? kPricesUpdateInterval : kPricesUpdateInterval / 6
                                                                      target:self
                                                                    selector:@selector(requestPage)
                                                                    userInfo:@(updated)
                                                                     repeats:NO];
            }
        }
    };
    [self updateStats];
    if (pricePageInfo.limit + requestingCurrencies.count == 0)
    {
        completion(_pricePageInfo.sorting == TGSortingSearch);
        return;
    }
    if ([self loadCurrenciesIfNeeded:NULL]) {
        return;
    }
    
    NSMutableDictionary *parameters = @{
                                        @"sort":[self sortParamForSorting:pricePageInfo.sorting],
                                        @"order":[self orderParamForSorting:pricePageInfo.sorting],
                                        @"currency":self.selectedCurrency.code ?: @"USD",
                                        @"limit": @(pricePageInfo.limit),
                                        @"offset": @(pricePageInfo.offset),
                                        }.mutableCopy;
    if (_pricePageInfo.isFavorited || _pricePageInfo.sorting == TGSortingSearch) {
        NSMutableArray<NSString *> *requestedCurrencyCodes = [NSMutableArray array];
        [requestingCurrencies enumerateObjectsUsingBlock:^(TGCryptoCurrency * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [requestedCurrencyCodes addObject:obj.code];
        }];
        parameters[@"only"] = [requestedCurrencyCodes componentsJoinedByString:@","];
    }
    TGLogCMD(@"request sent: %@",parameters);
    indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(pricePageInfo.offset, pricePageInfo.limit)];
    NSURLSessionDataTask *updatePricesDataTask =
    [_livecoinSessionManager GET:@"coins"
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
             TGLogCMD(@"TGCMError invalid response: %@",responseObject);
             completion(NO);
             return;
         }
         NSArray<TGCryptoCurrency *> *newCoins = [_pricesInfo updateValuesWithJSON:responseObject
                                                                          pageInfo:pricePageInfo
                                                                  invalidatedCoins:&invalidatedCoins];
         if (newCoins.count > 0) {
             // new coin added case
             NSMutableDictionary<NSString *, TGCryptoCurrency *> *newCurrencies = _currencies.mutableCopy;
             for (TGCryptoCurrency *newCoin in newCoins) {
                 if (newCoin.code == nil || newCurrencies[newCoin.code] != nil) continue;
                 newCurrencies[newCoin.code] = newCoin;
             }
             if (newCurrencies.count > 0) {
                 _currencies = newCurrencies.copy;
             }
         }
         if (newCoins.count == 0 || _lastUpdateDate + 60 > NSDate.date.timeIntervalSince1970) {
             completion(YES);
             [self setNeedsArchiveFeedItems];
             return;
         }
         _lastUpdateDate = 0;
         [NSUserDefaults.standardUserDefaults removeObjectForKey:kLastUpdateCurrenciesDateKey];
         [self loadCurrenciesIfNeeded:^(BOOL success) {
             [self setNeedsArchiveFeedItems];
             completion(success);
         }];
     }
                         failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
                             if (error.code == NSURLErrorCancelled) return;
                             [self checkResponceIfAPIIsOutOfDate:task.response];
                             TGLogCMD(@"TGCMError error: %@",error);
                             completion(NO);
                         }];
    updatePricesDataTask.priority = NSURLSessionTaskPriorityHigh;
    _updatePricesDataTasks[indexSet] = updatePricesDataTask;
}

- (NSString *)orderParamForSorting:(TGCoinSorting)sorting
{
    switch (sorting) {
        case TGSortingCoinDescending:
        case TGSortingPriceDescending:
        case TGSorting24hDescending:
            return @"descending";
            
        default:
            return @"ascending";
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
            
        case TGSortingSearch:
            return @"none";
            
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
    if (_pricePageInfo.isFavorited && !favorite && _pageUpdateBlock != NULL) {
        _pageUpdateBlock(_pricesInfo.copy);
    }
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

- (BOOL)loadCurrenciesIfNeeded:(void (^)(BOOL success))completion
{
    __weak static NSURLSessionDataTask *getCurrenciesTask = nil;
    static NSMutableArray<void (^)(BOOL)> *pendingBlocks = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pendingBlocks = [NSMutableArray array];
    });
    if (getCurrenciesTask != nil) {
        if (completion != NULL) {
            TGDispatchOnMainThread(^{
                [pendingBlocks addObject:[completion copy]];
            });
        }
        return NO;
    }
    if (_currencies != nil && _lastUpdateDate + kDaySecons > NSDate.date.timeIntervalSince1970) {
        if (completion != NULL) {
            completion(YES);
        }
        return NO;
    }
    if (_apiOutOfDate) {
        if (completion != NULL) {
            completion(NO);
        }
        return NO;
    }
    if (completion != NULL) {
        [pendingBlocks addObject:[completion copy]];
    }
    void(^allBlocks)(BOOL success) = ^(BOOL success) {
        TGDispatchOnMainThread(^{
            for (void (^block)() in pendingBlocks) {
                block(success);
            }
            [pendingBlocks removeAllObjects];
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
                                                 [self requestPage];
                                             } failure:^(__unused NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                 [self checkResponceIfAPIIsOutOfDate:task.response];
                                                 TGLogCMD(@"TGCMError error: %@",error);
                                                 allBlocks(NO);
                                             }];
    getCurrenciesTask.priority = NSURLSessionTaskPriorityHigh;
    return YES;
}

- (BOOL)parseCurrenciesResponseObject:(id)responseObject
{
    NSArray *data = nil;
    NSString *coinsUrlBase = nil, *coinsIcon64Base = nil, *flagsIcon64Base = nil;
    if (responseObject == nil ||
        ![responseObject isKindOfClass:[NSDictionary class]] ||
        ![[responseObject objectForKey:kSuccessKey] boolValue] ||
        !(coinsUrlBase = [responseObject objectForKey:@"coinsUrlBase"]) ||
        !(coinsIcon64Base = [responseObject objectForKey:@"coinsIcon64Base"]) ||
        !(flagsIcon64Base = [responseObject objectForKey:@"flagsIcon64Base"]) ||
        !(data = [responseObject objectForKey:kDataKey]) ||
        ![data isKindOfClass:[NSArray class]])
    {
        TGLogCMD(@"TGCMError invalid response: %@",responseObject);
        return NO;
    }
    NSMutableDictionary<NSString *, TGCryptoCurrency *> *currencies = [NSMutableDictionary dictionary];
    for (NSDictionary *coinDictionary in data) {
        if (![coinDictionary isKindOfClass:[NSDictionary class]]) {
            TGLogCMD(@"TGCMError invalid response[data][i]: %@",coinDictionary);
            continue;
        }
        NSString *code = coinDictionary[@"code"];
        TGCryptoCurrency *cryptoCurrency = _currencies[code] ?: [TGCryptoCurrency.alloc initWithCode:code];
        [cryptoCurrency fillWithCurrencyJson:coinDictionary baseURL:coinsUrlBase baseIconURLGenerator:^NSString *(TGCryptoCurrencyType type) {
            switch (type) {
                case TGCryptoCurrencyTypeCoin:
                    return coinsIcon64Base;
                    
                case TGCryptoCurrencyTypeFiat:
                    return flagsIcon64Base;
                    
                default:
                    return nil;
            }
        }];
        
        currencies[cryptoCurrency.code] = cryptoCurrency;
    }
    _currencies = currencies.copy;
    return YES;
}

- (TGCryptoCurrency *)cachedCurrencyWithCode:(NSString *)code
{
    return _currencies[code];
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

- (void)cancelPriceRequests
{
    [_updatePricesTimer invalidate];
    [_updatePricesDataTasks.allValues makeObjectsPerformSelector:@selector(cancel)];
    [_updatePricesDataTasks removeAllObjects];
}

@end
