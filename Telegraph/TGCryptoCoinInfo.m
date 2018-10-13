//
//  TGCryptoCoinInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoCoinInfo.h"
#import "TGCryptoManager.h"

@implementation TGCryptoCoinInfo

- (instancetype)initWithCurrency:(TGCryptoCurrency *)currency
{
    if (self = [super init]) {
        _currency = currency;
    }
    return self;
}

- (instancetype)initWithJSON:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"code"]];
        _volume = [dictionary[@"volume"] doubleValue];
        _cap = [dictionary[@"cap"] doubleValue];
        _rank = [dictionary[@"rank"] integerValue];
        _price = [dictionary[@"price"] doubleValue];

        id dayDelta = dictionary[@"delta"][@"day"];
        if ([dayDelta isKindOfClass:[NSNumber class]]) {
            _dayDelta = @([dayDelta doubleValue] - 1);
        }
        
        id minuteDelta = dictionary[@"delta"][@"minute"];
        if ([minuteDelta isKindOfClass:[NSNumber class]]) {
            _minDelta = @([minuteDelta doubleValue] - 1);
        }
        
        _updatedDate = NSDate.date.timeIntervalSince1970;
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

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:[decoder decodeObjectForKey:@"code"]];
        _volume = [decoder decodeDoubleForKey:@"volume"];
        _cap = [decoder decodeDoubleForKey:@"cap"];
        _rank = [decoder decodeIntegerForKey:@"rank"];
        _price = [decoder decodeDoubleForKey:@"price"];
        _dayDelta = [decoder decodeObjectForKey:@"dayDelta"];
        _minDelta = [decoder decodeObjectForKey:@"minDelta"];
        _updatedDate = [decoder decodeDoubleForKey:@"updatedDate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (_currency) [encoder encodeObject:_currency.code forKey:@"code"];
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_cap forKey:@"cap"];
    [encoder encodeInteger:_rank forKey:@"rank"];
    [encoder encodeDouble:_price forKey:@"price"];
    [encoder encodeObject:_dayDelta forKey:@"dayDelta"];
    [encoder encodeObject:_minDelta forKey:@"minDelta"];
    [encoder encodeDouble:_updatedDate forKey:@"updatedDate"];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@; price: %@", [self class], self, _currency.code, @(_price)];
}

@end
