#import "TGModernConversationActionInputPanel.h"

#import <LegacyComponents/LegacyComponents.h>

#import <LegacyComponents/TGModernButton.h>

#import <LegacyComponents/ASHandle.h>

#import "TGPresentation.h"

@interface TGModernConversationActionInputPanel ()
{
    UIEdgeInsets _safeAreaInset;
    
    NSString *_action;
        
    CALayer *_stripeLayer;
    TGModernButton *_actionButton;
    UIImageView *_iconView;
    
    UIActivityIndicatorView *_activityIndicator;
    
    TGModernConversationActionInputPanelIcon _icon;
    bool _destructive;
}

@end

@implementation TGModernConversationActionInputPanel

- (CGFloat)baseHeight
{
    static CGFloat value = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        value = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45.0f : 56.0f;
    });
    
    return value;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [self baseHeight])];
    if (self)
    {
        self.backgroundColor = UIColorRGB(0xf7f7f7);
        
        _stripeLayer = [[CALayer alloc] init];
        _stripeLayer.backgroundColor = UIColorRGB(0xb2b2b2).CGColor;
        [self.layer addSublayer:_stripeLayer];
        
        _actionButton = [[TGModernButton alloc] initWithFrame:CGRectZero];
        _actionButton.adjustsImageWhenDisabled = false;
        _actionButton.adjustsImageWhenHighlighted = false;
        [_actionButton addTarget:self action:@selector(actionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_actionButton];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [super setPresentation:presentation];
    
    self.backgroundColor = presentation.pallete.barBackgroundColor;
    _stripeLayer.backgroundColor = presentation.pallete.barSeparatorColor.CGColor;
    
    if (_icon == TGModernConversationActionInputPanelIconJoin)
        _iconView.image = [self joinImage:self.presentation.pallete.conversationInputPanelActionColor];
    
    if (_destructive)
        [_actionButton setTitleColor:self.presentation.pallete.destructiveColor];
}

- (void)setActionWithTitle:(NSString *)title action:(NSString *)action
{
    _destructive = true;
    [self setActionWithTitle:title action:action color:self.presentation.pallete.destructiveColor];
}

- (void)setActionWithTitle:(NSString *)title action:(NSString *)action color:(UIColor *)color
{
    [self setActionWithTitle:title action:action color:color icon:TGModernConversationActionInputPanelIconNone];
}

- (UIImage *)joinImage:(UIColor *)color
{
    CGFloat side = 18.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(side / 2.0f - 0.5f, 0.0f, 1.5f, side));
    CGContextFillRect(context, CGRectMake(0.0f, side / 2.0f - 0.5f, side, 1.5f));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setActionWithTitle:(NSString *)title action:(NSString *)action color:(UIColor *)color icon:(TGModernConversationActionInputPanelIcon)icon
{
    _action = action;
    
    [_actionButton setTitleColor:color];
    [_actionButton setTitle:title forState:UIControlStateNormal];
    
    _icon = icon;
    
    switch (icon) {
        case TGModernConversationActionInputPanelIconNone: {
            [_iconView removeFromSuperview];
            [self setNeedsLayout];
            break;
        }
        case TGModernConversationActionInputPanelIconJoin: {
            if (_iconView == nil) {
                _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 18.0f, 18.0f)];
            }
            if (_iconView.superview == nil) {
                [_actionButton addSubview:_iconView];
            }
            if (self.presentation != nil)
            {
                _iconView.image = [self joinImage:self.presentation.pallete.conversationInputPanelActionColor];
                [_iconView sizeToFit];
            }
            break;
        }
    }
    
    [self setNeedsLayout];
}

- (void)setActivity:(bool)activity
{
    _actionButton.userInteractionEnabled = !activity;
    
    if (activity)
    {
        if (_activityIndicator == nil)
        {
            _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            _activityIndicator.color = self.presentation.pallete.conversationInputPanelActionColor;
        }
        
        if (_activityIndicator.superview == nil)
        {
            [self addSubview:_activityIndicator];
            [_activityIndicator startAnimating];
            [self setNeedsLayout];
        }
    }
    else
    {
        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
    }
}

- (void)adjustForSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset
{
    [self _adjustForSize:size keyboardHeight:keyboardHeight duration:duration animationCurve:animationCurve contentAreaHeight:contentAreaHeight safeAreaInset:safeAreaInset];
}

- (void)_adjustForSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve contentAreaHeight:(CGFloat)__unused contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset
{
    _safeAreaInset = safeAreaInset;
    
    dispatch_block_t block = ^
    {
        CGSize messageAreaSize = size;
        
        self.frame = CGRectMake(0, messageAreaSize.height - keyboardHeight - [self baseHeight] - safeAreaInset.bottom, messageAreaSize.width, [self baseHeight] + safeAreaInset.bottom);
        [self layoutSubviews];
    };
    
    if (duration > DBL_EPSILON)
        [UIView animateWithDuration:duration delay:0 options:animationCurve << 16 animations:block completion:nil];
    else
        block();
}

- (void)changeToSize:(CGSize)size keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration contentAreaHeight:(CGFloat)contentAreaHeight safeAreaInset:(UIEdgeInsets)safeAreaInset
{
    [self _adjustForSize:size keyboardHeight:keyboardHeight duration:duration animationCurve:0 contentAreaHeight:contentAreaHeight safeAreaInset:safeAreaInset];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _stripeLayer.frame = CGRectMake(0.0f, -TGScreenPixel, self.frame.size.width, TGScreenPixel);
    _actionButton.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, [self baseHeight]);
    
    if (_icon != TGModernConversationActionInputPanelIconNone) {
        CGSize titleSize = [_actionButton.titleLabel sizeThatFits:_actionButton.bounds.size];
        [_actionButton setContentEdgeInsets:UIEdgeInsetsMake(0.0f, _iconView.frame.size.width + 9.0f, 0.0f, 0.0f)];
        _iconView.frame = CGRectOffset(_iconView.bounds, CGFloor(_actionButton.frame.size.width - titleSize.width - _iconView.frame.size.width - 9.0f) / 2.0f, CGFloor(_actionButton.frame.size.height - _iconView.frame.size.height) / 2.0f);
    } else {
        [_actionButton setContentEdgeInsets:UIEdgeInsetsZero];
    }
    
    _activityIndicator.frame = CGRectMake(self.frame.size.width - _activityIndicator.frame.size.width - 12.0f - _safeAreaInset.right, CGFloor(([self baseHeight] - _activityIndicator.frame.size.height) / 2.0f), _activityIndicator.frame.size.width, _activityIndicator.frame.size.height);
}

- (void)actionButtonPressed
{
    if (_action != nil)
        [_companionHandle requestAction:@"actionPanelAction" options:@{@"action": _action}];
}

@end
