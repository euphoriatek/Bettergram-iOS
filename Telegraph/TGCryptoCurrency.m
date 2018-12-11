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
        _code = code;
        _rank = NSIntegerMax;
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
        _type = [decoder decodeIntegerForKey:@"type"];
        
        _favorite = [decoder decodeBoolForKey:@"favorite"];
        _requestsCount = [decoder decodeIntegerForKey:@"requestsCount"];
        
        _volume = [decoder decodeDoubleForKey:@"volume"];
        _cap = [decoder decodeDoubleForKey:@"cap"];
        _rank = [decoder decodeIntegerForKey:@"rank"];
        if (_rank < 1) {
            _rank = NSIntegerMax;
        }
        _price = [decoder decodeObjectForKey:@"price"];
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
    [encoder encodeInteger:_type forKey:@"type"];
    
    [encoder encodeBool:_favorite forKey:@"favorite"];
    [encoder encodeInteger:_requestsCount forKey:@"requestsCount"];
    
    [encoder encodeDouble:_volume forKey:@"volume"];
    [encoder encodeDouble:_cap forKey:@"cap"];
    [encoder encodeInteger:_rank forKey:@"rank"];
    [encoder encodeObject:_price forKey:@"price"];
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
                     baseURL:(NSString *)baseURL
        baseIconURLGenerator:(NSString *(^)(TGCryptoCurrencyType type))baseIconURLGenerator
{
#if DEBUG
    NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
    [unknownKeys removeObjectsInArray:@[@"code",@"name",@"url",@"symbol",@"icon",@"type"]];
    if (unknownKeys.count > 0) {
        TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
        [NSException raise:@"TGCMError" format:@"TGCMError: unknown currency keys: %@", unknownKeys];
    }
#endif
    _name = dictionary[@"name"];
    _symbol = dictionary[@"symbol"];
    
    NSString *typeString = dictionary[@"type"];
    if ([typeString isEqualToString:@"coin"]) {
        _type = TGCryptoCurrencyTypeCoin;
        static NSCharacterSet *set = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableCharacterSet *mSet = NSMutableCharacterSet.decimalDigitCharacterSet;
            [mSet formUnionWithCharacterSet:NSMutableCharacterSet.letterCharacterSet];
            [mSet addCharactersInString:@"_"];
            set = mSet.invertedSet;
        });
        _url = [NSString stringWithFormat:@"%@%@-%@",baseURL, [[_name componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""], _code];
    }
    else if ([typeString isEqualToString:@"fiat"]) {
        _type = TGCryptoCurrencyTypeFiat;
    }
    else {
        _type = TGCryptoCurrencyTypeUnknown;
    }
    
    NSString *iconName = dictionary[@"icon"];
    if (iconName) {
        _iconURL = [baseIconURLGenerator(_type) stringByAppendingString:iconName];
    }
}

- (void)fillWithCoinInfoJson:(NSDictionary *)dictionary sorting:(TGCoinSorting)sorting
{
#if DEBUG
    NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
    [unknownKeys removeObjectsInArray:@[
                                        // used
                                        @"code",@"cap",@"rank",@"price",@"delta",
                                        // unused
                                        @"supply",@"circulating",@"name", @"volume", @"plot", @"extremes", @"ico"
                                        ]];
    if (unknownKeys.count > 0) {
        TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
        [NSException raise:@"TGCMError" format:@"TGCMError: unknown currency keys: %@", unknownKeys];
    }
#endif
    if (![dictionary[@"code"] isEqualToString:_code]) return;
    _cap = [dictionary[@"cap"] doubleValue];
    _rank = [dictionary[@"rank"] integerValue];
    if (_rank < 1) {
        _rank = NSIntegerMax;
    }
    
    id price = dictionary[@"price"];
    if ([price isKindOfClass:NSNumber.class]) {
        _price = price;
    }
    else {
        _price = nil;
    }
    
    id dayDelta = dictionary[@"delta"][@"day"];
    if ([dayDelta isKindOfClass:[NSNumber class]]) {
        _dayDelta = @([dayDelta doubleValue] - 1);
    }
    else {
        _dayDelta = nil;
    }
    
    id minuteDelta = dictionary[@"delta"][@"minute"];
    if ([minuteDelta isKindOfClass:[NSNumber class]]) {
        _minDelta = @([minuteDelta doubleValue] - 1);
    }
    else {
        _dayDelta = nil;
    }
    
    *[self updatedDatePointerForSorting:sorting] = _updatedDate = NSDate.date.timeIntervalSince1970;
    
    /* non used values
     name
     _volume = [dictionary[@"volume"] doubleValue];
     _supply = [dictionary[@"supply"] integerValue];
     _circulating = [dictionary[@"circulating"] integerValue];
     */
}

- (NSTimeInterval)updatedDateForSorting:(TGCoinSorting)sorting
{
    return *[self updatedDatePointerForSorting:sorting];
}

- (void)setUpdatedDate:(NSTimeInterval)updatedDate sorting:(TGCoinSorting)sorting
{
    *[self updatedDatePointerForSorting:sorting] = updatedDate;
}

- (NSTimeInterval *)updatedDatePointerForSorting:(TGCoinSorting)sorting
{
    switch (sorting) {
        case TGSortingPriceAscending:
        case TGSortingPriceDescending:
            return &_priceSortingUpdatedDate;
            
        case TGSorting24hAscending:
        case TGSorting24hDescending:
            return &_deltaSortingUpdatedDate;
            
        case TGSortingNone:
            return &_rankSortingUpdatedDate;
            
        default:
            return &_updatedDate;
    }
}

- (void)clean
{
    _volume = 0;
    _cap = 0;
    _rank = NSIntegerMax;
    _price = 0;
    _dayDelta = nil;
    _minDelta = nil;
    _updatedDate = _priceSortingUpdatedDate = _rankSortingUpdatedDate = _deltaSortingUpdatedDate = 0;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@; price: %@", [self class], self, _code, _price];
}

@end
