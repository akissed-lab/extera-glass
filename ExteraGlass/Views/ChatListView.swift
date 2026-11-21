import SwiftUI
import TDLibKit

struct ChatListView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var search = ""
    @State private var showCompose = false

    private var filtered: [ChatItem] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return telegram.chats }
        return telegram.chats.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        if filtered.isEmpty {
                            emptyState
                        } else {
                            ForEach(filtered) { chat in
                                NavigationLink(value: chat.id) {
                                    ChatRowView(chat: chat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 90)
                }
                .glassScrollEdges()

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showCompose = true } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 58)
                                .background(themeStore.theme.accent.gradient, in: Circle())
                        }
                        .glassSurface(cornerRadius: 29, tint: themeStore.theme.accent)
                        .shadow(color: themeStore.theme.accent.opacity(0.35), radius: 14, y: 6)
                        .padding(.trailing, 20)
                        .padding(.bottom, 18)
                    }
                }
            }
            .navigationTitle("Чаты")
            .navigationDestination(for: Int64.self) { chatId in
                ChatView(chatId: chatId)
            }
            .searchable(text: $search, prompt: "Поиск по чатам")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let user = telegram.currentUser {
                        AvatarView(
                            title: [user.firstName, user.lastName].filter { !$0.isEmpty }.joined(separator: " "),
                            photo: nil,
                            size: 34
                        )
                    }
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(themeStore.theme.accent)
            Text(search.isEmpty ? "Загрузка чатов…" : "Ничего не найдено")
                .font(.headline)
                .foregroundStyle(themeStore.theme.primaryText)
            if !search.isEmpty {
                Text("Попробуйте другое имя или @username")
                    .font(.subheadline)
                    .foregroundStyle(themeStore.theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var username = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()
                VStack(spacing: 20) {
                    TextField("@username или ссылка t.me/...", text: $username)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(16)
                        .glassSurface(cornerRadius: 16)

                    Button("Найти чат") {
                        Task {
                            busy = true
                            await telegram.searchPublicChat(username)
                            busy = false
                            if telegram.errorMessage == nil { dismiss() }
                        }
                    }
                    .buttonStyle(GlassButtonStyle(tint: themeStore.theme.accent))
                    .disabled(username.isEmpty || busy)

                    if busy { ProgressView() }

                    Text("Поиск публичных каналов и групп по username.")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
