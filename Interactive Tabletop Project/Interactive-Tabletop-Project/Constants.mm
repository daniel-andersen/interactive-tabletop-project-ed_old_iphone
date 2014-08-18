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

#import "Constants.h"
#import "ExternalDisplay.h"
#import "CameraSession.h"

Constants *constantsInstance = nil;

@implementation Constants

+ (Constants *)instance {
    @synchronized (self) {
        if (constantsInstance == nil) {
            constantsInstance = [[Constants alloc] init];
        }
        return constantsInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.borderEnabled = NO;
    self.borderRecognizedSizePct = CGSizeMake(0.04f, 0.04f);
    self.borderViewSizePct = CGSizeMake(0.5f, 0.5f);
    [self recalculateConstants];
    
    self.defaultViewAnimationDuration = 0.3f;
}

- (void)setBorderEnabled:(bool)borderEnabled {
    _borderEnabled = borderEnabled;
    [self recalculateConstants];
}

- (void)recalculateConstants {
    CGSize screenSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGSize cameraCaptureSize = CGSizeMake(640.0f, 480.0f); // TODO! Hardcoded camera capture size!

    self.canvasRect = [self canvasRectWithBrickSize:self.brickSize screenSize:[ExternalDisplay instance].widescreenBounds.size];
    self.canvasScreenRect = [self canvasRectWithBrickSize:self.brickScreenSize screenSize:screenSize];
    self.canvasCameraRect = [self canvasRectWithBrickSize:self.brickCameraSize screenSize:cameraCaptureSize];
    
    self.brickSize = [self brickSizeWithScreenSize:self.canvasRect.size];
    self.brickScreenSize = [self brickSizeWithScreenSize:self.canvasScreenRect.size];
    self.brickCameraSize = [self brickSizeWithScreenSize:self.canvasCameraRect.size];

    self.gridRect = [self gridRectWithBrickSize:self.brickSize screenSize:self.canvasRect.size];
    self.gridScreenRect = [self gridRectWithBrickSize:self.brickScreenSize screenSize:self.canvasScreenRect.size];
    self.gridCameraRect = [self gridRectWithBrickSize:self.brickCameraSize screenSize:self.canvasCameraRect.size];
}

- (CGRect)canvasRectWithBrickSize:(CGSize)brickSize screenSize:(CGSize)screenSize {
    CGSize rectSize = [self screenSizeWithoutBorder:screenSize];
    
    return CGRectMake((screenSize.width  - rectSize.width ) / 2.0f,
                      (screenSize.height - rectSize.height) / 2.0f,
                      rectSize.width,
                      rectSize.height);
}

- (CGSize)brickSizeWithScreenSize:(CGSize)screenSize {
    return CGSizeMake((int)(screenSize.width  / self.gridSize.width),
                      (int)(screenSize.height / self.gridSize.height));
}

- (CGRect)gridRectWithBrickSize:(CGSize)brickSize screenSize:(CGSize)screenSize {
    CGSize rectSize = CGSizeMake(brickSize.width  * self.gridSize.width,
                                 brickSize.height * self.gridSize.height);
    
    return CGRectMake((screenSize.width  - rectSize.width ) / 2.0f,
                      (screenSize.height - rectSize.height) / 2.0f,
                      rectSize.width,
                      rectSize.height);
}

- (CGSize)screenSizeWithoutBorder:(CGSize)screenSize {
    CGSize borderSize = CGSizeMake(0.0f, 0.0f);
    if (self.borderEnabled) {
        borderSize = CGSizeMake(screenSize.width  * [Constants instance].borderRecognizedSizePct.width,
                                screenSize.height * [Constants instance].borderRecognizedSizePct.height);
    }
    
    return CGSizeMake(screenSize.width  - (borderSize.width  * 2.0f),
                      screenSize.height - (borderSize.height * 2.0f));
}

@end
