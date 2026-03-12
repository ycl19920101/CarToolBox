//
//  AuthService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

#import "AuthService.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

// Constants
static NSString *const kDefaultBaseURL = @"http://localhost:3000/api";
static NSString *const kAuthPath = @"/auth";

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
        _accessToken = dict[@"access_token"] ?: @"";
        _refreshToken = dict[@"refresh_token"] ?: @"";
        _expiresIn = [dict[@"expires_in"] integerValue];
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

@interface AuthService ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t networkQueue;
@end

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
    return [self initWithBaseURL:kDefaultBaseURL];
}

- (instancetype)initWithBaseURL:(NSString *)baseURL {
    self = [super init];
    if (self) {
        _baseURL = [baseURL copy];
        _currentAccessToken = nil;
        _currentRefreshToken = nil;
        _session = [NSURLSession sharedSession];
        _networkQueue = dispatch_queue_create("com.cartoolbox.auth.network", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Private Methods

- (NSURL *)URLForPath:(NSString *)path {
    NSString *fullPath = [NSString stringWithFormat:@"%@%@%@", self.baseURL, kAuthPath, path];
    return [NSURL URLWithString:fullPath];
}

- (NSMutableURLRequest *)requestForPath:(NSString *)path method:(NSString *)method body:(NSDictionary * _Nullable)body {
    NSURL *url = [self URLForPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // Add auth token if available
    if (self.currentAccessToken) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.currentAccessToken] forHTTPHeaderField:@"Authorization"];
    }

    // Add body if present
    if (body) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        if (jsonData) {
            request.HTTPBody = jsonData;
        } else {
            NSLog(@"Error serializing JSON: %@", error);
        }
    }

    return request;
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
    NSString *message = [self messageForStatusCode:statusCode];
    NSInteger code = statusCode == 401 ? AuthErrorCodeNotAuthenticated : AuthErrorCodeUnknown;

    return [NSError errorWithDomain:kAuthErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (NSString *)messageForStatusCode:(NSInteger)statusCode {
    switch (statusCode) {
        case 400: return @"请求参数错误";
        case 401: return @"未授权，请先登录";
        case 403: return @"无权限访问";
        case 404: return @"请求的资源不存在";
        case 429: return @"请求过于频繁";
        case 500: return @"服务器内部错误";
        default: return @"请求失败";
    }
}

- (NSDictionary *)deviceInfo {
    struct utsname systemInfo;
    uname(&systemInfo);

    return @{
        @"device_name": [[UIDevice currentDevice] name] ?: @"Unknown Device",
        @"device_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"unknown",
        @"model": [NSString stringWithUTF8String:systemInfo.machine] ?: @"unknown",
        @"system_version": [[UIDevice currentDevice] systemVersion] ?: @"unknown"
    };
}

#pragma mark - Network Request

- (void)performRequest:(NSURLRequest *)request completion:(void (^)(NSDictionary * _Nullable, NSInteger, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        dispatch_async(strongSelf.networkQueue ?: dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, 0, error);
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;

            if (data && data.length > 0) {
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                if (jsonError) {
                    completion(nil, statusCode, [NSError errorWithDomain:kAuthErrorDomain
                                                                  code:AuthErrorCodeUnknown
                                                              userInfo:@{NSLocalizedDescriptionKey: @"解析响应失败"}]);
                    return;
                }

                completion(json, statusCode, nil);
            } else {
                completion(@{}, statusCode, nil);
            }
        });
    }];

    [task resume];
}

#pragma mark - Authentication

- (void)registerWithUsername:(NSString *)username
                    password:(NSString *)password
                       email:(NSString *)email
                       phone:(NSString *)phone
                  completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *body = [[self deviceInfo] mutableCopy];
    body[@"username"] = username;
    body[@"password"] = password;
    if (email) body[@"email"] = email;
    if (phone) body[@"phone"] = phone;

    NSMutableURLRequest *request = [self requestForPath:@"/register" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            // Store tokens
            if (response[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:response[@"data"][@"tokens"]];
            }

            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)loginWithIdentifier:(NSString *)identifier
                  password:(NSString *)password
              rememberMe:(BOOL)rememberMe
               completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *body = [[self deviceInfo] mutableCopy];
    body[@"identifier"] = identifier;
    body[@"password"] = password;
    body[@"remember_me"] = @(rememberMe);

    NSMutableURLRequest *request = [self requestForPath:@"/login" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            // Store tokens
            if (response[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:response[@"data"][@"tokens"]];
            }

            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)loginWithPhone:(NSString *)phone
                  code:(NSString *)code
            completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *body = [[self deviceInfo] mutableCopy];
    body[@"phone"] = phone;
    body[@"code"] = code;

    NSMutableURLRequest *request = [self requestForPath:@"/login-sms" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            // Store tokens
            if (response[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:response[@"data"][@"tokens"]];
            }

            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)loginWithBiometricToken:(NSString *)refreshToken
                     completion:(AuthCompletionHandler)completion {
    NSMutableDictionary *body = [[self deviceInfo] mutableCopy];
    body[@"refresh_token"] = refreshToken;

    NSMutableURLRequest *request = [self requestForPath:@"/biometric-login" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            // Store tokens
            if (response[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:response[@"data"][@"tokens"]];
            }

            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)sendVerificationCodeToPhone:(NSString *)phone
                               type:(NSString *)type
                         completion:(AuthCompletionHandler)completion {
    NSDictionary *body = @{@"phone": phone, @"type": type};
    NSMutableURLRequest *request = [self requestForPath:@"/send-code" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

#pragma mark - Password Management

- (void)changePasswordFrom:(NSString *)oldPassword
                        to:(NSString *)newPassword
                 completion:(SimpleCompletionHandler)completion {
    NSDictionary *body = @{
        @"old_password": oldPassword,
        @"new_password": newPassword
    };

    NSMutableURLRequest *request = [self requestForPath:@"/change-password" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(NO, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)forgotPasswordWithEmail:(NSString *)email
                     completion:(AuthCompletionHandler)completion {
    NSDictionary *body = @{@"email": email};
    NSMutableURLRequest *request = [self requestForPath:@"/forgot-password" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        // For forgot password, always return success even if user doesn't exist (security)
        if (statusCode >= 200 && statusCode < 300) {
            completion(response, nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)resetPasswordWithToken:(NSString *)token
                  newPassword:(NSString *)newPassword
                   completion:(SimpleCompletionHandler)completion {
    NSDictionary *body = @{
        @"token": token,
        @"password": newPassword
    };

    NSMutableURLRequest *request = [self requestForPath:@"/reset-password" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(NO, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            completion(YES, nil);
        } else {
            completion(NO, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

#pragma mark - Token Management

- (void)refreshToken:(NSString *)refreshToken
          completion:(AuthCompletionHandler)completion {
    NSDictionary *body = @{@"refresh_token": refreshToken};
    NSMutableURLRequest *request = [self requestForPath:@"/refresh" method:@"POST" body:body];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            // Update tokens
            if (response[@"data"][@"tokens"]) {
                [self updateTokensWithDictionary:response[@"data"][@"tokens"]];
            }

            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

- (void)logoutWithCompletion:(SimpleCompletionHandler)completion {
    NSMutableURLRequest *request = [self requestForPath:@"/logout" method:@"POST" body:nil];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
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
            completion(NO, [self errorFromResponse:response statusCode:statusCode]);
        }
    }];
}

#pragma mark - User Info

- (void)getCurrentUserWithCompletion:(AuthCompletionHandler)completion {
    NSMutableURLRequest *request = [self requestForPath:@"/me" method:@"GET" body:nil];

    [self performRequest:request completion:^(NSDictionary *response, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && response[@"success"]) {
            completion(response[@"data"], nil);
        } else {
            completion(nil, [self errorFromResponse:response statusCode:statusCode]);
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
