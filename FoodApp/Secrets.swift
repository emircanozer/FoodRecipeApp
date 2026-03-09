import Foundation

enum Secrets {
    private static var secrets: [String: Any]? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return dict
    }

    static var geminiAPIKey: String {
        return secrets?["GeminiAPIKey"] as? String ?? ""
    }

    static var supabaseURL: URL {
        let urlString = secrets?["SupabaseURL"] as? String ?? ""
        return URL(string: urlString) ?? URL(string: "https://example.com")!
    }

    static var supabaseAnonKey: String {
        return secrets?["SupabaseAnonKey"] as? String ?? ""
    }
}
