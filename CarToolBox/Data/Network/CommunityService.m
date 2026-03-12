//
//  CommunityService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

#import "CommunityService.h"

@interface CommunityService ()
@property (nonatomic, copy) NSString *baseURL;
@end

@implementation CommunityService

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseURL = @"http://localhost:3000";
    }
    return self;
}

#pragma mark - Private Methods

- (NSURL *)urlForEndpoint:(NSString *)endpoint {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.baseURL, endpoint]];
}

- (void)makeRequest:(NSURLRequest *)request
         completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
                NSError *statusError = [NSError errorWithDomain:@"CommunityService"
                                                           code:httpResponse.statusCode
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Server error"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, statusError);
                });
                return;
            }

            if (data) {
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(json, jsonError);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, nil);
                });
            }
        }];
    [task resume];
}

- (NSMutableURLRequest *)requestForEndpoint:(NSString *)endpoint method:(NSString *)method {
    NSURL *url = [self urlForEndpoint:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    return request;
}

#pragma mark - Posts

- (void)getPostsPage:(NSInteger)page
            pageSize:(NSInteger)pageSize
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/posts?page=%ld&page_size=%ld", (long)page, (long)pageSize];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"GET"];
    [self makeRequest:request completion:completion];
}

- (void)getPostDetail:(NSString *)postId
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/posts/%@", postId];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"GET"];
    [self makeRequest:request completion:completion];
}

- (void)createPostWithTitle:(NSString *)title
                    content:(NSString *)content
                     media:(NSArray * _Nullable)media
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = @"/api/community/posts";
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"POST"];

    NSMutableDictionary *body = @{@"title": title, @"content": content}.mutableCopy;
    if (media) {
        body[@"media"] = media;
    }

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    }

    [self makeRequest:request completion:completion];
}

- (void)deletePost:(NSString *)postId
        completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/posts/%@", postId];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"DELETE"];
    [self makeRequest:request completion:completion];
}

#pragma mark - Likes

- (void)toggleLikeWithTargetType:(NSString *)targetType
                        targetId:(NSString *)targetId
                      completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = @"/api/community/like";
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"POST"];

    NSDictionary *body = @{@"target_type": targetType, @"target_id": targetId};
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    }

    [self makeRequest:request completion:completion];
}

#pragma mark - Comments

- (void)getCommentsForPost:(NSString *)postId
                      page:(NSInteger)page
                  pageSize:(NSInteger)pageSize
                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/posts/%@/comments?page=%ld&page_size=%ld",
                          postId, (long)page, (long)pageSize];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"GET"];
    [self makeRequest:request completion:completion];
}

- (void)createCommentForPost:(NSString *)postId
                     content:(NSString *)content
                   parentId:(NSString * _Nullable)parentId
              replyToUserId:(NSString * _Nullable)replyToUserId
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/posts/%@/comments", postId];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"POST"];

    NSMutableDictionary *body = @{@"content": content}.mutableCopy;
    if (parentId) {
        body[@"parent_id"] = parentId;
    }
    if (replyToUserId) {
        body[@"reply_to_user_id"] = replyToUserId;
    }

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (jsonData) {
        [request setHTTPBody:jsonData];
    }

    [self makeRequest:request completion:completion];
}

- (void)deleteComment:(NSString *)commentId
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = [NSString stringWithFormat:@"/api/community/comments/%@", commentId];
    NSMutableURLRequest *request = [self requestForEndpoint:endpoint method:@"DELETE"];
    [self makeRequest:request completion:completion];
}

#pragma mark - Media Upload

- (void)uploadImageWithData:(NSData *)imageData
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = @"/api/community/upload/image";
    NSURL *url = [self urlForEndpoint:endpoint];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
        forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n"]
        dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:body];
    [self makeRequest:request completion:completion];
}

- (void)uploadVideoWithURL:(NSURL *)videoURL
                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *endpoint = @"/api/community/upload/video";
    NSURL *url = [self urlForEndpoint:endpoint];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
        forHTTPHeaderField:@"Content-Type"];

    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    if (!videoData) {
        NSError *error = [NSError errorWithDomain:@"CommunityService"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Failed to read video file"}];
        completion(nil, error);
        return;
    }

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n"]
        dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: video/mp4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:videoData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:body];
    [self makeRequest:request completion:completion];
}

@end
