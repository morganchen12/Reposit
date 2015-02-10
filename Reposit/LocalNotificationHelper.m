//
//  LocalNotificationHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/4/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "LocalNotificationHelper.h"
#import "GitHubHelper.h"
#import "UserHelper.h"
#import "Repository.h"
@import UIKit;

static const NSTimeInterval kSecondsInDay = 86400;

@interface LocalNotificationHelper()

@end

@implementation LocalNotificationHelper

#pragma mark - Initializers / Factory methods

+ (instancetype)sharedHelper {
    static dispatch_once_t once;
    static LocalNotificationHelper *helper;
    dispatch_once(&once, ^{
        helper = [[LocalNotificationHelper alloc] init];
    });
    return helper;
}

#pragma mark - Notifications

- (void)checkAndSendNotifications {
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == kNilOptions) {
        // no permissions granted by user, exit function
        return;
    }
    
    // fetch repos from core data and check if they have recent commits
    NSArray *allRepos = [[UserHelper currentHelper] getRepos];
    NSMutableArray *oldRepos = [[NSMutableArray alloc] initWithCapacity:allRepos.count];
    for (Repository *repo in allRepos) {
        if ([repo.daysSinceCommit compare:repo.reminderPeriod] != NSOrderedAscending ||
            repo.daysSinceCommit.integerValue < 0) {
            [oldRepos addObject:repo];
        }
    }
    
    // reset badge num and exit if all repos have recent commits
    if (oldRepos.count == 0) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        return;
    }
    
    // notification messages
    NSString *action = @"dismiss";
    NSString *body;
    
    // cancel old notifications before scheduling new ones
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    for (Repository *repo in oldRepos) {
        body = [NSString stringWithFormat:@"%@ has no recent commits", repo.name];
        
        NSTimeInterval timeIntervalSinceNow;
        
        if (repo.daysSinceCommit.integerValue == NSNotFound) {
            timeIntervalSinceNow = repo.reminderPeriod.doubleValue * kSecondsInDay;
        }
        else {
            timeIntervalSinceNow = (repo.reminderPeriod.doubleValue - repo.daysSinceCommit.doubleValue) * kSecondsInDay;
        }
        
        // configure notification
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:timeIntervalSinceNow];
        notification.alertBody = body;
        notification.alertAction = action;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.applicationIconBadgeNumber = oldRepos.count;
        
        // schedule notification
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

@end
