//
//  ViewController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

public class HomeController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }

    private func configureViewComponents() {
        view.backgroundColor = .background
        title = "home"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
    }
}

