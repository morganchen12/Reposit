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

// animation constants
static const float kCellPopulationAnimationDelay    = 0.05;
static const float kCellPopulationAnimationDuration = 0.25;

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
    NSString *fullname = [NSString stringWithFormat:@"%@ / %@", repo.owner, repo.name];
    
    cell.textLabel.text = fullname;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.text = @"  Checking recent commits...";
    
    // check if user has recently committed to their projects
    // note: this method may cause excessive api calls for a large number of Repository objects
    // (i.e. scrolling would call this method repeatedly), but it's generally unlikely that a
    // user has enough side projects to actually fill the entire page. If the GitHub API rate
    // limit becomes problematic, look here
    [[GitHubHelper sharedHelper] currentUserDidCommitToRepo:repo completion:^(NSInteger daysSinceCommit) {
        
        // recent commits found
        if (daysSinceCommit != NSNotFound) {
            
            // animate fade out label
            [UIView animateWithDuration:kCellPopulationAnimationDuration
                                  delay:kCellPopulationAnimationDelay
                                options:kNilOptions animations:^{
                                    cell.detailTextLabel.alpha = 0.0;
                                } completion:^(BOOL finished) {
                                    
                                }];
            
            // use spaces as poor man's indentation
            // update label on case-by-case basis for commits pushed today and yesterday
            if (daysSinceCommit == 0) {
                cell.detailTextLabel.text = @"  Last commit today";
            }
            else if (daysSinceCommit == 1) {
                cell.detailTextLabel.text = @"  Last commit yesterday";
            }
            
            // otherwise, generalize "x days ago"
            else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"  Last commit %li days ago", (long)daysSinceCommit];
            }
            
            // darkish green
            UIColor *green = [UIColor colorWithRed:0.07058823529
                                             green:0.38823529411
                                              blue:0.1725490196
                                             alpha:1.0];
            cell.detailTextLabel.textColor = green;
        }
        
        // no recent commits, berate user
        else {
            cell.detailTextLabel.text = @"  No recent commits";
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
        
        // animate fade in label
        [UIView animateWithDuration:kCellPopulationAnimationDuration
                              delay:(kCellPopulationAnimationDelay)
                            options:kNilOptions animations:^{
                                cell.detailTextLabel.alpha = 1.0;
                            } completion:^(BOOL finished) {
                                
                            }];
    }];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (self.repositories.count) {
        
        // clean up first-time user experience view if necessary
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
    }
    
    else {
        
        // display message when table is empty (also doubles as first-time user experience)
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
        [[UserHelper currentHelper] deleteRepository:self.repositories[indexPath.row]];
        [[UserHelper currentHelper] saveContext];
        
        // delete object from local array, preserving order
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
