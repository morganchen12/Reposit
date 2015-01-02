//
//  GitHubHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GitHubHelper : NSObject <NSURLSessionDelegate>

/* Return a singleotn instance of GitHubHelper.
 */
+ (instancetype)sharedHelper;

/* Return a list of public repositories belonging to a GitHub user. Takes in a username string as a parameter.
 * Result array is passed in as a parameter to the completion block.
 */
- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *repos))completion;

/* Check whether or not a user has committed to a repository within the past specified number of days.
 * This function requires that the repo name be in the format @"username/reponame".
 * Result bool is passed in as a parameter to the completion block.
 */
- (void)user:(NSString *)username didCommitToRepo:(NSString *)repo inTimeFrame:(NSUInteger)days completion:(void (^)(BOOL committed))completion;

@end
