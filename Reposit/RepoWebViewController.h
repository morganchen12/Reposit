//
//  RepoDetailViewController.h
//  Reposit
//
//  Created by Morgan Chen on 1/3/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Repository;

@interface RepoWebViewController : UIViewController

@property (nonatomic, readwrite, weak) Repository *repository;

@end
