import SwiftUI
import TDLibKit

struct RootView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            GlassBackdrop()

            Group {
                switch telegram.authorizationState {
                case .authorizationStateReady,
                     .authorizationStateLoggingOut,
                     .authorizationStateClosing:
                    MainTabView()
                default:
                    AuthView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .animation(.smooth(duration: 0.35), value: telegram.authorizationState)
        .overlay(alignment: .top) {
            if let error = telegram.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(themeStore.theme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassSurface(cornerRadius: 14)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { telegram.errorMessage = nil }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        TabView {
            ChatListView()
                .tabItem {
                    Label("Чаты", systemImage: "bubble.left.and.bubble.right.fill")
                }

            SavedMessagesView()
                .tabItem {
                    Label("Сохранённое", systemImage: "bookmark.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
        }
        .tint(themeStore.theme.accent)
        .glassScrollEdges()
    }
}

struct SavedMessagesView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        // В Telegram чат «Сохранённые сообщения» имеет id текущего пользователя.
        if let id = telegram.currentUserId {
            ChatView(chatId: id)
        } else {
            NavigationStack {
                ZStack {
                    GlassBackdrop()
                    ProgressView("Загрузка…")
                        .tint(themeStore.theme.accent)
                }
                .navigationTitle("Сохранённое")
            }
        }
    }
}
