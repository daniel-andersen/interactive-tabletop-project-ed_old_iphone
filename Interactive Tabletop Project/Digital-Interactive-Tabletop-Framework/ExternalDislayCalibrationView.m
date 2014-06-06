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

#import <QuartzCore/QuartzCore.h>

#import "ExternalDislayCalibrationView.h"

@interface ExternalDislayCalibrationView ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIImageView *trollsaheadImageView;

@end

@implementation ExternalDislayCalibrationView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    
    [self showCalibrationBorder];
    [self showLogo];
}

- (void)showCalibrationBorder {
    [self addPixelAt:CGPointMake(0.0f, 0.0f)];
    [self addPixelAt:CGPointMake(self.bounds.size.width - 1.0f, 0.0f)];
    [self addPixelAt:CGPointMake(self.bounds.size.width - 1.0f, self.bounds.size.height - 1.0f)];
    [self addPixelAt:CGPointMake(0.0f, self.bounds.size.height - 1.0f)];
}

- (void)addPixelAt:(CGPoint)p {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(p.x, p.y, 1.0f, 1.0f)];
    view.backgroundColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
    [self addSubview:view];
}

- (void)showLogo {
    UIImage *logo = [UIImage imageNamed:@"splash_logo.png"];
    
    float aspectRatio = logo.size.height / logo.size.width;
    float logoWidth = self.bounds.size.width * 0.7f;
    float logoHeight = logoWidth * aspectRatio;
    
    self.logoImageView = [[UIImageView alloc] initWithImage:logo];
    self.logoImageView.frame = CGRectMake((self.bounds.size.width - logoWidth) / 2.0f, (self.bounds.size.height - logoHeight) / 2.0f, logoWidth, logoHeight);
    [self addSubview:self.logoImageView];
}

- (void)showTrollsAhead {
    UIImage *logo = [UIImage imageNamed:@"splash_trollsahead.png"];
    
    float aspectRatio = logo.size.height / logo.size.width;
    float logoWidth = self.bounds.size.width * 0.3f;
    float logoHeight = logoWidth * aspectRatio;
    
    self.trollsaheadImageView = [[UIImageView alloc] initWithImage:logo];
    self.trollsaheadImageView.frame = CGRectMake((self.bounds.size.width - logoWidth) / 2.0f, (self.bounds.size.height - logoHeight) / 2.0f, logoWidth, logoHeight);
    self.trollsaheadImageView.alpha = 0.0f;
    [self addSubview:self.trollsaheadImageView];
}

- (void)hideView {
    float fadeSpeed = 1.5f;
    
    [UIView animateWithDuration:fadeSpeed animations:^{
        self.logoImageView.alpha = 0.0f;
    } completion:^(BOOL finished) {

        [self.logoImageView removeFromSuperview];
        self.logoImageView = nil;

        [self showTrollsAhead];
        
        [UIView animateWithDuration:fadeSpeed animations:^{
            self.trollsaheadImageView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:fadeSpeed animations:^{
                self.trollsaheadImageView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self.trollsaheadImageView removeFromSuperview];
                self.trollsaheadImageView = nil;

                [self.delegate calibrationViewDidHide];
            }];
        }];
    }];
}

@end
