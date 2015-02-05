//
//  UserGraphView.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UserGraphView.h"

@implementation UserGraphView


// draw graph
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, self.bounds);
}


@end
