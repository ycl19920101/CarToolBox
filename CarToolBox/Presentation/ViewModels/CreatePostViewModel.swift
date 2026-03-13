//
//  CreatePostViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/11.
//

import Foundation
import UIKit
import Combine

extension Notification.Name {
    static let postDidCreate = Notification.Name("postDidCreate")
}

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
        Logger.community.debug("Added image, total: \(selectedImages.count)")
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        Logger.community.debug("Removed image at index \(index), remaining: \(selectedImages.count)")
        // Also remove from mediaItems if exists
        if mediaItems.count > index {
            mediaItems.remove(at: index)
        }
    }

    func setVideoURL(_ url: URL) {
        selectedVideoURL = url
        Logger.community.debug("Video URL set: \(url.path)")
    }

    func removeVideo() {
        selectedVideoURL = nil
        Logger.community.debug("Video removed")
    }

    func submitPost() async -> Bool {
        guard canSubmit else {
            Logger.community.error("Cannot submit: title or content is empty")
            return false
        }

        Logger.community.separator()
        Logger.community.info("Starting post submission...")
        Logger.community.debug("Title: \(title)")
        Logger.community.debug("Content: \(content)")
        Logger.community.debug("Images: \(selectedImages.count)")
        Logger.community.debug("Video: \(selectedVideoURL?.path ?? "none")")
        Logger.community.separator()

        isSubmitting = true
        errorMessage = nil

        // Upload media first
        var uploadedMedia: [MediaUpload] = []

        // Upload images
        for (index, image) in selectedImages.enumerated() {
            Logger.community.debug("Uploading image \(index + 1)/\(selectedImages.count)...")
            if let media = await uploadImage(image) {
                uploadedMedia.append(media)
                Logger.community.info("✅ Image \(index + 1) uploaded: \(media.url)")
            } else {
                Logger.community.error("❌ Image \(index + 1) upload failed")
            }
        }

        // Upload video if selected
        if let videoURL = selectedVideoURL {
            Logger.community.debug("Uploading video: \(videoURL.path)")
            if let media = await uploadVideo(videoURL) {
                uploadedMedia.append(media)
                Logger.community.info("✅ Video uploaded: \(media.url)")
            } else {
                Logger.community.error("❌ Video upload failed")
            }
        }

        Logger.community.debug("Creating post with \(uploadedMedia.count) media items...")

        // Prepare media data
        let mediaData = uploadedMedia.isEmpty ? nil : uploadedMedia.map { [
            "type": $0.type,
            "url": $0.url,
            "thumbnail_url": $0.thumbnail_url as Any,
            "width": $0.width as Any,
            "height": $0.height as Any,
            "size": $0.size as Any,
            "duration": $0.duration as Any
        ].compactMapValues { $0 } }

        // Debug: Log media data being sent
        if let mediaData = mediaData {
            Logger.community.debug("Sending media data: \(mediaData)")
        }

        // Create the post
        return await withCheckedContinuation { continuation in
            communityService.createPost(withTitle: title, content: content, media: mediaData) { [weak self] response, error in
                guard let self = self else {
                    Logger.community.error("Self is nil")
                    continuation.resume(returning: false)
                    return
                }

                if let error = error {
                    Logger.community.error("Create post error: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        Logger.community.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                    self.errorMessage = error.localizedDescription
                    continuation.resume(returning: false)
                } else if let response = response,
                          let success = response["success"] as? Bool,
                          success {
                    Logger.community.info("✅ Post created successfully!")
                    Logger.community.debug("Response: \(response)")
                    self.showSuccess = true
                    NotificationCenter.default.post(name: .postDidCreate, object: nil)
                    continuation.resume(returning: true)
                } else {
                    Logger.community.error("Create post failed - unexpected response")
                    Logger.community.debug("Response: \(String(describing: response))")
                    self.errorMessage = "Failed to create post"
                    continuation.resume(returning: false)
                }

                self.isSubmitting = false
            }
        }
    }

    private func uploadImage(_ image: UIImage) async -> MediaUpload? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            Logger.community.error("Failed to convert image to JPEG data")
            return nil
        }

        Logger.community.debug("Image data size: \(imageData.count) bytes")

        return await withCheckedContinuation { continuation in
            communityService.uploadImage(with: imageData) { response, error in
                if let error = error {
                    Logger.community.error("Upload image error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                // Debug: Log full response
                Logger.community.debug("Upload image response: \(String(describing: response))")

                if let response = response,
                   let success = response["success"] as? Bool,
                   success {
                    // Try to parse data from response["data"] first, then try response directly
                    var mediaData: [String: Any]?
                    if let responseData = response["data"] as? [String: Any] {
                        mediaData = responseData
                    } else {
                        // Maybe the response itself contains the media info (convert from NSDictionary)
                        mediaData = Dictionary(uniqueKeysWithValues: response.map { (key: AnyHashable, value: Any) in
                            (String(describing: key), value)
                        })
                    }

                    if let data = mediaData {
                        Logger.community.debug("Upload image data: \(data)")
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
                        Logger.community.error("Upload image: no data in response")
                        continuation.resume(returning: nil)
                    }
                } else {
                    Logger.community.error("Upload image unexpected response: \(String(describing: response))")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func uploadVideo(_ videoURL: URL) async -> MediaUpload? {
        Logger.community.debug("Starting video upload from: \(videoURL.path)")

        return await withCheckedContinuation { continuation in
            communityService.uploadVideo(with: videoURL) { response, error in
                if let error = error {
                    Logger.community.error("Upload video error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                if let response = response,
                   let success = response["success"] as? Bool,
                   success,
                   let data = response["data"] as? [String: Any] {
                    let media = MediaUpload(
                        type: data["type"] as? String ?? "video",
                        url: data["url"] as? String ?? "",
                        thumbnail_url: data["thumbnail_url"] as? String,
                        width: data["width"] as? Int,
                        height: data["height"] as? Int,
                        size: data["size"] as? Int,
                        duration: data["duration"] as? Double
                    )
                    continuation.resume(returning: media)
                } else {
                    Logger.community.error("Upload video unexpected response: \(String(describing: response))")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
