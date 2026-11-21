import SwiftUI

extension Color {
    /// Поддерживает #RRGGBB и #AARRGGBB (формат .attheme из ExteraGram).
    init(hex: String) {
        let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard let value = UInt64(raw, radix: 16) else {
            self = .gray
            return
        }
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        if raw.count >= 8 {
            a = (value >> 24) & 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        } else {
            a = 0xFF
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        }
        self = Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AppTheme {
    let key: String
    let displayName: String
    let isDark: Bool

    let accent: Color
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let navigationBar: Color
    let navigationTitle: Color
    let primaryText: Color
    let secondaryText: Color
    let incomingBubble: Color
    let outgoingBubble: Color
    let incomingText: Color
    let outgoingText: Color
    let timeText: Color
    let serviceBubble: Color
    let inputBackground: Color
    let chatBackground: Color
    let divider: Color

    init?(key: String, tokens: [String: String]) {
        func color(_ name: String) -> Color {
            Color(hex: tokens[name] ?? "#888888")
        }
        self.key = key
        self.displayName = tokens["displayName"] ?? key
        self.isDark = Bool(tokens["isDark"] ?? "") ?? false
        accent = color("accent")
        background = color("background")
        surface = color("surface")
        surfaceElevated = color("surfaceElevated")
        navigationBar = color("navigationBar")
        navigationTitle = color("navigationTitle")
        primaryText = color("primaryText")
        secondaryText = color("secondaryText")
        incomingBubble = color("incomingBubble")
        outgoingBubble = color("outgoingBubble")
        incomingText = color("incomingText")
        outgoingText = color("outgoingText")
        timeText = color("timeText")
        serviceBubble = color("serviceBubble")
        inputBackground = color("inputBackground")
        chatBackground = color("chatBackground")
        divider = color("divider")
    }

    static let all: [AppTheme] = ThemeTokens.all.compactMap { key, tokens in
        AppTheme(key: key, tokens: tokens)
    }.sorted { $0.displayName < $1.displayName }

    static func theme(for key: String) -> AppTheme {
        all.first { $0.key == key } ?? all.first { $0.key == "night" } ?? all[0]
    }
}

final class ThemeStore: ObservableObject {
    @AppStorage("extera.theme") var themeKey: String = "night"
    @AppStorage("extera.glass") var glassEnabled: Bool = true
    @AppStorage("extera.glass.intensity") var glassIntensity: Double = 0.8
    @AppStorage("extera.showStories") var showStories: Bool = true

    var theme: AppTheme { AppTheme.theme(for: themeKey) }
    var colorScheme: ColorScheme { theme.isDark ? .dark : .light }

    func select(_ theme: AppTheme) {
        themeKey = theme.key
    }
}
