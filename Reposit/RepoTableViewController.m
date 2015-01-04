//
//  RepoTableViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "RepoTableViewController.h"
#import "GitHubHelper.h"
#import "Repository.h"

@interface RepoTableViewController ()

@property (nonatomic, readwrite) NSArray *repositories;

@end

@implementation RepoTableViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = NO;
    
    // display an Edit button in the navigation bar for this view controller
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    // if github username is defined, fetch recent commits
    if ([GitHubHelper sharedHelper].currentUser) {
        self.repositories = [GitHubHelper sharedHelper].getRepos;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // prompt user to enter their github username
    if (![GitHubHelper sharedHelper].currentUser) {
        [self performSegueWithIdentifier:@"ShowSettings" sender:self];
    }
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    // Return the number of sections.
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.repositories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RepoCell" forIndexPath:indexPath];
    
    Repository *repo = (Repository *)(self.repositories[indexPath.row]);
    NSString *fullname = [NSString stringWithFormat:@"%@ / %@", repo.owner, repo.name];
    
    cell.textLabel.text = fullname;
    cell.detailTextLabel.text = @"  Checking recent commits...";
    
    [[GitHubHelper sharedHelper] currentUserDidCommitToRepo:repo completion:^(NSInteger daysSinceCommit) {
        if (daysSinceCommit != NSNotFound) {
            if (daysSinceCommit == 1) {
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
            cell.detailTextLabel.textColor = [UIColor redColor];
        }
    }];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[GitHubHelper sharedHelper] deleteRepository:self.repositories[indexPath.row]];
        [[GitHubHelper sharedHelper] saveContext];
        self.repositories = [GitHubHelper sharedHelper].getRepos;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
