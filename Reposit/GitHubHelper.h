//
//  GitHubHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Repository;

@interface GitHubHelper : NSObject <NSURLSessionDelegate>

@property (nonatomic, readwrite) NSString *currentUser;

#pragma mark - Factory

/* Return a singleton instance of GitHubHelper.
 */
+ (instancetype)sharedHelper;

#pragma mark - Github API

/* Return a list of public repositories belonging to a GitHub user. Takes in a username string as a parameter.
 * Result array is passed in as a parameter to the completion block.
 */
- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *repos))completion;

/* Calls publicReposFromUser:completion: with user as the current user.
 */
- (void)publicReposFromCurrentUserWithCompletion:(void (^)(NSArray *repos))completion;

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

#pragma mark - Core Data

/* Fetch all repositories from Core Data.
 */
- (NSArray *)getRepos;

/* Creates and saves a Repository object with the given parameters. The "obligation" parameter specifies
 * the number of days a user has to commit before the app will remind them. This method is directly or
 * indirectly called by every other save method listed below. Does not actually save the managed object context.
 */
- (void)saveRepoWithName:(NSString *)name owner:(NSString *)owner obligation:(NSUInteger)obligation;

/* Calls saveRepoWithName:owner:obligation: with a default obligation period of 7 days.
 */
- (void)saveRepoWithName:(NSString *)name owner:(NSString *)owner;

/* Creates and saves a single Repository object from JSON downloaded from the Github API.
 * Calls saveRepoWithName:owner: with data from the JSON dictionary.
 */
- (void)saveRepoFromJSONObject:(NSDictionary *)JSONObject;

/* Calls saveRepoFromJSONObject: with an array of JSON objects.
 */
- (void)saveReposFromJSONObjects:(NSArray *)JSONObjects;

/* Deletes a repo from the managed object context. Does not actually save the managed object context.
 */
- (void)deleteRepository:(Repository *)repo;

/* Actually save the managed object context to disk. Returns YES if save was successful.
 */
- (BOOL)saveContext;

@end
