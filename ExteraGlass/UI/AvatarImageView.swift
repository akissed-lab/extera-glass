import UIKit
import TDLibKit

/// Круглый аватар с градиентным плейсхолдером и индикатором «онлайн».
/// Не использует фирменные ассеты — только цвета и инициалы.
final class AvatarImageView: UIView {
    private let circle = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let initialsLabel = UILabel()
    private let onlineDot = UIView()
    private var side: CGFloat = 52

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        circle.contentMode = .scaleAspectFill
        circle.clipsToBounds = true
        circle.layer.cornerCurve = .continuous
        circle.layer.insertSublayer(gradientLayer, at: 0)
        addSubview(circle)

        initialsLabel.textAlignment = .center
        initialsLabel.textColor = .white
        circle.addSubview(initialsLabel)

        onlineDot.backgroundColor = .systemGreen
        onlineDot.layer.cornerRadius = 6
        onlineDot.layer.borderWidth = 2
        addSubview(onlineDot)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = side / 2
        circle.frame = CGRect(x: 0, y: 0, width: side, height: side)
        circle.layer.cornerRadius = radius
        gradientLayer.frame = circle.bounds
        initialsLabel.frame = circle.bounds
        let dotSide = max(10, side * 0.28)
        onlineDot.frame = CGRect(x: side - dotSide + 1, y: side - dotSide + 1, width: dotSide, height: dotSide)
        onlineDot.layer.cornerRadius = dotSide / 2
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: side, height: side)
    }

    func configure(
        title: String,
        photo: ChatPhotoInfo?,
        fileData: Data?,
        size: CGFloat,
        showOnline: Bool,
        theme: AppTheme,
        tweaks: Tweaks
    ) {
        side = size
        invalidateIntrinsicContentSize()
        setNeedsLayout()

        let imageData: Data?
        if let fileData { imageData = fileData } else { imageData = photo?.minithumbnail?.data }
        if let data = imageData, let image = UIImage(data: data) {
            circle.image = image
            initialsLabel.isHidden = true
            gradientLayer.isHidden = true
        } else {
            circle.image = nil
            initialsLabel.isHidden = false
            gradientLayer.isHidden = false
            initialsLabel.text = Self.initials(for: title)
            initialsLabel.font = .systemFont(ofSize: size * 0.36, weight: .semibold)
            let colors = Self.gradient(for: title)
            gradientLayer.colors = [colors.0.cgColor, colors.1.cgColor]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        }

        onlineDot.isHidden = !showOnline || tweaks.hideOnline
        onlineDot.layer.borderColor = theme.surface.cgColor
    }

    private static func initials(for title: String) -> String {
        let parts = title.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.count > 1 ? parts[1].first.map(String.init) ?? "" : ""
        return first + second
    }

    private static func gradient(for title: String) -> (UIColor, UIColor) {
        let palette: [(UIColor, UIColor)] = [
            ( UIColor.systemBlue, UIColor.systemCyan ),
            ( UIColor.systemPurple, UIColor.systemPink ),
            ( UIColor.systemOrange, UIColor.systemRed ),
            ( UIColor.systemGreen, UIColor.systemTeal ),
            ( UIColor.systemIndigo, UIColor.systemBlue ),
            ( UIColor.systemBrown, UIColor.systemOrange ),
        ]
        let hash = title.unicodeScalars.reduce(UInt(0)) { $0 &+ UInt($1.value) }
        return palette[Int(hash % UInt(palette.count))]
    }
}
