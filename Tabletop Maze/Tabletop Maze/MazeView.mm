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

#import "MazeView.h"
#import "PracticeHelper.h"
#import "MazeContainerView.h"
#import "MazeModel.h"
#import "MazeConstants.h"
#import "BoardCalibrator.h"
#import "BrickRecognizer.h"
#import "Constants.h"
#import "Util.h"

#define BRICK_TYPE_COUNT 6

enum GameState {
    INITIALIZING,
    NEW_GAME,
    PLACE_PLAYERS,
    PLAYER_TURN,
    MOVING_ONTO_POSITION,
    DRAGON_TURN,
    DRAGON_MOVING_ONTO_POSITION,
    WAIT,
    PRACTICING
};

@interface MazeView ()

@property (nonatomic, strong) UIImageView *titleImageView;

@property (nonatomic, assign) CGSize borderSize;

@property (nonatomic, strong) MazeContainerView *currentMazeView;
@property (nonatomic, strong) MazeContainerView *otherMazeView;

@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UIImageView *treasureImageView;

@property (nonatomic, strong) NSArray *brickMarkers;

@property (nonatomic, assign) enum GameState gameState;

@property (nonatomic, assign) int restartCountDown;

@property (nonatomic, assign) bool animatingMask;

@property (nonatomic, strong) UIImageView *testImage;

@end

@implementation MazeView

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];

    self.gameState = INITIALIZING;
    
    self.animatingMask = NO;

    self.borderSize = CGSizeMake(2.0f, 2.0f);

    self.otherMazeView = [[MazeContainerView alloc] init];
    [self addSubview:self.otherMazeView];

    self.currentMazeView = [[MazeContainerView alloc] init];
    [self addSubview:self.currentMazeView];

    self.titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Title"]];
    self.titleImageView.frame = self.bounds;
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.titleImageView.alpha = 0.0f;
    [self addSubview:self.titleImageView];
    
    self.overlayView = [[UIView alloc] initWithFrame:[Constants instance].gridRect];
    self.overlayView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.overlayView];
    
    UIImage *brickMarkerImage = [UIImage imageNamed:@"Brick Marker"];
    NSMutableArray *markers = [NSMutableArray array];
    for (int i = 0; i < MAX_PLAYERS; i++) {
        UIImageView *imageView = [self brickImageViewWithImage:brickMarkerImage];
        [markers addObject:imageView];
        [self.overlayView addSubview:imageView];
    }
    self.brickMarkers = [markers copy];
    
    self.treasureImageView = [self brickImageViewWithImage:[UIImage imageNamed:@"Treasure"]];
    [self.overlayView addSubview:self.treasureImageView];

    self.testImage = [[UIImageView alloc] initWithFrame:CGRectMake(20.0f, 20.0f, 300.0f, 200.0f)];
    self.testImage.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.testImage];
}

- (UIImageView *)brickImageViewWithImage:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.alpha = 0.0f;
    return imageView;
}

- (void)didAppear {
    [super didAppear];
}

- (void)showLogo {
    self.titleImageView.alpha = 0.0f;
    self.titleImageView.hidden = NO;
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.titleImageView.alpha = 1.0f;
    }];
}

- (void)hideLogo {
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.titleImageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.titleImageView.hidden = YES;
    }];
}

- (void)start {
    NSLog(@"Start");
    if ([PracticeHelper instance].enabled) {
        [self startPractice];
    } else {
        [self startNewGame];
    }
}

- (void)startPractice {
    NSLog(@"Practicing");
    self.gameState = PRACTICING;
}

- (void)startNewGame {
    NSLog(@"Start new game");
    self.gameState = NEW_GAME;

    for (int i = 0; i < MAX_PLAYERS; i++) {
        [[MazeModel instance] disablePlayer:i];
    }
    [MazeModel instance].currentPlayer = -1;

    [self hideMaze];
    [self showLogo];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self createMaze];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didGenerateMaze];
        });
    });
}

- (void)startPlacePlayers {
    NSLog(@"Start place players");
    self.gameState = PLACE_PLAYERS;

    [self drawMaze];

    self.otherMazeView.alpha = 1.0f;
    self.currentMazeView.alpha = 1.0f;

    [self placeDragons];
    [self showBrickMarkers];
    [self updateMask];
}

- (void)startLevel {
    [self hideLogo];
    [self hideBrickMarkers];
    [self showObjects];
}

- (void)startPlayerTurn {
    self.restartCountDown = [MazeConstants instance].brickStableCountDown;
    self.gameState = PLAYER_TURN;
    [self showBrickMarker:[MazeModel instance].currentPlayer];
    [self updateMask];
}

- (void)startDragonTurn {
    self.gameState = DRAGON_TURN;

    for (int i = 0; i < 100; i++) {
        cv::Point currentPosition = [[MazeModel instance] positionOfDragon:[MazeModel instance].currentDragon];
        cv::Point targetPosition = [[MazeModel instance] targetPositionOfDragon:[MazeModel instance].currentDragon];

        if (currentPosition == targetPosition) {
            [[MazeModel instance] setRandomTargetPositionOfDragon:[MazeModel instance].currentDragon];
            continue;
        }
    
        NSArray *pathEntries = [[MazeModel instance] shortestPathFrom:currentPosition to:targetPosition];

        MazeEntry *entry = pathEntries.count > [MazeModel instance].dragonReachDistance ? [pathEntries objectAtIndex:[MazeModel instance].dragonReachDistance] : [pathEntries lastObject];
        [self moveDragonToPosition:entry.position];

        break;
    }
}

- (void)update {
    if (self.animatingMask) {
        return;
    }
    switch (self.gameState) {
        case PRACTICING:
            [self updatePracticing];
            break;
        case PLACE_PLAYERS:
            [self updatePlacePlayers];
            break;
        case PLAYER_TURN:
            [self updatePlayerTurn];
        default:
            break;
    }
}

- (void)updatePracticing {
    if (![BoardCalibrator instance].isBoardFullyRecognized) {
        return;
    }
    self.testImage.image = [[BrickRecognizer instance] tiledImageWithLocations:[[PracticeHelper instance] validPositionsForPlayer:0]];
    //self.testImage.image = [[BrickRecognizer instance] imageNumber:0 withLocations:[[PracticeHelper instance] validPositionsForPlayer:0]];
    [[PracticeHelper instance] updatePractice];
}

- (void)updatePlacePlayers {
    if (![BoardCalibrator instance].isBoardFullyRecognized) {
        return;
    }
    bool refreshMask = NO;
    for (int i = 0; i < MAX_PLAYERS; i++) {
        cv::Point position = [self findPlayerPosition:i];
        if (![[MazeModel instance] isPlayerEnabled:i]) {
            if (position == [[MazeModel instance] positionOfPlayer:i]) {
                [[MazeModel instance] enablePlayer:i];
                if ([MazeModel instance].currentPlayer == -1) {
                    [MazeModel instance].currentPlayer = i;
                } else {
                    [self hideBrickMarker:i];
                }
                refreshMask = YES;
            }
        } else {
            if (position.x != -1 && position != [[MazeModel instance] positionOfPlayer:i] && [MazeModel instance].currentPlayer == i) {
                [self movePlayerToPosition:position];
                [self startLevel];
                return;
            }
        }
    }
    if (refreshMask) {
        [self updateMask];
    }
}

- (void)updatePlayerTurn {
    if (![BoardCalibrator instance].isBoardFullyRecognized) {
        return;
    }
    cv::Point position = [self findPlayerPosition:[MazeModel instance].currentPlayer];
    if (position.x != -1 && position != [[MazeModel instance] positionOfPlayer:[MazeModel instance].currentPlayer]) {
        [self movePlayerToPosition:position];
    }
    
#ifndef TARGET_IPHONE_SIMULATOR
    if (position.x == -1) {
        self.restartCountDown--;
        if (self.restartCountDown <= 0) {
            [[MazeModel instance] disablePlayer:[MazeModel instance].currentPlayer];
            [self hideBrickMarker:[MazeModel instance].currentPlayer];
            [self nextPlayer];
        }
    } else {
        self.restartCountDown = [MazeConstants instance].brickStableCountDown;
    }
#endif
}

- (void)movePlayerToPosition:(cv::Point)position {
    self.gameState = MOVING_ONTO_POSITION;
    
    cv::Point oldPosition = [[MazeModel instance] positionOfPlayer:[MazeModel instance].currentPlayer];
    
    [[MazeModel instance] setPositionOfPlayer:[MazeModel instance].currentPlayer position:position];
    [self updateMaskWithAnimationDuration:[MazeConstants instance].stepAnimationDuration completion:nil];

    NSArray *pathEntries = [[MazeModel instance] shortestPathFrom:oldPosition to:position];
    float delayPerBrick = [MazeConstants instance].stepAnimationDuration / (float)(pathEntries.count - 1);
    for (int i = 1; i < pathEntries.count; i++) {
        MazeEntry *entry = [pathEntries objectAtIndex:i];
        float delayRight = delayPerBrick * (float)(i - 1);
        float delayLeft = (delayRight + (delayPerBrick / 2.0f));
        if (i < pathEntries.count - 1) {
            [self performSelector:@selector(placeDisplacedRightFootprintAtEntry:) withObject:entry afterDelay:delayRight];
            [self performSelector:@selector(placeDisplacedLeftFootprintAtEntry:) withObject:entry afterDelay:delayLeft];
        } else {
            [self performSelector:@selector(placeRightFootprintAtEntry:) withObject:entry afterDelay:delayRight];
            [self performSelector:@selector(placeLeftFootprintAtEntry:) withObject:entry afterDelay:delayLeft];
        }
    }
    [self performSelector:@selector(finishMovePlayerToEntry:) withObject:[pathEntries lastObject] afterDelay:(delayPerBrick * (float)pathEntries.count)];
}

- (void)placeLeftFootprintAtEntry:(MazeEntry *)entry {
    [self placeFootprintAtEntry:entry side:0 displacement:0.0f];
}

- (void)placeRightFootprintAtEntry:(MazeEntry *)entry {
    [self placeFootprintAtEntry:entry side:1 displacement:0.0f];
}

- (void)placeDisplacedLeftFootprintAtEntry:(MazeEntry *)entry {
    [self placeFootprintAtEntry:entry side:0 displacement:0.2f];
}

- (void)placeDisplacedRightFootprintAtEntry:(MazeEntry *)entry {
    [self placeFootprintAtEntry:entry side:1 displacement:0.2f];
}

- (void)placeFootprintAtEntry:(MazeEntry *)entry side:(int)side displacement:(float)displacement {
    int dir = ((NSNumber *)[entry.bag objectForKey:@"direction"]).intValue;

    UIImage *footprintImage = [UIImage imageNamed:[NSString stringWithFormat:@"Player Footprint %@", side == 0 ? @"Left" : @"Right"]];

    CGRect rect = [self rectForEntry:entry];
    rect.origin.x += dirX[(dir + (side == 1 ? 0 : 2)) % 4] * rect.size.width  * displacement;
    rect.origin.y += dirY[(dir + (side == 1 ? 0 : 2)) % 4] * rect.size.height * displacement;
    
    UIGraphicsBeginImageContextWithOptions(self.currentMazeView.mazeImageView.image.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, self.currentMazeView.mazeImageView.bounds);

    [self.currentMazeView.mazeImageView.image drawAtPoint:CGPointZero];
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(context, rect.size.width * 0.5f, rect.size.height * 0.5f);
    CGContextRotateCTM(context, ((float)(dir + 3) / 4.0f) * 2.0f * M_PI);
    CGContextTranslateCTM(context, rect.size.width * -0.5f, rect.size.height * -0.5f);
    CGContextDrawImage(context, (CGRect){ CGPointZero, rect.size }, footprintImage.CGImage);
    CGContextRestoreGState(context);
    
    self.currentMazeView.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    self.otherMazeView.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
}

- (void)finishMovePlayerToEntry:(MazeEntry *)entry {
    if (entry.position == [MazeModel instance].treasurePosition) {
        [self endGame];
    } else {
        [self hideBrickMarker:[MazeModel instance].currentPlayer];
        [self nextPlayer];
    }
}

- (void)moveDragonToPosition:(cv::Point)position {
    self.gameState = DRAGON_MOVING_ONTO_POSITION;
    
    cv::Point oldPosition = [[MazeModel instance] positionOfDragon:[MazeModel instance].currentDragon];
    
    [[MazeModel instance] setPositionOfDragon:[MazeModel instance].currentDragon position:position];
    
    NSArray *pathEntries = [[MazeModel instance] shortestPathFrom:oldPosition to:position];
    if (pathEntries == nil || pathEntries.count == 0) {
        [self finishMoveDragonToEntry:[[MazeModel instance] entryAtPosition:position]];
        return;
    }
    
    float delayPerBrick = [MazeConstants instance].stepAnimationDuration / (float)(pathEntries.count - 1);
    for (int i = 1; i < pathEntries.count; i++) {
        MazeEntry *entry = [pathEntries objectAtIndex:i];
        float delayRight = delayPerBrick * (float)(i - 1);
        float delayLeft = (delayRight + (delayPerBrick / 2.0f));
        [self performSelector:@selector(moveLeftFootprintOfDragonToEntry:) withObject:entry afterDelay:delayLeft];
        [self performSelector:@selector(moveRightFootprintOfDragonToEntry:) withObject:entry afterDelay:delayRight];
    }
    [self performSelector:@selector(finishMoveDragonToEntry:) withObject:[pathEntries lastObject] afterDelay:(delayPerBrick * (float)pathEntries.count)];
}

- (void)moveLeftFootprintOfDragonToEntry:(MazeEntry *)entry {
    [self moveDragonImageToEntry:entry imageView:[self.currentMazeView dragonFootprintLeftImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:NO];
    [self moveDragonImageToEntry:entry imageView:[self.currentMazeView dragonImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:YES];
    [self moveDragonImageToEntry:entry imageView:[self.otherMazeView dragonFootprintLeftImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:NO];
    [self moveDragonImageToEntry:entry imageView:[self.otherMazeView dragonImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:YES];
}

- (void)moveRightFootprintOfDragonToEntry:(MazeEntry *)entry {
    [self moveDragonImageToEntry:entry imageView:[self.currentMazeView dragonFootprintRightImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:NO];
    [self moveDragonImageToEntry:entry imageView:[self.currentMazeView dragonImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:YES];
    [self moveDragonImageToEntry:entry imageView:[self.otherMazeView dragonFootprintRightImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:NO];
    [self moveDragonImageToEntry:entry imageView:[self.otherMazeView dragonImageViewWithIndex:[MazeModel instance].currentDragon] enlarged:YES];
}

- (void)moveDragonImageToEntry:(MazeEntry *)entry imageView:(UIImageView *)imageView enlarged:(bool)enlarged {
    int dir = ((NSNumber *)[entry.bag objectForKey:@"direction"]).intValue;
    float angle = ((float)(dir + 1) / 4.0f) * 2.0f * M_PI;

    imageView.frame = enlarged ? [self enlargedRect:[self rectForEntry:entry] factor:1.5f] : [self rectForEntry:entry];
    imageView.transform = CGAffineTransformMakeRotation(angle);
}

- (void)finishMoveDragonToEntry:(MazeEntry *)entry {
    // TODO! Check for player at position
    if ([MazeModel instance].currentDragon < 3) {
        [MazeModel instance].currentDragon = [MazeModel instance].currentDragon + 1;
        [self startDragonTurn];
    } else {
        [self startFirstPlayerTurn];
    }
}

- (void)endGame {
    [self hideBrickMarkers];
    [UIView animateWithDuration:5.0f animations:^{
        self.treasureImageView.frame = CGRectMake(self.treasureImageView.frame.origin.x - (self.treasureImageView.frame.size.width * 2.0f),
                                                  self.treasureImageView.frame.origin.y - (self.treasureImageView.frame.size.height * 2.0f),
                                                  self.treasureImageView.frame.size.width * 5.0f,
                                                  self.treasureImageView.frame.size.height * 5.0f);
    } completion:^(BOOL finished) {
        [self startNewGame];
    }];
}

- (void)startFirstPlayerTurn {
    self.gameState = WAIT;
    
    for (int i = 0; i < MAX_PLAYERS; i++) {
        [MazeModel instance].currentPlayer = [MazeModel instance].currentPlayer + 1;
        if ([[MazeModel instance] isPlayerEnabled:[MazeModel instance].currentPlayer]) {
            [self startPlayerTurn];
            return;
        }
    }
    [self performSelector:@selector(endGame) withObject:nil afterDelay:([MazeConstants instance].defaultAnimationDuration * 1.2f)];
}

- (void)nextPlayer {
    self.gameState = WAIT;

    int nextPlayer = [MazeModel instance].currentPlayer;
    [MazeModel instance].currentPlayer = -1;
    
    [self updateMask];

    for (int i = nextPlayer + 1; i < MAX_PLAYERS; i++) {
        if ([[MazeModel instance] isPlayerEnabled:i]) {
            [MazeModel instance].currentPlayer = i;
            [self performSelector:@selector(startPlayerTurn) withObject:nil afterDelay:([MazeConstants instance].defaultAnimationDuration * 1.2f)];
            return;
        }
    }
    [MazeModel instance].currentDragon = 0;
    NSLog(@"Start dragon turn!");
    [self performSelector:@selector(startDragonTurn) withObject:nil afterDelay:[MazeConstants instance].defaultAnimationDuration * 1.2f];
}

- (cv::Point)findPlayerPosition:(int)player {
    cv::vector<cv::Point> positions;
    for (MazeEntry *entry in [[MazeModel instance] reachableEntriesForPlayer:player reachDistance:[self playerReachDistance:player]]) {
        positions.push_back(cv::Point(entry.x, entry.y));
    }
    return [[BrickRecognizer instance] positionOfBrickAtLocations:positions];
}

- (void)createMaze {
    [MazeModel instance].width = (int)[Constants instance].gridSize.width;
    [MazeModel instance].height = (int)[Constants instance].gridSize.height;
    
    [[MazeModel instance] createRandomMaze];
}

- (void)didGenerateMaze {
    [self performSelector:@selector(startPlacePlayers) withObject:nil afterDelay:2.0f];
}

- (void)drawMaze {
    UIGraphicsBeginImageContextWithOptions(self.currentMazeView.mazeImageView.frame.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, self.bounds);

    // Draw tiles
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            int type = [Util randomIntFrom:0 to:BRICK_TYPE_COUNT];
            MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
            UIImage *tileImage;
            if (entry.type == HALLWAY) {
                tileImage = [UIImage imageNamed:[NSString stringWithFormat:@"Brick %i", type + 1]];
            } else {
                tileImage = [UIImage imageNamed:[NSString stringWithFormat:@"Wall %i", type + 1]];
            }
            CGContextDrawImage(context, [self rectForEntry:entry], tileImage.CGImage);
        }
    }
    
    self.currentMazeView.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    self.otherMazeView.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
}

- (void)drawMask {
    int maskMap[[MazeModel instance].height][[MazeModel instance].width];
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            maskMap[i][j] = 0;
        }
    }
    for (int i = 0; i < MAX_PLAYERS; i++) {
        if (![[MazeModel instance] isPlayerEnabled:i] && self.gameState != PLACE_PLAYERS) {
            continue;
        }
        NSArray *reachableEntries = [[MazeModel instance] reachableEntriesForPlayer:i reachDistance:[self playerReachDistance:i]];
        for (MazeEntry *entry in reachableEntries) {
            int mask = i == [MazeModel instance].currentPlayer || (self.gameState == PLACE_PLAYERS && ![[MazeModel instance] isPlayerEnabled:i]) ? 2 : 1;
            maskMap[entry.y][entry.x] = MAX(mask, maskMap[entry.y][entry.x]);
        }
    }

    UIGraphicsBeginImageContextWithOptions(self.currentMazeView.mazeImageView.frame.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.0f].CGColor);
    CGContextFillRect(context, self.bounds);

    UIImage *maskImage = [UIImage imageNamed:@"Mask"];

    if (self.gameState != NEW_GAME) {
        for (int i = 0; i < [MazeModel instance].height; i++) {
            for (int j = 0; j < [MazeModel instance].width; j++) {
                if (maskMap[i][j] > 0) {
                    MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
                    float alpha = maskMap[i][j] == 0 ? 0.0f : (maskMap[i][j] == 1 ? 0.2f : 1.0f);
                    [maskImage drawInRect:[self maskRectForEntry:entry] blendMode:kCGBlendModeDestinationOver alpha:alpha];
                }
            }
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    self.currentMazeView.maskLayer.contents = (id)image.CGImage;
    UIGraphicsEndImageContext();
}

- (CGRect)rectForEntry:(MazeEntry *)entry {
    return [self rectForPosition:entry.position];
}

- (CGRect)rectForPosition:(cv::Point)position {
    return CGRectMake(position.x * [Constants instance].brickSize.width,
                      position.y * [Constants instance].brickSize.height,
                      [Constants instance].brickSize.width,
                      [Constants instance].brickSize.height);
}

- (CGRect)maskRectForEntry:(MazeEntry *)entry {
    CGRect rect = [self rectForEntry:entry];
    rect.origin.x -= rect.size.width;
    rect.origin.y -= rect.size.height;
    rect.size.width *= 3.0f;
    rect.size.height *= 3.0f;
    return rect;
}

- (int)playerReachDistance:(int)player {
    if ([[MazeModel instance] isPlayerEnabled:player]) {
        return [MazeModel instance].playerReachDistance;
    } else {
        return 2;
    }
}

- (void)updateMask {
    [self updateMaskWithAnimationDuration:[MazeConstants instance].defaultAnimationDuration completion:nil];
}

- (void)updateMaskWithAnimationDuration:(float)animationDuration completion:(void (^)())completion {
    self.animatingMask = YES;

    [self swapMazeViews];

    [self drawMask];

    [self sendSubviewToBack:self.currentMazeView];
    
    self.currentMazeView.alpha = 1.0f;
    self.currentMazeView.hidden = NO;
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.otherMazeView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.otherMazeView.hidden = YES;
        self.animatingMask = NO;
        if (completion != nil) {
            completion();
        }
    }];
}

- (void)swapMazeViews {
    MazeContainerView *tmpView = self.currentMazeView;
    self.currentMazeView = self.otherMazeView;
    self.otherMazeView = tmpView;
}

- (void)showBrickMarkers {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        [self showBrickMarker:i];
    }
}

- (void)hideBrickMarkers {
    for (int i = 0; i < MAX_PLAYERS; i++) {
        [self hideBrickMarker:i];
    }
}

- (void)showBrickMarker:(int)player {
    UIImageView *markerView = [self.brickMarkers objectAtIndex:player];

    markerView.frame = [self rectForEntry:[[MazeModel instance] entryForPlayer:player]];
    markerView.alpha = 0.0f;
    markerView.hidden = NO;

    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        markerView.alpha = 1.0f;
    }];
}

- (void)hideBrickMarker:(int)player {
    UIImageView *markerView = [self.brickMarkers objectAtIndex:player];
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        markerView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        markerView.hidden = YES;
    }];
}

- (void)showObjects {
    self.treasureImageView.frame = [self enlargedRect:[self rectForPosition:[MazeModel instance].treasurePosition] factor:1.5f];
    self.treasureImageView.alpha = 0.0f;
    self.treasureImageView.hidden = NO;
    
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.treasureImageView.alpha = 1.0f;
        for (int i = 0; i < MAX_DRAGONS; i++) {
            [self.currentMazeView dragonImageViewWithIndex:i].alpha = 1.0f;
            [self.currentMazeView dragonFootprintLeftImageViewWithIndex:i].alpha = 1.0f;
            [self.currentMazeView dragonFootprintRightImageViewWithIndex:i].alpha = 1.0f;

            [self.otherMazeView dragonImageViewWithIndex:i].alpha = 1.0f;
            [self.otherMazeView dragonFootprintLeftImageViewWithIndex:i].alpha = 1.0f;
            [self.otherMazeView dragonFootprintRightImageViewWithIndex:i].alpha = 1.0f;
        }
    }];
}

- (void)hideObjects {
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.treasureImageView.alpha = 0.0f;
        for (int i = 0; i < MAX_DRAGONS; i++) {
            [self.currentMazeView dragonImageViewWithIndex:i].alpha = 0.0f;
            [self.currentMazeView dragonFootprintLeftImageViewWithIndex:i].alpha = 0.0f;
            [self.currentMazeView dragonFootprintRightImageViewWithIndex:i].alpha = 0.0f;
            
            [self.otherMazeView dragonImageViewWithIndex:i].alpha = 0.0f;
            [self.otherMazeView dragonFootprintLeftImageViewWithIndex:i].alpha = 0.0f;
            [self.otherMazeView dragonFootprintRightImageViewWithIndex:i].alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        self.treasureImageView.hidden = YES;
    }];
}

- (void)hideMaze {
    [self hideObjects];
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.currentMazeView.alpha = 0.0f;
        self.otherMazeView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.treasureImageView.hidden = YES;

        [self drawMask];
        [self swapMazeViews];
        [self drawMask];
    }];
}

- (void)placeDragons {
    for (int i = 0; i < MAX_DRAGONS; i++) {
        CGRect frame = [self frameOfDragonWithIndex:i];
        CGRect enlargedFrame = [self enlargedRect:frame factor:1.5f];

        [self.currentMazeView dragonImageViewWithIndex:i].frame = enlargedFrame;
        [self.currentMazeView dragonFootprintLeftImageViewWithIndex:i].frame = frame;
        [self.currentMazeView dragonFootprintRightImageViewWithIndex:i].frame = frame;
        
        [self.otherMazeView dragonImageViewWithIndex:i].frame = enlargedFrame;
        [self.otherMazeView dragonFootprintLeftImageViewWithIndex:i].frame = frame;
        [self.otherMazeView dragonFootprintRightImageViewWithIndex:i].frame = frame;
    }
}

- (CGRect)frameOfDragonWithIndex:(int)index {
    return [self rectForPosition:[[MazeModel instance] positionOfDragon:index]];
}

- (CGRect)enlargedRect:(CGRect)rect factor:(float)factor {
    float width = rect.size.width * factor;
    float height = rect.size.height * factor;
    return CGRectMake(CGRectGetMidX(rect) - (width / 2.0f),
                      CGRectGetMidY(rect) - (height / 2.0f),
                      width,
                      height);
}

@end
