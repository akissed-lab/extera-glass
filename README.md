# Extera Glass — iOS‑клиент Telegram на TDLib

Неофициальный нативный клиент: **TDLib** (реальный MTProto, авторизация, шифрование, сообщения) + SwiftUI‑интерфейс с **Liquid Glass** и темами, извлечёнными из `exteraGram-full-universal-20261102.apk`.

## Что уже работает

- ✅ Вход по номеру телефона, код, 2FA‑пароль, регистрация нового аккаунта, подтверждение с другого устройства
- ✅ Загрузка списка чатов и истории сообщений, обновления в реальном времени (`updateNewMessage` и др.)
- ✅ Отправка текстовых сообщений в настоящий Telegram
- ✅ Открытие чата / пометка прочитанного
- ✅ Чат «Сохранённые сообщения» (реальный чат с самим собой)
- ✅ Поиск публичного чата по `@username` или ссылке `t.me/…`
- ✅ Аватары (миниатюры + загрузка файла), статусы, счётчики непрочитанного, закреплённые и приглушённые чаты
- ✅ Отображение фото, видео, стикеров, GIF, голосовых, документов, геолокации, контактов, опросов
- ✅ 8 тем из APK (`day`, `night`, `darkblue`, `arctic`, `bluebubbles`, `monet_light`, `monet_dark`, `monet_black`) — цвета конвертируются из `.attheme` в Swift
- ✅ Liquid Glass: нативный `.glassEffect` на iOS 26, совместимый `.ultraThinMaterial` + блики на iOS 17–18
- ✅ Переключатель стекла,-intensity, темы, выход из аккаунта

## Чего пока нет

- ❌ Звонки, истории/каналы‑сторис, секретные чаты, форумы/топики
- ❌ Отправка медиа и файлов (только текст), реакции, ответы, пересылка
- ❌ Push‑уведомления, фоновые задачи, широкий поиск по сообщениям
- ❌ Полная поддержка всех типов авторизации (email‑код пока не реализован)
- ❌ Локализация (интерфейс на русском, системные строки — на родном языке)

Это рабочий каркас клиента с настоящим входом и сообщениями, но **не полный аналог ExteraGram/Telegram**.

## Подготовка

1. Получите свои `api_id` и `api_hash`: https://my.telegram.org → API Development Tools.
2. Скопируйте `ExteraGlass/Config.swift.example` в `ExteraGlass/Config.swift` и замените значения:
   ```swift
   static let apiID: Int = 0
   static let apiHash: String = "YOUR_API_HASH"
   ```
   Файл `Config.swift` добавлен в `.gitignore` — реальные ключи не должны попадать в репозиторий.
3. Откройте `ExteraGlass.xcodeproj` в Xcode 26 (требуется macOS).

> Telegram требует использовать собственные ключи и не называть приложение «Telegram» / не использовать официальный логотип. См. [правила](https://core.telegram.org/api/obtaining_api_id).

## Сборка

### Локально (Mac)

```bash
xcodebuild -project ExteraGlass.xcodeproj \
  -scheme ExteraGlass \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Для установки на устройство нужна подпись: в Xcode выберите Team в `Signing & Capabilities`.

### Через GitHub Actions (без Mac)

Workflow `.github/workflows/build-ipa.yml`:
- по умолчанию собирает **ad‑hoc IPA** (артефакт `ExteraGlass-adhoc`) — его можно переподписать через AltStore/Sideloadly;
- если добавить секреты `SIGNING_CERT_P12`, `SIGNING_CERT_PASSWORD`, `SIGNING_PROVISIONING_PROFILE`, `APPLE_TEAM_ID` — собирает IPA с вашим сертификатом.

Обязательные секреты репозитория (Settings → Secrets and variables → Actions → New repository secret):

| Секрет | Значение |
|---|---|
| `TELEGRAM_API_ID` | ваш `api_id` (цифры) |
| `TELEGRAM_API_HASH` | ваш `api_hash` |

Без них сборка сразу упадёт с понятной ошибкой. Шаг `Generate Config.swift from secrets` создаёт файл с ключами прямо в раннере — в репозитории его нет. Если репозиторий публичный, **не добавляйте** `Config.swift` вручную.

IPA появляется во вкладке Actions → артефакты конкретного запуска.

## Генерация файлов

```bash
# Обновить темы из APK (если поменялся файл)
python tools/extract_themes.py

# Пересобрать Xcode-проект после добавления Swift-файлов
python tools/generate_xcodeproj.py
```

## Структура

```
ExteraGlass/
  App/        — @main, корневой роутинг, табы
  Core/       — TDLibService ( MTProto, апдейты ), модели чата
  Theme/      — темы из APK, Liquid Glass, токены
  Views/      — авторизация, список чатов, чат, сообщения, настройки
tools/        — генераторы
.github/      — CI сборки IPA
```

## Юридическое

Используйте собственные API‑ключи, не выдавайте приложение за официальный клиент Telegram и не используйте фирменный логотип. ExteraGram — сторонний форк; его темы и ресурсы остаются собственностью авторов. Проект предназначен для личного использования и сборки IPA.

## Известные трудности

- TDLibKit тянет бинарный `.xcframework` ~300 МБ — первая сборка долгая.
- Ad‑hoc IPA не устанавливается напрямую в App Store и требует переподписи.
- На iOS 17–18 стекло — имитация (material), настоящий `.glassEffect` доступен только с iOS 26 SDK.
