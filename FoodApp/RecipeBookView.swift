//
//  RecipeBookView.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//

import SwiftUI
import Supabase

struct SavedRecipe: Codable, Identifiable {
    let id: Int
    let createdAt: Date
    let recipeText: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case recipeText = "recipe_text"
        case imageUrl = "image_url"
    }
    
    // İlk satırı başlık olarak al, Markdown başlık öneklerini (#, ##, ###) ve fazladan boşlukları temizle
    var title: String {
        let firstLine = recipeText.split(separator: "\n").first.map(String.init) ?? "Başlıksız Tarif"
        return firstLine
            .replacingOccurrences(of: #"^\s*#{1,6}\s*"#, with: "", options: .regularExpression) // baştaki #... kaldır
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? "Başlıksız Tarif" : firstLine
                .replacingOccurrences(of: #"^\s*#{1,6}\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RecipeBookView: View {
    let supabase = FoodApp.supabase
    
    @State private var savedRecipes: [SavedRecipe] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let errorMessage {
                    Card {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Hata: \(errorMessage)")
                                .font(AppFont.footnote())
                                .foregroundStyle(.orange)
                        }
                    }
                    .cardPadding()
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(AppColor.primary)
                        Text("Tarifler yükleniyor...")
                            .font(AppFont.body())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding()
                } else if savedRecipes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "book")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(AppColor.textSecondary)
                        Text("Henüz kaydedilmiş tarifiniz yok.")
                            .font(AppFont.body())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.top, 32)
                } else {
                    List {
                        ForEach(savedRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRow(recipe: recipe)
                            }
                        }
                        .onDelete(perform: deleteRecipe)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(AppColor.background)
            .navigationTitle("Şefin Tarifleri")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await fetchRecipes() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Yenile")
                }
            }
            .onAppear {
                if savedRecipes.isEmpty {
                    Task { await fetchRecipes() }
                }
            }
        }
    }

    func fetchRecipes() async {
        isLoading = true
        errorMessage = nil
         
        do {
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "Tarifleri görmek için giriş yapmalısınız."
                isLoading = false
                return
            }

            let recipes: [SavedRecipe] = try await supabase.database
                .from("recipes")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            self.savedRecipes = recipes
        } catch {
            print("SUPABASE FETCH HATASI: \(error.localizedDescription)")
            errorMessage = "Tarifler yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
         
        isLoading = false
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        let recipesToDelete = offsets.map { savedRecipes[$0] }
        savedRecipes.remove(atOffsets: offsets)

        Task {
            for recipe in recipesToDelete {
                do {
                    try await supabase.database
                        .from("recipes")
                        .delete()
                        .eq("id", value: recipe.id)
                        .execute()
                } catch {
                    print("SUPABASE SİLME HATASI: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct RecipeRow: View {
    let recipe: SavedRecipe

    private func emojiPlaceholder(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("salata") { return "🥗" }
        if lower.contains("makarna") { return "🍝" }
        if lower.contains("çorba") { return "🥣" }
        if lower.contains("tatlı") || lower.contains("dessert") { return "🍰" }
        if lower.contains("tavuk") { return "🍗" }
        if lower.contains("balık") { return "🐟" }
        if lower.contains("kahvaltı") { return "🍳" }
        return "🍽️"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let urlString = recipe.imageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(width: 60, height: 60)
                         .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColor.cardBackground)
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: "photo").foregroundStyle(AppColor.textSecondary))
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColor.secondary)
                        .frame(width: 60, height: 60)
                    Text(emojiPlaceholder(for: recipe.title))
                        .font(.system(size: 26))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(AppFont.title())
                    .lineLimit(2)
                Text(recipe.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.footnote())
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Yeni: Tarif metnini bölümlere ayıran basit parser ve daha özgün detay görünümü
private struct ParsedRecipe {
    var title: String?
    var sections: [Section] = []

    struct Section: Identifiable {
        let id = UUID()
        let heading: String?
        let type: SectionType
        let lines: [String]
    }

    enum SectionType {
        case ingredients
        case steps
        case notes
        case serving
        case text
    }
}

private extension String {
    func trimmingMarkdownHeading() -> String {
        self.replacingOccurrences(of: #"^\s*#{1,6}\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Çok basit sezgisel ayrıştırma: baştaki başlık, ardından bilinen bölüm anahtarları
private func parseRecipeText(_ text: String) -> ParsedRecipe {
    var result = ParsedRecipe()
    let lines = text.components(separatedBy: .newlines)

    var currentHeading: String?
    var currentType: ParsedRecipe.SectionType = .text
    var buffer: [String] = []

    func flush() {
        guard !buffer.isEmpty else { return }
        result.sections.append(.init(heading: currentHeading, type: currentType, lines: buffer))
        buffer.removeAll()
    }

    for (idx, raw) in lines.enumerated() {
        let line = raw.trimmingCharacters(in: .whitespaces)

        // Başlığa uygun ilk satır (# ...)
        if idx == 0, line.hasPrefix("#") {
            result.title = line.trimmingMarkdownHeading()
            continue
        }

        // Bölüm başlıkları: ## Malzemeler / ## Hazırlanış / ## Notlar / ## Servis vb.
        if line.hasPrefix("#") {
            flush()
            let cleaned = line.trimmingMarkdownHeading()
            let heading = cleaned.lowercased()

            currentHeading = cleaned
            if heading.contains("malzeme") {
                currentType = .ingredients
            } else if heading.contains("hazırlan") || heading.contains("adım") || heading.contains("yapılış") {
                currentType = .steps
            } else if heading.contains("servis") || heading.contains("serv") || heading.contains("sunum") {
                currentType = .serving
            } else if heading.contains("not") || heading.contains("ipucu") {
                currentType = .notes
            } else {
                currentType = .text
            }
            continue
        }

        // Madde işaretleri veya numaralı satırlar
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
            buffer.append(line.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression)
                            .replacingOccurrences(of: #"^[-*]\s"#, with: "", options: .regularExpression))
        } else if !line.isEmpty {
            buffer.append(line)
        } else {
            // boş satır -> paragraf ayrımı, burada biriktirmeye devam edelim
            buffer.append("")
        }
    }
    flush()

    // Eğer hiç başlık yakalayamadıysak, ilk satırı başlık olarak deneyelim
    if result.title == nil, let firstNonEmpty = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
        result.title = firstNonEmpty.trimmingMarkdownHeading()
    }

    return result
}

struct RecipeDetailView: View {
    let recipe: SavedRecipe
    
    var body: some View {
        let parsed = parseRecipeText(recipe.recipeText)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Başlık (sade)
                if let title = parsed.title, !title.isEmpty {
                    Text(title)
                        .font(AppFont.titleLarge())
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal)
                        .padding(.top, 12)
                } else {
                    Text(recipe.title)
                        .font(AppFont.titleLarge())
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }

                // Bölümler
                ForEach(parsed.sections) { section in
                    SectionCard(icon: sectionIcon(section.type),
                                title: sectionTitle(section)) {
                        sectionContent(section)
                    }
                    .cardPadding()
                }

                // Tarih bilgisi
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppColor.textSecondary)
                    Text("Kaydedildi: \(recipe.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppFont.footnote())
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Tarif")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section helpers

    private func sectionIcon(_ type: ParsedRecipe.SectionType) -> String {
        switch type {
        case .ingredients: return "🥕"
        case .steps: return "👩‍🍳"
        case .serving: return "🍽️"
        case .notes: return "ℹ️"
        case .text: return "📌"
        }
    }

    private func sectionTitle(_ section: ParsedRecipe.Section) -> String {
        if let heading = section.heading, !heading.isEmpty { return heading }
        switch section.type {
        case .ingredients: return "Malzemeler"
        case .steps: return "Hazırlanış"
        case .serving: return "Servis Önerileri"
        case .notes: return "Notlar"
        case .text: return "Bilgiler"
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: ParsedRecipe.Section) -> some View {
        switch section.type {
        case .ingredients:
            IngredientPillGrid(lines: section.lines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })
        case .steps:
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(section.lines.enumerated()).filter { !$0.element.trimmingCharacters(in: .whitespaces).isEmpty }, id: \.offset) { idx, line in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppColor.primary)
                            .clipShape(Circle())
                            .padding(.top, 2)
                        Text(line)
                            .font(AppFont.body())
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
            }
        case .serving:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(paragraphs(from: section.lines), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppColor.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        case .notes, .text:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(paragraphs(from: section.lines), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }

    private func paragraphs(from lines: [String]) -> [String] {
        var result: [String] = []
        var buffer: [String] = []
        func flush() {
            let joined = buffer.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { result.append(joined) }
            buffer.removeAll()
        }
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flush()
            } else {
                buffer.append(line)
            }
        }
        flush()
        return result
    }
}

// Section Card: UserRecipeDetailView’deki ile uyumlu bir başlık şeridi ve içerik
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
                .overlay(
                    Divider().opacity(0.6),
                    alignment: .bottom
                )

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// Ingredient pill grid (UserRecipeDetailView’den uyarlanmış)
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

#Preview {
    RecipeBookView()
}
