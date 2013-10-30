//
//  CKAuthViewController.m
//  ChimpKit2
//
//  Created by Amro Mousa on 8/16/11.
//  Copyright (c) 2011 MailChimp. All rights reserved.
//

#import "CKAuthViewController.h"
#import "CKScanViewController.h"
#import "ChimpKit.h"


@interface CKAuthViewController()

- (void)authWithClientId:(NSString *)yd andSecret:(NSString *)secret;
- (void)getAccessTokenMetaDataForAccessToken:(NSString *)anAccessToken;
- (void)cleanup;

@end


@implementation CKAuthViewController

- (id)initWithClientId:(NSString *)cId clientSecret:(NSString *)cSecret andRedirectUrl:(NSString *)redirectUrl {
    self = [super init];
	
    if (self) {
        self.clientId = cId;
        self.clientSecret = cSecret;
        self.redirectUrl = redirectUrl;
    }
	
    return self;
}

- (id)initWithClientId:(NSString *)cId andClientSecret:(NSString *)cSecret {
    return [self initWithClientId:cId clientSecret:cSecret andRedirectUrl:kDefaultRedirectUrl];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Connect to MailChimp";
    self.connectionData = [NSMutableData data];
    
    //If presented modally in a new VC, add the cancel button
    if (([self.navigationController.viewControllers objectAtIndex:0] == self) && (self.disableCancelling == NO)) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                               target:self 
                                                                                               action:@selector(cancelButtonTapped:)];
    }
	
	if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) && (self.disableAPIKeyScanning == NO)) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Scan Key"
																				  style:UIBarButtonItemStylePlain
																				 target:self
																				 action:@selector(scanButtonTapped:)];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self authWithClientId:self.clientId andSecret:self.clientSecret];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webview stopLoading];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark - UI Actions

- (void)cancelButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(ckAuthUserCanceled)]) {
        [self.delegate ckAuthUserCanceled];
    }
	
	if (self.userCancelled) {
		self.userCancelled();
	}
}

- (void)scanButtonTapped:(id)sender {
	CKScanViewController *scanViewController = [[CKScanViewController alloc] init];
	
	[scanViewController setApiKeyFound:^(NSString *apiKey) {
		if (self.disableAccountDataFetching) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthSucceededWithApiKey:andAccountData:)]) {
				[self.delegate ckAuthSucceededWithApiKey:apiKey andAccountData:nil];
			}
			
			if (self.authSucceeded) {
				self.authSucceeded(apiKey, nil);
			}
		} else {
			[self fetchAccountDataForAPIKey:apiKey];
		}
	}];
	
	[self.navigationController pushViewController:scanViewController animated:YES];
}


#pragma mark - Private Methods

- (void)authWithClientId:(NSString *)yd andSecret:(NSString *)secret {
    self.clientId = yd;
    self.clientSecret = secret;
    
    //Kick off the auth process
    NSString *url = [NSString stringWithFormat:@"%@?response_type=code&client_id=%@&redirect_uri=%@",
                     kAuthorizeUrl,
                     self.clientId,
                     self.redirectUrl];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:
                              [NSURL URLWithString:url]];
    [self.webview loadRequest:request];
}

- (void)getAccessTokenForAuthCode:(NSString *)authCode {
    [self cleanup];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kAccessTokenUrl]];
    [request setHTTPMethod:@"POST"];

    NSString *postBody = [NSString stringWithFormat:@"grant_type=authorization_code&client_id=%@&client_secret=%@&code=%@&redirect_uri=%@",
                          self.clientId,
                          self.clientSecret,
                          authCode,
                          self.redirectUrl];

    [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];

    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)getAccessTokenMetaDataForAccessToken:(NSString *)anAccessToken {
    [self cleanup];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kMetaDataUrl]];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", anAccessToken] forHTTPHeaderField:@"Authorization"];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)cleanup {
    self.connection = nil;
    [self.connectionData setLength:0];
}

- (void)fetchAccountDataForAPIKey:(NSString *)apiKey {
	ChimpKit *chimpKit = [[ChimpKit alloc] init];
	
	chimpKit.apiKey = apiKey;
	
	[chimpKit callApiMethod:@"users/profile" withParams:nil andCompletionHandler:^(ChimpKitRequest *request, NSError *error) {
		if (error) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthFailedWithError:)]) {
				[self.delegate ckAuthFailedWithError:error];
			}
			
			if (self.authFailed) {
				self.authFailed(error);
			}
		} else {
			NSLog(@"Response String: %@", [request responseString]);
			
			NSError *error = nil;
			id responseData = [NSJSONSerialization JSONObjectWithData:[[request responseString] dataUsingEncoding:NSUTF8StringEncoding]
															  options:0
																error:&error];
			
			if (responseData && [responseData isKindOfClass:[NSDictionary class]]) {
				if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthSucceededWithApiKey:andAccountData:)]) {
					[self.delegate ckAuthSucceededWithApiKey:apiKey andAccountData:responseData];
				}
				
				if (self.authSucceeded) {
					self.authSucceeded(apiKey, responseData);
				}
			} else {
				if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthFailedWithError:)]) {
					[self.delegate ckAuthFailedWithError:nil];
				}
				
				if (self.authFailed) {
					self.authFailed(nil);
				}
			}
		}
	}];
}


#pragma mark - <UIWebViewDelegate> Methods

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    [self.spinner setHidden:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self.spinner setHidden:YES];
    
    NSString *currentUrl = request.URL.absoluteString;
    if (kCKAuthDebug) NSLog(@"CKAuthViewController webview shouldStartLoadWithRequest url: %@", currentUrl);
    
    //If MailChimp redirected us to our redirect url, then the user has been auth'd
    if ([currentUrl rangeOfString:self.redirectUrl].location == 0) {
        NSArray *urlSplit = [currentUrl componentsSeparatedByString:@"code="];
        
		if (urlSplit.count > 1) {
			//The auth code must now be exchanged for an access token (the api key)
			NSString *authCode = [urlSplit objectAtIndex:1];
			[self getAccessTokenForAuthCode:authCode];
		}
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.spinner setHidden:YES];
}


- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
    [self.spinner setHidden:YES];

    //ToDo: Show error
}


#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.spinner setHidden:NO];

    [self.connectionData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *response = [[NSString alloc] initWithData:self.connectionData encoding:NSUTF8StringEncoding];
    if (kCKAuthDebug) NSLog(@"Auth Response: %@", response);

    NSDictionary *jsonValue = [NSJSONSerialization JSONObjectWithData:self.connectionData
                                                              options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments
                                                                error:nil];

    if (!self.accessToken) {
        self.accessToken = [jsonValue objectForKey:@"access_token"];

        //Get the access token metadata so we can return a proper API key
        [self getAccessTokenMetaDataForAccessToken:self.accessToken];
    } else {
        [self.spinner setHidden:YES];

        //And we're done. We can now concat the access token and the data center
        //to form the MailChimp API key and notify our delegate
        NSString *dataCenter = [jsonValue objectForKey:@"dc"];
        NSString *apiKey = [NSString stringWithFormat:@"%@-%@", self.accessToken, dataCenter];
        
		if (self.disableAccountDataFetching) {
			if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthSucceededWithApiKey:andAccountData:)]) {
				[self.delegate ckAuthSucceededWithApiKey:apiKey andAccountData:nil];
			}
			
			if (self.authSucceeded) {
				self.authSucceeded(apiKey, nil);
			}
		} else {
			[self fetchAccountDataForAPIKey:apiKey];
		}

        [self cleanup];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.spinner setHidden:YES];

    if (self.delegate && [self.delegate respondsToSelector:@selector(ckAuthFailedWithError:)]) {
		[self.delegate ckAuthFailedWithError:error];
	}
	
	if (self.authFailed) {
		self.authFailed(error);
	}
	
    [self cleanup];
}


@end
