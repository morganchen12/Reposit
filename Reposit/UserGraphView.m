//
//  UserGraphView.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UserGraphView.h"
#import "GitHubHelper.h"
#import "Repository.h"
#import <OctoKit/OctoKit.h>

static const float kGraphInset = 60.0;
static const NSInteger kGraphAxesLabelFontSize = 10;
static const NSInteger kLabelValueOffset = 10;

@interface UserGraphView()

@property (nonatomic, readwrite, copy) NSDictionary *stats;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) NSInteger largestValue;

@end

@implementation UserGraphView

#pragma mark - Property accessors

- (void)setRepository:(Repository *)repository {
    _repository = repository;
    
    // indicate activity
    if (!(self.activityIndicator)) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.hidesWhenStopped = YES;
        
        // position indicator in center of view
        CGRect newFrame = self.activityIndicator.frame;
        newFrame.origin = CGPointMake((self.superview.frame.size.width - self.activityIndicator.frame.size.width) / 2,
                                      (self.frame.size.height - self.activityIndicator.frame.size.height) /2);
        self.activityIndicator.frame = newFrame;
        
        [self addSubview:self.activityIndicator];
    }
    
    [self.activityIndicator startAnimating];
    
    [[GitHubHelper sharedHelper] participationForRepositoryWithName:_repository.name
                                                              owner:_repository.owner
                                                         completion:^(NSArray *results) {
                                                             self.stats = [results[0] parsedResult];
                                                             [self.activityIndicator stopAnimating];
                                                             [self setNeedsDisplay];
                                                         }];
}

#pragma mark - Custom drawing

// draw graph
- (void)drawRect:(CGRect)rect {
    
    // don't draw anything if no data is available
    if (!(self.stats)) {
        // do nothing in here
        
        return;
    }
    
    self.opaque = NO;
    self.alpha = 0;
    
    // inset graph by 16 points to be consistent with margins
    CGRect graphContainer = CGRectInset(self.bounds, 8, 8);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *pointHeights = [self mapStatsToPoints];
    
    // assemble array of actual CGPoint structs
    // numPoints can be used to determine horizontal spacing
    // between data points
    NSInteger numPoints = pointHeights.count;
    
    // can't draw one or less points
    if (numPoints <= 1) {
        
        NSString *errorMessage = @"No data";
        UIColor *errorColor = [UIColor lightGrayColor];
        
        NSDictionary *errorMessageAttributes = @{
                                                 NSFontAttributeName: [UIFont systemFontOfSize:20],
                                                 NSForegroundColorAttributeName: errorColor,
                                                 };
        
        CGSize errorMessageSize = [errorMessage sizeWithAttributes:errorMessageAttributes];
        
        [errorMessage drawAtPoint:CGPointMake((self.bounds.size.width - errorMessageSize.width) / 2,
                                              (self.bounds.size.height - errorMessageSize.height) / 2)
                   withAttributes:errorMessageAttributes];
        
        return;
    }
    
    // flip context so graphing things makes sense
    CGContextTranslateCTM(context, 0.0, graphContainer.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGPoint *points = calloc(numPoints, sizeof(CGPoint));
    
    // rect taking up most of the upper right space of the graph, leaving room
    // for axes on the left and bottom.
    CGRect graphRect = graphContainer;
    graphRect.origin = CGPointMake(kGraphInset, kGraphInset);
    graphRect.size.width -= kGraphInset;
    graphRect.size.height -= kGraphInset;
    
    // calculate graph height to be next multiple of 10 above largest value
    int maxY = (int)self.largestValue;
    int newMaxY = maxY;
    
    int remainder = 1;
    while (remainder != 0) {
        newMaxY++;
        remainder = newMaxY % 10;
    }
    
    float adjustedHeight = graphRect.size.height * ((float)maxY/newMaxY);
    
    
    // scale point doubles to height/width of graph
    for (NSInteger i = 0; i < numPoints; i++) {
        int x = ((i+1) * graphRect.size.width / (numPoints)) + graphRect.origin.x;
        int y = ([pointHeights[i] floatValue] * adjustedHeight) + graphRect.origin.y;
        
        points[i] = CGPointMake(x, y);
    }
    
    // draw background lines
    UIColor *veryLightGray = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.6];
    CGContextSetStrokeColorWithColor(context, veryLightGray.CGColor);
    CGContextSetLineWidth(context, 0.5);
    
    CGContextBeginPath (context);
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    
    // vertical lines
    for (NSInteger i = 0; i < numPoints; i++) {
        // move to desired x, then draw line to full height of graph
        CGContextMoveToPoint(context, points[i].x, graphRect.origin.y);
        CGContextAddLineToPoint(context, points[i].x, graphRect.origin.y + graphRect.size.height);
        
        // then move back to x axis
        CGContextMoveToPoint(context, points[i].x, graphRect.origin.y);
    }
    
    // horizontal lines
    int numVerticalLines = newMaxY/10;
    if (newMaxY < 50) {
        numVerticalLines = newMaxY/5;
    }
    for (NSInteger i = 0; i < numVerticalLines; i++) {
        // move to desired y, then draw line to full width of graph
        float y = (i+1)*(graphRect.size.height / numVerticalLines) + graphRect.origin.y;
        
        CGContextMoveToPoint(context, graphRect.origin.x, y);
        CGContextAddLineToPoint(context, graphRect.origin.x + graphRect.size.width, y);
        
        // then move back to y axis
        CGContextMoveToPoint(context, graphRect.origin.x, y);
    }
    
    CGContextStrokePath(context);
    
    // draw axes
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    CGContextAddLineToPoint(context,
                            graphRect.origin.x + graphRect.size.width,
                            graphRect.origin.y);
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    CGContextAddLineToPoint(context,
                            graphRect.origin.x,
                            graphRect.origin.y + graphRect.size.height);
    CGContextStrokePath(context);
    
    
    // set color and line width
    UIColor *tealish = [UIColor colorWithRed:0.0   / 255
                                       green:144.0 / 255
                                        blue:163.0 / 255
                                       alpha:1.0];
    
    CGContextSetStrokeColorWithColor(context, tealish.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    // draw graph
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    
    for (NSInteger i = 0; i < numPoints; i++) {
        CGContextAddLineToPoint(context, points[i].x, points[i].y);
        CGContextMoveToPoint(context, points[i].x, points[i].y);
    }
    
    // save g state before and restore after to maintain path
    CGContextStrokePath(context);
    
    // reconstruct path
    // draw path for gradient
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, graphRect.origin.x, graphRect.origin.y);
    
    for (NSInteger i = 0; i < numPoints; i++) {
        CGContextAddLineToPoint(context, points[i].x, points[i].y);
    }
    
    // close path
    CGContextAddLineToPoint(context, graphRect.origin.x + graphRect.size.width, graphRect.origin.y);
    CGContextClosePath(context);
    
    // push to context stack and save state to clip gradient
    CGContextSaveGState(context);
    CGContextClip(context);
    
    // draw gradient
    UIColor *startingColor = [UIColor colorWithRed:0.0   / 255
                                                 green:144.0 / 255
                                                  blue:163.0 / 255
                                                 alpha:0.4];
    UIColor *endingColor = [UIColor colorWithRed:0.0   / 255
                                           green:144.0 / 255
                                            blue:163.0 / 255
                                           alpha:0.1];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = {0.0, 1.0};
    NSArray *colors = @[(__bridge id)(startingColor.CGColor), (__bridge id)(endingColor.CGColor)];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    
    CGPoint startPoint = CGPointMake(graphRect.origin.x, graphRect.origin.y + adjustedHeight);
    CGPoint endPoint = CGPointMake(graphRect.origin.x, graphRect.origin.y);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kNilOptions);
    
    // restore state when done drawing clipped gradient
    CGContextRestoreGState(context);
    
    // release gradient and color space
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    // draw circles at data points
    float rectOffset = 1.0;
    
    for (NSInteger i = 0; i < numPoints; i++) {
        CGContextMoveToPoint(context, points[i].x, points[i].y);
        CGContextBeginPath(context);

        CGRect rect= CGRectMake ((points[i].x - rectOffset), (points[i].y - rectOffset), rectOffset*2, rectOffset*2);
        CGContextAddEllipseInRect(context, rect);
        
        CGContextStrokePath(context);
    }
    
    // no memory leaks
    free(points);

    // save state and flip context again so labels are right side up
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, graphContainer.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // label axes
    
    // y-axis
    NSString *yAxisLabel = @"Commits";
    NSDictionary *yAxisLabelAttributes = @{
                                           NSFontAttributeName: [UIFont systemFontOfSize:kGraphAxesLabelFontSize],
                                           NSForegroundColorAttributeName: [UIColor blackColor],
                                           };
    
    CGSize sizeForYAxisLabel = [yAxisLabel sizeWithAttributes:yAxisLabelAttributes];
    [yAxisLabel drawInRect:CGRectMake(graphContainer.origin.x,
                                      (graphContainer.origin.y + graphRect.size.height) / 2,
                                      sizeForYAxisLabel.width,
                                      sizeForYAxisLabel.height)
            withAttributes:yAxisLabelAttributes];
    
    // x-axis
    NSString *xAxisLabel = @"Weeks ago";
    NSDictionary *xAxisLabelAttributes = yAxisLabelAttributes;
    CGSize sizeForXAxisLabel = [xAxisLabel sizeWithAttributes:xAxisLabelAttributes];
    [xAxisLabel drawInRect:CGRectMake((graphContainer.origin.x + graphContainer.size.width) / 2,
                                      graphRect.size.height + graphContainer.origin.y + kGraphInset / 2 - sizeForXAxisLabel.height / 2,
                                      sizeForXAxisLabel.width,
                                      sizeForXAxisLabel.height)
            withAttributes:xAxisLabelAttributes];
    
    // label axes with min and max values
    NSString *xMinLabel = [NSString stringWithFormat:@"%ld", (long)numPoints];
    NSString *xMaxLabel = @"0";
    
    NSString *yMinLabel = @"0";
    NSString *yMaxLabel = [NSString stringWithFormat:@"%ld", (long)newMaxY];
    
    CGSize xMinLabelSize = [xMinLabel sizeWithAttributes:xAxisLabelAttributes];
    CGSize xMaxLabelSize = [xMaxLabel sizeWithAttributes:xAxisLabelAttributes];
    CGSize yMinLabelSize = [yMinLabel sizeWithAttributes:yAxisLabelAttributes];
    CGSize yMaxLabelSize = [yMaxLabel sizeWithAttributes:yAxisLabelAttributes];
    
    [xMinLabel drawInRect:CGRectMake(graphRect.origin.x - xMinLabelSize.width / 2,
                                     graphContainer.origin.y + graphRect.size.height + kLabelValueOffset - xMinLabelSize.height / 2,
                                     xMinLabelSize.width,
                                     xMinLabelSize.height)
           withAttributes:xAxisLabelAttributes];
    [xMaxLabel drawInRect:CGRectMake(graphContainer.size.width - xMaxLabelSize.width + graphContainer.origin.x / 2,
                                     graphContainer.origin.y + graphRect.size.height + kLabelValueOffset - xMinLabelSize.height / 2,
                                     xMaxLabelSize.width,
                                     xMaxLabelSize.height)
           withAttributes:xAxisLabelAttributes];
    
    [yMaxLabel drawInRect:CGRectMake(graphRect.origin.x - yMaxLabelSize.width - kLabelValueOffset - 4,
                                     graphContainer.origin.y - yMinLabelSize.height + 4,
                                     yMaxLabelSize.width,
                                     yMaxLabelSize.height)
           withAttributes:yAxisLabelAttributes];
    [yMinLabel drawInRect:CGRectMake(graphRect.origin.x - yMinLabelSize.width - kLabelValueOffset - 4,
                                     graphContainer.origin.y + graphRect.size.height - yMinLabelSize.height - 4,
                                     yMinLabelSize.width,
                                     yMinLabelSize.height)
           withAttributes:yAxisLabelAttributes];
    
    // pop context off of stack for sake of completeness
    CGContextRestoreGState(context);
    
    // fade in
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

- (NSArray *)mapStatsToPoints {
    // points are represented as doubles from 0 to 1, where 0 is
    // the bottom/leftmost side of the graph and 1 is the top/rightmost side.
    
    NSArray *rawData = self.stats[@"all"];
    NSInteger startIndex = 0;
    NSInteger largestValue = 0;
    
    // find earliest index with contributions to avoid graphing empty data points
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
    
    // shitty side effect deliberately introduced due to laziness
    self.largestValue = largestValue;
    
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:rawData.count - startIndex];
    
    // convert all values to doubles from 0 to 1
    for (NSInteger i = startIndex; i < rawData.count; i++) {
        double scaledDataPoint = [rawData[i] doubleValue] / largestValue;
        [returnArray addObject:@(scaledDataPoint)];
    }
    
    return [returnArray copy];
}


@end
