//
//  NotificationService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

#import "NotificationService.h"

NSErrorDomain const NotificationServiceErrorDomain = @"NotificationService";

@implementation NotificationService

+ (instancetype)shared {
    static NotificationService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NotificationService alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)requestAuthorization {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert;
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"Notifications authorized");
        } else {
            NSLog(@"Notifications not authorized: %@", error.localizedDescription);
        }
    }];
}

- (void)scheduleBatteryNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    // Remove only the old battery notification, not all notifications
    [center removePendingNotificationRequestsWithIdentifiers:@[@"battery_notification"]];

    // Create battery reminder notification
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"电量提醒";
    content.body = @"车辆电量低于20%，请及时充电";
    content.sound = [UNNotificationSound defaultSound];

    // 1 hour later
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:3600 repeats:NO];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"battery_notification"
                                                                     content:content
                                                                     trigger:trigger];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to schedule battery notification: %@", error.localizedDescription);
        } else {
            NSLog(@"Battery notification scheduled");
        }
    }];
}

- (void)scheduleChargingCompleteNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    // Remove only the old charging complete notification, not all notifications
    [center removePendingNotificationRequestsWithIdentifiers:@[@"charging_complete_notification"]];

    // Create charging complete notification
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"充电完成";
    content.body = @"您的车辆已充满电";
    content.sound = [UNNotificationSound defaultSound];

    // 60 seconds later (for testing)
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:60 repeats:NO];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"charging_complete_notification"
                                                                     content:content
                                                                     trigger:trigger];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to schedule charging complete notification: %@", error.localizedDescription);
        } else {
            NSLog(@"Charging complete notification scheduled");
        }
    }];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    // 在前台显示通知
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler {
    completionHandler();
}

@end
