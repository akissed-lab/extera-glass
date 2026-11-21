import UIKit

final class ThemeSelectionViewController: UITableViewController {
    private let themeStore = ThemeStore.shared
    private var appearanceToken: AppearanceToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Тема"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "theme")
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AppTheme.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "theme", for: indexPath)
        let theme = AppTheme.all[indexPath.row]
        let selected = theme.key == themeStore.currentKey
        cell.textLabel?.text = (selected ? "✓  " : "      ") + theme.displayName
        cell.textLabel?.textColor = themeStore.theme.primaryText
        cell.backgroundColor = themeStore.theme.surface

        let swatches = UIView(frame: CGRect(x: 0, y: 0, width: 76, height: 28))
        let colors = [theme.accent, theme.incomingBubble, theme.outgoingBubble, theme.chatBackground]
        for (index, color) in colors.enumerated() {
            let chip = UIView(frame: CGRect(x: index * 19, y: 0, width: 16, height: 28))
            chip.backgroundColor = color
            chip.layer.cornerRadius = 4
            chip.layer.borderWidth = 0.5
            chip.layer.borderColor = UIColor.separator.cgColor
            swatches.addSubview(chip)
        }
        cell.accessoryView = swatches
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        themeStore.select(AppTheme.all[indexPath.row])
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
}
