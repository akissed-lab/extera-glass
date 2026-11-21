import Foundation
import UIKit

/// Твики оформления и приватности в духе ExteraGram.
/// Все значения сохраняются в UserDefaults и применяются без перезапуска.
final class Tweaks {
    static let shared = Tweaks()
    private let defaults = UserDefaults.standard

    private enum Key {
        static let wallpaper = "extera.tweak.wallpaper"
        static let largeText = "extera.tweak.largeText"
        static let compact = "extera.tweak.compact"
        static let bubbleRadius = "extera.tweak.bubbleRadius"
        static let hidePhone = "extera.tweak.hidePhone"
        static let hideOnline = "extera.tweak.hideOnline"
        static let hideChecks = "extera.tweak.hideChecks"
        static let hideTime = "extera.tweak.hideTime"
        static let showSenderNames = "extera.tweak.showSenderNames"
    }

    private init() {
        defaults.register(defaults: [
            Key.wallpaper: true,
            Key.largeText: false,
            Key.compact: false,
            Key.bubbleRadius: 16,
            Key.hidePhone: false,
            Key.hideOnline: false,
            Key.hideChecks: false,
            Key.hideTime: false,
            Key.showSenderNames: true,
        ])
    }

    private func bool(_ key: String) -> Bool { defaults.bool(forKey: key) }
    private func set(_ value: Bool, _ key: String) {
        defaults.set(value, forKey: key)
        ThemeStore.shared.notify()
    }

    // Оформление
    var wallpaper: Bool {
        get { bool(Key.wallpaper) }
        set { set(newValue, Key.wallpaper) }
    }

    var largeText: Bool {
        get { bool(Key.largeText) }
        set { set(newValue, Key.largeText) }
    }

    var compactChatList: Bool {
        get { bool(Key.compact) }
        set { set(newValue, Key.compact) }
    }

    var bubbleRadius: CGFloat {
        get { CGFloat(defaults.integer(forKey: Key.bubbleRadius)) }
        set {
            defaults.set(Int(newValue), forKey: Key.bubbleRadius)
            ThemeStore.shared.notify()
        }
    }

    // Приватность / стиль
    var hidePhone: Bool {
        get { bool(Key.hidePhone) }
        set { set(newValue, Key.hidePhone) }
    }

    var hideOnline: Bool {
        get { bool(Key.hideOnline) }
        set { set(newValue, Key.hideOnline) }
    }

    var hideChecks: Bool {
        get { bool(Key.hideChecks) }
        set { set(newValue, Key.hideChecks) }
    }

    var hideTime: Bool {
        get { bool(Key.hideTime) }
        set { set(newValue, Key.hideTime) }
    }

    var showSenderNames: Bool {
        get { bool(Key.showSenderNames) }
        set { set(newValue, Key.showSenderNames) }
    }

    // MARK: - Шрифты

    func bodyFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: size * (largeText ? 1.15 : 1), weight: weight)
    }
}
