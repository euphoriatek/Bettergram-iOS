#import "TGPresentationAssets.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGRoundMessageViewModel.h"

@implementation TGPresentationAssets

+ (UIImage *)chatFavoritedIcon:(UIColor *)color
{
    NSString *code = @"M8.15217391,15 L7.01086957,13.8586957 C2.77173913,10.1086957 0,7.58152174 0,4.48369565 C0,1.95652174 1.95652174,0 4.48369565,0 C5.86956522,0 7.25543478,0.652173913 8.15217391,1.71195652 C9.04891304,0.652173913 10.4347826,0 11.8206522,0 C14.3478261,0 16.3043478,1.95652174 16.3043478,4.48369565 C16.3043478,7.58152174 13.5326087,10.1086957 9.29347826,13.8586957 L8.15217391,15 Z";
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(17, 17), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 1, 3);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)cryptoPricesFavoriteImageSelected:(BOOL)selected withBackgound:(UIColor *)backgroundColor color:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 34, 34);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (backgroundColor != nil) {
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextAddEllipseInRect(context, rect);
        CGContextFillPath(context);
    }
    
    CGContextSetLineWidth(context, 1);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextTranslateCTM(context, 29.0/3, 29.0/3);
    TGDrawSvgPath(context, selected ? [self selectedStarCode] : [self deselectedStarCode]);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (NSString *)selectedStarCode
{
    return @"M14.0248526,4.74958678 L9.98683605,4.3677686 C9.73229059,4.3446281 9.51245588,4.18264463 9.40832365,3.93966942 L7.96204266,0.433884298 C7.7306377,-0.144628099 6.9091501,-0.144628099 6.67774514,0.433884298 L5.24303439,3.93966942 C5.15047241,4.18264463 4.91906745,4.3446281 4.664522,4.3677686 L0.626505468,4.74958678 C0.0248525752,4.80743802 -0.218122631,5.55950413 0.233117038,5.96446281 L3.27609224,8.63719008 C3.47278646,8.8107438 3.5537782,9.06528926 3.49592696,9.31983471 L2.58187737,13.068595 C2.44303439,13.6586777 3.07939803,14.1446281 3.61162943,13.8322314 L6.97857158,11.853719 C7.19840629,11.7264463 7.464522,11.7264463 7.68435671,11.853719 L11.0512989,13.8322314 C11.5835303,14.1446281 12.2198939,13.6702479 12.0810509,13.068595 L11.1785716,9.31983471 C11.1207203,9.06528926 11.2017121,8.8107438 11.3984063,8.63719008 L14.4413815,5.96446281 C14.8810509,5.55950413 14.6265055,4.80743802 14.0248526,4.74958678 Z";
}

+ (NSString *)deselectedStarCode
{
    return @"M14.138843,4.76694215 L10.1008264,4.38512397 C9.84628099,4.36198347 9.62644628,4.2 9.52231405,3.95702479 L8.07603306,0.451239669 C7.8446281,-0.127272727 7.0231405,-0.127272727 6.79173554,0.451239669 L5.35702479,3.95702479 C5.26446281,4.2 5.03305785,4.36198347 4.7785124,4.38512397 L0.740495868,4.76694215 C0.138842975,4.82479339 -0.104132231,5.5768595 0.347107438,5.98181818 L3.39008264,8.65454545 C3.58677686,8.82809917 3.6677686,9.08264463 3.60991736,9.33719008 L2.69586777,13.0859504 C2.55702479,13.6760331 3.19338843,14.1619835 3.72561983,13.8495868 L7.09256198,11.8710744 C7.31239669,11.7438017 7.5785124,11.7438017 7.79834711,11.8710744 L11.1652893,13.8495868 C11.6975207,14.1619835 12.3338843,13.6876033 12.1950413,13.0859504 L11.292562,9.33719008 C11.2347107,9.08264463 11.3157025,8.82809917 11.5123967,8.65454545 L14.5553719,5.98181818 C14.9950413,5.5768595 14.7404959,4.82479339 14.138843,4.76694215 S";
}

+ (UIImage *)cryptoPricesSortArrowsTopArrowColor:(UIColor *)topArrowColor bottomArrowColor:(UIColor *)bottomArrowColor
{
    NSString *topArrowCode = @"M0,4 L3,0 L6,4 Z";
    NSString *bottomArrowCode = @"M0,6 L3,10 L6,6 Z";
    
    CGRect rect = CGRectMake(0, 0, 6, 10);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, topArrowColor.CGColor);
    TGDrawSvgPath(context, topArrowCode);
    
    CGContextSetFillColorWithColor(context, bottomArrowColor.CGColor);
    TGDrawSvgPath(context, bottomArrowCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chooseCurrencyButtonImageWithSymbol:(NSString *)symbol color:(UIColor *)color
{
    NSString *arrowCode = @"M31,10 L35.5,16 L40,10 Z";
    CGFloat circleWidth = 1.62;
    
    CGRect rect = CGRectMake(0, 0, 40, 26);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, circleWidth);
    
    CGRect ellipseRect = CGRectMake(circleWidth / 2, circleWidth / 2,
                                    rect.size.height - circleWidth,
                                    rect.size.height - circleWidth);
    CGContextStrokeEllipseInRect(context, ellipseRect);
    
    TGDrawSvgPath(context, arrowCode);
    
    CGFloat fontSize = rect.size.height - circleWidth;
    UIFont *font;
    CGSize symbolSize;
    CGFloat maxHypot = (rect.size.height - circleWidth * 2);
    do {
        font = TGSystemFontOfSize(fontSize);
        NSDictionary *attributes = @{NSFontAttributeName : font};
        symbolSize = [symbol sizeWithAttributes:attributes];
        CGSize realSize;
        realSize.width = CTLineGetTypographicBounds(CTLineCreateWithAttributedString((CFAttributedStringRef)[[NSAttributedString alloc] initWithString:symbol attributes:attributes]),
                                                    &realSize.height, NULL, NULL);
        CGFloat d = hypot(realSize.width, realSize.height);
        if (d > maxHypot) {
            fontSize -= TGScreenPixel;
        }
        else {
            break;
        }
    } while (true);
    [symbol drawInRect:CGRectMake((rect.size.height - symbolSize.width) / 2,
                                  (rect.size.height - symbolSize.height) / 2,
                                  symbolSize.width,
                                  symbolSize.height)
        withAttributes:@{ NSFontAttributeName : font,
                          NSForegroundColorAttributeName : color }];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)settingsImage:(UIColor *)color
{
    CGSize size = CGSizeMake(23, 20);
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGRect rect = CGRectMake(0, 0, size.width, 2);
    CGFloat cornerRadius = rect.size.height * 0.3;
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius] fill];
    
    rect.origin.y = size.height - rect.size.height;
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius] fill];
    
    rect.size.width = size.width * 17 / 23;
    rect.origin.y /= 2;
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius] fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)searchRssIcon:(UIColor *)color
{
    NSString *code1 = @"M354.633948,49.9638111 L349.157967,44.4856873 C350.139545,43.1469131 350.665372,41.528367 350.65804,39.8683197 C350.639311,35.5350456 347.134472,32.0251076 342.801229,32.0000796 C340.727529,31.9906973 338.736205,32.811057 337.270869,34.2784058 C335.805532,35.7457547 334.987907,37.7382025 335.000135,39.8118884 C335.018864,44.145557 338.524024,47.6558148 342.857661,47.6808428 C344.524471,47.688067 346.14893,47.1561022 347.4886,46.1643404 L347.494315,46.1600545 L352.965295,51.6338924 C353.261094,51.9442125 353.701854,52.0698227 354.116801,51.9620551 C354.531749,51.8542875 354.855684,51.5300753 354.963096,51.1150357 C355.070509,50.6999962 354.944521,50.2593439 354.633948,49.9638111 L354.633948,49.9638111 Z";
    NSString *code2 = @"M342.851946,46.1121951 C339.385226,46.0922527 336.581144,43.284347 336.565926,39.817603 C336.556569,38.1588691 337.210723,36.5652309 338.382772,35.3914386 C339.55482,34.2176462 341.147484,33.5611228 342.806229,33.5680131 C346.27295,33.5879554 349.077031,36.3958611 349.09225,39.8626052 C349.101606,41.521339 348.447452,43.1149772 347.275404,44.2887695 C346.103356,45.4625619 344.510692,46.1190853 342.851946,46.1121951 Z";
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, -335, -32);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code1);
    CGContextSetBlendMode(context, kCGBlendModeClear);
    TGDrawSvgPath(context, code2);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)newMessageIcon:(UIColor *)color
{
    NSString *code = @"M0,24 L20,24 L20,8.21091175 L18.2164439,10.3273526 L18.2164439,22.2131088 L1.78355613,22.2131088 L1.78355613,5.78689125 L14.7372276,5.78689125 L16.1545504,4 L0,4 Z M10.0506634,14.3078812 L10,17 L12.5548854,16.2965873 L22,3.98870611 L21.1676719,3.32580408 L11.9143546,15.37589 L10.9770808,15.725755 L11.0820265,14.712988 L20.3353438,2.66290204 L19.4993969,2 Z M22.9343236,2.18663117 C22.9343236,2.18663117 23.1634097,1.06692863 22.765878,0.742989526 L21.9876589,0.109195633 C21.5901272,-0.214743468 20.6064044,0.285249492 20.6064044,0.285249492 L20,1.09861832 L22.3279192,3 L22.9343236,2.18663117 Z";
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(23, 28), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)readIcon:(UIColor *)color unread:(BOOL)unread
{
    NSString *code = @"M13,0.1875 C5.925781,0.1875 0.1875,5.253906 0.1875,11.5 C0.1875,14.675781 1.675781,17.539063 4.0625,19.59375 C3.542969,22.601563 0.175781,23.828125 0.40625,24.65625 C3.414063,25.902344 9.378906,23.011719 10.28125,22.5625 C11.15625,22.730469 12.070313,22.8125 13,22.8125 C20.074219,22.8125 25.8125,17.746094 25.8125,11.5 C25.8125,5.253906 20.074219,0.1875 13,0.1875 Z";
    CGFloat side = 26;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    if (unread) {
        CGFloat smallRadius = side * 20 / 78 / 2;
        CGFloat bigRadius = smallRadius * 3 / 2 ;
        CGPoint center = CGPointMake(side - smallRadius, smallRadius);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextAddArc(context, center.x, center.y, bigRadius, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFill);
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextAddArc(context, center.x, center.y, smallRadius, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFill);
    }
        
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
};

#pragma mark - orinigal ones

+ (UIImage *)tabBarContactsIcon:(UIColor *)color
{
    NSString *code = @"M46.5,13 C27.428409,13 12,28.428409 12,47.5 C12,57.512776 16.2627225,66.5135605 23.0625,72.8125 C28.754193,68.7098485 37.4142195,68.0640625 39.1875,63.296875 C39.4065,60.878875 39.328125,59.17825 39.328125,56.96875 C38.230125,56.39425 36.189375,52.74925 35.859375,49.65625 C34.998375,49.58575 33.633375,48.754 33.234375,45.4375 C33.021375,43.657 33.88875,42.65875 34.40625,42.34375 C31.49475,31.13875 33.078375,21.353875 46.359375,21.109375 C49.678875,21.109375 52.2525,21.982375 53.25,23.734375 C62.943,25.081375 59.99475,38.13025 58.59375,42.34375 C59.11275,42.65875 59.980125,43.657 59.765625,45.4375 C59.368125,48.754 58.001625,49.58575 57.140625,49.65625 C56.809125,52.75075 54.860625,56.39425 53.765625,56.96875 C53.765625,59.17825 53.68725,60.878875 53.90625,63.296875 C55.6750635,68.0575585 64.270464,68.728288 69.9375,72.8125 C76.7372775,66.5135605 81,57.512776 81,47.5 C81,28.428409 65.571591,13 46.5,13 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(31, 31), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 0.336f, 0.336f);
    CGContextTranslateCTM(context, -0.33f, -0.33f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);

    CGContextRestoreGState(context);
    
    CGContextSetLineWidth(context, 1.33f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextStrokeEllipseInRect(context, CGRectMake(3.5f, 3.5f + 0.33f, 24.0f, 24.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)_callsIcon:(UIColor *)color stroke:(bool)stroke
{
    NSString *code = @"M20.8804647,51.180242 C20.8176441,51.1174215 47.8926125,78.1944734 65.4216461,70.68323 C65.4216461,70.68323 73.7076795,63.8274142 71.6806691,59.0572407 C71.0315231,57.5286073 62.7371137,48.3253971 52.00736,46.5371056 C52.00736,46.5371056 47.5366293,47.4312514 41.2755123,51.9040743 C41.2755123,51.9040743 36.8131577,53.8019529 27.502451,44.4975318 C18.1917442,35.1931107 20.0959055,30.7223818 20.0959055,30.7223818 C24.5666362,24.4633612 25.4607824,19.9926323 25.4607824,19.9926323 C23.6724901,9.26078874 14.4692763,0.968476478 12.9427364,0.319330821 C8.17256103,-1.70767884 1.31674263,6.57835136 1.31674263,6.57835136 C-6.19450374,24.1052841 20.8804647,51.180242 20.8804647,51.180242";
    
    if (stroke)
        code = [code stringByAppendingString:@" S"];
    else
        code = [code stringByAppendingString:@" Z"];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(31, 31), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 4.0f, 4.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)tabBarCallsIcon:(UIColor *)color
{
    return [self _callsIcon:color stroke:false];
}

+ (UIImage *)tabBarChatsIcon:(UIColor *)color downArrow:(NSNumber *)downArrow
{
    NSString *code = @"M36.3991203,72.9863676 C36.7653912,72.9954488 37.1323771,73 37.5,73 C58.6483576,73 76,57.9116153 76,39 C76,32.2746124 73.8055889,26.0327374 70.0263925,20.7810195 C81.821834,25.5490491 90,35.9440407 90,48 C90,57.4495579 85.3853733,65.1952817 77.5330155,70.69422 C76.5288377,71.397437 75.6039392,75.3047404 77.8422549,78.5867691 C80.0805706,81.8687978 82.8711876,83.3686517 81.471701,83.9301475 C80.6088976,84.2763177 75.5108064,84.447552 71.8312186,82.4737142 C66.5697786,79.651325 65.0988406,76.8415645 63.9666822,77.0899522 C61.2576974,77.6842845 58.4212488,78 55.5,78 C48.4361182,78 41.8680823,76.1539405 36.3991203,72.9863676 Z M37.5,69 C34.5787512,69 31.7423026,68.6842845 29.0333178,68.0899522 C27.9011594,67.8415645 26.4302214,70.651325 21.1687814,73.4737142 C17.4891936,75.447552 12.3911024,75.2763177 11.528299,74.9301475 C10.1288124,74.3686517 12.9194294,72.8687978 15.1577451,69.5867691 C17.3960608,66.3047404 16.4711623,62.397437 15.4669845,61.69422 C7.61462671,56.1952817 3,48.4495579 3,39 C3,22.4314575 18.4461761,9 37.5,9 C56.5538239,9 72,22.4314575 72,39 C72,55.5685425 56.5538239,69 37.5,69 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(31, 31), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    if (downArrow != nil)
    {
        NSString *arrowCode = @"M0,0 L11.6775298,10.8847467 C11.8591736,11.0540588 12.1408264,11.0540588 12.3224702,10.8847467 L24,0 U";
        bool down = downArrow.boolValue;
        
        CGContextSetLineWidth(context, 4.0f);
        CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        if (!down)
        {
            CGContextScaleCTM(context, 1.0f, -1.0f);
            CGContextTranslateCTM(context, 25.0f, -44.0f);
        }
        else
        {
            CGContextTranslateCTM(context, 25.0f, 35.0f);
        }
        TGDrawSvgPath(context, arrowCode);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)tabBarSettingsIcon:(UIColor *)color
{
    NSString *outerCode = @"M68.3275496,69.3275496 L76.5,55.1724504 L76.5,38.8275496 L68.3275496,24.6724504 L54.1724504,16.5 L37.8275496,16.5 L23.6724504,24.6724504 L15.5,38.8275496 L15.5,55.1724504 L23.6724504,69.3275496 L37.8275496,77.5 L54.1724504,77.5 L68.3275496,69.3275496 Z M69.2499195,70.2499195 L66.8327471,72.8901647 C65.9489387,73.8555369 65.7929874,75.2824598 66.4474072,76.4159481 L67.5980762,78.4089653 C68.4265033,79.8438432 67.9348779,81.6786144 66.5,82.5070416 C65.0651221,83.3354687 63.2303509,82.8438432 62.4019238,81.4089653 L61.2512548,79.4159481 C60.596835,78.2824598 59.2831079,77.7040561 58.0051668,77.9867706 L54.5100612,78.7599807 L51.0966059,79.8379139 C49.8485192,80.2320466 49,81.3898224 49,82.6986619 L49,85 C49,86.6568542 47.6568542,88 46,88 C44.3431458,88 43,86.6568542 43,85 L43,82.6986619 C43,81.3898224 42.1514808,80.2320466 40.9033941,79.8379139 L37.4899388,78.7599807 L33.9948332,77.9867706 C32.7168921,77.7040561 31.403165,78.2824598 30.7487452,79.4159481 L29.5980762,81.4089653 C28.7696491,82.8438432 26.9348779,83.3354687 25.5,82.5070416 C24.0651221,81.6786144 23.5734967,79.8438432 24.4019238,78.4089653 L25.5525928,76.4159481 C26.2070126,75.2824598 26.0510613,73.8555369 25.1672529,72.8901647 L22.7500805,70.2499195 L20.1098353,67.8327471 C19.1444631,66.9489387 17.7175402,66.7929874 16.5840519,67.4474072 L14.5910347,68.5980762 C13.1561568,69.4265033 11.3213856,68.9348779 10.4929584,67.5 C9.66453132,66.0651221 10.1561568,64.2303509 11.5910347,63.4019238 L13.5840519,62.2512548 C14.7175402,61.596835 15.2959439,60.2831079 15.0132294,59.0051668 L14.2400193,55.5100612 L13.1620861,52.0966059 C12.7679534,50.8485192 11.6101776,50 10.3013381,50 L8,50 L8,50 C6.34314575,50 5,48.6568542 5,47 C5,45.3431458 6.34314575,44 8,44 L10.3013381,44 C11.6101776,44 12.7679534,43.1514808 13.1620861,41.9033941 L14.2400193,38.4899388 L15.0132294,34.9948332 C15.2959439,33.7168921 14.7175402,32.403165 13.5840519,31.7487452 L11.5910347,30.5980762 L11.5910347,30.5980762 C10.1561568,29.7696491 9.66453132,27.9348779 10.4929584,26.5 C11.3213856,25.0651221 13.1561568,24.5734967 14.5910347,25.4019238 L16.5840519,26.5525928 C17.7175402,27.2070126 19.1444631,27.0510613 20.1098353,26.1672529 L22.7500805,23.7500805 L25.1672529,21.1098353 C26.0510613,20.1444631 26.2070126,18.7175402 25.5525928,17.5840519 L24.4019238,15.5910347 L24.4019238,15.5910347 C23.5734967,14.1561568 24.0651221,12.3213856 25.5,11.4929584 C26.9348779,10.6645313 28.7696491,11.1561568 29.5980762,12.5910347 L30.7487452,14.5840519 C31.403165,15.7175402 32.7168921,16.2959439 33.9948332,16.0132294 L37.4899388,15.2400193 L40.9033941,14.1620861 C42.1514808,13.7679534 43,12.6101776 43,11.3013381 L43,9 L43,9 C43,7.34314575 44.3431458,6 46,6 C47.6568542,6 49,7.34314575 49,9 L49,11.3013381 C49,12.6101776 49.8485192,13.7679534 51.0966059,14.1620861 L54.5100612,15.2400193 L58.0051668,16.0132294 C59.2831079,16.2959439 60.596835,15.7175402 61.2512548,14.5840519 L62.4019238,12.5910347 L62.4019238,12.5910347 C63.2303509,11.1561568 65.0651221,10.6645313 66.5,11.4929584 C67.9348779,12.3213856 68.4265033,14.1561568 67.5980762,15.5910347 L66.4474072,17.5840519 C65.7929874,18.7175402 65.9489387,20.1444631 66.8327471,21.1098353 L69.2499195,23.7500805 L71.8901647,26.1672529 C72.8555369,27.0510613 74.2824598,27.2070126 75.4159481,26.5525928 L77.4089653,25.4019238 C78.8438432,24.5734967 80.6786144,25.0651221 81.5070416,26.5 C82.3354687,27.9348779 81.8438432,29.7696491 80.4089653,30.5980762 L78.4159481,31.7487452 C77.2824598,32.403165 76.7040561,33.7168921 76.9867706,34.9948332 L77.7599807,38.4899388 L78.8379139,41.9033941 C79.2320466,43.1514808 80.3898224,44 81.6986619,44 L84,44 C85.6568542,44 87,45.3431458 87,47 C87,48.6568542 85.6568542,50 84,50 L81.6986619,50 C80.3898224,50 79.2320466,50.8485192 78.8379139,52.0966059 L77.7599807,55.5100612 L76.9867706,59.0051668 C76.7040561,60.2831079 77.2824598,61.596835 78.4159481,62.2512548 L80.4089653,63.4019238 L80.4089653,63.4019238 C81.8438432,64.2303509 82.3354687,66.0651221 81.5070416,67.5 C80.6786144,68.9348779 78.8438432,69.4265033 77.4089653,68.5980762 L75.4159481,67.4474072 C74.2824598,66.7929874 72.8555369,66.9489387 71.8901647,67.8327471 L69.2499195,70.2499195 Z";
    
    NSString *innerCode = @"M48.1171899,45 L34.6858849,24.8905996 L31.3514679,27.1094004 L44.6366332,47 L31.3514679,66.8905996 L34.6858849,69.1094004 L48.1171899,49 L71.0896466,49 L71.0896466,45 L48.1171899,45 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(31, 31), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 0.333333f, 0.333333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, outerCode);
    CGContextRestoreGState(context);
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    CGContextFillEllipseInRect(context, CGRectMake(6.5f, 6.5f + 0.33f, 18.0f - 0.33f, 18.0f - 0.33f));
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    CGContextFillEllipseInRect(context, CGRectMake(8.0f, 8.0f + 0.33f, 15.0f - 0.33f, 15.0f - 0.33f));
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetBlendMode(context, kCGBlendModeClear);

    CGContextScaleCTM(context, 0.333333f, 0.333333f);
    TGDrawSvgPath(context, innerCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)contactsPlusIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake((18.0f) / 2.0f - 1.0f, 0.0f, 1.5f, 18.0f));
    CGContextFillRect(context, CGRectMake(0.0f, (18.0f) / 2.0f - 1.0f, 18.0f, 1.5f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)contactsInviteIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListAddMemberIcon.png"), color);
}

+ (UIImage *)contactsShareIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListInviteIcon.png"), color);
}

+ (UIImage *)contactsNewGroupIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListCreateGroupIcon.png"), color);
}

+ (UIImage *)contactsNewEncryptedIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListCreateSecretChatIcon.png"), color);
}

+ (UIImage *)contactsNewChannelIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListBroadcastIcon.png"), color);
}

+ (UIImage *)contactsUpgradeIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"GroupInfoIconUpgrade.png"), color);
}

+ (UIImage *)contactsInviteLinkIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernContactListInviteFriendsIcon.png"), color);
}

+ (UIImage *)callsNewIcon:(UIColor *)color
{
    return [self _callsIcon:color stroke:true];
}

+ (UIImage *)callsInfoIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"CallInfoIcon.png"), color);
}

+ (UIImage *)callsOutgoingIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"CallOutgoing.png"), color);
}

+ (UIImage *)searchClearIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 14), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 14.0f, 14.0f));
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.3333f);
    
    CGContextMoveToPoint(context, 4.0f, 4.0f);
    CGContextAddLineToPoint(context, 10.0f, 10.0f);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 10.0f, 4.0f);
    CGContextAddLineToPoint(context, 4.0f, 10.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatMutedIcon:(UIColor *)color
{
    NSString *code = @"M9.42822897,7.57177103 L15.9272078,1.07279221 C16.2647733,0.735226725 16.7226103,0.545584412 17.2,0.545584412 C18.1941125,0.545584412 19,1.35147186 19,2.34558441 L19,2.34558441 L19,17.5423659 L27.0820829,25.9612023 C27.6557951,26.5588191 27.6364165,27.5083688 27.0387997,28.082081 C26.4411829,28.6557931 25.4916331,28.6364146 24.917921,28.0387977 L0.917920977,3.03879774 C0.344208826,2.44118092 0.363587392,1.49163117 0.961204216,0.917919018 C1.55882104,0.344206867 2.50837079,0.363585434 3.08208294,0.961202258 L9.42822897,7.57177103 Z M3.29958931,9.08220226 L19,25.4367967 L19,26.6544156 C19,27.1318053 18.8103577,27.5896423 18.4727922,27.9272078 C17.7698485,28.6301515 16.6301515,28.6301515 15.9272078,27.9272078 L15.9272078,27.9272078 L8.29289322,20.2928932 C8.10535684,20.1053568 7.85100293,20 7.58578644,20 L7.58578644,20 L4,20 C2.34314575,20 1,18.6568542 1,17 L1,17 L1,12 L1,12 C1,10.5843213 1.98058202,9.3976698 3.29958931,9.08220226 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10, 10), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.34f, 0.34f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)_encryptedIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(9, 12), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    
    CGContextSetLineWidth(context, 4.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6.0f, 2.0f, 15.0f, 28.0f) cornerRadius:7.5f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0f, 16.0f, 27.0f, 19.0f) cornerRadius:4.0f] fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEncryptedIcon:(UIColor *)color
{
    return [self _encryptedIcon:color];
}

+ (UIImage *)chatVerifiedIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    NSString *code = @"M19.5760653,38.7990895 L14.3219376,40.499918 L14.3219376,40.499918 C12.9203476,40.9536307 11.3967227,40.3225246 10.7264722,39.0106275 L8.21391022,34.0927308 L8.21391022,34.0927308 C7.92669233,33.5305525 7.46944754,33.0733077 6.90726921,32.7860898 L1.98937254,30.2735278 L1.98937254,30.2735278 C0.677475432,29.6032773 0.0463693474,28.0796524 0.500082003,26.6780624 L2.20091049,21.4239347 L2.20091049,21.4239347 C2.39533688,20.8233209 2.39533688,20.1766791 2.20091049,19.5760653 L0.500082003,14.3219376 L0.500082003,14.3219376 C0.0463693474,12.9203476 0.677475432,11.3967227 1.98937254,10.7264722 L6.90726921,8.21391022 L6.90726921,8.21391022 C7.46944754,7.92669233 7.92669233,7.46944754 8.21391022,6.90726921 L10.7264722,1.98937254 L10.7264722,1.98937254 C11.3967227,0.677475432 12.9203476,0.0463693474 14.3219376,0.500082003 L19.5760653,2.20091049 L19.5760653,2.20091049 C20.1766791,2.39533688 20.8233209,2.39533688 21.4239347,2.20091049 L26.6780624,0.500082003 L26.6780624,0.500082003 C28.0796524,0.0463693474 29.6032773,0.677475432 30.2735278,1.98937254 L32.7860898,6.90726921 L32.7860898,6.90726921 C33.0733077,7.46944754 33.5305525,7.92669233 34.0927308,8.21391022 L39.0106275,10.7264722 L39.0106275,10.7264722 C40.3225246,11.3967227 40.9536307,12.9203476 40.499918,14.3219376 L38.7990895,19.5760653 L38.7990895,19.5760653 C38.6046631,20.1766791 38.6046631,20.8233209 38.7990895,21.4239347 L40.499918,26.6780624 L40.499918,26.6780624 C40.9536307,28.0796524 40.3225246,29.6032773 39.0106275,30.2735278 L34.0927308,32.7860898 L34.0927308,32.7860898 C33.5305525,33.0733077 33.0733077,33.5305525 32.7860898,34.0927308 L30.2735278,39.0106275 L30.2735278,39.0106275 C29.6032773,40.3225246 28.0796524,40.9536307 26.6780624,40.499918 L21.4239347,38.7990895 L21.4239347,38.7990895 C20.8233209,38.6046631 20.1766791,38.6046631 19.5760653,38.7990895 Z";
    
    NSString *checkCode = @"M0.666666667,6.53731343 L5.30898243,11.1796292 C5.42409542,11.2947422 5.60515382,11.2896093 5.71109501,11.170737 L15.6666667,0 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 14), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextTranslateCTM(context, 13.0f, 15.0f);
    CGContextSetLineWidth(context, 1.5f * 3.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, checkCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatDeliveredIcon:(UIColor *)color
{
    NSString *code = @"M0,14 L10.7900828,24.7900828 C10.9060169,24.9060169 11.090655,24.8992722 11.1945138,24.7838736 L33.5,0 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.36f, 0.36f);
    
    CGContextTranslateCTM(context, 3.0f, 3.0f);
    CGContextSetLineWidth(context, 4.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatReadIcon:(UIColor *)color
{
    NSString *code = @"M0,14 L10.7900828,24.7900828 C10.9060169,24.9060169 11.090655,24.8992722 11.1945138,24.7838736 L33.5,0 U M22,25 L44.5,0 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.36f, 0.36f);
    
    CGContextTranslateCTM(context, 3.0f, 3.0f);
    CGContextSetLineWidth(context, 4.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatPendingIcon:(UIColor *)color
{
    NSString *code = @"M18.0549043,9 L18.0549043,18.6975509 L13.5,23.4391976 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextStrokeEllipseInRect(context, CGRectMake(1.5f, 1.5f, 33.0f, 33.0f));
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatUnsentIcon:(UIColor *)color
{
    NSString *code = @"M30.3209839,35.4970703 L29.5397339,23.8027344 C29.3932488,21.5240771 29.3200073,19.8883513 29.3200073,18.8955078 C29.3200073,17.5445896 29.6740077,16.4907264 30.382019,15.7338867 C31.0900304,14.977047 32.0218245,14.5986328 33.1774292,14.5986328 C34.5771758,14.5986328 35.5130388,15.0828402 35.9850464,16.0512695 C36.457054,17.0196989 36.6930542,18.4153555 36.6930542,20.2382812 C36.6930542,21.3125054 36.6360886,22.4029893 36.5221558,23.5097656 L35.4723511,35.5458984 C35.3584182,36.9781973 35.11428,38.0768191 34.7399292,38.8417969 C34.3655784,39.6067747 33.747095,39.9892578 32.8844604,39.9892578 C32.0055498,39.9892578 31.3952043,39.6189816 31.0534058,38.878418 C30.7116072,38.1378544 30.467469,37.0107498 30.3209839,35.4970703 Z M33.0309448,51.5615234 C32.0381013,51.5615234 31.1714108,51.2400748 30.4308472,50.597168 C29.6902836,49.9542611 29.3200073,49.0550188 29.3200073,47.8994141 C29.3200073,46.8902944 29.6740077,46.0317418 30.382019,45.3237305 C31.0900304,44.6157191 31.9567209,44.2617188 32.9821167,44.2617188 C34.0075125,44.2617188 34.8823409,44.6157191 35.6066284,45.3237305 C36.3309159,46.0317418 36.6930542,46.8902944 36.6930542,47.8994141 C36.6930542,49.0387427 36.3268469,49.933916 35.5944214,50.5849609 C34.8619958,51.2360059 34.0075122,51.5615234 33.0309448,51.5615234 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22, 22), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetLineWidth(context, 3);
    CGContextStrokeEllipseInRect(context, CGRectMake(1.5f, 1.5f, 63.0f, 63.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatPinnedIcon:(UIColor *)color
{
    NSString *code = @"M8.98099749,11.8025204 C9.0717974,11.0021361 8.89356055,10.3766256 8.44292399,9.92935205 L11.920224,6.45205202 C12.1556312,6.68745918 12.4448457,6.80516276 12.7878675,6.80516276 C13.1308894,6.80516276 13.4234669,6.68745918 13.6555111,6.45205202 C13.8909182,6.21664486 14.0086218,5.92743035 14.0086218,5.5844085 C14.0086218,5.24138664 13.8909182,4.95217213 13.6555111,4.71676497 L9.31393047,0.368458459 C9.07852332,0.133051301 8.78930881,0.0153477218 8.44628695,0.0153477218 C8.10326509,0.0153477218 7.81405058,0.133051301 7.57864342,0.368458459 C7.34323626,0.603865618 7.22553268,0.893080126 7.22553268,1.23610199 C7.22553268,1.57912384 7.34323626,1.86833835 7.57864342,2.10374551 L4.1013434,5.58104554 C3.6540698,5.13377194 3.02855935,4.95553509 2.22817501,5.04633499 C1.42779067,5.13713489 0.748472872,5.459979 0.190221611,6.01823026 C0.0725180317,6.13593384 0.0153477218,6.28054109 0.0153477218,6.45205202 C0.0153477218,6.62356295 0.0758809911,6.76817021 0.19358457,6.88587378 L2.93775944,9.63004866 L0.156592017,13.4369187 C0.0557032347,13.581526 0.0691550723,13.7160443 0.190221611,13.8371109 L0.19694753,13.8438368 C0.25075488,13.8976441 0.318014068,13.9245478 0.395362135,13.9245478 C0.472710201,13.9245478 0.543332348,13.9010071 0.607228577,13.8572886 L4.23249881,10.924788 L7.14482166,13.8371109 C7.26252524,13.9548145 7.40713249,14.0153477 7.57864342,14.0153477 C7.75015435,14.0153477 7.89476161,13.9581774 8.01246519,13.8404738 C8.56735349,13.2822226 8.89019759,12.6029048 8.98099749,11.8025204 Z";

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 14), false, 0.0f);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)chatMentionedIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    NSString *code = @"M36.3010244,14.804 C36.8080244,17.69 36.4570244,20.576 35.3260244,22.955 C34.7410244,24.164 33.9610244,25.178 33.0250244,25.958 C28.4620244,29.702 23.7820244,26.114 22.8850244,23.969 C21.7150244,25.217 19.6870244,25.841 17.9710244,25.841 C13.4860244,25.841 9.85902441,22.292 9.85902441,17.924 C9.85902441,13.556 13.4860244,10.007 17.9710244,10.007 C19.6870244,10.007 21.3640244,10.514 22.7290244,11.489 L22.7290244,10.943 L26.1220244,10.943 L26.1610244,22.019 L26.2000244,22.019 C26.2000244,23.657 29.5930244,26.621 32.3620244,21.59 C33.2980244,19.952 33.3760244,17.612 32.9470244,15.389 C31.5430244,7.628 23.8600244,2.48 15.8260244,3.923 C7.79202441,5.366 2.41002441,12.932 3.81402441,20.693 C5.21802441,28.454 12.9010244,33.641 20.9350244,32.159 C22.2220244,31.925 23.4700244,31.535 24.6790244,31.028 L24.7180244,30.989 L27.0580244,33.641 L26.9800244,33.68 C25.2640244,34.499 23.4310244,35.084 21.5590244,35.396 C19.1410244,35.864 16.7230244,35.864 14.3440244,35.357 C12.0820244,34.85 9.93702441,33.953 7.98702441,32.666 C6.03702441,31.379 4.43802441,29.741 3.15102441,27.83 C1.82502441,25.841 0.928024414,23.657 0.499024414,21.278 C0.0700244141,18.938 0.109024414,16.559 0.694024414,14.258 C1.20102441,11.996 2.17602441,9.929 3.50202441,8.018 C4.86702441,6.107 6.54402441,4.508 8.53302441,3.26 C10.5610244,1.973 12.8230244,1.115 15.2410244,0.686 C17.6590244,0.257 20.0770244,0.257 22.4170244,0.725 C24.7180244,1.232 26.8630244,2.129 28.7740244,3.416 C30.7240244,4.742 32.3620244,6.341 33.6490244,8.252 C34.9750244,10.241 35.8720244,12.425 36.3010244,14.804 Z";
    
    NSString *innerCode = @"M17.9710244,22.526 C20.6230244,22.526 22.7290244,20.459 22.7290244,17.924 C22.7290244,15.428 20.6230244,13.322 17.9710244,13.322 C15.3580244,13.322 13.2130244,15.428 13.2130244,17.924 C13.2130244,20.459 15.3580244,22.526 17.9710244,22.526 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 20.0f, 20.0f));
    CGContextTranslateCTM(context, 4.0f, 4.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    TGDrawSvgPath(context, innerCode);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEditDeleteIcon:(UIColor *)color
{
    NSString *code = @"M39.0015,9 L39.0015,6 C39.0015,2.6865 36.315,0 33.0015,0 L21.0015,0 C17.688,0 15.0015,2.6865 15.0015,6 L15.0015,9 L0,9 L0,12 L3.375,12 L7.4985,70.5 C7.4985,70.5 8.442,75 11.9985,75 L25.4985,75 L28.4985,75 L41.9985,75 C45.5565,75 46.5,70.5 46.5,70.5 L50.5005,12 L54,12 L54,9 L39.0015,9 L39.0015,9 Z";
    
    NSString *innerCode = @"M18.0015,6 C18.0015,4.3425 19.3455,3 21.0015,3 L33.0015,3 C34.6575,3 36.0015,4.344 36.0015,6 L36.0015,9 L18.0015,9 L18.0015,6 L18.0015,6 Z M43.5015,68.9985 C43.2495,71.3175 42,71.9985 42,71.9985 L28.5,71.9985 L25.5,71.9985 L12,71.9985 C12,71.9985 10.752,71.3175 10.5,68.9985 C10.2495,66.6795 6.375,11.9985 6.375,11.9985 L47.3745,11.9985 C47.376,11.9985 43.752,66.6795 43.5015,68.9985 L43.5015,68.9985 Z";
    
    NSString *linesCode = @"M39.0015,18 L36.0015,18 L34.5015,66 L37.5015,66 L39.0015,18 Z M19.5015,66 L18.0015,18 L15,18 L16.5,66 L19.5015,66 Z M25.5,18 L28.5,18 L28.5,66 L25.5,66 L25.5,18 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 25), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    TGDrawSvgPath(context, innerCode);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, linesCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)_muteUnmuteIcon:(bool)mute color:(UIColor *)color
{
    NSString *code = @"M9,39 L9,27 C9,14.5735931 20.5735931,4.5 33,4.5 C45.4264069,4.5 57,14.5716483 57,27 L57,39 C57,54 66,58.5 66,58.5 L66,63 L3.0,63 L0,58.5 C0,58.5 9,54 9,39 Z M25.5,67.5 C25.5,71.6421356 28.8578644,75 33,75 C37.1421356,75 40.5,71.6421356 40.5,67.5 L25.5,67.5 Z";
    
    NSString *innerCode = @"M3,60.1200801 C2.31513867,60.6337713 1.74520985,60.981497 1.34164079,61.1832816 L3,58.5 L3,63 L3.0,60 L66,60 L63,63 L63,58.5 L64.6583592,61.1832816 C64.2547902,60.981497 63.6848613,60.6337713 63,60.1200801 C62.9479192,60.0810161 62.8951738,60.0409923 62.8417864,60 C61.4932586,58.9515915 60.2499985,57.7083313 59.1,56.175 C55.8980336,51.9057115 54,46.2116106 54,39 L54,27 C54,16.5530718 44.1125577,7.5 33,7.5 C21.8882118,7.5 12,16.554317 12,27 L12,39 C12,46.2116106 10.1019664,51.9057115 6.9,56.175 C5.7500015,57.7083313 4.50674138,58.9515915 3.24807184,59.9305567 C3.10482617,60.0409923 3.05208076,60.0810161 3,60.1200801 Z";
    
    NSString *lineInnerCode = @"M7.68198052,0.818019485 L72.1819805,65.3180195 L65.8180195,71.6819805 L1.31801948,7.18198052 Z";
    
    NSString *lineCode = @"M5.56066017,1.93933983 L70.0606602,66.4393398 C71.4748737,67.8535534 69.3535534,69.9748737 67.9393398,68.5606602 L3.43933983,4.06066017 C2.02512627,2.64644661 4.14644661,0.525126266 5.56066017,1.93933983 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 27), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, 2.0f);
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    TGDrawSvgPath(context, innerCode);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetFillColorWithColor(context, color.CGColor);
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(30.0f, 0.0f, 6.0f, 7.33f) cornerRadius:3.0f] fill];
    CGContextFillRect(context, CGRectMake(0.0f, 59.0f, 4.0f, 4.0f));
    CGContextFillRect(context, CGRectMake(62.0f, 59.0f, 4.0f, 4.0f));
    
    if (mute)
    {
        CGContextSaveGState(context);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        CGContextTranslateCTM(context, 1.0f, 0.0f);
        TGDrawSvgPath(context, lineInnerCode);
        CGContextRestoreGState(context);
        
        TGDrawSvgPath(context, lineCode);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEditMuteIcon:(UIColor *)color
{
    return [self _muteUnmuteIcon:true color:color];
}

+ (UIImage *)chatEditUnmuteIcon:(UIColor *)color
{
    return [self _muteUnmuteIcon:false color:color];
}

+ (UIImage *)chatEditPinIcon:(UIColor *)color
{
    NSString *code = @"M45.7904491,0.0606601718 C46.6859491,0.0606601718 47.5296991,0.384660172 48.1341991,0.998160172 L70.0018398,23.1001759 C70.6588398,23.7616759 71.0128398,24.6988009 70.9393398,25.6783009 C70.8418398,27.0133009 70.0033398,28.3550509 68.6893398,29.3345509 L51.1580898,41.2876759 C53.1650898,49.3411759 50.8232148,57.8443009 44.9237148,63.7408009 C44.6297148,64.0348009 44.2295898,64.2095509 43.8455898,64.2095509 C43.4615898,64.2095509 43.1068398,64.0801759 42.8143398,63.7876759 L7.21232414,28.1856602 C6.93032414,27.9036602 6.79044914,27.5050352 6.79044914,27.1075352 C6.79044914,26.7100352 6.93032414,26.3567852 7.21232414,26.0762852 C11.6793241,21.6092852 17.6286991,19.1387852 23.9466991,19.1387852 C25.7871991,19.1387852 27.5976991,19.3266602 29.3841991,19.7481602 L41.8060741,2.31066017 C42.9085741,0.885660172 44.3819491,0.0606601718 45.7904491,0.0606601718 Z M18.6148945,43.8069805 L27.1461445,52.3851055 L2.61948052,70.4898945 C2.34648052,70.7073945 2.00898052,70.8180195 1.68198052,70.8180195 C1.29648052,70.8180195 0.894855515,70.6871445 0.603855515,70.3961445 C0.0653555153,69.8591445 0.0376055153,68.9775195 0.510105515,68.3805195 L18.6148945,43.8069805 Z";
    
    NSString *innerCode = @"M10.4385304,27.1692257 L43.8089702,60.5396656 C48.2093318,55.4701442 49.8834924,48.5793907 48.247121,42.0131138 L47.7419263,39.9859164 L49.4680794,38.8089938 L66.8963766,26.9292893 C67.5607162,26.4340682 67.9184305,25.855193 67.9477504,25.4538171 C67.9554285,25.3514951 67.9236195,25.2649162 67.8692423,25.2101588 L45.9972624,3.10374825 C45.9800997,3.08633007 45.9152382,3.06066017 45.7904491,3.06066017 C45.3756316,3.06066017 44.7431757,3.41699786 44.2494916,4.0512667 L30.6577436,23.1310035 L28.6953049,22.6679932 C27.1858018,22.3118468 25.6124554,22.1387852 23.9466991,22.1387852 C18.9356843,22.1387852 14.1973723,23.9129562 10.4385304,27.1692257 Z M22.5677792,52.0358966 L18.9547618,48.4030275 L8.77661164,62.2160899 L22.5677792,52.0358966 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 26), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, 2.0f);
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    TGDrawSvgPath(context, innerCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEditUnpinIcon:(UIColor *)color
{
    NSString *code = @"M45.7904491,0.0606601718 C46.6859491,0.0606601718 47.5296991,0.384660172 48.1341991,0.998160172 L70.0018398,23.1001759 C70.6588398,23.7616759 71.0128398,24.6988009 70.9393398,25.6783009 C70.8418398,27.0133009 70.0033398,28.3550509 68.6893398,29.3345509 L51.1580898,41.2876759 C53.1650898,49.3411759 50.8232148,57.8443009 44.9237148,63.7408009 C44.6297148,64.0348009 44.2295898,64.2095509 43.8455898,64.2095509 C43.4615898,64.2095509 43.1068398,64.0801759 42.8143398,63.7876759 L7.21232414,28.1856602 C6.93032414,27.9036602 6.79044914,27.5050352 6.79044914,27.1075352 C6.79044914,26.7100352 6.93032414,26.3567852 7.21232414,26.0762852 C11.6793241,21.6092852 17.6286991,19.1387852 23.9466991,19.1387852 C25.7871991,19.1387852 27.5976991,19.3266602 29.3841991,19.7481602 L41.8060741,2.31066017 C42.9085741,0.885660172 44.3819491,0.0606601718 45.7904491,0.0606601718 Z M18.6148945,43.8069805 L27.1461445,52.3851055 L2.61948052,70.4898945 C2.34648052,70.7073945 2.00898052,70.8180195 1.68198052,70.8180195 C1.29648052,70.8180195 0.894855515,70.6871445 0.603855515,70.3961445 C0.0653555153,69.8591445 0.0376055153,68.9775195 0.510105515,68.3805195 L18.6148945,43.8069805 Z";
    
    NSString *innerCode = @"M10.4385304,27.1692257 L43.8089702,60.5396656 C48.2093318,55.4701442 49.8834924,48.5793907 48.247121,42.0131138 L47.7419263,39.9859164 L49.4680794,38.8089938 L66.8963766,26.9292893 C67.5607162,26.4340682 67.9184305,25.855193 67.9477504,25.4538171 C67.9554285,25.3514951 67.9236195,25.2649162 67.8692423,25.2101588 L45.9972624,3.10374825 C45.9800997,3.08633007 45.9152382,3.06066017 45.7904491,3.06066017 C45.3756316,3.06066017 44.7431757,3.41699786 44.2494916,4.0512667 L30.6577436,23.1310035 L28.6953049,22.6679932 C27.1858018,22.3118468 25.6124554,22.1387852 23.9466991,22.1387852 C18.9356843,22.1387852 14.1973723,23.9129562 10.4385304,27.1692257 Z M22.5677792,52.0358966 L18.9547618,48.4030275 L8.77661164,62.2160899 L22.5677792,52.0358966 Z M7.82842712,2.17157288 L72.3284271,66.6715729 C76.0996633,70.442809 70.442809,76.0996633 66.6715729,72.3284271 L2.17157288,7.82842712 C-1.59966329,4.05719096 4.05719096,-1.59966329 7.82842712,2.17157288 Z";
    
    NSString *lineCode = @"M4.06066017,1.93933983 L68.5606602,66.4393398 C69.9748737,67.8535534 67.8535534,69.9748737 66.4393398,68.5606602 L1.93933983,4.06066017 C0.525126266,2.64644661 2.64644661,0.525126266 4.06066017,1.93933983 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 26), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, 2.0f);
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    TGDrawSvgPath(context, innerCode);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, lineCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEditGroupIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(26, 26), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, 2.0f);
    
    //CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    //CGCo
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    
    CGContextStrokeEllipseInRect(context, CGRectMake(9.0f, 5.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(45.0f, 5.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(9.0f, 41.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(45.0f, 41.0f, 29.0f, 29.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatEditUngroupIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(26, 26), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0f, 2.0f);
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    
    CGContextStrokeEllipseInRect(context, CGRectMake(9.0f, 5.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(45.0f, 5.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(9.0f, 41.0f, 29.0f, 29.0f));
    CGContextStrokeEllipseInRect(context, CGRectMake(45.0f, 41.0f, 29.0f, 29.0f));
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(context, 4.0f);
    
    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, 78.0f, 78.0f);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, 78.0f, 78.0f);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatsLockBaseIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10, 7), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0f, 0.0f, 10.0f, 7.0f) cornerRadius:1.33f] fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatsLockTopIcon:(UIColor *)color active:(bool)active
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(7, 6), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 1.5f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.75f, 0.75f, 5.5f, 12.0f) cornerRadius:2.5f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    
    if (!active)
    {
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        
        CGContextFillRect(context, CGRectMake(4.0f, 5.33f, 3.0f, 2.0f));
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatsProxyIcon:(UIColor *)color connected:(bool)connected onlyShield:(bool)onlyShield
{
    NSString *shieldCode = @"M27,1.6414763 L1.5,12.9748096 L1.5,30 C1.5,45.9171686 12.4507463,60.7063193 27,64.4535514 C41.5492537,60.7063193 52.5,45.9171686 52.5,30 L52.5,12.9748096 L27,1.6414763 S";
    NSString *onCode = @"M27,47 C34.7319865,47 41,40.7319865 41,33 C41,25.2680135 34.7319865,19 27,19 C19.2680135,19 13,25.2680135 13,33 U";
    NSString *checkCode = @"M15.5769231,34.1735387 L23.5896918,42.2164446 C23.6840928,42.3112006 23.8352513,42.30478 23.9262955,42.2032393 L40.5,23.71875 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 22), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    
    TGDrawSvgPath(context, shieldCode);
    
    if (!onlyShield)
    {
        if (connected)
        {
            TGDrawSvgPath(context, checkCode);
        }
        else
        {
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(26.0f - 0.5f, 15.0f, 3.0f, 15.0f) cornerRadius:1.5f];
            CGContextAddPath(context, path.CGPath);
            CGContextFillPath(context);
            
            CGContextTranslateCTM(context, 18.0f * 1.5f, 22.0f * 1.5f);
            CGContextRotateCTM(context, M_PI_2 + M_PI_4);
            CGContextTranslateCTM(context, -18.0f * 1.5f, -22.0f * 1.5f);
            TGDrawSvgPath(context, onCode);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatsProxySpinner:(UIColor *)color
{
    NSString *onCode = @"M27,47 C34.7319865,47 41,40.7319865 41,33 C41,25.2680135 34.7319865,19 27,19 C19.2680135,19 13,25.2680135 13,33 U";
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 22), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    
    TGDrawSvgPath(context, onCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatTitleMutedIcon:(UIColor *)color
{
    return [self chatMutedIcon:color];
}

+ (UIImage *)chatTitleEncryptedIcon:(UIColor *)color
{
    return [self _encryptedIcon:color];
}

+ (UIImage *)chatTitleLiveLocationIcon:(UIColor *)color active:(bool)active
{
    return active ? TGTintedImage(TGImageNamed(@"LiveLocationTitlePin"), color) : TGTintedImage(TGImageNamed(@"LiveLocationTitleIcon"), color);
}

+ (UIImage *)chatTitleMuteIcon:(UIColor *)color
{
    return [self _muteUnmuteIcon:true color:color];
}

+ (UIImage *)chatTitleUnmuteIcon:(UIColor *)color
{
    return [self _muteUnmuteIcon:false color:color];
}

+ (UIImage *)chatTitleSearchIcon:(UIColor *)color
{
    NSString *code = @"M72.5,72.5 L92,92 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(25, 25), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -8.0f, -7.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 6.0f);
    TGDrawSvgPath(context, code);
    
    CGContextSetLineWidth(context, 3.0f);
    CGContextStrokeEllipseInRect(context, CGRectMake(26.0f, 26.0f, 53.0f, 53.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatTitleReportIcon:(UIColor *)color
{
    NSString *code = @"M57.3010254,65.8984375 L56.5197754,54.2041016 C56.3732903,51.9254443 56.3000488,50.2897185 56.3000488,49.296875 C56.3000488,47.9459568 56.6540492,46.8920936 57.3620605,46.1352539 C58.0700719,45.3784142 59.001866,45 60.1574707,45 C61.5572173,45 62.4930803,45.4842074 62.9650879,46.4526367 C63.4370955,47.421066 63.6730957,48.8167227 63.6730957,50.6396484 C63.6730957,51.7138726 63.6161301,52.8043564 63.5021973,53.9111328 L62.4523926,65.9472656 C62.3384597,67.3795645 62.0943215,68.4781863 61.7199707,69.2431641 C61.3456199,70.0081418 60.7271365,70.390625 59.864502,70.390625 C58.9855913,70.390625 58.3752458,70.0203488 58.0334473,69.2797852 C57.6916487,68.5392216 57.4475105,67.4121169 57.3010254,65.8984375 Z M60.0109863,81.9628906 C59.0181428,81.9628906 58.1514523,81.641442 57.4108887,80.9985352 C56.6703251,80.3556283 56.3000488,79.456386 56.3000488,78.3007812 C56.3000488,77.2916616 56.6540492,76.433109 57.3620605,75.7250977 C58.0700719,75.0170863 58.9367625,74.6630859 59.9621582,74.6630859 C60.987554,74.6630859 61.8623824,75.0170863 62.5866699,75.7250977 C63.3109574,76.433109 63.6730957,77.2916616 63.6730957,78.3007812 C63.6730957,79.4401099 63.3068884,80.3352832 62.5744629,80.9863281 C61.8420374,81.637373 60.9875537,81.9628906 60.0109863,81.9628906 Z M57.86981,28.3335289 L22.0213699,86.6914547 C21.2986803,87.8679262 21.6665432,89.4075004 22.8430146,90.13019 C23.2366499,90.3719945 23.6895877,90.5 24.1515599,90.5 L95.8484401,90.5 C97.229152,90.5 98.3484401,89.3807119 98.3484401,88 C98.3484401,87.5380279 98.2204347,87.0850901 97.9786301,86.6914547 L62.13019,28.3335289 C61.4075004,27.1570575 59.8679262,26.7891946 58.6914547,27.5118842 C58.356842,27.717432 58.0753578,27.9989162 57.86981,28.3335289 S";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 30), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -4.0f, -4.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 3.0f);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatTitleInfoIcon:(UIColor *)color
{
    NSString *code= @"M60,49.5 C62.4852814,49.5 64.5,47.4852814 64.5,45 C64.5,42.5147186 62.4852814,40.5 60,40.5 C57.5147186,40.5 55.5,42.5147186 55.5,45 C55.5,47.4852814 57.5147186,49.5 60,49.5 Z M63,76.5 L66,76.5 L66,78 L54,78 L54,76.5 L57,76.5 L57,52.5 L63,52.5 L63,76.5 Z M54,52.5 L57,52.5 L57,54 L54,54 L54,52.5 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(24, 24), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextTranslateCTM(context, -24.0f, -24.0f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 3.0f);
    TGDrawSvgPath(context, code);
    
    CGContextStrokeEllipseInRect(context, CGRectMake(27.5f, 27.5f, 65.0f, 65.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatTitleCallIcon:(UIColor *)color
{
    return [self _callsIcon:color stroke:true];
}

+ (UIImage *)chatTitleGroupIcon:(UIColor *)color
{
    return [self chatEditGroupIcon:color];
}

+ (UIImage *)chatSearchNextIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InlineSearchUp.png"), color);
}

+ (UIImage *)chatSearchPreviousIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InlineSearchDown.png"), color);
}

+ (UIImage *)chatSearchCalendarIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationSearchCalendar.png"), color);
}

+ (UIImage *)chatSearchNameIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationSearchUser.png"), color);
}

+ (UIImage *)chatPlaceholderEncryptedIcon
{
    return [self _encryptedIcon:[UIColor whiteColor]];
}

+ (UIImage *)chatBubbleFull:(UIColor *)color borderColor:(UIColor *)borderColor outgoing:(bool)outgoing
{
    NSString *code = @"M98.9898269,45.5175307 C98.4669332,20.2898891 77.8529454,0 52.5,0 L52.5,0 L46.5,0 L46.5,0 C20.8187591,0 0,20.8187591 0,46.5 L0,46.5 L0,46.5 C0,72.1812409 20.8187591,93 46.5,93 L52.5,93 C63.4281796,93 73.475875,89.2301985 81.4135902,82.9200913 C89.2183311,91.030032 103.215929,92.6305181 109.680374,92.9265773 C111.202766,92.9962999 112.30736,92.9936773 112.814875,92.9866937 C113.019729,92.9838748 113.043082,92.9866937 113.043082,92.9866937 C99.0430817,83.9870161 99,69.5848507 99,69.5848507 L99,45.5 L98.9898269,45.5175307";
    
    NSString *fillCode = [code stringByAppendingString:@" Z"];
    NSString *strokeCode = [code stringByAppendingString:@" S"];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 33), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    if (!outgoing)
    {
        CGContextScaleCTM(context, -1.0f, 1.0f);
        CGContextTranslateCTM(context, -38.0f * 3.0f - 3.0f, 3.0f);
    }
    else
    {
        CGContextTranslateCTM(context, 3.0f, 3.0f);
    }
    CGContextSetLineWidth(context, TGScreenPixel * 2 * 3.0f);

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    if (borderColor != nil)
        TGDrawSvgPath(context, strokeCode);
    TGDrawSvgPath(context, fillCode);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image stretchableImageWithLeftCapWidth:outgoing ? 17 : 23 topCapHeight:16];
}

+ (UIImage *)chatBubblePartial:(UIColor *)color borderColor:(UIColor *)borderColor outgoing:(bool)outgoing
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40, 33), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGPoint origin = CGPointMake(outgoing ? 1.0f : 6.0f, 1.0f);
    CGContextSetLineWidth(context, TGScreenPixel * 2);
    if (borderColor != nil)
        CGContextStrokeEllipseInRect(context, CGRectMake(origin.x, origin.y, 33.0f, 31.0f));
    CGContextFillEllipseInRect(context, CGRectMake(origin.x, origin.y, 33.0f, 31.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image stretchableImageWithLeftCapWidth:outgoing ? 17 : 23 topCapHeight:16];
}

+ (UIImage *)chatBubbleImage:(UIColor *)color borderColor:(UIColor *)borderColor outgoing:(bool)outgoing hasTail:(bool)hasTail
{
    if (hasTail)
        return [self chatBubbleFull:color borderColor:borderColor outgoing:outgoing];
    else
        return [self chatBubblePartial:color borderColor:borderColor outgoing:outgoing];
}

+ (UIImage *)chatRoundMessageBackgroundImage:(UIColor *)color borderColor:(UIColor *)borderColor
{
    CGSize roundSize = [TGRoundMessageViewModel roundSize];
    UIGraphicsBeginImageContextWithOptions(roundSize, false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, TGScreenPixel);
    
    CGRect rect = CGRectInset(CGRectMake(0.0f, 0.0f, roundSize.width, roundSize.height), TGScreenPixel, TGScreenPixel);
    CGContextFillEllipseInRect(context, rect);
    CGContextStrokeEllipseInRect(context, rect);
    
    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return backgroundImage;
}

+ (UIImage *)chatPlaceholderBackgroundImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30.0f, 30.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 30.0f, 30.0f));
    
    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:15 topCapHeight:15];
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatUnreadBackgroundImage:(UIColor *)color borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 25), false, 0.0f);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 1.0f, 25.0f));
    
    if (borderColor != nil)
    {
        CGContextSetFillColorWithColor(context, borderColor.CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 1.0f, 1.0f));
        CGContextFillRect(context, CGRectMake(0.0f, 24.0f, 1.0f, 1.0f));
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatSystemBackgroundImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(21, 21), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect bounds = CGRectMake(0.5f, 0, 20, 20);
    
    CGFloat radius = 0.5f * CGRectGetHeight(bounds);
    
    CGMutablePathRef visiblePath = CGPathCreateMutable();
    CGRect innerRect = CGRectInset(bounds, radius, radius);
    CGPathMoveToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x + innerRect.size.width, bounds.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, bounds.origin.y, bounds.origin.x + bounds.size.width, innerRect.origin.y, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, innerRect.origin.y + innerRect.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height, innerRect.origin.x + innerRect.size.width, bounds.origin.y + bounds.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y + bounds.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y + bounds.size.height, bounds.origin.x, innerRect.origin.y + innerRect.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x, innerRect.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y, innerRect.origin.x, bounds.origin.y, radius);
    CGPathCloseSubpath(visiblePath);
    
    CGContextSaveGState(context);
    
    [color setFill];
    CGContextAddPath(context, visiblePath);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(bounds, -2, -2));
    
    CGPathAddPath(path, NULL, visiblePath);
    CGPathCloseSubpath(path);
    
    CGContextAddPath(context, visiblePath);
    CGContextClip(context);
    
    CGContextSaveGState(context);
    
    [color setFill];
    CGContextAddPath(context, path);
    CGContextEOFillPath(context);
    
    CGContextRestoreGState(context);
    
    CGPathRelease(path);
    CGPathRelease(visiblePath);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width / 2) topCapHeight:(int)(image.size.height / 2)];
    
    return image;
}

+ (UIImage *)chatReplyBackgroundImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16.0f, 16.0f), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, 16.0f, 16.0f);
    
    CGFloat radius = 0.5f * CGRectGetHeight(bounds);
    
    CGMutablePathRef visiblePath = CGPathCreateMutable();
    CGRect innerRect = CGRectInset(bounds, radius, radius);
    CGPathMoveToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x + innerRect.size.width, bounds.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, bounds.origin.y, bounds.origin.x + bounds.size.width, innerRect.origin.y, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, innerRect.origin.y + innerRect.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height, innerRect.origin.x + innerRect.size.width, bounds.origin.y + bounds.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, innerRect.origin.x, bounds.origin.y + bounds.size.height);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y + bounds.size.height, bounds.origin.x, innerRect.origin.y + innerRect.size.height, radius);
    CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x, innerRect.origin.y);
    CGPathAddArcToPoint(visiblePath, NULL,  bounds.origin.x, bounds.origin.y, innerRect.origin.x, bounds.origin.y, radius);
    CGPathCloseSubpath(visiblePath);
    
    CGContextSaveGState(context);
    
    [color setFill];
    CGContextAddPath(context, visiblePath);
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(bounds, -2, -2));
    
    CGPathAddPath(path, NULL, visiblePath);
    CGPathCloseSubpath(path);
    
    CGContextAddPath(context, visiblePath);
    CGContextClip(context);
    
    CGContextSaveGState(context);

    [color setFill];
    CGContextAddPath(context, path);
    CGContextEOFillPath(context);
    
    CGContextRestoreGState(context);
    
    CGPathRelease(path);
    CGPathRelease(visiblePath);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width / 2) topCapHeight:(int)(image.size.height / 2)];
    
    return image;
}

+ (UIImage *)chatActionShareImage:(UIColor *)color backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(29.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 29.0f, 29.0f));
    
    if (borderColor != nil)
    {
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, 28.0f, 28.0f));
    }
    
    UIImage *iconImage = TGTintedImage(TGImageNamed(@"ConversationChannelInlineShareIcon.png"), color);
    [iconImage drawAtPoint:CGPointMake(CGFloor((29.0f - iconImage.size.width) / 2.0f), CGFloor((29.0f - iconImage.size.height) / 2.0f))];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatActionReplyImage:(UIColor *)color backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(33.0f, 33.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 33.0f, 33.0f));
    
    if (borderColor != nil)
    {
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, 32.0f, 32.0f));
    }
    
    CGContextTranslateCTM(context, 33.0f, 0);
    CGContextScaleCTM(context, -1.0, 1.0);
    UIImage *iconImage = TGTintedImage(TGImageNamed(@"ConversationChannelInlineShareIcon.png"), color);
    [iconImage drawAtPoint:CGPointMake(CGFloor((33.0f - iconImage.size.width) / 2.0f), CGFloor((33.0f - iconImage.size.height) / 2.0f))];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatActionGoToImage:(UIColor *)color backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(29.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 29.0f, 29.0f));
    
    if (borderColor != nil)
    {
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, 28.0f, 28.0f));
    }
    
    UIImage *iconImage = TGTintedImage(TGImageNamed(@"ConversationGoToIcon.png"), color);
    [iconImage drawAtPoint:CGPointMake(CGFloor((29.0f - iconImage.size.width) / 2.0f), CGFloor((29.0f - iconImage.size.height) / 2.0f) + 1.0f)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatReplyButtonImage:(UIColor *)color borderColor:(UIColor *)borderColor
{
    CGFloat size = 14.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, size, size));

    if (borderColor != nil)
    {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, 1.0f);
        CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, size - 1.0f, size - 1.0f));
    }
    
    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:(NSInteger)(size / 2.0f) topCapHeight:(NSInteger)(size / 2.0f)];
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatReplyButtonUrlIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(8.0f, 8.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat lineWidth = 1.5f;
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextMoveToPoint(context, lineWidth / 2.0f, lineWidth / 2.0f);
    CGContextAddLineToPoint(context, 8.0f - lineWidth / 2.0f, lineWidth / 2.0f);
    CGContextAddLineToPoint(context, 8.0f - lineWidth / 2.0f, 8.0f - lineWidth / 2.0f);
    CGContextStrokePath(context);
    CGContextMoveToPoint(context, lineWidth / 2.0f, 8.0f - lineWidth / 2.0f);
    CGContextAddLineToPoint(context, 8.0f - lineWidth / 2.0f, lineWidth / 2.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatReplyButtonPhoneIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"botbutton_phone.png"), color);
}

+ (UIImage *)chatReplyButtonLocationIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"botbutton_location.png"), color);
}

+  (UIImage *)chatReplyButtonSwitchInlineIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"botbutton_share.png"), color);
}

+ (UIImage *)chatReplyButtonActionIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"botbutton_msg.png"), color);
}

+ (UIImage *)chatCallIcon:(UIColor *)color
{
    return [self _callsIcon:color stroke:true];
}

+ (UIImage *)chatClockFrameIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextSetLineWidth(context, 1.0f);
    CGContextStrokeEllipseInRect(context, CGRectMake(2.5f, 2.5f, 10.0f, 10.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatClockHourIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextMoveToPoint(context, 7.5f, 4.5f);
    CGContextAddLineToPoint(context, 7.5f, 7.5f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatClockMinuteIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextMoveToPoint(context, 7.5f, 7.5f);
    CGContextAddLineToPoint(context, 11.0f, 7.5f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatDeliveredMessageIcon:(UIColor * )color
{
    NSString *code = @"M41,61.0505996 L50.0121078,69.9446719 L50.0121078,69.9446719 C50.0907258,70.0222602 50.2173561,70.0214254 50.2949444,69.9428074 C50.2960613,69.9416757 50.2971648,69.9405306 50.2982544,69.9393725 L70,49 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.36f, 0.36f);
    
    CGContextTranslateCTM(context, -39.0f, -46.0f);
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatReadMessageIcon:(UIColor *)color
{
    NSString *code = @"M61,70 L81,49 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.36f, 0.36f);
    
    CGContextTranslateCTM(context, -51.0f, -46.0f);
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatUnsentMessageIcon:(UIColor *)color color:(UIColor *)iconColor
{
    NSString *code = @"M30.3209839,35.4970703 L29.5397339,23.8027344 C29.3932488,21.5240771 29.3200073,19.8883513 29.3200073,18.8955078 C29.3200073,17.5445896 29.6740077,16.4907264 30.382019,15.7338867 C31.0900304,14.977047 32.0218245,14.5986328 33.1774292,14.5986328 C34.5771758,14.5986328 35.5130388,15.0828402 35.9850464,16.0512695 C36.457054,17.0196989 36.6930542,18.4153555 36.6930542,20.2382812 C36.6930542,21.3125054 36.6360886,22.4029893 36.5221558,23.5097656 L35.4723511,35.5458984 C35.3584182,36.9781973 35.11428,38.0768191 34.7399292,38.8417969 C34.3655784,39.6067747 33.747095,39.9892578 32.8844604,39.9892578 C32.0055498,39.9892578 31.3952043,39.6189816 31.0534058,38.878418 C30.7116072,38.1378544 30.467469,37.0107498 30.3209839,35.4970703 Z M33.0309448,51.5615234 C32.0381013,51.5615234 31.1714108,51.2400748 30.4308472,50.597168 C29.6902836,49.9542611 29.3200073,49.0550188 29.3200073,47.8994141 C29.3200073,46.8902944 29.6740077,46.0317418 30.382019,45.3237305 C31.0900304,44.6157191 31.9567209,44.2617188 32.9821167,44.2617188 C34.0075125,44.2617188 34.8823409,44.6157191 35.6066284,45.3237305 C36.3309159,46.0317418 36.6930542,46.8902944 36.6930542,47.8994141 C36.6930542,49.0387427 36.3268469,49.933916 35.5944214,50.5849609 C34.8619958,51.2360059 34.0075122,51.5615234 33.0309448,51.5615234 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22, 22), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 66.0f, 66.0f));

    CGContextSetFillColorWithColor(context, iconColor.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatMessageViewsIcon:(UIColor *)color
{
    CGFloat alpha = 1.0f;
    if (![color getRed:nil green:nil blue:nil alpha:&alpha])
        [color getWhite:nil alpha:&alpha];
    
    UIImage *tintedImage = TGTintedImage(TGImageNamed(@"MessageInlineViewCountIconMedia.png"), [color colorWithAlphaComponent:1.0f]);
    if (alpha > 1.0f - FLT_EPSILON)
    {
        return tintedImage;
    }
    else
    {
        UIGraphicsBeginImageContextWithOptions(tintedImage.size, false, 0.0f);
        [tintedImage drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:alpha];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

+ (UIImage *)chatInstantViewIcon:(UIColor *)color
{
    NSString *code = @"M62.4237573,56.242532 L68.6008574,45.3138164 C69.9641724,42.9017976 69.2490118,42.2787106 67.0133901,43.9046172 L50.6790537,55.7841346 C49.7933206,56.4283042 49.7678266,57.5101414 50.6393204,58.18797 L57.6989251,63.6787736 L51.521825,74.6074892 C50.15851,77.019508 50.8736706,77.642595 53.1092923,76.0166884 L69.4436287,64.137171 C70.3293618,63.4930014 70.3548559,62.4111642 69.483362,61.7333356 L62.4237573,56.242532 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(9, 12), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextTranslateCTM(context, -45.0f, -44.0f);
    CGContextSetFillColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)chatMentionsButton:(UIColor *)color backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(38.0f, 38.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.5f, 0.5f, 37.0f, 37.0f));
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, TGScreenPixel);
    CGContextStrokeEllipseInRect(context, CGRectMake(0.25f, 0.25f, 37.5f, 37.5f));
    
    UIImage *icon = TGTintedImage(TGImageNamed(@"ChatNavigateToUnseenMentionsIcon.png"), color);
    [icon drawAtPoint:CGPointMake(CGFloor((38.0f - icon.size.width) / 2.0f), CGFloor((38.0f - icon.size.height) / 2.0f))];
   
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)chatDownButton:(UIColor *)color backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(38.0f, 38.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.5f, 0.5f, 37.0f, 37.0f));
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, TGScreenPixel);
    CGContextStrokeEllipseInRect(context, CGRectMake(0.25f, 0.25f, 37.5f, 37.5f));
    
    CGFloat arrowLineWidth = 1.5f;
    CGFloat scale = (int)TGScreenScaling();
    if (scale >= 3.0)
        arrowLineWidth = 5.0f / 3.0f;
    
    CGContextSetLineWidth(context, arrowLineWidth);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextBeginPath(context);
    CGPoint position = CGPointMake(9.0f - TGRetinaPixel, 15.0f);
    CGContextMoveToPoint(context, position.x + 1.0f, position.y + 1.0f);
    CGContextAddLineToPoint(context, position.x + 10.0f, position.y + 10.0f);
    CGContextAddLineToPoint(context, position.x + 19.0f, position.y + 1.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)chatDeleteIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernConversationActionDelete.png"), color);
}

+ (UIImage *)chatShareIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ActionsWhiteIcon"), color);
}

+ (UIImage *)chatForwardIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernConversationActionForward.png"), color);
}

+ (UIImage *)inputPanelFieldBackground:(UIColor *)color borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(33, 33), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    
    CGContextSetLineWidth(context, 1.0f);
    CGRect rect = CGRectMake(0.5f, 0.5f, 32.0f, 32.0f);
    CGContextFillEllipseInRect(context, rect);
    CGContextStrokeEllipseInRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image stretchableImageWithLeftCapWidth:16 topCapHeight:16];
}

+ (UIImage *)inputPanelAttachIcon:(UIColor *)color accentColor:(UIColor *)accentColor
{
    NSString *code = @"M63.5084258,47.1736444 L46.1818644,64.3732581 C42.6551823,67.874101 42.6501313,73.5450748 46.1843277,77.0533769 L46.0546538,76.9246531 C49.5826963,80.4268464 55.3002588,80.4293526 58.8309565,76.9245234 L82.1903763,53.7362527 C88.4607317,47.5118387 88.4555115,37.414888 82.8995295,31.8996133 L82.8995295,31.8996133 L82.7705247,31.7715537 C76.4976538,25.5446426 66.3304974,25.541489 60.060003,31.766041 L36.7280964,54.9270001 C27.9458841,63.6448672 27.9414991,77.7749696 36.7272423,86.4963418 L36.5419919,86.3124486 C45.3237325,95.0298475 59.5643416,95.0272721 68.336344,86.3195401 L85.6397976,69.1428648 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 30), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -5.0f, -5.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetLineWidth(context, 5.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    if (accentColor != nil)
    {
        CGContextTranslateCTM(context, 51.0f, 45.0f);
        code = @"M17,12.5706686 L17,0 L30.8544849,13.8544849 C38.5953555,17.2617212 44,24.9996994 44,34 C44,46.1502645 34.1502645,56 22,56 C9.8497355,56 0,46.1502645 0,34 C0,23.5696354 7.25858699,14.8346046 17,12.5706686 Z";
        CGContextSetBlendMode(context, kCGBlendModeClear);
        TGDrawSvgPath(context, code);
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextSetStrokeColorWithColor(context, accentColor.CGColor);
        code = @"M36,34 C36,36.9179632 35.1072962,39.6274244 33.5800985,41.8701734 C31.0605447,45.5702359 26.8140232,48 22,48 C14.2680135,48 8,41.7319865 8,34 C8,26.2680135 15,20 22,20 U";
        TGDrawSvgPath(context, code);
        
        CGContextSetFillColorWithColor(context, accentColor.CGColor);
        code = @"M22,12 L22,28 L30,20 Z";
        TGDrawSvgPath(context, code);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)inputPanelSendIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    NSString *code = @"M33,44 L49.2911562,28.2025152 L49.2911562,28.2025152 C49.4075223,28.0896753 49.5924777,28.0896753 49.7088438,28.2025152 L66,44 U M49.5,28 C51.1568542,28 52.5,29.3431458 52.5,31 L52.5,72 C52.5,73.6568542 51.1568542,75 49.5,75 C47.8431458,75 46.5,73.6568542 46.5,72 L46.5,31 C46.5,29.3431458 47.8431458,28 49.5,28 Z";

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(33, 33), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 33.0f, 33.0f));
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetLineWidth(context, 6.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)inputPanelConfirmIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    NSString *code = @"M28,51.8059701 L42.5672395,66.3732097 C42.6826007,66.4885708 42.8628212,66.4857542 42.9771136,66.3587627 L73,33 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(33, 33), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 33.0f, 33.0f));
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetLineWidth(context, 6.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)inputPanelMicrophoneIcon:(UIColor *)color
{
    NSString *arcCode = @"M34.9964878,61 C35,73 45,85 60,85 C75,85 85,73 85,61 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 30), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -5.0f, -5.0f);
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetLineWidth(context, 5.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(47.5f, 26.5f, 25.0f, 46.0f) cornerRadius:12.5f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);

    path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(57.5f, 85.0f, 5.0f, 14.0f) cornerRadius:2.5f];
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    
    TGDrawSvgPath(context, arcCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)inputPanelVideoMessageIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(30, 30), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetLineWidth(context, 5.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(12.5f, 12.5f, 65.0f, 65.0f) cornerRadius:20.5f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    
    CGContextStrokeEllipseInRect(context, CGRectMake(29.5f, 29.5f, 31.0f, 31.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)inputPanelArrowIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"StickersTabArrow"), color);
}

+ (UIImage *)inputPanelStickersIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationInputFieldStickerIcon.png"), color);
}

+ (UIImage *)inputPanelKeyboardIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationInputFieldKeyboardIcon.png"), color);
}

+ (UIImage *)inputPanelCommandsIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationInputFieldCommandIcon.png"), color);
}

+ (UIImage *)inputPanelBotKeyboardIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ConversationInputFieldActionsIcon.png"), color);
}

+ (UIImage *)inputPanelBroadcastIcon:(UIColor *)color active:(bool)active
{
    return TGTintedImage(active ? TGImageNamed(@"ConversationInputFieldBroadcastIconActive.png") : TGImageNamed(@"ConversationInputFieldBroadcastIconInactive.png"), color);
}

+ (UIImage *)inputPanelTimerIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ModernConversationSecretAccessoryTimer.png"), color);
}

+ (UIImage *)inputPanelClearIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 14), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 14.0f, 14.0f));
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.3333f);
    
    CGContextMoveToPoint(context, 4.0f, 4.0f);
    CGContextAddLineToPoint(context, 10.0f, 10.0f);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 10.0f, 4.0f);
    CGContextAddLineToPoint(context, 4.0f, 10.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)replyCloseIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(9, 9), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.3333f);
    
    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, 9.0f, 9.0f);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 9.0f, 0.0f);
    CGContextAddLineToPoint(context, 0.0f, 9.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)pinCloseIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.3333f);
    
    CGContextMoveToPoint(context, 2.0f, 2.0f);
    CGContextAddLineToPoint(context, 13.0f, 13.0f);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, 13.0f, 2.0f);
    CGContextAddLineToPoint(context, 2.0f, 13.0f);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)stickersGifIcon:(UIColor *)color
{
    return TGTintedImage(TGComponentsImageNamed(@"StickerKeyboardGifIcon.png"), color);
}

+ (UIImage *)stickersTrendingIcon:(UIColor *)color
{
    return TGTintedImage(TGComponentsImageNamed(@"StickerKeyboardTrendingIcon.png"), color);
}

+ (UIImage *)stickersRecentIcon:(UIColor *)color
{
    return TGTintedImage(TGComponentsImageNamed(@"StickerKeyboardRecentTab.png"), color);
}

+ (UIImage *)stickersFavoritesIcon:(UIColor *)color
{
    return TGTintedImage(TGComponentsImageNamed(@"StickerKeyboardFavoriteTab.png"), color);
}

+ (UIImage *)stickersSettingsIcon:(UIColor *)color
{
    return TGTintedImage(TGComponentsImageNamed(@"StickerKeyboardSettingsIcon.png"), color);
}

+ (UIImage *)stickersHollowButton:(UIColor *)color radius:(CGFloat)radius
{
    CGSize size = CGSizeMake(radius * 2.0f, radius * 2.0f);
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.0f);
    CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, size.width - 1.0f, size.height - 1.0f));
    
    UIImage *buttonImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:(NSInteger)(size.width / 2.0f) topCapHeight:(NSInteger)(size.height / 2.0f)];
    UIGraphicsEndImageContext();
    
    return buttonImage;
}

+ (UIImage *)stickersPlaceholderImage:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"StickersPlaceholderIcon.png"), color);
}

+ (UIImage *)commandsButtonImage:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
    CGFloat radius = 5.0f;
    CGFloat shadowSize = 1.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius * 2.0f, radius * 2.0f + shadowSize), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, shadowColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, shadowSize, radius * 2.0f, radius * 2.0f));
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, radius * 2.0f, radius * 2.0f));
    
    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:(NSInteger)radius topCapHeight:(NSInteger)radius];
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)profileVerifiedIcon:(UIColor *)backgroundColor color:(UIColor *)color
{
    NSString *code = @"M22.268087,44.298786 L16.9846589,46.0090994 L16.9846589,46.0090994 C15.1158722,46.6140496 13.0843724,45.7725749 12.190705,44.0233787 L9.66413137,39.0780566 L9.66413137,39.0780566 C9.28117419,38.3284855 8.67151447,37.7188258 7.92194336,37.3358686 L2.97662128,34.809295 L2.97662128,34.809295 C1.22742514,33.9156276 0.38595036,31.8841278 0.990900567,30.0153411 L2.70121398,24.731913 L2.70121398,24.731913 C2.96044918,23.9310945 2.96044918,23.0689055 2.70121398,22.268087 L0.990900567,16.9846589 L0.990900567,16.9846589 C0.38595036,15.1158722 1.22742514,13.0843724 2.97662128,12.190705 L7.92194336,9.66413137 L7.92194336,9.66413137 C8.67151447,9.28117419 9.28117419,8.67151447 9.66413137,7.92194336 L12.190705,2.97662128 L12.190705,2.97662128 C13.0843724,1.22742514 15.1158722,0.38595036 16.9846589,0.990900567 L22.268087,2.70121398 L22.268087,2.70121398 C23.0689055,2.96044918 23.9310945,2.96044918 24.731913,2.70121398 L30.0153411,0.990900567 L30.0153411,0.990900567 C31.8841278,0.38595036 33.9156276,1.22742514 34.809295,2.97662128 L37.3358686,7.92194336 L37.3358686,7.92194336 C37.7188258,8.67151447 38.3284855,9.28117419 39.0780566,9.66413137 L44.0233787,12.190705 L44.0233787,12.190705 C45.7725749,13.0843724 46.6140496,15.1158722 46.0090994,16.9846589 L44.298786,22.268087 L44.298786,22.268087 C44.0395508,23.0689055 44.0395508,23.9310945 44.298786,24.731913 L46.0090994,30.0153411 L46.0090994,30.0153411 C46.6140496,31.8841278 45.7725749,33.9156276 44.0233787,34.809295 L39.0780566,37.3358686 L39.0780566,37.3358686 C38.3284855,37.7188258 37.7188258,38.3284855 37.3358686,39.0780566 L34.809295,44.0233787 L34.809295,44.0233787 C33.9156276,45.7725749 31.8841278,46.6140496 30.0153411,46.0090994 L24.731913,44.298786 L24.731913,44.298786 C23.9310945,44.0395508 23.0689055,44.0395508 22.268087,44.298786 Z";
    
    NSString *checkCode = @"M15.4000244,24.5373134 L21.0425395,30.1798285 C21.1575424,30.2948314 21.3415779,30.2879933 21.4515072,30.1668549 L33.4000244,17 U";

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16, 16), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    TGDrawSvgPath(context, code);
    
    CGContextSetLineWidth(context, 5.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, checkCode);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)profileCallIcon:(UIColor *)color
{
    return [self _callsIcon:color stroke:true];
}

+ (UIImage *)profilePhoneDisclosureIcon:(UIColor *)color
{
    NSString *code = @"M0,0 L12.2928932,12.2928932 C12.6834175,12.6834175 12.6834175,13.3165825 12.2928932,13.7071068 L0,26 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(7, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextTranslateCTM(context, 3.0f, 3.0f);
    CGContextSetLineWidth(context, 6.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)collectionMenuDisclosureIcon:(UIColor *)color
{
    NSString *code = @"M52,44 L67.2928932,59.2928932 L67.2928932,59.2928932 C67.6834175,59.6834175 67.6834175,60.3165825 67.2928932,60.7071068 L52,76 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(8, 14), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.31f, 0.31f);
    CGContextTranslateCTM(context, -47.0f, -37.0f);
    CGContextSetLineWidth(context, 6.42f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)collectionMenuCheckIcon:(UIColor *)color
{
    NSString *code = @"M45,61.3825089 L54.6358383,70.8993687 C54.7545287,71.0165935 54.9405803,71.01304 55.0501705,70.8927766 L75,49 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(14, 11), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextTranslateCTM(context, -40.0f, -43.0f);
    CGContextSetLineWidth(context, 6.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)collectionMenuAddIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake((18.0f - 1.5f) / 2.0f, 0.0f, 1.5f, 18.0f));
    CGContextFillRect(context, CGRectMake(0.0f, (18.0f - 1.5f) / 2.0f, 18.0f, 1.5f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)collectionMenuReorderIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22.0f, 9.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 22.0f, 2.0f - TGRetinaPixel));
    CGContextFillRect(context, CGRectMake(0.0f, 4.0f - TGRetinaPixel, 22.0f, 2.0f - TGRetinaPixel));
    CGContextFillRect(context, CGRectMake(0.0f, 7.0f, 22.0f, 2.0f - TGRetinaPixel));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)menuCornersImage:(UIColor *)color
{
    CGFloat radius = 5.5f;
    CGRect rect = CGRectMake(0, 0, radius * 2 + 1.0f, radius * 2 + 1.0f);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillEllipseInRect(context, rect);
    
    UIImage *cornersImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius)];
    UIGraphicsEndImageContext();
    
    return cornersImage;
}

+ (UIImage *)fontSizeSmallIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InstantViewFontMinIcon"), color);
}

+ (UIImage *)fontSizeLargeIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InstantViewFontMaxIcon"), color);
}

+ (UIImage *)brightnessMinIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InstantViewBrightnessMinIcon"), color);
}

+ (UIImage *)brightnessMaxIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"InstantViewBrightnessMaxIcon"), color);
}

+ (UIImage *)videoPlayerPlayIcon:(UIColor *)color
{
      return TGTintedImage(TGImageNamed(@"VideoPlayerPlayIcon"), color);
}

+ (UIImage *)videoPlayerPauseIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"VideoPlayerPauseIcon"), color);
}

+ (UIImage *)videoPlayerForwardIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"VideoPlayerForwardIcon"), color);
}

+ (UIImage *)videoPlayerBackwardIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"VideoPlayerBackwardIcon"), color);
}

+ (UIImage *)videoPlayerPIPIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"VideoPlayerPIPIcon"), color);
}

+ (UIImage *)speakerIcon:(UIColor *)color
{
    NSString *code = @"M40.4733082,11.3180452 L20.5516959,27.55047 C20.1948571,27.8412276 19.7486477,28 19.28835,28 L4,28 C1.790861,28 -2.705415e-16,29.790861 0,32 L0,54 C-3.65367767e-15,56.209139 1.790861,58 4,58 L19.28835,58 C19.7486477,58 20.1948571,58.1587724 20.5516959,58.44953 L40.4733082,74.6819548 C42.18591,76.0774082 44.7054866,75.8203085 46.1009399,74.1077067 C46.6824551,73.394029 47,72.5016102 47,71.5810149 L47,14.4189851 C47,12.2098461 45.209139,10.4189851 43,10.4189851 C42.0794047,10.4189851 41.1869859,10.73653 40.4733082,11.3180452 Z";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(11.0f, 11.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);

    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)rate2xIcon:(UIColor *)color
{
    NSString *code = @"M15.3637695,32.1972656 L23.7749023,32.1972656 C24.6127972,32.1972656 25.2519509,32.3691389 25.6923828,32.7128906 C26.1328147,33.0566423 26.3530273,33.5239228 26.3530273,34.1147461 C26.3530273,34.6411159 26.1784685,35.0869122 25.8293457,35.4521484 C25.4802229,35.8173846 24.9511754,36 24.2421875,36 L12.3828125,36 C11.5771444,36 10.9487327,35.7771018 10.4975586,35.3312988 C10.0463845,34.8854958 9.82080078,34.3618194 9.82080078,33.7602539 C9.82080078,33.3735332 9.96581886,32.8605989 10.2558594,32.2214355 C10.5458999,31.5822722 10.8627913,31.08008 11.206543,30.7148438 C12.635261,29.2324145 13.9243107,27.9621635 15.0737305,26.9040527 C16.2231503,25.845942 17.0449194,25.1503923 17.5390625,24.8173828 C18.4199263,24.1943328 19.1530732,23.5686067 19.7385254,22.9401855 C20.3239775,22.3117644 20.7697739,21.6672396 21.0759277,21.0065918 C21.3820816,20.345944 21.5351562,19.6987336 21.5351562,19.0649414 C21.5351562,18.377438 21.3713395,17.7624539 21.0437012,17.2199707 C20.7160628,16.6774875 20.2702665,16.2558609 19.7062988,15.9550781 C19.1423312,15.6542954 18.5273471,15.5039062 17.8613281,15.5039062 C16.4540945,15.5039062 15.3476603,16.1215759 14.5419922,17.3569336 C14.4345698,17.5180672 14.2546399,17.9584925 14.0021973,18.6782227 C13.7497546,19.3979528 13.4650895,19.9511699 13.1481934,20.3378906 C12.8312972,20.7246113 12.3667023,20.9179688 11.7543945,20.9179688 C11.2172825,20.9179688 10.7714861,20.7407244 10.4169922,20.3862305 C10.0624982,20.0317365 9.88525391,19.5483429 9.88525391,18.9360352 C9.88525391,18.1948205 10.0517561,17.4213907 10.3847656,16.6157227 C10.7177751,15.8100546 11.2145963,15.0795931 11.8752441,14.4243164 C12.535892,13.7690397 13.3737742,13.2399922 14.388916,12.8371582 C15.4040578,12.4343242 16.5937432,12.2329102 17.9580078,12.2329102 C19.6015707,12.2329102 21.0034122,12.4907201 22.1635742,13.0063477 C22.9155311,13.3500994 23.576169,13.8227509 24.1455078,14.4243164 C24.7148466,15.0258819 25.1579574,15.7214316 25.4748535,16.5109863 C25.7917496,17.3005411 25.9501953,18.1196247 25.9501953,18.9682617 C25.9501953,20.3002996 25.6198764,21.5114692 24.9592285,22.6018066 C24.2985807,23.6921441 23.6245152,24.5461395 22.9370117,25.1638184 C22.2495083,25.7814972 21.0974202,26.75097 19.4807129,28.0722656 C17.8640056,29.3935613 16.7548858,30.4194299 16.1533203,31.1499023 C15.8955065,31.4399429 15.6323256,31.7890605 15.3637695,32.1972656 Z M28.8464425,31.4077148 L34.1315987,23.6894531 L29.6843331,16.8251953 C29.2653857,16.1591764 28.9511799,15.5871606 28.7417062,15.1091309 C28.5322325,14.6311011 28.4274972,14.1718772 28.4274972,13.7314453 C28.4274972,13.2802712 28.6289112,12.8747577 29.0317452,12.5148926 C29.4345793,12.1550275 29.9260294,11.9750977 30.5061105,11.9750977 C31.1721294,11.9750977 31.6904348,12.1711406 32.0610421,12.5632324 C32.4316494,12.9553242 32.9445837,13.6831002 33.5998605,14.746582 L37.1447823,20.4829102 L40.9314034,14.746582 C41.2429284,14.2631812 41.5087949,13.8496111 41.7290109,13.5058594 C41.9492268,13.1621077 42.1613829,12.8774425 42.3654855,12.6518555 C42.569588,12.4262684 42.7978572,12.2570806 43.0502999,12.1442871 C43.3027426,12.0314936 43.5954643,11.9750977 43.9284737,11.9750977 C44.5300392,11.9750977 45.0214894,12.1550275 45.402839,12.5148926 C45.7841885,12.8747577 45.9748605,13.3017553 45.9748605,13.7958984 C45.9748605,14.5156286 45.5612904,15.4931579 44.7341378,16.7285156 L40.0773995,23.6894531 L45.08863,31.4077148 C45.5398041,32.084476 45.8674376,32.6457497 46.0715401,33.0915527 C46.2756427,33.5373557 46.3776925,33.9589824 46.3776925,34.3564453 C46.3776925,34.7324238 46.2863848,35.0761703 46.1037667,35.3876953 C45.9211486,35.6992203 45.6633387,35.9462881 45.3303292,36.1289062 C44.9973197,36.3115244 44.6213469,36.402832 44.2023995,36.402832 C43.7512254,36.402832 43.3698815,36.3088388 43.0583566,36.1208496 C42.7468316,35.9328604 42.4943927,35.6992201 42.3010323,35.4199219 C42.107672,35.1406236 41.7478123,34.5981486 41.2214425,33.7924805 L37.0642159,27.2504883 L32.6491769,33.9858398 C32.3054251,34.5229519 32.0610428,34.8989247 31.9160226,35.1137695 C31.7710023,35.3286144 31.5964435,35.5380849 31.3923409,35.7421875 C31.1882383,35.9462901 30.9465415,36.1074213 30.6672433,36.2255859 C30.387945,36.3437506 30.0603116,36.402832 29.6843331,36.402832 C29.1042521,36.402832 28.623544,36.2255877 28.2421944,35.8710938 C27.8608449,35.5165998 27.670173,35.0009799 27.670173,34.3242188 C27.670173,33.5292929 28.0622589,32.5571347 28.8464425,31.4077148 Z M8,2 C4.6862915,2 2,4.6862915 2,8 L2,40 C2,43.3137085 4.6862915,46 8,46 L48,46 C51.3137085,46 54,43.3137085 54,40 L54,8 C54,4.6862915 51.3137085,2 48,2 L8,2 S";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(19.0f, 16.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 4.0f);
    
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)sharedMediaDownloadIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"SharedMediaDocumentStatusDownload.png"), color);
}

+ (UIImage *)sharedMediaPauseIcon:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(11.0f, 11.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(2.0f, 0.0f, 2.0f, 11.0f - 1.0f));
    CGContextFillRect(context, CGRectMake(2.0f + 2.0f + 2.0f, 0.0f, 2.0f, 11.0f - 1.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)shareSearchIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ShareSearchIcon"), color);
}

+ (UIImage *)shareExternalIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"ShareExternalIcon"), color);
}

+ (UIImage *)shareSelectionImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(60.0f, 60.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 60.0f, 60.0f));
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(2.0f, 2.0f, 60.0f - 4.0f, 60.0f - 4.0f));
    UIImage *circleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return circleImage;
}

+ (UIImage *)passportIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"PassportButtonIcon"), color);
}

+ (UIImage *)passportScanIcon:(UIColor *)color
{
    return TGTintedImage(TGImageNamed(@"PassportScan"), color);
}

+ (UIImage *)appearanceSwatchCheckIcon:(UIColor *)color
{
    NSString *code = @"M0,23.173913 L16.699191,39.765981 C17.390617,40.452972 18.503246,40.464805 19.209127,39.792676 L61,0 U";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.3333f, 0.3333f);
    CGContextTranslateCTM(context, 62.0f, 72.0f);
    CGContextSetLineWidth(context, 10.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)proxyShieldImage:(UIColor *)color
{
    NSString *code = @"M100,6.56393754 L6,48.2657557 L6,110.909091 C6,169.509174 46.3678836,223.966692 100,237.814087 C153.632116,223.966692 194,169.509174 194,110.909091 L194,48.2657557 L100,6.56393754 S";
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(67, 82), false, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 0.333333f, 0.333333f);
    //CGContextTranslateCTM(context, 62.0f, 72.0f);
    CGContextSetLineWidth(context, 12.0f);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    TGDrawSvgPath(context, code);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)badgeWithDiameter:(CGFloat)diameter color:(UIColor *)color border:(CGFloat)border borderColor:(UIColor *)borderColor
{
    CGFloat size = diameter + (border > FLT_EPSILON ? border * 2.0f : 0.0f);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (border > FLT_EPSILON && ![borderColor isEqual:[UIColor clearColor]])
    {
        CGContextSetFillColorWithColor(context, borderColor.CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, size, size));
    }
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(border, border, diameter, diameter));
    
    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    return [image stretchableImageWithLeftCapWidth:(int)(size / 2.0f) topCapHeight:0];
}

+ (UIImage *)avatarPlaceholderWithDiameter:(CGFloat)diameter color:(UIColor *)color border:(CGFloat)border borderColor:(UIColor *)borderColor
{
    CGFloat size = diameter;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
    
    if (border > FLT_EPSILON)
    {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, border);
        CGContextStrokeEllipseInRect(context, CGRectMake(border / 2.0f, border / 2.0f, diameter - border, diameter - border));
    }

    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:10.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color border:(CGFloat)border borderColor:(UIColor *)borderColor
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(4.0f, 4.0f), true, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 4.0f, 4.0f));
    
    if (borderColor != nil)
    {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextSetLineWidth(context, border);
    }
    
    UIImage *placeholderImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:2 topCapHeight:2];
    UIGraphicsEndImageContext();
    
    return placeholderImage;
}

+ (UIImage *)plusMinusIcon:(bool)plus backgroundColor:(UIColor *)backgroundColor color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22.0f, 24.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 22.0f, 22.0f));
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(5.5f, 10.5f, 11.0f, 1.0f));
    if (plus)
        CGContextFillRect(context, CGRectMake(10.5f, 5.5f, 1.0f, 11.0f));
    
    UIImage *placeholderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return placeholderImage;
}

+ (UIImage *)segmentedControlBackgroundImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, 9.0f, 28.0f) cornerRadius:4.0f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)segmentedControlSelectedImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, 9.0f, 28.0f) cornerRadius:4.0f];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)segmentedControlHighlightedImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:0.15f].CGColor);
    CGContextSetLineWidth(context, 1.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, 9.0f, 28.0f) cornerRadius:4.0f];
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)segmentedControlDividerImage:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 29.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, 1.0f, 29.0f));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)modernButtonImageWithColor:(UIColor *)color solid:(bool)solid
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(16.0f, 16.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGFloat lineWidth = 1.666667f;
    CGContextSetLineWidth(context, lineWidth);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(lineWidth / 2.0f, lineWidth / 2.0f, 16.0f - lineWidth, 16.0f - lineWidth) cornerRadius:8.0f];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, solid ? kCGPathFillStroke : kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f)];
}

@end
