#import "UISegmentedControl+SetPallete.h"

#import "TGFont.h"
#import "LegacyComponentsInternal.h"
#import "TGColor.h"
#import "TGSearchBar.h"
#import "TGImageUtils.h"


@implementation UISegmentedControlPallete

+ (instancetype)palleteWithDefaultTextColor:(UIColor *)defaultTextColor
                       selectedTextColor:(UIColor *)selectedTextColor
         segmentedControlBackgroundImage:(UIImage *)segmentedControlBackgroundImage
           segmentedControlSelectedImage:(UIImage *)segmentedControlSelectedImage
        segmentedControlHighlightedImage:(UIImage *)segmentedControlHighlightedImage
            segmentedControlDividerImage:(UIImage *)segmentedControlDividerImage
{
    UISegmentedControlPallete *pallete = [[self alloc] init];
    pallete->_defaultTextColor = defaultTextColor;
    pallete->_selectedTextColor = selectedTextColor;
    pallete->_segmentedControlBackgroundImage = segmentedControlBackgroundImage;
    pallete->_segmentedControlSelectedImage = segmentedControlSelectedImage;
    pallete->_segmentedControlHighlightedImage = segmentedControlHighlightedImage;
    pallete->_segmentedControlDividerImage = segmentedControlDividerImage;
    return pallete;
}

@end


@implementation UISegmentedControl (SetPallete)

- (void)setPallete:(UISegmentedControlPallete *)pallete
{
    [self setPallete:pallete accentColor:nil accentContrastColor:nil];
}

- (void)setNoPalleteAccentColor:(UIColor *)accentColor accentContrastColor:(UIColor *)accentContrastColor
{
    [self setPallete:nil accentColor:accentColor accentContrastColor:accentContrastColor];
}

- (void)setPallete:(UISegmentedControlPallete *)pallete accentColor:(UIColor *)accentColor accentContrastColor:(UIColor *)accentContrastColor
{
    UIImage *(^TintedImageIfNeeded)(UIImage *image, UIColor *color) = ^(UIImage *image, UIColor *color) {
        if (color == nil) {
            return image;
        }
        return TGTintedImage(image, color);
    };
    [self setBackgroundImage:pallete != nil ? pallete.segmentedControlBackgroundImage : TintedImageIfNeeded(TGComponentsImageNamed(@"ModernSegmentedControlBackground.png"),  accentColor) forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self setBackgroundImage:pallete != nil ? pallete.segmentedControlSelectedImage : TintedImageIfNeeded(TGComponentsImageNamed(@"ModernSegmentedControlSelected.png"),  accentColor) forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [self setBackgroundImage:pallete != nil ? pallete.segmentedControlSelectedImage : TintedImageIfNeeded(TGComponentsImageNamed(@"ModernSegmentedControlSelected.png"),  accentColor) forState:UIControlStateSelected | UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [self setBackgroundImage:pallete != nil ? pallete.segmentedControlHighlightedImage : TintedImageIfNeeded(TGComponentsImageNamed(@"ModernSegmentedControlHighlighted.png"),  accentColor) forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [self setDividerImage:pallete != nil ? pallete.segmentedControlDividerImage : TintedImageIfNeeded(TGComponentsImageNamed(@"ModernSegmentedControlDivider.png"),  accentColor) forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [self setTitleTextAttributes:@{UITextAttributeTextColor:pallete != nil ? pallete.defaultTextColor : accentColor ?: TGAccentColor(), UITextAttributeTextShadowColor: [UIColor clearColor], UITextAttributeFont: TGSystemFontOfSize(13)} forState:UIControlStateNormal];
    [self setTitleTextAttributes:@{UITextAttributeTextColor:pallete != nil ? pallete.selectedTextColor : accentContrastColor ?: [UIColor whiteColor], UITextAttributeTextShadowColor: [UIColor clearColor], UITextAttributeFont: TGSystemFontOfSize(13)} forState:UIControlStateSelected];
    
}

@end
