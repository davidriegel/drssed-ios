//
//  InfiniteCollectionView.swift
//  Wearhouse
//
//  Created by David Riegel on 17.09.25.
//

import UIKit

// MARK: - Infinite Collection View
class InfiniteCollectionView: UIView {


private var collectionView: UICollectionView!
private var dataSource: [ClothingLocal] = []
private let multiplier = 3 // Creates 3 copies of the data for infinite scroll
private var imageCache = NSCache<NSString, UIImage>()

override init(frame: CGRect) {
    super.init(frame: frame)
    setupCollectionView()
}

required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupCollectionView()
}

override func layoutSubviews() {
    super.layoutSubviews()
    // Ensure we scroll to middle section after layout is complete
    //if bounds.width > 0 && !dataSource.isEmpty {
        //scrollToMiddleSection()
    //}
}

private func setupCollectionView() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    backgroundColor = .cyan
    
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .lightGray
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.isPagingEnabled = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.register(OutfitCreationImageCell.self,
                           forCellWithReuseIdentifier: OutfitCreationImageCell.identifier)
    
    addSubview(collectionView)
    
    NSLayoutConstraint.activate([
        collectionView.topAnchor.constraint(equalTo: topAnchor),
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
}

private func setupSampleData() {
    // Remove this method as we'll use real data source
}

private func createImage(with color: UIColor) -> UIImage {
    // Keep for placeholder images
    let size = CGSize(width: 100, height: 100)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image ?? UIImage()
}

private func scrollToMiddleSection() {
    guard !dataSource.isEmpty, bounds.width > 0 else { return }
    let middleSection = multiplier / 2
    let indexPath = IndexPath(item: 0, section: middleSection)
    collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
}

// Public method to update data source
func updateDataSource(_ newDataSource: [ClothingLocal]) {
    dataSource = newDataSource
    collectionView.reloadData()
    DispatchQueue.main.async {
        self.scrollToMiddleSection()
    }
}

// Load image from URL with caching
private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    // Check cache first
    if let cachedImage = imageCache.object(forKey: urlString as NSString) {
        completion(cachedImage)
        return
    }
    
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }
    
    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
        guard let data = data,
              let image = UIImage(data: data),
              error == nil else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        // Cache the image
        self?.imageCache.setObject(image, forKey: urlString as NSString)
        
        DispatchQueue.main.async {
            completion(image)
        }
    }.resume()
}


}

// MARK: - Collection View Data Source
extension InfiniteCollectionView: UICollectionViewDataSource {


func numberOfSections(in collectionView: UICollectionView) -> Int {
    return dataSource.isEmpty ? 0 : multiplier
}

func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataSource.count
}

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OutfitCreationImageCell.identifier, for: indexPath) as! OutfitCreationImageCell
    
    let itemIndex = indexPath.item % dataSource.count
    let item = dataSource[itemIndex]
    
    // Set placeholder image first
    //cell.configure(with: createImage(with: .systemGray5))
    
    // Load actual image from URL
    loadImage(from: item.imageID) { image in
        // Make sure the cell hasn't been reused
        if let currentIndexPath = collectionView.indexPath(for: cell),
           currentIndexPath == indexPath {
            //cell.configure(with: image ?? self.createImage(with: .systemGray3))
        }
    }
    
    return cell
}


}

// MARK: - Collection View Delegate Flow Layout
extension InfiniteCollectionView: UICollectionViewDelegateFlowLayout {


func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return collectionView.bounds.size
}


}

// MARK: - Scroll View Delegate for Infinite Scrolling
extension InfiniteCollectionView: UIScrollViewDelegate {


func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    handleInfiniteScroll()
}

func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
        handleInfiniteScroll()
    }
}

private func handleInfiniteScroll() {
    guard !dataSource.isEmpty else { return }
    
    let pageWidth = collectionView.bounds.width
    let currentPage = Int(collectionView.contentOffset.x / pageWidth)
    let totalItems = dataSource.count * multiplier
    
    // If we're at the beginning of the first section, jump to the beginning of the last section
    if currentPage < dataSource.count {
        let newOffset = CGPoint(x: pageWidth * CGFloat(currentPage + dataSource.count * (multiplier - 1)), y: 0)
        collectionView.setContentOffset(newOffset, animated: false)
    }
    // If we're at the end of the last section, jump to the end of the first section
    else if currentPage >= totalItems - dataSource.count {
        let newOffset = CGPoint(x: pageWidth * CGFloat(currentPage - dataSource.count * (multiplier - 1)), y: 0)
        collectionView.setContentOffset(newOffset, animated: false)
    }
}


}
