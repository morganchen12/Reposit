//
//  Repository.h
//  Reposit
//
//  Created by Morgan Chen on 1/30/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Repository : NSManagedObject

@property (nonatomic, retain) NSNumber *daysSinceCommit;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *owner;
@property (nonatomic, retain) NSNumber *reminderPeriod;
@property (nonatomic, retain) User *relationship;

@end
