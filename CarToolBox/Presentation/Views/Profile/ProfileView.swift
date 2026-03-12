//
//  ProfileView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var showChangePassword = false
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if authViewModel.isLoggedIn {
                            authenticatedProfile
                        } else {
                            unauthenticatedView
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("个人中心")
            .sheet(isPresented: $showLogin) {
                LoginView(viewModel: authViewModel)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(viewModel: authViewModel)
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(viewModel: authViewModel)
            }
        }
    }

    // MARK: - Authenticated Profile

    private var authenticatedProfile: some View {
        VStack(spacing: 20) {
            // User header
            userHeaderView
                .padding(.top, 20)

            // Stats
            statsView
                .padding(.horizontal)

            // Settings sections
            accountSettings
            securitySettings
            aboutSettings
        }
    }

    private var userHeaderView: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)

                if let avatarURL = authViewModel.currentUser.avatar, !avatarURL.isEmpty {
                    AsyncImage(url: URL(string: avatarURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
            }

            // User info
            VStack(spacing: 4) {
                Text(authViewModel.currentUser.username)
                    .font(.title2)
                    .fontWeight(.bold)

                if !authViewModel.currentUser.email.isEmpty {
                    Text(authViewModel.currentUser.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Status badges
            HStack(spacing: 8) {
                BiometricStatusIndicator(
                    isEnabled: authViewModel.isBiometricEnabled,
                    type: authViewModel.biometricType
                )

                if authViewModel.rememberMe {
                    statusBadge("已记住", icon: "checkmark.circle.fill", color: .green)
                }
            }
        }
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            statItem(icon: "car.fill", title: "车辆", value: "1")
            statItem(icon: "map.fill", title: "里程", value: "12.5k")
            statItem(icon: "battery.100", title: "电量", value: "85%")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var accountSettings: some View {
        VStack(spacing: 0) {
            sectionHeader("账号设置")

            settingRow(icon: "person.crop.circle", title: "编辑资料") {
                isEditing.toggle()
            }

            Divider()
                .padding(.leading, 52)

            settingRow(icon: "key.fill", title: "修改密码") {
                showChangePassword = true
            }

            Divider()
                .padding(.leading, 52)

            settingRow(icon: "bell.fill", title: "通知设置") {
                // TODO: Implement notification settings
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var securitySettings: some View {
        VStack(spacing: 0) {
            sectionHeader("安全设置")

            settingRow(
                icon: authViewModel.biometricIconName,
                title: "生物识别登录",
                showToggle: true,
                isToggleOn: authViewModel.isBiometricEnabled
            ) {
                authViewModel.toggleBiometric()
            }

            if authViewModel.isBiometricEnabled {
                Divider()
                    .padding(.leading, 52)

                settingRow(icon: "faceid", title: "测试生物识别") {
                    // Test biometric
                }
            }

            Divider()
                .padding(.leading, 52)

            settingRow(icon: "checkmark.circle.fill", title: "记住我", showToggle: true, isToggleOn: authViewModel.rememberMe) {
                authViewModel.rememberMe.toggle()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var aboutSettings: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                sectionHeader("关于")

                settingRow(icon: "info.circle", title: "版本", value: "1.0.0")

                Divider()
                    .padding(.leading, 52)

                settingRow(icon: "doc.text", title: "使用条款") {
                    // TODO: Show terms
                }

                Divider()
                    .padding(.leading, 52)

                settingRow(icon: "hand.raised", title: "隐私政策") {
                    // TODO: Show privacy policy
                }

                Divider()
                    .padding(.leading, 52)

                settingRow(icon: "questionmark.circle", title: "帮助与反馈") {
                    // TODO: Show help
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)

            logoutButton
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
        }
    }

    private func settingRow(
        icon: String,
        title: String,
        value: String? = nil,
        showToggle: Bool = false,
        isToggleOn: Bool = false,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                if showToggle {
                    Toggle("", isOn: .constant(isToggleOn))
                        .labelsHidden()
                } else if let value = value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func statusBadge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }

    private var logoutButton: some View {
        Button(action: {
            authViewModel.logout()
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("退出登录")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Unauthenticated View

    private var unauthenticatedView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("CarToolBox")
                    .font(.title)
                    .fontWeight(.bold)

                Text("登录以体验完整功能")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Buttons
            VStack(spacing: 16) {
                Button(action: { showLogin = true }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: { showRegister = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("注册")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Features preview
            featuresPreview
        }
        .padding(.vertical, 40)
    }

    private var featuresPreview: some View {
        VStack(spacing: 16) {
            Text("CarToolBox 提供的功能")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                featureItem(icon: "car.fill", title: "车辆管理")
                featureItem(icon: "lock.fill", title: "远程控制")
                featureItem(icon: "bolt.fill", title: "电量监控")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func featureItem(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Biometric Status Indicator

struct BiometricStatusIndicator: View {
    let isEnabled: Bool
    let type: BiometricManager.BiometricType

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isEnabled ? type.iconName : "lock.slash")
                .foregroundColor(isEnabled ? .green : .secondary)
                .font(.caption)

            Text(isEnabled ? type.localizedDescription : "未启用")
                .font(.caption)
                .foregroundColor(isEnabled ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isEnabled ? Color.green : Color.secondary).opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    let vm = AuthViewModel()
    vm.currentUser = UserModel(from: UserDTO(
        id: "1",
        username: "测试用户",
        email: "test@example.com",
        phone: "13800138000",
        avatar: nil,
        created_at: nil,
        updated_at: nil,
        last_login_at: nil
    ))
    return ProfileView(authViewModel: vm)
}

#Preview("Unauthenticated") {
    ProfileView(authViewModel: AuthViewModel())
}
