//
//  UploadController.swift
//  Clothing Booth
//
//  Created by David Riegel on 12.09.24.
//

import UIKit
import SkeletonView

class UploadController: UIViewController {
    
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
    var fileExtension: String = ""
    var selectedSeasonsArray: Array = [String]() {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains("Spring") { selected.append("Spring")}
            if selectedSeasonsArray.contains("Summer") { selected.append("Summer")}
            if selectedSeasonsArray.contains("Autumn") { selected.append("Autumn")}
            if selectedSeasonsArray.contains("Winter") { selected.append("Winter")}
            
            
            seasonsSelection.text = selected.joined(separator: ", ")
            seasonsSelection.textColor = .label
            
            if selected.isEmpty {
                seasonsSelection.textColor = .placeholderText
                seasonsSelection.text = "none"
            }
        }
    }
    
    var imageURL: URL?
    
    var selectedTagsArray: Array = [String]() {
        didSet {
            var selected = [String]()
            if selectedTagsArray.contains("Casual") { selected.append("Casual")}
            if selectedTagsArray.contains("Formal") { selected.append("Formal")}
            if selectedTagsArray.contains("Sports") { selected.append("Sports")}
            if selectedTagsArray.contains("Vintage") { selected.append("Vintage")}
            
            
            tagsSelection.text = selected.joined(separator: ", ")
            tagsSelection.textColor = .label
            
            if selected.isEmpty {
                tagsSelection.textColor = .placeholderText
                tagsSelection.text = "none"
            }
        }
    }
    
    let colorPickerView = UIColorPickerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: -- Image
    
    lazy var uploadImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isSkeletonable = true
        iv.skeletonCornerRadius = 12
        iv.image = UIImage(named: "upload_placeholder")
        iv.isUserInteractionEnabled = true
        iv.heightAnchor.constraint(equalToConstant: view.frame.width / 2.5).isActive = true
        iv.widthAnchor.constraint(equalToConstant: view.frame.width / 2.5).isActive = true
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
    
    lazy var nameCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.text = "0/50"
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
    
    lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.placeholder = "super cool t-shirt"
        tf.textColor = .label
        tf.textAlignment = .left
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
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var typeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var typeIndidicatorImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 25).isActive = true
        iv.widthAnchor.constraint(equalToConstant: 25).isActive = true
        return iv
    }()
    
    lazy var typeSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = "placeholder"
        return label
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
    
    // MARK: -- Seasons
    
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
    
    lazy var seasonsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var seasonsIndidicatorImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 25).isActive = true
        iv.widthAnchor.constraint(equalToConstant: 25).isActive = true
        return iv
    }()
    
    lazy var seasonsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = "none"
        return label
    }()
    
    lazy var seasonsPickerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        view.widthAnchor.constraint(equalToConstant: self.view.frame.width / 1.5).isActive = true
        view.layer.cornerRadius = (self.view.frame.width / 5) / 4.16
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        
        let backgroundDarken = CALayer()
        backgroundDarken.backgroundColor = UIColor(white: 0, alpha: 0.4).cgColor
        backgroundDarken.frame = CGRect(x: -self.view.frame.width, y: 0, width: self.view.frame.width * 2, height: self.view.frame.height / 2)
        view.layer.addSublayer(backgroundDarken)
        return view
    }()
    
    lazy var springPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "🌱 Spring", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var summerPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "☀️ Summer", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var autumnPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "🍂 Autumn", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var winterPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "❄️ Winter", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var seasonsPickerDone: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: "Done", attributes: [.font : UIFont.systemFont(ofSize: 16, weight: .bold)])
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    // MARK: -- Description
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "short description"
        return label
    }()
    
    lazy var descriptionCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.text = "0/155"
        return label
    }()
    
    lazy var descriptionBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.width / 5).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.backgroundColor = .clear
        tv.text = "optional description e.g. \"white tshirt with butterfly print\""
        tv.textColor = .placeholderText
        tv.textAlignment = .left
        tv.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        tv.font = .systemFont(ofSize: 13, weight: .heavy)
        tv.returnKeyType = .done
        return tv
    }()
    
    // MARK: -- Tags
    
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
        view.widthAnchor.constraint(equalToConstant: self.view.frame.width * (3 / 5)).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var tagsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var tagsIndidicatorImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 25).isActive = true
        iv.widthAnchor.constraint(equalToConstant: 25).isActive = true
        return iv
    }()
    
    lazy var tagsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = "none"
        return label
    }()
    
    lazy var tagsPickerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        view.widthAnchor.constraint(equalToConstant: self.view.frame.width / 1.5).isActive = true
        view.layer.cornerRadius = (self.view.frame.width / 5) / 4.16
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        
        let backgroundDarken = CALayer()
        backgroundDarken.backgroundColor = UIColor(white: 0, alpha: 0.4).cgColor
        backgroundDarken.frame = CGRect(x: -self.view.frame.width, y: 0, width: self.view.frame.width * 2, height: self.view.frame.height / 2)
        view.layer.addSublayer(backgroundDarken)
        return view
    }()
    
    lazy var casualPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "🧍🏻 Casual", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var formalPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "🕴🏻 Formal", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var sportsPickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "⛹🏻 Sports", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var vintagePickerButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.heightAnchor.constraint(equalToConstant: self.view.frame.width / 12).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        bt.layer.cornerRadius = self.view.frame.width / 25
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .systemBackground
        let title = NSAttributedString(string: "🧳 Vintage", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var tagsPickerDone: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: "Done", attributes: [.font : UIFont.systemFont(ofSize: 16, weight: .bold)])
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
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
    
    lazy var colorPickerBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var colorPickerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = self.colorPickerView.selectedColor
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.secondaryLabel.cgColor
        button.addTarget(self, action: #selector(showColorPicker), for: .touchUpInside)
        button.layer.cornerRadius = (self.view.frame.height / 20) / 4.16
        return button
    }()
    
    
    // MARK: -- Finish
    
    lazy var finishButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: "i'm ready", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .accent
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    // MARK: -- objC functions
    
    @objc
    func showColorPicker() {
        present(colorPickerView, animated: true)
    }
    
    @objc
    func cancelTapped() {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popViewController(animated: true)
    }
    
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
    func soon() {
        let infoAlert = UIAlertController(title: "🤫", message: "Pshhht! You've found a feature that is still work in progress...", preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(infoAlert, animated: true)
    }
    
    @objc
    func uploadClothing() {
        guard let clothingURL = imageURL else {
            let infoAlert = UIAlertController(title: "", message: "You still need to take a picture of your clothing piece", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
            return
        }
        
        guard nameTextField.text ?? "" != "" else {
            let infoAlert = UIAlertController(title: "", message: "You still need to give your clothing piece a name", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
            return
        }
        
        guard typeSelection.text != "placeholder" else {
            let infoAlert = UIAlertController(title: "", message: "You still need to select your clothing piece type", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
            return
        }
        
        guard seasonsSelection.text != "none" else {
            let infoAlert = UIAlertController(title: "", message: "You still need to select the seasons this clothing piece is for", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
            return
        }
        
        guard tagsSelection.text != "none" else {
            let infoAlert = UIAlertController(title: "", message: "You still need to select tags for your clothing piece", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
            return
        }
        
        Task { [self] in
            do {
                let clothingPiece = try await APIHandler.shared.clothingHandler.uploadClothing(with: nameTextField.text!, description: descriptionTextView.textColor == .label ? descriptionTextView.text : "", type: typeSelection.text!, seasons: selectedSeasonsArray, tags:  selectedTagsArray, imageURL: String(clothingURL.absoluteString.split(separator: "/").last?.split(separator: ".").first ?? ""), color: colorPickerView.selectedColor)
                
                var clothesArray = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
                clothesArray.append(clothingPiece)
                
                let alert = UIAlertController(title: nil, message: "Clothing piece uploaded successfully.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.cancelTapped()
                }))
                
                return present(alert, animated: true)
            }
            catch APIError.unprocessableContent {
                let alert = UIAlertController(title: "", message: "The image background couldn't be removed, please upload a clearer image and try again.\nUse a bright enviroment and ensure a high contrast for the best results.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            } catch APIError.tooManyRequests {
                let alert = UIAlertController(title: "", message: "You're being rate limited... wait a minute and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            }
        }
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
                let topConstraint = self.uploadImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
                topConstraint!.constant = -heightDifferenceOfPickerButton
                self.uploadImageView.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            self.typePicker.alpha = 1
            self.typePickerDone.alpha = 1
        }
    }
    
    @objc func hidePickerView() {
        UIView.animate(withDuration: 0.3) {
            let topConstraint = self.uploadImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
            topConstraint!.constant = 15
            self.uploadImageView.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.typePicker.alpha = 0
            self.typePickerDone.alpha = 0
        } completion: { _ in
            self.typePicker.isHidden = true
            self.typePickerDone.isHidden = true
        }
    }
    
    @objc func showSeasonsPickerView() {
        guard seasonsPickerView.isHidden else { return }
        seasonsPickerView.isHidden = false
        descriptionTextView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            self.seasonsPickerView.alpha = 1
        }
    }
    
    @objc func hideSeasonsPickerView() {
        guard !seasonsPickerView.isHidden else { return }
        descriptionTextView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.3) {
            self.seasonsPickerView.alpha = 0
        } completion: { _ in
            self.seasonsPickerView.isHidden = true
        }
    }
    
    @objc func springButton() {
        if !springPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            springPickerButton.layer.addSublayer(overlay)
            
            springPickerButton.isSelected = true
            
            selectedSeasonsArray.append("Spring")
        }
        else {
            springPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            springPickerButton.isSelected = false
            selectedSeasonsArray.remove(at: selectedSeasonsArray.firstIndex(of: "Spring")!)
        }
    }
    
    @objc func summerButton() {
        if !summerPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            summerPickerButton.layer.addSublayer(overlay)
            
            summerPickerButton.isSelected = true
            
            selectedSeasonsArray.append("Summer")
        }
        else {
            summerPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            summerPickerButton.isSelected = false
            selectedSeasonsArray.remove(at: selectedSeasonsArray.firstIndex(of: "Summer")!)
        }
    }
    
    @objc func autumnButton() {
        if !autumnPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            autumnPickerButton.layer.addSublayer(overlay)
            
            autumnPickerButton.isSelected = true
            
            selectedSeasonsArray.append("Autumn")
        }
        else {
            autumnPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            autumnPickerButton.isSelected = false
            selectedSeasonsArray.remove(at: selectedSeasonsArray.firstIndex(of: "Autumn")!)
        }
    }
    
    @objc func winterButton() {
        if !winterPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            winterPickerButton.layer.addSublayer(overlay)
            
            winterPickerButton.isSelected = true
            
            selectedSeasonsArray.append("Winter")
        }
        else {
            winterPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            winterPickerButton.isSelected = false
            selectedSeasonsArray.remove(at: selectedSeasonsArray.firstIndex(of: "Winter")!)
        }
    }
    
    @objc func showTagsPickerView() {
        guard tagsPickerView.isHidden else { return }
        tagsPickerView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.tagsPickerView.alpha = 1
        }
    }
    
    @objc func hideTagsPickerView() {
        guard !tagsPickerView.isHidden else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.tagsPickerView.alpha = 0
        } completion: { _ in
            self.tagsPickerView.isHidden = true
        }
    }
    
    @objc func casualButton() {
        if !casualPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            casualPickerButton.layer.addSublayer(overlay)
            
            casualPickerButton.isSelected = true
            
            selectedTagsArray.append("Casual")
        }
        else {
            casualPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            casualPickerButton.isSelected = false
            selectedTagsArray.remove(at: selectedTagsArray.firstIndex(of: "Casual")!)
        }
    }
    
    @objc func formalButton() {
        if !formalPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            formalPickerButton.layer.addSublayer(overlay)
            
            formalPickerButton.isSelected = true
            
            selectedTagsArray.append("Formal")
        }
        else {
            formalPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            formalPickerButton.isSelected = false
            selectedTagsArray.remove(at: selectedTagsArray.firstIndex(of: "Formal")!)
        }
    }
    
    @objc func sportsButton() {
        if !sportsPickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            sportsPickerButton.layer.addSublayer(overlay)
            
            sportsPickerButton.isSelected = true
            
            selectedTagsArray.append("Sports")
        }
        else {
            sportsPickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            sportsPickerButton.isSelected = false
            selectedTagsArray.remove(at: selectedTagsArray.firstIndex(of: "Sports")!)
        }
    }
    
    @objc func vintageButton() {
        if !vintagePickerButton.isSelected {
            let overlay = CALayer()
            overlay.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 4.5, height: self.view.frame.width / 12)
            overlay.backgroundColor = UIColor(white: 0.5, alpha: 0.5).cgColor
            overlay.name = "selectedOverlay"
            overlay.cornerRadius = self.view.frame.width / 25
            vintagePickerButton.layer.addSublayer(overlay)
            
            vintagePickerButton.isSelected = true
            
            selectedTagsArray.append("Vintage")
        }
        else {
            vintagePickerButton.layer.sublayers?.removeAll { $0.name == "selectedOverlay" }
            vintagePickerButton.isSelected = false
            selectedTagsArray.remove(at: selectedTagsArray.firstIndex(of: "Vintage")!)
        }
    }

    // MARK: -- View configuration
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = "Add piece to collection"
        
        tabBarController?.tabBar.isHidden = true
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "wand.and.stars", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(soon))
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        colorPickerView.supportsAlpha = true
        colorPickerView.selectedColor = .label
        colorPickerView.delegate = self
        colorPickerView.title = "color picker"
        
        view.addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        uploadImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(uploadImage))
        uploadImageView.addGestureRecognizer(imageTap)
        
        view.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: uploadImageView.topAnchor, constant: 5).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 5).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(nameBackgroundView)
        nameBackgroundView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        nameBackgroundView.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 5).isActive = true
        nameBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        nameBackgroundView.addSubview(nameCountLabel)
        nameCountLabel.bottomAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: -5).isActive = true
        nameCountLabel.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -10).isActive = true
        
        nameBackgroundView.addSubview(nameTextField)
        nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        nameTextField.leftAnchor.constraint(equalTo: nameBackgroundView.leftAnchor, constant: 5).isActive = true
        nameTextField.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(typeBackgroundView)
        typeBackgroundView.bottomAnchor.constraint(equalTo: uploadImageView.bottomAnchor, constant: -5).isActive = true
        typeBackgroundView.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 5).isActive = true
        typeBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(typeLabel)
        typeLabel.bottomAnchor.constraint(equalTo: typeBackgroundView.topAnchor, constant: -5).isActive = true
        typeLabel.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 5).isActive = true
        typeLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        typeBackgroundView.addSubview(typeIndidicatorImage)
        typeIndidicatorImage.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: -15).isActive = true
        typeIndidicatorImage.centerYAnchor.constraint(equalTo: typeBackgroundView.centerYAnchor).isActive = true
        
        typeBackgroundView.addSubview(typeButton)
        typeButton.topAnchor.constraint(equalTo: typeBackgroundView.topAnchor).isActive = true
        typeButton.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor).isActive = true
        typeButton.bottomAnchor.constraint(equalTo: typeBackgroundView.bottomAnchor).isActive = true
        typeButton.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor).isActive = true
        typeButton.addTarget(self, action: #selector(showPickerView), for: .touchUpInside)
        
        typeBackgroundView.addSubview(typeSelection)
        typeSelection.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor, constant: 5).isActive = true
        typeSelection.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: -5).isActive = true
        typeSelection.centerYAnchor.constraint(equalTo: typeBackgroundView.centerYAnchor).isActive = true
        
        view.addSubview(seasonsLabel)
        seasonsLabel.topAnchor.constraint(equalTo: uploadImageView.bottomAnchor, constant: 15).isActive = true
        seasonsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(seasonsBackgroundView)
        seasonsBackgroundView.topAnchor.constraint(equalTo: seasonsLabel.bottomAnchor, constant: 5).isActive = true
        seasonsBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        seasonsBackgroundView.addSubview(seasonsIndidicatorImage)
        seasonsIndidicatorImage.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor, constant: -15).isActive = true
        seasonsIndidicatorImage.centerYAnchor.constraint(equalTo: seasonsBackgroundView.centerYAnchor).isActive = true
        
        seasonsBackgroundView.addSubview(seasonsButton)
        seasonsButton.topAnchor.constraint(equalTo: seasonsBackgroundView.topAnchor).isActive = true
        seasonsButton.leftAnchor.constraint(equalTo: seasonsBackgroundView.leftAnchor).isActive = true
        seasonsButton.bottomAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor).isActive = true
        seasonsButton.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor).isActive = true
        seasonsButton.addTarget(self, action: #selector(showSeasonsPickerView), for: .touchUpInside)
        
        seasonsBackgroundView.addSubview(seasonsSelection)
        seasonsSelection.leftAnchor.constraint(equalTo: seasonsBackgroundView.leftAnchor, constant: 5).isActive = true
        seasonsSelection.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor, constant: -5).isActive = true
        seasonsSelection.centerYAnchor.constraint(equalTo: seasonsBackgroundView.centerYAnchor).isActive = true
        
        view.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor, constant: 15).isActive = true
        descriptionLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        descriptionLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(descriptionBackgroundView)
        descriptionBackgroundView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 5).isActive = true
        descriptionBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        descriptionBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        descriptionBackgroundView.addSubview(descriptionCountLabel)
        descriptionCountLabel.bottomAnchor.constraint(equalTo: descriptionBackgroundView.bottomAnchor, constant: -5).isActive = true
        descriptionCountLabel.rightAnchor.constraint(equalTo: descriptionBackgroundView.rightAnchor, constant: -10).isActive = true
        
        descriptionBackgroundView.addSubview(descriptionTextView)
        descriptionTextView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 5).isActive = true
        descriptionTextView.leftAnchor.constraint(equalTo: descriptionBackgroundView.leftAnchor, constant: 5).isActive = true
        descriptionTextView.rightAnchor.constraint(equalTo: descriptionBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(tagsLabel)
        tagsLabel.topAnchor.constraint(equalTo: descriptionBackgroundView.bottomAnchor, constant: 15).isActive = true
        tagsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        tagsLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(tagsBackgroundView)
        tagsBackgroundView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 5).isActive = true
        tagsBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        
        tagsBackgroundView.addSubview(tagsIndidicatorImage)
        tagsIndidicatorImage.rightAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor, constant: -15).isActive = true
        tagsIndidicatorImage.centerYAnchor.constraint(equalTo: tagsBackgroundView.centerYAnchor).isActive = true
        
        tagsBackgroundView.addSubview(tagsButton)
        tagsButton.topAnchor.constraint(equalTo: tagsBackgroundView.topAnchor).isActive = true
        tagsButton.leftAnchor.constraint(equalTo: tagsBackgroundView.leftAnchor).isActive = true
        tagsButton.bottomAnchor.constraint(equalTo: tagsBackgroundView.bottomAnchor).isActive = true
        tagsButton.rightAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor).isActive = true
        tagsButton.addTarget(self, action: #selector(showTagsPickerView), for: .touchUpInside)
        
        tagsBackgroundView.addSubview(tagsSelection)
        tagsSelection.leftAnchor.constraint(equalTo: tagsBackgroundView.leftAnchor, constant: 5).isActive = true
        tagsSelection.rightAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor, constant: -5).isActive = true
        tagsSelection.centerYAnchor.constraint(equalTo: tagsBackgroundView.centerYAnchor).isActive = true
        
        view.addSubview(colorPickerLabel)
        colorPickerLabel.topAnchor.constraint(equalTo: descriptionBackgroundView.bottomAnchor, constant: 15).isActive = true
        colorPickerLabel.leftAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor, constant: 5).isActive = true
        colorPickerLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(colorPickerBackgroundView)
        colorPickerBackgroundView.topAnchor.constraint(equalTo: colorPickerLabel.bottomAnchor, constant: 5).isActive = true
        colorPickerBackgroundView.leftAnchor.constraint(equalTo: tagsBackgroundView.rightAnchor, constant: 5).isActive = true
        colorPickerBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        colorPickerBackgroundView.addSubview(colorPickerButton)
        colorPickerButton.topAnchor.constraint(equalTo: colorPickerBackgroundView.topAnchor, constant: 5).isActive = true
        colorPickerButton.leftAnchor.constraint(equalTo: colorPickerBackgroundView.leftAnchor, constant: 5).isActive = true
        colorPickerButton.rightAnchor.constraint(equalTo: colorPickerBackgroundView.rightAnchor, constant: -5).isActive = true
        colorPickerButton.bottomAnchor.constraint(equalTo: colorPickerBackgroundView.bottomAnchor, constant: -5).isActive = true
        
        view.addSubview(finishButton)
        finishButton.topAnchor.constraint(equalTo: tagsBackgroundView.bottomAnchor, constant: 20).isActive = true
        finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        finishButton.addTarget(self, action: #selector(uploadClothing), for: .touchUpInside)
        
        setupExtraViews()
    }
    
    // MARK: -- Extra Views
    
    func setupExtraViews() {
        view.addSubview(typePicker)
        typePicker.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        typePicker.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        typePicker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.selectRow(0, inComponent: 0, animated: false)
        
        view.addSubview(typePickerDone)
        typePickerDone.topAnchor.constraint(equalTo: typePicker.topAnchor, constant: 10).isActive = true
        typePickerDone.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        typePickerDone.addTarget(self, action: #selector(hidePickerView), for: .touchUpInside)
        
        
        // MARK: --
        
        view.addSubview(seasonsPickerView)
        seasonsPickerView.topAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor, constant: 15).isActive = true
        seasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        seasonsPickerView.addSubview(springPickerButton)
        springPickerButton.leftAnchor.constraint(equalTo: seasonsPickerView.leftAnchor, constant: 10).isActive = true
        springPickerButton.centerYAnchor.constraint(equalTo: seasonsPickerView.centerYAnchor, constant: -20).isActive = true
        springPickerButton.addTarget(self, action: #selector(springButton), for: .touchUpInside)
        
        seasonsPickerView.addSubview(summerPickerButton)
        summerPickerButton.leftAnchor.constraint(equalTo: seasonsPickerView.leftAnchor, constant: 10).isActive = true
        summerPickerButton.centerYAnchor.constraint(equalTo: seasonsPickerView.centerYAnchor, constant: 20).isActive = true
        summerPickerButton.addTarget(self, action: #selector(summerButton), for: .touchUpInside)
        
        seasonsPickerView.addSubview(autumnPickerButton)
        autumnPickerButton.leftAnchor.constraint(equalTo: summerPickerButton.rightAnchor, constant: -10).isActive = true
        autumnPickerButton.centerYAnchor.constraint(equalTo: seasonsPickerView.centerYAnchor, constant: -20).isActive = true
        autumnPickerButton.addTarget(self, action: #selector(autumnButton), for: .touchUpInside)
        
        seasonsPickerView.addSubview(winterPickerButton)
        winterPickerButton.leftAnchor.constraint(equalTo: summerPickerButton.rightAnchor, constant: -10).isActive = true
        winterPickerButton.centerYAnchor.constraint(equalTo: seasonsPickerView.centerYAnchor, constant: 20).isActive = true
        winterPickerButton.addTarget(self, action: #selector(winterButton), for: .touchUpInside)
        
        seasonsPickerView.addSubview(seasonsPickerDone)
        seasonsPickerDone.rightAnchor.constraint(equalTo: seasonsPickerView.rightAnchor, constant: -25).isActive = true
        seasonsPickerDone.centerYAnchor.constraint(equalTo: seasonsPickerView.centerYAnchor).isActive = true
        seasonsPickerDone.addTarget(self, action: #selector(hideSeasonsPickerView), for: .touchUpInside)
        
        // MARK: --
        
        view.addSubview(tagsPickerView)
        tagsPickerView.topAnchor.constraint(equalTo: tagsBackgroundView.bottomAnchor, constant: 15).isActive = true
        tagsPickerView.centerXAnchor.constraint(equalTo: tagsBackgroundView.centerXAnchor).isActive = true
        
        tagsPickerView.addSubview(casualPickerButton)
        casualPickerButton.leftAnchor.constraint(equalTo: tagsPickerView.leftAnchor, constant: 10).isActive = true
        casualPickerButton.centerYAnchor.constraint(equalTo: tagsPickerView.centerYAnchor, constant: -20).isActive = true
        casualPickerButton.addTarget(self, action: #selector(casualButton), for: .touchUpInside)
        
        tagsPickerView.addSubview(formalPickerButton)
        formalPickerButton.leftAnchor.constraint(equalTo: tagsPickerView.leftAnchor, constant: 10).isActive = true
        formalPickerButton.centerYAnchor.constraint(equalTo: tagsPickerView.centerYAnchor, constant: 20).isActive = true
        formalPickerButton.addTarget(self, action: #selector(formalButton), for: .touchUpInside)
        
        tagsPickerView.addSubview(sportsPickerButton)
        sportsPickerButton.leftAnchor.constraint(equalTo: casualPickerButton.rightAnchor, constant: -10).isActive = true
        sportsPickerButton.centerYAnchor.constraint(equalTo: tagsPickerView.centerYAnchor, constant: -20).isActive = true
        sportsPickerButton.addTarget(self, action: #selector(sportsButton), for: .touchUpInside)
        
        tagsPickerView.addSubview(vintagePickerButton)
        vintagePickerButton.leftAnchor.constraint(equalTo: casualPickerButton.rightAnchor, constant: -10).isActive = true
        vintagePickerButton.centerYAnchor.constraint(equalTo: tagsPickerView.centerYAnchor, constant: 20).isActive = true
        vintagePickerButton.addTarget(self, action: #selector(vintageButton), for: .touchUpInside)
        
        tagsPickerView.addSubview(tagsPickerDone)
        tagsPickerDone.rightAnchor.constraint(equalTo: tagsPickerView.rightAnchor, constant: -25).isActive = true
        tagsPickerDone.centerYAnchor.constraint(equalTo: tagsPickerView.centerYAnchor).isActive = true
        tagsPickerDone.addTarget(self, action: #selector(hideTagsPickerView), for: .touchUpInside)
    }
}

extension UploadController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard descriptionTextView.textColor == UIColor.placeholderText else { return true }
        
        descriptionTextView.text = ""
        descriptionTextView.textColor = UIColor.label
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard descriptionTextView.text.count == 0 else { return }
        
        descriptionTextView.text = "optional description e.g. \"white tshirt with butterfly print\""
        descriptionTextView.textColor = UIColor.placeholderText
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text != "\n" else {
            textView.resignFirstResponder()
            return false
        }
        
        guard text != "" else {
            descriptionCountLabel.text = "\((descriptionTextView.text?.count ?? 0) - 1)/155"
            return true
        }
        
        guard descriptionTextView.text?.count ?? 0 < 155 else { return false }
        
        descriptionCountLabel.text = "\((descriptionTextView.text?.count ?? 0) + 1)/155"
        return true
    }
}

extension UploadController: UIPickerViewDelegate, UIPickerViewDataSource {
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
        let previousIndex = clothingTypes.firstIndex(of: typeSelection.text ?? "") ?? 0
        
        if newText.contains("*") {
            pickerView.selectRow(row > previousIndex ? row - 1 : row + 1, inComponent: component, animated: true)
            newText = clothingTypes[row > previousIndex ? row - 1 : row + 1]
        }
        
        typeSelection.text = newText
        typeSelection.textColor = .label
    }
}

extension UploadController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            dismiss(animated: true)
            
            guard let image = info[.editedImage] as? UIImage else { return }
            let assetPath = info[.imageURL] as! NSURL
            self.fileExtension = (assetPath.absoluteString ?? "").components(separatedBy: ".").last ?? ""
            
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. [\(fileExtension)]", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                present(alert, animated: true)
                return
            }
            
            uploadImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            do {
                let clothingURL = try await APIHandler.shared.clothingHandler.removeClothingBackground(from: image, self.fileExtension)
                
                imageURL = clothingURL
                uploadImageView.sd_setImage(with: clothingURL)
                uploadImageView.hideSkeleton()
            } catch APIError.payloadTooLarge, APIError.unprocessableContent {
                let alert = UIAlertController(title: "", message: "The image background couldn't be removed, please upload a clearer image and try again.\nUse a bright enviroment and ensure a high contrast for the best results.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.imageURL = nil
                    self.uploadImageView.image = UIImage(named: "upload_placeholder")
                    self.uploadImageView.hideSkeleton()
                }))
                
                return present(alert, animated: true)
            } catch APIError.tooManyRequests {
                let alert = UIAlertController(title: "", message: "You're being rate limited... wait a minute and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            }
        }
    }
}

extension UploadController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case nameTextField:
            if string == "" {
                nameCountLabel.text = "\((nameTextField.text?.count ?? 0) - 1)/50"
                return true
            }
            
            guard nameTextField.text?.count ?? 0 < 50 else { return false }
            
            nameCountLabel.text = "\((nameTextField.text?.count ?? 0) + 1)/50"
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

extension UploadController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        colorPickerButton.backgroundColor = color
    }
}
