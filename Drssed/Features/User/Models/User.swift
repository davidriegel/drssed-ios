//
//  User.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation

public struct User: Codable {
    let user_id: String
    let is_guest: Bool
    let created_at: Date
    let updated_at: Date?
    let username: String?
    let email: String?
    let profile_picture: String
}
