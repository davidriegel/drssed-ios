//
//  ProfileViewController.swift
//  Drssed
//
//  Created by David Riegel on 08.05.26.
//

import UIKit
import Combine

class ProfileViewController: UIViewController {
    private let clothingRepository: ClothingRepository = ClothingRepository()
    private let outfitRepository: OutfitRepository = OutfitRepository()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var currentAuthState: AuthState = .unknown
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
        bindAuthState()
    }
    
    // MARK: -- Scroll Container
    
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.contentInsetAdjustmentBehavior = .always
        return sv
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Guest
    
    lazy var guestHeaderCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "profile.guest.title")
        label.font = .systemFont(ofSize: 22, weight: .black)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    lazy var headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "profile.guest.subtitle")
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    lazy var guestInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "profile.guest.retention.notice")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Authenticated

    lazy var userHeaderCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()

    lazy var profilePictureImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 36
        iv.clipsToBounds = true
        iv.backgroundColor = .tertiarySystemGroupedBackground
        return iv
    }()

    lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .black)
        label.textColor = .label
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    lazy var memberSinceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    // MARK: -- Stats Card
    
    lazy var statsCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    lazy var clothingCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .black)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    lazy var clothingTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "profile.stats.clothing")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    lazy var statsDivider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    lazy var outfitCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .black)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    lazy var outfitTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "profile.stats.outfits")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Account Section

    lazy var accountSectionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    lazy var changeEmailRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.account.email"),
            symbolName: "envelope",
            action: { [weak self] in self?.wipMessage() }
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    lazy var emailSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()

    lazy var changePasswordRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.account.password"),
            symbolName: "lock",
            action: { [weak self] in self?.wipMessage() }
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    lazy var passwordSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()

    lazy var deleteAccountRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.account.delete"),
            symbolName: "trash",
            action: { [weak self] in self?.didTapDeleteAccount() },
            tintColor: .systemRed
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()
    
    // MARK: -- Sign Up Button
    
    lazy var signUpButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.pushSignUp()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .prominentGlass()
        button.configuration?.baseBackgroundColor = .accent
        button.configuration?.baseForegroundColor = .label
        button.backgroundColor = .accent
        button.setAttributedTitle(NSAttributedString(
            string: String(localized: "profile.guest.signup"),
            attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        ), for: .normal)
        return button
    }()
    
    // MARK: -- Sign In Button
    
    lazy var signInTextButton: UIButton = {
        let bt = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.pushSignIn()
        })
        bt.configuration = .plain()
        bt.translatesAutoresizingMaskIntoConstraints = false
        let title = NSMutableAttributedString(
            string: String(localized: "profile.guest.signin.cta1") + " ",
            attributes: [.foregroundColor: UIColor.label, .font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        )
        title.append(NSAttributedString(
            string: String(localized: "profile.guest.signin.cta2"),
            attributes: [.foregroundColor: UIColor.accent, .font: UIFont.systemFont(ofSize: 14, weight: .black)]
        ))
        bt.setAttributedTitle(title, for: .normal)
        bt.titleLabel?.textAlignment = .center
        return bt
    }()
    
    // MARK: -- App Section
    
    lazy var appSectionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()
    
    lazy var aboutRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.about"),
            symbolName: "info.circle",
            action: { [weak self] in self?.wipMessage() }
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()
    
    lazy var aboutSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    lazy var privacyRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.privacy"),
            symbolName: "hand.raised",
            action: { [weak self] in self?.didTapPrivacy() }
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()
    
    lazy var privacySeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    lazy var versionRow: SettingsRow = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        let row = SettingsRow(
            title: String(localized: "profile.version"),
            symbolName: "app.badge",
            detail: "\(version) (\(build))",
            isInteractive: false
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    // MARK: - Sign Out Button

    lazy var signOutButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.didTapSignOut()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .prominentGlass()
        button.configuration?.baseBackgroundColor = .secondarySystemGroupedBackground
        button.configuration?.baseForegroundColor = .systemRed
        button.backgroundColor = .secondarySystemGroupedBackground
        button.setAttributedTitle(NSAttributedString(
            string: String(localized: "profile.signout"),
            attributes: [
                .font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black),
                .foregroundColor: UIColor.systemRed
            ]
        ), for: .normal)
        return button
    }()
    
    // MARK: - Delete guest data
    
    lazy var dangerSectionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    lazy var deleteGuestAccountRow: SettingsRow = {
        let row = SettingsRow(
            title: String(localized: "profile.guest.delete"),
            symbolName: "trash",
            action: { [weak self] in self?.didTapDeleteGuestAccount() },
            tintColor: .systemRed,
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()
    
    // MARK: - Actions
    
    func pushSignUp() {
        DispatchQueue.main.async {
            let signUpController = UINavigationController(rootViewController: SignUpController())
            self.present(signUpController, animated: true)
        }
    }
    
    func pushSignIn() {
        DispatchQueue.main.async {
            let signInController = UINavigationController(rootViewController: SignInController())
            self.present(signInController, animated: true)
        }
    }
    
    func didTapDeleteGuestAccount() {
        let alert = UIAlertController(
            title: String(localized: "profile.guest.delete.confirm.title"),
            message: String(localized: "profile.guest.delete.confirm.message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: String(localized: "common.cancel"),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: String(localized: "common.delete"),
            style: .destructive,
            handler: { [weak self] _ in
                self?.performAccountDeletion()
            }
        ))
        
        present(alert, animated: true)
    }
    
    func didTapDeleteAccount() {
        let alert = UIAlertController(
            title: String(localized: "profile.account.delete.confirm.title"),
            message: String(localized: "profile.account.delete.confirm.message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: String(localized: "common.cancel"),
            style: .cancel
        ))
        
        let deleteAction = UIAlertAction(
            title: String(localized: "profile.account.delete.confirm.action"),
            style: .destructive,
            handler: { [weak self] _ in
                self?.performAccountDeletion()
            }
        )
        
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
    
    private func performAccountDeletion() {
        deleteAccountRow.isUserInteractionEnabled = false
        
        Task {
            do {
                try await AuthenticationManager.shared.deleteAccount()
            } catch {
                ErrorHandler.handle(error)
                deleteAccountRow.isUserInteractionEnabled = true
            }
        }
    }

    func didTapSignOut() {
        let alert = UIAlertController(
            title: String(localized: "profile.signout.confirm.title"),
            message: String(localized: "profile.signout.confirm.message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: String(localized: "common.cancel"),
            style: .cancel
        ))
        
        alert.addAction(UIAlertAction(
            title: String(localized: "profile.signout"),
            style: .destructive,
            handler: { [weak self] _ in
                self?.performSignOut()
            }
        ))
        
        present(alert, animated: true)
    }

    private func performSignOut() {
        signOutButton.isEnabled = false
        
        Task {
            await AuthenticationManager.shared.signOut()
        }
    }
    
    func didTapAbout() {
        guard let url = URL(string: "about", relativeTo: URL(string: "https://drssed.app")) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    func didTapPrivacy() {
        guard let url = URL(string: "privacy", relativeTo: URL(string: "https://drssed.app")) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Functions
    
    func loadGenericData() async {
        async let clothingCount = clothingRepository.fetchClothes().count
        async let outfitCount = outfitRepository.fetchOutfits().count
        
        let (clothes, outfits) = await (clothingCount, outfitCount)
        
        clothingCountLabel.text = String(clothes)
        outfitCountLabel.text = String(outfits)
    }
    
    private func bindAuthState() {
        AuthenticationManager.shared.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleAuthStateChange(state)
            }
            .store(in: &cancellables)
        
        AuthenticationManager.shared.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.handleUserChange(user)
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthStateChange(_ newState: AuthState) {
        guard newState != currentAuthState else { return }
        currentAuthState = newState
        rebuildContent(for: newState)
    }
    
    private func handleUserChange(_ user: User?) {
        guard currentAuthState == .authenticated, let user = user else { return }
        
        emailLabel.text = user.email ?? "—"
        
        switch user.profilePictureKind {
        case .default(let name):
            profilePictureImageView.sd_cancelCurrentImageLoad()
            profilePictureImageView.image = UIImage(named: "default_\(name)_profilepicture")
        case .custom(let url):
            profilePictureImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "default_hat_profilepicture")
            )
        case .none:
            profilePictureImageView.sd_cancelCurrentImageLoad()
            profilePictureImageView.image = nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        memberSinceLabel.text = String(localized: "profile.member_since") + " " + formatter.string(from: user.createdAt)
    }
    
    private func rebuildContent(for state: AuthState) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        switch state {
        case .guest, .unauthenticated, .unknown:
            configureGuestLayout()
        case .authenticated:
            configureAuthenticatedLayout()
        }
        
        Task { await loadGenericData() }
    }
    
    private func wipMessage() {
        let infoAlert = UIAlertController(title: "🤫", message: String(localized: "workinprogress.message"), preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))
        UIApplication.shared.topMostViewController()!.present(infoAlert, animated: true)
    }
    
    // MARK: -- Layout
    
    func configureViewComponents() {
        view.backgroundColor = .background
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    func configureGuestLayout() {
        contentView.addSubview(guestHeaderCard)
        NSLayoutConstraint.activate([
            guestHeaderCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            guestHeaderCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            guestHeaderCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        guestHeaderCard.addSubview(headerTitleLabel)
        NSLayoutConstraint.activate([
            headerTitleLabel.topAnchor.constraint(equalTo: guestHeaderCard.topAnchor, constant: 24),
            headerTitleLabel.leadingAnchor.constraint(equalTo: guestHeaderCard.leadingAnchor, constant: 20),
            headerTitleLabel.trailingAnchor.constraint(equalTo: guestHeaderCard.trailingAnchor, constant: -20)
        ])
        
        guestHeaderCard.addSubview(headerSubtitleLabel)
        NSLayoutConstraint.activate([
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 6),
            headerSubtitleLabel.leadingAnchor.constraint(equalTo: guestHeaderCard.leadingAnchor, constant: 20),
            headerSubtitleLabel.trailingAnchor.constraint(equalTo: guestHeaderCard.trailingAnchor, constant: -20)
        ])
        
        guestHeaderCard.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: headerSubtitleLabel.bottomAnchor, constant: 24),
            signUpButton.leadingAnchor.constraint(equalTo: guestHeaderCard.leadingAnchor, constant: 20),
            signUpButton.trailingAnchor.constraint(equalTo: guestHeaderCard.trailingAnchor, constant: -20),
            signUpButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        guestHeaderCard.addSubview(signInTextButton)
        NSLayoutConstraint.activate([
            signInTextButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 8),
            signInTextButton.centerXAnchor.constraint(equalTo: guestHeaderCard.centerXAnchor),
            signInTextButton.bottomAnchor.constraint(equalTo: guestHeaderCard.bottomAnchor, constant: -16),
            signInTextButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        contentView.addSubview(guestInfoLabel)
        NSLayoutConstraint.activate([
            guestInfoLabel.topAnchor.constraint(equalTo: guestHeaderCard.bottomAnchor, constant: 5),
            guestInfoLabel.leadingAnchor.constraint(equalTo: guestHeaderCard.leadingAnchor),
            guestInfoLabel.trailingAnchor.constraint(equalTo: guestHeaderCard.trailingAnchor),
        ])
        
        let statsCard = configureStatsCard(topAnchor: guestInfoLabel.bottomAnchor)
        let appSection = configureAppSection(topAnchor: statsCard.bottomAnchor)
        
        contentView.addSubview(dangerSectionContainer)
        NSLayoutConstraint.activate([
            dangerSectionContainer.topAnchor.constraint(equalTo: appSection.bottomAnchor, constant: 20),
            dangerSectionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dangerSectionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dangerSectionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        dangerSectionContainer.addSubview(deleteGuestAccountRow)
        NSLayoutConstraint.activate([
            deleteGuestAccountRow.topAnchor.constraint(equalTo: dangerSectionContainer.topAnchor),
            deleteGuestAccountRow.leadingAnchor.constraint(equalTo: dangerSectionContainer.leadingAnchor),
            deleteGuestAccountRow.trailingAnchor.constraint(equalTo: dangerSectionContainer.trailingAnchor),
            deleteGuestAccountRow.bottomAnchor.constraint(equalTo: dangerSectionContainer.bottomAnchor)
        ])
    }
    
    func configureAuthenticatedLayout() {
        // User Header Card
        contentView.addSubview(userHeaderCard)
        NSLayoutConstraint.activate([
            userHeaderCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            userHeaderCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            userHeaderCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        userHeaderCard.addSubview(profilePictureImageView)
        NSLayoutConstraint.activate([
            profilePictureImageView.topAnchor.constraint(equalTo: userHeaderCard.topAnchor, constant: 20),
            profilePictureImageView.leadingAnchor.constraint(equalTo: userHeaderCard.leadingAnchor, constant: 20),
            profilePictureImageView.bottomAnchor.constraint(equalTo: userHeaderCard.bottomAnchor, constant: -20),
            profilePictureImageView.widthAnchor.constraint(equalToConstant: 72),
            profilePictureImageView.heightAnchor.constraint(equalToConstant: 72)
        ])
        
        userHeaderCard.addSubview(emailLabel)
        NSLayoutConstraint.activate([
            emailLabel.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: userHeaderCard.trailingAnchor, constant: -20),
            emailLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor, constant: 14)
        ])
        
        userHeaderCard.addSubview(memberSinceLabel)
        NSLayoutConstraint.activate([
            memberSinceLabel.leadingAnchor.constraint(equalTo: emailLabel.leadingAnchor),
            memberSinceLabel.trailingAnchor.constraint(equalTo: emailLabel.trailingAnchor),
            memberSinceLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4)
        ])
        
        // Stats Card
        let statsCard = configureStatsCard(topAnchor: userHeaderCard.bottomAnchor)
        
        // Account Section
        contentView.addSubview(accountSectionContainer)
        NSLayoutConstraint.activate([
            accountSectionContainer.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 20),
            accountSectionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            accountSectionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        accountSectionContainer.addSubview(changeEmailRow)
        NSLayoutConstraint.activate([
            changeEmailRow.topAnchor.constraint(equalTo: accountSectionContainer.topAnchor),
            changeEmailRow.leadingAnchor.constraint(equalTo: accountSectionContainer.leadingAnchor),
            changeEmailRow.trailingAnchor.constraint(equalTo: accountSectionContainer.trailingAnchor)
        ])
        
        accountSectionContainer.addSubview(emailSeparator)
        NSLayoutConstraint.activate([
            emailSeparator.topAnchor.constraint(equalTo: changeEmailRow.bottomAnchor),
            emailSeparator.leadingAnchor.constraint(equalTo: accountSectionContainer.leadingAnchor, constant: 52),
            emailSeparator.trailingAnchor.constraint(equalTo: accountSectionContainer.trailingAnchor),
            emailSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        accountSectionContainer.addSubview(changePasswordRow)
        NSLayoutConstraint.activate([
            changePasswordRow.topAnchor.constraint(equalTo: emailSeparator.bottomAnchor),
            changePasswordRow.leadingAnchor.constraint(equalTo: accountSectionContainer.leadingAnchor),
            changePasswordRow.trailingAnchor.constraint(equalTo: accountSectionContainer.trailingAnchor)
        ])
        
        accountSectionContainer.addSubview(passwordSeparator)
        NSLayoutConstraint.activate([
            passwordSeparator.topAnchor.constraint(equalTo: changePasswordRow.bottomAnchor),
            passwordSeparator.leadingAnchor.constraint(equalTo: accountSectionContainer.leadingAnchor, constant: 52),
            passwordSeparator.trailingAnchor.constraint(equalTo: accountSectionContainer.trailingAnchor),
            passwordSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        accountSectionContainer.addSubview(deleteAccountRow)
        NSLayoutConstraint.activate([
            deleteAccountRow.topAnchor.constraint(equalTo: passwordSeparator.bottomAnchor),
            deleteAccountRow.leadingAnchor.constraint(equalTo: accountSectionContainer.leadingAnchor),
            deleteAccountRow.trailingAnchor.constraint(equalTo: accountSectionContainer.trailingAnchor),
            deleteAccountRow.bottomAnchor.constraint(equalTo: accountSectionContainer.bottomAnchor)
        ])
        
        let appSection = configureAppSection(topAnchor: accountSectionContainer.bottomAnchor)

        contentView.addSubview(signOutButton)
        NSLayoutConstraint.activate([
            signOutButton.topAnchor.constraint(equalTo: appSection.bottomAnchor, constant: 24),
            signOutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            signOutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            signOutButton.heightAnchor.constraint(equalToConstant: 50),
            signOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    func configureStatsCard(topAnchor: NSLayoutYAxisAnchor) -> UIView {
        contentView.addSubview(statsCard)
        NSLayoutConstraint.activate([
            statsCard.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsCard.heightAnchor.constraint(equalToConstant: 88)
        ])
        
        statsCard.addSubview(statsDivider)
        NSLayoutConstraint.activate([
            statsDivider.centerXAnchor.constraint(equalTo: statsCard.centerXAnchor),
            statsDivider.centerYAnchor.constraint(equalTo: statsCard.centerYAnchor),
            statsDivider.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            statsDivider.heightAnchor.constraint(equalTo: statsCard.heightAnchor, multiplier: 0.5)
        ])
        
        statsCard.addSubview(clothingCountLabel)
        NSLayoutConstraint.activate([
            clothingCountLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor),
            clothingCountLabel.trailingAnchor.constraint(equalTo: statsDivider.leadingAnchor),
            clothingCountLabel.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16)
        ])
        
        statsCard.addSubview(clothingTitleLabel)
        NSLayoutConstraint.activate([
            clothingTitleLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor),
            clothingTitleLabel.trailingAnchor.constraint(equalTo: statsDivider.leadingAnchor),
            clothingTitleLabel.topAnchor.constraint(equalTo: clothingCountLabel.bottomAnchor, constant: 2)
        ])
        
        statsCard.addSubview(outfitCountLabel)
        NSLayoutConstraint.activate([
            outfitCountLabel.leadingAnchor.constraint(equalTo: statsDivider.trailingAnchor),
            outfitCountLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor),
            outfitCountLabel.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16)
        ])
        
        statsCard.addSubview(outfitTitleLabel)
        NSLayoutConstraint.activate([
            outfitTitleLabel.leadingAnchor.constraint(equalTo: statsDivider.trailingAnchor),
            outfitTitleLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor),
            outfitTitleLabel.topAnchor.constraint(equalTo: outfitCountLabel.bottomAnchor, constant: 2)
        ])
        
        return statsCard
    }
    
    func configureAppSection(topAnchor: NSLayoutYAxisAnchor) -> UIView {
        contentView.addSubview(appSectionContainer)
        NSLayoutConstraint.activate([
            appSectionContainer.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            appSectionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appSectionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        appSectionContainer.addSubview(aboutRow)
        NSLayoutConstraint.activate([
            aboutRow.topAnchor.constraint(equalTo: appSectionContainer.topAnchor),
            aboutRow.leadingAnchor.constraint(equalTo: appSectionContainer.leadingAnchor),
            aboutRow.trailingAnchor.constraint(equalTo: appSectionContainer.trailingAnchor)
        ])
        
        appSectionContainer.addSubview(aboutSeparator)
        NSLayoutConstraint.activate([
            aboutSeparator.topAnchor.constraint(equalTo: aboutRow.bottomAnchor),
            aboutSeparator.leadingAnchor.constraint(equalTo: appSectionContainer.leadingAnchor, constant: 52),
            aboutSeparator.trailingAnchor.constraint(equalTo: appSectionContainer.trailingAnchor),
            aboutSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        appSectionContainer.addSubview(privacyRow)
        NSLayoutConstraint.activate([
            privacyRow.topAnchor.constraint(equalTo: aboutSeparator.bottomAnchor),
            privacyRow.leadingAnchor.constraint(equalTo: appSectionContainer.leadingAnchor),
            privacyRow.trailingAnchor.constraint(equalTo: appSectionContainer.trailingAnchor)
        ])
        
        appSectionContainer.addSubview(privacySeparator)
        NSLayoutConstraint.activate([
            privacySeparator.topAnchor.constraint(equalTo: privacyRow.bottomAnchor),
            privacySeparator.leadingAnchor.constraint(equalTo: appSectionContainer.leadingAnchor, constant: 52),
            privacySeparator.trailingAnchor.constraint(equalTo: appSectionContainer.trailingAnchor),
            privacySeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        
        appSectionContainer.addSubview(versionRow)
        NSLayoutConstraint.activate([
            versionRow.topAnchor.constraint(equalTo: privacySeparator.bottomAnchor),
            versionRow.leadingAnchor.constraint(equalTo: appSectionContainer.leadingAnchor),
            versionRow.trailingAnchor.constraint(equalTo: appSectionContainer.trailingAnchor),
            versionRow.bottomAnchor.constraint(equalTo: appSectionContainer.bottomAnchor)
        ])
        
        return appSectionContainer
    }
}
