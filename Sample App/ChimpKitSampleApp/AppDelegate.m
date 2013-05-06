//
//  AppDelegate.m
//  ChimpKitSampleApp
//
//  Created by Drew Conner on 1/7/13.
//  Copyright (c) 2013 MailChimp. All rights reserved.
//

#import "AppDelegate.h"
#import "ChimpKit.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Set your API Key here
	[[ChimpKit sharedKit] setApiKey:@"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXX"];
	
    return YES;
}

@end
