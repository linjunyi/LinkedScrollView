# LinkedScrollView
A lightweight iOS component for **two-level scroll view linkage** with support for **horizontal paging**.  
实现 **ScrollView 二级联动** 与 **横向切屏** 的解决方案。

## ✨ Features
- 支持主 ScrollView 与子 ScrollView 的上下联动  
- 支持横向切换多个页面  
- 可配置悬浮 Header（float view）  
- Block 回调，轻松监听滚动与分页事件  

## 📸 Snapshots
### Style 1 ```LinkedScrollStyleDragSubSrollToRefresh```
<video src="https://github.com/user-attachments/assets/5d040965-b88d-466d-be3a-0724c4979b2b" controls="controls" width="360">
</video>

### Style 2 ```LinkedScrollStyleDragHeaderToRefresh```
<video src="https://github.com/user-attachments/assets/e204e8ef-598a-4c53-9f86-ea3129abfc70" controls="controls" width="360">
</video> 


## 🚀 Usage

### Quick Start
```objc
- (void)setupScrollView {
    LinkedScrollView *linkedScrollView =
        [[LinkedScrollView alloc] initWithStyle:LinkedScrollStyleDragHeaderToRefresh];
    linkedScrollView.frame = self.view.bounds;
    linkedScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:linkedScrollView];
    
    // Header
    UIView *header = [self createHeaderView];
    CGFloat width = CGRectGetWidth(self.view.bounds);
    header.frame = CGRectMake(0, 0, width, 576.0 / 1024 * width);
    [linkedScrollView addSubview:header];
    
    // Content Views
    UIScrollView *scrollView1 = [self createScrollView:@"页面一"];
    UIScrollView *scrollView2 = [self createScrollView:@"页面二"];
    UIScrollView *scrollView3 = [self createScrollView:@"页面三"];

    [linkedScrollView setLinkedHeader:header floatViewHeight:@(FloatMenuViewHeight)];
    [linkedScrollView setLinkedContentViews:@[scrollView1, scrollView2, scrollView3]];
    
    // Add Linked Scrolls
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
```



