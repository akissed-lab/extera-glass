import UIKit
import Combine
import TDLibKit

/// Корневой контейнер: авторизация <-> основной интерфейс.
final class RootViewController: UIViewController {
    private let telegram: TDLibService
    private var current: UIViewController?
    private var cancellables = Set<AnyCancellable>()
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
        view.backgroundColor = ThemeStore.shared.theme.background
        appearanceToken = AppearanceToken { [weak self] in
            self?.view.backgroundColor = ThemeStore.shared.theme.background
        }

        telegram.$authorizationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.update(for: state) }
            .store(in: &cancellables)
    }

    private func update(for state: AuthorizationState) {
        if shouldShowMain(for: state) {
            if !(current is MainTabBarController) {
                show(MainTabBarController(telegram: telegram))
            }
        } else if !(current is AuthViewController) {
            show(AuthViewController(telegram: telegram))
        }
    }

    /// После успешного входа сессия живёт в локальной базе TDLib.
    /// Пока сервер не ответил, показываем основной экран, если вход уже был раньше.
    private func shouldShowMain(for state: AuthorizationState) -> Bool {
        switch state {
        case .authorizationStateReady:
            return true
        case .authorizationStateWaitPhoneNumber,
             .authorizationStateWaitCode,
             .authorizationStateWaitPassword,
             .authorizationStateWaitRegistration,
             .authorizationStateWaitOtherDeviceConfirmation,
             .authorizationStateWaitEmailAddress,
             .authorizationStateWaitEmailCode,
             .authorizationStateLoggingOut,
             .authorizationStateClosing:
            return false
        case .authorizationStateWaitTdlibParameters:
            return telegram.hasActiveSession
        default:
            return telegram.hasActiveSession
        }
    }

    private func show(_ viewController: UIViewController) {
        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        addChild(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        current = viewController
    }
}
