//
//  OutfitsGalleryViewController.swift
//  Wearhouse
//
//  Created by David Riegel on 18.11.24.
//

import UIKit

public class OutfitsGalleryViewController: UIViewController {
    
    private enum viewMode: CaseIterable {
        case SINGLE
        case MEDIUM
        case SMALL
    }
    
    private var selectedViewMode: viewMode = .SMALL

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        loadUserOutfits()
    }
    
    var outfits: [Outfit] = [] {
        didSet {
            applySnapshot(items: outfits)
        }
    }
    
    private var imageSizes: [String: CGSize] = [:]
    
    enum Section {
        case main
    }

    // 2. DiffableDataSource-Typ
    var dataSource: UICollectionViewDiffableDataSource<Section, Outfit>!

    // 3. Setup
    func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Outfit>(
            collectionView: galleryOutfitsView,
            cellProvider: { (collectionView: UICollectionView, indexPath: IndexPath, item: Outfit) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: OutfitsGallery_ViewCell.identifier,
                    for: indexPath
                ) as! OutfitsGallery_ViewCell
                cell.delegate = self
                cell.configure(with: item)
                return cell
            }
        )
    }
    
    func applySnapshot(items: [Outfit], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Outfit>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    
    // MARK: --
    
    private lazy var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = "casual fit"
        //sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        return sb
    }()
    
    private lazy var galleryOutfitsView: UICollectionView = {
        let flayout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let numberOfItems = self.outfits[sectionIndex].clothing_ids.count
            var heightDimension = NSCollectionLayoutDimension.fractionalHeight(0.4)
            
            switch numberOfItems {
                case 1, 2:
                    heightDimension = NSCollectionLayoutDimension.fractionalHeight(0.4)
                case 3:
                    heightDimension = NSCollectionLayoutDimension.fractionalHeight(0.3)
                default:
                    heightDimension = NSCollectionLayoutDimension.fractionalHeight(0.2)
                }
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: heightDimension)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(OutfitsGallery_ViewCell.self, forCellWithReuseIdentifier: OutfitsGallery_ViewCell.identifier)
        cv.backgroundColor = .clear
        cv.delegate = self
        //cv.dataSource = self
        return cv
    }()
    
    // MARK: --
    
    private func loadUserOutfits() {
        Task {
            do {
                self.outfits = try await APIHandler.shared.outfitHandler.getMyOutfits(limit: 100, offset: 0).outfits
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        title = "outfits"
        
        navigationController?.navigationBar.prefersLargeTitles = false
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .automatic
        
        view.addSubview(galleryOutfitsView)
        galleryOutfitsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        galleryOutfitsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        galleryOutfitsView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5).isActive = true
        galleryOutfitsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5).isActive = true
        setupDataSource()
    }
}

//! MARK: -- USE FLOW DELEGATE


extension OutfitsGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OutfitsGallery_ViewCellDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfits.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    func didLoadImageSize(_ size: CGSize, for outfit: Outfit) {
        //imageSizes[outfit.outfit_id] = size
        // Layout invalidieren, damit UICollectionView neue Höhe berechnet
        //galleryOutfitsView.performBatchUpdates {
            //galleryOutfitsView.collectionViewLayout.invalidateLayout()
        //}
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch selectedViewMode {
        case .MEDIUM:
            return CGSize(width: (galleryOutfitsView.bounds.width / 2) - 7.5, height: CGFloat(galleryOutfitsView.bounds.height / CGFloat(2.5)))
        case .SMALL:
            return CGSize(width: (galleryOutfitsView.bounds.width / 3) - (20 / 3), height: CGFloat(galleryOutfitsView.bounds.height / CGFloat(3)))
        case .SINGLE:
            galleryOutfitsView.isPagingEnabled = true
            return CGSize(width: galleryOutfitsView.bounds.width, height: galleryOutfitsView.bounds.height)
        }
    
        var heightFraction = 5
        let itemCount = outfits[indexPath.item].clothing_ids.count
        
        switch itemCount {
        case 2:
            heightFraction = 3
        case 3:
            heightFraction = 4
        default:
            heightFraction = 5
        }
        
        return CGSize(width: (galleryOutfitsView.bounds.width / 2) - 7.5, height: CGFloat(galleryOutfitsView.bounds.height / CGFloat(2.5)))
    }
}
