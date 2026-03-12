//
//  TabBarView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

@MainActor
struct TabBarView: View {
    @State private var selectedTab = 0
    @ObservedObject var authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)

            VehicleView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("车辆")
                }
                .tag(1)

            CommunityView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("社区")
                }
                .tag(2)

            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    TabBarView(authViewModel: AuthViewModel())
}