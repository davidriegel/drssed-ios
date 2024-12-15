//
//  ClothingDetailsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 02.08.24.
//

import UIKit

class ClothingDetailsController: UIViewController {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: -- Information about the selected clothing piece ( for Generator Controller ) [Image Name Brand Type ShortDescription Type ]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    let clothing: Clothing
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = clothing.name
    }
}
