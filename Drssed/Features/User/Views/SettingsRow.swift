//
//  SettingsRow.swift
//  Drssed
//
//  Created by David Riegel on 08.05.26.
//

import UIKit

final class SettingsRow: UIControl {
    
    private let action: (() -> Void)?
    
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private lazy var chevronView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.isUserInteractionEnabled = false
        return stack
    }()
    
    init(title: String, symbolName: String, detail: String? = nil, isInteractive: Bool = true, action: (() -> Void)? = nil, tintColor: UIColor = .accent) {
        self.action = action
        super.init(frame: .zero)
        
        titleLabel.text = title
        iconView.image = UIImage(systemName: symbolName)
        iconView.tintColor = tintColor
        detailLabel.text = detail
        detailLabel.isHidden = (detail == nil)
        chevronView.isHidden = !isInteractive
        isUserInteractionEnabled = isInteractive
        
        setupLayout()
        if isInteractive {
            addTarget(self, action: #selector(didTap), for: .touchUpInside)
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    private func setupLayout() {
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(detailLabel)
        contentStack.addArrangedSubview(chevronView)
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            iconView.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    @objc private func didTap() {
        action?()
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = self.isHighlighted ? .tertiarySystemGroupedBackground : .clear
            }
        }
    }
}
