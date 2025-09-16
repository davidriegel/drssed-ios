//
//  ClothesGalleryController.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit

class ClothesGalleryController: UIViewController {
    
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
        updateData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        uploadButton.layer.add(createUploadButtonHover(), forKey: "hoverAnimation")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.clothingCollectionView.flashScrollIndicators()
    }

    // MARK: --
    
    var dataSource: [ClothingAPI] = [] {
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
    
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Section, ClothingAPI> = UICollectionViewDiffableDataSource<Section, ClothingAPI>(
        collectionView: self.clothingCollectionView,
        cellProvider: { (collectionView: UICollectionView, indexPath: IndexPath, item: ClothingAPI) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothesGallery_ViewCell.identifier,
                for: indexPath
            ) as! ClothesGallery_ViewCell
            cell.configureViewComponents(with: item.image_id, and: item.name)
            return cell
        }
    )
    
    func applySnapshot(items: [ClothingAPI], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ClothingAPI>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    
    var sortedAndFilteredDataSource: [ClothingAPI] = [] {
        didSet {
            applySnapshot(items: sortedAndFilteredDataSource)
        }
    }
    
    var searchDataSource: [ClothingAPI] = [] {
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
    
    var clothingTypesSelected: clothingTypes? = nil {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var clothingSeasonsSelected: [clothingSeasons] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    var clothingTagsSelected: [clothingTags] = [] {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    enum sortOptions {
        case Name
        case Date
        case Edit
    }
    
    enum clothingTypes: CaseIterable {
        case Tops
        case Bottoms
        case Footwear
        case Accessoires
        
        static func withLabel(_ label: String) -> clothingTypes? {
            return self.allCases.first{ "\($0)" == label }
        }
    }
    
    enum clothingSeasons {
        case Spring
        case Summer
        case Autumn
        case Winter
    }
    
    enum clothingTags {
        case Casual
        case Formal
        case Sports
        case Vintage
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
        view.register(ClothesGallery_ViewCell.self, forCellWithReuseIdentifier: ClothesGallery_ViewCell.identifier)
        view.delegate = self
        view.showsVerticalScrollIndicator = true
        view.backgroundColor = .background
        view.isPagingEnabled = true
        view.decelerationRate = .fast
        return view
    }()
    
    lazy var clothingRefreshControll: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(updateData), for: .valueChanged)
        return rc
    }()
    
    lazy var typeStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .leading
        return sv
    }()
    
    lazy var typeScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isScrollEnabled = true
        sv.alwaysBounceHorizontal = true
        sv.showsHorizontalScrollIndicator = false
        return sv
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
    
    func showClothingDetails(of clothing: ClothingAPI) {
        let clothingController = ClothingDetailsController(clothing)
        clothingController.delegate = self
        present(clothingController, animated: true)
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
    
    func sortClothes(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        switch clothingSortSelected {
        case .Name:
            sortByName(source: source)
        case .Date:
            sortByDate(source: source)
        case .Edit:
            sortByEdit(source: source)
        }
    }
    
    private func sortByName(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        var tempSortedDataSource: [ClothingAPI] = source != nil ? source! : dataSource
        tempSortedDataSource.sort {
            return ($0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending)
        }
        
        return tempSortedDataSource
    }
    
    private func sortByDate(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        var tempSortedDataSource: [ClothingAPI] = source != nil ? source! : dataSource
        tempSortedDataSource.sort {
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-DD hh-mm-ss"
            //let first = formatter.date(from: $0.created_at) ?? Date()
            let first = $0.seasons.count
            let second = $1.seasons.count
            //let second = formatter.date(from: $1.created_at) ?? Date()
            return first > second
        }
        
        return tempSortedDataSource
    }
    
    // sortByEdit currently not available due to API, edits date not being saved to database
    private func sortByEdit(source _: [ClothingAPI]? = nil) -> [ClothingAPI] {
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
            UIAction(title: String(localized: "scale_small"), attributes: .keepsMenuPresented, state: selectedViewMode == .SMALL ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .SMALL
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "scale_medium"), attributes: .keepsMenuPresented, state: selectedViewMode == .MEDIUM ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .MEDIUM
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "scale_large"), attributes: .keepsMenuPresented, state: selectedViewMode == .LARGE ? .on : .mixed, handler: { _ in
                self.selectedViewMode = .LARGE
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            })
        ]
        
        return UIMenu(title: String(localized: "scale_menu_title"), children: scaleMenuItems)
    }
    
    func generateFilterMenu() -> UIMenu {
        let tagsMenuItems: [UIAction] = [
            UIAction(title: "🌱 Spring", attributes: .keepsMenuPresented, state: clothingSeasonsSelected.contains(.Spring) ? .on : .mixed, handler: { (_) in self.filterBySeason(.Spring) }),
            UIAction(title: "☀️ Summer", attributes: .keepsMenuPresented, state: clothingSeasonsSelected.contains(.Summer) ? .on : .mixed, handler: { (_) in self.filterBySeason(.Summer) }),
            UIAction(title: "🍂 Autumn", attributes: .keepsMenuPresented, state: clothingSeasonsSelected.contains(.Autumn) ? .on : .mixed, handler: { (_) in self.filterBySeason(.Autumn) }),
            UIAction(title: "❄️ Winter", attributes: .keepsMenuPresented, state: clothingSeasonsSelected.contains(.Winter) ? .on : .mixed, handler: { (_) in self.filterBySeason(.Winter) })
        ]
        
        let seasonsMenuItems: [UIAction] = [
            UIAction(title: "🧍🏻 Casual", attributes: .keepsMenuPresented, state: clothingTagsSelected.contains(.Casual) ? .on : .mixed, handler: { (_) in self.filterByTags(.Casual) }),
            UIAction(title: "🕴🏻 Formal", attributes: .keepsMenuPresented, state: clothingTagsSelected.contains(.Formal) ? .on : .mixed, handler: { (_) in self.filterByTags(.Formal) }),
            UIAction(title: "⛹🏻 Sports", attributes: .keepsMenuPresented, state: clothingTagsSelected.contains(.Sports) ? .on : .mixed, handler: { (_) in self.filterByTags(.Sports) }),
            UIAction(title: "🧳 Vintage", attributes: .keepsMenuPresented, state: clothingTagsSelected.contains(.Vintage) ? .on : .mixed, handler: { (_) in self.filterByTags(.Vintage) })
        ]
        
        var totalItems: [UIMenuElement] = []
        totalItems.append(UIMenu(title: "", options: .displayInline, children: tagsMenuItems))
        totalItems += seasonsMenuItems
        
        let menu = UIMenu(title: "Filter by", options: [], children: totalItems)
        return menu
    }
    
    func filterBySeason(_ seasonSelected: clothingSeasons) {
        clothingSeasonsSelected.contains(seasonSelected) ? clothingSeasonsSelected.removeAll(where: { season in
            return season == seasonSelected
        }) : clothingSeasonsSelected.append(seasonSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesSeason(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        let tempFilteredDataSource: [ClothingAPI] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!clothingSeasonsSelected.isEmpty) else {
                return true
            }
            
            return clothingSeasonsSelected.allSatisfy { clothing.seasons.contains("\($0)")}
        }
    }
    
    func filterByTags(_ tagSelected: clothingTags) {
        clothingTagsSelected.contains(tagSelected) ? clothingTagsSelected.removeAll(where: { season in
            return season == tagSelected
        }) : clothingTagsSelected.append(tagSelected)
        self.navigationItem.rightBarButtonItems?.first!.menu = generateFilterMenu()
    }
    
    func filterClothesTags(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        let tempFilteredDataSource: [ClothingAPI] = source != nil ? source! : dataSource
        
        return tempFilteredDataSource.filter { clothing in
            guard (!clothingTagsSelected.isEmpty) else {
                return true
            }
            
            return clothingTagsSelected.allSatisfy { clothing.tags.contains("\($0)")}
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
    
    func addTypeButtons() {
        for arrView in typeStackView.arrangedSubviews {
            typeStackView.removeArrangedSubview(arrView)
        }
    
        let allButton = UIButton()
        let attributedTitle = NSAttributedString(string: "All", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold)])
        allButton.setAttributedTitle(attributedTitle, for: .normal)
        allButton.setTitleColor(.label, for: .normal)
        allButton.layer.cornerRadius = ( view.frame.size.height / 20 ) / 2
        allButton.backgroundColor = .accent
        allButton.layer.shadowColor = UIColor.label.cgColor
        allButton.layer.shadowOpacity = 0.4
        allButton.layer.shadowRadius = 6
        allButton.layer.shadowOffset = CGSizeMake(6, 6)
        allButton.addTarget(self, action: #selector(typeButtonAction(_:)), for: .touchUpInside)
        
        typeStackView.addArrangedSubview(allButton)
        
        allButton.widthAnchor.constraint(greaterThanOrEqualToConstant: view.frame.size.width / 5).isActive = true
        allButton.heightAnchor.constraint(equalToConstant: view.frame.size.height / 20).isActive = true
        
        for type in clothingTypes.allCases {
            let typeButton = UIButton()
            let attributedTitle = NSAttributedString(string: "\(type)", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold)])
            typeButton.setAttributedTitle(attributedTitle, for: .normal)
            typeButton.setTitleColor(.secondaryLabel, for: .normal)
            typeButton.layer.cornerRadius = ( view.frame.size.height / 20 ) / 2
            typeButton.backgroundColor = .clear
            typeButton.layer.shadowColor = UIColor.label.cgColor
            typeButton.layer.shadowOpacity = 0.4
            typeButton.layer.shadowRadius = 6
            typeButton.layer.shadowOffset = CGSizeMake(6, 6)
            typeButton.addTarget(self, action: #selector(typeButtonAction(_:)), for: .touchUpInside)
            typeButton.isSelected = false
            typeButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10) // All buttons need to be configurated w. the UIButtonConfigurations due to deprecation in near future ()
            
            typeStackView.addArrangedSubview(typeButton)
            
            typeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: view.frame.size.width / 5).isActive = true
            typeButton.heightAnchor.constraint(equalToConstant: view.frame.size.height / 20).isActive = true
        }
        
        let spacing = UIView()
        spacing.backgroundColor = .clear
        
        typeStackView.addArrangedSubview(spacing)
        spacing.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        spacing.heightAnchor.constraint(equalToConstant: view.frame.size.height / 20).isActive = true
    }
    
    func filterClothesType(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        let tempFilteredDataSource: [ClothingAPI] = source != nil ? source! : dataSource
        let topsCategories: [String] = ["TOP", "T-Shirt", "Shirt", "Polo", "Sweater", "Hoodie", "Jacket", "Coat"]
        let bottomsCategories: [String] = ["BOTTOM", "Jeans", "Shorts", "Pants", "Skirt"]
        let footwearCategories: [String] = ["FOOTWEAR", "Sneakers", "Boots", "Sandals", "Heels", "Loafers"]
        let accessoriesCategories: [String] = ["ACCESSORIES", "Hat", "Scarf", "Gloves", "Belt", "Bag", "Watch", "Accessory"]
        
        return tempFilteredDataSource.filter { clothing in
            switch clothingTypesSelected {
            case .Tops:
                return topsCategories.contains(clothing.category.rawValue)
            case .Bottoms:
                return bottomsCategories.contains(clothing.category.rawValue)
            case .Footwear:
                return footwearCategories.contains(clothing.category.rawValue)
            case .Accessoires:
                return accessoriesCategories.contains(clothing.category.rawValue)
            case nil:
                return true
            }
        }
    }
    
    func sortAndFilterDataSource(source: [ClothingAPI]? = nil) -> [ClothingAPI] {
        let filterForTags: [ClothingAPI] = filterClothesTags(source: source != nil ? source! : dataSource)
        let filterForSeasons: [ClothingAPI] = filterClothesSeason(source: filterForTags)
        let filterForType: [ClothingAPI] = filterClothesType(source: filterForSeasons)
        let sortClothesBy: [ClothingAPI] = sortClothes(source: filterForType)
        return sortClothesBy
    }
    
    // MARK: --
    
    @objc
    func addClothingPiece() {
        let vc = UploadController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc
    func typeButtonAction(_ sender: UIButton) {
        for arrView in typeStackView.arrangedSubviews {
            guard let buttonView = arrView as? UIButton, buttonView != sender else { continue }
            
            UIView.animate(withDuration: 0.4) {
                buttonView.backgroundColor = .clear
                buttonView.setTitleColor(.secondaryLabel, for: .normal)
                buttonView.frame.origin.y = 0
            }
        }
        
        guard sender.frame.origin.y == 0 else {
            return
        }
        
        UIView.animate(withDuration: 0.4) {
            sender.setTitleColor(.label, for: .normal)
            sender.backgroundColor = .accent
            sender.frame.origin.y -= 5
        }
        
        guard let buttonTitle = sender.titleLabel?.text else { return }
        guard let type = clothingTypes.withLabel(buttonTitle) else { clothingTypesSelected = nil; return }
        clothingTypesSelected = type
    }
    
    @objc
    func updateData() {
        Task {
            //dataSource = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
            
            do {
                dataSource = try await APIHandler.shared.clothingHandler.getMyClothing(limit: 100, offset: 0).clothing
                
                if let encoded = try? JSONEncoder().encode(dataSource) {
                    UserDefaults.standard.setValue(encoded, forKey: "userClothes")
                }
            } catch {
                ErrorHandler.handle(error, suppressed: [.tooManyRequests])
            }
            
            clothingRefreshControll.endRefreshing()
        }
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), menu: generateScaleMenu())
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateFilterMenu()), UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateSortMenu())]
        
        view.addSubview(typeScrollView)
        typeScrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        typeScrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        typeScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        typeScrollView.heightAnchor.constraint(equalToConstant: view.frame.size.height / 10).isActive = true
        
        typeScrollView.addSubview(typeStackView)
        typeStackView.leadingAnchor.constraint(equalTo: typeScrollView.leadingAnchor).isActive = true
        typeStackView.trailingAnchor.constraint(equalTo: typeScrollView.trailingAnchor).isActive = true
        typeStackView.centerYAnchor.constraint(equalTo: typeScrollView.centerYAnchor).isActive = true
        typeStackView.heightAnchor.constraint(equalToConstant: view.frame.size.height / 20).isActive = true
        
        addTypeButtons()
        
        view.addSubview(clothingCollectionView)
        clothingCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        clothingCollectionView.bottomAnchor.constraint(equalTo: typeStackView.topAnchor, constant: -5).isActive = true
        clothingCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        clothingCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        clothingCollectionView.refreshControl = clothingRefreshControll
        
        view.addSubview(uploadButton)
        uploadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: typeScrollView.topAnchor, constant: -10).isActive = true
        
        clothingCollectionView.addSubview(uploadNowButton)
        NSLayoutConstraint.activate([
            uploadNowButton.centerXAnchor.constraint(equalTo: clothingCollectionView.centerXAnchor),
            uploadNowButton.topAnchor.constraint(equalTo: clothingCollectionView.topAnchor, constant: 20)
        ])
    }
}

extension ClothesGalleryController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UploadControllerDelegate, ClothingDetailsControllerDelegate {
    
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
    
    func didUploadClothing(_ clothing: ClothingAPI) {
        dataSource.insert(clothing, at: 0)
    }
    
    func didEditClothing(_ clothing: ClothingAPI) {
        guard var clothingArray = try? JSONDecoder().decode([ClothingAPI].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data()) else { return updateData() }
        
        let unsafeIndex = clothingArray.firstIndex { $0.clothing_id == clothing.clothing_id }
        guard let index = unsafeIndex else { return updateData() }
        clothingArray[index] = clothing
        
        dataSource = clothingArray
    }
    
    func didDeleteClothing(_ clothing: ClothingAPI) {
        guard var clothingArray = try? JSONDecoder().decode([ClothingAPI].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data()) else { return updateData() }
        
        let unsafeIndex = clothingArray.firstIndex { $0.clothing_id == clothing.clothing_id }
        guard let index = unsafeIndex else { return updateData() }
        clothingArray.remove(at: index)
        
        dataSource = clothingArray
    }
}
