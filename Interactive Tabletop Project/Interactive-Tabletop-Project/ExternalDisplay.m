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

#import "ExternalDisplay.h"
#import "Constants.h"

ExternalDisplay *externalDisplayInstance = nil;

@interface ExternalDisplay ()

@end

@implementation ExternalDisplay

@synthesize window;
@synthesize screen;
@synthesize widescreenBounds;
@synthesize externalDisplayFound;

+ (ExternalDisplay *)instance {
    if (externalDisplayInstance == nil) {
        externalDisplayInstance = [[ExternalDisplay alloc] init];
    }
    return externalDisplayInstance;
}

- (void)initialize {
    if ([UIScreen screens].count > 1) {
        [self redirectLoggerToFile];
        screen = [[UIScreen screens] objectAtIndex:1];
        UIScreenMode *bestScreenMode = nil;
        for (UIScreenMode *screenMode in screen.availableModes) {
            NSLog(@"Resolution: %f, %f", screenMode.size.width, screenMode.size.height);
            if (bestScreenMode == nil || screenMode.size.width > bestScreenMode.size.width || (screenMode.size.width == bestScreenMode.size.width && screenMode.size.height > bestScreenMode.size.height)) {
                bestScreenMode = screenMode;
            }
        }
        NSLog(@"Choose: %f, %f", bestScreenMode.size.width, bestScreenMode.size.height);
        screen.currentMode = bestScreenMode;
        screen.overscanCompensation = UIScreenOverscanCompensationScale;
        externalDisplayFound = YES;
    } else {
        NSLog(@"No external displays found!");
        screen = [UIScreen mainScreen];
        externalDisplayFound = NO;
    }

    [self setupWidescreenBounds];

    window = [[UIWindow alloc] initWithFrame:screen.bounds];
    window.backgroundColor = [UIColor blackColor];
    window.screen = screen;
    window.hidden = [ExternalDisplay instance].externalDisplayFound ? NO : YES;
}

- (void)setupWidescreenBounds {
    if (screen.bounds.size.width > screen.bounds.size.height) {
        widescreenBounds = screen.bounds;
    } else {
        widescreenBounds = CGRectMake(0.0f, 0.0f, screen.bounds.size.height, screen.bounds.size.width);
    }
}

- (void)redirectLoggerToFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

@end
