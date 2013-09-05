//
//  NKPreviewViewController.m
//  Rainforest
//
//  Created by Neil Kimmett on 05/09/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "NKPreviewViewController.h"
#import "Video.h"

@interface NKPreviewViewController ()
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) MPMoviePlayerController *playerController;
@property (nonatomic, assign) NSUInteger currentPlayingIndex;
@end

@implementation NKPreviewViewController

- (id)initWithAssetURLs:(NSArray *)assetURLs
{
    self = [super init];
    if (self) {
        _videos = [assetURLs mutableCopy];
        _currentPlayingIndex = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] init];
    player.scalingMode = MPMovieScalingModeAspectFit;
    player.controlStyle = MPMovieControlStyleNone;
    player.allowsAirPlay = NO;
    player.repeatMode = MPMovieRepeatModeNone;
    
    Video *video = _videos[_currentPlayingIndex];
    player.contentURL = video.contentURL;
    
    [player prepareToPlay];
    CGRect frame = CGRectInset(self.view.frame, 20, 0);
    frame.origin.y = 84;
    frame.size.height = frame.size.width;
    player.view.frame = frame;
    
    [self.view addSubview:player.view];
    [player play];
    self.playerController = player;
    
    [self enqueueNextVideo];
}

- (void)enqueueNextVideo
{
    Video *video = _videos[_currentPlayingIndex];
    AVURLAsset *currentAsset = [[AVURLAsset alloc] initWithURL:video.contentURL
                                                       options:nil];
    double delayInSeconds = CMTimeGetSeconds(currentAsset.duration);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _currentPlayingIndex++;
        if (_currentPlayingIndex >= _videos.count) {
            _currentPlayingIndex = 0;
        }
        Video *video = _videos[_currentPlayingIndex];
        _playerController.contentURL = video.contentURL;
        [_playerController play];
        [self enqueueNextVideo];
    });
    
}

@end
