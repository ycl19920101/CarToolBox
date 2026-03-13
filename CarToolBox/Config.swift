//
//  Config.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation

// MARK: - App Environment

enum AppEnvironment {
    case development
    case staging
    case production

    #if DEBUG
    static let current: AppEnvironment = .development
    #else
    static let current: AppEnvironment = .production
    #endif
}

// MARK: - Configuration

struct Config {
    // MARK: - App Environment

    static let environment: AppEnvironment = AppEnvironment.current

    // MARK: - API Configuration

    struct API {
        static var baseURL: String {
            switch environment {
            case .development:
                return "http://localhost:3000"
            case .staging:
                return "https://staging-api.cartoolbox.com"
            case .production:
                return "https://api.cartoolbox.com"
            }
        }

        static let apiVersion = "v1"
        static let timeout: TimeInterval = 30
        static let retryCount = 3
        static let retryDelay: TimeInterval = 1.0

        // MARK: - Endpoints

        struct Auth {
            static let path = "/api/auth"
            static let register = "\(path)/register"
            static let login = "\(path)/login"
            static let sendCode = "\(path)/send-code"
            static let loginSMS = "\(path)/login-sms"
            static let biometricLogin = "\(path)/biometric-login"
            static let changePassword = "\(path)/change-password"
            static let forgotPassword = "\(path)/forgot-password"
            static let resetPassword = "\(path)/reset-password"
            static let refreshToken = "\(path)/refresh"
            static let me = "\(path)/me"
            static let logout = "\(path)/logout"
        }

        struct Vehicle {
            static let path = "/api/vehicle"
            static let status = "\(path)/status"
            static let lock = "\(path)/lock"
            static let unlock = "\(path)/unlock"
            static let battery = "\(path)/battery"
            static let climate = "\(path)/climate"
            static let windows = "\(path)/windows"
            static let horn = "\(path)/horn"
            static let location = "\(path)/location"
        }

            // MARK: - Community API Configuration

    struct Community {
        static let path = "/api/community"
        static let posts = "\(path)/posts"
        static let postDetail = "\(path)/posts/:id"
        static let userPosts = "/api/community/users/:userId/posts"
        static let createPost = "\(path)/posts"
        static let like = "\(path)/like"
        static let upload = "\(path)/upload"
        static let uploadImage = "\(upload)/image"
        static let uploadImages = "\(upload)/images"
        static let uploadVideo = "\(upload)/video"
        static let comments = "/api/community/posts/:postId/comments"
        static let commentReplies = "/api/community/comments/:commentId/replies"
    }
}

    // MARK: - App Configuration

    struct App {
        static let name = "CarToolBox"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // MARK: - Feature Flags

        struct Features {
            static let biometricAuth = true
            static let rememberMe = true
            static let darkMode = true
            static let notifications = true
            static let locationTracking = true
            static let analytics = true
        }

        // MARK: - Limits

        struct Limits {
            static let maxRetries = 3
            static let maxImageSize = 10 * 1024 * 1024 // 10MB
            static let maxVideoSize = 50 * 1024 * 1024 // 50MB
            static let maxCaptionLength = 500
        }

        // MARK: - Cache

        struct Cache {
            static let imageCacheSize = 100 * 1024 * 1024 // 100MB
            static let dataCacheSize = 50 * 1024 * 1024 // 50MB
            static let tokenCacheDuration: TimeInterval = 3600 // 1 hour
        }
    }

    // MARK: - Security Configuration

    struct Security {
        static let accessTokenExpiration: TimeInterval = 3600 // 1 hour
        static let refreshTokenExpiration: TimeInterval = 604800 // 7 days
        static let rememberMeExpiration: TimeInterval = 604800 // 7 days
        static let passwordMinLength = 8
        static let passwordMaxLength = 128

        // Keychain settings
        static let keychainService = "com.cartoolbox"
        static let keychainAccessGroup: String? = nil // Set for app extensions

        // Biometric settings
        static let biometricTimeout: TimeInterval = 0 // No timeout
        static let allowBiometricFallback = true
    }

    // MARK: - UI Configuration

    struct UI {
        // Animation
        static let animationDuration: TimeInterval = 0.3
        static let springDamping: CGFloat = 0.8
        static let springResponse: Double = 0.5

        // Layout
        static let defaultPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50

        // Colors
        struct Colors {
            static let primary = "blue"
            static let success = "green"
            static let warning = "orange"
            static let error = "red"
        }
    }

    // MARK: - Storage Keys

    struct Keys {
        static let hasOnboarded = "hasOnboarded"
        static let lastKnownVersion = "lastKnownVersion"
        static let theme = "theme"
        static let language = "language"
        static let notificationsEnabled = "notificationsEnabled"
        static let locationEnabled = "locationEnabled"
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension Config {
    static func printConfiguration() {
        Logger.general.info("""
        ╔════════════════════════════════════════╗
        ║   CarToolBox Configuration                 ║
        ╠════════════════════════════════════════╣
        ║   Environment: \(environment.rawValue)                ║
        ║   API Base URL: \(API.baseURL)    ║
        ║   App Version: \(App.version)                     ║
        ║   Build: \(App.build)                          ║
        ╠════════════════════════════════════════╣
        ║   Features:                               ║
        ║   • Biometric Auth: \(App.Features.biometricAuth ? "✅" : "❌")             ║
        ║   • Remember Me: \(App.Features.rememberMe ? "✅" : "❌")                ║
        ║   • Dark Mode: \(App.Features.darkMode ? "✅" : "❌")                   ║
        ║   • Notifications: \(App.Features.notifications ? "✅" : "❌")              ║
        ╚════════════════════════════════════════╝
        """)
    }
}

extension AppEnvironment {
    var rawValue: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}
#endif
