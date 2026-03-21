//
//  OutfitSubmitController.swift
//  Drssed
//
//  Created by David Riegel on 25.09.25.
//

import UIKit

class OutfitComposerViewController_Submit: UIViewController {
    private let outfitRepo: OutfitRepository = AppRepository.shared.outfitRepository
    
    private let outfitScene: [CanvasPlacement]
    private let initialPreviewImage: UIImage
    
    var selectedSeasonsArray: [Seasons] = [] {
        didSet {
            var selected = [String]()
            if selectedSeasonsArray.contains(.SPRING) { selected.append(String(localized: "common.season.spring"))}
            if selectedSeasonsArray.contains(.SUMMER) { selected.append(String(localized: "common.season.summer"))}
            if selectedSeasonsArray.contains(.AUTUMN) { selected.append(String(localized: "common.season.autumn"))}
            if selectedSeasonsArray.contains(.WINTER) { selected.append(String(localized: "common.season.winter"))}
            
            
            outfitSeasonsSelection.text = selected.joined(separator: ", ")
            outfitSeasonsSelection.textColor = .label
            
            if selected.isEmpty {
                outfitSeasonsSelection.textColor = .placeholderText
                outfitSeasonsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    var selectedTagsArray: [Tags] = [] {
        didSet {
            var selected = [String]()
            if selectedTagsArray.contains(.CASUAL) { selected.append(String(localized: "common.tag.casual"))}
            if selectedTagsArray.contains(.FORMAL) { selected.append(String(localized: "common.tag.formal"))}
            if selectedTagsArray.contains(.SPORTS) { selected.append(String(localized: "common.tag.sports"))}
            if selectedTagsArray.contains(.VINTAGE) { selected.append(String(localized: "common.tag.vintage"))}
            
            
            outfitTagsSelection.text = selected.joined(separator: ", ")
            outfitTagsSelection.textColor = .label
            
            if selected.isEmpty {
                outfitTagsSelection.textColor = .placeholderText
                outfitTagsSelection.text = String(localized: "common.none")
            }
        }
    }
    
    init(_ outfitScene: [CanvasPlacement], previewImage: UIImage) {
        self.outfitScene = outfitScene
        self.initialPreviewImage = previewImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        previewImageView.image = initialPreviewImage
        
        configureViewComponents()
    }
    
    override func viewDidLayoutSubviews() {
        finishButton.layer.cornerRadius = CornerStyle.medium.radius(for: finishButton)
    }
    
    // MARK: -- Image
    
    lazy var previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(named: "placeholder.upload")
        iv.isUserInteractionEnabled = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: -- Name
    
    lazy var outfitNameField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.name.title"), placeholder: String(localized: "common.placeholder.name"), charCounterWithCharacters: 50)
        view.fieldInput.delegate = self
        return view
    }()
    
    // MARK: -- Favorite
    
    lazy var outfitFavoriteField: CustomSwitchInput = {
        let view = CustomSwitchInput(fieldTitle: String(localized: "common.favorite.title"))
        return view
    }()
    
    // MARK: -- Public
    
    lazy var outfitPublicField: CustomSwitchInput = {
        let view = CustomSwitchInput(fieldTitle: String(localized: "common.public.title"))
        return view
    }()
  
    // MARK: -- Seasons
    
    lazy var outfitSeasonsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.season.title"))
        view.fieldInput.isUserInteractionEnabled = true
        view.fieldInput.addTarget(self, action: #selector(showSeasonsPickerView), for: .touchUpInside)
        return view
    }()
    
    lazy var outfitSeasonsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = String(localized: "common.none")
        return label
    }()
    
    lazy var seasonsPickerView: SeasonsPickerView = {
        let view = SeasonsPickerView(delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    // MARK: -- Tags
    
    lazy var outfitTagsField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "common.tag.title"))
        view.fieldInput.isUserInteractionEnabled = true
        view.fieldInput.addTarget(self, action: #selector(showTagsPickerView), for: .touchUpInside)
        return view
    }()
    
    lazy var outfitTagsSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = String(localized: "common.none")
        return label
    }()
    
    lazy var tagsPickerView: TagsPickerView = {
        let view = TagsPickerView(delegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.isHidden = true
        view.alpha = 0
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 1
        return view
    }()
    
    // MARK: -- Finish
    
    lazy var finishButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: String(localized: "clothingupload.button.finish"), attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .accent
        return button
    }()
    
    @objc
    func cancelTapped() {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popViewController(animated: true)
    }
    
    func returnToLookbook() {
        tabBarController?.tabBar.isHidden = false
        
        guard let lookbookVC = navigationController?.viewControllers.compactMap({ $0 as? OutfitsGalleryViewController }).first else { return }
        
        navigationController?.popToViewController(lookbookVC, animated: true)
    }
    
    @objc func showSeasonsPickerView() {
        seasonsPickerView.showSeasonsPickerView()
        showInteractionBlocker()
        view.bringSubviewToFront(seasonsPickerView)
    }
    
    @objc func hideSeasonsPickerView() {
        seasonsPickerView.hideSeasonsPickerView()
        hideInteractionBlocker()
    }
    
    @objc func showTagsPickerView() {
        tagsPickerView.showTagsPickerView()
        showInteractionBlocker()
        view.bringSubviewToFront(tagsPickerView)
    }
    
    @objc func hideTagsPickerView() {
        tagsPickerView.hideTagsPickerView()
        hideInteractionBlocker()
    }

    // MARK: -- View configuration
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "outfitcomposer.submit.title")
        
        tabBarController?.tabBar.isHidden = true
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            previewImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor)
        ])
        
        view.addSubview(outfitNameField)
        NSLayoutConstraint.activate([
            outfitNameField.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 10),
            outfitNameField.leadingAnchor.constraint(equalTo: previewImageView.leadingAnchor),
            outfitNameField.trailingAnchor.constraint(equalTo: previewImageView.trailingAnchor),
            outfitNameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
    
        view.addSubview(outfitSeasonsField)
        outfitSeasonsField.addSubview(outfitSeasonsSelection)
        NSLayoutConstraint.activate([
            outfitSeasonsField.topAnchor.constraint(equalTo: outfitNameField.bottomAnchor, constant: 10),
            outfitSeasonsField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            outfitSeasonsField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            outfitSeasonsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            outfitSeasonsSelection.topAnchor.constraint(equalTo: outfitSeasonsField.fieldBackground.topAnchor),
            outfitSeasonsSelection.leadingAnchor.constraint(equalTo: outfitSeasonsField.leadingAnchor),
            outfitSeasonsSelection.trailingAnchor.constraint(equalTo: outfitSeasonsField.trailingAnchor),
            outfitSeasonsSelection.bottomAnchor.constraint(equalTo: outfitSeasonsField.fieldBackground.bottomAnchor)
        ])
        
        let sv = UIStackView(arrangedSubviews: [outfitTagsField, outfitFavoriteField])
        // check if user is signed in
        if false {
            sv.addArrangedSubview(outfitPublicField)
        }
        
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 5
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        NSLayoutConstraint.activate([
            sv.topAnchor.constraint(equalTo: outfitSeasonsField.bottomAnchor, constant: 10),
            sv.leadingAnchor.constraint(equalTo: previewImageView.leadingAnchor),
            sv.trailingAnchor.constraint(equalTo: previewImageView.trailingAnchor),
        ])
        
        outfitTagsField.addSubview(outfitTagsSelection)
        NSLayoutConstraint.activate([
            outfitTagsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),
            
            outfitTagsSelection.topAnchor.constraint(equalTo: outfitTagsField.fieldBackground.topAnchor),
            outfitTagsSelection.leadingAnchor.constraint(equalTo: outfitTagsField.leadingAnchor, constant: 5),
            outfitTagsSelection.trailingAnchor.constraint(equalTo: outfitTagsField.indicatorImageView.leadingAnchor, constant: -5),
            outfitTagsSelection.bottomAnchor.constraint(equalTo: outfitTagsField.fieldBackground.bottomAnchor)
        ])
        
        view.addSubview(finishButton)
        NSLayoutConstraint.activate([
            finishButton.topAnchor.constraint(equalTo: sv.bottomAnchor, constant: 20),
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.heightAnchor.constraint(equalToConstant: 45),
            finishButton.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2)
        ])
        
        finishButton.addAction(UIAction(handler: { _ in
            Task {
                let outfit = Outfit(
                    name: self.outfitNameField.fieldInput.text ?? "",
                    imageID: "",
                    itemDescription: "",
                    seasons: self.selectedSeasonsArray,
                    tags: self.selectedTagsArray,
                    scene: self.outfitScene
                )
                
                await self.outfitRepo.addOrUpdateOutfit(from: outfit)
                
                let alert = UIAlertController(title: nil, message: String(localized: "outfitcomposer.alert.success"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default, handler: { _ in
                    NotificationCenter.default.post(name: .outfitCreated, object: nil)
                    self.returnToLookbook()
                }))
                        
                return self.present(alert, animated: true)
            }
        }), for: .primaryActionTriggered)
        
        
        view.addSubview(seasonsPickerView)
        seasonsPickerView.topAnchor.constraint(equalTo: outfitSeasonsField.bottomAnchor, constant: 15).isActive = true
        seasonsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        seasonsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        seasonsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        
        view.addSubview(tagsPickerView)
        tagsPickerView.topAnchor.constraint(equalTo: outfitTagsField.bottomAnchor, constant: 15).isActive = true
        tagsPickerView.heightAnchor.constraint(equalToConstant: self.view.frame.width / 4).isActive = true
        tagsPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        tagsPickerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
    }
}

extension OutfitComposerViewController_Submit: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case outfitNameField.fieldInput:
            if string == "" { return true }
            
            guard outfitNameField.fieldInput.text?.count ?? 0 < 50 else { return false }
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension OutfitComposerViewController_Submit: SeasonsPickerViewDelegate {
    func seasonSelected(_ season: Seasons) {
        if let idx = selectedSeasonsArray.firstIndex(of: season) {
            selectedSeasonsArray.remove(at: idx)
        } else {
            selectedSeasonsArray.append(season)
        }
    }
    
    func seasonsDoneButtonPressed() {
        self.hideSeasonsPickerView()
    }
}

extension OutfitComposerViewController_Submit: TagsPickerViewDelegate {
    func tagSelected(_ tag: Tags) {
        if let idx = selectedTagsArray.firstIndex(of: tag) {
            selectedTagsArray.remove(at: idx)
        } else {
            selectedTagsArray.append(tag)
        }
    }
    
    func tagsDoneButtonPressed() {
        hideTagsPickerView()
    }
}
