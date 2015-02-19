//
//  UITableViewCell+Configurations.h
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Repository;

@interface UITableViewCell (Configurations)

- (void)configureForRepoTableViewWithRepository:(Repository *)repo;
- (void)configureForAddRepoTableViewWithParsedResult:(NSDictionary *)result;

@end
