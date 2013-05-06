//
//  ChimpKitExportRequest.h
//  ChimpKitSampleApp
//
//  Created by Drew Conner on 5/3/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ChimpKitRequest.h"


@class ChimpKitExportRequest;


typedef void (^ChimpKitExportRequestDataReceivedBlock)(ChimpKitExportRequest *request, NSString *data, BOOL *shouldCancelRequest);


@protocol ChimpKitExportRequestDelegate <ChimpKitRequestDelegate>

@optional
- (void)ckExportRequest:(ChimpKitExportRequest *)aRequest didReceiveData:(NSString *)data;
- (BOOL)ckShouldCancelExportRequest:(ChimpKitExportRequest *)aReqeust;

@end


@interface ChimpKitExportRequest : ChimpKitRequest

@property (nonatomic, weak) id<ChimpKitExportRequestDelegate> delegate;

- (void)startImmediatelyWithDataReceivedHandler:(ChimpKitExportRequestDataReceivedBlock)aDataReceivedHandler andCompletionHandler:(ChimpKitRequestCompletionBlock)aCompletionHandler;
- (void)enqueueWithDataReceivedHandler:(ChimpKitExportRequestDataReceivedBlock)aDataReceivedHandler andCompletionHandler:(ChimpKitRequestCompletionBlock)aCompletionHandler;

@end
