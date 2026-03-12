//
//  CoreDataManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import CoreData
import Combine

class VehicleRepository: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext
    @Published var vehicles: [Vehicle] = []

    init() {
        // 简化初始化，暂时使用模拟数据
        vehicles = []
    }

    func addVehicle(name: String) {
        let vehicle = Vehicle(context: context)
        vehicle.id = UUID()
        vehicle.name = name
        vehicle.batteryLevel = 0
        vehicle.mileage = 0
        vehicle.isLocked = true
        vehicle.lastUpdateDate = Date()
        vehicles.append(vehicle)
        PersistenceController.shared.save()
    }

    func updateVehicle(_ vehicle: Vehicle) {
        do {
            try context.save()
        } catch {
            print("Error updating vehicle: \(error)")
        }
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        context.delete(vehicle)
        do {
            try context.save()
        } catch {
            print("Error deleting vehicle: \(error)")
        }
    }
}

class UserRepository: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext
    @Published var users: [User] = []

    init() {
        // 简化初始化，暂时使用模拟数据
        users = []
    }

    func createUser(username: String, email: String) {
        let user = User(context: context)
        user.id = UUID()
        user.username = username
        user.email = email
        user.createdAt = Date()
        users.append(user)
        PersistenceController.shared.save()
    }
}

class CommunityRepository: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext
    @Published var posts: [Post] = []

    init() {
        // 简化初始化，暂时使用模拟数据
        posts = []
    }

    func createPost(title: String, content: String, author: User) -> Post {
        let post = Post(context: context)
        post.id = UUID()
        post.title = title
        post.content = content
        post.createdAt = Date()
        post.likes = 0
        post.author = author
        posts.append(post)
        PersistenceController.shared.save()
        return post
    }

    func likePost(_ post: Post) {
        post.likes += 1
        PersistenceController.shared.save()
    }

    func addComment(to post: Post, content: String, author: User) {
        let comment = Comment(context: context)
        comment.id = UUID()
        comment.content = content
        comment.createdAt = Date()
        comment.author = author
        comment.post = post
        PersistenceController.shared.save()
    }
}