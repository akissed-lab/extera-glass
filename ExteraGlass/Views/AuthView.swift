import SwiftUI
import TDLibKit

struct AuthView: View {
    @EnvironmentObject private var telegram: TDLibService
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                fields
            }
            .padding(28)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeStore.theme.accent.gradient)
                    .frame(width: 84, height: 84)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-12))
            }
            .glassSurface(cornerRadius: 42, tint: themeStore.theme.accent)

            Text("Extera Glass")
                .font(.largeTitle.bold())
                .foregroundStyle(themeStore.theme.primaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(themeStore.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
    }

    @ViewBuilder
    private var fields: some View {
        switch telegram.authorizationState {
        case .authorizationStateWaitTdlibParameters:
            ProgressView("Подключение к Telegram…")
                .tint(themeStore.theme.accent)

        case .authorizationStateWaitPhoneNumber:
            VStack(spacing: 14) {
                TextField("Номер телефона", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .padding(16)
                    .glassSurface(cornerRadius: 16)

                Button(action: submitPhone) {
                    HStack { Text("Получить код"); Image(systemName: "arrow.right") }
                }
                .buttonStyle(GlassButtonStyle(tint: themeStore.theme.accent))
                .disabled(phone.count < 6 || busy)
            }

        case .authorizationStateWaitCode(let info):
            VStack(spacing: 14) {
                TextField("Код из Telegram", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .glassSurface(cornerRadius: 16)

                Text(codeHint(info.codeInfo))
                    .font(.footnote)
                    .foregroundStyle(themeStore.theme.secondaryText)

                Button("Войти", action: submitCode)
                    .buttonStyle(GlassButtonStyle(tint: themeStore.theme.accent))
                    .disabled(code.isEmpty || busy)
            }

        case .authorizationStateWaitPassword(let info):
            VStack(spacing: 14) {
                SecureField("Пароль 2FA", text: $password)
                    .textContentType(.password)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .glassSurface(cornerRadius: 16)

                if !info.passwordHint.isEmpty {
                    Text("Подсказка: \(info.passwordHint)")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.secondaryText)
                }

                Button("Подтвердить", action: submitPassword)
                    .buttonStyle(GlassButtonStyle(tint: themeStore.theme.accent))
                    .disabled(password.isEmpty || busy)
            }

        case .authorizationStateWaitRegistration:
            VStack(spacing: 14) {
                TextField("Имя", text: $firstName)
                    .textContentType(.givenName)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .glassSurface(cornerRadius: 16)
                TextField("Фамилия", text: $lastName)
                    .textContentType(.familyName)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .glassSurface(cornerRadius: 16)
                Button("Завершить регистрацию") {
                    Task {
                        busy = true
                        await telegram.register(firstName: firstName, lastName: lastName)
                        busy = false
                    }
                }
                .buttonStyle(GlassButtonStyle(tint: themeStore.theme.accent))
                .disabled(firstName.isEmpty || busy)
            }

        case .authorizationStateWaitOtherDeviceConfirmation(let info):
            VStack(spacing: 12) {
                Text("Подтвердите вход на другом устройстве")
                    .font(.headline)
                Text(info.link)
                    .font(.footnote)
                    .textSelection(.enabled)
                    .foregroundStyle(themeStore.theme.accent)
                    .padding()
                    .glassSurface(cornerRadius: 14)
            }

        case .authorizationStateWaitEmailAddress:
            Text("Вход по email пока не поддерживается этим клиентом.")
                .foregroundStyle(themeStore.theme.secondaryText)

        case .authorizationStateWaitEmailCode:
            Text("Код из email пока не поддерживается этим клиентом.")
                .foregroundStyle(themeStore.theme.secondaryText)

        case .authorizationStateReady:
            ProgressView()

        default:
            ProgressView("Загрузка…")
        }

        if busy {
            ProgressView().padding(.top, 4)
        }
    }

    private var subtitle: String {
        switch telegram.authorizationState {
        case .authorizationStateWaitPhoneNumber:
            return "Введите номер — придёт код подтверждения"
        case .authorizationStateWaitCode:
            return "Введите код, который прислал Telegram"
        case .authorizationStateWaitPassword:
            return "Введите пароль двухфакторной защиты"
        case .authorizationStateWaitRegistration:
            return "Создайте профиль"
        default:
            return "Нативный клиент на TDLib"
        }
    }

    private func codeHint(_ info: AuthenticationCodeInfo) -> String {
        switch info.type {
        case .authenticationCodeTypeTelegramMessage:
            return "Код отправлен приложением Telegram"
        case .authenticationCodeTypeSms,
             .authenticationCodeTypeSmsWord,
             .authenticationCodeTypeSmsPhrase:
            return "Код отправлен SMS"
        case .authenticationCodeTypeCall:
            return "Telegram позвонит вам"
        case .authenticationCodeTypeFlashCall:
            return "Flash call"
        case .authenticationCodeTypeMissedCall:
            return "Пропущенный звонок"
        case .authenticationCodeTypeFragment:
            return "Код через Fragment"
        case .authenticationCodeTypeFirebaseAndroid,
             .authenticationCodeTypeFirebaseIos:
            return "Код через Firebase"
        }
    }

    private func submitPhone() {
        Task {
            busy = true
            await telegram.submitPhone(phone)
            busy = false
        }
    }

    private func submitCode() {
        Task {
            busy = true
            await telegram.submitCode(code)
            busy = false
        }
    }

    private func submitPassword() {
        Task {
            busy = true
            await telegram.submitPassword(password)
            busy = false
        }
    }
}
