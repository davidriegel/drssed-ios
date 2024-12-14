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
    
    
    var dataSource: [Clothing] = [] {
        didSet {
            filteredDataSource = dataSource
        }
    }
    var filteredDataSource: [Clothing] = [] {
        didSet {
            clothingCollectionView.reloadData()
        }
    }
    let placeholders: [String] = ["super cool t-shirt", "fav hoodie", "zipper"]
    var sortNameToggle: Bool = false
    var sortDateToggle: Bool = true
    var sortEditToggle: Bool = false
    
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
    
    func toggleSortFalse(sender: Int) {
        if sender != 1 {
            sortNameToggle = false
        }
        if sender != 2 {
            sortDateToggle = false
        }
        if sender != 3 {
            sortEditToggle = false
        }
    }
    
    func generateSortMenu() -> UIMenu {
        let menuItems: [UIAction] = [
            UIAction(title: "Name", image: UIImage(systemName: "tshirt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), identifier: nil, discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: sortNameToggle ? .on : .mixed, handler: { (_) in self.toggleSortFalse(sender: 1); self.sortNameToggle.toggle(); self.navigationItem.rightBarButtonItems?.last!.menu = self.generateSortMenu() }),
            UIAction(title: "Date added", image: UIImage(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: sortDateToggle ? .on : .mixed, handler: { (_) in self.toggleSortFalse(sender: 2); self.sortDateToggle.toggle(); self.navigationItem.rightBarButtonItems?.last!.menu = self.generateSortMenu()}),
            UIAction(title: "Recently edited", image: UIImage(systemName: "pencil.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), discoverabilityTitle: nil, attributes: .keepsMenuPresented, state: sortEditToggle ? .on : .mixed, handler: { (_) in self.toggleSortFalse(sender: 3); self.sortEditToggle.toggle(); self.navigationItem.rightBarButtonItems?.last!.menu = self.generateSortMenu()})
        ]
        
        let menu = UIMenu(title: "Sort by", image: nil, identifier: nil, options: [], children: menuItems)
        return menu
    }
    
    func generateFilterMenu() -> UIMenu {
        let menuItems: [UIAction] = [
        ]
        
        let menu = UIMenu(title: "Filter by", options: [], children: menuItems)
        return menu
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
    
    @objc
    func addClothingPiece() {
        navigationController?.pushViewController(UploadController(), animated: true)
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
        
        view.addSubview(uploadButton)
        uploadButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
    }
}

extension ClothesController: UICollectionViewDataSource, UICollectionViewDelegate, SkeletonCollectionViewDelegate, SkeletonCollectionViewDataSource, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text?.lowercased(), !query.isEmpty else {
            filteredDataSource = dataSource
            return
        }
        
        filteredDataSource = dataSource.filter { clothingPiece in
            let name = clothingPiece.name.lowercased()
            return name.hasPrefix(query) || name.contains(query)
        }
        
        if filteredDataSource.isEmpty {
            let fuzzyMatches = dataSource.filter { clothingPiece in
                let name = clothingPiece.name.lowercased()
                let distance = levenshteinDistance(name, query)
                return distance <= 2
            }
            
            if !fuzzyMatches.isEmpty {
                filteredDataSource = fuzzyMatches
            }
        }
        
        filteredDataSource.sort {
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
        return filteredDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let customCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClothingViewCell.identifier, for: indexPath) as? ClothingViewCell else {
            return UICollectionViewCell()
        }
        
        customCell.configureViewComponents(with: URL(string: "https://api.clothing-booth.com" + filteredDataSource[indexPath.item].image)!, and: filteredDataSource[indexPath.item].name)
        
        return customCell
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
