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
#import "AVAssetStitcher.h"

@interface NKVideoSelectViewController ()
@property (nonatomic) NSMutableArray *assetURLs;
@property (nonatomic) NSMutableArray *selectedAssetURLs;
@end

@implementation NKVideoSelectViewController

+ (instancetype)selectionViewController
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    return [[self alloc] initWithCollectionViewLayout:layout];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.allowsMultipleSelection = YES;
    
    UIBarButtonItem *generateButton = [[UIBarButtonItem alloc] initWithTitle:@"Generate"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(generateVideo:)];
    self.navigationItem.rightBarButtonItem = generateButton;
    
    [self.collectionView registerClass:[NKVideoThumbnailCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    
    self.assetURLs = [NSMutableArray array];
    self.selectedAssetURLs = [NSMutableArray array];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop2) {
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            if ([type isEqualToString:ALAssetTypeVideo]) {
                NSNumber *duration = [asset valueForProperty:ALAssetPropertyDuration];
                if ([duration floatValue] <= 7.0f) {
                    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
                    [self.assetURLs addObject:url];
                    [self.collectionView reloadData];
                }
            }
        }];
    } failureBlock:^(NSError *error) {
        NSLog(@"%@", error);
    }];
    
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
    cell.presentingViewController = self;
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedAssetURLs addObject:self.assetURLs[indexPath.row]];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *url = self.selectedAssetURLs[indexPath.row];
    [self.selectedAssetURLs removeObject:url];
}

#pragma mark - Video generation
- (void)generateVideo:(id)sender
{
    AVAssetStitcher *assetStitcher = [[AVAssetStitcher alloc] initWithOutputSize:CGSizeMake(500, 500)];

    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];
    NSURL *videoURL = [NSURL URLWithString:[documentsDirectory stringByAppendingPathComponent:@"megavine.mp4"]];
    
    for (NSURL *url in self.selectedAssetURLs) {
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
        [assetStitcher addAsset:urlAsset withTransform:nil withErrorHandler:^(NSError *error) {
            NSLog(@"%@", error);
        }];
    }
    
    [assetStitcher exportTo:videoURL withPreset:AVAssetExportPresetHighestQuality withCompletionHandler:^(NSError *error) {
        NSLog(@"%@", error);
        MPMoviePlayerViewController *movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
        [self presentMoviePlayerViewControllerAnimated:movieController];
    }];

    
}

@end
