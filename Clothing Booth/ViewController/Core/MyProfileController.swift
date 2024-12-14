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
        updateData()
    }
    
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
        lb.lastLineFillPercent = 60
        lb.skeletonTextLineHeight = .relativeToFont
        lb.linesCornerRadius = 4
        lb.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
        lb.textAlignment = .natural
        lb.textColor = .label
        lb.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lb.numberOfLines = 1
        lb.text = "username"
        return lb
    }()
    
    var friendsLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.isSkeletonable = true
        lb.lastLineFillPercent = 40
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
            
            UIApplication.shared.windows.first?.rootViewController = UINavigationController(rootViewController: SignUpController())
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    func updateData() {
        Task {
            let profile = await getMyProfile()
            let profilePictureURL = await retrieveProfilePicture()
            guard profile != nil else { return }
            
            usernameLabel.hideSkeleton()
            friendsLabel.hideSkeleton()
            profilePictureImageView.hideSkeleton()
            usernameLabel.text = profile!.username
            profilePictureImageView.sd_setImage(with: profilePictureURL)
        }
    }
    
    func getMyProfile() async -> privateUser? {
        do {
            return try await APIHandler.shared.getMyUserProfile()
        } catch let e {
            print(e)
            return nil
        }
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
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "door.left.hand.open", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.systemRed, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(signOut))

        
        view.addSubview(profilePictureImageView)
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        profilePictureImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(usernameLabel)
        usernameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        usernameLabel.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 15).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(friendsLabel)
        friendsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 5).isActive = true
        friendsLabel.leftAnchor.constraint(equalTo: profilePictureImageView.rightAnchor, constant: 15).isActive = true
        friendsLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(pinnedLabel)
        pinnedLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 15).isActive = true
        pinnedLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        
        view.addSubview(editPinnedButton)
        editPinnedButton.centerYAnchor.constraint(equalTo: pinnedLabel.centerYAnchor).isActive = true
        editPinnedButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
    }
}
