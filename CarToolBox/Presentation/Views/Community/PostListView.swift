//
//  PostListView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

struct PostListView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingCreatePost = false
    @State private var selectedVideoMedia: MediaDTO?

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
                                }
                            )
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
}

struct PostCellView: View {
    let post: PostDTO
    let onLike: () -> Void
    let onVideoTap: (MediaDTO) -> Void

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
                MediaPreviewView(media: post.media, onVideoTap: onVideoTap)
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
            SingleMediaView(media: media[0])
        case .singleVideo:
            VideoPreviewCell(media: media[0], onTap: { onVideoTap?(media[0]) })
        case .twoImages:
            TwoMediaView(media: Array(media.prefix(2)), onVideoTap: onVideoTap)
        case .threeImages:
            ThreeMediaView(media: Array(media.prefix(3)), onVideoTap: onVideoTap)
        case .fourImages:
            FourMediaView(media: Array(media.prefix(4)), onVideoTap: onVideoTap)
        case .manyImages(let remaining):
            ManyMediaView(media: Array(media.prefix(4)), remainingCount: remaining, onVideoTap: onVideoTap)
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

// MARK: - Two Media View (horizontal split)

struct TwoMediaView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(media) { item in
                MediaCell(item: item, aspectRatio: 1, onVideoTap: onVideoTap)
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 32 - 4) / 2)
    }
}

// MARK: - Three Media View (1 large + 2 small)

struct ThreeMediaView: View {
    let media: [MediaDTO]
    var onVideoTap: ((MediaDTO) -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            // 左侧大图 (2/3 宽度)
            MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap)
                .frame(maxWidth: .infinity)

            // 右侧两张小图 (1/3 宽度)
            VStack(spacing: 4) {
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap)
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap)
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

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap)
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap)
            }
            HStack(spacing: 4) {
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap)
                MediaCell(item: media[3], aspectRatio: 1, onVideoTap: onVideoTap)
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

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                MediaCell(item: media[0], aspectRatio: 1, onVideoTap: onVideoTap)
                MediaCell(item: media[1], aspectRatio: 1, onVideoTap: onVideoTap)
            }
            HStack(spacing: 4) {
                MediaCell(item: media[2], aspectRatio: 1, onVideoTap: onVideoTap)
                ZStack {
                    MediaCell(item: media[3], aspectRatio: 1, onVideoTap: onVideoTap)
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
            }
        }
    }
}

#Preview {
    NavigationView {
        PostListView()
    }
}
