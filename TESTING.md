# Testing Guide for VehicleService and NotificationService

## Prerequisites

- iOS device or simulator running iOS 13.0+
- Notification permissions enabled in device Settings
- App installed and launched at least once
- Xcode console for log verification

## VehicleService Testing

### Air Conditioner Control
1. Open the app and navigate to Vehicle screen
2. Tap "空调控制" button
3. Verify action executes without error
4. Test with invalid temperature (e.g., 15°C or 31°C) - should show error

### Window Control
1. Tap "车窗控制" button
2. Verify action executes without error
3. Test with invalid open level (e.g., -1 or 101) - should show error

### Horn and Flash
1. Tap "鸣笛闪灯" button
2. Verify action executes without error

## NotificationService Testing

### Permission Request
1. Launch the app for the first time
2. Verify system notification permission dialog appears
3. Grant permission
4. Check console logs for "Notifications authorized"

### Battery Notification
1. Trigger battery notification scheduling (Note: Currently requires calling `scheduleBatteryNotification()` method directly in code, as no UI button exists yet)
2. Wait 60 seconds
3. Verify system notification banner appears
4. Verify charging complete notification is not cleared

### Charging Complete Notification
1. Trigger charging complete notification scheduling (Note: Currently requires calling `scheduleChargingCompleteNotification()` method directly in code, as no UI button exists yet)
2. Wait 60 seconds
3. Verify system notification banner appears
4. Verify battery notification is not cleared

### Foreground Notification Display
1. Schedule any notification via the methods above
2. Keep app in foreground when notification triggers
3. Verify system notification banner appears at the top of the screen
