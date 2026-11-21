import UIKit
import TDLibKit

/// Бабл сообщения. Верстка через Auto Layout, поэтому высота считается автоматически.
final class MessageCell: UITableViewCell {
    private let bubble = UIView()
    private let stack = UIStackView()
    private let senderLabel = UILabel()
    private let mediaView = UIImageView()
    private let bodyLabel = UILabel()
    private let metaLabel = UILabel()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var mediaHeight: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layoutMargins = UIEdgeInsets(top: 7, left: 11, bottom: 6, right: 11)
        bubble.layer.cornerCurve = .continuous
        contentView.addSubview(bubble)

        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(stack)

        senderLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        senderLabel.numberOfLines = 1
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        metaLabel.font = .systemFont(ofSize: 11)
        metaLabel.numberOfLines = 1

        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 9
        mediaView.isHidden = true

        stack.addArrangedSubview(senderLabel)
        stack.addArrangedSubview(mediaView)
        stack.addArrangedSubview(bodyLabel)
        stack.addArrangedSubview(metaLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bubble.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bubble.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bubble.layoutMarginsGuide.bottomAnchor),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 310),
        ])

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        mediaHeight = mediaView.heightAnchor.constraint(equalToConstant: 150)
        mediaHeight.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mediaView.image = nil
        mediaView.isHidden = true
        senderLabel.isHidden = true
    }

    func configure(
        message: Message,
        chat: ChatItem?,
        telegram: TDLibService,
        theme: AppTheme,
        tweaks: Tweaks
    ) {
        let outgoing = message.isOutgoing
        leadingConstraint.isActive = !outgoing
        trailingConstraint.isActive = outgoing
        bubble.layer.cornerRadius = tweaks.bubbleRadius
        bubble.backgroundColor = outgoing ? theme.outgoingBubble : theme.incomingBubble

        let textColor = outgoing ? theme.outgoingText : theme.incomingText
        bodyLabel.textColor = textColor
        metaLabel.textColor = outgoing ? textColor.withAlphaComponent(0.75) : theme.timeText
        senderLabel.textColor = theme.accent

        if !outgoing && tweaks.showSenderNames, let chat, !chat.isPrivate {
            senderLabel.text = telegram.displayName(for: message.senderId)
            senderLabel.isHidden = false
        } else {
            senderLabel.isHidden = true
        }

        mediaView.image = nil
        mediaView.isHidden = true
        var fontSize: CGFloat = 15

        switch message.content {
        case .messageText(let text):
            bodyLabel.text = text.text.text

        case .messagePhoto(let photo):
            if let data = photo.photo.minithumbnail?.data, let image = UIImage(data: data) {
                mediaView.image = image
                mediaView.isHidden = false
            }
            bodyLabel.text = photo.caption.text

        case .messageSticker(let sticker):
            bodyLabel.text = sticker.sticker.emoji
            fontSize = 40

        case .messageVideo,
             .messageAnimation,
             .messageVoiceNote,
             .messageDocument,
             .messageLocation,
             .messageContact,
             .messagePoll:
            bodyLabel.text = message.previewText

        default:
            bodyLabel.text = message.previewText
        }

        bodyLabel.font = tweaks.bodyFont(size: fontSize)
        bodyLabel.isHidden = (bodyLabel.text ?? "").isEmpty

        var meta: [String] = []
        if message.editDate > 0 { meta.append("изм.") }
        if !tweaks.hideTime {
            let date = Date(timeIntervalSince1970: TimeInterval(message.date))
            meta.append(Self.timeFormatter.string(from: date))
        }
        if outgoing && !tweaks.hideChecks {
            meta.append(message.sendingState == nil ? "✓✓" : "◷")
        }
        metaLabel.text = meta.joined(separator: "  ")
        metaLabel.isHidden = meta.isEmpty
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

final class DateSeparatorCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, theme: AppTheme) {
        label.text = text
        label.textColor = .white
        label.backgroundColor = theme.serviceBubble
    }
}

final class LoadEarlierCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        label.text = "Загрузить раньше"
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(theme: AppTheme) {
        label.textColor = theme.accent
    }
}
