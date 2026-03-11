//
//  ImageBackgroundView.swift
//  Wearhouse
//
//  Created by David Riegel on 15.08.25.
//

import Foundation
import UIKit
import SDWebImage

protocol ClothingImagePreviewDelegate: AnyObject {
    func didTapOnImage(_ clothing: Clothing)
}

class ClothingImagePreview: UIView {
    private(set) var clothing: Clothing? = nil
    public var delegate: ClothingImagePreviewDelegate?
    
    private lazy var clothingImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapImage)))
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height * 0.15
    }
    
    @objc
    func didTapImage() {
        guard let clothing = clothing else { return }
        
        delegate?.didTapOnImage(clothing)
    }
    
    init(clothing: Clothing) {
        super.init(frame: .zero)
        
        self.clothing = clothing
        
        backgroundColor = .secondarySystemBackground
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        addSubview(clothingImageView)
        
        NSLayoutConstraint.activate([
            clothingImageView.heightAnchor.constraint(equalTo: heightAnchor),
            clothingImageView.widthAnchor.constraint(equalTo: heightAnchor),
            clothingImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            clothingImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        clothingImageView.sd_setImage(with: URL(string: clothing.imageID, relativeTo: APIHandler.clothingImagesURL))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
