//
//  CommunityService.m
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

#import "CommunityService.h"
#import "NetworkManager.h"

@implementation CommunityService

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static CommunityService *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - Error Handling

- (NSError *)errorFromResponse:(NSDictionary *)response statusCode:(NSInteger)statusCode {
    NSString *message = response[@"message"] ?: [[NetworkManager sharedInstance] messageForStatusCode:statusCode];
    NSInteger code = [response[@"error"][@"code"] integerValue] ?: statusCode;

    return [NSError errorWithDomain:@"CommunityService"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"请求失败"}];
}

#pragma mark - Posts

- (void)getPostsPage:(NSInteger)page
            pageSize:(NSInteger)pageSize
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/posts?page=%ld&page_size=%ld", (long)page, (long)pageSize];

    [[NetworkManager sharedInstance] GET:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)getPostDetail:(NSString *)postId
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/posts/%@", postId];

    [[NetworkManager sharedInstance] GET:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)createPostWithTitle:(NSString *)title
                    content:(NSString *)content
                      media:(NSArray * _Nullable)media
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = @"/api/community/posts";

    NSMutableDictionary *params = @{@"title": title, @"content": content}.mutableCopy;
    if (media) {
        params[@"media"] = media;
    }

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)deletePost:(NSString *)postId
        completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/posts/%@", postId];

    [[NetworkManager sharedInstance] DELETE:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Likes

- (void)toggleLikeWithTargetType:(NSString *)targetType
                        targetId:(NSString *)targetId
                      completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = @"/api/community/like";
    NSDictionary *params = @{@"targetType": targetType, @"targetId": targetId};

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Comments

- (void)getCommentsForPost:(NSString *)postId
                      page:(NSInteger)page
                  pageSize:(NSInteger)pageSize
                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/posts/%@/comments?page=%ld&page_size=%ld",
                      postId, (long)page, (long)pageSize];

    [[NetworkManager sharedInstance] GET:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)createCommentForPost:(NSString *)postId
                     content:(NSString *)content
                   parentId:(NSString * _Nullable)parentId
              replyToUserId:(NSString * _Nullable)replyToUserId
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/posts/%@/comments", postId];

    NSMutableDictionary *params = @{@"content": content}.mutableCopy;
    if (parentId) {
        params[@"parentId"] = parentId;
    }
    if (replyToUserId) {
        params[@"replyToUserId"] = replyToUserId;
    }

    [[NetworkManager sharedInstance] POST:path parameters:params completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300 && data[@"success"]) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)deleteComment:(NSString *)commentId
           completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    NSString *path = [NSString stringWithFormat:@"/api/community/comments/%@", commentId];

    [[NetworkManager sharedInstance] DELETE:path parameters:nil completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

#pragma mark - Media Upload

- (void)uploadImageWithData:(NSData *)imageData
                 completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [[NetworkManager sharedInstance] uploadImage:imageData
                                            path:@"/api/community/upload/image"
                                       fieldName:@"image"
                                        fileName:nil
                                      completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

- (void)uploadVideoWithURL:(NSURL *)videoURL
                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    [[NetworkManager sharedInstance] uploadVideo:videoURL
                                            path:@"/api/community/upload/video"
                                       fieldName:@"video"
                                        fileName:nil
                                      completion:^(NSDictionary *data, NSInteger statusCode, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        if (statusCode >= 200 && statusCode < 300) {
            completion(data, nil);
        } else {
            completion(nil, [self errorFromResponse:data statusCode:statusCode]);
        }
    }];
}

@end
