//
//  TGFeedParser.h
//  Bettergram
//
//  Created by Dukhov Philip on 10/13/18.
//

#import <Foundation/Foundation.h>
#import "MWFeedParser.h"

@class MWFeedItem, TGFeedParser;

@protocol TGFeedParserDelegate <NSObject>

- (void)feedParser:(TGFeedParser *)feedParser fetchedItems:(NSArray<MWFeedItem *> *)feedItems;

@end


@interface TGFeedParser : NSObject

@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong, readonly) NSSet<NSString *> *urls;

@property (nonatomic, strong) NSDate *lastReadDate;

@property (nonatomic, weak) id<TGFeedParserDelegate> delegate;

- (instancetype)initWithKey:(NSString *)key;
- (void)setNeedsArchiveFeedItems;
- (NSURLSessionDataTask *)fillFeedItemThumbnailFromOGImage:(MWFeedItem *)feedItem completion:(void (^)(NSString *url))completion;

@end