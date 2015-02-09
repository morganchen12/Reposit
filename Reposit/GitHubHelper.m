//
//  GitHubHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <OctoKit/OctoKit.h>

#import "SessionHelper.h"
#import "GitHubHelper.h"
#import "UserHelper.h"
#import "LocalNotificationHelper.h"
#import "AppDelegate.h"
#import "Repository.h"
#import "Secret.h"
#import "KeychainWrapper.h"

@interface GitHubHelper()

@property (nonatomic, readonly) KeychainWrapper *keychainWrapper;

@end

@implementation GitHubHelper

#pragma mark - Initializers / Factory methods

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // initialize keychain wrapper
        _keychainWrapper = [[KeychainWrapper alloc] init];
        
        // set OCTClient ID and secret;
        [OCTClient setClientID:kOctoKitClientID clientSecret:kOctoKitClientSecret];
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

#pragma mark - Github API

- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *))completion {
    NSAssert(!!username && username.length > 0, @"username must not be nil or empty!");
    
    // assemble url from username
    NSString *urlString = [NSString stringWithFormat:@"users/%@/repos?sort=updated", username];
    
    // create request
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:urlString parameters:nil notMatchingEtag:@"AddRepos"];
    
    // enqueue request
    RACSignal *signal = [self.client enqueueRequest:request resultClass:nil];
    
    // perform request and completion block
    [[signal collect] subscribeNext:^(NSArray *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(results);
        });
    } error:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (void)publicReposFromCurrentUserWithCompletion:(void (^)(NSArray *))completion {
    [self publicReposFromUser:[SessionHelper currentSession].currentUser.username completion:completion];
}

- (void)participationForRepositoryWithName:(NSString *)name owner:(NSString *)owner completion:(void (^)(NSArray *stats))completion {
    NSAssert(owner && owner.length > 0, @"owner must not be nil or empty!");
    NSAssert(name && name.length > 0, @"name must not be nil or empty!");
    
    // assemble url from username
    NSString *urlString = [NSString stringWithFormat:@"repos/%@/%@/stats/participation", owner, name];
    
    // create request
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET"
                                                             path:urlString
                                                       parameters:nil
                                                  notMatchingEtag:nil];
    
    // enqueue request
    RACSignal *signal = [self.client enqueueRequest:request resultClass:nil];
    
    // perform request and completion block
    [[signal collect] subscribeNext:^(NSArray *results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(results);
        });
    } error:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (void)participationForRepository:(Repository *)repo completion:(void (^)(NSArray *stats))completion {
    [self participationForRepositoryWithName:repo.name owner:repo.owner completion:completion];
}

- (void)user:(NSString *)username didCommitToRepo:(NSString *)repo inTimeFrame:(NSUInteger)days completion:(void (^)(NSInteger daysSinceCommit))completion {
    
    // workaround because github api doesn't accept calls with since < 5 days
    __block NSUInteger tempDays = 0;
    
    // if days < 5, set tempDays to 5
    tempDays = (days < 5) ? 5 : days;
    
    // boilerplate code to assemble request url from arguments
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateCalculations = [[NSDateComponents alloc] init];
    dateCalculations.day = -1*tempDays;
    NSDate *referenceDate = [calendar dateByAddingComponents:dateCalculations toDate:[NSDate date] options:kNilOptions];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:referenceDate];
    int day = (int)components.day;
    int month = (int)components.month;
    int year = (int)components.year;
    
    NSString *urlString = [NSString stringWithFormat:@"repos/%@/commits", repo];
    
    NSDictionary *parameters = @{
                                 @"since"  : [NSString stringWithFormat:@"%04d-%02d-%02d", year, month, day],
                                 @"author" : username
                                 };
    
    // create request
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET"
                                                             path:urlString
                                                       parameters:parameters
                                                  notMatchingEtag:nil];
    
    // enqueue request
    RACSignal *signal = [self.client enqueueRequest:request resultClass:nil];
    
    // perform request
    [[signal collect] subscribeNext:^(NSArray *results) {
         // get date string on most recent commit
        NSString *dateString = ((OCTResponse *)(results[0])).parsedResult[@"commit"][@"author"][@"date"];
        
        // turn date string into days (integer)
        NSInteger daysSinceLastCommit = [self daysSinceDateStringFromNow:dateString];
        
        // work around github api
        if (tempDays != days) {
            if (daysSinceLastCommit > days) {
                daysSinceLastCommit = NSNotFound;
            }
        }
        
        // perform completion block
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(daysSinceLastCommit);
        });
    } error:^(NSError *error) {
        NSLog(@"Error fetching commits: %@", error.description);
    } completed:^{
        
    }];
}

- (void)currentUserDidCommitToRepo:(Repository *)repo completion:(void (^)(NSInteger daysSinceCommit))completion {
    NSString *repoName = [NSString stringWithFormat:@"%@/%@", repo.owner, repo.name];
    
    // extremely ugly method indentation
    [self user:[SessionHelper currentSession].currentUser.username
didCommitToRepo:repoName
   inTimeFrame:[repo.reminderPeriod unsignedLongValue]
    completion:^(NSInteger daysSinceCommit) {
        
        repo.daysSinceCommit = @(daysSinceCommit);
        [[UserHelper currentHelper] saveContext];
        [[LocalNotificationHelper sharedHelper] checkAndSendNotifications];
        
        completion(daysSinceCommit);
    }];
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
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    // calculate day difference
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay fromDate:date toDate:[NSDate date] options:kNilOptions];
    return (NSInteger)(difference.day);
}

#pragma mark - OAuth

- (BOOL)signInToGitHub {
    
    // check keychain before authenticating
    NSString *rawLogin = [self.keychainWrapper myObjectForKey:(__bridge id)kSecAttrAccount];
    NSString *token    = [self.keychainWrapper myObjectForKey:(__bridge id)kSecValueData];
    
    if (rawLogin.length && token.length) {
        OCTUser *user = [OCTUser userWithRawLogin:rawLogin server:[OCTServer dotComServer]];
        OCTClient *client = [OCTClient authenticatedClientWithUser:user token:token];
        
        _client = client;
        [SessionHelper currentSession].currentUser = [UserHelper helperForUsername:user.rawLogin];
        
        // should make call to /user here to get current user and check that auth tokens in keychain are
        // still valid
        
        return YES;
    }
    
    // if nothing in keychain, authenticate
    __block BOOL success;
    [[OCTClient signInToServerUsingWebBrowser:[OCTServer dotComServer] scopes:OCTClientAuthorizationScopesUser] subscribeNext:^(id x) {
        success = YES;
        
        // set up properties
        _client = (OCTClient *)x;
        OCTUser *user = ((OCTClient *)x).user;
        [SessionHelper currentSession].currentUser = [UserHelper helperForUsername:user.login];
        
        // set up stuff in keychain
        [self.keychainWrapper mySetObject:self.client.user.rawLogin forKey:(__bridge id)kSecAttrAccount];
        [self.keychainWrapper mySetObject:self.client.token forKey:(__bridge id)kSecValueData];
    } error:^(NSError *error) {
        NSLog(@"%@", error.description);
        success = NO;
    }];
    
    return success;
}

@end
