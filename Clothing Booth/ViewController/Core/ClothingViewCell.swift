//
//  ClothingViewCell.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit
import SDWebImage
import SkeletonView

class ClothingViewCell: UICollectionViewCell {
    static let identifier: String = "clothing"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.heightAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (4 / 5)).isActive = true
        iv.widthAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (4 / 5)).isActive = true
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    lazy var nameLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lb.adjustsFontSizeToFitWidth = true
        lb.minimumScaleFactor = 0.4
        lb.heightAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (1 / 5)).isActive = true
        lb.widthAnchor.constraint(equalToConstant: self.contentView.frame.size.width * (3 / 4)).isActive = true
        lb.textAlignment = .center
        return lb
    }()
    
    func configureViewComponents(with imageURL: URL,and name: String) {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = self.contentView.frame.size.height / 6
        
        contentView.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        imageView.sd_setImage(with: imageURL)
        
        contentView.addSubview(nameLabel)
        nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5).isActive = true
        nameLabel.text = name
    }
}

class SkeletonClothingViewCell: UICollectionViewCell {
    static let identifier: String = "skeleton_clothing"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        
        
        contentView.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: imageView.leftAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: imageView.rightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.heightAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (3 / 5)).isActive = true
        iv.widthAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (3 / 5)).isActive = true
        iv.isSkeletonable = true
        iv.skeletonCornerRadius = Float(self.contentView.frame.size.height * (1 / 10))
        iv.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    lazy var nameLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lb.heightAnchor.constraint(equalToConstant: self.contentView.frame.size.height * (2 / 5)).isActive = true
        lb.isSkeletonable = true
        lb.lastLineFillPercent = Int.random(in: 50...80)
        lb.skeletonTextLineHeight = .relativeToFont
        lb.linesCornerRadius = 4
        lb.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        lb.textAlignment = .center
        return lb
    }()
}
