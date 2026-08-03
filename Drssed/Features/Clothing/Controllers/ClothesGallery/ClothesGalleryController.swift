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

        NotificationCenter.default.addObserver(self, selector: #selector(onClothingChanged), name: .syncDidFinish, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDataFromCoreData()
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
    
    var dataSourceByID: [String: Clothing] = [:]
    
    private enum Section {
        case main
    }
    
    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Section, String> = UICollectionViewDiffableDataSource<Section, String>(
        collectionView: self.clothingCollectionView,
        cellProvider: { [weak self] (collectionView: UICollectionView, indexPath: IndexPath, item: String) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ClothingCollectionViewCell.identifier,
                for: indexPath
            ) as! ClothingCollectionViewCell
            guard let self, let clothing = self.dataSourceByID[item] else { return cell }
            cell.configureViewComponents(with: clothing.imageID, and: clothing.name)
            return cell
        }
    )
    
    func applySnapshot(items: [Clothing], animatingDifferences: Bool = true) {
        self.dataSourceByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items.map(\.id), toSection: .main)
        diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func reconfigure(clothingIDs: [String], animatingDifferences: Bool = false) {
        var snapshot = diffableDataSource.snapshot()
        let validIDs = clothingIDs.filter { snapshot.itemIdentifiers.contains($0) }
        guard !validIDs.isEmpty else { return }
        snapshot.reconfigureItems(validIDs)
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
    let placeholders: [String] = [String(localized: "wardrobe.search.placeholder")]
    
    var clothingSortSelected: sortOptions = .Date {
        didSet {
            sortedAndFilteredDataSource = sortAndFilterDataSource(source: dataSource)
        }
    }
    
    struct WardrobeFilter {
        var topLevel: ClothingCategories? = nil
        var subCategory: ClothingSubCategories? = nil
    }

    var wardrobeFilter = WardrobeFilter() {
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
    
    lazy var navSortButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateSortMenu())
        return button
    }()
    
    lazy var navFilterButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateFilterMenu())
        return button
    }()
    
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
    
        rc.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }

            Task {
                let didSync = await SyncManager.shared.syncWithServer()
                
                DispatchQueue.main.async {
                    self.reloadDataFromCoreData()

                    if !didSync {
                        ToastPresenter.error(String(localized: "sync.failed"))
                    }
                }
            }
        }), for: .valueChanged)
        
        return rc
    }()
    
    private let categoryOrder: [ClothingCategories] = [.JACKET, .TOP, .BOTTOM, .ONE_PIECE]

    lazy var categorySegmentControl: UISegmentedControl = {
        var items: [String] = [String(localized: "common.all")]
        items.append(contentsOf: categoryOrder.map { $0.localizedName })
        let sc = UISegmentedControl(items: items)
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.tintColor = .secondarySystemBackground
        sc.selectedSegmentTintColor = .accent
        return sc
    }()

    lazy var subCategoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.register(SubCategoryFilterCell.self, forCellWithReuseIdentifier: SubCategoryFilterCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.isHidden = true
        cv.alpha = 0
        cv.heightAnchor.constraint(equalToConstant: SubCategoryFilterCell.height).isActive = true
        return cv
    }()

    lazy var filterStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [categorySegmentControl, subCategoryCollectionView])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        return sv
    }()

    /// nil → "All", non-nil → specific sub-category
    private var subCategoryItems: [ClothingSubCategories?] = []
    private var selectedSubCategoryIndex: Int = 0
    
    lazy var uploadButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.backgroundColor = .clear
        bt.configuration = .prominentGlass()
        bt.configuration?.baseBackgroundColor = .accent
        bt.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .bold))), for: .normal)
        bt.configuration?.baseForegroundColor = .label
        bt.addTarget(self, action: #selector(addClothingPiece), for: .touchUpInside)
        bt.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 14).isActive = true
        bt.widthAnchor.constraint(equalToConstant: self.view.bounds.height / 14).isActive = true
        bt.layer.cornerRadius = (self.view.bounds.height / 14) / 2
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
    
    private func clothing(at indexPath: IndexPath) -> Clothing? {
        guard let id = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        return dataSourceByID[id]
    }

    func showClothingDetails(of clothing: Clothing) {
        let detailsController = ClothingDetailsController(clothing)
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
            UIAction(title: String(localized: "common.sort.name"), image: UIImage(systemName: "tshirt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), identifier: nil, discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Name ? .on : .mixed, handler: { [weak self] (_) in self?.sortBy(.Name) }),
            UIAction(title: String(localized: "common.sort.date"), image: UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Date ? .on : .mixed, handler: { [weak self] (_) in self?.sortBy(.Date) }),
            UIAction(title: String(localized: "common.sort.edit"), image: UIImage(systemName: "pencil.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .Edit ? .on : .mixed, handler: { [weak self] (_) in self?.sortBy(.Edit) })
        ]
        
        let menu = UIMenu(title: String(localized: "common.sort.menu"), image: nil, identifier: nil, options: [], children: menuItems)
        return menu
    }
    
    func sortBy(_ sortOption: sortOptions) {
        guard sortOption != clothingSortSelected else {
            return
        }
        
        clothingSortSelected = sortOption
        self.navigationItem.rightBarButtonItems?.last{ $0 == navSortButton }?.menu = generateSortMenu()
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
    
    private func sortByEdit(source: [Clothing]? = nil) -> [Clothing] {
        var tempSortedDataSource: [Clothing] = source != nil ? source! : dataSource
        tempSortedDataSource.sort { $0.updatedAt > $1.updatedAt }
        
        return tempSortedDataSource
    }
    
    lazy var uploadNowButton: UIButton = {
        var btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        var attributedTitle = NSMutableAttributedString(string: String(localized: "wardrobe.upload.cta1") + "\n", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.secondaryLabel])
        let callToAction = NSAttributedString(string: String(localized: "wardrobe.upload.cta2"), attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .heavy), .foregroundColor: UIColor.label])
        attributedTitle.append(NSAttributedString(attributedString: callToAction))
        btn.setAttributedTitle(attributedTitle, for: .normal)
        btn.isHidden = true
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(addClothingPiece), for: .touchUpInside)
        return btn
    }()
    
    func generateScaleMenu() -> UIMenu {
        let scaleMenuItems: [UIAction] = [
            UIAction(title: String(localized: "common.scale.small"), attributes: .keepsMenuPresented, state: selectedViewMode == .SMALL ? .on : .mixed, handler: { [weak self] _ in
                guard let self else { return }

                self.selectedViewMode = .SMALL
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "common.scale.medium"), attributes: .keepsMenuPresented, state: selectedViewMode == .MEDIUM ? .on : .mixed, handler: { [weak self] _ in
                guard let self else { return }

                self.selectedViewMode = .MEDIUM
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            }),
            UIAction(title: String(localized: "common.scale.large"), attributes: .keepsMenuPresented, state: selectedViewMode == .LARGE ? .on : .mixed, handler: { [weak self] _ in
                guard let self else { return }

                self.selectedViewMode = .LARGE
                self.navigationItem.leftBarButtonItem?.menu = self.generateScaleMenu()
            })
        ]
        
        return UIMenu(title: String(localized: "common.scale.title"), children: scaleMenuItems)
    }
    
    func generateFilterMenu() -> UIMenu {
        let tagsMenuItems: [UIAction] = [
            UIAction(title: "🌱 " + Seasons.SPRING.localizedName, attributes: .keepsMenuPresented, state: selectedSeasons.contains(.SPRING) ? .on : .mixed, handler: { [weak self] (_) in self?.filterBySeason(.SPRING) }),
            UIAction(title: "☀️ " + Seasons.SUMMER.localizedName, attributes: .keepsMenuPresented, state: selectedSeasons.contains(.SUMMER) ? .on : .mixed, handler: { [weak self] (_) in self?.filterBySeason(.SUMMER) }),
            UIAction(title: "🍂 " + Seasons.AUTUMN.localizedName, attributes: .keepsMenuPresented, state: selectedSeasons.contains(.AUTUMN) ? .on : .mixed, handler: { [weak self] (_) in self?.filterBySeason(.AUTUMN) }),
            UIAction(title: "❄️ " + Seasons.WINTER.localizedName, attributes: .keepsMenuPresented, state: selectedSeasons.contains(.WINTER) ? .on : .mixed, handler: { [weak self] (_) in self?.filterBySeason(.WINTER) })
        ]
        
        let seasonsMenuItems: [UIAction] = [
            UIAction(title: "🧍🏻 " + Tags.CASUAL.localizedName, attributes: .keepsMenuPresented, state: selectedTags.contains(.CASUAL) ? .on : .mixed, handler: { [weak self] (_) in self?.filterByTags(.CASUAL) }),
            UIAction(title: "🕴🏻 " + Tags.FORMAL.localizedName, attributes: .keepsMenuPresented, state: selectedTags.contains(.FORMAL) ? .on : .mixed, handler: { [weak self] (_) in self?.filterByTags(.FORMAL) }),
            UIAction(title: "⛹🏻 " + Tags.SPORTS.localizedName, attributes: .keepsMenuPresented, state: selectedTags.contains(.SPORTS) ? .on : .mixed, handler: { [weak self] (_) in self?.filterByTags(.SPORTS) }),
            UIAction(title: "🧳 " + Tags.VINTAGE.localizedName, attributes: .keepsMenuPresented, state: selectedTags.contains(.VINTAGE) ? .on : .mixed, handler: { [weak self] (_) in self?.filterByTags(.VINTAGE) })
        ]
        
        var totalItems: [UIMenuElement] = []
        totalItems.append(UIMenu(title: "", options: .displayInline, children: tagsMenuItems))
        totalItems += seasonsMenuItems
        
        let menu = UIMenu(title: String(localized: "common.filter.menu"), options: [], children: totalItems)
        return menu
    }
    
    func filterBySeason(_ seasonSelected: Seasons) {
        selectedSeasons.contains(seasonSelected) ? selectedSeasons.removeAll(where: { season in
            return season == seasonSelected
        }) : selectedSeasons.append(seasonSelected)
        self.navigationItem.rightBarButtonItems?.first{ $0 == navFilterButton }?.menu = generateFilterMenu()
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
    
    private func updateSubCategorySegment(animated: Bool) {
        let topLevel = wardrobeFilter.topLevel
        let shouldShow = topLevel != nil

        if let topLevel = topLevel {
            var items: [ClothingSubCategories?] = [nil]
            items.append(contentsOf: topLevel.subCategories.map { Optional($0) })
            subCategoryItems = items
            selectedSubCategoryIndex = 0
            subCategoryCollectionView.reloadData()
            subCategoryCollectionView.setContentOffset(.zero, animated: false)
        }

        let isCurrentlyVisible = !subCategoryCollectionView.isHidden
        guard shouldShow != isCurrentlyVisible else { return }

        animateSubSegment(show: shouldShow, animated: animated)
    }

    private func animateSubSegment(show: Bool, animated: Bool) {
        let segmentHeight = categorySegmentControl.bounds.height
        let collapsedTransform = CGAffineTransform(translationX: 0, y: -segmentHeight).scaledBy(x: 0.6, y: 0.6)

        if show {
            subCategoryCollectionView.transform = collapsedTransform
            subCategoryCollectionView.alpha = 0
            subCategoryCollectionView.isHidden = false
        }

        let changes = {
            self.subCategoryCollectionView.transform = show ? .identity : collapsedTransform
            self.subCategoryCollectionView.alpha = show ? 1 : 0
            self.subCategoryCollectionView.isHidden = !show
            self.view.layoutIfNeeded()
        }

        guard animated else {
            changes()
            return
        }

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: changes
        )
    }

    private func title(for item: ClothingSubCategories?) -> String {
        item?.localizedName ?? String(localized: "common.all")
    }

    func filterClothesType(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource

        let byCategory: [Clothing]
        if let topLevel = wardrobeFilter.topLevel {
            byCategory = tempFilteredDataSource.filter { $0.category == topLevel }
        } else {
            byCategory = tempFilteredDataSource
        }

        guard let sub = wardrobeFilter.subCategory else { return byCategory }
        return byCategory.filter { $0.subCategory == sub }
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
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .automatic
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateScaleMenu())
        
        let spacerView1 = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
            
        let emptyButton = UIBarButtonItem(customView: spacerView1)
        emptyButton.hidesSharedBackground = true
        
        navigationItem.rightBarButtonItems = [navFilterButton, navSortButton, emptyButton]
        
        view.addSubview(filterStackView)
        NSLayoutConstraint.activate([
            filterStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        categorySegmentControl.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            let index = self.categorySegmentControl.selectedSegmentIndex
            let newTopLevel: ClothingCategories? = (index >= 1 && index <= self.categoryOrder.count) ? self.categoryOrder[index - 1] : nil
            self.wardrobeFilter = WardrobeFilter(topLevel: newTopLevel, subCategory: nil)
            self.updateSubCategorySegment(animated: true)
        }, for: .valueChanged)

        view.addSubview(clothingCollectionView)
        clothingCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        clothingCollectionView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 20).isActive = true
        clothingCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        clothingCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        clothingCollectionView.refreshControl = clothingRefreshControll

        view.addSubview(uploadButton)
        uploadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
        clothingCollectionView.addSubview(uploadNowButton)
        NSLayoutConstraint.activate([
            uploadNowButton.centerXAnchor.constraint(equalTo: clothingCollectionView.centerXAnchor),
            uploadNowButton.topAnchor.constraint(equalTo: clothingCollectionView.topAnchor, constant: 20),
            uploadNowButton.leadingAnchor.constraint(equalTo: clothingCollectionView.leadingAnchor, constant: 20),
            uploadNowButton.trailingAnchor.constraint(equalTo: clothingCollectionView.trailingAnchor, constant: -20)
        ])
    }
}

extension ClothesGalleryController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UISearchResultsUpdating, UploadControllerDelegate, ClothingDetailsDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard collectionView === subCategoryCollectionView else { return 0 }
        return subCategoryItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView === subCategoryCollectionView else { return UICollectionViewCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubCategoryFilterCell.identifier, for: indexPath) as! SubCategoryFilterCell
        let item = subCategoryItems[indexPath.item]
        cell.configure(title: title(for: item), isSelected: indexPath.item == selectedSubCategoryIndex)
        return cell
    }

    func didUpdateClothing() {
        reloadDataFromCoreData()
    }
    
    func didDeleteClothing() {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === subCategoryCollectionView {
            let item = subCategoryItems[indexPath.item]
            return CGSize(width: SubCategoryFilterCell.width(for: title(for: item)), height: SubCategoryFilterCell.height)
        }

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
        if collectionView === subCategoryCollectionView {
            let previousIndex = selectedSubCategoryIndex
            guard previousIndex != indexPath.item else { return }
            selectedSubCategoryIndex = indexPath.item
            wardrobeFilter.subCategory = subCategoryItems[indexPath.item]

            var indexPaths = [IndexPath(item: previousIndex, section: 0), indexPath]
            indexPaths = indexPaths.filter { $0.item < subCategoryItems.count }
            collectionView.reloadItems(at: indexPaths)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            return
        }

        guard let clothing = clothing(at: indexPath) else { return }

        showClothingDetails(of: clothing)
    }
    
    func didUploadClothing(_ clothing: Clothing) {
        reconfigure(clothingIDs: [clothing.id])
    }
}
