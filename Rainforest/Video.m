//
//  Video.m
//  Rainforest
//
//  Created by Neil Kimmett on 05/09/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import "Video.h"
#import <AVFoundation/AVFoundation.h>

@implementation Video

- (id)initWithContentURL:(NSURL *)contentURL
{
    self = [super init];
    if (self) {
        _contentURL = contentURL;
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL
                                                    options:nil];
        _duration = CMTimeGetSeconds(asset.duration);
    }
    return self;
}

+ (instancetype)videoWithContentURL:(NSURL *)contentURL
{
    Video *video = [[self alloc] initWithContentURL:contentURL];
    return video;
}


- (UIImage *)image
{
    NSAssert(_contentURL != nil, @"Can't have image when contentURL is nil");
    return [[[self class] sharedImageCache] objectForKey:_contentURL];
}

- (void)generateImageWithCompletion:(void (^)(UIImage *image))completion
{
    NSAssert(_contentURL != nil, @"Can't generate image when contentURL is nil");
    dispatch_queue_t taskQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(taskQ, ^{
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_contentURL options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        
        AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
            if (result != AVAssetImageGeneratorSucceeded) {
                NSLog(@"couldn't generate thumbnail, error:%@", error);
            }
            UIImage *thumbImage = [UIImage imageWithCGImage:im];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(thumbImage);
                
                [[[self class] sharedImageCache] setObject:thumbImage forKey:_contentURL];
            });
        };
        
        CGSize maxSize = CGSizeMake(100, 100);
        generator.maximumSize = maxSize;
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:handler];
    });
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

@end
