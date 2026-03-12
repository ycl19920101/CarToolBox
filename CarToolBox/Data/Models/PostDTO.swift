//
//  PostDTO.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

import Foundation

// MARK: - Post Data Transfer Object

struct PostDTO: Codable, Identifiable {
    let id: String
    let user_id: String
    let title: String
    let content: String
    let status: String
    let view_count: Int
    var like_count: Int
    var comment_count: Int
    let created_at: String
    let updated_at: String?
    let deleted_at: String?

    // Author info
    var author_name: String?
    var author_avatar: String?

    // Like status
    var is_liked: Bool

    // Media
    var media: [MediaDTO]

    enum CodingKeys: String, CodingKey {
        case id, user_id, title, content, status, view_count, like_count, comment_count
        case created_at, updated_at, deleted_at
        case author_name, author_avatar, is_liked, media
    }

    var createdAtDate: Date? {
        return ISO8601DateFormatter().date(from: created_at)
    }
}

// MARK: - Media Data Transfer Object

struct MediaDTO: Codable, Identifiable {
    let id: String
    let post_id: String
    let type: String // 'image' or 'video'
    let url: String
    let thumbnail_url: String?
    let width: Int?
    let height: Int?
    let size: Int?
    let duration: Double?
    let sort_order: Int

    enum CodingKeys: String, CodingKey {
        case id, post_id, type, url, thumbnail_url, width, height, size, duration, sort_order
    }
}

// MARK: - Comment Data Transfer Object

struct CommentDTO: Codable, Identifiable {
    let id: String
    let post_id: String
    let user_id: String
    let parent_id: String?
    let reply_to_user_id: String?
    let content: String
    let like_count: Int
    let status: String
    let created_at: String
    let deleted_at: String?

    // Author info
    var author_name: String?
    var author_avatar: String?
    var reply_to_user_name: String?

    // Like status
    var is_liked: Bool

    // Replies (for nested comments)
    var replies: [CommentDTO]?

    enum CodingKeys: String, CodingKey {
        case id, post_id, user_id, parent_id, reply_to_user_id, content
        case like_count, status, created_at, deleted_at
        case author_name, author_avatar, reply_to_user_name, is_liked, replies
    }

    var createdAtDate: Date? {
        return ISO8601DateFormatter().date(from: created_at)
    }
}

// MARK: - Posts Response

struct PostsResponse: Codable {
    let posts: [PostDTO]
    let total: Int
    let has_more: Bool
    let page: Int
    let page_size: Int
}

// MARK: - Comments Response

struct CommentsResponse: Codable {
    let comments: [CommentDTO]
    let total: Int
    let has_more: Bool
    let page: Int
    let page_size: Int
}

// MARK: - Like Response

struct LikeResponse: Codable {
    let liked: Bool
    let like_count: Int
}

// MARK: - Media Upload Request

struct MediaUpload: Codable {
    let type: String // 'image' or 'video'
    let url: String
    let thumbnail_url: String?
    let width: Int?
    let height: Int?
    let size: Int?
    let duration: Double?
}

// MARK: - Create Post Request

struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let media: [MediaUpload]?
}

// MARK: - Create Comment Request

struct CreateCommentRequest: Codable {
    let content: String
    let parent_id: String?
    let reply_to_user_id: String?
}

// MARK: - Upload Response

struct UploadResponse: Codable {
    let type: String
    let url: String
    let thumbnail_url: String?
    let width: Int?
    let height: Int?
    let size: Int?
    let duration: Double?
}
