//
//  CustomTextFieldInput.swift
//  Clothing Booth
//
//  Created by David Riegel on 24.04.25.
//

import UIKit

final public class CustomTextFieldInput: CustomInputBackground {
    private var maxCharacters: Int = 0
    
    private var characters: Int = 0 {
        didSet {
            fieldCounter.text = "\(characters)/\(maxCharacters)"
        }
    }
    
    public var fieldInput: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = .label
        tf.textAlignment = .left
        tf.isUserInteractionEnabled = true
        tf.keyboardType = .default
        tf.font = .systemFont(ofSize: 13, weight: .heavy)
        tf.returnKeyType = .done
        return tf
    }()
    
    private var fieldCounter: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.isHidden = true
        return label
    }()
    
    init(fieldTitle title: String, placeholder: String? = nil, text: String? = nil, charCounterWithCharacters: Int = 0) {
        super.init(fieldTitle: title)
        
        fieldInput.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        setupView(placeholder: placeholder, text: text, charCounterWithCharacters: charCounterWithCharacters)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func characterCounter(enabled: Bool, withCharacters characters: Int) {
        maxCharacters = characters
        fieldCounter.isHidden = !enabled
    }
    
    @objc
    fileprivate func textFieldDidChange(_ textField: UITextField) {
        updateCounter()
    }
    
    private func updateCounter() {
        characters = fieldInput.text?.count ?? 0
    }
    
    private func setupView(placeholder: String? = nil, text: String? = nil, charCounterWithCharacters: Int = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(fieldInput)
        addSubview(fieldCounter)
        
        fieldInput.placeholder = placeholder
        fieldInput.text = text
        maxCharacters = charCounterWithCharacters
        characters = fieldInput.text?.count ?? 0
        
        if charCounterWithCharacters > 0 {
            fieldCounter.isHidden = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fieldInput.topAnchor.constraint(equalTo: fieldBackground.topAnchor),
            fieldInput.leadingAnchor.constraint(equalTo: fieldBackground.leadingAnchor, constant: 5),
            fieldInput.trailingAnchor.constraint(equalTo: fieldBackground.trailingAnchor, constant: -5),
            fieldInput.heightAnchor.constraint(equalTo: fieldBackground.heightAnchor),
            fieldInput.bottomAnchor.constraint(equalTo: fieldBackground.bottomAnchor),
            
            fieldCounter.bottomAnchor.constraint(equalTo: fieldBackground.bottomAnchor, constant: -5),
            fieldCounter.leadingAnchor.constraint(equalTo: fieldBackground.leadingAnchor),
            fieldCounter.trailingAnchor.constraint(equalTo: fieldBackground.trailingAnchor, constant: -10)
        ])
    }
}
