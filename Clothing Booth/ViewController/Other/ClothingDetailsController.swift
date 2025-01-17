//
//  ClothingDetailsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 02.08.24.
//

import UIKit
import SDWebImage

class ClothingDetailsController: UIViewController {
    
    private let clothing: Clothing
    
    init(_ clothing: Clothing) {
        self.clothing = clothing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: -- Information about the selected clothing piece ( for Generator Controller ) [Image Name Brand Type ShortDescription Type ]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: --
    
    lazy var clothingImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.heightAnchor.constraint(equalToConstant: self.view.frame.width * (2 / 3)).isActive = true
        iv.widthAnchor.constraint(equalToConstant: self.view.frame.width * (2 / 3)).isActive = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        
        view.addSubview(clothingImageView)
        clothingImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        clothingImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        clothingImageView.sd_setImage(with: URL(string: clothing.image, relativeTo: URL(string: "https://api.clothing-booth.com/")))
    }
}
