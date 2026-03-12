//
//  ChangePasswordView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import SwiftUI
import Combine

struct ChangePasswordView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var showSuccess = false
    @State private var showErrorAlert = false
    @FocusState private var focusedField: Field?

    enum Field {
        case currentPassword
        case newPassword
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
                            currentPasswordField
                            newPasswordField
                            confirmPasswordField

                            // Password strength indicator
                            passwordStrengthIndicator

                            saveButton
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
            }
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.clearChangePasswordForm()
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
            .onReceive(viewModel.$errorMessage.dropFirst()) { errorMessage in
                showErrorAlert = errorMessage != nil
            }
            .onReceive(viewModel.$successMessage.dropFirst()) { successMessage in
                if successMessage != nil {
                    showSuccess = true
                }
            }
            .alert("成功", isPresented: $showSuccess) {
                Button("确定") {
                    viewModel.clearChangePasswordForm()
                    dismiss()
                }
            } message: {
                Text("密码修改成功")
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("修改密码")
                .font(.title2)
                .fontWeight(.bold)

            Text("为了账号安全，请定期更换密码")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Current Password Field

    private var currentPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前密码")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showCurrentPassword {
                    TextField("请输入当前密码", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .focused($focusedField, equals: .currentPassword)
                } else {
                    SecureField("请输入当前密码", text: $viewModel.currentPassword)
                        .textContentType(.password)
                        .focused($focusedField, equals: .currentPassword)
                }

                Button(action: { showCurrentPassword.toggle() }) {
                    Image(systemName: showCurrentPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .currentPassword ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - New Password Field

    private var newPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("新密码")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showNewPassword {
                    TextField("请输入新密码（至少8位）", text: $viewModel.changeNewPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .newPassword)
                } else {
                    SecureField("请输入新密码（至少8位）", text: $viewModel.changeNewPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .newPassword)
                }

                Button(action: { showNewPassword.toggle() }) {
                    Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == .newPassword ? Color.blue : Color.clear, lineWidth: 1.5)
            )

            if !viewModel.changeNewPassword.isEmpty && viewModel.changeNewPassword.count < 8 {
                Text("密码至少需要8个字符")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if !viewModel.changeNewPassword.isEmpty &&
               viewModel.changeNewPassword == viewModel.currentPassword {
                Text("新密码不能与当前密码相同")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Confirm Password Field

    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("确认新密码")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                if showConfirmPassword {
                    TextField("请再次输入新密码", text: $viewModel.confirmChangePassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                } else {
                    SecureField("请再次输入新密码", text: $viewModel.confirmChangePassword)
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

            if !viewModel.confirmChangePassword.isEmpty && viewModel.confirmChangePassword != viewModel.changeNewPassword {
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

            Text(passwordStrength)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(strengthColor(for: 2))
        }
    }

    private var passwordStrength: String {
        let result = PasswordValidator.strength(of: viewModel.changeNewPassword)
        return result.level
    }

    private func strengthColor(for index: Int) -> Color {
        let result = PasswordValidator.strength(of: viewModel.changeNewPassword)
        if result.score >= 5 {
            return .green
        } else if result.score >= 3 {
            return .orange
        } else if index < result.score {
            return .red
        }
        return .gray.opacity(0.3)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                focusedField = nil
                viewModel.changePassword()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("保存")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isChangePasswordValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isChangePasswordValid || viewModel.isLoading)

            if !viewModel.isChangePasswordValid {
                validationHints
            }
        }
    }

    // MARK: - Validation Hints

    private var validationHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("密码要求:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Image(systemName: viewModel.changeNewPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.changeNewPassword.count >= 8 ? .green : .secondary)
                Text("至少8个字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Image(systemName: viewModel.confirmChangePassword == viewModel.changeNewPassword ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.confirmChangePassword == viewModel.changeNewPassword ? .green : .secondary)
                Text("两次输入一致")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Image(systemName: viewModel.changeNewPassword != viewModel.currentPassword ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.changeNewPassword != viewModel.currentPassword ? .green : .secondary)
                Text("与当前密码不同")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ChangePasswordView(viewModel: AuthViewModel())
}
