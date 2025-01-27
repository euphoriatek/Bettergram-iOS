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
#import "TGApplication.h"

#import "TGCryptoChoosePriceViewController.h"
#import "TGCryptoManager.h"
#import "TGAppDelegate.h"
#import "TGCryptoTabViewController.h"
#import "TGViewController+OpenLink.h"


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

const NSUInteger kPagesLimitMultiplier = 3;
const NSUInteger kCellsLimitMultiplier = 10;

@interface TGMarketInfoMarkView : UIView {
    UILabel *_titleLabel;
    UILabel *_valueLabel;
    UILabel *_changeLabel;
    TGPresentation *_presentation;
    CGFloat _change;
}

@property (nonatomic, strong) TGPresentation *presentation;

@property (nonatomic, strong) NSNumberFormatter *percentFormatter;

@end

@implementation TGMarketInfoMarkView

- (instancetype)initWithPercentFormatter:(NSNumberFormatter *)percentFormatter
{
    if (self = [super init]) {
        _percentFormatter = percentFormatter;
        
        _titleLabel = [UILabel.alloc init];
        _titleLabel.font = TGSystemFontOfSize(10);
        
        _valueLabel = [UILabel.alloc init];
        _valueLabel.font = TGSystemFontOfSize(16);
        
        _changeLabel = [UILabel.alloc init];
        _changeLabel.font = TGSystemFontOfSize(10);
        
        [self addSubviews:self.labels];
    }
    return self;
}

- (NSArray<UIView *> *)labels
{
    return @[_titleLabel, _valueLabel];
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
    _changeLabel.text = [NSString stringWithFormat:@"(%@)", [self.percentFormatter stringFromNumber:@(change)]];
    [self updateMarkChangeLabelFont];
    [self setNeedsLayout];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    _titleLabel.textColor = presentation.pallete.secondaryTextColor;
    _valueLabel.textColor = presentation.pallete.textColor;
    [self updateMarkChangeLabelFont];
}

- (void)updateMarkChangeLabelFont
{
    if (_change > 0) {
        _changeLabel.textColor = _presentation.pallete.accentColor;
    }
    else if (_change < 0) {
        _changeLabel.textColor = _presentation.pallete.destructiveColor;
    }
    else {
        _changeLabel.textColor = _presentation.pallete.secondaryTextColor;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.labels enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj sizeToFit];
    }];
    
    CGPoint center = CGPointMake(self.frame.size.width / 2,
                                 _titleLabel.frame.size.height / 2);
    _titleLabel.center = center;
    
    center.y = CGRectGetMaxY(_titleLabel.frame) + kMarketInfoOffset + _valueLabel.frame.size.height / 2;
    _valueLabel.center = center;
    
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
    sizeThatFits.height += kMarketInfoOffset * (self.labels.count - 1);
    return sizeThatFits;
}

@end

@interface TGMarketInfoCell : UITableViewCell {
    TGMarketInfoMarkView *_marketCapView;
    TGMarketInfoMarkView *_24VolumeView;
    TGMarketInfoMarkView *_btcDominanceView;
}

@property (nonatomic, strong) NSNumberFormatter *percentFormatter;
@property (nonatomic, strong) NSNumberFormatter *currencyFormatter;

@property (nonatomic, strong) TGPresentation *presentation;

@property (nonatomic, assign) BOOL ignoreTableView;

@end

@implementation TGMarketInfoCell

- (instancetype)initWithPercentFormatter:(NSNumberFormatter *)percentFormatter currencyFormatter:(NSNumberFormatter *)currencyFormatter
{
    if (self = [super init]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        _percentFormatter = percentFormatter;
        _currencyFormatter = currencyFormatter;
        
        _marketCapView = [TGMarketInfoMarkView.alloc initWithPercentFormatter:percentFormatter];
        _24VolumeView = [TGMarketInfoMarkView.alloc initWithPercentFormatter:percentFormatter];
        _btcDominanceView = [TGMarketInfoMarkView.alloc initWithPercentFormatter:percentFormatter];
        
        [self.contentView addSubviews:self.views];
    }
    return self;
}

- (void)setAlpha:(CGFloat)alpha
{
    if (_ignoreTableView && ![self.superview isKindOfClass:[UITableView class]]) return;
    [super setAlpha:alpha];
}

- (void)removeFromSuperview
{
    if (_ignoreTableView && ![self.superview isKindOfClass:[UITableView class]]) return;
    [super removeFromSuperview];
}

- (NSArray<TGMarketInfoMarkView *> *)views
{
    return @[_marketCapView, _24VolumeView, _btcDominanceView];
}

- (void)setMarketCapValue:(double)value change:(double)change
{
    [_marketCapView setValueString:[self.currencyFormatter stringFromNumber:@(value)]];
    [_marketCapView setChange:change];
    [self setNeedsLayout];
}

- (void)set24VolumeValue:(double)value change:(double)change
{
    [_24VolumeView setValueString:[self.currencyFormatter stringFromNumber:@(value)]];
    [_24VolumeView setChange:change];
    [self setNeedsLayout];
}

- (void)setBTCDominanceValue:(double)value change:(double)change
{
    [_btcDominanceView setValueString:[NSString stringWithFormat:@"%.2f%%",value * 100]];
    [_btcDominanceView setChange:change];
    [self setNeedsLayout];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    if ([_presentation isEqual:presentation]) return;
    [self updateShadow];
    self.contentView.backgroundColor = presentation.pallete.backgroundColor;
    [self.views enumerateObjectsUsingBlock:^(TGMarketInfoMarkView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj setPresentation:presentation];
    }];
}

- (void)updateShadow
{
    [self.contentView.layer applySketchShadowWithColor:self.presentation.pallete.secondaryTextColor
                                               opacity:0.2
                                                     x:self.isPortrait ? 0 : 1
                                                     y:self.isPortrait ? 1 : 0
                                                  blur:6];
}

- (BOOL)isPortrait
{
    return self.contentView.frame.size.height < self.contentView.frame.size.width;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateShadow];
    UIEdgeInsets contentEdgeInsets;
    if (self.isPortrait) {
        contentEdgeInsets = UIEdgeInsetsMake(kMarketViewOffset, kMarketViewOffset, 0, kMarketViewOffset);
    }
    else {
        contentEdgeInsets = UIEdgeInsetsMake(kMarketViewOffset, kMarketViewOffset / 2, kMarketViewOffset, 0);
    }
    self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, contentEdgeInsets);
    
    [self.views enumerateObjectsUsingBlock:^(TGMarketInfoMarkView * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        [obj sizeToFit];
    }];
    _24VolumeView.center = CGPointMake(self.contentView.frame.size.width / 2,
                                       self.contentView.frame.size.height / 2);
    if (self.isPortrait) {
        {
            CGRect frame = _marketCapView.frame;
            frame.origin.y = (self.contentView.frame.size.height - frame.size.height) / 2;
            frame.origin.x = MAX(0,MIN(kMarketInfoInset, (CGRectGetMinX(_24VolumeView.frame) - frame.size.width) / 2));
            _marketCapView.frame = frame;
        }{
            CGRect frame = _btcDominanceView.frame;
            frame.origin.y = (self.contentView.frame.size.height - frame.size.height) / 2;
            frame.origin.x = self.contentView.frame.size.width - frame.size.width - MAX(0,MIN(kMarketInfoInset, (self.contentView.frame.size.width - CGRectGetMaxX(_24VolumeView.frame) - frame.size.width) / 2));
            _btcDominanceView.frame = frame;
        }
    }
    else {
        _marketCapView.center = CGPointMake(self.contentView.frame.size.width / 2,
                                            kMarketInfoInset + _marketCapView.frame.size.height / 2);
        _btcDominanceView.center = CGPointMake(self.contentView.frame.size.width / 2,
                                               self.contentView.frame.size.height - kMarketInfoInset - _btcDominanceView.frame.size.height / 2);
    }
}

- (void)localizationUpdated
{
    [_marketCapView setTitle:[NSString stringWithFormat:@"%@:",TGLocalized(@"Crypto.Prices.MarketCap")]];
    [_24VolumeView setTitle:[NSString stringWithFormat:@"%@:",TGLocalized(@"Crypto.Prices.24Volume")]];
    [_btcDominanceView setTitle:TGLocalized(@"Crypto.Prices.BTCDominance")];
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
    [self setTitleColor:presentation.pallete.textColor forState:UIControlStateNormal];
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


@class TGFilterCell;

@protocol TGFilterCellDelegate <TGSearchBarDelegate>

- (void)filterCellDidUpdateFilterState:(TGFilterCell *)filterCell;

@end

@interface TGFilterCell : UITableViewCell

@property (nonatomic, strong, readonly) TGSearchBar *searchBar;
@property (nonatomic, strong, readonly) UIButton *favoritesFilterButton;

@property (nonatomic, weak) id<TGFilterCellDelegate> delegate;

@property (nonatomic, readonly) BOOL isFiltered;

@end

@implementation TGFilterCell

- (instancetype)init
{
    if (self = [super init]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        _searchBar = [TGSearchBar.alloc initWithFrame:CGRectZero style:TGSearchBarStyleLightPlain];
        _searchBar.backgroundColor = UIColor.clearColor;
        _searchBar.clipsToBounds = YES;
        
        _favoritesFilterButton = [UIButton.alloc init];
        _favoritesFilterButton.adjustsImageWhenHighlighted = NO;
        [_favoritesFilterButton addTarget:self action:@selector(favoritesFilterButtonTap) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubviews:@[_favoritesFilterButton, _searchBar]];
    }
    return self;
}

- (void)setDelegate:(id<TGFilterCellDelegate>)delegate
{
    _delegate = delegate;
    _searchBar.delegate = delegate;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame,
                                                   UIEdgeInsetsMake((self.frame.size.height - kFilterViewHeight) / 2,
                                                                    kMarketViewOffset - TGSearchBar.textFieldOffsetX,
                                                                    (self.frame.size.height - kFilterViewHeight) / 2,
                                                                    (kFilterViewHeight - [_favoritesFilterButton imageForState:UIControlStateNormal].size.width) / 2 + TGSearchBar.textFieldOffsetX * 2));
    _favoritesFilterButton.frame = CGRectMake(self.contentView.frame.size.width - kFilterViewHeight,
                                              0,
                                              kFilterViewHeight, kFilterViewHeight);
    _searchBar.frame = CGRectMake(0, 0, self.contentView.frame.size.width - kFilterViewInset - _favoritesFilterButton.frame.size.width, kFilterViewHeight);
}

- (void)favoritesFilterButtonTap
{
    _favoritesFilterButton.selected = !_favoritesFilterButton.selected;
    [self.delegate filterCellDidUpdateFilterState:self];
}

- (BOOL)isFiltered
{
    return _searchBar.isFirstResponder || _searchBar.text.length > 0;
}

@end


@class TGSortCell;

@protocol TGSortCellDelegate <NSObject>

- (void)sortView:(TGSortCell *)sortView didUpdateSorting:(TGCoinSorting)sorting;

@end

@interface TGSortCell : UITableViewCell {
    TGSortButton *_sortCoinButton;
    TGSortButton *_sortPriceButton;
    TGSortButton *_sort24hButton;
    
    UIView *_topSeparatorView;
    UIView *_bottomSeparatorView;
}

@property (nonatomic, strong) TGPresentation *presentation;
@property (nonatomic, assign) TGCoinSorting sorting;
@property (nonatomic, weak) id<TGSortCellDelegate> delegate;

@end

@implementation TGSortCell

- (instancetype)init
{
    if (self = [super init]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        _topSeparatorView = [UIView.alloc init];
        _bottomSeparatorView = [UIView.alloc init];
        [self addSubviews:@[_bottomSeparatorView, _topSeparatorView]];
        
        _sortCoinButton = [TGSortButton.alloc init];
        _sortPriceButton = [TGSortButton.alloc init];
        _sort24hButton = [TGSortButton.alloc init];
        [self addSubviews:self.buttons];
        [self.buttons enumerateObjectsUsingBlock:^(TGSortButton * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
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
            
        default:
            break;
    }
    _sortCoinButton.sortState = sortCoin;
    _sortPriceButton.sortState = sortPrice;
    _sort24hButton.sortState = sort24h;
    [self.delegate sortView:self didUpdateSorting:sorting];
}

- (void)sortButtopTap:(TGSortButton *)sortButton
{
    if (sortButton == _sortCoinButton) {
        switch (_sorting) {
            case TGSortingCoinAscending:
                self.sorting = TGSortingCoinDescending;
                break;
                
            case TGSortingCoinDescending:
                self.sorting = TGSortingNone;
                break;
                
            default:
                self.sorting = TGSortingCoinAscending;
                break;
        }
    }
    else if (sortButton == _sortPriceButton) {
        switch (_sorting) {
            case TGSortingPriceAscending:
                self.sorting = TGSortingNone;
                break;
                
            case TGSortingPriceDescending:
                self.sorting = TGSortingPriceAscending;
                break;
                
            default:
                self.sorting = TGSortingPriceDescending;
                break;
        }
    }
    else if (sortButton == _sort24hButton) {
        switch (_sorting) {
            case TGSorting24hAscending:
                self.sorting = TGSortingNone;
                break;
                
            case TGSorting24hDescending:
                self.sorting = TGSorting24hAscending;
                break;
                
            default:
                self.sorting = TGSorting24hDescending;
                break;
        }
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

@class TGCoinCell;

@protocol TGCoinCellDelegate <NSObject>

- (void)coinCell:(TGCoinCell *)cell didTapFavoriteButton:(UIButton *)favoriteButton;

@end


@interface TGCoinCell : UITableViewCell {
    UIView *_separatorView;
}

@property (nonatomic, strong, readonly) UIButton *favoriteButton;
@property (nonatomic, strong, readonly) TGRemoteImageView *iconImageView;
@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *priceLabel;
@property (nonatomic, strong, readonly) UILabel *h24Label;

@property (nonatomic, strong) TGPresentation *presentation;
@property (nonatomic, weak) id<TGCoinCellDelegate> delegate;

@property (nonatomic, assign) NSComparisonResult priceDelta;
@property (nonatomic, assign) NSComparisonResult h24Delta;

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
        
        _favoriteButton = [UIButton.alloc init];
        _favoriteButton.adjustsImageWhenHighlighted = NO;
        [_favoriteButton addTarget:self action:@selector(favoriteButtonTap) forControlEvents:UIControlEventTouchUpInside];
        
        _iconImageView = [TGRemoteImageView.alloc init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.contentHints = TGRemoteImageContentHintLoadFromDiskSynchronously;
        
        _nameLabel = [UILabel.alloc init];
        _nameLabel.font = TGSystemFontOfSize(16);
        
        _priceLabel = [UILabel.alloc init];
        _priceLabel.font = TGSystemFontOfSize(14);
        
        _h24Label = [UILabel.alloc init];
        _h24Label.font = TGSystemFontOfSize(14);
        
        [self.contentView addSubviews:@[
                                        _favoriteButton,
                                        _iconImageView,
                                        _nameLabel,
                                        _priceLabel,
                                        _h24Label,
                                        _separatorView = [UIView.alloc init],
                                        ]];
    }
    return self;
}

- (void)favoriteButtonTap
{
    [self.delegate coinCell:self didTapFavoriteButton:_favoriteButton];
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

- (void)setPriceDelta:(NSComparisonResult)priceDelta
{
    _priceDelta = priceDelta;
    _priceLabel.textColor = [self textColorForDelta:_priceDelta];
}

- (void)setH24Delta:(NSComparisonResult)h24Delta
{
    _h24Delta = h24Delta;
    _h24Label.textColor = [self textColorForDelta:_h24Delta];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    if ([_presentation isEqual:presentation]) return;
    _presentation = presentation;
    [_favoriteButton setImage:presentation.images.cryptoPricesUnfavoritedImage forState:UIControlStateNormal];
    [_favoriteButton setImage:presentation.images.cryptoPricesFavoritedImage forState:UIControlStateSelected];
    [_nameLabel setTextColor:presentation.pallete.textColor];
    _separatorView.backgroundColor = presentation.pallete.separatorColor;
    _priceLabel.textColor = [self textColorForDelta:_priceDelta];
    _h24Label.textColor = [self textColorForDelta:_h24Delta];
}

- (UIColor *)textColorForDelta:(NSComparisonResult)delta
{
    switch (delta) {
        case NSOrderedAscending:
            return _presentation.pallete.accentColor;
            
        case NSOrderedDescending:
            return _presentation.pallete.destructiveColor;
            
        default:
            return _presentation.pallete.secondaryTextColor;
    }
}

@end


@interface TGLoadingCell : UITableViewCell

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation TGLoadingCell

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass(self);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        
        _activityIndicatorView = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:_activityIndicatorView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _activityIndicatorView.center = self.contentView.center;
}

@end


@interface TGCryptoPricesViewController () <UITableViewDelegate, UITableViewDataSource, TGSortCellDelegate, TGFilterCellDelegate, TGCoinCellDelegate> {
    TGMarketInfoCell *_marketInfoCell;
    TGFilterCell *_filterCell;
    TGSortCell *_sortCell;
    
    TGListsTableView *_tableView;
    NSArray<UITableViewCell *> *_topSectionCells;
    CGFloat _topSectionCellsHeight;
    CGPoint _lastContentOffset;
    NSInteger _lastSelectedPageIndex;
    
    TGCryptoNumberFormatter *_percentFormatter;
    TGCryptoNumberFormatter *_currencyFormatter;
    
    UIBarButtonItem *_rightButtonItem;
    UIBarButtonItem *_leftButtonItem;
    
    BOOL _resetScrollPosition;
    
    UIButton *_titleView;
    
    BOOL _filterActivated;
    
    UILabel *_apiOutOfDateLabel;
    
    TGCryptoPricesInfo *_pendingUpdate;
    
    CGSize _lastFrameUpdateViewSize;
    
    BOOL _pagingEnabled;
    
    NSInteger _forceUpdateFlags;
}

@property (nonatomic, strong) TGPresentation *presentation;
@property (nonatomic, strong) TGCryptoPricesInfo *pricesInfo;

@end

@implementation TGCryptoPricesViewController

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    if (self = [super init]) {
        _presentation = presentation;
        _lastSelectedPageIndex = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _pagingEnabled = NO;
    
    self.ignoreKeyboardWhenAdjustingScrollViewInsets = YES;
    
    _percentFormatter = [TGCryptoNumberFormatter.alloc init];
    _percentFormatter.positivePrefix = @"+";
    _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
    _percentFormatter.minimumFractionDigits = 2;
    
    _currencyFormatter = [TGCryptoNumberFormatter.alloc init];
    _currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    
    _marketInfoCell = [TGMarketInfoCell.alloc initWithPercentFormatter:_percentFormatter currencyFormatter:_currencyFormatter];
    
    _filterCell = [TGFilterCell.alloc init];
    _filterCell.delegate = self;
    
    _sortCell = [TGSortCell.alloc init];
    _sortCell.sorting = TGSortingNone;
    _sortCell.delegate = self;
    
    [self.view addSubview:(_tableView = [TGListsTableView.alloc init])];
    _tableView.backgroundColor = nil;
    _tableView.decelerationRate = _pagingEnabled ? UIScrollViewDecelerationRateFast : UIScrollViewDecelerationRateNormal;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 50;
    [_tableView registerClass:TGCoinCell.class forCellReuseIdentifier:TGCoinCell.reuseIdentifier];
    [_tableView registerClass:TGLoadingCell.class forCellReuseIdentifier:TGLoadingCell.reuseIdentifier];
    [_tableView reloadData];
    _tableView.refreshControl = [[UIRefreshControl alloc] init];
    [_tableView.refreshControl addTarget:self action:@selector(refreshStateChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.titleView = _titleView = [UIButton.alloc init];
    [_titleView addTarget:self action:@selector(titleViewTap) forControlEvents:UIControlEventTouchUpInside];
    _titleView.adjustsImageWhenHighlighted = NO;
    [_titleView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(titleViewLongPress:)]];
    
    [self setRightBarButtonItem:_rightButtonItem = [UIBarButtonItem.alloc initWithImage:nil
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(currencyButtonTap)]
                       animated:false];
    
    if (!TGIsPad()) {
        [self setLeftBarButtonItem:_leftButtonItem = [UIBarButtonItem.alloc initWithImage:nil
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:@selector(settingsButtonTap)]
                          animated:false];
    }
    [self setPresentation:_presentation];
    [self localizationUpdated];
    
    if (TGCryptoManager.manager.apiOutOfDate) {
        [self apiOutOfDate];
    }
    else {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(apiOutOfDate)
                                                   name:TGCryptoManagerAPIOutOfDate
                                                 object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateRightButtonItemImage];
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self pageInfoUpdated];
    __weak TGCryptoPricesViewController *weakSelf = self;
    [TGCryptoManager.manager setStatsUpdateBlock:^(TGCryptoPricesInfo *pricesInfo) {
        TGDispatchOnMainThread(^{
            __strong TGCryptoPricesViewController *strongSelf = weakSelf;
            if (strongSelf != nil && pricesInfo != nil) {
                [self stateUpdated:2];
                _currencyFormatter.currencySymbol = pricesInfo.currency.symbol ?: @"";
                [_marketInfoCell setMarketCapValue:pricesInfo.marketCap change:0];
                [_marketInfoCell set24VolumeValue:pricesInfo.volume change:0];
                [_marketInfoCell setBTCDominanceValue:pricesInfo.btcDominance change:0];
            }
        });
    } pageUpdateBlock:^(TGCryptoPricesInfo *pricesInfo) {
        TGDispatchOnMainThread(^{
            __strong TGCryptoPricesViewController *strongSelf = weakSelf;
            if (strongSelf != nil && pricesInfo != nil) {
                [self stateUpdated:1];
                strongSelf.pricesInfo = pricesInfo;
            }
        });
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [TGCryptoManager.manager setStatsUpdateBlock:NULL pageUpdateBlock:NULL];    
    [super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return !TGIsPad() && _filterCell.isFiltered;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!CGSizeEqualToSize(_lastFrameUpdateViewSize, self.view.bounds.size)) {
        [self controllerInsetUpdated:UIEdgeInsetsZero];
    }
}

- (void)controllerInsetUpdated:(__unused UIEdgeInsets)previousInset
{
    if (!self.isViewLoaded) return;
    
    if (_apiOutOfDateLabel) {
        _apiOutOfDateLabel.frame = self.view.bounds;
        return;
    }
    if (_filterCell.isFiltered && !_filterActivated) return;
    _lastFrameUpdateViewSize = self.view.bounds.size;
    _marketInfoCell.ignoreTableView = UIInterfaceOrientationIsLandscape(self.currentInterfaceOrientation);
    [self updateTopSectionCells];
    {
        CGRect frame = CGRectMake(0, self.controllerInset.top,
                                  _lastFrameUpdateViewSize.width,
                                  _lastFrameUpdateViewSize.height - self.controllerInset.top - self.controllerInset.bottom + 1);
        
        if (_marketInfoCell.ignoreTableView) {
            [self.view addSubview:_marketInfoCell];
            _marketInfoCell.frame = CGRectMake(self.controllerSafeAreaInset.left,
                                               self.controllerInset.top,
                                               kMarketViewWidth,
                                               frame.size.height - 1);
            frame.origin.x = CGRectGetMaxX(_marketInfoCell.frame);
            frame.size.width -= CGRectGetMaxX(_marketInfoCell.frame) + self.controllerSafeAreaInset.right;
        }
        else {
            if (_marketInfoCell.superview == self.view) {
                [_marketInfoCell removeFromSuperview];
            }
        }
        _tableView.frame = frame;
    }
    [self updateTableViewContentSizeReloadDataCells:NO];
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = presentation.pallete.backgroundColor;
    
    [_filterCell.searchBar setSearchBarPallete:presentation.keyboardSearchBarPallete
                       segmentedControlPallete:presentation.segmentedControlPallete];
    [_filterCell.favoritesFilterButton setImage:presentation.images.cryptoPricesFilterFavoriteDeselectedImage forState:UIControlStateNormal];
    [_filterCell.favoritesFilterButton setImage:presentation.images.cryptoPricesFilterFavoriteSelectedImage forState:UIControlStateSelected];
    
    [_marketInfoCell setPresentation:presentation];
    [_sortCell setPresentation:presentation];
    [_tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof UITableViewCell * _Nonnull cell, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[TGCoinCell class]])
            [(TGCoinCell *)cell setPresentation:presentation];
        else if ([cell isKindOfClass:TGLoadingCell.class])
            ((TGLoadingCell *)cell).activityIndicatorView.color = _presentation.pallete.textColor;
    }];
    [self updateRightButtonItemImage];
    _leftButtonItem.image = _presentation.images.settingsButton;
    [_titleView setImage:TGTintedImage(TGImageNamed(@"header_logo_live_coin_watch"), _presentation.pallete.navigationTitleColor)
                forState:UIControlStateNormal];
    _apiOutOfDateLabel.textColor = _presentation.pallete.textColor;
    _tableView.refreshControl.tintColor = _presentation.pallete.textColor;
}

- (void)localizationUpdated
{
    _filterCell.searchBar.placeholder = TGLocalized(@"Crypto.Prices.SearchLabel");
    [_marketInfoCell localizationUpdated];
    [_sortCell localizationUpdated];
    _apiOutOfDateLabel.text = TGLocalized(@"Crypto.Prices.API.Out.Of.Date");
}

- (void)currencyButtonTap
{
    UIViewController *viewController = [TGCryptoChoosePriceViewController.alloc initWithPresentation:_presentation];
    if (TGIsPad()) {
        TGPopoverController *popoverController = [[TGPopoverController alloc] initWithContentViewController:viewController];
        [popoverController setContentSize:CGSizeMake(320.0f, 528.0f)];
        
        [popoverController presentPopoverFromBarButtonItem:self.tabBarController.navigationItem.rightBarButtonItem
                                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                                  animated:true];
    }
    else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)settingsButtonTap
{
    TGViewController *accountSettingsController = TGAppDelegateInstance.rootController.accountSettingsController;
    [TGAppDelegateInstance.rootController pushContentController:accountSettingsController];
    
    [accountSettingsController setTargetNavigationItem:accountSettingsController.navigationItem titleController:TGAppDelegateInstance.rootController];
}

- (void)scrollToTopRequested
{
    [_tableView scrollToTop];
}

- (void)titleViewTap
{
    [(TGApplication *)[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.livecoinwatch.com/"]
                                                    forceNative:true
                                                      keepStack:true];
}

- (void)titleViewLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showActionsMenuForLink:@"https://www.livecoinwatch.com/"
                             webPage:nil];
        
    }
}

- (void)refreshStateChanged:(UIRefreshControl *)__unused sender
{
    setbit(&_forceUpdateFlags, 1);
    setbit(&_forceUpdateFlags, 2);
    [TGCryptoManager.manager forceUpdatePrices];
}

#pragma mark - TGSortCellDelegate

- (void)sortView:(__unused TGSortCell *)sortView didUpdateSorting:(__unused TGCoinSorting)sorting
{
    _resetScrollPosition = YES;
    [self pageInfoUpdated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView
{
    if (_apiOutOfDateLabel)
        return 0;
    return _topSectionCells.count + 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < (NSInteger)_topSectionCells.count) {
        return 1;
    }
    return self.coinInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<UITableViewCell *> *topSectionCells = _topSectionCells;
    if (indexPath.section < (NSInteger)_topSectionCells.count) {
        return topSectionCells[indexPath.section];
    }
    TGCryptoCurrency *coinInfo = self.coinInfos[indexPath.row];
    if (coinInfo.code == nil && indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        TGLoadingCell *cell = (TGLoadingCell *)[tableView dequeueReusableCellWithIdentifier:TGLoadingCell.reuseIdentifier];
        cell.activityIndicatorView.color = _presentation.pallete.textColor;
        return cell;
    }
    TGCoinCell *cell = (TGCoinCell *)[tableView dequeueReusableCellWithIdentifier:TGCoinCell.reuseIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    [cell setPresentation:_presentation];
    if (coinInfo.iconURL) {
        [cell.iconImageView loadImage:coinInfo.iconURL filter:@"circle:30x30" placeholder:nil];
    }
    else {
        cell.iconImageView.image = nil;
    }
    cell.nameLabel.text = coinInfo.name ?: coinInfo.code;
    cell.priceLabel.text = [_currencyFormatter stringFromNumber:coinInfo.price];
    cell.priceDelta = (coinInfo.price == nil || coinInfo.minDelta == nil) ? NSOrderedSame : [@0 compare:coinInfo.minDelta];
    cell.h24Label.text = [_percentFormatter stringFromNumber:coinInfo.dayDelta];
    cell.h24Delta = [@0 compare:coinInfo.dayDelta ?: @0];
    cell.favoriteButton.selected = coinInfo.favorite;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(__unused UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:TGLoadingCell.class]) {
        [((TGLoadingCell *)cell).activityIndicatorView startAnimating];
    }
}

- (void)tableView:(__unused UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:TGLoadingCell.class]) {
        [((TGLoadingCell *)cell).activityIndicatorView stopAnimating];
    }
    if (!_pagingEnabled && indexPath.section == tableView.numberOfSections - 1) {
        [self pageInfoUpdated];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < (NSInteger)_topSectionCells.count) {
        UITableViewCell *cell = _topSectionCells[indexPath.section];
        if ([cell isKindOfClass:[TGFilterCell class]]) {
            return 26 + kFilterViewHeight;
        }
        if ([cell isKindOfClass:[TGSortCell class]]) {
            return kSortViewHeight;
        }
        if ([cell isKindOfClass:[TGMarketInfoCell class]]) {
            return kMarketViewHeight + kMarketViewOffset;
        }
    }
    return tableView.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != tableView.numberOfSections - 1) return;
    
    TGCryptoCurrency *coinInfo = self.coinInfos[indexPath.row];
    if (coinInfo.code == nil && indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        return;
    }
    [(TGApplication *)[UIApplication sharedApplication] openURL:[NSURL URLWithString:coinInfo.url]
                                                    forceNative:true
                                                      keepStack:true];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (![scrollView isKindOfClass:[UITableView class]]) return;
    UITableView *tableView = (id)scrollView;
    _lastContentOffset = tableView.contentOffset;
    _lastSelectedPageIndex = [self tableView:tableView pageAtOffset:_lastContentOffset.y];
    if (_filterCell.isFiltered) {
        [_filterCell.searchBar resignFirstResponder];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)__unused velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (!_pagingEnabled || ![scrollView isKindOfClass:[UITableView class]]) return;
    UITableView *tableView = (id)scrollView;
    
    CGFloat scrollDelta = (*targetContentOffset).y - _lastContentOffset.y;
    
    NSInteger selectedPage = _lastSelectedPageIndex;
    NSUInteger basePageRowsCount = (NSUInteger)floor(tableView.bounds.size.height / tableView.rowHeight);
    if (ABS(scrollDelta) > _topSectionCellsHeight / 5) {
        if (scrollDelta > 0) {
            selectedPage = MIN(selectedPage + 1, (NSInteger)ceil((double)self.coinInfos.count / basePageRowsCount));
        }
        else {
            selectedPage = MAX(selectedPage - 1, 0);
        }
    }
    if (selectedPage > 0) {
        *targetContentOffset = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:basePageRowsCount * (selectedPage - 1)
                                                                                   inSection:tableView.numberOfSections - 1]].origin;
    }
    else {
        CGPoint origin = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                             inSection:0]].origin;
        if (!tableView.refreshControl.refreshing || origin.y < (*targetContentOffset).y) {
            *targetContentOffset = origin;
        }
    }
}

- (void)scrollViewDidEndDragging:(__unused UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(__unused UIScrollView *)scrollView
{
    [self pageInfoUpdated];
    _lastSelectedPageIndex = -1;
    if (_pendingUpdate) {
        self.pricesInfo = _pendingUpdate;
    }
}

#pragma mark - TGCoinCellDelegate

- (void)coinCell:(TGCoinCell *)cell didTapFavoriteButton:(UIButton *)favoriteButton
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if (indexPath == nil) return;
    [TGCryptoManager.manager updateCoin:self.coinInfos[indexPath.row]
                               favorite:!favoriteButton.selected];
}

#pragma mark - TGFilterCellDelegate

- (void)filterCellDidUpdateFilterState:(TGFilterCell *)__unused filterCell
{
    _resetScrollPosition = YES;
    [self pageInfoUpdated];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self updateTopSectionCellsIncludeInBatch:^{
        [self updateTableViewContentSizeReloadDataCells:YES];
        [self pageInfoUpdated];
    }];
    [searchBar setShowsCancelButton:YES animated:YES];
    if (!TGIsPad()) {
        if ([self.tabBarController isKindOfClass:[TGCryptoTabViewController class]]) {
            [(TGCryptoTabViewController *)self.tabBarController setTabBarHidden:YES animated:YES];
        }
        if (iosMajorVersion() >= 11) {
            [self setNavigationBarHidden:YES withAnimation:TGViewControllerNavigationBarAnimationSlideFar duration:0.3];
        }
        else {
            [self setNavigationBarHidden:YES animated:YES];
        }
    }
    _filterActivated = YES;
    [self controllerInsetUpdated:UIEdgeInsetsZero];
}

- (void)searchBar:(UISearchBar *)__unused searchBar textDidChange:(NSString *)__unused searchText
{
    [self pageInfoUpdated];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)__unused searchBar
{
    _filterActivated = NO;
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self updateTopSectionCellsIncludeInBatch:^{
        [self updateTableViewContentSizeReloadDataCells:YES];
    }];
    if (!TGIsPad()) {
        if ([self.tabBarController isKindOfClass:[TGCryptoTabViewController class]]) {
            [(TGCryptoTabViewController *)self.tabBarController setTabBarHidden:NO animated:YES];
        }
        [self setNavigationBarHidden:NO animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }
    [self pageInfoUpdated];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - Helpers

- (NSUInteger)tableView:(UITableView *)tableView pageAtOffset:(CGFloat)offset
{
    NSUInteger basePageRowsCount = [self baseRowsCountForTableView:tableView];
    
    NSInteger selectedPage = 0;
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:CGPointMake(0, offset + 0.1)];
    if (indexPath.section == _tableView.numberOfSections - 1) {
        selectedPage = 1 + indexPath.row / basePageRowsCount;
    }
    return selectedPage;
}

- (NSUInteger)baseRowsCountForTableView:(UITableView *)tableView
{
    return (NSUInteger)floor(tableView.bounds.size.height / tableView.rowHeight);
}

- (void)setPricesInfo:(TGCryptoPricesInfo *)pricesInfo
{
    _pricesInfo = pricesInfo;
    _currencyFormatter.currencySymbol = pricesInfo.currency.symbol ?: @"";
    [self updateTableViewContentSizeReloadDataCells:YES];
    if (_resetScrollPosition) {
        [_tableView scrollsToTop];
        _resetScrollPosition = YES;
    }
}

- (void)updateTableViewContentSizeReloadDataCells:(BOOL)reloadDataCells
{
    if (reloadDataCells) {
        [UIView performWithoutAnimation:^{
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:_tableView.numberOfSections - 1] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
    if (_pagingEnabled) {
        CGSize contentSize = CGSizeZero;
        NSUInteger basePageRowsCount = [self baseRowsCountForTableView:_tableView];
        CGFloat partCellSize = _tableView.bounds.size.height - basePageRowsCount * _tableView.rowHeight;
        CGFloat basePageHeight = _tableView.rowHeight * basePageRowsCount;
        contentSize.height = _topSectionCellsHeight + ceil((double)self.coinInfos.count / basePageRowsCount) * basePageHeight + partCellSize;
        contentSize.width = _tableView.bounds.size.width;
        _tableView.fixedContentSize = &contentSize;
    }
    else {
        _tableView.fixedContentSize = NULL;
    }
}

- (void)updateTopSectionCells
{
    [self updateTopSectionCellsIncludeInBatch:NULL];
}

- (void)updateTopSectionCellsIncludeInBatch:(void (NS_NOESCAPE ^ _Nullable)(void))batch
{
    NSMutableArray<UITableViewCell *> *oldTopSectionCells = _topSectionCells.mutableCopy;
    if (_filterCell.isFiltered) {
        _topSectionCells = @[_filterCell];
    }
    else {
        NSMutableArray *cells = @[_filterCell, _sortCell].mutableCopy;
        if (UIInterfaceOrientationIsPortrait(self.currentInterfaceOrientation)) {
            [cells insertObject:_marketInfoCell atIndex:0];
        }
        _topSectionCells = cells.copy;
    }
    if ([oldTopSectionCells isEqualToArray:_topSectionCells]) return;
    NSMutableIndexSet *deletedSections = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *insertedSections = [NSMutableIndexSet indexSet];
    [oldTopSectionCells enumerateObjectsUsingBlock:^(UITableViewCell * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if (![_topSectionCells containsObject:obj]) {
            if (obj.superview == _tableView)
                [obj removeFromSuperview];
            [deletedSections addIndex:idx];
        }
    }];
    [_topSectionCells enumerateObjectsUsingBlock:^(UITableViewCell * _Nonnull obj, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if (![oldTopSectionCells containsObject:obj]) {
            [insertedSections addIndex:idx];
        }
    }];
    [_tableView performBatchUpdates:^{
        if (insertedSections.count > 0) [_tableView insertSections:insertedSections withRowAnimation:UITableViewRowAnimationAutomatic];
        if (deletedSections.count > 0) [_tableView deleteSections:deletedSections withRowAnimation:UITableViewRowAnimationAutomatic];
        if (batch != NULL)
            batch();
    } completion:NULL];
    _topSectionCellsHeight = 0;
    for (NSUInteger i = 0; i < _topSectionCells.count; i++) {
        _topSectionCellsHeight += [self tableView:_tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
    }
}

- (void)updateRightButtonItemImage
{
    [TGCryptoManager.manager loadCurrenciesIfNeeded:^(__unused BOOL success) {
        TGCryptoCurrency *selectedCurrency = TGCryptoManager.manager.selectedCurrency;
        if (selectedCurrency) {
            NSString *currencySymbol = selectedCurrency.symbol ?: selectedCurrency.code;
            _rightButtonItem.image = [_presentation.images chooseCurrencyButtonImageForCurrencySymbol:currencySymbol];
        }
    }];
}

- (NSArray<TGCryptoCurrency *> *)coinInfos
{
    NSNumber *key;
    if (_filterCell.isFiltered) {
        key = @(TGSortingSearch);
    }
    else if (_filterCell.favoritesFilterButton.isSelected) {
        key = TGSortingFavoritedKey;
    }
    else {
        key = @(_sortCell.sorting);
    }
    return _pricesInfo.coinInfos[key];
}

- (void)pageInfoUpdated
{
    static BOOL requested = NO;
    if (requested) return;
    
    TGCoinSorting sorting = _sortCell.sorting ;
    if (_filterCell.isFiltered) {
        sorting = TGSortingSearch;
    }
    TGCryptoPricePageInfo *pageInfo = [TGCryptoPricePageInfo pageInfoWithLimit:[self baseRowsCountForTableView:_tableView]
                                                                        offset:0
                                                                       sorting:sorting
                                                                  searchString:_filterCell.searchBar.text];
    pageInfo.isFavorited = _filterCell.favoritesFilterButton.isSelected;
    
    if (pageInfo.sorting != TGSortingSearch && !pageInfo.isFavorited) {
        if (_pagingEnabled) {
            pageInfo.offset = MAX(0, (NSInteger)[self tableView:_tableView pageAtOffset:_tableView.contentOffset.y] - 1) * pageInfo.limit;
            pageInfo.limit *= kPagesLimitMultiplier;
        }
        else {
            pageInfo.limit *= kCellsLimitMultiplier;
            __block NSInteger topCellIndex = 0;
            __block NSInteger bottomCellIndex = [self tableView:_tableView numberOfRowsInSection:_topSectionCells.count];
            [_tableView.indexPathsForVisibleRows enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                if (obj.section != _tableView.numberOfSections - 1) return;
                topCellIndex = MAX(topCellIndex, obj.row);
                bottomCellIndex = MIN(bottomCellIndex, obj.row);
            }];
            pageInfo.offset = MAX(0, (topCellIndex + bottomCellIndex - (NSInteger)pageInfo.limit) / 2);
        }
    }
    TGCryptoManager.manager.pricePageInfo = pageInfo;
}

- (void)apiOutOfDate
{
    if (_apiOutOfDateLabel != nil) return;
    
    _apiOutOfDateLabel = [UILabel.alloc initWithFrame:self.view.bounds];
    _apiOutOfDateLabel.textColor = _presentation.pallete.textColor;
    _apiOutOfDateLabel.textAlignment = NSTextAlignmentCenter;
    _apiOutOfDateLabel.numberOfLines = 0;
    _apiOutOfDateLabel.userInteractionEnabled = YES;
    _apiOutOfDateLabel.text = TGLocalized(@"Crypto.Prices.API.Out.Of.Date");
    [self.view addSubview:_apiOutOfDateLabel];
    [_tableView reloadData];
}

- (void)stateUpdated:(NSInteger)flag
{
    clrbit(&_forceUpdateFlags, flag);
    if (_tableView.refreshControl.refreshing && _forceUpdateFlags == 0) {
        [_tableView.refreshControl endRefreshing];
    }
}

@end
