import UIKit

final class MainTabBarController: UITabBarController {
    private let telegram: TDLibService
    private var appearanceToken: AppearanceToken?

    init(telegram: TDLibService) {
        self.telegram = telegram
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let chats = UINavigationController(rootViewController: ChatListViewController(telegram: telegram))
        chats.navigationBar.prefersLargeTitles = true
        chats.tabBarItem = UITabBarItem(
            title: "Чаты",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        let saved = UINavigationController(
            rootViewController: ChatViewController(
                chatId: 0,
                telegram: telegram,
                waitForCurrentUser: true
            )
        )
        saved.tabBarItem = UITabBarItem(
            title: "Сохранённое",
            image: UIImage(systemName: "bookmark"),
            selectedImage: UIImage(systemName: "bookmark.fill")
        )

        let settings = UINavigationController(rootViewController: SettingsViewController(telegram: telegram))
        settings.navigationBar.prefersLargeTitles = true
        settings.tabBarItem = UITabBarItem(
            title: "Настройки",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [chats, saved, settings]
        selectedIndex = 0

        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }
        applyTheme()
    }

    private func applyTheme() {
        let theme = ThemeStore.shared.theme
        applyTabBarTheme(tabBar, theme: theme)
        view.backgroundColor = theme.background
        for navigationController in viewControllers?.compactMap({ $0 as? UINavigationController }) ?? [] {
            applyNavigationBarTheme(navigationController.navigationBar, theme: theme)
        }
    }
}
