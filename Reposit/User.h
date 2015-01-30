//
//  User.h
//  Reposit
//
//  Created by Morgan Chen on 1/30/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Repository;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSOrderedSet *repos;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)insertObject:(Repository *)value inReposAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReposAtIndex:(NSUInteger)idx;
- (void)insertRepos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReposAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReposAtIndex:(NSUInteger)idx withObject:(Repository *)value;
- (void)replaceReposAtIndexes:(NSIndexSet *)indexes withRepos:(NSArray *)values;
- (void)addReposObject:(Repository *)value;
- (void)removeReposObject:(Repository *)value;
- (void)addRepos:(NSOrderedSet *)values;
- (void)removeRepos:(NSOrderedSet *)values;

@end
