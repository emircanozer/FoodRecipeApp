// ContentView.swift

import SwiftUI
import PhotosUI
import GoogleGenerativeAI
import Supabase

struct GeminiRecipeResponse: Decodable {
    let tarif_metni: String
    let arama_terimi: String
}

struct Recipe: Codable {
    let recipeText: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case recipeText = "recipe_text"
        case imageUrl = "image_url"
    }
}

// Encodable payload for inserting into Supabase "recipes" table
struct NewRecipe: Encodable {
    let userId: UUID
    let recipeText: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recipeText = "recipe_text"
        case imageUrl = "image_url"
    }
}

struct ContentView: View {

    // API Keys
    let apiKey = "AIzaSyCe_0Eclyu2g9PvzFDN--3VQl-yrY_QKHw"
    let supabase = FoodApp.supabase

    // Preferences
    @AppStorage("isVegetarian") var isVegetarian: Bool = false
    @AppStorage("isVegan") var isVegan: Bool = false
    @AppStorage("isGlutenFree") var isGlutenFree: Bool = false
    @AppStorage("prepTime") var prepTime: Int = 30
    @AppStorage("dislikedIngredients") var dislikedIngredients: String = ""
    @AppStorage("skillLevel") var skillLevel: String = "Orta"

    // State
    @State private var promptText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    @State private var geminiResponse: String = "Merhaba! Bugün ne pişirmek istersiniz?"

    @State private var isLoading: Bool = false
    @State private var isSaving = false
    @State private var saveAlertMessage: String?
    @State private var showingCamera: Bool = false

    // Seçilen/çekilen görsel
    @ViewBuilder
    private var selectedImageView: some View {
        if let currentSelectedImage = selectedImage {
            Card {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: currentSelectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColor.separator.opacity(0.3), lineWidth: 0.5)
                        )
                        .clipped()

                    Button {
                        self.selectedImage = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(CircularIconButtonStyle())
                    .padding(10)
                    .accessibilityLabel("Görseli kaldır")
                }
            }
            .cardPadding()
        } else {
            // Boş durum kartı
            Card {
                HStack(spacing: 12) {
                    Text("🍳")
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Görsel ekleyin veya metin yazın")
                            .font(AppFont.title())
                        Text("Kamera ya da galeriden malzemeleri paylaşabilir, not ekleyebilirsiniz.")
                            .font(AppFont.footnote())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                }
            }.cardPadding()
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Hero başlık
                VStack(spacing: 6) {
                    Text("Merhaba, bugün ne pişirelim?")
                        .font(AppFont.display())
                        .multilineTextAlignment(.center)
                    Text("Malzemelerinizi yazın veya bir fotoğraf ekleyin.")
                        .font(AppFont.footnote())
                        .foregroundStyle(AppColor.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Sadece kullanıcıdan gelen görseli göster
                        selectedImageView

                        if isLoading {
                            VStack(spacing: 20) {
                                // Lottie animasyon dosyasının adını buraya yaz (örn: "chef-loading")
                                LottieView(name: "chef-loading")
                                    .frame(width: 250, height: 250)
                                    .shadow(color: AppColor.primary.opacity(0.2), radius: 10)
                                
                                VStack(spacing: 8) {
                                    Text("Şef malzemeleri inceliyor...")
                                        .font(AppFont.title())
                                        .foregroundStyle(AppColor.primary)
                                    
                                    Text("Harika bir tarif hazırlanıyor, lütfen bekleyin.")
                                        .font(AppFont.footnote())
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                        } else if isSaving {
                            HStack(spacing: 8) {
                                ProgressView().tint(AppColor.primary)
                                Text("Tarif kaydediliyor...")
                                    .font(AppFont.body())
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .padding(.horizontal)
                        }

                        // AI Balon
                        AIBubble(text: cleanedGeminiText(geminiResponse))
                            .cardPadding()
                    }
                    .padding(.vertical, 12)
                }
                .background(AppColor.background)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

                // Giriş çubuğu
                inputBar
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .top)
            }
            .navigationTitle("Tarif Oluştur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        selectedImage = nil
                        showingCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Kamerayı aç")

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .foregroundStyle(AppColor.primary)
                    }
                    .accessibilityLabel("Galeriden seç")
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage, isPresented: $showingCamera)
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        self.selectedImage = uiImage
                        self.geminiResponse = "Fotoğraf eklendi. Eklemek istediğiniz bir not var mı?"
                    }
                }
            }
            .alert("Tebrikler 🥳 ", isPresented: .constant(saveAlertMessage != nil), actions: {
                Button("Tamam") { saveAlertMessage = nil }
            }, message: {
                Text(saveAlertMessage ?? "")
            })
        }
    }

    // Giriş barı
    private var inputBar: some View {
        HStack(spacing: 10) {

            // Metin alanı kapsayıcısı
            HStack(alignment: .bottom, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppColor.primary)

                TextField("Bugün ne pişirelim? Örn: tavuk, makarna", text: $promptText, axis: .vertical)
                    .font(AppFont.body())
                    .lineLimit(1...4)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Gönder butonu
            Button {
                Task { await generateRecipe() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(AppColor.primary)
                    .clipShape(Circle())
            }
            .disabled((promptText.isEmpty && selectedImage == nil) || isLoading || isSaving)
            .accessibilityLabel("Tarif oluştur")

            // Kaydet butonu
            Button {
                Task { await saveRecipe() }
            } label: {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(AppColor.primary)
                    .clipShape(Circle())
            }
            .disabled(isLoading || isSaving || cleanedGeminiText(geminiResponse).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || geminiResponse == "Merhaba! Bugün ne pişirmek istersiniz?" || geminiResponse.hasPrefix("Akıllı tarifiniz hazırlanıyor"))
            .accessibilityLabel("Tarifi kaydet")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // Metni temizle: baştaki markdown başlıklarını (#...) kaldır
    private func cleanedGeminiText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let cleaned = lines.map { line in
            line.replacingOccurrences(of: #"^\s*#{1,6}\s*"#, with: "", options: .regularExpression)
        }
        return cleaned.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Kaydetme
    func saveRecipe() async {
        isSaving = true
        defer { isSaving = false }

        let textToSave = cleanedGeminiText(geminiResponse)
        guard !textToSave.isEmpty,
              textToSave != "Merhaba! Bugün ne pişirmek istersiniz?",
              !textToSave.hasPrefix("Bir hata oluştu:") else {
            saveAlertMessage = "Kaydedilecek geçerli bir tarif bulunamadı."
            return
        }

        // 1) Oturumdaki kullanıcı ID'sini al
        let userId: UUID
        do {
            let session = try await supabase.auth.session
            userId = session.user.id
        } catch {
            saveAlertMessage = "Giriş yapmalısınız: \(error.localizedDescription)"
            return
        }

        // 2) Image upload (opsiyonel) – şimdilik imageUrl = nil
        let payload = NewRecipe(
            userId: userId,
            recipeText: textToSave,
            imageUrl: nil
        )

        do {
            _ = try await supabase.database
                .from("recipes")
                .insert(payload)
                .select()
                .single()
                .execute()

            saveAlertMessage = "Tarif başarıyla kaydedildi! Defterim sekmesinden görebilirsiniz."
        } catch {
            saveAlertMessage = "Tarif kaydedilirken hata: \(error.localizedDescription)"
        }
    }

    // Gemini
    func generateRecipe() async {
        isLoading = true
        geminiResponse = "Akıllı tarifiniz hazırlanıyor..."

        var constraints = "Kullanıcının tercihleri şunlar:"
        if isVegetarian { constraints += " Tarif VEJETARYEN olmalı." }
        if isVegan { constraints += " Tarif VEGAN olmalı." }
        if isGlutenFree { constraints += " Tarif GLÜTENSİZ olmalı." }
        constraints += " Hazırlık süresi en fazla \(prepTime) dakika olmalı."
        if !dislikedIngredients.isEmpty {
            constraints += " Tarif şu malzemeleri İÇERMEMELİ: \(dislikedIngredients)."
        }
        constraints += " Tarifin zorluk seviyesi \(skillLevel) olmalı."

        let jsonInstruction = "Cevabını BANA SADECE BİR JSON objesi olarak ver, başka hiçbir metin veya markdown (` ```json ... ``` `) ekleme. Bu JSON objesi şu iki anahtarı içermeli: {\"tarif_metni\": \"...\", \"arama_terimi\": \"...\"}"
        let userRequest = promptText.isEmpty ? "Fotoğraftaki malzemelere odaklan." : "Kullanıcının özel isteği: \"\(promptText)\""

        let textPrompt = """
        \(constraints)

        \(userRequest)

        Bu kısıtlamalara ve özel isteğe uyarak, (varsa) sağlanan fotoğraftaki malzemeleri de kullanarak bana bir yemek tarifi oluştur.
        \(jsonInstruction)
        """

        do {
            let model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)

            var contentParts: [ModelContent.Part] = []
            contentParts.append(.text(textPrompt))

            if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                contentParts.append(.data(mimetype: "image/jpeg", imageData))
            }

            let response = try await model.generateContent([
                ModelContent(parts: contentParts)
            ])

            if var text = response.text {
                guard let firstBrace = text.firstIndex(of: "{"),
                      let lastBrace = text.lastIndex(of: "}") else {
                    self.geminiResponse = "Hata: JSON verisi bulunamadı (Başlangıç '{' veya Bitiş '}' eksik). \n\nAlınan Ham Veri:\n\(text)"
                    throw URLError(.badServerResponse)
                }

                let jsonString = String(text[firstBrace...lastBrace])
                let jsonData = Data(jsonString.utf8)

                let decodedResponse = try JSONDecoder().decode(GeminiRecipeResponse.self, from: jsonData)

                self.geminiResponse = decodedResponse.tarif_metni

            } else {
                throw URLError(.cannotParseResponse)
            }

        } catch {
            self.geminiResponse = "Bir hata oluştu: \(error.localizedDescription)\nLütfen tekrar deneyin."
        }

        isLoading = false
        promptText = ""
        selectedImage = nil
        selectedPhotoItem = nil
    }
}

// Sohbet baloncukları
private struct AIBubble: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Text("👨‍🍳")
            VStack(alignment: .leading, spacing: 8) {
                Text("Şef’in Önerisi")
                    .font(AppFont.footnote())
                    .foregroundStyle(AppColor.textSecondary)
                Text(text)
                    .font(AppFont.body())
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(12)
            .background(AppColor.bubbleAI)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}

