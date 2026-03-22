//
//  OutfitsGallery_ViewCell.swift
//  Drssed
//
//  Created by David Riegel on 16.08.25.
//
import UIKit
import SDWebImage

protocol OutfitsGallery_ViewCellDelegate: AnyObject {
    func didLoadImageSize(_ size: CGSize, for outfit: Outfit)
}

// MARK: - Custom Collection View Cell
class OutfitsGallery_ViewCell: UICollectionViewCell {
    static let identifier = "OutfitsGallery_ViewCell"
    
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
    
    weak var delegate: OutfitsGallery_ViewCellDelegate?

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
    
    private let itemCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 11)
        label.textColor = .accent
        label.textAlignment = .right
        return label
    }()
    
    private let itemFavoriteImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.image = UIImage(systemName: "heart.fill")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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
        cardView.addSubview(itemCountLabel)
        cardView.addSubview(itemFavoriteImageView)

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
            
            // Item count label on top of ImageView
            itemCountLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            itemCountLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            itemCountLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            
            // Item heart button on top of ImageView
            
            itemFavoriteImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            itemFavoriteImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            itemFavoriteImageView.heightAnchor.constraint(equalTo: itemCountLabel.heightAnchor, multiplier: 1)
        ])
    }

    func configure(with outfit: Outfit, title: String? = nil) {
        titleLabel.text = title
        itemCountLabel.text = "● " + String(outfit.scene.count)
        itemFavoriteImageView.isHidden = !outfit.isFavorite

        imageView.sd_setImage(with: URL(string: outfit.imageID, relativeTo: APIClient.outfitImagesURL)) { [weak self] image, _, _, _ in
            guard let self = self, let image = image else { return }
            self.delegate?.didLoadImageSize(image.size, for: outfit)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        itemCountLabel.text = nil
    }


    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        setNeedsLayout()
        layoutIfNeeded()
    }
}
