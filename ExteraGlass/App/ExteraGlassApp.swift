import SwiftUI

@main
struct ExteraGlassApp: App {
    @StateObject private var telegram = TDLibService()
    @StateObject private var themeStore = ThemeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(telegram)
                .environmentObject(themeStore)
                .preferredColorScheme(themeStore.colorScheme)
                .tint(themeStore.theme.accent)
        }
    }
}
