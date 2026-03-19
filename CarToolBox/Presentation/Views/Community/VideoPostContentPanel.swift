//
//  VideoPostContentPanel.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/17.
//

import SwiftUI

struct VideoPostContentPanel: View {
    let post: PostDTO
    let onCommentTap: () -> Void

    @State private var isTitleExpanded = false
    @State private var isContentExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack(spacing: 12) {
                // Avatar
                if let avatarUrl = post.author_avatar, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                // Author name
                Text(post.author_name ?? "匿名")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                // Time
                Text(DateParser.relativeTime(from: post.createdAtDate))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Title (expandable)
            if !post.title.isEmpty {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(isTitleExpanded ? nil : 1)
                    .onTapGesture {
                        withAnimation {
                            isTitleExpanded.toggle()
                        }
                    }
            }

            // Content (expandable)
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(isContentExpanded ? nil : 2)
                    .onTapGesture {
                        withAnimation {
                            isContentExpanded.toggle()
                        }
                    }
            }

            // Stats and comment button
            HStack(spacing: 16) {
                // Views
                Label("\(post.view_count)", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                // Likes
                Label("\(post.like_count)", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Comment button
                Button(action: onCommentTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("评论 (\(post.comment_count))")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            VideoPostContentPanel(
                post: PostDTO(
                    id: "1",
                    user_id: "1",
                    title: "这是一个很长的帖子标题用来测试折叠功能是否正常工作",
                    content: "这是帖子的详细内容，可以包含很多文字。点击可以展开查看完整内容。这是帖子的详细内容，可以包含很多文字。点击可以展开查看完整内容。这是帖子的详细内容，可以包含很多文字。点击可以展开查看完整内容。",
                    created_at: ISO8601DateFormatter().string(from: Date()),
                    author_name: "测试用户",
                    is_liked: false,
                    media: []
                ),
                onCommentTap: {}
            )
        }
    }
}
