import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    // Görünümün boş bir yerine dokununca klavyeyi kapatmak için kolay kullanım
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}
