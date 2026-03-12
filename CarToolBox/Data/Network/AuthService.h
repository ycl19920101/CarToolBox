//
//  AuthService.h
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Auth completion handler block
typedef void (^AuthCompletionHandler)(NSDictionary * _Nullable data, NSError * _Nullable error);

/// Simple completion handler
typedef void (^SimpleCompletionHandler)(BOOL success, NSError * _Nullable error);

/// Token data model
@interface AuthTokens : NSObject
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, assign) NSInteger expiresIn;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

/// User data model
@interface AuthUser : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic, copy, nullable) NSString *phone;
@property (nonatomic, copy, nullable) NSString *avatar;
@property (nonatomic, copy, nullable) NSString *createdAt;
@property (nonatomic, copy, nullable) NSString *updatedAt;
@property (nonatomic, copy, nullable) NSString *lastLoginAt;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

/// Authentication service
@interface AuthService : NSObject

/// Shared singleton instance
+ (instancetype)sharedInstance;

/// API base URL (configurable)
@property (nonatomic, copy) NSString *baseURL;

/// Current access token
@property (nonatomic, copy, nullable) NSString *currentAccessToken;

/// Current refresh token
@property (nonatomic, copy, nullable) NSString *currentRefreshToken;

/// Initialize with default base URL
- (instancetype)init;

/// Initialize with custom base URL
- (instancetype)initWithBaseURL:(NSString *)baseURL;

// MARK: - Authentication

/// Register a new user
/// @param username Username
/// @param password Password
/// @param email Email (optional)
/// @param phone Phone (optional)
/// @param completion Completion handler with user and tokens
- (void)registerWithUsername:(NSString *)username
                    password:(NSString *)password
                       email:(NSString * _Nullable)email
                       phone:(NSString * _Nullable)phone
                  completion:(AuthCompletionHandler)completion;

/// Login with username/email and password
/// @param identifier Username or email
/// @param password Password
/// @param rememberMe Remember me flag
/// @param completion Completion handler with user and tokens
- (void)loginWithIdentifier:(NSString *)identifier
                  password:(NSString *)password
              rememberMe:(BOOL)rememberMe
               completion:(AuthCompletionHandler)completion;

/// Login with SMS verification code
/// @param phone Phone number
/// @param code Verification code
/// @param completion Completion handler with user and tokens
- (void)loginWithPhone:(NSString *)phone
                  code:(NSString *)code
            completion:(AuthCompletionHandler)completion;

/// Login with biometric authentication (using stored refresh token)
/// @param refreshToken Stored refresh token
/// @param completion Completion handler with user and tokens
- (void)loginWithBiometricToken:(NSString *)refreshToken
                     completion:(AuthCompletionHandler)completion;

/// Send verification code
/// @param phone Phone number
/// @param type Code type: "register", "login", "reset"
/// @param completion Completion handler
- (void)sendVerificationCodeToPhone:(NSString *)phone
                               type:(NSString *)type
                         completion:(AuthCompletionHandler)completion;

// MARK: - Password Management

/// Change password
/// @param oldPassword Current password
/// @param newPassword New password
/// @param completion Completion handler
- (void)changePasswordFrom:(NSString *)oldPassword
                        to:(NSString *)newPassword
                 completion:(SimpleCompletionHandler)completion;

/// Request password reset
/// @param email Email address
/// @param completion Completion handler
- (void)forgotPasswordWithEmail:(NSString *)email
                     completion:(AuthCompletionHandler)completion;

/// Reset password with token
/// @param token Reset token
/// @param newPassword New password
/// @param completion Completion handler
- (void)resetPasswordWithToken:(NSString *)token
                  newPassword:(NSString *)newPassword
                   completion:(SimpleCompletionHandler)completion;

// MARK: - Token Management

/// Refresh access token using refresh token
/// @param refreshToken Refresh token
/// @param completion Completion handler with new tokens
- (void)refreshToken:(NSString *)refreshToken
          completion:(AuthCompletionHandler)completion;

/// Logout current user
/// @param completion Completion handler
- (void)logoutWithCompletion:(SimpleCompletionHandler)completion;

// MARK: - User Info

/// Get current user information
/// @param completion Completion handler with user data
- (void)getCurrentUserWithCompletion:(AuthCompletionHandler)completion;

// MARK: - Utility

/// Set access token for authenticated requests
/// @param token Access token
- (void)setAccessToken:(NSString *)token;

/// Clear all stored tokens
- (void)clearTokens;

/// Check if user is authenticated
- (BOOL)isAuthenticated;

@end

NS_ASSUME_NONNULL_END
