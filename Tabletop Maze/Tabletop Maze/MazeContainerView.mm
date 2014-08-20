//
//  MazeContainerView.m
//  Tabletop Maze
//
//  Created by Daniel Andersen on 20/08/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import "MazeContainerView.h"
#import "Constants.h"

@implementation MazeContainerView

- (id)init {
    if (self = [super initWithFrame:[Constants instance].gridRect]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    self.alpha = 0.0f;
    
    self.mazeImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.mazeImageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:self.mazeImageView];

    self.maskLayer = [CALayer layer];
    self.maskLayer.anchorPoint = CGPointMake(0.0f, 0.0f);
    self.maskLayer.bounds = self.mazeImageView.bounds;
    self.mazeImageView.layer.mask = self.maskLayer;
}

@end
