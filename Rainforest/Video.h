//
//  Video.h
//  Rainforest
//
//  Created by Neil Kimmett on 05/09/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Video : NSObject

+ (instancetype)videoWithContentURL:(NSURL *)contentURL;

@property (nonatomic, copy) NSURL *contentURL;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) CGFloat duration;

- (void)generateImageWithCompletion:(void (^)(UIImage *image))completion;

@end
