//
//  RepoDetailViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/4/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "RepoDetailViewController.h"
#import "RepoWebViewController.h"
#import "Repository.h"
#import "UserHelper.h"
#import "SessionHelper.h"
#import "PickerViewToolBar.h"

@interface RepoDetailViewController ()

@property (nonatomic, readonly) NSArray *pickerOptions;

@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) PickerViewToolBar *toolBar;

@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation RepoDetailViewController

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _pickerOptions = @[@2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up picker view and toolbar
    if (!(self.pickerView)) self.pickerView = [[UIPickerView alloc] init];
    if (!(self.toolBar)) self.toolBar = [PickerViewToolBar toolBarFromNib];
    
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.toolBar.pickerView = self.pickerView;
    self.toolBar.buttonDelegate = self;
    
    self.textField.inputView = self.pickerView;
    self.textField.inputAccessoryView = self.toolBar;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // set up author label
    self.authorLabel.text = self.repository.owner;
    self.authorLabel.textColor = [UIColor grayColor];
    
    // set up picker view
    NSInteger row = [self.pickerOptions indexOfObject:self.repository.reminderPeriod];
    [self.pickerView selectRow:row inComponent:0 animated:NO];
    
    // set up text field
    self.textField.text = [self.repository.reminderPeriod stringValue];
}

#pragma mark - property accessors

- (void)setRepository:(Repository *)repository {
    _repository = repository;
    self.navigationItem.title = _repository.name;
    self.authorLabel.text = _repository.owner;
    self.authorLabel.textColor = [UIColor grayColor];
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    // center text in label in picker view
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.text = ((NSNumber *)(self.pickerOptions[row])).stringValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerOptions.count;
}

#pragma mark - PickerViewToolBarButtonDelegate

- (void)toolBarCancelButtonPressed {
    [self.textField resignFirstResponder];
}

- (void)toolBarSaveButtonPressed {
    NSNumber *selection = self.pickerOptions[[self.pickerView selectedRowInComponent:0]];
    self.repository.reminderPeriod = selection;
    self.textField.text = [selection stringValue];
    [[SessionHelper currentSession].currentUser saveContext];
    [self.textField resignFirstResponder];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowRepoWebView"]) {
        RepoWebViewController *destination = (RepoWebViewController *)(segue.destinationViewController);
        destination.repository = self.repository;
    }
}


@end
