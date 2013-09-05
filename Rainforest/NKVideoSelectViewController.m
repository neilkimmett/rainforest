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
#import "NKVideoThumbnailCell.h"
#import "NKAssetStitcher.h"
#import "NKViewSnapshotter.h"
#import "UIImage+ImageEffects.h"
#import "NKPreviewViewController.h"

@interface NKVideoSelectViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *assetURLs;
@property (nonatomic, strong) NSMutableDictionary *selectedAssetURLsByRow;
@property (nonatomic, strong) NSMutableArray *selectedAssetURLsArray;
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
    layout.itemSize = CGSizeMake(100, 100);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:frame
                                                          collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    collectionView.contentInset = [UIDevice isiOS7] && self.navigationController.navigationBar.translucent ? UIEdgeInsetsMake(heightAdjustment, 0, 0, 0) : UIEdgeInsetsZero;
    [collectionView registerClass:[NKVideoThumbnailCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    collectionView.dataSource = self;
    collectionView.allowsMultipleSelection = YES;
    collectionView.backgroundColor = [UIColor whiteColor];
    
    self.collectionView = collectionView;
    [self.view addSubview:collectionView];
    
    [self loadAssets];
}

- (void)loadAssets
{
    self.assetURLs = [NSMutableArray array];

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop2) {
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            if ([type isEqualToString:ALAssetTypeVideo]) {
                NSNumber *duration = [asset valueForProperty:ALAssetPropertyDuration];
                if ([duration floatValue] <= 7.0f) {
                    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
                    [self.assetURLs insertObject:url atIndex:0];
                    [self.collectionView reloadData];
                }
            }
        }];
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
    for (NSNumber *index in [self.selectedAssetURLsByRow allKeys]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[index intValue] inSection:0];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    
    self.selectedAssetURLsByRow = [NSMutableDictionary dictionary];
    self.selectedAssetURLsArray = [NSMutableArray array];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetURLs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    NKVideoThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.contentURL = self.assetURLs[indexPath.row];
    
    if (cell.gestureRecognizers.count == 0) {
        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellDidRecognizeLongPress:)];
        gesture.minimumPressDuration = 0.3;
        [cell addGestureRecognizer:gesture];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self removePreviewView];
    NSURL *url = self.assetURLs[indexPath.row];
    [self.selectedAssetURLsArray addObject:url];
    self.selectedAssetURLsByRow[@(indexPath.row)] = url;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self removePreviewView];
    NSURL *url = self.selectedAssetURLsByRow[@(indexPath.row)];
    [self.selectedAssetURLsArray removeObject:url];
    [self.selectedAssetURLsByRow removeObjectForKey:@(indexPath.row)];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self removePreviewView];
}

#pragma mark - Gesture rec
- (void)cellDidRecognizeLongPress:(UILongPressGestureRecognizer *)gesture
{
    
    NKVideoThumbnailCell *cell = (NKVideoThumbnailCell *)gesture.view;

    if ([self.playerController.contentURL isEqual:cell.contentURL]) {
        return;
    }
    [self removePreviewView];
    
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
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:cell.contentURL];
    player.scalingMode = MPMovieScalingModeAspectFit;
    player.controlStyle = MPMovieControlStyleNone;
    player.allowsAirPlay = NO;
    player.repeatMode = MPMovieRepeatModeOne;
    [player prepareToPlay];
    player.view.frame = [self previewRectForPressedCell:cell];
    [self.view addSubview:player.view];
    [player play];
    self.playerController = player;
}

- (CGRect)previewRectForPressedCell:(NKVideoThumbnailCell *)cell
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
    
    [self.previewBackgroundOverlay removeFromSuperview];
    self.previewBackgroundOverlay = nil;
}

#pragma mark - Buttons
- (void)didTapNextButton:(id)sender
{
    NKPreviewViewController *viewController = [[NKPreviewViewController alloc] initWithAssetURLs:[self.selectedAssetURLsArray copy]];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Video generation
- (void)generateVideo:(id)sender
{
    NKAssetStitcher *assetStitcher = [[NKAssetStitcher alloc] init];

    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];

    [self.selectedAssetURLsByRow enumerateKeysAndObjectsUsingBlock:^(NSNumber *idx, NSURL *url, BOOL *stop) {
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
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
