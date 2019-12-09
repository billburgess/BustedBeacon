//
//  NotificationController.h
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, NotificationCompletionType) {
    NotificationCompletionTypePermissionDenied = 1,
    NotificationCompletionTypeRequestSuccess = 2,
    NotificationCompletionTypeRequestError = 3
};

typedef void(^ _Nullable NotificationRequestCompletionHandler)(NotificationCompletionType completionType);

@interface NotificationController : NSObject

@property (nullable, nonatomic, copy) NotificationRequestCompletionHandler completionBlock;

- (void)registerForPushNotifications:(NotificationRequestCompletionHandler)completionHandler;
- (void)registerForLocalNotifications:(NotificationRequestCompletionHandler)completionHandler;
- (void)unregisterForPushNotifications:(NotificationRequestCompletionHandler)completionHandler;

+ (void)presentLocalNotification:(UILocalNotification *_Nonnull)notification;

@end
