//
//  LocalNotificationHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/4/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "LocalNotificationHelper.h"
#import "GitHubHelper.h"
#import "Repository.h"
@import UIKit;

// check if should send local notification every hour
static const NSTimeInterval kTimeBetweenNotificationChecks = 3600;

// time interval between notification scheduling and display
static const NSTimeInterval kNotificationSleepInterval = 10;

@interface LocalNotificationHelper()

@property (nonatomic, readonly) NSTimer *notificationTimer;

@end

@implementation LocalNotificationHelper

#pragma mark - Initializers / Factory methods

- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationTimer = [NSTimer scheduledTimerWithTimeInterval:kTimeBetweenNotificationChecks
                                                              target:self
                                                            selector:@selector(checkAndSendNotifications)
                                                            userInfo:nil
                                                             repeats:YES];
    }
    return self;
}

+ (instancetype)sharedHelper {
    static dispatch_once_t once;
    static LocalNotificationHelper *helper;
    dispatch_once(&once, ^{
        helper = [[LocalNotificationHelper alloc] init];
    });
    return helper;
}

#pragma mark - NSTimer

- (void)checkAndSendNotifications {
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == kNilOptions) {
        // no permissions granted by user, exit function
        return;
    }
    
    // fetch repos from core data and check if they have recent commits
    NSArray *allRepos = [[GitHubHelper sharedHelper] getRepos];
    NSMutableArray *oldRepos = [[NSMutableArray alloc] initWithCapacity:allRepos.count];
    for (Repository *repo in allRepos) {
        if ([repo.daysSinceCommit compare:repo.reminderPeriod] != NSOrderedAscending) {
            [oldRepos addObject:repo];
        }
    }
    
    // exit if all repos have recent commits
    if (oldRepos.count == 0) return;
    
    // notification messages
    NSString *action = @"Work on your side projects!";
    NSString *body;
    
    if (oldRepos.count == 1) {
        Repository *repo = oldRepos[0];
        body = [NSString stringWithFormat:@"%@ needs your attention", repo.name];
    }
    else {
        body = [NSString stringWithFormat:@"%lu projects need your attention", (unsigned long)(oldRepos.count)];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:kNotificationSleepInterval];
    notification.alertBody = body;
    notification.alertAction = action;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

@end
