//
//  UserRecipeDetailView.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import SwiftUI

struct UserRecipeDetailView: View {
    let recipe: UserRecipe
    @State private var showAllDescription = false
    @State private var isSharing = false
    @State private var shareItem: String = ""
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geo in
                    Color.clear
                        .preference(key: OffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)

                VStack(spacing: 16) {
                    // Hero
                    HeroHeader(
                        imageURLString: recipe.imageUrl,
                        title: recipe.title,
                        isFavorite: recipe.isFavorite,
                        isSpicy: recipe.isSpicy,
                        scrollOffset: scrollOffset
                    )
                    .padding(.top, 8)

                    // Hızlı bilgiler
                    QuickChips(recipe: recipe)
                        .cardPadding()

                    // Açıklama
                    if let description = recipe.description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        SectionCard(icon: "📝", title: "Açıklama") {
                            ExpandableText(
                                text: description,
                                lineLimit: 5,
                                expanded: $showAllDescription
                            )
                            .foregroundStyle(AppColor.textPrimary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        .cardPadding()
                    }

                    // Malzemeler
                    if let ingredients = recipe.ingredients, !ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        SectionCard(icon: "🥕", title: "Malzemeler") {
                            IngredientPillGrid(lines: splitLines(ingredients))
                        }
                        .cardPadding()
                    }

                    // Notlar
                    if let notes = recipe.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        SectionCard(icon: "ℹ️", title: "Ek Bilgiler") {
                            Text(notes)
                                .font(AppFont.body())
                                .foregroundStyle(AppColor.textPrimary)
                                .lineSpacing(5)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }
                        .cardPadding()
                    }

                    // Tarih
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Oluşturulma: \(recipe.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(AppFont.footnote())
                            .foregroundStyle(AppColor.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .padding(.top, 8)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(OffsetKey.self) { value in
                scrollOffset = value
            }
        }
        .background(AppColor.background)
        .navigationTitle("Tarif Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareItem = shareText()
                    isSharing = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(activityItems: [shareItem])
        }
    }

    private func splitLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func shareText() -> String {
        var parts: [String] = ["\(recipe.title)"]
        if let d = recipe.description, !d.isEmpty { parts.append(d) }
        if let ing = recipe.ingredients, !ing.isEmpty {
            parts.append("Malzemeler:\n\(ing)")
        }
        if let n = recipe.notes, !n.isEmpty { parts.append("Notlar:\n\(n)") }
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Hero Header

private struct HeroHeader: View {
    let imageURLString: String?
    let title: String
    let isFavorite: Bool
    let isSpicy: Bool
    let scrollOffset: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageURLString,
                   let url = URL(string: imageURLString) {
                    if url.isFileURL {
                        LocalImageView(fileURL: url)
                            .resizableHero()
                    } else {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            ZStack {
                                Rectangle().fill(AppColor.cardBackground)
                                Text("📷 Görsel Yok").foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        .resizableHero()
                    }
                } else {
                    ZStack {
                        Rectangle().fill(
                            LinearGradient(
                                colors: [AppColor.primary.opacity(0.25), AppColor.secondary],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        Text("🍽️").font(.system(size: 48))
                    }
                    .resizableHero()
                }
            }
            .frame(height: 260 + parallaxAmount)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColor.separator.opacity(0.25), lineWidth: 0.5)
            )
            .padding(.horizontal)
            .offset(y: parallaxOffset)

            // Gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(height: 260)
            .padding(.horizontal)

            // Title & badges
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if isFavorite { Pill("Favori", systemImage: "heart.fill") }
                    if isSpicy { Pill("Baharatlı", systemImage: "flame.fill") }
                }
                .transition(.opacity)

                Text(title)
                    .font(AppFont.titleLarge())
                    .foregroundStyle(.white)
                    .shadow(radius: 6)
                    .lineLimit(3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
    }

    private var parallaxAmount: CGFloat {
        max(0, -scrollOffset * 0.25)
    }
    private var parallaxOffset: CGFloat {
        min(0, scrollOffset * 0.25)
    }
}

// CHANGE: make this extension accessible to other files (remove `private`)
extension View {
    func resizableHero() -> some View {
        self
            .scaledToFill()
            .overlay(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
            )
    }
}

// Yerel file:// görsel yükleyici
private struct LocalImageView: View {
    let fileURL: URL
    var body: some View {
        if let data = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(AppColor.cardBackground)
                Text("📷 Görsel Yüklenemedi").foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(icon)
                    Text(title).font(AppFont.title())
                    Spacer()
                }
                .padding(.bottom, 2)

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - ExpandableText

private struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    @Binding var expanded: Bool

    @State private var canExpand = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(AppFont.body())
                .lineSpacing(6)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(expanded ? nil : lineLimit)
                .background(
                    Text(text)
                        .font(AppFont.body())
                        .lineSpacing(6)
                        .opacity(0)
                        .readSize { size in
                            // Basit tahmin: tek satır yüksekliğine göre uzun mu
                            canExpand = text.count > 140 || size.height > 160
                        }
                )

            if canExpand {
                Button(expanded ? "Gizle" : "Daha Fazla") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        expanded.toggle()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

private struct SizeReader: ViewModifier {
    let onChange: (CGSize) -> Void
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SizeKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizeKey.self, perform: onChange)
    }
}
private struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}
private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeReader(onChange: onChange))
    }
}

// MARK: - Ingredient Grid

private struct IngredientPillGrid: View {
    let lines: [String]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var appear = false

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColor.primary)
                    Text(line)
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(AppColor.secondary)
                .clipShape(Capsule())
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(Double(idx) * 0.03), value: appear)
            }
        }
        .onAppear { appear = true }
    }
}

// MARK: - Quick Chips (mevcut)

private struct QuickChips: View {
    let recipe: UserRecipe

    var body: some View {
        HStack(spacing: 8) {
            if let m = recipe.minutes {
                Pill("\(m) dk", systemImage: "timer")
            }
            if let c = recipe.cuisine, !c.isEmpty {
                Pill(c, systemImage: "globe")
            }
            if let d = recipe.difficulty, !d.isEmpty {
                Pill(d, systemImage: "flame")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Share Sheet

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Scroll offset key
private struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview {
    UserRecipeDetailView(
        recipe: UserRecipe(
            id: 1,
            userId: UUID(),
            title: "Ev Yapımı Pizza",
            description: "Dışı çıtır, içi yumuşak bir pizza. Uzun açıklama denemesi için birkaç cümle daha ekleyelim. İnce hamur, zengin sos ve taze malzemelerle harika bir lezzet.",
            minutes: 45,
            ingredients: "Un\nSu\nMaya\nDomates Sosu\nMozzarella\nZeytinyağı\nTuz",
            notes: "Taş fırın efekti için döküm tava kullanın.",
            isFavorite: true,
            isSpicy: true,
            cuisine: "İtalyan",
            difficulty: "Orta",
            imageUrl: nil,
            createdAt: Date()
        )
    )
}
