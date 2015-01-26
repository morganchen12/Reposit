//
//  CoreDataHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/26/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSManagedObjectContext;
@class OCTRepository;
@class Repository;

@interface CoreDataHelper : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

#pragma mark - Factory

/* Return a singleton instance of GitHubHelper.
 */
+ (instancetype)sharedHelper;

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

/* Save a Repository managed object from an OCTRepository object.
 */
- (void)saveRepoFromOCTRepository:(OCTRepository *)repo;

/* Saves an array of OCTRepositories as Repository objects. Assumes all elements in the array are OCTRepository 
 * instances.
 */
- (void)saveReposFromOCTRepositories:(NSArray *)repos;

/* Deletes a repo from the managed object context. Does not actually save the managed object context.
 */
- (void)deleteRepository:(Repository *)repo;

/* Actually save the managed object context to disk. Returns YES if save was successful.
 */
- (BOOL)saveContext;

@end
