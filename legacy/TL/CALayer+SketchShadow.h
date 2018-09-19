#import <QuartzCore/QuartzCore.h>

@interface CALayer (SketchShadow)

- (void)applySketchShadowWithColor:(UIColor *)color
                           opacity:(CGFloat)opacity
                                 x:(CGFloat)x
                                 y:(CGFloat)y
                              blur:(CGFloat)blur;

@end
