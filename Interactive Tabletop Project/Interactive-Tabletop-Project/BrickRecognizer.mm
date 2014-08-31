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

#import "BrickRecognizer.h"
#import "BoardCalibrator.h"
#import "UIImage+OpenCV.h"

#define HISTOGRAM_BIN_COUNT 4
#define HISTOGRAM_BIN_COUNT_FALLBACK 2
#define HISTOGRAM_BIN_COUNT_FALLBACK_2 8

#define BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA 40.0f
#define BRICK_RECOGNITION_MINIMUM_PROBABILITY 0.4f
#define BRICK_RECOGNITION_MINIMUM_DEVIATION 0.7f

BrickRecognizer *brickRecognizerInstance = nil;

@implementation BrickRecognizer

+ (BrickRecognizer *)instance {
    @synchronized(self) {
        if (brickRecognizerInstance == nil) {
            brickRecognizerInstance = [[BrickRecognizer alloc] init];
        }
        return brickRecognizerInstance;
    }
}

- (cv::Point)positionOfBrickAtLocations:(cv::vector<cv::Point>)locations {
    @synchronized([BoardCalibrator instance].boardImageLock) {
        cv::Mat brickImages = [self tiledImageFromLocations:locations];
        
        MedianMinMax medianMinMax = [self medianMinMaxFromLocations:locations inTiledImage:brickImages];
        if (medianMinMax.max - medianMinMax.min < BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA) {
            //NSLog(@"%f vs %f = %f", medianMinMax.min, medianMinMax.max, medianMinMax.max - medianMinMax.min);
            return cv::Point(-1, -1);
        }
        for (int i = 0; i < 3; i++) {
            int histogramBinCount = i == 0 ? HISTOGRAM_BIN_COUNT : (i == 1 ? HISTOGRAM_BIN_COUNT_FALLBACK : HISTOGRAM_BIN_COUNT_FALLBACK_2);
            cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:locations withHistogramBinCount:histogramBinCount];
            float maxProbability = [self maxProbabilityFromProbabilities:probabilities];
            float secondMaxProbability = [self secondMaxProbabilityFromProbabilities:probabilities];
            if (secondMaxProbability / maxProbability >= BRICK_RECOGNITION_MINIMUM_DEVIATION) {
                //NSLog(@"%f vs %f - %f vs %f", medianMinMax.max - medianMinMax.min, maxProbability, secondMaxProbability, secondMaxProbability / maxProbability);
                continue;
            }
            if (maxProbability < BRICK_RECOGNITION_MINIMUM_PROBABILITY) {
                break;
            }
            //NSLog(@"%f vs %f - %f vs %f", medianMinMax.max - medianMinMax.min, maxProbability, secondMaxProbability, secondMaxProbability / maxProbability);
            return [self maxProbabilityPositionFromLocations:locations probabilities:probabilities];
        }
        return cv::Point(-1, -1);
    }
}

- (cv::vector<cv::Point>)positionOfBricksAtLocations:(cv::vector<cv::Point>)locations controlPoints:(cv::vector<cv::Point>)controlPoints {
    @synchronized([BoardCalibrator instance].boardImageLock) {
        cv::vector<cv::Point> positions;
        for (int i = 0; i < locations.size(); i++) {
            cv::vector<cv::Point> brickLocations = [self allLocationsFromLocation:locations[i] controlPoints:controlPoints];
            cv::Mat brickImages = [self tiledImageFromLocations:brickLocations];
            MedianMinMax medianMinMax = [self medianMinMaxFromLocations:brickLocations inTiledImage:brickImages];
            if (medianMinMax.max - medianMinMax.min < BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA) {
                continue;
            }
            cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:brickLocations];
            float maxProbability = [self maxProbabilityFromProbabilities:probabilities];
            float secondMaxProbability = [self secondMaxProbabilityFromProbabilities:probabilities];
            if (maxProbability < BRICK_RECOGNITION_MINIMUM_PROBABILITY || secondMaxProbability >= BRICK_RECOGNITION_MINIMUM_PROBABILITY) {
                continue;
            }
            cv::Point maxProbPosition = [self maxProbabilityPositionFromLocations:brickLocations probabilities:probabilities];
            if (maxProbPosition == locations[i]) {
                positions.push_back(locations[i]);
            }
        }
        return positions;
    }
}

- (float)maxProbabilityFromProbabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    for (int i = 0; i < probabilities.size(); i++) {
        maxProb = MAX(maxProb, probabilities[i]);
    }
    return maxProb;
}

- (float)secondMaxProbabilityFromProbabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    float secondMaxProb = 0.0f;
    for (int i = 0; i < probabilities.size(); i++) {
        if (probabilities[i] > maxProb) {
            secondMaxProb = maxProb;
            maxProb = probabilities[i];
        } else if (probabilities[i] > secondMaxProb) {
            secondMaxProb = probabilities[i];
        }
    }
    return secondMaxProb;
}

- (cv::Point)maxProbabilityPositionFromLocations:(cv::vector<cv::Point>)locations probabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    int maxProbIndex = 0;
    for (int i = 0; i < locations.size(); i++) {
        if (probabilities[i] > maxProb) {
            maxProb = probabilities[i];
            maxProbIndex = i;
        }
    }
    return locations[maxProbIndex];
}

- (MedianMinMax)medianMinMaxFromLocations:(cv::vector<cv::Point>)locations inTiledImage:(cv::Mat)tiledImage {
    MedianMinMax medianMinMax = {.min = 256.0f, .max = 0.0f};
    for (int i = 0; i < locations.size(); i++) {
        cv::Mat brickImage = [self extractBrickImageFromIndex:i inTiledImage:tiledImage];
        cv::Mat histogram = [self calculateHistogramFromImage:brickImage binCount:256];
        float median = [self calculateMedianOfHistogram:histogram binCount:256];
        medianMinMax.min = MIN(median, medianMinMax.min);
        medianMinMax.max = MAX(median, medianMinMax.max);
    }
    return medianMinMax;
}

- (cv::Mat)tiledImageFromLocations:(cv::vector<cv::Point>)locations {
    return [self prepareImageWithoutEqualizingWithLocations:locations];
}

- (cv::vector<cv::Point>)allLocationsFromLocation:(cv::Point)location controlPoints:(cv::vector<cv::Point>)controlPoints {
    cv::vector<cv::Point> allLocations;
    allLocations.push_back(location);
    for (int i = 0; i < controlPoints.size(); i++) {
        allLocations.push_back(controlPoints[i]);
    }
    return allLocations;
}

- (cv::vector<cv::Point>)allLocationsFromLocations:(cv::vector<cv::Point>)locations controlPoints:(cv::vector<cv::Point>)controlPoints {
    cv::vector<cv::Point> allLocations;
    for (int i = 0; i < locations.size(); i++) {
        allLocations.push_back(locations[i]);
    }
    for (int i = 0; i < controlPoints.size(); i++) {
        allLocations.push_back(controlPoints[i]);
    }
    return allLocations;
}

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations {
    return [self probabilitiesOfBricksAtLocations:locations withHistogramBinCount:HISTOGRAM_BIN_COUNT];
}

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations withHistogramBinCount:(int)histogramBinCount {
    @synchronized([BoardCalibrator instance].boardImageLock) {
        cv::Mat preparedImage = [self prepareImageWithLocations:locations];
        cv::vector<float> probabilities;
        for (int i = 0; i < locations.size(); i++) {
            probabilities.push_back([self probabilityOfBrickAtIndex:i inTiledImage:preparedImage withHistogramBinCount:histogramBinCount]);
        }
        return probabilities;
    }
}

- (float)probabilityOfBrickAtIndex:(int)index inTiledImage:(cv::Mat)tiledImage withHistogramBinCount:(int)histogramBinCount {
    cv::Mat equalizedBrickImage = [self extractBrickImageFromIndex:index inTiledImage:tiledImage];
    cv::Mat equalizedHistogram = [self calculateHistogramFromImage:equalizedBrickImage binCount:histogramBinCount];
    CGSize brickSize = [self brickSizeFromBoardImage];
    return equalizedHistogram.at<float>(0) / (float)(brickSize.width * brickSize.height);
}

- (float)calculateMedianOfHistogram:(cv::Mat)histogram binCount:(int)binCount {
    CGSize smallerBrickSize = [self brickSizeFromBoardImage];
    float median = 0.0f;
    for (int i = 0; i < binCount; i++) {
        median += histogram.at<float>(i) * (float)i / ((int)smallerBrickSize.width * (int)smallerBrickSize.height);
    }
    return median;
}

- (float)calculateModeOfHistogram:(cv::Mat)histogram binCount:(int)binCount {
    float max = 0.0f;
    int mode = 0;
    for (int i = 0; i < binCount; i++) {
        if (histogram.at<float>(i) > max) {
            max = histogram.at<float>(i);
            mode = i;
        }
    }
    return mode;
}

- (cv::Mat)calculateHistogramFromImage:(cv::Mat)image binCount:(int)binCount {
    cv::Mat histogram;
    float range[] = {0, 256};
    const float *histRange = {range};
    cv::calcHist(&image, 1, 0, cv::Mat(), histogram, 1, &binCount, &histRange);
    return histogram;
}

- (cv::Mat)extractBrickImageFromLocation:(cv::Point)location {
    CGRect rect = [[BoardUtil instance] brickRectWithPosition:location screenSize:[BoardCalibrator instance].boardImageSize];
    cv::Rect cvRect;
    cvRect.x = rect.origin.x;
    cvRect.y = rect.origin.y;
    cvRect.width = rect.size.width;
    cvRect.height = rect.size.height;
    return cv::Mat([BoardCalibrator instance].boardImage, cvRect);
}

- (cv::Mat)extractBrickImageFromIndex:(int)index inTiledImage:(cv::Mat)image {
    CGSize brickSize = [self brickSizeFromBoardImage];
    cv::Rect rect = cv::Rect((int)brickSize.width * index,
                             0,
                             (int)brickSize.width,
                             (int)brickSize.height);
    return cv::Mat(image, rect);
}

- (cv::Mat)prepareImageWithLocations:(cv::vector<cv::Point>)locations {
    cv::Mat preparedImage = [self prepareImageWithoutEqualizingWithLocations:locations].clone();
    return [self equalizeImage:preparedImage];
}

- (UIImage *)tiledImageWithLocations:(cv::vector<cv::Point>)locations {
    @autoreleasepool {
        @synchronized([BoardCalibrator instance].boardImageLock) {
            //cv::Mat image = [self prepareImageWithoutEqualizingWithLocations:locations];
            cv::Mat image = [self prepareImageWithLocations:locations];
            return [Util drawGridOnTiledImage:[UIImage imageWithCVMat:image] count:locations.size()];
        }
    }
}

- (UIImage *)imageNumber:(int)index withLocations:(cv::vector<cv::Point>)locations {
    @autoreleasepool {
        @synchronized([BoardCalibrator instance].boardImageLock) {
            cv::Mat tiledImage = [self prepareImageWithoutEqualizingWithLocations:locations];
            cv::Mat image = [self extractBrickImageFromIndex:index inTiledImage:tiledImage].clone();
            return [UIImage imageWithCVMat:image];
        }
    }
}

- (cv::Mat)prepareImageWithoutEqualizingWithLocations:(cv::vector<cv::Point>)locations {
    CGSize brickSize = [self brickSizeFromBoardImage];
    cv::Mat tiledImage = cv::Mat((int)brickSize.height, (int)brickSize.width * (int)locations.size(), [BoardCalibrator instance].boardImage.type());
    for (int i = 0; i < locations.size(); i++) {
        cv::Mat brickImage = [self extractBrickImageFromLocation:locations[i]];
        cv::Rect roi(cv::Point((int)brickSize.width * i, 0), brickImage.size());
        brickImage.copyTo(tiledImage(roi));
    }
    return tiledImage;
}

- (cv::Mat)equalizeImage:(cv::Mat)image {
    cv::Mat equalizedImage;
    cv::equalizeHist(image, equalizedImage);
    return equalizedImage;
}

- (CGSize)brickSizeFromBoardImage {
    CGRect canvasRect = [[BoardUtil instance] canvasRectWithScreenSize:[BoardCalibrator instance].boardImageSize];
    return [[BoardUtil instance] brickSizeWithGridRect:[[BoardUtil instance] gridRectWithCanvasSize:canvasRect.size]];
}

@end
