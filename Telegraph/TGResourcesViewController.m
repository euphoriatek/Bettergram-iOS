//
//  TGResourcesViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/28/18.
//

#import "TGResourcesViewController.h"

#import "TGPresentation.h"
#import "TGResourceSection.h"
#import "TGCryptoManager.h"
#import "TGApplication.h"

@interface TGCryptoResourceCell : UITableViewCell

@property (nonatomic, strong, readonly) TGRemoteImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;

@property (nonatomic, strong, readonly) TGPresentation *presentation;

@end

const static CGFloat kCellIconSize = 30;
static const CGSize kBaseCellOffset = (CGSize){.width = 20, .height = 7};
const static CGFloat kSeeAllButtonOffset = 30;

@implementation TGCryptoResourceCell

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        
        _iconImageView = [[TGRemoteImageView alloc] init];
        _iconImageView.clipsToBounds = YES;
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.contentHints = TGRemoteImageContentHintLoadFromDiskSynchronously;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = TGSystemFontOfSize(16);
        
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = TGSystemFontOfSize(10);
        
        [self.contentView addSubviews:@[_iconImageView, _titleLabel, _subtitleLabel]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, UIEdgeInsetsMake(kBaseCellOffset.height, kBaseCellOffset.width,
                                                                                            kBaseCellOffset.height, kBaseCellOffset.width));
    _iconImageView.frame = CGRectMake(0, 0, kCellIconSize, kCellIconSize);
    
    {
        CGRect frame = CGRectZero;
        frame.origin.x = 10 + CGRectGetMaxX(_iconImageView.frame);
        frame.size = [_titleLabel sizeThatFits:CGSizeZero];
        frame.size.width = MIN(frame.size.width, self.contentView.frame.size.width - frame.origin.x);
        _titleLabel.frame = frame;
        
        frame.size = [_subtitleLabel sizeThatFits:CGSizeZero];
        frame.size.width = MIN(frame.size.width, self.contentView.frame.size.width - frame.origin.x);
        frame.origin.y = self.contentView.frame.size.height - frame.size.height;
        _subtitleLabel.frame = frame;
    }
}

- (void)setPresentation:(TGPresentation *)presentation
{
    if ([_presentation isEqual:presentation]) return;
    _titleLabel.textColor = presentation.pallete.dialogTitleColor;
    _subtitleLabel.textColor = presentation.pallete.secondaryTextColor; //8F8E94
}

@end


@class TGCryptoResourceHeaderView;
@protocol TGCryptoResourceHeaderViewDelegate <NSObject>

- (void)headerViewDidTapSeeAllButton:(TGCryptoResourceHeaderView *)headerView;

@end

@interface TGCryptoResourceHeaderView : UITableViewHeaderFooterView {
    UIView *_rightLineView;
}

@property (nonatomic, weak) id<TGCryptoResourceHeaderViewDelegate> delegate;

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) TGPresentation *presentation;
@property (nonatomic, strong, readonly) UIButton *seeAllButton;

@end

@implementation TGCryptoResourceHeaderView

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = UIColor.clearColor;
        
        _label = [[UILabel alloc] init];
        _label.font = TGSystemFontOfSize(16);
        
        _rightLineView = [[UIView alloc] init];
        
        _seeAllButton = [[UIButton alloc] init];
        _seeAllButton.adjustsImageWhenHighlighted = NO;
        _seeAllButton.titleLabel.font = TGSystemFontOfSize(10);
        [_seeAllButton addTarget:self action:@selector(seeAllButtonTap) forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubviews:@[_label, _seeAllButton, _rightLineView]];
    }
    return self;
}

- (void)seeAllButtonTap
{
    [_delegate headerViewDidTapSeeAllButton:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = CGRectZero;
    labelFrame.size = [_label sizeThatFits:CGSizeZero];
    labelFrame.origin.x = kBaseCellOffset.width;
    labelFrame.origin.y = (self.contentView.frame.size.height - labelFrame.size.height) / 2;
    
    if (!_seeAllButton.isHidden) {
        CGRect frame = CGRectZero;
        frame.size.width = MAX(44, [_seeAllButton sizeThatFits:CGSizeZero].width + 12);
        frame.size.height = self.contentView.frame.size.height;
        frame.origin.x = MIN(kSeeAllButtonOffset + CGRectGetMaxX(labelFrame),
                             self.contentView.frame.size.width - kBaseCellOffset.width - frame.size.width);
        
        labelFrame.size.width = MIN(labelFrame.size.width, frame.origin.x - kSeeAllButtonOffset);
        
        _seeAllButton.frame = frame;
    }
    else {
        labelFrame.size.width = MIN(labelFrame.size.width, self.contentView.frame.size.width - kBaseCellOffset.width - labelFrame.size.width);
    }
    _label.frame = labelFrame;
    
    {
        CGRect frame = CGRectZero;
        frame.origin.x = CGRectGetMaxX((_seeAllButton.isHidden ? _label : _seeAllButton).frame) + kSeeAllButtonOffset / 2;
        frame.size.height = 1;
        frame.origin.y = (self.contentView.frame.size.height - frame.size.height) / 2;
        frame.size.width = self.contentView.frame.size.width - kBaseCellOffset.width - frame.origin.x;
        _rightLineView.frame = frame.size.width > 10 ? frame : CGRectZero;
    }
}

- (void)setPresentation:(TGPresentation *)presentation
{
    if ([_presentation isEqual:presentation]) return;
    _label.textColor = presentation.pallete.dialogTitleColor;
    _rightLineView.backgroundColor = presentation.pallete.cryptoSortArrowColor;
    [_seeAllButton setBackgroundImage:presentation.images.seeAllButtonBackground forState:UIControlStateNormal];
    [_seeAllButton setTitleColor:presentation.pallete.accentContrastColor forState:UIControlStateNormal];
}

- (void)localizationUpdated
{
    [_seeAllButton setTitle:TGLocalized(@"Crypto.Resources.SeeAllButton") forState:UIControlStateNormal];
}

@end


@interface TGResourcesViewController () <UITableViewDelegate, UITableViewDataSource, TGCryptoResourceHeaderViewDelegate> {
    TGListsTableView *_tableView;
    NSArray<TGResourceSection *> *_resourceSections;
    NSMutableIndexSet *_uncoveredSectionIndexes;
    
}

@property (nonatomic, strong) TGPresentation *presentation;

@end

@implementation TGResourcesViewController

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    if (self = [super init]) {
        _presentation = presentation;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    _tableView = [[TGListsTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    if (@available(iOS 11.0, *)) {
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.sectionFooterHeight = 0;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.sectionHeaderHeight = _tableView.rowHeight = 44;
    [_tableView registerClass:[TGCryptoResourceCell class] forCellReuseIdentifier:TGCryptoResourceCell.reuseIdentifier];
    [_tableView registerClass:[TGCryptoResourceHeaderView class] forHeaderFooterViewReuseIdentifier:TGCryptoResourceHeaderView.reuseIdentifier];
    [self.view addSubview:_tableView];
    
    [self setPresentation:_presentation];
    [self localizationUpdated];
    
    [TGCryptoManager.manager fetchResources:^(NSArray<TGResourceSection *> *resourceSections) {
        TGDispatchOnMainThread(^{
            _uncoveredSectionIndexes = [[NSMutableIndexSet alloc] init];
            _resourceSections = resourceSections;
            [_tableView reloadData];
        });
    }];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = presentation.pallete.backgroundColor;
}

- (void)localizationUpdated
{
    self.titleText = TGLocalized(@"Crypto.Resources.Title");
    [_tableView reloadData];
}

- (void)scrollToTopRequested
{
    [_tableView scrollToTop];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return _resourceSections.count;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRowsInSection = _resourceSections[section].resourceItems.count;
    if (![_uncoveredSectionIndexes containsIndex:section] && numberOfRowsInSection > 2) {
        return 2;
    }
    return numberOfRowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGCryptoResourceCell *cell = (TGCryptoResourceCell *)[tableView dequeueReusableCellWithIdentifier:TGCryptoResourceCell.reuseIdentifier forIndexPath:indexPath];
    [cell setPresentation:_presentation];
    TGResourceItem *resourceItem = _resourceSections[indexPath.section].resourceItems[indexPath.row];
    cell.titleLabel.text = resourceItem.title;
    [cell.iconImageView loadImage:resourceItem.iconURLString
                           filter:nil//[NSString stringWithFormat:@"circle:%1$@x%1$@",@(kCellIconSize)]
                      placeholder:nil];
    cell.subtitleLabel.text = resourceItem.descriptionString;
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TGCryptoResourceHeaderView *view = (TGCryptoResourceHeaderView *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:TGCryptoResourceHeaderView.reuseIdentifier];
    view.presentation = _presentation;
    [view localizationUpdated];
    TGResourceSection *resourceSections = _resourceSections[section];
    view.label.text = resourceSections.title;
    view.seeAllButton.hidden = _resourceSections[section].resourceItems.count < 3 || [_uncoveredSectionIndexes containsIndex:section];
    view.delegate = self;
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGResourceItem *resourceItem = _resourceSections[indexPath.section].resourceItems[indexPath.row];
    
    [(TGApplication *)[UIApplication sharedApplication] openURL:[NSURL URLWithString:resourceItem.urlString]
                                                    forceNative:true
                                                      keepStack:true];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TGCryptoResourceHeaderViewDelegate

- (void)headerViewDidTapSeeAllButton:(TGCryptoResourceHeaderView *)headerView
{
    for (NSInteger section = 0; section < _tableView.numberOfSections; section++) {
        if ([_tableView headerViewForSection:section] == headerView) {
            [_uncoveredSectionIndexes addIndex:section];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
            return;
        }
    }
}

@end
