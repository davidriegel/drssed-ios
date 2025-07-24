//
//  ClothingDetailsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 02.08.24.
//

import UIKit
import SDWebImage
import SkeletonView

final class ClothingDetailsController: UIViewController {
    
    weak var delegate: ClothingDetailsControllerDelegate?
    let clothing: Clothing
    
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
    
    lazy var clothingNameField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: "name", placeholder: "super cool t-shirt", text: clothing.name, charCounterWithCharacters: 50)
        view.fieldInput.delegate = self
        view.fieldInput.isUserInteractionEnabled = false
        return view
    }()
    
    // MARK: -- Type
    
    lazy var clothingTypeField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: "type of clothing")
        view.fieldInput.isUserInteractionEnabled = false
        view.fieldInput.addTarget(self, action: #selector(showPickerView), for: .touchUpInside)
        return view
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
    
    // MARK: -- Color
    
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
    
    lazy var colorPickerField = CustomInputBackground(fieldTitle: "color")
    
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
    
    // MARK: -- Seasons
    
    lazy var clothingSeasonsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: "seasons")
        view.fieldInput.isUserInteractionEnabled = false
        view.fieldInput.addTarget(self, action: #selector(seasonButtonTapped), for: .touchUpInside)
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
    
    // MARK: -- Tags
    
    lazy var clothingTagsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: "tags")
        view.fieldInput.isUserInteractionEnabled = false
        view.fieldInput.addTarget(self, action: #selector(tagButtonTapped), for: .touchUpInside)
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
    
    // MARK: -- Buttons
    
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
        
        view.addSubview(clothingNameField)
        NSLayoutConstraint.activate([
            clothingNameField.topAnchor.constraint(equalTo: clothingImageView.bottomAnchor, constant: 10),
            clothingNameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingNameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingNameField.heightAnchor.constraint(equalToConstant: self.view.frame.height / 13)
        ])
        
        view.addSubview(clothingTypeField)
        clothingTypeField.addSubview(clothingTypeLabel)
        NSLayoutConstraint.activate([
            clothingTypeField.topAnchor.constraint(equalTo: clothingNameField.bottomAnchor, constant: 10),
            clothingTypeField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingTypeField.widthAnchor.constraint(equalToConstant: ((view.safeAreaLayoutGuide.layoutFrame.width / 2) - 25)),
            clothingTypeField.heightAnchor.constraint(equalToConstant: self.view.frame.height / 13),
            
            clothingTypeLabel.topAnchor.constraint(equalTo: clothingTypeField.fieldBackground.topAnchor),
            clothingTypeLabel.leadingAnchor.constraint(equalTo: clothingTypeField.leadingAnchor),
            clothingTypeLabel.trailingAnchor.constraint(equalTo: clothingTypeField.trailingAnchor),
            clothingTypeLabel.bottomAnchor.constraint(equalTo: clothingTypeField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(colorPickerField)
        colorPickerField.addSubview(clothingColorButton)
        NSLayoutConstraint.activate([
            colorPickerField.topAnchor.constraint(equalTo: clothingNameField.bottomAnchor, constant: 10),
            colorPickerField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            colorPickerField.widthAnchor.constraint(equalToConstant: ((view.safeAreaLayoutGuide.layoutFrame.width / 2) - 25)),
            colorPickerField.heightAnchor.constraint(equalToConstant: self.view.frame.height / 13),
            
            clothingColorButton.topAnchor.constraint(equalTo: colorPickerField.fieldBackground.topAnchor, constant: 5),
            clothingColorButton.leadingAnchor.constraint(equalTo: colorPickerField.fieldBackground.leadingAnchor, constant: 5),
            clothingColorButton.trailingAnchor.constraint(equalTo: colorPickerField.fieldBackground.trailingAnchor, constant: -5),
            clothingColorButton.bottomAnchor.constraint(equalTo: colorPickerField.fieldBackground.bottomAnchor, constant: -5)
        ])
        
        view.addSubview(clothingSeasonsField)
        clothingSeasonsField.addSubview(clothingSeasonsLabel)
        NSLayoutConstraint.activate([
            clothingSeasonsField.topAnchor.constraint(equalTo: clothingTypeField.bottomAnchor, constant: 10),
            clothingSeasonsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingSeasonsField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingSeasonsField.heightAnchor.constraint(equalToConstant: self.view.frame.height / 13),
            
            clothingSeasonsLabel.topAnchor.constraint(equalTo: clothingSeasonsField.fieldBackground.topAnchor),
            clothingSeasonsLabel.leadingAnchor.constraint(equalTo: clothingSeasonsField.leadingAnchor),
            clothingSeasonsLabel.trailingAnchor.constraint(equalTo: clothingSeasonsField.trailingAnchor),
            clothingSeasonsLabel.bottomAnchor.constraint(equalTo: clothingSeasonsField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(clothingTagsField)
        clothingTagsField.addSubview(clothingTagsLabel)
        NSLayoutConstraint.activate([
            clothingTagsField.topAnchor.constraint(equalTo: clothingSeasonsLabel.bottomAnchor, constant: 10),
            clothingTagsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingTagsField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingTagsField.heightAnchor.constraint(equalToConstant: self.view.frame.height / 13),
            
            clothingTagsLabel.topAnchor.constraint(equalTo: clothingTagsField.fieldBackground.topAnchor),
            clothingTagsLabel.leadingAnchor.constraint(equalTo: clothingTagsField.leadingAnchor),
            clothingTagsLabel.trailingAnchor.constraint(equalTo: clothingTagsField.trailingAnchor),
            clothingTagsLabel.bottomAnchor.constraint(equalTo: clothingTagsField.fieldBackground.bottomAnchor)
        ])
        
        let tagTap = UITapGestureRecognizer(target: self, action: #selector(tagButtonTapped))
        clothingTagsLabel.addGestureRecognizer(tagTap)
        
        view.addSubview(deleteButton)
        deleteButton.topAnchor.constraint(equalTo: clothingTagsField.bottomAnchor, constant: 20).isActive = true
        deleteButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(editButton)
        editButton.topAnchor.constraint(equalTo: clothingTagsField.bottomAnchor, constant: 20).isActive = true
        editButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        editButton.addTarget(self, action: #selector(startEditing), for: .touchUpInside)
        
        view.addSubview(doneButton)
        doneButton.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 10).isActive = true
        doneButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        doneButton.addTarget(self, action: #selector(finishEditing), for: .touchUpInside)
        
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
