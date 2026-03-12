//
//  ImageCache.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import UIKit
import Combine

class ImageCache: ObservableObject {
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

@MainActor
class ImageCacheViewModel: ObservableObject {
    @Published var imageCache = ImageCache()

    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString

        if let cachedImage = imageCache.getImage(forKey: cacheKey) {
            return cachedImage
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidImageData
        }

        imageCache.setImage(image, forKey: cacheKey)
        return image
    }
}

enum ImageError: Error {
    case invalidImageData
}