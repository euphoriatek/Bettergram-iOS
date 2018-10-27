#import <Foundation/Foundation.h>


@interface NSString (ValidateFilter)

- (BOOL)validateFilter:(NSString *)filter;

@end


@interface NSString (Levenshtein)

- (double)compareWithText:(NSString *)stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;
- (NSInteger)compareWithWord:(NSString *) stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost;

@end


@interface NSArray<ObjectType> (Filtered)

- (NSArray<ObjectType> *)filteredArrayUsingMatchingString:(NSString *)string
                                     levenshteinMatchGain:(NSInteger)gain
                                              missingCost:(NSInteger)cost
                                         fieldGetterBlock:(NSArray<NSString *> *(^)(ObjectType obj))fieldGetterBlock
                                threshold:(double)threshold
                                      equalCaseComparator:(NSComparator)cmptr;

@end
