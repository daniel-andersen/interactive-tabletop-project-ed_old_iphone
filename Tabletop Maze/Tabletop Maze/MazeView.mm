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

#import "MazeView.h"
#import "MazeModel.h"
#import "Constants.h"
#import "Util.h"

#define BRICK_TYPE_COUNT 6

@interface MazeView ()

@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *mazeImageView;

@property (nonatomic, strong) CALayer *mazeMask;

@property (nonatomic, assign) CGSize borderSize;

@end

@implementation MazeView

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];

    self.mazeImageView = [[UIImageView alloc] initWithFrame:[Constants instance].gridRect];
    self.mazeImageView.contentMode = UIViewContentModeScaleToFill;
    self.mazeImageView.alpha = 0.0f;
    [self addSubview:self.mazeImageView];

    self.titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Title"]];
    self.titleImageView.frame = self.bounds;
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.titleImageView.alpha = 0.0f;
    [self addSubview:self.titleImageView];
    
    self.borderSize = CGSizeMake(2.0f, 2.0f);

    self.mazeMask = [CALayer layer];
    self.mazeMask.anchorPoint = CGPointMake(0.0f, 0.0f);
    self.mazeMask.bounds = self.mazeImageView.bounds;
    self.mazeImageView.layer.mask = self.mazeMask;
}

- (void)didAppear {
    [super didAppear];
    [UIView animateWithDuration:1.0f animations:^{
        self.titleImageView.alpha = 1.0f;
    }];
}

- (void)update {
}

- (void)drawMaze {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, self.bounds);

    // Draw tiles
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            int type = [Util randomIntFrom:0 to:BRICK_TYPE_COUNT];
            UIImage *tileImage = [UIImage imageNamed:[NSString stringWithFormat:@"Brick %i", type + 1]];
            MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
            CGContextDrawImage(context, [self rectForEntry:entry], tileImage.CGImage);
        }
    }
    
    // Draw walls
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
            [self drawWallForEntry:entry withContext:context];
        }
    }
    
    self.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)drawMask {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.0f].CGColor);
    CGContextFillRect(context, self.bounds);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    self.mazeMask.contents = (id)image.CGImage;
    UIGraphicsEndImageContext();
}

- (void)drawWallForEntry:(MazeEntry *)entry withContext:(CGContextRef)context {
    MazeEntry *leftEntry = [[MazeModel instance] entryAtX:(entry.x - 1) y:entry.y];
    MazeEntry *rightEntry = [[MazeModel instance] entryAtX:(entry.x + 1) y:entry.y];
    MazeEntry *upEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y - 1)];
    MazeEntry *downEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y + 1)];
    
    bool brickBorders[3][3];
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            brickBorders[i][j] = NO;
        }
    }
    
    // Left
    if ([entry hasBorder:BORDER_LEFT]) {
        brickBorders[0][0] = YES;
        brickBorders[1][0] = YES;
        brickBorders[2][0] = YES;
    }
    
    // Right
    if ([entry hasBorder:BORDER_RIGHT]) {
        brickBorders[0][2] = YES;
        brickBorders[1][2] = YES;
        brickBorders[2][2] = YES;
    }

    // Top
    if ([entry hasBorder:BORDER_UP]) {
        brickBorders[0][0] = YES;
        brickBorders[0][1] = YES;
        brickBorders[0][2] = YES;
    }

    // Bottom
    if ([entry hasBorder:BORDER_DOWN]) {
        brickBorders[2][0] = YES;
        brickBorders[2][1] = YES;
        brickBorders[2][2] = YES;
    }
    
    // Corner left/top
    if ([leftEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_LEFT]) {
        brickBorders[0][0] = YES;
    }

    // Corner right/top
    if ([rightEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_RIGHT]) {
        brickBorders[0][2] = YES;
    }

    // Corner left/bottom
    if ([leftEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_LEFT]) {
        brickBorders[2][0] = YES;
    }
    
    // Corner right/bottom
    if ([rightEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_RIGHT]) {
        brickBorders[2][2] = YES;
    }
    
    // Draw borders
    CGRect brickRect = [self rectForEntry:entry];

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (!brickBorders[i][j] || (i == 1 && j == 1)) {
                continue;
            }
            CGRect borderRect = [self rectForBorderAtX:j y:i brickRect:brickRect];
            borderRect.origin.x -= 1.0f;
            borderRect.origin.y -= 1.0f;
            borderRect.size.width += 2.0f;
            borderRect.size.height += 2.0f;
            
            borderRect = CGRectIntersection(borderRect, brickRect);

            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextFillRect(context, borderRect);
        }
    }

    // Draw filling
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (!brickBorders[i][j] || (i == 1 && j == 1)) {
                continue;
            }
            CGRect borderRect = [self rectForBorderAtX:j y:i brickRect:brickRect];
            borderRect = CGRectIntersection(borderRect, brickRect);
            
            CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillRect(context, borderRect);
        }
    }
}

- (CGRect)rectForBorderAtX:(int)x y:(int)y brickRect:(CGRect)brickRect {
    return CGRectMake(brickRect.origin.x + (x == 0 ? 0.0f : (x == 2 ? brickRect.size.width - self.borderSize.width : self.borderSize.width)),
                      brickRect.origin.y + (y == 0 ? 0.0f : (y == 2 ? brickRect.size.height - self.borderSize.height : self.borderSize.height)),
                      x == 0 || x == 2 ? self.borderSize.width : (brickRect.size.width - (self.borderSize.width * 2.0f)),
                      y == 0 || y == 2 ? self.borderSize.height : (brickRect.size.height - (self.borderSize.height * 2.0f)));
}

- (CGRect)rectForEntry:(MazeEntry *)entry {
    return CGRectMake(entry.x * [Constants instance].brickSize.width,
                      entry.y * [Constants instance].brickSize.height,
                      [Constants instance].brickSize.width,
                      [Constants instance].brickSize.height);
}

- (void)showMaze {
    [UIView animateWithDuration:1.0f animations:^{
        self.mazeImageView.alpha = 1.0f;
    }];
}

@end
