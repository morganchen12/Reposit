//
//  UITableViewCell+Configurations.m
//  Reposit
//
//  Created by Morgan Chen on 2/19/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "UITableViewCell+Configurations.h"
#import "Repository.h"
#import "GitHubHelper.h"

// animation constants
static const float kCellPopulationAnimationDelay    = 0.05;
static const float kCellPopulationAnimationDuration = 0.3;

@implementation UITableViewCell (Configurations)

- (void)configureForRepoTableViewWithRepository:(Repository *)repo {
    NSString *fullname = [NSString stringWithFormat:@"%@ / %@", repo.owner, repo.name];
    
    self.textLabel.text = fullname;
    self.detailTextLabel.textColor = [UIColor grayColor];
    self.detailTextLabel.text = @"  Checking recent commits...";
    
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
                                    self.detailTextLabel.alpha = 0.0;
                                } completion:^(BOOL finished) {
                                    
                                }];
            
            // use spaces as poor man's indentation
            // update label on case-by-case basis for commits pushed today and yesterday
            if (daysSinceCommit == 0) {
                self.detailTextLabel.text = @"  Last commit today";
            }
            else if (daysSinceCommit == 1) {
                self.detailTextLabel.text = @"  Last commit yesterday";
            }
            
            // otherwise, generalize "x days ago"
            else {
                self.detailTextLabel.text = [NSString stringWithFormat:@"  Last commit %li days ago", (long)daysSinceCommit];
            }
            
            // darkish green
            UIColor *green = [UIColor colorWithRed:0.07058823529
                                             green:0.38823529411
                                              blue:0.1725490196
                                             alpha:1.0];
            self.detailTextLabel.textColor = green;
        }
        
        // no recent commits, berate user
        else {
            self.detailTextLabel.text = @"  No recent commits";
            self.detailTextLabel.textColor = [UIColor grayColor];
        }
        
        // animate fade in label
        [UIView animateWithDuration:kCellPopulationAnimationDuration
                              delay:(kCellPopulationAnimationDelay)
                            options:kNilOptions animations:^{
                                self.detailTextLabel.alpha = 1.0;
                            } completion:^(BOOL finished) {
                                
                            }];
    }];

}

@end
