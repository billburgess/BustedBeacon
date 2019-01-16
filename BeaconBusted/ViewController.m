//
//  ViewController.m
//  BeaconBusted
//
//  Created by Bill Burgess on 1/16/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "ViewController.h"
#import "LocationManagerController.h"
#import "NotificationController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString * CellIdentifier = @"CellIdentifier";
	
	UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}
	
	cell.textLabel.text = @"Start Monitoring Beacon";
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	[LocationManagerController requestLocationPermissionWithCompletion:^(LocationPermissionCompletionType completionType) {
		if (completionType == LocationPermissionCompletionTypePermissionAlways) {
			// user accepted location permission
			NSLog(@"location permission always, ok to monitor Beacons");
			[self registerForLocalNotifications];
		} else if (completionType == LocationPermissionCompletionTypePermissionDenied) {
			// user denied permission
			NSLog(@"location permission denied, unable to monitor Beacons");
		} else if (completionType == LocationPermissionCompletionTypePermissionWhenInUse) {
			// user did not give enough permission
			NSLog(@"location permission when in use, not enough permission to monitor Beacons");
		} else if (completionType == LocationPermissionCompletionTypePermissionUnavailable) {
			// location permission not available
			NSLog(@"location permission unavailable, unable to monitor Beacons");
		}
	}];
}

- (void)registerForLocalNotifications {
	self.nc = [[NotificationController alloc] init];
	
	[self.nc registerForLocalNotifications:^(NotificationCompletionType completionType) {
		if (completionType == NotificationCompletionTypeRequestSuccess) {
			// notifications permitted
			NSLog(@"notification permission allowed");
			[LocationManagerController startMonitoringBeacon];
		} else if (completionType == NotificationCompletionTypePermissionDenied) {
			// notification denied
			NSLog(@"notification permission no allowed");
		} else if (completionType == NotificationCompletionTypeRequestError) {
			// error requesting permission
			NSLog(@"notification permission error");
		}
	}];
}

@end
