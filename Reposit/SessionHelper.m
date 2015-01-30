//
//  SessionHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/30/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "SessionHelper.h"
#import "UserHelper.h"

@implementation SessionHelper

#pragma mark - Initializers / Factory methods

+ (instancetype)currentSession {
    static SessionHelper *helper;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        helper = [[SessionHelper alloc] init];
    });
    
    return helper;
}

#pragma mark - Property accessors

- (UserHelper *)currentUser {
    
    // return current user if it exists
    if (_currentUser) {
        return _currentUser;
    }
    
    // otherwise, create helper from NSUserDefaults
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
    if (username) {
        _currentUser = [UserHelper helperForUsername:username];
    }
    
    return _currentUser;
}

@end
