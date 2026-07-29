//
//  OutfitRecommendationCell.swift
//  Drssed
//
//  Created by David Riegel on 28.07.26.
//

import UIKit
import SDWebImage

/// One recommended outfit on the home screen: the outfit plus the shortcut to wear it right away.
final class OutfitRecommendationCell: UICollectionViewCell {
    static let identifier = "OutfitRecommendationCell"

    /// Called when the shortcut in the corner of the card is tapped.
    var onWear: (() -> Void)?

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5
            ) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.masksToBounds = true
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    /// A view backed by a gradient layer, so the gradient always covers the exact bounds –
    /// reading the frame from the outside is unreliable while layout is still settling.
    private final class ScrimView: UIView {
        override class var layerClass: AnyClass { CAGradientLayer.self }

        var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    }

    /// Fades the bottom of the outfit render into the card so the name stays readable
    /// whatever the outfit happens to look like.
    private let scrimView: ScrimView = {
        let v = ScrimView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        return v
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .heavy)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let itemCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 10, weight: .heavy)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var wearButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.onWear?()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.layer.masksToBounds = true
        return bt
    }()

    private static let wearButtonSize: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        cardView.layer.cornerRadius = CornerStyle.medium.radius(for: contentView)
        cardView.layer.borderWidth = 0.5
        cardView.layer.borderColor = UIColor.separator.cgColor

        wearButton.layer.cornerRadius = Self.wearButtonSize / 2

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.18
        contentView.layer.shadowRadius = 10
        contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.layer.masksToBounds = false

        // Resolved by hand: a CGColor does not follow light and dark mode on its own.
        let base = UIColor.secondarySystemBackground.resolvedColor(with: traitCollection)
        scrimView.gradientLayer.colors = [
            base.withAlphaComponent(0).cgColor,
            base.withAlphaComponent(0.95).cgColor,
            base.cgColor
        ]
        scrimView.gradientLayer.locations = [0, 0.5, 1]
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(scrimView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(itemCountLabel)
        cardView.addSubview(wearButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            wearButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -6),
            wearButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            wearButton.widthAnchor.constraint(equalToConstant: Self.wearButtonSize),
            wearButton.heightAnchor.constraint(equalToConstant: Self.wearButtonSize),

            // The scrim starts above the text block and runs to the bottom edge.
            scrimView.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -18),
            scrimView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),

            itemCountLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            itemCountLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            itemCountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            itemCountLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with outfit: Outfit, isWornToday: Bool) {
        nameLabel.text = outfit.name
        itemCountLabel.text = String(format: NSLocalizedString("home.recommendations.pieces", comment: ""), outfit.scene.count)

        wearButton.setImage(
            UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .heavy))
            ),
            for: .normal
        )
        wearButton.isEnabled = !isWornToday

        // The action carries the weight, the finished state steps back – an outfit already
        // logged for today needs to read as done, not as the thing to tap.
        wearButton.tintColor = isWornToday ? .accent : .background
        wearButton.backgroundColor = isWornToday
            ? UIColor.accent.withAlphaComponent(0.22)
            : .accent
        wearButton.accessibilityLabel = isWornToday
            ? String(localized: "home.recommendations.wornToday")
            : String(localized: "wear.action.todayQuick")

        imageView.sd_setImage(with: URL(string: outfit.id, relativeTo: APIClient.outfitImagesURL))

        accessibilityLabel = outfit.name
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        onWear = nil
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        nameLabel.text = nil
        itemCountLabel.text = nil
    }
}
