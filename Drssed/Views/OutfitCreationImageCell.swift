//
//  OutfitCreationImageCell.swift
//  Wearhouse
//
//  Created by David Riegel on 13.08.25.
//


import UIKit
import SDWebImage

// MARK: - Custom Collection View Cell
class OutfitCreationImageCell: UICollectionViewCell {
static let identifier = "OutfitCreationImageCell"


private let imageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.clipsToBounds = true
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

private func setupUI() {
    contentView.addSubview(imageView)
    
    NSLayoutConstraint.activate([
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
    ])
}

    func configure(with image: String) {
        imageView.sd_setImage(with: URL(string: image, relativeTo: APIHandler.clothingImagesURL))
    }

override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
}


}
