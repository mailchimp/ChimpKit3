//
//  ChimpKitExportRequest.m
//  ChimpKitSampleApp
//
//  Created by Drew Conner on 5/3/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKitExportRequest.h"


@interface ChimpKitExportRequest ()

@property (nonatomic, copy) ChimpKitRequestCompletionBlock completionHandler;
@property (nonatomic, copy) ChimpKitExportRequestDataReceivedBlock dataReceivedHandler;
@property (nonatomic, strong) NSString *lastPartialLine;

@end


@implementation ChimpKitExportRequest


#pragma mark - Public Methods

- (void)startImmediatelyWithDataReceivedHandler:(ChimpKitExportRequestDataReceivedBlock)aDataReceivedHandler andCompletionHandler:(ChimpKitRequestCompletionBlock)aCompletionHandler {
	self.completionHandler = aCompletionHandler;
	self.dataReceivedHandler = aDataReceivedHandler;
	
	[self startImmediately];
}

- (void)enqueueWithDataReceivedHandler:(ChimpKitExportRequestDataReceivedBlock)aDataReceivedHandler andCompletionHandler:(ChimpKitRequestCompletionBlock)aCompletionHandler {
	self.completionHandler = aCompletionHandler;
	self.dataReceivedHandler = aDataReceivedHandler;
	
	[self enqueue];
}


#pragma mark - Private Methods

- (void)parseReceivedData:(NSData *)data {
	NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	if (self.lastPartialLine) {
		stringData = [self.lastPartialLine stringByAppendingString:stringData];
	}
	
	NSArray *lines = [stringData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		NSUInteger index = [lines indexOfObject:line];
		if (index == (lines.count - 1)) {
			self.lastPartialLine = line;
			break;
		}
		
		if ((self.delegate) && [self.delegate respondsToSelector:@selector(ckExportRequest:didReceiveData:)]) {
			[self.delegate ckExportRequest:self didReceiveData:line];
		}
		
		if (self.dataReceivedHandler) {
			BOOL shouldCancelRequest = NO;
			
			self.dataReceivedHandler(self, line, &shouldCancelRequest);
			
			if (shouldCancelRequest) {
				[self cancel];
				
				break;
			}
		}
		
		if ((self.delegate) && [self.delegate respondsToSelector:@selector(ckShouldCancelExportRequest:)]) {
			if ([self.delegate ckShouldCancelExportRequest:self]) {
				[self cancel];
				
				break;
			}
		}
	}
}

- (void)finish {
	self.dataReceivedHandler = nil;
	
	[super finish];
}


#pragma mark - <NSOperation> Methods

- (void)main {
	[self startImmediately];
	
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while (self.isFinished == NO);
}


#pragma mark - <NSURLConnectionDelegate> Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self parseReceivedData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	
	if (self.completionHandler) {
		self.completionHandler(self, nil);
	} else if (self.delegate && [self.delegate respondsToSelector:@selector(ckRequestSucceeded:)]) {
		[self.delegate ckRequestSucceeded:self];
	}
	
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (self.completionHandler) {
		self.completionHandler(self, error);
	} else if (self.delegate && [self.delegate respondsToSelector:@selector(ckRequestFailed:andError:)]) {
		[self.delegate ckRequestFailed:self andError:error];
	}
	
	[self finish];
}


@end
