//
//  SessionHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/30/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserHelper;

@interface SessionHelper : NSObject

@property (nonatomic, strong) UserHelper *currentUser;

#pragma mark - Initializers / Factory methods

/* Return a singleton instance of the current session.
 */
+ (instancetype)currentSession;

@end
