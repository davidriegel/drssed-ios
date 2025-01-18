//
//  DefaultAvatarPicker.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.01.25.
//

import UIKit

protocol UIDefaultAvatarPickerDelegate: AnyObject {
    func defaultAvatarPicker(_ image: UIImage, _ named: String)
}

class UIDefaultAvatarPicker: UIViewController {
    weak var delegate: UIDefaultAvatarPickerDelegate?
    
    let defaultAvatarsNamed: [String] = ["default_hat_profilepicture", "default_scarf_profilepicture", "default_cap_profilepicture", "default_tshirt_profilepicture", "default_sweater_profilepicture"]
    lazy var defaultAvatars: [UIImage] = self.defaultAvatarsNamed.compactMap { name in
        UIImage(named: name)!
    }
    
    init(delegate: UIDefaultAvatarPickerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    lazy var collectionView: UICollectionView = {
        var layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.itemSize = CGSize(width: (self.view.bounds.width / 3) - 1.5, height: (self.view.bounds.width / 3) - 1.5)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 1, bottom: 10, right: 1)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(DefaultAvatarCell.self, forCellWithReuseIdentifier: DefaultAvatarCell.identifier)
        cv.backgroundColor = .background
        cv.isUserInteractionEnabled = true
        return cv
    }()
    
    @objc
    func cancelTapped() {
        navigationController?.dismiss(animated: true)
    }

    func configureViewComponents() {
        view.backgroundColor = .background
        title = "default avatars"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        
        view.addSubview(collectionView)
        //collectionView.frame = view.bounds
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
}

extension UIDefaultAvatarPicker: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return defaultAvatars.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let customCell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultAvatarCell.identifier, for: indexPath) as? DefaultAvatarCell else {
            assertionFailure("couldn't create cell")
            return UICollectionViewCell()
        }
        
        customCell.imageView.image = defaultAvatars[indexPath.item]
        
        return customCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.defaultAvatarPicker(defaultAvatars[indexPath.item], defaultAvatarsNamed[indexPath.item])
        cancelTapped()
    }
}
