//
//  NSKDataManager.h
//  Quantified Norm
//
//  Created by Neil Kimmett on 09/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSKDataManager : NSObject

+ (instancetype)shared;
- (void)sendDatum:(NSDictionary *)datum success:(void (^)())success;
- (NSArray *)loadDataFromFile;
- (NSString *)authToken;
- (NSString *)url;

@end
