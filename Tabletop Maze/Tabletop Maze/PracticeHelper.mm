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
        cv::Point2i positions[4] = {cv::Point2i(11, 1), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    if (self.currentImageNumber == 7) {
        cv::Point2i positions[4] = {cv::Point2i(23, 3), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    if (self.currentImageNumber == 8) {
        cv::Point2i positions[4] = {cv::Point2i(21, 5), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    if (self.currentImageNumber == 10) {
        cv::Point2i positions[4] = {cv::Point2i(20, 5), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    if (self.currentImageNumber == 11) {
        cv::Point2i positions[4] = {cv::Point2i(7, 4), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
        return positions[player];
    }
    if (self.currentImageNumber == 12) {
        cv::Point2i positions[4] = {cv::Point2i(16, 5), cv::Point2i(-1, -1), cv::Point2i(-1, -1), cv::Point2i(-1, -1)};
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
        if (player == 0) {
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
    if (self.currentImageNumber == 7) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x, p.y - 2));
            v.push_back(cv::Point2i(p.x + 1, p.y - 2));
            v.push_back(cv::Point2i(p.x + 1, p.y + 2));
            v.push_back(cv::Point2i(p.x + 1, p.y + 1));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 1, p.y - 2));
            v.push_back(cv::Point2i(p.x + 2, p.y));
            v.push_back(cv::Point2i(p.x + 2, p.y - 1));
            v.push_back(cv::Point2i(p.x + 2, p.y - 2));
            v.push_back(cv::Point2i(p.x + 3, p.y));
            v.push_back(cv::Point2i(p.x + 3, p.y - 1));
            v.push_back(cv::Point2i(p.x + 3, p.y - 2));
            v.push_back(cv::Point2i(p.x + 4, p.y - 2));
            v.push_back(cv::Point2i(p.x + 5, p.y - 2));
            v.push_back(cv::Point2i(p.x, p.y));
        }
    }
    if (self.currentImageNumber == 8) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 2, p.y));
            v.push_back(cv::Point2i(p.x + 2, p.y + 1));
            v.push_back(cv::Point2i(p.x + 2, p.y + 2));
            v.push_back(cv::Point2i(p.x + 2, p.y - 1));
            v.push_back(cv::Point2i(p.x + 2, p.y - 3));
            v.push_back(cv::Point2i(p.x + 2, p.y - 3));
            v.push_back(cv::Point2i(p.x + 2, p.y - 4));
            v.push_back(cv::Point2i(p.x + 3, p.y - 4));
            v.push_back(cv::Point2i(p.x + 4, p.y - 4));
        }
    }
    if (self.currentImageNumber == 10) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y));
            v.push_back(cv::Point2i(p.x + 1, p.y - 1));
            v.push_back(cv::Point2i(p.x + 2, p.y));
            v.push_back(cv::Point2i(p.x + 3, p.y));
            v.push_back(cv::Point2i(p.x + 3, p.y + 1));
            v.push_back(cv::Point2i(p.x + 3, p.y + 2));
            v.push_back(cv::Point2i(p.x + 3, p.y + 3));
            v.push_back(cv::Point2i(p.x + 2, p.y + 2));
            v.push_back(cv::Point2i(p.x + 3, p.y - 1));
            v.push_back(cv::Point2i(p.x + 3, p.y - 2));
            v.push_back(cv::Point2i(p.x + 3, p.y - 3));
            v.push_back(cv::Point2i(p.x + 3, p.y - 4));
            v.push_back(cv::Point2i(p.x + 4, p.y - 4));
        }
    }
    if (self.currentImageNumber == 11) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y - 1));
            v.push_back(cv::Point2i(p.x - 1, p.y - 1));
            v.push_back(cv::Point2i(p.x - 2, p.y - 1));
            v.push_back(cv::Point2i(p.x - 2, p.y));
            v.push_back(cv::Point2i(p.x - 2, p.y + 1));
            v.push_back(cv::Point2i(p.x - 3, p.y + 1));
            v.push_back(cv::Point2i(p.x - 2, p.y - 2));
            v.push_back(cv::Point2i(p.x - 2, p.y - 3));
            v.push_back(cv::Point2i(p.x - 1, p.y - 3));
            v.push_back(cv::Point2i(p.x, p.y - 3));
            v.push_back(cv::Point2i(p.x + 1, p.y - 3));
            v.push_back(cv::Point2i(p.x, p.y));
        }
    }
    if (self.currentImageNumber == 12) {
        cv::Point2i p = [self positionOfPlayer:player];
        if (player == 0) {
            v.push_back(cv::Point2i(p.x, p.y));
            v.push_back(cv::Point2i(p.x - 1, p.y));
            v.push_back(cv::Point2i(p.x - 2, p.y));
            v.push_back(cv::Point2i(p.x - 3, p.y));
            v.push_back(cv::Point2i(p.x - 4, p.y));
            v.push_back(cv::Point2i(p.x - 5, p.y));
            v.push_back(cv::Point2i(p.x - 6, p.y));
            v.push_back(cv::Point2i(p.x - 7, p.y));
            v.push_back(cv::Point2i(p.x - 8, p.y));
            v.push_back(cv::Point2i(p.x - 5, p.y - 1));
            v.push_back(cv::Point2i(p.x - 5, p.y - 2));
            v.push_back(cv::Point2i(p.x - 4, p.y - 2));
            v.push_back(cv::Point2i(p.x - 7, p.y - 1));
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
