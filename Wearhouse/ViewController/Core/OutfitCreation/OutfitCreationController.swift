//
//  OutfitCreation+Controller.swift
//  Wearhouse
//
//  Created by David Riegel on 13.08.25.
//

import UIKit

class OutfitCreationController: UIViewController {
    private let clothingRepo: ClothingRepository = ClothingRepository()
    
    private var visibleContainer: [ClothingCategories] = []
    
    var dataSoutce: [ClothingLocal] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        updateData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        saveButton.layer.cornerRadius = CornerStyle.large.radius(for: saveButton) // 45 / 5
        shuffleButton.layer.cornerRadius = CornerStyle.large.radius(for: shuffleButton) // 45 / 5
    }
    
    func updateData() -> Void {
        Task {
            jacketContainer.setDataSource(await AppRepository.shared.clothingRepository.fetchClothes(filterCategories: [.JACKET]))
            topContainer.setDataSource(await AppRepository.shared.clothingRepository.fetchClothes(filterCategories: [.TOP]))
            bottomContainer.setDataSource(await AppRepository.shared.clothingRepository.fetchClothes(filterCategories: [.BOTTOM]))
            footwearContainer.setDataSource(await AppRepository.shared.clothingRepository.fetchClothes(filterCategories: [.FOOTWEAR]))
        }
    }
    
    lazy var piecesAmountChoiceStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.spacing = 5
        view.alignment = .center
        view.distribution = .equalCentering
        view.axis = .horizontal
        return view
    }()
    
    lazy var twoClothesButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "2.square"), for: .normal)
        bt.setImage(UIImage(systemName: "2.square.fill"), for: .selected)
        bt.tintColor = .label
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .normal)
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .selected)
        bt.addTarget(self, action: #selector(twoClothingStacks), for: .touchUpInside)
        return bt
    }()
    
    lazy var threeClothesButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "3.square"), for: .normal)
        bt.setImage(UIImage(systemName: "3.square.fill"), for: .selected)
        bt.tintColor = .label
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .normal)
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .selected)
        bt.addTarget(self, action: #selector(threeClothingStacks), for: .touchUpInside)
        return bt
    }()
    
    lazy var fourClothesButton: UIButton = {
        let bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "4.square"), for: .normal)
        bt.setImage(UIImage(systemName: "4.square.fill"), for: .selected)
        bt.tintColor = .label
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .normal)
        bt.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .selected)
        bt.addTarget(self, action: #selector(fourClothingStacks), for: .touchUpInside)
        return bt
    }()
    
    lazy var containerStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.distribution = .fillEqually
        sv.spacing = 10
        return sv
    }()
    
    lazy var jacketContainer: OutfitCreation_Container = {
        let container = OutfitCreation_Container()
        return container
    }()
    
    lazy var topContainer: OutfitCreation_Container = {
        let container = OutfitCreation_Container()
        return container
    }()

    lazy var bottomContainer: OutfitCreation_Container = {
        let container = OutfitCreation_Container()
        return container
    }()

    lazy var footwearContainer: OutfitCreation_Container = {
        let container = OutfitCreation_Container()
        return container
    }()
    
    lazy var buttonContainer: UIView = {
        let container = UIView()
        return container
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: "save outfit", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .accent
        button.addTarget(self, action: #selector(saveOutfit), for: .touchUpInside)
        return button
    }()
    
    lazy var shuffleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "shuffle", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .normal) // maybe change for other icon e.g. gift.fill
        button.backgroundColor = .accent
        button.addTarget(self, action: #selector(shuffleItems), for: .touchUpInside)
        return button
    }()
    
    @objc
    private func twoClothingStacks() {
        twoClothesButton.isSelected = true
        
        threeClothesButton.isSelected = false
        fourClothesButton.isSelected = false
        
        adjustClothingStacks(stacks: [.TOP, .BOTTOM])
    }
    
    @objc
    private func threeClothingStacks() {
        threeClothesButton.isSelected = true
        
        twoClothesButton.isSelected = false
        fourClothesButton.isSelected = false
        
        adjustClothingStacks(stacks: [.TOP, .BOTTOM, .FOOTWEAR])
    }
    
    @objc
    private func fourClothingStacks() {
        fourClothesButton.isSelected = true
        
        threeClothesButton.isSelected = false
        twoClothesButton.isSelected = false
        
        adjustClothingStacks(stacks: [.JACKET, .TOP, .BOTTOM, .FOOTWEAR])
    }
    
    @objc
    private func saveOutfit() {
        var outfitClothes: [Clothing] = []
        
        for visible in visibleContainer {
            switch visible {
            case .JACKET:
                guard let clothing = jacketContainer.selectedClothing else { return }
                outfitClothes.append(clothing)
            case .TOP:
                guard let clothing = topContainer.selectedClothing else { return }
                outfitClothes.append(clothing)
            case .BOTTOM:
                guard let clothing = bottomContainer.selectedClothing else { return }
                outfitClothes.append(clothing)
            case .FOOTWEAR:
                guard let clothing = footwearContainer.selectedClothing else { return }
                outfitClothes.append(clothing)
            }
        }
        
        guard !outfitClothes.isEmpty else { return } // present alert if no clothes are selected
        
        navigationController?.pushViewController(OutfitCreationSubmitController(outfitClothes: outfitClothes), animated: true)
    }
    
    @objc
    private func shuffleItems() {
        var success: Bool = false
        
        for container in visibleContainer {
            switch container {
            case .JACKET:
                if jacketContainer.shuffleToNewItem() {
                    success = true
                }
            case .TOP:
                if topContainer.shuffleToNewItem() {
                    success = true
                }
            case .BOTTOM:
                if bottomContainer.shuffleToNewItem() {
                    success = true
                }
            case .FOOTWEAR:
                if footwearContainer.shuffleToNewItem() {
                    success = true
                }
            }
        }
        
        guard !success else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        let alert = UIAlertController(title: "All items are locked", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default))
        
        present(alert, animated: true)
    }

    
    private func adjustClothingStacks(stacks: [ClothingCategories]) {
        for subview in containerStack.arrangedSubviews {
            containerStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        visibleContainer = stacks
        
        for stack in stacks {
            switch stack {
            case .JACKET:
                containerStack.addArrangedSubview(jacketContainer)
            case .TOP:
                containerStack.addArrangedSubview(topContainer)
            case .BOTTOM:
                containerStack.addArrangedSubview(bottomContainer)
            case .FOOTWEAR:
                containerStack.addArrangedSubview(footwearContainer)
            }
        }
    }
    
    
    private func configureViewComponents() -> Void {
        view.backgroundColor = .background
        title = "creator"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(piecesAmountChoiceStackView)
        NSLayoutConstraint.activate([
            piecesAmountChoiceStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            piecesAmountChoiceStackView.heightAnchor.constraint(equalToConstant: 44),
            piecesAmountChoiceStackView.widthAnchor.constraint(equalToConstant: 150),
            piecesAmountChoiceStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        view.addSubview(saveButton)
        view.addSubview(shuffleButton)
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            saveButton.rightAnchor.constraint(equalTo: view.centerXAnchor, constant: (view.frame.width / 2) / 3),
            saveButton.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.115),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            shuffleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            shuffleButton.leftAnchor.constraint(equalTo: saveButton.rightAnchor, constant: 15),
            shuffleButton.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.115),
            shuffleButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.15)
        ])
        
        piecesAmountChoiceStackView.addArrangedSubview(twoClothesButton)
        piecesAmountChoiceStackView.addArrangedSubview(threeClothesButton)
        piecesAmountChoiceStackView.addArrangedSubview(fourClothesButton)
        
        view.addSubview(containerStack)
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: piecesAmountChoiceStackView.bottomAnchor, constant: 20),
            containerStack.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            containerStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        threeClothingStacks()
    }
}
