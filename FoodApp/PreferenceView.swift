// PreferenceView.swift

import SwiftUI

struct PreferenceView: View {
    @AppStorage("isVegetarian") var isVegetarian: Bool = false
    @AppStorage("isVegan") var isVegan: Bool = false
    @AppStorage("isGlutenFree") var isGlutenFree: Bool = false
    @AppStorage("prepTime") var prepTime: Int = 30
    @AppStorage("dislikedIngredients") var dislikedIngredients: String = ""
    @AppStorage("skillLevel") var skillLevel: String = "Orta"

    @Binding var hasCompletedOnboarding: Bool

    private let prepTimes = [15, 30, 45, 60]
    private let skillLevels = ["Acemiyim", "Hallederim", "Chef Gibiyim"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Başlık
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sizi Tanıyalım")
                            .font(AppFont.display())
                        Text("Tercihlerinize göre tarifleri daha iyi uyarlayalım.")
                            .font(AppFont.footnote())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .cardPadding()

                    // Diyet Tercihleri
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Diyet Tercihleri")
                                .font(AppFont.title())

                            Toggle("🥬 Vejetaryen", isOn: $isVegetarian)
                            Toggle("🌱 Vegan", isOn: $isVegan)
                            Toggle("🚫🌾 Glütensiz", isOn: $isGlutenFree)
                        }
                    }
                    .cardPadding()

                    // İstenmeyen Malzemeler
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İstenmeyen Malzemeler")
                                .font(AppFont.title())

                            TextField("Örn: mantar, pırasa (virgülle ayırın)", text: $dislikedIngredients)
                                .padding(10)
                                .background(AppColor.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .autocapitalization(.none)
                        }
                    }
                    .cardPadding()

                    // Hazırlık Süresi
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hazırlık Süresi")
                                .font(AppFont.title())

                            Picker("Maksimum Süre", selection: $prepTime) {
                                ForEach(prepTimes, id: \.self) { time in
                                    Text("\(time) dk").tag(time)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .cardPadding()

                    // Beceri Seviyesi
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Beceri Seviyesi")
                                .font(AppFont.title())

                            Picker("Beceri Seviyesi", selection: $skillLevel) {
                                ForEach(skillLevels, id: \.self) { level in
                                    Text(level).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .cardPadding()

                    // Bilgi
                    Text("Bu ayarları Profil sekmesinden istediğiniz zaman değiştirebilirsiniz.")
                        .font(AppFont.footnote())
                        .foregroundStyle(AppColor.textSecondary)
                        .cardPadding()
                }
                .padding(.top, 12)
            }
            .background(AppColor.background)
            .navigationTitle("Tercihler")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PreferenceView(hasCompletedOnboarding: .constant(false))
}

