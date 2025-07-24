//
//  OutfitsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 18.11.24.
//

import UIKit

public class OutfitsController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: --
    
    private lazy var searchBarController: UISearchController = {
        let sb = UISearchController()
        sb.searchBar.placeholder = "casual fit"
        //sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        return sb
    }()
    
    // MARK: --
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        title = "outfits"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.searchController = searchBarController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationItem.largeTitleDisplayMode = .automatic
    }
}
