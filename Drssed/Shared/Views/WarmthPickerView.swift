//
//  WarmthPickerView.swift
//  Drssed
//
//  Created by David Riegel on 01.07.26.
//

import UIKit

protocol WarmthPickerViewDelegate: AnyObject {
    func warmthSelected(_ warmth: Warmth)
}

final class WarmthPickerView: UIView {
    private weak var delegate: WarmthPickerViewDelegate?

    private(set) var selectedWarmth: Warmth {
        didSet { updateAppearance() }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = String(localized: "common.warmth.title")
        return label
    }()

    private lazy var backgroundContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.clipsToBounds = true
        return view
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        return stack
    }()

    private var pillButtons: [UIButton] = []

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundContainer.layer.cornerRadius = CornerStyle.small.radius(for: backgroundContainer)

        pillButtons.forEach { pill in
            pill.layer.cornerRadius = CornerStyle.small.radius(for: pill)
            pill.layer.cornerCurve = .continuous
        }
    }

    init(delegate: WarmthPickerViewDelegate, preselected: Warmth = .MILD) {
        self.selectedWarmth = preselected
        super.init(frame: .zero)
        self.delegate = delegate

        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
        buildPills()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the selected warmth without notifying the delegate.
    /// Use when the selection is driven externally (e.g. resetting to a saved value).
    func setWarmth(_ warmth: Warmth) {
        guard warmth != selectedWarmth else { return }
        selectedWarmth = warmth
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(backgroundContainer)
        backgroundContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight),

            backgroundContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundContainer.heightAnchor.constraint(equalToConstant: 62),

            stack.topAnchor.constraint(equalTo: backgroundContainer.topAnchor),
            stack.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor)
        ])
    }

    private func buildPills() {
        for warmth in Warmth.allCases {
            let button = makePillButton(for: warmth)
            pillButtons.append(button)
            stack.addArrangedSubview(button)
        }
    }

    private func makePillButton(for warmth: Warmth) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2)
        config.imagePlacement = .top
        config.imagePadding = 2
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = warmth.rawValue
        button.setImage(UIImage(systemName: warmth.symbolName), for: .normal)

        let title = NSAttributedString(
            string: warmth.localizedName,
            attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold)]
        )
        button.setAttributedTitle(title, for: .normal)

        button.addAction(UIAction { [weak self] _ in
            guard let self = self,
                  let picked = Warmth(rawValue: button.tag),
                  picked != self.selectedWarmth else { return }
            self.selectedWarmth = picked
            self.delegate?.warmthSelected(picked)
        }, for: .touchUpInside)

        return button
    }

    private func updateAppearance() {
        for pill in pillButtons {
            let isSelected = pill.tag == selectedWarmth.rawValue
            UIView.animate(withDuration: 0.2) {
                pill.backgroundColor = isSelected ? .accent : .clear
            }
            pill.tintColor = isSelected ? .label : .secondaryLabel
            pill.setTitleColor(isSelected ? .label : .secondaryLabel, for: .normal)
        }
    }
}
