//
//  UploadController.swift
//  Clothing Booth
//
//  Created by David Riegel on 12.09.24.
//

import UIKit
import SkeletonView
import TOCropViewController

protocol UploadControllerDelegate: AnyObject {
    func didUploadClothing(_ clothing: Clothing)
}

class UploadController: UIViewController {
    weak var delegate: UploadControllerDelegate?
    private let clothingRepo: ClothingRepository = ClothingRepository()
        
    let clothingCategoriesDataSource: [String] = {
        var ar: [String] = ["*"]
        for clothingCategory in ClothingCategories.allCases {
            ar.append(clothingCategory.localizedName)
            ar.append("*")
        }
        
        return ar
    }()
    
    var fileExtension: String = ""
    
    var selectedCategory: ClothingCategories?
    var selectedSeasonsArray: [Seasons] = [] {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains(.SPRING) { selected.append(String(localized: "common.season.spring"))}
            if selectedSeasonsArray.contains(.SUMMER) { selected.append(String(localized: "common.season.summer"))}
            if selectedSeasonsArray.contains(.AUTUMN) { selected.append(String(localized: "common.season.autumn"))}
            if selectedSeasonsArray.contains(.WINTER) { selected.append(String(localized: "common.season.winter"))}
            
            
            clothingSeasonsSelection.text = selected.joined(separator: ", ")
            clothingSeasonsSelection.textColor = .label
            
            if selected.isEmpty {
                clothingSeasonsSelection.textColor = .placeholderText
                clothingSeasonsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    var imageID: String = ""
    
    var selectedTagsArray: [Tags] = [] {
        didSet {
            var selected = [String]()
            if selectedTagsArray.contains(.CASUAL) { selected.append(String(localized: "common.tag.casual"))}
            if selectedTagsArray.contains(.FORMAL) { selected.append(String(localized: "common.tag.formal"))}
            if selectedTagsArray.contains(.SPORTS) { selected.append(String(localized: "common.tag.sports"))}
            if selectedTagsArray.contains(.VINTAGE) { selected.append(String(localized: "common.tag.vintage"))}
            
            
            clothingTagsSelection.text = selected.joined(separator: ", ")
            clothingTagsSelection.textColor = .label
            
            if selected.isEmpty {
                clothingTagsSelection.textColor = .placeholderText
                clothingTagsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    let colorPickerView = UIColorPickerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    override func viewDidLayoutSubviews() {
        descriptionBackgroundView.layer.cornerRadius = CornerStyle.medium.radius(for: descriptionBackgroundView)
        clothingColorPickerButton.layer.cornerRadius = CornerStyle.medium.radius(for: clothingColorPickerButton)
        
        finishButton.layer.cornerRadius = CornerStyle.medium.radius(for: finishButton)
    }
    
    // MARK: -- Image
    
    lazy var uploadImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isSkeletonable = true
        iv.skeletonCornerRadius = 12
        iv.image = UIImage(named: "placeholder.upload")
        iv.isUserInteractionEnabled = true
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        return picker
    }()
    
    // MARK: -- Name
    
    lazy var clothingNameField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.name.title"), placeholder: String(localized: "common.placeholder.name"), charCounterWithCharacters: 50)
        view.fieldInput.delegate = self
        return view
    }()
    
    // MARK: -- Type
    
    lazy var clothingCategoryField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.category.title"))
        view.fieldInput.isUserInteractionEnabled = true
        view.fieldInput.addTarget(self, action: #selector(showCategoryPicker), for: .touchUpInside)
        return view
    }()
    
    lazy var clothingCategorySelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = String(localized: "common.placeholder.select")
        return label
    }()
    
    lazy var categoryPicker: UIPickerView = {
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
    
    lazy var categoryPickerDone: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: String(localized: "common.done"), attributes: [.font : UIFont.systemFont(ofSize: 18, weight: .bold)])
        button.isHidden = true
        button.alpha = 0
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
  
    // MARK: -- Seasons
    
    lazy var clothingSeasonsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.season.title"))
        view.fieldInput.isUserInteractionEnabled = true
        view.fieldInput.addTarget(self, action: #selector(showSeasonsPickerView), for: .touchUpInside)
        return view
    }()
    
    lazy var clothingSeasonsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = String(localized: "common.none")
        return label
    }()
    
    lazy var seasonsPickerView: SeasonsPickerView = {
        let view = SeasonsPickerView(delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    // MARK: -- Description
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = String(localized: "clothingupload.description.title")
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
        return view
    }()
    
    lazy var descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.backgroundColor = .clear
        tv.text = String(localized: "clothingupload.description.placeholder")
        tv.textColor = .placeholderText
        tv.textAlignment = .left
        tv.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4.5).isActive = true
        tv.font = .systemFont(ofSize: 13, weight: .heavy)
        tv.returnKeyType = .done
        return tv
    }()
    
    // MARK: -- Tags
    
    lazy var clothingTagsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.tag.title"))
        view.fieldInput.isUserInteractionEnabled = true
        view.fieldInput.addTarget(self, action: #selector(showTagsPickerView), for: .touchUpInside)
        return view
    }()
    
    lazy var clothingTagsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = String(localized: "common.none")
        return label
    }()
    
    lazy var tagsPickerView: TagsPickerView = {
        let view = TagsPickerView(delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    // MARK: -- Color
    
    lazy var clothingColorBackground: CustomInputBackground = {
        let view = CustomInputBackground(fieldTitle: String(localized: "common.color.title"))
        return view
    }()
    
    lazy var clothingColorPickerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = self.colorPickerView.selectedColor
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemGray6.cgColor
        button.addTarget(self, action: #selector(showColorPicker), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: -- Finish
    
    lazy var finishButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: String(localized: "clothingupload.button.finish"), attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .accent
        button.addTarget(self, action: #selector(uploadClothing), for: .touchUpInside)
        return button
    }()
    
    // MARK: -- helper functions
    
    func presentCropView(with image: UIImage) {
        let cropViewController = TOCropViewController(image: image)
        cropViewController.delegate = self
        cropViewController.cancelButtonColor = .systemRed
        cropViewController.doneButtonColor = .accent
        //cropViewController.showCancelConfirmationDialog = true
        present(cropViewController, animated: true, completion: nil)
    }
    
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
        let selectionAlert = UIAlertController(title: String(localized: "imagepicker.uploadimage.title"), message: String(localized: "imagepicker.uploadimage.hint"), preferredStyle: .alert)
        selectionAlert.addAction(UIAlertAction(title: String(localized: "imagepicker.selectimage"), style: .default, handler: { _ in
            self.present(self.imagePickerController, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: String(localized: "imagepicker.takeimage"), style: .default, handler: { _ in
            let infoAlert = UIAlertController(title: "Soon", message: "This is currently not possible but very soon will be.", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
            self.present(infoAlert, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        self.present(selectionAlert, animated: true)
    }
    
    @objc
    func soon() {
        let infoAlert = UIAlertController(title: "🤫", message: String(localized: "workinprogress.message"), preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
        self.present(infoAlert, animated: true)
    }
    
    @objc
    func uploadClothing() {
        let errorAlert = UIAlertController(title: String(localized: "common.error.title"), message: nil, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
        
        
        if imageID.isEmpty {
            errorAlert.message = String(localized: "clothingupload.error.missing.image")
        }
        
        var name = ""
        
        if let clothingName = clothingNameField.fieldInput.text, clothingName != "" {
            name = clothingName
        } else {
            return ErrorHandler.handle(CustomError.missingValue(field: String(localized: "common.name.title")))
        }
        
        var category: ClothingCategories!
        
        if let selectedCategory = selectedCategory {
            category = selectedCategory
        } else {
            errorAlert.message = String(localized: "clothingupload.error.missing.category")
        }
        
        if selectedSeasonsArray.isEmpty {
            errorAlert.message = String(localized: "clothingupload.error.missing.seasons")
        }
        
        if selectedTagsArray.isEmpty {
            errorAlert.message = String(localized: "clothingupload.error.missing.tags")
        }
        
        guard errorAlert.message == nil else {
            self.present(errorAlert, animated: true)
            return
        }
        
        let domainModel = Clothing(name: name, imageID: imageID, category: category, itemDescription: descriptionTextView.text ?? "", color: colorPickerView.selectedColor, seasons: selectedSeasonsArray, tags: selectedTagsArray)
        
        Task {
            await clothingRepo.addOrUpdateClothing(from: domainModel)
            delegate?.didUploadClothing(domainModel)
        }
                
        let alert = UIAlertController(title: nil, message: String(localized: "clothingupload.alert.success"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default, handler: { _ in
            self.cancelTapped()
        }))
                
        return present(alert, animated: true)
    }
    
    @objc
    func showCategoryPicker(_ sender: UIButton) {
        guard categoryPicker.isHidden == true else {
            return
        }
        
        categoryPicker.isHidden = false
        categoryPickerDone.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.categoryPicker.alpha = 1
            self.categoryPickerDone.alpha = 1
        }
    }
    
    @objc func hidePickerView() {
        UIView.animate(withDuration: 0.3) {
            let topConstraint = self.uploadImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
            topConstraint!.constant = 15
            self.uploadImageView.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.categoryPicker.alpha = 0
            self.categoryPickerDone.alpha = 0
        } completion: { _ in
            self.categoryPicker.isHidden = true
            self.categoryPickerDone.isHidden = true
        }
    }
    
    @objc func showSeasonsPickerView() {
        seasonsPickerView.showSeasonsPickerView()
        showInteractionBlocker()
        view.bringSubviewToFront(seasonsPickerView)
    }
    
    @objc func hideSeasonsPickerView() {
        seasonsPickerView.hideSeasonsPickerView()
        hideInteractionBlocker()
    }
    
    @objc func showTagsPickerView() {
        tagsPickerView.showTagsPickerView()
        showInteractionBlocker()
        view.bringSubviewToFront(tagsPickerView)
    }
    
    @objc func hideTagsPickerView() {
        tagsPickerView.hideTagsPickerView()
        hideInteractionBlocker()
    }

    // MARK: -- View configuration
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "clothingupload.title")
        
        tabBarController?.tabBar.isHidden = true
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "wand.and.stars", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(soon))
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        colorPickerView.supportsAlpha = false
        colorPickerView.selectedColor = .label
        colorPickerView.delegate = self
        colorPickerView.title = "color picker"
        
        view.addSubview(uploadImageView)
        NSLayoutConstraint.activate([
            uploadImageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            uploadImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            uploadImageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.4),
            uploadImageView.heightAnchor.constraint(equalTo: uploadImageView.widthAnchor)
        ])
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(uploadImage))
        uploadImageView.addGestureRecognizer(imageTap)
        
        view.addSubview(clothingNameField)
        NSLayoutConstraint.activate([
            clothingNameField.topAnchor.constraint(equalTo: uploadImageView.topAnchor, constant: 5),
            clothingNameField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 5),
            clothingNameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
        
        view.addSubview(clothingCategoryField)
        clothingCategoryField.addSubview(clothingCategorySelection)
        NSLayoutConstraint.activate([
            clothingCategoryField.bottomAnchor.constraint(equalTo: uploadImageView.bottomAnchor, constant: -5),
            clothingCategoryField.leadingAnchor.constraint(equalTo: uploadImageView.trailingAnchor, constant: 5),
            clothingCategoryField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingCategoryField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            clothingCategorySelection.topAnchor.constraint(equalTo: clothingCategoryField.fieldBackground.topAnchor),
            clothingCategorySelection.leadingAnchor.constraint(equalTo: clothingCategoryField.leadingAnchor),
            clothingCategorySelection.trailingAnchor.constraint(equalTo: clothingCategoryField.trailingAnchor),
            clothingCategorySelection.bottomAnchor.constraint(equalTo: clothingCategoryField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(clothingSeasonsField)
        clothingSeasonsField.addSubview(clothingSeasonsSelection)
        NSLayoutConstraint.activate([
            clothingSeasonsField.topAnchor.constraint(equalTo: uploadImageView.bottomAnchor, constant: 10),
            clothingSeasonsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingSeasonsField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            clothingSeasonsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            clothingSeasonsSelection.topAnchor.constraint(equalTo: clothingSeasonsField.fieldBackground.topAnchor),
            clothingSeasonsSelection.leadingAnchor.constraint(equalTo: clothingSeasonsField.leadingAnchor),
            clothingSeasonsSelection.trailingAnchor.constraint(equalTo: clothingSeasonsField.trailingAnchor),
            clothingSeasonsSelection.bottomAnchor.constraint(equalTo: clothingSeasonsField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: clothingSeasonsField.bottomAnchor, constant: 15).isActive = true
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
        
        view.addSubview(clothingTagsField)
        clothingTagsField.addSubview(clothingTagsSelection)
        NSLayoutConstraint.activate([
            clothingTagsField.topAnchor.constraint(equalTo: descriptionBackgroundView.bottomAnchor, constant: 10),
            clothingTagsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clothingTagsField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.6),
            clothingTagsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            clothingTagsSelection.topAnchor.constraint(equalTo: clothingTagsField.fieldBackground.topAnchor),
            clothingTagsSelection.leadingAnchor.constraint(equalTo: clothingTagsField.leadingAnchor, constant: 5),
            clothingTagsSelection.trailingAnchor.constraint(equalTo: clothingTagsField.indicatorImageView.leadingAnchor, constant: -5),
            clothingTagsSelection.bottomAnchor.constraint(equalTo: clothingTagsField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(clothingColorBackground)
        clothingColorBackground.addSubview(clothingColorPickerButton)
        NSLayoutConstraint.activate([
            clothingColorBackground.topAnchor.constraint(equalTo: descriptionBackgroundView.bottomAnchor, constant: 10),
            clothingColorBackground.leftAnchor.constraint(equalTo: clothingTagsField.rightAnchor, constant: 5),
            clothingColorBackground.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            
            clothingColorPickerButton.topAnchor.constraint(equalTo: clothingColorBackground.fieldBackground.topAnchor, constant: 5),
            clothingColorPickerButton.leftAnchor.constraint(equalTo: clothingColorBackground.fieldBackground.leftAnchor, constant: 5),
            clothingColorPickerButton.rightAnchor.constraint(equalTo: clothingColorBackground.fieldBackground.rightAnchor, constant: -5),
            clothingColorPickerButton.bottomAnchor.constraint(equalTo: clothingColorBackground.fieldBackground.bottomAnchor, constant: -5)
        ])
        
        view.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.topAnchor.constraint(equalTo: clothingTagsField.bottomAnchor, constant: 20),
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.heightAnchor.constraint(equalToConstant: 45),
            finishButton.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2)
        ])
        
        
        view.addSubview(seasonsPickerView)
        seasonsPickerView.topAnchor.constraint(equalTo: clothingSeasonsField.bottomAnchor, constant: 15).isActive = true
        seasonsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        seasonsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        seasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        view.addSubview(tagsPickerView)
        tagsPickerView.topAnchor.constraint(equalTo: clothingTagsField.bottomAnchor, constant: 15).isActive = true
        tagsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        tagsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        tagsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        setupExtraViews()
    }
    
    // MARK: -- Extra Views
    
    func setupExtraViews() {
        view.addSubview(categoryPicker)
        categoryPicker.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        categoryPicker.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        categoryPicker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.selectRow(0, inComponent: 0, animated: false)
        
        view.addSubview(categoryPickerDone)
        categoryPickerDone.topAnchor.constraint(equalTo: categoryPicker.topAnchor, constant: 10).isActive = true
        categoryPickerDone.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        categoryPickerDone.addTarget(self, action: #selector(hidePickerView), for: .touchUpInside)
        
        // MARK: --
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
        
        descriptionTextView.text = String(localized: "clothingupload.description.placeholder")
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
        return clothingCategoriesDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        guard clothingCategoriesDataSource[row].contains("*") else {
            let label = UILabel()
            label.textAlignment = .center
            label.text = clothingCategoriesDataSource[row]
            label.font = UIFont.systemFont(ofSize: 22)

            return label
        }
        
        let splitter = UIView()
        splitter.backgroundColor = .lightGray
        splitter.frame = CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 2)
        return splitter
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var newText = clothingCategoriesDataSource[row]
        let previousIndex = clothingCategoriesDataSource.firstIndex(of: clothingCategorySelection.text ?? "") ?? 0
        
        if newText.contains("*") {
            pickerView.selectRow(row > previousIndex ? row - 1 : row + 1, inComponent: component, animated: true)
            newText = clothingCategoriesDataSource[row > previousIndex ? row - 1 : row + 1]
        }
        
        clothingCategorySelection.text = newText
        selectedCategory = ClothingCategories.fromLocalized(newText)
        clothingCategorySelection.textColor = .label
    }
}

extension UploadController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            dismiss(animated: true)
            
            let image = info[.originalImage] as? UIImage ?? UIImage()
            
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
            
            presentCropView(with: image)
            
        }
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        Task {
            uploadImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            cropViewController.dismiss(animated: true)
            
            do {
                let (imageID, clothingURL, clothingColor, clothingCategory) = try await APIClient.shared.clothingHandler.removeClothingBackground(from: image)
                
                self.imageID = imageID
                colorPickerView.selectedColor = clothingColor
                clothingColorPickerButton.backgroundColor = clothingColor
                
                if let index = clothingCategoriesDataSource.firstIndex(of: clothingCategory.localizedName) {
                    categoryPicker.selectRow(index, inComponent: 0, animated: true)
                    categoryPicker.delegate?.pickerView?(categoryPicker, didSelectRow: index, inComponent: 0)
                }
                
                uploadImageView.sd_setImage(with: clothingURL)
                uploadImageView.hideSkeleton()
            } catch APIError.payloadTooLarge {
                self.imageID = ""
                self.uploadImageView.image = UIImage(named: "upload_placeholder")
                self.uploadImageView.hideSkeleton()
                
                ErrorHandler.handle(APIError.payloadTooLarge(message: String(localized: "imagepicker.backgroundRemoval.error"), suggestion: String(localized: "imagepicker.error.tooLarge.suggestion")))
            } catch APIError.unprocessableContent {
                self.imageID = ""
                self.uploadImageView.image = UIImage(named: "upload_placeholder")
                self.uploadImageView.hideSkeleton()
                
                
                ErrorHandler.handle(APIError.unprocessableContent(message: String(localized: "imagepicker.backgroundRemoval.error"), suggestion: String(localized: "imagepicker.uploadimage.hint")))
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
        
    func cropViewController(_ cropViewController: TOCropViewController,
                            didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension UploadController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case clothingNameField.fieldInput:
            if string == "" { return true }
            
            guard clothingNameField.fieldInput.text?.count ?? 0 < 50 else { return false }
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
        clothingColorPickerButton.backgroundColor = color
    }
}

extension UploadController: SeasonsPickerViewDelegate {
    func seasonSelected(_ season: Seasons) {
        if let idx = selectedSeasonsArray.firstIndex(of: season) {
            selectedSeasonsArray.remove(at: idx)
        } else {
            selectedSeasonsArray.append(season)
        }
    }
    
    func seasonsDoneButtonPressed() {
        self.hideSeasonsPickerView()
    }
}

extension UploadController: TagsPickerViewDelegate {
    func tagSelected(_ tag: Tags) {
        if let idx = selectedTagsArray.firstIndex(of: tag) {
            selectedTagsArray.remove(at: idx)
        } else {
            selectedTagsArray.append(tag)
        }
    }
    
    func tagsDoneButtonPressed() {
        hideTagsPickerView()
    }
}
