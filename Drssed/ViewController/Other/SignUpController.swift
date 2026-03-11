//
//  SignUpController.swift
//  Clothing Booth
//
//  Created by David Riegel on 09.08.24.
//

import UIKit

class SignUpController: UIViewController {
    
    var nextController: welcomeController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextController = welcomeController()
        configureViewComponents()
    }
    
    lazy var signUpLabel: UILabel = {
        var lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 24, weight: .black)
        lb.textAlignment = .center
        lb.text = "welcome, sign up"
        return lb
    }()
    
    lazy var emailTextField: UITextField = {
        var tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.textColor = .label
        tf.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
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
        tf.textContentType = .newPassword
        tf.returnKeyType = .continue
        tf.delegate = self
        tf.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return tf
    }()
    
    lazy var signUpButton: UIButton = {
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
        bt.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return bt
    }()
    
    lazy var signInTextButton: UIButton = {
        var bt = UIButton()
        bt.translatesAutoresizingMaskIntoConstraints = false
        var title = NSMutableAttributedString(string: "Already have an Account? ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.label, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .bold)])
        title.append(NSAttributedString(string: "Sign In", attributes: [NSAttributedString.Key.foregroundColor : UIColor.accent, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .black)]))
        bt.setAttributedTitle(title, for: .normal)
        bt.titleLabel?.textAlignment = .center
        bt.addTarget(self, action: #selector(pushSignIn), for: .touchUpInside)
        return bt
    }()
    
    @objc
    func pushSignIn() {
        DispatchQueue.main.async {
            let signInController = SignInController()
            signInController.navigationItem.hidesBackButton = true
            self.navigationController?.pushViewController(signInController, animated: true)
        }
    }
    
    @objc
    func handleSignUp() {
        // nextController can't be nil here due to not being able to click the sign up button without nextController to be initiated first
        
        signUpButton.alpha = 0.2
        signUpButton.isEnabled = false
        
        self.nextController!.email = emailTextField.text!
        self.nextController!.password = passwordTextField.text!
        self.navigationController?.pushViewController(self.nextController!, animated: true)
    }
    
    @objc
    func checkTextFieldInputs(_ textField: UITextField) {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let validEmail = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: emailTextField.text ?? "")
        
        if !(emailTextField.text?.count ?? 0 > 0) || !(passwordTextField.text?.count ?? 0 > 7) || !validEmail {
            signUpButton.alpha = 0.2
            signUpButton.isEnabled = false
            return
        }
        
        signUpButton.alpha = 1
        signUpButton.isEnabled = true
    }
    
    func configureViewComponents() {
        view.backgroundColor = .background
        title = ""
        
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(signUpLabel)
        signUpLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        signUpLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signUpLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(emailTextField)
        emailTextField.topAnchor.constraint(equalTo: signUpLabel.bottomAnchor, constant: 20).isActive = true
        emailTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        emailTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        view.addSubview(passwordTextField)
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20).isActive = true
        passwordTextField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        passwordTextField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        view.addSubview(signUpButton)
        signUpButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20).isActive = true
        signUpButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signUpButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        view.addSubview(signInTextButton)
        signInTextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        signInTextButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        signInTextButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension SignUpController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
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
