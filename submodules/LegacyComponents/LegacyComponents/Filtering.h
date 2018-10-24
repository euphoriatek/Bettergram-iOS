#import <Foundation/Foundation.h>


@interface NSString (ValidateFilter)

- (BOOL)validateFilter:(NSString *)filter;

@end


@interface NSString (Levenshtein)

- (float)compareWithText: (NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;
- (NSInteger)compareWithWord:(NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;

@end


@interface NSArray<ObjectType> (Filtered)

- (NSArray<ObjectType> *)filteredArrayUsingMatchingString:(NSString *)string
                                     levenshteinMatchGain:(NSInteger)gain
                                              missingCost:(NSInteger)cost
                                         fieldGetterBlock:(NSDictionary<NSNumber *, NSString *> *(^)(ObjectType obj))fieldGetterBlock
                                filterThresholdMultiplier:(double)filterThresholdMultiplier
                                      equalCaseComparator:(NSComparator)cmptr;

@end
