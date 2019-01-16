//
//  AppDelegate.m
//  BeaconBusted
//
//  Created by Bill Burgess on 1/16/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	ViewController *vc = [[ViewController alloc] initWithStyle:UITableViewStyleGrouped];
	self.window.rootViewController = vc;
	[self.window makeKeyAndVisible];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"localNotificationRegistration" object:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSString *token = [deviceToken description];
	token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
	token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
	token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"deviceRegistration" object:token];
	});
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
#if !(TARGET_OS_SIMULATOR)
	//running on device
	
	// notify views that registration is complete without token
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"deviceRegistration" object:nil];
	});
#else
	// running in Simulator, use bogus token/device
	NSLog(@"Simulator returning bogus device token");
	
	NSString *token = @"f0614576b28f9a1aba6b2497a4b15603d8a88965a717d073cf462633b5beb15f";
	// notify views that registration is complete
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"deviceRegistration" object:token];
	});
#endif
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	NSLog(@"AppDelegate: didReceiveLocalNotification: %@", notification.alertBody);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSLog(@"AppDelegate: didReceiveRemoteNotification:");
}

@end
