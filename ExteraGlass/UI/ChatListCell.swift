import UIKit
import TDLibKit

/// Строка списка чатов в плотности Telegram: аватар 52pt, одна строка заголовка,
/// одна строка превью, бейдж непрочитанного справа.
final class ChatListCell: UITableViewCell {
    private let avatar = AvatarImageView()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let previewLabel = UILabel()
    private let badge = UnreadBadgeLabel()
    private let pinIcon = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let muteIcon = UIImageView(image: UIImage(systemName: "bell.slash.fill"))
    private let verifiedIcon = UIImageView(image: UIImage(systemName: "megaphone.fill"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatar)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(previewLabel)
        contentView.addSubview(badge)
        contentView.addSubview(pinIcon)
        contentView.addSubview(muteIcon)
        contentView.addSubview(verifiedIcon)

        avatar.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        muteIcon.translatesAutoresizingMaskIntoConstraints = false
        verifiedIcon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        previewLabel.font = .systemFont(ofSize: 15)
        previewLabel.numberOfLines = 1
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true
        for icon in [pinIcon, muteIcon, verifiedIcon] {
            icon.contentMode = .scaleAspectFit
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),

            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            badge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            badge.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),

            previewLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            previewLabel.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -8),
            previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            pinIcon.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            pinIcon.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -2),
            pinIcon.widthAnchor.constraint(equalToConstant: 11),
            pinIcon.heightAnchor.constraint(equalToConstant: 11),

            muteIcon.trailingAnchor.constraint(equalTo: badge.leadingAnchor, constant: -6),
            muteIcon.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),
            muteIcon.widthAnchor.constraint(equalToConstant: 12),
            muteIcon.heightAnchor.constraint(equalToConstant: 12),

            verifiedIcon.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -6),
            verifiedIcon.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            verifiedIcon.widthAnchor.constraint(equalToConstant: 12),
            verifiedIcon.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatar.configure(
            title: "", photo: nil, fileData: nil, size: 52,
            showOnline: false, theme: ThemeStore.shared.theme, tweaks: Tweaks.shared
        )
    }

    func configure(chat: ChatItem, telegram: TDLibService, theme: AppTheme, tweaks: Tweaks) {
        let fileData: Data? = chat.photo.flatMap { photo in
            telegram.files[photo.small.id]
        }
        avatar.configure(
            title: chat.title,
            photo: chat.photo,
            fileData: fileData,
            size: tweaks.compactChatList ? 46 : 52,
            showOnline: chat.isPrivate,
            theme: theme,
            tweaks: tweaks
        )

        titleLabel.text = chat.title
        titleLabel.font = tweaks.bodyFont(size: 16, weight: .semibold)
        titleLabel.textColor = theme.primaryText

        previewLabel.font = tweaks.bodyFont(size: 15)
        previewLabel.textColor = theme.secondaryText
        if let message = chat.lastMessage {
            timeLabel.text = Self.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(message.date)))
            let prefix = message.isOutgoing && !tweaks.hideChecks ? "Вы: " : ""
            previewLabel.text = prefix + message.previewText
        } else {
            timeLabel.text = ""
            previewLabel.text = "Нет сообщений"
        }
        timeLabel.textColor = theme.secondaryText

        let unread = chat.unreadCount
        badge.isHidden = unread == 0
        badge.text = unread > 99 ? "99+" : "\(unread)"
        badge.backgroundColor = theme.accent
        badge.textColor = .white

        pinIcon.isHidden = !chat.isPinned
        muteIcon.isHidden = !chat.isMuted || unread > 0
        verifiedIcon.isHidden = !chat.isChannel
        for icon in [pinIcon, muteIcon, verifiedIcon] { icon.tintColor = theme.secondaryText }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
