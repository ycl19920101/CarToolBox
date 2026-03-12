//
//  AppCoordinator.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import UIKit
import SwiftUI

// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController? { get set }
    var childCoordinators: [Coordinator] { get set }
    var parentCoordinator: Coordinator? { get set }

    func start()
    func stop()
    func childDidFinish(_ child: Coordinator)
}

extension Coordinator {
    func childDidFinish(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }
}

// MARK: - App Coordinator

class AppCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    // Shared auth view model
    let authViewModel = AuthViewModel()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        // Check if user is authenticated
        if authViewModel.isLoggedIn {
            showMainApp()
        } else {
            showAuthFlow()
        }
    }

    func stop() {
        childCoordinators.removeAll()
    }

    // MARK: - Navigation

    private func showMainApp() {
        let homeCoordinator = HomeCoordinator(
            navigationController: navigationController!,
            authViewModel: authViewModel
        )
        homeCoordinator.parentCoordinator = self
        childCoordinators.append(homeCoordinator)
        homeCoordinator.start()
    }

    private func showAuthFlow() {
        let authCoordinator = AuthCoordinator(
            navigationController: navigationController!,
            authViewModel: authViewModel,
            onAuthSuccess: { [weak self] in
                self?.authCoordinatorDidFinish()
            }
        )
        authCoordinator.parentCoordinator = self
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
    }

    private func authCoordinatorDidFinish() {
        showMainApp()
    }

    // MARK: - Auth State Changes

    func handleAuthStateChange() {
        if authViewModel.isLoggedIn {
            showMainApp()
        } else {
            showAuthFlow()
        }
    }

    // MARK: - Public Methods

    func showLogin() {
        let loginCoordinator = LoginCoordinator(
            navigationController: navigationController!,
            authViewModel: authViewModel
        )
        loginCoordinator.parentCoordinator = self
        childCoordinators.append(loginCoordinator)
        loginCoordinator.start()
    }

    func showRegister() {
        let registerCoordinator = RegisterCoordinator(
            navigationController: navigationController!,
            authViewModel: authViewModel
        )
        registerCoordinator.parentCoordinator = self
        childCoordinators.append(registerCoordinator)
        registerCoordinator.start()
    }
}

// MARK: - Auth Coordinator

class AuthCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let authViewModel: AuthViewModel
    private let onAuthSuccess: () -> Void

    init(
        navigationController: UINavigationController,
        authViewModel: AuthViewModel,
        onAuthSuccess: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.authViewModel = authViewModel
        self.onAuthSuccess = onAuthSuccess
    }

    func start() {
        showLogin()
    }

    func stop() {
        childCoordinators.removeAll()
    }

    private func showLogin() {
        let loginView = LoginView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: loginView)
        navigationController?.setViewControllers([hostingController], animated: false)
    }

    func showRegister() {
        let registerView = RegisterView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: registerView)
        navigationController?.pushViewController(hostingController, animated: true)
    }

    func showForgotPassword() {
        let forgotPasswordView = ForgotPasswordView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: forgotPasswordView)
        navigationController?.pushViewController(hostingController, animated: true)
    }

    func showBiometricLogin() {
        let biometricLoginView = BiometricLoginView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: biometricLoginView)
        navigationController?.setViewControllers([hostingController], animated: false)
    }
}

// MARK: - Login Coordinator

class LoginCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let authViewModel: AuthViewModel

    init(navigationController: UINavigationController, authViewModel: AuthViewModel) {
        self.navigationController = navigationController
        self.authViewModel = authViewModel
    }

    func start() {
        let loginView = LoginView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: loginView)
        navigationController?.present(hostingController, animated: true)
    }

    func stop() {
        navigationController?.dismiss(animated: true)
        childCoordinators.removeAll()
    }
}

// MARK: - Register Coordinator

class RegisterCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let authViewModel: AuthViewModel

    init(navigationController: UINavigationController, authViewModel: AuthViewModel) {
        self.navigationController = navigationController
        self.authViewModel = authViewModel
    }

    func start() {
        let registerView = RegisterView(viewModel: authViewModel)
        let hostingController = UIHostingController(rootView: registerView)
        navigationController?.present(hostingController, animated: true)
    }

    func stop() {
        navigationController?.dismiss(animated: true)
        childCoordinators.removeAll()
    }
}

// MARK: - Home Coordinator

class HomeCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let authViewModel: AuthViewModel

    init(navigationController: UINavigationController, authViewModel: AuthViewModel) {
        self.navigationController = navigationController
        self.authViewModel = authViewModel
    }

    func start() {
        let tabBarView = TabBarView(authViewModel: authViewModel)
        let hostingController = UIHostingController(rootView: tabBarView)
        navigationController?.setViewControllers([hostingController], animated: false)
    }

    func stop() {
        childCoordinators.removeAll()
    }

    // MARK: - Navigation Helpers

    func showVehicleDetail(vehicleId: String) {
        // TODO: Implement vehicle detail navigation
    }

    func showCreatePost() {
        // TODO: Implement create post navigation
    }

    func showPostDetail(postId: String) {
        // TODO: Implement post detail navigation
    }
}
