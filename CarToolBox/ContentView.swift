//
//  ContentView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading {
                // Loading state while checking auth
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                }
            } else if authViewModel.isLoggedIn {
                TabBarView(authViewModel: authViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.authState)
    }
}
