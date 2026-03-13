//
//  CommunityViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import Combine

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [PostDTO] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMorePosts: Bool = false
    @Published var selectedPost: PostDTO?

    @Published var currentPage: Int = 1
    private let pageSize: Int = 20

    private var communityService: CommunityService
    private var notificationObserver: NSObjectProtocol?

    init() {
        communityService = CommunityService()
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .postDidCreate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.refreshPosts()
            }
        }
        Task {
            await fetchPosts()
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @MainActor
    func fetchPosts() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        communityService.getPostsPage(currentPage, pageSize: pageSize) { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let response = response,
                      let success = response["success"] as? Bool,
                      success,
                      let data = response["data"] as? [String: Any] {
                let postsData = data["posts"] as? [[String: Any]] ?? []

                // Debug: Log posts data
                Logger.community.debug("Fetched \(postsData.count) posts")
                if let firstPost = postsData.first {
                    Logger.community.debug("First post media: \(firstPost["media"] ?? "nil")")
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: postsData)
                    let newPosts = try JSONDecoder().decode([PostDTO].self, from: jsonData)

                    // Debug: Log decoded posts media count
                    Logger.community.debug("Decoded \(newPosts.count) posts")
                    if let firstPost = newPosts.first {
                        Logger.community.debug("First decoded post media count: \(firstPost.media.count)")
                        if let firstMedia = firstPost.media.first {
                            Logger.community.debug("First media URL: \(firstMedia.url)")
                        }
                    }
                    if self.currentPage == 1 {
                        self.posts = newPosts
                    } else {
                        self.posts.append(contentsOf: newPosts)
                    }
                    self.hasMorePosts = data["has_more"] as? Bool ?? false
                    self.currentPage += 1
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }

            self.isLoading = false
        }
    }

    func refreshPosts() async {
        currentPage = 1
        await fetchPosts()
    }

    func likePost(_ post: PostDTO) {
        Task { [weak self] in
            guard let self = self else { return }

            self.communityService.toggleLike(withTargetType: "post", targetId: post.id) { response, error in

                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success,
                          let data = response["data"] as? [String: Any] {
                    let likeCount = data["like_count"] as? Int ?? 0
                    let liked = data["liked"] as? Bool ?? false
                    if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                        self.posts[index].like_count = likeCount
                        self.posts[index].is_liked = liked
                    }
                }
            }
        }
    }

    func createPost(title: String, content: String, media: [[String: Any]]? = nil) async {
        guard !title.isEmpty && !content.isEmpty else { return }

        isLoading = true

        communityService.createPost(withTitle: title, content: content, media: media) { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let response = response,
                      let success = response["success"] as? Bool,
                      success,
                      let data = response["data"] as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let post = try JSONDecoder().decode(PostDTO.self, from: jsonData)
                    self.posts.insert(post, at: 0)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }

            self.isLoading = false
        }
    }

    func deletePost(_ post: PostDTO) async {
        communityService.deletePost(post.id) { [weak self] response, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = error.localizedDescription
            } else if let response = response,
                      let success = response["success"] as? Bool,
                      success {
                self.posts.removeAll { $0.id == post.id }
            }
        }
    }
}
