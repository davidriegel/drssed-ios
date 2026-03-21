//
//  ClothingViewCell.swift
//  Drssed
//
//  Created by David Riegel on 21.03.26.
//

import UIKit
import SDWebImage

// MARK: - Custom Collection View Cell
class Clothing_ViewCell: UICollectionViewCell {
    static let identifier = "Clothing_ViewCell"
    
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
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .label
        label.numberOfLines = 2
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

        cardView.layer.cornerRadius = CornerStyle.medium.radius(for: contentView)
        cardView.layer.borderWidth = 0.5
        cardView.layer.borderColor = UIColor.separator.cgColor

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.18
        contentView.layer.shadowRadius = 10
        contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.layer.masksToBounds = false
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // CardView fills the contentView with a small inset
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            // ImageView fills the cardView
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Title label on top of ImageView
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -6),
        ])
    }

    func configure(item: Clothing, title: String? = nil) {
        titleLabel.text = title

        imageView.sd_setImage(with: URL(string: item.imageID, relativeTo: APIClient.clothingImagesURL))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }


    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        setNeedsLayout()
        layoutIfNeeded()
    }
}
