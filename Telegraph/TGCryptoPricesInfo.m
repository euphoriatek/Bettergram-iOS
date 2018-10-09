//
//  TGCryptoPricesInfo.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/22/18.
//

#import "TGCryptoPricesInfo.h"
#import "TGCryptoManager.h"

@interface TGCryptoPricesInfo () {
    NSMutableArray<TGCryptoCoinInfo *> *_coinInfos;
}

@end

@implementation TGCryptoPricesInfo

- (instancetype)initWithJSON:(NSDictionary *)dictionary ignoreUnknownCoins:(BOOL)ignoreUnknownCoins favorites:(BOOL)favorites
{
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:dictionary[@"currency"]];
        _marketCap = [dictionary[@"cap"] doubleValue];
        _volume = [dictionary[@"volume"] doubleValue];
        _btcDominance = [dictionary[@"btcDominance"] doubleValue];
        
        _coinInfos = [NSMutableArray array];
        for (id json in dictionary[@"data"][favorites ? @"favorites" : @"list"]) {
            TGCryptoCoinInfo *coinInfo = [[TGCryptoCoinInfo alloc] initWithJSON:json];
            if (!ignoreUnknownCoins && coinInfo.currency == nil) {
                return nil;
            }
            [_coinInfos addObject:coinInfo];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _currency = [TGCryptoManager.manager cachedCurrencyWithCode:[decoder decodeObjectForKey:@"code"]];
        _marketCap = [[decoder decodeObjectForKey:@"marketCap"] doubleValue];
        _volume = [[decoder decodeObjectForKey:@"volume"] doubleValue];
        _btcDominance = [[decoder decodeObjectForKey:@"btcDominance"] doubleValue];
        _coinInfos = [decoder decodeObjectForKey:@"coinInfos"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    if (_currency) [encoder encodeObject:_currency.code forKey:@"code"];
    [encoder encodeDouble:_marketCap forKey:@"marketCap"];
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_btcDominance forKey:@"btcDominance"];
    [encoder encodeObject:_coinInfos forKey:@"coinInfos"];
}

- (void)coinInfoAtIndexUnfavorited:(NSUInteger)index
{
    [_coinInfos removeObjectAtIndex:index];
}

@end
