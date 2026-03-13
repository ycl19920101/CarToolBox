# CarToolBox 项目开发规则

## 项目概述
这是一个 **Objective-C 与 Swift 混编项目**。

## 混编架构
- **UI层**: SwiftUI (Views + ViewModels)
- **服务层**: Objective-C (网络请求、系统服务)
- **桥接方式**: Bridging Header (`CarToolBox/CarToolBox-Bridging-Header.h`)

## OC与Swift混编规则

### Swift 调用 OC（主要模式）

通过 Bridging Header 暴露的 OC 类，Swift 直接调用：

```swift
// OC定义: - (void)login:(NSString *)identifier password:(NSString *)pwd completion:(void(^)(NSDictionary *, NSError *))completion
// Swift调用:
AuthService.sharedInstance().login(withIdentifier: identifier, password: pwd) { data, error in
}
```

### 方法名转换规则

| OC语法 | Swift语法 |
|--------|-----------|
| `- (void)doSomething:` | `doSomething(_:)` |
| `- (void)doWithParam:(Type)param` | `do(withParam: param)` |
| `[Class shared]` | `Class.shared()` |
| `[[Class alloc] init]` | `Class()` |

### Block 转 Closure

```swift
// OC: void(^)(NSDictionary *, NSError *)
// Swift: ([AnyHashable: Any]?, Error?) -> Void
service.fetchData { data, error in
}
```

### 枚举桥接

```swift
// OC: typedef NS_ENUM(NSInteger, WindowPosition) { WindowPositionAll = 0 }
// Swift: WindowPosition.all (小写开头)
```

### 新增OC类时的步骤

1. 创建 `.h` 和 `.m` 文件
2. 在 `CarToolBox-Bridging-Header.h` 中添加 `#import "NewClass.h"`
3. Swift 中即可直接调用

### OC 调用 Swift（如需要）

```swift
@objc public class MySwiftClass: NSObject {
    @objc public func myMethod() { }
}
```

```objc
#import "CarToolBox-Swift.h"
```

## 现有OC服务类

| 类名 | 功能 | 位置 |
|------|------|------|
| `VehicleService` | 车辆控制 | `Data/Network/` |
| `AuthService` | 认证服务 | `Data/Network/` |
| `CommunityService` | 社区服务 | `Data/Network/` |
| `NotificationService` | 通知服务 | `Domain/Services/` |

## 编码规范

1. 新增网络服务优先使用 OC 实现
2. UI 和 ViewModel 使用 Swift/SwiftUI
3. OC 类使用单例模式：`+ (instancetype)sharedInstance`
4. 回调统一使用 Block
