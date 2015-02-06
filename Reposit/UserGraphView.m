//
//  UserGraphView.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UserGraphView.h"
#import "GitHubHelper.h"
#import <OctoKit/OctoKit.h>

@interface UserGraphView()

@property (nonatomic, readwrite, copy) NSDictionary *stats;

@end

@implementation UserGraphView

#pragma mark - View lifecycle methods

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [[GitHubHelper sharedHelper] participationForRepositoryWithName:@"Reposit"
                                                              owner:@"morganchen12"
                                                         completion:^(NSArray *results) {
                                                             self.stats = [results[0] parsedResult];
                                                             [self setNeedsDisplay];
                                                         }];
}

#pragma mark - Custom drawing

// draw graph
- (void)drawRect:(CGRect)rect {
    
    // don't draw anything if no data is available
    if (!(self.stats)) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // outline
    CGRect strokeRect = CGRectInset(self.bounds, 1.5, 1.5);
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, strokeRect);
    
    NSArray *pointHeights = [self mapStatsToPoints];
    
    // assemble array of actual CGPoint structs
    // numPoints can be used to determine horizontal spacing
    // between data points
    NSInteger numPoints = pointHeights.count;
    CGPoint *points = calloc(numPoints, sizeof(CGPoint));
    
    for (NSInteger i = 0; i < numPoints; i++) {
        int x = (i) * (self.bounds.size.width / numPoints);
        int y = [pointHeights[i] floatValue] * self.bounds.size.height;
        
        points[i] = CGPointMake(x, y);
    }
    
    // set color and line width
    UIColor *tealish = [UIColor colorWithRed:0.0   / 255
                                       green:144.0 / 255
                                        blue:163.0 / 255
                                       alpha:1.0];
    
    CGContextSetStrokeColorWithColor(context, tealish.CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // draw
    CGContextBeginPath (context);
    CGContextMoveToPoint(context, 0, 0);
    
    for (NSInteger i = 0; i < numPoints; i++) {
        CGContextAddLineToPoint(context, points[i].x, points[i].y);
        CGContextMoveToPoint(context, points[i].x, points[i].y);
    }
    
    CGContextStrokePath(context);
    
    free(points);
}

- (NSArray *)mapStatsToPoints {
    // points are represented as doubles from 0 to 1, where 0 is
    // the bottom/leftmost side of the graph and 1 is the top/rightmost side.
    
    NSArray *rawData = self.stats[@"all"];
    NSInteger startIndex = 0;
    NSInteger largestValue = 0;
    
    // find earliest index with contributions to avoid graphing empty data points
    // this loop can be made faster, but array size is always 52 so it doesn't matter
    for (NSInteger i = 0; i < rawData.count; i++) {
        if ([rawData[i] intValue] == 0) {
            startIndex++;
        }
        else {
            break;
        }
    }
    
    // accumulate largest value in array to determine axes labels
    for (NSInteger i = startIndex; i < rawData.count; i++) {
        if ([rawData[i] intValue] > largestValue) {
            largestValue = [rawData[i] intValue];
        }
    }
    
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:rawData.count - startIndex];
    
    // convert all values to doubles from 0 to 1
    for (NSInteger i = startIndex; i < rawData.count; i++) {
        double scaledDataPoint = [rawData[i] doubleValue] / largestValue;
        [returnArray addObject:@(scaledDataPoint)];
    }
    
    return [returnArray copy];
}


@end
