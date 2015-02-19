//
//  RepoTableViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "RepoTableViewController.h"
#import "RepoDetailViewController.h"
#import "LocalNotificationHelper.h"
#import "GitHubHelper.h"
#import "SessionHelper.h"
#import "UserHelper.h"
#import "Repository.h"

#import "UITableViewCell+Configurations.h"
#import "UILabel+Configurations.h"

@interface RepoTableViewController ()

@property (nonatomic, readwrite) NSArray *repositories;

@end

@implementation RepoTableViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // don't preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // if current user exists, fetch recent commits
    if ([SessionHelper currentSession].currentUser) {
        self.repositories = [UserHelper currentHelper].getRepos;
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // prompt user to enter their github username if it's not saved
    if (!([SessionHelper currentSession].currentUser &&
          [GitHubHelper sharedHelper].client)) {
        
        [[GitHubHelper sharedHelper] signInToGitHub];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.repositories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepoCell" forIndexPath:indexPath];
    
    // assemble "username / Repository" format for cell text from core data objects
    Repository *repo = (Repository *)(self.repositories[indexPath.row]);
    
    // configure cell for given repository
    [cell configureForRepoTableViewWithRepository:repo];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (self.repositories.count) {
        
        // clean up empty table view background view if necessary
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    
    else {
        
        // display message when table is empty (also doubles as first-time user experience)
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height)];
        
        [messageLabel configureForRepoTableViewBackground];
        
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // delete object from core data
        [[UserHelper currentHelper] deleteRepository:self.repositories[indexPath.row]];
        [[UserHelper currentHelper] saveContext];
        
        // animate deletion in table view
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ShowRepoDetail" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // boilerplate to pass along Repository object and assign back button text
    if ([segue.identifier isEqualToString:@"ShowRepoDetail"]) {
        self.navigationItem.backBarButtonItem.title = @"Save";
        RepoDetailViewController *destination = (RepoDetailViewController *)[segue destinationViewController];
        NSInteger selection = [self.tableView indexPathForSelectedRow].row;
        destination.repository = self.repositories[selection];
    }
}


@end
