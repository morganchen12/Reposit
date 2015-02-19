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

#import "UILabel+Configurations.h"
#import "UISearchBar+Configurations.h"
#import "UIRefreshControl+Configurations.h"
#import "UITableViewCell+Configurations.h"

@interface AddReposTableViewController () <UISearchBarDelegate>

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
    
    // configure refresh control
    [self.refreshControl configureForAddReposTableViewController];
    [self.refreshControl addTarget:self action:@selector(refreshRepos) forControlEvents:UIControlEventValueChanged];
    
    // configure appearance and stuff
    [self.searchBar configureForAddRepoTableViewController];
    self.searchBar.delegate = self;
    
    if (!(self.messageLabel)) {
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height)];
        
        // text left out of config method due to its dynamic nature--maybe this is bad?
        messageLabel.text = kLoadingMessage;
        
        // configure
        [messageLabel configureForAddRepoTableViewBackground];
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
    
    NSInteger offset = self.tableView.contentOffset.y -
                       self.refreshControl.frame.size.height -
                       self.searchBar.frame.size.height +
                       20;
    
    // programatically scroll up to show loading
    [self.tableView setContentOffset:CGPointMake(0, offset) animated:YES];
    [self.refreshControl sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - UITableViewDelegate

// check cells initially as they are selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedIndexPaths addObject:indexPath];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

// uncheck cells
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedIndexPaths removeObject:indexPath];
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchedRepositories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddRepoCell" forIndexPath:indexPath];
    
    OCTResponse *response = (OCTResponse *)(self.fetchedRepositories[indexPath.row]);
    
    [cell configureForAddRepoTableViewWithParsedResult:response.parsedResult];
    
    // maintain checkmarks as cells are reused
    // could use a dict instead of array to check for selected indexes if this becomes slow
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
