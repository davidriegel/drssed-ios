//
//  TagPickerView.swift
//  Clothing Booth
//
//  Created by David Riegel on 17.04.25.
//


import UIKit

protocol TagPickerViewDelegate: AnyObject {
    func tagPickerView(_ pickerView: TagPickerView, didSelectTag tag: String)
    func tagPickerViewDidTapDone(_ pickerView: TagPickerView)
}

class TagPickerView: UIView {
    
    private var tags: [(emoji: String, title: String)] = []
    private var tagButtons: [UIButton] = []
    
    weak var delegate: TagPickerViewDelegate?
    
    private let tagsStackView = UIStackView()
    private let tagsPickerDone = UIButton()
    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Öffentliche Methode zum Konfigurieren

    func configure(with tags: [(emoji: String, title: String)]) {
        self.tags = tags
        createTagButtons()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        
        // StackView
        tagsStackView.axis = .horizontal
        tagsStackView.spacing = 8
        tagsStackView.distribution = .fillEqually
        tagsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tagsStackView)
        
        // Selection Label
        tagsSelection.translatesAutoresizingMaskIntoConstraints = false
        tagsSelection.font = .systemFont(ofSize: 13, weight: .heavy)
        tagsSelection.textAlignment = .center
        tagsSelection.textColor = .placeholderText
        tagsSelection.text = "none"
        addSubview(tagsSelection)
        
        // Done Button
        let doneTitle = NSAttributedString(
            string: "Done",
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold)]
        )
        tagsPickerDone.setAttributedTitle(doneTitle, for: .normal)
        tagsPickerDone.setTitleColor(.label, for: .normal)
        tagsPickerDone.translatesAutoresizingMaskIntoConstraints = false
        tagsPickerDone.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        addSubview(tagsPickerDone)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            tagsStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            tagsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tagsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            tagsSelection.topAnchor.constraint(equalTo: tagsStackView.bottomAnchor, constant: 12),
            tagsSelection.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            tagsPickerDone.topAnchor.constraint(equalTo: tagsSelection.bottomAnchor, constant: 12),
            tagsPickerDone.centerXAnchor.constraint(equalTo: centerXAnchor),
            tagsPickerDone.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func createTagButtons() {
        // Alte Buttons entfernen
        tagButtons.forEach { tagsStackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        tagButtons.removeAll()

        // Neue Buttons erzeugen
        for tag in tags {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.backgroundColor = .systemBackground
            
            let title = NSAttributedString(
                string: "\(tag.emoji) \(tag.title)",
                attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)]
            )
            button.setAttributedTitle(title, for: .normal)
            button.addTarget(self, action: #selector(tagButtonTapped(_:)), for: .touchUpInside)
            
            tagButtons.append(button)
            tagsStackView.addArrangedSubview(button)
        }
    }

    // MARK: - Actions

    @objc private func tagButtonTapped(_ sender: UIButton) {
        guard let title = sender.attributedTitle(for: .normal)?.string else { return }
        tagsSelection.text = title
        delegate?.tagPickerView(self, didSelectTag: title)
    }

    @objc private func doneTapped() {
        delegate?.tagPickerViewDidTapDone(self)
    }
}
