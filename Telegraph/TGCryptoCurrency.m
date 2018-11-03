//
//  TGCryptoCurrency.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import "TGCryptoCurrency.h"
#import <LegacyComponents/LegacyComponents.h>


@implementation TGCryptoCurrency

- (instancetype)initWithCode:(NSString *)code
{    
    if (self = [super init]) {
        _requestsCount = 0;
        _code = code.uppercaseString;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        _code = [decoder decodeObjectForKey:@"code"];
        _name = [decoder decodeObjectForKey:@"name"];
        _url = [decoder decodeObjectForKey:@"url"];
        _symbol = [decoder decodeObjectForKey:@"symbol"];
        _iconURL = [decoder decodeObjectForKey:@"iconURL"];
        _favorite = [decoder decodeBoolForKey:@"favorite"];
        _requestsCount = [decoder decodeIntegerForKey:@"requestsCount"];
        
        _volume = [decoder decodeDoubleForKey:@"volume"];
        _cap = [decoder decodeDoubleForKey:@"cap"];
        _rank = [decoder decodeIntegerForKey:@"rank"];
        _price = [decoder decodeDoubleForKey:@"price"];
        _dayDelta = [decoder decodeObjectForKey:@"dayDelta"];
        _minDelta = [decoder decodeObjectForKey:@"minDelta"];
        
        _updatedDate = _priceSortingUpdatedDate = _rankSortingUpdatedDate = _deltaSortingUpdatedDate = 0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_code forKey:@"code"];
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_url forKey:@"url"];
    [encoder encodeObject:_symbol forKey:@"symbol"];
    [encoder encodeObject:_iconURL forKey:@"iconURL"];
    [encoder encodeBool:_favorite forKey:@"favorite"];
    [encoder encodeInteger:_requestsCount forKey:@"requestsCount"];
    
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_cap forKey:@"cap"];
    [encoder encodeInteger:_rank forKey:@"rank"];
    [encoder encodeDouble:_price forKey:@"price"];
    [encoder encodeObject:_dayDelta forKey:@"dayDelta"];
    [encoder encodeObject:_minDelta forKey:@"minDelta"];
}

- (BOOL)validateFilter:(NSString *)filter
{
    return [_code validateFilter:filter] || [_name validateFilter:filter] || [_symbol validateFilter:filter];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]] && [_code isEqual:[(TGCryptoCurrency *)object code]];
}

- (void)fillWithCurrencyJson:(NSDictionary *)dictionary
{
#if DEBUG
    NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
    [unknownKeys removeObjectsInArray:@[@"code",@"name",@"url",@"symbol",@"icon"]];
    if (unknownKeys.count > 0) {
        TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
        [NSException raise:@"TGCMError" format:@"TGCMError: unknown currency keys: %@", unknownKeys];
    }
#endif
    _name = dictionary[@"name"];
    _url = dictionary[@"url"];
    _symbol = dictionary[@"symbol"];
    _iconURL = dictionary[@"icon"];
}

- (void)fillWithCoinInfoJson:(NSDictionary *)dictionary sorting:(TGCoinSorting)sorting
{
#if DEBUG
    NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
    [unknownKeys removeObjectsInArray:@[@"code",@"volume",@"cap",@"rank",@"price",@"delta"]];
    if (unknownKeys.count > 0) {
        TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
        [NSException raise:@"TGCMError" format:@"TGCMError: unknown currency keys: %@", unknownKeys];
    }
#endif
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
    switch (sorting) {
        case TGSortingPriceAscending:
        case TGSortingPriceDescending:
            _priceSortingUpdatedDate = NSDate.date.timeIntervalSince1970;
            break;
            
        case TGSorting24hAscending:
        case TGSorting24hDescending:
            _deltaSortingUpdatedDate = NSDate.date.timeIntervalSince1970;
            break;
            
        case TGSortingNone:
            _rankSortingUpdatedDate = NSDate.date.timeIntervalSince1970;
            break;
            
        default:
            break;
    }
}

- (void)cleanSortingDate:(TGCoinSorting)sorting
{
    switch (sorting) {
        case TGSortingPriceAscending:
        case TGSortingPriceDescending:
            _priceSortingUpdatedDate = 0;
            break;
            
        case TGSorting24hAscending:
        case TGSorting24hDescending:
            _deltaSortingUpdatedDate = 0;
            break;
            
        case TGSortingNone:
            _rankSortingUpdatedDate = 0;
            break;
            
        default:
            _updatedDate = 0;
            break;
    }
}

- (void)clean
{
    _volume = 0;
    _cap = 0;
    _rank = 0;
    _price = 0;
    _dayDelta = nil;
    _minDelta = nil;
    _updatedDate = _priceSortingUpdatedDate = _rankSortingUpdatedDate = _deltaSortingUpdatedDate = 0;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@; price: %@", [self class], self, _code, @(_price)];
}

@end
