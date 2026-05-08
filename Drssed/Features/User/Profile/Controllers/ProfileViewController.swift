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
    }
    
    private func handleAuthStateChange(_ newState: AuthState) {
        guard newState != currentAuthState else { return }
        currentAuthState = newState
        rebuildContent(for: newState)
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
    
    func configureGuestLayout() {
        contentView.addSubview(headerCard)
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        headerCard.addSubview(headerTitleLabel)
        NSLayoutConstraint.activate([
            headerTitleLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 24),
            headerTitleLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            headerTitleLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20)
        ])
        
        headerCard.addSubview(headerSubtitleLabel)
        NSLayoutConstraint.activate([
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 6),
            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            headerSubtitleLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20)
        ])
        
        headerCard.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: headerSubtitleLabel.bottomAnchor, constant: 24),
            signUpButton.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            signUpButton.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            signUpButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        headerCard.addSubview(signInTextButton)
        NSLayoutConstraint.activate([
            signInTextButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 8),
            signInTextButton.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            signInTextButton.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),
            signInTextButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        contentView.addSubview(guestInfoLabel)
        NSLayoutConstraint.activate([
            guestInfoLabel.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 5),
            guestInfoLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor),
            guestInfoLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor),
        ])
        
        configureSharedComponents(topAnchor: guestInfoLabel.bottomAnchor)
    }
    
    func configureAuthenticatedLayout() {
        configureSharedComponents(topAnchor: contentView.topAnchor)
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
    
    // MARK: -- Guest header card
    
    lazy var headerCard: UIView = {
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
            action: { [weak self] in self?.didTapAbout() }
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
    
    // MARK: -- Actions
    
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
    
    func configureSharedComponents(topAnchor: NSLayoutYAxisAnchor) {
        // Stats Card
        contentView.addSubview(statsCard)
        NSLayoutConstraint.activate([
            statsCard.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsCard.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.3)
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
        
        // App Section
        contentView.addSubview(appSectionContainer)
        NSLayoutConstraint.activate([
            appSectionContainer.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 20),
            appSectionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appSectionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            appSectionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
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
    }
}
