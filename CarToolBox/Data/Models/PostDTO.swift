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

    // Memberwise initializer for previews and manual construction
    init(
        id: String,
        user_id: String,
        title: String,
        content: String,
        status: String = "published",
        view_count: Int = 0,
        like_count: Int = 0,
        comment_count: Int = 0,
        created_at: String,
        updated_at: String? = nil,
        deleted_at: String? = nil,
        author_name: String? = nil,
        author_avatar: String? = nil,
        is_liked: Bool = false,
        media: [MediaDTO] = []
    ) {
        self.id = id
        self.user_id = user_id
        self.title = title
        self.content = content
        self.status = status
        self.view_count = view_count
        self.like_count = like_count
        self.comment_count = comment_count
        self.created_at = created_at
        self.updated_at = updated_at
        self.deleted_at = deleted_at
        self.author_name = author_name
        self.author_avatar = author_avatar
        self.is_liked = is_liked
        self.media = media
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id 可能有多种格式
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }

        // user_id 可能有多种格式
        if let userIdString = try? container.decode(String.self, forKey: .user_id) {
            user_id = userIdString
        } else if let userIdInt = try? container.decode(Int.self, forKey: .user_id) {
            user_id = String(userIdInt)
        } else {
            user_id = ""
        }

        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        status = (try? container.decode(String.self, forKey: .status)) ?? "published"
        view_count = (try? container.decode(Int.self, forKey: .view_count)) ?? 0
        like_count = (try? container.decode(Int.self, forKey: .like_count)) ?? 0
        comment_count = (try? container.decode(Int.self, forKey: .comment_count)) ?? 0
        created_at = try container.decode(String.self, forKey: .created_at)
        updated_at = try? container.decode(String.self, forKey: .updated_at)
        deleted_at = try? container.decode(String.self, forKey: .deleted_at)
        author_name = try? container.decode(String.self, forKey: .author_name)
        author_avatar = try? container.decode(String.self, forKey: .author_avatar)
        is_liked = (try? container.decode(Bool.self, forKey: .is_liked)) ?? false

        // media 解码，如果失败则使用空数组
        if let mediaArray = try? container.decode([MediaDTO].self, forKey: .media) {
            media = mediaArray
        } else {
            media = []
        }
    }

    var createdAtDate: Date? {
        return DateParser.parse(created_at)
    }

    /// Check if post has video media
    var hasVideo: Bool {
        return media.contains { $0.type == "video" }
    }

    /// Get the first video media if available
    var firstVideoMedia: MediaDTO? {
        return media.first { $0.type == "video" }
    }
}

// MARK: - Media Data Transfer Object

struct MediaDTO: Codable, Identifiable {
    let id: String
    let post_id: String?
    let type: String // 'image' or 'video'
    let url: String
    let thumbnail_url: String?
    let width: Int?
    let height: Int?
    let size: Int?
    let duration: Double?
    let sort_order: Int?

    enum CodingKeys: String, CodingKey {
        case id, post_id, type, url, thumbnail_url, width, height, size, duration, sort_order
    }

    // 完整 URL（自动拼接基础域名）
    var fullURL: String {
        return fullURLString(from: url)
    }

    var fullThumbnailURL: String? {
        guard let thumb = thumbnail_url else { return nil }
        return fullURLString(from: thumb)
    }

    private func fullURLString(from path: String) -> String {
        // 如果已经是完整 URL，直接返回
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        }
        // 否则拼接基础 URL
        let baseURL = Config.API.baseURL
        // 确保路径以 / 开头
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return baseURL + normalizedPath
    }

    // Memberwise initializer
    init(
        id: String = UUID().uuidString,
        post_id: String? = nil,
        type: String,
        url: String,
        thumbnail_url: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        size: Int? = nil,
        duration: Double? = nil,
        sort_order: Int? = nil
    ) {
        self.id = id
        self.post_id = post_id
        self.type = type
        self.url = url
        self.thumbnail_url = thumbnail_url
        self.width = width
        self.height = height
        self.size = size
        self.duration = duration
        self.sort_order = sort_order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id 可能有多种格式，尝试解析
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            // 如果没有 id，生成一个基于 url 的唯一标识
            id = UUID().uuidString
        }

        post_id = try? container.decode(String.self, forKey: .post_id)
        type = try container.decode(String.self, forKey: .type)
        url = try container.decode(String.self, forKey: .url)
        thumbnail_url = try? container.decode(String.self, forKey: .thumbnail_url)
        width = try? container.decode(Int.self, forKey: .width)
        height = try? container.decode(Int.self, forKey: .height)
        size = try? container.decode(Int.self, forKey: .size)
        duration = try? container.decode(Double.self, forKey: .duration)
        sort_order = try? container.decode(Int.self, forKey: .sort_order)
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id 可能有多种格式
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = UUID().uuidString
        }

        // post_id 可能有多种格式
        if let postIdString = try? container.decode(String.self, forKey: .post_id) {
            post_id = postIdString
        } else if let postIdInt = try? container.decode(Int.self, forKey: .post_id) {
            post_id = String(postIdInt)
        } else {
            post_id = ""
        }

        // user_id 可能有多种格式
        if let userIdString = try? container.decode(String.self, forKey: .user_id) {
            user_id = userIdString
        } else if let userIdInt = try? container.decode(Int.self, forKey: .user_id) {
            user_id = String(userIdInt)
        } else {
            user_id = ""
        }

        parent_id = try? container.decode(String.self, forKey: .parent_id)
        reply_to_user_id = try? container.decode(String.self, forKey: .reply_to_user_id)
        content = try container.decode(String.self, forKey: .content)
        like_count = (try? container.decode(Int.self, forKey: .like_count)) ?? 0
        status = (try? container.decode(String.self, forKey: .status)) ?? "active"
        created_at = (try? container.decode(String.self, forKey: .created_at)) ?? ISO8601DateFormatter().string(from: Date())
        deleted_at = try? container.decode(String.self, forKey: .deleted_at)

        author_name = try? container.decode(String.self, forKey: .author_name)
        author_avatar = try? container.decode(String.self, forKey: .author_avatar)
        reply_to_user_name = try? container.decode(String.self, forKey: .reply_to_user_name)
        is_liked = (try? container.decode(Bool.self, forKey: .is_liked)) ?? false
        replies = try? container.decode([CommentDTO].self, forKey: .replies)
    }

    var createdAtDate: Date? {
        return DateParser.parse(created_at)
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
