//
//  ClothingDetailsController.swift
//  Clothing Booth
//
//  Created by David Riegel on 02.08.24.
//

import UIKit

class ClothingDetailsController: UIViewController {
    
    private let clothing: Clothing
    
    init(_ clothing: Clothing) {
        self.clothing = clothing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: -- Information about the selected clothing piece ( for Generator Controller ) [Image Name Brand Type ShortDescription Type ]

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: --
    
    func configureViewComponents() {
        view.backgroundColor = .background
        
    }
}
