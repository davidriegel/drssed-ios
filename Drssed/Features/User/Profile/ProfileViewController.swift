//
//  ProfileViewController.swift
//  Drssed
//
//  Created by David Riegel on 08.05.26.
//

import UIKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }
    
    func configureViewComponents() {
        view.backgroundColor = .background
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.largeTitleDisplayMode = .never
    }
}
