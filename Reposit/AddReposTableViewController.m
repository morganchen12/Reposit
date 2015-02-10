//
//  AddReposTableViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/3/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "AddReposTableViewController.h"
#import "GitHubHelper.h"
#import "UserHelper.h"
#import "SessionHelper.h"

// animation constants
static const float kCellPopulationAnimationDelay    = 0.01;
static const float kCellPopulationAnimationDuration = 0.4;

@interface AddReposTableViewController ()

@property (nonatomic, readwrite) NSArray *fetchedRepositories;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, readwrite) NSMutableArray *selectedIndexPaths;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation AddReposTableViewController

static NSString *kLoadingMessage = @"Loading...\n\nIf this message persists, check your internet connection.";
static NSString *kNoResultsMessage = @"No results";

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedIndexPaths = [[NSMutableArray alloc] init];
    
    UIColor *tealish = [UIColor colorWithRed: 0.0 / 255
                                       green:81.0 / 255
                                        blue:92.0 / 255
                                       alpha:1.0];
    self.refreshControl.backgroundColor = tealish;
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(refreshRepos) forControlEvents:UIControlEventValueChanged];
    
    self.searchBar.tintColor = tealish;
    self.searchBar.delegate = self;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    if (!(self.messageLabel)) {
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height)];
        messageLabel.text = kLoadingMessage;
        messageLabel.textColor = [UIColor darkGrayColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:22];
        [messageLabel sizeToFit];
        self.messageLabel = messageLabel;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.searchBar.text = [SessionHelper currentSession].currentUser.username;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // fetch repos from Github
    [self.refreshControl beginRefreshing];
    NSInteger offset = self.tableView.contentOffset.y-self.refreshControl.frame.size.height;
    [self.tableView setContentOffset:CGPointMake(0, offset) animated:YES];
    [self.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - UIRefreshControl

// do not call directly! use [self.refreshControl beginRefreshing instead]
- (void)refreshRepos {
    NSCharacterSet *whiteSpaceAndNewLine = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *userNameTrimmed = [self.searchBar.text stringByTrimmingCharactersInSet:whiteSpaceAndNewLine];
    
    self.messageLabel.text = kLoadingMessage;
    
    BOOL userNameIsValid = ([userNameTrimmed rangeOfString:@" "].location == NSNotFound);

    if (!userNameIsValid) {
        // stop refreshing and return
        [self.refreshControl endRefreshing];
        return;
    }
    
    [[GitHubHelper sharedHelper] publicReposFromUser:userNameTrimmed completion:^(NSArray *repos) {
        self.fetchedRepositories = repos;
        
        // if no results, display "no results"
        if (!(repos.count)) {
            self.messageLabel.text = kNoResultsMessage;
            self.fetchedRepositories = @[];
        }
        
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    
    // deselect all cells before refreshing
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedIndexPaths) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    [self.refreshControl beginRefreshing];
    NSInteger offset = self.tableView.contentOffset.y-self.refreshControl.frame.size.height-(self.searchBar.frame.size.height+20);
    [self.tableView setContentOffset:CGPointMake(0, offset) animated:YES];
    [self.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedIndexPaths addObject:indexPath];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedIndexPaths removeObject:indexPath];
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.fetchedRepositories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddRepoCell" forIndexPath:indexPath];
    
    UIColor *tealish = [UIColor colorWithRed:0.0   / 255
                                       green:144.0 / 255
                                        blue:163.0 / 255
                                       alpha:1.0];
    cell.tintColor = tealish;
    
    OCTResponse *response = (OCTResponse *)(self.fetchedRepositories[indexPath.row]);
    NSDictionary *result = (NSDictionary *)(response.parsedResult);
    
    cell.textLabel.text = result[@"name"]; // use @"full_name" maybe
    
    // set description if provided
    cell.detailTextLabel.textColor = [UIColor grayColor];
    NSString *description = result[@"description"];
    if (description && (NSNull *)description != [NSNull null]) {
        cell.detailTextLabel.text = description;
    }
    else {
        cell.detailTextLabel.text = @"";
    }
    
    // check marks
    if ([self.selectedIndexPaths containsObject:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // animate
    cell.textLabel.alpha = 0.0;
    cell.detailTextLabel.alpha = 0.0;
    
    [UIView animateWithDuration:kCellPopulationAnimationDuration
                          delay:(kCellPopulationAnimationDelay)
                        options:kNilOptions animations:^{
                            cell.textLabel.alpha = 1.0;
                            cell.detailTextLabel.alpha = 1.0;
                        } completion:^(BOOL finished) {
                            
                        }];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.fetchedRepositories.count) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else {
        // display message when table is empty
        
        self.tableView.backgroundView = self.messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 1;
}

#pragma mark - Interface builder outlets

- (IBAction)cancelButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveButtonPressed:(id)sender {
    // save all selected and pop view controller
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if (selectedRows.count > 0) {
        for (NSIndexPath *indexPath in selectedRows) {
            NSDictionary *JSONObject = ((OCTResponse *)(self.fetchedRepositories[indexPath.row])).parsedResult;
            
            [[UserHelper currentHelper] saveRepoFromJSONObject:JSONObject];
        }
        [[UserHelper currentHelper] saveContext];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
