//
//  TGCryptoCurrency.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/21/18.
//

#import <Foundation/Foundation.h>

@interface TGCryptoCurrency : NSObject

@property (readonly, nonatomic, strong) NSString *code;
@property (readonly, nonatomic, strong) NSString *name;
@property (readonly, nonatomic, strong) NSString *url;
@property (readonly, nonatomic, strong) NSString *symbol;
@property (readonly, nonatomic, strong) NSString *iconURL;

@property (nonatomic, assign) BOOL favorite;

- (instancetype)initWithJSON:(NSDictionary *)dictionary;
- (BOOL)validateFilter:(NSString *)filter;

@end
