//
//  TGCryptoCurrency.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import <Foundation/Foundation.h>

@interface TGCryptoCurrency : NSObject <NSCoding>

@property (readonly, nonatomic, strong) NSString *code;
@property (readonly, nonatomic, strong) NSString *name;
@property (readonly, nonatomic, strong) NSString *url;
@property (readonly, nonatomic, strong) NSString *symbol;
@property (readonly, nonatomic, strong) NSString *iconURL;

@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) NSUInteger requestsCount;

- (instancetype)initWithCode:(NSString *)code;
- (void)fillWithCurrencyJson:(NSDictionary *)dictionary;
- (BOOL)validateFilter:(NSString *)filter;

// Coin info

@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double cap;
@property (readonly, nonatomic, assign) NSInteger rank;
@property (readonly, nonatomic, assign) double price;
@property (readonly, nonatomic, strong) NSNumber *minDelta;
@property (readonly, nonatomic, strong) NSNumber *dayDelta;

@property (readonly, nonatomic, assign) NSTimeInterval updatedDate;

- (void)fillWithCoinInfoJson:(NSDictionary *)dictionary;
- (void)clean;

@end
