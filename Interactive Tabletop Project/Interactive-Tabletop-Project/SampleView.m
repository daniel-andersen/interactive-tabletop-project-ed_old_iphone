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

#import "SampleView.h"

@interface SampleView ()

@property (nonatomic, strong) UIView *leftBorderView;
@property (nonatomic, strong) UIView *rightBorderView;
@property (nonatomic, strong) UIView *topBorderView;
@property (nonatomic, strong) UIView *bottomBorderView;

@end

@implementation SampleView

- (id)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor redColor];

        self.leftBorderView = [[UIView alloc] init];
        self.leftBorderView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.leftBorderView];
        
        self.rightBorderView = [[UIView alloc] init];
        self.rightBorderView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.rightBorderView];

        self.topBorderView = [[UIView alloc] init];
        self.topBorderView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.topBorderView];

        self.bottomBorderView = [[UIView alloc] init];
        self.bottomBorderView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.bottomBorderView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    float borderSize = 6.0f;

    self.leftBorderView.frame = CGRectMake(1.0f, 1.0f, borderSize, self.frame.size.height - 2.0f);
    self.rightBorderView.frame = CGRectMake(self.frame.size.width - borderSize - 1.0f, 1.0f, borderSize, self.frame.size.height - 2.0f);
    self.topBorderView.frame = CGRectMake(1.0f, 1.0f, self.frame.size.width - 2.0f, borderSize);
    self.bottomBorderView.frame = CGRectMake(1.0f, self.frame.size.height - borderSize - 1.0f, self.frame.size.width - 2.0f, borderSize);
}

- (void)update {
    
}

@end
