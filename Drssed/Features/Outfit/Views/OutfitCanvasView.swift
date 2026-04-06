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
    func canvasViewDidBeginDragging(_ canvasView: OutfitCanvasView)
    func canvasViewDidEndDragging(_ canvasView: OutfitCanvasView)
}

extension OutfitCanvasViewDelegate {
    func canvasViewDidBeginDragging(_ canvasView: OutfitCanvasView) {}
    func canvasViewDidEndDragging(_ canvasView: OutfitCanvasView) {}
}

class OutfitCanvasView: UIView {

    weak var delegate: OutfitCanvasViewDelegate?

    var clothingImageViews: [String: UIImageView] = [:]

    private var editingMode: Bool = false
    
    lazy var gridView: GridView = {
        let gv = GridView()
        gv.numberOfColumns = 3
        gv.numberOfRows = 4
        gv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gv.frame = self.bounds
        return gv
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCanvas()
    }
    
    init(editingMode edit: Bool = false) {
        super.init(frame: CGRect())
        setupCanvas()
        if edit { toggleEditing() }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCanvas()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = CornerStyle.small.radius(for: self)
    }
    
    private func setupCanvas() {
        backgroundColor = .secondarySystemBackground
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
        clipsToBounds = true
    }
    
    // MARK: - Public Methods
    
    func toggleEditing() {
        if subviews.contains(gridView) {
            editingMode = false
            gridView.removeFromSuperview()

            for (_, iv) in clothingImageViews {
                iv.isUserInteractionEnabled = false
            }
        } else {
            editingMode = true
            insertSubview(gridView, at: 0)

            for (_, iv) in clothingImageViews {
                iv.isUserInteractionEnabled = true
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
        clothingImageViews[clothing.id] = itemView
        delegate?.canvasView(self, didAddClothing: clothing)
    }

    func removeClothing(_ clothing: Clothing) {
        guard editingMode, let itemView = clothingImageViews[clothing.id] else { return }
        itemView.removeFromSuperview()
        clothingImageViews.removeValue(forKey: clothing.id)
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
            let sortedPlacements = placements.sorted { $0.z < $1.z }
            
            let clothingIDs = placements.map { $0.clothing_id }
            let images = await AppRepository.shared.clothingRepository.getClothingImages(with: clothingIDs)
            
            layoutIfNeeded()
            
            for placement in sortedPlacements {
                guard let image = images[placement.clothing_id] else {
                    continue
                }
                
                let imageView = createClothingImageView(
                    image: image,
                    placement: placement
                )
                
                addSubview(imageView)
                clothingImageViews[placement.clothing_id] = imageView
            }
        }
    }
    
    // MARK: - Private Methods
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

        [pan, pinch, rotate].forEach {
            $0.delegate = self
            view.addGestureRecognizer($0)
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard editingMode, let targetView = gesture.view else { return }
        bringSubviewToFront(targetView)
        
        switch gesture.state {
        case .began:
            delegate?.canvasViewDidBeginDragging(self)
        case .ended, .cancelled, .failed:
            delegate?.canvasViewDidEndDragging(self)
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
        targetView.transform = targetView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }
}

extension OutfitCanvasView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let otherView = otherGestureRecognizer.view else { return false }
        return otherView == self || otherView.isDescendant(of: self)
    }
}
