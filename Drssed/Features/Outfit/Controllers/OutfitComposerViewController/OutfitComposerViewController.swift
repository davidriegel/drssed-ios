//
//  OutfitCreationController.swift
//  Drssed
//
//  Created by David Riegel on 21.09.25.
//

import UIKit
import SDWebImage

class OutfitComposerViewController: UIViewController {
    private let clothingRepo: ClothingRepository = ClothingRepository()
    
    private let minSize: CGFloat = 60
    private let maxSize: CGFloat = 90
    
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
        
        canvasView.layer.cornerRadius = CornerStyle.large.radius(for: canvasView)
        submitButton.layer.cornerRadius = CornerStyle.medium.radius(for: submitButton)
    }
    
    // MARK: -- canvasView
    
    lazy var clothingPickerController: UINavigationController = {
        let clothesPickerSheet = UINavigationController(rootViewController: OutfitComposerViewController_Picker(delegate: self))
        clothesPickerSheet.modalPresentationStyle = .pageSheet
        clothesPickerSheet.isModalInPresentation = true //TURN ON AGAIN TO NOT DISAPPEAR
        
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
    
    lazy var canvasView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var toolbarView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 16
        return sv
    }()
    
    lazy var clearButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "arrow.counterclockwise", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "outfitcomposer.clear"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { _ in
            let picker = self.clothingPickerController.viewControllers.first as! OutfitComposerViewController_Picker
            
            for (index, clothing) in self.pickedClothing.enumerated() {
                picker.clothingCollectionView.delegate?.collectionView?(picker.clothingCollectionView, didDeselectItemAt: IndexPath(row: index, section: 0))
                picker.clothingCollectionView.deselectItem(at: IndexPath(row: index, section: 0), animated: true)
                }
            }
        )
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tintColor = .label
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        bt.backgroundColor = .accent
        return bt
    }()
    
    lazy var randomButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "dice.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.baseBackgroundColor = .accent
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "common.suggest"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { _ in
            let infoAlert = UIAlertController(title: "🤫", message: String(localized: "workinprogress.message"), preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
            UIApplication.shared.topMostViewController()!.present(infoAlert, animated: true)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tintColor = .label
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        bt.backgroundColor = .accent
        return bt
    }()
    
    lazy var addButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.titleLineBreakMode = .byClipping
        config.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .bold)))
        config.imagePlacement = .top
        config.imagePadding = 2
        config.attributedTitle = AttributedString(String(localized: "common.add"), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize - 2, weight: .semibold)]))
        let bt = UIButton(configuration: config, primaryAction: UIAction { _ in
            self.clothingPickerController.sheetPresentationController?.animateChanges {
                self.clothingPickerController.sheetPresentationController?.selectedDetentIdentifier = .medium
            }
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tintColor = .label
        bt.titleLabel?.adjustsFontSizeToFitWidth = true
        bt.titleLabel?.minimumScaleFactor = 0.5
        bt.titleLabel?.numberOfLines = 1
        bt.backgroundColor = .accent
        return bt
    }()
    
    lazy var submitButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setAttributedTitle(NSAttributedString(string: String(localized: "common.continue"), attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        bt.configuration?.titlePadding = 5
        bt.setTitleColor(.label, for: .normal)
        bt.backgroundColor = .accent.withAlphaComponent(0.3)
        bt.isEnabled = false
        return bt
    }()
    
    private func configureViewComponents() -> Void {
        view.backgroundColor = .background
        title = String(localized: "outfitcomposer.title")
        
        tabBarController?.tabBar.isHidden = true
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.present(clothingPickerController, animated: true)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), primaryAction: UIAction {_ in
            self.clothingPickerController.dismiss(animated: true)
            self.navigationController?.popViewController(animated: true)
            self.tabBarController?.tabBar.isHidden = false
        })
        
        [canvasView, toolbarView, submitButton].forEach {
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            canvasView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvasView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -20),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor, multiplier: 1.25)
        ])
        
        NSLayoutConstraint.activate([
            toolbarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarView.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 10),
            toolbarView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8),
            toolbarView.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        toolbarView.addArrangedSubview(clearButton)
        toolbarView.addArrangedSubview(randomButton)
        toolbarView.addArrangedSubview(addButton)
        
        NSLayoutConstraint.activate([
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: toolbarView.bottomAnchor, constant: 20),
            submitButton.heightAnchor.constraint(equalToConstant: 45),
            submitButton.widthAnchor.constraint(equalToConstant: self.view.frame.width * 0.8)
        ])
        submitButton.addAction(UIAction { _ in
            self.clothingPickerController.dismiss(animated: true)
            
            guard self.pickedClothing.count > 1 else {
                let alert = UIAlertController(title: "", message: String(localized: "outfitcomposer.error.selectmultipleitems"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default, handler: {_ in self.navigationController?.present(self.clothingPickerController, animated: true)}))
                self.navigationController?.present(alert, animated: true)
                return
            }
            
            
            
            guard let previewImage = self.canvasView.renderAsTransparentImage() else { return }
            let vc = OutfitComposerViewController_Submit(self.getItemCanvasPosition(), previewImage: previewImage)
            self.navigationController?.pushViewController(vc, animated: true)
        }, for: .primaryActionTriggered)
    }
    
    private func getItemCanvasPosition() -> [CanvasPlacement] {
        var result: [CanvasPlacement] = []

        for view in canvasView.subviews {
            guard
                let itemView = view as? UIImageView,
                let image = itemView.image,
                let clothingID = itemView.accessibilityIdentifier
            else { continue }

            let centerInCanvas = itemView.superview?.convert(itemView.center, to: canvasView) ?? itemView.center

            // Normalisiert 0..1
            let x = Double(centerInCanvas.x / max(canvasView.bounds.width, 1))
            let y = Double(centerInCanvas.y / max(canvasView.bounds.height, 1))

            let z = canvasView.subviews.firstIndex(of: itemView) ?? 0
            
            let viewSize = itemView.bounds.size
            let imageSize = image.size

            let fitScale = min(
                viewSize.width / imageSize.width,
                viewSize.height / imageSize.height
            )

            let fittedImageWidth = imageSize.width * fitScale

            let t = itemView.transform
            let transformScale = sqrt(t.a * t.a + t.b * t.b)

            let visualWidth = fittedImageWidth * transformScale
            let normalizedScale = visualWidth / canvasView.bounds.width
            let rotation = Double(atan2(t.b, t.a))

            result.append(CanvasPlacement(
                clothing_id: clothingID,
                x: x,
                y: y,
                z: z,
                scale: normalizedScale,
                rotation: rotation
            ))
        }

        return result
    }
    
    private func addClothingToCanvas(_ clothing: Clothing) {
        let itemView = UIImageView()
        itemView.sd_setImage(with: URL(string: clothing.imageID, relativeTo: APIClient.clothingImagesURL))
        itemView.tintColor = .label
        itemView.contentMode = .scaleAspectFit
        itemView.frame = CGRect(x: canvasView.bounds.midX - 75, y: canvasView.bounds.midY - 75, width: 150, height: 150)
        itemView.isUserInteractionEnabled = true
        itemView.accessibilityIdentifier = clothing.id
            
        // Gesten hinzufügen
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
            
        [pan, pinch, rotate].forEach {
            $0.delegate = self
            itemView.addGestureRecognizer($0)
        }
                
        canvasView.addSubview(itemView)
        pickedClothing.append(clothing)
    }
    
    private func removeClothingFromCanvas(_ clothing: Clothing) {
        
        if let index = pickedClothing.firstIndex(of: clothing) {
            pickedClothing.remove(at: index)
            canvasView.subviews[index].removeFromSuperview()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let targetView = gesture.view else { return }
        canvasView.bringSubviewToFront(targetView)
        
        let translation = gesture.translation(in: canvasView)
        targetView.center = CGPoint(x: targetView.center.x + translation.x, y: targetView.center.y + translation.y)
        gesture.setTranslation(.zero, in: canvasView)
        
        // Begrenzung
        var frame = targetView.frame
        if !canvasView.bounds.contains(frame) {
            // Clamp X
            frame.origin.x = max(0, min(frame.origin.x, canvasView.bounds.width - frame.width))
            // Clamp Y
            frame.origin.y = max(0, min(frame.origin.y, canvasView.bounds.height - frame.height))
            targetView.frame = frame
        }
    }
        
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        /*
         guard let targetView = gesture.view else { return }
        
         let currentWidth = targetView.bounds.width
         let newWidth = currentWidth * gesture.scale
            
         if newWidth >= minSize && newWidth <= maxSize {
            targetView.transform = targetView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
         }
        
         */
    }
        
        @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
            guard let targetView = gesture.view else { return }
            targetView.transform = targetView.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        }
}

extension OutfitComposerViewController: OutfitComposerViewController_PickerDelegate, UIGestureRecognizerDelegate {
    func didSelectClothing(_ clothing: Clothing) {
        addClothingToCanvas(clothing)
    }
    
    func didDeselectClothing(_ clothing: Clothing) {
        removeClothingFromCanvas(clothing)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
    }
}
