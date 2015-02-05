//
//  PickerViewToolBar.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "PickerViewToolBar.h"

@interface PickerViewToolBar()

@end

@implementation PickerViewToolBar

#pragma mark - Initializers and Life Cycle methods

+ (instancetype)toolBarFromNib {
    PickerViewToolBar *toolBar = [[NSBundle mainBundle] loadNibNamed:@"PickerViewToolBar" owner:nil options:nil][0];
    return toolBar;
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self.buttonDelegate toolBarCancelButtonPressed];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self.buttonDelegate toolBarSaveButtonPressed];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
