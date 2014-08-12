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
    self.borderSizePct = CGSizeMake(0.02f, 0.02f);
}

- (void)recalculateConstants {
    CGSize screenSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGSize cameraCaptureSize = CGSizeMake(640.0f, 480.0f); // TODO! Hardcoded camera capture size!
    
    self.brickSize = [self brickSizeWithScreenSize:[ExternalDisplay instance].widescreenBounds.size];
    self.brickScreenSize = [self brickSizeWithScreenSize:screenSize];
    self.brickCameraSize = [self brickSizeWithScreenSize:cameraCaptureSize];

    self.gridRect = [self gridRectWithBrickSize:self.brickSize screenSize:[ExternalDisplay instance].widescreenBounds.size];
    self.gridScreenRect = [self gridRectWithBrickSize:self.brickScreenSize screenSize:screenSize];
    self.gridCameraRect = [self gridRectWithBrickSize:self.brickCameraSize screenSize:cameraCaptureSize];
}

- (CGSize)brickSizeWithScreenSize:(CGSize)screenSize {
    return CGSizeMake((int)(screenSize.width  / self.gridSize.width),
                      (int)(screenSize.height / self.gridSize.height));
}

- (CGRect)gridRectWithBrickSize:(CGSize)brickSize screenSize:(CGSize)screenSize {
    CGSize rectSize = CGSizeMake(brickSize.width * self.gridSize.width, brickSize.height * self.gridSize.height);
    return CGRectMake((screenSize.width  - rectSize.width ) / 2.0f,
                      (screenSize.height - rectSize.height) / 2.0f,
                      rectSize.width,
                      rectSize.height);
}

@end
