//
//  AuthView.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//

import SwiftUI
import Supabase

struct AuthView: View {
    let supabase = FoodApp.supabase

    // Redirect URL: Supabase Authentication ayarlarınıza eklediğiniz URL’yi girin.
    private let passwordResetRedirectURL = URL(string: "foodapp://auth-reset")!

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var authError: Error?
    @State private var isSigningUp = false

    // Yeni: Şifre sıfırlama sayfası için sheet kontrolü
    @State private var isPresentingResetSheet = false

    // Yeni: Kayıt ol başarı mesajı
    @State private var signupSuccessMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan: yumuşak gradient
                LinearGradient(
                    colors: [
                        AppColor.primary.opacity(0.10),
                        AppColor.primaryMuted,
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Üst başlık alanı
                        VStack(spacing: 10) {
                            Text(isSigningUp ? "Lezzet Yolculuğuna Katıl" : "Lezzete Giriş Yap")
                                .font(AppFont.display())
                                .multilineTextAlignment(.center)

                            Text(isSigningUp
                                 ? "Favori tariflerini kaydet, paylaş ve ilham al. 👩🏻‍🍳🍝"
                                 : "En sevdiğin tariflere ulaş, yeni tatlar keşfet. 🍲✨")
                                .font(AppFont.body())
                                .foregroundStyle(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 32)

                        // Orta alan: kart form
                        Card {
                            VStack(spacing: 14) {
                                // E-posta alanı
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("E-posta")
                                        .font(AppFont.footnote())
                                        .foregroundStyle(AppColor.textSecondary)

                                    HStack(spacing: 10) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundStyle(AppColor.primary)
                                        TextField("email@ornek.com", text: $email)
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            .autocorrectionDisabled(true)
                                    }
                                    .padding(12)
                                    .background(AppColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                // Şifre alanı
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Şifre")
                                        .font(AppFont.footnote())
                                        .foregroundStyle(AppColor.textSecondary)

                                    HStack(spacing: 10) {
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(AppColor.primary)
                                        SecureField("••••••••", text: $password)
                                    }
                                    .padding(12)
                                    .background(AppColor.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                if let authError {
                                    Text(authError.localizedDescription)
                                        .font(AppFont.footnote())
                                        .foregroundStyle(.red)
                                        .padding(.top, 2)
                                }

                                // Ana aksiyon butonu
                                Button {
                                    Task { await authenticate() }
                                } label: {
                                    HStack(spacing: 8) {
                                        if isLoading { ProgressView().tint(.white) }
                                        Text(isSigningUp ? "Kayıt Ol" : "Giriş Yap")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isLoading || email.isEmpty || password.isEmpty)
                                .padding(.top, 6)

                                // Şifremi unuttum (yalnızca giriş modunda)
                                if !isSigningUp {
                                    Button {
                                        isPresentingResetSheet = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "key.fill")
                                            Text("Şifremi Unuttum")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                }

                                // Mod değiştir
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        isSigningUp.toggle()
                                        authError = nil
                                    }
                                } label: {
                                    Text(isSigningUp
                                         ? "Hesabın var mı? Giriş Yap"
                                         : "Hesabın yok mu? Kayıt Ol")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .padding(.top, 4)
                            }
                        }
                        .cardPadding()

                        // Alt dekoratif bölüm
                        HStack(spacing: 8) {
                            Pill("Yemek", systemImage: "fork.knife")
                            Pill("Yapay Zeka Şefi", systemImage: "brain.fill")
                            Pill("Hızlı Tarifler", systemImage: "bolt.fill")
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(isSigningUp ? "Hesap Oluştur" : "Giriş Yap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingResetSheet) {
                NavigationStack {
                    ResetPasswordView(
                        supabase: supabase,
                        defaultEmail: email,
                        redirectURL: passwordResetRedirectURL
                    )
                    .navigationTitle("Şifre Sıfırla")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Kapat") { isPresentingResetSheet = false }
                        }
                    }
                }
            }
            .alert("Hoş geldiniz 👋", isPresented: .constant(signupSuccessMessage != nil)) {
                Button("Tamam") { signupSuccessMessage = nil }
            } message: {
                Text(signupSuccessMessage ?? "")
            }
            .dismissKeyboardOnTap()
        }
    }

    // Giriş/Kayıt
    func authenticate() async {
        await MainActor.run { isLoading = true; authError = nil }
        defer { Task { await MainActor.run { isLoading = false } } }

        do {
            if isSigningUp {
                _ = try await supabase.auth.signUp(email: email, password: password)
                await MainActor.run {
                    signupSuccessMessage = "Kayıt işlemi başarılı! E-postanı doğruladıktan sonra giriş yapabilirsin."
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                _ = try await supabase.auth.signIn(email: email, password: password)
            }
            _ = try? await supabase.auth.session
        } catch {
            await MainActor.run { authError = error }
        }
    }
}

// MARK: - Reset Password View

private struct ResetPasswordView: View {
    let supabase: SupabaseClient
    let defaultEmail: String
    let redirectURL: URL

    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isSending = false
    @State private var message: String?
    @State private var isSuccess = false

    // Basit debounce koruması
    @State private var lastSendAt: Date?

    var body: some View {
        VStack(spacing: 14) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("E‑posta adresinizi girin. Bu adrese şifre sıfırlama bağlantısı gönderilecektir.")
                        .font(AppFont.footnote())
                        .foregroundStyle(AppColor.textSecondary)

                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(AppColor.primary)
                        TextField("email@ornek.com", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)
                    }
                    .padding(12)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let message {
                        Text(message)
                            .font(AppFont.footnote())
                            .foregroundStyle(isSuccess ? .green : .red)
                            .padding(.top, 4)
                    }

                    Button {
                        Task { await sendReset() }
                    } label: {
                        HStack {
                            if isSending { ProgressView().tint(.white) }
                            Text("Bağlantıyı Gönder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSending || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .cardPadding()

            Spacer()
        }
        .onAppear {
            self.email = defaultEmail
        }
        .background(AppColor.background)
        .toolbar {
            if isSuccess {
                ToolbarItem(placement: .bottomBar) {
                    Button("Kapat") { dismiss() }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .dismissKeyboardOnTap()
    }

    private func sendReset() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Çok hızlı çift tıklamayı engelle
        if let last = lastSendAt, Date().timeIntervalSince(last) < 1.0 {
            return
        }
        lastSendAt = Date()

        await MainActor.run {
            isSending = true
            message = nil
            isSuccess = false
        }
        do {
            try await supabase.auth.resetPasswordForEmail(trimmed, redirectTo: redirectURL)
            await MainActor.run {
                isSuccess = true
                message = "Şifre yenileme bağlantısı \(trimmed) adresine gönderildi. Lütfen e‑postanızı kontrol edin."
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                isSuccess = false
                message = "Hata: \(error.localizedDescription)"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        await MainActor.run { isSending = false }
    }
}

#Preview {
    AuthView()
}

