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
    @Published var isLoading: Bool = false
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
            await loadPostDetail()
            await loadComments()
        }
    }

    convenience init(post: PostDTO) {
        self.init(postId: post.id)
        self.post = post
    }

    @MainActor
    func loadPostDetail() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        communityService.getPostDetail(postId) { [weak self] response, error in
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

            self.isLoading = false
        }
    }

    @MainActor
    func loadComments() async {
        guard !isLoading else { return }

        isLoading = true

        communityService.getCommentsForPost(postId, page: currentPage, pageSize: pageSize) { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let response = response,
                      let success = response["success"] as? Bool,
                      success,
                      let data = response["data"] as? [String: Any],
                      let commentsData = data["comments"] as? [[String: Any]] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: commentsData)
                    let newComments = try JSONDecoder().decode([CommentDTO].self, from: jsonData)
                    self.comments.append(contentsOf: newComments)
                    self.hasMoreComments = data["has_more"] as? Bool ?? false
                    self.currentPage += 1
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }

            self.isLoading = false
        }
    }

    func toggleLike() {
        Task { [weak self] in
            guard let self = self else { return }

            self.communityService.toggleLike(withTargetType: "post", targetId: self.postId) { response, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success,
                          let data = response["data"] as? [String: Any] {
                    let liked = data["liked"] as? Bool ?? false
                    let likeCount = data["like_count"] as? Int ?? 0
                    self.post?.like_count = likeCount
                    self.post?.is_liked = liked
                }
            }
        }
    }

    func createComment(content: String, parentId: String? = nil) async {
        guard !content.isEmpty else { return }

        isLoading = true

        communityService.createComment(forPost: postId, content: content, parentId: parentId, replyToUserId: nil) { [weak self] response, error in
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

            self.isLoading = false
        }
    }

    func deleteComment(_ comment: CommentDTO) {
        Task { [weak self] in
            guard let self = self else { return }

            self.communityService.deleteComment(comment.id) { response, error in
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
