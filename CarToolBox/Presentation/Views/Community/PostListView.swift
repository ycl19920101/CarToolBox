//
//  PostListView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import AVKit

struct PostListView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var videoPlaybackManager = VideoPlaybackManager.shared
    @State private var isShowingCreatePost = false
    @State private var selectedVideoMedia: MediaDTO?
    @State private var selectedImageMedia: (images: [MediaDTO], initialIndex: Int)?
    @State private var viewFrames: [String: CGRect] = [:]

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("加载中...")
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("暂无帖子")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("下拉刷新或点击右上角发布第一个帖子")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostCellView(
                                post: post,
                                onLike: { viewModel.likePost(post) },
                                onVideoTap: { media in
                                    selectedVideoMedia = media
                                },
                                onImageTap: { media in
                                    handleImageTap(media: media, in: post)
                                },
                                isVideoPlaying: videoPlaybackManager.currentPlayingPostId == post.id
                            )
                            .trackFrame(id: post.id)
                            .onTapGesture {
                                viewModel.selectedPost = post
                            }
                        }

                        if viewModel.hasMorePosts {
                            ProgressView()
                                .onAppear {
                                    Task {
                                        await viewModel.fetchPosts()
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshPosts()
                }
                .onPreferenceChange(ViewFramePreferenceKey.self) { frames in
                    viewFrames = frames
                    updatePlayingVideo()
                }
            }
        }
        .navigationTitle("社区")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingCreatePost = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingCreatePost) {
            CreatePostView()
        }
        .sheet(item: $viewModel.selectedPost) { post in
            PostDetailView(post: post)
        }
        .fullScreenCover(item: $selectedVideoMedia) { media in
            if let url = URL(string: media.fullURL) {
                VideoPlayerView(videoURL: url)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImageMedia.map { ImageMediaWrapper(images: $0.images, initialIndex: $0.initialIndex) } },
            set: { selectedImageMedia = $0.map { ($0.images, $0.initialIndex) } }
        )) { wrapper in
            ImageViewerView(images: wrapper.images, initialIndex: wrapper.initialIndex)
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.fetchPosts()
            }
        }
        .alert("错误", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Video Auto-Play Logic

    private func updatePlayingVideo() {
        let screenHeight = UIScreen.main.bounds.height

        // Filter posts with video media
        let videoPosts = viewModel.posts.filter { post in
            post.media.contains { $0.type == "video" }
        }

        // Find the closest visible video post to screen center
        var closestVideoPostId: String?
        var minDistance: CGFloat = .infinity

        for post in videoPosts {
            guard let frame = viewFrames[post.id] else { continue }

            // Check if the post is visible on screen
            let visibleRange: ClosedRange<CGFloat> = -frame.height...screenHeight + frame.height
            guard visibleRange.contains(frame.midY) else { continue }

            let distance = VisibilityCalculator.distanceToScreenCenter(frame, screenHeight: screenHeight)
            if distance < minDistance {
                minDistance = distance
                closestVideoPostId = post.id
            }
        }

        // Play the closest video post
        if let postId = closestVideoPostId,
           let post = videoPosts.first(where: { $0.id == postId }),
           let videoMedia = post.media.first(where: { $0.type == "video" }),
           let url = URL(string: videoMedia.fullURL) {

            // Only start playing if not already playing this video
            if videoPlaybackManager.currentPlayingPostId != postId {
                videoPlaybackManager.playVideo(postId: postId, url: url)
            }
        } else {
            // No visible video posts, stop playback
            videoPlaybackManager.stopCurrentVideo()
        }
    }

    // MARK: - Image Tap Handler

    private func handleImageTap(media: MediaDTO, in post: PostDTO) {
        let images = post.media.filter { $0.type == "image" }
        guard !images.isEmpty else { return }

        if let index = images.firstIndex(where: { $0.id == media.id }) {
            selectedImageMedia = (images, index)
        } else {
            selectedImageMedia = (images, 0)
        }
    }
}

// MARK: - Image Media Wrapper

struct ImageMediaWrapper: Identifiable {
    let id = UUID()
    let images: [MediaDTO]
    let initialIndex: Int
}

struct PostCellView: View {
    let post: PostDTO
    let onLike: () -> Void
    let onVideoTap: (MediaDTO) -> Void
    var onImageTap: ((MediaDTO) -> Void)?
    var isVideoPlaying: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Text(post.title)
                .font(.headline)
                .padding(.bottom, 4)

            Text(post.content)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)

            // Media preview
            if !post.media.isEmpty {
                MediaPreviewView(
                    media: post.media,
                    onVideoTap: onVideoTap,
                    onImageTap: onImageTap,
                    isVideoPlaying: isVideoPlaying
                )
            }

            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack {
                        Image(systemName: post.is_liked ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                        Text("\(post.like_count)")
                    }
                }

                HStack {
                    Image(systemName: "message")
                    Text("\(post.comment_count)")
                }

                Spacer()

                HStack {
                    Image(systemName: "eye")
                    Text("\(post.view_count)")
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct MediaPreviewView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?
    var isVideoPlaying: Bool = false

    private var layoutType: MediaLayoutType {
        switch media.count {
        case 0:
            return .none
        case 1:
            return media[0].type == "video" ? .singleVideo : .singleImage
        case 2:
            return .twoImages
        case 3:
            return .threeImages
        case 4:
            return .fourImages
        default:
            return .manyImages(media.count - 4)
        }
    }

    var body: some View {
        switch layoutType {
        case .none:
            EmptyView()
        case .singleImage:
            SingleMediaView(media: media[0], onImageTap: onImageTap)
        case .singleVideo:
            AutoPlayingVideoCell(media: media[0], isPlaying: isVideoPlaying, onFullscreenTap: { onVideoTap?(media[0]) })
        case .twoImages:
            TwoMediaView(media: Array(media.prefix(2)), onVideoTap: onVideoTap, onImageTap: onImageTap)
        case .threeImages:
            ThreeMediaView(media: Array(media.prefix(3)), onVideoTap: onVideoTap, onImageTap: onImageTap)
        case .fourImages:
            FourMediaView(media: Array(media.prefix(4)), onVideoTap: onVideoTap, onImageTap: onImageTap)
        case .manyImages(let remaining):
            ManyMediaView(media: Array(media.prefix(4)), remainingCount: remaining, onVideoTap: onVideoTap, onImageTap: onImageTap)
        }
    }
}

// MARK: - Layout Type

enum MediaLayoutType {
    case none
    case singleImage
    case singleVideo
    case twoImages
    case threeImages
    case fourImages
    case manyImages(Int)
}

// MARK: - Single Media View (16:9)

struct SingleMediaView: View {
    let media: MediaDTO
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: media.fullThumbnailURL ?? media.fullURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
                    .overlay(ProgressView())
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
            .clipped()
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                onImageTap?(media)
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32) * 9 / 16)
    }
}

// MARK: - Video Preview Cell (16:9 with play button and duration)

struct VideoPreviewCell: View {
    let media: MediaDTO
    var onTap: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 缩略图背景
                AsyncImage(url: URL(string: media.fullThumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView())
                }

                // 播放按钮（白底蓝色三角形）
                Circle()
                    .fill(.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .offset(x: 2, y: 0)
                    }

                // 右下角时长标签
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let duration = media.duration {
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(8)
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
            .clipped()
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32) * 9 / 16)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Auto Playing Video Cell (for list auto-play)

struct AutoPlayingVideoCell: View {
    let media: MediaDTO
    let isPlaying: Bool
    var onFullscreenTap: (() -> Void)?

    @ObservedObject var playbackManager = VideoPlaybackManager.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPlaying, let player = playbackManager.currentPlayer {
                    // Show video player when playing
                    VideoPlayer(player: player)
                        .disabled(true) // Disable user interaction on the player
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                        .clipped()

                    // Mute indicator (top-left)
                    VStack {
                        HStack {
                            Image(systemName: "speaker.slash.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)

                    // Fullscreen button (bottom-right)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                onFullscreenTap?()
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(8)
                } else {
                    // Show thumbnail when not playing
                    AsyncImage(url: URL(string: media.fullThumbnailURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .overlay(ProgressView())
                    }

                    // Play button indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .offset(x: 2, y: 0)
                        }
                }

                // Duration label (bottom-right, always visible)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let duration = media.duration {
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(8)
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
            .clipped()
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap to fullscreen
                onFullscreenTap?()
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32) * 9 / 16)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Two Media View (horizontal split)

struct TwoMediaView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(media) { item in
                MediaCell(item: item, aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32 - 4) / 2)
    }
}

// MARK: - Three Media View (1 large + 2 small)

struct ThreeMediaView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            // 左侧大图 (2/3 宽度)
            MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                .frame(maxWidth: .infinity)

            // 右侧两张小图 (1/3 宽度)
            VStack(spacing: 4) {
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
            }
            .frame(width: (UIScreen.main.bounds.width - 32 - 8) / 3)
        }
        .frame(height: (UIScreen.main.bounds.width - 32 - 4) / 2)
    }
}

// MARK: - Four Media View (2x2 grid)

struct FourMediaView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
            }
            HStack(spacing: 4) {
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                MediaCell(item: media[3], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32 - 4))
    }
}

// MARK: - Many Media View (2x2 grid with +N overlay)

struct ManyMediaView: View {
    let media: [MediaDTO]
    let remainingCount: Int
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
            }
            HStack(spacing: 4) {
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                ZStack {
                    MediaCell(item: media[3], aspectRatio: 1, onVideoTap: onVideoTap, onImageTap: onImageTap)
                    // +N 遮罩
                    Color.black.opacity(0.5)
                    Text("+\(remainingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .cornerRadius(8)
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32 - 4))
    }
}

// MARK: - Media Cell

struct MediaCell: View {
    let item: MediaDTO
    var aspectRatio: CGFloat = 1
    var onVideoTap: ((MediaDTO) -> Void)?
    var onImageTap: ((MediaDTO) -> Void)?

    var body: some View {
        ZStack {
            if item.type == "image" {
                AsyncImage(url: URL(string: item.fullThumbnailURL ?? item.fullURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .overlay(ProgressView())
                }
            } else {
                // 视频缩略图
                AsyncImage(url: URL(string: item.fullThumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }

                // 小播放按钮
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .offset(x: 1, y: 0)
                    }
            }
        }
        .clipped()
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == "video" {
                onVideoTap?(item)
            } else {
                onImageTap?(item)
            }
        }
    }
}

#Preview {
    NavigationView {
        PostListView()
    }
}
