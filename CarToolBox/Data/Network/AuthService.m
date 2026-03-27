//
//  AuthService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

#import "AuthService.h"
#import "NetworkManager.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

// Error domain
static NSString *const kAuthErrorDomain = @"com.cartoolbox.auth.error";

// Error codes
typedef NS_ENUM(NSInteger, AuthErrorCode) {
    AuthErrorCodeUnknown = 9001,
    AuthErrorCodeParameter = 1001,
    AuthErrorCodeUsernameExists = 1002,
    AuthErrorCodeVerificationError = 1003,
    AuthErrorCodeVerificationExpired = 1004,
    AuthErrorCodeNotAuthenticated = 2001,
    AuthErrorCodeTokenExpired = 2002,
    AuthErrorCodeInvalidCredentials = 2003,
    AuthErrorCodeInvalidRefreshToken = 2004,
    AuthErrorCodeNoPermission = 3001,
    AuthErrorCodeUserNotFound = 4001,
    AuthErrorCodeTooManyRequests = 5001
};

// MARK: - AuthTokens Implementation

@implementation AuthTokens

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        // Support both snake_case and camelCase formats
        _accessToken = dict[@"access_token"] ?: dict[@"accessToken"] ?: dict[@"token"] ?: @"";
        _refreshToken = dict[@"refresh_token"] ?: dict[@"refreshToken"] ?: @"";
        _expiresIn = [dict[@"expires_in"] integerValue] ?: [dict[@"expiresIn"] integerValue];
    }
    return self;
}

@end

// MARK: - AuthUser Implementation

@implementation AuthUser

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _userId = dict[@"id"] ?: @"";
        _username = dict[@"username"] ?: @"";
        _email = dict[@"email"];
        _phone = dict[@"phone"];
        _avatar = dict[@"avatar"];
        _createdAt = dict[@"created_at"];
        _updatedAt = dict[@"updated_at"];
        _lastLoginAt = dict[@"last_login_at"];
    }
    return self;
}

@end

// MARK: - AuthService Implementation

@implementation AuthService

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static AuthService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentAccessToken = nil;
        _currentRefreshToken = nil;
    }
    return self;
}

#pragma mark - Private Methods

- (NSString *)authPath:(NSString *)path {
    return [NSString stringWithFormat:@"/api/auth%@", path];
}

- (NSDictionary *)deviceInfo {
    struct utsname systemInfo;
    uname(&systemInfo);

    return @{
        @"deviceName": [[UIDevice currentDevice] name] ?: @"Unknown Device",
        @"deviceId": [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"unknown",
        @"model": [NSString stringWithUTF8String:systemInfo.machine] ?: @"unknown",
        @"systemVersion": [[UIDevice currentDevice] systemVersion] ?: @"unknown"
    };
}

- (NSError *)errorFromResponse:(NSDictionary *)response statusCode:(NSInteger)statusCode {
    if (response[@"error"]) {
        NSDictionary *errorDict = response[@"error"];
        NSInteger code = [errorDict[@"code"] integerValue];
        NSString *message = response[@"message"] ?: @"Unknown error";

        return [NSError errorWithDomain:kAuthErrorDomain
                                   code:code
                               userInfo:@{NSLocalizedDescriptionKey: message}];
    }

    // Default error based on status code
    NSString *message = [[NetworkManager sharedInstance] messageForStatusCode:statusCode];
    NSInteger code = statusCode == 401 ? AuthErrorCodeNotAuthenticated : AuthErrorCodeUnknown;

    return [NSError errorWithDomain:kAuthErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Authentication

- (void)registerWithUsername:(NSString *)username
                    password:(NSString *)password
                       email:(NSString *)email
                       phone:(NSString *)phone
                  completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *params = [[self deviceInfo] mutableCopy];
    params[@"username"] = username;
    params[@"password"] = password;
    if (email) params[@"email"] = email;
    if (phone) params[@"phone"] = phone;

    NSString *path = [self authPath:@"/register"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            NSDictionary *responseData = data[@"data"];
            // Store tokens - support both nested and root level formats
            if (responseData[@"tokens"]) {
                [self updateTokensWithDictionary:responseData[@"tokens"]];
            } else if (responseData[@"accessToken"]) {
                // Tokens at root level of data
                [self updateTokensWithDictionary:responseData];
            }

            completion(responseData, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)loginWithIdentifier:(NSString *)identifier
                  password:(NSString *)password
              rememberMe:(BOOL)rememberMe
               completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *params = [[self deviceInfo] mutableCopy];
    params[@"username"] = identifier;
    params[@"password"] = password;
    params[@"rememberMe"] = @(rememberMe);

    NSString *path = [self authPath:@"/login"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            NSDictionary *responseData = data[@"data"];
            // Store tokens - support both nested and root level formats
            if (responseData[@"tokens"]) {
                [self updateTokensWithDictionary:responseData[@"tokens"]];
            } else if (responseData[@"accessToken"]) {
                // Tokens at root level of data
                [self updateTokensWithDictionary:responseData];
            }

            completion(responseData, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)loginWithPhone:(NSString *)phone
                  code:(NSString *)code
            completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *params = [[self deviceInfo] mutableCopy];
    params[@"phone"] = phone;
    params[@"code"] = code;

    NSString *path = [self authPath:@"/login-sms"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            // Store tokens
            if (data[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:data[@"data"][@"tokens"]];
            }

            completion(data[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)loginWithBiometricToken:(NSString *)refreshToken
                     completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *params = [[self deviceInfo] mutableCopy];
    params[@"refreshToken"] = refreshToken;

    NSString *path = [self authPath:@"/biometric-login"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            // Store tokens
            if (data[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:data[@"data"][@"tokens"]];
            }

            completion(data[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)sendVerificationCodeToPhone:(NSString *)phone
                               type:(NSString *)type
                         completion:(AuthCompletionHandler)completion {
    NSDictionary *params = @{@"phone": phone, @"type": type};
    NSString *path = [self authPath:@"/send-code"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(data[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Password Management

- (void)changePasswordFrom:(NSString *)oldPassword
                        to:(NSString *)newPassword
                 completion:(SimpleCompletionHandler)completion {
    NSDictionary *params = @{
        @"oldPassword": oldPassword,
        @"newPassword": newPassword
    };

    NSString *path = [self authPath:@"/change-password"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(NO, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)forgotPasswordWithEmail:(NSString *)email
                     completion:(AuthCompletionHandler)completion {
    NSDictionary *params = @{@"email": email};
    NSString *path = [self authPath:@"/forgot-password"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        // For forgot password, always return success even if user doesn't exist (security)
        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)resetPasswordWithToken:(NSString *)token
                  newPassword:(NSString *)newPassword
                   completion:(SimpleCompletionHandler)completion {
    NSDictionary *params = @{
        @"token": token,
        @"password": newPassword
    };

    NSString *path = [self authPath:@"/reset-password"];

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(NO, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Token Management

- (void)refreshToken:(NSString *)refreshToken
          completion:(AuthCompletionHandler)completion {
    NSDictionary *params = @{@"refreshToken": refreshToken};
    NSString *path = [self authPath:@"/refresh"];

    // Temporarily clear the access token to avoid sending expired token
    NSString *oldAccessToken = [AuthService sharedInstance].currentAccessToken;
    [AuthService sharedInstance].currentAccessToken = nil;

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            // Restore old token on error (will be cleared by caller if needed)
            [AuthService sharedInstance].currentAccessToken = oldAccessToken;
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            // Update tokens from response
            NSDictionary *responseData = data[@"data"];
            if (responseData[@"tokens"]) {
                [self updateTokensWithDictionary:responseData[@"tokens"]];
            } else if (responseData[@"accessToken"]) {
                // Tokens at root level of data
                [self updateTokensWithDictionary:responseData];
            }
            completion(responseData, nil);
        } else {
            // Restore old token on failure
            [AuthService sharedInstance].currentAccessToken = oldAccessToken;
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)logoutWithCompletion:(SimpleCompletionHandler)completion {
    NSString *path = [self authPath:@"/logout"];

    [[NetworkManager sharedInstance] POST:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        // Always clear local tokens regardless of server response
        [self clearTokens];

        if (error) {
            // For logout, success even if network fails
            completion(YES, nil);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - User Info

- (void)getCurrentUserWithCompletion:(AuthCompletionHandler)completion {
    NSString *path = [self authPath:@"/me"];

    [[NetworkManager sharedInstance] GET:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(data[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Utility

- (void)setAccessToken:(NSString *)token {
    _currentAccessToken = [token copy];
}

- (void)clearTokens {
    _currentAccessToken = nil;
    _currentRefreshToken = nil;
}

- (void)updateTokensWithDictionary:(NSDictionary *)dict {
    AuthTokens *tokens = [[AuthTokens alloc] initWithDictionary:dict];
    self.currentAccessToken = tokens.accessToken;
    self.currentRefreshToken = tokens.refreshToken;
}

- (BOOL)isAuthenticated {
    return self.currentAccessToken != nil && self.currentAccessToken.length > 0;
}

@end
