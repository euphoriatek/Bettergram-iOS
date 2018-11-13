#import "TGCryptoNumberFormatter.h"

@implementation TGCryptoNumberFormatter

- (NSString *)stringFromNumber:(NSNumber *)number
{
    switch (self.numberStyle) {
        case NSNumberFormatterCurrencyStyle:
            if (number.doubleValue < 1) {
                self.maximumFractionDigits = 4;
                return [super stringFromNumber:number];
            }
            if (number.doubleValue < 10000) {
                self.maximumFractionDigits = 2;
                return [super stringFromNumber:number];
            }
            if (number.doubleValue < 1000000) {
                self.maximumFractionDigits = 0;
                return [super stringFromNumber:number];
            }
            self.maximumFractionDigits = 2;
            break;
            
        case NSNumberFormatterPercentStyle:
            
            break;
            
        default:
            break;
    }
    static NSArray* units;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        units = @[@"k",@"M",@"B",@"T",@"P",@"E"];
    });
    BOOL isPrecents = self.numberStyle == NSNumberFormatterPercentStyle;
    NSUInteger exp = (NSUInteger)(log10l(number.doubleValue * (isPrecents ? 100 : 1)) / 3.f);
    if (exp - 1 < units.count)
        return [NSString stringWithFormat:@"%@ %@", [super stringFromNumber:@(number.doubleValue / pow(1000, exp))], units[exp-1]];
    return [super stringFromNumber:number];
}

@end
