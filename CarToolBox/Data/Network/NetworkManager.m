//
//  NetworkManager.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/13.
//

#import "NetworkManager.h"
#import "AuthService.h"
#import "CarToolBox-Swift.h"

// Constants
static NSString *const kDefaultBaseURL = @"http://localhost:3000";
static NSTimeInterval const kDefaultTimeout = 30.0;

// Error domain
NSErrorDomain const NetworkManagerErrorDomain = @"com.cartoolbox.network.error";

@interface NetworkManager ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_queue_t networkQueue;
@property (nonatomic, copy, nullable) NSString *manualAuthToken;
@end

@implementation NetworkManager

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static NetworkManager *shared = nil;
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
        _baseURL = kDefaultBaseURL;
        _timeoutInterval = kDefaultTimeout;

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = _timeoutInterval;
        config.timeoutIntervalForResource = _timeoutInterval * 2;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        _session = [NSURLSession sessionWithConfiguration:config];
        _networkQueue = dispatch_queue_create("com.cartoolbox.network", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Configuration

- (void)configureWithBaseURL:(NSString *)baseURL {
    self.baseURL = baseURL;
}

#pragma mark - Private Methods

- (NSURL *)URLForPath:(NSString *)path {
    // If path already contains full URL, use it directly
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"]) {
        return [NSURL URLWithString:path];
    }

    NSString *fullPath = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
    return [NSURL URLWithString:fullPath];
}

- (NSString *)httpMethodString:(HTTPMethod)method {
    switch (method) {
        case HTTPMethodGET: return @"GET";
        case HTTPMethodPOST: return @"POST";
        case HTTPMethodPUT: return @"PUT";
        case HTTPMethodPATCH: return @"PATCH";
        case HTTPMethodDELETE: return @"DELETE";
    }
}

- (NSString *)currentAuthToken {
    // Priority: manually set token > AuthService token
    if (self.manualAuthToken) {
        return self.manualAuthToken;
    }
    return [AuthService sharedInstance].currentAccessToken;
}

- (NSMutableURLRequest *)buildRequestWithPath:(NSString *)path
                                       method:(HTTPMethod)method
                                   parameters:(NSDictionary *)parameters
                                      headers:(NSDictionary *)headers {
    NSURL *url = [self URLForPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = [self httpMethodString:method];
    request.timeoutInterval = self.timeoutInterval;

    // Default headers
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // Add authorization header if token exists
    NSString *token = [self currentAuthToken];
    if (token.length > 0) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    }

    // Add custom headers
    if (headers) {
        for (NSString *key in headers) {
            [request setValue:headers[key] forHTTPHeaderField:key];
        }
    }

    // Add parameters
    if (parameters) {
        if (method == HTTPMethodGET || method == HTTPMethodDELETE) {
            // For GET/DELETE, add as URL query parameters
            NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSMutableArray *queryItems = [NSMutableArray array];
            for (NSString *key in parameters) {
                NSString *value = [NSString stringWithFormat:@"%@", parameters[key]];
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
            }
            components.queryItems = queryItems;
            request.URL = components.URL;
        } else {
            // For POST/PUT/PATCH, add as JSON body
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
            if (jsonData) {
                request.HTTPBody = jsonData;
            } else {
                [OCLogger error:@"Network" message:[NSString stringWithFormat:@"JSON serialization error: %@", error]];
            }
        }
    }

    return request;
}

- (NSError *)errorWithCode:(NetworkErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:NetworkManagerErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Unknown error"}];
}

- (NSError *)errorFromStatusCode:(NSInteger)statusCode {
    NSString *message = [self messageForStatusCode:statusCode];
    NetworkErrorCode code;

    switch (statusCode) {
        case 401: code = NetworkErrorCodeUnauthorized; break;
        case 403: code = NetworkErrorCodeForbidden; break;
        case 404: code = NetworkErrorCodeNotFound; break;
        default:
            if (statusCode >= 500) {
                code = NetworkErrorCodeServerError;
            } else {
                code = NetworkErrorCodeUnknown;
            }
            break;
    }

    return [self errorWithCode:code message:message];
}

- (NSString *)messageForStatusCode:(NSInteger)statusCode {
    switch (statusCode) {
        case 400: return @"请求参数错误";
        case 401: return @"未授权，请先登录";
        case 403: return @"无权限访问";
        case 404: return @"请求的资源不存在";
        case 429: return @"请求过于频繁";
        case 500: return @"服务器内部错误";
        case 502: return @"网关错误";
        case 503: return @"服务暂时不可用";
        default:
            if (statusCode >= 500) {
                return @"服务器错误";
            } else if (statusCode >= 400) {
                return @"请求失败";
            }
            return @"未知错误";
    }
}

#pragma mark - Logging

- (void)logRequest:(NSURLRequest *)request {
    NSString *bodyString = nil;
    if (request.HTTPBody) {
        bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    }
    [OCLogger logRequest:@"Network" method:request.HTTPMethod url:request.URL.absoluteString headers:request.allHTTPHeaderFields body:bodyString];
}

- (void)logResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error {
    NSString *dataString = nil;
    if (data) {
        dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    NSString *errorMessage = error ? error.localizedDescription : nil;
    [OCLogger logResponse:@"Network" url:response.URL.absoluteString statusCode:response.statusCode data:dataString errorMessage:errorMessage];
}

#pragma mark - Generic Request

- (void)requestWithPath:(NSString *)path
                 method:(HTTPMethod)method
             parameters:(NSDictionary *)parameters
                headers:(NSDictionary *)headers
             completion:(NetworkCompletionHandler)completion {
    NSMutableURLRequest *request = [self buildRequestWithPath:path method:method parameters:parameters headers:headers];

    [self logRequest:request];

    __weak typeof(self) weakSelf = self;

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [strongSelf logResponse:httpResponse data:data error:error];

        dispatch_async(strongSelf.networkQueue, ^{
            if (error) {
                // Network error (no connection, timeout, etc.)
                NetworkErrorCode code = NetworkErrorCodeUnknown;
                if (error.code == NSURLErrorTimedOut) {
                    code = NetworkErrorCodeTimeout;
                } else if (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorNetworkConnectionLost) {
                    code = NetworkErrorCodeNoConnection;
                }

                NSError *networkError = [strongSelf errorWithCode:code message:error.localizedDescription];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, 0, networkError);
                });
                return;
            }

            NSInteger statusCode = httpResponse.statusCode;

            // Parse JSON response
            NSDictionary *jsonResponse = nil;
            if (data && data.length > 0) {
                NSError *jsonError;
                jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (jsonError) {
                    NSError *parseError = [strongSelf errorWithCode:NetworkErrorCodeDecodingError message:@"解析响应失败"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, statusCode, parseError);
                    });
                    return;
                }
            } else {
                jsonResponse = @{};
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                completion(jsonResponse, statusCode, nil);
            });
        });
    }];

    [task resume];
}

#pragma mark - Convenience Methods

- (void)GET:(NSString *)path
 parameters:(NSDictionary *)parameters
 completion:(NetworkCompletionHandler)completion {
    [self requestWithPath:path method:HTTPMethodGET parameters:parameters headers:nil completion:completion];
}

- (void)POST:(NSString *)path
  parameters:(NSDictionary *)parameters
  completion:(NetworkCompletionHandler)completion {
    [self requestWithPath:path method:HTTPMethodPOST parameters:parameters headers:nil completion:completion];
}

- (void)PUT:(NSString *)path
 parameters:(NSDictionary *)parameters
 completion:(NetworkCompletionHandler)completion {
    [self requestWithPath:path method:HTTPMethodPUT parameters:parameters headers:nil completion:completion];
}

- (void)PATCH:(NSString *)path
   parameters:(NSDictionary *)parameters
   completion:(NetworkCompletionHandler)completion {
    [self requestWithPath:path method:HTTPMethodPATCH parameters:parameters headers:nil completion:completion];
}

- (void)DELETE:(NSString *)path
    parameters:(NSDictionary *)parameters
    completion:(NetworkCompletionHandler)completion {
    [self requestWithPath:path method:HTTPMethodDELETE parameters:parameters headers:nil completion:completion];
}

#pragma mark - Upload

- (void)uploadImage:(NSData *)imageData
               path:(NSString *)path
          fieldName:(NSString *)fieldName
           fileName:(NSString *)fileName
         completion:(NetworkUploadCompletionHandler)completion {
    NSString *field = fieldName.length > 0 ? fieldName : @"image";
    NSString *file = fileName.length > 0 ? fileName : @"image.jpg";

    NSURL *url = [self URLForPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval * 3; // Longer timeout for uploads

    // Add authorization header
    NSString *token = [self currentAuthToken];
    if (token.length > 0) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    }
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSString *boundary = [[NSUUID UUID] UUIDString];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];

    // Start boundary with --
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", field, file] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    // End boundary
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    [OCLogger debug:@"Network" message:[NSString stringWithFormat:@"Uploading image: field=%@, file=%@, size=%lu bytes", field, file, (unsigned long)imageData.length]];

    [self logRequest:request];

    __weak typeof(self) weakSelf = self;

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [strongSelf logResponse:httpResponse data:data error:error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSError *networkError = [strongSelf errorWithCode:NetworkErrorCodeUnknown message:error.localizedDescription];
                completion(nil, 0, networkError);
                return;
            }

            NSInteger statusCode = httpResponse.statusCode;

            NSDictionary *jsonResponse = nil;
            if (data && data.length > 0) {
                NSError *jsonError;
                jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            }

            completion(jsonResponse ?: @{}, statusCode, nil);
        });
    }];

    [task resume];
}

- (void)uploadVideo:(NSURL *)videoURL
               path:(NSString *)path
          fieldName:(NSString *)fieldName
           fileName:(NSString *)fileName
         completion:(NetworkUploadCompletionHandler)completion {
    NSString *field = fieldName.length > 0 ? fieldName : @"video";
    NSString *file = fileName.length > 0 ? fileName : @"video.mp4";

    // Read video data
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    if (!videoData) {
        NSError *error = [self errorWithCode:NetworkErrorCodeUnknown message:@"无法读取视频文件"];
        completion(nil, 0, error);
        return;
    }

    NSURL *url = [self URLForPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval * 10; // Much longer timeout for video uploads

    // Add authorization header
    NSString *token = [self currentAuthToken];
    if (token.length > 0) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    }

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", field, file] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: video/mp4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:videoData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    [self logRequest:request];

    __weak typeof(self) weakSelf = self;

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [strongSelf logResponse:httpResponse data:data error:error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSError *networkError = [strongSelf errorWithCode:NetworkErrorCodeUnknown message:error.localizedDescription];
                completion(nil, 0, networkError);
                return;
            }

            NSInteger statusCode = httpResponse.statusCode;

            NSDictionary *jsonResponse = nil;
            if (data && data.length > 0) {
                NSError *jsonError;
                jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            }

            completion(jsonResponse ?: @{}, statusCode, nil);
        });
    }];

    [task resume];
}

#pragma mark - Authorization

- (void)setAuthToken:(NSString *)token {
    self.manualAuthToken = token;
}

- (NSString *)authToken {
    return [self currentAuthToken];
}

- (void)clearAuthToken {
    self.manualAuthToken = nil;
}

@end
