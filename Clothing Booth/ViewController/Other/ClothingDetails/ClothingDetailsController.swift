//
//  ClothingDetailsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 02.08.24.
//

import UIKit
import SDWebImage
import SkeletonView

protocol ClothingDetailsControllerDelegate: AnyObject {
    func didEditClothing(_ clothing: Clothing)
}

class ClothingDetailsController: UIViewController {
    
    weak var delegate: ClothingDetailsControllerDelegate?
    private let clothing: Clothing
    
    let clothingTypes = [
        "*🤫🌟",
        "T-Shirt",
        "Shirt",
        "Polo",
        "Sweater",
        "Hoodie",
        "Jacket",
        "Coat",
        "*🤫🌟",
        "Jeans",
        "Shorts",
        "Pants",
        "Skirt",
        "*🤫🌟",
        "Sneakers",
        "Boots",
        "Sandals",
        "Heels",
        "Loafers",
        "*🤫🌟",
        "Hat",
        "Scarf",
        "Gloves",
        "Belt",
        "Bag",
        "Watch",
        "Accessory"
    ]
    
    init(_ clothing: Clothing) {
        self.clothing = clothing
        
        super.init(nibName: nil, bundle: nil)
        
        selectedSeasonsArray = clothing.seasons
        selectedTagsArray = clothing.tags
        
        presentationController?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let colorPickerView = UIColorPickerViewController()
    var updatedImageID: String?
    
    var isEditingClothing = false {
        didSet {
            isModalInPresentation = isEditingClothing
            setEditingMode()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: --
    
    var selectedSeasonsArray: Array = [String]() {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains("Spring") { selected.append("Spring")}
            if selectedSeasonsArray.contains("Summer") { selected.append("Summer")}
            if selectedSeasonsArray.contains("Autumn") { selected.append("Autumn")}
            if selectedSeasonsArray.contains("Winter") { selected.append("Winter")}
            
            
            clothingSeasonsLabel.text = selected.joined(separator: ", ")
            clothingSeasonsLabel.textColor = .label
            
            if selected.isEmpty {
                clothingSeasonsLabel.textColor = .placeholderText
                clothingSeasonsLabel.text = "none"
            }
        }
    }
    
    var selectedTagsArray: Array = [String]() {
        didSet {
            var selected = [String]()
            if selectedTagsArray.contains("Casual") { selected.append("Casual")}
            if selectedTagsArray.contains("Formal") { selected.append("Formal")}
            if selectedTagsArray.contains("Sports") { selected.append("Sports")}
            if selectedTagsArray.contains("Vintage") { selected.append("Vintage")}
            
            
            clothingTagsLabel.text = selected.joined(separator: ", ")
            clothingTagsLabel.textColor = .label
            
            if selected.isEmpty {
                clothingTagsLabel.textColor = .placeholderText
                clothingTagsLabel.text = "none"
            }
        }
    }
    
    // MARK: -- Image
    
    lazy var clothingImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.heightAnchor.constraint(equalToConstant: self.view.frame.width * (2 / 3)).isActive = true
        iv.widthAnchor.constraint(equalToConstant: self.view.frame.width * (2 / 3)).isActive = true
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        return picker
    }()
    
    // MARK: -- Name
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "name"
        return label
    }()
    
    lazy var nameBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var nameCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.text = "\(clothing.name.count)/50"
        return label
    }()
    
    lazy var clothingNameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.placeholder = "super cool t-shirt"
        tf.textColor = .label
        tf.text = clothing.name
        tf.textAlignment = .left
        tf.isUserInteractionEnabled = false
        tf.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        tf.font = .systemFont(ofSize: 13, weight: .heavy)
        tf.returnKeyType = .done
        return tf
    }()
    
    // MARK: -- Type

    lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "type of clothing"
        return label
    }()
    
    lazy var typeBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.widthAnchor.constraint(equalToConstant: (self.view.frame.width / 2) - 25).isActive = true
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var typeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        return button
    }()
    
    lazy var typePicker: UIPickerView = {
        let pv = UIPickerView()
        pv.isHidden = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.alpha = 0
        pv.backgroundColor = .secondarySystemBackground
        pv.autoresizingMask = .flexibleWidth
        pv.contentMode = .center
        
        let topBorder = CALayer()
        topBorder.backgroundColor = UIColor.darkGray.cgColor
        topBorder.frame = CGRectMake(0, 0, self.view.frame.width, 1.5)
        pv.layer.addSublayer(topBorder)
        return pv
    }()
    
    lazy var typePickerDone: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: "Done", attributes: [.font : UIFont.systemFont(ofSize: 18, weight: .bold)])
        button.isHidden = true
        button.alpha = 0
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    lazy var clothingTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = clothing.category
        return label
    }()
    
    lazy var colorPickerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "color"
        return label
    }()
    
    lazy var colorPickerBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.widthAnchor.constraint(equalToConstant: (self.view.frame.width / 2) - 25).isActive = true
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var clothingColorButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: clothing.color)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.secondaryLabel.cgColor
        button.layer.cornerRadius = (self.view.frame.height / 20) / 4.16
        button.addTarget(self, action: #selector(showColorPicker), for: .touchUpInside)
        button.isUserInteractionEnabled = false
        return button
    }()

    lazy var seasonsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "seasons"
        return label
    }()
    
    lazy var seasonsBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var clothingSeasonsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = clothing.seasons.joined(separator: ", ")
        return label
    }()
    
    lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "tags"
        return label
    }()
    
    lazy var tagsBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var clothingTagsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = clothing.tags.joined(separator: ", ")
        return label
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setImage(UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.systemRed, renderingMode: .alwaysOriginal), for: .normal)
        button.setAttributedTitle(NSAttributedString(string: "delete", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemRed.withAlphaComponent(0.2)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: (self.view.frame.width / 2) - 25).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    lazy var editButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal), for: .normal)
        button.setAttributedTitle(NSAttributedString(string: "edit", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.systemYellow, for: .normal)
        button.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: (self.view.frame.width / 2) - 25).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: "done", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.accent, for: .normal)
        button.backgroundColor = .accent.withAlphaComponent(0.2)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    // MARK: -- ObjC Functions
    
    @objc
    func uploadImage() {
        let selectionAlert = UIAlertController(title: "👕", message: "Please ensure a high contrast between the clothing piece and the background also try to use a bright environment for better results.", preferredStyle: .alert)
        selectionAlert.addAction(UIAlertAction(title: "Upload Image", style: .default, handler: { _ in
            self.present(self.imagePickerController, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
            let infoAlert = UIAlertController(title: "Soon", message: "This is currently not possible but very soon will be.", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(selectionAlert, animated: true)
    }
    
    @objc
    func showPickerView(_ sender: UIButton) {
        guard typePicker.isHidden == true else {
            return
        }
        
        let bottomOfPickerButton = typeBackgroundView.convert(typeBackgroundView.bounds, to: view).maxY
        let topOfPicker = view.frame.height - typePicker.frame.height
        let heightDifferenceOfPickerButton = typeBackgroundView.convert(typeBackgroundView.bounds, to: typePicker).maxY
        
        typePicker.isHidden = false
        typePickerDone.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            if bottomOfPickerButton > topOfPicker {
                let topConstraint = self.clothingImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
                topConstraint!.constant = -heightDifferenceOfPickerButton
                self.clothingImageView.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            self.typePicker.alpha = 1
            self.typePickerDone.alpha = 1
        }
    }
    
    @objc func hidePickerView() {
        UIView.animate(withDuration: 0.3) {
            let topConstraint = self.clothingImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
            topConstraint!.constant = 15
            self.clothingImageView.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.typePicker.alpha = 0
            self.typePickerDone.alpha = 0
        } completion: { _ in
            self.typePicker.isHidden = true
            self.typePickerDone.isHidden = true
        }
    }
    
    @objc
    func showColorPicker() {
        present(colorPickerView, animated: true)
    }
    
    @objc func seasonButtonTapped() {
        showSeasonPicker { selectedSeason in
            let seasonName = String(selectedSeason.dropFirst(2))
            if self.selectedSeasonsArray.contains(seasonName) {
                self.selectedSeasonsArray.remove(at: self.selectedSeasonsArray.firstIndex(of: seasonName)!)
            } else {
                self.selectedSeasonsArray.append(seasonName)
            }
        }
    }
    
    @objc func tagButtonTapped() {
        showTagPicker { selectedTag in
            let tagName = String(selectedTag.dropFirst(2))
            if self.selectedTagsArray.contains(tagName) {
                self.selectedTagsArray.remove(at: self.selectedTagsArray.firstIndex(of: tagName)!)
            } else {
                self.selectedTagsArray.append(tagName)
            }
        }
    }
    
    @objc
    func startEditing() {
        isEditingClothing = true
    }
    
    @objc
    func finishEditing() {
        isEditingClothing = false
        guard checkChangesMade() else { return }
        
        let editedClothingItem = clothing.update(
            name: clothingNameTextField.text,
            category: clothingTypeLabel.text,
            tags: selectedTagsArray,
            seasons: selectedSeasonsArray,
            color: colorPickerView.selectedColor.hexStringFromColor(color: colorPickerView.selectedColor),
            image: updatedImageID
        )
        
        Task {
            do {
                try await saveChangesToDatabase(editedClothingItem)
                try saveChangesToUserDefaults(editedClothingItem)
                
                delegate?.didEditClothing(editedClothingItem)
            } catch let e {
                ErrorHandler.handle(e)
            }
        }
    }
    
    // MARK: -- Functions
    
    func showSeasonPicker(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Pick a Season", message: nil, preferredStyle: .actionSheet)

        let tags = ["🌱 Spring", "☀️ Summer", "🍂 Autumn", "❄️ Winter"]

        for tag in tags {
            alert.addAction(UIAlertAction(title: tag, style: .default, handler: { _ in
                completion(tag)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }
    
    func showTagPicker(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Pick a Tag", message: nil, preferredStyle: .actionSheet)

        let tags = ["🧍🏻 Casual", "🕴🏻 Formal", "⛹🏻 Sports", "🧳 Vintage"]

        for tag in tags {
            alert.addAction(UIAlertAction(title: tag, style: .default, handler: { _ in
                completion(tag)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    
    func setEditingMode() {
        clothingImageView.isUserInteractionEnabled = isEditingClothing
        clothingNameTextField.isUserInteractionEnabled = isEditingClothing
        typeButton.isUserInteractionEnabled = isEditingClothing
        clothingSeasonsLabel.isUserInteractionEnabled = isEditingClothing
        clothingColorButton.isUserInteractionEnabled = isEditingClothing
        clothingTagsLabel.isUserInteractionEnabled = isEditingClothing
    }
    
    func checkChangesMade() -> Bool {
        return !(clothingNameTextField.text == clothing.name && (updatedImageID == nil) && clothingTypeLabel.text == clothing.category && selectedTagsArray == clothing.tags && selectedSeasonsArray == clothing.seasons && colorPickerView.selectedColor.hexStringFromColor(color: colorPickerView.selectedColor) == clothing.color)
    }
    
    func saveChangesToDatabase(_ item: Clothing) async throws {
        try await APIHandler.shared.clothingHandler.patchEditClothing(clothing: item)
    }
    
    func saveChangesToUserDefaults(_ item: Clothing) throws {
        var clothesArray = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
        
        guard let clothingIndex = clothesArray.firstIndex (where: { $0.clothing_id == clothing.clothing_id }) else {
            return assertionFailure("clothingIndex should not be nil")
        }
        
        clothesArray[clothingIndex] = item
        
        let encoded = try JSONEncoder().encode(clothesArray)
        
        UserDefaults.standard.setValue(encoded, forKey: "userClothes")
    }
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        colorPickerView.supportsAlpha = false
        colorPickerView.selectedColor = .label
        colorPickerView.delegate = self
        colorPickerView.title = "color picker"
        
        view.addSubview(clothingImageView)
        clothingImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        clothingImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        clothingImageView.sd_setImage(with: URL(string: clothing.image, relativeTo: URL(string: "https://api.clothing-booth.com/")))
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(uploadImage))
        clothingImageView.addGestureRecognizer(imageTap)
        
        view.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: clothingImageView.bottomAnchor, constant: 10).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(nameBackgroundView)
        nameBackgroundView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        nameBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        nameBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        nameBackgroundView.addSubview(nameCountLabel)
        nameCountLabel.bottomAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: -5).isActive = true
        nameCountLabel.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -10).isActive = true
        
        nameBackgroundView.addSubview(clothingNameTextField)
        clothingNameTextField.centerYAnchor.constraint(equalTo: nameBackgroundView.centerYAnchor).isActive = true
        clothingNameTextField.leftAnchor.constraint(equalTo: nameBackgroundView.leftAnchor, constant: 5).isActive = true
        clothingNameTextField.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(typeLabel)
        typeLabel.topAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: 10).isActive = true
        typeLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(typeBackgroundView)
        typeBackgroundView.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 5).isActive = true
        typeBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        
        typeBackgroundView.addSubview(typeButton)
        typeButton.topAnchor.constraint(equalTo: typeBackgroundView.topAnchor).isActive = true
        typeButton.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor).isActive = true
        typeButton.bottomAnchor.constraint(equalTo: typeBackgroundView.bottomAnchor).isActive = true
        typeButton.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor).isActive = true
        typeButton.addTarget(self, action: #selector(showPickerView), for: .touchUpInside)
        
        typeBackgroundView.addSubview(clothingTypeLabel)
        clothingTypeLabel.centerYAnchor.constraint(equalTo: typeBackgroundView.centerYAnchor).isActive = true
        clothingTypeLabel.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor, constant: 5).isActive = true
        clothingTypeLabel.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(colorPickerLabel)
        colorPickerLabel.topAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: 10).isActive = true
        colorPickerLabel.leftAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: 5).isActive = true
        
        view.addSubview(colorPickerBackgroundView)
        colorPickerBackgroundView.topAnchor.constraint(equalTo: colorPickerLabel.bottomAnchor, constant: 5).isActive = true
        colorPickerBackgroundView.leftAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: 5).isActive = true
        
        colorPickerBackgroundView.addSubview(clothingColorButton)
        clothingColorButton.topAnchor.constraint(equalTo: colorPickerBackgroundView.topAnchor, constant: 5).isActive = true
        clothingColorButton.leftAnchor.constraint(equalTo: colorPickerBackgroundView.leftAnchor, constant: 5).isActive = true
        clothingColorButton.rightAnchor.constraint(equalTo: colorPickerBackgroundView.rightAnchor, constant: -5).isActive = true
        clothingColorButton.bottomAnchor.constraint(equalTo: colorPickerBackgroundView.bottomAnchor, constant: -5).isActive = true

        view.addSubview(seasonsLabel)
        seasonsLabel.topAnchor.constraint(equalTo: typeBackgroundView.bottomAnchor, constant: 10).isActive = true
        seasonsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(seasonsBackgroundView)
        seasonsBackgroundView.topAnchor.constraint(equalTo: seasonsLabel.bottomAnchor, constant: 5).isActive = true
        seasonsBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        seasonsBackgroundView.addSubview(clothingSeasonsLabel)
        clothingSeasonsLabel.centerYAnchor.constraint(equalTo: seasonsBackgroundView.centerYAnchor).isActive = true
        clothingSeasonsLabel.leftAnchor.constraint(equalTo: seasonsBackgroundView.leftAnchor, constant: 5).isActive = true
        clothingSeasonsLabel.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor, constant: -5).isActive = true
        
        let seasonTap = UITapGestureRecognizer(target: self, action: #selector(seasonButtonTapped))
        clothingSeasonsLabel.addGestureRecognizer(seasonTap)
        
        view.addSubview(tagsLabel)
        tagsLabel.topAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor, constant: 10).isActive = true
        tagsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        tagsLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(tagsBackgroundView)
        tagsBackgroundView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 5).isActive = true
        tagsBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        tagsBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        tagsBackgroundView.addSubview(clothingTagsLabel)
        clothingTagsLabel.centerYAnchor.constraint(equalTo: tagsBackgroundView.centerYAnchor).isActive = true
        clothingTagsLabel.leftAnchor.constraint(equalTo: tagsBackgroundView.leftAnchor, constant: 5).isActive = true
        clothingTagsLabel.rightAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor, constant: -5).isActive = true
        
        let tagTap = UITapGestureRecognizer(target: self, action: #selector(tagButtonTapped))
        clothingTagsLabel.addGestureRecognizer(tagTap)
        
        view.addSubview(deleteButton)
        deleteButton.topAnchor.constraint(equalTo: tagsBackgroundView.bottomAnchor, constant: 20).isActive = true
        deleteButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(editButton)
        editButton.topAnchor.constraint(equalTo: tagsBackgroundView.bottomAnchor, constant: 20).isActive = true
        editButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        editButton.addTarget(self, action: #selector(startEditing), for: .touchUpInside)
        
        view.addSubview(doneButton)
        doneButton.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 10).isActive = true
        doneButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        doneButton.addTarget(self, action: #selector(finishEditing), for: .touchUpInside)
        
        setupPickerView()
    }
    
    func setupPickerView() {
        view.addSubview(typePicker)
        typePicker.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        typePicker.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        typePicker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.selectRow(clothingTypes.firstIndex(of: clothing.category) ?? 0, inComponent: 0, animated: false)
        
        view.addSubview(typePickerDone)
        typePickerDone.topAnchor.constraint(equalTo: typePicker.topAnchor, constant: 10).isActive = true
        typePickerDone.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        typePickerDone.addTarget(self, action: #selector(hidePickerView), for: .touchUpInside)
    }
}

extension ClothingDetailsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            dismiss(animated: true)
            
            guard let image = info[.editedImage] as? UIImage else { return }
            let assetPath = info[.imageURL] as! NSURL
            let fileExtension = (assetPath.absoluteString ?? "").components(separatedBy: ".").last ?? ""
            
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. [\(fileExtension)]", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                present(alert, animated: true)
                return
            }
            
            clothingImageView.image = nil
            clothingImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            do {
                let clothingURL = try await APIHandler.shared.clothingHandler.removeClothingBackground(from: image, fileExtension)
                
                updatedImageID = clothingURL.deletingPathExtension().lastPathComponent
                clothingImageView.sd_setImage(with: clothingURL)
                clothingImageView.hideSkeleton()
            } catch APIError.payloadTooLarge {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.image, relativeTo: APIHandler.baseURL))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(APIError.payloadTooLargeWithMessage("The image background couldn't be removed.", suggestion: "Use a smaller image or a image with lower resolution."))                }
            } catch APIError.unprocessableContent {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.image, relativeTo: APIHandler.baseURL))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(APIError.unprocessableContentWithMessage("The image backround couldn't be removed.", suggestion: "Use a brighter enviroment and ensure a high contrast for the best results."))
                }
            } catch {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.image, relativeTo: APIHandler.baseURL))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(error)
                }
            }
        }
    }
}

extension ClothingDetailsController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return clothingTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        guard clothingTypes[row].contains("*") else {
            let label = UILabel()
            label.textAlignment = .center
            label.text = clothingTypes[row]
            label.font = UIFont.systemFont(ofSize: 22)

            return label
        }
        
        let splitter = UIView()
        splitter.backgroundColor = .lightGray
        splitter.frame = CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 2)
        return splitter
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var newText = clothingTypes[row]
        let previousIndex = clothingTypes.firstIndex(of: clothingTypeLabel.text ?? "") ?? 0
        
        if newText.contains("*") {
            pickerView.selectRow(row > previousIndex ? row - 1 : row + 1, inComponent: component, animated: true)
            newText = clothingTypes[row > previousIndex ? row - 1 : row + 1]
        }
        
        clothingTypeLabel.text = newText
        clothingTypeLabel.textColor = .label
    }
}

extension ClothingDetailsController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case clothingNameTextField:
            if string == "" {
                nameCountLabel.text = "\((clothingNameTextField.text?.count ?? 0) - 1)/50"
                return true
            }
            
            guard clothingNameTextField.text?.count ?? 0 < 50 else { return false }
            
            nameCountLabel.text = "\((clothingNameTextField.text?.count ?? 0) + 1)/50"
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension ClothingDetailsController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !isEditingClothing
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard checkChangesMade() else {
            dismiss(animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Unsaved changes", message: "There are some unsaved changes", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Save and continue", style: .default, handler: { _ in
            self.finishEditing()
        }))
        
        alert.addAction(UIAlertAction(title: "Undo", style: .destructive, handler: { _ in
            self.clothingNameTextField.text = self.clothing.name
            self.clothingTypeLabel.text = self.clothing.category
            self.selectedTagsArray = self.clothing.tags
            self.selectedSeasonsArray = self.clothing.seasons
            self.clothingColorButton.backgroundColor = UIColor(hex: self.clothing.color)
            self.colorPickerView.selectedColor = UIColor(hex: self.clothing.color)!
            
            if self.updatedImageID != nil {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.image, relativeTo: URL(string: "https://api.clothing-booth.com/")))
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Abort", style: .cancel, handler: { _ in
            return
        }))
        
        present(alert, animated: true)
    }
}

extension ClothingDetailsController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        clothingColorButton.backgroundColor = color
    }
}
