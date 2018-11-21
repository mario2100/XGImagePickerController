//
//  MediaCell.m
//  MyApp
//
//  Created by huxinguang on 2018/10/30.
//  Copyright © 2018年 huxinguang. All rights reserved.
//

#import "MediaCell.h"
#import "PickerMacro.h"
#import "UIView+XGAdd.h"
#import "AssetPickerManager.h"
#import "AssetModel.h"


@interface MediaCell()<UIScrollViewDelegate,PlayerManagerDelegate>

@end

@implementation MediaCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubViews];
        self.playerManager.delegate = self;
    }
    return self;
}

- (void)setupSubViews{
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.mediaContainerView];
    [self.mediaContainerView addSubview:self.imageView];
    [self.mediaContainerView addSubview:self.playBtn];
    [self.contentView addSubview:self.bottomBar];
}

#pragma mark - Getter

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = self.contentView.bounds;
        _scrollView.bouncesZoom = YES;
        _scrollView.maximumZoomScale = 3;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.showsVerticalScrollIndicator = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

-(UIView *)mediaContainerView{
    if (!_mediaContainerView) {
        _mediaContainerView = [UIView new];
        _mediaContainerView.clipsToBounds = YES;
    }
    return _mediaContainerView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [FLAnimatedImageView new];
        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

- (UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"player_play"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

-(BottomBar *)bottomBar{
    if (!_bottomBar) {
        _bottomBar = [[BottomBar alloc]initWithFrame:CGRectMake(0, kAppScreenHeight-30, kAppScreenWidth, 30)];
    }
    return _bottomBar;
}

-(PlayerManager *)playerManager{
    return [PlayerManager shareInstance];
}

#pragma mark - Setter

- (void)setItem:(AssetModel *)item{
    _item = item;
    if (item.asset.mediaType == PHAssetMediaTypeVideo) {
        self.playBtn.hidden = NO;
    }else{
        self.playBtn.hidden = YES;
    }
    self.bottomBar.hidden = YES;
    [self.scrollView setZoomScale:1.0 animated:NO];
    self.scrollView.maximumZoomScale = 1.0;
    __weak typeof (self) weakSelf = self;
    [[AssetPickerManager manager]getPhotoWithAsset:item.asset completion:^(UIImage *photo, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.scrollView.maximumZoomScale = 3;
            if (photo) {
                weakSelf.imageView.image = photo;
                [weakSelf resizeSubviewSize];
            }
        });
    }];
   
    [self resizeSubviewSize];
    
}

- (void)resizeSubviewSize {
    _mediaContainerView.origin = CGPointZero;
    _mediaContainerView.width = self.width;
    
    UIImage *image = _imageView.image;
    if (image.size.height / image.size.width > self.height / self.width) {
        _mediaContainerView.height = floor(image.size.height / (image.size.width / self.width));
    } else {
        CGFloat height = image.size.height / image.size.width * self.width;
        if (height < 1 || isnan(height)) height = self.height;
        height = floor(height);
        _mediaContainerView.height = height;
        _mediaContainerView.centerY = self.height / 2;
    }
    if (_mediaContainerView.height > self.height && _mediaContainerView.height - self.height <= 1) {
        _mediaContainerView.height = self.height;
    }
    self.scrollView.contentSize = CGSizeMake(self.width, MAX(_mediaContainerView.height, self.height));
    [self.scrollView scrollRectToVisible:self.scrollView.bounds animated:NO];
    
    if (_mediaContainerView.height <= self.height) {
        self.scrollView.alwaysBounceVertical = NO;
    } else {
        self.scrollView.alwaysBounceVertical = YES;
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.imageView.frame = _mediaContainerView.bounds;
    self.playBtn.size = CGSizeMake(42, 42);
    self.playBtn.center = self.imageView.center;
    [CATransaction commit];
}

-(void)layoutSubviews{
    [super layoutSubviews];
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.mediaContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    self.mediaContainerView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - player

- (void)playAction{
    __weak typeof (self) weakSelf = self;
    [[AssetPickerManager manager]getVideoWithAsset:self.item.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (playerItem) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.playerManager playWithItem:playerItem onLayer:weakSelf.imageView.layer];
                weakSelf.playBtn.hidden = YES;
                weakSelf.bottomBar.hidden = NO;
            });
        }
    }];
}

- (void)showOrHidePlayerControls{
    if (self.item.asset.mediaType == PHAssetMediaTypeImage) {
        return;
    }
}

- (void)pauseAndResetPlayer{
    if (self.item.asset.mediaType == PHAssetMediaTypeImage) {
        return;
    }
    self.playBtn.hidden = NO;
    self.bottomBar.hidden = YES;
    [self.playerManager pauseAndResetPlayer];
    [self.imageView.layer.sublayers.firstObject removeFromSuperlayer];
    
}

- (void)pausePlayer{
    self.playBtn.hidden = NO;
    self.bottomBar.hidden = YES;
    [self.playerManager pause];
}


#pragma mark - PlayerManagerDelegate

- (void)playerDidFinishPlay:(PlayerManager *)manager{
    self.playBtn.hidden = NO;
    self.bottomBar.hidden = YES;
}

@end

@implementation BottomBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
        [self addSubview:self.leftTimeLabel];
        [self addSubview:self.slider];
        [self addSubview:self.rightTimeLabel];
        [self addConstraints];
    }
    return self;
}

- (void)addConstraints{
    self.leftTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.slider.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [NSLayoutConstraint constraintWithItem:self.leftTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.leftTimeLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.leftTimeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:60],
                                              [NSLayoutConstraint constraintWithItem:self.leftTimeLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.leftTimeLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:20],
                                              [NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.slider attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.rightTimeLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.rightTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.rightTimeLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.rightTimeLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0],
                                              [NSLayoutConstraint constraintWithItem:self.rightTimeLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.leftTimeLabel attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]
                                              ]];
    
}

-(UILabel *)leftTimeLabel{
    if (!_leftTimeLabel) {
        _leftTimeLabel = [UILabel new];
        _leftTimeLabel.font = [UIFont systemFontOfSize:12];
        _leftTimeLabel.textColor = [UIColor whiteColor];
        _leftTimeLabel.textAlignment = NSTextAlignmentCenter;
        _leftTimeLabel.text = @"00:12";
    }
    return _leftTimeLabel;
}

-(UISlider *)slider{
    if (!_slider) {
        _slider = [UISlider new];
        _slider.value = 0.0;
        _slider.minimumValue = 0.0;
        _slider.maximumValue = 1.0;
        _slider.minimumTrackTintColor = self.tintColor?self.tintColor:[UIColor blueColor];
        _slider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _slider.backgroundColor = [UIColor clearColor];
        [_slider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
        [_slider addTarget:self action:@selector(sliderDidSlide:)  forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(onClickSlider:) forControlEvents:UIControlEventTouchUpInside];
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapSlider:)];
//        sliderTap.delegate = self;
        [_slider addGestureRecognizer:sliderTap];
    }
    return _slider;
}

-(UILabel *)rightTimeLabel{
    if (!_rightTimeLabel) {
        _rightTimeLabel = [UILabel new];
        _rightTimeLabel.font = [UIFont systemFontOfSize:12];
        _rightTimeLabel.textColor = [UIColor whiteColor];
        _rightTimeLabel.textAlignment = NSTextAlignmentCenter;
        _rightTimeLabel.text = @"00:54";
    }
    return _rightTimeLabel;
}

- (void)sliderDidSlide:(UISlider *)slider{
    
}

- (void)onClickSlider:(UISlider *)slider{
    
}

- (void)onTapSlider:(UISlider *)slider{
    
}



@end

