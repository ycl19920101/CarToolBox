//
//  PostDetailViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

import Foundation
import Combine

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: PostDTO?
    @Published var comments: [CommentDTO] = []
    @Published var isLoadingPost: Bool = false
    @Published var isLoadingComments: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreComments: Bool = false
    @Published var commentText: String = ""

    private let communityService: CommunityService
    private let postId: String
    private var currentPage: Int = 1
    private let pageSize: Int = 20

    init(postId: String) {
        self.postId = postId
        self.communityService = CommunityService()
        Task {
            async let postDetail: Void = loadPostDetail()
            async let comments: Void = loadComments()
            _ = await (postDetail, comments)
        }
    }

    convenience init(post: PostDTO) {
        self.init(postId: post.id)
        self.post = post
    }

    @MainActor
    func loadPostDetail() async {
        guard !isLoadingPost else { return }

        isLoadingPost = true
        errorMessage = nil

        communityService.getPostDetail(postId) { [weak self] response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success,
                          let data = response["data"] as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        self.post = try JSONDecoder().decode(PostDTO.self, from: jsonData)
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                }

                self.isLoadingPost = false
            }
        }
    }

    @MainActor
    func loadComments() async {
        guard !isLoadingComments else { return }

        isLoadingComments = true

        communityService.getCommentsForPost(postId, page: currentPage, pageSize: pageSize) { [weak self] response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    Logger.community.error("Load comments error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                } else if let response = response {
                    Logger.community.debug("Load comments response: \(response)")

                    // 尝试解析评论数据
                    var commentsData: [[String: Any]]?
                    var hasMore = false

                    // 格式1: { "success": true, "data": { "comments": [...] } }
                    if let success = response["success"] as? Bool,
                       success,
                       let data = response["data"] as? [String: Any] {
                        commentsData = data["comments"] as? [[String: Any]] ?? data["items"] as? [[String: Any]]
                        hasMore = data["has_more"] as? Bool ?? data["hasNext"] as? Bool ?? false
                    }
                    // 格式2: { "comments": [...] }
                    else if let directComments = response["comments"] as? [[String: Any]] {
                        commentsData = directComments
                        hasMore = response["has_more"] as? Bool ?? response["hasNext"] as? Bool ?? false
                    }

                    if let commentsData = commentsData {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: commentsData)
                            let newComments = try JSONDecoder().decode([CommentDTO].self, from: jsonData)
                            Logger.community.debug("Decoded \(newComments.count) comments")
                            self.comments.append(contentsOf: newComments)
                            self.hasMoreComments = hasMore
                            self.currentPage += 1
                        } catch {
                            Logger.community.error("Decode comments error: \(error.localizedDescription)")
                            self.errorMessage = error.localizedDescription
                        }
                    } else {
                        Logger.community.warning("No comments data found in response")
                    }
                }

                self.isLoadingComments = false
            }
        }
    }

    func toggleLike() {
        communityService.toggleLike(withTargetType: "post", targetId: postId) { [weak self] response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success,
                          let data = response["data"] as? [String: Any] {
                    let liked = data["liked"] as? Bool ?? false
                    let likeCount = data["likeCount"] as? Int ?? data["like_count"] as? Int ?? 0
                    self.post?.like_count = likeCount
                    self.post?.is_liked = liked
                }
            }
        }
    }

    func createComment(content: String, parentId: String? = nil) async {
        guard !content.isEmpty else { return }

        isLoadingComments = true

        communityService.createComment(forPost: postId, content: content, parentId: parentId, replyToUserId: nil) { [weak self] response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success,
                          let data = response["data"] as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let comment = try JSONDecoder().decode(CommentDTO.self, from: jsonData)
                        self.comments.append(comment)
                        self.post?.comment_count += 1
                        self.commentText = ""
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                }

                self.isLoadingComments = false
            }
        }
    }

    func deleteComment(_ comment: CommentDTO) {
        communityService.deleteComment(comment.id) { [weak self] response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success {
                    self.comments.removeAll { $0.id == comment.id }
                    self.post?.comment_count = max(0, (self.post?.comment_count ?? 1) - 1)
                }
            }
        }
    }
}
