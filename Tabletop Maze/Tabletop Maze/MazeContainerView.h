//
//  MazeContainerView.h
//  Tabletop Maze
//
//  Created by Daniel Andersen on 20/08/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MazeContainerView : UIView

@property (nonatomic, strong) UIImageView *mazeImageView;
@property (nonatomic, strong) CALayer *maskLayer;

@end
