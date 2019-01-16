//
//  LocationManagerController.m
//  


#import "LocationManagerController.h"
#import "NotificationController.h"

@interface LocationManagerController ()

@end

@implementation LocationManagerController

+ (instancetype)sharedManager {
    
    static LocationManagerController *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    if (self = [super init]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // ensure location manager initialized on main queue
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
			// only available on iOS 9 or later. Needed for SLC updates
			if (@available(iOS 9.0, *)) {
				self.locationManager.allowsBackgroundLocationUpdates = YES;
			}
            self.locationManager.pausesLocationUpdatesAutomatically = NO; // prevent updates from quitting
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest; // ignored for SLC
            self.locationManager.distanceFilter = kCLDistanceFilterNone; // ignored for SLC
            self.locationManager.pausesLocationUpdatesAutomatically = NO; // prevents SLC from stopping
        });
    }
    return self;
}

+ (void)requestLocationPermissionWithCompletion:(LocationPermissionRequestCompletionHandler)completionHandler {
    LocationManagerController *lc = [LocationManagerController sharedManager];
    
    if (completionHandler != nil) {
        lc.completionBlock = completionHandler;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // user has not authorized us to use location
        if (lc.completionBlock != nil) {
            lc.completionBlock(LocationPermissionCompletionTypePermissionDenied);
            lc.completionBlock = nil;
        }
        return;
    }
	
	if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
		if (lc.completionBlock != nil) {
			lc.completionBlock(LocationPermissionCompletionTypePermissionWhenInUse);
			lc.completionBlock = nil;
		}
		return;
	}
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        // region monitoring not available for device
        if (lc.completionBlock != nil) {
            lc.completionBlock(LocationPermissionCompletionTypePermissionUnavailable);
            lc.completionBlock = nil;
        }
        return;
    } else {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            // trigger a location check to prompt user for authorization
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] addObserver:lc selector:@selector(checkForAuthorizationStatusChange) name:@"WaitingOnAuthorizationStatus" object:nil];
				[lc.locationManager requestAlwaysAuthorization];
			});
            return;
        }
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            // user has previously granted permission, just fire request always and return
			dispatch_async(dispatch_get_main_queue(), ^{
				[lc.locationManager requestAlwaysAuthorization];
				if (lc.completionBlock != nil) {
					lc.completionBlock(LocationPermissionCompletionTypePermissionAlways);
					lc.completionBlock = nil;
				}
			});
            return;
        }
    }
}

- (void)checkForAuthorizationStatusChange {
	dispatch_async(dispatch_get_main_queue(), ^{
		// set default compeltion type and update based on current permission
		LocationPermissionCompletionType completionType = LocationPermissionCompletionTypePermissionUnavailable;
		
		if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
			completionType = LocationPermissionCompletionTypePermissionAlways;
		}
		if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
			completionType = LocationPermissionCompletionTypePermissionWhenInUse;
		}
		if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
			[CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
			completionType = LocationPermissionCompletionTypePermissionDenied;
		}
		
		if (self.completionBlock) {
			self.completionBlock(completionType);
			self.completionBlock = nil;
		}
		
		// remove our notification observer
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"WaitingOnAuthorizationStatus" object:nil];
	});
}

+ (void)startMonitoringBeacon {
	NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"7FDB5A2D-4A58-44B4-B15E-FF833208E8F1"];
	CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"123"];
	
	LocationManagerController *lm = [LocationManagerController sharedManager];
	[lm.locationManager startMonitoringForRegion:beaconRegion];
}

#pragma mark LocationManagerController Delegate Methods
- (void)fenceError:(NSError *)error {
	NSLog(@"fence error: %@", error.localizedDescription);
	
	UILocalNotification *notif = [[UILocalNotification alloc] init];
	notif.alertBody = error.localizedDescription;
	notif.alertTitle = @"Beacon Error";
	notif.fireDate = nil;
	[NotificationController presentLocalNotification:notif];
	
    if ([self.delegate respondsToSelector:@selector(fenceError:)]) {
        [self.delegate fenceError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion: %@", region);
	
    // set up our long running background task
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask" expirationHandler:[self backgroundTaskExpirationBlock]];
	
    // check for beacons and get out
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
		if ([beaconRegion.identifier isEqualToString:@"123"]) {
			NSLog(@"beacon is ours");
			UILocalNotification *notif = [[UILocalNotification alloc] init];
			notif.alertBody = @"You have entered the Beacon";
			notif.alertTitle = @"Beacon Entry";
			notif.fireDate = nil;
			[NotificationController presentLocalNotification:notif];
		}
        
        [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
        self->bgTask = UIBackgroundTaskInvalid;
        return;
    }

    [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
    self->bgTask = UIBackgroundTaskInvalid;
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion: %@", region);
	
    // set up our long running background task
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask" expirationHandler:[self backgroundTaskExpirationBlock]];
    
    // check for beacons and get out
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
		CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
		if ([beaconRegion.identifier isEqualToString:@"123"]) {
			NSLog(@"beacon is ours");
			UILocalNotification *notif = [[UILocalNotification alloc] init];
			notif.alertBody = @"You have exited the Beacon";
			notif.alertTitle = @"Beacon Exit";
			notif.fireDate = nil;
			[NotificationController presentLocalNotification:notif];
		}
        
        [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
        self->bgTask = UIBackgroundTaskInvalid;
        return;
    }
	
    [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
    self->bgTask = UIBackgroundTaskInvalid;
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
	NSLog(@"didDetermineState: %@", region);
	
	if ([self.delegate respondsToSelector:@selector(didDetermineState:forRegion:)]) {
		[self.delegate didDetermineState:state forRegion:region];
	}
	
	if (state == CLRegionStateInside) {
		// user is inside the fence we just enabled
		NSLog(@"User is inside this location already");
	}
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    // should fire when region was added successfully
    NSLog(@"Region added ok");
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    // this method is called when the region can't be added
    // could be error or just too many fences on device
    NSLog(@"Region failed to monitor: %@", [error localizedDescription]);
	
    [self fenceError:error];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if ([self.delegate respondsToSelector:@selector(didRangeBeacons:inRegion:)]) {
        [self.delegate didRangeBeacons:beacons inRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"rangingBeaconsDidFailForRegion:");
	
    if ([self.delegate respondsToSelector:@selector(rangingBeaconsDidFailForRegion:withError:)]) {
        [self.delegate rangingBeaconsDidFailForRegion:region withError:error];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([self.delegate respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)]) {
        [self.delegate locationManager:manager didChangeAuthorizationStatus:status];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"LocationManager: didUpdateLocations: %@", locations);
    
    updateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"backgroundTask" expirationHandler:[self updateTaskExpirationBlock]];
		
    if (locations.count > 0) {
        // update location with valid location
        //CLLocation *location = locations[0];
    }
	
    [[UIApplication sharedApplication] endBackgroundTask:self->updateTask];
    self->updateTask = UIBackgroundTaskInvalid;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (error.code == kCLErrorDenied) {
		[self.locationManager stopMonitoringSignificantLocationChanges];
	}
}

#pragma mark - Task Management
- (taskCompletionBlock)backgroundTaskExpirationBlock {
	return ^{
		[[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
		self->bgTask = UIBackgroundTaskInvalid;
	};
}

- (taskCompletionBlock)statusTaskExpirationBlock {
	return ^{
		[[UIApplication sharedApplication] endBackgroundTask:self->statusTask];
		self->statusTask = UIBackgroundTaskInvalid;
	};
}

- (taskCompletionBlock)updateTaskExpirationBlock {
	return ^{
		[[UIApplication sharedApplication] endBackgroundTask:self->updateTask];
		self->updateTask = UIBackgroundTaskInvalid;
	};
}

@end
