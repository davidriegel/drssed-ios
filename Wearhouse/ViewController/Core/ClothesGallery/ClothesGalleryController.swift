//
//  ClothesGalleryController.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit

class ClothesGalleryController: UIViewController {
    private let clothingRepo: ClothingRepository = AppRepository.shared.clothingRepository
    
    private enum viewMode: CaseIterable {
        case SMALL
        case MEDIUM
        case LARGE
    }
    
    private var selectedViewMode: viewMode = .MEDIUM {
        didSet {
            clothingCollectionView.performBatchUpdates({
                clothingCollectionView.collectionViewLayout.invalidateLayout()
            }, completion: nil)

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
        reloadDataFromCoreData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onClothingChanged), name: .clothingUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onClothingChanged), name: .clothingDeleted, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataFromCoreData()
        uploadButton.layer.add(createUploadButtonHover(), forKey: "hoverAnimation")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.clothingCollectionView.flashScrollIndicators()
    }

    // MARK: --
    
    var dataSource: [Clothing] = [] {
        didSet {
            uploadNowButton.isHidden = !dataSource.isEmpty
            uploadNowButton.isEnabled = dataSource.isEmpty
            
            searchDataSource = dataSource
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
            cell.configureViewComponents(with: item.imageID, and: item.name)
            return cell
        }
    )
    
    func applySnapshot(items: [Clothing], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Clothing>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
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
    
    var isSearching: Bool = false
    let placeholders: [String] = ["super cool t-shirt", "fav hoodie", "zipper"]
    
    var clothingSortSelected: sortOptions = .Date {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var selectedCategory: ClothingCategories? = nil {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var selectedSeasons: [Seasons] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var selectedTags: [Tags] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    enum sortOptions {
        case Name
        case Date
        case Edit
    }
    
    // MARK: --
    
    lazy var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = placeholders.randomElement()
        sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        return sb
    }()
    
    lazy var  clothingCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let view =  UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.scrollsToTop = true
        view.register(ClothingCollectionViewCell.self, forCellWithReuseIdentifier: ClothingCollectionViewCell.identifier)
        view.delegate = self
        view.showsVerticalScrollIndicator = true
        view.backgroundColor = .background
        view.isPagingEnabled = true
        view.decelerationRate = .fast
        return view
    }()
    
    lazy var clothingRefreshControll: UIRefreshControl = {
        let rc = UIRefreshControl()
    
        rc.addAction(UIAction(handler: { _ in
            Task {
                await SyncManager.shared.syncWithServer()
                
                DispatchQueue.main.async {
                    self.reloadDataFromCoreData()
                }
            }
        }), for: .valueChanged)
        
        return rc
    }()
    
    lazy var categorySegmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [String(localized: "common.all"), ClothingCategories.JACKET.localizedName, ClothingCategories.TOP.localizedName, ClothingCategories.BOTTOM.localizedName, ClothingCategories.FOOTWEAR.localizedName])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.tintColor = .secondarySystemBackground
        sc.selectedSegmentTintColor = .accent
        return sc
    }()
    
    lazy var uploadButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .bold))), for: .normal)
        bt.backgroundColor = .accent
        bt.tintColor = .label
        bt.addTarget(self, action: #selector(addClothingPiece), for: .touchUpInside)
        bt.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 14).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.bounds.height / 14).isActive = true
        bt.layer.cornerRadius = (self.view.bounds.height / 14) / 2
        bt.layer.shadowColor = UIColor.label.cgColor
        bt.layer.shadowOpacity = 0.4
        bt.layer.shadowRadius = 6
        bt.layer.shadowOffset = CGSizeMake(6, 6)
        return bt
    }()
    
    // MARK: --
    
    func reloadDataFromCoreData() {
        Task { @MainActor in
            let items = await AppRepository.shared.clothingRepository.fetchClothes()
            dataSource = items
            clothingRefreshControll.endRefreshing()
        }
    }
    
    func showClothingDetails(of clothing: Clothing) {
        let detailsController = DetailsController(clothing)
        let navController = UINavigationController(rootViewController: detailsController)
        navController.setNavigationBarHidden(true, animated: false)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        navigationController?.present(navController, animated: true)
        
    }
    
    func generateSortMenu() -> UIMenu {
        let menuItems: [UIAction] = [
            UIAction(title: "Name", image: UIImage(systemName: "tshirt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), identifier: nil, discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Name ? .on : .mixed, handler: { (_) in self.sortBy(.Name) }),
            UIAction(title: "Date added", image: UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Date ? .on : .mixed, handler: { (_) in self.sortBy(.Date) }),
            UIAction(title: "Recently edited (wip)", image: UIImage(systemName: "pencil.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Edit ? .on : .mixed, handler: { (_) in self.sortBy(.Edit) })
        ]
        
        let menu = UIMenu(title: "Sort by (descending)", image: nil, identifier: nil, options: [], children: menuItems)
        return menu
    }
    
    func sortBy(_ sortOption: sortOptions) {
        guard sortOption != clothingSortSelected else {
            return
        }
        
        clothingSortSelected = sortOption
        self.navigationItem.rightBarButtonItems?.last!.menu = generateSortMenu()
    }
    
    func sortClothes(source: [Clothing]? = nil) -> [Clothing] {
        switch clothingSortSelected {
        case .Name:
            sortByName(source: source)
        case .Date:
            sortByDate(source: source)
        case .Edit:
            sortByEdit(source: source)
        }
    }
    
    private func sortByName(source: [Clothing]? = nil) -> [Clothing] {
        var tempSortedDataSource: [Clothing] = source != nil ? source! : dataSource
        tempSortedDataSource.sort {
            return ($0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending)
        }
        
        return tempSortedDataSource
    }
    
    private func sortByDate(source: [Clothing]? = nil) -> [Clothing] {
        var tempSortedDataSource: [Clothing] = source != nil ? source! : dataSource
        tempSortedDataSource.sort { $0.createdAt > $1.createdAt }
        
        return tempSortedDataSource
    }
    
    // sortByEdit currently not available due to API, edits date not being saved to database
    private func sortByEdit(source _: [Clothing]? = nil) -> [Clothing] {
        return dataSource
    }
    
    lazy var uploadNowButton: UIButton = {
        var btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        var attributedTitle = NSMutableAttributedString(string: "Seems like you have uploaded nothing yet..?\n", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.secondaryLabel])
        let callToAction = NSAttributedString(string: "Upload your first clothing piece now!", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .heavy), .foregroundColor: UIColor.label])
        attributedTitle.append(NSAttributedString(attributedString: callToAction))
        btn.setAttributedTitle(attributedTitle, for: .normal)
        btn.isHidden = true
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(addClothingPiece), for: .touchUpInside)
        return btn
    }()
    
    func generateScaleMenu() -> UIMenu {
        let scaleMenuItems: [UIAction] = [
            UIAction(title: String(localized: "common.scale.small"), attributes: .keepsMenuPresented, state: selectedViewMode == .SMALL ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .SMALL
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "common.scale.medium"), attributes: .keepsMenuPresented, state: selectedViewMode == .MEDIUM ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .MEDIUM
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "common.scale.large"), attributes: .keepsMenuPresented, state: selectedViewMode == .LARGE ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .LARGE
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            })
        ]
        
        return UIMenu(title: String(localized: "common.scale.title"), children: scaleMenuItems)
    }
    
    func generateFilterMenu() -> UIMenu {
        let tagsMenuItems: [UIAction] = [
            UIAction(title: "🌱 Spring", attributes: .keepsMenuPresented, state: selectedSeasons.contains(.SPRING) ? .on : .mixed, handler: { (_) in self.filterBySeason(.SPRING) }),
            UIAction(title: "☀️ Summer", attributes: .keepsMenuPresented, state: selectedSeasons.contains(.SUMMER) ? .on : .mixed, handler: { (_) in self.filterBySeason(.SUMMER) }),
            UIAction(title: "🍂 Autumn", attributes: .keepsMenuPresented, state: selectedSeasons.contains(.AUTUMN) ? .on : .mixed, handler: { (_) in self.filterBySeason(.AUTUMN) }),
            UIAction(title: "❄️ Winter", attributes: .keepsMenuPresented, state: selectedSeasons.contains(.WINTER) ? .on : .mixed, handler: { (_) in self.filterBySeason(.WINTER) })
        ]
        
        let seasonsMenuItems: [UIAction] = [
            UIAction(title: "🧍🏻 Casual", attributes: .keepsMenuPresented, state: selectedTags.contains(.CASUAL) ? .on : .mixed, handler: { (_) in self.filterByTags(.CASUAL) }),
            UIAction(title: "🕴🏻 Formal", attributes: .keepsMenuPresented, state: selectedTags.contains(.FORMAL) ? .on : .mixed, handler: { (_) in self.filterByTags(.FORMAL) }),
            UIAction(title: "⛹🏻 Sports", attributes: .keepsMenuPresented, state: selectedTags.contains(.SPORTS) ? .on : .mixed, handler: { (_) in self.filterByTags(.SPORTS) }),
            UIAction(title: "🧳 Vintage", attributes: .keepsMenuPresented, state: selectedTags.contains(.VINTAGE) ? .on : .mixed, handler: { (_) in self.filterByTags(.VINTAGE) })
        ]
        
        var totalItems: [UIMenuElement] = []
        totalItems.append(UIMenu(title: "", options: .displayInline, children: tagsMenuItems))
        totalItems += seasonsMenuItems
        
        let menu = UIMenu(title: "Filter by", options: [], children: totalItems)
        return menu
    }
    
    func filterBySeason(_ seasonSelected: Seasons) {
        selectedSeasons.contains(seasonSelected) ? selectedSeasons.removeAll(where: { season in
            return season == seasonSelected
        }) : selectedSeasons.append(seasonSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesSeason(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!selectedSeasons.isEmpty) else {
                return true
            }
            
            return selectedSeasons.allSatisfy { clothing.seasons.contains($0)}
        }
    }
    
    func filterByTags(_ tagSelected: Tags) {
        selectedTags.contains(tagSelected) ? selectedTags.removeAll(where: { season in
            return season == tagSelected
        }) : selectedTags.append(tagSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesTags(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!selectedTags.isEmpty) else {
                return true
            }
            
            return selectedTags.allSatisfy { clothing.tags.contains($0)}
        }
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
    
    func createUploadButtonHover() -> CABasicAnimation {
        uploadButton.layer.removeAllAnimations()
        
        let hover = CABasicAnimation(keyPath: "position")
            
        hover.isAdditive = true
        hover.fromValue = NSValue(cgPoint: CGPoint.zero)
        hover.toValue = NSValue(cgPoint: CGPoint(x: 0.0, y: 10.0))
        hover.autoreverses = true
        hover.duration = 2
        hover.repeatCount = Float.infinity
        
        return hover
    }
    
    func filterClothesType(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource
        guard let clothingType = selectedCategory else { return tempFilteredDataSource }
        
        return tempFilteredDataSource.filter { $0.category == clothingType }
    }
    
    func sortAndFilterDataSource(source: [Clothing]? = nil) -> [Clothing] {
        let filterForTags: [Clothing] = filterClothesTags(source: source != nil ? source! : dataSource)
        let filterForSeasons: [Clothing] = filterClothesSeason(source: filterForTags)
        let filterForType: [Clothing] = filterClothesType(source: filterForSeasons)
        let sortClothesBy: [Clothing] = sortClothes(source: filterForType)
        return sortClothesBy
    }
    
    // MARK: --
    
    @objc
    func addClothingPiece() {
        let vc = UploadController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onClothingChanged() {
        reloadDataFromCoreData()
    }
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = String(localized: "wardrobe.title")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .automatic
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateScaleMenu())
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateFilterMenu()), UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateSortMenu())]
        
        view.addSubview(categorySegmentControl)
        NSLayoutConstraint.activate([
            categorySegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categorySegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categorySegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        categorySegmentControl.addAction(UIAction { _ in
            switch self.categorySegmentControl.selectedSegmentIndex {
            case 1:
                self.selectedCategory = .JACKET
            case 2:
                self.selectedCategory = .TOP
            case 3:
                self.selectedCategory = .BOTTOM
            case 4:
                self.selectedCategory = .FOOTWEAR
            default:
                self.selectedCategory = nil
            }
        }, for: .valueChanged)
        
        view.addSubview(clothingCollectionView)
        clothingCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        clothingCollectionView.topAnchor.constraint(equalTo: categorySegmentControl.bottomAnchor, constant: 20).isActive = true
        clothingCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        clothingCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        clothingCollectionView.refreshControl = clothingRefreshControll
        
        view.addSubview(uploadButton)
        uploadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
        clothingCollectionView.addSubview(uploadNowButton)
        NSLayoutConstraint.activate([
            uploadNowButton.centerXAnchor.constraint(equalTo: clothingCollectionView.centerXAnchor),
            uploadNowButton.topAnchor.constraint(equalTo: clothingCollectionView.topAnchor, constant: 20)
        ])
    }
}

extension ClothesGalleryController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UploadControllerDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.lowercased(), !query.isEmpty else {
            isSearching = false
            searchDataSource = dataSource
            return
        }
        
        isSearching = true
        
        searchDataSource = dataSource.filter { clothingPiece in
            let name = clothingPiece.name.lowercased()
            return name.hasPrefix(query) || name.contains(query)
        }
        
        if searchDataSource.isEmpty {
            let fuzzyMatches = dataSource.filter { clothingPiece in
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
        showClothingDetails(of: isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource[indexPath.item])
    }
    
    func didUploadClothing(_ clothing: Clothing) {
        reloadDataFromCoreData()
    }
}
