//
//  TGResourceSection.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/28/18.
//

#import <Foundation/Foundation.h>


@interface TGResourceItem : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *descriptionString;
@property (nonatomic, strong, readonly) NSString *urlString;
@property (nonatomic, strong, readonly) NSString *iconURLString;

@end


@interface TGResourceSection : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSArray<TGResourceItem *> *resourceItems;

- (instancetype)initWithJSON:(NSDictionary *)dictionary;

@end
