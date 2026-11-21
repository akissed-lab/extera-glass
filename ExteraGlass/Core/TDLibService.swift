import Foundation
import UIKit
import TDLibKit

/// Один TDLib-клиент на приложение. Все @Published-состояния обновляются на главном потоке.
final class TDLibService: ObservableObject {
    static weak var shared: TDLibService?

    // MARK: - Состояние

    @Published private(set) var authorizationState: AuthorizationState = .authorizationStateWaitTdlibParameters
    @Published private(set) var chats: [ChatItem] = []
    @Published private(set) var messages: [Int64: [Message]] = [:]
    @Published private(set) var users: [Int64: User] = [:]
    @Published private(set) var currentUser: User?
    @Published private(set) var files: [Int: Data] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var currentUserId: Int64? { currentUser?.id }

    // MARK: - TDLib

    private let manager = TDLibClientManager()
    private let client: TDLibClient
    private var didConfigure = false
    private var didLoadInitial = false

    init() {
        client = manager.createClient { [weak self] data, _ in
            guard let self = self else { return }
            guard let update = try? JSONDecoder().decode(Update.self, from: data) else { return }
            DispatchQueue.main.async { self.handle(update) }
        }
        TDLibService.shared = self
    }

    deinit {
        // TDLibClientManager закроет клиенты в deinit.
        TDLibService.shared = nil
    }

    // MARK: - Обработка апдейтов

    private func handle(_ update: Update) {
        switch update {
        case .updateAuthorizationState(let payload):
            authorizationState = payload.authorizationState
            switch payload.authorizationState {
            case .authorizationStateWaitTdlibParameters:
                configureIfNeeded()
            case .authorizationStateReady:
                loadInitialDataIfNeeded()
            default:
                break
            }

        case .updateNewChat(let payload):
            upsert(ChatItem(payload.chat))

        case .updateChatTitle(let payload):
            mutate(payload.chatId) { $0.title = payload.title }

        case .updateChatLastMessage(let payload):
            mutate(payload.chatId) { item in
                item.lastMessage = payload.lastMessage
                if let main = payload.positions.first(where: { if case .chatListMain = $0.list { return true }; return false }) {
                    item.isPinned = main.isPinned
                    item.order = main.order.rawValue
                }
            }

        case .updateChatUnreadMentionCount(let payload):
            mutate(payload.chatId) { $0.unreadMentionCount = payload.unreadMentionCount }

        case .updateUser(let payload):
            users[payload.user.id] = payload.user
            if payload.user.id == currentUserId { currentUser = payload.user }

        case .updateNewMessage(let payload):
            append(payload.message)

        case .updateMessageSendSucceeded(let payload):
            replace(payload.oldMessageId, in: payload.message.chatId, with: payload.message)

        case .updateMessageContent(let payload):
            updateContent(payload.chatId, messageId: payload.messageId)

        case .updateDeleteMessages(let payload):
            messages[payload.chatId]?.removeAll { payload.messageIds.contains($0.id) }

        default:
            break
        }
    }

    private func upsert(_ item: ChatItem) {
        if let index = chats.firstIndex(where: { $0.id == item.id }) {
            chats[index] = item
        } else {
            chats.append(item)
        }
        sortChats()
    }

    private func mutate(_ chatId: Int64, _ block: (inout ChatItem) -> Void) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { return }
        block(&chats[index])
        sortChats()
    }

    private func sortChats() {
        chats.sort {
            if $0.order != $1.order { return $0.order > $1.order }
            return $0.id > $1.id
        }
    }

    private func append(_ message: Message) {
        guard messages[message.chatId] != nil else { return }
        var list = messages[message.chatId] ?? []
        if !list.contains(where: { $0.id == message.id }) {
            list.append(message)
            messages[message.chatId] = list.sorted { $0.id < $1.id }
        }
        fetchUserIfNeeded(for: message)
    }

    private func replace(_ oldId: Int64, in chatId: Int64, with message: Message) {
        guard var list = messages[chatId] else { return }
        if let index = list.firstIndex(where: { $0.id == oldId }) {
            list[index] = message
        } else if !list.contains(where: { $0.id == message.id }) {
            list.append(message)
        }
        messages[chatId] = list.sorted { $0.id < $1.id }
    }

    private func updateContent(_ chatId: Int64, messageId: Int64) {
        guard messages[chatId]?.contains(where: { $0.id == messageId }) == true else { return }
        // TDLib-модель неизменяема — перезапрашиваем сообщение после апдейта.
        Task {
            do {
                let fresh = try await client.getMessage(chatId: chatId, messageId: messageId)
                DispatchQueue.main.async { self.replace(messageId, in: chatId, with: fresh) }
            } catch {
                await report(error)
            }
        }
    }

    private func fetchUserIfNeeded(for message: Message) {
        guard let userId = message.senderId.userId, userId != 0, users[userId] == nil else { return }
        Task {
            do {
                let user = try await client.getUser(userId: userId)
                DispatchQueue.main.async { self.users[userId] = user }
            } catch { /* игнорируем -- имя покажем как ID */ }
        }
    }

    // MARK: - Авторизация

    private func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true
        Task {
            do {
                _ = try await client.setTdlibParameters(
                    apiHash: Config.apiHash,
                    apiId: Config.apiID,
                    applicationVersion: Config.appVersion,
                    databaseDirectory: tdlibDirectory,
                    databaseEncryptionKey: nil,
                    deviceModel: Config.deviceModel,
                    filesDirectory: tdlibFilesDirectory,
                    systemLanguageCode: Config.languageCode,
                    systemVersion: UIDevice.current.systemVersion,
                    useChatInfoDatabase: true,
                    useFileDatabase: true,
                    useMessageDatabase: true,
                    useSecretChats: true,
                    useTestDc: false
                )
            } catch {
                await report(error)
            }
        }
    }

    private var tdlibDirectory: String {
        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = path.appendingPathComponent("tdlib", isDirectory: true).path
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    private var tdlibFilesDirectory: String {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = path.appendingPathComponent("tdlib-files", isDirectory: true).path
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    func submitPhone(_ phone: String) async {
        do {
            let normalized = phone.isEmpty ? phone : (phone.hasPrefix("+") ? phone : "+" + phone)
            _ = try await client.setAuthenticationPhoneNumber(phoneNumber: normalized, settings: nil)
        } catch {
            await report(error)
        }
    }

    func submitCode(_ code: String) async {
        do {
            _ = try await client.checkAuthenticationCode(code: code)
        } catch {
            await report(error)
        }
    }

    func submitPassword(_ password: String) async {
        do {
            _ = try await client.checkAuthenticationPassword(password: password)
        } catch {
            await report(error)
        }
    }

    func register(firstName: String, lastName: String) async {
        do {
            _ = try await client.registerUser(
                disableNotification: false,
                firstName: firstName,
                lastName: lastName
            )
        } catch {
            await report(error)
        }
    }

    func logout() async {
        do {
            _ = try await client.logOut()
        } catch {
            await report(error)
        }
    }

    // MARK: - Данные

    private func loadInitialDataIfNeeded() {
        guard !didLoadInitial else { return }
        didLoadInitial = true
        Task {
            do {
                let me = try await client.getMe()
                DispatchQueue.main.async { self.currentUser = me }
                // Чат «Сохранённые сообщения» — это чат с самим собой.
                await self.loadChatIfNeeded(me.id)
                let result = try await client.getChats(chatList: .chatListMain, limit: 100)
                DispatchQueue.main.async {
                    result.chatIds.forEach { id in
                        Task { await self.loadChatIfNeeded(id) }
                    }
                }
                _ = try? await client.loadChats(chatList: .chatListMain, limit: 100)
            } catch {
                await report(error)
            }
        }
    }

    private func loadChatIfNeeded(_ id: Int64) async {
        if chats.contains(where: { $0.id == id }) { return }
        do {
            let chat = try await client.getChat(chatId: id)
            DispatchQueue.main.async { self.upsert(ChatItem(chat)) }
        } catch { /* чат мог быть удалён */ }
    }

    func loadMessages(chatId: Int64) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let history = try await client.getChatHistory(
                chatId: chatId, fromMessageId: 0, limit: 60, offset: 0, onlyLocal: false
            )
            let ordered = (history.messages ?? []).sorted { $0.id < $1.id }
            DispatchQueue.main.async {
                self.messages[chatId] = ordered
                ordered.forEach { self.fetchUserIfNeeded(for: $0) }
            }
        } catch {
            await report(error)
        }
    }

    func loadMoreMessages(chatId: Int64) async {
        guard let oldest = messages[chatId]?.first?.id, oldest != 0 else { return }
        do {
            let history = try await client.getChatHistory(
                chatId: chatId, fromMessageId: oldest, limit: 50, offset: 0, onlyLocal: false
            )
            let older = (history.messages ?? []).filter { $0.id < oldest }
            guard !older.isEmpty else { return }
            DispatchQueue.main.async {
                self.messages[chatId] = (older + (self.messages[chatId] ?? [])).sorted { $0.id < $1.id }
            }
        } catch { /* тихо */ }
    }

    func open(chatId: Int64) {
        Task {
            try? await client.openChat(chatId: chatId)
            let ids = messages[chatId]?.map(\.id) ?? []
            if !ids.isEmpty {
                try? await client.viewMessages(chatId: chatId, forceRead: false, messageIds: ids, source: nil)
            }
        }
    }

    func sendText(_ text: String, to chatId: Int64) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let content = InputMessageText(
            clearDraft: true,
            linkPreviewOptions: nil,
            text: FormattedText(entities: [], text: trimmed)
        )
        do {
            _ = try await client.sendMessage(
                chatId: chatId,
                inputMessageContent: .inputMessageText(content),
                options: nil,
                replyMarkup: nil,
                replyTo: nil,
                topicId: nil
            )
        } catch {
            await report(error)
        }
    }

    func searchPublicChat(_ query: String) async -> ChatItem? {
        let username = query.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://t.me/", with: "")
            .replacingOccurrences(of: "@", with: "")
        guard !username.isEmpty else { return nil }
        do {
            let chat = try await client.searchPublicChat(username: username)
            let item = ChatItem(chat)
            DispatchQueue.main.async { self.upsert(item) }
            return item
        } catch {
            await report(error)
            return nil
        }
    }

    func downloadFile(_ fileId: Int) async -> Data? {
        if let cached = files[fileId] { return cached }
        do {
            let file = try await client.downloadFile(
                fileId: fileId, limit: 0, offset: 0, priority: 4, synchronous: false
            )
            guard file.local.isDownloadingCompleted,
                  !file.local.path.isEmpty,
                  let data = try? Data(contentsOf: URL(fileURLWithPath: file.local.path))
            else { return nil }
            DispatchQueue.main.async { self.files[fileId] = data }
            return data
        } catch {
            return nil
        }
    }

    func displayName(for sender: MessageSender) -> String {
        guard let id = sender.userId else { return "Группа" }
        if let user = users[id] {
            return [user.firstName, user.lastName].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return "Пользователь \(id)"
    }

    // MARK: - Ошибки

    private func report(_ error: Error) async {
        let message = error.localizedDescription
        await MainActor.run { self.errorMessage = message }
    }
}
