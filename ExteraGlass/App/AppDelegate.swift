import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    /// Держим сервис strongly: `TDLibService.shared` намеренно weak.
    private let telegram = TDLibService()
    private var appearanceToken: NSObjectProtocol?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootViewController(telegram: telegram)
        window.overrideUserInterfaceStyle = ThemeStore.shared.interfaceStyle
        window.makeKeyAndVisible()
        self.window = window

        appearanceToken = NotificationCenter.default.addObserver(
            forName: .exteraAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.overrideUserInterfaceStyle = ThemeStore.shared.interfaceStyle
        }
        return true
    }
}
