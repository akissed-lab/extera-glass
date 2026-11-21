import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    let chatId: Int64

    @State private var draft = ""
    @State private var scrollProxy: ScrollViewProxy?

    private var chat: ChatItem? {
        telegram.chats.first { $0.id == chatId }
    }

    private var messages: [Message] {
        telegram.messages[chatId] ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            emptyMessages
                        } else {
                            ForEach(messages) { message in
                                MessageBubbleView(message: message, chat: chat)
                                    .id(message.id)
                            }

                            HStack {
                                Spacer()
                                Button {
                                    Task { await telegram.loadMoreMessages(chatId: chatId) }
                                } label: {
                                    Label("Загрузить раньше", systemImage: "arrow.up.circle")
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding(.top, 4)
                            .id("load-more")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
                .glassScrollEdges()
                .onAppear { scrollProxy = proxy }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            inputBar
        }
        .background {
            GlassBackdrop()
            themeStore.theme.chatBackground.opacity(0.18).ignoresSafeArea()
        }
        .navigationTitle(chat?.title ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let chat {
                    AvatarView(title: chat.title, photo: chat.photo, size: 34)
                }
            }
        }
        .task {
            telegram.open(chatId: chatId)
            await telegram.loadMessages(chatId: chatId)
            if let last = messages.last {
                scrollProxy?.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var emptyMessages: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.badge")
                .font(.system(size: 40))
                .foregroundStyle(themeStore.theme.accent)
            Text("Сообщений пока нет")
                .font(.headline)
                .foregroundStyle(themeStore.theme.primaryText)
            Text("Напишите первое сообщение — оно придёт в настоящий Telegram.")
                .font(.footnote)
                .foregroundStyle(themeStore.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Сообщение…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassSurface(cornerRadius: 22, tint: themeStore.theme.accent.opacity(0.2))
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: draft.trimmingCharacters(in: .whitespaces).isEmpty
                      ? "mic.fill" : "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        draft.isEmpty ? Color.gray.opacity(0.5) : themeStore.theme.accent,
                        in: Circle()
                    )
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .glassSurface(cornerRadius: 21, tint: themeStore.theme.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await telegram.sendText(text, to: chatId) }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}
