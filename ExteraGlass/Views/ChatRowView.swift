import SwiftUI

struct ChatRowView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let chat: ChatItem

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                title: chat.title,
                photo: chat.photo,
                size: 54,
                showOnline: chat.isPrivate
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(chat.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeStore.theme.primaryText)
                        .lineLimit(1)
                    if chat.isChannel {
                        Image(systemName: "megaphone.fill")
                            .font(.caption2)
                            .foregroundStyle(themeStore.theme.secondaryText)
                    }
                    Spacer(minLength: 4)
                    if let message = chat.lastMessage {
                        Text(Self.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(message.date))))
                            .font(.caption2)
                            .foregroundStyle(themeStore.theme.secondaryText)
                    }
                }

                HStack(spacing: 6) {
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(themeStore.theme.secondaryText)
                    }
                    Text(preview)
                        .font(.subheadline)
                        .foregroundStyle(themeStore.theme.secondaryText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if chat.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(themeStore.theme.secondaryText)
                    }
                    if chat.unreadCount > 0 {
                        Text(chat.unreadCount > 99 ? "99+" : "\(chat.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(themeStore.theme.accent, in: Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if themeStore.glassEnabled {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeStore.theme.surface)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(themeStore.theme.divider.opacity(0.5), lineWidth: 0.5)
        }
    }

    private var preview: String {
        guard let message = chat.lastMessage else { return "Нет сообщений" }
        let prefix = message.isOutgoing ? "Вы: " : ""
        return prefix + message.previewText
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
