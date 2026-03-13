//
//  PostDetailView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import AVKit

struct PostDetailView: View {
    let post: PostDTO
    @StateObject private var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(post: PostDTO) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 用户信息
                    HStack {
                        if let avatarUrl = post.author_avatar {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        Text(post.author_name ?? "匿名")
                            .fontWeight(.bold)
                        Spacer()
                        Text(post.createdAtDate?.formatted() ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()

                    // 帖子标题
                    Text(post.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // 帖子内容
                    Text(post.content)
                        .font(.body)
                        .padding()

                    // 媒体展示
                    if !post.media.isEmpty {
                        MediaGridView(media: post.media)
                            .padding(.horizontal)
                    }

                    // 点赞和分享
                    HStack(spacing: 30) {
                        Button(action: {
                            viewModel.toggleLike()
                        }) {
                            HStack {
                                Image(systemName: viewModel.post?.is_liked == true ? "heart.fill" : "heart")
                                    .foregroundColor(.red)
                                Text("\(viewModel.post?.like_count ?? post.like_count)")
                            }
                        }

                        Spacer()

                        HStack {
                            Image(systemName: "message")
                            Text("\(viewModel.post?.comment_count ?? post.comment_count)")
                        }

                        Spacer()

                        Button(action: {
                            // TODO: 分享功能
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享")
                            }
                        }
                    }
                    .padding()

                    Divider()

                    // 评论区
                    VStack(alignment: .leading) {
                        Text("评论 (\(viewModel.comments.count))")
                            .font(.headline)
                            .padding()

                        ForEach(viewModel.comments) { comment in
                            CommentCellView(comment: comment)
                        }
                    }

                    // 评论输入框
                    VStack {
                        HStack {
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
                    }
                }
            }
            .navigationTitle("帖子详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommentCellView: View {
    let comment: CommentDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let avatarUrl = comment.author_avatar {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }

                Text(comment.author_name ?? "匿名")
                    .fontWeight(.bold)
                    .font(.subheadline)

                Spacer()

                Text(comment.createdAtDate?.formatted() ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(comment.content)
                .font(.body)
                .padding(.leading, 40)

            if let replies = comment.replies, !replies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(replies.prefix(3)) { reply in
                        HStack(alignment: .top, spacing: 4) {
                            Text(reply.author_name ?? "匿名")
                                .fontWeight(.bold)
                                .font(.caption)
                            Text(reply.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 40)
                    }

                    if replies.count > 3 {
                        Button("查看更多 \(replies.count - 3) 条回复") {
                            // TODO: 展开更多回复
                        }
                        .font(.caption)
                        .padding(.leading, 40)
                    }
                }
            }

            Divider()
        }
        .padding(.horizontal)
    }
}

struct MediaGridView: View {
    let media: [MediaDTO]
    @State private var selectedVideoURL: VideoURLWrapper?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(media) { item in
                if item.type == "image" {
                    AsyncImage(url: URL(string: item.fullURL)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .frame(height: 200)
                    }
                    .cornerRadius(8)
                } else if item.type == "video" {
                    VideoThumbnailCell(thumbnailURL: item.fullThumbnailURL, videoURL: item.fullURL, duration: item.duration)
                        .onTapGesture {
                            Logger.community.debug("Video tapped, fullURL: \(item.fullURL)")
                            if let url = URL(string: item.fullURL) {
                                Logger.community.debug("Video URL created: \(url.absoluteString)")
                                selectedVideoURL = VideoURLWrapper(url: url)
                            } else {
                                Logger.community.error("Failed to create URL from: \(item.fullURL)")
                            }
                        }
                        .cornerRadius(8)
                }
            }
        }
        .fullScreenCover(item: $selectedVideoURL) { wrapper in
            VideoPlayerView(videoURL: wrapper.url)
        }
    }
}

// MARK: - Video URL Wrapper for Identifiable

struct VideoURLWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Video Thumbnail Cell

struct VideoThumbnailCell: View {
    let thumbnailURL: String?
    let videoURL: String
    let duration: Double?
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnailURL = thumbnailURL,
               let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
            } else {
                Color.black
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if let duration = duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding(8)
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .frame(height: 200)
        .clipped()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("视频加载失败")
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
            } else if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else if isLoading {
                ProgressView()
                    .foregroundColor(.white)
            }

            // 关闭按钮 - 始终显示在顶部
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        player?.pause()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            loadAndPlayVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadAndPlayVideo() {
        isLoading = true
        errorMessage = nil

        Logger.community.debug("Loading video from URL: \(videoURL.absoluteString)")

        // 验证 URL
        guard videoURL.scheme == "http" || videoURL.scheme == "https" else {
            errorMessage = "无效的视频URL"
            isLoading = false
            return
        }

        // 创建 player
        let newPlayer = AVPlayer(url: videoURL)
        player = newPlayer

        // 监听播放状态
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            errorMessage = "视频播放失败"
            isLoading = false
        }

        // 延迟一点播放，确保 UI 已准备好
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isLoading = false
            newPlayer.play()
        }
    }
}

#Preview {
    PostDetailView(post: PostDTO(
        id: "1",
        user_id: "1",
        title: "测试帖子",
        content: "这是测试内容",
        status: "published",
        view_count: 100,
        like_count: 50,
        comment_count: 10,
        created_at: "2026-03-11T00:00:00Z",
        updated_at: nil,
        deleted_at: nil,
        author_name: "测试用户",
        author_avatar: nil,
        is_liked: false,
        media: []
    ))
}
