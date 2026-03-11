//
//  CustomSwitchInput.swift
//  Drssed
//
//  Created by David Riegel on 25.09.25.
//

import UIKit

final public class CustomSwitchInput: CustomInputBackground {
    private(set) var fieldInput: UISwitch = {
        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.isUserInteractionEnabled = true
        sw.setOn(false, animated: false)
        sw.onTintColor = .accent
        return sw
    }()
    
    override init(fieldTitle title: String) {
        super.init(fieldTitle: title)
        
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldInput)
        
        fieldBackground.isHidden = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fieldInput.centerYAnchor.constraint(equalTo: fieldBackground.centerYAnchor),
            fieldInput.leadingAnchor.constraint(equalTo: fieldBackground.leadingAnchor),
            fieldInput.trailingAnchor.constraint(equalTo: fieldBackground.trailingAnchor),
            fieldInput.heightAnchor.constraint(equalTo: fieldBackground.heightAnchor)
        ])
    }
}


