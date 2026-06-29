//
//  CategoryPickerSheetController.swift
//  Drssed
//
//  Created by David Riegel on 29.06.26.
//

import UIKit

protocol CategoryPickerSheetControllerDelegate: AnyObject {
    func categoryPicker(_ controller: CategoryPickerSheetController,
                        didSelect subCategory: ClothingSubCategories,
                        in category: ClothingCategories)
}

class CategoryPickerSheetController: UIViewController {
    weak var delegate: CategoryPickerSheetControllerDelegate?

    private let preselectedSubCategory: ClothingSubCategories?

    private let allSections: [(category: ClothingCategories, items: [ClothingSubCategories])] = {
        ClothingCategories.allCases.compactMap { cat in
            let items = cat.subCategories
            return items.isEmpty ? nil : (cat, items)
        }
    }()

    private var visibleSections: [(category: ClothingCategories, items: [ClothingSubCategories])] = []

    private var searchQuery: String = "" {
        didSet { rebuildVisibleSections() }
    }

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = String(localized: "categorypicker.search.placeholder")
        sc.searchBar.autocapitalizationType = .none
        sc.searchBar.autocorrectionType = .no
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.keyboardDismissMode = .onDrag
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "SubCategoryCell")
        return tv
    }()

    init(preselected: ClothingSubCategories?, delegate: CategoryPickerSheetControllerDelegate?) {
        self.preselectedSubCategory = preselected
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
        title = String(localized: "categorypicker.title")
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        rebuildVisibleSections()
    }

    private func rebuildVisibleSections() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if query.isEmpty {
            visibleSections = allSections
        } else {
            visibleSections = allSections.compactMap { section in
                let filtered = section.items.filter { $0.localizedName.lowercased().contains(query) }
                return filtered.isEmpty ? nil : (section.category, filtered)
            }
        }

        if isViewLoaded { tableView.reloadData() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension CategoryPickerSheetController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleSections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        visibleSections[section].category.localizedName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubCategoryCell", for: indexPath)
        let subCategory = visibleSections[indexPath.section].items[indexPath.row]

        var config = UIListContentConfiguration.cell()
        config.text = subCategory.localizedName
        config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.contentConfiguration = config
        cell.accessoryType = (subCategory == preselectedSubCategory) ? .checkmark : .none
        cell.tintColor = .accent
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = visibleSections[indexPath.section]
        let subCategory = section.items[indexPath.row]
        delegate?.categoryPicker(self, didSelect: subCategory, in: section.category)
        dismiss(animated: true)
    }
}

extension CategoryPickerSheetController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchQuery = searchController.searchBar.text ?? ""
    }
}
