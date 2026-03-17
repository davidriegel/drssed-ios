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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard email != nil, password != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
    }
    
    var email: String? = nil
    var password: String? = nil
    var changedPicture: Bool = false
    var defaultAvatar: String = "default_" + ["hat", "scarf", "tshirt", "cap", "sweater"].randomElement()! + "_profilepicture" {
        didSet {
            changedPicture = false
            profilePictureImageView.image = UIImage(named: defaultAvatar)
        }
    }
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
        
        iv.image = UIImage(named: defaultAvatar)
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "photo.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: 45).isActive = true
        button.layer.cornerRadius = 45 / 5
        button.addTarget(self, action: #selector(changeProfilePicture), for: .touchUpInside)
        return button
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
        bt.backgroundColor = .accent
        bt.layer.cornerRadius = 5
        bt.setTitle("Sign Up", for: .normal)
        bt.setTitleColor(UIColor.label, for: .normal)
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .black)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(proceed), for: .touchUpInside)
        return bt
    }()
    
    @objc
    func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }
    
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
        let alert = UIAlertController(title: "", message: "Pick your profile picture.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Default avatars", style: .default, handler: { _ in
            let defaultAvatarPicker = DefaultAvatarPickerController(delegate: self)
            let navigationController = UINavigationController(rootViewController: defaultAvatarPicker)
            self.present(navigationController, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Camera roll", style: .default, handler: { _ in
            self.present(self.imagePickerController, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            // cancel
        }))
        
        self.present(alert, animated: true)
    }
    
    @objc
    func removeProfilePicture() {
        guard changedPicture else {
            return
        }
        
        profilePictureImageView.image = UIImage(named: defaultAvatar)
        changedPicture = false
    }
    
    @objc
    func proceed() {
        Task {/*
            do {
                let tokenResponse = try await APIClient.shared.authHandler.signUpWith(email: self.email!, username: self.usernameTextField.text!, password: self.password!, andProfilePicture: self.defaultAvatar.replacingOccurrences(of: "profilepicture", with: "light"))
                UserDefaults.standard.set(tokenResponse.access_token, forKey: "access_token")
                UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)), forKey: "expires_at")
                UserDefaults.standard.set(tokenResponse.refresh_token, forKey: "refresh_token")
            } catch AuthenticationError.emailAlreadyInUse {
                let alert = UIAlertController(title: "", message: "This email adress is already in use.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            } catch AuthenticationError.usernameAlreadyInUse {
                let alert = UIAlertController(title: "", message: "This username is already in use.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            } catch APIError.tooManyRequests {
                let alert = UIAlertController(title: "", message: "You're being rate limited... wait a minute and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                
                return present(alert, animated: true)
            } catch {
                assertionFailure("\(error)")
                ErrorHandler.handle(error)
                return
            }
            
            if changedPicture {
                do {
                    let _ = try await APIClient.shared.userHandler.setProfilePicture(with: profilePictureImageView.image!, fileExtension)
                } catch APIError.badRequest {
                    let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. (Don't worry you can pick a profile picture later.)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default))
                    present(alert, animated: true)
                } catch {
                    let alert = UIAlertController(title: "Unexpected Error", message: "Something went wrong. (Don't worry you can pick a profile picture later.)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default))
                    present(alert, animated: true)
                }
            }
               */
            
            view.window?.rootViewController = TabBarController()
        }
    }
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = ""
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.accent, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        
        view.addSubview(profilePictureImageView)
        profilePictureImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 125).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        profilePictureImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let profilePicture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture))
        profilePictureImageView.addGestureRecognizer(profilePicture)
        
        view.addSubview(galleryButton)
        galleryButton.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 20).isActive = true
        galleryButton.bottomAnchor.constraint(equalTo: profilePictureImageView.centerYAnchor, constant: -5).isActive = true
        
        view.addSubview(trashButton)
        trashButton.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 20).isActive = true
        trashButton.topAnchor.constraint(equalTo: profilePictureImageView.centerYAnchor, constant: 5).isActive = true
        
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

extension welcomeController: UIDefaultAvatarPickerDelegate {
    func defaultAvatarPicker(_ image: UIImage, _ named: String) {
        self.defaultAvatar = named
    }
}
