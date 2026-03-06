//
//  AuthManager.swift
//  FoodApp
//
//  Created by Emircan Özer on 25.10.2025.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    private let supabase: SupabaseClient
    @Published private(set) var session: Session?

    // Listener görevi bir Task olarak tutulur ki AuthManager yaşam süresince aktif kalsın.
    private var authListenerTask: Task<Void, Never>?

    init(supabase: SupabaseClient = FoodApp.supabase) {
        self.supabase = supabase

        // Başlangıçta mevcut session’ı yükle ve auth değişimlerini dinle
        authListenerTask = Task {
            // 1) İlk session’ı çek
            let current = try? await supabase.auth.session
            await MainActor.run { self.session = current }

            // 2) Auth değişimlerini dinle (AsyncSequence)
            for await (_, newSession) in supabase.auth.authStateChanges {
                await MainActor.run {
                    self.session = newSession
                }
            }
        }
    }

    deinit {
        authListenerTask?.cancel()
    }

    // İsteğe bağlı: Elle tazelemek için
    func refreshSession() async {
        let current = try? await supabase.auth.session
        self.session = current
    }

    // İsteğe bağlı: Auth sarmalayıcıları (UI basitleştirme için)
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
        // Session değişimi listener ile zaten yansıyacak, yine de güvence için:
        await refreshSession()
    }

    func signUp(email: String, password: String) async throws {
        _ = try await supabase.auth.signUp(email: email, password: password)
        await refreshSession()
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        await refreshSession()
    }
}
