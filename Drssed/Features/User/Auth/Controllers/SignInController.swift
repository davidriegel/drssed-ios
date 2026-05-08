//
//  SignInController.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import UIKit

class SignInController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
    }
    
    // MARK: -- Logo
    
    lazy var logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        
        iv.image = UIImage(named: "hanger")
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    // MARK: -- Username
    
    lazy var emailField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.email"), placeholder: String(localized: "auth.signin.email.placeholder"))
        view.fieldInput.delegate = self
        view.fieldInput.textContentType = .emailAddress
        view.fieldInput.autocapitalizationType = .none
        view.fieldInput.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return view
    }()
    
    // MARK: -- Password
    
    lazy var passwordField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(fieldTitle: String(localized: "common.password"), placeholder: String(localized: "auth.signin.password.placeholder"))
        view.fieldInput.autocapitalizationType = .none
        view.fieldInput.isSecureTextEntry = true
        view.fieldInput.delegate = self
        view.fieldInput.textContentType = .password
        view.fieldInput.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return view
    }()
    
    // MARK: -- Sign In Button
    
    lazy var signInButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { _ in
            self.handleSignIn()
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
    
    lazy var signUpTextButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        var title = NSMutableAttributedString(string: String(localized: "auth.signin.signup.cta1") + " ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.label, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .bold)])
        title.append(NSAttributedString(string: String(localized: "auth.signin.signup.cta2"), attributes: [NSAttributedString.Key.foregroundColor : UIColor.accent, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .black)]))
        bt.setAttributedTitle(title, for: .normal)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(pushSignUp), for: .touchUpInside)
        return bt
    }()
    
    // MARK: -- Functions
    
    @objc
    func pushSignUp() {
        guard let nav = navigationController else { return }
        let signUpController = SignUpController()
        var stack = nav.viewControllers
        stack[stack.count - 1] = signUpController
        nav.setViewControllers(stack, animated: true)
    }
    
    @objc
    func dismissModal() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func handleSignIn() {
        Task {
            do {
                try await AuthenticationManager.shared.signInWith(email: emailField.fieldInput.text, password: passwordField.fieldInput.text ?? "")
                self.view.window?.rootViewController = TabBarController()
            } catch APIError.unauthorized {
                ErrorHandler.handle(AuthenticationError.invalidCredentials)
            } catch {
                ErrorHandler.handle(error)
            }
            
            signInButton.backgroundColor = .accent.withAlphaComponent(0.3)
            signInButton.isEnabled = false
        }
    }
    
    @objc
    func checkTextFieldInputs() {
        guard let email = emailField.fieldInput.text, let password = passwordField.fieldInput.text else {
            signInButton.backgroundColor = .accent.withAlphaComponent(0.3)
            signInButton.isEnabled = false
            return
        }
        
        let containsIllegalCharacters = !(email.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "_" || $0 == "." || $0 == "-" || $0 == "+" || $0 == "@" })
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidEmail = emailPredicate.evaluate(with: email)
        
        guard (email.count >= 3) && (password.count >= 8) && !containsIllegalCharacters && isValidEmail else {
            signInButton.backgroundColor = .accent.withAlphaComponent(0.3)
            signInButton.isEnabled = false
            return
        }
        
        signInButton.backgroundColor = .accent
        signInButton.isEnabled = true
    }
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "auth.signin.title")
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
        
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),
            logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor)
        ])
        
        view.addSubview(emailField)
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
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
        
        view.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 45),
            signInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2)
        ])
        
        view.addSubview(signUpTextButton)
        signUpTextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        signUpTextButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signUpTextButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension SignInController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField.fieldInput {
            passwordField.fieldInput.becomeFirstResponder()
        }
        else {
            view.endEditing(true)
            if signInButton.isEnabled {
                Task {
                    handleSignIn()
                }
            }
        }
        
        return true
    }
}
