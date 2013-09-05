//
//  NKVideoThumbnailCell.m
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NKIndexedImageCell.h"

#define kThumbnailExpansionAmount 40

@interface NKIndexedImageCell ()
@property (nonatomic, strong) UIView *selectionView;
@end

@implementation NKIndexedImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_imageView];
        
        _selectionView = [[UIView alloc] init];
        _selectionView.backgroundColor = [UIColor whiteColor];
        _selectionView.alpha = 0.5;
        [self addSubview:_selectionView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = [UIColor whiteColor];
    self.imageView.frame = self.bounds;
    self.selectionView.frame = self.bounds;
    self.selectionView.hidden = !self.selected;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
}

@end
