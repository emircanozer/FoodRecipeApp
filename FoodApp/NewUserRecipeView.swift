//
//  NewUserRecipeView.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import SwiftUI
import Supabase
import PhotosUI

struct NewUserRecipeView: View {
    let supabase = FoodApp.supabase

    // Form alanları
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var minutes: Int = 30
    @State private var ingredients: String = ""
    @State private var notes: String = ""
    @State private var isFavorite: Bool = false
    @State private var isSpicy: Bool = false
    @State private var cuisine: String = "Türk"
    @State private var difficulty: String = "Orta"

    // Görsel
    @State private var selectedImage: UIImage?
    @State private var isProcessingImage: Bool = false

    // Kamera/Galeri state
    @State private var showingCamera: Bool = false
    @State private var photoPickerItem: PhotosPickerItem?

    // Durum
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var imageError: String?

    private let cuisineOptions = ["Türk", "İtalyan", "Meksika", "Asya", "Hint", "Amerikan", "Diğer"]
    private let difficultyOptions = ["Kolay", "Orta", "Zor"]

    var body: some View {
        Form {
            Section(header: Label("Yemek Bilgileri", systemImage: "fork.knife").font(AppFont.title())) {
                HStack {
                    Text("🍽️")
                    TextField("Yemek adı", text: $title)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }

                HStack {
                    Text("⏱️")
                    Picker("Süre (dk)", selection: $minutes) {
                        ForEach(5...180, id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 120)
                }

                HStack {
                    Text("🌍")
                    Picker("Mutfak", selection: $cuisine) {
                        ForEach(cuisineOptions, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("🔥")
                    Picker("Zorluk", selection: $difficulty) {
                        ForEach(difficultyOptions, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section(header: Label("Açıklama", systemImage: "text.justify").font(AppFont.title())) {
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.separator))
                    .padding(.vertical, 4)
            }

            Section(header: Label("Malzemeler", systemImage: "leaf").font(AppFont.title())) {
                TextEditor(text: $ingredients)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.separator))
                    .padding(.vertical, 4)
                Text("Öneri: Her satıra bir malzeme yazın. 🥕🧅🧄")
                    .font(AppFont.footnote())
                    .foregroundStyle(AppColor.textSecondary)
            }

            Section(header: Label("Ek Bilgiler", systemImage: "info.circle").font(AppFont.title())) {
                Toggle("❤️ Favorim", isOn: $isFavorite)
                Toggle("🌶️ Baharatlı", isOn: $isSpicy)
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColor.separator))
                    .padding(.vertical, 4)
            }

            Section(header: Label("Görsel", systemImage: "photo").font(AppFont.title())) {
                if let selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button {
                            self.selectedImage = nil
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(CircularIconButtonStyle(size: 36))
                        .padding(6)
                    }
                } else {
                    VStack(spacing: 10) {
                        if isProcessingImage {
                            HStack(spacing: 8) {
                                ProgressView().tint(AppColor.primary)
                                Text("Görsel işleniyor…")
                                    .font(AppFont.footnote())
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        // İki ayrı ve hızlı buton
                        HStack(spacing: 12) {
                            Button {
                                // Sadece kamera sheet açılır
                                showingCamera = true
                            } label: {
                                Label("Kamera ile Çek", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isProcessingImage)

                            PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                                Label("Galeriden Seç", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isProcessingImage)
                        }
                        if let imageError {
                            Text(imageError)
                                .font(AppFont.footnote())
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            if let saveError {
                Section {
                    Text(saveError)
                        .font(AppFont.footnote())
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Yeni Tarif")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIApplication.shared.endEditing()
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Kaydet")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessingImage)
            }
            ToolbarItem(placement: .keyboard) {
                Button("Kapat") { UIApplication.shared.endEditing() }
            }
        }
        // Kamera sadece bir sheet
        .sheet(isPresented: $showingCamera, onDismiss: {
            // Kamera kapandıktan sonra ek bir işlem yok
        }) {
            CameraView(selectedImage: Binding(
                get: { selectedImage },
                set: { img in
                    if let img { Task { await processPickedImage(img) } }
                    showingCamera = false
                }
            ), isPresented: $showingCamera)
        }
        // PhotosPicker değişimini dinle
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadPhotoPickerItem(newItem)
            }
        }
        .dismissKeyboardOnTap()
    }

    // PhotosPicker yükleme + arka planda işleme
    @MainActor
    private func loadPhotoPickerItem(_ item: PhotosPickerItem) async {
        imageError = nil
        isProcessingImage = true
        defer { isProcessingImage = false }

        do {
            // Transferable yerine Data -> UIImage ile daha geniş uyumluluk
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await processPickedImage(image)
            } else {
                imageError = "Görsel yüklenemedi."
            }
        } catch {
            imageError = "Galeri hatası: \(error.localizedDescription)"
        }
    }

    // Büyük görselleri downscale + sıkıştırma (arka planda)
    private func processPickedImage(_ image: UIImage) async {
        await MainActor.run { isProcessingImage = true; imageError = nil }
        defer { Task { await MainActor.run { isProcessingImage = false } } }

        let maxDimension: CGFloat = 1600 // performans ve depolama için yeterli
        let compression: CGFloat = 0.85

        let processed: UIImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let scaled = image.downscaledIfNeeded(maxDimension: maxDimension)
                // JPEG dönüştür ve geri UIImage üret
                if let data = scaled.jpegData(compressionQuality: compression),
                   let final = UIImage(data: data) {
                    continuation.resume(returning: final)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        if let final = processed {
            await MainActor.run { self.selectedImage = final }
        } else {
            await MainActor.run { self.imageError = "Görsel işlenemedi." }
        }
    }

    // KAYDET — yerel dosyaya kaydedip file:// URL saklıyor
    func save() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        // Auth
        let userId: UUID
        do {
            let session = try await supabase.auth.session
            userId = session.user.id
        } catch {
            saveError = "Giriş yapmalısınız: \(error.localizedDescription)"
            return
        }

        // 1) (Opsiyonel) Görseli Belgeler klasörüne kaydet
        var localImageURLString: String? = nil
        if let image = selectedImage {
            do {
                localImageURLString = try await saveImageToDocuments(image: image, preferredExtension: "jpg", compression: 0.85)
            } catch {
                saveError = "Görsel kaydedilemedi: \(error.localizedDescription)"
                return
            }
        }

        // 2) Insert payload
        let payload = NewUserRecipe(
            userId: userId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : descriptionText,
            minutes: minutes,
            ingredients: ingredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : ingredients,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            isFavorite: isFavorite,
            isSpicy: isSpicy,
            cuisine: cuisine,
            difficulty: difficulty,
            imageUrl: localImageURLString
        )

        do {
            _ = try await supabase.database
                .from("user_recipes")
                .insert(payload)
                .select()
                .single()
                .execute()
            dismiss()
        } catch {
            saveError = "Kaydetme hatası: \(error.localizedDescription)"
        }
    }

    private func saveImageToDocuments(image: UIImage, preferredExtension: String = "jpg", compression: CGFloat = 0.85) async throws -> String {
        let filename = UUID().uuidString + "." + preferredExtension.lowercased()
        let url = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(filename)

        let data: Data
        if preferredExtension.lowercased() == "png" {
            guard let png = image.pngData() else {
                throw NSError(domain: "ImageSave", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG verisi üretilemedi"])
            }
            data = png
        } else {
            guard let jpg = image.jpegData(compressionQuality: compression) else {
                throw NSError(domain: "ImageSave", code: 2, userInfo: [NSLocalizedDescriptionKey: "JPEG verisi üretilemedi"])
            }
            data = jpg
        }

        try data.write(to: url, options: .atomic)
        return url.absoluteString
    }
}

private extension UIImage {
    func downscaledIfNeeded(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

