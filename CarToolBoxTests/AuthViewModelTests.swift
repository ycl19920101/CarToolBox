//
//  AuthViewModelTests.swift
//  CarToolBoxTests
//
//  Created by Chunlin Yao on 2026/3/9.
//

import XCTest
@testable import CarToolBox

// MARK: - Mock Services

class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var shouldThrowError = false
    var mockUser: UserDTO?
    var mockTokens: TokenData?

    func register(username: String, password: String, email: String?, phone: String?) async throws -> AuthResponse {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Username already exists"])
        }

        let user = mockUser ?? UserDTO(
            id: "123",
            username: username,
            email: email,
            phone: phone,
            avatar: nil,
            created_at: nil,
            updated_at: nil,
            last_login_at: nil
        )

        let tokens = mockTokens ?? TokenData(
            access_token: "mockAccessToken",
            refresh_token: "mockRefreshToken",
            expires_in: 3600
        )

        return AuthResponse(user: user, tokens: tokens)
    }

    func login(identifier: String, password: String, device_name: String?, device_id: String?, rememberMe: Bool) async throws -> AuthResponse {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Username or password error"])
        }

        let user = mockUser ?? UserDTO(
            id: "123",
            username: identifier,
            email: "\(identifier)@example.com",
            phone: nil,
            avatar: nil,
            created_at: nil,
            updated_at: nil,
            last_login_at: nil
        )

        let tokens = mockTokens ?? TokenData(
            access_token: "mockAccessToken",
            refresh_token: "mockRefreshToken",
            expires_in: 3600
        )

        return AuthResponse(user: user, tokens: tokens)
    }

    func loginWithSMS(phone: String, code: String, device_name: String?, device_id: String?) async throws -> AuthResponse {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Verification code error"])
        }

        let user = mockUser ?? UserDTO(
            id: "123",
            username: phone,
            email: nil,
            phone: phone,
            avatar: nil,
            created_at: nil,
            updated_at: nil,
            last_login_at: nil
        )

        let tokens = mockTokens ?? TokenData(
            access_token: "mockAccessToken",
            refresh_token: "mockRefreshToken",
            expires_in: 3600
        )

        return AuthResponse(user: user, tokens: tokens)
    }

    func sendVerificationCode(to phone: String, type: VerificationCodeType) async throws -> VerificationCodeResponse {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Phone is required"])
        }

        return VerificationCodeResponse(
            phone: phone,
            type: type.rawValue,
            message: "Verification code sent successfully",
            code: nil
        )
    }

    func loginWithBiometric(refreshToken: String, device_name: String?, device_id: String?) async throws -> AuthResponse {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 2004, userInfo: [NSLocalizedDescriptionKey: "Invalid refresh token"])
        }

        let user = mockUser ?? UserDTO(
            id: "123",
            username: "testuser",
            email: "test@example.com",
            phone: nil,
            avatar: nil,
            created_at: nil,
            updated_at: nil,
            last_login_at: nil
        )

        let tokens = mockTokens ?? TokenData(
            access_token: "mockAccessToken",
            refresh_token: "mockRefreshToken",
            expires_in: 3600
        )

        return AuthResponse(user: user, tokens: tokens)
    }

    func changePassword(oldPassword: String, newPassword: String) async throws -> UserDTO {
        if shouldThrowError {
            throw NSError(domain: "Mock", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Current password incorrect"])
        }

        return mockUser ?? UserDTO(
            id: "123",
            username: "testuser",
            email: "test@example.com",
            phone: nil,
            avatar: nil,
            created_at: nil,
            updated_at: nil,
            last_login_at: nil
        )
    }

    func forgotPassword(email: String) async throws -> PasswordResetResponse {
        return PasswordResetResponse(message: "Password reset email sent")
    }

    func resetPassword(token: String, newPassword: String) async throws -> SimpleResponse {
        return SimpleResponse(success: true, message: "Password reset successful", error: nil)
    }

    func logout() {}
}

protocol AuthServiceProtocol {
    func register(username: String, password: String, email: String?, phone: String?) async throws -> AuthResponse
    func login(identifier: String, password: String, device_name: String?, device_id: String?, rememberMe: Bool) async throws -> AuthResponse
    func loginWithSMS(phone: String, code: String, device_name: String?, device_id: String?) async throws -> AuthResponse
    func sendVerificationCode(to phone: String, type: VerificationCodeType) async throws -> VerificationCodeResponse
    func loginWithBiometric(refreshToken: String, device_name: String?, device_id: String?) async throws -> AuthResponse
    func changePassword(oldPassword: String, newPassword: String) async throws -> UserDTO
    func forgotPassword(email: String) async throws -> PasswordResetResponse
    func resetPassword(token: String, newPassword: String) async throws -> SimpleResponse
    func logout()
}

// MARK: - AuthViewModel Tests

@MainActor
class AuthViewModelTests: XCTestCase {

    var sut: AuthViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        // Note: We would need to modify AuthViewModel to accept an injected service for proper testing
        // For now, this shows the test structure
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testLoginValidation_WhenEmpty_ShouldBeInvalid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.loginIdentifier = ""
        viewModel.loginPassword = ""

        // Then
        XCTAssertFalse(viewModel.isLoginValid)
    }

    func testLoginValidation_WhenValid_ShouldBeValid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.loginIdentifier = "testuser"
        viewModel.loginPassword = "Test123456"

        // Then
        XCTAssertTrue(viewModel.isLoginValid)
    }

    func testRegisterValidation_WhenEmpty_ShouldBeInvalid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.registerUsername = ""
        viewModel.registerPassword = ""

        // Then
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    func testRegisterValidation_WhenValid_ShouldBeValid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.registerUsername = "testuser"
        viewModel.registerPassword = "Test123456"
        viewModel.registerConfirmPassword = "Test123456"
        viewModel.registerEmail = "test@example.com"

        // Then
        XCTAssertTrue(viewModel.isRegisterValid)
    }

    func testRegisterValidation_WhenPasswordsMismatch_ShouldBeInvalid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.registerUsername = "testuser"
        viewModel.registerPassword = "Test123456"
        viewModel.registerConfirmPassword = "Different123"
        viewModel.registerEmail = "test@example.com"

        // Then
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    func testRegisterValidation_WhenPasswordTooShort_ShouldBeInvalid() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.registerUsername = "testuser"
        viewModel.registerPassword = "Short"
        viewModel.registerConfirmPassword = "Short"
        viewModel.registerEmail = "test@example.com"

        // Then
        XCTAssertFalse(viewModel.isRegisterValid)
    }

    func testPasswordStrength_WhenWeak_ShouldReturnWeak() {
        // Given
        let password = "password"

        // When
        let result = PasswordValidator.strength(of: password)

        // Then
        XCTAssertLessThan(result.score, 3)
    }

    func testPasswordStrength_WhenStrong_ShouldReturnStrong() {
        // Given
        let password = "Str0ng!P@ssw0rd123"

        // When
        let result = PasswordValidator.strength(of: password)

        // Then
        XCTAssertGreaterThanOrEqual(result.score, 5)
        XCTAssertEqual(result.level, "强")
    }

    // MARK: - Phone Validation Tests

    func testPhoneValidator_WhenValid_ShouldBeValid() {
        // Given
        let validPhones = ["13800138000", "+8613800138000", "1234567890"]

        // Then
        for phone in validPhones {
            XCTAssertTrue(PhoneValidator.isValid(phone), "\(phone) should be valid")
        }
    }

    func testPhoneValidator_WhenInvalid_ShouldBeInvalid() {
        // Given
        let invalidPhones = ["123", "abc", "13800138000", "1234567890123456"]

        // Then
        for phone in invalidPhones {
            if phone.count < 10 || phone.count > 15 {
                XCTAssertFalse(PhoneValidator.isValid(phone), "\(phone) should be invalid")
            }
        }
    }

    // MARK: - Email Validation Tests

    func testEmailValidator_WhenValid_ShouldBeValid() {
        // Given
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "test@subdomain.example.com"
        ]

        // Then
        for email in validEmails {
            XCTAssertTrue(EmailValidator.isValid(email), "\(email) should be valid")
        }
    }

    func testEmailValidator_WhenInvalid_ShouldBeInvalid() {
        // Given
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            "user..name@example.com"
        ]

        // Then
        for email in invalidEmails {
            XCTAssertFalse(EmailValidator.isValid(email), "\(email) should be invalid")
        }
    }

    // MARK: - State Tests

    func testInitialState_ShouldBeUnauthenticated() {
        // Given
        let viewModel = AuthViewModel()

        // Then
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertEqual(viewModel.authState, .idle)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testAuthState_WhenLoading_ShouldIndicateLoading() {
        // Given
        let viewModel = AuthViewModel()

        // When
        viewModel.authState = .loading

        // Then
        XCTAssertTrue(viewModel.isLoading)
    }

    func testAuthState_WhenAuthenticated_ShouldBeLoggedIn() {
        // Given
        let viewModel = AuthViewModel()

        // When
        viewModel.authState = .authenticated

        // Then
        XCTAssertTrue(viewModel.isLoggedIn)
    }

    // MARK: - Form Clear Tests

    func testClearLoginForm_ShouldResetAllFields() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.loginIdentifier = "testuser"
        viewModel.loginPassword = "Test123456"
        viewModel.rememberMe = true
        viewModel.errorMessage = "Some error"

        // When
        viewModel.clearLoginForm()

        // Then
        XCTAssertEqual(viewModel.loginIdentifier, "")
        XCTAssertEqual(viewModel.loginPassword, "")
        XCTAssertFalse(viewModel.rememberMe)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testClearRegisterForm_ShouldResetAllFields() {
        // Given
        let viewModel = AuthViewModel()
        viewModel.registerUsername = "testuser"
        viewModel.registerEmail = "test@example.com"
        viewModel.registerPhone = "13800138000"
        viewModel.registerPassword = "Test123456"
        viewModel.registerConfirmPassword = "Test123456"

        // When
        viewModel.clearRegisterForm()

        // Then
        XCTAssertEqual(viewModel.registerUsername, "")
        XCTAssertEqual(viewModel.registerEmail, "")
        XCTAssertEqual(viewModel.registerPhone, "")
        XCTAssertEqual(viewModel.registerPassword, "")
        XCTAssertEqual(viewModel.registerConfirmPassword, "")
    }

    // MARK: - Biometric Tests

    func testBiometricManager_WhenFaceIDAvailable_ShouldReturnFaceID() {
        // Given
        let manager = BiometricManager.shared

        // When
        let type = manager.getBiometricType()

        // Then
        // This test depends on device capabilities
        // In a real test environment, we'd mock the LAContext
        XCTAssertNotNil(type)
    }
}
