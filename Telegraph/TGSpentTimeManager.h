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
@property (nonatomic, assign) NSTimeInterval installationTime;

- (void)notifyReachingInAppTime:(NSTimeInterval)inAppTime
          sinceInstallationTime:(NSTimeInterval)sinceInstallationTime
                         target:(id)target
                       selector:(SEL)selector;

@end
