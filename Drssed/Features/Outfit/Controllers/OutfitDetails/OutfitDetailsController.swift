//
//  OutfitDetailsController.swift
//  Drssed
//
//  Created by David Riegel on 19.03.26.
//

import UIKit
import CropViewController
import PhotosUI

final class OutfitDetailsController: UIViewController {
    var savedItem: Outfit
    var item: Outfit
    let clothingRepo = ClothingRepository()
    
    init(outfit: Outfit) {
        self.savedItem = outfit
        self.item = outfit
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }
    
    // MARK: - UI Elements -
    
    
    // Image UI
    
    lazy var itemImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        
        iv.sd_setImage(with: URL(string: item.imageID, relativeTo: APIClient.outfitImagesURL), placeholderImage: UIImage(named: "placeholder.upload"))
        return iv
    }()
    
    // Name
    
    lazy var itemNameTextField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.name.title"), placeholder: String(localized: "common.placeholder.name"), text: item.name, charCounterWithCharacters: 50)
        view.fieldInput.isUserInteractionEnabled = false
        return view
    }()
    
    // Outfit items
    
    lazy var  outfitItemsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(Clothing_ViewCell.self, forCellWithReuseIdentifier: Clothing_ViewCell.identifier)
        cv.isScrollEnabled = false
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = .background
        return cv
    }()
    
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        
        [itemImageView, itemNameTextField, outfitItemsCollectionView].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            itemImageView.leadingAnchor.constraint(lessThanOrEqualTo: view.leadingAnchor, constant: 20),
            itemImageView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            itemImageView.heightAnchor.constraint(equalTo: itemImageView.widthAnchor, multiplier: 1),
            itemImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            itemNameTextField.topAnchor.constraint(equalTo: itemImageView.bottomAnchor, constant: 20),
            itemNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            itemNameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
        
        NSLayoutConstraint.activate([
            outfitItemsCollectionView.topAnchor.constraint(equalTo: itemNameTextField.bottomAnchor, constant: 10),
            outfitItemsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            outfitItemsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            outfitItemsCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2)
        ])
    }
}

extension OutfitDetailsController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item.scene.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Clothing_ViewCell.identifier,
            for: indexPath
        ) as! Clothing_ViewCell
        
        let clothingID = item.scene[indexPath.item].clothing_id
        
        Task { @MainActor in
            guard let clothing = await clothingRepo.getClothing(with: clothingID) else {
                return
            }
            
            if collectionView.indexPath(for: cell) == indexPath {
                cell.configure(item: clothing)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 40) / 3
        return CGSize(width: width, height: width)
    }
}
