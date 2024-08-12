//
//  welcomeController.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import UIKit

class welcomeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }
    
    var changedPicture: Bool = false
    var fileExtension: String = ""
    
    lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        return picker
    }()
    
    lazy var profilePictureImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "profilepicture_placeholder")
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    lazy var trashButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "trash.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.layer.cornerRadius = 45 / 5
        button.addTarget(self, action: #selector(removeProfilePicture), for: .touchUpInside)
        return button
    }()
    
    lazy var welcomeLabel: UILabel = {
        var lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.textColor = .label
        lb.textAlignment = .center
        lb.numberOfLines = 0
        let question = NSMutableAttributedString(string: "and how should we call you?", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .black)])
        let required = NSMutableAttributedString(string: "\ra profile picture is not required", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .medium)])
        question.append(required)
        lb.attributedText = question
        return lb
    }()
    
    lazy var usernameTextField: UITextField = {
        var tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = .label
        tf.attributedPlaceholder = NSAttributedString(string: "Username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tf.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        tf.backgroundColor = .secondarySystemBackground
        tf.borderStyle = .bezel
        tf.isSecureTextEntry = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.returnKeyType = .continue
        tf.delegate = self
        tf.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return tf
    }()
    
    lazy var doneButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.alpha = 0.2
        bt.isEnabled = false
        bt.backgroundColor = .label
        bt.layer.cornerRadius = 5
        bt.setTitle("Sign Up", for: .normal)
        bt.setTitleColor(UIColor.systemBackground, for: .normal)
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .black)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(proceed), for: .touchUpInside)
        return bt
    }()
    
    @objc
    func checkTextFieldInputs(_ textField: UITextField) {
        if !(usernameTextField.text?.count ?? 0 > 2) || (usernameTextField.text?.count ?? 0 > 32) {
            doneButton.alpha = 0.2
            doneButton.isEnabled = false
            return
        }
        
        doneButton.alpha = 1
        doneButton.isEnabled = true
    }
    
    @objc
    func changeProfilePicture() {
        self.present(self.imagePickerController, animated: true)
    }
    
    @objc
    func removeProfilePicture() {
        guard changedPicture else {
            return
        }
        
        profilePictureImageView.image = UIImage(named: "profilepicture_placeholder")
        changedPicture = false
    }
    
    @objc
    func proceed() {
        Task {
            let success1 = await setUsername()
            var success2 = true
            if changedPicture {
                success2 = await setProfilePicture()
            }
            
            
            if success1 && success2 {
                view.window?.rootViewController = TabBarController()
            }
        }
    }
    
    func setProfilePicture() async -> Bool {
        do {
            try await APIHandler.shared.setProfilePicture(with: profilePictureImageView.image!, fileExtension)
            return true
        } catch NetworkingError.badRequest {
            let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. []", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
            return false
        } catch let e {
            print(e)
            let alert = UIAlertController(title: "", message: "An unexpected error happened.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
            return false
        }
    }
    
    func setUsername() async -> Bool {
        do {
            try await APIHandler.shared.setUsername(username: usernameTextField.text ?? "")
            return true
        } catch NetworkingError.badRequest {
            return true
        } catch NetworkingError.conflict {
            let alert = UIAlertController(title: "", message: "This username is already in use.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
            return false
        } catch let e {
            print(e)
            let alert = UIAlertController(title: "", message: "An unexpected error happened.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
            return false
        }
    }
    
    func configureViewComponents() {
        view.backgroundColor = .systemBackground
        title = ""
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(profilePictureImageView)
        profilePictureImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        profilePictureImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let profilePicture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture))
        profilePictureImageView.addGestureRecognizer(profilePicture)
        
        view.addSubview(trashButton)
        trashButton.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 20).isActive = true
        trashButton.centerYAnchor.constraint(equalTo: profilePictureImageView.centerYAnchor).isActive = true
        
        view.addSubview(welcomeLabel)
        welcomeLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 20).isActive = true
        welcomeLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        welcomeLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(usernameTextField)
        usernameTextField.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20).isActive = true
        usernameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        usernameTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        usernameTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true

        view.addSubview(doneButton)
        doneButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20).isActive = true
        doneButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension welcomeController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        if doneButton.isEnabled {
            Task {
                proceed()
            }
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !(usernameTextField.text?.count ?? 0 >= 32) else {
            return string.isEmpty ? true : false
        }
        
        return true
    }
}

extension welcomeController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            guard let image = info[.editedImage] as? UIImage else { return }
            let assetPath = info[.imageURL] as! NSURL
            self.fileExtension = (assetPath.absoluteString ?? "").components(separatedBy: ".").last ?? ""
            
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. [\(fileExtension)]", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                present(alert, animated: true)
                return
            }
            
            profilePictureImageView.image = image
            changedPicture = true
            
            dismiss(animated: true)
        }
    }
}
