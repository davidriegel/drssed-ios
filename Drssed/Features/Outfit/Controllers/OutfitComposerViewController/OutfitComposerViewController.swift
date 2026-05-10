//
//  OutfitCreationController.swift
//  Drssed
//
//  Created by David Riegel on 21.09.25.
//

import UIKit
import Toast

class OutfitComposerViewController: UIViewController {
    private let clothingRepo: ClothingRepository = ClothingRepository()
    
    private lazy var suggestionSession = OutfitSuggestionSession()
    
    private(set) var lockedClothes: Set<Clothing.ID> = []

    private var pickedClothing: [Clothing] = [] {
        didSet {
            self.submitButton.isEnabled = pickedClothing.count > 1
            self.submitButton.backgroundColor = pickedClothing.count > 1 ? .accent : .accent.withAlphaComponent(0.3)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewComponents()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        submitButton.layer.cornerRadius = CornerStyle.medium.radius(for: submitButton)
    }

    // MARK: - Canvas

    lazy var clothingPickerNavController: UINavigationController = {
        let clothesPickerSheet = UINavigationController(rootViewController: OutfitComposerViewController_Picker(delegate: self))
        clothesPickerSheet.modalPresentationStyle = .pageSheet
        clothesPickerSheet.isModalInPresentation = false

        if let sheet = clothesPickerSheet.sheetPresentationController {
            sheet.preferredCornerRadius = CornerStyle.small.radius(for: clothesPickerSheet.view)
            sheet.detents = [.custom(identifier: .init("small"), resolver: { context in
                0.08 * context.maximumDetentValue
            }), .medium()]

            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        return clothesPickerSheet
    }()

    lazy var canvasView: OutfitCanvasView = {
        let cv = OutfitCanvasView(editingMode: true)
        cv.delegate = self
        return cv
    }()

    // MARK: - Toolbar

    lazy var toolbarView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        sv.distribution = .fillEqually
        sv.spacing = 16
        return sv
    }()

    lazy var clearButton: UIButton = {
        var config = UIButton.Configuration.glass()
        config.baseForegroundColor = .label
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "arrow.counterclockwise", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "outfitcomposer.clear"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { _ in
            let picker = self.clothingPickerNavController.viewControllers.first as! OutfitComposerViewController_Picker

            for (index, _) in self.pickedClothing.enumerated() {
                picker.clothingCollectionView.delegate?.collectionView?(picker.clothingCollectionView, didDeselectItemAt: IndexPath(row: index, section: 0))
                picker.clothingCollectionView.deselectItem(at: IndexPath(row: index, section: 0), animated: true)
            }
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        return bt
    }()

    lazy var randomButton: UIButton = {
        var config = UIButton.Configuration.glass()
        config.baseForegroundColor = .label
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "dice.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.baseBackgroundColor = .accent
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "common.suggest"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.didTapSuggest()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        return bt
    }()
    
    private func didTapSuggest() {
        randomButton.isEnabled = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task { @MainActor in
            defer { self.randomButton.isEnabled = true }
            
            let anchor = self.lockedClothes
            
            do {
                let outfit = try await self.suggestionSession.next(currentAnchor: anchor)
                
                self.applySuggestedOutfit(outfit, preservingAnchor: anchor)
            } catch APIError.unprocessableContent {
                ToastPresenter.error(String(localized: "outfitcomposer.error.suggest"))
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }

    
    private func applySuggestedOutfit(_ outfit: Outfit, preservingAnchor anchor: Set<String>) {
        let anchoredIDs = anchor
        let toRemove = pickedClothing.filter { !anchoredIDs.contains($0.id) }

        for clothing in toRemove {
            canvasView.removeClothing(clothing)
            let picker = clothingPickerNavController.viewControllers.first as! OutfitComposerViewController_Picker
            picker.programmaticallyDeselect(clothingID: clothing.id)
        }

        let suggestedPlacements = outfit.scene
            .sorted { $0.z < $1.z }
            .filter { !anchor.contains($0.clothing_id) }

        Task { @MainActor in
            for placement in suggestedPlacements {
                guard let clothing = await AppRepository.shared.clothingRepository.getClothing(with: placement.clothing_id) else { continue }
                canvasView.addClothing(clothing, at: placement)
                
                let picker = clothingPickerNavController.viewControllers.first as! OutfitComposerViewController_Picker
                picker.programmaticallySelect(clothingID: clothing.id)
            }
        }
    }

    lazy var addButton: UIButton = {
        var config = UIButton.Configuration.glass()
        config.baseForegroundColor = .label
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "common.add"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { _ in
            self.navigationController?.present(self.clothingPickerNavController, animated: true)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        return bt
    }()
    
    // MARK: - Submit Button

    lazy var submitButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.configuration = .prominentGlass()
        bt.configuration?.baseBackgroundColor = .accent
        bt.setAttributedTitle(NSAttributedString(string: String(localized: "common.continue"), attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        bt.configuration?.titlePadding = 5
        bt.configuration?.baseForegroundColor = .label
        bt.backgroundColor = .accent.withAlphaComponent(0.3)
        bt.isEnabled = false
        return bt
    }()
    
    // MARK: - Configuration

    private func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "outfitcomposer.title")

        tabBarController?.tabBar.isHidden = true

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes

        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal),
            primaryAction: UIAction { _ in
                self.clothingPickerNavController.dismiss(animated: true)
                self.navigationController?.popViewController(animated: true)
                self.tabBarController?.tabBar.isHidden = false
            }
        )

        [canvasView, toolbarView, submitButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            canvasView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvasView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -20),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor, multiplier: 4.0 / 3.0),

            toolbarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: -10),
            toolbarView.widthAnchor.constraint(equalTo: canvasView.widthAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 45),

            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 20),
            submitButton.heightAnchor.constraint(equalToConstant: 45),
            submitButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8)
        ])

        toolbarView.addArrangedSubview(clearButton)
        toolbarView.addArrangedSubview(randomButton)
        toolbarView.addArrangedSubview(addButton)

        submitButton.addAction(UIAction { _ in
            self.clothingPickerNavController.dismiss(animated: true)

            guard self.pickedClothing.count > 1 else {
                let alert = UIAlertController(title: "", message: String(localized: "outfitcomposer.error.selectmultipleitems"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default, handler: { _ in
                    self.navigationController?.present(self.clothingPickerNavController, animated: true)
                }))
                self.navigationController?.present(alert, animated: true)
                return
            }

            guard let previewImage = self.canvasView.renderAsTransparentImage() else { return }
            let vc = OutfitComposerViewController_Submit(self.canvasView.getItemCanvasPositions(), previewImage: previewImage)
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .primaryActionTriggered)
    }
}

extension OutfitComposerViewController: OutfitComposerViewController_PickerDelegate {
    func didSelectClothing(_ clothing: Clothing) {
        lockedClothes.insert(clothing.id)
        canvasView.addClothing(clothing)
        canvasView.setLocked(true, for: clothing.id)
    }

    func didDeselectClothing(_ clothing: Clothing) {
        lockedClothes.remove(clothing.id)
        canvasView.removeClothing(clothing)
        canvasView.setLocked(false, for: clothing.id)
    }
}

extension OutfitComposerViewController: OutfitCanvasViewDelegate {
    func canvasView(_ canvasView: OutfitCanvasView, didAddClothing clothing: Clothing) {
        pickedClothing.append(clothing)
    }

    func canvasView(_ canvasView: OutfitCanvasView, didRemoveClothing clothing: Clothing) {
        pickedClothing.removeAll { $0 == clothing }
    }
    
    func canvasView(_ canvasView: OutfitCanvasView, didLongPressClothing clothing: Clothing) {
        if lockedClothes.contains(clothing.id) {
            canvasView.setLocked(false, for: clothing.id)
            lockedClothes.remove(clothing.id)
            return
        }
        
        canvasView.setLocked(true, for: clothing.id)
        lockedClothes.insert(clothing.id)
    }
}
