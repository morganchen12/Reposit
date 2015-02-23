//
//  PickerViewToolBar.h
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PickerViewToolBarButtonDelegate <NSObject>

@required

- (void)toolBarCancelButtonPressed;
- (void)toolBarSaveButtonPressed;

@end

@interface PickerViewToolBar : UIToolbar

@property (nonatomic, weak) UIPickerView *pickerView;
@property (nonatomic, weak) id<PickerViewToolBarButtonDelegate> buttonDelegate;
@property (nonatomic, weak) UITextField *textField;

#pragma mark - Initializers and Life Cycle methods

+ (instancetype)toolBarFromNib;

@end
