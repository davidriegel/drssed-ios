//
//  User.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation

public struct PrivateUser: Codable {
    let user_id: String
    let username: String
    let email: String
    let profile_picture: String
    let created_at: String
    let updated_at: String
    let friends: [String]?
    let incoming_friend_requests: [String]?
    let outgoing_friend_requests: [String]?
}

public struct imageResponse: Codable {
    let path: String
}
