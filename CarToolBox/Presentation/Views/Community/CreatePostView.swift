//
//  CreatePostView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var isShowingVideoPicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("标题")) {
                    TextField("请输入标题", text: $viewModel.title)
                }

                Section(header: Text("内容")) {
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 150)
                }

                Section(header: Text("图片（可选，最多9张）")) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 9, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("选择图片")
                        }
                    }
                    .disabled(viewModel.selectedVideoURL != nil)
                    .onChange(of: selectedItems) { newItems in
                        Task {
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    viewModel.addImage(image)
                                }
                            }
                        }
                    }

                    if !viewModel.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: viewModel.selectedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .clipped()

                                        Button(action: {
                                            viewModel.removeImage(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(.white))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("视频（可选，仅支持1个）")) {
                    PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                        HStack {
                            Image(systemName: "video")
                            Text("选择视频")
                        }
                    }
                    .disabled(!viewModel.selectedImages.isEmpty)
                    .onChange(of: selectedVideoItem) { newItem in
                        Task {
                            if let newItem = newItem {
                                if let videoTransferable = try? await newItem.loadTransferable(type: VideoTransferable.self) {
                                    viewModel.setVideoURL(videoTransferable.url)
                                }
                            }
                        }
                    }

                    if let videoURL = viewModel.selectedVideoURL {
                        ZStack(alignment: .topTrailing) {
                            VideoThumbnailView(videoURL: videoURL)
                                .frame(height: 150)
                                .cornerRadius(8)

                            Button(action: {
                                viewModel.removeVideo()
                                selectedVideoItem = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Circle().fill(.white))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }
                }
            }
            .navigationTitle("发布动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") {
                        Task {
                            let success = await viewModel.submitPost()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("发布中...")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
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
}

#Preview {
    CreatePostView()
}

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "video_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Video Thumbnail View

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
            }

            Image(systemName: "play.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        Task {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            do {
                let cgImage = try await imageGenerator.image(at: .zero).image
                thumbnail = UIImage(cgImage: cgImage)
            } catch {
                Logger.community.error("Failed to generate thumbnail: \(error)")
            }
        }
    }
}

import AVFoundation
