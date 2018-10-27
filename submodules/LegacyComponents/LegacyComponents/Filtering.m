#import "Filtering.h"


@implementation NSString (ValidateFilter)

- (BOOL)validateFilter:(NSString *)filter
{
    return filter.length > 0 && [self rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound;
}

@end


@implementation NSString (Levenshtein)

// default match: 0
// default cost: 1

// calculate the mean distance between all words in stringA and stringB
- (double)compareWithText:(NSString *)stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost {
    NSString *mStringA = [self stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSString *mStringB = [stringB stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    NSArray *arrayA = [mStringA componentsSeparatedByString: @" "];
    NSArray *arrayB = [mStringB componentsSeparatedByString: @" "];
    
    double smallestDistance = 0;
    for (NSString *tokenA in arrayA) {
        for (NSString *tokenB in arrayB) {
            smallestDistance = MAX(smallestDistance, ((float) -[tokenA compareWithWord:tokenB matchGain:gain missingCost:cost]) / MIN(tokenA.length, tokenB.length));
        }
    }
    
    return smallestDistance;
}


// calculate the distance between two string treating them eash as a single word
- (NSInteger)compareWithWord:(NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost {
    // normalize strings
    NSString * stringA = [NSString stringWithString: self];
    stringA = [[stringA stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    stringB = [[stringB stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    
    // Step 1
    NSUInteger k, i, j, distance;
    NSInteger change, *d;
    
    NSUInteger n = [stringA length];
    NSUInteger m = [stringB length];
    
    if( n++ != 0 && m++ != 0 ) {
        d = malloc( sizeof(NSInteger) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ ) {
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if([stringA characterAtIndex: i-1] == [stringB characterAtIndex: j-1]) {
                    change = -gain;
                } else {
                    change = cost;
                }
                
                // Step 6
                d[ j * n + i ] = MIN(d [ (j - 1) * n + i ] + 1, MIN(d[ j * n + i - 1 ] +  1, d[ (j - 1) * n + i -1 ] + change));
            }
        }
        
        distance = d[ n * m - 1 ];
        free( d );
        return distance;
    }
    
    return 0;
}

@end


@implementation NSArray (Filtered)

- (NSArray *)filteredArrayUsingMatchingString:(NSString *)string
                         levenshteinMatchGain:(NSInteger)gain
                                  missingCost:(NSInteger)cost
                             fieldGetterBlock:(NSArray<NSString *> *(^)(id))fieldGetterBlock
                                    threshold:(double)threshold
                          equalCaseComparator:(NSComparator)cmptr
{
    if (string.length < 2) return nil;
    NSMutableArray *weights = [NSMutableArray array];
    __block double weight = 0;
    threshold *= gain;
    [self enumerateObjectsUsingBlock:^(id obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        weight = 0;
        [fieldGetterBlock(obj) enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            weight = MAX([obj compareWithText:string matchGain:gain missingCost:cost], weight);
        }];
        if (weight > threshold)
            [weights addObject:@[@(weight), obj]];
    }];
    [weights sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSComparisonResult result = [[obj2 firstObject] compare:[obj1 firstObject]];
        if (cmptr != NULL && result == NSOrderedSame) {
            result = cmptr(obj1, obj2);
        }
        return result;
    }];
    NSMutableArray *array = [NSMutableArray array];
    [weights enumerateObjectsUsingBlock:^(id  _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [array addObject:[obj lastObject]];
    }];
    return array.copy;
}

@end
