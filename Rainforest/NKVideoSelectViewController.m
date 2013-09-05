//
//  NKVideoSelectViewController.m
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "NKVideoSelectViewController.h"
#import "NKIndexedImageCell.h"
#import "NKAssetStitcher.h"
#import "NKViewSnapshotter.h"
#import "UIImage+ImageEffects.h"
#import "NKPreviewViewController.h"
#import "Video.h"

@interface NKVideoSelectViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *videos;
@property (nonatomic, strong) NSMutableDictionary *selectedVideosByRow;
@property (nonatomic, strong) NSMutableArray *selectedVideosArray;
@property (nonatomic, strong) MPMoviePlayerController *playerController;
@property (nonatomic, strong) UIView *previewBackgroundOverlay;
@end

@implementation NKVideoSelectViewController

+ (instancetype)selectionViewController
{
    return [[self alloc] init];
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
//    CGFloat heightAdjustment = self.parentViewController.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
//    if (![UIDevice isiOS7]) {
//        frame.size.height -= heightAdjustment;
//    }
    
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = containerView;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(106, 106);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 1.0f / [[UIScreen mainScreen] scale];

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                          collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    collectionView.contentInset = [UIDevice isiOS7] && self.navigationController.navigationBar.translucent ? UIEdgeInsetsMake(heightAdjustment, 0, 0, 0) : UIEdgeInsetsZero;
    [collectionView registerClass:[NKIndexedImageCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    collectionView.dataSource = self;
    collectionView.allowsMultipleSelection = YES;
    collectionView.backgroundColor = [UIColor whiteColor];
    
    self.collectionView = collectionView;
    [self.view addSubview:collectionView];
    
    [self loadVideos];
}

- (void)loadVideos
{
    NSMutableArray *videos = [NSMutableArray array];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop2) {
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            if ([type isEqualToString:ALAssetTypeVideo]) {
                NSNumber *duration = [asset valueForProperty:ALAssetPropertyDuration];
                if ([duration floatValue] <= 7.0f) {
                    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
                    
                    Video *video = [Video videoWithContentURL:url];
                    [videos insertObject:video atIndex:0];
                }
            }
        }];
        self.videos = [videos copy];
        [self.collectionView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(didTapNextButton:)];
    //                                                                      action:@selector(generateVideo:)];
    self.navigationItem.rightBarButtonItem = barButton;
    
}
- (void)viewDidAppear:(BOOL)animated
{
    for (NSNumber *index in [self.selectedVideosByRow allKeys]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[index intValue] inSection:0];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    self.selectedVideosByRow = [NSMutableDictionary dictionary];
    self.selectedVideosArray = [NSMutableArray array];
    [self enableOrDisableNextButton];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.videos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    NKIndexedImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.index = indexPath.row;

    Video *video = self.videos[indexPath.row];
    if (video.image) {
        cell.imageView.image = video.image;
    }
    else {
        cell.imageView.image = nil;
        [video generateImageWithCompletion:^(UIImage *image) {
            cell.imageView.image = image;
            [cell setNeedsDisplay];
        }];
    }
    
    if (cell.gestureRecognizers.count == 0) {
        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellDidRecognizeLongPress:)];
        gesture.minimumPressDuration = 0.2;
        [cell addGestureRecognizer:gesture];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Video *video = self.videos[indexPath.row];
    [self.selectedVideosArray addObject:video];
    self.selectedVideosByRow[@(indexPath.row)] = video;
    
    [self enableOrDisableNextButton];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Video *video = self.selectedVideosByRow[@(indexPath.row)];
    [self.selectedVideosArray removeObject:video];
    [self.selectedVideosByRow removeObjectForKey:@(indexPath.row)];
    
    [self enableOrDisableNextButton];
}

#pragma mark - Gesture rec
- (void)cellDidRecognizeLongPress:(UILongPressGestureRecognizer *)gesture
{
    
    NKIndexedImageCell *cell = (NKIndexedImageCell *)gesture.view;

    Video *video = _videos[cell.index];
    if ([self.playerController.contentURL isEqual:video.contentURL]) {
        return;
    }
    
    [self addBlurredPreviewBackground];

    CGRect cellRect = [self.collectionView convertRect:cell.frame toView:self.view];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:video.image];
    imageView.frame = cellRect;
    [self.view addSubview:imageView];
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:video.contentURL];
    CGRect previewRect = [self previewRectForPressedCell:cell];
    player.scalingMode = MPMovieScalingModeAspectFit;
    player.controlStyle = MPMovieControlStyleNone;
    player.allowsAirPlay = NO;
    player.repeatMode = MPMovieRepeatModeOne;
    [player prepareToPlay];
    player.view.frame = previewRect;
    [self.view addSubview:player.view];
    self.playerController = player;

    player.view.hidden = YES;
    self.previewBackgroundOverlay.alpha = 0.0f;
    [UIView animateWithDuration:0.2f animations:^{
        imageView.frame = previewRect;
        self.previewBackgroundOverlay.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
        player.view.hidden = NO;
        [player play];
    }];
}

- (void)addBlurredPreviewBackground
{
    [self.previewBackgroundOverlay removeFromSuperview];
    self.previewBackgroundOverlay = nil;
    
    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    UIImage *blurImage = [[NKViewSnapshotter snapshotImageFromView:self.view] applyBlurWithRadius:5
                                                                                        tintColor:tintColor
                                                                            saturationDeltaFactor:1.5
                                                                                        maskImage:nil];
    UIImageView *previewBackgroundView = [[UIImageView alloc] initWithImage:blurImage];
    previewBackgroundView.frame = self.view.bounds;
    previewBackgroundView.userInteractionEnabled = YES;
    [self.view addSubview:previewBackgroundView];
    self.previewBackgroundOverlay = previewBackgroundView;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removePreviewView)];
    [previewBackgroundView addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(removePreviewView)];
    [previewBackgroundView addGestureRecognizer:pan];
}

- (CGRect)previewRectForPressedCell:(NKIndexedImageCell *)cell
{
    CGRect cellRect = [self.collectionView convertRect:cell.frame toView:self.view];

    CGFloat previewSize = 200;
    CGRect previewFrame = CGRectMake(0, 0, previewSize, previewSize);
    if (cellRect.origin.x < CGRectGetMidX(self.view.frame)) {
        previewFrame.origin.x = CGRectGetMaxX(cellRect) + 5;
    }
    else {
        previewFrame.origin.x = CGRectGetMinX(cellRect) - previewSize - 5;
    }
    
    if (cellRect.origin.y < CGRectGetMidY(self.view.frame)) {
        previewFrame.origin.y = CGRectGetMaxY(cellRect) + 5;
    }
    else {
        previewFrame.origin.y = CGRectGetMinY(cellRect) - previewSize - 5;
    }
    
    // Account for preview spilling off screen
    CGFloat overspillX = CGRectGetMaxX(previewFrame) - CGRectGetMaxX(self.view.frame);
    if (overspillX > 0) {
        previewFrame = CGRectOffset(previewFrame, -overspillX, 0);
    }
    CGFloat overspillY = CGRectGetMaxY(previewFrame) - CGRectGetMaxY(self.view.frame);
    if (overspillY > 0) {
        previewFrame = CGRectOffset(previewFrame, 0, -overspillY);
    }
    return previewFrame;
}

- (void)removePreviewView
{
    [self.playerController stop];
    [self.playerController.view removeFromSuperview];
    self.playerController = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.previewBackgroundOverlay.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.previewBackgroundOverlay removeFromSuperview];
        self.previewBackgroundOverlay = nil;
    }];
}

#pragma mark - Buttons
- (void)enableOrDisableNextButton
{
    self.navigationItem.rightBarButtonItem.enabled = self.selectedVideosArray.count > 0;
}

- (void)didTapNextButton:(id)sender
{
    NKPreviewViewController *viewController = [[NKPreviewViewController alloc] initWithAssetURLs:[_selectedVideosArray copy]];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Video generation
- (void)generateVideo:(id)sender
{
    NKAssetStitcher *assetStitcher = [[NKAssetStitcher alloc] init];

    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];

    [_selectedVideosByRow enumerateKeysAndObjectsUsingBlock:^(NSNumber *idx, Video *video, BOOL *stop) {
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:video.contentURL options:nil];
        [assetStitcher addAsset:urlAsset withTransform:nil withErrorHandler:^(NSError *error) {
            NSLog(@"%@", error);
        }];
    }];
    
    NSString *exportPath = [documentsDirectory stringByAppendingPathComponent:@"name.mp4"];
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    [assetStitcher exportTo:exportUrl withPreset:AVAssetExportPresetPassthrough withCompletionHandler:^(NSError *error) {
        if (!error) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl]) {
                [library writeVideoAtPathToSavedPhotosAlbum:exportUrl completionBlock:^(NSURL *assetURL, NSError *error){
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        MPMoviePlayerViewController *movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:assetURL];
                        [self presentMoviePlayerViewControllerAnimated:movieController];
                        
                    }
                }];
            }
        }
    }];
}

@end
