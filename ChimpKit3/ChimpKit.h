//
//  ChimpKit.h
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChimpKitRequest.h"


@interface ChimpKit : NSObject

@property (nonatomic, strong) NSString *apiKey;

+ (ChimpKit *)sharedKit;

- (void)callApiMethod:(NSString *)aMethod
		   withParams:(NSDictionary *)someParams
 andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler;

- (void)callApiMethod:(NSString *)aMethod
		   withParams:(NSDictionary *)someParams
		  andDelegate:(id<ChimpKitRequestDelegate>)aDelegate;

@end
