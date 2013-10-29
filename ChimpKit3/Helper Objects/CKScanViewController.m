//
//  CKScanViewController.m
//  ChimpKitSampleApp
//
//  Created by Drew Conner on 10/29/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CKScanViewController.h"


@interface CKScanViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end


@implementation CKScanViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Scan API Key";
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
		// TODO: Show iOS7 Required Message
	} else {
		self.captureSession = [[AVCaptureSession alloc] init];
		
		AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		NSError *error = nil;
		AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
		
		if (videoInput) {
			[self.captureSession addInput:videoInput];
		} else {
			NSLog(@"Video Capture Error: %@", error);
		}
		
		AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
		[self.captureSession addOutput:metadataOutput];
		[metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
		[metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
		
		self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
		self.previewLayer.frame = self.view.layer.bounds;
		[self.view.layer addSublayer:self.previewLayer];
		
		[self.captureSession startRunning];
	}
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancelButtonTapped:)];
}


#pragma mark - UI Actions

- (void)cancelButtonTapped:(id)sender {
	if (self.userCancelled) {
		self.userCancelled();
	}
}


#pragma mark <AVCaptureMetadataOutputObjectsDelegate> Methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for(AVMetadataObject *metadataObject in metadataObjects) {
        AVMetadataMachineReadableCodeObject *readableObject = (AVMetadataMachineReadableCodeObject *)metadataObject;
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode]) {
			[self.previewLayer removeFromSuperlayer];
			self.previewLayer = nil;
			
			[self.captureSession stopRunning];
			self.captureSession = nil;
			
			if (self.apiKeyFound) {
				self.apiKeyFound(readableObject.stringValue);
			}
        }
    }
}


@end
