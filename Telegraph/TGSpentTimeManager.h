//
//  TGSpentTimeManager.h
//  Bettergram
//
//  Created by Dukhov Philip on 9/20/18.
//

#import <Foundation/Foundation.h>


@interface TGSpentTimeManager : NSObject

@property (nonatomic, assign) NSTimeInterval elapsedTime;
@property (nonatomic, assign) NSTimeInterval totalElapsedTime;

- (void)notifyReachingTime:(NSTimeInterval)time target:(id)target selector:(SEL)selector;

@end
