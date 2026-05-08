//
//  UserAPI.swift
//  Drssed
//
//  Created by David Riegel on 08.05.26.
//

import Foundation

public struct UserAPI: Codable, Hashable {
    let user_id: String
    let is_guest: Bool
    let username: String?
    let email: String?
    let email_verified_at: Date?
    let updated_at: Date
    let created_at: Date
    let profile_picture: String?
    
    func toDomain() -> User {
        return User.init(from: self)
    }
}

public struct UserAPIWrapper: Codable {
    let user: UserAPI
}
