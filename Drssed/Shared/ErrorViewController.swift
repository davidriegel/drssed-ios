//
//  ErrorViewController.swift
//  Drssed
//
//  Created by David Riegel on 17.03.26.
//

import UIKit

final class ErrorViewController: UIViewController {
    
    // MARK: - Properties
    
    private let error: Error
    private let retryAction: () -> Void
    
    // MARK: - UI Components
    
    private let errorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "error.title.system")
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "error.action.retry")
        config.cornerStyle = .medium
        config.buttonSize = .large
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    init(error: Error, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureErrorMessage()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(errorImageView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            // Error Icon
            errorImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            errorImageView.widthAnchor.constraint(equalToConstant: 80),
            errorImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: errorImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Retry Button
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    private func configureErrorMessage() {
        // Intelligente Error-Message basierend auf Error-Typ
        if let apiError = error as? APIError {
            messageLabel.text = getMessageForAPIError(apiError)
        } else if let authError = error as? AuthenticationError {
            messageLabel.text = getMessageForAuthError(authError)
        } else {
            messageLabel.text = String(localized: "error.api.generic.suggestion")
        }
    }
    
    private func getMessageForAPIError(_ error: APIError) -> String {
        switch error {
        case .offline:
            return String(localized: "error.api.offline.description")
            
        case .serverUnavailable:
            return String(localized: "error.api.serverUnavailable.description")
            
        case .timeout:
            return String(localized: "error.api.timeout.description")
            
        default:
            return String(localized: "error.api.generic.suggestion")
        }
    }
    
    private func getMessageForAuthError(_ error: AuthenticationError) -> String {
        switch error {
        case .userNotSignedIn:
            return String(localized: "error.auth.unknown.description")
            
        default:
            return String(localized: "error.api.generic.suggestion")
        }
    }
    
    // MARK: - Actions
    
    @objc private func retryButtonTapped() {
        // Zeige Loading-Indicator auf Button
        retryButton.configuration?.showsActivityIndicator = true
        retryButton.isEnabled = false
        
        // Führe Retry aus
        retryAction()
    }
}
