//
//  PickerViewToolBar.m
//  Reposit
//
//  Created by Morgan Chen on 2/5/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "PickerViewToolBar.h"

@interface PickerViewToolBar() <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, readonly, assign) CGFloat initialY;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

static const CGFloat kVelocityToDismissKeyboard = 100;
static const NSTimeInterval kAnimationDuration = 0.25;

@implementation PickerViewToolBar

#pragma mark - Initializers and Life Cycle methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _initialY = 0;
        
        // notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    // prevent message sends to deallocated objects
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

#pragma mark - Gesture recognizer

- (IBAction)panHandler:(UIPanGestureRecognizer *)sender {
    // disable everything while moving
    self.pickerView.userInteractionEnabled = NO;
    self.cancelButton.enabled = NO;
    self.saveButton.enabled = NO;
    
    CGPoint translation = [sender translationInView:self];
    if (!(self.initialY)) {
        _initialY = self.superview.frame.origin.y;
    }
    
    // clamp
    if (translation.y < 0) {
        translation.y = 0;
    }
    
    // move view around based on drag, abusing view hierarchy
    CGRect tempFrame = self.superview.frame;
    tempFrame.origin.y = self.initialY + translation.y;
    self.superview.frame = tempFrame;
    
    // handle keyboard dismissal on gesture end
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGFloat keyboardViewHeight = [UIScreen mainScreen].bounds.size.height - self.initialY;
        
        // reenable everything at the end of animation
        void (^reenableInputBlock)() = ^{
            self.pickerView.userInteractionEnabled = YES;
            self.cancelButton.enabled = YES;
            self.saveButton.enabled = YES;
        };
        
        // should never be less than 0 because keyboardViewHeight > translation.y
        double fractionOfViewLeftToDismiss = (keyboardViewHeight - translation.y) / keyboardViewHeight;
        
        if ((translation.y > keyboardViewHeight / 2) || ([sender velocityInView:self].y > kVelocityToDismissKeyboard)) {
            tempFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
            [UIView animateWithDuration:kAnimationDuration*fractionOfViewLeftToDismiss animations:^{
                self.superview.frame = tempFrame;
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView setAnimationsEnabled:NO];
                    [self.textField resignFirstResponder];
                    
                    reenableInputBlock();
                }
            }];
        }
        else {
            tempFrame.origin.y = self.initialY;
            [UIView animateWithDuration:1.8*kAnimationDuration * (1 - fractionOfViewLeftToDismiss) animations:^{
                self.superview.frame = tempFrame;
            } completion:^(BOOL finished) {
                reenableInputBlock();
            }];
        }
    }
}

- (void)keyboardDidHide {
    [UIView setAnimationsEnabled:YES];
}

@end
