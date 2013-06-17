//
//  ViewController.m
//  ChimpKitSampleApp
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "ViewController.h"
#import "ChimpKit.h"
#import "CKSubscribeAlertView.h"


@implementation ViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
		
	// This call fetches lists
    [[ChimpKit sharedKit] callApiMethod:@"lists/list"
							 withParams:nil
				   andCompletionHandler:^(ChimpKitRequest *request, NSError *error) {
					   NSLog(@"Here are my lists: %@", request.responseString);
				   }];
}


#pragma mark - UI Actions

- (IBAction)subscribeButtonTapped:(id)sender {
	CKSubscribeAlertView *alert = [[CKSubscribeAlertView alloc] initWithTitle:@"Subscribe"
                                                                  message:@"Enter your email address to subscribe to our mailing list."
                                                                   listId:@"<YOUR LIST ID>"
                                                        cancelButtonTitle:@"Cancel"
                                                     subscribeButtonTitle:@"Subscribe"];
	
	[alert show];
}

- (IBAction)loginButtonTapped:(id)sender {
	CKAuthViewController *authViewController = [[CKAuthViewController alloc] initWithClientId:@"<YOUR CLIENT ID>"
																			  andClientSecret:@"<YOUR CLIENT SECRET>"];
	
    authViewController.delegate = self;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:authViewController];
	
    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - <CKAuthViewControllerDelegate> Methods

- (void)ckAuthUserCanceled {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)ckAuthSucceededWithApiKey:(NSString *)apiKey accountName:(NSString *)accountName andRole:(NSString *)role {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)ckAuthFailedWithError:(NSError *)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}


@end
