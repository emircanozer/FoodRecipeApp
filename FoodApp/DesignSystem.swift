import SwiftUI

enum AppColor {
    // Ana palet (birincil renk)
    static let primary = Color(red: 0.55, green: 0.35, blue: 0.95) // Lavender/Magenta ton
    static let primaryMuted = Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.12)

    // İkincil yüzey ve arka planlar
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let separator = Color(.separator)

    // Metin
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    // Durum renkleri
    static let destructive = Color.red
    static let successTint = Color.green.opacity(0.2)
    static let warningTint = Color.orange.opacity(0.2)

    // Sohbet baloncukları
    static let bubbleUser = primary
    static let bubbleAI = cardBackground

    // Çip/rozet
    static let chipBackground = Color(.tertiarySystemFill)
    static let chipForeground = textPrimary

    // İkon arkaplanları
    static let iconBackground = primaryMuted

    // Yeni: Tasarımda beklenen "secondary" yüzey rengi.
    // Mevcut kullanım alanları için yumuşak bir vurgu/arka plan olarak iconBackground ile eşliyoruz.
    static let secondary = iconBackground
}

enum AppFont {
    static func display() -> Font { .system(.largeTitle, design: .rounded).weight(.semibold) }
    static func titleLarge() -> Font { .system(.title2, design: .rounded).weight(.semibold) }
    static func title() -> Font { .system(.title3, design: .rounded).weight(.semibold) }
    static func body() -> Font { .system(.body, design: .rounded) }
    static func footnote() -> Font { .system(.footnote, design: .rounded) }
    static func button() -> Font { .system(.headline, design: .rounded) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button())
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(AppColor.primary)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppColor.primary.opacity(0.15), radius: 8, x: 0, y: 4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button())
            .foregroundColor(AppColor.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minHeight: 40)
            .background(AppColor.iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CircularIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let background: Color
    let foreground: Color

    init(size: CGFloat = 44, background: Color = Color.black.opacity(0.55), foreground: Color = .white) {
        self.size = size
        self.background = background
        self.foreground = foreground
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(12)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func cardPadding() -> some View {
        self.padding(.horizontal).padding(.top, 8)
    }
}

// Küçük rozet/pill yardımcıları
struct Pill: View {
    let text: String
    let systemImage: String?
    let emoji: String?

    init(_ text: String, systemImage: String? = nil, emoji: String? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.emoji = emoji
    }

    var body: some View {
        HStack(spacing: 6) {
            if let emoji { Text(emoji) }
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(AppFont.footnote())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.chipBackground)
        .clipShape(Capsule())
        .foregroundStyle(AppColor.chipForeground)
    }
}
