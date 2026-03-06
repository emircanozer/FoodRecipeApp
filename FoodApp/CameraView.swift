//
//  CameraView.swift
//  FoodApp
//
//  Created by Emircan Özer on 24.10.2025.
//

// CameraView.swift
// Bu dosya, UIKit'in kamerasını SwiftUI'da kullanmak için gereklidir.

import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera // Kamerayı kullan
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image // Çekilen resmi ContentView'a gönder
            }
            parent.isPresented = false // Kamerayı kapat
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false // Kamerayı kapat
        }
    }
}
#Preview {
    // Önizleme için .constant() kullanarak sahte bağlamalar oluşturun
    CameraView(
        selectedImage: .constant(nil),  // Sahte bir resim değişkeni (boş)
        isPresented: .constant(true)     // Sahte bir gösterim değişkeni (true)
    )
}
