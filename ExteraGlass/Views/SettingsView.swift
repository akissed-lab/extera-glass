import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    accountCard
                    glassCard
                    themesCard
                    aboutCard
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .background { GlassBackdrop() }
            .navigationTitle("Настройки")
            .glassScrollEdges()
            .alert("Выйти из аккаунта?", isPresented: $showLogoutConfirm) {
                Button("Выйти", role: .destructive) {
                    Task { await telegram.logout() }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            AvatarView(
                title: telegram.currentUser.map { [$0.firstName, $0.lastName].filter { !$0.isEmpty }.joined(separator: " ") } ?? "?",
                size: 58,
                showOnline: true
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(telegram.currentUser.map { [$0.firstName, $0.lastName].filter { !$0.isEmpty }.joined(separator: " ") } ?? "Загрузка…")
                    .font(.headline)
                    .foregroundStyle(themeStore.theme.primaryText)
                if let username = telegram.currentUser?.usernames?.activeUsernames.first, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(themeStore.theme.secondaryText)
                }
            }
            Spacer()
            Button(role: .destructive) { showLogoutConfirm = true } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
            .glassSurface(cornerRadius: 14)
        }
        .padding(16)
        .glassSurface(cornerRadius: 22)
    }

    private var glassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Liquid Glass", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(themeStore.theme.primaryText)

            Toggle("Стеклянный интерфейс", isOn: $themeStore.glassEnabled)
                .tint(themeStore.theme.accent)

            if #available(iOS 26.0, *) {
                Text("Используется нативный эффект iOS 26.")
                    .font(.caption)
                    .foregroundStyle(themeStore.theme.secondaryText)
            } else {
                VStack(alignment: .leading) {
                    Text("На этой версии iOS используется совместимый material-эффект.")
                        .font(.caption)
                        .foregroundStyle(themeStore.theme.secondaryText)
                    Slider(value: $themeStore.glassIntensity, in: 0...1) {
                        Text("Интенсивность блика")
                    }
                    .tint(themeStore.theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassSurface(cornerRadius: 22)
    }

    private var themesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Темы ExteraGram", systemImage: "paintpalette")
                .font(.headline)
                .foregroundStyle(themeStore.theme.primaryText)

            Text("Палитры извлечены из assets/*.attheme вашего APK.")
                .font(.caption)
                .foregroundStyle(themeStore.theme.secondaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(AppTheme.all, id: \.key) { theme in
                    Button {
                        withAnimation { themeStore.select(theme) }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.background)
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accent)
                                        .frame(width: 18, height: 26)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.incomingBubble)
                                        .frame(width: 18, height: 20)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.outgoingBubble)
                                        .frame(width: 18, height: 20)
                                }
                            }
                            .frame(height: 50)
                            .overlay {
                                if themeStore.themeKey == theme.key {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(theme.accent, lineWidth: 2.5)
                                }
                            }

                            Text(theme.displayName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(themeStore.theme.primaryText)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassSurface(cornerRadius: 22)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("О приложении", systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(themeStore.theme.primaryText)
            Text("Extera Glass — неофициальный клиент на TDLib. Дизайн вдохновлён ExteraGram 13.1.1.")
                .font(.footnote)
                .foregroundStyle(themeStore.theme.secondaryText)
            Text("Для входа нужны собственные api_id и api_hash с my.telegram.org (см. Config.swift).")
                .font(.footnote)
                .foregroundStyle(themeStore.theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassSurface(cornerRadius: 22)
    }
}
