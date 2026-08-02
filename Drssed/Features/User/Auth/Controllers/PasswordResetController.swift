//
//  PasswordResetController.swift
//  Drssed
//
//  Created by David Riegel on 02.08.26.
//

import UIKit


final class PasswordResetController: UIViewController {

    private let prefilledEmail: String?

    init(prefilledEmail: String? = nil) {
        self.prefilledEmail = prefilledEmail

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        checkTextFieldInputs()
    }

    // MARK: - UI Elements -

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "auth.reset.subtitle")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emailField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(
            fieldTitle: String(localized: "common.email"),
            placeholder: String(localized: "auth.signin.email.placeholder"),
            text: prefilledEmail
        )
        view.fieldInput.delegate = self
        view.fieldInput.textContentType = .emailAddress
        view.fieldInput.keyboardType = .emailAddress
        view.fieldInput.autocapitalizationType = .none
        view.fieldInput.autocorrectionType = .no
        view.fieldInput.addTarget(self, action: #selector(checkTextFieldInputs), for: .editingChanged)
        return view
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.handleSend()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .prominentGlass()
        button.configuration?.baseBackgroundColor = .accent
        button.configuration?.baseForegroundColor = .label
        button.backgroundColor = .accent.withAlphaComponent(0.3)
        button.isEnabled = false
        button.setAttributedTitle(
            NSAttributedString(
                string: String(localized: "auth.reset.send"),
                attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
            ),
            for: .normal
        )
        return button
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .secondaryLabel
        return spinner
    }()

    private lazy var confirmationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "auth.reset.confirmation")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Functions -

    private func handleSend() {
        guard let email = emailField.fieldInput.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              email.isValidEmail else { return }

        view.endEditing(true)
        setSending(true)

        Task {
            do {
                try await AuthenticationManager.shared.requestPasswordReset(email: email)

                showConfirmation()
            } catch {
                ErrorHandler.handle(error)
                setSending(false)
            }
        }
    }

    private func setSending(_ isSending: Bool) {
        emailField.fieldInput.isEnabled = !isSending
        isSending ? spinner.startAnimating() : spinner.stopAnimating()

        guard !isSending else {
            sendButton.isEnabled = false
            sendButton.backgroundColor = .accent.withAlphaComponent(0.3)
            return
        }

        checkTextFieldInputs()
    }

    private func showConfirmation() {
        spinner.stopAnimating()

        [subtitleLabel, emailField, sendButton].forEach { $0.isHidden = true }
        confirmationLabel.isHidden = false
    }

    @objc
    private func checkTextFieldInputs() {
        let email = emailField.fieldInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isValid = email.isValidEmail

        sendButton.isEnabled = isValid
        sendButton.backgroundColor = isValid ? .accent : .accent.withAlphaComponent(0.3)
    }

    // MARK: - Layout -

    private func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "auth.reset.title")

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.largeTitleDisplayMode = .never

        [subtitleLabel, emailField, sendButton, spinner, confirmationLabel].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),

            emailField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(greaterThanOrEqualToConstant: 65),

            sendButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 25),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 45),
            sendButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),

            spinner.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 16),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            confirmationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            confirmationLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            confirmationLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30)
        ])

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension PasswordResetController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)

        if sendButton.isEnabled {
            handleSend()
        }

        return true
    }
}
