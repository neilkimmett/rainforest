//
//  MSSlideUpAnimator.h
//  Food(ness)
//
//  Created by Neil Kimmett on 19/06/2013.
//  Copyright (c) 2013 Marks & Spencer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKViewSnapshotter : NSObject

+ (UIView *)snapshotViewFromView:(UIView *)view;
+ (UIImage *)snapshotImageFromView:(UIView *)view;

@end
