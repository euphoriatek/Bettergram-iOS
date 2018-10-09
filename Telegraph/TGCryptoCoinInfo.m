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
        if ([dayDelta isKindOfClass:[NSNumber class]]) {
            _dayDelta = @([dayDelta doubleValue] - 1);
        }
        
        id minuteDelta = dictionary[@"delta"][@"minute"];
        if ([minuteDelta isKindOfClass:[NSNumber class]]) {
            _minDelta = @([minuteDelta doubleValue] - 1);
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

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:[decoder decodeObjectForKey:@"code"]];
        _volume = [[decoder decodeObjectForKey:@"volume"] doubleValue];
        _cap = [[decoder decodeObjectForKey:@"cap"] doubleValue];
        _rank = [[decoder decodeObjectForKey:@"rank"] integerValue];
        _price = [[decoder decodeObjectForKey:@"price"] doubleValue];
        _dayDelta = [decoder decodeObjectForKey:@"dayDelta"];
        _minDelta = [decoder decodeObjectForKey:@"minDelta"];
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
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@; price: %@", [self class], self, _currency.code, @(_price)];
}

@end
