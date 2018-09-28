#import "UIView+AddSubviews.h"

@implementation UIView (AddSubviews)

- (void)addSubviews:(NSArray<UIView *> *)subviews
{
    [subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [self addSubview:obj];
    }];
}

@end
