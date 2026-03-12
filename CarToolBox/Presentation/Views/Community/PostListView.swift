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
                            PostCellView(post: post) {
                                viewModel.likePost(post)
                            }
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
                MediaPreviewView(media: post.media)
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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(media.prefix(4)) { item in
                    if item.type == "image" {
                        AsyncImage(url: URL(string: item.thumbnail_url ?? item.url)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    } else {
                        ZStack {
                            Color.gray.opacity(0.2)
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                            Image(systemName: "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        PostListView()
    }
}
