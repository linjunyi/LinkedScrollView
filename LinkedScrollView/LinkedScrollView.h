//
//  LinkedScrollView.h
//  Ape_xc
//
//  Created by 林君毅 on 2022/5/16.
//  Copyright © 2022 Fenbi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//=======================  Demo  =======================

// 创建和布局 LinkedScrollView
//    LinkedScrollView *scrollView = [[LinkedScrollView alloc] initWithStyle:LinkedScrollStyleDragHeaderToRefresh];
//    _scrollView = scrollView;
//    [self.view addSubview:scrollView];
//    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.mas_equalTo(UIEdgeInsetsZero);
//    }];
//    _scrollView.scrollBlock = ^(UIScrollView *sv, BOOL linkage, BOOL showFloat) {
//        // 滚动回调
//    };
//    _scrollView.contentDidChangePage = ^(NSInteger pageIndex) {
//        // 横向分页切换回调
//    };

// 创建和布局 HeaderView
//    UIView *headerView = [self createHeaerView];
//    [_scrollView addSubview:headerView];
//    [headerView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.leading.width.equalTo(headerView.superview);
//        make.top.mas_equalTo(30);
//        make.bottom.mas_equalTo(100);
//    }];

// demo 1 : 使用ScrollMenuViewController
//    ScrollMenuViewController *menuController = [[ScrollMenuViewController alloc] initWithMenuTitles:@[@"页面1", @"页面2"] subVCCreator:^UIViewController<ScrollMenuSubViewController> *(NSUInteger index) {
//        UIViewController<ScrollMenuSubViewController> *vc;
//        if (index == 0) {
//            vc = (UIViewController<ScrollMenuSubViewController> *)[DebugFuncHomeViewController new];
//        } else {
//            vc = (UIViewController<ScrollMenuSubViewController> *)[DebugFuncTestViewController new];
//        }
//        return vc;
//    } indexChangedHandler:^(ScrollMenuViewController *controller, NSUInteger from, NSUInteger to, BOOL click) {
//        DebugFuncBaseViewController *currentVC = (DebugFuncBaseViewController *)[controller currentController];
//        if (currentVC.tableView) {
//            [scrollView addLinkedScroll:currentVC.tableView];
//        }
//    } dataChangedHandler:^(ScrollMenuViewController *controller, NSUInteger index, id data) {
//
//    }];
//    [self addChildViewController:menuController];
//
//    [scrollView setLinkedHeader:headerView floatViewHeight:@0];
//    [scrollView setLinkedContentViews:@[menuController.view]];
//    DebugFuncBaseViewController *currentVC = (DebugFuncBaseViewController *)[menuController currentController];
//    if (currentVC.tableView) {
//        [scrollView addLinkedScroll:currentVC.tableView];
//    }

// demo 2 : 直接添加联动的scrollViews
//    UITableView *leftTableV  = [self createTableView];
//    UITableView *rightTableV = [self createTableView];
//    
//    __weak typeof(self) weakSelf = self;
//    [_scrollView setLinkedHeader:headerView floatViewHeight:@(self.navBar.height)];
//    [_scrollView setLinkedContentViews:@[leftTableV, rightTableV]];
//    [_scrollView addLinkedScroll:leftTableV];
//    [_scrollView addLinkedScroll:rightTableV];

// demo 3 : 使用childViewController
//    UIViewController *childVC1 = [self createChildViewController];
//    UIViewController *childVC2 = [self createChildViewController];
//    UIViewController *childVC3 = [self createChildViewController];
//    [self addChildViewController:childVC1];
//    [self addChildViewController:childVC2];
//    [self addChildViewController:childVC3];
//    
//    __weak typeof(self) weakSelf = self;
//    [_scrollView setLinkedHeader:headerView floatViewHeight:@(44)];
//    [_scrollView setLinkedContentViews:@[childVC1.view, childVC2.view, childVC3.view]];
//    [_scrollView addLinkedScroll:[childVC1 scrollView]];
//    [_scrollView addLinkedScroll:[childVC2 scrollView]];
//    [_scrollView addLinkedScroll:[childVC3 scrollView]];


//============================= Layout ==============================
//
//+-----------------------------------------------------------------+
//|                          LinkedHeader                           |
//|                (provided and laid out outside)                  |
//+-----------------------------------------------------------------+
//
//+-----------------------------------------------------------------+
//|                          LinkedFooter                           |
//|                (provided and laid out inside)                   |
//|  +-----------------------------------------------------------+  |
//|  |                       LinkedScrolls (N)                   |  |
//|  |  +-------------+   +-------------+   +-------------+      |  |
//|  |  |  scroll1 or |   |  scroll2 or |   |  scroll3 or |  ... |  |
//|  |  |its superView|   |its superView|   |its superView|  ... |  |
//|  |  +-------------+   +-------------+   +-------------+      |  |
//|  +-----------------------------------------------------------+  |
//+-----------------------------------------------------------------+
//
//==========================================================

typedef NS_ENUM(NSInteger, LinkedScrollStyle) {
    LinkedScrollStyleDragSubSrollToRefresh   = 0,       //contentOffset.y == 0时，下拉触发SubSroll滑动，Header部分不动
    LinkedScrollStyleDragHeaderToRefresh     = 1,       //contentOffset.y == 0时，下拉触发Header滑动,SubSroll不动
 
    // 后续有需要，写个 LinkedScrollView 子类对Header布局进行内部管理
//    LinkedScrollStyleDragHeaderToBigger      = 102,       //contentOffset.y == 0时，下拉触发Header区域放大
};

@interface LinkedScrollView : UIScrollView

@property (nonatomic, assign, readonly) LinkedScrollStyle scrollStyle;

/// 滚动回调
/// - sv: 当前发生滚动的 scrollView（可能是 self，也可能是某个 linkedScroll）
/// - linkage: 是否触发了联动修正
/// - showFloat: 是否滚动到了需要展示浮动视图的区域
@property (nonatomic, copy) void(^scrollBlock)(UIScrollView *sv, BOOL linkage, BOOL showFloat);

/// 横向分页切换回调
/// - pageIndex: 当前展示的页面索引
@property (nonatomic, copy) void(^contentDidChangePage)(NSInteger pageIndex);

/// Header是否能被用户拖动
/// YES: Header 部分不可拖动，只能由 linkedScrolls 驱动联动
/// NO : Header 部分可拖动
/// 默认为NO
@property (nonatomic, assign) BOOL disableHeaderUserDrag;







/// 初始化方法
/// - Parameter scrollStyle: 需要联动模式，详见 NS_ENUM LinkedScrollStyle
- (id)initWithStyle:(LinkedScrollStyle)scrollStyle;


/// 设置 header（外部负责添加和布局）
/// - Parameters:
///   - header: 头部视图
///   - floatViewHeight: 顶部悬浮区的高度，传 nil 默认 44
- (void)setLinkedHeader:(UIView *)header floatViewHeight:(nullable NSNumber *)floatViewHeight;

/// 配置联动内容区域
/// - contentViews: header 下方的内容视图，从左到右排列；
///   支持横向分页。可以直接传入子 scrollView，
///   或者其承载的 superView（例如子控制器的 view）。
///   ⚠️ 调用后需配合 -addLinkedScroll: 建立联动。
- (void)setLinkedContentViews:(NSArray<UIView *> *)contentViews;

/// 设置当前展示的页面
/// - page: 目标页索引
/// - animated: 是否需要动画
- (void)setContentPage:(NSInteger)page animated:(BOOL)animated;

/// 添加需要联动的子 scrollView
/// - Parameter scrollView: 需要联动的 UIScrollView
- (void)addLinkedScroll:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
