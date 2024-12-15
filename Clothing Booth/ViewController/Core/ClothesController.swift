//
//  ClothesController.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit
import SkeletonView

class ClothesController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
        updateData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        uploadButton.layer.add(createUploadButtonHover(), forKey: "hoverAnimation")
    }
    
    // MARK: --
    
    var dataSource: [Clothing] = [] {
        didSet {
            searchDataSource = dataSource
            sortedAndFilteredDataSource = sortClothes(source: filterClothesType(source: dataSource))
        }
    }
    
    var sortedAndFilteredDataSource: [Clothing] = [] {
        didSet {
            clothingCollectionView.reloadData()
        }
    }
    
    var searchDataSource: [Clothing] = [] {
        didSet {
            clothingCollectionView.reloadData()
        }
    }
    
    var isSearching: Bool = false
    let placeholders: [String] = ["super cool t-shirt", "fav hoodie", "zipper"]
    
    var clothingSortSelected: sortOptions = .date {
        didSet {
            sortedAndFilteredDataSource = sortClothes(source: filterClothesType(source: dataSource))
        }
    }
    
    var clothingTypesSelected: clothingTypes? = nil {
        didSet {
            sortedAndFilteredDataSource = sortClothes(source: filterClothesType(source: dataSource))
        }
    }
    
    enum sortOptions {
        case name
        case date
        case edit
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
    
    // MARK: --
    
    lazy var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = placeholders.randomElement()
        sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        return sb
    }()
    
    lazy var clothingCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.estimatedItemSize = CGSize(width: (self.view.frame.width / 3.2), height: (self.view.frame.width / 2))
        let view =  UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isSkeletonable = true
        view.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.scrollsToTop = true
        view.register(ClothingViewCell.self, forCellWithReuseIdentifier: ClothingViewCell.identifier)
        view.register(SkeletonClothingViewCell.self, forCellWithReuseIdentifier: SkeletonClothingViewCell.identifier)
        view.dataSource = self
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .background
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
    
    func showClothingDetails(of clothing: Clothing) {
        present(ClothingDetailsController(clothing), animated: true)
    }
    
    func generateSortMenu() -> UIMenu {
        let menuItems: [UIAction] = [
            UIAction(title: "Name", image: UIImage(systemName: "tshirt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), identifier: nil, discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .name ? .on : .mixed, handler: { (_) in self.sortBy(.name) }),
            UIAction(title: "Date added", image: UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .date ? .on : .mixed, handler: { (_) in self.sortBy(.date) }),
            UIAction(title: "Recently edited (wip)", image: UIImage(systemName: "pencil.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: clothingSortSelected == .edit ? .on : .mixed, handler: { (_) in self.sortBy(.edit) })
        ]
        
        let menu = UIMenu(title: "Sort by (ascending)", image: nil, identifier: nil, options: [], children: menuItems)
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
        case .name:
            sortByName(source: source)
        case .date:
            sortByDate(source: source)
        case .edit:
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
        tempSortedDataSource.sort {
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-DD hh-mm-ss"
            let first = formatter.date(from: $0.created_at) ?? Date()
            let second = formatter.date(from: $1.created_at) ?? Date()
            return first > second
        }
        
        return tempSortedDataSource
    }
    
    // sortByEdit currently not available due to API, edits date not being saved to database
    private func sortByEdit(source _: [Clothing]? = nil) -> [Clothing] {
        return dataSource
    }
    
    func generateFilterMenu() -> UIMenu {
        let menuItems: [UIAction] = [
        ]
        
        let menu = UIMenu(title: "Filter by", options: [], children: menuItems)
        return menu
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
            typeButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            
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
    
    func filterClothesType(source: [Clothing]? = nil) -> [Clothing] {
        let tempFilteredDataSource: [Clothing] = source != nil ? source! : dataSource
        let topsCategories: [String] = ["T-Shirt", "Shirt", "Polo", "Sweater", "Hoodie", "Jacket", "Coat"]
        let bottomsCategories: [String] = ["Jeans", "Shorts", "Pants", "Skirt"]
        let footwearCategories: [String] = ["Sneakers", "Boots", "Sandals", "Heels", "Loafers"]
        let accessoriesCategories: [String] = ["Hat", "Scarf", "Gloves", "Belt", "Bag", "Watch", "Accessory"]
        
        return tempFilteredDataSource.filter { clothing in
            guard (clothingTypesSelected != nil) else {
                return true
            }
            
            switch clothingTypesSelected {
            case .Tops:
                return topsCategories.contains(clothing.category)
            case .Bottoms:
                return bottomsCategories.contains(clothing.category)
            case .Footwear:
                return footwearCategories.contains(clothing.category)
            case .Accessoires:
                return accessoriesCategories.contains(clothing.category)
            case nil:
                return true
            }
        }
    }
    
    // MARK: --
    
    @objc
    func addClothingPiece() {
        navigationController?.pushViewController(UploadController(), animated: true)
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
            clothingCollectionView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            
            do {
                dataSource = try await APIHandler.shared.getClothingList(limit: 30, offset: 0).clothing
                if let encoded = try? JSONEncoder().encode(dataSource) {
                    UserDefaults.standard.setValue(encoded, forKey: "userClothes")
                }
            } catch NetworkingError.rateLimiting {
                // possibily show alert
                dataSource = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
            } catch let e {
                print(e)
                dataSource = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
            }
            
            clothingCollectionView.hideSkeleton()
            clothingCollectionView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        navigationController?.navigationBar.prefersLargeTitles = false
        title = "clothes"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationItem.largeTitleDisplayMode = .automatic
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.2.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateFilterMenu()), UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), menu: generateSortMenu())]
        
        view.addSubview(clothingCollectionView)
        clothingCollectionView.topAnchor.constraint(equalTo: view.superview?.topAnchor ?? view.topAnchor).isActive = true
        clothingCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        clothingCollectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        clothingCollectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5).isActive = true
        clothingCollectionView.refreshControl = clothingRefreshControll
        
        view.addSubview(typeScrollView)
        typeScrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        typeScrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        typeScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
        typeScrollView.heightAnchor.constraint(equalToConstant: view.frame.size.height / 10).isActive = true
        
        typeScrollView.addSubview(typeStackView)
        typeStackView.leadingAnchor.constraint(equalTo: typeScrollView.leadingAnchor).isActive = true
        typeStackView.trailingAnchor.constraint(equalTo: typeScrollView.trailingAnchor).isActive = true
        typeStackView.centerYAnchor.constraint(equalTo: typeScrollView.centerYAnchor).isActive = true
        typeStackView.heightAnchor.constraint(equalToConstant: view.frame.size.height / 20).isActive = true
        
        addTypeButtons()
        
        view.addSubview(uploadButton)
        uploadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: typeScrollView.topAnchor, constant: -10).isActive = true
    }
}

extension ClothesController: UICollectionViewDataSource, UICollectionViewDelegate, SkeletonCollectionViewDelegate, SkeletonCollectionViewDataSource, UISearchResultsUpdating {
    
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? searchDataSource.count : sortedAndFilteredDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let customCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClothingViewCell.identifier, for: indexPath) as? ClothingViewCell else {
            return UICollectionViewCell()
        }
        
        if isSearching {
            customCell.configureViewComponents(with: URL(string: "https://api.clothing-booth.com" + searchDataSource[indexPath.item].image)!, and: searchDataSource[indexPath.item].name)
        } else {
            customCell.configureViewComponents(with: URL(string: "https://api.clothing-booth.com" + sortedAndFilteredDataSource[indexPath.item].image)!, and: sortedAndFilteredDataSource[indexPath.item].name)
        }
        
        return customCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showClothingDetails(of: isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource [indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        showClothingDetails(of: isSearching ? searchDataSource[indexPath.item] : sortedAndFilteredDataSource [indexPath.item])
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int.random(in: 4...8)
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> SkeletonView.ReusableCellIdentifier {
        return SkeletonClothingViewCell.identifier
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell? {
        let cell = skeletonView.dequeueReusableCell(withReuseIdentifier: SkeletonClothingViewCell.identifier, for: indexPath)
        return cell
    }
}
