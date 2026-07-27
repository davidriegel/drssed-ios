//
//  WearCalendarDayCell.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import UIKit
import SDWebImage

/// A single day of the wear calendar, showing the outfit that was worn on it.
final class WearCalendarDayCell: UICollectionViewCell {
    static let identifier = "WearCalendarDayCell"

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.clipsToBounds = true
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 9, weight: .heavy)
        label.textColor = .accent
        label.isHidden = true
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

        cardView.layer.cornerRadius = CornerStyle.small.radius(for: cardView)
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(dayLabel)
        cardView.addSubview(countLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),

            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 2),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 2),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -2),

            dayLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 3),
            dayLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            countLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -3),
            countLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])
    }

    func configure(day: WearCalendarDay, isSelected: Bool) {
        dayLabel.text = day.date.map { String(Calendar.current.component(.day, from: $0)) }
        dayLabel.textColor = day.isToday ? .accent : .secondaryLabel
        dayLabel.font = .systemFont(ofSize: 12, weight: day.isToday ? .black : .bold)

        cardView.isHidden = day.date == nil
        cardView.layer.borderWidth = isSelected ? 2 : (day.isToday ? 1 : 0)
        cardView.layer.borderColor = isSelected ? UIColor.accent.cgColor : UIColor.accent.withAlphaComponent(0.4).cgColor

        countLabel.isHidden = day.wears.count < 2
        countLabel.text = "+\(day.wears.count - 1)"

        if let outfitID = day.wears.first?.outfitID {
            imageView.sd_setImage(with: URL(string: outfitID, relativeTo: APIClient.outfitImagesURL))
        } else {
            imageView.image = nil
        }

        accessibilityLabel = day.accessibilityLabel
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        dayLabel.text = nil
        countLabel.isHidden = true
    }
}
