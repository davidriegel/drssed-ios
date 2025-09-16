//
//  SeasonsPickerswift
//  Wearhouse
//
//  Created by David Riegel on 15.08.25.
//

import UIKit

protocol SeasonsPickerViewDelegate: AnyObject {
    func springSeasonSelected()
    func summerSeasonSelected()
    func autumnSeasonSelected()
    func winterSeasonSelected()
    func seasonsDoneButtonPressed()
}

class SeasonsPickerView: UIView {
    private var delegate: SeasonsPickerViewDelegate!
    
    lazy var pickerButtonPress: UIAction = {
        let ac = UIAction { action in
            guard let button = action.sender as? UIButton else { return }
            
            button.isSelected.toggle()
            button.backgroundColor = button.isSelected ? .accent : .secondarySystemBackground
            
            switch button.tag {
            case 1:
                self.delegate.springSeasonSelected()
            case 2:
                self.delegate.summerSeasonSelected()
            case 3:
                self.delegate.autumnSeasonSelected()
            case 4:
                self.delegate.winterSeasonSelected()
            default:
                return
            }
        }
        return ac
    }()
    
    lazy var doneButtonPress: UIAction = {
        let ac = UIAction { _ in
            self.delegate.seasonsDoneButtonPressed()
        }
        
        return ac
    }()
    
    lazy var springPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 1
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "🌱 " + String(localized: "common.season.spring"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var summerPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 2
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "☀️ " + String(localized: "common.season.summer"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var autumnPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 3
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "🍂 " + String(localized: "common.season.autumn"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var winterPickerButton: UIButton = {
        let bt = UIButton(frame: .zero, primaryAction: pickerButtonPress)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tag = 4
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.lightGray.cgColor
        bt.backgroundColor = .secondarySystemBackground
        
        let title = NSAttributedString(string: "❄️ " + String(localized: "common.season.winter"), attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
        bt.layer.cornerCurve = .continuous
        bt.setAttributedTitle(title, for: .normal)
        bt.isSelected = false
        return bt
    }()
    
    lazy var seasonsPickerDone: UIButton = {
        let button = UIButton(frame: .zero, primaryAction: doneButtonPress)
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: String(localized: "common.done"), attributes: [.font : UIFont.systemFont(ofSize: 16, weight: .bold)])
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        springPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: springPickerButton)
        summerPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: summerPickerButton)
        autumnPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: autumnPickerButton)
        winterPickerButton.layer.cornerRadius = CornerStyle.small.radius(for: winterPickerButton)
        
        layer.cornerRadius = CornerStyle.large.radius(for: self)
    }
    
    public func showSeasonsPickerView() {
        guard isHidden else { return }
        isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    public func hideSeasonsPickerView() {
        guard !isHidden else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
    
    init(delegate: SeasonsPickerViewDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate
        
        addSubview(springPickerButton)
        NSLayoutConstraint.activate([
            springPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            springPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            springPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            springPickerButton.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -5)
        ])
        
        addSubview(summerPickerButton)
        NSLayoutConstraint.activate([
            summerPickerButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            summerPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            summerPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            summerPickerButton.topAnchor.constraint(equalTo: centerYAnchor, constant: 5)
        ])
        
        addSubview(autumnPickerButton)
        NSLayoutConstraint.activate([
            autumnPickerButton.leadingAnchor.constraint(equalTo: springPickerButton.trailingAnchor, constant: 10),
            autumnPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            autumnPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            autumnPickerButton.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -5)
        ])
        
        addSubview(winterPickerButton)
        NSLayoutConstraint.activate([
            winterPickerButton.leadingAnchor.constraint(equalTo: springPickerButton.trailingAnchor, constant: 10),
            winterPickerButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
            winterPickerButton.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.3),
            winterPickerButton.topAnchor.constraint(equalTo: centerYAnchor, constant: 5)
        ])
        
        addSubview(seasonsPickerDone)
        NSLayoutConstraint.activate([
            seasonsPickerDone.centerYAnchor.constraint(equalTo: centerYAnchor),
            seasonsPickerDone.leadingAnchor.constraint(equalTo: autumnPickerButton.trailingAnchor, constant: 10),
            seasonsPickerDone.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
