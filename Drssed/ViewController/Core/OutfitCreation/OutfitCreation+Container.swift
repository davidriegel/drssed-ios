//
//  OutfitCreation+Container.swift
//  Drssed
//
//  Created by David Riegel on 13.08.25.
//

import Foundation
import UIKit

class OutfitCreation_Container: UIView {
    private var selectedIndex: Int? {
        didSet {
            selectedClothing = dataSource[selectedIndex ?? 0]
        }
    }
    private(set) var selectedClothing: Clothing?
    private let multiplier: Int = 50
    
    private var dataSource: [Clothing] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    public func getDataSource() -> [Clothing] {
        return dataSource
    }
    
    public func setDataSource(_ data: [Clothing]) {
        dataSource = data
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 0
        layout.sectionInsetReference = .fromContentInset
        layout.sectionInset = .zero
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(OutfitCreationImageCell.self, forCellWithReuseIdentifier: OutfitCreationImageCell.identifier)
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast
        return cv
    }()
    
    private lazy var selectionBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var actionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.spacing = 5
        sv.alignment = .center
        sv.distribution = .equalSpacing
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        sv.axis = .horizontal
        return sv
    }()
    
    private lazy var lockButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)), for: .normal)
        button.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .accent)), for: .selected)
        
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalTo: button.heightAnchor)])
        button.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(didTapLock), for: .touchUpInside)
        return button
    }()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(didTapMagnifyingglass), for: .touchUpInside)
        button.tintColor = .label
        return button
    }()
    
    private lazy var shuffleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "shuffle", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .secondaryLabel)), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(didTapShuffle), for: .touchUpInside)
        button.tintColor = .label
        return button
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBackground.layer.cornerRadius = selectionBackground.bounds.height * 0.15
        
        collectionView.performBatchUpdates({
            collectionView.collectionViewLayout.invalidateLayout()
            scrollToMiddleSection()
        }, completion: nil)
    }
    
    private func scrollToMiddleSection() {
        guard !dataSource.isEmpty else { return }
        
        let index = selectedIndex ?? self.dataSource.count / 2
        let middleSection = self.multiplier / 2
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: middleSection),
                                                     at: .centeredHorizontally,
                                                     animated: false)
        self.selectedIndex = index % self.dataSource.count

    }
    
    @objc
    func didTapLock() {
        lockButton.isSelected.toggle()
        collectionView.isScrollEnabled.toggle()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc
    func didTapShuffle() {
        if lockButton.isSelected {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        _ = shuffleToNewItem()
    }
    
    @objc
    func didTapMagnifyingglass() {
        if lockButton.isSelected {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    public func shuffleToNewItem() -> Bool {
        guard !lockButton.isSelected else { return false }
        guard !dataSource.isEmpty else { return false }
        
        let newIndexPath = IndexPath(item: .random(in: 0..<self.dataSource.count), section: self.multiplier / 2)
        self.selectedIndex = newIndexPath.item
        
        self.collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: true)
        
        return true
    }
    
    init() {
        super.init(frame: .zero)
        
        addSubview(selectionBackground)
        addSubview(actionsStackView)
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            selectionBackground.heightAnchor.constraint(equalTo: heightAnchor),
            selectionBackground.widthAnchor.constraint(equalTo: heightAnchor),
            selectionBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectionBackground.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            actionsStackView.leadingAnchor.constraint(equalTo: selectionBackground.leadingAnchor),
            actionsStackView.trailingAnchor.constraint(equalTo: selectionBackground.trailingAnchor),
            actionsStackView.bottomAnchor.constraint(equalTo: selectionBackground.bottomAnchor),
            actionsStackView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.2)
        ])
        
        actionsStackView.addArrangedSubview(searchButton)
        actionsStackView.addArrangedSubview(shuffleButton)
        actionsStackView.addArrangedSubview(lockButton)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: actionsStackView.topAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OutfitCreation_Container: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.isEmpty ? 0 : multiplier
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OutfitCreationImageCell.identifier, for: indexPath) as! OutfitCreationImageCell
        
        let imageIndex = indexPath.item % dataSource.count
        cell.configure(with: dataSource[imageIndex].imageID)
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = scrollView as? UICollectionView,
              let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        // Vorher: Scroll-Ziel setzen, damit es sofort smooth snapt
        let proposedOffset = targetContentOffset.pointee
        let visibleRect = CGRect(origin: CGPoint(x: proposedOffset.x, y: 0),
                                 size: collectionView.bounds.size)
        
        // Layout-Attribute für sichtbare Zellen
        guard let attributes = layout.layoutAttributesForElements(in: visibleRect), !attributes.isEmpty else { return }
        
        // Mittelpunkt des CollectionViews (in Content-Koordinaten)
        let collectionViewCenterX = proposedOffset.x + collectionView.bounds.width / 2
        
        // Das Attribut finden, das der Mitte am nächsten ist
        let closest = attributes.min(by: {
            abs($0.center.x - collectionViewCenterX) < abs($1.center.x - collectionViewCenterX)
        })
        
        if let closest = closest {
            // Neues Offset berechnen, damit diese Zelle in der Mitte landet
            let targetX = closest.center.x - collectionView.bounds.width / 2
            targetContentOffset.pointee = CGPoint(x: targetX, y: proposedOffset.y)
            
            // Index merken
            selectedIndex = closest.indexPath.item % dataSource.count
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard selectedIndex != nil else { return }
        
        let newIndexPath = IndexPath(item: selectedIndex!, section: multiplier / 2)
        collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
    }
}

