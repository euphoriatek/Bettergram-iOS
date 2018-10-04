//
//  TGSpentTimeManager.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/20/18.
//

#import "TGSpentTimeManager.h"

@interface TGTimeAction : NSObject

@property (nonatomic, readonly, assign) NSTimeInterval time;
@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly, assign) SEL selector;

@end

@implementation TGTimeAction

- (instancetype)initWithTime:(NSTimeInterval)time target:(id)target selector:(SEL)selector
{
    if (self = [super init]) {
        _time = time;
        _target = target;
        _selector = selector;
    }
    return self;
}

- (void)invoce
{
    [_target performSelector:_selector];
}

@end

@interface TGSpentTimeManager() {
    NSDate *_activeStartDate;
    NSMutableArray<TGTimeAction *> *_timeActions;
    NSMutableArray<NSTimer *> *_timers;
}

@end

@implementation TGSpentTimeManager

static NSString * const kUserDefaultKey = @"totalElapsedTime";

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
        
        _totalElapsedTime = [NSUserDefaults.standardUserDefaults doubleForKey:kUserDefaultKey];
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
        [NSUserDefaults.standardUserDefaults setDouble:_elapsedTime forKey:kUserDefaultKey];
        [NSUserDefaults.standardUserDefaults synchronize];
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

- (void)notifyReachingTime:(NSTimeInterval)time target:(id)target selector:(SEL)selector
{
    TGTimeAction *timeAction = [[TGTimeAction alloc] initWithTime:time target:target selector:selector];
    [_timeActions addObject:timeAction];
    [self createTimerWithTimeAction:timeAction];
}

- (void)createTimerWithTimeAction:(TGTimeAction *)timeAction
{
    if (timeAction.time + 1 < self.totalElapsedTime) {
        [timeAction invoce];
        return;
    }
    [_timers addObject:[NSTimer scheduledTimerWithTimeInterval:timeAction.time - self.totalElapsedTime
                                                       repeats:NO
                                                         block:^(__unused NSTimer * _Nonnull timer) {
                                                             [timeAction invoce];
                                                             [_timeActions removeObject:timeAction];
                                                         }]];
}

@end
