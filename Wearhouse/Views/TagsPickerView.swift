//
//  TagsPickerView.swift
//  Wearhouse
//
//  Created by David Riegel on 19.08.25.
//

import UIKit

protocol TagsPickerViewDelegate: AnyObject {
    func tagSelected(_ tag: Tags)
    func tagsDoneButtonPressed()
}

class TagsPickerView: UIView {
    private var delegate: TagsPickerViewDelegate!
    
    lazy var pickerButtonPress: UIAction = {
        let ac = UIAction { action in
            guard let button = action.sender as? UIButton else { return }
            
            button.isSelected.toggle()
            button.backgroundColor = button.isSelected ? .accent : .secondarySystemBackground
            
            switch button.tag {
            case 1:
                self.delegate.tagSelected(.CASUAL)
            case 2:
                self.delegate.tagSelected(.FORMAL)
            case 3:
                self.delegate.tagSelected(.SPORTS)
            case 4:
                self.delegate.tagSelected(.VINTAGE)
            default:
                return
            }
        }
        return ac
    }()
    
    lazy var doneButtonPress: UIAction = {
        let ac = UIAction { _ in
            self.delegate.tagsDoneButtonPressed()
        }
        
        return ac
    }()
    
    lazy var casualPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 1
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "🧍🏻 " + String(localized: "common.tag.casual"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var formalPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 2
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "🕴🏻 " + String(localized: "common.tag.formal"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var sportsPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 3
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "⛹🏻 " + String(localized: "common.tag.sports"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var vintagePickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 4
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "🧳 " + String(localized: "common.tag.vintage"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.layer.cornerCurve = .continuous
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var tagsPickerDone: UIButton = {
        let button = UIButton(frame: .zero, primaryAction: doneButtonPress)
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: String(localized: "common.done"), attributes: [.font : UIFont.systemFont(ofSize: 16, weight: .bold)])
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        casualPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: casualPickerButton)
        formalPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: formalPickerButton)
        sportsPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: sportsPickerButton)
        vintagePickerButton.layer.cornerRadius = CornerStyle.small.radius(for: vintagePickerButton)
        
        layer.cornerRadius = CornerStyle.large.radius(for: self)
    }
    
    public func showTagsPickerView() {
        guard isHidden else { return }
        isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    public func hideTagsPickerView() {
        guard !isHidden else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
    
    init(delegate: TagsPickerViewDelegate, _ preselection: [Tags] = []) {
        super.init(frame: .zero)
        self.delegate = delegate
        
        preselection.forEach { tag in
            switch tag {
            case .CASUAL:
                casualPickerButton.isSelected = true
                casualPickerButton.backgroundColor = .accent
            case .FORMAL:
                formalPickerButton.isSelected = true
                formalPickerButton.backgroundColor = .accent
            case .VINTAGE:
                vintagePickerButton.isSelected = true
                vintagePickerButton.backgroundColor = .accent
            case .SPORTS:
                sportsPickerButton.isSelected = true
                sportsPickerButton.backgroundColor = .accent
            }
        }
        
        addSubview(casualPickerButton)
        NSLayoutConstraint.activate([
            casualPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            casualPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            casualPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            casualPickerButton.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -5)
        ])
        
        addSubview(formalPickerButton)
        NSLayoutConstraint.activate([
            formalPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            formalPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            formalPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            formalPickerButton.topAnchor.constraint(equalTo: centerYAnchor, constant: 5)
        ])
        
        addSubview(sportsPickerButton)
        NSLayoutConstraint.activate([
            sportsPickerButton.leadingAnchor.constraint(equalTo: casualPickerButton.trailingAnchor, constant: 10),
            sportsPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            sportsPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            sportsPickerButton.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -5)
        ])
        
        addSubview(vintagePickerButton)
        NSLayoutConstraint.activate([
            vintagePickerButton.leadingAnchor.constraint(equalTo: casualPickerButton.trailingAnchor, constant: 10),
            vintagePickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            vintagePickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            vintagePickerButton.topAnchor.constraint(equalTo: centerYAnchor, constant: 5)
        ])
        
        addSubview(tagsPickerDone)
        NSLayoutConstraint.activate([
            tagsPickerDone.centerYAnchor.constraint(equalTo: centerYAnchor),
            tagsPickerDone.leadingAnchor.constraint(equalTo: sportsPickerButton.trailingAnchor, constant: 10),
            tagsPickerDone.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

