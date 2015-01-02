//
//  GitHubHelper.m
//  Reposit
//
//  Created by Morgan Chen on 1/1/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "GitHubHelper.h"

@implementation GitHubHelper

+ (instancetype)sharedHelper {
    static GitHubHelper *helper;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        helper = [[GitHubHelper alloc] init];
    });
    return helper;
}

- (void)publicReposFromUser:(NSString *)username completion:(void (^)(NSArray *))completion {
    
    // assemble GET url from username
    NSString *urlString = [NSString stringWithFormat:@"https://api.github.com/users/%@/repos?sort=updated", username];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // create request using URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    // debug
    NSLog(@"%@", urlString);
    
    // create session with self as delegate
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:nil];
    
    // perform request
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:
    ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // serialize data, handle errors
        if (httpResponse.statusCode == 200 && data) {
            NSError *serializationError;
            NSArray *downloadedJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            NSLog(@"%@", downloadedJSON);
            
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

- (void)user:(NSString *)username didCommitToRepo:(NSString *)repo inTimeFrame:(NSUInteger)days completion:(void (^)(BOOL))completion {
    
    // boilerplate code to assemble request url from arguments
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateCalculations = [[NSDateComponents alloc] init];
    dateCalculations.day = -1*days;
    NSDate *referenceDate = [calendar dateByAddingComponents:dateCalculations toDate:[NSDate date] options:kNilOptions];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:referenceDate];
    NSInteger day = components.day;
    NSInteger month = components.month;
    NSInteger year = components.year;
    
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
                // pass data into completion handler asynchronously
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(!!(downloadedJSON.count));
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

@end
