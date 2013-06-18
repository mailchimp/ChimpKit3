//
//  ChimpKit.m
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKit.h"


#define kAPI20Endpoint	@"https://%@.api.mailchimp.com/2.0/"
#define kErrorDomain	@"com.MailChimp.ChimpKit.ErrorDomain"


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
			self.apiURL = [NSString stringWithFormat:kAPI20Endpoint, [apiKeyParts objectAtIndex:1]];
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
		if (self.delegate && [self.delegate respondsToSelector:@selector(methodCall:failedWithError:)]) {
			NSError *error = [NSError errorWithDomain:kErrorDomain code:kChimpKitErrorInvalidCompletionHandler userInfo:nil];
			[self.delegate methodCall:aMethod failedWithError:error];
		}
		
		return;
	}
    
	[self callApiMethod:aMethod withApiKey:anApiKey params:someParams andCompletionHandler:aHandler orDelegate:nil];
}

- (void)callApiMethod:(NSString *)aMethod withParams:(NSDictionary *)someParams andDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
    [self callApiMethod:aMethod withApiKey:nil params:someParams andDelegate:aDelegate];
}

- (void)callApiMethod:(NSString *)aMethod withApiKey:(NSString *)anApiKey params:(NSDictionary *)someParams andDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	if (aDelegate == nil) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(methodCall:failedWithError:)]) {
			NSError *error = [NSError errorWithDomain:kErrorDomain code:kChimpKitErrorInvalidDelegate userInfo:nil];
			[self.delegate methodCall:aMethod failedWithError:error];
		}
		
		return;
	}
    
	[self callApiMethod:aMethod withApiKey:anApiKey params:someParams andCompletionHandler:nil orDelegate:aDelegate];
}

- (void)callApiMethod:(NSString *)aMethod withApiKey:(NSString *)anApiKey params:(NSDictionary *)someParams andCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler orDelegate:(id<ChimpKitRequestDelegate>)aDelegate {
	if ((anApiKey == nil) && (self.apiKey == nil)) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(methodCall:failedWithError:)]) {
			NSError *error = [NSError errorWithDomain:kErrorDomain code:kChimpKitErrorInvalidAPIKey userInfo:nil];
			[self.delegate methodCall:aMethod failedWithError:error];
		}
		
		return;
	}
	
	NSString *urlString = nil;
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:someParams];
	
	if (anApiKey) {
		NSArray *apiKeyParts = [anApiKey componentsSeparatedByString:@"-"];
		if ([apiKeyParts count] > 1) {
			NSString *apiURL = [NSString stringWithFormat:kAPI20Endpoint, [apiKeyParts objectAtIndex:1]];
			urlString = [NSString stringWithFormat:@"%@%@", apiURL, aMethod];
		} else {
            NSError *error = [NSError errorWithDomain:kErrorDomain code:kChimpKitErrorInvalidAPIKey userInfo:nil];

			if (self.delegate && [self.delegate respondsToSelector:@selector(methodCall:failedWithError:)]) {
				[self.delegate methodCall:aMethod failedWithError:error];
			}
            
            if (aHandler) {
                aHandler(nil, error);
            }
			
			return;
		}
		
		[params setValue:anApiKey forKey:@"apikey"];
	} else if (self.apiKey) {
		urlString = [NSString stringWithFormat:@"%@%@", self.apiURL, aMethod];
		[params setValue:self.apiKey forKey:@"apikey"];
	}
	
	if (kCKDebug) NSLog(@"URL: %@", urlString);
	    
	ChimpKitRequest *request = [ChimpKitRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setHttpMethod:@"POST"];
	[request setHttpBody:[self encodeRequestParams:params]];
	[request setShouldUseBackgroundThread:self.shouldUseBackgroundThread];
	
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
