//
//  RepositTests.m
//  RepositTests
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "GitHubHelper.h"

@interface RepositTests : XCTestCase

@end

@implementation RepositTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExample {
    [[GitHubHelper sharedHelper] publicReposFromUser:@"morganchen12" completion:^(NSArray *repos) {
        NSLog(@"%@", repos);
    }];
    sleep(1);
    XCTAssert(YES, @"Pass");
}

@end
