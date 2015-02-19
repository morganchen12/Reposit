//
//  UIPickerView+Configurations.m
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UIPickerView+Configurations.h"

@implementation UIPickerView (Configurations)

- (void)configureForTextFieldInputView {
    // mess with appearances
    
    UIColor *tealish = [UIColor colorWithRed: 0.0 / 255
                                       green:81.0 / 255
                                        blue:92.0 / 255
                                       alpha:1.0];
    
    for (CALayer *layer in self.layer.sublayers) {
        layer.backgroundColor = tealish.CGColor;
    }
    
    [self.layer.sublayers[0] setBackgroundColor:[UIColor clearColor]];
    [self.layer.sublayers[0] setOpaque:NO];
    
    // evil hack to grab views related to the gray thing behind the keyboard
    UIView *pickerViewContainerView = [[[UIApplication sharedApplication].windows[1] subviews][0] subviews][0];
    UIView *keyboardInputBackdropView;
    UIView *pickerViewBackgroundView;
    if (pickerViewContainerView.subviews.count) {
        keyboardInputBackdropView = pickerViewContainerView.subviews[0];
        pickerViewBackgroundView = keyboardInputBackdropView.subviews[0];
        
        // ruin apple UI dreams by deleting gray bg view
        for (UIView *subview in pickerViewBackgroundView.subviews) {
            [subview removeFromSuperview];
        }
    }
    
    if (!(pickerViewBackgroundView.subviews.count)) {
        UIView *dimView = [[UIView alloc] initWithFrame:pickerViewContainerView.frame];
        
        dimView.layer.backgroundColor = [UIColor blackColor].CGColor;
        dimView.layer.opaque = NO;
        dimView.layer.opacity = 0.8;
        
        [pickerViewBackgroundView addSubview:dimView];
    }

}

@end
