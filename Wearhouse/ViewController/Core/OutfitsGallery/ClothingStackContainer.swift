//
//  ClothingStackContainer.swift
//  Wearhouse
//
//  Created by David Riegel on 24.11.25.
//

import UIKit

// MARK: - ClothingStackContainer
class ClothingStackContainer: UIView {


private var infiniteCollectionView: InfiniteCollectionView!

override init(frame: CGRect) {
    super.init(frame: frame)
    setupCollectionView()
}

required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupCollectionView()
}

private func setupCollectionView() {
    infiniteCollectionView = InfiniteCollectionView()
    infiniteCollectionView.translatesAutoresizingMaskIntoConstraints = false
    
    addSubview(infiniteCollectionView)
    
    NSLayoutConstraint.activate([
        infiniteCollectionView.topAnchor.constraint(equalTo: topAnchor),
        infiniteCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
        infiniteCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        infiniteCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
}

// Public method to set data source
func setDataSource(_ dataSource: [ClothingLocal]) {
    infiniteCollectionView.updateDataSource(dataSource)
}


}
