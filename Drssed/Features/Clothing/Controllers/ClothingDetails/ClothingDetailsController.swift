//
//  ClothingDetailsController.swift
//  Drssed
//
//  Created by David Riegel on 04.11.25.
//

import UIKit
import CropViewController
import PhotosUI

protocol ClothingDetailsDelegate: ModalPresentationDelegate {
    func didUpdateClothing()
    func didDeleteClothing()
}

final class ClothingDetailsController: UIViewController {
    
    weak var delegate: ClothingDetailsDelegate?
    
    init(_ item: Clothing, allowsEditing: Bool = false) {
        self.item = item
        self.savedItem = item
        self.allowsEditing = allowsEditing
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedSeasonsArray = item.seasons
        self.selectedTagsArray = item.tags
        self.selectedCategory = item.subCategory
        configureViewComponents()
        
        view.addGestureRecognizer(dismissKeyboardTapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.isModalInPresentation = true
        self.navigationController?.presentationController?.delegate = self
    }
    
    // MARK: - Global variables
    
    var item: Clothing {
        didSet {
            DispatchQueue.main.async {
                self.updateUIFromItem()
                let hasChanges = self.unsavedChanges()
                self.itemDoneButton.isEnabled = hasChanges
            }
        }
    }
    
    var savedItem: Clothing {
        didSet {
            let hasChanges = self.unsavedChanges()
            self.itemDoneButton.isEnabled = hasChanges
        }
    }
    let allowsEditing: Bool
    let colorPickerView = UIColorPickerViewController()
    
    var selectedCategory: ClothingSubCategories? {
        didSet {
            itemCategorySelection.text = selectedCategory?.localizedName ?? String(localized: "common.placeholder.select")
            itemCategorySelection.textColor = selectedCategory == nil ? .placeholderText : .label
        }
    }
    
    var selectedSeasonsArray: [Seasons] = [] {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains(.SPRING) { selected.append(String(localized: "common.season.spring"))}
            if selectedSeasonsArray.contains(.SUMMER) { selected.append(String(localized: "common.season.summer"))}
            if selectedSeasonsArray.contains(.AUTUMN) { selected.append(String(localized: "common.season.autumn"))}
            if selectedSeasonsArray.contains(.WINTER) { selected.append(String(localized: "common.season.winter"))}
            
            
            itemSeasonsSelection.text = selected.joined(separator: ", ")
            itemSeasonsSelection.textColor = .label
            
            if selected.isEmpty {
                itemSeasonsSelection.textColor = .placeholderText
                itemSeasonsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    var selectedTagsArray: [Tags] = [] {
        didSet {
            var selected = [String]()
            if selectedTagsArray.contains(.CASUAL) { selected.append(String(localized: "common.tag.casual"))}
            if selectedTagsArray.contains(.FORMAL) { selected.append(String(localized: "common.tag.formal"))}
            if selectedTagsArray.contains(.SPORTS) { selected.append(String(localized: "common.tag.sports"))}
            if selectedTagsArray.contains(.VINTAGE) { selected.append(String(localized: "common.tag.vintage"))}
            
            
            itemTagsSelection.text = selected.joined(separator: ", ")
            itemTagsSelection.textColor = .label
            
            if selected.isEmpty {
                itemTagsSelection.textColor = .placeholderText
                itemTagsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    private var itemImageHeightConstraint: NSLayoutConstraint?
    
    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        return tap
    }()
    
    // MARK: - Functions
    
    func promptUnsavedChanges(dismissAfterSave dismiss: Bool = false) -> Void {
        let alert = UIAlertController(title: String(localized: "details.unsaved.title"), message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String(localized: "common.save"), style: .default, handler: { _ in
            Task {
                await self.saveItemChanges()
                
                DispatchQueue.main.async {
                    if !self.unsavedChanges() && dismiss {
                        alert.dismiss(animated: true)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.undo"), style: .destructive, handler: { _ in
            self.item = self.savedItem
        }))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel, handler: { _ in
            return
        }))
        
        present(alert, animated: true)
    }
    
    func dismissPickers() -> Void {
        self.itemSeasonsPickerView.hideSeasonsPickerView()
        self.itemTagsPickerView.hideTagsPickerView()
    }
    
    func disableEditing() -> Void {
        guard !unsavedChanges() else {
            promptUnsavedChanges()
            segmentController.selectedSegmentIndex = 1
            
            return
        }
        itemImageView.isUserInteractionEnabled = false
        
        itemNameField.fieldInput.isUserInteractionEnabled = false
        
        itemCategoryField.fieldInput.isUserInteractionEnabled = false
        itemCategoryField.indicatorImageView.isHidden = true
        
        itemColorButton.isUserInteractionEnabled = false
        
        itemSeasonsField.fieldInput.isUserInteractionEnabled = false
        itemSeasonsField.indicatorImageView.isHidden = true
        
        itemTagsField.fieldInput.isUserInteractionEnabled = false
        itemTagsField.indicatorImageView.isHidden = true

        itemWarmthPickerView.isUserInteractionEnabled = false

        itemImageHeightConstraint?.isActive = false
        itemImageHeightConstraint = itemImageView.heightAnchor.constraint(equalTo: itemImageView.widthAnchor, multiplier: 0.8)
        itemImageHeightConstraint?.isActive = true

        dismissPickers()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }
    
    func enableEditing() -> Void {
        itemImageView.isUserInteractionEnabled = true
        
        itemNameField.fieldInput.isUserInteractionEnabled = true
        
        itemCategoryField.fieldInput.isUserInteractionEnabled = true
        itemCategoryField.indicatorImageView.isHidden = false
        
        itemColorButton.isUserInteractionEnabled = true
        
        itemSeasonsField.fieldInput.isUserInteractionEnabled = true
        itemSeasonsField.indicatorImageView.isHidden = false
        
        itemTagsField.fieldInput.isUserInteractionEnabled = true
        itemTagsField.indicatorImageView.isHidden = false

        itemWarmthPickerView.isUserInteractionEnabled = true

        itemImageHeightConstraint?.isActive = false
        itemImageHeightConstraint = itemImageView.heightAnchor.constraint(equalTo: itemImageView.widthAnchor, multiplier: 0.3)
        itemImageHeightConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }
    
    func saveItemChanges() async -> Void {
        if await AppRepository.shared.clothingRepository.addOrUpdateClothing(from: item) {
            self.delegate?.didUpdateClothing()
            savedItem = item
        }
    }
    
    func deleteItem() async -> Void {
        let alert = UIAlertController(title: String(localized: "details.delete.title"), message: String(localized: "details.delete.question"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.delete"), style: .destructive, handler: { _ in
            Task {
                if await AppRepository.shared.clothingRepository.deleteClothing(with: self.item.id) {
                    self.delegate?.didDeleteClothing()
                    self.dismiss(animated: true)
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    func unsavedChanges() -> Bool {
        return savedItem != item
    }
    
    private func updateUIFromItem() {
        Task { @MainActor in
            self.itemNameField.fieldInput.text = self.item.name
            
            self.itemColorButton.backgroundColor = self.item.color
            self.colorPickerView.selectedColor = self.item.color
            
            self.selectedCategory = self.item.subCategory
            self.selectedSeasonsArray = self.item.seasons
            self.selectedTagsArray = self.item.tags
            self.itemWarmthPickerView.setWarmth(self.item.warmth)
        }
    }
    
    private func presentCropView(with image: UIImage) {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        cropViewController.cancelButtonColor = .systemRed
        cropViewController.doneButtonColor = .accent
        
        
        
        navigationController?.pushViewController(cropViewController, animated: true)
    }
    
    // MARK: - ObjC Functions
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    func showImageSourceOptions() {
        let actionSheet = UIAlertController(title: String(localized: "imagepicker.source.title"), message: String(localized: "imagepicker.source.message"), preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: String(localized: "imagepicker.source.camera"), style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: String(localized: "imagepicker.source.library"), style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        let camera = UIImagePickerController()
        camera.sourceType = .camera
        camera.allowsEditing = false
        camera.delegate = self
        present(camera, animated: true)
    }
    
    // MARK: - UI Elements
    
    /// Segment Controller UI
    
    lazy var segmentController: UISegmentedControl = {
        let sc = UISegmentedControl(items: [String(localized: "common.view"), String(localized: "common.edit")])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.tintColor = .secondarySystemBackground
        sc.selectedSegmentTintColor = .accent
        return sc
    }()
    
    /// Done UI
    
    lazy var itemDoneButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }

            Task {
                await self.saveItemChanges()
            }
        })
        let title = String(localized: "common.save")
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(title, for: .normal)
        bt.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        bt.setTitleColor(.accent, for: .normal)
        bt.setTitleColor(.lightGray, for: .disabled)
        bt.isEnabled = false
        return bt
    }()
    
    lazy var itemDeleteButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { [weak self] _ in
            guard let self else { return }

            Task {
                await self.deleteItem()
            }
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .headline), scale: .large)), for: .normal)
        bt.tintColor = .systemRed
        return bt
    }()
    
    /// Image UI
    
    lazy var itemImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(showImageSourceOptions))
        iv.addGestureRecognizer(imageTap)
        
        iv.sd_setImage(with: URL(string: item.imageID, relativeTo: APIClient.clothingImagesURL), placeholderImage: UIImage(named: "placeholder.upload"))
        return iv
    }()
    
    /// Name UI
    
    lazy var itemNameField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.name.title"), placeholder: String(localized: "common.placeholder.name"), text: item.name, charCounterWithCharacters: 50)
        view.fieldInput.delegate = self
        view.fieldInput.isUserInteractionEnabled = false
        return view
    }()
    
    /// Category UI
    
    lazy var itemCategoryField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.category.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.indicatorImageView.isHidden = true
        view.fieldInput.addAction(UIAction { [weak self] _ in
            self?.presentCategoryPicker()
        }, for: .primaryActionTriggered)
        return view
    }()

    lazy var itemCategorySelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = item.subCategory.localizedName
        return label
    }()
    
    /// Color UI
    
    lazy var itemColorPickerField = CustomInputBackground(fieldTitle: String(localized: "common.color.title"))
    
    lazy var itemColorButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = item.color
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.secondaryLabel.cgColor
        button.layer.cornerRadius = (self.view.frame.height / 20) / 4.16
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.present(self.colorPickerView, animated: true)
        }, for: .primaryActionTriggered)
        button.isUserInteractionEnabled = false
        return button
    }()
    
    /// Seasons UI
    
    lazy var itemSeasonsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.season.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.indicatorImageView.isHidden = true
        view.fieldInput.addAction(UIAction { [weak self] _ in self?.itemSeasonsPickerView.showSeasonsPickerView()}, for: .primaryActionTriggered)
        return view
    }()
    
    lazy var itemSeasonsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        return label
    }()
    
    lazy var itemSeasonsPickerView: SeasonsPickerView = {
        let view = SeasonsPickerView(delegate: self, item.seasons)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    /// Tags UI
    
    lazy var itemTagsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.tag.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.indicatorImageView.isHidden = true
        view.fieldInput.addAction(UIAction { [weak self] _ in self?.itemTagsPickerView.showTagsPickerView()}, for: .primaryActionTriggered)
        return view
    }()
    
    lazy var itemTagsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        return label
    }()
    
    lazy var itemTagsPickerView: TagsPickerView = {
        let view = TagsPickerView(delegate: self, item.tags)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    /// Warmth UI

    lazy var itemWarmthPickerView: WarmthPickerView = {
        let view = WarmthPickerView(delegate: self, preselected: item.warmth)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    /// Scroll container (keeps all fields reachable on smaller screens)

    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    lazy var contentView: UIView = {
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()

    // MARK: - UI Setup
    
    func configureViewComponents() -> Void {
        view.backgroundColor = .background

        itemImageHeightConstraint = itemImageView.heightAnchor.constraint(equalTo: itemImageView.widthAnchor, multiplier: 0.8)
        itemImageHeightConstraint?.isActive = true

        colorPickerView.supportsAlpha = false
        colorPickerView.selectedColor = item.color
        colorPickerView.delegate = self

        [segmentController, itemDoneButton, itemDeleteButton, scrollView].forEach {
            view.addSubview($0)
        }

        scrollView.addSubview(contentView)

        [itemImageView, itemNameField, itemCategoryField, itemCategorySelection, itemColorPickerField, itemColorButton, itemSeasonsField, itemSeasonsSelection, itemWarmthPickerView, itemTagsField, itemTagsSelection, itemSeasonsPickerView, itemTagsPickerView].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            segmentController.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            segmentController.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        segmentController.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.segmentController.selectedSegmentIndex == 0 ? self.disableEditing() : self.enableEditing()
        }, for: .valueChanged)

        NSLayoutConstraint.activate([
            itemDoneButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        NSLayoutConstraint.activate([
            itemDeleteButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDeleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentController.bottomAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            itemImageView.leadingAnchor.constraint(lessThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            itemImageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            itemImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        NSLayoutConstraint.activate([
            itemNameField.topAnchor.constraint(equalTo: itemImageView.bottomAnchor, constant: 20),
            itemNameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itemNameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])

        NSLayoutConstraint.activate([
            itemCategoryField.topAnchor.constraint(equalTo: itemNameField.bottomAnchor, constant: 10),
            itemCategoryField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itemCategoryField.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -5),
            itemCategoryField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            itemCategorySelection.topAnchor.constraint(equalTo: itemCategoryField.fieldBackground.topAnchor),
            itemCategorySelection.leadingAnchor.constraint(equalTo: itemCategoryField.leadingAnchor),
            itemCategorySelection.trailingAnchor.constraint(equalTo: itemCategoryField.trailingAnchor),
            itemCategorySelection.bottomAnchor.constraint(equalTo: itemCategoryField.fieldBackground.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            itemColorPickerField.topAnchor.constraint(equalTo: itemNameField.bottomAnchor, constant: 10),
            itemColorPickerField.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 5),
            itemColorPickerField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemColorPickerField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            itemColorButton.topAnchor.constraint(equalTo: itemColorPickerField.fieldBackground.topAnchor, constant: 5),
            itemColorButton.leadingAnchor.constraint(equalTo: itemColorPickerField.fieldBackground.leadingAnchor, constant: 5),
            itemColorButton.trailingAnchor.constraint(equalTo: itemColorPickerField.fieldBackground.trailingAnchor, constant: -5),
            itemColorButton.bottomAnchor.constraint(equalTo: itemColorPickerField.fieldBackground.bottomAnchor, constant: -5)
        ])

        NSLayoutConstraint.activate([
            itemSeasonsField.topAnchor.constraint(equalTo: itemCategoryField.bottomAnchor, constant: 10),
            itemSeasonsField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itemSeasonsField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemSeasonsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            itemSeasonsSelection.topAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.topAnchor),
            itemSeasonsSelection.leadingAnchor.constraint(equalTo: itemSeasonsField.leadingAnchor),
            itemSeasonsSelection.trailingAnchor.constraint(equalTo: itemSeasonsField.trailingAnchor),
            itemSeasonsSelection.bottomAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            itemTagsField.topAnchor.constraint(equalTo: itemSeasonsField.bottomAnchor, constant: 10),
            itemTagsField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itemTagsField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemTagsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            itemTagsSelection.topAnchor.constraint(equalTo: itemTagsField.fieldBackground.topAnchor),
            itemTagsSelection.leadingAnchor.constraint(equalTo: itemTagsField.leadingAnchor),
            itemTagsSelection.trailingAnchor.constraint(equalTo: itemTagsField.trailingAnchor),
            itemTagsSelection.bottomAnchor.constraint(equalTo: itemTagsField.fieldBackground.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            itemWarmthPickerView.topAnchor.constraint(equalTo: itemTagsField.bottomAnchor, constant: 10),
            itemWarmthPickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            itemWarmthPickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            itemWarmthPickerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        contentView.bringSubviewToFront(itemSeasonsPickerView)
        NSLayoutConstraint.activate([
            itemSeasonsPickerView.topAnchor.constraint(equalTo: itemSeasonsField.bottomAnchor, constant: 15),
            itemSeasonsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemSeasonsPickerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            itemSeasonsPickerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        contentView.bringSubviewToFront(itemTagsPickerView)
        NSLayoutConstraint.activate([
            itemTagsPickerView.topAnchor.constraint(equalTo: itemTagsField.bottomAnchor, constant: 15),
            itemTagsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemTagsPickerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            itemTagsPickerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
    }

    private func presentCategoryPicker() {
        view.endEditing(true)

        let picker = CategoryPickerSheetController(preselected: selectedCategory, delegate: self)
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        present(nav, animated: true)
    }
}

extension ClothingDetailsController: CategoryPickerSheetControllerDelegate {
    func categoryPicker(_ controller: CategoryPickerSheetController,
                        didSelect subCategory: ClothingSubCategories,
                        in category: ClothingCategories) {
        selectedCategory = subCategory
        item.category = category
        item.subCategory = subCategory
    }
}

extension ClothingDetailsController: SeasonsPickerViewDelegate, TagsPickerViewDelegate {
    func seasonSelected(_ season: Seasons) {
        if let idx = selectedSeasonsArray.firstIndex(of: season) {
            selectedSeasonsArray.remove(at: idx)
            item.seasons.remove(at: idx)
        } else {
            selectedSeasonsArray.append(season)
            item.seasons.append(season)
        }
    }
    
    func tagSelected(_ tag: Tags) {
        if let idx = selectedTagsArray.firstIndex(of: tag) {
            selectedTagsArray.remove(at: idx)
            item.tags.remove(at: idx)
        } else {
            selectedTagsArray.append(tag)
            item.tags.append(tag)
        }
    }
    
    func tagsDoneButtonPressed() {
        itemTagsPickerView.hideTagsPickerView()
    }
    
    func seasonsDoneButtonPressed() {
        itemSeasonsPickerView.hideSeasonsPickerView()
    }
}

extension ClothingDetailsController: WarmthPickerViewDelegate {
    func warmthSelected(_ warmth: Warmth) {
        item.warmth = warmth
    }
}

extension ClothingDetailsController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRanges ranges: [NSValue], replacementString string: String) -> Bool {
        if textField == self.itemNameField.fieldInput {
            if string == "" { item.name = itemNameField.fieldInput.text!.dropLast().description; return true }
            
            guard itemNameField.fieldInput.text?.count ?? 0 < 50 else { return false }
            
            item.name = itemNameField.fieldInput.text! + string
        }
        
        return true
    }
}

extension ClothingDetailsController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        item.color = color
    }
}

extension ClothingDetailsController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if presentationController.presentedViewController !== self.navigationController { return true }
        return !self.unsavedChanges()
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard presentationController.presentedViewController === self.navigationController else { return }
        guard self.unsavedChanges() else {
            self.dismiss(animated: true)
            return
        }
        promptUnsavedChanges(dismissAfterSave: true)
    }
}

extension ClothingDetailsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        presentCropView(with: image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension ClothingDetailsController: PHPickerViewControllerDelegate, CropViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true)
            return
        }

        provider.loadObject(ofClass: UIImage.self) { object, _ in
            guard let image = object as? UIImage else {
                DispatchQueue.main.async { picker.dismiss(animated: true) }
                return
            }
            DispatchQueue.main.async {
                picker.dismiss(animated: true) {
                    self.presentCropView(with: image)
                }
            }
        }
    }
    
    func cropViewController(_ crop: CropViewController, didFinishCancelled cancelled: Bool) {
        navigationController?.popToRootViewController(animated: true)
    }

    func cropViewController(_ crop: CropViewController,
                            didCropToImage image: UIImage,
                            withRect cropRect: CGRect,
                            angle: Int) {
        //itemImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        
        navigationController?.popToRootViewController(animated: true)

        Task {
            do {
                let (imageID, clothingURL, clothingColor, _, _) = try await APIClient.shared.clothingHandler.removeClothingBackground(from: image)
                
                item.imageID = imageID
                item.color = clothingColor
                
                DispatchQueue.main.async {
                    self.itemImageView.sd_setImage(with: clothingURL)
                }
                
            } catch APIError.payloadTooLarge {
                ErrorHandler.handle(APIError.payloadTooLarge(message: String(localized: "imagepicker.backgroundRemoval.error"), suggestion: String(localized: "imagepicker.error.tooLarge.suggestion")))
            } catch APIError.unprocessableContent {
                
                
                ErrorHandler.handle(APIError.unprocessableContent(message: String(localized: "imagepicker.backgroundRemoval.error"), suggestion: String(localized: "imagepicker.uploadimage.hint")))
            } catch {
                ErrorHandler.handle(error)
            }
            
            //uploadImageView.hideSkeleton()
        }
    }
}
