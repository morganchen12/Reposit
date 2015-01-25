//
//  AddReposTableViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/3/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "AddReposTableViewController.h"
#import "GitHubHelper.h"

@interface AddReposTableViewController ()

@property (nonatomic, readwrite) NSArray *fetchedRepositories;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, readwrite) NSMutableArray *selectedIndexPaths;

@end

@implementation AddReposTableViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.selectedIndexPaths = [[NSMutableArray alloc] init];
    
    UIColor *tealish = [UIColor colorWithRed:0.0  / 255
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.searchBar.text = [GitHubHelper sharedHelper].currentUser;
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
    
    BOOL userNameIsValid = ([userNameTrimmed rangeOfString:@" "].location == NSNotFound);

    if (!userNameIsValid) {
        // stop refreshing and return
        [self.refreshControl endRefreshing];
        return;
    }
    
    if ([[GitHubHelper sharedHelper].currentUser isEqualToString:userNameTrimmed]) {
        [[GitHubHelper sharedHelper] publicReposFromCurrentUserWithCompletion:^(NSArray *repos) {
            self.fetchedRepositories = repos;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        }];
    }
    else {
        [[GitHubHelper sharedHelper] publicReposFromUser:userNameTrimmed completion:^(NSArray *repos) {
            self.fetchedRepositories = repos;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        }];
    }
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
    
    cell.textLabel.text = self.fetchedRepositories[indexPath.row][@"name"]; // use @"full_name" maybe
    
    // set description if provided
    cell.detailTextLabel.textColor = [UIColor grayColor];
    NSString *description = self.fetchedRepositories[indexPath.row][@"description"];
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
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.fetchedRepositories.count) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else {
        // display message when table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height)];
        messageLabel.text = @"Loading...\n\nIf this message persists, check your internet connection.";
        messageLabel.textColor = [UIColor darkGrayColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:22];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
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
            [[GitHubHelper sharedHelper] saveRepoFromJSONObject:self.fetchedRepositories[indexPath.row]];
        }
        [[GitHubHelper sharedHelper] saveContext];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
