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
        case id
        case user_id = "userId"
        case title, content, status
        case view_count = "viewCount"
        case like_count = "likeCount"
        case comment_count = "commentCount"
        case created_at = "createdAt"
        case updated_at = "updatedAt"
        case deleted_at = "deletedAt"
        case author_name, author_avatar
        case is_liked = "isLiked"
        case media
        case author
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

        // user_id 可能有多种格式，也可能从 author.id 获取
        if let userIdString = try? container.decode(String.self, forKey: .user_id) {
            user_id = userIdString
        } else if let userIdInt = try? container.decode(Int.self, forKey: .user_id) {
            user_id = String(userIdInt)
        } else if let author = try? container.decode(AuthorDTO.self, forKey: .author) {
            user_id = author.id
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

        // 优先从嵌套 author 对象获取，其次从平铺字段获取
        if let author = try? container.decode(AuthorDTO.self, forKey: .author) {
            author_name = author.username
            author_avatar = author.avatar
        } else {
            author_name = try? container.decode(String.self, forKey: .author_name)
            author_avatar = try? container.decode(String.self, forKey: .author_avatar)
        }

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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(status, forKey: .status)
        try container.encode(view_count, forKey: .view_count)
        try container.encode(like_count, forKey: .like_count)
        try container.encode(comment_count, forKey: .comment_count)
        try container.encode(created_at, forKey: .created_at)
        try container.encodeIfPresent(updated_at, forKey: .updated_at)
        try container.encodeIfPresent(deleted_at, forKey: .deleted_at)
        try container.encodeIfPresent(author_name, forKey: .author_name)
        try container.encodeIfPresent(author_avatar, forKey: .author_avatar)
        try container.encode(is_liked, forKey: .is_liked)
        try container.encode(media, forKey: .media)
    }
}

// MARK: - Author Data Transfer Object

struct AuthorDTO: Codable {
    let id: String
    let username: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id, username, avatar
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = ""
        }

        username = try? container.decode(String.self, forKey: .username)
        avatar = try? container.decode(String.self, forKey: .avatar)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(avatar, forKey: .avatar)
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
        case id
        case post_id = "postId"
        case type, url
        case thumbnail_url = "thumbnailUrl"
        case width, height, size, duration
        case sort_order = "sortOrder"
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
        case id
        case post_id = "postId"
        case user_id = "userId"
        case parent_id = "parentId"
        case reply_to_user_id = "replyToUserId"
        case content
        case like_count = "likeCount"
        case status
        case created_at = "createdAt"
        case deleted_at = "deletedAt"
        case author_name, author_avatar, reply_to_user_name
        case is_liked = "isLiked"
        case replies
        case author
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

        // user_id 可能有多种格式，也可能从 author.id 获取
        if let userIdString = try? container.decode(String.self, forKey: .user_id) {
            user_id = userIdString
        } else if let userIdInt = try? container.decode(Int.self, forKey: .user_id) {
            user_id = String(userIdInt)
        } else if let author = try? container.decode(AuthorDTO.self, forKey: .author) {
            user_id = author.id
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

        // 优先从嵌套 author 对象获取，其次从平铺字段获取
        if let author = try? container.decode(AuthorDTO.self, forKey: .author) {
            author_name = author.username
            author_avatar = author.avatar
        } else {
            author_name = try? container.decode(String.self, forKey: .author_name)
            author_avatar = try? container.decode(String.self, forKey: .author_avatar)
        }

        reply_to_user_name = try? container.decode(String.self, forKey: .reply_to_user_name)
        is_liked = (try? container.decode(Bool.self, forKey: .is_liked)) ?? false
        replies = try? container.decode([CommentDTO].self, forKey: .replies)
    }

    var createdAtDate: Date? {
        return DateParser.parse(created_at)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(post_id, forKey: .post_id)
        try container.encode(user_id, forKey: .user_id)
        try container.encodeIfPresent(parent_id, forKey: .parent_id)
        try container.encodeIfPresent(reply_to_user_id, forKey: .reply_to_user_id)
        try container.encode(content, forKey: .content)
        try container.encode(like_count, forKey: .like_count)
        try container.encode(status, forKey: .status)
        try container.encode(created_at, forKey: .created_at)
        try container.encodeIfPresent(deleted_at, forKey: .deleted_at)
        try container.encodeIfPresent(author_name, forKey: .author_name)
        try container.encodeIfPresent(author_avatar, forKey: .author_avatar)
        try container.encodeIfPresent(reply_to_user_name, forKey: .reply_to_user_name)
        try container.encode(is_liked, forKey: .is_liked)
        try container.encodeIfPresent(replies, forKey: .replies)
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
