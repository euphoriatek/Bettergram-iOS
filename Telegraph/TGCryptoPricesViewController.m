//
//  TGCryptoPricesViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/17/18.
//

#import "TGCryptoPricesViewController.h"
#import "CALayer+SketchShadow.h"

#import "TGPresentation.h"
#import <LegacyComponents/TGSearchBar.h>
#import "TGTableView.h"

const CGFloat kMarketInfoOffset = 2;
const CGFloat kMarketInfoInset = 20;

const CGFloat kMarketViewOffset = 20;
const CGFloat kMarketViewHeight = 80;
const CGFloat kMarketViewWidth = 110;

const CGFloat kFilterViewHeight = 44;
const CGFloat kFilterViewInset = 31;

const CGFloat kSortViewHeight = 54;

const CGFloat kCellPriceOffset = 100;
const CGFloat kCellIconOffset = 10;

@interface TGMarketInfoMarkView : UIView {
    UILabel *_titleLabel;
    UILabel *_valueLabel;
    UILabel *_changeLabel;
    TGPresentation *_presentation;
    CGFloat _change;
}

@property (nonatomic, strong) TGPresentation *presentation;

@end

@implementation TGMarketInfoMarkView

- (instancetype)init
{
    if (self = [super init]) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = TGSystemFontOfSize(10);
        
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = TGSystemFontOfSize(16);
        
        _changeLabel = [[UILabel alloc] init];
        _changeLabel.font = TGSystemFontOfSize(10);
        
        [self.labels enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [self addSubview:obj];
        }];
    }
    return self;
}

- (NSArray<UIView *> *)labels
{
    return @[_titleLabel, _valueLabel, _changeLabel];
}

- (void)setTitle:(NSString *)markTitle
{
    _titleLabel.text = markTitle;
}

- (void)setValueString:(NSString *)valueString
{
    _valueLabel.text = valueString;
    [self setNeedsLayout];
}

- (void)setChange:(CGFloat)change
{
    _change = change;
    NSString *percentSign;
    if (change > 0) {
        percentSign = @"+";
    }
    else if (change < 0) {
        percentSign = @"-";
    }
    else {
        percentSign = @"";
    }
    _changeLabel.text = [NSString stringWithFormat:@"(%@%.2f%%)", percentSign, ABS(change)];
    [self updateMarkChangeLabelFont];
    [self setNeedsLayout];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    _titleLabel.textColor = presentation.pallete.marketInfoMarkTitleColor;
    _valueLabel.textColor = presentation.pallete.marketInfoMarkValueColor;
    [self updateMarkChangeLabelFont];
}

- (void)updateMarkChangeLabelFont
{
    if (_change > 0) {
        _changeLabel.textColor = _presentation.pallete.marketInfoMarkChangeGainColor;
    }
    else if (_change < 0) {
        _changeLabel.textColor = _presentation.pallete.marketInfoMarkChangeLossColor;
    }
    else {
        _titleLabel.textColor = _presentation.pallete.marketInfoMarkTitleColor;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.labels enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj sizeToFit];
    }];
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    _valueLabel.center = center;
    
    center.y = CGRectGetMinY(_valueLabel.frame) - kMarketInfoOffset - _titleLabel.frame.size.height / 2;
    _titleLabel.center = center;
    
    center.y = CGRectGetMaxY(_valueLabel.frame) + kMarketInfoOffset + _changeLabel.frame.size.height / 2;
    _changeLabel.center = center;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    __block CGSize sizeThatFits = CGSizeZero;
    [self.labels enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        CGSize labelSize = [obj sizeThatFits:size];
        sizeThatFits.width = MAX(sizeThatFits.width, labelSize.width);
        sizeThatFits.height += labelSize.height;
    }];
    sizeThatFits.height += kMarketInfoOffset * 2;
    return sizeThatFits;
}

@end

@interface TGMarketInfoView : UIView {
    TGMarketInfoMarkView *_marketCapView;
    TGMarketInfoMarkView *_24VolumeView;
    TGMarketInfoMarkView *_btcDominanceView;
}

@end

@implementation TGMarketInfoView

- (instancetype)init
{
    if (self = [super init]) {
        self.backgroundColor = UIColor.whiteColor;
        
        _marketCapView = [[TGMarketInfoMarkView alloc] init];
        _24VolumeView = [[TGMarketInfoMarkView alloc] init];
        _btcDominanceView = [[TGMarketInfoMarkView alloc] init];
        
        [self.views enumerateObjectsUsingBlock:^(TGMarketInfoMarkView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [self addSubview:obj];
        }];
    }
    return self;
}

- (NSArray<TGMarketInfoMarkView *> *)views
{
    return @[_marketCapView, _24VolumeView, _btcDominanceView];
}

- (void)setMarketCapValue:(CGFloat)value change:(CGFloat)change
{
    [_marketCapView setValueString:[self usdStringWithValue:value]];
    [_marketCapView setChange:change];
}

- (void)set24VolumeValue:(CGFloat)value change:(CGFloat)change
{
    [_24VolumeView setValueString:[self usdStringWithValue:value]];
    [_24VolumeView setChange:change];
}

- (void)setBTCDominanceValue:(CGFloat)value change:(CGFloat)change
{
    [_btcDominanceView setValueString:[NSString stringWithFormat:@"%.2f%%",value]];
    [_btcDominanceView setChange:change];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [self.layer applySketchShadowWithColor:presentation.pallete.secondaryTextColor
                                   opacity:0.2
                                         x:0
                                         y:1
                                      blur:6];
    self.backgroundColor = presentation.pallete.backgroundColor;
    [self.views enumerateObjectsUsingBlock:^(TGMarketInfoMarkView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj setPresentation:presentation];
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.views enumerateObjectsUsingBlock:^(TGMarketInfoMarkView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj sizeToFit];
    }];
    if (self.frame.size.height < self.frame.size.width) {
        _marketCapView.center = CGPointMake(kMarketInfoInset + _marketCapView.frame.size.width / 2,
                                            self.frame.size.height / 2);
        _24VolumeView.center = CGPointMake(self.frame.size.width / 2,
                                           self.frame.size.height / 2);
        _btcDominanceView.center = CGPointMake(self.frame.size.width - kMarketInfoInset - _btcDominanceView.frame.size.width / 2,
                                               self.frame.size.height / 2);
    }
    else {
        _marketCapView.center = CGPointMake(self.frame.size.width / 2,
                                            kMarketInfoInset + _marketCapView.frame.size.height / 2);
        _24VolumeView.center = CGPointMake(self.frame.size.width / 2,
                                           self.frame.size.height / 2);
        _btcDominanceView.center = CGPointMake(self.frame.size.width / 2,
                                               self.frame.size.height - kMarketInfoInset - _btcDominanceView.frame.size.height / 2);
    }
}

- (void)localizationUpdated
{
    [_marketCapView setTitle:TGLocalized(@"Crypto.Prices.MarketCap")];
    [_24VolumeView setTitle:TGLocalized(@"Crypto.Prices.24Volume")];
    [_btcDominanceView setTitle:TGLocalized(@"Crypto.Prices.BTCDominance")];
}

- (NSString *)usdStringWithValue:(CGFloat)value
{
    if (value < 1000) {
        return [NSString stringWithFormat:@"$%.2f",value];
    }
    int exp = (int) (log10l(value) / 3.f);
    NSArray* units = @[@"k",@"M",@"B",@"T",@"P",@"E"];
    return [NSString stringWithFormat:@"$%.2f %@", (value / pow(1000, exp)), [units objectAtIndex:(exp-1)]];
}

@end

@interface TGSortButton : UIButton

@property (nonatomic, assign) NSComparisonResult sortState;
@property (nonatomic, strong) TGPresentation *presentation;

@end

@implementation TGSortButton

- (instancetype)init
{
    if (self = [super init]) {
        self.transform = CGAffineTransformMakeScale(-1, 1);
        self.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        self.imageView.transform = CGAffineTransformMakeScale(-1, 1);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 0);
        self.adjustsImageWhenHighlighted = NO;
    }
    return self;
}

- (void)setSortState:(NSComparisonResult)sortState
{
    if (_sortState == sortState) return;
    _sortState = sortState;
    [self updateImage];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    [self setTitleColor:presentation.pallete.marketInfoMarkValueColor forState:UIControlStateNormal];
    [self updateImage];
}

- (void)updateImage
{
    switch (_sortState) {
        case NSOrderedAscending:
            [self setImage:_presentation.images.cryptoPricesSortAscendingImage forState:UIControlStateNormal];
            break;
            
        case NSOrderedDescending:
            [self setImage:_presentation.images.cryptoPricesSortDescendingImage forState:UIControlStateNormal];
            break;
            
        default:
            [self setImage:_presentation.images.cryptoPricesSortImage forState:UIControlStateNormal];
            break;
    }
}

- (CGSize)contentSize
{
    return [super sizeThatFits:CGSizeZero];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize result = [super sizeThatFits:size];
    result.width = MAX(result.width + 4, 45);
    result.height = MAX(result.height, 45);
    return result;
}

@end

typedef enum : NSUInteger {
    TGSortingCoinAscending,
    TGSortingCoinDescending,
    TGSortingPriceAscending,
    TGSortingPriceDescending,
    TGSorting24hAscending,
    TGSorting24hDescending,
} TGCoinSorting;

@class TGSortView;

@protocol TGSortViewDelegate <NSObject>

- (void)sortView:(TGSortView *)sortView didUpdateSorting:(TGCoinSorting)sorting;

@end

@interface TGSortView : UIView {
    TGSortButton *_sortCoinButton;
    TGSortButton *_sortPriceButton;
    TGSortButton *_sort24hButton;
    
    UIView *_topSeparatorView;
    UIView *_bottomSeparatorView;
}

@property (nonatomic, strong) TGPresentation *presentation;
@property (nonatomic, assign) TGCoinSorting sorting;
@property (nonatomic, weak) id<TGSortViewDelegate> delegate;

@end

@implementation TGSortView

- (instancetype)init
{
    if (self = [super init]) {
        _topSeparatorView = [[UIView alloc] init];
        [self addSubview:_topSeparatorView];
        _bottomSeparatorView = [[UIView alloc] init];
        [self addSubview:_bottomSeparatorView];
        
        _sortCoinButton = [[TGSortButton alloc] init];
        _sortPriceButton = [[TGSortButton alloc] init];
        _sort24hButton = [[TGSortButton alloc] init];
        [self.buttons enumerateObjectsUsingBlock:^(TGSortButton * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [self addSubview:obj];
            [obj addTarget:self action:@selector(sortButtopTap:) forControlEvents:UIControlEventTouchUpInside];
        }];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _topSeparatorView.frame = CGRectMake(0, 0, self.frame.size.width, 1);
    _bottomSeparatorView.frame = CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1);
    [self.buttons enumerateObjectsUsingBlock:^(TGSortButton * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj sizeToFit];
    }];
    
    {
        CGRect frame = _sortCoinButton.frame;
        frame.origin.x = kMarketViewOffset - (frame.size.width - _sortCoinButton.contentSize.width) / 2;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _sortCoinButton.frame = frame;
    }{
        CGRect frame = _sortPriceButton.frame;
        frame.origin.x = self.frame.size.width - frame.size.width - kCellPriceOffset + (frame.size.width - _sortPriceButton.contentSize.width) / 2;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _sortPriceButton.frame = frame;
    }{
        CGRect frame = _sort24hButton.frame;
        frame.origin.x = self.frame.size.width - frame.size.width - kMarketViewOffset + (frame.size.width - _sort24hButton.contentSize.width) / 2;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _sort24hButton.frame = frame;
    }
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    _topSeparatorView.backgroundColor = _bottomSeparatorView.backgroundColor = presentation.pallete.separatorColor;
    [self.buttons enumerateObjectsUsingBlock:^(TGSortButton * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj setPresentation:presentation];
    }];
}

- (void)setSorting:(TGCoinSorting)sorting
{
    _sorting = sorting;
    NSComparisonResult sortCoin = NSOrderedSame;
    NSComparisonResult sortPrice = NSOrderedSame;
    NSComparisonResult sort24h = NSOrderedSame;
    switch (sorting) {
        case TGSortingCoinAscending:
            sortCoin = NSOrderedAscending;
            break;
            
        case TGSortingCoinDescending:
            sortCoin = NSOrderedDescending;
            break;
            
        case TGSortingPriceAscending:
            sortPrice = NSOrderedAscending;
            break;
            
        case TGSortingPriceDescending:
            sortPrice = NSOrderedDescending;
            break;
            
        case TGSorting24hAscending:
            sort24h = NSOrderedAscending;
            break;
            
        case TGSorting24hDescending:
            sort24h = NSOrderedDescending;
            break;
    }
    _sortCoinButton.sortState = sortCoin;
    _sortPriceButton.sortState = sortPrice;
    _sort24hButton.sortState = sort24h;
}

- (void)sortButtopTap:(TGSortButton *)sortButton
{
    if (sortButton == _sortCoinButton) {
        self.sorting = _sorting == TGSortingCoinAscending ? TGSortingCoinDescending : TGSortingCoinAscending;
    }
    else if (sortButton == _sortPriceButton) {
        self.sorting = _sorting == TGSortingPriceDescending ? TGSortingPriceAscending : TGSortingPriceDescending;
    }
    else if (sortButton == _sort24hButton) {
        self.sorting = _sorting == TGSorting24hDescending ? TGSorting24hAscending : TGSorting24hDescending;
    }
}

- (NSArray<TGSortButton *> *)buttons
{
    return @[_sortCoinButton, _sortPriceButton, _sort24hButton];
}

- (void)localizationUpdated
{
    [_sortCoinButton setTitle:TGLocalized(@"Crypto.Prices.SortCoin") forState:UIControlStateNormal];
    [_sortPriceButton setTitle:TGLocalized(@"Crypto.Prices.SortPrice") forState:UIControlStateNormal];
    [_sort24hButton setTitle:TGLocalized(@"Crypto.Prices.Sort24h") forState:UIControlStateNormal];
}

@end

@interface TGCoinCell : UITableViewCell {
    UIView *_separatorView;
    BOOL _priceRising;
    BOOL _h24Rising;
}

@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) TGRemoteImageView *iconImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UILabel *h24Label;

@property (nonatomic, strong) TGPresentation *presentation;

@end

@implementation TGCoinCell

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        _favoriteButton = [[UIButton alloc] init];
        _favoriteButton.adjustsImageWhenHighlighted = NO;
        [_favoriteButton addTarget:self action:@selector(favoriteButtonTap) forControlEvents:UIControlEventTouchUpInside];
        _iconImageView = [[TGRemoteImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _nameLabel = [[UILabel alloc] init];
        _priceLabel = [[UILabel alloc] init];
        _h24Label = [[UILabel alloc] init];
        _separatorView = [[UIView alloc] init];
        
        [@[
           _favoriteButton,
           _iconImageView,
           _nameLabel,
           _priceLabel,
           _h24Label,
           _separatorView,
           ] enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
               [self.contentView addSubview:obj];
           }];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
}

- (void)favoriteButtonTap
{
    _favoriteButton.selected = !_favoriteButton.selected;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _separatorView.frame = CGRectMake(kMarketViewOffset, self.contentView.frame.size.height - 1, self.contentView.frame.size.width - kMarketViewOffset * 2, 1);
    {
        CGSize contentSize = CGSizeMake(15, 14);
        CGRect frame = CGRectZero;
        frame.size.width = MAX(contentSize.width, 45);
        frame.size.height = MAX(contentSize.height, 45);
        frame.origin.x = kMarketViewOffset - (frame.size.width - contentSize.width) / 2;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _favoriteButton.frame = frame;
    }{
        CGFloat iconSide = self.contentView.frame.size.height - 2 * kCellIconOffset;
        _iconImageView.frame = CGRectMake(CGRectGetMaxX(_favoriteButton.frame), kCellIconOffset,
                                          iconSide, iconSide);
    }{
        CGRect frame = CGRectZero;
        frame.size = [_priceLabel sizeThatFits:CGSizeZero];
        frame.origin.x = self.contentView.frame.size.width - kCellPriceOffset - frame.size.width;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _priceLabel.frame = frame;
    }{
        CGSize contentSize = [_nameLabel sizeThatFits:CGSizeZero];
        CGRect frame = CGRectZero;
        frame.origin.x = CGRectGetMaxX(_iconImageView.frame) + kCellIconOffset;
        frame.size.width = MIN(contentSize.width, _priceLabel.frame.origin.x - frame.origin.x - kCellIconOffset);
        frame.size.height = contentSize.height;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _nameLabel.frame = frame;
    }{
        CGRect frame = CGRectZero;
        frame.size = [_h24Label sizeThatFits:CGSizeZero];
        frame.origin.x = self.contentView.frame.size.width - kMarketViewOffset - frame.size.width;
        frame.origin.y = (self.frame.size.height - frame.size.height) / 2;
        _h24Label.frame = frame;
    }
}

- (void)setPrice:(CGFloat)price rising:(BOOL)rising
{
    _priceLabel.text = [NSString stringWithFormat:@"$%.2f", price];
    [_priceLabel setTextColor:rising ? _presentation.pallete.accentColor : _presentation.pallete.destructiveColor];
    _priceRising = rising;
}

- (void)set24h:(CGFloat)h24 rising:(BOOL)rising
{
    _h24Label.text = [NSString stringWithFormat:@"%.2f%%", h24];
    [_h24Label setTextColor:rising ? _presentation.pallete.accentColor : _presentation.pallete.destructiveColor];
    _h24Rising = rising;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    if ([_presentation isEqual:presentation]) return;
    _presentation = presentation;
    [_favoriteButton setImage:presentation.images.cryptoPricesUnfavoritedImage forState:UIControlStateNormal];
    [_favoriteButton setImage:presentation.images.cryptoPricesFavoritedImage forState:UIControlStateSelected];
    [_nameLabel setTextColor:presentation.pallete.marketInfoMarkValueColor];
    _separatorView.backgroundColor = presentation.pallete.separatorColor;
    [_priceLabel setTextColor:_priceRising ? _presentation.pallete.accentColor : _presentation.pallete.destructiveColor];
    [_h24Label setTextColor:_h24Rising ? _presentation.pallete.accentColor : _presentation.pallete.destructiveColor];
}

@end

@interface TGCryptoPricesViewController () <TGSortViewDelegate, UITableViewDelegate, UITableViewDataSource> {
    TGMarketInfoView *_marketInfoView;
    
    UIView *_filterView;
    TGSearchBar *_searchBar;
    UIButton *_favoritesFilterButton;
    
    TGSortView *_sortView;
    
    UITableView *_tableView;
}

@property (nonatomic, strong) TGPresentation *presentation;

@end

@implementation TGCryptoPricesViewController

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    if (self = [super init]) {
        _presentation = presentation;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _marketInfoView = [[TGMarketInfoView alloc] init];
    
    _filterView = [UIView new];
    
    _searchBar = [[TGSearchBar alloc] initWithFrame:CGRectZero style:TGSearchBarStyleLightPlain];
    _searchBar.backgroundColor = UIColor.clearColor;
    [_filterView addSubview:_searchBar];
    
    _favoritesFilterButton = [[UIButton alloc] init];
    _favoritesFilterButton.adjustsImageWhenHighlighted = false;
    [_favoritesFilterButton addTarget:self action:@selector(favoritesFilterButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [_filterView addSubview:_favoritesFilterButton];

    _sortView = [[TGSortView alloc] init];
    _sortView.delegate = self;
    _sortView.sorting = TGSortingPriceDescending;
    
    _tableView = [[TGTableView alloc] init];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 50;
    [_tableView registerClass:[TGCoinCell class] forCellReuseIdentifier:TGCoinCell.reuseIdentifier];
    
    [@[
       _marketInfoView,
       _filterView,
       _sortView,
       _tableView
       ] enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [self.view addSubview:obj];
       }];
    [self setPresentation:_presentation];
    [self localizationUpdated];
//    TMP
    [_marketInfoView setMarketCapValue:199534116331.4769 change:6.2573];
    [_marketInfoView set24VolumeValue:11463411633.4769 change:-2.72123];
    [_marketInfoView setBTCDominanceValue:53.67 change:-0.0831];
    [[[TGSortButton alloc] init] setTitle:@"asd" forState:UIControlStateNormal];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = presentation.pallete.backgroundColor;
    
    _searchBar.pallete = presentation.searchBarPallete;
    [_favoritesFilterButton setImage:presentation.images.cryptoPricesFilterFavoriteDeselectedImage forState:UIControlStateNormal];
    [_favoritesFilterButton setImage:presentation.images.cryptoPricesFilterFavoriteSelectedImage forState:UIControlStateSelected];
    
    [_marketInfoView setPresentation:presentation];
    
    [_sortView setPresentation:presentation];
    [_tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof TGCoinCell * _Nonnull cell, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [cell setPresentation:presentation];
    }];
}

- (void)controllerInsetUpdated:(__unused UIEdgeInsets)previousInset
{
    _searchBar.safeAreaInset = [self controllerSafeAreaInset];
    
    if (UIInterfaceOrientationIsPortrait(self.currentInterfaceOrientation)) {
        _marketInfoView.frame = CGRectMake(kMarketViewOffset, kMarketViewOffset + self.controllerInset.top,
                                           self.view.frame.size.width - 2 * kMarketViewOffset, kMarketViewHeight);
        _filterView.frame = CGRectMake(kMarketViewOffset - 8, CGRectGetMaxY(_marketInfoView.frame) + kMarketViewOffset,
                                       self.view.frame.size.width - 2 * kMarketViewOffset + (kFilterViewHeight - [_favoritesFilterButton imageForState:UIControlStateNormal].size.width) / 2 + 16,
                                       kFilterViewHeight);
        _sortView.frame = CGRectMake(0, CGRectGetMaxY(_filterView.frame) + kMarketViewOffset,
                                     self.view.frame.size.width, kSortViewHeight);
    }
    else {
        _marketInfoView.frame = CGRectMake(kMarketViewOffset / 2 + self.controllerSafeAreaInset.left,
                                           kMarketViewOffset + self.controllerInset.top,
                                           kMarketViewWidth,
                                           self.view.frame.size.height - 2 * kMarketViewOffset - self.controllerInset.top - self.controllerInset.bottom);
        _filterView.frame = CGRectMake(CGRectGetMaxX(_marketInfoView.frame) + kMarketViewOffset - 8,
                                       kMarketViewOffset + self.controllerInset.top,
                                       self.view.frame.size.width - 2 * kMarketViewOffset - CGRectGetMaxX(_marketInfoView.frame) - self.controllerSafeAreaInset.right + 16,
                                       kFilterViewHeight);
        _sortView.frame = CGRectMake(CGRectGetMaxX(_marketInfoView.frame), CGRectGetMaxY(_filterView.frame) + kMarketViewOffset / 2,
                                     self.view.frame.size.width - self.controllerSafeAreaInset.right - CGRectGetMaxX(_marketInfoView.frame), kSortViewHeight);
    }
    _tableView.frame = CGRectMake(_sortView.frame.origin.x, CGRectGetMaxY(_sortView.frame), _sortView.frame.size.width,
                                  self.view.frame.size.height - CGRectGetMaxY(_sortView.frame) - self.controllerInset.bottom + 1);
    
    _favoritesFilterButton.frame = CGRectMake(_filterView.frame.size.width - kFilterViewHeight,
                                              0,
                                              kFilterViewHeight, kFilterViewHeight);
    _searchBar.frame = CGRectMake(0, 0, _filterView.frame.size.width - kFilterViewInset - _favoritesFilterButton.frame.size.width, kFilterViewHeight);
}

- (void)localizationUpdated
{
    _searchBar.placeholder = TGLocalized(@"Crypto.Prices.SearchLabel");
    [_marketInfoView localizationUpdated];
    [_sortView localizationUpdated];
}

- (void)favoritesFilterButtonTap
{
    _favoritesFilterButton.selected = !_favoritesFilterButton.selected;
}

#pragma mark - TGSortViewDelegate

- (void)sortView:(__unused TGSortView *)sortView didUpdateSorting:(TGCoinSorting)sorting
{
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGCoinCell *cell = (TGCoinCell *)[tableView dequeueReusableCellWithIdentifier:TGCoinCell.reuseIdentifier];
    [cell setPresentation:_presentation];
    [cell.iconImageView loadImage:@"https://beta.livecoinwatch.com/public/coins/icons/32/xlm.png" filter:@"circle:30x30" placeholder:nil];
    cell.nameLabel.text = @"Bitcoin";
    cell.priceLabel.text = [NSString stringWithFormat:@"$%.2f", 6324.7123];
    [cell setPrice:6324.7123 + indexPath.row rising:YES];
    [cell set24h:6.123 rising:NO];
    return cell;
}

#pragma mark - UITableViewDelegate

@end
