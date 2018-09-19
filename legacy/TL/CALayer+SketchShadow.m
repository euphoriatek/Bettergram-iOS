#import "CALayer+SketchShadow.h"

@implementation CALayer (SketchShadow)

- (void)applySketchShadowWithColor:(UIColor *)color
                           opacity:(CGFloat)opacity
                                 x:(CGFloat)x
                                 y:(CGFloat)y
                              blur:(CGFloat)blur
{
    self.shadowColor = color.CGColor;
    self.shadowOpacity = (float)opacity;
    self.shadowRadius = blur / 2;
    self.shadowOffset = CGSizeMake(x, y);
}

@end
