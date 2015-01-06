//
//  SettingsViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/2/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "SettingsViewController.h"
#import "GitHubHelper.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;

@end

@implementation SettingsViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userNameTextField.delegate = self;
    UIColor *tealish = [UIColor colorWithRed:0.0   / 255
                                       green:144.0 / 255
                                        blue:163.0 / 255
                                       alpha:1.0];
    self.userNameTextField.tintColor = tealish;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *currentUser = [GitHubHelper sharedHelper].currentUser;
    if (currentUser) {
        self.userNameTextField.text = currentUser;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Interface Builder Outlets

- (IBAction)saveButtonPressed:(id)sender {
    NSCharacterSet *whiteSpaceAndNewLine = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *userNameTrimmed = [self.userNameTextField.text stringByTrimmingCharactersInSet:whiteSpaceAndNewLine];
    
    // user name is valid if there are no internal spaces
    BOOL userNameIsValid = ([userNameTrimmed rangeOfCharacterFromSet:whiteSpaceAndNewLine].location == NSNotFound);
    
    // save current user if field is valid (does not contain whitespace)
    if (userNameIsValid) {
        [GitHubHelper sharedHelper].currentUser = userNameTrimmed;
    }
    
    // transition back to main view controller
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelButtonPressed:(id)sender {
    // transition back to main view controller
    [self.navigationController popViewControllerAnimated:YES];
}

@end
