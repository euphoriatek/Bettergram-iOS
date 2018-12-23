#import "TGDialogListCellEditingButton.h"

#import <LegacyComponents/LegacyComponents.h>


@interface TGDialogListCellEditingButton () {
    UILabel *_labelView;
    UIImageView *_iconView;
    
    bool _triggered;
}

@end

@implementation TGDialogListCellEditingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.clipsToBounds = YES;
        _labelView = [[UILabel alloc] init];
        _labelView.backgroundColor = nil;
        _labelView.opaque = false;
        _labelView.textColor = [UIColor whiteColor];
        
        static UIFont *font;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            font = TGMediumSystemFontOfSize(13.0f);
        });
        
        _labelView.font = font;
        [self addSubview:_labelView];
        
        _iconView = [[UIImageView alloc] init];
        [self addSubview:_iconView];
    }
    return self;
}

- (void)setLabelOnly:(bool)labelOnly {
    _labelOnly = labelOnly;
    _labelView.font = TGMediumSystemFontOfSize(_labelOnly ? 18.0f : 13.0f);
}

- (void)setSmallLabel:(bool)smallLabel {
    _smallLabel = smallLabel;
    _labelView.font = TGMediumSystemFontOfSize(_smallLabel ? 14.0f : (_labelOnly ? 18.0f : 13.0f));
}

- (void)setTitle:(NSString *)title {
    _iconView.hidden = true;
    if (!_labelOnly && _labelView.text.length == 0)
        _labelView.alpha = 0.0f;
    _labelView.text = title;
    [_labelView sizeToFit];
    
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title image:(UIImage *)image {
    _labelView.alpha = 1.0f;
    _labelView.text = title;
    [_labelView sizeToFit];
    
    _iconView.hidden = false;
    if (!_labelOnly)
        _iconView.image = image;
    [self setNeedsLayout];
}

- (bool)triggered {
    return _triggered;
}

- (void)setTriggered:(bool)triggered {
    [self setTriggered:triggered animated:false];
}

- (void)setTriggered:(bool)triggered animated:(bool)animated {
    if (triggered == _triggered)
        return;
    
    _triggered = triggered;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:7 << 16 animations:^{
            [self layoutSubviews];
        } completion:nil];
    }
    else
    {
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGFloat buttonWidth = self.buttonWidth;
    
    CGSize labelSize = _labelView.bounds.size;
    CGSize iconSize = _iconView.image.size;
    
    CGFloat labelY = _labelOnly ? 17.0f : 49.0f;
    if (_smallLabel) {
        labelY = 15.0f;
    } else if (_offsetLabel) {
        labelY = 14.0f;
    }
    
    CGFloat offset = _triggered ? bounds.size.width - buttonWidth : 0.0f;
    _labelView.center = CGPointMake(offset + buttonWidth / 2.0f, labelY + labelSize.height / 2.0f);
    _iconView.frame = CGRectMake(offset + CGFloor((buttonWidth - iconSize.width) / 2.0f), 14.0f, iconSize.width, iconSize.height);
}

@end
