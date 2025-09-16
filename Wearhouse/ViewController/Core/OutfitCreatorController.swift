//
//  OutfitCreatorController.swift
//  Clothing Booth
//
//  Created by David Riegel on 16.12.24.
//

import UIKit
import SkeletonView

class OutfitCreatorController: UIViewController {
    
     private enum ClothingStacks {
        case JACKET
        case TOP
        case BOTTOM
        case FOOTWEAR
    }
    
    var jacketDataSource: [ClothingAPI] = []
    var topsDataSource: [ClothingAPI] = [] {
        didSet {
            topContainer.setDataSource(topsDataSource)
        }
    }
    var bottomsDataSource: [ClothingAPI] = []
    var footwearDataSource: [ClothingAPI] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        updateData()
        configureViewComponents()
    }
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .blue
        view.axis = .vertical
        view.spacing = 0
        return view
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: "save outfit", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.systemBackground, for: .normal)
        button.backgroundColor = .label
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
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
    
    lazy var shuffleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "gift.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .systemBackground)), for: .normal) // maybe change for other icon e.g. shuffle.fill
        button.backgroundColor = .label
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    func setupStackView() {
        for _ in 0...3 {
            let backgroundView: UIView = {
                let view = UIView()
                view.translatesAutoresizingMaskIntoConstraints = false
                //                view.backgroundColor = .red
                //                view.layer.borderColor = UIColor.white.cgColor
                //                view.layer.borderWidth = 1
                view.heightAnchor.constraint(equalToConstant: (self.view.frame.height - ((self.navigationController?.navigationBar.frame.maxY)! + (self.tabBarController?.tabBar.frame.height)!)) / 5).isActive = true
                view.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
                return view
            }()
            
            let clothingImage: UIImageView = {
                let view = UIImageView()
                view.translatesAutoresizingMaskIntoConstraints = false
                //                view.backgroundColor = .brown
                view.image = UIImage(named: "save02")
                view.isUserInteractionEnabled = true
                return view
            }()
            
            let imageButtonOverlay: UIButton = {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.addTarget(self, action: #selector(presentClothingInformation), for: .touchUpInside)
                return button
            }()
            
            // TODO: add lock button
            
            let lockButton: UIButton = {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setImage(UIImage(systemName: "lock.open.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .normal)
                button.setImage(UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .selected)
                button.addTarget(self, action: #selector(lockPiece), for: .touchUpInside)
                return button
            }()
            
            let searchButton: UIButton = {
                let button = UIButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(weight: .medium)), for: .normal)
                button.tintColor = .label
                return button
            }()
            
            stackView.addArrangedSubview(backgroundView)
            backgroundView.addSubview(clothingImage)
            clothingImage.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
            clothingImage.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
            clothingImage.heightAnchor.constraint(equalToConstant: (self.view.frame.height - ((self.navigationController?.navigationBar.frame.maxY)! + (self.tabBarController?.tabBar.frame.height)!)) / 5).isActive = true
            clothingImage.widthAnchor.constraint(equalToConstant: (self.view.frame.height - ((self.navigationController?.navigationBar.frame.maxY)! + (self.tabBarController?.tabBar.frame.height)!)) / 5).isActive = true
            
            clothingImage.addSubview(imageButtonOverlay)
            imageButtonOverlay.translatesAutoresizingMaskIntoConstraints = false
            imageButtonOverlay.topAnchor.constraint(equalTo: clothingImage.topAnchor).isActive = true
            imageButtonOverlay.bottomAnchor.constraint(equalTo: clothingImage.bottomAnchor).isActive = true
            imageButtonOverlay.leftAnchor.constraint(equalTo: clothingImage.leftAnchor).isActive = true
            imageButtonOverlay.rightAnchor.constraint(equalTo: clothingImage.rightAnchor).isActive = true
            
            backgroundView.addSubview(lockButton)
            lockButton.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
            lockButton.leftAnchor.constraint(equalTo: clothingImage.rightAnchor, constant: 30).isActive = true
            lockButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
            backgroundView.addSubview(searchButton)
            searchButton.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
            searchButton.leftAnchor.constraint(equalTo: clothingImage.leftAnchor, constant: -30).isActive = true
            searchButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
        }
    }
    
    func updateData() {
        Task {
            jacketDataSource = try await APIHandler.shared.clothingHandler.getMyClothing(category: .JACKET).clothing
            topsDataSource = try await APIHandler.shared.clothingHandler.getMyClothing(category: .TOP).clothing
            bottomsDataSource = try await APIHandler.shared.clothingHandler.getMyClothing(category: .BOTTOM).clothing
            footwearDataSource = try await APIHandler.shared.clothingHandler.getMyClothing(category: .FOOTWEAR).clothing
        }
    }
    
    @objc
    func showInfo() {
        let infoAlert = UIAlertController(title: "Info", message: "Here you can try generating yourself new outfits. You can also lock specific pieces you like in place.", preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(infoAlert, animated: true)
    }
    
    @objc
    private func lockPiece(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
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
    
    lazy var jacketContainer: ClothingStackContainer = {
        let container = ClothingStackContainer()
        
        // Set height constraints for containers
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return container
        //let container = ClothingStackContainer(identifier: "Jacket", height: Int(self.view.frame.height - ((self.navigationController?.navigationBar.frame.maxY)! + (self.tabBarController?.tabBar.frame.height)!)) / 5, width: Int(self.view.frame.width))
        //container.delegate = self

        //return container
    }()
    
    lazy var topContainer: ClothingStackContainer = {
        let container = ClothingStackContainer()
        
        // Set height constraints for containers
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return container
    }()
    
    lazy var bottomContainer: ClothingStackContainer = {
        let container = ClothingStackContainer()
        
        // Set height constraints for containers
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return container
    }()
    
    lazy var footwearContainer: ClothingStackContainer = {
        let container = ClothingStackContainer()
        
        // Set height constraints for containers
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return container
    }()
    
    private func adjustClothingStacks(stacks: [ClothingStacks]) {
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
        }
        
        for stack in stacks {
            switch stack {
            case .JACKET:
                stackView.addArrangedSubview(jacketContainer)
            case .TOP:
                stackView.addArrangedSubview(topContainer)
            case .BOTTOM:
                stackView.addArrangedSubview(bottomContainer)
            case .FOOTWEAR:
                stackView.addArrangedSubview(footwearContainer)
            }
        }
    }
    
    @objc
    private func presentClothingInformation() {
        //present(CloPieceController(), animated: true)
    }
    
    private func configureViewComponents() {
        view.backgroundColor = .systemBackground
        title = "create"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.app.fill", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.systemBackground, .label])), style: .plain, target: self, action: #selector(showInfo))
        
        view.addSubview(piecesAmountChoiceStackView)
        NSLayoutConstraint.activate([
            piecesAmountChoiceStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            piecesAmountChoiceStackView.heightAnchor.constraint(equalToConstant: 44),
            piecesAmountChoiceStackView.widthAnchor.constraint(equalToConstant: 150),
            piecesAmountChoiceStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        piecesAmountChoiceStackView.addArrangedSubview(twoClothesButton)
        piecesAmountChoiceStackView.addArrangedSubview(threeClothesButton)
        piecesAmountChoiceStackView.addArrangedSubview(fourClothesButton)
        
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: piecesAmountChoiceStackView.bottomAnchor, constant: 10).isActive = true
        //setupStackView()
        
        view.addSubview(saveButton)
        saveButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 15).isActive = true
        saveButton.rightAnchor.constraint(equalTo: view.centerXAnchor, constant: (view.frame.width / 2) / 3).isActive = true
        
        view.addSubview(shuffleButton)
        shuffleButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 15).isActive = true
        shuffleButton.leftAnchor.constraint(equalTo: saveButton.rightAnchor, constant: 15).isActive = true
    }
}
