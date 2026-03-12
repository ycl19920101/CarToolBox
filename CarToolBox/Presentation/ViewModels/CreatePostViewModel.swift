//
//  CreatePostViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

import Foundation
import UIKit
import Combine

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var selectedVideoURL: URL?
    @Published var mediaItems: [MediaUpload] = []

    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false

    private let communityService: CommunityService

    init() {
        communityService = CommunityService()
    }

    var canSubmit: Bool {
        !title.isEmpty && !content.isEmpty
    }

    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        // Also remove from mediaItems if exists
        if mediaItems.count > index {
            mediaItems.remove(at: index)
        }
    }

    func submitPost() async -> Bool {
        guard canSubmit else { return false }

        isSubmitting = true
        errorMessage = nil

        // Upload images first
        var uploadedMedia: [MediaUpload] = []

        for image in selectedImages {
            if let media = await uploadImage(image) {
                uploadedMedia.append(media)
            }
        }

        // Create the post
        return await withCheckedContinuation { continuation in
            communityService.createPost(withTitle: title, content: content, media: uploadedMedia.isEmpty ? nil : uploadedMedia.map { [
                "type": $0.type,
                "url": $0.url,
                "thumbnail_url": $0.thumbnail_url as Any,
                "width": $0.width as Any,
                "height": $0.height as Any,
                "size": $0.size as Any,
                "duration": $0.duration as Any
            ].compactMapValues { $0 } }) { [weak self] response, error in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    continuation.resume(returning: false)
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success {
                    self.showSuccess = true
                    continuation.resume(returning: true)
                } else {
                    self.errorMessage = "Failed to create post"
                    continuation.resume(returning: false)
                }

                self.isSubmitting = false
            }
        }
    }

    private func uploadImage(_ image: UIImage) async -> MediaUpload? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            communityService.uploadImage(with: imageData) { response, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                if let response = response,
                   let success = response["success"] as? Bool,
                   success,
                   let data = response["data"] as? [String: Any] {
                    let media = MediaUpload(
                        type: data["type"] as? String ?? "image",
                        url: data["url"] as? String ?? "",
                        thumbnail_url: data["thumbnail_url"] as? String,
                        width: data["width"] as? Int,
                        height: data["height"] as? Int,
                        size: data["size"] as? Int,
                        duration: data["duration"] as? Double
                    )
                    continuation.resume(returning: media)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
