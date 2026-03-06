//
//  PhotoLibraryView.swift
//  FoodApp
//
//  Created by Emircan Özer on 26.10.2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct PhotoLibraryView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoLibraryView

        init(_ parent: PhotoLibraryView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { parent.isPresented = false }

            guard let provider = results.first?.itemProvider else { return }

            // Try to load UIImage directly
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    guard let image = object as? UIImage else { return }
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image
                    }
                }
                return
            }

            // Fallback: load data representation
            let typeIdentifiers = provider.registeredTypeIdentifiers
            guard let typeId = typeIdentifiers.first else { return }

            provider.loadDataRepresentation(forTypeIdentifier: typeId) { [weak self] data, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.parent.selectedImage = image
                }
            }
        }
    }
}

#Preview {
    PhotoLibraryView(
        selectedImage: .constant(nil),
        isPresented: .constant(true)
    )
}
