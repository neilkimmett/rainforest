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

+ (NSCache *)sharedImageCache
{
    static NSCache *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[NSCache alloc] init];
    });
    
    return _shared;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
    self.selectionView.frame = self.bounds;
    self.selectionView.hidden = !self.selected;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
}


- (void)setContentURL:(NSURL *)contentURL
{
    _contentURL = contentURL;
    
    UIImage *cachedImage = [[[self class] sharedImageCache] objectForKey:contentURL];
    if (cachedImage) {
        self.imageView.image = cachedImage;
    }
    else {
        self.imageView.image = nil;
        [self setNeedsDisplay];
        [self generateThumbnailForAssetWithContentURL:contentURL];
    }
}

- (void)generateThumbnailForAssetWithContentURL:(NSURL *)contentURL
{
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(taskQ, ^{
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
            if (result != AVAssetImageGeneratorSucceeded) {
                NSLog(@"couldn't generate thumbnail, error:%@", error);
            }
            UIImage *thumbImage = [UIImage imageWithCGImage:im];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = thumbImage;
                [self setNeedsDisplay];
                
                [[[self class] sharedImageCache] setObject:thumbImage forKey:contentURL];
            });
        };
        
        CGSize maxSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        generator.maximumSize = maxSize;
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:handler];
    });
}

@end
