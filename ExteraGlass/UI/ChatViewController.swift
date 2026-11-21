import UIKit
import Combine
import TDLibKit

final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private enum MessageRow {
        case loadEarlier
        case date(String)
        case message(Message)
    }

    private let telegram: TDLibService
    private var chatId: Int64
    private let waitForCurrentUser: Bool

    private var rows: [MessageRow] = []
    private var lastReloadKey = ""
    private var cancellables = Set<AnyCancellable>()
    private var appearanceToken: AppearanceToken?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let attachButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottom: NSLayoutConstraint!
    private let titleView = ChatTitleView()

    init(chatId: Int64, telegram: TDLibService, waitForCurrentUser: Bool = false) {
        self.chatId = chatId
        self.telegram = telegram
        self.waitForCurrentUser = waitForCurrentUser
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }

        navigationItem.titleView = titleView
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        telegram.$chats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)

        telegram.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadMessages() }
            .store(in: &cancellables)

        if waitForCurrentUser {
            telegram.$currentUser
                .receive(on: DispatchQueue.main)
                .sink { [weak self] user in
                    guard let id = user?.id, id != 0 else { return }
                    self?.setChatId(id)
                }
                .store(in: &cancellables)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        applyTheme()
        updateTitle()
        if chatId != 0 { load() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let keyboardVisible = inputBottom.constant < -1
        inputBar.layoutMargins.bottom = keyboardVisible ? 8 : 8 + view.safeAreaInsets.bottom
    }

    private func buildUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "message")
        tableView.register(DateSeparatorCell.self, forCellReuseIdentifier: "date")
        tableView.register(LoadEarlierCell.self, forCellReuseIdentifier: "earlier")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 8, right: 0)
        view.addSubview(tableView)

        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        attachButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        attachButton.tintColor = ThemeStore.shared.theme.secondaryText
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)

        textField.placeholder = "Сообщение"
        textField.returnKeyType = .send
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        sendButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        let barStack = UIStackView(arrangedSubviews: [attachButton, textField, sendButton])
        barStack.axis = .horizontal
        barStack.spacing = 8
        barStack.alignment = .center
        barStack.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(barStack)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            attachButton.widthAnchor.constraint(equalToConstant: 32),
            attachButton.heightAnchor.constraint(equalToConstant: 32),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            textField.heightAnchor.constraint(equalToConstant: 38),

            barStack.topAnchor.constraint(equalTo: inputBar.layoutMarginsGuide.topAnchor),
            barStack.leadingAnchor.constraint(equalTo: inputBar.layoutMarginsGuide.leadingAnchor),
            barStack.trailingAnchor.constraint(equalTo: inputBar.layoutMarginsGuide.trailingAnchor),
            barStack.bottomAnchor.constraint(equalTo: inputBar.layoutMarginsGuide.bottomAnchor),
        ])

        inputBottom = inputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottom,
        ])
    }

    private func setChatId(_ id: Int64) {
        guard id != chatId else { return }
        chatId = id
        lastReloadKey = ""
        updateTitle()
        load()
    }

    private func load() {
        telegram.open(chatId: chatId)
        Task { await telegram.loadMessages(chatId: chatId) }
    }

    private func updateTitle() {
        let chat = telegram.chats.first { $0.id == chatId }
        let name = chat?.title ?? (waitForCurrentUser ? "Сохранённое сообщение" : "Чат")
        var detail = ""
        if let chat {
            if chat.isChannel { detail = "канал" }
            else if chat.isPrivate { detail = Tweaks.shared.hideOnline ? "" : "онлайн" }
            else { detail = "группа" }
        }
        titleView.configure(title: name, subtitle: detail, theme: ThemeStore.shared.theme)
    }

    private func applyTheme() {
        let theme = ThemeStore.shared.theme
        if Tweaks.shared.wallpaper {
            view.backgroundColor = UIColor(patternImage: Wallpaper.pattern(for: theme))
        } else {
            view.backgroundColor = theme.chatBackground
        }
        tableView.backgroundColor = .clear
        inputBar.backgroundColor = theme.inputBackground
        inputBar.layer.borderColor = theme.divider.cgColor
        inputBar.layer.borderWidth = 0.5
        textField.textColor = theme.primaryText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Сообщение",
            attributes: [.foregroundColor: theme.secondaryText]
        )
        attachButton.tintColor = theme.secondaryText
        sendButton.backgroundColor = theme.accent
        sendButton.layer.cornerRadius = 18
        applyNavigationBarTheme(navigationController?.navigationBar, theme: theme)
        updateTitle()
        tableView.reloadData()
    }

    // MARK: - Данные

    private func reloadMessages() {
        let list = telegram.messages[chatId] ?? []
        let key = "\(list.count):\(list.first?.id ?? 0):\(list.last?.id ?? 0)"
        guard key != lastReloadKey else { return }
        lastReloadKey = key

        let oldHeight = tableView.contentSize.height
        let oldOffset = tableView.contentOffset.y
        let atBottom = oldOffset + tableView.bounds.height >= oldHeight - 80

        rows = Self.buildRows(from: list)
        tableView.reloadData()

        if atBottom || rows.count < 3 {
            scrollToBottom()
        } else {
            let newHeight = tableView.contentSize.height
            tableView.contentOffset.y = oldOffset + (newHeight - oldHeight)
        }
    }

    private static func buildRows(from messages: [Message]) -> [MessageRow] {
        guard !messages.isEmpty else { return [] }
        var result: [MessageRow] = []
        if messages.count >= 50 { result.append(.loadEarlier) }
        var previousDay = ""
        for message in messages {
            let day = dayTitle(message.date)
            if day != previousDay {
                result.append(.date(day))
                previousDay = day
            }
            result.append(.message(message))
        }
        return result
    }

    private static func dayTitle(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Сегодня" }
        if calendar.isDateInYesterday(date) { return "Вчера" }
        return formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func scrollToBottom() {
        guard !rows.isEmpty else { return }
        let indexPath = IndexPath(row: rows.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theme = ThemeStore.shared.theme
        switch rows[indexPath.row] {
        case .loadEarlier:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "earlier", for: indexPath) as? LoadEarlierCell else {
                return UITableViewCell()
            }
            cell.configure(theme: theme)
            return cell

        case .date(let text):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "date", for: indexPath) as? DateSeparatorCell else {
                return UITableViewCell()
            }
            cell.configure(text: text, theme: theme)
            return cell

        case .message(let message):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "message", for: indexPath) as? MessageCell else {
                return UITableViewCell()
            }
            let chat = telegram.chats.first { $0.id == chatId }
            cell.configure(
                message: message,
                chat: chat,
                telegram: telegram,
                theme: theme,
                tweaks: Tweaks.shared
            )
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .loadEarlier = rows[indexPath.row] {
            Task { await telegram.loadMoreMessages(chatId: chatId) }
        }
        view.endEditing(true)
    }

    // MARK: - Ввод

    @objc private func textChanged() {
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        sendButton.setImage(
            UIImage(systemName: hasText ? "arrow.up" : "mic.fill"),
            for: .normal
        )
    }

    @objc private func sendTapped() {
        let text = textField.text ?? ""
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        textField.text = ""
        textChanged()
        Task { await telegram.sendText(text, to: chatId) }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }

    @objc private func attachTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Сообщение", style: .default))
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.sourceView = attachButton
        present(sheet, animated: true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let height = max(0, view.bounds.height - frame.origin.y)
        inputBottom.constant = -height
        inputBar.layoutMargins.bottom = height > 0 ? 8 : 8 + view.safeAreaInsets.bottom
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        if height == 0 { scrollToBottom() }
    }
}

private final class ChatTitleView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String, theme: AppTheme) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        titleLabel.textColor = theme.navigationTitle
        subtitleLabel.textColor = theme.secondaryText
    }
}
