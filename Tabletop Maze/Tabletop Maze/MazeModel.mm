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
    bool playerValid[MAX_PLAYERS];
}

@property (nonatomic, strong) NSMutableArray *maze;

@property (nonatomic, strong) NSMutableArray *backtrackingStack;
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
    self.wallMaxLength = 4;
}

- (void)createRandomMaze {
    for (int i = 0; i < 10; i++) {
        NSLog(@"Creating random maze with size %ix%i", self.width, self.height);
        [self resetMaze];
        [self createWalls];
        
        NSLog(@"Placing treasure and players");
        [self resetMazeBags];
        [self placeTreasure];
        [self placePlayers];
        
        int validPlayers = 0;
        for (int i = 0; i < MAX_PLAYERS; i++) {
            validPlayers += [self isPlayerValid:i] ? 1 : 0;
        }
        if (validPlayers < MAX_PLAYERS) {
            NSLog(@"Failed!");
            continue;
        }
        
        playerValid[2] = NO;
        
        NSLog(@"Generated maze!");
        [self resetMazeBags];
        return;
    }
}

- (void)createWalls {
    int numberOfWalls = (self.width / 2) * (self.height / 2);
    for (int i = 0; i < numberOfWalls; i++) {
        [self attemptWallStart];
    }
}

- (void)placeTreasure {
    for (int i = 0; i < 1000; i++) {
        int deltaX = self.width / 4;
        int deltaY = self.height / 4;
        
        self.treasurePosition = cv::Point2i([Util randomIntFrom:((self.width - deltaX) / 2) to:((self.width + deltaX) / 2)],
                                            [Util randomIntFrom:((self.height - deltaY) / 2) to:((self.height + deltaY) / 2)]);

        MazeEntry *entry = [self entryAtPosition:self.treasurePosition];
        if (entry.type == HALLWAY) {
            break;
        }
    }
}

- (void)placePlayers {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        playerValid[i] = YES;
    }
    [self recursivelyCreatePlayerPositionMapFromEntry:[self entryAtPosition:self.treasurePosition] distanceFromStart:0];
    [self findPlayerPositionsFromMap];
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

- (void)findPlayerPositionsFromMap {
    int maxBorderDistance[4];
    
    int verticalMargin = (int)((float)self.height * 0.25f);
    int horizontalMargin = (int)((float)self.width * 0.25f);
    
    // Left max distance
    for (int i = verticalMargin; i < self.height - verticalMargin; i++) {
        MazeEntry *entry = [self entryAtX:1 y:i];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[0] = MAX(maxBorderDistance[0], distanceFromStart.intValue);
        }
    }

    // Right max distance
    for (int i = verticalMargin; i < self.height - verticalMargin; i++) {
        MazeEntry *entry = [self entryAtX:(self.width - 2) y:i];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[1] = MAX(maxBorderDistance[1], distanceFromStart.intValue);
        }
    }

    // Top max distance
    for (int i = horizontalMargin; i < self.width - horizontalMargin; i++) {
        MazeEntry *entry = [self entryAtX:i y:1];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[2] = MAX(maxBorderDistance[2], distanceFromStart.intValue);
        }
    }

    // Bottom max distance
    for (int i = horizontalMargin; i < self.width - horizontalMargin; i++) {
        MazeEntry *entry = [self entryAtX:i y:(self.height - 2)];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[3] = MAX(maxBorderDistance[3], distanceFromStart.intValue);
        }
    }
    
    // Find minimum border distance per border
    int minBorderDistance = 1000000;
    for (int i = 0; i < 4; i++) {
        minBorderDistance = MIN(maxBorderDistance[i], minBorderDistance);
    }
    
    // Find nearest border location to minimum distance for all players
    MazeEntry *leftStartingEntry = nil;
    MazeEntry *rightStartingEntry = nil;
    for (int i = verticalMargin; i < self.height - verticalMargin; i++) {
        leftStartingEntry = [self updateBestStartingEntry:leftStartingEntry candidateEntry:[self entryAtX:1 y:i] targetDistanceFromStart:minBorderDistance];
        rightStartingEntry = [self updateBestStartingEntry:rightStartingEntry candidateEntry:[self entryAtX:(self.width - 2) y:i] targetDistanceFromStart:minBorderDistance];
    }

    MazeEntry *topStartingEntry = nil;
    MazeEntry *bottomStartingEntry = nil;
    for (int i = horizontalMargin; i < self.width - horizontalMargin; i++) {
        topStartingEntry = [self updateBestStartingEntry:topStartingEntry candidateEntry:[self entryAtX:i y:1] targetDistanceFromStart:minBorderDistance];
        bottomStartingEntry = [self updateBestStartingEntry:bottomStartingEntry candidateEntry:[self entryAtX:i y:(self.height - 2)] targetDistanceFromStart:minBorderDistance];
    }
    
    if ([leftStartingEntry.bag objectForKey:@"distanceFromStart"] != nil) {
        leftStartingEntry = [self entryAtPosition:cv::Point2i(leftStartingEntry.position.x - 1, leftStartingEntry.position.y)];
        leftStartingEntry.type = HALLWAY;
        playerPosition[0] = leftStartingEntry.position;
    } else {
        playerValid[0] = NO;
    }
    
    if ([rightStartingEntry.bag objectForKey:@"distanceFromStart"] != nil) {
        rightStartingEntry = [self entryAtPosition:cv::Point2i(rightStartingEntry.position.x + 1, rightStartingEntry.position.y)];
        rightStartingEntry.type = HALLWAY;
        playerPosition[1] = rightStartingEntry.position;
    } else {
        playerValid[1] = NO;
    }

    if ([topStartingEntry.bag objectForKey:@"distanceFromStart"] != nil) {
        topStartingEntry = [self entryAtPosition:cv::Point2i(topStartingEntry.position.x, topStartingEntry.position.y - 1)];
        topStartingEntry.type = HALLWAY;
        playerPosition[2] = topStartingEntry.position;
    } else {
        playerValid[2] = NO;
    }
    
    if ([bottomStartingEntry.bag objectForKey:@"distanceFromStart"] != nil) {
        bottomStartingEntry = [self entryAtPosition:cv::Point2i(bottomStartingEntry.position.x, bottomStartingEntry.position.y + 1)];
        bottomStartingEntry.type = HALLWAY;
        playerPosition[3] = bottomStartingEntry.position;
    } else {
        playerValid[3] = NO;
    }
}

- (MazeEntry *)updateBestStartingEntry:(MazeEntry *)currentEntry candidateEntry:(MazeEntry *)candidateEntry targetDistanceFromStart:(int)targetDistanceFromStart {
    if (currentEntry == nil || [currentEntry.bag objectForKey:@"distanceFromStart"] == nil) {
        return candidateEntry;
    }
    NSNumber *currentDistanceFromStart = [currentEntry.bag objectForKey:@"distanceFromStart"];
    NSNumber *candidateDistanceFromStart = [candidateEntry.bag objectForKey:@"distanceFromStart"];

    int currentDelta = ABS(targetDistanceFromStart - currentDistanceFromStart.intValue);
    int candidateDelta = ABS(targetDistanceFromStart - candidateDistanceFromStart.intValue);
    
    if (candidateDelta > currentDelta) {
        return currentEntry;
    }
    if (candidateDelta == currentDelta && [Util randomIntFrom:0 to:10] < 5) {
        return currentEntry;
    }
    return candidateEntry;
}

- (void)recursivelyCreatePlayerPositionMapFromEntry:(MazeEntry *)entry distanceFromStart:(int)newDistanceFromStart {
    if (entry == nil || [entry.bag objectForKey:@"visited"] != nil) {
        return;
    }
    [entry.bag setObject:[NSNumber numberWithBool:YES] forKey:@"visited"];

    NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
    if (distanceFromStart == nil || [distanceFromStart intValue] > newDistanceFromStart) {
        [entry.bag setObject:[NSNumber numberWithInt:newDistanceFromStart] forKey:@"distanceFromStart"];
    }
    distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];

    int nextDistanceFromStart = [distanceFromStart intValue] + 1;
    MazeEntry *leftEntry = [self entryAtX:(entry.x - 1) y:entry.y];
    if (leftEntry.type == HALLWAY) {
        [self recursivelyCreatePlayerPositionMapFromEntry:leftEntry distanceFromStart:nextDistanceFromStart];
    }
    MazeEntry *rightEntry = [self entryAtX:(entry.x + 1) y:entry.y];
    if (rightEntry.type == HALLWAY) {
        [self recursivelyCreatePlayerPositionMapFromEntry:rightEntry distanceFromStart:nextDistanceFromStart];
    }
    MazeEntry *upEntry = [self entryAtX:entry.x y:(entry.y - 1)];
    if (upEntry.type == HALLWAY) {
        [self recursivelyCreatePlayerPositionMapFromEntry:upEntry distanceFromStart:nextDistanceFromStart];
    }
    MazeEntry *downEntry = [self entryAtX:entry.x y:(entry.y + 1)];
    if (downEntry.type == HALLWAY) {
        [self recursivelyCreatePlayerPositionMapFromEntry:downEntry distanceFromStart:nextDistanceFromStart];
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
    cv::Point2i startPosition = [self randomWallStart];
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

- (MazeEntry *)randomUnvisitedEntry {
    int count = self.unvisitedEntries.count;
    return [self.unvisitedEntries objectAtIndex:(rand() % count)];
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
    self.unvisitedEntries = [NSMutableArray array];
    self.backtrackingStack = [NSMutableArray array];

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

- (bool)isPlayerValid:(int)player {
    return playerValid[player];
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
