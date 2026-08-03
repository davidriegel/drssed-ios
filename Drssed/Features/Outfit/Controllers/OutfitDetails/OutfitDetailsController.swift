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
    func didUpdateOutfit(outfit: Outfit)
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

    /// A read-only sheet only shows the outfit – editing, deleting and wearing stay out of it.
    let isReadOnly: Bool

    let clothingRepo: ClothingRepository = AppRepository.shared.clothingRepository
    let wearRepo: WearRepository = AppRepository.shared.wearRepository

    /// The wear entry of this outfit for today, if it was already worn.
    private var todaysWear: OutfitWear? {
        didSet { updateWearButton() }
    }

    private var wearStats: OutfitWearStats = .none {
        didSet { itemStatsView.configure(with: wearStats) }
    }

    private var clothingGridHeightConstraint: NSLayoutConstraint?

    weak var delegate: OutfitDetailsDelegate?

    init(outfit: Outfit, isReadOnly: Bool = false) {
        self.savedItem = outfit
        self.item = outfit
        self.isReadOnly = isReadOnly

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        self.navigationController?.presentationController?.delegate = self

        Task { await refreshWearStats() }

        guard !isReadOnly else { return }

        Task { await refreshTodaysWear() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The grid grows with the number of pieces; its width only settles once laid out.
        guard clothingGridHeightConstraint?.constant != clothingGridHeight() else { return }

        clothingGridHeightConstraint?.constant = clothingGridHeight()
        outfitItemsCollectionView.collectionViewLayout.invalidateLayout()
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
    
    // Delete button
    
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
    
    // Wear button

    lazy var itemWearButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.wearButtonTapped()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tintColor = .accent
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
        view.fieldInput.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.showInteractionBlocker(); self.view.bringSubviewToFront(self.itemSeasonsPickerView); self.itemSeasonsPickerView.showSeasonsPickerView()
        }, for: .primaryActionTriggered)
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
        view.fieldInput.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.showInteractionBlocker(); self.view.bringSubviewToFront(self.itemTagsPickerView); self.itemTagsPickerView.showTagsPickerView()
        }, for: .primaryActionTriggered)
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
    
    // Scrolling content

    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 10
        sv.alignment = .fill
        return sv
    }()

    // Wear history

    lazy var itemStatsView: OutfitStatsView = {
        let view = OutfitStatsView()
        view.translatesAutoresizingMaskIntoConstraints = false
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

    // MARK: Wear

    /// Loads the wear history of this outfit from the local store.
    private func refreshWearStats() async {
        let wears = await wearRepo.fetchWears(outfitID: item.id)
        let stats = OutfitWearStats(wears: wears)

        await MainActor.run { self.wearStats = stats }
    }

    /// Height the item grid needs for all of its rows – it does not scroll on its own.
    private func clothingGridHeight() -> CGFloat {
        let columns = 3
        let rows = max(1, Int(ceil(Double(item.scene.count) / Double(columns))))
        let cellWidth = (view.bounds.width - 40 - CGFloat(columns - 1) * 10) / CGFloat(columns)

        return CGFloat(rows) * cellWidth + CGFloat(rows - 1) * 10
    }

    private func refreshTodaysWear() async {
        let wear = await wearRepo.getWear(forOutfit: item.id)

        await MainActor.run {
            self.todaysWear = wear
        }
    }

    /// Opens the editor for today, or removes the entry again when the outfit is already worn today.
    ///
    /// The editor is shown instead of logging right away so the details are at least offered –
    /// every field in it stays optional.
    private func wearButtonTapped() {
        if let wear = todaysWear {
            promptRemoveWear(wear)
            return
        }

        presentWearEditor(mode: .create(outfitID: item.id))
    }

    /// Logs a wear for today without asking for details – the weather still comes along.
    private func logWearToday() async {
        guard let logged = await wearRepo.logWearNow(outfitID: item.id) else { return }

        await MainActor.run {
            self.todaysWear = logged
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func promptRemoveWear(_ wear: OutfitWear) {
        let alert = UIAlertController(
            title: String(localized: "wear.remove.title"),
            message: String(localized: "wear.remove.question"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))

        alert.addAction(UIAlertAction(title: String(localized: "common.delete"), style: .destructive, handler: { _ in
            Task {
                guard await self.wearRepo.deleteWear(with: wear.id) else { return }

                await MainActor.run {
                    self.todaysWear = nil
                }
            }
        }))

        present(alert, animated: true)
    }

    private func presentWearEditor(mode: WearEditorController.Mode) {
        let editor = WearEditorController(mode: mode)
        editor.delegate = self

        let navController = UINavigationController(rootViewController: editor)
        navController.setNavigationBarHidden(true, animated: false)

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
    }

    private func updateWearButton() {
        let isWornToday = todaysWear != nil
        let symbol = isWornToday ? "checkmark.circle.fill" : "checkmark.circle"

        itemWearButton.setImage(
            UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .headline), scale: .large)),
            for: .normal
        )
        itemWearButton.accessibilityLabel = isWornToday
            ? String(localized: "wear.action.remove")
            : String(localized: "wear.action.today")
        itemWearButton.menu = wearMenu()
    }

    private func wearMenu() -> UIMenu {
        var items: [UIAction] = []

        if let wear = todaysWear {
            items.append(UIAction(title: String(localized: "wear.action.edit"), image: UIImage(systemName: "square.and.pencil"), handler: { [weak self] _ in
                self?.presentWearEditor(mode: .edit(wear))
            }))

            items.append(UIAction(title: String(localized: "wear.action.remove"), image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [weak self] _ in
                self?.promptRemoveWear(wear)
            }))

            items.append(UIAction(title: String(localized: "wear.action.log"), image: UIImage(systemName: "calendar.badge.plus"), handler: { [weak self] _ in
                guard let self else { return }

                self.presentWearEditor(mode: .create(outfitID: self.item.id))
            }))
        } else {
            items.append(UIAction(title: String(localized: "wear.action.today"), image: UIImage(systemName: "checkmark.circle"), handler: { [weak self] _ in
                guard let self else { return }

                self.presentWearEditor(mode: .create(outfitID: self.item.id))
            }))

            // Shortcut for everyone who does not want to fill in the sheet.
            items.append(UIAction(title: String(localized: "wear.action.todayQuick"), image: UIImage(systemName: "bolt"), handler: { [weak self] _ in
                guard let self else { return }

                Task { await self.logWearToday() }
            }))
        }

        return UIMenu(title: String(localized: "wear.menu.title"), children: items)
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
        itemStatsView.configure(with: wearStats)
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .background

        // The header stays pinned, everything below it scrolls – the item grid alone can be
        // taller than the sheet once an outfit holds more than three pieces.
        [segmentController, itemDeleteButton, itemWearButton, itemDoneButton, scrollView, itemSeasonsPickerView, itemTagsPickerView].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            segmentController.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            segmentController.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        segmentController.addAction(UIAction { [weak self] _ in
            self?.toggleEditing()
        }, for: .valueChanged)

        NSLayoutConstraint.activate([
            itemDeleteButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDeleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            itemWearButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemWearButton.leadingAnchor.constraint(equalTo: itemDeleteButton.trailingAnchor, constant: 15),
            itemDoneButton.centerYAnchor.constraint(equalTo: segmentController.centerYAnchor),
            itemDoneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        if isReadOnly {
            [segmentController, itemDeleteButton, itemWearButton, itemDoneButton].forEach { $0.isHidden = true }
            // A character budget is an editing affordance and has no business in a sheet
            // that cannot be edited.
            itemNameTextField.characterCounter(enabled: false, withCharacters: 50)
        } else {
            updateWearButton()
        }

        // Without the controls above it the content moves up into their place.
        let scrollTop = isReadOnly
            ? scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
            : scrollView.topAnchor.constraint(equalTo: segmentController.bottomAnchor, constant: 20)

        NSLayoutConstraint.activate([
            scrollTop,
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20)
        ])

        let previewRow = UIView()
        previewRow.translatesAutoresizingMaskIntoConstraints = false
        previewRow.addSubview(itemPreviewView)

        let tagsRow = UIStackView(arrangedSubviews: [itemTagsField, itemFavoriteField])
        tagsRow.axis = .horizontal
        tagsRow.alignment = .center
        tagsRow.spacing = 5
        tagsRow.translatesAutoresizingMaskIntoConstraints = false

        // Everything joins the hierarchy before the constraints are activated – the preview
        // sizes itself against the safe area, which needs a common ancestor.
        [previewRow, itemStatsView, itemNameTextField, itemSeasonsField, tagsRow, outfitItemsCollectionView].forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(20, after: previewRow)
        contentStack.setCustomSpacing(20, after: itemStatsView)

        itemSeasonsField.addSubview(itemSeasonsSelection)
        itemTagsField.addSubview(itemTagsSelection)

        let clothingGridHeight = outfitItemsCollectionView.heightAnchor.constraint(equalToConstant: clothingGridHeight())
        clothingGridHeightConstraint = clothingGridHeight

        NSLayoutConstraint.activate([
            itemPreviewView.topAnchor.constraint(equalTo: previewRow.topAnchor),
            itemPreviewView.bottomAnchor.constraint(equalTo: previewRow.bottomAnchor),
            itemPreviewView.centerXAnchor.constraint(equalTo: previewRow.centerXAnchor),
            itemPreviewView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),
            itemPreviewView.heightAnchor.constraint(equalTo: itemPreviewView.widthAnchor, multiplier: 4.0 / 3.0),

            itemNameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            itemSeasonsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            itemSeasonsSelection.topAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.topAnchor),
            itemSeasonsSelection.leadingAnchor.constraint(equalTo: itemSeasonsField.leadingAnchor),
            itemSeasonsSelection.trailingAnchor.constraint(equalTo: itemSeasonsField.trailingAnchor),
            itemSeasonsSelection.bottomAnchor.constraint(equalTo: itemSeasonsField.fieldBackground.bottomAnchor),

            tagsRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            itemTagsField.heightAnchor.constraint(equalTo: tagsRow.heightAnchor),
            itemTagsSelection.topAnchor.constraint(equalTo: itemTagsField.fieldBackground.topAnchor),
            itemTagsSelection.leadingAnchor.constraint(equalTo: itemTagsField.leadingAnchor),
            itemTagsSelection.trailingAnchor.constraint(equalTo: itemTagsField.trailingAnchor),
            itemTagsSelection.bottomAnchor.constraint(equalTo: itemTagsField.fieldBackground.bottomAnchor),

            clothingGridHeight
        ])

        // The pickers float above the dimmed background instead of following their field,
        // which would scroll them out of sight.
        NSLayoutConstraint.activate([
            itemSeasonsPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            itemSeasonsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemSeasonsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            itemSeasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            itemTagsPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            itemTagsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4),
            itemTagsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            itemTagsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        updateUIFromItem()
    }
}

extension OutfitDetailsController: WearEditorDelegate {
    func wearEditor(_ controller: WearEditorController, didSave wear: OutfitWear) {
        guard wear.outfitID == item.id else { return }

        // A wear can be logged for or moved to another day, only today's entry drives the button.
        if wear.isOnSameDay(as: Date()) {
            todaysWear = wear
        } else if todaysWear?.id == wear.id {
            todaysWear = nil
        }
    }

    func wearEditor(_ controller: WearEditorController, didDelete wearID: String) {
        if todaysWear?.id == wearID {
            todaysWear = nil
        }
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
            delegate?.didUpdateOutfit(outfit: savedItem)
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
        // Three per row, matching what `clothingGridHeight()` reserves.
        let width = (collectionView.frame.width - 2 * 10) / 3
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
