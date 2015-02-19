//
//  UIPickerView+Configurations.h
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPickerView (Configurations)

/* Extremely hacky method, never look at its implementation or call on a picker view that's not
 * substituting for a keyboard.
 */
- (void)configureForTextFieldInputView;

@end
