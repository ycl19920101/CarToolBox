//
//  DataCache.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation

class DataCache {
    private let cache = NSCache<NSString, NSData>()

    init() {
        cache.countLimit = 100
    }

    func set<T: Codable>(_ data: T, forKey key: String) {
        do {
            let jsonData = try JSONEncoder().encode(data)
            cache.setObject(jsonData as NSData, forKey: key as NSString)
        } catch {
            print("Failed to encode data for cache: \(error)")
        }
    }

    func get<T: Codable>(forKey key: String, type: T.Type) -> T? {
        guard let data = cache.object(forKey: key as NSString) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data as Data)
        } catch {
            print("Failed to decode data from cache: \(error)")
            return nil
        }
    }

    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}