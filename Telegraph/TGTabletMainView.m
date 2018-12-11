#import "TGTabletMainView.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGPresentation.h"

@interface TGTabletMainView ()
{
    UIView *_stripeView;
    UIView *_masterViewContainer;
    UIView *_detailViewContainer;
    
    CGFloat _bottomInset;
}

@end

@implementation TGTabletMainView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.clipsToBounds = true;
        
        CGRect detailViewContainerFrame = [self rectForDetailViewForFrame:frame];
        
        _detailViewContainer = [[UIView alloc] initWithFrame:detailViewContainerFrame];
        _detailViewContainer.clipsToBounds = true;
        [self addSubview:_detailViewContainer];
        
        CGRect masterViewContainerFrame = [self rectForMasterViewForFrame:frame];
        _masterViewContainer = [[UIView alloc] initWithFrame:masterViewContainerFrame];
        _masterViewContainer.clipsToBounds = true;
        [self addSubview:_masterViewContainer];
        
        _stripeView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(masterViewContainerFrame), 0.0f, TGScreenPixel, masterViewContainerFrame.size.height)];
        _stripeView.backgroundColor = UIColorRGBA(0x575757, 0.43f);
        [self addSubview:_stripeView];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    _stripeView.backgroundColor = presentation.pallete.padSeparatorColor;
}

- (void)updateBottomInset:(CGFloat)inset
{
    _bottomInset = inset;
    
    CGRect masterViewContainerFrame = [self rectForMasterViewForFrame:self.frame];
    _stripeView.frame = CGRectMake(CGRectGetMaxX(masterViewContainerFrame), 0.0f, TGScreenPixel, masterViewContainerFrame.size.height - _bottomInset);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self layoutForFrame:frame];
}

- (void)layoutForFrame:(CGRect)frame {
    CGRect masterViewContainerFrame = [self rectForMasterViewForFrame:frame];
    _masterViewContainer.frame = masterViewContainerFrame;
    
    _stripeView.frame = CGRectMake(CGRectGetMaxX(masterViewContainerFrame), 0.0f, TGScreenPixel, masterViewContainerFrame.size.height - _bottomInset);
    
    masterViewContainerFrame.origin = CGPointZero;
    _masterView.frame = masterViewContainerFrame;
    
    CGRect detailViewContainerFrame = [self rectForDetailViewForFrame:frame];
    
    _detailViewContainer.frame = detailViewContainerFrame;
    
    detailViewContainerFrame.origin = CGPointZero;
    _detailView.frame = detailViewContainerFrame;
}

- (void)setFullScreenDetail:(bool)fullScreenDetail {
    if (fullScreenDetail != _fullScreenDetail) {
        _fullScreenDetail = fullScreenDetail;
        
        if (fullScreenDetail) {
            [_masterViewContainer removeFromSuperview];
            [_stripeView removeFromSuperview];
        } else {
            [self insertSubview:_masterViewContainer aboveSubview:_detailViewContainer];
            [self addSubview:_stripeView];
        }
        
        [self layoutForFrame:self.frame];
    }
}

- (CGRect)rectForMasterViewForFrame:(CGRect)frame
{
    return CGRectMake(0.0f, 0.0f, frame.size.width >= (1024.0f - FLT_EPSILON) ? 389.0f : 320.0f, frame.size.height);
}

- (CGRect)rectForDetailViewForFrame:(CGRect)frame
{
    if (_fullScreenDetail) {
        return CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
    } else {
        CGRect dialogListViewFrame = [self rectForMasterViewForFrame:frame];
        return CGRectMake(dialogListViewFrame.size.width, 0.0f, MAX(0.0f, frame.size.width - dialogListViewFrame.size.width + 1.0f), frame.size.height);
    }
}

- (void)setMasterView:(UIView *)masterView
{
    [_masterView removeFromSuperview];
    
    _masterView = masterView;
    CGRect masterViewContainerFrame = [self rectForMasterViewForFrame:self.frame];
    masterViewContainerFrame.origin = CGPointZero;
    _masterView.frame = masterViewContainerFrame;
    [_masterViewContainer addSubview:_masterView];
}

- (void)setDetailView:(UIView *)detailView
{
    if (detailView != _detailView) {
        [_detailView removeFromSuperview];
        _detailView = detailView;
    }
    CGRect detailViewContainerFrame = [self rectForDetailViewForFrame:self.frame];
    detailViewContainerFrame.origin = CGPointZero;
    _detailView.frame = detailViewContainerFrame;
    [_detailViewContainer addSubview:_detailView];
}

@end
