//
//  VehicleService.h
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

#import <Foundation/Foundation.h>

// Error domain constant for VehicleService errors
extern NSErrorDomain const VehicleServiceErrorDomain;

// Error codes
typedef NS_ENUM(NSInteger, VehicleServiceError) {
    VehicleServiceErrorInvalidParameter = 1001,
    VehicleServiceErrorTimeout = 1002,
    VehicleServiceErrorDeviceOffline = 1003,
    VehicleServiceErrorOperationFailed = 1004
};

// Window position enum
typedef NS_ENUM(NSInteger, WindowPosition) {
    WindowPositionFrontLeft = 1,
    WindowPositionFrontRight = 2,
    WindowPositionRearLeft = 3,
    WindowPositionRearRight = 4,
    WindowPositionAll = 5
};

NS_ASSUME_NONNULL_BEGIN

@interface VehicleService : NSObject

+ (instancetype)shared;

// 获取车辆状态
- (void)getVehicleStatusWithCompletion:(void(^)(NSDictionary * _Nullable status, NSError * _Nullable error))completion;

// 更新车锁状态
- (void)updateVehicleLock:(BOOL)locked completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// 获取电池电量
- (void)getBatteryLevelWithCompletion:(void(^)(double level, NSError * _Nullable error))completion;

// Air conditioner control
- (void)setAirConditioner:(BOOL)enabled
               temperature:(double)temperature
                completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// Window control
- (void)setWindowPosition:(WindowPosition)position
                openLevel:(double)level
                completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

// Horn and flash
- (void)triggerHornAndFlash:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
