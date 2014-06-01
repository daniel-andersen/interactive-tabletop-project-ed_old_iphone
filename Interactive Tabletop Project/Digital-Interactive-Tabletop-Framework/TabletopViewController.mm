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

#import "TabletopViewController.h"
#import "BoardCalibrator.h"
#import "ExternalDisplay.h"
#import "UIImage+CaptureScreen.h"
#import "Constants.h"
#import "SampleView.h"

@interface TabletopViewController () <BoardCalibratorDelegate>

@property (nonatomic, assign) bool isUpdating;

@property (nonatomic, strong) NSTimer *updateTimer;

@end

@implementation TabletopViewController

@synthesize tabletopView = _tabletopView;
@synthesize updateInterval = _updateInterval;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initialize {
    self.updateInterval = 0.1f;
    
    [[ExternalDisplay instance] initialize];
    [BoardCalibrator instance].delegate = self;
    self.tabletopView = [[SampleView alloc] init];

    //[self setGridOfSize:CGSizeMake(30.0f, 20.0f)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[BoardCalibrator instance] start];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[BoardCalibrator instance] stop];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:super.overlayView];
    super.overlayView.hidden = [[ExternalDisplay instance] isCalibrating];
    [[ExternalDisplay instance] layoutSubviews];
}

- (void)setGridOfSize:(CGSize)size {
    [Constants instance].gridSize = size;
    [[Constants instance] calculateBrickSize];
    [super addBoardGridLayer];
}

- (IBAction)startButtonPressed:(id)sender {
    [[ExternalDisplay instance] stopProjectorCalibration];
    [self start];
}

- (void)start {
    super.overlayView.hidden = NO;
    [self startUpdateTimer];
}

- (void)startUpdateTimer {
    self.isUpdating = NO;
    if (self.updateTimer != nil) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    self.updateTimer = [NSTimer timerWithTimeInterval:self.updateInterval target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.updateTimer forMode:NSRunLoopCommonModes];
}

- (void)boardCalibratorUpdateWithImage:(UIImage *)image {
    [super previewFrame:image];
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    return [UIImage imageWithView:self.tabletopView];
}

- (void)update {
    @synchronized(self) {
        if (self.isUpdating) {
            return;
        }
        [self.tabletopView update];
        self.isUpdating = YES;
    }
    @try {
    } @finally {
        self.isUpdating = NO;
    }
}

- (void)setTabletopView:(TabletopView *)tabletopView {
    [_tabletopView hide];
    _tabletopView = tabletopView;
    [_tabletopView show];
    if (![CameraSession instance].initialized && ![ExternalDisplay instance].externalDisplayFound) {
        [super prepareSimulatorViewWithPreviewView:tabletopView];
    }
}

- (TabletopView *)tabletopView {
    return _tabletopView;
}

- (void)setUpdateInterval:(CFTimeInterval)updateInterval {
    _updateInterval = updateInterval;
    if (self.updateTimer != nil) {
        [self startUpdateTimer];
    }
}

- (CFTimeInterval)updateInterval {
    return _updateInterval;
}

@end
