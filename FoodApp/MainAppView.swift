//
//  MainAppView.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//

import SwiftUI

struct MainAppView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Oluştur", systemImage: "sparkles")
                }

            RecipeBookView()
                .tabItem {
                    Label("Şefin Kitabı",systemImage: "fork.knife")
                }

            UserRecipesListView()
                .tabItem {
                    Label("Tüm Tarifler", systemImage: "globe")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .tint(AppColor.primary)
    }
}

#Preview {
    MainAppView()
}
