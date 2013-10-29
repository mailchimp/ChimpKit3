//
//  CKAuthViewController.h
//  ChimpKit2
//
//  Created by Amro Mousa on 8/16/11.
//  Copyright (c) 2011 MailChimp. All rights reserved.
//

#import <UIKit/UIKit.h>


#define kCKAuthDebug        0

#define kAuthorizeUrl           @"https://login.mailchimp.com/oauth2/authorize"
#define kAccessTokenUrl         @"https://login.mailchimp.com/oauth2/token"
#define kMetaDataUrl            @"https://login.mailchimp.com/oauth2/metadata"
#define kDefaultRedirectUrl     @"https://modev1.mailchimp.com/wait.html"


@protocol CKAuthViewControllerDelegate <NSObject>

// You must dismiss the Auth View in all of these methods
- (void)ckAuthUserCanceled;
- (void)ckAuthSucceededWithApiKey:(NSString *)apiKey accountName:(NSString *)accountName andRole:(NSString *)role;
- (void)ckAuthFailedWithError:(NSError *)error;

@end


@interface CKAuthViewController : UIViewController <UIWebViewDelegate>

@property (unsafe_unretained, readwrite) id<CKAuthViewControllerDelegate> delegate;

@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *redirectUrl;

@property (strong, nonatomic) NSString *accessToken;

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *connectionData;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIWebView *webview;

- (id)initWithClientId:(NSString *)cId andClientSecret:(NSString *)cSecret;
- (id)initWithClientId:(NSString *)cId clientSecret:(NSString *)cSecret andRedirectUrl:(NSString *)rdirectUrl;

@property (nonatomic, copy) void (^authSucceeded)(NSString *apiKey, NSString *accountName, NSString *role);
@property (nonatomic, copy) void (^authFailed)(NSError *error);
@property (nonatomic, copy) void (^userCancelled)(void);

@end
