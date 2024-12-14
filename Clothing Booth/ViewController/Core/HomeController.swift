//
//  ViewController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

class HomeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }

    func configureViewComponents() {
        view.backgroundColor = .background
        title = "home"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
    }
}

