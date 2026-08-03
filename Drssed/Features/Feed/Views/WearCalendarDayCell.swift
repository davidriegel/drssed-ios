//
//  WearCalendarDayCell.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import UIKit
import SDWebImage

/// A single day of the wear calendar, showing the outfit that was worn on it.
///
/// Only days that carry an entry get a card – an empty month should read as empty instead of
/// as a wall of boxes. The date sits above the outfit rather than on top of it.
final class WearCalendarDayCell: UICollectionViewCell {
    static let identifier = "WearCalendarDayCell"

    private let dayBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .tertiaryLabel
        return label
    }()

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

    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 9, weight: .heavy)
        label.textColor = .accent
        label.isHidden = true
        return label
    }()

    private static let badgeHeight: CGFloat = 18

    /// A day with an outfit puts its date above the picture; an empty day has nothing to
    /// sit above, so the date centres in the cell instead of clinging to the top edge.
    private var badgeTopConstraint: NSLayoutConstraint?
    private var badgeCenterConstraint: NSLayoutConstraint?

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
        dayBadge.layer.cornerRadius = Self.badgeHeight / 2
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(dayBadge)
        dayBadge.addSubview(dayLabel)
        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(countLabel)

        badgeTopConstraint = dayBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1)
        badgeCenterConstraint = dayBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)

        NSLayoutConstraint.activate([
            dayBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayBadge.heightAnchor.constraint(equalToConstant: Self.badgeHeight),
            dayBadge.widthAnchor.constraint(greaterThanOrEqualTo: dayBadge.heightAnchor),

            dayLabel.topAnchor.constraint(equalTo: dayBadge.topAnchor),
            dayLabel.bottomAnchor.constraint(equalTo: dayBadge.bottomAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: dayBadge.leadingAnchor, constant: 6),
            dayLabel.trailingAnchor.constraint(equalTo: dayBadge.trailingAnchor, constant: -6),

            cardView.topAnchor.constraint(equalTo: dayBadge.bottomAnchor, constant: 1),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),

            imageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 2),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 2),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -2),

            countLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -3),
            countLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4)
        ])
    }

    func configure(day: WearCalendarDay) {
        let hasEntries = !day.wears.isEmpty

        dayBadge.isHidden = day.date == nil
        dayLabel.text = day.date.map { String(Calendar.current.component(.day, from: $0)) }

        // Today is the only day that gets a filled marker, so it stays findable in a
        // month that is otherwise mostly empty.
        dayBadge.backgroundColor = day.isToday ? .accent : .clear
        dayLabel.textColor = day.isToday ? .background : (hasEntries ? .label : .tertiaryLabel)
        dayLabel.font = .systemFont(ofSize: 11, weight: day.isToday ? .black : .bold)

        cardView.isHidden = !hasEntries

        badgeTopConstraint?.isActive = hasEntries
        badgeCenterConstraint?.isActive = !hasEntries

        countLabel.isHidden = day.wears.count < 2
        countLabel.text = "+\(day.wears.count - 1)"

        if let wear = day.wears.first, let outfit = day.outfit(for: wear) {
            imageView.sd_setImage(with: outfit.imageURL)
        } else {
            imageView.image = nil
        }

        accessibilityLabel = day.accessibilityLabel
        isAccessibilityElement = day.date != nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        dayLabel.text = nil
        dayBadge.backgroundColor = .clear
        countLabel.isHidden = true
    }
}
