//
//  PracticeHelper.m
//  Tabletop Maze
//
//  Created by Daniel Andersen on 27/08/14.
//  Copyright (c) 2014 Trolls Ahead. All rights reserved.
//

#import "PracticeHelper.h"
#import "MazeConstants.h"
#import "BrickRecognizer.h"
#import "ExternalDisplay.h"
#import "Constants.h"

PracticeHelper *practiceHelper = nil;

@interface PracticeHelper ()

@end

@implementation PracticeHelper

+ (PracticeHelper *)instance {
    @synchronized (self) {
        if (practiceHelper == nil) {
            practiceHelper = [[PracticeHelper alloc] init];
        }
        return practiceHelper;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _enabled = NO;
    _currentImageNumber = 1;
}

- (UIImage *)currentImage {
    return [UIImage imageNamed:[self currentImageName]];
}

- (NSString *)currentImageName {
    return [NSString stringWithFormat:@"Practice %i%@", self.currentImageNumber, self.placePlayers ? @"b" : @"a"];
}

- (cv::Point2i)positionOfPlayer:(int)player {
    if (self.currentImageNumber == 1) {
        cv::Point2i positions[4] = {cv::Point2i(0, 9), cv::Point2i([self mazeSize].x - 1, 7), cv::Point2i(11, 0), cv::Point2i(9, [self mazeSize].y - 1)};
        return positions[player];
    }
    if (self.currentImageNumber == 2) {
        cv::Point2i positions[4] = {cv::Point2i(0, 8), cv::Point2i([self mazeSize].x - 1, 11), cv::Point2i(17, 0), cv::Point2i(15, [self mazeSize].y - 1)};
        return positions[player];
    }
    if (self.currentImageNumber == 3) {
        cv::Point2i positions[4] = {cv::Point2i(0, 5), cv::Point2i([self mazeSize].x - 1, 9), cv::Point2i(8, 0), cv::Point2i(21, [self mazeSize].y - 1)};
        return positions[player];
    }
    if (self.currentImageNumber == 4) {
        cv::Point2i positions[4] = {cv::Point2i(0, 14), cv::Point2i([self mazeSize].x - 1, 11), cv::Point2i(8, 0), cv::Point2i(11, [self mazeSize].y - 1)};
        return positions[player];
    }
    if (self.currentImageNumber == 5) {
        cv::Point2i positions[4] = {cv::Point2i(0, 14), cv::Point2i([self mazeSize].x - 1, 11), cv::Point2i(23, 0), cv::Point2i(9, [self mazeSize].y - 1)};
        return positions[player];
    }
    if (self.currentImageNumber == 6) {
        cv::Point2i positions[4] = {cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(11, 1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    return cv::Point2i(-1, -1);
}

- (cv::vector<cv::Point2i>)validPositionsForPlayer:(int)player {
    cv::vector<cv::Point2i> v;
    if (self.currentImageNumber == 1) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 2, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
        }
        if (player == 1) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
        }
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y + 1));
            v.push_back(cv::Point2i(p.x, p.y + 2));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
        }
        if (player == 3) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
        }
    }
    if (self.currentImageNumber == 2) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
        }
        if (player == 1) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x - 2, p.y));
        }
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y + 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x, p.y + 2));
        }
        if (player == 3) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
        }
    }
    if (self.currentImageNumber == 3) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
        }
        if (player == 1) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x - 2, p.y));
        }
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y + 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
            v.push_back(cv::Point2i(p.x, p.y + 2));
        }
        if (player == 3) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
        }
    }
    if (self.currentImageNumber == 4) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
        }
        if (player == 1) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x - 2, p.y));
        }
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y + 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
        }
        if (player == 3) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
        }
    }
    if (self.currentImageNumber == 5) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
            v.push_back(cv::Point2i(p.x + 2, p.y));
        }
        if (player == 1) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
            v.push_back(cv::Point2i(p.x - 2, p.y));
        }
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y + 1));
            v.push_back(cv::Point2i(p.x - 1, p.y + 1));
            v.push_back(cv::Point2i(p.x, p.y + 2));
        }
        if (player == 3) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
        }
    }
    if (self.currentImageNumber == 6) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 2) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 2, p.y));
            v.push_back(cv::Point2i(p.x - 3, p.y));
            v.push_back(cv::Point2i(p.x - 4, p.y));
            v.push_back(cv::Point2i(p.x - 5, p.y));
            v.push_back(cv::Point2i(p.x - 6, p.y));
            v.push_back(cv::Point2i(p.x - 2, p.y + 1));
            v.push_back(cv::Point2i(p.x - 2, p.y + 1));
            v.push_back(cv::Point2i(p.x - 3, p.y - 1));
        }
    }
    return v;
}

- (cv::Point2i)mazeSize {
    return cv::Point2i(33, 20);
}

- (void)updatePractice {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        cv::vector<cv::Point> positions = [self validPositionsForPlayer:i];
        if (positions.size() == 0) {
            continue;
        }
        cv::Point recognizedPosition = [[BrickRecognizer instance] positionOfBrickAtLocations:positions];
        if (![self isRecognizedPositionValidForPlayer:i position:recognizedPosition]) {
            if (recognizedPosition.x == -1) {
                NSLog(@"Player %i has NOT been recognized but should have been", i + 1);
            } else {
                NSLog(@"Player %i has been recognized at wrong position: %i, %i", i + 1, recognizedPosition.x, recognizedPosition.y);
            }
        }
    }
}

- (bool)isRecognizedPositionValidForPlayer:(int)player position:(cv::Point)position {
    if (self.placePlayers) {
        return position == [self positionOfPlayer:player];
    } else {
        return position.x == -1;
    }
}

- (void)setEnabled:(bool)enabled {
    _enabled = enabled;
    if (enabled) {
        [ExternalDisplay instance].widescreenBounds = CGRectMake(0.0f, 0.0f, 1280.0f, 800.0f);
        [[Constants instance] recalculateConstants];
    }
}

@end
