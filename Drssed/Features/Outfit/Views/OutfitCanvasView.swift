//
//  OutfitCanvasView.swift
//  Drssed
//
//  Created by David Riegel on 06.04.26.
//

import UIKit
import SDWebImage

protocol OutfitCanvasViewDelegate: AnyObject {
    func canvasView(_ canvasView: OutfitCanvasView, didAddClothing clothing: Clothing)
    func canvasView(_ canvasView: OutfitCanvasView, didRemoveClothing clothing: Clothing)
    func canvasView(_ canvasView: OutfitCanvasView, didLongPressClothing clothing: Clothing)
    func canvasViewDidBeginInteraction(_ canvasView: OutfitCanvasView)
    func canvasViewDidEndInteraction(_ canvasView: OutfitCanvasView)
}

extension OutfitCanvasViewDelegate {
    func canvasView(_ canvasView: OutfitCanvasView, didLongPressClothing clothing: Clothing) {}
    func canvasViewDidBeginInteraction(_ canvasView: OutfitCanvasView) {}
    func canvasViewDidEndInteraction(_ canvasView: OutfitCanvasView) {}
}

class OutfitCanvasView: UIView {

    // MARK: - Configuration
    public weak var delegate: OutfitCanvasViewDelegate?
    private var editingMode: Bool
    private(set) var clothingItems: [String: (clothing: Clothing, view: UIImageView)] = [:]
    private var lockBadgeViews: [String: UIView] = [:]
    
    lazy var gridView: GridView = {
        let gv = GridView()
        gv.numberOfColumns = 3
        gv.numberOfRows = 4
        gv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gv.frame = self.bounds
        return gv
    }()
    
    // MARK: - Initialization
    
    init(editingMode edit: Bool = false) {
        editingMode = edit
        
        super.init(frame: CGRect())
        setupCanvas()
        if edit { toggleEditing() }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = CornerStyle.small.radius(for: self)
    }
    
    // MARK: - Public Methods
    
    func toggleEditing() {
        if subviews.contains(gridView) {
            editingMode = false
            gridView.removeFromSuperview()

            for (_, item) in clothingItems {
                item.view.isUserInteractionEnabled = false
            }
        } else {
            editingMode = true
            insertSubview(gridView, at: 0)

            for (_, item) in clothingItems {
                item.view.isUserInteractionEnabled = true
            }
        }
    }

    func addClothing(_ clothing: Clothing) {
        guard editingMode else { return }

        let itemView = UIImageView()
        itemView.sd_setImage(with: URL(string: clothing.imageID, relativeTo: APIClient.clothingImagesURL))
        itemView.tintColor = .label
        itemView.contentMode = .scaleAspectFit
        itemView.frame = CGRect(x: bounds.midX - 75, y: bounds.midY - 75, width: 150, height: 150)
        itemView.accessibilityIdentifier = clothing.id
        attachEditingGestures(to: itemView)

        addSubview(itemView)
        clothingItems[clothing.id] = (clothing, itemView)
        delegate?.canvasView(self, didAddClothing: clothing)
    }
    
    func addClothing(_ clothing: Clothing, at placement: CanvasPlacement) {
        guard editingMode else { return }

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.accessibilityIdentifier = clothing.id
        attachEditingGestures(to: imageView)

        let url = URL(string: clothing.imageID, relativeTo: APIClient.clothingImagesURL)
        imageView.sd_setImage(with: url) { [weak self, weak imageView] image, _, _, _ in
            guard let self, let imageView, let image else { return }
            self.applyPlacement(placement, to: imageView, intrinsicSize: image.size)
        }

        addSubview(imageView)
        clothingItems[clothing.id] = (clothing, imageView)
        delegate?.canvasView(self, didAddClothing: clothing)
    }

    func removeClothing(_ clothing: Clothing) {
        guard editingMode, let item = clothingItems[clothing.id] else { return }
        item.view.removeFromSuperview()
        clothingItems.removeValue(forKey: clothing.id)
        delegate?.canvasView(self, didRemoveClothing: clothing)
    }

    func getItemCanvasPositions() -> [CanvasPlacement] {
        var result: [CanvasPlacement] = []

        for view in subviews {
            guard
                let itemView = view as? UIImageView,
                let image = itemView.image,
                let clothingID = itemView.accessibilityIdentifier
            else { continue }

            let centerInCanvas = itemView.superview?.convert(itemView.center, to: self) ?? itemView.center
            let x = Double(centerInCanvas.x / max(bounds.width, 1))
            let y = Double(centerInCanvas.y / max(bounds.height, 1))
            let z = subviews.firstIndex(of: itemView) ?? 0

            let viewSize = itemView.bounds.size
            let imageSize = image.size
            let fitScale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let fittedImageWidth = imageSize.width * fitScale

            let t = itemView.transform
            let transformScale = sqrt(t.a * t.a + t.b * t.b)
            let visualWidth = fittedImageWidth * transformScale
            let normalizedScale = visualWidth / bounds.width
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

    func loadOutfit(placements: [CanvasPlacement]) {
        Task {
            for item in clothingItems.values {
                item.view.removeFromSuperview()
            }
            
            clothingItems.removeAll()
            
            let sortedPlacements = placements.sorted { $0.z < $1.z }
            
            let clothingIDs = placements.map { $0.clothing_id }
            let images = await AppRepository.shared.clothingRepository.getClothingImages(with: clothingIDs)
            let clothings = await AppRepository.shared.clothingRepository.fetchClothes(ids: clothingIDs)
            let clothingByID = Dictionary(uniqueKeysWithValues: clothings.map { ($0.id, $0) })
            
            layoutIfNeeded()
            
            for placement in sortedPlacements {
                guard let image = images[placement.clothing_id], let clothing = clothingByID[placement.clothing_id] else {
                    continue
                }
                
                let imageView = createClothingImageView(
                    image: image,
                    placement: placement
                )
                
                addSubview(imageView)
                clothingItems[placement.clothing_id] = (clothing, imageView)
            }
        }
    }

    func setLocked(_ isLocked: Bool, for clothingID: String) {
        guard let item = clothingItems[clothingID] else { return }

        if isLocked {
            guard lockBadgeViews[clothingID] == nil else { return }
            let badge = makeLockBadge()
            item.view.addSubview(badge)
            positionLockBadge(badge, in: item.view)
            lockBadgeViews[clothingID] = badge

            badge.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            badge.alpha = 0
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.5,
                options: [],
                animations: {
                    badge.transform = .identity
                    badge.alpha = 1
                }
            )
            
            applyCounterRotation(to: badge, from: item.view)
        } else {
            guard let badge = lockBadgeViews[clothingID] else { return }
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    badge.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    badge.alpha = 0
                },
                completion: { _ in
                    badge.removeFromSuperview()
                }
            )
            lockBadgeViews.removeValue(forKey: clothingID)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCanvas() {
        backgroundColor = .secondarySystemBackground
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
        clipsToBounds = true
    }
    
    private func createClothingImageView(
        image: UIImage,
        placement: CanvasPlacement
    ) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = placement.clothing_id
        attachEditingGestures(to: imageView)
        
        let canvasWidth = bounds.width
        let canvasHeight = bounds.height
        
        let targetWidth = placement.scale * canvasWidth
        let aspectRatio = image.size.height / image.size.width
        let targetHeight = targetWidth * aspectRatio
        
        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: targetWidth,
            height: targetHeight
        )
        
        if placement.rotation != 0 {
            imageView.transform = CGAffineTransform(rotationAngle: placement.rotation)
        }
        
        let centerX = placement.x * canvasWidth
        let centerY = placement.y * canvasHeight
        
        imageView.center = CGPoint(x: centerX, y: centerY)

        return imageView
    }

    private func attachEditingGestures(to view: UIImageView) {
        view.isUserInteractionEnabled = editingMode

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4

        [pan, pinch, rotate, longPress].forEach {
            $0.delegate = self
            view.addGestureRecognizer($0)
        }
    }
    
    private func applyPlacement(_ placement: CanvasPlacement, to imageView: UIImageView, intrinsicSize: CGSize) {
        let canvasWidth = bounds.width
        let canvasHeight = bounds.height

        let targetWidth = placement.scale * canvasWidth
        let aspectRatio = intrinsicSize.height / max(intrinsicSize.width, 1)
        let targetHeight = targetWidth * aspectRatio

        imageView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

        if placement.rotation != 0 {
            imageView.transform = CGAffineTransform(rotationAngle: placement.rotation)
        }

        imageView.center = CGPoint(
            x: placement.x * canvasWidth,
            y: placement.y * canvasHeight
        )
    }
    
    private func applyCounterRotation(to badge: UIView, from itemView: UIView) {
        let rotation = atan2(itemView.transform.b, itemView.transform.a)
        badge.transform = CGAffineTransform(rotationAngle: -rotation)
    }
    
    private func makeLockBadge() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 3
        container.layer.shadowOffset = CGSize(width: 0, height: 1)

        let icon = UIImageView(image: UIImage(
            systemName: "lock.fill",
            withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .bold))
        ))
        icon.tintColor = .accent
        icon.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(icon)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 24),
            container.heightAnchor.constraint(equalToConstant: 24),
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func positionLockBadge(_ badge: UIView, in itemView: UIImageView) {
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: itemView.topAnchor, constant: 4),
            badge.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -4)
        ])
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard editingMode, let targetView = gesture.view else { return }
        bringSubviewToFront(targetView)
        
        switch gesture.state {
        case .began:
            delegate?.canvasViewDidBeginInteraction(self)
        case .ended, .cancelled, .failed:
            delegate?.canvasViewDidEndInteraction(self)
        default:
            break
        }

        let translation = gesture.translation(in: self)
        targetView.center = CGPoint(x: targetView.center.x + translation.x, y: targetView.center.y + translation.y)
        gesture.setTranslation(.zero, in: self)

        let halfW: CGFloat
        let halfH: CGFloat

        if let imageView = targetView as? UIImageView, let image = imageView.image {
            let imageSize = image.size
            let viewSize = targetView.bounds.size
            let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            halfW = (imageSize.width * scale) / 2
            halfH = (imageSize.height * scale) / 2
        } else {
            halfW = targetView.bounds.width / 2
            halfH = targetView.bounds.height / 2
        }

        var center = targetView.center
        center.x = max(halfW, min(center.x, bounds.width - halfW))
        center.y = max(halfH, min(center.y, bounds.height - halfH))
        targetView.center = center
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard editingMode, let targetView = gesture.view as? UIImageView, let image = targetView.image else { return }
        defer { gesture.scale = 1 }
        
        switch gesture.state {
        case .began:
            delegate?.canvasViewDidBeginInteraction(self)
        case .ended, .cancelled, .failed:
            delegate?.canvasViewDidEndInteraction(self)
        default:
            break
        }

        let currentTransform = targetView.transform
        let currentScale = sqrt(currentTransform.a * currentTransform.a + currentTransform.b * currentTransform.b)

        let viewSize = targetView.bounds.size
        let fitScale = min(viewSize.width / image.size.width, viewSize.height / image.size.height)
        let fittedW = image.size.width * fitScale
        let fittedH = image.size.height * fitScale

        let minScale = max(44 / fittedW, 44 / fittedH)
        let maxScale = min(bounds.width / fittedW, bounds.height / fittedH)

        let clampedScale = max(minScale, min(currentScale * gesture.scale, maxScale))
        let delta = clampedScale / currentScale

        targetView.transform = currentTransform.scaledBy(x: delta, y: delta)

        let halfW = (fittedW * clampedScale) / 2
        let halfH = (fittedH * clampedScale) / 2
        var center = targetView.center
        center.x = max(halfW, min(center.x, bounds.width - halfW))
        center.y = max(halfH, min(center.y, bounds.height - halfH))
        targetView.center = center
    }

    @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard editingMode, let targetView = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            delegate?.canvasViewDidBeginInteraction(self)
        case .ended, .cancelled, .failed:
            delegate?.canvasViewDidEndInteraction(self)
        default:
            break
        }
        
        targetView.transform = targetView.transform.rotated(by: gesture.rotation)
        
        if let id = targetView.accessibilityIdentifier, let badge = lockBadgeViews[id] {
            applyCounterRotation(to: badge, from: targetView)
        }
        
        gesture.rotation = 0
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard editingMode, let targetView = gesture.view, let id = targetView.accessibilityIdentifier, let item = clothingItems[id] else { return }
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            delegate?.canvasViewDidBeginInteraction(self)
            delegate?.canvasView(self, didLongPressClothing: item.clothing)
        case .ended, .cancelled, .failed:
            delegate?.canvasViewDidEndInteraction(self)
        default: break
        }
    }
}

extension OutfitCanvasView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let otherView = otherGestureRecognizer.view else { return false }
        return otherView == self || otherView.isDescendant(of: self)
    }
}
