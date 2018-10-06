//
//  TGCryptoCoinInfo.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import <Foundation/Foundation.h>

@class TGCryptoCurrency;

@interface TGCryptoCoinInfo : NSObject

@property (readonly, nonatomic, strong) TGCryptoCurrency *currency;
@property (readonly, nonatomic, assign) double volume;
@property (readonly, nonatomic, assign) double cap;
@property (readonly, nonatomic, assign) NSInteger rank;
@property (readonly, nonatomic, assign) double price;
@property (readonly, nonatomic, assign) double minDelta;
@property (readonly, nonatomic, assign) double dayDelta;

- (instancetype)initWithJSON:(NSDictionary *)dictionary;

@end
