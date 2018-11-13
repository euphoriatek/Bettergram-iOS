#import <UIKit/UIKit.h>

@interface TGListsTableView : UITableView

@property (nonatomic, strong, nullable) UIRefreshControl *refreshControl;
- (void)performBatchUpdates:(void (NS_NOESCAPE ^ _Nullable)(void))updates completion:(void (^ _Nullable)(BOOL finished))completion;

@property (nonatomic, assign) bool blockContentOffset;
@property (nonatomic, assign) CGFloat indexOffset;
@property (nonatomic, assign) bool mayHaveIndex;

@property (nonatomic, copy) void (^onHitTest)(CGPoint);

@property (nonatomic, assign) CGSize* fixedContentSize;

- (void)adjustBehaviour;
- (void)scrollToTop;

@end
