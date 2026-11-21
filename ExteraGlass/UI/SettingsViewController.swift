import UIKit

final class SettingsViewController: UITableViewController {
    private let telegram: TDLibService
    private let themeStore = ThemeStore.shared
    private let tweaks = Tweaks.shared
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
        title = "Настройки"
        navigationItem.largeTitleDisplayMode = .always
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        appearanceToken = AppearanceToken { [weak self] in self?.applyTheme() }
        applyTheme()
    }

    private func applyTheme() {
        let theme = themeStore.theme
        view.backgroundColor = theme.background
        tableView.backgroundColor = theme.background
        applyNavigationBarTheme(navigationController?.navigationBar, theme: theme)
        tableView.reloadData()
    }

    private func switchCell(title: String, isOn: Bool, tag: Int, theme: AppTheme) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = title
        cell.textLabel?.textColor = theme.primaryText
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        let control = UISwitch(frame: .zero)
        control.isOn = isOn
        control.onTintColor = theme.accent
        control.tag = tag
        control.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = control
        return cell
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 1: tweaks.wallpaper = sender.isOn
        case 2: tweaks.largeText = sender.isOn
        case 3: tweaks.compactChatList = sender.isOn
        case 4: tweaks.hidePhone = sender.isOn
        case 5: tweaks.hideOnline = sender.isOn
        case 6: tweaks.hideChecks = sender.isOn
        case 7: tweaks.hideTime = sender.isOn
        case 8: tweaks.showSenderNames = sender.isOn
        default: break
        }
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        tweaks.bubbleRadius = CGFloat(6 + sender.value * 20)
    }

    // MARK: - UITableView

    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 5
        case 2: return 5
        default: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Оформление"
        case 2: return "Приватность и стиль"
        case 3: return "О приложении"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theme = themeStore.theme
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.textColor = theme.primaryText
        cell.detailTextLabel?.textColor = theme.secondaryText
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let user = telegram.currentUser
                let name = user.map { [$0.firstName, $0.lastName].filter { !$0.isEmpty }.joined(separator: " ") } ?? "Загрузка…"
                let username = user?.usernames?.activeUsernames.first ?? ""
                cell.textLabel?.text = name
                cell.detailTextLabel?.text = tweaks.hidePhone || username.isEmpty ? "Профиль" : "@\(username)"
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.text = "Выйти из аккаунта"
                cell.textLabel?.textColor = .systemRed
                cell.detailTextLabel?.text = nil
            }
            return cell

        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Тема"
                cell.detailTextLabel?.text = themeStore.theme.displayName
                cell.accessoryType = .disclosureIndicator
                return cell
            case 1: return switchCell(title: "Обои чата", isOn: tweaks.wallpaper, tag: 1, theme: theme)
            case 2: return switchCell(title: "Крупный текст", isOn: tweaks.largeText, tag: 2, theme: theme)
            case 3: return switchCell(title: "Компактный список", isOn: tweaks.compactChatList, tag: 3, theme: theme)
            default:
                cell.textLabel?.text = "Радиус баблов"
                cell.detailTextLabel?.text = nil
                let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 140, height: 30))
                slider.minimumValue = 0
                slider.maximumValue = 1
                slider.value = Float((tweaks.bubbleRadius - 6) / 20)
                slider.tintColor = theme.accent
                slider.tag = 100
                slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
                cell.accessoryView = slider
                cell.selectionStyle = .none
                return cell
            }

        case 2:
            switch indexPath.row {
            case 0: return switchCell(title: "Скрывать номер", isOn: tweaks.hidePhone, tag: 4, theme: theme)
            case 1: return switchCell(title: "Скрывать онлайн", isOn: tweaks.hideOnline, tag: 5, theme: theme)
            case 2: return switchCell(title: "Скрывать галочки", isOn: tweaks.hideChecks, tag: 6, theme: theme)
            case 3: return switchCell(title: "Скрывать время", isOn: tweaks.hideTime, tag: 7, theme: theme)
            default: return switchCell(title: "Имена в группах", isOn: tweaks.showSenderNames, tag: 8, theme: theme)
            }

        default:
            cell.textLabel?.text = "Неофициальный клиент на TDLib"
            cell.detailTextLabel?.text = "Темы и твики из ExteraGram. Собственные api_id / api_hash в Config.swift."
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 1 {
            let alert = UIAlertController(
                title: "Выйти из аккаунта?",
                message: "Локальная база TDLib останется на устройстве.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
                Task { await self?.telegram.logout() }
            })
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        } else if indexPath.section == 1 && indexPath.row == 0 {
            navigationController?.pushViewController(ThemeSelectionViewController(), animated: true)
        }
    }
}
