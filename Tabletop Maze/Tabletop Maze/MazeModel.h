//
//  MazeModel.h
//  Tabletop Maze
//
//  Created by Daniel Andersen on 08/06/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BORDER_NONE  (0 << 1)
#define BORDER_UP    (1 << 1)
#define BORDER_RIGHT (1 << 2)
#define BORDER_DOWN  (1 << 3)
#define BORDER_LEFT  (1 << 4)

@interface MazeEntry : NSObject

- (id)initWithPosition:(CGPoint)p;

- (bool)hasBorder:(int)borderMask;
- (void)addBorder:(int)borderMask;
- (void)removeBorder:(int)borderMask;

@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;

@property (nonatomic, assign) cv::Point2i position;

@property (nonatomic, assign) int borderMask;

@property (nonatomic, strong) NSMutableDictionary *bag;

@end



@interface MazeModel : NSObject

+ (MazeModel *)instance;

- (void)createRandomMaze;

- (MazeEntry *)entryAtX:(int)x y:(int)y;

- (cv::Point2i)positionOfPlayer:(int)player;
- (cv::Point2i)positionOfTreasure;

- (NSArray *)reachableEntriesForPlayer:(int)player;

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int playerReachDistance;

@end
