//
//  UserGraphView.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UserGraphView.h"
#import "GitHubHelper.h"

@interface UserGraphView()

@property (nonatomic, readwrite, copy) NSDictionary *stats;

@end

@implementation UserGraphView


// draw graph
- (void)drawRect:(CGRect)rect {
    [[GitHubHelper sharedHelper] participationForRepositoryWithName:@"Reposit"
                                                              owner:@"morganchen12"
                                                         completion:^(NSDictionary *results) {
                                                             self.stats = results;
                                                         }];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, self.bounds);
}


@end
