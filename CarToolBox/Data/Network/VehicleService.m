//
//  VehicleService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

#import "VehicleService.h"

// Constants for air conditioner temperature bounds
static const double kMinTemperature = 16.0;
static const double kMaxTemperature = 30.0;
NSErrorDomain const VehicleServiceErrorDomain = @"VehicleService";

@implementation VehicleService

+ (instancetype)shared {
    static VehicleService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VehicleService alloc] init];
    });
    return instance;
}

- (void)getVehicleStatusWithCompletion:(void(^)(NSDictionary * _Nullable status, NSError * _Nullable error))completion {
    // Validate completion block to prevent crash
    if (!completion) {
        return;
    }

    // Simulate API call - delay 1 second
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *status = @{
            @"batteryLevel": @75.5,
            @"mileage": @12500.0,
            @"isLocked": @YES,
            @"temperature": @23.5,
            @"range": @320.0,
            @"chargingStatus": @"not_charging"
        };
        completion(status, nil);
    });
}

- (void)updateVehicleLock:(BOOL)locked completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Validate completion block to prevent crash
    if (!completion) {
        return;
    }

    // Simulate remote lock - delay 0.5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(YES, nil);
    });
}

- (void)getBatteryLevelWithCompletion:(void(^)(double level, NSError * _Nullable error))completion {
    // Validate completion block to prevent crash
    if (!completion) {
        return;
    }

    // Simulate getting battery level - delay 0.5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(75.5, nil);
    });
}

- (void)setAirConditioner:(BOOL)enabled
                 temperature:(double)temperature
                 completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    // Note: 'enabled' parameter is accepted for future use in controlling AC on/off state

    // Validate completion block to prevent crash
    if (!completion) {
        return;
    }

    // Parameter validation
    if (temperature < kMinTemperature || temperature > kMaxTemperature) {
        NSError *error = [NSError errorWithDomain:VehicleServiceErrorDomain
                                             code:VehicleServiceErrorInvalidParameter
                                         userInfo:@{NSLocalizedDescriptionKey: @"Temperature must be between 16°C and 30°C"}];
        completion(NO, error);
        return;
    }

    // Simulate API call - delay 1 second
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(YES, nil);
    });
}

- (void)setWindowPosition:(WindowPosition)position
                  openLevel:(double)level
                 completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    if (!completion) {
        return;
    }

    // Parameter validation
    if (level < 0.0 || level > 100.0) {
        NSError *error = [NSError errorWithDomain:VehicleServiceErrorDomain
                                             code:VehicleServiceErrorInvalidParameter
                                         userInfo:@{NSLocalizedDescriptionKey: @"Open level must be between 0% and 100%"}];
        completion(NO, error);
        return;
    }

    if (position < WindowPositionFrontLeft || position > WindowPositionAll) {
        NSError *error = [NSError errorWithDomain:VehicleServiceErrorDomain
                                             code:VehicleServiceErrorInvalidParameter
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid window position"}];
        completion(NO, error);
        return;
    }

    // Simulate API call - delay 0.8 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(YES, nil);
    });
}

- (void)triggerHornAndFlash:(void(^)(BOOL success, NSError * _Nullable error))completion {
    if (!completion) {
        return;
    }

    // Simulate API call - delay 0.5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion(YES, nil);
    });
}

@end
