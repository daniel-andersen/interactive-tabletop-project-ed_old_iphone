//
//  MazeModel.m
//  Tabletop Maze
//
//  Created by Daniel Andersen on 08/06/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#include <vector>

#import "MazeModel.h"
#import "MazeConstants.h"
#import "Util.h"

MazeModel *mazeModelInstance = nil;

@interface MazeModel () {
    cv::Point2i playerPosition[MAX_PLAYERS];
}

@property (nonatomic, strong) NSMutableArray *maze;

@property (nonatomic, strong) NSMutableArray *backtrackingStack;
@property (nonatomic, strong) NSMutableArray *unvisitedEntries;

@property (nonatomic, strong) MazeEntry *firstDiggedEntry;
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
    self.width = 30;
    self.height = 20;
}

- (void)createRandomMaze {
    NSLog(@"Creating random maze with size %ix%i", self.width, self.height);
    [self resetMaze];
    [self chooseRandomStartingPosition];
    [self recursivelyCreateMazeFromCurrentEntry:self.firstDiggedEntry];
    
    NSLog(@"Placing treasure and players");
    [self resetMazeBags];
    [self placeTreasureAndPlayers];

    NSLog(@"Generated maze!");
    [self resetMazeBags];
}

- (void)placeTreasureAndPlayers {
    [self recursivelyCreatePlayerPositionMapFromEntry:self.firstDiggedEntry distanceFromStart:0];
    [self findPlayerPositionsFromMap];

    //
    for (int i = 0; i < self.height; i++) {
        NSString *rowStr = @"";
        for (int j = 0; j < self.width; j++) {
            MazeEntry *entry = [self entryAtX:j y:i];
            NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
            NSString *s;
            if (distanceFromStart == nil) {
                s = @"    ";
            } else if ([distanceFromStart intValue] < 10) {
                s = [NSString stringWithFormat:@"%i   ", [distanceFromStart intValue]];
            } else if ([distanceFromStart intValue] < 100) {
                s = [NSString stringWithFormat:@"%i  ", [distanceFromStart intValue]];
            } else {
                s = [NSString stringWithFormat:@"%i ", [distanceFromStart intValue]];
            }
            rowStr = [rowStr stringByAppendingString:s];
        }
        NSLog(@"%@", rowStr);
    }
    //
}

- (void)findPlayerPositionsFromMap {
    int maxBorderDistance[4];
    
    // Left max distance
    for (int i = 1; i < self.height - 1; i++) {
        MazeEntry *entry = [self entryAtX:0 y:i];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[0] = MAX(maxBorderDistance[0], distanceFromStart.intValue);
        }
    }

    // Right max distance
    for (int i = 1; i < self.height - 1; i++) {
        MazeEntry *entry = [self entryAtX:(self.width - 1) y:i];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[1] = MAX(maxBorderDistance[1], distanceFromStart.intValue);
        }
    }

    // Top max distance
    for (int i = 1; i < self.width - 1; i++) {
        MazeEntry *entry = [self entryAtX:i y:0];
        NSNumber *distanceFromStart = [entry.bag objectForKey:@"distanceFromStart"];
        if (distanceFromStart != nil) {
            maxBorderDistance[2] = MAX(maxBorderDistance[2], distanceFromStart.intValue);
        }
    }

    // Bottom max distance
    for (int i = 1; i < self.width - 1; i++) {
        MazeEntry *entry = [self entryAtX:i y:(self.height - 1)];
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
    for (int i = 1; i < self.height - 1; i++) {
        leftStartingEntry = [self updateBestStartingEntry:leftStartingEntry candidateEntry:[self entryAtX:0 y:i] targetDistanceFromStart:minBorderDistance];
        rightStartingEntry = [self updateBestStartingEntry:rightStartingEntry candidateEntry:[self entryAtX:(self.width - 1) y:i] targetDistanceFromStart:minBorderDistance];
    }

    MazeEntry *topStartingEntry = nil;
    MazeEntry *bottomStartingEntry = nil;
    for (int i = 1; i < self.width - 1; i++) {
        topStartingEntry = [self updateBestStartingEntry:topStartingEntry candidateEntry:[self entryAtX:i y:0] targetDistanceFromStart:minBorderDistance];
        bottomStartingEntry = [self updateBestStartingEntry:bottomStartingEntry candidateEntry:[self entryAtX:i y:(self.height - 1)] targetDistanceFromStart:minBorderDistance];
    }
    
    playerPosition[0] = cv::Point2i(leftStartingEntry.x, leftStartingEntry.y);
    playerPosition[1] = cv::Point2i(rightStartingEntry.x, rightStartingEntry.y);
    playerPosition[2] = cv::Point2i(topStartingEntry.x, topStartingEntry.y);
    playerPosition[3] = cv::Point2i(bottomStartingEntry.x, bottomStartingEntry.y);
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
    if (![entry hasBorder:BORDER_LEFT]) {
        [self recursivelyCreatePlayerPositionMapFromEntry:[self entryAtX:(entry.x - 1) y:entry.y] distanceFromStart:nextDistanceFromStart];
    }
    if (![entry hasBorder:BORDER_RIGHT]) {
        [self recursivelyCreatePlayerPositionMapFromEntry:[self entryAtX:(entry.x + 1) y:entry.y] distanceFromStart:nextDistanceFromStart];
    }
    if (![entry hasBorder:BORDER_UP]) {
        [self recursivelyCreatePlayerPositionMapFromEntry:[self entryAtX:entry.x y:(entry.y - 1)] distanceFromStart:nextDistanceFromStart];
    }
    if (![entry hasBorder:BORDER_DOWN]) {
        [self recursivelyCreatePlayerPositionMapFromEntry:[self entryAtX:entry.x y:(entry.y + 1)] distanceFromStart:nextDistanceFromStart];
    }
}

- (void)removeWallBetween:(MazeEntry *)entry1 andEntry:(MazeEntry *)entry2 {
    if (entry1.y == entry2.y) {
        if (entry1.x == entry2.x - 1) {
            [entry1 removeBorder:BORDER_RIGHT];
            [entry2 removeBorder:BORDER_LEFT];
        }
        if (entry1.x == entry2.x + 1) {
            [entry1 removeBorder:BORDER_LEFT];
            [entry2 removeBorder:BORDER_RIGHT];
        }
    }
    if (entry1.x == entry2.x) {
        if (entry1.y == entry2.y - 1) {
            [entry1 removeBorder:BORDER_DOWN];
            [entry2 removeBorder:BORDER_UP];
        }
        if (entry1.y == entry2.y + 1) {
            [entry1 removeBorder:BORDER_UP];
            [entry2 removeBorder:BORDER_DOWN];
        }
    }
}

- (void)recursivelyCreateMazeFromCurrentEntry:(MazeEntry *)entry {
    [self.unvisitedEntries removeObject:entry];
    NSArray *unvisitedNeighbours = [self unvisitedNeighboursFromEntry:entry];
    if (unvisitedNeighbours.count > 0) {
        MazeEntry *otherEntry = [unvisitedNeighbours objectAtIndex:[Util randomIntFrom:0 to:unvisitedNeighbours.count]];
        [self removeWallBetween:entry andEntry:otherEntry];
        [self.backtrackingStack addObject:entry];
        [self recursivelyCreateMazeFromCurrentEntry:otherEntry];
    } else if (self.backtrackingStack.count > 0) {
        MazeEntry *otherEntry = [self.backtrackingStack lastObject];
        [self.backtrackingStack removeLastObject];
        [self recursivelyCreateMazeFromCurrentEntry:otherEntry];
    } else if (self.unvisitedEntries.count > 0) {
        [self recursivelyCreateMazeFromCurrentEntry:[self randomUnvisitedEntry]];
    }
}

- (void)chooseRandomStartingPosition {
    int deltaX = self.width / 4;
    int deltaY = self.height / 4;

    int x = [Util randomIntFrom:((self.width - deltaX) / 2) to:((self.width + deltaX) / 2)];
    int y = [Util randomIntFrom:((self.height - deltaY) / 2) to:((self.height + deltaY) / 2)];
    
    self.firstDiggedEntry = [self entryAtX:x y:y];
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

- (cv::Point2i)positionOfPlayer:(int)player {
    return playerPosition[player];
}

- (cv::Point2i)positionOfTreasure {
    return cv::Point2i(self.firstDiggedEntry.x, self.firstDiggedEntry.y);
}

@end



@implementation MazeEntry

- (id)initWithPosition:(CGPoint)p {
    if (self = [super init]) {
        self.x = (int)p.x;
        self.y = (int)p.y;
        self.borderMask = BORDER_UP | BORDER_DOWN | BORDER_LEFT | BORDER_RIGHT;
        self.bag = [NSMutableDictionary dictionary];
    }
    return self;
}

- (bool)hasBorder:(int)borderMask {
    return (self.borderMask & borderMask) != 0;
}

- (void)addBorder:(int)borderMask {
    self.borderMask |= borderMask;
}

- (void)removeBorder:(int)borderMask {
    self.borderMask &= ~borderMask;
}

@end