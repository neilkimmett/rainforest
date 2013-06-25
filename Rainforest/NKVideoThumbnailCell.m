//
//  NKVideoThumbnailCell.m
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NKVideoThumbnailCell.h"

#define kThumbnailExpansionAmount 40

@interface NKVideoThumbnailCell ()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIView *selectionView;
@property (nonatomic) BOOL hasExpanded;
@property (nonatomic) MPMoviePlayerController *playerController;
@end

@implementation NKVideoThumbnailCell

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
    
    self.imageView.frame = self.bounds;
    self.selectionView.frame = self.bounds;
    self.layer.zPosition = self.highlighted ? 100 : 1;
    self.selectionView.hidden = !self.selected;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    if (!highlighted && self.hasExpanded) {
        [self.playerController stop];
        [self.playerController.view removeFromSuperview];
        self.playerController = nil;
        
        self.frame = CGRectInset(self.frame, kThumbnailExpansionAmount, kThumbnailExpansionAmount);
        self.hasExpanded = NO;
    }
    else if (highlighted && !self.hasExpanded) {
        self.frame = CGRectInset(self.frame, -kThumbnailExpansionAmount, -kThumbnailExpansionAmount);
        self.hasExpanded = YES;

        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:self.contentURL];
        player.scalingMode = MPMovieScalingModeAspectFit;
        player.controlStyle = MPMovieControlStyleNone;
        player.allowsAirPlay = NO;
        player.repeatMode = MPMovieRepeatModeOne;
        [player prepareToPlay];
        [player.view setFrame:self.bounds];
        [self.contentView addSubview:player.view];
        [player play];
        self.playerController = player;
    }
}


- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = contentURL;
    self.imageView.image = nil;
    [self setNeedsLayout];
    [self generateThumbnailForAssetWithContentURL:contentURL];
}

- (void)generateThumbnailForAssetWithContentURL:(NSURL *)contentURL
{
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(taskQ, ^{
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform=TRUE;
        CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
            if (result != AVAssetImageGeneratorSucceeded) {
                NSLog(@"couldn't generate thumbnail, error:%@", error);
            }
            UIImage *thumbImage = [UIImage imageWithCGImage:im];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = thumbImage;
                [self setNeedsLayout];
            });
        };
        
        CGSize maxSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        generator.maximumSize = maxSize;
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    });
}

@end
