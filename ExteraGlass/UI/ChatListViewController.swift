import UIKit
import Combine
import TDLibKit

final class ChatListViewController: UITableViewController {
    private enum Row {
        case chat(ChatItem)
        case remoteSearch(String)
    }

    private let telegram: TDLibService
    private var rows: [Row] = []
    private var allChats: [ChatItem] = []
    private var query = ""
    private var cancellables = Set<AnyCancellable>()
    private var appearanceToken: AppearanceToken?
    private let searchController = UISearchController(searchResultsController: nil)

    init(telegram: TDLibService) {
        self.telegram = telegram
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Чаты"
        navigationItem.largeTitleDisplayMode = .always
        tableView.register(ChatListCell.self, forCellReuseIdentifier: "chat")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(openMenu)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(openCompose)
        )

        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }

        telegram.$chats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chats in
                self?.allChats = chats
                self?.applyFilter()
            }
            .store(in: &cancellables)

        telegram.$files
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        applyTheme()
        applyFilter()
    }

    private func applyTheme() {
        let theme = ThemeStore.shared.theme
        view.backgroundColor = theme.background
        tableView.backgroundColor = theme.background
        tableView.separatorColor = theme.divider
        applyNavigationBarTheme(navigationController?.navigationBar, theme: theme)
    }

    private func applyFilter() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        var result: [Row]
        if trimmed.isEmpty {
            result = allChats.map { .chat($0) }
        } else {
            let needle = trimmed.lowercased()
            result = allChats.filter { $0.title.lowercased().contains(needle) }.map { .chat($0) }
            result.insert(.remoteSearch(trimmed), at: 0)
        }
        rows = result
        tableView.reloadData()
    }

    // MARK: - Действия

    @objc private func openMenu() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Сохранённые сообщения", style: .default) { [weak self] _ in
            self?.tabBarController?.selectedIndex = 1
        })
        sheet.addAction(UIAlertAction(title: "Настройки и темы", style: .default) { [weak self] _ in
            self?.tabBarController?.selectedIndex = 2
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        present(sheet, animated: true)
    }

    @objc private func openCompose() {
        let compose = UINavigationController(rootViewController: ComposeViewController(telegram: telegram))
        present(compose, animated: true)
    }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Tweaks.shared.compactChatList ? 62 : 74
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .chat(let chat):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "chat", for: indexPath) as? ChatListCell else {
                return UITableViewCell()
            }
            cell.configure(
                chat: chat,
                telegram: telegram,
                theme: ThemeStore.shared.theme,
                tweaks: Tweaks.shared
            )
            if let photo = chat.photo, telegram.files[photo.small.id] == nil {
                Task { await telegram.downloadFile(photo.small.id) }
            }
            return cell

        case .remoteSearch(let text):
            let cell = UITableViewCell(style: .default, reuseIdentifier: "remote")
            cell.textLabel?.text = "Найти @\(text.trimmingCharacters(in: .whitespaces))"
            cell.textLabel?.textColor = ThemeStore.shared.theme.accent
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .chat(let chat):
            let vc = ChatViewController(chatId: chat.id, telegram: telegram)
            navigationController?.pushViewController(vc, animated: true)

        case .remoteSearch(let text):
            telegram.errorMessage = nil
            Task {
                if let chat = await telegram.searchPublicChat(text) {
                    await MainActor.run {
                        let vc = ChatViewController(chatId: chat.id, telegram: telegram)
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
    }
}

extension ChatListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""
        applyFilter()
    }
}
