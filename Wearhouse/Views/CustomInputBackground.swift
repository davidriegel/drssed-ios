//
//  CustomInputBackground.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.04.25.
//

import UIKit

public class CustomInputBackground: UIView {
    private var fieldTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        return label
    }()
    
    public var fieldBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.clipsToBounds = true
        return view
    }()
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        fieldBackground.layer.cornerRadius = CornerStyle.small.radius(for: fieldBackground)
    }
    
    init(fieldTitle title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        setupView(title)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setTitleText(_ text: String) {
        fieldTitle.text = text
    }
    
    private func setupView(_ title: String) {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldTitle)
        addSubview(fieldBackground)
        
        fieldTitle.text = title
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fieldTitle.topAnchor.constraint(equalTo: self.topAnchor),
            fieldTitle.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            fieldTitle.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            fieldTitle.heightAnchor.constraint(equalToConstant: fieldTitle.font.lineHeight),
            
            fieldBackground.topAnchor.constraint(equalTo: fieldTitle.bottomAnchor, constant: 5),
            fieldBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            fieldBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            fieldBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

