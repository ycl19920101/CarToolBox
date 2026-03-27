//
//  AuthViewModel.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import Foundation
import Combine

// MARK: - Auth State

enum AuthState {
    case idle
    case loading
    case authenticated
    case unauthenticated

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var isLoggedIn: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
}

// MARK: - Auth ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var authState: AuthState = .idle
    @Published var currentUser: UserModel = UserModel()
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Login form
    @Published var loginIdentifier: String = ""
    @Published var loginPassword: String = ""
    @Published var rememberMe: Bool = false

    // Register form
    @Published var registerUsername: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPhone: String = ""
    @Published var registerPassword: String = ""
    @Published var registerConfirmPassword: String = ""

    // SMS login form
    @Published var smsPhone: String = ""
    @Published var smsCode: String = ""
    @Published var codeCountdown: Int = 0
    @Published var canResendCode: Bool = true

    // Forgot password form
    @Published var forgotPasswordEmail: String = ""
    @Published var resetToken: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""

    // Change password form
    @Published var currentPassword: String = ""
    @Published var changeNewPassword: String = ""
    @Published var confirmChangePassword: String = ""

    // Biometric
    @Published var isBiometricEnabled: Bool = false
    @Published var canUseBiometric: Bool = false

    // MARK: - Private Properties

    private let authService = AuthService.sharedInstance()
    private let keychainManager = KeychainManager.shared
    private let biometricManager = BiometricManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?

    // MARK: - Computed Properties

    var isLoginValid: Bool {
        !loginIdentifier.isEmpty && !loginPassword.isEmpty
    }

    var isRegisterValid: Bool {
        !registerUsername.isEmpty &&
        !registerPassword.isEmpty &&
        registerPassword == registerConfirmPassword &&
        registerPassword.count >= 8 &&
        !(registerEmail.isEmpty && registerPhone.isEmpty)
    }

    var isSMSLoginValid: Bool {
        !smsPhone.isEmpty && !smsCode.isEmpty && smsCode.count == 6
    }

    var isForgotPasswordValid: Bool {
        !forgotPasswordEmail.isEmpty
    }

    var isResetPasswordValid: Bool {
        !resetToken.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmNewPassword &&
        newPassword.count >= 8
    }

    var isChangePasswordValid: Bool {
        !currentPassword.isEmpty &&
        !changeNewPassword.isEmpty &&
        changeNewPassword == confirmChangePassword &&
        changeNewPassword.count >= 8
    }

    var passwordStrength: (level: String, score: Int) {
        let password = registerPassword.isEmpty ? changeNewPassword : registerPassword
        return PasswordValidator.strength(of: password)
    }

    var isLoggedIn: Bool {
        authState.isLoggedIn
    }

    var isLoading: Bool {
        authState.isLoading
    }

    var biometricType: BiometricManager.BiometricType {
        biometricManager.getBiometricType()
    }

    var biometricIconName: String {
        biometricManager.biometricIconName
    }

    // MARK: - Initialization

    init() {
        loadSavedAuthState()
        checkBiometricAvailability()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - Private Methods

    private func loadSavedAuthState() {
        authState = .loading

        Task { @MainActor in
            // Check if we have saved tokens
            let userId = try? keychainManager.loadUserId()
            let username = try? keychainManager.loadUsername()
            let accessToken = try? keychainManager.loadAccessToken()
            let refreshToken = try? keychainManager.loadRefreshToken()

            if let accessToken = accessToken, !accessToken.isEmpty {
                // We have a token, try to get current user info
                if let userId = userId {
                    currentUser.id = userId
                    currentUser.username = username ?? ""
                }

                // Set tokens to AuthService for API calls
                authService.currentAccessToken = accessToken
                if let refreshToken = refreshToken {
                    authService.currentRefreshToken = refreshToken
                }

                rememberMe = keychainManager.getRememberMe()
                isBiometricEnabled = keychainManager.isBiometricEnabled()

                // Verify token is still valid by getting current user
                let success = await getCurrentUser()

                if success {
                    authState = .authenticated
                } else {
                    // Token expired, clear auth
                    clearAuthState()
                }
            } else {
                clearAuthState()
            }
        }
    }

    private func clearAuthState() {
        authState = .unauthenticated
        currentUser = UserModel()
        errorMessage = nil
        successMessage = nil
    }

    private func checkBiometricAvailability() {
        canUseBiometric = biometricManager.canUseBiometric()
        isBiometricEnabled = keychainManager.isBiometricEnabled()
    }

    private func saveAuthState() {
        Task {
            do {
                try keychainManager.saveUserId(currentUser.id)
                try keychainManager.saveUsername(currentUser.username)
                try keychainManager.setRememberMe(rememberMe)
                try? keychainManager.enableBiometric()
            } catch {
                Logger.auth.error("Failed to save auth state: \(error)")
            }
        }
    }

    private func clearSavedAuthState() {
        keychainManager.deleteTokens()
        keychainManager.delete(for: .userId)
        keychainManager.delete(for: .username)
        keychainManager.delete(for: .rememberMe)
        keychainManager.delete(for: .lastLoginDate)
        keychainManager.delete(for: .biometricEnabled)

        // Clear NetworkManager's manual auth token
        NetworkManager.sharedInstance().clearAuthToken()
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    private func startCodeCountdown() {
        canResendCode = false
        codeCountdown = 60

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.codeCountdown -= 1
            if self.codeCountdown <= 0 {
                self.canResendCode = true
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
            }
        }
    }

    // MARK: - Login

    func login() {
        guard isLoginValid else {
            Logger.auth.error("Login validation failed: missing identifier or password")
            errorMessage = "请输入用户名和密码"
            return
        }

        Logger.auth.separator()
        Logger.auth.info("Starting login...")
        Logger.auth.debug("Identifier: \(loginIdentifier)")
        Logger.auth.debug("Remember me: \(rememberMe)")

        authState = .loading
        errorMessage = nil

        authService.login(withIdentifier: loginIdentifier, password: loginPassword, rememberMe: rememberMe) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    Logger.auth.error("Login failed: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        Logger.auth.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                    self.handleError(error)
                    self.authState = .idle
                    return
                }

                if let data = data {
                    Logger.auth.info("Login successful")
                    self.handleAuthResponse(data)
                    self.successMessage = "登录成功"
                    self.authState = .authenticated
                }
                Logger.auth.separator()
            }
        }
    }

    // MARK: - Register

    func register() {
        guard isRegisterValid else {
            Logger.auth.error("Register validation failed")
            errorMessage = "请填写完整的注册信息"
            return
        }

        Logger.auth.separator()
        Logger.auth.info("Starting registration...")
        Logger.auth.debug("Username: \(registerUsername)")
        Logger.auth.debug("Email: \(registerEmail.isEmpty ? "none" : registerEmail)")
        Logger.auth.debug("Phone: \(registerPhone.isEmpty ? "none" : registerPhone)")

        authState = .loading
        errorMessage = nil

        authService.register(withUsername: registerUsername,
                             password: registerPassword,
                                email: registerEmail.isEmpty ? nil : registerEmail,
                                phone: registerPhone.isEmpty ? nil : registerPhone) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    Logger.auth.error("Registration failed: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        Logger.auth.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    }
                    self.handleError(error)
                    self.authState = .idle
                    return
                }

                if let data = data {
                    Logger.auth.info("Registration successful")
                    self.handleAuthResponse(data)
                    self.successMessage = "注册成功"
                    self.authState = .authenticated
                }
                Logger.auth.separator()
            }
        }
    }

    // MARK: - SMS Login

    func sendVerificationCode() {
        guard !smsPhone.isEmpty else {
            errorMessage = "请输入手机号"
            return
        }

        guard PhoneValidator.isValid(smsPhone) else {
            errorMessage = "请输入有效的手机号"
            return
        }

        errorMessage = nil

        authService.sendVerificationCode(toPhone: smsPhone, type: "login") { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    return
                }

                self.successMessage = "验证码已发送"
                self.startCodeCountdown()
            }
        }
    }

    func loginWithSMS() {
        guard isSMSLoginValid else {
            errorMessage = "请输入手机号和验证码"
            return
        }

        authState = .loading
        errorMessage = nil

        authService.login(withPhone: smsPhone, code: smsCode) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    self.authState = .idle
                    return
                }

                if let data = data {
                    self.handleAuthResponse(data)
                    self.successMessage = "登录成功"
                    self.authState = .authenticated
                }
            }
        }
    }

    // MARK: - Biometric Login

    func loginWithBiometric() {
        guard canUseBiometric else {
            errorMessage = "设备不支持生物识别"
            return
        }

        guard isBiometricEnabled else {
            errorMessage = "请先登录并启用生物识别"
            return
        }

        guard let refreshToken = try? keychainManager.loadRefreshToken() else {
            errorMessage = "请先登录"
            return
        }

        authState = .loading
        errorMessage = nil

        Task {
            do {
                let success = try await biometricManager.authenticate(
                    reason: biometricManager.getBiometricPromptReason()
                )

                if success {
                    authService.login(withBiometricToken: refreshToken) { [weak self] data, error in
                        DispatchQueue.main.async {
                            guard let self = self else { return }

                            if let error = error {
                                self.handleError(error)
                                self.authState = .idle
                                return
                            }

                            if let data = data {
                                self.handleAuthResponse(data)
                                self.successMessage = "生物识别登录成功"
                                self.authState = .authenticated
                            }
                        }
                    }
                }
            } catch {
                handleError(error)
                authState = .idle
            }
        }
    }

    // MARK: - Password Management

    func forgotPassword() {
        guard isForgotPasswordValid else {
            errorMessage = "请输入邮箱地址"
            return
        }

        errorMessage = nil

        authService.forgotPassword(withEmail: forgotPasswordEmail) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    return
                }

                self.successMessage = "如果该邮箱已注册，您将收到重置密码的邮件"
            }
        }
    }

    func resetPassword() {
        guard isResetPasswordValid else {
            errorMessage = "请填写完整的密码信息"
            return
        }

        authState = .loading
        errorMessage = nil

        authService.resetPassword(withToken: resetToken, newPassword: newPassword) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    self.authState = .idle
                    return
                }

                if success {
                    self.successMessage = "密码重置成功，请使用新密码登录"
                    self.resetToken = ""
                    self.newPassword = ""
                    self.confirmNewPassword = ""
                    self.authState = .idle
                }
            }
        }
    }

    func changePassword() {
        guard isChangePasswordValid else {
            errorMessage = "请填写完整的密码信息"
            return
        }

        authState = .loading
        errorMessage = nil

        authService.changePassword(from: currentPassword, to: changeNewPassword) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    self.authState = .idle
                    return
                }

                if success {
                    self.successMessage = "密码修改成功"
                    self.currentPassword = ""
                    self.changeNewPassword = ""
                    self.confirmChangePassword = ""
                    self.authState = .authenticated
                }
            }
        }
    }

    // MARK: - Token Management

    func refreshAccessToken() {
        guard let refreshToken = try? keychainManager.loadRefreshToken() else {
            return
        }

        authService.refreshToken(refreshToken) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    // Token refresh failed, logout
                    self.logout()
                    return
                }

                if let data = data {
                    self.handleAuthResponse(data)
                }
            }
        }
    }

    // MARK: - User Info

    @discardableResult
    func getCurrentUser() async -> Bool {
        await withCheckedContinuation { continuation in
            authService.getCurrentUser { [weak self] data, error in
                DispatchQueue.main.async {
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }

                    if let error = error {
                        self.handleError(error)
                        continuation.resume(returning: false)
                        return
                    }

                    if let data = data {
                        self.handleAuthResponse(data)
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    // MARK: - Logout

    func logout() {
        authState = .loading

        authService.logout { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Clear auth state regardless of server response
                self.clearAuthState()
                self.clearSavedAuthState()
                self.successMessage = "已退出登录"
                self.authState = .unauthenticated
            }
        }
    }

    // MARK: - Helper Methods

    private func handleAuthResponse(_ data: [AnyHashable: Any]) {
        Logger.auth.debug("Handling auth response...")

        // Handle user data - support both formats:
        // 1. { "user": {...}, "accessToken": "..." } - from login/register
        // 2. { "id": "...", "username": "..." } - direct user object from /me
        if let userDict = data["user"] as? [String: Any] {
            // Login/register response format
            Logger.auth.debug("Found user dict in response")
            let userDTO = UserDTO(dictionary: userDict)
            currentUser.update(from: userDTO)
            Logger.auth.debug("User: id=\(currentUser.id), username=\(currentUser.username)")
        } else if data["id"] as? String != nil {
            // Direct user object format (from /me endpoint)
            Logger.auth.debug("Found direct user object in response")
            let userDTO = UserDTO(dictionary: data as? [String: Any] ?? [:])
            currentUser.update(from: userDTO)
            Logger.auth.debug("User: id=\(currentUser.id), username=\(currentUser.username)")
        }

        // Handle tokens - support multiple formats:
        // 1. Tokens at root level: { "accessToken": "...", "refreshToken": "..." }
        // 2. Tokens nested: { "tokens": { "access_token": "..." } }
        var accessToken: String?
        var refreshToken: String?

        // Try root level first (camelCase)
        accessToken = data["accessToken"] as? String
        refreshToken = data["refreshToken"] as? String

        // Try root level snake_case
        if accessToken == nil {
            accessToken = data["access_token"] as? String
        }
        if refreshToken == nil {
            refreshToken = data["refresh_token"] as? String
        }

        // Try nested tokens object
        if accessToken == nil, let tokensDict = data["tokens"] as? [String: Any] {
            accessToken = tokensDict["access_token"] as? String
                ?? tokensDict["accessToken"] as? String
                ?? tokensDict["token"] as? String
            refreshToken = tokensDict["refresh_token"] as? String
                ?? tokensDict["refreshToken"] as? String
        }

        if let accessToken = accessToken, !accessToken.isEmpty {
            Logger.auth.debug("Access token: \(accessToken.prefix(20))...")
            Logger.auth.debug("Refresh token: \(refreshToken?.prefix(20) ?? "nil")...")

            // Always set tokens in memory first (works even if Keychain fails)
            authService.currentAccessToken = accessToken
            authService.currentRefreshToken = refreshToken
            Logger.auth.debug("✅ Tokens set in AuthService - currentAccessToken: \(authService.currentAccessToken ?? "nil")")

            // Try to persist to Keychain (may fail on simulator)
            do {
                try keychainManager.saveAccessToken(accessToken)
                if let refreshToken = refreshToken {
                    try keychainManager.saveRefreshToken(refreshToken)
                }
                Logger.auth.debug("✅ Tokens saved to Keychain")
            } catch {
                Logger.auth.warning("⚠️ Keychain save failed (tokens in memory still work): \(error)")
            }
        } else {
            Logger.auth.warning("⚠️ No access token found in response")
        }

        saveAuthState()
    }

    // MARK: - Clear Forms

    func clearLoginForm() {
        loginIdentifier = ""
        loginPassword = ""
        rememberMe = false
        errorMessage = nil
    }

    func clearRegisterForm() {
        registerUsername = ""
        registerEmail = ""
        registerPhone = ""
        registerPassword = ""
        registerConfirmPassword = ""
        errorMessage = nil
    }

    func clearSMSLoginForm() {
        smsPhone = ""
        smsCode = ""
        codeCountdown = 0
        canResendCode = true
        countdownTimer?.invalidate()
        countdownTimer = nil
        errorMessage = nil
    }

    func clearForgotPasswordForm() {
        forgotPasswordEmail = ""
        resetToken = ""
        newPassword = ""
        confirmNewPassword = ""
        errorMessage = nil
    }

    func clearChangePasswordForm() {
        currentPassword = ""
        changeNewPassword = ""
        confirmChangePassword = ""
        errorMessage = nil
    }

    func clearAllForms() {
        clearLoginForm()
        clearRegisterForm()
        clearSMSLoginForm()
        clearForgotPasswordForm()
        clearChangePasswordForm()
        successMessage = nil
    }

    // MARK: - Biometric Settings

    func toggleBiometric() {
        if canUseBiometric {
            isBiometricEnabled.toggle()
            if isBiometricEnabled {
                try? keychainManager.enableBiometric()
            } else {
                keychainManager.disableBiometric()
            }
        }
    }
}

// MARK: - Password Validator

enum PasswordValidator {
    static func strength(of password: String) -> (level: String, score: Int) {
        guard !password.isEmpty else {
            return ("无", 0)
        }

        var score = 0

        // Length
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }

        // Variety
        if password.lowercased() != password { score += 1 }
        if password.uppercased() != password { score += 1 }
        if password.range(of: "\\d", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }

        let level: String
        switch score {
        case 0...2: level = "弱"
        case 3...4: level = "中"
        case 5...7: level = "强"
        default: level = "强"
        }

        return (level, score)
    }
}

// MARK: - Phone Validator

enum PhoneValidator {
    static func isValid(_ phone: String) -> Bool {
        // Remove non-digit characters
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
}

// MARK: - Email Validator

enum EmailValidator {
    static func isValid(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - UserDTO Extension

extension UserDTO {
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.email = dictionary["email"] as? String
        self.phone = dictionary["phone"] as? String
        self.avatar = dictionary["avatar"] as? String
        self.created_at = dictionary["createdAt"] as? String ?? dictionary["created_at"] as? String
        self.updated_at = dictionary["updatedAt"] as? String ?? dictionary["updated_at"] as? String
        self.last_login_at = dictionary["lastLoginAt"] as? String ?? dictionary["last_login_at"] as? String
    }
}
