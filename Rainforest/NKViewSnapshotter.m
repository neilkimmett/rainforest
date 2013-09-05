//
//  MSSlideUpAnimator.m
//  Food(ness)
//
//  Created by Neil Kimmett on 19/06/2013.
//  Copyright (c) 2013 Marks & Spencer. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NKViewSnapshotter.h"

@implementation NKViewSnapshotter

+ (UIView *)snapshotViewFromView:(UIView *)view
{
    if ([view respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [view snapshotViewAfterScreenUpdates:NO];
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self snapshotImageFromView:view]];
    imageView.frame = view.bounds;
    return imageView;
}

+ (UIImage *)snapshotImageFromView:(UIView *)view
{
    if (UIGraphicsBeginImageContextWithOptions) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    }
	else {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return snapshot;
}

@end
