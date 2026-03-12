//
//  AuthResponse.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation
import Combine

// MARK: - API Response Wrapper

/// Generic API response wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
    let error: APIError?
}

/// Simple API response without data
struct SimpleResponse: Codable {
    let success: Bool
    let message: String
    let error: APIError?
}

// MARK: - Auth Response Data

/// Authentication response containing tokens and user info
struct AuthResponse: Codable {
    let user: UserDTO
    let tokens: TokenData
}

/// Token data from auth response
struct TokenData: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int

    var accessTokenExpirationDate: Date {
        return Date().addingTimeInterval(TimeInterval(expires_in))
    }
}

// MARK: - User Data Transfer Object

/// User data transfer object (without sensitive info)
struct UserDTO: Codable {
    let id: String
    let username: String
    let email: String?
    let phone: String?
    let avatar: String?
    let created_at: String?
    let updated_at: String?
    let last_login_at: String?

    var createdAtDate: Date? {
        return ISO8601DateFormatter().date(from: created_at ?? "")
    }

    var updatedAtDate: Date? {
        return ISO8601DateFormatter().date(from: updated_at ?? "")
    }

    var lastLoginDate: Date? {
        return ISO8601DateFormatter().date(from: last_login_at ?? "")
    }
}

/// Verification code response
struct VerificationCodeResponse: Codable {
    let phone: String
    let type: String
    let message: String
    let code: String? // Only in development mode

    var codeType: VerificationCodeType {
        return VerificationCodeType(rawValue: type) ?? .register
    }
}

/// Password reset response
struct PasswordResetResponse: Codable {
    let message: String
    let token: String? // Only in development mode
}

/// Current user response
struct CurrentUserResponse: Codable {
    let user: UserDTO
}

// MARK: - User Model for SwiftUI

/// User model for use in SwiftUI views
@MainActor
class UserModel: ObservableObject {
    @Published var id: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var avatar: String? = nil
    @Published var createdAt: Date? = nil
    @Published var updatedAt: Date? = nil
    @Published var lastLoginAt: Date? = nil

    init() {}

    init(from dto: UserDTO) {
        self.id = dto.id
        self.username = dto.username
        self.email = dto.email ?? ""
        self.phone = dto.phone ?? ""
        self.avatar = dto.avatar
        self.createdAt = dto.createdAtDate
        self.updatedAt = dto.updatedAtDate
        self.lastLoginAt = dto.lastLoginDate
    }

    func toDTO() -> UserDTO {
        let formatter = ISO8601DateFormatter()
        return UserDTO(
            id: id,
            username: username,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            avatar: avatar,
            created_at: createdAt.map { formatter.string(from: $0) },
            updated_at: updatedAt.map { formatter.string(from: $0) },
            last_login_at: lastLoginAt.map { formatter.string(from: $0) }
        )
    }

    func update(from dto: UserDTO) {
        self.id = dto.id
        self.username = dto.username
        self.email = dto.email ?? ""
        self.phone = dto.phone ?? ""
        self.avatar = dto.avatar
        self.createdAt = dto.createdAtDate
        self.updatedAt = dto.updatedAtDate
        self.lastLoginAt = dto.lastLoginDate
    }
}

// MARK: - Login Session

/// Login session management
@MainActor
class LoginSession: ObservableObject {
    @Published var user: UserModel
    @Published var accessToken: String = ""
    @Published var refreshToken: String = ""
    @Published var tokenExpirationDate: Date?

    private(set) var isRememberMe: Bool = false

    var isAuthenticated: Bool {
        return !accessToken.isEmpty && tokenExpirationDate ?? Date() > Date()
    }

    var isTokenExpired: Bool {
        guard let expiration = tokenExpirationDate else { return true }
        return expiration <= Date()
    }

    init() {
        self.user = UserModel()
    }

    func update(with response: AuthResponse, rememberMe: Bool = false) {
        self.user = UserModel(from: response.user)
        self.accessToken = response.tokens.access_token
        self.refreshToken = response.tokens.refresh_token
        self.tokenExpirationDate = response.tokens.accessTokenExpirationDate
        self.isRememberMe = rememberMe
    }

    func updateTokens(tokens: TokenData) {
        self.accessToken = tokens.access_token
        self.refreshToken = tokens.refresh_token
        self.tokenExpirationDate = tokens.accessTokenExpirationDate
    }

    func clear() {
        self.user = UserModel()
        self.accessToken = ""
        self.refreshToken = ""
        self.tokenExpirationDate = nil
        self.isRememberMe = false
    }
}
