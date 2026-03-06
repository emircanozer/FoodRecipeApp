// ProfileView.swift

import SwiftUI
import Supabase
import PhotosUI

struct ProfileView: View {

    let supabase = FoodApp.supabase
    @State private var userEmail: String?
    @State private var currentUserId: String? // kullanıcıya özel anahtar için
    @State private var showingPreferences = false
    @State private var signOutError: Error?
    @State private var isSigningOut = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // Tercih özeti
    @AppStorage("isVegetarian") private var isVegetarian: Bool = false
    @AppStorage("isVegan") private var isVegan: Bool = false
    @AppStorage("isGlutenFree") private var isGlutenFree: Bool = false
    @AppStorage("prepTime") private var prepTime: Int = 30
    @AppStorage("dislikedIngredients") private var dislikedIngredients: String = ""
    @AppStorage("skillLevel") private var skillLevel: String = "Orta"

    // Theme
    @AppStorage("appTheme") private var appTheme: String = "system" // "light" | "dark" | "system"

    // Navigation to RecipeBook
    @State private var goToRecipeBook = false

    // Rating UI state
    @State private var showingRating = false
    @State private var selectedRating: Int? = nil
    @State private var showThanksAlert = false

    // Profil resmi (kullanıcıya özel, UserDefaults)
    @State private var profileImageData: Data?
    @State private var showingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?

    // Şifre değiştir
    @State private var showingChangePassword = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isUpdatingPassword = false
    @State private var passwordUpdateMessage: String?

    // Hesabı kapat (geçici: logout + bilgilendirme)
    @State private var showingCloseAccountConfirm = false
    @State private var closeAccountInfoAlert = false

    // Profil resmi büyütme
    @State private var isShowingProfileImageFullscreen = false
    @Namespace private var profileImageNamespace

    var body: some View {
        NavigationStack {
            let headerImage = profileUIImage()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard(headerImage: headerImage)
                    preferencesCard()
                    quickActionsCard()
                    accountCard()
                    themeCard()
                    aboutCard()
                }
                .padding(.vertical, 12)
            }
            .background(AppColor.background)
            .navigationTitle("Profiliniz 👨‍🍳")
            .sheet(isPresented: $showingPreferences) {
                NavigationStack {
                    PreferenceView(hasCompletedOnboarding: .constant(true))
                        .navigationTitle("Tercihler")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Bitti") { showingPreferences = false }
                                    .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                }
            }
            .sheet(isPresented: $showingRating) {
                RatingSheet(
                    selectedRating: $selectedRating,
                    onRated: {
                        showingRating = false
                        showThanksAlert = true
                    }
                )
                .presentationDetents([.height(220)])
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItem, matching: .images)
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordSheet(
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isUpdating: $isUpdatingPassword,
                    message: $passwordUpdateMessage,
                    onSubmit: { Task { await changePassword() } }
                )
                .presentationDetents([.height(300)])
            }
            .alert("Teşekkürler!", isPresented: $showThanksAlert) {
                Button("Kapat", role: .cancel) { }
            } message: {
                Text("Değerlendirmeniz için teşekkürler!")
            }
            .alert("Hesabı Kapat", isPresented: $showingCloseAccountConfirm) {
                Button("İptal", role: .cancel) { }
                Button("Kapat", role: .destructive) {
                    Task { await closeAccountFallback() }
                }
            } message: {
                Text("Hesabı kapatmak mevcut oturumunuzu sonlandırır. Kalıcı silme için destekle iletişime geçiniz.")
            }
            .alert("Bilgi", isPresented: $closeAccountInfoAlert) {
                Button("Tamam") { }
            } message: {
                Text("Oturum kapatıldı. Kalıcı hesap silme için destek ile iletişime geçin.")
            }
            .onAppear {
                Task { await refreshAuthAndLoadProfileAssets() }
            }
            .onChange(of: photoPickerItem) { item in
                Task { await handlePhotoPickerChange(item) }
            }
            .overlay(fullscreenProfileOverlay(headerImage: headerImage))
        }
    }

    // MARK: - Section builders

    private func headerCard(headerImage: UIImage?) -> some View {
        Card {
            ProfileHeaderView(
                email: userEmail,
                title: "Bilgileriniz",
                subtitle: "Hesabınızı ve tercihlerinizi yönetin.",
                profileImage: headerImage,
                isShowingFullscreen: $isShowingProfileImageFullscreen,
                namespace: profileImageNamespace
            )
        }
        .cardPadding()
    }

    private func preferencesCard() -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Tercih Özeti", systemImage: "list.bullet.rectangle")
                        .font(AppFont.title())
                    Spacer()
                    if hasCompletedOnboarding {
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text("Tamam")
                                        .font(AppFont.footnote())
                                        .foregroundStyle(.green)
                                }.padding(.horizontal, 8)
                            )
                            .frame(height: 24)
                    } else {
                        Capsule()
                            .fill(Color.orange.opacity(0.2))
                            .overlay(
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Eksik")
                                        .font(AppFont.footnote())
                                        .foregroundStyle(.orange)
                                }.padding(.horizontal, 8)
                            )
                            .frame(height: 24)
                    }
                }

                PreferenceSummaryView(
                    isVegetarian: isVegetarian,
                    isVegan: isVegan,
                    isGlutenFree: isGlutenFree,
                    prepTime: prepTime,
                    dislikedIngredients: dislikedIngredients,
                    skillLevel: skillLevel
                )

                HStack {
                    Button {
                        showingPreferences = true
                    } label: {
                        Text("Tercihlerim")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(isActive: $goToRecipeBook) {
                        RecipeBookView()
                    } label: {
                        EmptyView()
                    }
                    .frame(width: 0, height: 0)
                    .hidden()

                    Button {
                        goToRecipeBook = true
                    } label: {
                        Text("Tarifler")
                        
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingRating = true
                    } label: {
                        Text("Puanla")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 4)
            }
        }
        .cardPadding()
    }

    private func quickActionsCard() -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hızlı Eylemler")
                    .font(AppFont.title())
                QuickActionsGrid(
                    onPickProfilePhoto: { showingPhotoPicker = true },
                    onChangePassword: { showingChangePassword = true },
                    onCloseAccount: { showingCloseAccountConfirm = true }
                )
                // Profil foto silme butonu
                if profileImageData != nil {
                    Button(role: .destructive) {
                        deleteCurrentUserProfileImage()
                    } label: {
                        Label("Profil Resmini Sil", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .tint(AppColor.destructive)
                    .accessibilityLabel("Profil resmini sil")
                }
            }
        }
        .cardPadding()
    }

    private func accountCard() -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hesap")
                    .font(AppFont.title())

                HStack(spacing: 8) {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(AppColor.primary)
                    Text(userEmail ?? "E-posta yükleniyor...")
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                }

                Button(role: .destructive) {
                    Task {
                        await signOut()
                    }
                } label: {
                    HStack {
                        if isSigningOut { ProgressView().tint(.white) }
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(AppFont.button())
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(AppColor.destructive)
                .accessibilityLabel("Çıkış yap")

                if let signOutError {
                    Text("Çıkış yapılırken hata oluştu: \(signOutError.localizedDescription)")
                        .font(AppFont.footnote())
                        .foregroundStyle(.red)
                }
            }
        }
        .cardPadding()
    }

    private func themeCard() -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tema")
                    .font(AppFont.title())
                Picker("Görünüm", selection: $appTheme) {
                    Text("Sistem").tag("system")
                    Text("Açık").tag("light")
                    Text("Koyu").tag("dark")
                }
                .pickerStyle(.segmented)
                Text("Uygulama görünümünü tercihlerinize göre ayarlayın.")
                    .font(AppFont.footnote())
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .cardPadding()
    }

    private func aboutCard() -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hakkında")
                    .font(AppFont.title())

                HStack {
                    Label("Sürüm", systemImage: "number.square")
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Text(appVersionString())
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textSecondary)
                }

                HStack {
                    Label("Gizlilik", systemImage: "lock.shield")
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                    Link("Politika", destination: URL(string: "https://example.com/privacy")!)
                        .font(AppFont.body())
                }
            }
        }
        .cardPadding()
    }

    private func fullscreenProfileOverlay(headerImage: UIImage?) -> some View {
        Group {
            if isShowingProfileImageFullscreen, let image = headerImage {
                FullscreenProfileImageView(
                    image: image,
                    isPresented: $isShowingProfileImageFullscreen,
                    namespace: profileImageNamespace
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
    }

    // MARK: - Helpers

    func profileUIImage() -> UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    func handlePhotoPickerChange(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            await MainActor.run {
                self.profileImageData = data
                saveProfileImageForCurrentUser(data: data)
            }
        }
    }

    func refreshAuthAndLoadProfileAssets() async {
        do {
            let session = try await supabase.auth.session
            let email = session.user.email
            let userId = session.user.id.uuidString
            await MainActor.run {
                self.userEmail = email
                self.currentUserId = userId
                self.profileImageData = loadProfileImageForUser(userId: userId)
            }
        } catch {
            print("Error fetching user session: \(error)")
            await MainActor.run {
                self.userEmail = "E-posta alınamadı"
                self.currentUserId = nil
                self.profileImageData = nil
            }
        }
    }

    func fetchUserEmail() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.userEmail = session.user.email
            } catch {
                print("Error fetching user session: \(error)")
                self.userEmail = "E-posta alınamadı"
            }
        }
    }

    func signOut() async {
        await MainActor.run { isSigningOut = true; signOutError = nil }
        do {
            try await supabase.auth.signOut()
            // Oturum kapandıktan sonra UI temizle
            await MainActor.run {
                self.userEmail = nil
                self.currentUserId = nil
                self.profileImageData = nil
            }
        } catch {
            print("SUPABASE SIGN OUT HATASI: \(error.localizedDescription)")
            await MainActor.run { signOutError = error }
        }
        await MainActor.run { isSigningOut = false }
    }

    func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "v\(version) (\(build))"
    }

    // Şifre değiştirme
    func changePassword() async {
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            await MainActor.run {
                passwordUpdateMessage = "Şifre en az 6 karakter olmalı."
            }
            return
        }
        guard newPassword == confirmPassword else {
            await MainActor.run {
                passwordUpdateMessage = "Şifreler eşleşmiyor."
            }
            return
        }

        await MainActor.run { isUpdatingPassword = true; passwordUpdateMessage = nil }
        do {
            // Updated to match current Supabase Swift API
            _ = try await supabase.auth.update(user: UserAttributes(password: newPassword))
            await MainActor.run {
                passwordUpdateMessage = "Şifre başarıyla güncellendi."
                newPassword = ""
                confirmPassword = ""
            }
        } catch {
            await MainActor.run {
                passwordUpdateMessage = "Şifre güncellenirken hata: \(error.localizedDescription)"
            }
        }
        await MainActor.run { isUpdatingPassword = false }
    }

    // Hesabı kapat (geçici: logout + bilgi)
    func closeAccountFallback() async {
        await signOut()
        await MainActor.run { closeAccountInfoAlert = true }
    }

    // MARK: - UserDefaults (kullanıcıya özel profil resmi)

    private func userDefaultsKey(for userId: String) -> String {
        "profileImageData_\(userId)"
    }

    private func saveProfileImageForCurrentUser(data: Data) {
        guard let userId = currentUserId else { return }
        let key = userDefaultsKey(for: userId)
        UserDefaults.standard.set(data, forKey: key)
    }

    private func loadProfileImageForUser(userId: String) -> Data? {
        let key = userDefaultsKey(for: userId)
        return UserDefaults.standard.data(forKey: key)
    }

    private func deleteCurrentUserProfileImage() {
        guard let userId = currentUserId else { return }
        let key = userDefaultsKey(for: userId)
        UserDefaults.standard.removeObject(forKey: key)
        self.profileImageData = nil
    }
}

// MARK: - Creative Header

private struct ProfileHeaderView: View {
    let email: String?
    let title: String
    let subtitle: String
    let profileImage: UIImage?

    @Binding var isShowingFullscreen: Bool
    var namespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.primary.opacity(0.25), AppColor.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 130)

            HStack(spacing: 12) {
                if let profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(radius: 2)
                        .accessibilityLabel("Profil fotoğrafı")
                        .matchedGeometryEffect(id: "profileImage", in: namespace)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                isShowingFullscreen = true
                            }
                        }
                } else {
                    InitialsAvatar(text: initials(from: email), size: 64)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.titleLarge())
                    Text(email ?? "E-posta yükleniyor…")
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textSecondary)
                    Text(subtitle)
                        .font(AppFont.footnote())
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
            }
            .padding(12)
        }
    }

    private func initials(from email: String?) -> String {
        guard let email, let first = email.first else { return "?" }
        return String(first).uppercased()
    }
}

private struct InitialsAvatar: View {
    let text: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor(for: text))
                .frame(width: size, height: size)
            Text(text)
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Kullanıcı avatarı")
    }

    private func avatarColor(for seed: String) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .pink, .orange, .teal, .indigo]
        let idx = abs(seed.hashValue) % colors.count
        return colors[idx].opacity(0.9)
    }
}

// MARK: - Preference Summary (kısaltılmış rozetler -> tam metin)

private struct PreferenceSummaryView: View {
    let isVegetarian: Bool
    let isVegan: Bool
    let isGlutenFree: Bool
    let prepTime: Int
    let dislikedIngredients: String
    let skillLevel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WrapHStack(spacing: 8, lineSpacing: 8) {
                if isVegetarian { ShortChip(text: "Vejetaryen", fullText: "Vejetaryen", systemImage: "leaf") }
                if isVegan { ShortChip(text: "Vegan", fullText: "Vegan", systemImage: "leaf.circle") }
                if isGlutenFree { ShortChip(text: "Glütensiz", fullText: "Glütensiz", systemImage: "checkmark.circle") }
                ShortChip(text: "Maks. hazırlık: \(prepTime) dk", fullText: "Maksimum hazırlık süresi \(prepTime) dakika", systemImage: "timer")
                ShortChip(text: "Beceri: \(skillLevel)", fullText: "Beceri seviyesi: \(skillLevel)", systemImage: "flame")
                if !dislikedIngredients.trimmingCharacters(in: .whitespaces).isEmpty {
                    ShortChip(text: "Hariç: \(dislikedIngredients)", fullText: "Hariç tutulacak malzemeler: \(dislikedIngredients)", systemImage: "xmark.octagon")
                }
            }
            .padding(.top, 2)
        }
    }
}

private struct ShortChip: View {
    let text: String
    let fullText: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(AppFont.footnote())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.secondary)
        .clipShape(Capsule())
        .foregroundStyle(AppColor.textPrimary)
        .accessibilityLabel(fullText)
    }
}

// MARK: - Quick Actions (güncellendi)

private struct QuickActionsGrid: View {
    var onPickProfilePhoto: () -> Void
    var onChangePassword: () -> Void
    var onCloseAccount: () -> Void

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            QuickActionButton(title: "Profil Resmim", systemImage: "person.crop.circle.fill", action: onPickProfilePhoto)
            QuickActionButton(title: "Şifreyi Değiştir", systemImage: "key.fill", action: onChangePassword)
            QuickActionButton(title: "Hesabı Kapat", systemImage: "person.crop.circle.badge.xmark", action: onCloseAccount)
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppColor.secondary)
                        .frame(width: 48, height: 48)
                    Image(systemName: systemImage)
                        .foregroundStyle(AppColor.primary)
                }
                Text(title)
                    .font(AppFont.footnote())
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - WrapHStack (çok satırlı rozet yerleşimi)

private struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 17, macOS 14, *) {
            AnyLayout(_WrapHStack(spacing: spacing, lineSpacing: lineSpacing)) {
                content
            }
        } else {
            HStack(spacing: spacing) {
                content
            }
        }
    }

    @available(iOS 17, macOS 14, *)
    private struct _WrapHStack: Layout {
        let spacing: CGFloat
        let lineSpacing: CGFloat

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let maxWidth = proposal.width ?? .infinity
            var width: CGFloat = 0
            var height: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if width + size.width > maxWidth {
                    height += lineHeight + lineSpacing
                    width = 0
                    lineHeight = 0
                }
                width += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            height += lineHeight
            return CGSize(width: maxWidth, height: height)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var x = bounds.minX
            var y = bounds.minY
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > bounds.maxX {
                    x = bounds.minX
                    y += lineHeight + lineSpacing
                    lineHeight = 0
                }
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
    }
}

// MARK: - Rating Sheet

private struct RatingSheet: View {
    @Binding var selectedRating: Int?
    var onRated: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Uygulamayı Puanlayın")
                .font(AppFont.title())
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        selectedRating = star
                        onRated()
                    } label: {
                        Image(systemName: (selectedRating ?? 0) >= star ? "star.fill" : "star")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppColor.primary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("\(star) yıldız")
                }
            }
            .padding(.top, 8)

            Text("Geri bildiriminiz bizim için çok değerli.")
                .font(AppFont.footnote())
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding()
        .background(AppColor.background)
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isUpdating: Bool
    @Binding var message: String?
    var onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Şifreyi Değiştir")
                .font(AppFont.title())

            SecureField("Yeni şifre", text: $newPassword)
                .textContentType(.newPassword)
                .padding(10)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            SecureField("Yeni şifre (tekrar)", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding(10)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if let message {
                Text(message)
                    .font(AppFont.footnote())
                    .foregroundStyle(message.contains("hata") ? .red : .green)
            }

            Button {
                onSubmit()
            } label: {
                HStack {
                    if isUpdating { ProgressView().tint(.white) }
                    Text("Güncelle")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isUpdating)
        }
        .padding()
        .background(AppColor.background)
    }
}

#Preview {
    ProfileView()
}

// MARK: - Fullscreen profile image

private struct FullscreenProfileImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    var namespace: Namespace.ID

    @State private var backgroundOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "profileImage", in: namespace)
                .onTapGesture {
                    close()
                }
                .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 80 {
                            close()
                        }
                    })

            VStack {
                HStack {
                    Spacer()
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(radius: 4)
                            .padding()
                    }
                    .accessibilityLabel("Kapat")
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                backgroundOpacity = 0.9
            }
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            backgroundOpacity = 0
            isPresented = false
        }
    }
}

