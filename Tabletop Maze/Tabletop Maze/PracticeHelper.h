//
//  PracticeHelper.h
//  Tabletop Maze
//
//  Created by Daniel Andersen on 27/08/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PracticeHelper : NSObject

+ (PracticeHelper *)instance;

- (cv::Point2i)positionOfPlayer:(int)player;
- (cv::vector<cv::Point2i>)validPositionsForPlayer:(int)player;

- (void)updatePractice;

- (UIImage *)currentImage;

@property (nonatomic, assign) bool enabled;
@property (nonatomic, assign) int imageCount;
@property (nonatomic, assign) int currentImageNumber;
@property (nonatomic, assign) bool placePlayers;

@end
