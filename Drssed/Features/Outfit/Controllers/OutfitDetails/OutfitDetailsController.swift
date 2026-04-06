//
//  OutfitDetailsController.swift
//  Drssed
//
//  Created by David Riegel on 19.03.26.
//

import UIKit
import CropViewController
import SDWebImage
import PhotosUI

protocol OutfitDetailsDelegate: ModalPresentationDelegate {
    func didUpdateOutfit()
    func didDeleteOutfit()
}

final class OutfitDetailsController: UIViewController {
    var savedItem: Outfit {
        didSet {
            let hasChanges = self.checkForUnsavedChanges()
            self.itemDoneButton.isEnabled = hasChanges
        }
    }
    var item: Outfit {
        didSet {
            let hasChanges = self.checkForUnsavedChanges()
            self.itemDoneButton.isEnabled = hasChanges
        }
    }
    
    var didUpdate: Bool = false
    
    let clothingRepo = ClothingRepository()
    
    weak var delegate: OutfitDetailsDelegate?
    
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
        self.navigationController?.presentationController?.delegate = self
    }
    
    // MARK: - Variables -
    
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
    
    // MARK: - UI Elements -
    
    // Segment Control
    
    lazy var segmentController: UISegmentedControl = {
        let sc = UISegmentedControl(items: [String(localized: "common.view"), String(localized: "common.edit")])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.tintColor = .secondarySystemBackground
        sc.selectedSegmentTintColor = .accent
        return sc
    }()
    
    // Done Button
    
    lazy var itemDoneButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction {_ in
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
    
    // Delete button
    
    lazy var itemDeleteButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction {_ in
            Task {
                await self.deleteItem()
            }
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .headline), scale: .large)), for: .normal)
        bt.tintColor = .systemRed
        return bt
    }()
    
    // Preview Canvas
    
    lazy var itemPreviewView: OutfitCanvasView = {
        let cv = OutfitCanvasView(editingMode: false)
        cv.delegate = self
        return cv
    }()
    
    // Name
    
    lazy var itemNameTextField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.name.title"), placeholder: String(localized: "common.placeholder.name"), text: item.name, charCounterWithCharacters: 50)
        view.fieldInput.isUserInteractionEnabled = false
        view.fieldInput.delegate = self
        return view
    }()
    
    // Seasons
    
    lazy var itemSeasonsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.season.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.indicatorImageView.isHidden = true
        view.fieldInput.addAction(UIAction {_ in self.showInteractionBlocker(); self.view.bringSubviewToFront(self.itemSeasonsPickerView); self.itemSeasonsPickerView.showSeasonsPickerView()}, for: .primaryActionTriggered)
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
    
    // Favorite
    
    lazy var itemFavoriteField: CustomSwitchInput = {
        let view = CustomSwitchInput(fieldTitle: String(localized: "common.favorite.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.fieldInput.addTarget(self, action: #selector(favoriteToggled), for: .valueChanged)
        return view
    }()
    
    // Tags
    
    lazy var itemTagsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.tag.title"))
        view.fieldInput.isUserInteractionEnabled = false
        view.indicatorImageView.isHidden = true
        view.fieldInput.addAction(UIAction {_ in self.showInteractionBlocker(); self.view.bringSubviewToFront(self.itemTagsPickerView); self.itemTagsPickerView.showTagsPickerView()}, for: .primaryActionTriggered)
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
    
    // MARK: - Functions -
    
    // MARK: Objc Functions
    
    @objc
    func favoriteToggled() {
        item.isFavorite.toggle()
    }
    
    func saveItemChanges() async {
        if await AppRepository.shared.outfitRepository.addOrUpdateOutfit(from: item) {
            if savedItem.scene != item.scene {
                if let cacheKey = SDWebImageManager.shared.cacheKey(for: URL(string: item.id, relativeTo: APIClient.outfitImagesURL)) {
                    SDImageCache.shared.removeImageFromDisk(forKey: cacheKey)
                    SDImageCache.shared.removeImageFromMemory(forKey: cacheKey)
                }
            }
            
            savedItem = item
            didUpdate = true
        }
    }
    
    func promptUnsavedChanges(dismissAfterSave dismiss: Bool = false) -> Void {
        let alert = UIAlertController(title: String(localized: "outfitdetails.unsaved.title"), message: String(localized: "outfitdetails.unsaved.message"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String(localized: "common.save"), style: .default, handler: { _ in
            Task {
                await self.saveItemChanges()
                
                DispatchQueue.main.async {
                    if !self.checkForUnsavedChanges() && dismiss {
                        alert.dismiss(animated: true)
                    }
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.undo"), style: .destructive, handler: { _ in
            self.item = self.savedItem
            
            DispatchQueue.main.async {
                self.updateUIFromItem()
            }
        }))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel, handler: { _ in
            return
        }))
        
        present(alert, animated: true)
    }
    
    func deleteItem() async -> Void {
        let alert = UIAlertController(title: String(localized: "outfitdetails.delete.title"), message: String(localized: "outfitdetails.delete.question"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        
        alert.addAction(UIAlertAction(title: String(localized: "common.delete"), style: .destructive, handler: { _ in
            Task {
                if await AppRepository.shared.outfitRepository.deleteOutfit(with: self.item.id) {
                    self.delegate?.didDeleteOutfit()
                    self.dismiss(animated: true)
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    func checkForUnsavedChanges() -> Bool {
        return savedItem != item
    }
    
    func toggleEditing() {
        itemPreviewView.toggleEditing()
        itemNameTextField.fieldInput.isUserInteractionEnabled.toggle()
        itemSeasonsField.fieldInput.isUserInteractionEnabled.toggle()
        itemSeasonsField.indicatorImageView.isHidden.toggle()
        itemTagsField.fieldInput.isUserInteractionEnabled.toggle()
        itemTagsField.indicatorImageView.isHidden.toggle()
        itemFavoriteField.fieldInput.isUserInteractionEnabled.toggle()
    }
    
    private func updateUIFromItem() {
        itemPreviewView.loadOutfit(placements: item.scene)
        
        itemNameTextField.fieldInput.text = item.name
        selectedSeasonsArray = item.seasons
        selectedTagsArray = item.tags
        itemFavoriteField.fieldInput.isOn = item.isFavorite
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        
        [segmentController, itemDeleteButton, itemDoneButton, itemPreviewView, itemNameTextField, itemSeasonsField, itemSeasonsSelection, itemSeasonsPickerView, itemTagsField, itemTagsPickerView, outfitItemsCollectionView].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            segmentController.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            segmentController.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        segmentController.addAction(UIAction { _ in
            self.toggleEditing()
        }, for: .valueChanged)
        
        NSLayoutConstraint.activate([
            itemDeleteButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDeleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemDoneButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            itemPreviewView.topAnchor.constraint(equalTo: segmentController.bottomAnchor, constant: 20),
            itemPreviewView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),
            itemPreviewView.heightAnchor.constraint(equalTo: itemPreviewView.widthAnchor, multiplier: 4.0 / 3.0),
            itemPreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            itemNameTextField.topAnchor.constraint(equalTo: itemPreviewView.bottomAnchor, constant: 20),
            itemNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            itemNameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
        
        NSLayoutConstraint.activate([
            itemSeasonsField.topAnchor.constraint(equalTo: itemNameTextField.bottomAnchor, constant: 10),
            itemSeasonsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            itemSeasonsField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            itemSeasonsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            itemSeasonsSelection.topAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.topAnchor),
            itemSeasonsSelection.leadingAnchor.constraint(equalTo: itemSeasonsField.leadingAnchor),
            itemSeasonsSelection.trailingAnchor.constraint(equalTo: itemSeasonsField.trailingAnchor),
            itemSeasonsSelection.bottomAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.bottomAnchor),
            
            itemSeasonsPickerView.topAnchor.constraint(equalTo: itemSeasonsField.bottomAnchor, constant: 15),
            itemSeasonsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemSeasonsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            itemSeasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        let sv = UIStackView(arrangedSubviews: [itemTagsField, itemFavoriteField])
        
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 5
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        NSLayoutConstraint.activate([
            sv.topAnchor.constraint(equalTo: itemSeasonsField.bottomAnchor, constant: 10),
            sv.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            sv.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            sv.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            itemTagsField.heightAnchor.constraint(equalTo: sv.heightAnchor)
        ])
        
        itemTagsField.addSubview(itemTagsSelection)
        NSLayoutConstraint.activate([
            itemTagsSelection.topAnchor.constraint(equalTo: itemTagsField.fieldBackground.topAnchor),
            itemTagsSelection.leadingAnchor.constraint(equalTo: itemTagsField.leadingAnchor),
            itemTagsSelection.trailingAnchor.constraint(equalTo: itemTagsField.trailingAnchor),
            itemTagsSelection.bottomAnchor.constraint(equalTo: itemTagsField.fieldBackground.bottomAnchor),
            
            itemTagsPickerView.topAnchor.constraint(equalTo: itemTagsField.bottomAnchor, constant: 15),
            itemTagsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemTagsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            itemTagsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            outfitItemsCollectionView.topAnchor.constraint(equalTo: itemTagsField.bottomAnchor, constant: 10),
            outfitItemsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            outfitItemsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            outfitItemsCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2)
        ])
        
        updateUIFromItem()
    }
}

extension OutfitDetailsController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if presentationController.presentedViewController !== self.navigationController { return true }
        return !self.checkForUnsavedChanges()
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard presentationController.presentedViewController === self.navigationController else { return }
        guard self.checkForUnsavedChanges() else {
            self.dismiss(animated: true)
            return
        }
        
        promptUnsavedChanges(dismissAfterSave: true)
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if self.didUpdate {
            delegate?.didUpdateOutfit()
        }
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

extension OutfitDetailsController: SeasonsPickerViewDelegate, TagsPickerViewDelegate {
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
        self.hideInteractionBlocker()
        self.itemTagsPickerView.hideTagsPickerView()
    }
    
    func seasonSelected(_ season: Seasons) {
        if let idx = selectedSeasonsArray.firstIndex(of: season) {
            selectedSeasonsArray.remove(at: idx)
            item.seasons.remove(at: idx)
        } else {
            selectedSeasonsArray.append(season)
            item.seasons.append(season)
        }
    }
    
    func seasonsDoneButtonPressed() {
        self.hideInteractionBlocker()
        self.itemSeasonsPickerView.hideSeasonsPickerView()
    }
}

extension OutfitDetailsController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRanges ranges: [NSValue], replacementString string: String) -> Bool {
        if textField == self.itemNameTextField.fieldInput {
            if string == "" { item.name = itemNameTextField.fieldInput.text!.dropLast().description; return true }
            
            guard itemNameTextField.fieldInput.text?.count ?? 0 < 50 else { return false }
            
            item.name = itemNameTextField.fieldInput.text! + string
        }
        
        return true
    }
}

extension OutfitDetailsController: OutfitCanvasViewDelegate {
    func canvasView(_ canvasView: OutfitCanvasView, didAddClothing clothing: Clothing) {
        return
    }
    
    func canvasView(_ canvasView: OutfitCanvasView, didRemoveClothing clothing: Clothing) {
        return
    }
    
    func canvasViewDidBeginInteraction(_ canvasView: OutfitCanvasView) {
        navigationController?.isModalInPresentation = true
    }
    
    func canvasViewDidEndInteraction(_ canvasView: OutfitCanvasView) {
        navigationController?.isModalInPresentation = false
        
        item.scene = canvasView.getItemCanvasPositions()
    }
}
