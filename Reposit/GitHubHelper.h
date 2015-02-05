//
//  GitHubHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Repository;
@class OCTClient;

@interface GitHubHelper : NSObject <NSURLSessionDelegate>

@property (nonatomic, readonly) OCTClient *client;


#pragma mark - Factory

/* Return a singleton instance of GitHubHelper.
 */
+ (instancetype)sharedHelper;

#pragma mark - Github API

/* Retreive a list of public repositories belonging to a GitHub user. Takes in a username string as a parameter.
 * Result array is passed in as a parameter to the completion block.
 */
- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *repos))completion;

/* Calls publicReposFromUser:completion: with user as the current user.
 */
- (void)publicReposFromCurrentUserWithCompletion:(void (^)(NSArray *repos))completion;

/* Retreive the commit activity for a particular repository.
 */
- (void)participationForRepositoryWithName:(NSString *)name owner:(NSString *)owner completion:(void (^)(NSDictionary *results))completion;

/* Calls commitActivityForRepositoryWithName:owner: with the given Repository's name and owner
 */
- (void)participationForRepository:(Repository *)repo completion:(void (^)(NSDictionary *results))completion;

/* Check whether or not a user has committed to a repository within the past specified number of days.
 * If commits are present, completion block will be passed the number of days since the last commit. Otherwise,
 * the completion block will be passed NSNotFound (NSIntegerMax).
 * This function requires that the repo name be in the format @"username/reponame".
 * Result integer is passed in as a parameter to the completion block. Completion block cannot be nil.
 */
- (void)user:(NSString *)username didCommitToRepo:(NSString *)repo inTimeFrame:(NSUInteger)days completion:(void (^)(NSInteger daysSinceCommit))completion;

/* Calls user:didCommitToRepo:inTimeFrame:completion with current user as user and a Repository object. When 
 * executing the completion block, this function also saves daysSinceCommit to the repository's respective property.
 */
- (void)currentUserDidCommitToRepo:(Repository *)repo completion:(void (^)(NSInteger daysSinceCommit))completion;

#pragma mark - OctoKit

- (BOOL)signInToGitHub;

@end
