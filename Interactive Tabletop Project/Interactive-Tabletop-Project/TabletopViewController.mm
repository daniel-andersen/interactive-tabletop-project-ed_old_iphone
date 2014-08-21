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
#import "ExternalDislayCalibrationView.h"
#import "FakeCameraUtil.h"
#import "UIImage+CaptureScreen.h"
#import "Constants.h"

@interface TabletopViewController () <BoardCalibratorDelegate, ExternalDisplayCalibrationViewDelegate>

@property (nonatomic, assign) bool isUpdating;

@property (nonatomic, strong) NSTimer *updateTimer;

@property (nonatomic, strong) ExternalDislayCalibrationView *externalDislayCalibrationView;
@property (nonatomic, assign) CFAbsoluteTime calibratorStartTime;
@property (nonatomic, assign) CFAbsoluteTime calibratorMinDuration;

@end

@implementation TabletopViewController

@synthesize tabletopView = _tabletopView;
@synthesize updateInterval = _updateInterval;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
}

- (void)initialize {
    self.updateInterval = 0.1f;
    
    [[ExternalDisplay instance] initialize];
    [BoardCalibrator instance].delegate = self;

    [self startExternalDisplayCalibration];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[BoardCalibrator instance] start];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[BoardCalibrator instance] stop];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:super.overlayView];
    super.overlayView.hidden = [self isCalibratingExternalDisplay];
    if ([self isCalibratingExternalDisplay]) {
        [[ExternalDisplay instance].window bringSubviewToFront:self.externalDislayCalibrationView];
    }
}

- (void)startExternalDisplayCalibration {
    if (![ExternalDisplay instance].externalDisplayFound) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self calibrationViewDidHide];
        });
        return;
    }
    NSLog(@"Showing calibration view...");
    self.externalDislayCalibrationView = [[ExternalDislayCalibrationView alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
    self.externalDislayCalibrationView.delegate = self;
    
    [[ExternalDisplay instance].window addSubview:self.externalDislayCalibrationView];
    
    self.calibratorMinDuration = 8.0f;
    self.calibratorStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)stopExternalDisplayCalibration {
    CFTimeInterval remainingTime = MAX(0.0f, (self.calibratorStartTime + self.calibratorMinDuration) - CFAbsoluteTimeGetCurrent());
    [self performSelector:@selector(hideExternalDisplayCalibrationView) withObject:nil afterDelay:remainingTime];
}

- (void)hideExternalDisplayCalibrationView {
    [self.externalDislayCalibrationView hideView];
}

- (void)calibrationViewDidHide {
    [self.externalDislayCalibrationView removeFromSuperview];
    self.externalDislayCalibrationView = nil;

    super.overlayView.hidden = NO;
    [self startUpdateTimer];
}

- (bool)isCalibratingExternalDisplay {
    return self.externalDislayCalibrationView != nil;
}

- (void)setGridOfSize:(CGSize)size {
    [Constants instance].gridSize = size;
    [[Constants instance] recalculateConstants];
    [super addBoardGridLayer];
}

- (void)setGridWithPixelSize:(CGSize)size {
    [self setGridOfSize:CGSizeMake((int)([Constants instance].canvasRect.size.width  / size.width ),
                                   (int)([Constants instance].canvasRect.size.height / size.height))];
}

- (void)showBorderAnimated:(bool)animated {
    [Constants instance].borderEnabled = YES;

    if (self.tabletopBorderView == nil) {
        self.tabletopBorderView = [[TabletopBorderView alloc] initWithImages:[NSArray arrayWithObjects:
                                                                              [UIImage imageNamed:@"border_top_left.png"],
                                                                              [UIImage imageNamed:@"border_top.png"],
                                                                              [UIImage imageNamed:@"border_top_right.png"],
                                                                              [UIImage imageNamed:@"border_right.png"],
                                                                              [UIImage imageNamed:@"border_bottom_right.png"],
                                                                              [UIImage imageNamed:@"border_bottom.png"],
                                                                              [UIImage imageNamed:@"border_bottom_left.png"],
                                                                              [UIImage imageNamed:@"border_left.png"],
                                                                              nil]];
    } else {
        [self.tabletopBorderView removeFromSuperview];
    }
    self.tabletopBorderView.hidden = NO;
    self.tabletopBorderView.alpha = 0.0f;
    
    [[ExternalDisplay instance].window insertSubview:self.tabletopBorderView atIndex:0];
    
    [UIView animateWithDuration:(animated ? [Constants instance].defaultViewAnimationDuration : 0.0f) animations:^{
        self.tabletopBorderView.alpha = 1.0f;
    }];
}

- (void)hideBorderAnimated:(bool)animated {
    [Constants instance].borderEnabled = NO;

    [UIView animateWithDuration:(animated ? [Constants instance].defaultViewAnimationDuration : 0.0f) animations:^{
        self.tabletopBorderView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.tabletopBorderView removeFromSuperview];
    }];
}

- (void)start {
    [self stopExternalDisplayCalibration];
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
    if (self.tabletopBorderView == nil) {
        return [UIImage imageWithView:self.tabletopView];
    } else {
        return [self simulatedBorderedImage];
    }
}

- (UIImage *)simulatedBorderedImage {
    CGSize size = CGSizeMake(self.tabletopBorderView.frame.size.width * 1.2f, self.tabletopBorderView.frame.size.height * 1.2f);

    CGRect tabletopRect = CGRectMake((size.width - self.tabletopBorderView.bounds.size.width) / 2.0f, (size.height - self.tabletopBorderView.bounds.size.height) / 2.0f, self.tabletopBorderView.bounds.size.width, self.tabletopBorderView.bounds.size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
    
    CGContextDrawImage(context, tabletopRect, [UIImage imageWithView:self.tabletopBorderView].CGImage);
    CGContextDrawImage(context, CGRectMake((size.width - self.tabletopView.bounds.size.width) / 2.0f, (size.height - self.tabletopView.bounds.size.height) / 2.0f, self.tabletopView.bounds.size.width, self.tabletopView.bounds.size.height), [UIImage imageWithView:self.tabletopView].CGImage);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    image = [[FakeCameraUtil instance] drawBricksOnImage:image inRect:tabletopRect];

    return image;
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
    [self hideCurrentTabletopView];
    _tabletopView = tabletopView;
    [self showCurrentTabletopView];
    if (![CameraSession instance].initialized && ![ExternalDisplay instance].externalDisplayFound) {
        [self prepareSimulatorViewWithPreviewView:tabletopView borderView:self.tabletopBorderView];
    }
}

- (TabletopView *)tabletopView {
    return _tabletopView;
}

- (void)hideCurrentTabletopView {
    [_tabletopView willDisappear];
    [_tabletopView hide];
    [_tabletopView didDisappear];
}

- (void)showCurrentTabletopView {
    [_tabletopView willAppear];
    [_tabletopView show];
    [_tabletopView didAppear];
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
