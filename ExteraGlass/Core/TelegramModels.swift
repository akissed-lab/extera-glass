import Foundation
import TDLibKit

/// Упрощённая модель чата: TDLib-структуры неизменяемы, поэтому для UI
/// храним только нужные поля и обновляем их точечно через апдейты.
struct ChatItem: Identifiable, Hashable {
    let id: Int64
    var title: String
    var lastMessage: Message?
    var unreadCount: Int
    var unreadMentionCount: Int
    var isPinned: Bool
    var isMuted: Bool
    var photo: ChatPhotoInfo?
    var type: ChatType
    var order: Int64
    var accentColorId: Int

    init(_ chat: Chat) {
        id = chat.id
        title = chat.title
        lastMessage = chat.lastMessage
        unreadCount = chat.unreadCount
        unreadMentionCount = chat.unreadMentionCount
        photo = chat.photo
        type = chat.type
        accentColorId = chat.accentColorId
        let mainPosition = chat.positions.first { position in
            if case .chatListMain = position.list { return true }
            return false
        } ?? chat.positions.first
        isPinned = mainPosition?.isPinned ?? false
        isMuted = chat.notificationSettings.muteFor > 0
        order = mainPosition?.order.rawValue ?? 0
    }

    var isChannel: Bool {
        if case .chatTypeSupergroup(let group) = type { return group.isChannel }
        return false
    }

    var isPrivate: Bool {
        if case .chatTypePrivate = type { return true }
        if case .chatTypeSecret = type { return true }
        return false
    }

    var placeholder: String {
        let words = title.split(separator: " ")
        let first = words.first?.first.map(String.init) ?? "?"
        let second = words.count > 1 ? words[1].first.map(String.init) ?? "" : ""
        return first + second
    }
}

extension Message {
    var isOutgoing: Bool {
        if case .messageSenderUser(let sender) = senderId {
            return sender.userId == TDLibService.shared?.currentUserId
        }
        return false
    }

    var previewText: String {
        switch content {
        case .messageText(let text):
            return text.text.text
        case .messagePhoto(let photo):
            return photo.caption.text.isEmpty ? "📷 Фото" : "📷 \(photo.caption.text)"
        case .messageVideo(let video):
            return video.caption.text.isEmpty ? "🎬 Видео" : "🎬 \(video.caption.text)"
        case .messageSticker(let sticker):
            return "\(sticker.sticker.emoji) Стикер"
        case .messageAnimation:
            return "🎞 GIF"
        case .messageVoiceNote:
            return "🎤 Голосовое сообщение"
        case .messageDocument(let document):
            return "📎 \(document.document.fileName)"
        case .messageLocation:
            return "📍 Геолокация"
        case .messageContact:
            return "👤 Контакт"
        case .messagePoll(let poll):
            return "📊 \(poll.poll.question.text)"
        default:
            return "Сообщение"
        }
    }
}

extension MessageSender {
    var userId: Int64? {
        if case .messageSenderUser(let sender) = self { return sender.userId }
        return nil
    }
}
