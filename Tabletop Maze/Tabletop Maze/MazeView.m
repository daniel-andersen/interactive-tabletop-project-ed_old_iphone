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

#define BRICK_TYPE_COUNT 6

@interface MazeView ()

@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *mazeImageView;

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
    
    self.mazeImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.mazeImageView.contentMode = UIViewContentModeScaleToFill;
    self.mazeImageView.alpha = 0.0f;
    [self addSubview:self.mazeImageView];

    self.titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Title"]];
    self.titleImageView.frame = self.bounds;
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.titleImageView.alpha = 0.0f;
    [self addSubview:self.titleImageView];
    
    self.borderSize = CGSizeMake(MAX(2.0f, [Constants instance].brickSize.width * 0.1f),
                                 MAX(2.0f, [Constants instance].brickSize.height * 0.1f));
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
            int type = rand() % BRICK_TYPE_COUNT;
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

- (void)drawWallForEntry:(MazeEntry *)entry withContext:(CGContextRef)context {
    CGRect rect = [self rectForEntry:entry];

    MazeEntry *leftEntry = [[MazeModel instance] entryAtX:(entry.x - 1) y:entry.y];
    MazeEntry *rightEntry = [[MazeModel instance] entryAtX:(entry.x + 1) y:entry.y];
    MazeEntry *upEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y - 1)];
    MazeEntry *downEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y + 1)];
    
    // Left
    if ([entry hasBorder:BORDER_LEFT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, self.borderSize.width, rect.size.height));
    }
    
    // Right
    if ([entry hasBorder:BORDER_RIGHT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x + rect.size.width - self.borderSize.width, rect.origin.y, self.borderSize.width, rect.size.height));
    }

    // Top
    if ([entry hasBorder:BORDER_UP]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, self.borderSize.height));
    }

    // Bottom
    if ([entry hasBorder:BORDER_DOWN]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - self.borderSize.height, rect.size.width, self.borderSize.height));
    }
    
    // Corner left/top
    if ([leftEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_LEFT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, self.borderSize.width, self.borderSize.height));
    }

    // Corner right/top
    if ([rightEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_RIGHT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x + rect.size.width - self.borderSize.width, rect.origin.y, self.borderSize.width, self.borderSize.height));
    }

    // Corner left/bottom
    if ([leftEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_LEFT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - self.borderSize.height, self.borderSize.width, self.borderSize.height));
    }
    
    // Corner right/bottom
    if ([rightEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_RIGHT]) {
        CGContextFillRect(context, CGRectMake(rect.origin.x + rect.size.width - self.borderSize.width, rect.origin.y + rect.size.height - self.borderSize.height, self.borderSize.width, self.borderSize.height));
    }
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
