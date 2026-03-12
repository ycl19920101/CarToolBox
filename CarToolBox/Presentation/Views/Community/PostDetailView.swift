//
//  PostDetailView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

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

    var body: some View {
        VStack(spacing: 8) {
            ForEach(media) { item in
                if item.type == "image" {
                    AsyncImage(url: URL(string: item.url)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .frame(height: 200)
                    }
                    .cornerRadius(8)
                } else if item.type == "video" {
                    ZStack {
                        Color.black
                            .frame(height: 200)
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
