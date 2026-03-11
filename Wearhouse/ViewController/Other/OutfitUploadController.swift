//
//  OutfitUploadController.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.25.
//

import UIKit

class OutfitUploadController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    private lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.layer.cornerCurve = .continuous
        //tf.layer.cornerRadius = 12
        tf.backgroundColor = .secondarySystemBackground
        tf.placeholder = "Super cool summer outfit"
        return tf
    }()
    
    private lazy var createButton: UIButton = {
        //let button = UIButton(type: .roundedRect)
        //button.translatesAutoresizingMaskIntoConstraints = false
        //button.setTitle("Done", for: .normal)
        //button.backgroundColor = .secondarySystemBackground
        var config = UIButton.Configuration.bordered()
        config.title = "Done"
        config.baseBackgroundColor = .secondarySystemBackground
            
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(createMockOutfit), for: .touchUpInside)
        return button
    }()
    
    @objc private func createMockOutfit() {
        Task {
            do {
                //let _ = try await APIHandler.shared.outfitHandler.createNewOutfit(name: "nameTextField.text2", is_public: true, clothing_ids: ["e9b9b5b8-e67f-4207-aa9b-f108b974af5b", "e9b9b5b8-e67f-4207-aa9b-f108b974af5b"], description: nil, tags: nil, seasons: nil)
                
                print("Successfully created outfit.")
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
    
    private func configureViewComponents() {
        title = "creator"
        
        view.addSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
        
        view.addSubview(createButton)
        createButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        createButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        createButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        createButton.topAnchor.constraint(equalTo: view.subviews[view.subviews.endIndex - 2].bottomAnchor, constant: 10).isActive = true
    }
}
