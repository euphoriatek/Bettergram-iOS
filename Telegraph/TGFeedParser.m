//
//  TGFeedParser.m
//  Bettergram
//
//  Created by Dukhov Philip on 10/13/18.
//

#import "TGFeedParser.h"

#import "TGCryptoManager.h"
#import <AFNetworking/AFNetworking.h>
#import <HTMLReader/HTMLReader.h>

static NSTimeInterval const kRssUpdateInterval = 60 * 20;


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
    
    BOOL _unreadCountUpdateRequested;
    
    void (^_forceUpdateCompletion)();
}

@property (nonatomic, assign) NSUInteger requestedParsers;

@end


@implementation TGFeedParser

- (instancetype)initWithKey:(NSString *)key
{
    if (self = [super init]) {
        _processingQueue = dispatch_queue_create("FeedParserProcessingQueue", NULL);
        _httpParserSessionManager = [AFHTTPSessionManager.alloc init];
        _httpParserSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _parsersOldestDate = [NSMutableDictionary dictionary];
        _key = key;
        _lastReportedFeedItemIndex = NSNotFound;
        _feedItems = [self cachedFeedItemsForRssKey:key].mutableCopy;
        NSTimeInterval lastReadDate = [NSUserDefaults.standardUserDefaults doubleForKey:self.lastReadDateKey];
        self.lastReadDate = lastReadDate > 0 ? [NSDate dateWithTimeIntervalSince1970:lastReadDate] : NSDate.date;
        
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
                                                   selector:@selector(reachabilityStatusChanged)
                                                       name:AFNetworkingReachabilityDidChangeNotification
                                                     object:nil];
        }];
    }
    return self;
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
    if (_unreadCount == unreadCount) return;
    _unreadCount = unreadCount;
    if (!_unreadCountUpdateRequested && _unreadCountUpdatedBlock != NULL) {
        _unreadCountUpdateRequested = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            _unreadCountUpdateRequested = NO;
            if (_unreadCountUpdatedBlock != NULL) {
                _unreadCountUpdatedBlock();
            }
        });
    }
}

- (void)setRequestedParsers:(NSUInteger)requestedParsers
{
    if (_requestedParsers == requestedParsers) return;
    _requestedParsers = requestedParsers;
    if (requestedParsers == 0 && _forceUpdateCompletion != NULL) {
        _forceUpdateCompletion();
        _forceUpdateCompletion = NULL;
    }
}

- (void)forceUpdate:(void (^)())completion
{
    [self initTimer];
    _forceUpdateCompletion = completion;
}

- (void)initTimer
{
    [_globalTimer invalidate];
    _globalTimer = [NSTimer scheduledTimerWithTimeInterval:kRssUpdateInterval repeats:YES block:^(__unused NSTimer * _Nonnull timer) {
        for (MWFeedParser *parser in _feedParsers) {
            [parser stopParsing];
        }
        self.requestedParsers = _feedParsers.count;
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
    if (date.timeIntervalSinceNow > kRssUpdateInterval)
        [self initTimer];
}

- (NSString *)lastReadDateKey
{
    return [NSString stringWithFormat:@"lastRead%@Date",_key];
}

- (void)setLastReadDate:(NSDate *)lastReadDate
{
    if (_lastReadDate != nil && [_lastReadDate compare:lastReadDate] != NSOrderedAscending) return;
    _lastReadDate = lastReadDate;
    [NSUserDefaults.standardUserDefaults setDouble:lastReadDate.timeIntervalSince1970 forKey:self.lastReadDateKey];
    self.unreadCount = 0;
    [_feedItems enumerateObjectsUsingBlock:^(MWFeedItem * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if ([_lastReadDate compare:obj.date] == NSOrderedAscending) {
            self.unreadCount++;
        }
    }];
}

- (MWFeedParser *)parserWithFeedURLString:(NSString *)urlString
{
    MWFeedParser *feedParser = [MWFeedParser.alloc initWithFeedURL:[NSURL URLWithString:urlString]];
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
    if ([_lastReadDate compare:item.date] == NSOrderedAscending) {
        self.unreadCount++;
    }
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
                                              if ([_lastReadDate compare:obj.date] == NSOrderedAscending) {
                                                  self.unreadCount--;
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
    else {
        [_updateFeedTimer invalidate];
        _updateFeedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reportNewFeedItems) userInfo:nil repeats:NO];
    }
    self.requestedParsers--;
}

- (void)feedParser:(MWFeedParser *)__unused parser didFailWithError:(NSError *)__unused error
{
    self.requestedParsers--;
    if (_forceUpdateCompletion != NULL) {
        _forceUpdateCompletion();
        _forceUpdateCompletion = NULL;
    }
    if (_globalTimer.fireDate.timeIntervalSinceNow > 30)
        [NSTimer scheduledTimerWithTimeInterval:30 repeats:NO block:^(__unused NSTimer * _Nonnull timer) {
            [self initTimer];
        }];
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
                                         if ([_lastReadDate compare:obj.date] == NSOrderedAscending) {
                                             self.unreadCount--;
                                         }
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
