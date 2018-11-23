#import <UIKit/UIKit.h>


@interface UISegmentedControlPallete : NSObject

@property (nonatomic, readonly) UIColor *defaultTextColor;
@property (nonatomic, readonly) UIColor *selectedTextColor;
@property (nonatomic, readonly) UIImage *segmentedControlBackgroundImage;
@property (nonatomic, readonly) UIImage *segmentedControlSelectedImage;
@property (nonatomic, readonly) UIImage *segmentedControlHighlightedImage;
@property (nonatomic, readonly) UIImage *segmentedControlDividerImage;

+ (instancetype)palleteWithDefaultTextColor:(UIColor *)defaultTextColor
                          selectedTextColor:(UIColor *)selectedTextColor
            segmentedControlBackgroundImage:(UIImage *)segmentedControlBackgroundImage
              segmentedControlSelectedImage:(UIImage *)segmentedControlSelectedImage
           segmentedControlHighlightedImage:(UIImage *)segmentedControlHighlightedImage
               segmentedControlDividerImage:(UIImage *)segmentedControlDividerImage;

@end


@interface UISegmentedControl (SetPallete)

- (void)setPallete:(UISegmentedControlPallete *)pallete;
- (void)setNoPalleteAccentColor:(UIColor *)accentColor accentContrastColor:(UIColor *)accentContrastColor;

@end
