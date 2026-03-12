//
//  BiometricManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation
import LocalAuthentication

// MARK: - Biometric Manager

/// Manager for biometric authentication (Face ID / Touch ID)
class BiometricManager {

    // MARK: - Biometric Type

    enum BiometricType: String {
        case none
        case touchID = "Touch ID"
        case faceID = "Face ID"

        var iconName: String {
            switch self {
            case .none:
                return "person.circle"
            case .touchID:
                return "touchid"
            case .faceID:
                return "faceid"
            }
        }

        var localizedDescription: String {
            switch self {
            case .none:
                return "不可用"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            }
        }
    }

    // MARK: - Error

    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case lockedOut
        case userFallback
        case userCancel
        case systemCancel
        case authenticationFailed
        case passcodeNotSet
        case unknown(Error)
        case appCancel
        case invalidContext

        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "生物识别不可用"
            case .notEnrolled:
                return "未设置生物识别"
            case .lockedOut:
                return "生物识别已被锁定，请使用密码"
            case .userFallback:
                return "用户选择使用密码"
            case .userCancel:
                return "用户取消"
            case .systemCancel:
                return "系统取消"
            case .authenticationFailed:
                return "认证失败"
            case .passcodeNotSet:
                return "未设置密码"
            case .unknown(let error):
                return error.localizedDescription
            case .appCancel:
                return "应用取消"
            case .invalidContext:
                return "无效的上下文"
            }
        }
    }

    // MARK: - Shared Instance

    static let shared = BiometricManager()

    private init() {}

    // MARK: - Availability Check

    /// Check if biometric authentication is available
    func canUseBiometric() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Get the type of biometric authentication available
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .faceID
        @unknown default:
            return .none
        }
    }

    /// Check if biometric is enrolled
    func isBiometricEnrolled() -> Bool {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            return error.code != kLAErrorBiometryNotEnrolled
        }

        return canEvaluate
    }

    /// Check if passcode is set
    func isPasscodeSet() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    // MARK: - Authentication

    /// Authenticate with biometrics
    /// - Parameters:
    ///   - reason: Reason to show to user
    ///   - fallbackTitle: Custom fallback button title (optional)
    /// - Returns: Result indicating success or failure
    func authenticate(reason: String, fallbackTitle: String? = nil) async throws -> Bool {
        let context = LAContext()

        // Set fallback title
        if let fallbackTitle = fallbackTitle {
            context.localizedFallbackTitle = fallbackTitle
        } else {
            // Remove fallback button
            context.localizedFallbackTitle = ""
        }

        // Set cancel title
        context.localizedCancelTitle = "取消"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapError(error)
        } catch {
            throw BiometricError.unknown(error)
        }
    }

    /// Authenticate with device passcode as fallback
    /// - Parameter reason: Reason to show to user
    /// - Returns: Result indicating success or failure
    func authenticateWithPasscode(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "取消"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapError(error)
        } catch {
            throw BiometricError.unknown(error)
        }
    }

    /// Invalidate current context
    func invalidate() {
        // LAContext is lightweight and doesn't need explicit invalidation
        // This method is for future use if needed
    }

    // MARK: - Error Mapping

    private func mapError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockedOut
        case .userFallback:
            return .userFallback
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .authenticationFailed:
            return .authenticationFailed
        case .passcodeNotSet:
            return .passcodeNotSet
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        default:
            return .unknown(error)
        }
    }

    // MARK: - UI Helpers

    /// Get the prompt title for biometric login
    func getBiometricPromptTitle() -> String {
        switch getBiometricType() {
        case .faceID:
            return "使用 Face ID 登录"
        case .touchID:
            return "使用 Touch ID 登录"
        case .none:
            return "登录"
        }
    }

    /// Get the prompt reason for biometric login
    func getBiometricPromptReason() -> String {
        switch getBiometricType() {
        case .faceID:
            return "验证您的身份以快速登录"
        case .touchID:
            return "验证您的身份以快速登录"
        case .none:
            return "验证您的身份"
        }
    }

    /// Check if face ID is available
    var isFaceIDAvailable: Bool {
        return getBiometricType() == .faceID
    }

    /// Check if touch ID is available
    var isTouchIDAvailable: Bool {
        return getBiometricType() == .touchID
    }

    /// Get the appropriate image name for current biometric type
    var biometricIconName: String {
        return getBiometricType().iconName
    }

    /// Get localized name for current biometric type
    var biometricLocalizedName: String {
        return getBiometricType().localizedDescription
    }
}
