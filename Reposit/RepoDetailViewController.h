//
//  RepoDetailViewController.h
//  Reposit
//
//  Created by Morgan Chen on 1/4/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Repository;
@protocol PickerViewToolBarButtonDelegate;

@interface RepoDetailViewController : UIViewController <UIPickerViewDataSource,
                                                        UIPickerViewDelegate,
                                                        UIToolbarDelegate,
                                                        PickerViewToolBarButtonDelegate>

@property (nonatomic, readwrite, weak) Repository *repository;

@end
