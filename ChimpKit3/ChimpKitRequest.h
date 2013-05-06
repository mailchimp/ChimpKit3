//
//  ChimpKitRequest.h
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ChimpKitRequest;


typedef void (^ChimpKitRequestCompletionBlock)(ChimpKitRequest *request, NSError *error);


@protocol ChimpKitRequestDelegate <NSObject>

@optional
- (void)ckrequest:(ChimpKitRequest *)aRequest didReceivedResponse:(NSHTTPURLResponse *)aResponse;
- (void)ckRequestSucceeded:(ChimpKitRequest *)aRequest;
- (void)ckRequestFailed:(ChimpKitRequest *)aRequest andError:(NSError *)anError;

@end


@interface ChimpKitRequest : NSOperation <NSURLConnectionDelegate>

// ChimpKitRequest Specific Properties and Methods
@property (nonatomic, weak) id<ChimpKitRequestDelegate> delegate;
@property (nonatomic, assign) BOOL shouldUseBackgroundThread;
@property (nonatomic, strong) id userInfo;

+ (id)requestWithURL:(NSURL *)aURL;
- (id)initWithURL:(NSURL *)aURL;

+ (void)setMaximumConcurrentConnections:(NSInteger)maxConnections;


// HTTP Request Properties and Methods
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSData *httpBody;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;


// Request Lifecycle Methods

- (void)startImmediately;
- (void)startImmediatelyWithCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler;

- (void)enqueue;
- (void)enqueueWithCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler;

- (void)cancel;


// Response Properties
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *responseString;


@end


@interface ChimpKitRequest (SubclassingHooks)

- (void)finish;

@end
