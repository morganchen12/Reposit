//
//  UILabel+Configurations.m
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UILabel+Configurations.h"

static const CGFloat kBackgroundLabelFontSize = 22.0;

@implementation UILabel (Configurations)

- (void)configureForRepoTableViewBackground {
    static NSString *noReposMessage = @"No active repositories :(\n\nTap the '+' in the upper right corner to get started.";
    self.text = noReposMessage;
    self.textColor = [UIColor blackColor];
    self.numberOfLines = 0;
    self.textAlignment = NSTextAlignmentCenter;
    self.font = [UIFont systemFontOfSize:kBackgroundLabelFontSize];
}

- (void)configureForAddRepoTableViewBackground {
    self.textColor = [UIColor darkGrayColor];
    self.numberOfLines = 0;
    self.textAlignment = NSTextAlignmentCenter;
    self.font = [UIFont systemFontOfSize:kBackgroundLabelFontSize];
}

- (void)configureForPickerView {
    
    // center text in label in picker view
    self.textAlignment = NSTextAlignmentCenter;
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor whiteColor];
}

@end
