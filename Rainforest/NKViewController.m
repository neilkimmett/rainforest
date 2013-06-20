//
//  NKViewController.m
//  Rainforest
//
//  Created by Neil Kimmett on 16/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NKViewController.h"
#import "AVAssetStitcher.h"

@interface NKViewController ()
@property (nonatomic) AVAssetStitcher *assetStitcher;
@end

@implementation NKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AVAssetStitcher *assetStitcher = [[AVAssetStitcher alloc] initWithOutputSize:CGSizeMake(500, 500)];
    self.assetStitcher = assetStitcher;
    
    __block NSUInteger count = 0;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop2) {
                                   NSString *type = [result valueForProperty:ALAssetPropertyType];
                                   if ([type isEqualToString:ALAssetTypeVideo]) {
                                       NSNumber *duration = [result valueForProperty:ALAssetPropertyDuration];
                                       if ([duration floatValue] <= 7.0f) {
                                               NSURL *url = [result valueForProperty:ALAssetPropertyAssetURL];
                                               AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
//                                               NSArray *sourceVideoTracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
//                                               [urlAsset loadValuesAsynchronouslyForKeys:sourceVideoTracks completionHandler: ^{
//                                                   Float64 durationSeconds = CMTimeGetSeconds([urlAsset duration]);
//                                                   if (durationSeconds > 0) {
                                                       [assetStitcher addAsset:urlAsset withTransform:nil withErrorHandler:^(NSError *error) {
                                                           NSLog(@"%@", error);
                                                       }];
                                                       count++;
                                                       if (count > 4) {
                                                           [self exportFinalVideo];
                                                           *stop = YES;
                                                           *stop2 = YES;
                                                       }
//                                                   }
//                                               }];
                                           
                                           }
//                                           NSLog(@"ALAssetPropertyType %@", [result valueForProperty:ALAssetPropertyType]);
//                                           NSLog(@"ALAssetPropertyLocation %@", [result valueForProperty:ALAssetPropertyLocation]);
//                                           NSLog(@"ALAssetPropertyOrientation %@", [result valueForProperty:ALAssetPropertyOrientation]);
//                                           NSLog(@"ALAssetPropertyDate %@", [result valueForProperty:ALAssetPropertyDate]);
//                                           NSLog(@"ALAssetPropertyRepresentations %@", [result valueForProperty:ALAssetPropertyRepresentations]);
//                                           NSLog(@"ALAssetPropertyURLs %@", [result valueForProperty:ALAssetPropertyURLs]);
//                                           NSLog(@"ALAssetPropertyAssetURL %@", [result valueForProperty:ALAssetPropertyAssetURL]);
//                                           NSLog(@"\n\n\n\n");
                                   }
                               }];
                           } failureBlock:^(NSError *error) {
                               NSLog(@"%@", error);
                           }];
    
}
- (void)exportFinalVideo
{
    NSLog(@"%@ %s", NSStringFromClass([self class]), __FUNCTION__);
    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];
    NSURL *videoURL = [NSURL URLWithString:[documentsDirectory stringByAppendingPathComponent:@"megavine.mp4"]];
    [self.assetStitcher exportTo:videoURL withPreset:AVAssetExportPresetHighestQuality withCompletionHandler:^(NSError *error) {
        NSLog(@"%@", error);
//        MPMoviePlayerViewController *movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
//        [self presentMoviePlayerViewControllerAnimated:movieController];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
