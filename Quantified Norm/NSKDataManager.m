//
//  NSKDataManager.m
//  Quantified Norm
//
//  Created by Neil Kimmett on 09/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import "NSKDataManager.h"
#import "AFHTTPSessionManager.h"

@interface NSKDataManager ()
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@end

@implementation NSKDataManager

+ (instancetype)shared
{
    static NSKDataManager *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    
    return _shared;
}

- (NSString *)dataFilename
{
    NSArray *documentsSearchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsSearchPaths count] == 0 ? nil : [documentsSearchPaths objectAtIndex:0];
    NSString *dataFile = [documentsDirectory stringByAppendingPathComponent:@"unsent_data.json"];
    return dataFile;
}

- (void)writeBlankDataToFileIfFileDoesntExist:(NSString *)dataFilename
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataFilename]) {
        [@"[]" writeToFile:dataFilename atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (NSArray *)loadDataFromFile
{
    NSString *dataFilename = [self dataFilename];
    
    [self writeBlankDataToFileIfFileDoesntExist:dataFilename];

    NSData *currentFileData = [[NSFileManager defaultManager] contentsAtPath:dataFilename];
    NSArray *currentFileContents = [NSJSONSerialization JSONObjectWithData:currentFileData
                                                                   options:NSJSONReadingAllowFragments error:nil];
    return currentFileContents;
}

- (void)writeDataToFile:(NSArray *)allOfTheDataArray
{
    NSString *dataFilename = [self dataFilename];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allOfTheDataArray options:0 error:nil];
    [jsonData writeToFile:dataFilename atomically:YES];
}

- (void)addNewThingToFile:(NSMutableDictionary *)thing
{
    NSArray *currentFileContents = [self loadDataFromFile];
    NSArray *allOfTheDataArray = [@[thing] arrayByAddingObjectsFromArray:currentFileContents];
    [self writeDataToFile:allOfTheDataArray];
}

- (NSString *)authToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"QuantifiedNormAuthToken"];
}

- (NSString *)url
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"QuantifiedNormURLToPOSTTo"];
}

- (void)sendDatum:(NSDictionary *)datum success:(void (^)())success
{
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self url]]];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:[self authToken] forHTTPHeaderField:@"X-Auth"];
    
    [request setHTTPMethod:@"POST"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];

    NSMutableDictionary *thing = [@{
                                    @"datum": datum,
                                    @"sent": @NO,
                                    @"timestamp": dateString} mutableCopy];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:thing options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            thing[@"sent"] = @YES;
            [self addNewThingToFile:thing];
            success();
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                                message:[error localizedRecoverySuggestion]
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
    
    [postDataTask resume];
    return;
    
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{@"X-Auth": [self authToken]};
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    self.manager = manager;
    
    
    [manager POST:[self url] parameters:thing success:^(NSURLSessionDataTask *task, id responseObject) {
        thing[@"sent"] = @YES;
        [self addNewThingToFile:thing];
        success();
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedFailureReason]
                                                            message:[error localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
    }];
}

@end
