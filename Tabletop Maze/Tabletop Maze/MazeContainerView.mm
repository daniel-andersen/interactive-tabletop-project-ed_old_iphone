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

#import "MazeContainerView.h"
#import "Constants.h"
#import "MazeConstants.h"

@implementation MazeContainerView

- (id)init {
    if (self = [super initWithFrame:[Constants instance].gridRect]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    
    self.mazeImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.mazeImageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:self.mazeImageView];

    self.maskLayer = [CALayer layer];
    self.maskLayer.anchorPoint = CGPointMake(0.0f, 0.0f);
    self.maskLayer.bounds = self.mazeImageView.bounds;
    self.mazeImageView.layer.mask = self.maskLayer;

    self.dragonImageViews = [NSMutableArray array];
    for (int i = 0; i < MAX_DRAGONS; i++) {
        UIImageView *dragonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Dragon"]];
        dragonImageView.contentMode = UIViewContentModeScaleAspectFit;
        dragonImageView.alpha = 0.0f;
        [self addSubview:dragonImageView];
        [self.dragonImageViews addObject:dragonImageView];
    }
}

@end
