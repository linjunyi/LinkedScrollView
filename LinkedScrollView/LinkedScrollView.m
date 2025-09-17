//
//  LinkedScrollView.m
//  Ape_xc
//
//  Created by 林君毅 on 2022/5/16.
//  Copyright © 2022 Fenbi. All rights reserved.
//

#import "LinkedScrollView.h"
#import <objc/runtime.h>

#define kDefaultFloatHeight 44

static void *kLinkedScrollContentOffsetContext = &kLinkedScrollContentOffsetContext;

@interface UIScrollView (Linked)

@property (nonatomic, assign) BOOL forbidFixScroll;

@end

@implementation UIScrollView (Linked)

- (BOOL)forbidFixScroll {
    NSNumber *num = objc_getAssociatedObject(self, @selector(forbidFixScroll));
    return [num boolValue];
}

- (void)setForbidFixScroll:(BOOL)forbidFixScroll {
    objc_setAssociatedObject(self, @selector(forbidFixScroll),
                             @(forbidFixScroll), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface LinkedScrollView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *linkedHeader;
@property (nonatomic, strong) UIScrollView *linkedFooter;
@property (nonatomic, strong) NSArray<UIView *> *linkedContentViews;
@property (nonatomic, strong) NSHashTable<UIScrollView *> *linkedScrolls;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSNumber *floatViewHeight;
@property (nonatomic, assign) CGFloat headerBottom;

@end

@implementation LinkedScrollView

#pragma mark - Life Cycle && Override

- (instancetype)initWithStyle:(LinkedScrollStyle)scrollStyle {
    if (self = [super init]) {
        _scrollStyle = scrollStyle;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.showsVerticalScrollIndicator = NO;
        self.panGestureRecognizer.cancelsTouchesInView = NO;
        [self _addLinkedObserverFor:self];
        _linkedScrolls = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)dealloc {
    [self _removeAllLinkedObservers];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.bounds.size.height > 0 && self.bounds.size.width > 0 && self.linkedHeader.bounds.size.height > 0) {
        CGFloat headerBottom = CGRectGetMaxY(self.linkedHeader.frame);
        if (_headerBottom != headerBottom) {
            _headerBottom = headerBottom;
            self.contentSize = CGSizeMake(self.contentSize.width,
                                          headerBottom - _floatViewHeight.floatValue + self.bounds.size.height);
        }
        
        self.linkedFooter.delegate = nil;
        {
            CGFloat footerHeight = MAX(0, self.contentOffset.y + self.bounds.size.height - headerBottom);
            if (footerHeight != self.linkedFooter.bounds.size.height) {
                self.linkedFooter.frame = CGRectMake(0, headerBottom, self.bounds.size.width, footerHeight);
            }
            if (self.linkedFooter.contentOffset.x != CGRectGetWidth(self.bounds) * _currentPage) {
                [self _setContentPage:_currentPage animated:NO];
            }
        }
        self.linkedFooter.delegate = self;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        // self 不在初始状态时，优先触发自身滑动，直至回复初始状态
        if (self.contentOffset.y < 0) {
            return YES;
        }
        
        CGPoint point = [self.panGestureRecognizer locationInView:self];
        if (CGRectContainsPoint(self.linkedFooter.frame, point)) {
            if (_scrollStyle == LinkedScrollStyleDragHeaderToRefresh) {
                UIScrollView *activeView = [self activeLinkedScroll];
                if ([self.panGestureRecognizer translationInView:self].y > 0 && activeView.contentOffset.y <= 0) {
                    return YES;
                }
            }
            return NO;
        }
        if (_disableHeaderUserDrag) {
            if (CGRectContainsPoint(self.linkedHeader.frame, point)) {
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - Observer

- (void)_addLinkedObserverFor:(UIScrollView *)scrollView {
    [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kLinkedScrollContentOffsetContext];
}

- (void)_removeAllLinkedObservers {
    @try {
        [self removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(contentOffset))
                     context:kLinkedScrollContentOffsetContext];
    } @catch (NSException *exception) {}
    
    [self _removeLinkedScrollsObservers];
}

- (void)_removeLinkedScrollsObservers {
    if (!_linkedScrolls) return;

    NSArray *scrolls = [_linkedScrolls allObjects];
    for (UIScrollView *scrollV in scrolls) {
        @try {
            [scrollV removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(contentOffset))
                            context:kLinkedScrollContentOffsetContext];
        } @catch (NSException *exception) {}
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))] &&
        context == kLinkedScrollContentOffsetContext) {
        
        if ([object isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)object;
            if (self.bounds.size.height == 0) {
                return;
            }
            
            NSValue *newValue = change[NSKeyValueChangeNewKey];
            NSValue *oldValue = change[NSKeyValueChangeOldKey];
            if ([newValue isEqualToValue:oldValue]) {
                return;
            }
            
            if (scrollView.forbidFixScroll) {
                return;
            }
            
            [self fixScroll:scrollView];
        }
    }
}

#pragma mark - Header && Footer && LinkedScrolls

- (void)setLinkedHeader:(UIView *)header floatViewHeight:(nullable NSNumber *)floatViewHeight {
    if (_linkedHeader != header) {
        _linkedHeader = header;
        _floatViewHeight = floatViewHeight ?: @(kDefaultFloatHeight);
        [self setNeedsLayout];
    }
}

- (UIScrollView *)linkedFooter {
    if (!_linkedFooter) {
        _linkedFooter = [UIScrollView new];
        _linkedFooter.delegate = self;
        _linkedFooter.backgroundColor = [UIColor clearColor];
        _linkedFooter.showsHorizontalScrollIndicator = NO;
        _linkedFooter.pagingEnabled = YES;
        [self addSubview:_linkedFooter];
    }
    return _linkedFooter;
}

- (void)setLinkedContentViews:(NSArray<UIView *> *)contentViews {
    if (_linkedContentViews) {
        [_linkedContentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self _removeLinkedScrollsObservers];
    }
    _linkedContentViews = contentViews;
    
    UIView *lastV = nil;
    for (UIView *view in contentViews) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.linkedFooter addSubview:view];

        [NSLayoutConstraint activateConstraints:@[
            [view.topAnchor constraintEqualToAnchor:self.linkedFooter.topAnchor],
            [view.heightAnchor constraintEqualToAnchor:self.linkedFooter.heightAnchor],
            [view.widthAnchor constraintEqualToAnchor:self.widthAnchor],
            lastV ?
                [view.leadingAnchor constraintEqualToAnchor:lastV.trailingAnchor] :
                [view.leadingAnchor constraintEqualToAnchor:self.linkedFooter.leadingAnchor]
        ]];
        lastV = view;
    }

    if (lastV) {
        [NSLayoutConstraint activateConstraints:@[
            [lastV.trailingAnchor constraintEqualToAnchor:self.linkedFooter.trailingAnchor]
        ]];
    }
    [self setNeedsLayout];
}

- (void)setContentPage:(NSInteger)page animated:(BOOL)animated {
    if (_currentPage == page) {
        return;
    }
    _currentPage = page;
    [self _setContentPage:page animated:animated];
}
    
- (void)_setContentPage:(NSInteger)page animated:(BOOL)animated {
    if (self.bounds.size.width > 0 && self.linkedFooter.bounds.size.width > 0) {
        self.linkedFooter.delegate = nil;
        if (animated) {
            [UIView animateWithDuration:.3 animations:^{
                [self.linkedFooter setContentOffset:CGPointMake(self.bounds.size.width * self.currentPage, 0) animated:NO];
            } completion:^(BOOL finished) {
                self.linkedFooter.delegate = self;
            }];
            
        } else {
            [self.linkedFooter setContentOffset:CGPointMake(self.bounds.size.width * self.currentPage, 0) animated:NO];
            self.linkedFooter.delegate = self;
        }
    }
}

- (void)addLinkedScroll:(UIScrollView *)scrollView {
    if (![scrollView isKindOfClass:[UIScrollView class]]) return;
    if ([_linkedScrolls containsObject:scrollView]) return;
    
    [scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.panGestureRecognizer];
    [_linkedScrolls addObject:scrollView];
    [self _addLinkedObserverFor:scrollView];
}

#pragma mark - ScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _linkedFooter) {
        _currentPage = (NSInteger)((_linkedFooter.contentOffset.x + _linkedFooter.bounds.size.width * .3) / _linkedFooter.bounds.size.width);
        if (_contentDidChangePage) {
            _contentDidChangePage(_currentPage);
        }
    }
}

#pragma mark - Core

- (CGFloat)maxContentOffsetY {
    return (int)(CGRectGetMaxY(self.linkedHeader.frame) - _floatViewHeight.floatValue);
}

- (CGFloat)minContentOffsetY {
    return (int)(self.linkedHeader.frame.origin.y);
}

- (BOOL)canScrollUp {
    return self.contentOffset.y < [self maxContentOffsetY] - FLT_EPSILON;
}

- (BOOL)canScrollDown {
    return self.contentOffset.y > [self minContentOffsetY] + FLT_EPSILON;
}

- (BOOL)shouldShowFloat {
    return self.contentOffset.y >= [self maxContentOffsetY];
}

- (BOOL)isActive:(UIScrollView *)linkedScroll {
    CGRect rect = [linkedScroll.superview convertRect:linkedScroll.frame toView:self.superview];
    return CGRectContainsPoint(self.frame, CGPointMake(rect.origin.x+rect.size.width/2, rect.origin.y+rect.size.height/2));
}

- (UIScrollView *)activeLinkedScroll {
    for (UIScrollView *scrollV in _linkedScrolls) {
        if ([self isActive:scrollV]) {
            return scrollV;
        }
    }
    return nil;
}

#pragma mark - Fix Scroll

- (void)noObserveUpdateOffset:(CGPoint)offset forScrollView:(UIScrollView *)scrollView {
    if ((int)(scrollView.contentOffset.y * 100) != (int)(offset.y * 100)) {
        scrollView.forbidFixScroll = YES;
        [scrollView setContentOffset:offset animated:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            scrollView.forbidFixScroll = NO;
        });
    }
    
}

- (void)fixScroll:(UIScrollView *)scrollView {
    if (!scrollView || self.bounds.size.height <= 0 || _linkedHeader.bounds.size.height <= 0) return;
    
    if (scrollView == self) {
        [self fixScrollForSelf];
    } else if ([self isActive:scrollView]) {
        [self fixScrollForLinkedScroll:scrollView];
    }
}

- (void)fixScrollForSelf {
    if (self.contentOffset.y > [self maxContentOffsetY]) {
        [self noObserveUpdateOffset:CGPointMake(0, [self maxContentOffsetY]) forScrollView:self];
    }
    if (self.scrollBlock) {
        __weak typeof(self) weakSelf = self;
        self.scrollBlock(weakSelf, NO, [self shouldShowFloat]);
    }
}

/// 特定情况下，linkedScroll滑动时不动，而是触发self的滑动
- (void)fixScrollForLinkedScroll:(UIScrollView *)linkedScroll {
    CGFloat offsetY = self.contentOffset.y + linkedScroll.contentOffset.y;
    BOOL needFix = NO;
    if (linkedScroll.contentOffset.y > 0 && [self canScrollUp]) {
        offsetY = offsetY > [self maxContentOffsetY] ? [self maxContentOffsetY] : offsetY;
        needFix = YES;
    }
    else if (linkedScroll.contentOffset.y < 0 && [self canScrollDown]) {
        offsetY = offsetY < [self minContentOffsetY] ? [self minContentOffsetY] : offsetY;
        needFix = YES;
    }
    if (needFix) {
        for (UIScrollView *scrollV in _linkedScrolls) {
            if (scrollV != linkedScroll) {
                [self noObserveUpdateOffset:CGPointMake(scrollV.contentOffset.x, 0) forScrollView:scrollV];
            }
        }
        [self noObserveUpdateOffset:CGPointMake(self.contentOffset.x, offsetY) forScrollView:self];
        if (self.scrollBlock) {
            __weak typeof(self) weakSelf = self;
            self.scrollBlock(weakSelf, YES, [self shouldShowFloat]);
        }
    } else {
        if (self.scrollBlock) {
            self.scrollBlock(linkedScroll, NO, [self shouldShowFloat]);
        }
    }
}

@end
