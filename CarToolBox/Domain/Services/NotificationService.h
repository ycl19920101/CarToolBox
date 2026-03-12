//
//  NotificationService.h
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

// Error domain constant for NotificationService errors
extern NSErrorDomain const NotificationServiceErrorDomain;

// Error codes
typedef NS_ENUM(NSInteger, NotificationServiceError) {
    NotificationServiceErrorPermissionDenied = 2001,
    NotificationServiceErrorInvalidTrigger = 2002,
    NotificationServiceErrorSystemDisabled = 2003
};

NS_ASSUME_NONNULL_BEGIN

@interface NotificationService : NSObject <UNUserNotificationCenterDelegate>

+ (instancetype)shared;

// 请求通知权限
- (void)requestAuthorization;

// 调度电量提醒
- (void)scheduleBatteryNotification;

// 调充电完成通知
- (void)scheduleChargingCompleteNotification;

@end

NS_ASSUME_NONNULL_END
