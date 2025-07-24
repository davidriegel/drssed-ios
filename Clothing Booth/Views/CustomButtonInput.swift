//
//  CustomButtonInput.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.04.25.
//

import UIKit

final public class CustomButtonInput: CustomInputBackground {
    public var fieldInput: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }()
    
    init(fieldTitle title: String, buttonTitle: String? = nil) {
        super.init(fieldTitle: title)
        
        setupView(title: buttonTitle)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldInput)
        
        fieldInput.setTitle(title, for: .normal)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fieldInput.topAnchor.constraint(equalTo: fieldBackground.topAnchor),
            fieldInput.leadingAnchor.constraint(equalTo: fieldBackground.leadingAnchor),
            fieldInput.trailingAnchor.constraint(equalTo: fieldBackground.trailingAnchor),
            fieldInput.heightAnchor.constraint(equalTo: fieldBackground.heightAnchor),
            fieldInput.bottomAnchor.constraint(equalTo: fieldBackground.bottomAnchor)
        ])
    }
}


