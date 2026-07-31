//
//  AuthLandingController.swift
//  Drssed
//
//  Created by David Riegel on 29.07.26.
//

import UIKit

/// The screen the app falls back to when it has no account: after signing out and after
/// deleting one. It exists so that neither of those silently mints a fresh guest account.
///
/// It does not route anywhere itself – the scene watches the auth state and swaps the root
/// once registering, signing in or continuing as a guest has succeeded.
final class AuthLandingController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
    }

    // MARK: - UI Elements -

    private lazy var logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "hanger")
        iv.clipsToBounds = true
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28, weight: .black)
        label.textColor = .label
        label.text = String(localized: "auth.landing.title")
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 3
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = String(localized: "auth.landing.subtitle")
        return label
    }()

    private lazy var signUpButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { _ in
            self.presentModally(SignUpController())
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.configuration = .prominentGlass()
        bt.configuration?.baseBackgroundColor = .accent
        bt.configuration?.baseForegroundColor = .label
        bt.backgroundColor = .accent
        bt.setAttributedTitle(
            NSAttributedString(
                string: String(localized: "auth.landing.signup"),
                attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
            ),
            for: .normal
        )
        return bt
    }()

    private lazy var signInButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { _ in
            self.presentModally(SignInController())
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setAttributedTitle(
            NSAttributedString(
                string: String(localized: "auth.landing.signin"),
                attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
            ),
            for: .normal
        )
        bt.setTitleColor(.accent, for: .normal)
        return bt
    }()

    private lazy var guestButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { _ in
            self.continueAsGuest()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setAttributedTitle(
            NSAttributedString(
                string: String(localized: "auth.landing.guest"),
                attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .bold)]
            ),
            for: .normal
        )
        bt.setTitleColor(.secondaryLabel, for: .normal)
        return bt
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .secondaryLabel
        return spinner
    }()

    // MARK: - Functions -

    private func continueAsGuest() {
        setButtons(enabled: false)
        spinner.startAnimating()

        Task {
            defer {
                self.setButtons(enabled: true)
                self.spinner.stopAnimating()
            }

            do {
                // Clearing has to precede the state flip – that flip is what swaps the
                // root view controller and kicks off the first sync.
                await SyncManager.shared.clearSyncState()
                try await AuthenticationManager.shared.registerAsGuest()
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }

    private func setButtons(enabled: Bool) {
        [signUpButton, signInButton, guestButton].forEach { $0.isEnabled = enabled }
    }

    /// Presents the auth screens the way the profile does – wrapped in a navigation
    /// controller, so their cancel button lands back here instead of nowhere.
    private func presentModally(_ controller: UIViewController) {
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    // MARK: - Layout -

    private func configureViewComponents() {
        view.backgroundColor = .background

        [logoImageView, titleLabel, subtitleLabel, signUpButton, signInButton, guestButton, spinner].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -10),
            logoImageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),
            logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            signUpButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 45),
            signUpButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),

            signInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 12),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 30),

            spinner.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 12),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            guestButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            guestButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            guestButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
