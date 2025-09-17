//
//  ViewController.m
//  LinkedScrollViewDemo
//
//  Created by 林君毅 on 2025/9/16.
//

#import "ViewController.h"
#import "LinkedScrollView.h"

#define FloatMenuViewHeight 100

@interface ViewController ()

@property (nonatomic, strong) LinkedScrollView *scrollView;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupScrollView];
    [self setupMenuView:@[@"标题一", @"标题二", @"标题三"]];
}

- (void)setupScrollView {
    LinkedScrollView *linkedScrollView = [[LinkedScrollView alloc] initWithStyle:LinkedScrollStyleDragHeaderToRefresh];
    _scrollView = linkedScrollView;
    linkedScrollView.frame = self.view.bounds;
    linkedScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:linkedScrollView];
    
    UIView *header = [self createHeaderView];
    CGFloat width = CGRectGetWidth(self.view.bounds);
    header.frame = CGRectMake(0, 0, width, 576.0 / 1024 * width);
    [linkedScrollView addSubview:header];
    
    UIScrollView *scrollView1 = [self createScrollView:@"页面一"];
    UIScrollView *scrollView2 = [self createScrollView:@"页面二"];
    UIScrollView *scrollView3 = [self createScrollView:@"页面三"];

    [linkedScrollView setLinkedHeader:header floatViewHeight:@(FloatMenuViewHeight)];
    [linkedScrollView setLinkedContentViews:@[scrollView1, scrollView2, scrollView3]];
    [linkedScrollView addLinkedScroll:scrollView1];
    [linkedScrollView addLinkedScroll:scrollView2];
    [linkedScrollView addLinkedScroll:scrollView3];
    __weak typeof(self) weakSelf = self;
    linkedScrollView.scrollBlock = ^(UIScrollView * _Nonnull sv, BOOL linkage, BOOL showFloat) {
        weakSelf.menuView.hidden = !showFloat;
    };
    linkedScrollView.contentDidChangePage = ^(NSInteger pageIndex) {
        weakSelf.selectedIndex = pageIndex;
    };
}

- (UIView *)createHeaderView {
    UIImageView *headerView = [UIImageView new];
    headerView.image = [UIImage imageNamed:@"HeadBg"];
    return headerView;
}

- (UIScrollView *)createScrollView:(NSString *)prefix {
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.showsVerticalScrollIndicator = NO;
    
    CGFloat y = 0;
    for (NSInteger i = 0; i < 20; i++) {
        y = [self addCellTo:scrollView text:[NSString stringWithFormat:@"%@ cell %zd", prefix, i+1] y:y];
    }
    y += 20;
    scrollView.contentSize = CGSizeMake(0, y);
    
    return scrollView;
}

- (CGFloat)addCellTo:(UIView *)superview text:(NSString *)text y:(CGFloat)y {
    UIView *cell = [UIView new];
    cell.frame = CGRectMake(0, y, CGRectGetWidth(self.view.bounds), 100);
    [superview addSubview:cell];
    
    UILabel *label = [UILabel new];
    label.frame = CGRectMake(20, 15, 200, 25);
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [UIColor blackColor];
    label.text = text;
    [cell addSubview:label];
    
    UIView *speLine = [UIView new];
    speLine.frame = CGRectMake(20, cell.bounds.size.height-.5, cell.bounds.size.width-40, .5);
    speLine.backgroundColor = [UIColor grayColor];
    [cell addSubview:speLine];
    
    return CGRectGetMaxY(cell.frame);
}

- (void)setupMenuView:(NSArray<NSString *> *)titles {
    UIView *menuView = [UIView new];
    _menuView = menuView;
    menuView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:menuView];
    menuView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [menuView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [menuView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor],
        [menuView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [menuView.heightAnchor constraintEqualToConstant:FloatMenuViewHeight]
    ]];
    
    CGFloat x = 20;
    for (NSString *t in titles) {
        UIButton *btn = [UIButton new];
        btn.tag = 500 + [titles indexOfObject:t];
        btn.frame = CGRectMake(x, 60, 60, 34);
        btn.backgroundColor = [UIColor whiteColor];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        [btn setTitle:t forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:btn];
        x += CGRectGetWidth(btn.frame) + 20;
    }
    [self updateMenuView];
}

- (void)updateMenuView {
    for (UIView *view in self.menuView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            if (btn.tag - 500 == self.selectedIndex) {
                btn.backgroundColor = [UIColor blueColor];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            } else {
                btn.backgroundColor = [UIColor whiteColor];
                [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            }
        }
    }
}

#pragma mark -

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [self updateMenuView];
}

- (void)btnClicked:(UIButton *)btn {
    self.selectedIndex = btn.tag - 500;
    [_scrollView setContentPage:self.selectedIndex animated:YES];
}

@end
