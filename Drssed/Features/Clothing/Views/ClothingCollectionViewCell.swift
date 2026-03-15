//
//  ClothingCollectionViewCell.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit
import SDWebImage
import SkeletonView

public class ClothingCollectionViewCell: UICollectionViewCell {
    public static let identifier: String = "ClothingCollectionViewCell"
    
    public override var isHighlighted: Bool {
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.isSkeletonable = true
    }
    
    public override var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = CornerStyle.large.radius(for: contentView)
        imageViewWrapper.layer.cornerRadius = CornerStyle.large.radius(for: contentView) - 5
        selectedOverlay.layer.cornerRadius = CornerStyle.large.radius(for: contentView) - 5
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private lazy var imageViewWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isSkeletonable = true
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isSkeletonable = true
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    private lazy var nameLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isSkeletonable = true
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        lb.adjustsFontSizeToFitWidth = true
        lb.minimumScaleFactor = 0.4
        lb.numberOfLines = 2
        lb.textAlignment = .center
        return lb
    }()
    
    private lazy var selectedOverlay: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.20)
        v.isHidden = true

        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.label, .accent])))
        check.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(check)

        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 35),
            check.heightAnchor.constraint(equalToConstant: 35)
        ])

        return v
    }()
    
    public func configureViewComponents(with image_id: String,and name: String, isSelectable: Bool = false) {
        backgroundColor = .accent
        
        contentView.addSubview(imageViewWrapper)
        NSLayoutConstraint.activate([
            imageViewWrapper.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1),
            imageViewWrapper.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            imageViewWrapper.topAnchor.constraint(equalTo: contentView.topAnchor)
        ])
        
        imageViewWrapper.addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: imageViewWrapper.widthAnchor, multiplier: 0.9).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageViewWrapper.heightAnchor, multiplier: 0.9).isActive = true
        imageView.centerXAnchor.constraint(equalTo: imageViewWrapper.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: imageViewWrapper.centerYAnchor).isActive = true
        imageView.sd_setImage(with: URL(string: image_id, relativeTo: APIClient.clothingImagesURL))
        
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: imageViewWrapper.bottomAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        if isSelectable {
            contentView.addSubview(selectedOverlay)
            NSLayoutConstraint.activate([
                selectedOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                selectedOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                selectedOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
                selectedOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        nameLabel.text = name
    }
}
