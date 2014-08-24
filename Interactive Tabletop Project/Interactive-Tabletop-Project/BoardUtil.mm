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

#import "BoardUtil.h"
#import "ExternalDisplay.h"
#import "Constants.h"

BoardUtil *boardUtilInstance = nil;

@implementation BoardUtil

+ (BoardUtil *)instance {
    @synchronized(self) {
        if (boardUtilInstance == nil) {
            boardUtilInstance = [[BoardUtil alloc] init];
        }
        return boardUtilInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
}

- (CGRect)canvasRectWithScreenSize:(CGSize)screenSize {
    CGSize rectSize = [self screenSizeWithoutBorder:screenSize];
    
    return CGRectMake((screenSize.width  - rectSize.width ) / 2.0f,
                      (screenSize.height - rectSize.height) / 2.0f,
                      rectSize.width,
                      rectSize.height);
}

- (CGRect)gridRectWithBrickSize:(CGSize)brickSize canvasSize:(CGSize)canvasSize {
    CGSize rectSize = CGSizeMake(brickSize.width  * [Constants instance].gridSize.width,
                                 brickSize.height * [Constants instance].gridSize.height);
    
    return CGRectMake((canvasSize.width  - rectSize.width ) / 2.0f,
                      (canvasSize.height - rectSize.height) / 2.0f,
                      rectSize.width,
                      rectSize.height);
}

- (CGRect)gridRectWithCanvasSize:(CGSize)canvasSize {
    return CGRectMake(canvasSize.width  * [Constants instance].gridPaddingPercent.width,
                      canvasSize.height * [Constants instance].gridPaddingPercent.height,
                      canvasSize.width  * (1.0f - ([Constants instance].gridPaddingPercent.width  * 2.0f)),
                      canvasSize.height * (1.0f - ([Constants instance].gridPaddingPercent.height * 2.0f)));
}

- (CGSize)gridPaddingPercentFromCanvasSize:(CGSize)canvasSize gridSize:(CGSize)gridSize {
    return CGSizeMake((1.0f - (gridSize.width  / canvasSize.width )) / 2.0f,
                      (1.0f - (gridSize.height / canvasSize.height)) / 2.0f);
}

- (CGSize)brickSizeWithCanvasSize:(CGSize)canvasSize {
    return CGSizeMake((int)(canvasSize.width  / [Constants instance].gridSize.width),
                      (int)(canvasSize.height / [Constants instance].gridSize.height));
}

- (CGSize)brickSizeWithGridRect:(CGRect)gridRect {
    return CGSizeMake(gridRect.size.width  / [Constants instance].gridSize.width,
                      gridRect.size.height / [Constants instance].gridSize.height);
}

- (CGRect)brickRectWithPosition:(cv::Point)position screenSize:(CGSize)screenSize {
    CGRect canvasRect = [self canvasRectWithScreenSize:screenSize];
    CGRect gridRect = [self gridRectWithCanvasSize:canvasRect.size];
    CGSize brickSize = [[BoardUtil instance] brickSizeWithGridRect:gridRect];
    return CGRectMake(canvasRect.origin.x + gridRect.origin.x + (position.x * brickSize.width),
                      canvasRect.origin.y + gridRect.origin.y + (position.y * brickSize.height),
                      (int)brickSize.width,
                      (int)brickSize.height);
}

- (CGSize)screenSizeWithoutBorder:(CGSize)screenSize {
    CGSize borderSize = CGSizeMake(0.0f, 0.0f);
    if ([Constants instance].borderEnabled) {
        borderSize = CGSizeMake(screenSize.width  * ([Constants instance].borderViewSizePct.width + [Constants instance].borderPaddingSizePct.width),
                                screenSize.height * ([Constants instance].borderViewSizePct.height + [Constants instance].borderPaddingSizePct.height));
    }
    
    return CGSizeMake(screenSize.width  - (borderSize.width  * 2.0f),
                      screenSize.height - (borderSize.height * 2.0f));
}

@end
