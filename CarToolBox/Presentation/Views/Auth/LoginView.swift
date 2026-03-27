//
//  LoginView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import SwiftUI
import Combine

struct LoginView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var showPassword = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @FocusState private var focusedField: Field?

    enum Field {
        case identifier
        case password
    }

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Logo and title
                    headerView

                    // Form
                    ScrollView {
                        VStack(spacing: 20) {
                            identifierField
                            passwordField
                            rememberMeSection
                            loginButton
                            additionalLinks
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Biometric login button
                    if viewModel.canUseBiometric && viewModel.isBiometricEnabled {
                        biometricLoginButton
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        viewModel.clearLoginForm()
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("成功", isPresented: $showSuccessAlert) {
                Button("确定") {
                    viewModel.successMessage = nil
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .onReceive(viewModel.$errorMessage.dropFirst()) { errorMessage in
                showErrorAlert = errorMessage != nil
            }
            .onReceive(viewModel.$successMessage.dropFirst()) { successMessage in
                showSuccessAlert = successMessage != nil
            }
            .onChange(of: viewModel.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    // Reset all local state when logged in to allow view transition
                    showRegister = false
                    showForgotPassword = false
                    showErrorAlert = false
                    showSuccessAlert = false
                    // Dismiss the login sheet when login succeeds
                    dismiss()
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("CarToolBox")
                .font(.title)
                .fontWeight(.bold)

            Text("欢迎回来")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }

    // MARK: - Identifier Field

    private var identifierField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("用户名或邮箱")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField("请输入用户名或邮箱", text: $viewModel.loginIdentifier)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .identifier)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .identifier ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Password Field

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("密码")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showPassword {
                    TextField("请输入密码", text: $viewModel.loginPassword)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("请输入密码", text: $viewModel.loginPassword)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                }

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .password ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Remember Me

    private var rememberMeSection: some View {
        HStack {
            Button(action: { viewModel.rememberMe.toggle() }) {
                Image(systemName: viewModel.rememberMe ? "checkmark.square.fill" : "square")
                    .foregroundColor(viewModel.rememberMe ? .blue : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())

            Text("记住我")
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: { showForgotPassword = true }) {
                Text("忘记密码?")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button(action: {
            focusedField = nil
            viewModel.login()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text("登录")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isLoginValid ? Color.blue : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isLoginValid || viewModel.isLoading)
    }

    // MARK: - Additional Links

    private var additionalLinks: some View {
        VStack(spacing: 16) {
            Divider()

            HStack {
                Text("还没有账号?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: { showRegister = true }) {
                    Text("立即注册")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("或使用")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("手机验证码登录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    // Navigate to SMS login (could add separate view)
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("短信登录")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Biometric Login Button

    private var biometricLoginButton: some View {
        Button(action: { viewModel.loginWithBiometric() }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.biometricIconName)
                    .font(.title)
                Text(viewModel.biometricType.localizedDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(25)
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Preview

#Preview {
    LoginView(viewModel: AuthViewModel())
}
