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
        return [self _safeAreaInsetForOrientation:orientation];
    }
    return UIEdgeInsetsZero;
}

@end
