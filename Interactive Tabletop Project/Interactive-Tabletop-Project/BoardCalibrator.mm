// Copyright (c) 2014, Daniel Andersen (daniel@trollsahead.dk)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "BoardCalibrator.h"
#import "CameraSession.h"
#import "CameraUtil.h"
#import "ExternalDisplay.h"
#import "BoardUtil.h"
#import "UIImage+OpenCV.h"
#import "Constants.h"

BoardCalibrator *boardCalibratorInstance = nil;

@interface BoardCalibrator () <CameraSessionDelegate>

@property (nonatomic, assign) CFAbsoluteTime successTime;
@property (nonatomic, assign) CFAbsoluteTime lastUpdateTime;

@end

@implementation BoardCalibrator

@synthesize state;
@synthesize boardBounds;
@synthesize screenPoints;
@synthesize boardImage;
@synthesize boardImageSize;
@synthesize boardImageLock;

+ (BoardCalibrator *)instance {
    @synchronized(self) {
        if (boardCalibratorInstance == nil) {
            boardCalibratorInstance = [[BoardCalibrator alloc] init];
        }
        return boardCalibratorInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    boardImageLock = [[NSObject alloc] init];

    state = BOARD_CALIBRATION_STATE_UNCALIBRATED;
    boardBounds.bounds.defined = NO;

    [CameraSession instance].delegate = self;
}

- (void)start {
    [[CameraSession instance] start];
}

- (void)stop {
    [[CameraSession instance] stop];
}

- (void)processFrame:(UIImage *)image {
    @autoreleasepool {
        if (image == nil) {
            return;
        }
        cv::Mat grayscaledImage = [image grayscaledCVMat];
        [self updateBoundsWithImage:grayscaledImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [CameraSession instance].readyToProcessFrame = YES;
        });
        [self.delegate boardCalibratorUpdateWithImage:image];
    }
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    return [self.delegate requestSimulatedImageIfNoCamera];
}

- (void)updateBoundsWithImage:(cv::Mat)image {
    boardBounds = [[BoardRecognizer instance] findBoardBoundsFromImage:image];
    if (boardBounds.bounds.defined) {
        state = BOARD_CALIBRATION_STATE_CALIBRATED;
        @synchronized(boardImageLock) {
            boardImage = [self perspectiveCorrectImage:image];
            boardImageSize = CGSizeMake(boardImage.cols, boardImage.rows);
        }
        //[cameraSession lock];
    } else {
        state = BOARD_CALIBRATION_STATE_CALIBRATING;
        //[cameraSession unlock];
    }
}

- (cv::Mat)perspectiveCorrectImage:(cv::Mat)image {
    return [[BoardRecognizer instance] perspectiveCorrectImage:image fromBoardBounds:boardBounds.bounds];
}

- (bool)isBoardFullyRecognized {
    return self.boardBounds.bounds.defined && !self.boardBounds.isBoundsObstructed;
}

- (bool)isBoardRecognized {
    return self.boardBounds.bounds.defined;
}

@end
