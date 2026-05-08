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
}
