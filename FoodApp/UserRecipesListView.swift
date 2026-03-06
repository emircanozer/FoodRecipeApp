//
//  UserRecipesListView.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import SwiftUI
import Supabase

struct UserRecipesListView: View {
    let supabase = FoodApp.supabase

    @State private var recipes: [UserRecipe] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewRecipe = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 8) {
                        ProgressView().tint(AppColor.primary)
                        Text("Tarifler yükleniyor…")
                            .font(AppFont.body())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding()
                } else if let errorMessage {
                    Card {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .font(AppFont.footnote())
                                .foregroundStyle(.orange)
                        }
                    }
                    .cardPadding()
                } else if recipes.isEmpty {
                    VStack(spacing: 10) {
                        Text("🍽️")
                            .font(.system(size: 48))
                        Text("Bu Bölümde Tüm Kullanıcılar Tarafından Paylaşılan Global Tarifler Yer Alır.")
                            .font(AppFont.title())
                            .multilineTextAlignment(.center)
                        Text("Siz de Sağ üstteki “Yeni Tarif” ile hemen ekleyin.")
                            .font(AppFont.footnote())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.top, 32)
                } else {
                    List {
                        ForEach(recipes) { r in
                            NavigationLink {
                                UserRecipeDetailView(recipe: r)
                            } label: {
                                HStack(spacing: 12) {
                                    if let urlString = r.imageUrl, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { img in
                                            img.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppColor.cardBackground)
                                                .frame(width: 60, height: 60)
                                                .overlay(Text("📷"))
                                        }
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColor.cardBackground)
                                            .frame(width: 60, height: 60)
                                            .overlay(Text("🍲"))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(r.title)
                                                .font(AppFont.title())
                                                .lineLimit(2)
                                            if r.isFavorite {
                                                Text("❤️")
                                            }
                                            if r.isSpicy {
                                                Text("🌶️")
                                            }
                                        }
                                        HStack(spacing: 8) {
                                            if let minutes = r.minutes {
                                                Pill("\(minutes) dk", systemImage: "timer", emoji: nil)
                                            }
                                            if let cuisine = r.cuisine, !cuisine.isEmpty {
                                                Pill(cuisine, systemImage: "globe", emoji: nil)
                                            }
                                            if let difficulty = r.difficulty, !difficulty.isEmpty {
                                                Pill(difficulty, systemImage: "flame", emoji: nil)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Tüm Tarifler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewRecipe = true
                    } label: {
                        Label("Yeni Tarif", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await fetchRecipes() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .onAppear {
                if recipes.isEmpty {
                    Task { await fetchRecipes() }
                }
            }
            .sheet(isPresented: $showingNewRecipe, onDismiss: {
                Task { await fetchRecipes() }
            }) {
                NavigationStack {
                    NewUserRecipeView()
                }
            }
            .background(AppColor.background)
        }
    }

    func fetchRecipes() async {
        isLoading = true
        errorMessage = nil
        do {
            // Artık kullanıcıya göre filtre yok; tüm kullanıcıların tarifleri listelenir
            let items: [UserRecipe] = try await supabase.database
                .from("user_recipes")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.recipes = items
        } catch {
            errorMessage = "Yükleme hatası: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteRecipes(at offsets: IndexSet) {
        let toDelete = offsets.map { recipes[$0] }
        recipes.remove(atOffsets: offsets)
        Task {
            for item in toDelete {
                do {
                    try await supabase.database
                        .from("user_recipes")
                        .delete()
                        .eq("id", value: item.id)
                        .execute()
                } catch {
                    print("Silme hatası: \(error)")
                }
            }
        }
    }
}

#Preview {
    UserRecipesListView()
}
