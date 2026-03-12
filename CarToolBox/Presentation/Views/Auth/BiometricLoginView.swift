//
//  BiometricLoginView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/9.
//

import SwiftUI
import Combine

struct BiometricLoginView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss: DismissAction
    @State private var showPasswordLogin = false
    @State private var showErrorAlert = false

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Header with biometric icon
                    headerView

                    // User info
                    if !viewModel.currentUser.username.isEmpty {
                        userInfoView
                    }

                    // Biometric button
                    biometricButton
                        .padding(.horizontal, 40)

                    // Fallback options
                    fallbackOptions

                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
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
            .sheet(isPresented: $showPasswordLogin) {
                LoginView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 20) {
            // Biometric icon with animation
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: viewModel.biometricIconName)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

            Text("生物识别登录")
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    // MARK: - User Info

    private var userInfoView: some View {
        VStack(spacing: 8) {
            Text("欢迎回来，")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(viewModel.currentUser.username)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Biometric Button

    private var biometricButton: some View {
        Button(action: {
            viewModel.loginWithBiometric()
        }) {
            HStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: viewModel.biometricIconName)
                        .font(.title2)
                }

                Text(biometricButtonText)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
    }

    private var biometricButtonText: String {
        switch viewModel.biometricType {
        case .faceID:
            return "使用 Face ID 登录"
        case .touchID:
            return "使用 Touch ID 登录"
        case .none:
            return "登录"
        }
    }

    // MARK: - Fallback Options

    private var fallbackOptions: some View {
        VStack(spacing: 16) {
            // Password login
            Button(action: {
                showPasswordLogin = true
            }) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.secondary)
                    Text("使用密码登录")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }

            // Help text
            VStack(spacing: 8) {
                Text("如遇到问题，请尝试:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    helpItem("使用密码登录")
                    Divider()
                        .frame(height: 20)
                    helpItem("重启应用")
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private func helpItem(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.blue)
    }
}

// MARK: - Biometric Quick Login Button

struct BiometricQuickLoginButton: View {
    let username: String?
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.title3)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("快速登录")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let username = username {
                        Text(username)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(isPressed ? 0.5 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Face ID") {
    let vm = AuthViewModel()
    vm.currentUser.username = "测试用户"
    return BiometricLoginView(viewModel: vm)
}

#Preview("Touch ID") {
    let vm = AuthViewModel()
    return BiometricLoginView(viewModel: vm)
}

#Preview("Quick Login Button") {
    VStack(spacing: 20) {
        BiometricQuickLoginButton(username: "test@example.com", onTap: {})
        BiometricQuickLoginButton(username: nil, onTap: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Status Indicator") {
    VStack(spacing: 12) {
        BiometricStatusIndicator(isEnabled: true, type: BiometricManager.BiometricType.faceID)
        BiometricStatusIndicator(isEnabled: true, type: BiometricManager.BiometricType.touchID)
        BiometricStatusIndicator(isEnabled: false, type: BiometricManager.BiometricType.none)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
