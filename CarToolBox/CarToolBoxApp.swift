//
//  CarToolBoxApp.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI
import CoreData

@main
struct CarToolBoxApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            TabBarView(authViewModel: authViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
