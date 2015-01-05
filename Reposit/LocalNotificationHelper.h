//
//  LocalNotificationHelper.h
//  Reposit
//
//  Created by Morgan Chen on 1/4/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalNotificationHelper : NSObject

/* Return a singleton instance of LocalNotificationHelper.
 */
+ (instancetype)sharedHelper;

/* Check repo statuses and send out local notification if necessary.
 */
- (void)checkAndSendNotifications;

@end
