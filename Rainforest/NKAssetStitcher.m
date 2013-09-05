//
// Copyright (c) 2013 Neil Kimmett
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions
// of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

#import "NKAssetStitcher.h"

@interface NKAssetStitcher ()
@property (nonatomic, strong) AVMutableComposition *composition;
@end

@implementation NKAssetStitcher

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _composition = [[AVMutableComposition alloc] init];
    }
    return self;
}

- (void)addAsset:(AVURLAsset *)asset withTransform:(CGAffineTransform (^)(AVAssetTrack *videoTrack))transformToApply withErrorHandler:(void (^)(NSError *error))errorHandler
{
    NSError *error;
    BOOL success = [_composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                         ofAsset:asset
                                          atTime:_composition.duration
                                           error:&error];
    
    if(error || !success)
    {
        errorHandler(error);
        return;
    }
}


- (void)exportTo:(NSURL *)outputFile withPreset:(NSString *)preset withCompletionHandler:(void (^)(NSError *error))completionHandler
{
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:_composition presetName:preset];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputURL = outputFile;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        switch([exporter status])
        {
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(exporter.error);
                });
            } break;
            case AVAssetExportSessionStatusCancelled:
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(nil);
                });
            } break;
            default:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler([NSError errorWithDomain:@"Unknown export error" code:100 userInfo:nil]);
                });
            } break;
        }
        
    }];
}

@end
