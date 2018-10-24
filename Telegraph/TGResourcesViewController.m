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
#import "TGAppDelegate.h"

@interface TGCryptoResourceCell : UITableViewCell

@property (nonatomic, strong, readonly) TGRemoteImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;

@property (nonatomic, strong, readonly) TGPresentation *presentation;

@end

const static CGFloat kCellIconSize = 30;
static const CGSize kBaseCellOffset = (CGSize){.width = 20, .height = 7};

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

@end

@interface TGCryptoResourceHeaderView : UITableViewHeaderFooterView {
    UIView *_rightLineView;
}

@property (nonatomic, weak) id<TGCryptoResourceHeaderViewDelegate> delegate;

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) TGPresentation *presentation;

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
        
        [self.contentView addSubviews:@[_label, _rightLineView]];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect labelFrame = CGRectZero;
    labelFrame.size = [_label sizeThatFits:CGSizeZero];
    labelFrame.origin.x = kBaseCellOffset.width;
    labelFrame.origin.y = (self.contentView.frame.size.height - labelFrame.size.height) / 2;
    labelFrame.size.width = MIN(labelFrame.size.width, self.contentView.frame.size.width - kBaseCellOffset.width - labelFrame.origin.x);
    _label.frame = labelFrame;
    
    {
        CGRect frame = CGRectZero;
        frame.origin.x = CGRectGetMaxX(_label.frame) + 15;
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
}

@end


@interface TGResourcesViewController () <UITableViewDelegate, UITableViewDataSource, TGCryptoResourceHeaderViewDelegate> {
    TGListsTableView *_tableView;
    NSArray<TGResourceSection *> *_resourceSections;
    
    UIBarButtonItem *_leftButtonItem;
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
    _tableView.backgroundColor = nil;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.sectionFooterHeight = 0;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.sectionHeaderHeight = _tableView.rowHeight = 44;
    _tableView.bounces = NO;
    [_tableView registerClass:[TGCryptoResourceCell class] forCellReuseIdentifier:TGCryptoResourceCell.reuseIdentifier];
    [_tableView registerClass:[TGCryptoResourceHeaderView class] forHeaderFooterViewReuseIdentifier:TGCryptoResourceHeaderView.reuseIdentifier];
    [self.view addSubview:_tableView];
    
    [self setLeftBarButtonItem:_leftButtonItem = [[UIBarButtonItem alloc] initWithImage:nil
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(settingsButtonTap)]
                      animated:false];
    
    [self setPresentation:_presentation];
    [self localizationUpdated];
    
    [TGCryptoManager.manager fetchResources:^(NSArray<TGResourceSection *> *resourceSections) {
        TGDispatchOnMainThread(^{
            _resourceSections = resourceSections;
            [_tableView reloadData];
        });
    }];
}

- (void)controllerInsetUpdated:(__unused UIEdgeInsets)previousInset
{
    if (!self.isViewLoaded) return;
    
    _tableView.frame = UIEdgeInsetsInsetRect(self.view.bounds, self.controllerInset);
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = presentation.pallete.backgroundColor;
    _leftButtonItem.image = _presentation.images.settingsButton;
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

- (void)settingsButtonTap
{
    TGViewController *accountSettingsController = TGAppDelegateInstance.rootController.accountSettingsController;
    [TGAppDelegateInstance.rootController pushContentController:accountSettingsController];
    
    [accountSettingsController setTargetNavigationItem:accountSettingsController.navigationItem titleController:TGAppDelegateInstance.rootController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return _resourceSections.count;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)section
{
    return _resourceSections[section].resourceItems.count;
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
    TGResourceSection *resourceSections = _resourceSections[section];
    view.label.text = resourceSections.title;
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

@end
