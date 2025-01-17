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
    
    lazy var signInLabel: UILabel = {
        var lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 24, weight: .black)
        lb.textAlignment = .center
        lb.text = "welcome back, sign in"
        return lb
    }()
    
    lazy var signInNameTextField: UITextField = {
        var tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = .label
        tf.attributedPlaceholder = NSAttributedString(string: "Username or Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        tf.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        tf.backgroundColor = .secondarySystemBackground
        tf.borderStyle = .bezel
        tf.isSecureTextEntry = false
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.textContentType = .emailAddress
        tf.returnKeyType = .next
        tf.delegate = self
        tf.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return tf
    }()
    
    lazy var passwordTextField: UITextField = {
        var tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = .label
        tf.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        tf.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        tf.backgroundColor = .secondarySystemBackground
        tf.borderStyle = .bezel
        tf.isSecureTextEntry = true
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.textContentType = .password
        tf.returnKeyType = .continue
        tf.delegate = self
        tf.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return tf
    }()
    
    lazy var signInButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.alpha = 0.2
        bt.isEnabled = false
        bt.backgroundColor = .accent
        bt.layer.cornerRadius = 5
        bt.setTitle("Sign In", for: .normal)
        bt.setTitleColor(UIColor.label, for: .normal)
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .black)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
        return bt
    }()
    
    lazy var signUpTextButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        var title = NSMutableAttributedString(string: "Don't have an account? ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.label, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .bold)])
        title.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.foregroundColor : UIColor.accent, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .black)]))
        bt.setAttributedTitle(title, for: .normal)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(pushSignUp), for: .touchUpInside)
        return bt
    }()
    
    @objc
    func pushSignUp() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc
    func handleSignIn() {
        Task {
            do {
                let tokenResponse = try await APIHandler.shared.authHandler.signInWith(signInName: signInNameTextField.text!, andPassword: passwordTextField.text!)
                UserDefaults.standard.set(tokenResponse.access_token, forKey: "access_token")
                UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)), forKey: "expires_at")
                UserDefaults.standard.set(tokenResponse.refresh_token, forKey: "refresh_token")
                self.view.window?.rootViewController = TabBarController()
            } catch APIError.unauthorized {
                signInButton.alpha = 0.2
                signInButton.isEnabled = false
                
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: signInNameTextField.text ?? "")
                let signInUse = validEmail ? "email" : "username"
                
                let alert = UIAlertController(title: "", message: "Either your \(signInUse) or your password is wrong.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                present(alert, animated: true)
            } catch APIError.tooManyRequests {
                signInButton.alpha = 0.2
                signInButton.isEnabled = false
                let alert = UIAlertController(title: "", message: "You're being rate limited... wait a minute and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default))
                present(alert, animated: true)
            }
        }
    }
    
    @objc
    func checkTextFieldInputs(_ textField: UITextField) {
        if !(signInNameTextField.text?.count ?? 0 > 2) || !(passwordTextField.text?.count ?? 0 > 7) {
            signInButton.alpha = 0.2
            signInButton.isEnabled = false
            return
        }
        
        signInButton.alpha = 1
        signInButton.isEnabled = true
    }
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = ""
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(signInLabel)
        signInLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        signInLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signInLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(signInNameTextField)
        signInNameTextField.topAnchor.constraint(equalTo: signInLabel.bottomAnchor, constant: 20).isActive = true
        signInNameTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signInNameTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        signInNameTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        view.addSubview(passwordTextField)
        passwordTextField.topAnchor.constraint(equalTo: signInNameTextField.bottomAnchor, constant: 20).isActive = true
        passwordTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        passwordTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        view.addSubview(signInButton)
        signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20).isActive = true
        signInButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signInButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        signInButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
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
        if textField == signInNameTextField {
            passwordTextField.becomeFirstResponder()
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
