//
//  VideoPostDetailView.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI
import AVKit

struct VideoPostDetailView: View {
    let post: PostDTO
    let videoURL: URL

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostDetailViewModel
    @ObservedObject private var playbackManager = VideoPlaybackManager.shared
    @State private var showShareSheet = false
    @State private var showComments = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    init(post: PostDTO, videoURL: URL) {
        self.post = post
        self.videoURL = videoURL
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Video area (70% of screen)
                VStack(spacing: 0) {
                    // Video player area
                    ZStack {
                        if let player = playbackManager.currentPlayer,
                           playbackManager.currentPlayingPostId == post.id {
                            VideoPlayer(player: player)
                                .disabled(true)
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.7)
                                .clipped()
                        } else if isLoading {
                            ProgressView()
                                .foregroundColor(.white)
                        } else if let error = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("视频加载失败")
                                    .foregroundColor(.white)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }

                        // Overlay controls
                        VideoPlayerOverlayView(
                            playbackManager: playbackManager,
                            onBack: {
                                dismiss()
                            },
                            onMore: {
                                showShareSheet = true
                            }
                        )
                        .frame(height: geometry.size.height * 0.7)

                        // Right side action buttons
                        HStack {
                            Spacer()
                            rightActionButtons
                                .padding(.trailing, 12)
                                .padding(.bottom, 60)
                        }
                        .frame(height: geometry.size.height * 0.7)
                    }

                    // Bottom content panel (30% of screen)
                    VideoPostContentPanel(
                        post: viewModel.post ?? post,
                        onCommentTap: {
                            showComments = true
                        }
                    )
                    .frame(height: geometry.size.height * 0.3)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .onAppear {
            loadAndPlayVideo()
        }
        .onDisappear {
            playbackManager.stopCurrentVideo()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                post.title,
                post.content,
                URL(string: "https://cartoolbox.app/posts/\(post.id)")!
            ])
        }
        .sheet(isPresented: $showComments) {
            CommentsSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Right Action Buttons

    private var rightActionButtons: some View {
        VStack(spacing: 24) {
            // Like button
            ActionButton(
                icon: viewModel.post?.is_liked == true ? "heart.fill" : "heart",
                count: viewModel.post?.like_count ?? post.like_count,
                color: viewModel.post?.is_liked == true ? .red : .white
            ) {
                viewModel.toggleLike()
            }

            // Comment button
            ActionButton(
                icon: "bubble.right",
                count: viewModel.post?.comment_count ?? post.comment_count,
                color: .white
            ) {
                showComments = true
            }

            // Share button
            ActionButton(
                icon: "square.and.arrow.up",
                count: nil,
                color: .white
            ) {
                showShareSheet = true
            }
        }
    }

    // MARK: - Video Loading

    private func loadAndPlayVideo() {
        isLoading = true
        errorMessage = nil

        Logger.community.debug("Loading video from URL: \(videoURL.absoluteString)")

        // Validate URL
        guard videoURL.scheme == "http" || videoURL.scheme == "https" else {
            errorMessage = "无效的视频URL"
            isLoading = false
            return
        }

        // Start playback via manager
        playbackManager.playVideo(postId: post.id, url: videoURL)

        // Observe for errors
        if let player = playbackManager.currentPlayer {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                errorMessage = "视频播放失败"
                isLoading = false
            }
        }

        // Small delay to ensure player is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let count: Int?
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Comments Sheet View

struct CommentsSheetView: View {
    @ObservedObject var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.comments) { comment in
                        CommentCellView(comment: comment)
                    }

                    if viewModel.hasMoreComments {
                        ProgressView()
                            .onAppear {
                                Task {
                                    await viewModel.loadComments()
                                }
                            }
                    }

                    if viewModel.comments.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.right")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("暂无评论")
                                .foregroundColor(.gray)
                            Text("快来发表第一条评论吧")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("评论 (\(viewModel.post?.comment_count ?? 0))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                commentInputBar
            }
        }
    }

    private var commentInputBar: some View {
        HStack(spacing: 12) {
            TextField("写下你的评论...", text: $viewModel.commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("发送") {
                Task {
                    await viewModel.createComment(content: viewModel.commentText)
                }
            }
            .disabled(viewModel.commentText.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    VideoPostDetailView(
        post: PostDTO(
            id: "1",
            user_id: "1",
            title: "测试视频帖子",
            content: "这是视频帖子的内容描述，可以很长。",
            view_count: 100,
            like_count: 50,
            comment_count: 10,
            created_at: ISO8601DateFormatter().string(from: Date()),
            author_name: "测试用户",
            is_liked: false,
            media: [
                MediaDTO(
                    type: "video",
                    url: "https://example.com/video.mp4",
                    duration: 60
                )
            ]
        ),
        videoURL: URL(string: "https://example.com/video.mp4")!
    )
}
