//
//  CoreDataHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/26/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "CoreDataHelper.h"
#import "Repository.h"
#import "AppDelegate.h"

static const NSUInteger kDefaultObligationPeriod = 7; // days

@interface CoreDataHelper()



@end

@implementation CoreDataHelper

#pragma mark - Initializers / Life Cycle Methods

- (instancetype)init {
    self = [super init];
    if (self) {

        // set managedObjectContext for convenience
        _managedObjectContext = ((AppDelegate *)([UIApplication sharedApplication].delegate)).managedObjectContext;
    }
    return self;
}

+ (instancetype)sharedHelper {
    static CoreDataHelper *helper;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        helper = [[CoreDataHelper alloc] init];
    });
    return helper;
}

#pragma mark - Core Data

- (NSArray *)getRepos {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Repository"
                                                         inManagedObjectContext:self.managedObjectContext];
    request.entity = entityDescription;
    
    NSError *error;
    NSArray *queryResult = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@", error.description);
    }
    return queryResult;
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
