//
//  UserManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import Combine
import CoreData
import SwiftUI

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false

    private let userRepository = UserRepository()
    private let keychainManager = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Shared auth ViewModel for integration
    static let sharedAuthViewModel = AuthViewModel()

    init() {
        loadCurrentUser()
        observeAuthChanges()
    }

    private func loadCurrentUser() {
        // Check if user is already logged in via AuthViewModel
        if UserManager.sharedAuthViewModel.isLoggedIn {
            self.isLoggedIn = true
            self.isLoading = false

            // Create or update Core Data user from AuthViewModel
            syncUserFromAuth()
        } else {
            // Try to load from Core Data as fallback
            loadFromCoreData()
        }
    }

    private func loadFromCoreData() {
        let context = PersistenceController.shared.container.viewContext

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        do {
            let users = try context.fetch(request)
            if let user = users.first {
                self.currentUser = user
                self.isLoggedIn = false // Not logged in, just has cached data
            }
        } catch {
            Logger.auth.error("Error loading user from Core Data: \(error)")
        }

        self.isLoading = false
    }

    private func observeAuthChanges() {
        // Observe auth state changes from AuthViewModel
        UserManager.sharedAuthViewModel.$authState
            .removeDuplicates()
            .sink { [weak self] authState in
                guard let self = self else { return }

                switch authState {
                case .authenticated:
                    self.isLoggedIn = true
                    self.syncUserFromAuth()
                case .unauthenticated:
                    self.isLoggedIn = false
                    // Keep user data but clear login state
                case .idle, .loading:
                    break
                }
            }
            .store(in: &cancellables)

        // Observe user data changes
        UserManager.sharedAuthViewModel.$currentUser
            .dropFirst() // Skip initial value
            .sink { [weak self] userModel in
                self?.syncUserFromAuth()
            }
            .store(in: &cancellables)
    }

    private func syncUserFromAuth() {
        guard UserManager.sharedAuthViewModel.isLoggedIn else { return }

        let userModel = UserManager.sharedAuthViewModel.currentUser
        let context = PersistenceController.shared.container.viewContext

        // Find existing user by ID
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userModel.id)
        request.fetchLimit = 1

        do {
            let existingUsers = try context.fetch(request)

            if let existingUser = existingUsers.first {
                // Update existing user
                existingUser.username = userModel.username
                existingUser.email = userModel.email
                existingUser.createdAt = userModel.createdAt
                try context.save()
                self.currentUser = existingUser
            } else {
                // Create new user
                let newUser = User(context: context)
                newUser.id = UUID(uuidString: userModel.id) ?? UUID()
                newUser.username = userModel.username
                newUser.email = userModel.email
                newUser.createdAt = userModel.createdAt
                try context.save()
                self.currentUser = newUser
            }
        } catch {
            Logger.auth.error("Error syncing user from AuthViewModel: \(error)")
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Use AuthViewModel for login
        let authViewModel = UserManager.sharedAuthViewModel
        authViewModel.loginIdentifier = username
        authViewModel.loginPassword = password

        // Wait for login to complete (in real app, use async/await properly)
        // For now, we'll use the existing AuthViewModel implementation
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Create a simple timer-based check for demo purposes
            // In production, this should use proper async/await with callbacks
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if authViewModel.authState == AuthState.authenticated || authViewModel.errorMessage != nil {
                    timer.invalidate()

                    if let errorMessage = authViewModel.errorMessage {
                        // Error occurred
                        let error = NSError(
                            domain: "CarToolBox",
                            code: 2003,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }

    // MARK: - Logout

    func logout() {
        // Use AuthViewModel for logout
        UserManager.sharedAuthViewModel.logout()

        currentUser = nil
        isLoggedIn = false

        // Clear Core Data users
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
        } catch {
            Logger.auth.error("Error clearing users: \(error)")
        }
    }

    // MARK: - Profile Update

    func updateProfile(username: String, email: String) {
        guard let currentUser = currentUser else { return }

        currentUser.username = username
        currentUser.email = email

        let context = PersistenceController.shared.container.viewContext
        do {
            try context.save()
        } catch {
            Logger.auth.error("Error updating profile: \(error)")
        }

        // Also update AuthViewModel
        UserManager.sharedAuthViewModel.currentUser.username = username
        UserManager.sharedAuthViewModel.currentUser.email = email
    }

    // MARK: - Session Management

    var isSessionValid: Bool {
        return UserManager.sharedAuthViewModel.isLoggedIn
    }

    var refreshTokenIfNeeded: Bool {
        // Check if token is about to expire
        // In a real app, check expiration and refresh if needed
        return UserManager.sharedAuthViewModel.isLoggedIn
    }

    // MARK: - User Info

    var displayName: String {
        return currentUser?.username ?? UserManager.sharedAuthViewModel.currentUser.username
    }

    var displayEmail: String {
        return currentUser?.email ?? UserManager.sharedAuthViewModel.currentUser.email
    }

    var userId: String? {
        if let id = currentUser?.id?.uuidString {
            return id
        }
        return UserManager.sharedAuthViewModel.currentUser.id
    }

    // MARK: - State Binding

    /// Helper to bind auth state to UI
    var authStateBinding: Binding<Bool> {
        Binding(
            get: { self.isLoggedIn },
            set: { _ in }
        )
    }

    /// Show login view
    func showLogin() {
        // This would be implemented via navigation or sheet presentation
        // In a real app, use the app coordinator to show login
    }
}
