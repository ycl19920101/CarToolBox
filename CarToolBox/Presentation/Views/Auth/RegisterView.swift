//
//  RegisterView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import SwiftUI
import Combine

struct RegisterView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss: DismissAction
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false

    enum Field {
        case username
        case email
        case phone
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
                            usernameField
                            emailField
                            phoneField
                            passwordField
                            confirmPasswordField

                            // Password strength indicator
                            passwordStrengthIndicator

                            registerButton
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Terms and privacy
                    termsSection
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("注册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.clearRegisterForm()
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
            .alert("成功", isPresented: $showSuccessAlert) {
                Button("确定") {
                    viewModel.successMessage = nil
                    dismiss()
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
                    // Dismiss when registration succeeds and user is logged in
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("创建账号")
                .font(.title2)
                .fontWeight(.bold)

            Text("开始使用 CarToolBox")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Username Field

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("用户名 *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField("请输入用户名", text: $viewModel.registerUsername)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .username)
                    .onSubmit {
                        focusedField = .email
                    }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .username ? Color.blue : Color.clear, lineWidth: 1.5)
            )

            if !viewModel.registerUsername.isEmpty && viewModel.registerUsername.count < 3 {
                Text("用户名至少需要3个字符")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Email Field

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("邮箱")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField("请输入邮箱（可选）", text: $viewModel.registerEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .phone
                    }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .email ? Color.blue : Color.clear, lineWidth: 1.5)
            )

            if !viewModel.registerEmail.isEmpty && !EmailValidator.isValid(viewModel.registerEmail) {
                Text("请输入有效的邮箱地址")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Phone Field

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("手机号")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("(二选一)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "iphone")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TextField("请输入手机号（可选）", text: $viewModel.registerPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phone)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .phone ? Color.blue : Color.clear, lineWidth: 1.5)
            )

            if !viewModel.registerPhone.isEmpty && !PhoneValidator.isValid(viewModel.registerPhone) {
                Text("请输入有效的手机号")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Password Field

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("密码 *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showPassword {
                    TextField("请输入密码（至少8位）", text: $viewModel.registerPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("请输入密码（至少8位）", text: $viewModel.registerPassword)
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
    }

    // MARK: - Confirm Password Field

    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("确认密码 *")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showConfirmPassword {
                    TextField("请再次输入密码", text: $viewModel.registerConfirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                } else {
                    SecureField("请再次输入密码", text: $viewModel.registerConfirmPassword)
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

            if !viewModel.registerConfirmPassword.isEmpty && viewModel.registerConfirmPassword != viewModel.registerPassword {
                Text("两次输入的密码不一致")
                    .font(.caption)
                    .foregroundColor(.red)
            }
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

            Text(viewModel.passwordStrength.level)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(strengthColor(for: 2))
        }
    }

    private func strengthColor(for index: Int) -> Color {
        let score = viewModel.passwordStrength.score
        if score >= 5 {
            return .green
        } else if score >= 3 {
            return .orange
        } else if index < score {
            return .red
        }
        return .gray.opacity(0.3)
    }

    // MARK: - Register Button

    private var registerButton: some View {
        Button(action: {
            focusedField = nil
            viewModel.register()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text("注册")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isRegisterValid ? Color.blue : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isRegisterValid || viewModel.isLoading)
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("注册即表示您同意")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("服务条款") {
                    // TODO: Show terms
                }
                .font(.caption)
                .foregroundColor(.blue)

                Text("和")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("隐私政策")
                {
                    // TODO: Show privacy policy
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegisterView(viewModel: AuthViewModel())
}
