//
//  OutfitsGalleryViewController.swift
//  Drssed
//
//  Created by David Riegel on 18.11.24.
//

import UIKit

class OutfitsGalleryViewController: UIViewController {
    private let outfitRepo: OutfitRepository = AppRepository.shared.outfitRepository
    
    private enum viewMode: CaseIterable {
        case SMALL
        case MEDIUM
        case LARGE
    }
    
    private var selectedViewMode: viewMode = .MEDIUM {
        didSet {
            outfitCollectionView.isPagingEnabled = (selectedViewMode == .LARGE)

            outfitCollectionView.performBatchUpdates({
                outfitCollectionView.collectionViewLayout.invalidateLayout()
            }, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
        reloadDataFromCoreData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataFromCoreData()
        createFABButton.layer.add(createUploadButtonHover(), forKey: "hoverAnimation")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.outfitCollectionView.flashScrollIndicators()
    }

    // MARK: --
    
    var dataSource: [Outfit] = [] {
        didSet {
            createFirstButton.isHidden = !dataSource.isEmpty
            createFirstButton.isEnabled = dataSource.isEmpty
            
            searchDataSource = dataSource
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    private enum Section {
        case main
    }
    
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Section, Outfit> = UICollectionViewDiffableDataSource<Section, Outfit>(
        collectionView: self.outfitCollectionView,
        cellProvider: { (collectionView: UICollectionView, indexPath: IndexPath, item: Outfit) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OutfitsGallery_ViewCell.identifier,
                for: indexPath
            ) as! OutfitsGallery_ViewCell
            cell.configure(with: item, title: item.name)
            return cell
        }
    )
    
    func applySnapshot(items: [Outfit], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Outfit>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    
    var sortedAndFilteredDataSource: [Outfit] = [] {
        didSet {
            applySnapshot(items: sortedAndFilteredDataSource)
        }
    }
    
    var searchDataSource: [Outfit] = [] {
        didSet {
            applySnapshot(items: searchDataSource)
        }
    }
    
    var isSearching: Bool = false
    let placeholders: [String] = ["hallo ich bin outfit"]
    
    var outfitSortSelected: sortOptions = .Date {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var outfitSeasonsSelected: [Seasons] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var outfitTagsSelected: [Tags] = [] {
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
    
    lazy var  outfitCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(OutfitsGallery_ViewCell.self, forCellWithReuseIdentifier: OutfitsGallery_ViewCell.identifier)
        cv.delegate = self
        cv.showsVerticalScrollIndicator = true
        cv.backgroundColor = .background
        cv.decelerationRate = .fast
        return cv
    }()
    
    lazy var outfitRefreshControll: UIRefreshControl = {
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
    
    lazy var createFABButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .bold))), for: .normal)
        bt.backgroundColor = .accent
        bt.tintColor = .label
        bt.addTarget(self, action: #selector(pushToOutfitCreation), for: .touchUpInside)
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
            let items = await AppRepository.shared.outfitRepository.fetchOutfits()
            dataSource = items
            outfitRefreshControll.endRefreshing()
        }
    }
    
    func showOutfitDetails(of outfit: Outfit) {
        let detailsController = OutfitDetailsController(outfit: outfit)
        detailsController.delegate = self
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
            UIAction(title: String(localized: "common.sort.name"), image: UIImage(systemName: "tshirt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), identifier: nil, discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: outfitSortSelected == .Name ? .on : .mixed, handler: { (_) in self.sortBy(.Name) }),
            UIAction(title: String(localized: "common.sort.date"), image: UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: outfitSortSelected == .Date ? .on : .mixed, handler: { (_) in self.sortBy(.Date) }),
            UIAction(title: String(localized: "common.sort.edit"), image: UIImage(systemName: "pencil.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: outfitSortSelected == .Edit ? .on : .mixed, handler: { (_) in self.sortBy(.Edit) })
        ]
        
        let menu = UIMenu(title: String(localized: "common.sort.menu"), image: nil, identifier: nil, options: [], children: menuItems)
        return menu
    }
    
    func sortBy(_ sortOption: sortOptions) {
        guard sortOption != outfitSortSelected else {
            return
        }
        
        outfitSortSelected = sortOption
        self.navigationItem.rightBarButtonItems?.last!.menu = generateSortMenu()
    }
    
    func sortClothes(source: [Outfit]? = nil) -> [Outfit] {
        switch outfitSortSelected {
        case .Name:
            sortByName(source: source)
        case .Date:
            sortByDate(source: source)
        case .Edit:
            sortByEdit(source: source)
        }
    }
    
    private func sortByName(source: [Outfit]? = nil) -> [Outfit] {
        var tempSortedDataSource: [Outfit] = source != nil ? source! : dataSource
        tempSortedDataSource.sort {
            return ($0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending)
        }
        
        return tempSortedDataSource
    }
    
    private func sortByDate(source: [Outfit]? = nil) -> [Outfit] {
        var tempSortedDataSource: [Outfit] = source != nil ? source! : dataSource
        tempSortedDataSource.sort { $0.createdAt > $1.createdAt }
        
        return tempSortedDataSource
    }
    
    private func sortByEdit(source: [Outfit]? = nil) -> [Outfit] {
        var tempSortedDataSource: [Outfit] = source != nil ? source! : dataSource
        tempSortedDataSource.sort { $0.updatedAt > $1.updatedAt }
        
        return tempSortedDataSource
    }
    
    lazy var createFirstButton: UIButton = {
        var btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        var attributedTitle = NSMutableAttributedString(string: "Seems like you don't have any outfits yet..?\n", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.secondaryLabel])
        let callToAction = NSAttributedString(string: "Create your first outfit now!", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .heavy), .foregroundColor: UIColor.label])
        attributedTitle.append(NSAttributedString(attributedString: callToAction))
        btn.setAttributedTitle(attributedTitle, for: .normal)
        btn.isHidden = true
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(pushToOutfitCreation), for: .touchUpInside)
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
            UIAction(title: "🌱 " + Seasons.SPRING.localizedName, attributes: .keepsMenuPresented, state: outfitSeasonsSelected.contains(.SPRING) ? .on : .mixed, handler: { (_) in self.filterBySeason(.SPRING) }),
            UIAction(title: "☀️ " + Seasons.SUMMER.localizedName, attributes: .keepsMenuPresented, state: outfitSeasonsSelected.contains(.SUMMER) ? .on : .mixed, handler: { (_) in self.filterBySeason(.SUMMER) }),
            UIAction(title: "🍂 " + Seasons.AUTUMN.localizedName, attributes: .keepsMenuPresented, state: outfitSeasonsSelected.contains(.AUTUMN) ? .on : .mixed, handler: { (_) in self.filterBySeason(.AUTUMN) }),
            UIAction(title: "❄️ " + Seasons.WINTER.localizedName, attributes: .keepsMenuPresented, state: outfitSeasonsSelected.contains(.WINTER) ? .on : .mixed, handler: { (_) in self.filterBySeason(.WINTER) })
        ]
        
        let seasonsMenuItems: [UIAction] = [
            UIAction(title: "🧍🏻 " + Tags.CASUAL.localizedName, attributes: .keepsMenuPresented, state: outfitTagsSelected.contains(.CASUAL) ? .on : .mixed, handler: { (_) in self.filterByTags(.CASUAL) }),
            UIAction(title: "🕴🏻 " + Tags.FORMAL.localizedName, attributes: .keepsMenuPresented, state: outfitTagsSelected.contains(.FORMAL) ? .on : .mixed, handler: { (_) in self.filterByTags(.FORMAL) }),
            UIAction(title: "⛹🏻 " + Tags.SPORTS.localizedName, attributes: .keepsMenuPresented, state: outfitTagsSelected.contains(.SPORTS) ? .on : .mixed, handler: { (_) in self.filterByTags(.SPORTS) }),
            UIAction(title: "🧳 " + Tags.VINTAGE.localizedName, attributes: .keepsMenuPresented, state: outfitTagsSelected.contains(.VINTAGE) ? .on : .mixed, handler: { (_) in self.filterByTags(.VINTAGE) })
        ]
        
        var totalItems: [UIMenuElement] = []
        totalItems.append(UIMenu(title: "", options: .displayInline, children: tagsMenuItems))
        totalItems += seasonsMenuItems
        
        let menu = UIMenu(title: String(localized: "common.filter.menu"), options: [], children: totalItems)
        return menu
    }
    
    func filterBySeason(_ seasonSelected: Seasons) {
        outfitSeasonsSelected.contains(seasonSelected) ? outfitSeasonsSelected.removeAll(where: { season in
            return season == seasonSelected
        }) : outfitSeasonsSelected.append(seasonSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesSeason(source: [Outfit]? = nil) -> [Outfit] {
        let tempFilteredDataSource: [Outfit] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!outfitSeasonsSelected.isEmpty) else {
                return true
            }
            
            return outfitSeasonsSelected.allSatisfy { clothing.seasons.contains($0)}
        }
    }
    
    func filterByTags(_ tagSelected: Tags) {
        outfitTagsSelected.contains(tagSelected) ? outfitTagsSelected.removeAll(where: { season in
            return season == tagSelected
        }) : outfitTagsSelected.append(tagSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesTags(source: [Outfit]? = nil) -> [Outfit] {
        let tempFilteredDataSource: [Outfit] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!outfitTagsSelected.isEmpty) else {
                return true
            }
            
            return outfitTagsSelected.allSatisfy { clothing.tags.contains($0)}
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
        createFABButton.layer.removeAllAnimations()
        
        let hover = CABasicAnimation(keyPath: "position")
            
        hover.isAdditive = true
        hover.fromValue = NSValue(cgPoint: CGPoint.zero)
        hover.toValue = NSValue(cgPoint: CGPoint(x: 0.0, y: 10.0))
        hover.autoreverses = true
        hover.duration = 2
        hover.repeatCount = Float.infinity
        
        return hover
    }
    
    func sortAndFilterDataSource(source: [Outfit]? = nil) -> [Outfit] {
        let filterForTags: [Outfit] = filterClothesTags(source: source != nil ? source! : dataSource)
        let filterForSeasons: [Outfit] = filterClothesSeason(source: filterForTags)
        let sortClothesBy: [Outfit] = sortClothes(source: filterForSeasons)
        return sortClothesBy
    }
    
    // MARK: --
    
    @objc
    func pushToOutfitCreation() {
        let vc = OutfitComposerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = String(localized: "lookbook.title")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .automatic
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateScaleMenu())
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateFilterMenu()), UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateSortMenu())]
        
        view.addSubview(outfitCollectionView)
        outfitCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        outfitCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        outfitCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        outfitCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        outfitCollectionView.refreshControl = outfitRefreshControll
        
        view.addSubview(createFABButton)
        createFABButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        createFABButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
        outfitCollectionView.addSubview(createFirstButton)
        NSLayoutConstraint.activate([
            createFirstButton.centerXAnchor.constraint(equalTo: outfitCollectionView.centerXAnchor),
            createFirstButton.topAnchor.constraint(equalTo: outfitCollectionView.topAnchor, constant: 20)
        ])
    }
}

extension OutfitsGalleryViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, OutfitDetailsDelegate {
    func didUpdateOutfit() {
        reloadDataFromCoreData()
    }
    
    func didDeleteOutfit() {
        reloadDataFromCoreData()
    }
    
    
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
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let collectionWidth = collectionView.bounds.width
        let spacing: CGFloat = 10

        switch selectedViewMode {
        case .SMALL:
            let columns: CGFloat = 3
            let totalSpacing = spacing * (columns - 1)
            let itemWidth = (collectionWidth - totalSpacing) / columns
            let itemHeight = itemWidth * 1.25 // 4:5
            return CGSize(width: itemWidth, height: itemHeight)

        case .MEDIUM:
            let columns: CGFloat = 2
            let totalSpacing = spacing * (columns - 1)
            let itemWidth = (collectionWidth - totalSpacing) / columns
            let itemHeight = itemWidth * 1.25
            return CGSize(width: itemWidth, height: itemHeight)

        case .LARGE:
            let columns: CGFloat = 1
            let totalSpacing = spacing * (columns - 1)
            let itemWidth = (collectionWidth - totalSpacing) / columns
            let itemHeight = itemWidth * 1.25
            return CGSize(width: itemWidth, height: itemHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showOutfitDetails(of: isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource[indexPath.item])
    }
}
