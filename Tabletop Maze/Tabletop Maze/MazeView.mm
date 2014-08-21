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
    WAIT
};

@interface MazeView ()

@property (nonatomic, strong) UIImageView *titleImageView;

@property (nonatomic, assign) CGSize borderSize;

@property (nonatomic, strong) NSArray *maskImages;

@property (nonatomic, strong) MazeContainerView *currentMazeView;
@property (nonatomic, strong) MazeContainerView *otherMazeView;

@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UIImageView *treasureImageView;

@property (nonatomic, strong) NSArray *brickMarkers;

@property (nonatomic, assign) enum GameState gameState;

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
    
    NSMutableArray *images = [NSMutableArray array];
    for (int i = 0; i < 17; i++) {
        [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"Brick Mask %i", i]]];
    }
    self.maskImages = [images copy];
    
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
    [self startNewGame];
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
    [self swapMazeViews];
    [self drawMaze];

    self.otherMazeView.alpha = 1.0f;
    self.currentMazeView.alpha = 1.0f;

    [self showBrickMarkers];
    [self updateMask];
}

- (void)startLevel {
    [self hideLogo];
    [self hideBrickMarkers];
    [self showTreasure];
}

- (void)startPlayerTurn {
    self.gameState = PLAYER_TURN;
}

- (void)update {
    switch (self.gameState) {
        case PLACE_PLAYERS:
            [self updatePlacePlayers];
            break;
        case PLAYER_TURN:
            [self updatePlayerTurn];
        default:
            break;
    }
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
                [self hideBrickMarker:i];
                if ([MazeModel instance].currentPlayer == -1) {
                    [MazeModel instance].currentPlayer = i;
                }
                refreshMask = YES;
            }
        } else {
            if (position.x != -1 && position != [[MazeModel instance] positionOfPlayer:i] && [MazeModel instance].currentPlayer == i) {
                [self movePlayerToPosition:position];
                [self startLevel];
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
}

- (void)movePlayerToPosition:(cv::Point)position {
    [[MazeModel instance] setPositionOfPlayer:[MazeModel instance].currentPlayer position:position];
    if (position == [[MazeModel instance] positionOfTreasure]) {
        [self updateMask];
        self.gameState = WAIT;
        [self performSelector:@selector(endGame) withObject:nil afterDelay:[Constants instance].defaultViewAnimationDuration];
    } else {
        [self nextPlayer];
    }
}

- (void)endGame {
    [UIView animateWithDuration:5.0f animations:^{
        self.treasureImageView.frame = CGRectMake(self.treasureImageView.frame.origin.x - (self.treasureImageView.frame.size.width * 2.0f),
                                                  self.treasureImageView.frame.origin.y - (self.treasureImageView.frame.size.height * 2.0f),
                                                  self.treasureImageView.frame.size.width * 5.0f,
                                                  self.treasureImageView.frame.size.height * 5.0f);
    } completion:^(BOOL finished) {
        [self startNewGame];
    }];
}

- (void)nextPlayer {
    self.gameState = WAIT;
    do {
        [MazeModel instance].currentPlayer = ([MazeModel instance].currentPlayer + 1) % MAX_PLAYERS;
    } while (![[MazeModel instance] isPlayerEnabled:[MazeModel instance].currentPlayer]);
    [self updateMask];
    [self performSelector:@selector(startPlayerTurn) withObject:nil afterDelay:[Constants instance].defaultViewAnimationDuration];
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
    
    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillRect(context, self.bounds);

    // Draw tiles
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            int type = [Util randomIntFrom:0 to:BRICK_TYPE_COUNT];
            UIImage *tileImage = [UIImage imageNamed:[NSString stringWithFormat:@"Brick %i", type + 1]];
            MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
            CGContextDrawImage(context, [self rectForEntry:entry], tileImage.CGImage);
        }
    }
    
    // Draw walls
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    
    for (int i = 0; i < [MazeModel instance].height; i++) {
        for (int j = 0; j < [MazeModel instance].width; j++) {
            MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
            [self drawWallForEntry:entry withContext:context];
        }
    }
    
    self.currentMazeView.mazeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
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
    if (self.gameState >= PLAYER_TURN) {
        cv::Point p = [[MazeModel instance] positionOfTreasure];
        maskMap[p.y][p.x] = MAX(2, maskMap[p.y][p.x]);
    }

    UIGraphicsBeginImageContextWithOptions(self.currentMazeView.mazeImageView.frame.size, NO, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor);
    CGContextFillRect(context, self.bounds);

    if (self.gameState != NEW_GAME) {
        for (int i = 0; i < [MazeModel instance].height; i++) {
            for (int j = 0; j < [MazeModel instance].width; j++) {
                MazeEntry *entry = [[MazeModel instance] entryAtX:j y:i];
                int alphaBit = maskMap[i][j];
                int maskBit = 0;
                if (maskMap[i][j] > 0) {
                    maskBit = 16;
                } else {
                    if (![entry hasBorder:BORDER_UP] && maskMap[i - 1][j] > 0) {
                        maskBit |= (1 << 0);
                        alphaBit = MAX(alphaBit, maskMap[i - 1][j]);
                    }
                    if (![entry hasBorder:BORDER_RIGHT] && maskMap[i][j + 1] > 0) {
                        maskBit |= (1 << 1);
                        alphaBit = MAX(alphaBit, maskMap[i][j + 1]);
                    }
                    if (![entry hasBorder:BORDER_DOWN] && maskMap[i + 1][j] > 0) {
                        maskBit |= (1 << 2);
                        alphaBit = MAX(alphaBit, maskMap[i + 1][j]);
                    }
                    if (![entry hasBorder:BORDER_LEFT] && maskMap[i][j - 1] > 0) {
                        maskBit |= (1 << 3);
                        alphaBit = MAX(alphaBit, maskMap[i][j - 1]);
                    }
                }
                float alpha = alphaBit == 0 ? 0.0f : (alphaBit == 1 ? 0.2f : 1.0f);
                UIImage *image = [self.maskImages objectAtIndex:maskBit];
                [image drawInRect:[self rectForEntry:entry] blendMode:kCGBlendModeNormal alpha:alpha];
            }
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    self.currentMazeView.maskLayer.contents = (id)image.CGImage;
    UIGraphicsEndImageContext();
}

- (void)drawWallForEntry:(MazeEntry *)entry withContext:(CGContextRef)context {
    MazeEntry *leftEntry = [[MazeModel instance] entryAtX:(entry.x - 1) y:entry.y];
    MazeEntry *rightEntry = [[MazeModel instance] entryAtX:(entry.x + 1) y:entry.y];
    MazeEntry *upEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y - 1)];
    MazeEntry *downEntry = [[MazeModel instance] entryAtX:entry.x y:(entry.y + 1)];
    
    bool brickBorders[3][3];
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            brickBorders[i][j] = NO;
        }
    }
    
    // Left
    if ([entry hasBorder:BORDER_LEFT]) {
        brickBorders[0][0] = YES;
        brickBorders[1][0] = YES;
        brickBorders[2][0] = YES;
    }
    
    // Right
    if ([entry hasBorder:BORDER_RIGHT]) {
        brickBorders[0][2] = YES;
        brickBorders[1][2] = YES;
        brickBorders[2][2] = YES;
    }

    // Top
    if ([entry hasBorder:BORDER_UP]) {
        brickBorders[0][0] = YES;
        brickBorders[0][1] = YES;
        brickBorders[0][2] = YES;
    }

    // Bottom
    if ([entry hasBorder:BORDER_DOWN]) {
        brickBorders[2][0] = YES;
        brickBorders[2][1] = YES;
        brickBorders[2][2] = YES;
    }
    
    // Corner left/top
    if ([leftEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_LEFT]) {
        brickBorders[0][0] = YES;
    }

    // Corner right/top
    if ([rightEntry hasBorder:BORDER_UP] || [upEntry hasBorder:BORDER_RIGHT]) {
        brickBorders[0][2] = YES;
    }

    // Corner left/bottom
    if ([leftEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_LEFT]) {
        brickBorders[2][0] = YES;
    }
    
    // Corner right/bottom
    if ([rightEntry hasBorder:BORDER_DOWN] || [downEntry hasBorder:BORDER_RIGHT]) {
        brickBorders[2][2] = YES;
    }
    
    // Draw borders
    CGRect brickRect = [self rectForEntry:entry];

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (!brickBorders[i][j] || (i == 1 && j == 1)) {
                continue;
            }
            CGRect borderRect = [self rectForBorderAtX:j y:i brickRect:brickRect];
            borderRect.origin.x -= 1.0f;
            borderRect.origin.y -= 1.0f;
            borderRect.size.width += 2.0f;
            borderRect.size.height += 2.0f;
            
            borderRect = CGRectIntersection(borderRect, brickRect);

            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextFillRect(context, borderRect);
        }
    }

    // Draw filling
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (!brickBorders[i][j] || (i == 1 && j == 1)) {
                continue;
            }
            CGRect borderRect = [self rectForBorderAtX:j y:i brickRect:brickRect];
            borderRect = CGRectIntersection(borderRect, brickRect);
            
            CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillRect(context, borderRect);
        }
    }
}

- (CGRect)rectForBorderAtX:(int)x y:(int)y brickRect:(CGRect)brickRect {
    return CGRectMake(brickRect.origin.x + (x == 0 ? 0.0f : (x == 2 ? brickRect.size.width - self.borderSize.width : self.borderSize.width)),
                      brickRect.origin.y + (y == 0 ? 0.0f : (y == 2 ? brickRect.size.height - self.borderSize.height : self.borderSize.height)),
                      x == 0 || x == 2 ? self.borderSize.width : (brickRect.size.width - (self.borderSize.width * 2.0f)),
                      y == 0 || y == 2 ? self.borderSize.height : (brickRect.size.height - (self.borderSize.height * 2.0f)));
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

- (int)playerReachDistance:(int)player {
    return self.gameState == PLACE_PLAYERS && ![[MazeModel instance] isPlayerEnabled:player] ? 1 : [MazeModel instance].playerReachDistance;
}

- (void)updateMask {
    [self swapMazeViews];

    [self drawMask];

    [self sendSubviewToBack:self.currentMazeView];
    
    self.currentMazeView.alpha = 1.0f;
    self.currentMazeView.hidden = NO;
    
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.otherMazeView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.otherMazeView.hidden = YES;
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

- (void)showTreasure {
    self.treasureImageView.frame = [self rectForPosition:[[MazeModel instance] positionOfTreasure]];
    self.treasureImageView.alpha = 0.0f;
    self.treasureImageView.hidden = NO;
    
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.treasureImageView.alpha = 1.0f;
    }];
}

- (void)hideTreasure {
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.treasureImageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.treasureImageView.hidden = YES;
    }];
}

- (void)hideMaze {
    [UIView animateWithDuration:[MazeConstants instance].defaultAnimationDuration animations:^{
        self.treasureImageView.alpha = 0.0f;
        self.currentMazeView.alpha = 0.0f;
        self.otherMazeView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.treasureImageView.hidden = YES;

        [self drawMask];
        [self swapMazeViews];
        [self drawMask];
    }];
}

@end
