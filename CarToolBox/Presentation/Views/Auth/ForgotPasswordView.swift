//
//  ForgotPasswordView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss: DismissAction
    @State private var currentStep: Step = .email
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @FocusState private var focusedField: Field?

    enum Step {
        case email
        case reset
    }

    enum Field {
        case email
        case password
        case confirmPassword
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
                    // Header
                    headerView

                    // Form
                    ScrollView {
                        VStack(spacing: 20) {
                            if currentStep == .email {
                                emailStep
                            } else {
                                resetStep
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
            }
            .navigationTitle("找回密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.clearForgotPasswordForm()
                        dismiss()
                    }
                }
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("提示", isPresented: $showSuccessAlert) {
                Button("确定") {
                    viewModel.successMessage = nil
                    if currentStep == .reset {
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .onReceive(viewModel.$errorMessage.dropFirst()) { errorMessage in
                showErrorAlert = errorMessage != nil
            }
            .onReceive(viewModel.$successMessage.dropFirst()) { successMessage in
                if currentStep == .email && successMessage != nil {
                    // Move to next step after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        currentStep = .reset
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: currentStep == .email ? "envelope.circle.fill" : "key.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text(currentStep == .email ? "重置密码" : "设置新密码")
                .font(.title2)
                .fontWeight(.bold)

            Text(currentStep == .email ? "我们将发送重置链接到您的邮箱" : "请设置新的登录密码")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Email Step

    private var emailStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱地址")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("请输入注册邮箱", text: $viewModel.forgotPasswordEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .email)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(focusedField == .email ? Color.blue : Color.clear, lineWidth: 1.5)
                )

                if !viewModel.forgotPasswordEmail.isEmpty && !EmailValidator.isValid(viewModel.forgotPasswordEmail) {
                    Text("请输入有效的邮箱地址")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Button(action: {
                focusedField = nil
                viewModel.forgotPassword()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("发送重置邮件")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isForgotPasswordValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isForgotPasswordValid || viewModel.isLoading)

            infoText("密码重置链接将在15分钟后失效，请及时查收邮件。")
        }
    }

    // MARK: - Reset Step

    private var resetStep: some View {
        VStack(spacing: 20) {
            // Token input (in real app, this would come from email link)
            VStack(alignment: .leading, spacing: 8) {
                Text("重置令牌")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "ticket.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TextField("请输入邮件中的重置令牌", text: $viewModel.resetToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }

            // New password
            VStack(alignment: .leading, spacing: 8) {
                Text("新密码")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    if showPassword {
                        TextField("请输入新密码（至少8位）", text: $viewModel.newPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                    } else {
                        SecureField("请输入新密码（至少8位）", text: $viewModel.newPassword)
                            .textContentType(.newPassword)
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

            // Confirm password
            VStack(alignment: .leading, spacing: 8) {
                Text("确认新密码")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    if showConfirmPassword {
                        TextField("请再次输入新密码", text: $viewModel.confirmNewPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                    } else {
                        SecureField("请再次输入新密码", text: $viewModel.confirmNewPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                    }

                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(focusedField == .confirmPassword ? Color.blue : Color.clear, lineWidth: 1.5)
                )

                if !viewModel.confirmNewPassword.isEmpty && viewModel.confirmNewPassword != viewModel.newPassword {
                    Text("两次输入的密码不一致")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Password strength indicator
            passwordStrengthIndicator

            Button(action: {
                focusedField = nil
                viewModel.resetPassword()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("重置密码")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isResetPasswordValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isResetPasswordValid || viewModel.isLoading)
        }
    }

    // MARK: - Password Strength Indicator

    private var passwordStrengthIndicator: some View {
        HStack(spacing: 8) {
            Text("密码强度:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(strengthColor(for: index))
                    .frame(width: 40, height: 6)
            }

            Text(passwordStrength)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(strengthColor(for: 2))
        }
    }

    private var passwordStrength: String {
        let password = viewModel.newPassword
        let result = PasswordValidator.strength(of: password)
        return result.level
    }

    private func strengthColor(for index: Int) -> Color {
        let password = viewModel.newPassword
        let result = PasswordValidator.strength(of: password)
        if result.score >= 5 {
            return .green
        } else if result.score >= 3 {
            return .orange
        } else if index < result.score {
            return .red
        }
        return .gray.opacity(0.3)
    }

    // MARK: - Info Text

    private func infoText(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView(viewModel: AuthViewModel())
}
