//
//  NotificationController.m
//


#import "NotificationController.h"

@implementation NotificationController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerForPushNotifications:(NotificationRequestCompletionHandler)completionHandler {
    if (completionHandler) {
        // save our completion block for later handling
        self.completionBlock = completionHandler;
    }
    
    UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (grantedSettings.types == UIUserNotificationTypeNone) {
        if (self.completionBlock) {
            self.completionBlock(NotificationCompletionTypePermissionDenied);
            self.completionBlock = nil;
            return;
        }
    }
    
    [self registerForRemoteNotifications];
}

- (void)registerForLocalNotifications:(NotificationRequestCompletionHandler)completionHandler {
    if (completionHandler) {
        // save our completion block for later handling
        self.completionBlock = completionHandler;
    }
    
    [self registerForLocalNotifications];
}

- (void)unregisterForPushNotifications:(NotificationRequestCompletionHandler)completionHandler {
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
	
	if (completionHandler) {
		completionHandler(NotificationCompletionTypeRequestSuccess);
	}
}

- (void)registerForRemoteNotifications {
    // configure notification actions
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRegistrationComplete:) name:@"deviceRegistration" object:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    });
}

- (void)registerForLocalNotifications {
    // configure notification actions
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localRegistrationComplete:) name:@"localNotificationRegistration" object:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    });
}

- (void)localRegistrationComplete:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"localNotificationRegistration" object:nil];
    });
    
    UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (grantedSettings.types == UIUserNotificationTypeNone) {
        if (self.completionBlock) {
            self.completionBlock(NotificationCompletionTypePermissionDenied);
            self.completionBlock = nil;
        }
    } else {
        if (self.completionBlock) {
            self.completionBlock(NotificationCompletionTypeRequestSuccess);
            self.completionBlock = nil;
        }
    }
}

- (void)deviceRegistrationComplete:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceRegistration" object:nil];
    });

    NSString *token = notification.object;
    
    if (!token) {
        // no permission or registration failed
		
		// no previous device, likely first time request, user denied push
		if (self.completionBlock) {
			self.completionBlock(NotificationCompletionTypePermissionDenied);
			self.completionBlock = nil;
		}
    } else {
        // registration success
		if (self.completionBlock) {
			self.completionBlock(NotificationCompletionTypeRequestSuccess);
			self.completionBlock = nil;
		}
	}
}

#pragma mark - Presentation Methods
+ (void)presentLocalNotification:(UILocalNotification *)notification {
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

@end
