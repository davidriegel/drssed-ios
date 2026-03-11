//
//  OutfitCreator+PickerController.swift
//  Drssed
//
//  Created by David Riegel on 21.09.25.
//

import UIKit

protocol OutfitComposerViewController_PickerDelegate: AnyObject {
    func didSelectClothing(_ clothing: Clothing)
    func didDeselectClothing(_ clothing: Clothing)
}

class OutfitComposerViewController_Picker: UIViewController {
    
    private var delegate: OutfitComposerViewController_PickerDelegate
    private let clothingRepo: ClothingRepository = ClothingRepository()
    
    private var selectedClothingIDs: Set<Clothing.ID> = []
    
    private enum viewMode: CaseIterable {
        case LARGE
        case MEDIUM
        case SMALL
    }
    
    private var selectedViewMode: viewMode = .MEDIUM {
        didSet {
            clothingCollectionView.performBatchUpdates({
                clothingCollectionView.collectionViewLayout.invalidateLayout()
            }, completion: nil)

        }
    }
    
    private let categoryLimits: [ClothingCategories: Int] = [
        .FOOTWEAR: 1,
        .BOTTOM: 1,
        .TOP: 2,
        .JACKET: 1
    ]
    
    init(delegate: OutfitComposerViewController_PickerDelegate) {
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        loadDataFromCoreData()
    }
    
    var dataSource: [Clothing] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
//            uploadNowButton.isHidden = !dataSource.isEmpty
//            uploadNowButton.isEnabled = dataSource.isEmpty
            
            //searchDataSource = dataSource
            //sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    func sortAndFilterDataSource(source: [Clothing]? = nil) -> [Clothing] {
        /*let filterForTags: [Clothing] = filterClothesTags(source: source != nil ? source! : dataSource)
        let filterForSeasons: [Clothing] = filterClothesSeason(source: filterForTags)*/
        let filterForCategory: [Clothing] = filterClotheCategory(source: source)
        /*
        let sortClothesBy: [Clothing] = sortClothes(source: filterForType)*/
        return filterForCategory
    }
    
    func filterClotheCategory(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource
        guard let clothingType = filterClothingCategory else { return tempFilteredDataSource }
        
        return tempFilteredDataSource.filter { $0.category == clothingType }
    }
    
    var sortedAndFilteredDataSource: [Clothing] = [] {
        didSet {
            applySnapshot(items: sortedAndFilteredDataSource)
        }
    }
    
    var searchDataSource: [Clothing] = [] {
        didSet {
            applySnapshot(items: searchDataSource)
        }
    }
    
    var filterClothingCategory: ClothingCategories? = nil {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    private enum Section {
        case main
    }
    
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Section, Clothing> = UICollectionViewDiffableDataSource<Section, Clothing>(
        collectionView: self.clothingCollectionView,
        cellProvider: { (collectionView: UICollectionView, indexPath: IndexPath, item: Clothing) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCollectionViewCell.identifier,
                for: indexPath
            ) as! ClothingCollectionViewCell
            cell.configureViewComponents(with: item.imageID, and: item.name, isSelectable: true)
            return cell
        }
    )
    
    func applySnapshot(items: [Clothing], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Clothing>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            guard let self = self else { return }
            self.restoreSelection()
        }
    }
    
    var isSearching: Bool = false
    
    lazy var categorySegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [String(localized: "common.all"), ClothingCategories.JACKET.localizedName, ClothingCategories.TOP.localizedName, ClothingCategories.BOTTOM.localizedName, ClothingCategories.FOOTWEAR.localizedName])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.tintColor = .secondarySystemBackground
        sc.selectedSegmentTintColor = .accent
        return sc
    }()
    
    lazy var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = String(localized: "searchbar.clothes.placeholder")
        sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        sb.editButtonItem.tintColor = .green // nichts
        sb.searchBar.barTintColor = .blue // nichts
        //sb.searchBar.backgroundColor = .red
        sb.searchBar.tintColor = .yellow // nichts
        return sb
    }()

    lazy var clothingCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let view =  UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.scrollsToTop = true
        view.allowsMultipleSelection = true
        view.register(ClothingCollectionViewCell.self, forCellWithReuseIdentifier: ClothingCollectionViewCell.identifier)
        view.delegate = self
        view.showsVerticalScrollIndicator = true
        view.backgroundColor = .background
        view.decelerationRate = .fast
        return view
    }()
    
    lazy var clothingRefreshControll: UIRefreshControl = {
        let rc = UIRefreshControl()
    
        rc.addAction(UIAction(handler: { _ in
            Task {
                await SyncManager.shared.syncWithServer()
                
                DispatchQueue.main.async {
                    self.loadDataFromCoreData()
                }
            }
        }), for: .valueChanged)
        
        return rc
    }()
    
    private func loadDataFromCoreData() {
        Task { @MainActor in
            dataSource = await AppRepository.shared.clothingRepository.fetchClothes()
            clothingRefreshControll.endRefreshing()
        }
    }
    
    private func restoreSelection() {
        let snapshot = diffableDataSource.snapshot()
        
        for clothing in snapshot.itemIdentifiers {
            guard selectedClothingIDs.contains(clothing.id) else { continue }
            
            if let indexPath = diffableDataSource.indexPath(for: clothing) {
                clothingCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    func canSelect(_ item: Clothing) -> Bool {
        guard let max = categoryLimits[item.category] else {
            return true
        }

        let count = selectedClothingIDs
            .compactMap { id in dataSource.first(where: { $0.id == id }) }
            .filter { $0.category == item.category }
            .count

        return count < max
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = String(localized: "wardrobe.title")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(categorySegmentControl)
        NSLayoutConstraint.activate([
            categorySegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categorySegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categorySegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
            //categorySegmentControl.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        categorySegmentControl.addAction(UIAction { _ in
            switch self.categorySegmentControl.selectedSegmentIndex {
            case 1:
                self.filterClothingCategory = .JACKET
            case 2:
                self.filterClothingCategory = .TOP
            case 3:
                self.filterClothingCategory = .BOTTOM
            case 4:
                self.filterClothingCategory = .FOOTWEAR
            default:
                self.filterClothingCategory = nil
            }
        }, for: .valueChanged)
        
        view.addSubview(clothingCollectionView)
        NSLayoutConstraint.activate([
            clothingCollectionView.topAnchor.constraint(equalTo: categorySegmentControl.bottomAnchor, constant: 20),
            clothingCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            clothingCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            clothingCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5)
        ])
        clothingCollectionView.refreshControl = clothingRefreshControll

        //clothingCollectionView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
        //clothingCollectionView.scrollIndicatorInsets = clothingCollectionView.contentInset
    }
    
    func levenshteinDistance(_ string1: String, _ string2: String) -> Int {
        let s1 = Array(string1)
        let s2 = Array(string2)
        
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var previous = empty
        var current = empty
        
        
        for i in 0...s2.count {
            previous[i] = i
        }
        
        
        for i in 1...s1.count {
            current[0] = i
            for j in 1...s2.count {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,           // Einfügen
                    current[j - 1] + 1,        // Löschen
                    previous[j - 1] + cost     // Ersetzen
                )
            }
            previous = current
        }
        
        return current[s2.count]
    }
}


extension OutfitComposerViewController_Picker: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.lowercased(), !query.isEmpty else {
            isSearching = false
            searchDataSource = sortedAndFilteredDataSource
            return
        }
        
        isSearching = true
        
        searchDataSource = sortedAndFilteredDataSource.filter { clothingPiece in
            let name = clothingPiece.name.lowercased()
            return name.hasPrefix(query) || name.contains(query)
        }
        
        if searchDataSource.isEmpty {
            let fuzzyMatches = sortedAndFilteredDataSource.filter { clothingPiece in
                let name = clothingPiece.name.lowercased()
                let distance = levenshteinDistance(name, query)
                return distance <= 2
            }
            
            if !fuzzyMatches.isEmpty {
                searchDataSource = fuzzyMatches
            }
        }
        
        searchDataSource.sort {
            let nameA = $0.name.lowercased()
            let nameB = $1.name.lowercased()
            
            if nameA == query { return true }
            if nameB == query { return false }
            if nameA.hasPrefix(query) { return true }
            if nameB.hasPrefix(query) { return false }
            if nameA.contains(query) { return true }
            if nameB.contains(query) { return false }
            
            let distanceA = levenshteinDistance(nameA, query)
            let distanceB = levenshteinDistance(nameB, query)
            return distanceA < distanceB
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var columns: CGFloat = 4
        
        switch selectedViewMode {
        case .SMALL:
            columns = 4
        case .MEDIUM:
            columns = 3
        case .LARGE:
            columns = 2
        }
         
        let horizontalSpacing: CGFloat = 10
            
        let totalHorizontalSpacing = (columns - 1) * horizontalSpacing
            
        let availableWidth = collectionView.bounds.width - totalHorizontalSpacing
            
        let itemWidth = availableWidth / columns
            
        return CGSize(width: floor(itemWidth), height: floor(itemWidth))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let clothing = isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource[indexPath.item]
        
        if !canSelect(clothing) {
            collectionView.deselectItem(at: indexPath, animated: true)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        selectedClothingIDs.insert(clothing.id)
        delegate.didSelectClothing(clothing)
        
        /*
        self.sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.selectedDetentIdentifier = .init("small")
        }*/
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let clothing = isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource[indexPath.item]
        selectedClothingIDs.remove(clothing.id)
        delegate.didDeselectClothing(clothing)
        
        /*
        self.sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.selectedDetentIdentifier = .init("small")
        }
         */
    }
}
