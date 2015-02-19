//
//  UISearchBar+Configurations.m
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UISearchBar+Configurations.h"

@implementation UISearchBar (Configurations)

- (void)configureForAddRepoTableViewController {
    UIColor *tealish = [UIColor colorWithRed: 0.0 / 255
                                       green:81.0 / 255
                                        blue:92.0 / 255
                                       alpha:1.0];
    self.tintColor = tealish;
    self.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.autocorrectionType = UITextAutocorrectionTypeNo;
}

@end
