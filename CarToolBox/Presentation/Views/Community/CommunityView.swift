//
//  CommunityView.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import SwiftUI

struct CommunityView: View {
    var body: some View {
        NavigationView {
            PostListView()
                .navigationTitle("社区")
        }
    }
}

#Preview {
    CommunityView()
}
