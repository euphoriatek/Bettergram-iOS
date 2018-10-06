//
//  TGCryptoCurrency.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import "TGCryptoCurrency.h"

//@interface NSString (ValidateFilter)
//
//- (BOOL)validateFilter:(NSString *)filter;
//
//@end

@implementation NSString (ValidateFilter)

- (BOOL)validateFilter:(NSString *)filter
{
    return filter.length > 0 && [self rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound;
}

@end

@implementation TGCryptoCurrency

- (instancetype)initWithJSON:(NSDictionary *)dictionary
{    
    if (self = [super init]) {
        _code = [dictionary[@"code"] uppercaseString];
        _name = dictionary[@"name"];
        _url = dictionary[@"url"];
        _symbol = dictionary[@"symbol"];
        _iconURL = dictionary[@"icon"];
#if DEBUG
        NSMutableArray<NSString *> *unknownKeys = dictionary.allKeys.mutableCopy;
        [unknownKeys removeObjectsInArray:@[@"code",@"name",@"url",@"symbol",@"icon"]];
        if (unknownKeys.count > 0) {
            TGLog(@"TGCMError: unknown currency keys: %@", unknownKeys);
            return nil;
        }
#endif
    }
    return self;
}

- (BOOL)validateFilter:(NSString *)filter
{
    return [_code validateFilter:filter] || [_name validateFilter:filter] || [_symbol validateFilter:filter];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]] && [_code isEqual:[(TGCryptoCurrency *)object code]];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> code: %@", [self class], self, _code];
}

@end
