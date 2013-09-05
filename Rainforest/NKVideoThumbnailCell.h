//
//  NKVideoThumbnailCell.h
//  Rainforest
//
//  Created by Neil Kimmett on 20/06/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol NKVideoThumbnailCellDelegate;

@interface NKVideoThumbnailCell : UICollectionViewCell

@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, weak) id <NKVideoThumbnailCellDelegate> delegate;

@end

@protocol NKVideoThumbnailCellDelegate <NSObject>
// TODO: probably get rid of this
@end