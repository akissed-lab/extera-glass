import Foundation
import UIKit

extension UIColor {
    /// Поддерживает #RRGGBB и #AARRGGBB (формат .attheme из ExteraGram).
    convenience init(hex: String) {
        var raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if raw.count == 6 { raw = "FF" + raw }
        guard raw.count == 8, let value = UInt64(raw, radix: 16) else {
            self.init(gray: 0.5, alpha: 1)
            return
        }
        let a = CGFloat((value >> 24) & 0xFF) / 255
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

struct AppTheme {
    let key: String
    let displayName: String
    let isDark: Bool

    let accent: UIColor
    let background: UIColor
    let surface: UIColor
    let surfaceElevated: UIColor
    let navigationBar: UIColor
    let navigationTitle: UIColor
    let primaryText: UIColor
    let secondaryText: UIColor
    let incomingBubble: UIColor
    let outgoingBubble: UIColor
    let incomingText: UIColor
    let outgoingText: UIColor
    let timeText: UIColor
    let serviceBubble: UIColor
    let inputBackground: UIColor
    let chatBackground: UIColor
    let divider: UIColor

    init?(key: String, tokens: [String: String]) {
        func color(_ name: String) -> UIColor {
            UIColor(hex: tokens[name] ?? "#888888")
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

extension Notification.Name {
    static let exteraAppearanceDidChange = Notification.Name("extera.appearance.didChange")
}

final class ThemeStore {
    static let shared = ThemeStore()
    private let defaults = UserDefaults.standard
    private let themeKey = "extera.theme"

    private init() {
        defaults.register(defaults: ["extera.theme": "night"])
    }

    var currentKey: String {
        get { defaults.string(forKey: themeKey) ?? "night" }
        set {
            defaults.set(newValue, forKey: themeKey)
            notify()
        }
    }

    var theme: AppTheme { AppTheme.theme(for: currentKey) }
    var interfaceStyle: UIUserInterfaceStyle { theme.isDark ? .dark : .light }

    func select(_ theme: AppTheme) {
        currentKey = theme.key
    }

    func notify() {
        NotificationCenter.default.post(name: .exteraAppearanceDidChange, object: nil)
    }
}
