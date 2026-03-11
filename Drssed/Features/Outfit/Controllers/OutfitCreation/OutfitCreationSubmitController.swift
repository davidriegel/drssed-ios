//
//  OutfitCreationSubmitController.swift
//  Drssed
//
//  Created by David Riegel on 15.08.25.
//

import UIKit

class OutfitCreationSubmitController: UIViewController, ClothingImagePreviewDelegate {
    func didTapOnImage(_ clothing: Clothing) {
        present(ClothingDetailsController(clothing, editable: false), animated: true)
    }
    
    private var outfitClothes: [Clothing] = []
    
    var selectedSeasonsArray: [Seasons] = [] {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains(.SPRING) { selected.append(String(localized: "common.season.spring"))}
            if selectedSeasonsArray.contains(.SUMMER) { selected.append(String(localized: "common.season.summer"))}
            if selectedSeasonsArray.contains(.AUTUMN) { selected.append(String(localized: "common.season.autumn"))}
            if selectedSeasonsArray.contains(.WINTER) { selected.append(String(localized: "common.season.winter"))}
            
            
            seasonsSelection.text = selected.joined(separator: ", ")
            seasonsSelection.textColor = .label
            
            if selected.isEmpty {
                seasonsSelection.textColor = .placeholderText
                seasonsSelection.text = "none"
            }
        }
    }
    
    init(outfitClothes clothes: [Clothing]) {
        super.init(nibName: nil, bundle: nil)
        
        self.outfitClothes = clothes
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    // MARK: -- Seasons
    
    lazy var seasonsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "seasons"
        return label
    }()
    
    lazy var seasonsBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 18).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 18) / 4.16
        return view
    }()
    
    lazy var seasonsButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var seasonsIndidicatorImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 25).isActive = true
        iv.widthAnchor.constraint(equalToConstant: 25).isActive = true
        return iv
    }()
    
    lazy var seasonsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = "none"
        return label
    }()
    
    lazy var seasonsPickerView: SeasonsPickerView = {
        let view = SeasonsPickerView(delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        view.widthAnchor.constraint(equalToConstant: self.view.frame.width / 1.5).isActive = true
        view.layer.cornerRadius = (self.view.frame.width / 5) / 4.16
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    private lazy var itemsLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.text = "clothing items"
        lb.font = .systemFont(ofSize: 12, weight: .black)
        lb.textColor = .label
        lb.numberOfLines = 1
        lb.textAlignment = .natural
        return lb
    }()
    
    private lazy var outfitClothesPreview: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.spacing = 5
        sv.alignment = .center
        sv.distribution = .fillEqually
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        sv.axis = .horizontal
        return sv
    }()
    
    private lazy var createButton: UIButton = {
        var config = UIButton.Configuration.bordered()
        config.baseBackgroundColor = .accent
        config.baseForegroundColor = .label
        config.attributedTitle = AttributedString("save outfit", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]))
        
        let action = UIAction { [weak self] _ in
            self?.finishOutfit()
        }
        let button = UIButton(configuration: config, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc private func toggleSeasonsPickerView() {
        guard seasonsPickerView.isHidden else {
            seasonsPickerView.hideSeasonsPickerView()
            return hideInteractionBlocker()
        }
        
        seasonsPickerView.showSeasonsPickerView()
        showInteractionBlocker()
        view.bringSubviewToFront(seasonsPickerView)
    }
    
    private func finishOutfit() {
        Task {
            var clothing_ids: [String] = []
            
            for clothing in outfitClothes {
                clothing_ids.append(clothing.id)
            }
            
            do {
                //let _ = try await APIHandler.shared.outfitHandler.createNewOutfit(name: "nameTextField.text2", is_public: true, clothing_ids: clothing_ids, description: nil, tags: nil, seasons: nil)
                
                print("Successfully created outfit.")
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .background
        title = "outfit"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(seasonsLabel)
        seasonsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        seasonsLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(seasonsBackgroundView)
        seasonsBackgroundView.topAnchor.constraint(equalTo: seasonsLabel.bottomAnchor, constant: 5).isActive = true
        seasonsBackgroundView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        seasonsBackgroundView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        seasonsBackgroundView.addSubview(seasonsIndidicatorImage)
        seasonsIndidicatorImage.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor, constant: -15).isActive = true
        seasonsIndidicatorImage.centerYAnchor.constraint(equalTo: seasonsBackgroundView.centerYAnchor).isActive = true
        
        seasonsBackgroundView.addSubview(seasonsButton)
        seasonsButton.topAnchor.constraint(equalTo: seasonsBackgroundView.topAnchor).isActive = true
        seasonsButton.leftAnchor.constraint(equalTo: seasonsBackgroundView.leftAnchor).isActive = true
        seasonsButton.bottomAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor).isActive = true
        seasonsButton.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor).isActive = true
        seasonsButton.addTarget(self, action: #selector(toggleSeasonsPickerView), for: .touchUpInside)
        
        seasonsBackgroundView.addSubview(seasonsSelection)
        seasonsSelection.leftAnchor.constraint(equalTo: seasonsBackgroundView.leftAnchor, constant: 5).isActive = true
        seasonsSelection.rightAnchor.constraint(equalTo: seasonsBackgroundView.rightAnchor, constant: -5).isActive = true
        seasonsSelection.centerYAnchor.constraint(equalTo: seasonsBackgroundView.centerYAnchor).isActive = true
        
        view.addSubview(seasonsPickerView)
        seasonsPickerView.topAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor, constant: 15).isActive = true
        seasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        view.addSubview(itemsLabel)
        NSLayoutConstraint.activate([
            itemsLabel.topAnchor.constraint(equalTo: seasonsBackgroundView.bottomAnchor, constant: 15),
            itemsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            itemsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        view.addSubview(outfitClothesPreview)
        NSLayoutConstraint.activate([
            outfitClothesPreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            outfitClothesPreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            outfitClothesPreview.topAnchor.constraint(equalTo: itemsLabel.bottomAnchor, constant: 10)
        ])

        for clothing in outfitClothes {
            let previewView = ClothingImagePreview(clothing: clothing)
            previewView.delegate = self
            outfitClothesPreview.addArrangedSubview(previewView)
        }
        
        view.addSubview(createButton)
        NSLayoutConstraint.activate([
            createButton.topAnchor.constraint(equalTo: outfitClothesPreview.bottomAnchor, constant: 10),
            createButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            createButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

extension OutfitCreationSubmitController: SeasonsPickerViewDelegate {
    func seasonSelected(_ season: Seasons) {
        if let idx = selectedSeasonsArray.firstIndex(of: season) {
            selectedSeasonsArray.remove(at: idx)
        } else {
            selectedSeasonsArray.append(season)
        }
    }
    
    func seasonsDoneButtonPressed() {
        self.toggleSeasonsPickerView()
    }
}
