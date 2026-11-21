import UIKit

/// Процедурные «обои» чата — без фирменных ассетов Telegram.
/// Рисуется маленький повторяющийся тайл в цветах текущей темы.
enum Wallpaper {
    static func pattern(for theme: AppTheme) -> UIImage {
        let size = CGSize(width: 96, height: 96)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            theme.chatBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let ctx = context.cgContext
            let stroke = theme.accent.withAlphaComponent(theme.isDark ? 0.055 : 0.075)
            ctx.setStrokeColor(stroke.cgColor)
            ctx.setLineWidth(1.1)
            ctx.setLineCap(.round)

            ctx.addEllipse(in: CGRect(x: 12, y: 14, width: 24, height: 24))
            ctx.strokePath()

            ctx.move(to: CGPoint(x: 52, y: 18))
            ctx.addCurve(
                to: CGPoint(x: 84, y: 30),
                control1: CGPoint(x: 62, y: 6),
                control2: CGPoint(x: 78, y: 44)
            )
            ctx.strokePath()

            ctx.addEllipse(in: CGRect(x: 20, y: 58, width: 16, height: 16))
            ctx.strokePath()

            ctx.move(to: CGPoint(x: 50, y: 70))
            ctx.addLine(to: CGPoint(x: 68, y: 56))
            ctx.addLine(to: CGPoint(x: 86, y: 70))
            ctx.strokePath()

            ctx.move(to: CGPoint(x: 6, y: 46))
            ctx.addLine(to: CGPoint(x: 20, y: 46))
            ctx.strokePath()
        }
    }
}
