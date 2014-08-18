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

#import "TabletopBorderView.h"
#import "ExternalDisplay.h"
#import "Constants.h"

enum BorderViewImageIndex {
    topLeft = 0,
    top = 1,
    topRight = 2,
    right = 3,
    bottomRight = 4,
    bottom = 5,
    bottomLeft = 6,
    left = 7
};

@interface TabletopBorderView ()

@property (nonatomic, strong) NSArray *borderImages;

@end

@implementation TabletopBorderView

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (id)initWithImages:(NSArray *)images {
    if (self = [super init]) {
        self.borderImages = images;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    self.frame = [ExternalDisplay instance].widescreenBounds;

    if (self.borderImages != nil) {
        [self drawImageBorder];
    } else {
        [self drawSolidBorder];
    }
}

- (void)drawImageBorder {
    CGSize borderSize = CGSizeMake(self.bounds.size.width  * [Constants instance].borderRecognizedSizePct.width  * [Constants instance].borderViewSizePct.width,
                                   self.bounds.size.height * [Constants instance].borderRecognizedSizePct.height * [Constants instance].borderViewSizePct.height);

    UIImage *topLeftImage = [self borderImageWithIndex:topLeft];
    UIImage *topImage = [self borderImageWithIndex:top];
    UIImage *topRightImage = [self borderImageWithIndex:topRight];
    UIImage *rightImage = [self borderImageWithIndex:right];
    UIImage *bottomRightImage = [self borderImageWithIndex:bottomRight];
    UIImage *bottomImage = [self borderImageWithIndex:bottom];
    UIImage *bottomLeftImage = [self borderImageWithIndex:bottomLeft];
    UIImage *leftImage = [self borderImageWithIndex:left];

    CGSize topImageSize = [self sizeOfImage:topImage scaledToHeight:borderSize.height];
    CGSize bottomImageSize = [self sizeOfImage:bottomImage scaledToHeight:borderSize.height];
    CGSize leftImageSize = [self sizeOfImage:leftImage scaledToWidth:borderSize.width];
    CGSize rightImageSize = [self sizeOfImage:rightImage scaledToWidth:borderSize.width];

    CGSize topLeftImageSize = CGSizeMake(leftImageSize.width, topImageSize.height);
    CGSize topRightImageSize = CGSizeMake(rightImageSize.width, topImageSize.height);
    CGSize bottomLeftImageSize = CGSizeMake(leftImageSize.width, bottomImageSize.height);
    CGSize bottomRightImageSize = CGSizeMake(rightImageSize.width, bottomImageSize.height);
    
    int countTop = (int)(self.frame.size.width - topLeftImageSize.width - topRightImageSize.width) / (int)topImageSize.width;
    int countBottom = (int)(self.frame.size.width - bottomLeftImageSize.width - bottomRightImageSize.width) / (int)bottomImageSize.width;
    int countLeft = (int)(self.frame.size.height - topLeftImageSize.height - bottomLeftImageSize.height) / (int)leftImageSize.height;
    int countRight = (int)(self.frame.size.height - topRightImageSize.height - bottomRightImageSize.height) / (int)rightImageSize.height;
    
    float topImageWidth = (self.frame.size.width - topLeftImageSize.width - topRightImageSize.width) / countTop;
    float bottomImageWidth = (self.frame.size.width - bottomLeftImageSize.width - bottomRightImageSize.width) / countBottom;
    float leftImageHeight = (self.frame.size.height - topLeftImageSize.height - bottomLeftImageSize.height) / countLeft;
    float rightImageHeight = (self.frame.size.height - topRightImageSize.height - bottomRightImageSize.height) / countRight;
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0f);

    [topLeftImage drawInRect:CGRectMake(0.0f, 0.0f, topLeftImageSize.width + 1.0f, topLeftImageSize.height + 1.0f)];
    [topRightImage drawInRect:CGRectMake(self.bounds.size.width - topRightImageSize.width, 0.0f, topRightImageSize.width + 1.0f, topRightImageSize.height + 1.0f)];
    [bottomLeftImage drawInRect:CGRectMake(0.0f, self.bounds.size.height - bottomLeftImageSize.height, bottomLeftImageSize.width + 1.0f, bottomLeftImageSize.height + 1.0f)];
    [bottomRightImage drawInRect:CGRectMake(self.bounds.size.width - bottomRightImageSize.width, self.bounds.size.height - bottomRightImageSize.height, bottomRightImageSize.width + 1.0f, bottomRightImageSize.height + 1.0f)];

    for (int i = 0; i < countTop; i++) {
        [topImage drawInRect:CGRectMake(topLeftImageSize.width + (i * topImageWidth), 0.0f, topImageWidth + 1.0f, topImageSize.height + 1.0f)];
    }
    for (int i = 0; i < countBottom; i++) {
        [bottomImage drawInRect:CGRectMake(bottomLeftImageSize.width + (i * bottomImageWidth), self.bounds.size.height - bottomImageSize.height, bottomImageWidth + 1.0f, bottomImageSize.height + 1.0f)];
    }
    for (int i = 0; i < countLeft; i++) {
        [leftImage drawInRect:CGRectMake(0.0f, topLeftImageSize.height + (i * leftImageHeight), leftImageSize.width + 1.0f, leftImageHeight + 1.0f)];
    }
    for (int i = 0; i < countRight; i++) {
        [rightImage drawInRect:CGRectMake(self.bounds.size.width - rightImageSize.width, topRightImageSize.height + (i * rightImageHeight), rightImageSize.width + 1.0f, rightImageHeight + 1.0f)];
    }

    self.layer.contents = (id)UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIGraphicsEndImageContext();
}

- (UIImage *)borderImageWithIndex:(enum BorderViewImageIndex)index {
    return [self.borderImages objectAtIndex:index];
}

- (void)drawSolidBorder {
    
}

- (CGSize)sizeOfImage:(UIImage *)image scaledToWidth:(float)width {
    return CGSizeMake(width, image.size.height * width / image.size.width);
}

- (CGSize)sizeOfImage:(UIImage *)image scaledToHeight:(float)height {
    return CGSizeMake(image.size.width * height / image.size.height, height);
}

@end
