//
//  OutfitStatsView.swift
//  Drssed
//
//  Created by David Riegel on 28.07.26.
//

import UIKit

/// The wear history of an outfit as a row of tiles, plus a line about the last time it was worn.
///
/// Tiles without data are left out, so an outfit that was never rated does not show an empty
/// rating. An outfit that was never worn shows an invitation instead of an empty card.
final class OutfitStatsView: UIView {

    /// Draws the outline of the empty state. A shape layer as backing layer keeps the path
    /// in step with the bounds without anyone having to feed it a frame.
    private final class DashedBorderView: UIView {
        override class var layerClass: AnyClass { CAShapeLayer.self }

        private var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }

        override func layoutSubviews() {
            super.layoutSubviews()

            shapeLayer.path = UIBezierPath(
                roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                cornerRadius: CornerStyle.small.radius(for: self)
            ).cgPath
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.strokeColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
            shapeLayer.lineWidth = 1
            shapeLayer.lineDashPattern = [5, 4]
        }
    }

    /// Hidden arranged subviews drop out of the layout, so the two states can each size
    /// themselves without the other one holding the height open.
    private let rootStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        return sv
    }()

    // MARK: - Populated state

    private let background: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.clipsToBounds = true
        return view
    }()

    private let tileStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .top
        sv.spacing = 6
        return sv
    }()

    private let lastWornLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Empty state

    private let emptyView: DashedBorderView = {
        let view = DashedBorderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    /// The app's own hanger mark – it ships with a light and a dark variant and already
    /// carries the accent colour, so it is used as it is rather than tinted.
    private let emptyIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "hanger")
        return iv
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .black)
        label.textColor = .label
        label.textAlignment = .center
        label.text = String(localized: "outfitdetails.stats.never")
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = String(localized: "outfitdetails.stats.never.hint")
        return label
    }()

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

        background.layer.cornerRadius = CornerStyle.small.radius(for: background)
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(rootStack)
        rootStack.addArrangedSubview(background)
        rootStack.addArrangedSubview(emptyView)

        background.addSubview(tileStack)
        background.addSubview(lastWornLabel)

        let emptyStack = UIStackView(arrangedSubviews: [emptyIconView, emptyTitleLabel, emptySubtitleLabel])
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        emptyStack.axis = .vertical
        emptyStack.alignment = .center
        emptyStack.spacing = 6
        // The artwork's own transparent padding already provides the optical gap.
        emptyStack.setCustomSpacing(2, after: emptyIconView)
        emptyView.addSubview(emptyStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            tileStack.topAnchor.constraint(equalTo: background.topAnchor, constant: 12),
            tileStack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 12),
            tileStack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),

            lastWornLabel.topAnchor.constraint(equalTo: tileStack.bottomAnchor, constant: 8),
            lastWornLabel.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 12),
            lastWornLabel.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),
            lastWornLabel.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -12),

            // The artwork sits on a square canvas with generous padding, so it needs a
            // larger box than a glyph would to read at the same weight.
            emptyIconView.heightAnchor.constraint(equalToConstant: 46),
            emptyIconView.widthAnchor.constraint(equalTo: emptyIconView.heightAnchor),

            emptyStack.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 20),
            emptyStack.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            emptyStack.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20),
            emptyStack.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor, constant: -20)
        ])
    }

    func configure(with stats: OutfitWearStats) {
        background.isHidden = stats.isEmpty
        emptyView.isHidden = !stats.isEmpty

        guard !stats.isEmpty else { return }

        tileStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        tileStack.addArrangedSubview(
            Self.tile(
                value: String(format: NSLocalizedString("outfitdetails.stats.count.value", comment: ""), stats.count),
                caption: String(localized: "outfitdetails.stats.count")
            )
        )

        // The date is not a tile: the line below already spells it out in full, together
        // with the weather it was worn in.
        if let rating = stats.averageRating {
            tileStack.addArrangedSubview(
                Self.tile(
                    value: "★ " + NumberFormatter.localizedString(from: NSNumber(value: (rating * 10).rounded() / 10), number: .decimal),
                    caption: String(localized: "outfitdetails.stats.rating")
                )
            )
        }

        if let occasion = stats.favoriteOccasion {
            tileStack.addArrangedSubview(
                Self.tile(value: occasion.localizedName, caption: String(localized: "outfitdetails.stats.occasion"))
            )
        }

        lastWornLabel.text = stats.lastWorn.map(Self.lastWornText(for:))
    }

    /// One number with its caption underneath.
    private static func tile(value: String, caption: String) -> UIView {
        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 15, weight: .black)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.numberOfLines = 1
        valueLabel.text = value

        let captionLabel = UILabel()
        captionLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        captionLabel.textColor = .tertiaryLabel
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 1
        captionLabel.text = caption.uppercased()

        let sv = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        sv.axis = .vertical
        sv.spacing = 2
        return sv
    }

    /// Date of the last wear plus whatever weather and occasion it recorded.
    private static func lastWornText(for wear: OutfitWear) -> String {
        var parts: [String] = [wear.wornOn.formatted(date: .long, time: .omitted)]

        if let occasion = wear.occasion {
            parts.append(occasion.localizedName)
        }

        if let weather = wear.weather {
            parts.append(weather.localizedName)
        }

        if let temperature = wear.temperature {
            parts.append(NumberFormatter.localizedString(from: NSNumber(value: temperature), number: .decimal) + " °C")
        }

        return parts.joined(separator: " · ")
    }
}
