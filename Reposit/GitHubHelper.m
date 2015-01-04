//
//  GitHubHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "GitHubHelper.h"
#import "AppDelegate.h"
#import "Repository.h"

static const NSUInteger kDefaultObligationPeriod = 7; // days

@interface GitHubHelper()

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

@implementation GitHubHelper

#pragma mark - Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        // load user from memory if it exists
        NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:@"currentUser"];
        if (user) {
            _currentUser = user;
        }
        
        // set managedObjectContext for convenience
        _managedObjectContext = ((AppDelegate *)([UIApplication sharedApplication].delegate)).managedObjectContext;
    }
    return self;
}

+ (instancetype)sharedHelper {
    static GitHubHelper *helper;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        helper = [[GitHubHelper alloc] init];
    });
    return helper;
}

#pragma mark - Property accessors

- (void)setCurrentUser:(NSString *)currentUser {
    _currentUser = currentUser;
    [[NSUserDefaults standardUserDefaults] setObject:currentUser forKey:@"currentUser"];
}

#pragma mark - Github API

- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *))completion {
    
    // assemble GET url from username
    NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/users/%@/repos?sort=updated", username];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create request using URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    // create session with self as delegate
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:nil];
    
    // perform request
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:
    ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // serialize data, handle errors
        if (httpResponse.statusCode == 200 && data) {
            NSError *serializationError;
            NSArray *downloadedJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            
            if (serializationError) {
                // handle serialization error
            }
            else {
                // pass data into completion handler asynchronously
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(downloadedJSON);
                });
            }
        }
        else {
            // handle download error
        }
    }];
    
    // actually run data task
    [dataTask resume];
}

- (void)publicReposFromCurrentUserWithCompletion:(void (^)(NSArray *))completion {
    [self publicReposFromUser:self.currentUser completion:completion];
}

- (void)user:(NSString *)username didCommitToRepo:(NSString *)repo inTimeFrame:(NSUInteger)days completion:(void (^)(NSInteger daysSinceCommit))completion {
    
    // boilerplate code to assemble request url from arguments
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateCalculations = [[NSDateComponents alloc] init];
    dateCalculations.day = -1*days;
    NSDate *referenceDate = [calendar dateByAddingComponents:dateCalculations toDate:[NSDate date] options:kNilOptions];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:referenceDate];
    int day = (int)components.day;
    int month = (int)components.month;
    int year = (int)components.year;
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/repos/%@/commits?since=%4d-%2d-%2d&author=%@", repo, year, month, day, username];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create request using URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    // create session with self as delegate
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:nil];
    
    // perform request
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // serialize data, handle errors
        if (httpResponse.statusCode == 200 && data) {
            NSError *serializationError;
            NSArray *downloadedJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                                              
            if (serializationError) {
                // handle serialization error
            }
            else {
                // if no recent commits, pass NSNotFound into completion block
                if (!downloadedJSON.count) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NSNotFound);
                    });
                }
                else {
                    // get date string on most recent commit
                    NSString *dateString = downloadedJSON[0][@"commit"][@"author"][@"date"];
                    
                    // turn date string into days (integer)
                    NSInteger daysSinceLastCommit = [self daysSinceDateStringFromNow:dateString];
                    
                    // perform completion block
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(daysSinceLastCommit);
                    });
                }
            }
        }
        else {
            // handle download error
        }
    }];
    
    // actually run data task
    [dataTask resume];
}

- (void)currentUserDidCommitToRepo:(Repository *)repo completion:(void (^)(NSInteger daysSinceCommit))completion {
    NSString *repoName = [NSString stringWithFormat:@"%@/%@", repo.owner, repo.name];
    [self user:self.currentUser didCommitToRepo:repoName inTimeFrame:[repo.reminderPeriod unsignedLongValue] completion:completion];
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

// dateString must be in format YYYY-MM-DDTHH:MM:SSZ
- (NSInteger)daysSinceDateStringFromNow:(NSString *)dateString {
    
    // separate dateString into components
    NSString *dateWithoutTime = [dateString componentsSeparatedByString:@"T"][0];
    NSArray *yearMonthDay = [dateWithoutTime componentsSeparatedByString:@"-"];
    NSInteger year = ((NSString *)(yearMonthDay[0])).integerValue;
    NSInteger month = ((NSString *)(yearMonthDay[1])).integerValue;
    NSInteger day = ((NSString *)(yearMonthDay[2])).integerValue;
    
    // create NSDateComponents from components
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = year;
    dateComponents.month = month;
    dateComponents.day = day;
    
    // use current calendar to create NSDate from dateComponents
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
    // calculate day difference
    double seconds = [[NSDate date] timeIntervalSinceDate:date];
    return (NSInteger)(seconds / 60 / 60 / 24);
}

@end
