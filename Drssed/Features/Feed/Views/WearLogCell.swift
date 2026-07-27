//
//  WearLogCell.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import UIKit
import SDWebImage

/// One logged wear in the list below the calendar.
final class WearLogCell: UITableViewCell {
    static let identifier = "WearLogCell"

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .secondarySystemBackground
        iv.clipsToBounds = true
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let noteLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 2
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        thumbnailView.layer.cornerRadius = CornerStyle.small.radius(for: thumbnailView)
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .disclosureIndicator

        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel, noteLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(thumbnailView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 54),
            thumbnailView.heightAnchor.constraint(equalToConstant: 54),

            textStack.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with wear: OutfitWear) {
        nameLabel.text = wear.outfitName ?? String(localized: "calendar.outfit.unknown")
        detailLabel.text = Self.detailText(for: wear)

        noteLabel.text = wear.note
        noteLabel.isHidden = wear.note == nil

        thumbnailView.sd_setImage(with: URL(string: wear.outfitID, relativeTo: APIClient.outfitImagesURL))
    }

    /// Time, occasion, weather, temperature and rating of an entry – whatever of it was filled in.
    private static func detailText(for wear: OutfitWear) -> String {
        var parts: [String] = [wear.wornOn.formatted(date: .omitted, time: .shortened)]

        if let occasion = wear.occasion {
            parts.append(occasion.localizedName)
        }

        if let weather = wear.weather {
            parts.append(weather.localizedName)
        }

        if let temperature = wear.temperature {
            parts.append(NumberFormatter.localizedString(from: NSNumber(value: temperature), number: .decimal) + " °C")
        }

        if let rating = wear.rating {
            parts.append(String(repeating: "★", count: rating))
        }

        return parts.joined(separator: " · ")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.sd_cancelCurrentImageLoad()
        thumbnailView.image = nil
        nameLabel.text = nil
        detailLabel.text = nil
        noteLabel.text = nil
    }
}
