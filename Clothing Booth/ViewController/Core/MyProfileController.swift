//
//  MyProfileController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit
import SkeletonView
import SDWebImage

class MyProfileController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        updateProfileData()
    }
    
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.scrollsToTop = true
        sv.alwaysBounceVertical = true
        sv.refreshControl = refreshControl
        sv.delegate = self
        return sv
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(updateProfileData), for: .valueChanged)
        return rc
    }()
    
    var profilePictureImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.image = UIImage(named: "profilepicture_placeholder")
        iv.isSkeletonable = true
        iv.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        return iv
    }()
    
    var usernameLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isSkeletonable = true
        lb.lastLineFillPercent = 100
        lb.skeletonTextLineHeight = .relativeToFont
        lb.linesCornerRadius = 4
        lb.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        lb.textAlignment = .natural
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lb.numberOfLines = 1
        lb.text = "example_user"
        return lb
    }()
    
    var friendsLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isSkeletonable = true
        lb.lastLineFillPercent = 60
        lb.skeletonTextLineHeight = .relativeToFont
        lb.linesCornerRadius = 4
        lb.textAlignment = .natural
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lb.numberOfLines = 1
        lb.text = "0 friends"
        lb.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        return lb
    }()
    
    var pinnedLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isSkeletonable = false
        lb.textAlignment = .natural
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        lb.numberOfLines = 1
        lb.text = "Your pinned outfits"
        return lb
    }()
    
    var editPinnedButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "pencil", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    @objc
    func signOut() {
        let alert = UIAlertController(title: "Are you sure?", message: "Do you want to sign out?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            for key in UserDefaults.standard.dictionaryRepresentation().keys {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first else {
                let alert = UIAlertController(title: "An unexpected error occurred", message: "Please restart the app.", preferredStyle: .alert)
                self.present(alert, animated: true)
                return
            }
            
            window.rootViewController = UINavigationController(rootViewController: SignUpController())
            window.makeKeyAndVisible()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    @objc
    func updateProfileData() {
        Task {
            usernameLabel.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            friendsLabel.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            profilePictureImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            
            let profile = await getMyProfile()
            let profilePictureURL = await retrieveProfilePicture()
            guard profile != nil else { return }
            
            usernameLabel.hideSkeleton()
            friendsLabel.hideSkeleton()
            profilePictureImageView.hideSkeleton()
            usernameLabel.text = profile!.username
            profilePictureImageView.sd_setImage(with: profilePictureURL)
            
            self.refreshControl.endRefreshing()
        }
    }
    
    func getMyProfile() async -> privateUser? {
        var userProfile: privateUser?
        
        do {
            userProfile = try await APIHandler.shared.getMyUserProfile()
            
            if let encoded = try? JSONEncoder().encode(userProfile) {
                UserDefaults.standard.setValue(encoded, forKey: "userProfile")
            }
        } catch let e {
            print(e)
        }
        
        if userProfile == nil {
            do {
                userProfile = try JSONDecoder().decode(privateUser.self, from: UserDefaults.standard.data(forKey: "userProfile") ?? Data())
            } catch let e {
                print(e)
            }
        }
        
        return userProfile
    }
    
    func retrieveProfilePicture() async -> URL? {
        do {
            return try await APIHandler.shared.getMyProfilePicture()
        } catch NetworkingError.notFound {
            return nil
        } catch let e {
            print(e)
            return nil
        }
    }

    func configureViewComponents() {
        view.backgroundColor = .background
        title = "profile"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.standardAppearance.configureWithTransparentBackground()
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "door.left.hand.open", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.systemRed, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(signOut))
        
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        scrollView.addSubview(profilePictureImageView)
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20).isActive = true
        profilePictureImageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 20).isActive = true
        
        scrollView.addSubview(usernameLabel)
        usernameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        usernameLabel.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 15).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -20).isActive = true
        
        scrollView.addSubview(friendsLabel)
        friendsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 5).isActive = true
        friendsLabel.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 15).isActive = true
        friendsLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -20).isActive = true
        
        scrollView.addSubview(pinnedLabel)
        pinnedLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 15).isActive = true
        pinnedLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 20).isActive = true
        
        scrollView.addSubview(editPinnedButton)
        editPinnedButton.centerYAnchor.constraint(equalTo: pinnedLabel.centerYAnchor).isActive = true
        editPinnedButton.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -20).isActive = true
    }
}

extension MyProfileController: UIScrollViewDelegate {
    
}
