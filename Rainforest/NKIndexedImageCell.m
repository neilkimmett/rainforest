//
//  NKVideoThumbnailCell.m
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NKIndexedImageCell.h"
#import "NSString+FontAwesome.h"
#import "UIFont+FontAwesome.h"

#define kThumbnailExpansionAmount 40

@interface NKIndexedImageCell ()
@property (nonatomic, strong) UIView *selectionView;
@property (nonatomic, strong) UILabel *checkmarkLabel;
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
        
        UILabel *checkmarkLabel = [[UILabel alloc] init];
        checkmarkLabel.font = [UIFont iconicFontOfSize:20];
        checkmarkLabel.text = [NSString fontAwesomeIconStringForEnum:FAIconCheck];
        checkmarkLabel.textColor = [UIColor darkGrayColor];
        checkmarkLabel.textAlignment = NSTextAlignmentCenter;
        [_selectionView addSubview:checkmarkLabel];
        _checkmarkLabel = checkmarkLabel;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = [UIColor whiteColor];
    
    CGRect frame = self.bounds;
    _imageView.frame = frame;
    _selectionView.frame = frame;
    CGFloat checkmarkSize = 30;
    _checkmarkLabel.frame = CGRectMake(CGRectGetMaxX(frame) - checkmarkSize,
                                       CGRectGetMaxY(frame) - checkmarkSize,
                                       checkmarkSize, checkmarkSize);

    self.selectionView.hidden = !self.selected;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
}

@end
