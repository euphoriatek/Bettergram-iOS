#import "TGViewController+SafeAreaInsetsSwizzling.h"

@implementation TGViewController (SafeAreaInsetsSwizzling)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleClassMethod([TGViewController class], @selector(safeAreaInsetForOrientation:), @selector(_safeAreaInsetForOrientation:));
    });
}

+ (UIEdgeInsets)_safeAreaInsetForOrientation:(UIInterfaceOrientation)orientation
{
    if (@available(iOS 11.0, *)) {
        if (UIApplication.sharedApplication.statusBarOrientation == orientation) {
            return UIApplication.sharedApplication.keyWindow.safeAreaInsets;
        }
        if (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom != 0) {
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                return UIEdgeInsetsMake(0, 44, 21, 44);
            }
            return UIEdgeInsetsMake(44, 0, 34, 0);
        }
    }
    return UIEdgeInsetsZero;
}

@end
