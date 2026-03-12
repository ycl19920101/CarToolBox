//
//  APIError.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation

// MARK: - API Error

/// API error structure from backend
struct APIError: Codable {
    let code: Int
    let details: String?
}

// MARK: - Authentication Error

/// Authentication error codes (matching backend)
enum AuthErrorCode: Int {
    // Parameter errors (1000-1099)
    case parameterError = 1001
    case usernameExists = 1002
    case verificationCodeError = 1003
    case verificationCodeExpired = 1004

    // Authentication errors (2000-2099)
    case notAuthenticated = 2001
    case tokenExpired = 2002
    case invalidCredentials = 2003
    case invalidRefreshToken = 2004

    // Permission errors (3000-3099)
    case noPermission = 3001

    // Not found errors (4000-4099)
    case userNotFound = 4001

    // Rate limiting errors (5000-5099)
    case tooManyRequests = 5001

    // Server errors (9000-9099)
    case serverError = 9001

    // Unknown error
    case unknown = 9999

    var description: String {
        switch self {
        case .parameterError:
            return "参数错误"
        case .usernameExists:
            return "用户名已存在"
        case .verificationCodeError:
            return "验证码错误"
        case .verificationCodeExpired:
            return "验证码已过期"
        case .notAuthenticated:
            return "未登录"
        case .tokenExpired:
            return "登录已过期"
        case .invalidCredentials:
            return "用户名或密码错误"
        case .invalidRefreshToken:
            return "刷新令牌无效"
        case .noPermission:
            return "无权限操作"
        case .userNotFound:
            return "用户不存在"
        case .tooManyRequests:
            return "请求过于频繁，请稍后再试"
        case .serverError:
            return "服务器内部错误"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - Network Error

/// Custom error type for network operations
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case networkUnavailable
    case decodingError
    case serverError(String)
    case authError(AuthErrorCode)
    case tokenExpired
    case unknown(Error)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkUnavailable:
            return "网络不可用"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let message):
            return message
        case .authError(let code):
            return code.description
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var errorCode: Int? {
        switch self {
        case .authError(let code):
            return code.rawValue
        case .tokenExpired:
            return AuthErrorCode.tokenExpired.rawValue
        default:
            return nil
        }
    }
}

// MARK: - API Error Handler

/// Helper for handling API errors
struct APIErrorHandler {

    /// Parse API response and extract error if present
    static func handle<T: Codable>(response: APIResponse<T>) throws {
        if !response.success {
            if let error = response.error {
                throw NetworkError.authError(AuthErrorCode(rawValue: error.code) ?? .serverError)
            }
            throw NetworkError.serverError(response.message)
        }
    }

    /// Handle simple response without data
    static func handle(response: SimpleResponse) throws {
        if !response.success {
            if let error = response.error {
                throw NetworkError.authError(AuthErrorCode(rawValue: error.code) ?? .serverError)
            }
            throw NetworkError.serverError(response.message)
        }
    }

    /// Create an API error from a raw error
    static func create(from error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        return .unknown(error)
    }
}

// MARK: - HTTP Status Code Handler

/// Helper for HTTP status code handling
struct HTTPStatusCodeHandler {

    /// Check if status code indicates success
    static func isSuccess(_ statusCode: Int) -> Bool {
        return (200...299).contains(statusCode)
    }

    /// Check if status code indicates token expiration
    static func isTokenExpired(_ statusCode: Int) -> Bool {
        return statusCode == 401
    }

    /// Check if status code indicates server error
    static func isServerError(_ statusCode: Int) -> Bool {
        return (500...599).contains(statusCode)
    }

    /// Get error description for status code
    static func errorDescription(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "请求参数错误"
        case 401:
            return "未授权，请先登录"
        case 403:
            return "无权限访问"
        case 404:
            return "请求的资源不存在"
        case 429:
            return "请求过于频繁"
        case 500:
            return "服务器内部错误"
        case 502:
            return "网关错误"
        case 503:
            return "服务不可用"
        default:
            return "请求失败 (\(statusCode))"
        }
    }
}
