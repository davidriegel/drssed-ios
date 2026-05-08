//
//  User.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation

public struct User: Codable {
    let userID: String
    let isGuest: Bool
    let createdAt: Date
    let updatedAt: Date?
    let username: String?
    let email: String?
    let emailVerifiedAt: Date?
    let profilePicture: String?
    
    init(from api: UserAPI) {
        self.userID = api.user_id
        self.createdAt = api.created_at
        self.updatedAt = api.updated_at
        self.email = api.email
        self.emailVerifiedAt = api.email_verified_at
        self.isGuest = api.is_guest
        self.profilePicture = api.profile_picture
        self.username = api.username
    }
    
    var profilePictureKind: ProfilePicture? {
        guard let raw = profilePicture else { return nil }
        return ProfilePicture(rawValue: raw)
    }
}

enum ProfilePicture {
    case `default`(name: String)
    case custom(url: URL)
    
    init?(rawValue: String) {
        if rawValue.hasPrefix("default/") {
            let name = String(rawValue.dropFirst("default/".count))
            self = .default(name: name)
        } else if !rawValue.isEmpty,
                  let url = URL(string: "\(rawValue)", relativeTo: APIClient.profileImagesURL) {
            self = .custom(url: url)
        } else {
            return nil
        }
    }
}
