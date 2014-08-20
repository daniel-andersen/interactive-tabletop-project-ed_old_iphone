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
- (MazeEntry *)entryAtPosition:(cv::Point2i)position;

- (cv::Point2i)positionOfPlayer:(int)player;
- (cv::Point2i)positionOfTreasure;

- (MazeEntry *)entryForPlayer:(int)player;

- (bool)isPlayerEnabled:(int)player;

- (NSArray *)reachableEntriesForPlayer:(int)player;
- (NSArray *)reachableEntriesForPlayer:(int)player reachDistance:(int)reachDistance;

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

@property (nonatomic, assign) int playerReachDistance;

@property (nonatomic, assign) int currentPlayer;

@end
