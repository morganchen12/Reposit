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

@interface RepoDetailViewController ()

@property (nonatomic, readonly) NSArray *pickerOptions;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;

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
    
    // set up picker view
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // set up author label
    self.authorLabel.text = self.repository.owner;
    self.authorLabel.textColor = [UIColor grayColor];
    NSInteger row = [self.pickerOptions indexOfObject:self.repository.reminderPeriod];
    [self.pickerView selectRow:row inComponent:0 animated:NO];
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.text = ((NSNumber *)(self.pickerOptions[row])).stringValue;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSNumber *selected = (NSNumber *)(self.pickerOptions[row]);
    self.repository.reminderPeriod = selected;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerOptions.count;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowRepoWebView"]) {
        RepoWebViewController *destination = (RepoWebViewController *)(segue.destinationViewController);
        destination.repository = self.repository;
    }
}


@end
