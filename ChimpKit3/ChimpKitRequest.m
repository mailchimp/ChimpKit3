//
//  ChimpKitRequest.m
//  ChimpKit3
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKitRequest.h"

@interface ChimpKitRequest ()

@property (nonatomic, strong, readonly) NSMutableDictionary *headerFields;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) BOOL backgroundSupported;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, copy) ChimpKitRequestCompletionBlock completionHandler;

@end


@implementation ChimpKitRequest

@synthesize headerFields = _headerFields;


#pragma mark - Properites

- (NSMutableDictionary *)headerFields {
	if (!_headerFields) {
		_headerFields = [[NSMutableDictionary alloc] init];
	}
	
	return _headerFields;
}

- (void)setExecuting:(BOOL)executing {
	if (executing != _executing) {
		[self willChangeValueForKey:@"isExecuting"];
		_executing = executing;
		[self didChangeValueForKey:@"isExecuting"];
	}
}

- (void)setFinished:(BOOL)finished {
	if (finished != _finished) {
		[self willChangeValueForKey:@"isFinished"];
		_finished = finished;
		[self didChangeValueForKey:@"isFinished"];
	}
}


#pragma mark - Constructor

+ (id)requestWithURL:(NSURL *)aURL {
	return [[self alloc] initWithURL:aURL];
}


#pragma mark - Initalization

- (id)initWithURL:(NSURL *)aURL {
	self = [super init];
	
	if (self) {
		self.url = aURL;
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		self.timeoutInterval = 30.0f;
		
		UIDevice *device = [UIDevice currentDevice];
		if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
			self.backgroundSupported = device.multitaskingSupported;
		} else {
			self.backgroundSupported = NO;
		}
	}
	
	return self;
}


#pragma mark - Class Methods

+ (NSOperationQueue *)connectionQueue {
	static NSOperationQueue *connectionQueue = nil;
	
	if (connectionQueue == nil) {
		connectionQueue = [[NSOperationQueue alloc] init];
		[connectionQueue setMaxConcurrentOperationCount:3];
	}
	
	return connectionQueue;
}

+ (void)setMaximumConcurrentConnections:(NSInteger)maxConnections {
	[[self connectionQueue] setMaxConcurrentOperationCount:maxConnections];
}


#pragma mark - Public Methods

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	[self.headerFields setValue:value forKey:field];
}

- (void)startImmediately {
	[self startBackgroundTask];
	
	NSURLRequest *request = [self createRequest];
	
	self.responseData = [[NSMutableData alloc] init];
	
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	if (self.shouldUseBackgroundThread) {
		[self.connection setDelegateQueue:self.backgroundQueue];
	}
	
	[self.connection start];
}

- (void)startImmediatelyWithCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler {
	[self startBackgroundTask];
	
	NSURLRequest *request = [self createRequest];
	
	self.responseData = [[NSMutableData alloc] init];
	
	NSOperationQueue *queue = nil;
	
	if (self.shouldUseBackgroundThread) {
		queue = self.backgroundQueue;
	} else {
		queue = [NSOperationQueue mainQueue];
	}
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:queue 
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
							   self.response = (NSHTTPURLResponse *)response;
							   [self.responseData appendData:data];
							   self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
							   
							   aHandler(self, error);
							   
							   [self finish];
						   }];
}

- (void)enqueue {
	[self enqueueWithCompletionHandler:nil];
}

- (void)enqueueWithCompletionHandler:(ChimpKitRequestCompletionBlock)aHandler {
	[self startBackgroundTask];
	
	self.completionHandler = aHandler;
	
	[[ChimpKitRequest connectionQueue] addOperation:self];
}

- (void)cancel {
	[super cancel];
	
	[self finish];
}


#pragma mark - Private Methods

- (NSOperationQueue *)backgroundQueue {
	static NSOperationQueue *backgroundQueue = nil;
	
	if (backgroundQueue == nil) {
		backgroundQueue = [[NSOperationQueue alloc] init];
	}
	
	return backgroundQueue;
}

- (NSURLRequest *)createRequest {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
	
	if (self.httpMethod) {
		[request setHTTPMethod:self.httpMethod];
	}

	if (self.headerFields.count > 0) {
		[request setAllHTTPHeaderFields:self.headerFields];
	}
	
	if (self.httpBody) {
		[request setHTTPBody:self.httpBody];
	}
	
	return request;
}

- (void)startBackgroundTask {
	if (!self.backgroundSupported) return;
	
	UIApplication *application = [UIApplication sharedApplication];
	
	self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
		[self cancel];
		
        [application endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }];
}

- (void)finish {
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
	self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	
	self.delegate = nil;
	self.completionHandler = nil;
	
	if (self.connection) {
		[self.connection cancel];
		self.connection = nil;
	}
	
	self.executing = NO;
	self.finished = YES;
}


#pragma mark - <NSOperation> Methods

- (void)start {
	self.executing = YES;
	
	[self main];
}

- (void)main {
	if (self.completionHandler) {
		[self startImmediatelyWithCompletionHandler:self.completionHandler];
	} else {
		[self startImmediately];
		
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (self.isFinished == NO);
	}
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isReady {
	return YES;
}

- (BOOL)isExecuting {
	return self.executing;
}

- (BOOL)isFinished {
	return self.finished;
}


#pragma mark - <NSURLConnectionDelegate> Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.response = (NSHTTPURLResponse *)response;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(ckrequest:didReceivedResponse:)]) {
		[self.delegate ckrequest:self didReceivedResponse:self.response];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(ckRequestSucceeded:)]) {
		[self.delegate ckRequestSucceeded:self];
	}
	
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (self.delegate && [self.delegate respondsToSelector:@selector(ckRequestFailed:andError:)]) {
		[self.delegate ckRequestFailed:self andError:error];
	}
	
	[self finish];
}


@end
