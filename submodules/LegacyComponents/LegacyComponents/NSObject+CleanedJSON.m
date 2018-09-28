//
//  NSObject+CleanedJSON.m
//  LegacyComponents
//
//  Created by Dukhov Philip on 9/24/18.
//  Copyright © 2018 Telegram. All rights reserved.
//

#import "NSObject+CleanedJSON.h"

@implementation NSObject (CleanedJSON)

- (instancetype)cleanedJSON
{
    return self;
}

@end

@implementation NSNull (CleanedJSON)

- (instancetype)cleanedJSON
{
    return nil;
}

@end

@implementation NSDictionary (CleanedJSON)

- (instancetype)cleanedJSON
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in self) {
        id object = [[self objectForKey:key] cleanedJSON];
        if (object != nil) {
            result[key] = object;
        }
    }
    return result;
}

@end

@implementation NSArray (CleanedJSON)

- (instancetype)cleanedJSON
{
    NSMutableArray *result = [NSMutableArray array];
    for (id object in self) {
        id cleanedObject = [object cleanedJSON];
        if (cleanedObject) {
            [result addObject:cleanedObject];
        }
    }
    return result;
}

@end
