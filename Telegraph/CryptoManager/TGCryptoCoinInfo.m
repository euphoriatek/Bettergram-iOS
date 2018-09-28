//
//  TGCryptoCoinInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoCoinInfo.h"
#import "TGCryptoManager.h"

@implementation TGCryptoCoinInfo

- (instancetype)initWithJSON:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"code"]];
        _volume = [dictionary[@"volume"] doubleValue];
        _cap = [dictionary[@"cap"] doubleValue];
        _rank = [dictionary[@"rank"] integerValue];
        _price = [dictionary[@"price"] doubleValue];

        id dayDelta = dictionary[@"delta"][@"day"];
        if (dayDelta && [dayDelta isKindOfClass:[NSNumber class]]) {
            _dayDelta = [dayDelta doubleValue] - 1;
        }
        
        id minuteDelta = dictionary[@"delta"][@"minute"];
        if (minuteDelta && minuteDelta != [NSNull null]) {
            _minDelta = [minuteDelta doubleValue] - 1;
        }
#if DEBUG
        NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
        [unknownKeys removeObjectsInArray:@[@"code",@"volume",@"cap",@"rank",@"price",@"delta"]];
        if (unknownKeys.count > 0) {
            TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
            return nil;
        }
#endif
    }
    return self;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@; price: %@", [self class], self, _currency.code, @(_price)];
}

//{
//    "code": "BTC",
//    "volume": 512340.70359812863,
//    "cap": 17280211.99995429,
//    "rank": 1,
//    "price": 1,
//    "delta": {
//        "second": 1,
//        "minute": 1,
//        "hour": 1,
//        "day": 1,
//        "week": 1,
//        "month": 1
//    }
//},

@end
