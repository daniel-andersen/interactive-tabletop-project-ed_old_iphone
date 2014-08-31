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

#include <vector>

#import "MazeModel.h"
#import "MazeConstants.h"
#import "Util.h"

MazeModel *mazeModelInstance = nil;

enum Direction {
    UP,
    LEFT,
    RIGHT,
    DOWN
};

@interface MazeModel () {
    cv::Point2i playerPosition[MAX_PLAYERS];
    bool playerEnabled[MAX_PLAYERS];
}

@property (nonatomic, strong) NSMutableArray *maze;

@property (nonatomic, strong) NSMutableArray *unvisitedEntries;

@property (nonatomic, assign) int granularity;
@property (nonatomic, assign) int wallMinLength;
@property (nonatomic, assign) int wallMaxLength;

@end

@implementation MazeModel

+ (MazeModel *)instance {
    @synchronized (self) {
        if (mazeModelInstance == nil) {
            mazeModelInstance = [[MazeModel alloc] init];
        }
        return mazeModelInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.playerReachDistance = 4;
    self.currentPlayer = -1;

    self.width = 30;
    self.height = 20;

    self.granularity = 2;
    self.wallMinLength = 2;
    self.wallMaxLength = 3;
}

- (void)createRandomMaze {
    for (int i = 0; i < 10; i++) {
        NSLog(@"Creating random maze with size %ix%i", self.width, self.height);
        [self resetMaze];
        [self placePlayers];
        [self createWalls];
        
        NSLog(@"Placing treasure");
        [self resetMazeBags];
        [self placeTreasure];
        if (self.treasurePosition.x == -1) {
            NSLog(@"Failed placing treasure!");
            continue;
        }
        
        NSLog(@"Generated maze!");
        [self resetMazeBags];
        return;
    }
}

- (void)createWalls {
    int numberOfWalls = (self.width * 2 / 3) * self.height;
    for (int i = 0; i < numberOfWalls; i++) {
        [self attemptWallStart];
    }
    for (int i = 0; i < MAX_PLAYERS; i++) {
        [self entryForPlayer:i].type = HALLWAY;
    }
}

- (void)placeTreasure {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        [self createPlayerDistanceMapForPlayer:i];
    }
    self.treasurePosition = cv::Point2i(-1, -1);
    int bestScore = 10000;
    for (int i = 0; i < self.height; i++) {
        for (int j = 0; j < self.width; j++) {
            MazeEntry *entry = [self entryAtX:j y:i];
            if (entry.type == WALL) {
                continue;
            }
            int minDistance = 100000;
            int maxDistance = 0;
            for (int k = 0; k < MAX_PLAYERS; k++) {
                NSString *bagKey = [NSString stringWithFormat:@"distanceFromPlayer%i", k];
                NSNumber *distance = [entry.bag objectForKey:bagKey];
                if (distance != nil) {
                    minDistance = MIN(minDistance, distance.intValue);
                    maxDistance = MAX(maxDistance, distance.intValue);
                } else {
                    maxDistance = -1;
                    break;
                }
            }
            if (maxDistance == -1) {
                continue;
            }
            int score = maxDistance - minDistance;
            if (score < bestScore) {
                self.treasurePosition = entry.position;
                bestScore = score;
            }
        }
    }
}

- (void)createPlayerDistanceMapForPlayer:(int)player {
    self.unvisitedEntries = [NSMutableArray array];
    
    NSString *bagKey = [NSString stringWithFormat:@"distanceFromPlayer%i", player];
    
    MazeEntry *playerEntry = [self entryForPlayer:player];
    [playerEntry.bag setObject:[NSNumber numberWithInt:0] forKey:bagKey];
    
    [self.unvisitedEntries addObject:playerEntry];
    for (int i = 0; i < self.unvisitedEntries.count; i++) {
        [self updatePlayerDistanceMapFromEntry:[self.unvisitedEntries objectAtIndex:i] bagKey:bagKey];
    }
}

- (void)placePlayers {
    playerPosition[0] = cv::Point2i(1, 1);
    playerPosition[1] = cv::Point2i(self.width - 2, 1);
    playerPosition[2] = cv::Point2i(1, self.height - 2);
    playerPosition[3] = cv::Point2i(self.width - 2, self.height - 2);
}

- (NSArray *)reachableEntriesForPlayer:(int)player {
    return [self reachableEntriesForPlayer:player reachDistance:self.playerReachDistance];
}

- (NSArray *)reachableEntriesForPlayer:(int)player reachDistance:(int)reachDistance {
    [self resetMazeBags];

    [self recursivelyFindPlayerDistanceFromEntry:[self entryAtX:playerPosition[player].x y:playerPosition[player].y] distanceFromPlayer:0 reachDistance:reachDistance];
    
    NSMutableArray *reachableEntries = [NSMutableArray array];
    for (int i = 0; i < self.height; i++) {
        for (int j = 0; j < self.width; j++) {
            MazeEntry *entry = [self entryAtX:j y:i];
            bool valid = YES;
            for (int k = 0; k < MAX_PLAYERS; k++) {
                if (player != k && [self isPlayerEnabled:k] && [self positionOfPlayer:k] == entry.position) {
                    valid = NO;
                }
            }
            if (!valid) {
                continue;
            }
            NSNumber *distanceFromPlayer = [entry.bag objectForKey:@"distanceFromPlayer"];
            if (distanceFromPlayer != nil && distanceFromPlayer.intValue <= reachDistance) {
                [reachableEntries addObject:entry];
            }
        }
    }
    return reachableEntries;
}

- (void)recursivelyFindPlayerDistanceFromEntry:(MazeEntry *)entry distanceFromPlayer:(int)distanceFromPlayer reachDistance:(int)reachDistance {
    if (entry == nil || distanceFromPlayer > reachDistance) {
        return;
    }
    NSNumber *currentEntryDistanceFromPlayer = [entry.bag objectForKey:@"distanceFromPlayer"];
    if (currentEntryDistanceFromPlayer != nil && currentEntryDistanceFromPlayer.intValue < distanceFromPlayer) {
        return;
    }
    [entry.bag setObject:[NSNumber numberWithInt:distanceFromPlayer] forKey:@"distanceFromPlayer"];
    MazeEntry *leftEntry = [self entryAtX:(entry.x - 1) y:entry.y];
    if (leftEntry.type == HALLWAY) {
        [self recursivelyFindPlayerDistanceFromEntry:leftEntry distanceFromPlayer:(distanceFromPlayer + 1) reachDistance:reachDistance];
    }
    MazeEntry *rightEntry = [self entryAtX:(entry.x + 1) y:entry.y];
    if (rightEntry.type == HALLWAY) {
        [self recursivelyFindPlayerDistanceFromEntry:rightEntry distanceFromPlayer:(distanceFromPlayer + 1) reachDistance:reachDistance];
    }
    MazeEntry *upEntry = [self entryAtX:entry.x y:(entry.y - 1)];
    if (upEntry.type == HALLWAY) {
        [self recursivelyFindPlayerDistanceFromEntry:upEntry distanceFromPlayer:(distanceFromPlayer + 1) reachDistance:reachDistance];
    }
    MazeEntry *downEntry = [self entryAtX:entry.x y:(entry.y + 1)];
    if (downEntry.type == HALLWAY) {
        [self recursivelyFindPlayerDistanceFromEntry:downEntry distanceFromPlayer:(distanceFromPlayer + 1) reachDistance:reachDistance];
    }
}

- (void)updatePlayerDistanceMapFromEntry:(MazeEntry *)entry bagKey:(NSString *)bagKey {
    if (entry == nil || entry.type == WALL) {
        return;
    }
    NSNumber *distanceFromStart = [entry.bag objectForKey:bagKey];
    
    MazeEntry *leftEntry = [self entryAtX:(entry.x - 1) y:entry.y];
    if (leftEntry != nil && leftEntry.type == HALLWAY) {
        NSNumber *distance = [leftEntry.bag objectForKey:bagKey];
        if (distance == nil) {
            [leftEntry.bag setObject:[NSNumber numberWithInt:(distanceFromStart.intValue + 1)] forKey:bagKey];
            [self.unvisitedEntries addObject:leftEntry];
        }
    }
    MazeEntry *rightEntry = [self entryAtX:(entry.x + 1) y:entry.y];
    if (rightEntry != nil && rightEntry.type == HALLWAY) {
        NSNumber *distance = [rightEntry.bag objectForKey:bagKey];
        if (distance == nil) {
            [rightEntry.bag setObject:[NSNumber numberWithInt:(distanceFromStart.intValue + 1)] forKey:bagKey];
            [self.unvisitedEntries addObject:rightEntry];
        }
    }
    MazeEntry *upEntry = [self entryAtX:entry.x y:(entry.y - 1)];
    if (upEntry != nil && upEntry.type == HALLWAY) {
        NSNumber *distance = [upEntry.bag objectForKey:bagKey];
        if (distance == nil) {
            [upEntry.bag setObject:[NSNumber numberWithInt:(distanceFromStart.intValue + 1)] forKey:bagKey];
            [self.unvisitedEntries addObject:upEntry];
        }
    }
    MazeEntry *downEntry = [self entryAtX:entry.x y:(entry.y + 1)];
    if (downEntry != nil && downEntry.type == HALLWAY) {
        NSNumber *distance = [downEntry.bag objectForKey:bagKey];
        if (distance == nil) {
            [downEntry.bag setObject:[NSNumber numberWithInt:(distanceFromStart.intValue + 1)] forKey:bagKey];
            [self.unvisitedEntries addObject:downEntry];
        }
    }
}

- (void)createWallFromPosition:(cv::Point2i)position direction:(Direction)dir length:(int)len {
    int stepX = dir == LEFT ? -1 : (dir == RIGHT ? 1 : 0);
    int stepY = dir == UP   ? -1 : (dir == DOWN  ? 1 : 0);
    
    for (int i = 0; i < len; i++) {
        MazeEntry *entry = [self entryAtPosition:position];
        if (entry.type == WALL) {
            return;
        }
        entry.type = WALL;
        position.x += stepX;
        position.y += stepY;
    }
}

- (void)attemptWallStart {
    [self attemptWallStartAtPosition:[self randomWallStart]];
}

- (void)attemptWallStartAtPosition:(cv::Point2i)startPosition {
    MazeEntry *startEntry = [self entryAtPosition:startPosition];
    if (startEntry.type == WALL) {
        return;
    }
    Direction direction = (Direction)[Util randomIntFrom:0 to:4];
    int length = ([Util randomIntFrom:self.wallMinLength to:(self.wallMaxLength + 1)] * self.granularity) + 1;
    [self createWallFromPosition:startPosition direction:direction length:length];
}

- (cv::Point2i)randomWallStart {
    return cv::Point2i([Util randomIntFrom:0 to:(self.width  / self.granularity)] * self.granularity,
                       [Util randomIntFrom:0 to:(self.height / self.granularity)] * self.granularity);
}

- (NSArray *)unvisitedNeighboursFromEntry:(MazeEntry *)entry {
    NSMutableArray *entries = [NSMutableArray array];
    MazeEntry *upEntry = [self entryAtX:entry.x y:(entry.y - 1)];
    if (upEntry != nil && [self.unvisitedEntries containsObject:upEntry]) {
        [entries addObject:upEntry];
    }
    MazeEntry *downEntry = [self entryAtX:entry.x y:(entry.y + 1)];
    if (downEntry != nil && [self.unvisitedEntries containsObject:downEntry]) {
        [entries addObject:downEntry];
    }
    MazeEntry *leftEntry = [self entryAtX:(entry.x - 1) y:entry.y];
    if (leftEntry != nil && [self.unvisitedEntries containsObject:leftEntry]) {
        [entries addObject:leftEntry];
    }
    MazeEntry *rightEntry = [self entryAtX:(entry.x + 1) y:entry.y];
    if (rightEntry != nil && [self.unvisitedEntries containsObject:rightEntry]) {
        [entries addObject:rightEntry];
    }
    return entries;
}

- (void)resetMazeBags {
    for (int i = 0; i < self.height; i++) {
        for (int j = 0; j < self.width; j++) {
            [[self entryAtX:j y:i].bag removeAllObjects];
        }
    }
}

- (void)resetMaze {
    self.maze = [NSMutableArray array];

    for (int i = 0; i < self.height; i++) {
        NSMutableArray *columnArray = [NSMutableArray array];
        for (int j = 0; j < self.width; j++) {
            MazeEntry *mazeEntry = [[MazeEntry alloc] initWithPosition:CGPointMake(j, i)];
            [mazeEntry.bag setObject:[NSNumber numberWithBool:NO] forKey:@"visited"];
            [columnArray addObject:mazeEntry];
            
            [self.unvisitedEntries addObject:mazeEntry];
            
            mazeEntry.type = i == 0 || i == self.height - 1 || j == 0 || j == self.width - 1 ? WALL : HALLWAY;
        }
        [self.maze addObject:columnArray];
    }
}

- (MazeEntry *)entryAtX:(int)x y:(int)y {
    if (x < 0 || y < 0 || x >= self.width || y >= self.height) {
        return nil;
    }
    NSArray *columnArray = [self.maze objectAtIndex:y];
    return [columnArray objectAtIndex:x];
}

- (MazeEntry *)entryAtPosition:(cv::Point2i)position {
    return [self entryAtX:position.x y:position.y];
}

- (void)setPositionOfPlayer:(int)player position:(cv::Point2i)position {
    playerPosition[player] = position;
}

- (cv::Point2i)positionOfPlayer:(int)player {
    return playerPosition[player];
}

- (MazeEntry *)entryForPlayer:(int)player {
    return [self entryAtPosition:[self positionOfPlayer:player]];
}

- (void)disablePlayer:(int)player {
    playerEnabled[player] = NO;
}

- (void)enablePlayer:(int)player {
    playerEnabled[player] = YES;
}

- (bool)isPlayerEnabled:(int)player {
    return playerEnabled[player];
}

@end



@implementation MazeEntry

- (id)initWithPosition:(CGPoint)p {
    if (self = [super init]) {
        self.x = (int)p.x;
        self.y = (int)p.y;
        self.type = HALLWAY;
        self.bag = [NSMutableDictionary dictionary];
    }
    return self;
}

- (cv::Point2i)position {
    return cv::Point2i(self.x, self.y);
}

@end
