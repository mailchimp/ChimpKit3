//
//  ChimpKit.h
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChimpKitRequest.h"


#define kDefaultTimeoutInterval	15.0f


@interface ChimpKit : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *apiURL;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

+ (ChimpKit *)sharedKit;

- (void)callApiMethod:(NSString *)aMethod
		   withParams:(NSDictionary *)someParams
 andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler;

- (void)callApiMethod:(NSString *)aMethod
		   withParams:(NSDictionary *)someParams
		  andDelegate:(id<ChimpKitRequestDelegate>)aDelegate;

// If these methods are called with a nil apikey, ChimpKit falls back to
// using the global apikey
- (void)callApiMethod:(NSString *)aMethod
           withApiKey:(NSString *)anApiKey
               params:(NSDictionary *)someParams
 andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler;

- (void)callApiMethod:(NSString *)aMethod
           withApiKey:(NSString *)anApiKey
               params:(NSDictionary *)someParams
          andDelegate:(id<ChimpKitRequestDelegate>)aDelegate;
@end
