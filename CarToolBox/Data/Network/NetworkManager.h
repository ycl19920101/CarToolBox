//
//  NetworkManager.h
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// HTTP Method enum
typedef NS_ENUM(NSInteger, HTTPMethod) {
    HTTPMethodGET,
    HTTPMethodPOST,
    HTTPMethodPUT,
    HTTPMethodPATCH,
    HTTPMethodDELETE
};

/// Completion handler for JSON requests
typedef void (^NetworkCompletionHandler)(NSDictionary * _Nullable data, NSInteger statusCode, NSError * _Nullable error);

/// Completion handler for upload requests
typedef void (^NetworkUploadCompletionHandler)(NSDictionary * _Nullable data, NSInteger statusCode, NSError * _Nullable error);

/// Completion handler for download requests
typedef void (^NetworkDownloadCompletionHandler)(NSURL * _Nullable fileURL, NSError * _Nullable error);

/// Network error domain
extern NSErrorDomain const NetworkManagerErrorDomain;

/// Network error codes
typedef NS_ENUM(NSInteger, NetworkErrorCode) {
    NetworkErrorCodeUnknown = -1,
    NetworkErrorCodeInvalidURL = -1001,
    NetworkErrorCodeNoConnection = -1002,
    NetworkErrorCodeTimeout = -1003,
    NetworkErrorCodeInvalidResponse = -1004,
    NetworkErrorCodeDecodingError = -1005,
    NetworkErrorCodeUnauthorized = 401,
    NetworkErrorCodeForbidden = 403,
    NetworkErrorCodeNotFound = 404,
    NetworkErrorCodeServerError = 500
};

/// Unified Network Manager - Singleton
@interface NetworkManager : NSObject

/// Shared singleton instance
+ (instancetype)sharedInstance;

/// Base URL for API requests
@property (nonatomic, copy) NSString *baseURL;

/// Request timeout interval (default 30 seconds)
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

#pragma mark - Configuration

/// Configure base URL (call once at app startup)
- (void)configureWithBaseURL:(NSString *)baseURL;

#pragma mark - Generic Requests

/// Perform a generic JSON request
/// @param path API path (will be appended to baseURL)
/// @param method HTTP method
/// @param parameters Request parameters (will be serialized to JSON body for POST/PUT/PATCH, or URL query for GET)
/// @param headers Additional headers (optional)
/// @param completion Completion handler with response data, status code, and error
- (void)requestWithPath:(NSString *)path
                 method:(HTTPMethod)method
             parameters:(NSDictionary * _Nullable)parameters
                headers:(NSDictionary * _Nullable)headers
             completion:(NetworkCompletionHandler)completion;

/// GET request
- (void)GET:(NSString *)path
 parameters:(NSDictionary * _Nullable)parameters
 completion:(NetworkCompletionHandler)completion;

/// POST request
- (void)POST:(NSString *)path
  parameters:(NSDictionary * _Nullable)parameters
  completion:(NetworkCompletionHandler)completion;

/// PUT request
- (void)PUT:(NSString *)path
 parameters:(NSDictionary * _Nullable)parameters
 completion:(NetworkCompletionHandler)completion;

/// PATCH request
- (void)PATCH:(NSString *)path
   parameters:(NSDictionary * _Nullable)parameters
   completion:(NetworkCompletionHandler)completion;

/// DELETE request
- (void)DELETE:(NSString *)path
    parameters:(NSDictionary * _Nullable)parameters
    completion:(NetworkCompletionHandler)completion;

#pragma mark - Upload

/// Upload image data with multipart/form-data
/// @param imageData Image data to upload
/// @param path API path
/// @param fieldName Form field name (default: "image")
/// @param fileName File name (default: "image.jpg")
/// @param completion Completion handler
- (void)uploadImage:(NSData *)imageData
               path:(NSString *)path
          fieldName:(NSString * _Nullable)fieldName
           fileName:(NSString * _Nullable)fileName
         completion:(NetworkUploadCompletionHandler)completion;

/// Upload video data with multipart/form-data
/// @param videoURL Video file URL
/// @param path API path
/// @param fieldName Form field name (default: "video")
/// @param fileName File name (default: "video.mp4")
/// @param completion Completion handler
- (void)uploadVideo:(NSURL *)videoURL
               path:(NSString *)path
          fieldName:(NSString * _Nullable)fieldName
           fileName:(NSString * _Nullable)fileName
         completion:(NetworkUploadCompletionHandler)completion;

#pragma mark - Authorization

/// Set authorization token manually (optional, auto-managed if using AuthService)
- (void)setAuthToken:(NSString * _Nullable)token;

/// Get current authorization token
- (NSString * _Nullable)authToken;

/// Clear authorization token
- (void)clearAuthToken;

#pragma mark - Utility

/// Build full URL from path
- (NSURL *)URLForPath:(NSString *)path;

/// Get error message for status code
- (NSString *)messageForStatusCode:(NSInteger)statusCode;

@end

NS_ASSUME_NONNULL_END
