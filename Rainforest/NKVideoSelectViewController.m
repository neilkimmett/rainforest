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

@interface NKVideoSelectViewController ()
@property (nonatomic) NSMutableArray *assetURLs;
@property (nonatomic) NSMutableDictionary *selectedAssetURLsByRow;
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
    self.selectedAssetURLsByRow = [NSMutableDictionary dictionary];
    
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
    self.selectedAssetURLsByRow[@(indexPath.row)] = self.assetURLs[indexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.selectedAssetURLsByRow removeObjectForKey:@(indexPath.row)];
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
