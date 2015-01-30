//
//  UserHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/26/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "UserHelper.h"
#import "User.h"
#import "Repository.h"
#import "AppDelegate.h"
#import "SessionHelper.h"

static const NSUInteger kDefaultObligationPeriod = 7; // days

@interface UserHelper()

@property (nonatomic, readwrite, strong) User *user;

@end

@implementation UserHelper

#pragma mark - Initializers / Life Cycle Methods

- (instancetype)init {
    self = [super init];
    if (self) {

        // load user from disk if it exists
        NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
        if (user) {
            _username = user;
        }
        
        // set managedObjectContext for convenience
        _managedObjectContext = ((AppDelegate *)([UIApplication sharedApplication].delegate)).managedObjectContext;
    }
    return self;
}

+ (instancetype)helperForUsername:(NSString *)username {
    NSAssert(!!username, @"username must not be nil!");
    
    UserHelper *helper = [[UserHelper alloc] init];
    
    // configure request to look up user by username in Core Data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:helper.managedObjectContext];
    request.entity = entity;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", username];
    request.predicate = predicate;
    
    // execute fetch request
    NSError *error;
    NSArray *results = [helper.managedObjectContext executeFetchRequest:request error:&error];
    
    // handle error
    if (error) {
        NSLog(@"%@", error.description);
    }
    
    // if results, create helper based on results
    if (results.count == 1) {
        User *user = (User *)(results[0]);
        helper.username = user.name;
    }
    
    // otherwise create new user with username
    else {
        helper.username = username;
        helper.user = [helper saveUserWithName:username];
    }
    
    return helper;
}

+ (instancetype)currentHelper {
    
    // sanity check
    UserHelper *helper = [SessionHelper currentSession].currentUser;
    NSAssert(!!helper, @"Helper must not be nil!");
    
    return helper;
}

#pragma mark - Property accessors

- (void)setUsername:(NSString *)username {
    _username = username;
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
}

#pragma mark - Core Data

#pragma mark Repositories

- (NSArray *)getRepos {
    return self.user.repos.array;
}

- (void)saveRepoWithName:(NSString *)name owner:(NSString *)owner obligation:(NSUInteger)obligation {
    // if saving duplicate repo, exit
    if (![self repoIsUniqueWithName:name owner:owner]) {
        return;
    }
    
    // otherwise, save
    Repository *newRepo = (Repository *)[NSEntityDescription insertNewObjectForEntityForName:@"Repository"
                                                                      inManagedObjectContext:self.managedObjectContext];
    newRepo.name = name;
    newRepo.owner = owner;
    newRepo.reminderPeriod = @(obligation);
    newRepo.relationship = self.user;
}

- (void)saveRepoWithName:(NSString *)name owner:(NSString *)owner {
    [self saveRepoWithName:name owner:owner obligation:kDefaultObligationPeriod];
}

- (void)saveRepoFromJSONObject:(NSDictionary *)JSONObject {
    NSString *name = JSONObject[@"name"];
    NSString *owner = JSONObject[@"owner"][@"login"];
    
    [self saveRepoWithName:name owner:owner];
}

- (void)saveRepoFromOCTRepository:(OCTRepository *)repo {
    NSString *name = repo.name;
    NSString *owner = repo.ownerLogin;
    
    [self saveRepoWithName:name owner:owner];
}

- (void)saveReposFromOCTRepositories:(NSArray *)repos {
    for (OCTRepository *repo in repos) {
        [self saveRepoFromOCTRepository:repo];
    }
}

- (void)saveReposFromJSONObjects:(NSArray *)JSONObjects {
    for (NSDictionary *JSONObject in JSONObjects) {
        [self saveRepoFromJSONObject:JSONObject];
    }
}

- (void)deleteRepository:(Repository *)repo {
    [self.managedObjectContext deleteObject:repo];
}

- (BOOL)saveContext {
    NSError *error;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        return NO;
    }
    return YES;
}

#pragma mark Users

- (User *)saveUserWithName:(NSString *)name {
    User *newUser = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                          inManagedObjectContext:self.managedObjectContext];
    newUser.name = name;
    
    return newUser;
}

#pragma mark - Helpers

// validate before saving repos
- (BOOL)repoIsUniqueWithName:(NSString *)name owner:(NSString *)owner {
    NSArray *allRepos = [self getRepos];
    for (Repository *repo in allRepos) {
        if ([name isEqualToString:repo.name] && [owner isEqualToString:repo.owner]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)repoIsUnique:(Repository *)repository {
    return [self repoIsUniqueWithName:repository.name owner:repository.owner];
}

@end
