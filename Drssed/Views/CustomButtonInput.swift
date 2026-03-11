//
//  CustomButtonInput.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.04.25.
//

import UIKit

final public class CustomButtonInput: CustomInputBackground {
    private(set) var fieldInput: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }()
    
    public let indicatorImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    init(fieldTitle title: String, buttonTitle: String? = nil, indicatorImage: Bool = true) {
        super.init(fieldTitle: title)
        
        setupView(title: buttonTitle, indicatorImageHidden: indicatorImage)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String? = nil, indicatorImageHidden: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldInput)
        addSubview(indicatorImageView)
        
        fieldInput.setTitle(title, for: .normal)
        indicatorImageView.isHidden = !indicatorImageHidden
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fieldInput.topAnchor.constraint(equalTo: fieldBackground.topAnchor),
            fieldInput.leadingAnchor.constraint(equalTo: fieldBackground.leadingAnchor),
            fieldInput.trailingAnchor.constraint(equalTo: fieldBackground.trailingAnchor),
            fieldInput.heightAnchor.constraint(equalTo: fieldBackground.heightAnchor),
            fieldInput.bottomAnchor.constraint(equalTo: fieldBackground.bottomAnchor),
            
            indicatorImageView.trailingAnchor.constraint(equalTo: fieldInput.trailingAnchor, constant: -10),
            indicatorImageView.centerYAnchor.constraint(equalTo: fieldInput.centerYAnchor),
            indicatorImageView.heightAnchor.constraint(equalTo: fieldInput.heightAnchor, multiplier: 0.65),
            indicatorImageView.widthAnchor.constraint(equalTo: indicatorImageView.heightAnchor)
        ])
    }
}


