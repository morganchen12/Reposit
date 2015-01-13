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
#import "Repository.h"

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
    
    // if github username is defined, fetch recent commits
    if ([GitHubHelper sharedHelper].currentUser) {
        self.repositories = [GitHubHelper sharedHelper].getRepos;
        [self.tableView reloadData];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // prompt user to enter their github username if it's not saved
    if (![GitHubHelper sharedHelper].currentUser) {
        [self performSegueWithIdentifier:@"ShowSettings" sender:self];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.repositories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepoCell" forIndexPath:indexPath];
    
    Repository *repo = (Repository *)(self.repositories[indexPath.row]);
    NSString *fullname = [NSString stringWithFormat:@"%@ / %@", repo.owner, repo.name];
    
    cell.textLabel.text = fullname;
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = @"  Checking recent commits...";
    
    [[GitHubHelper sharedHelper] currentUserDidCommitToRepo:repo completion:^(NSInteger daysSinceCommit) {
        if (daysSinceCommit != NSNotFound) {
            if (daysSinceCommit == 0) {
                cell.detailTextLabel.text = @"  Last commit today";
            }
            else if (daysSinceCommit == 1) {
                cell.detailTextLabel.text = @"  Last commit yesterday";
            }
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"  Last commit %li days ago", (long)daysSinceCommit];
            }
            UIColor *green = [UIColor colorWithRed:0.07058823529
                                             green:0.38823529411
                                              blue:0.1725490196
                                             alpha:1.0];
            cell.detailTextLabel.textColor = green;
        }
        else {
            cell.detailTextLabel.text = @"  No recent commits";
            cell.detailTextLabel.textColor = [UIColor colorWithRed:214.0 / 255
                                                             green:0.0   / 255
                                                              blue:21.0  / 255
                                                             alpha:1.0];
        }
    }];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.repositories.count) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    else {
        // display message when table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                          0,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height)];
        messageLabel.text = @"No active repositories :(\n\nTap the '+' in the upper right corner to get started.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont systemFontOfSize:22];
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
        [[GitHubHelper sharedHelper] deleteRepository:self.repositories[indexPath.row]];
        [[GitHubHelper sharedHelper] saveContext];
        
        // delete object from local array, preserving order
        NSMutableArray *tempRepos = [self.repositories mutableCopy];
        [tempRepos removeObjectAtIndex:indexPath.row];
        self.repositories = [tempRepos copy];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ShowRepoDetail" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowRepoDetail"]) {
        self.navigationItem.backBarButtonItem.title = @"Save";
        RepoDetailViewController *destination = (RepoDetailViewController *)[segue destinationViewController];
        NSInteger selection = [self.tableView indexPathForSelectedRow].row;
        destination.repository = self.repositories[selection];
    }
}


@end
