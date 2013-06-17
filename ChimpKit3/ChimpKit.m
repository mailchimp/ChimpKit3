//
//  ChimpKit.m
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKit.h"

@implementation ChimpKit

#pragma mark - Class Methods

+ (ChimpKit *)sharedKit {
	static dispatch_once_t pred = 0;
	__strong static ChimpKit *_sharedKit = nil;
	
	dispatch_once(&pred, ^{
		_sharedKit = [[self alloc] init];
		_sharedKit.timeoutInterval = kDefaultTimeoutInterval;
	});
	
	return _sharedKit;
}


#pragma mark - Properties

- (void)setApiKey:(NSString *)apiKey {
	_apiKey = apiKey;
	
	if (_apiKey) {
		// Parse out the datacenter and template it into the URL.
		NSArray *apiKeyParts = [_apiKey componentsSeparatedByString:@"-"];
		if ([apiKeyParts count] > 1) {
			self.apiURL = [NSString stringWithFormat:@"https://%@.api.mailchimp.com/2.0/", [apiKeyParts objectAtIndex:1]];
			self.exportApiURL = [NSString stringWithFormat:@"https://%@.api.mailchimp.com/export/1.0/", [apiKeyParts objectAtIndex:1]];
		} else {
			NSAssert(FALSE, @"Please provide a valid API Key");
		}
	}
}


#pragma mark - API Methods
- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler {
    [self callApiMethod:aMethod withApiKey:nil params:someParams andCompletionHandler:aHandler];
}

- (void)callApiMethod:(NSString *)aMethod withApiKey:(NSString *)anApiKey params:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler {
	if (aHandler == nil) {
		NSLog(@"Please provide a Completion Handler before calling an API Method");
		
		return;
	}
    
	[self callApiMethod:aMethod withApiKey:anApiKey params:someParams andCompletionHandler:aHandler orDelegate:nil];
}

- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
    [self callApiMethod:aMethod withApiKey:nil params:someParams andDelegate:aDelegate];
}

- (void)callApiMethod:(NSString *)aMethod withApiKey:(NSString *)anApiKey params:(NSDictionary *)someParams andDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	if (aDelegate == nil) {
		NSLog(@"Please provide a Delegate before calling an API Method");
		
		return;
	}
    
	[self callApiMethod:aMethod withApiKey:anApiKey params:someParams andCompletionHandler:nil orDelegate:aDelegate];
}

- (void)callApiMethod:(NSString *)aMethod withApiKey:(NSString *)anApiKey params:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler orDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	if ((anApiKey == nil) && (self.apiKey == nil)) {
		NSLog(@"Please set an API Key before calling API Methods");
		
		return;
	}
	
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.apiURL, aMethod];
	
	NSLog(@"URL: %@", urlString);
	
    //Encode params sets the apikey after 
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:someParams];
    if (anApiKey) {
        [params setValue:anApiKey forKey:@"apikey"];
    } else if (self.apiKey) {
        [params setValue:self.apiKey forKey:@"apikey"];
    }
    
	ChimpKitRequest *request = [ChimpKitRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setHttpMethod:@"POST"];
	[request setHttpBody:[self encodeRequestParams:params]];
	
	if (aHandler) {
		[request startImmediatelyWithCompletionHandler:aHandler];
	} else {
		[request setDelegate:aDelegate];
		
		[request startImmediately];
	}
}


#pragma mark - Private Methods

- (NSMutableData *)encodeRequestParams:(NSDictionary *)params {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableData *postData = [NSMutableData dataWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	
    return postData;
}


@end
