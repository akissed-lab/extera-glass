import UIKit
import Combine
import TDLibKit

/// Экран входа. Все состояния TDLib обрабатываются в одном VC,
/// поля переключаются без пересоздания иерархии.
final class AuthViewController: UIViewController {
    private let telegram: TDLibService
    private var cancellables = Set<AnyCancellable>()
    private var appearanceToken: AppearanceToken?
    private var busy = false
    private var action: (() -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let logoCircle = UIView()
    private let logoImage = UIImageView(image: UIImage(systemName: "paperplane.fill"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let phoneField = UITextField()
    private let codeField = UITextField()
    private let passwordField = UITextField()
    private let firstNameField = UITextField()
    private let lastNameField = UITextField()
    private let hintLabel = UILabel()
    private let linkLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let activity = UIActivityIndicatorView(style: .medium)

    init(telegram: TDLibService) {
        self.telegram = telegram
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }

        telegram.$authorizationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoCircle.layer.cornerRadius = logoCircle.bounds.height / 2
    }

    private func buildUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -28),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
        ])

        // Логотип
        let logoWrap = UIView()
        logoWrap.heightAnchor.constraint(equalToConstant: 104).isActive = true
        logoCircle.addSubview(logoImage)
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        logoImage.tintColor = .white
        NSLayoutConstraint.activate([
            logoImage.centerXAnchor.constraint(equalTo: logoCircle.centerXAnchor),
            logoImage.centerYAnchor.constraint(equalTo: logoCircle.centerYAnchor),
            logoImage.widthAnchor.constraint(equalToConstant: 42),
            logoImage.heightAnchor.constraint(equalToConstant: 42),
        ])
        logoWrap.addSubview(logoCircle)
        logoCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoCircle.centerXAnchor.constraint(equalTo: logoWrap.centerXAnchor),
            logoCircle.centerYAnchor.constraint(equalTo: logoWrap.centerYAnchor),
            logoCircle.widthAnchor.constraint(equalToConstant: 84),
            logoCircle.heightAnchor.constraint(equalToConstant: 84),
        ])
        stack.addArrangedSubview(logoWrap)

        titleLabel.text = "Extera"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(subtitleLabel)

        phoneField.placeholder = "Номер телефона"
        phoneField.keyboardType = .phonePad
        phoneField.textContentType = .telephoneNumber
        phoneField.autocorrectionType = .no
        codeField.placeholder = "Код из Telegram"
        codeField.keyboardType = .numberPad
        codeField.textContentType = .oneTimeCode
        passwordField.placeholder = "Пароль 2FA"
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .password
        firstNameField.placeholder = "Имя"
        firstNameField.textContentType = .givenName
        lastNameField.placeholder = "Фамилия"
        lastNameField.textContentType = .familyName

        for field in [phoneField, codeField, passwordField, firstNameField, lastNameField] {
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
            field.leftViewMode = .always
            field.heightAnchor.constraint(equalToConstant: 50).isActive = true
            stack.addArrangedSubview(field)
        }

        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.numberOfLines = 0
        stack.addArrangedSubview(hintLabel)

        linkLabel.font = .systemFont(ofSize: 13)
        linkLabel.numberOfLines = 0
        linkLabel.isHidden = true
        stack.addArrangedSubview(linkLabel)

        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.layer.cornerRadius = 14
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        stack.addArrangedSubview(actionButton)

        activity.hidesWhenStopped = true
        activity.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        stack.addArrangedSubview(activity)

        applyTheme()
    }

    private func applyTheme() {
        let theme = ThemeStore.shared.theme
        view.backgroundColor = theme.background
        logoCircle.backgroundColor = theme.accent
        titleLabel.textColor = theme.primaryText
        subtitleLabel.textColor = theme.secondaryText
        hintLabel.textColor = theme.secondaryText
        linkLabel.textColor = theme.accent
        for field in [phoneField, codeField, passwordField, firstNameField, lastNameField] {
            field.backgroundColor = theme.surfaceElevated
            field.textColor = theme.primaryText
            field.layer.cornerRadius = 12
            field.layer.borderWidth = 1
            field.layer.borderColor = theme.divider.cgColor
            field.attributedPlaceholder = NSAttributedString(
                string: field.placeholder ?? "",
                attributes: [.foregroundColor: theme.secondaryText]
            )
        }
        actionButton.backgroundColor = theme.accent
        actionButton.setTitleColor(.white, for: .normal)
        activity.color = theme.accent
    }

    // MARK: - Состояния

    private func render(_ state: AuthorizationState) {
        [phoneField, codeField, passwordField, firstNameField, lastNameField].forEach { $0.isHidden = true }
        hintLabel.isHidden = true
        linkLabel.isHidden = true
        actionButton.isHidden = true
        activity.isHidden = true
        action = nil

        switch state {
        case .authorizationStateWaitTdlibParameters:
            subtitleLabel.text = "Подключение к Telegram…"
            activity.isHidden = false
            activity.startAnimating()

        case .authorizationStateWaitPhoneNumber:
            subtitleLabel.text = "Введите номер — придёт код подтверждения"
            phoneField.isHidden = false
            configureAction(title: "Получить код") { [weak self] in
                guard let self else { return }
                Task {
                    await self.runBusy { await self.telegram.submitPhone(self.phoneField.text ?? "") }
                }
            }

        case .authorizationStateWaitCode(let info):
            subtitleLabel.text = "Введите код, который прислал Telegram"
            codeField.isHidden = false
            hintLabel.text = codeHint(info.codeInfo)
            hintLabel.isHidden = false
            configureAction(title: "Войти") { [weak self] in
                guard let self else { return }
                Task {
                    await self.runBusy { await self.telegram.submitCode(self.codeField.text ?? "") }
                }
            }

        case .authorizationStateWaitPassword(let info):
            subtitleLabel.text = "Введите пароль двухфакторной защиты"
            passwordField.isHidden = false
            if !info.passwordHint.isEmpty {
                hintLabel.text = "Подсказка: \(info.passwordHint)"
                hintLabel.isHidden = false
            }
            configureAction(title: "Подтвердить") { [weak self] in
                guard let self else { return }
                Task {
                    await self.runBusy { await self.telegram.submitPassword(self.passwordField.text ?? "") }
                }
            }

        case .authorizationStateWaitRegistration:
            subtitleLabel.text = "Создайте профиль"
            firstNameField.isHidden = false
            lastNameField.isHidden = false
            configureAction(title: "Завершить регистрацию") { [weak self] in
                guard let self else { return }
                Task {
                    await self.runBusy {
                        await self.telegram.register(
                            firstName: self.firstNameField.text ?? "",
                            lastName: self.lastNameField.text ?? ""
                        )
                    }
                }
            }

        case .authorizationStateWaitOtherDeviceConfirmation(let info):
            subtitleLabel.text = "Подтвердите вход на другом устройстве"
            linkLabel.text = info.link
            linkLabel.isHidden = false
            activity.isHidden = false
            activity.startAnimating()

        case .authorizationStateWaitEmailAddress:
            subtitleLabel.text = "Вход по email пока не поддерживается этим клиентом."

        case .authorizationStateWaitEmailCode:
            subtitleLabel.text = "Код из email пока не поддерживается этим клиентом."

        default:
            subtitleLabel.text = "Загрузка…"
            activity.isHidden = false
            activity.startAnimating()
        }
    }

    private func configureAction(title: String, handler: @escaping () -> Void) {
        actionButton.isHidden = false
        actionButton.setTitle(title, for: .normal)
        action = handler
        actionButton.isEnabled = !busy
    }

    @objc private func actionTapped() {
        action?()
    }

    private func runBusy(_ work: @escaping () async -> Void) async {
        busy = true
        actionButton.isEnabled = false
        activity.isHidden = false
        activity.startAnimating()
        await work()
        await MainActor.run {
            busy = false
            actionButton.isEnabled = true
            activity.stopAnimating()
            activity.isHidden = true
        }
    }

    private func codeHint(_ info: AuthenticationCodeInfo) -> String {
        switch info.type {
        case .authenticationCodeTypeTelegramMessage:
            return "Код отправлен приложением Telegram"
        case .authenticationCodeTypeSms,
             .authenticationCodeTypeSmsWord,
             .authenticationCodeTypeSmsPhrase:
            return "Код отправлен SMS"
        case .authenticationCodeTypeCall:
            return "Telegram позвонит вам"
        case .authenticationCodeTypeFlashCall:
            return "Flash call"
        case .authenticationCodeTypeMissedCall:
            return "Пропущенный звонок"
        case .authenticationCodeTypeFragment:
            return "Код через Fragment"
        case .authenticationCodeTypeFirebaseAndroid,
             .authenticationCodeTypeFirebaseIos:
            return "Код через Firebase"
        }
    }
}
