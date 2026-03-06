//
//  MainView.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//


// MainView.swift

import SwiftUI
import Supabase

struct MainView: View {
    // Artık AuthManager kullanıyoruz
    @StateObject private var auth = AuthManager()

    // "hasCompletedOnboarding" değişkenini telefondan oku
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if auth.session != nil {
                // Kullanıcı giriş yapmış. Peki tercihleri seçmiş mi?
                if hasCompletedOnboarding {
                    // Evet, seçmiş -> Ana Uygulamayı (Sekmeli) göster
                    MainAppView()
                } else {
                    // Hayır, seçmemiş (yeni kullanıcı) -> Tercih ekranını göster
                    PreferenceView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            } else {
                // Kullanıcı giriş yapmamış
                AuthView()
            }
        }
        // İsteğe bağlı: Uygulama açıldığında bir kez daha tazele
        .task {
            await auth.refreshSession()
        }
    }
}
#Preview {
    MainView()
}

