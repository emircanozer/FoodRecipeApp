//
//  FoodAppApp.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//

import SwiftUI
import Supabase

@main
struct FoodApp: App {
    
    // 1. Supabase Kurulumu
    static let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://lnbpezkgrtwmlmxlfxwr.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxuYnBlemtncnR3bWxteGxmeHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzMDUxNDUsImV4cCI6MjA3Njg4MTE0NX0.lvjDJusQnagn1yqFZdPwkuIqjmpXKXnADpSaitzAdJo"
    )
    
    // 2. AuthManager (Senkron başlatılıyor)
    @State private var authManager = AuthManager()
    
    // 3. Animasyon Gösterilsin mi? (Başlangıçta EVET)
    @State private var showLaunchAnimation = true

    // 4. Tema seçimi
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Katman 1: Ana Uygulama (Altta hazır bekliyor)
                MainView()
                    .preferredColorScheme(colorSchemeFromAppTheme())

                // Katman 2: Animasyonlu Açılış Ekranı (Üstte)
                if showLaunchAnimation {
                    AnimatedLaunchView(isShowingLaunchAnimation: $showLaunchAnimation)
                        .transition(.opacity) // Kaybolurken yumuşak geçiş
                        .zIndex(1) // En üstte durmasını sağlar
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showLaunchAnimation) // Geçiş animasyonu
        }
    }

    private func colorSchemeFromAppTheme() -> ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

