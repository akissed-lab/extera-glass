import UIKit

final class ComposeViewController: UITableViewController, UITextFieldDelegate {
    private let telegram: TDLibService
    private let field = UITextField()
    private var busy = false
    private var appearanceToken: AppearanceToken?

    init(telegram: TDLibService) {
        self.telegram = telegram
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новый чат"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        field.placeholder = "@username или ссылка t.me/..."
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .search
        field.delegate = self

        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }
        applyTheme()
    }

    private func applyTheme() {
        let theme = ThemeStore.shared.theme
        view.backgroundColor = theme.background
        tableView.backgroundColor = theme.background
        field.textColor = theme.primaryText
        applyNavigationBarTheme(navigationController?.navigationBar, theme: theme)
        tableView.reloadData()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        searchTapped()
    }

    @objc private func searchTapped() {
        let query = field.text ?? ""
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty, !busy else { return }
        telegram.errorMessage = nil
        busy = true
        tableView.reloadData()

        Task {
            let result = await telegram.searchPublicChat(query)
            await MainActor.run {
                busy = false
                if result != nil {
                    dismiss(animated: true)
                } else {
                    let message = telegram.errorMessage ?? "Чат не найден"
                    let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTapped()
        return true
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 1 ? "Поиск публичных каналов и групп по username." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let theme = ThemeStore.shared.theme
        cell.backgroundColor = theme.surface
        cell.accessoryView = nil

        if indexPath.section == 0 {
            cell.selectionStyle = .none
            field.translatesAutoresizingMaskIntoConstraints = false
            if field.superview !== cell.contentView {
                field.removeFromSuperview()
                cell.contentView.addSubview(field)
                NSLayoutConstraint.activate([
                    field.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                    field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                    field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                ])
            }
            field.attributedPlaceholder = NSAttributedString(
                string: "@username или ссылка t.me/...",
                attributes: [.foregroundColor: theme.secondaryText]
            )
        } else {
            cell.textLabel?.text = busy ? "Поиск…" : "Найти чат"
            cell.textLabel?.textColor = busy ? theme.secondaryText : theme.accent
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .default
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 { searchTapped() }
    }
}
