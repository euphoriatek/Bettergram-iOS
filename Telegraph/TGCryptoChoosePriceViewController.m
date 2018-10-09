//
//  TGCryptoChoosePriceViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/24/18.
//

#import "TGCryptoChoosePriceViewController.h"
#import "TGCryptoManager.h"
#import "TGPresentation.h"

@interface TGCryptoChoosePriceViewController () <UITableViewDataSource, UITableViewDelegate, TGSearchBarDelegate> {
    NSArray<TGCryptoCurrency *> *_currencies;
    NSArray<TGCryptoCurrency *> *_filteredCurrencies;
    NSInteger _selectedIndex;
    
    UITableView *_tableView;
    TGSearchBar *_searchBar;
    
    TGPresentation *_presentation;
    
    BOOL _frameInitialized;
}

@end

@implementation TGCryptoChoosePriceViewController

- (instancetype)initWithPresentation:(TGPresentation *)presentation
{
    if (self = [super init]) {
        _presentation = presentation;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = nil;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.tableFooterView = [[UIView alloc] init];
    
    _searchBar = [[TGSearchBar alloc] init];
    _searchBar.style = TGSearchBarStyleLight;
    _searchBar.delegate = self;
    [_searchBar setShowsCancelButton:false animated:false];
    [_searchBar setAlwaysExtended:true];
    _searchBar.placeholder = TGLocalized(@"Crypto.Prices.ChooseCurrency.SearchPlaceholder");
    _searchBar.delayActivity = false;
    [self.view addSubview:_searchBar];
    
    [self setPresentation:_presentation];
    
    [self.view addSubviews:@[_tableView, _searchBar]];
    
    [TGCryptoManager.manager loadCurrencies:^(BOOL success) {
        TGDispatchOnMainThread(^{
            if (success) {
                _currencies = TGCryptoManager.manager.currencies;
                _selectedIndex = [_currencies indexOfObject:TGCryptoManager.manager.selectedCurrency];
                [_tableView reloadData];
            }
        });
    }];
}

- (void)controllerInsetUpdated:(UIEdgeInsets)__unused previousInset
{
    _searchBar.frame = CGRectMake(0, self.controllerInset.top, self.view.frame.size.width, [TGSearchBar searchBarBaseHeight]);
    _searchBar.safeAreaInset = self.controllerSafeAreaInset;
    
    UIEdgeInsets safeAreaInset = [self calculatedSafeAreaInset];;
    _tableView.frame = CGRectMake(safeAreaInset.left, CGRectGetMaxY(_searchBar.frame),
                                  self.view.frame.size.width - safeAreaInset.left - safeAreaInset.right, self.view.frame.size.height - CGRectGetMaxY(_searchBar.frame) - safeAreaInset.bottom);
    if (!_frameInitialized) {
        _frameInitialized = YES;
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:NO];
    }
}

- (void)setPresentation:(TGPresentation *)presentation
{
    _presentation = presentation;
    
    self.view.backgroundColor = presentation.pallete.backgroundColor;
    [_searchBar setPallete:_presentation.searchBarPallete];
}

- (NSArray<TGCryptoCurrency *> *)displayingCurrencies
{
    if (_searchBar.text.length > 0) {
        return _filteredCurrencies;
    }
    return _currencies;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section
{
    return [self displayingCurrencies].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = UIColor.clearColor;
        cell.textLabel.font = TGSystemFontOfSize(16);
        cell.tintColor = _presentation.pallete.accentColor;
        cell.textLabel.textColor = _presentation.pallete.textColor;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TGCryptoCurrency *currency = [self displayingCurrencies][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)",currency.name, currency.symbol ?: currency.code];
    cell.accessoryType = indexPath.row == _selectedIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *oldSelectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    oldSelectedCell.accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedIndex = indexPath.row;
    TGCryptoManager.manager.selectedCurrency = [self displayingCurrencies][_selectedIndex];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isTracking && _searchBar.isFirstResponder) {
        [_searchBar resignFirstResponder];
    }
}

#pragma mark - TGSearchBarDelegate

- (void)searchBar:(UISearchBar *)__unused searchBar textDidChange:(NSString *)searchText
{
    _filteredCurrencies = [_currencies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TGCryptoCurrency *  _Nullable evaluatedObject, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject validateFilter:searchText];
    }]];
    [_tableView reloadData];
}

@end
