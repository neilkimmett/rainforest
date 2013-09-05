//
//  NKVideoThumbnailCell.h
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKIndexedImageCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) NSUInteger index;

@end