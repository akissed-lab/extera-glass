import SwiftUI
import TDLibKit

struct AvatarView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var telegram: TDLibService

    let title: String
    let photo: ChatPhotoInfo?
    let size: CGFloat
    let showOnline: Bool

    init(title: String, photo: ChatPhotoInfo? = nil, size: CGFloat = 52, showOnline: Bool = false) {
        self.title = title
        self.photo = photo
        self.size = size
        self.showOnline = showOnline
    }

    var body: some View {
        ZStack {
            if let data = photo?.minithumbnail?.data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                let colors = gradient
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            if showOnline {
                Circle()
                    .fill(.green)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay {
                        Circle().strokeBorder(themeStore.theme.surface, lineWidth: 2)
                    }
            }
        }
        .task {
            if let fileId = photo?.small.id, telegram.files[fileId] == nil {
                _ = await telegram.downloadFile(fileId)
            }
        }
    }

    private var initials: String {
        let parts = title.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.count > 1 ? parts[1].first.map(String.init) ?? "" : ""
        return first + second
    }

    private var gradient: [Color] {
        let hash = title.unicodeScalars.reduce(0) { Int($0.value) + $1.value }
        let palette: [[Color]] = [
            [.blue, .cyan], [.purple, .pink], [.orange, .red],
            [.green, .teal], [.indigo, .blue], [.brown, .orange],
        ]
        return palette[abs(hash) % palette.count]
    }
}
