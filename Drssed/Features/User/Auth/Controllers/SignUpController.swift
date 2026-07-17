//
//  SignUpController.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import UIKit
import PhotosUI
import CropViewController

class SignUpController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }
    
    var changedPicture: Bool = false
    var defaultAvatar: String = "default_" + ["hat", "scarf", "tshirt", "cap", "sweater"].randomElement()! + "_profilepicture" {
        didSet {
            changedPicture = false
            profilePictureImageView.image = UIImage(named: defaultAvatar)
        }
    }
    
    // MARK: -- Profile picture
    
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
        let button = UIButton(primaryAction: UIAction { _ in
            self.showImageSourceOptions()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "photo.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .label)), for: .normal)
        return button
    }()
    
    // MARK: -- Username
    
    lazy var emailField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.email"), placeholder: String(localized: "auth.email.placeholder"))
        view.fieldInput.delegate = self
        view.fieldInput.textContentType = .emailAddress
        view.fieldInput.autocapitalizationType = .none
        view.fieldInput.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return view
    }()
    
    // MARK: -- Password
    
    lazy var passwordField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.password"), placeholder: String(localized: "auth.signup.password.placeholder"))
        view.fieldInput.autocapitalizationType = .none
        view.fieldInput.isSecureTextEntry = true
        view.fieldInput.delegate = self
        view.fieldInput.textContentType = .newPassword
        view.fieldInput.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return view
    }()
    
    // MARK: -- Sign Up Button
    
    lazy var signUpButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { _ in
            self.handleSignUp()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .prominentGlass()
        button.configuration?.baseBackgroundColor = .accent
        button.configuration?.baseForegroundColor = .label
        button.backgroundColor = .accent.withAlphaComponent(0.3)
        button.isEnabled = false
        button.setAttributedTitle(NSAttributedString(string: String(localized: "common.continue"), attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        return button
    }()
    
    // MARK: -- Sign In Button
    
    lazy var signInTextButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        var title = NSMutableAttributedString(string: String(localized: "auth.signup.signin.cta1") + " ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.label, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .bold)])
        title.append(NSAttributedString(string: String(localized: "auth.signup.signin.cta2"), attributes: [NSAttributedString.Key.foregroundColor : UIColor.accent, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .black)]))
        bt.setAttributedTitle(title, for: .normal)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(pushSignIn), for: .touchUpInside)
        return bt
    }()
    
    // MARK: - Functions
    
    @objc
    func pushSignIn() {
        guard let nav = navigationController else { return }
        let signInController = SignInController()
        var stack = nav.viewControllers
        stack[stack.count - 1] = signInController
        nav.setViewControllers(stack, animated: true)
    }
    
    @objc
    func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func handleSignUp() {
        signUpButton.backgroundColor = .accent.withAlphaComponent(0.3)
        signUpButton.isEnabled = false
        
        Task {
            do {
                _ = try await AuthenticationManager.shared.upgradeAccount(email: emailField.fieldInput.text, password: passwordField.fieldInput.text ?? "", profilePicture: String(defaultAvatar.split(separator: "_")[1]))
                self.dismissModal()
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
    
    @objc
    func checkTextFieldInputs() {
        guard let email = emailField.fieldInput.text, let password = passwordField.fieldInput.text else {
            signUpButton.backgroundColor = .accent.withAlphaComponent(0.3)
            signUpButton.isEnabled = false
            return
        }
        
        let containsIllegalCharacters = !(email.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "." || $0 == "-" || $0 == "+" || $0 == "@" })
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidEmail = emailPredicate.evaluate(with: email)
        
        guard (email.count >= 3) && (password.count >= 8) && !containsIllegalCharacters && isValidEmail else {
            signUpButton.backgroundColor = .accent.withAlphaComponent(0.3)
            signUpButton.isEnabled = false
            return
        }
        
        signUpButton.backgroundColor = .accent
        signUpButton.isEnabled = true
    }
    
    @objc
    func showImageSourceOptions() {
        let actionSheet = UIAlertController(title: String(localized: "imagepicker.source.title"), message: String(localized: "imagepicker.source.message"), preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: String(localized: "imagepicker.source.library"), style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: String(localized: "imagepicker.source.default"), style: .default) { [weak self] _ in
            self?.presentDefaultPicker()
        })
        
        actionSheet.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentDefaultPicker() {
        let defaultAvatarPicker = DefaultAvatarPickerController(delegate: self)
        let navigationController = UINavigationController(rootViewController: defaultAvatarPicker)
        self.present(navigationController, animated: true)
    }
    
    private func presentCropView(with image: UIImage) {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = self
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.aspectRatioPreset = CGSize(width: 1, height: 1)
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.cancelButtonColor = .systemRed
        cropViewController.rotateButtonsHidden = true
        cropViewController.resetButtonHidden = true
        cropViewController.doneButtonColor = .accent
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    // MARK: - Configure View
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "auth.signup.title")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
        
        view.addSubview(profilePictureImageView)
        NSLayoutConstraint.activate([
            profilePictureImageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.35),
            profilePictureImageView.widthAnchor.constraint(equalTo: profilePictureImageView.heightAnchor),
            profilePictureImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
        
        let profilePicture = UITapGestureRecognizer(target: self, action: #selector(showImageSourceOptions))
        profilePictureImageView.addGestureRecognizer(profilePicture)
        
        view.addSubview(galleryButton)
        NSLayoutConstraint.activate([
            galleryButton.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 20),
            galleryButton.centerYAnchor.constraint(equalTo: profilePictureImageView.centerYAnchor)
        ])
        
        view.addSubview(emailField)
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 20),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
        
        view.addSubview(passwordField)
        NSLayoutConstraint.activate([
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20),
            passwordField.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65)
        ])
        
        view.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 45),
            signUpButton.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2)
        ])
        
        view.addSubview(signInTextButton)
        NSLayoutConstraint.activate([
            signInTextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            signInTextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            signInTextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension SignUpController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField.fieldInput {
            passwordField.fieldInput.becomeFirstResponder()
        }
        else {
            view.endEditing(true)
            if signUpButton.isEnabled {
                Task {
                    handleSignUp()
                }
            }
        }
        
        return true
    }
}

extension SignUpController: UIDefaultAvatarPickerDelegate {
    func defaultAvatarPicker(_ image: UIImage, _ named: String) {
        self.defaultAvatar = named
    }
}

extension SignUpController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    ErrorHandler.handle(error)
                }
                return
            }
            
            guard let image = object as? UIImage else { return }
            
            DispatchQueue.main.async {
                self.presentCropView(with: image)
            }
        }
    }
}

extension SignUpController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        Task {
            cropViewController.dismiss(animated: true)
            
            profilePictureImageView.image = image
        }
    }
        
    func cropViewController(_ cropViewController: CropViewController,
                            didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
