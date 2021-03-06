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

#import "ViewController.h"
#import "MazeView.h"
#import "ExternalDisplay.h"
#import "PracticeHelper.h"
#import "MazeModel.h"
#import "Constants.h"

@interface ViewController ()

@property (nonatomic, strong) MazeView *mazeView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [PracticeHelper instance].enabled = NO;
    [PracticeHelper instance].currentImageNumber = 10;
    [PracticeHelper instance].placePlayers = YES;
    
    [self showBorderAnimated:NO];
#if TARGET_IPHONE_SIMULATOR
    if ([PracticeHelper instance].enabled) {
        [self setGridOfSize:CGSizeMake([[PracticeHelper instance] mazeSize].x, [[PracticeHelper instance] mazeSize].y)];
    } else {
        [self setGridWithPixelSize:CGSizeMake(20.0f, 20.0f)];
    }
#else
    [self setGridWithPixelSize:CGSizeMake(35.0f, 35.0f)];
#endif
    [self start];
}

- (void)calibrationViewDidHide {
    [super calibrationViewDidHide];

    NSLog(@"Starting...");
    self.mazeView = [[MazeView alloc] init];
    self.tabletopView = self.mazeView;

    [self.mazeView start];
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    if ([PracticeHelper instance].enabled) {
        return [[PracticeHelper instance] currentImage];
    } else {
        return [super requestSimulatedImageIfNoCamera];
    }
}

@end
