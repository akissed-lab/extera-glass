import Foundation
import SwiftUI
import TDLibKit

struct MessageBubbleView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var telegram: TDLibService

    let message: Message
    let chat: ChatItem?

    private var outgoing: Bool { message.isOutgoing }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if outgoing { Spacer(minLength: 40) }

            VStack(alignment: outgoing ? .trailing : .leading, spacing: 4) {
                if !outgoing, let chat, !chat.isPrivate {
                    Text(telegram.displayName(for: message.senderId))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(themeStore.theme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    content
                    meta
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(bubbleColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(bubbleBorder, lineWidth: 0.6)
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                .contextMenu {
                    Button("Копировать текст") {
                        UIPasteboard.general.string = message.previewText
                    }
                }
            }
            .frame(maxWidth: 320, alignment: outgoing ? .trailing : .leading)

            if !outgoing { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.content {
        case .messageText(let text):
            Text(text.text.text)
                .font(.body)
                .foregroundStyle(outgoing ? themeStore.theme.outgoingText : themeStore.theme.incomingText)
                .textSelection(.enabled)

        case .messagePhoto(let photo):
            if let data = photo.photo.minithumbnail?.data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 240, height: 170)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                mediaPlaceholder(icon: "photo", text: "Фото")
            }
            if !photo.caption.text.isEmpty {
                Text(photo.caption.text)
                    .font(.subheadline)
                    .foregroundStyle(outgoing ? themeStore.theme.outgoingText : themeStore.theme.incomingText)
            }

        case .messageVideo(let video):
            mediaPlaceholder(icon: "play.rectangle.fill", text: "Видео")
            if !video.caption.text.isEmpty {
                Text(video.caption.text).font(.subheadline)
            }

        case .messageSticker(let sticker):
            Text(sticker.sticker.emoji)
                .font(.system(size: 64))

        case .messageAnimation:
            mediaPlaceholder(icon: "bolt.fill", text: "GIF")

        case .messageVoiceNote(let voice):
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill").font(.title2)
                WaveformBars(duration: Int(voice.voiceNote.duration))
            }
            .foregroundStyle(outgoing ? themeStore.theme.outgoingText : themeStore.theme.incomingText)

        case .messageDocument(let document):
            HStack(spacing: 10) {
                Image(systemName: "doc.fill").font(.title2)
                Text(document.document.fileName).font(.subheadline)
            }

        case .messageLocation:
            mediaPlaceholder(icon: "map.fill", text: "Геолокация")

        case .messageContact:
            mediaPlaceholder(icon: "person.fill", text: "Контакт")

        case .messagePoll(let poll):
            Label(poll.poll.question.text, systemImage: "chart.bar.fill")
                .font(.subheadline)

        default:
            Text(message.previewText)
                .font(.subheadline)
                .italic()
                .foregroundStyle(themeStore.theme.secondaryText)
        }
    }

    private func mediaPlaceholder(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(outgoing ? themeStore.theme.outgoingText : themeStore.theme.incomingText)
        .padding(.vertical, 8)
    }

    private var meta: some View {
        HStack(spacing: 4) {
            if message.editDate > 0 {
                Text("изм.").font(.caption2)
            }
            Text(Self.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(message.date))))
                .font(.caption2)
            if outgoing {
                Image(systemName: message.sendingState == nil ? "checkmark.double" : "clock")
                    .font(.caption2)
            }
        }
        .foregroundStyle(timestampColor)
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
    }

    private var bubbleColor: Color {
        if #available(iOS 26.0, *), themeStore.glassEnabled {
            return (outgoing ? themeStore.theme.outgoingBubble : themeStore.theme.incomingBubble).opacity(0.72)
        }
        return outgoing ? themeStore.theme.outgoingBubble : themeStore.theme.incomingBubble
    }

    private var bubbleBorder: Color {
        (outgoing ? themeStore.theme.outgoingText : themeStore.theme.incomingText).opacity(0.12)
    }

    private var timestampColor: Color {
        outgoing ? themeStore.theme.outgoingText.opacity(0.7) : themeStore.theme.timeText
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct WaveformBars: View {
    let duration: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .frame(width: 2.5, height: CGFloat(6 + abs(sin(Double(index) * 1.7)) * 16))
            }
        }
        .accessibilityLabel("Голосовое, \(duration) с")
    }
}
