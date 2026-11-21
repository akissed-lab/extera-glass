import UIKit

/// Подписка на смену темы/твиков без @objc-селекторов — работает и в UIViewController, и в UITableViewController.
final class AppearanceToken {
    private let token: NSObjectProtocol

    init(_ body: @escaping () -> Void) {
        token = NotificationCenter.default.addObserver(
            forName: .exteraAppearanceDidChange,
            object: nil,
            queue: .main
        ) { _ in body() }
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}

func applyNavigationBarTheme(_ navigationBar: UINavigationBar?, theme: AppTheme) {
    guard let navigationBar else { return }
    navigationBar.barTintColor = theme.navigationBar
    navigationBar.tintColor = theme.accent
    navigationBar.isTranslucent = false
    navigationBar.titleTextAttributes = [.foregroundColor: theme.navigationTitle]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: theme.navigationTitle]
}

func applyTabBarTheme(_ tabBar: UITabBar?, theme: AppTheme) {
    guard let tabBar else { return }
    tabBar.barTintColor = theme.navigationBar
    tabBar.tintColor = theme.accent
    tabBar.isTranslucent = false
}

/// Анимированный бейдж непрочитанных сообщений.
final class UnreadBadgeLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let inset = UIEdgeInsets(top: 1, left: 7, bottom: 1, right: 7)
        super.drawText(in: rect.inset(by: inset))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 14, height: max(20, size.height + 2))
    }
}
