//
//  MazeModel.m
//  Tabletop Maze
//
//  Created by Daniel Andersen on 08/06/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import "MazeModel.h"

MazeModel *mazeModelInstance = nil;

@interface MazeModel ()

@property (nonatomic, strong) NSMutableArray *maze;

@property (nonatomic, strong) NSMutableArray *backtrackingStack;
@property (nonatomic, strong) NSMutableArray *unvisitedEntries;

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
    [self recursivelyCreateMazeFromCurrentEntry:[self randomUnvisitedEntry]];
    [self resetMazeBags];
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
        MazeEntry *otherEntry = [unvisitedNeighbours objectAtIndex:(rand() % unvisitedNeighbours.count)];
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
