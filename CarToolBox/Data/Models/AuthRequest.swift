//
//  AuthRequest.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation
import UIKit

// MARK: - Auth Requests

/// Login request with username/email and password
struct LoginRequest: Codable {
    let identifier: String
    let password: String
    let device_name: String?
    let device_id: String?
    let remember_me: Bool

    init(identifier: String, password: String, device_name: String? = nil, device_id: String? = nil, remember_me: Bool = false) {
        self.identifier = identifier
        self.password = password
        self.device_name = device_name ?? UIDevice.current.name
        self.device_id = device_id ?? UIDevice.current.identifierForVendor?.uuidString
        self.remember_me = remember_me
    }
}

/// Register request
struct RegisterRequest: Codable {
    let username: String
    let password: String
    let email: String?
    let phone: String?

    init(username: String, password: String, email: String? = nil, phone: String? = nil) {
        self.username = username
        self.password = password
        self.email = email
        self.phone = phone
    }
}

/// Send verification code request
struct SendCodeRequest: Codable {
    let phone: String
    let type: String // "register", "login", "reset"

    init(phone: String, type: VerificationCodeType) {
        self.phone = phone
        self.type = type.rawValue
    }
}

/// SMS login request
struct SMSLoginRequest: Codable {
    let phone: String
    let code: String
    let device_name: String?
    let device_id: String?

    init(phone: String, code: String, device_name: String? = nil, device_id: String? = nil) {
        self.phone = phone
        self.code = code
        self.device_name = device_name ?? UIDevice.current.name
        self.device_id = device_id ?? UIDevice.current.identifierForVendor?.uuidString
    }
}

/// Biometric login request
struct BiometricLoginRequest: Codable {
    let refresh_token: String
    let device_name: String?
    let device_id: String?

    init(refreshToken: String, device_name: String? = nil, device_id: String? = nil) {
        self.refresh_token = refreshToken
        self.device_name = device_name ?? UIDevice.current.name
        self.device_id = device_id ?? UIDevice.current.identifierForVendor?.uuidString
    }
}

/// Change password request
struct ChangePasswordRequest: Codable {
    let old_password: String
    let new_password: String

    init(oldPassword: String, newPassword: String) {
        self.old_password = oldPassword
        self.new_password = newPassword
    }
}

/// Forgot password request
struct ForgotPasswordRequest: Codable {
    let email: String

    init(email: String) {
        self.email = email
    }
}

/// Reset password request
struct ResetPasswordRequest: Codable {
    let token: String
    let password: String

    init(token: String, password: String) {
        self.token = token
        self.password = password
    }
}

/// Refresh token request
struct RefreshTokenRequest: Codable {
    let refresh_token: String

    init(refreshToken: String) {
        self.refresh_token = refreshToken
    }
}

// MARK: - Verification Code Type

enum VerificationCodeType: String, Codable {
    case register = "register"
    case login = "login"
    case reset = "reset"
}

// MARK: - Device Info Helper

struct DeviceInfo {
    static var name: String {
        return UIDevice.current.name
    }

    static var id: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    static var model: String {
        return UIDevice.current.model
    }

    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
}
