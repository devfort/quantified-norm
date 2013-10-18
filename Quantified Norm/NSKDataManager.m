//
//  NSKDataManager.m
//  Quantified Norm
//
//  Created by Neil Kimmett on 09/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import "NSKDataManager.h"
#import "AFHTTPSessionManager.h"

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

- (void)sendDatum:(NSDictionary *)datum success:(void (^)())success
{
    NSURLSessionConfiguration *config = [[NSURLSessionConfiguration alloc] init];
    config.HTTPAdditionalHeaders = @{@"X-Auth": [[NSUserDefaults standardUserDefaults] valueForKey:@"QuantifiedNormAuthToken"]};
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *thing = [@{
                                   @"datum": datum,
                                   @"sent": @NO,
                                   @"timestamp": dateString} mutableCopy];
    NSString *url = [[NSUserDefaults standardUserDefaults] valueForKey:@"QuantifiedNormURLToPOSTTo"];
    [manager POST:url parameters:thing success:^(NSURLSessionDataTask *task, id responseObject) {
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
