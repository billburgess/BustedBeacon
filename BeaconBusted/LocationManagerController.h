//
//  LocationManagerController.h
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

typedef void (^taskCompletionBlock)(void);
typedef void(^LMCStatusCompletionHandler)(BOOL success, NSError *error);

typedef NS_ENUM(NSInteger, LocationPermissionCompletionType) {
    LocationPermissionCompletionTypePermissionDenied = 1,
    LocationPermissionCompletionTypePermissionUnavailable = 2,
    LocationPermissionCompletionTypePermissionAlways = 3,
	LocationPermissionCompletionTypePermissionWhenInUse = 4
};

@protocol LocationManagerControllerDelegate <NSObject>
@optional
- (void)fenceError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region;
- (void)rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error;
- (void)didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region;
@end

typedef void(^ LocationPermissionRequestCompletionHandler)(LocationPermissionCompletionType completionType);

@interface LocationManagerController : NSObject <CLLocationManagerDelegate> {
    __block UIBackgroundTaskIdentifier bgTask;
	__block UIBackgroundTaskIdentifier statusTask;
	__block UIBackgroundTaskIdentifier updateTask;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) id<LocationManagerControllerDelegate> delegate;

@property (nonatomic, strong) id locationItemForStatusUpdate;

@property (nonatomic, copy) LocationPermissionRequestCompletionHandler completionBlock;

+ (instancetype)sharedManager;

+ (void)requestLocationPermissionWithCompletion:(LocationPermissionRequestCompletionHandler)completionHandler;

+ (void)startMonitoringBeacon;

@end
