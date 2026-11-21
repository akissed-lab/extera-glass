import SwiftUI

/// Стеклянная поверхность в стиле iOS 26.
/// На iOS 26 использует нативный `glassEffect`, на старших версиях — material + блик.
struct GlassSurface: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        Group {
            if !themeStore.glassEnabled {
                // Стекло выключено — обычная поверхность темы.
                content
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(themeStore.theme.surface)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(themeStore.theme.divider.opacity(0.5), lineWidth: borderWidth)
                    }
            } else if #available(iOS 26.0, *) {
                content
                    .glassEffect(
                        glass,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(themeStore.theme.divider.opacity(0.35), lineWidth: borderWidth)
                    }
            } else {
                // iOS 17–18: совместимый material + блик.
                content
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(themeStore.glassIntensity * 0.20),
                                                Color.white.opacity(0.02),
                                                Color.black.opacity(0.06),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(
                                        (tint ?? Color.white).opacity(0.32),
                                        lineWidth: borderWidth
                                    )
                            }
                    }
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
            }
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var base = Glass.regular
        if let tint {
            base = base.tint(tint)
        }
        if interactive {
            base = base.interactive()
        }
        return base
    }
}

extension View {
    func glassSurface(
        cornerRadius: CGFloat = 20,
        tint: Color? = nil,
        interactive: Bool = false,
        borderWidth: CGFloat = 0.7
    ) -> some View {
        modifier(
            GlassSurface(
                cornerRadius: cornerRadius,
                tint: tint,
                interactive: interactive,
                borderWidth: borderWidth
            )
        )
    }

    /// Мягкий scroll-edge эффект на iOS 26.
    @ViewBuilder
    func glassScrollEdges() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeStore: ThemeStore
    let tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint ?? themeStore.theme.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .glassSurface(cornerRadius: 16, tint: tint, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Декоративный фон с цветными пятнами — нужен, чтобы преломление стекла было видно.
struct GlassBackdrop: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        ZStack {
            themeStore.theme.background.ignoresSafeArea()
            if themeStore.glassEnabled {
                Group {
                    Circle()
                        .fill(themeStore.theme.accent.opacity(0.28))
                        .frame(width: 320, height: 320)
                        .blur(radius: 90)
                        .offset(x: -120, y: -260)

                    Circle()
                        .fill(Color.purple.opacity(themeStore.theme.isDark ? 0.24 : 0.16))
                        .frame(width: 280, height: 280)
                        .blur(radius: 80)
                        .offset(x: 150, y: 180)

                    Circle()
                        .fill(Color.teal.opacity(0.18))
                        .frame(width: 240, height: 240)
                        .blur(radius: 70)
                        .offset(x: -160, y: 320)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }
}
