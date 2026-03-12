//
//  CommunityService.h
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Community service for network calls
@interface CommunityService : NSObject

/// Get posts list
/// @param page Page number (default 1)
/// @param pageSize Page size (default 20)
/// @param completion Completion handler with response data or error
- (void)getPostsPage:(NSInteger)page
            pageSize:(NSInteger)pageSize
           completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Get post detail
/// @param postId Post ID
/// @param completion Completion handler with response data or error
- (void)getPostDetail:(NSString *)postId
           completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Create a new post
/// @param title Post title
/// @param content Post content
/// @param media Media items (optional)
/// @param completion Completion handler with response data or error
- (void)createPostWithTitle:(NSString *)title
                    content:(NSString *)content
                     media:(NSArray * _Nullable)media
                 completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Delete a post
/// @param postId Post ID
/// @param completion Completion handler with response data or error
- (void)deletePost:(NSString *)postId
        completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Toggle like on a post or comment
/// @param targetType Target type ('post' or 'comment')
/// @param targetId Target ID
/// @param completion Completion handler with response data or error
- (void)toggleLikeWithTargetType:(NSString *)targetType
                        targetId:(NSString *)targetId
                      completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Get comments for a post
/// @param postId Post ID
/// @param page Page number
/// @param pageSize Page size
/// @param completion Completion handler with response data or error
- (void)getCommentsForPost:(NSString *)postId
                      page:(NSInteger)page
                  pageSize:(NSInteger)pageSize
                completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Create a comment
/// @param postId Post ID
/// @param content Comment content
/// @param parentId Parent comment ID (optional)
/// @param replyToUserId Reply to user ID (optional)
/// @param completion Completion handler with response data or error
- (void)createCommentForPost:(NSString *)postId
                     content:(NSString *)content
                   parentId:(NSString * _Nullable)parentId
              replyToUserId:(NSString * _Nullable)replyToUserId
                 completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Delete a comment
/// @param commentId Comment ID
/// @param completion Completion handler with response data or error
- (void)deleteComment:(NSString *)commentId
           completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Upload image
/// @param imageData Image data
/// @param completion Completion handler with response data or error
- (void)uploadImageWithData:(NSData *)imageData
                 completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/// Upload video
/// @param videoURL Video file URL
/// @param completion Completion handler with response data or error
- (void)uploadVideoWithURL:(NSURL *)videoURL
                completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
