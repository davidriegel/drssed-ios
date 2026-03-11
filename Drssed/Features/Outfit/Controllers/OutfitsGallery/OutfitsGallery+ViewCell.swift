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

    private let gradientOverlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor
        ]
        layer.locations = [0.0, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return layer
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

        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.18
        contentView.layer.shadowRadius = 10
        contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.layer.masksToBounds = false
        contentView.layer.shadowPath = UIBezierPath(roundedRect: cardView.frame, cornerRadius: 18).cgPath
        
        gradientLayer.frame = gradientOverlayView.bounds
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(imageView)
        cardView.addSubview(gradientOverlayView)
        gradientOverlayView.addSubview(titleLabel)

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

            // Gradient overlay fills the card vertically so it scales with cell height
            gradientOverlayView.topAnchor.constraint(equalTo: cardView.topAnchor),
            gradientOverlayView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            gradientOverlayView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            gradientOverlayView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            // Title label inside the gradient overlay
            titleLabel.leadingAnchor.constraint(equalTo: gradientOverlayView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: gradientOverlayView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: gradientOverlayView.bottomAnchor, constant: -6)
        ])

        // Add a gradient layer to the overlay view
        gradientOverlayView.layer.insertSublayer(gradientLayer, at: 0)
    }

    func configure(with outfit: Outfit, title: String? = nil) {
        titleLabel.text = title

        imageView.sd_setImage(with: URL(string: outfit.imageID, relativeTo: APIClient.outfitImagesURL)) { [weak self] image, _, _, _ in
            guard let self = self, let image = image else { return }
            self.delegate?.didLoadImageSize(image.size, for: outfit)
        }
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
        gradientLayer.frame = gradientOverlayView.bounds
    }
}
