//
//  NetworkManager.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import Foundation
import Combine

// MARK: - Network Manager

@MainActor
class NetworkManager: ObservableObject {
    @Published var isConnected = true

    // Shared session with configuration
    private let session: URLSession
    private let keychainManager = KeychainManager.shared
    private let authViewModel: AuthViewModel

    // API configuration
    private let baseURL: String
    private let defaultTimeout: TimeInterval

    // Singleton
    static let shared = NetworkManager()

    init(baseURL: String = "https://api.cartoolbox.com", timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        self.defaultTimeout = timeout
        self.authViewModel = AuthViewModel()

        // Configure session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic Request Methods

    /// Perform a generic network request
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:],
        responseType: T.Type = T.self
    ) async throws -> T {
        var urlComponents = URLComponents(string: endpoint)

        if !endpoint.hasPrefix("http") {
            urlComponents?.scheme = "https"
            urlComponents?.host = baseURL
        }

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = defaultTimeout

        // Add default headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        // Add authentication token
        if let token = try? keychainManager.loadAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if present
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        // Perform request with retry logic
        return try await performRequestWithRetry(request: request, responseType: responseType)
    }

    /// Perform request with automatic retry on token expiration
    private func performRequestWithRetry<T: Decodable>(
        request: URLRequest,
        responseType: T.Type,
        retryCount: Int = 0
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "NetworkManager", code: -1))
        }

        // Handle token expiration (401)
        if httpResponse.statusCode == 401 && retryCount == 0 {
            // Try to refresh token
            if try await refreshToken() {
                // Create new request with updated token
                var newRequest = request
                if let token = try? keychainManager.loadAccessToken() {
                    newRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                return try await performRequestWithRetry(request: newRequest, responseType: responseType, retryCount: 1)
            }
        }

        // Handle other errors
        try handleStatusCode(httpResponse.statusCode)

        // Decode response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Token Management

    /// Refresh access token using refresh token
    private func refreshToken() async throws -> Bool {
        guard let refreshToken = try? keychainManager.loadRefreshToken() else {
            // No refresh token, user needs to login again
            authViewModel.logout()
            return false
        }

        // Create refresh token request
        let url = URL(string: "\(baseURL)/api/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RefreshTokenRequest(refreshToken: refreshToken)
        request.httpBody = try? JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        if httpResponse.statusCode == 401 {
            // Refresh token also expired, logout user
            authViewModel.logout()
            return false
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            return false
        }

        // Parse response and update tokens
        if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            try keychainManager.saveAccessToken(authResponse.tokens.access_token)
            try keychainManager.saveRefreshToken(authResponse.tokens.refresh_token)

            // Update auth service
            authViewModel.currentUser.update(from: authResponse.user)

            return true
        }

        return false
    }

    // MARK: - Error Handling

    private func handleStatusCode(_ statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            return
        case 400:
            throw NetworkError.serverError("请求参数错误")
        case 401:
            throw NetworkError.authError(.notAuthenticated)
        case 403:
            throw NetworkError.authError(.noPermission)
        case 404:
            throw NetworkError.serverError("请求的资源不存在")
        case 429:
            throw NetworkError.serverError("请求过于频繁")
        case 500...599:
            throw NetworkError.serverError("服务器内部错误")
        default:
            throw NetworkError.serverError(HTTPStatusCodeHandler.errorDescription(for: statusCode))
        }
    }

    private func handleAPIError<T>(_ response: APIResponse<T>) -> Error {
        if let error = response.error {
            let code = AuthErrorCode(rawValue: error.code) ?? .unknown
            return NetworkError.authError(code)
        }
        return NetworkError.serverError(response.message)
    }

    // MARK: - Vehicle Status (Existing Method)

    func fetchVehicleStatus() async throws -> VehicleStatus {
        return try await request(
            endpoint: "/vehicle/status",
            method: .get,
            responseType: VehicleStatus.self
        )
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

