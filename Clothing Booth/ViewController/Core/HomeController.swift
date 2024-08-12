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
    
    @objc
    func addClothingPiece() {
        navigationController?.pushViewController(UploadController(), animated: true)
    }

    func configureViewComponents() {
        view.backgroundColor = .systemBackground
        title = "home"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.up.forward.square.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemBackground, .label])), style: .plain, target: self, action: #selector(addClothingPiece))
    }
}

