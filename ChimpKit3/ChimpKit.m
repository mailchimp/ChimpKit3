//
//  ChimpKit.m
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKit.h"


@interface ChimpKit ()

@property (nonatomic, strong) NSString *apiURL;

@end


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
			self.apiURL = [NSString stringWithFormat:@"https://%@.api.mailchimp.com/1.3/?method=", [apiKeyParts objectAtIndex:1]];
		} else {
			NSAssert(FALSE, @"Please provide a valid API Key");
		}
	}
}


#pragma mark - API Methods

- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler {
	NSAssert(aHandler != nil, @"Please provide a Completion Handler before when calling an API Method");

	[self callApiMethod:aMethod withParams:someParams andCompletionHandler:aHandler orDelegate:nil];
}

- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	NSAssert(aDelegate != nil, @"Please provide a Delegate before when calling an API Method");

	[self callApiMethod:aMethod withParams:someParams andCompletionHandler:nil orDelegate:aDelegate];
}

- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler orDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	NSAssert(self.apiKey != nil, @"Please set your API Key before calling API Methods");
	
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.apiURL, aMethod];
	
	ChimpKitRequest *request = [ChimpKitRequest requestWithURL:[NSURL URLWithString:urlString]];
	
	[request setHttpMethod:@"POST"];
	[request setHttpBody:[self encodeRequestParams:someParams]];
	
	if (aHandler) {
		[request startImmediatelyWithCompletionHandler:aHandler];
	} else {
		[request setDelegate:aDelegate];
		
		[request startImmediately];
	}
}


#pragma mark - Private Methods

- (NSMutableData *)encodeRequestParams:(NSDictionary *)params {
    NSMutableDictionary *postBodyParams = [NSMutableDictionary dictionary];
	
    if (self.apiKey) {
        [postBodyParams setValue:self.apiKey forKey:@"apikey"];
    }
	
    if (params) {
        [postBodyParams setValuesForKeysWithDictionary:params];
    }
	
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postBodyParams options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *encodedParamsAsJson = [self encodeString:jsonString];
    NSMutableData *postData = [NSMutableData dataWithData:[encodedParamsAsJson dataUsingEncoding:NSUTF8StringEncoding]];
	
    return postData;
}

- (NSString *)encodeString:(NSString *)unencodedString {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
																									(__bridge CFStringRef)unencodedString,
																									NULL,
																									(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																									kCFStringEncodingUTF8));
    return encodedString;
}

@end
