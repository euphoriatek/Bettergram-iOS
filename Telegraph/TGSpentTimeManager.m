//
//  TGSpentTimeManager.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/20/18.
//

#import "TGSpentTimeManager.h"

@interface TGTimeAction : NSObject

@property (nonatomic, readonly, assign) NSTimeInterval inAppTime;
@property (nonatomic, readonly, assign) NSTimeInterval sinceInstallationTime;
@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly, assign) SEL selector;

@end

@implementation TGTimeAction

- (instancetype)initWithInAppTime:(NSTimeInterval)inAppTime
            sinceInstallationTime:(NSTimeInterval)sinceInstallationTime
                           target:(id)target
                         selector:(SEL)selector
{
    if (self = [super init]) {
        _inAppTime = inAppTime;
        _sinceInstallationTime = sinceInstallationTime;
        _target = target;
        _selector = selector;
    }
    return self;
}

- (void)invoce
{
    if ([_target respondsToSelector:_selector]) {
        IMP imp = [_target methodForSelector:_selector];
        void (*func)(id, SEL) = (void *)imp;
        func(_target, _selector);
    }
}

@end

@interface TGSpentTimeManager() {
    NSDate *_activeStartDate;
    NSMutableArray<TGTimeAction *> *_timeActions;
    NSMutableArray<NSTimer *> *_timers;
}

@end

@implementation TGSpentTimeManager

static NSString * const kUserTotalElapsedTimeKey = @"totalElapsedTime";
static NSString * const kUserInstallationTimeKey = @"installationTime";

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        _totalElapsedTime = [NSUserDefaults.standardUserDefaults doubleForKey:kUserTotalElapsedTimeKey];
        if (![NSUserDefaults.standardUserDefaults valueForKey:kUserInstallationTimeKey]) {
            _installationTime = NSDate.date.timeIntervalSince1970;
            [NSUserDefaults.standardUserDefaults setDouble:_installationTime forKey:kUserInstallationTimeKey];
        }
        else {
            _installationTime = [NSUserDefaults.standardUserDefaults doubleForKey:kUserInstallationTimeKey];
        }
        _activeStartDate = [NSDate date];
        _timeActions = [NSMutableArray array];
        _timers = [NSMutableArray array];
    }
    
    return self;
}

- (void)didBecomeActive {
    _activeStartDate = [NSDate date];
    if (_timers.count == 0) {
        [_timeActions enumerateObjectsUsingBlock:^(TGTimeAction * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [self createTimerWithTimeAction:obj];
        }];
    }
}

- (void)willResignActive {
    if (_activeStartDate) {
        _elapsedTime += [[NSDate date] timeIntervalSinceDate:_activeStartDate];
        _activeStartDate = nil;
        [_timers enumerateObjectsUsingBlock:^(NSTimer * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [obj invalidate];
        }];
        [_timers removeAllObjects];
        [NSUserDefaults.standardUserDefaults setDouble:_elapsedTime forKey:kUserTotalElapsedTimeKey];
    }
}

- (NSTimeInterval)elapsedTime {
    if (_activeStartDate) {
        return _elapsedTime + [[NSDate date] timeIntervalSinceDate:_activeStartDate];
    }
    return _elapsedTime;
}

- (NSTimeInterval)totalElapsedTime
{
    return _totalElapsedTime + self.elapsedTime;
}

- (void)notifyReachingInAppTime:(NSTimeInterval)inAppTime
          sinceInstallationTime:(NSTimeInterval)sinceInstallationTime
                         target:(id)target
                       selector:(SEL)selector
{
    TGTimeAction *timeAction = [[TGTimeAction alloc] initWithInAppTime:inAppTime
                                                 sinceInstallationTime:sinceInstallationTime
                                                                target:target
                                                              selector:selector];
    [_timeActions addObject:timeAction];
    [self createTimerWithTimeAction:timeAction];
}

- (void)createTimerWithTimeAction:(TGTimeAction *)timeAction
{
    if (timeAction.inAppTime + 1 < self.totalElapsedTime || timeAction.sinceInstallationTime + self.installationTime + 1 < NSDate.date.timeIntervalSince1970) {
        
        [timeAction invoce];
        return;
    }
    void(^block)(__unused NSTimer * _Nonnull) = ^(__unused NSTimer * _Nonnull timer) {
        [timeAction invoce];
        [_timeActions removeObject:timeAction];
    };
    NSArray<NSTimer *> *actionTimers = @[
                                         [NSTimer scheduledTimerWithTimeInterval:timeAction.inAppTime - self.totalElapsedTime
                                                                         repeats:NO
                                                                           block:block],
                                         [NSTimer scheduledTimerWithTimeInterval:timeAction.sinceInstallationTime + self.installationTime - NSDate.date.timeIntervalSince1970
                                                                         repeats:NO
                                                                           block:block]
                                         ];
    [_timers addObjectsFromArray:actionTimers];
}

@end
